import window from "@ohos.window";
import display from "@ohos.display";
import { common } from "@kit.AbilityKit";
import preferences from '@ohos.data.preferences';
import { HapApp } from "libohos.so";
import { AppWindow } from "./AppWindow";
import { FloatWindowManager } from "./FloatWindow";
import { calculateDockSize } from "../utils/HiCarDockUtils";

const APPS_PREFERENCES_NAME: string = 'hap_apps_storage';
const APPS_CACHE_KEY: string = 'hap_apps_cache';
const STORAGE_APP_LIST_WINDOW: string = 'floatAppListWindow';
const STORAGE_DISPLAY_ID: string = 'floatAppListDisplayId';
const LIST_MARGIN_VP: number = 32;
const LIST_CORNER_RADIUS_VP: number = 8;
const LIST_LANDSCAPE_ROWS: number = 3;
const LIST_ITEM_HEIGHT_VP: number = 82;

interface ListLayout {
  x: number;
  y: number;
  width: number;
  height: number;
  rowCount: number;
}

function vp2pxFloor(vp: number, density: number): number {
  return Math.floor(vp * density);
}

function calculateListLayout(screenInfo: display.Display): ListLayout {
  const margin = vp2pxFloor(LIST_MARGIN_VP, screenInfo.densityPixels);
  const dockWidth = calculateDockSize(screenInfo.width, screenInfo.height, screenInfo.densityPixels);
  const leftMargin = margin + dockWidth;
  const width = Math.max(1, screenInfo.width - leftMargin - margin);
  const height = Math.max(1, screenInfo.height - margin * 2);
  const isLandscape = screenInfo.width > screenInfo.height;
  const rowCount = isLandscape
    ? LIST_LANDSCAPE_ROWS
    : Math.max(1, Math.floor(height / vp2pxFloor(LIST_ITEM_HEIGHT_VP, screenInfo.densityPixels)));
  return { x: leftMargin, y: margin, width, height, rowCount };
}

export class FloatAppListWindowManager {
  private static currentWindow: window.Window | null = null;
  private static currentDisplayId: number = 0;
  private static readonly touchOutsideCallback: Callback<void> = () => {
    FloatAppListWindowManager.closeAndShowIcon();
  };

  static show(context: common.UIAbilityContext, displayId: number): void {
    AppWindow.minimizeAll();
    if (FloatAppListWindowManager.currentWindow && FloatAppListWindowManager.currentDisplayId === displayId) {
      FloatAppListWindowManager.currentWindow.showWindow((err) => {
        if (err.code != 0) {
          console.error("FloatAppListWindow: 显示应用列表失败:", JSON.stringify(err));
        }
      });
      return;
    }

    window.createWindow({
      name: `floatAppListWindow_${displayId}`,
      windowType: window.WindowType.TYPE_FLOAT,
      ctx: context,
      displayId: displayId
    }, (err, win) => {
      if (err.code != 0) {
        console.error("FloatAppListWindow: 创建应用列表窗口失败:", JSON.stringify(err));
        return;
      }
      FloatAppListWindowManager.currentWindow = win;
      FloatAppListWindowManager.currentDisplayId = displayId;
      AppStorage.setOrCreate(STORAGE_APP_LIST_WINDOW, win);
      AppStorage.setOrCreate(STORAGE_DISPLAY_ID, displayId);
      win.on('touchOutside', FloatAppListWindowManager.touchOutsideCallback);

      let screenInfo: display.Display;
      try {
        screenInfo = displayId === 0 ? display.getDefaultDisplaySync() : display.getDisplayByIdSync(displayId);
      } catch (error) {
        console.error("FloatAppListWindow: 获取屏幕信息失败:", JSON.stringify(error));
        screenInfo = display.getDefaultDisplaySync();
      }
      const layout = calculateListLayout(screenInfo);
      win.resize(layout.width, layout.height).catch((error: Error) => {
        console.error("FloatAppListWindow: 设置列表窗口大小失败:", JSON.stringify(error));
      });
      win.moveWindowTo(layout.x, layout.y).catch((error: Error) => {
        console.error("FloatAppListWindow: 设置列表窗口位置失败:", JSON.stringify(error));
      });
      win.setWindowCornerRadius(vp2pxFloor(LIST_CORNER_RADIUS_VP, screenInfo.densityPixels))
        .catch((error: Error) => {
          console.error("FloatAppListWindow: 设置列表窗口圆角失败:", JSON.stringify(error));
        });
      win.loadContent("window/FloatAppListWindow", (loadErr) => {
        if (loadErr.code != 0) {
          console.error("FloatAppListWindow: 加载列表页面失败:", JSON.stringify(loadErr));
          return;
        }
        win.showWindow((showErr) => {
          if (showErr.code != 0) {
            console.error("FloatAppListWindow: 显示应用列表失败:", JSON.stringify(showErr));
          }
        });
      });
    });
  }

  static hide(): void {
    FloatAppListWindowManager.destroyCurrentWindow();
  }

  static closeAndShowIcon(onClosed?: () => void, listWindow?: window.Window | null): void {
    FloatAppListWindowManager.destroyCurrentWindow(() => {
      AppWindow.showAll();
      FloatWindowManager.show(onClosed);
    }, listWindow);
  }

  private static destroyCurrentWindow(onClosed?: () => void, preferredWindow?: window.Window | null): void {
    const closingWindow = preferredWindow ||
      AppStorage.get<window.Window>(STORAGE_APP_LIST_WINDOW) ||
      FloatAppListWindowManager.currentWindow;
    if (!closingWindow) {
      onClosed?.();
      return;
    }
    console.info("FloatAppListWindow: 开始销毁应用列表窗口");
    closingWindow.destroyWindow((err) => {
      if (err.code != 0) {
        console.error("FloatAppListWindow: 销毁应用列表窗口失败:", JSON.stringify(err));
        return;
      }
      console.info("FloatAppListWindow: 应用列表窗口已销毁");
      if (FloatAppListWindowManager.currentWindow === closingWindow) {
        FloatAppListWindowManager.currentWindow = null;
      }
      onClosed?.();
    });
  }
}

@Entry
@Component
struct FloatAppListWindow {
  @State apps: HapApp[] = [];
  @State isLoading: boolean = false;
  private rowCount: number = 1;
  private displayId: number = 0;
  private currentWindow: window.Window | null = null;
  aboutToAppear(): void {
    this.currentWindow = AppStorage.get<window.Window>(STORAGE_APP_LIST_WINDOW) || null;
    this.displayId = AppStorage.get<number>(STORAGE_DISPLAY_ID) || 0;
    if (this.currentWindow) {
      let screenInfo: display.Display;
      try {
        screenInfo = this.displayId === 0 ? display.getDefaultDisplaySync() : display.getDisplayByIdSync(this.displayId);
      } catch (_) {
        screenInfo = display.getDefaultDisplaySync();
      }
      this.rowCount = calculateListLayout(screenInfo).rowCount;
    }
    this.loadAppsFromCache();
  }

  private async loadAppsFromCache(): Promise<void> {
    this.isLoading = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const prefs = await preferences.getPreferences(context, APPS_PREFERENCES_NAME);
      const cached = await prefs.get(APPS_CACHE_KEY, '');
      if (cached) {
        this.apps = JSON.parse(cached as string) as HapApp[];
      }
    } catch (error) {
      console.error("FloatAppListWindow: 加载应用缓存失败", error);
    } finally {
      this.isLoading = false;
    }
  }

  private launchApp(app: HapApp): void {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      FloatAppListWindowManager.closeAndShowIcon(() => {
        if (!AppWindow.showExisting(app.package)) {
          AppWindow.create(app.package, this.displayId, context);
        }
      }, this.currentWindow);
    } catch (error) {
      console.error("FloatAppListWindow: 启动应用异常:", JSON.stringify(error));
    }
  }

  build() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress().width(40).height(40).color($r('app.color.accent'))
          Text('加载中...').fontSize(12).fontColor($r('app.color.text_tertiary')).margin({ top: 8 })
        }
        .width('100%').layoutWeight(1).justifyContent(FlexAlign.Center).alignItems(HorizontalAlign.Center)
      } else {
        Scroll(new Scroller()) {
          Grid() {
            ForEach(this.apps, (app: HapApp) => {
              GridItem() {
                Column({ space: 6 }) {
                  Image(app.icon).width(48).height(48).borderRadius(24)
                  Text(app.name).fontSize(12).fontColor($r('app.color.text_primary')).maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis }).width('100%').textAlign(TextAlign.Center)
                }
                .width(100).padding(8).onClick(() => this.launchApp(app))
              }
            }, (app: HapApp) => app.package)
          }
          .rowsTemplate(Array(this.rowCount).fill('1fr').join(' '))
          .columnsGap(12).rowsGap(12).width('100%')
        }
        .width('100%').layoutWeight(1).scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Auto).edgeEffect(EdgeEffect.Spring)
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      }
    }
    .width('100%').height('100%').backgroundColor($r('app.color.bg_sheet')).borderRadius(20)
    .shadow({ radius: 20, color: $r('app.color.shadow_float'), offsetX: 0, offsetY: 4 })
  }
}
