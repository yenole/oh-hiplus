import window from "@ohos.window";
import display from "@ohos.display";
import { common } from "@kit.AbilityKit";
import preferences from '@ohos.data.preferences';
import { HapApp } from "libohos.so";
import { AppWindow } from "./AppWindow";
import { calculateDockSize, calculateFloatIconLayout, FloatIconLayout } from "../utils/HiCarDockUtils";

/** 应用列表缓存的 preferences 名称与 key。 */
const APPS_PREFERENCES_NAME: string = 'hap_apps_storage';
const APPS_CACHE_KEY: string = 'hap_apps_cache';

/** FloatWindow 在 AppStorage 中的键。 */
const STORAGE_FLOAT_WINDOW: string = 'floatWindow';
const STORAGE_DISPLAY_ID: string = 'floatWindowDisplayId';

/** 应用列表展开态窗口的尺寸参数（vp / 比例）。 */
const LIST_MARGIN_VP: number = 16;           // 窗口四周预留边距
const LIST_CORNER_RADIUS_VP: number = 8;     // 展开态窗口圆角
const LIST_LANDSCAPE_ROWS: number = 3;       // 横屏固定行数
const LIST_ITEM_HEIGHT_VP: number = 82;      // 竖屏单行估算高度（图标 + 间距 + 文字 + 内边距）

/** 悬浮图标态窗口的圆角由 HiCarDockUtils 按 vp 换算，此处仅保留拖动/点击用的手势参数。 */

/** 获取指定屏幕的 display 信息，失败时回退到默认屏幕。 */
function getScreenInfo(displayId: number): display.Display {
  try {
    return displayId === 0
      ? display.getDefaultDisplaySync()
      : display.getDisplayByIdSync(displayId);
  } catch (error) {
    console.error(`FloatWindow: 获取 display ${displayId} 失败，使用默认屏幕信息:`, error);
    return display.getDefaultDisplaySync();
  }
}

/** 计算指定屏幕下 HiCar Dock 的宽度（px）。 */
function getDockSize(screenInfo: display.Display): number {
  return calculateDockSize(screenInfo.width, screenInfo.height, screenInfo.densityPixels);
}

/** 计算悬浮图标态窗口的尺寸与位置（px，已按 vp 换算）。 */
function getFloatIconLayout(displayId: number): FloatIconLayout {
  const screenInfo = getScreenInfo(displayId);
  return calculateFloatIconLayout(
    screenInfo.width,
    screenInfo.height,
    screenInfo.densityPixels,
    getDockSize(screenInfo)
  );
}

/** 展开态应用列表的几何信息（px）。 */
interface ListLayout {
  x: number;
  y: number;
  width: number;
  height: number;
  rowCount: number;
}

/** 根据屏幕与实际密度计算展开态窗口的位置、尺寸与行数。 */
function calculateListLayout(screenInfo: display.Display): ListLayout {
  const margin = vp2pxFloor(LIST_MARGIN_VP, screenInfo.densityPixels);
  const dockWidth = getDockSize(screenInfo);

  // 左侧额外预留 HiCar Dock 宽度，避免列表与 Dock 重叠。
  const leftMargin = margin + dockWidth;
  const width = Math.max(1, screenInfo.width - leftMargin - margin);
  const height = Math.max(1, screenInfo.height - margin * 2);

  const isLandscape = screenInfo.width > screenInfo.height;
  const rowCount = isLandscape
    ? LIST_LANDSCAPE_ROWS
    : Math.max(1, Math.floor(height / vp2pxFloor(LIST_ITEM_HEIGHT_VP, screenInfo.densityPixels)));

  return { x: leftMargin, y: margin, width, height, rowCount };
}

/** 将 vp 向下取整换算为 px，用于窗口尺寸计算。 */
function vp2pxFloor(vp: number, density: number): number {
  return Math.floor(vp * density);
}

/**
 * 应用列表悬浮窗的生命周期管理。
 * 负责创建窗口、写入 AppStorage，并把窗口调到展开/收起所需的几何状态。
 */
class FloatWindowController {
  static create(context: common.UIAbilityContext, displayId: number): void {
    console.log(`FloatWindowController: 开始创建悬浮窗, displayId=${displayId}`);

    window.createWindow({
      name: "floatWindow",
      windowType: window.WindowType.TYPE_FLOAT,
      ctx: context,
      displayId: displayId
    }, (err, win) => {
      if (err.code != 0) {
        console.error("FloatWindowController: 创建悬浮窗失败:", JSON.stringify(err));
        return;
      }

      // 写入全局存储，供 FloatWindow 页面读取窗口实例与 displayId。
      AppStorage.setOrCreate(STORAGE_FLOAT_WINDOW, win);
      AppStorage.setOrCreate(STORAGE_DISPLAY_ID, displayId);

      // 初始为悬浮图标态。
      FloatWindowController.applyIconLayout(win, displayId);
      FloatWindowController.loadContent(win);
    });
  }

  /** 把窗口调整为悬浮图标态（尺寸、圆角、位置）。 */
  static applyIconLayout(win: window.Window, displayId: number): void {
    const layout = getFloatIconLayout(displayId);

    win.resize(layout.size, layout.size).catch((error: Error) => {
      console.error("FloatWindowController: 设置图标窗口大小失败:", JSON.stringify(error));
    });
    win.setWindowCornerRadius(layout.radius).catch((error: Error) => {
      console.error("FloatWindowController: 设置图标窗口圆角失败:", JSON.stringify(error));
    });
    win.moveWindowTo(layout.x, layout.y).catch((error: Error) => {
      console.error("FloatWindowController: 设置图标窗口位置失败:", JSON.stringify(error));
    });

    console.log(`FloatWindowController: 图标态 ${layout.size}x${layout.size}, 位置=(${layout.x},${layout.y})`);
  }

  /** 把窗口调整为展开态应用列表（尺寸、圆角、位置）。返回行数供页面渲染。 */
  static applyListLayout(win: window.Window, displayId: number): ListLayout {
    const layout = calculateListLayout(getScreenInfo(displayId));

    win.moveWindowTo(layout.x, layout.y).catch((error: Error) => {
      console.error("FloatWindowController: 移动列表窗口失败:", JSON.stringify(error));
    });
    win.resize(layout.width, layout.height).catch((error: Error) => {
      console.error("FloatWindowController: 调整列表窗口大小失败:", JSON.stringify(error));
    });
    win.setWindowCornerRadius(vp2pxFloor(LIST_CORNER_RADIUS_VP, getScreenInfo(displayId).densityPixels))
      .catch((error: Error) => {
        console.error("FloatWindowController: 设置列表窗口圆角失败:", JSON.stringify(error));
      });

    console.log(`FloatWindowController: 列表态 ${layout.width}x${layout.height}, ` +
      `位置=(${layout.x},${layout.y}), 行数=${layout.rowCount}`);
    return layout;
  }

  private static loadContent(win: window.Window): void {
    win.loadContent("window/FloatWindow", (err) => {
      if (err.code != 0) {
        console.error("FloatWindowController: 加载页面内容失败:", JSON.stringify(err));
        return;
      }
      win.showWindow((err) => {
        if (err.code != 0) {
          console.error("FloatWindowController: 显示窗口失败:", JSON.stringify(err));
        } else {
          console.log("FloatWindowController: 悬浮窗显示成功");
        }
      });
    });
  }
}

@Entry
@Component
struct FloatWindow {
  @State isExpanded: boolean = false;
  @State apps: HapApp[] = [];
  @State isLoading: boolean = false;
  private rowCount: number = 1;
  private displayId: number = 0;
  private currentWindow: window.Window | null = null;
  private isTouchOutsideListening: boolean = false;
  private readonly panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.All });
  private readonly touchOutsideCallback: Callback<void> = () => {
    this.collapseToListIcon();
  };

  // ==================== 生命周期 ====================

  aboutToAppear(): void {
    this.currentWindow = AppStorage.get<window.Window>(STORAGE_FLOAT_WINDOW) || null;
    this.displayId = AppStorage.get<number>(STORAGE_DISPLAY_ID) || 0;
    console.log(`FloatWindow: 页面加载, displayId=${this.displayId}, window=${this.currentWindow != null}`);
    this.loadAppsFromCache();
  }

  aboutToDisappear(): void {
    this.unregisterTouchOutsideListener();
  }

  // ==================== 数据 ====================

  private async loadAppsFromCache(): Promise<void> {
    this.isLoading = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const prefs = await preferences.getPreferences(context, APPS_PREFERENCES_NAME);
      const cached = await prefs.get(APPS_CACHE_KEY, '');
      if (cached) {
        this.apps = JSON.parse(cached as string) as HapApp[];
        console.log(`FloatWindow: 从缓存加载了 ${this.apps.length} 个应用`);
      } else {
        console.log("FloatWindow: 缓存为空");
      }
    } catch (error) {
      console.error("FloatWindow: 加载缓存失败", error);
    } finally {
      this.isLoading = false;
    }
  }

  // ==================== 展开 / 收起 ====================

  /** 点击悬浮图标：在图标态与应用列表之间切换。 */
  private toggleWindow(): void {
    if (this.isExpanded) {
      this.collapseToListIcon();
    } else {
      this.expandToList();
    }
  }

  /** 展开应用列表：隐藏应用悬浮窗、放大本窗口并监听外部点击。 */
  private expandToList(): void {
    if (!this.currentWindow) {
      console.warn("FloatWindow: currentWindow 为 null，无法展开列表");
      return;
    }

    // 列表覆盖屏幕，先隐藏已打开的应用窗口，再把列表提到前台。
    AppWindow.minimizeAll();
    this.currentWindow.showWindow((err) => {
      if (err.code != 0) {
        console.error("FloatWindow: 将列表窗口提到前台失败:", JSON.stringify(err));
      }
    });

    const layout = FloatWindowController.applyListLayout(this.currentWindow, this.displayId);
    this.rowCount = layout.rowCount;
    this.isExpanded = true;

    this.registerTouchOutsideListener();
  }

  /**
   * 收起应用列表并恢复悬浮图标态，统一处理的入口：
   * 外部点击、启动应用后、以及再次点击图标都走这里。
   */
  private collapseToListIcon(): void {
    if (!this.isExpanded) {
      this.unregisterTouchOutsideListener();
      return;
    }

    // 先切 UI 为图标态，再改窗口尺寸，避免中间态露出半张列表。
    this.isExpanded = false;
    this.unregisterTouchOutsideListener();
    AppWindow.showAll();

    if (!this.currentWindow) {
      this.currentWindow = AppStorage.get<window.Window>(STORAGE_FLOAT_WINDOW) || null;
    }
    if (!this.currentWindow) {
      console.warn("FloatWindow: currentWindow 为 null，无法恢复图标态");
      return;
    }
    FloatWindowController.applyIconLayout(this.currentWindow, this.displayId);
  }

  // ==================== 窗口外部点击监听 ====================

  private registerTouchOutsideListener(): void {
    if (this.isTouchOutsideListening || !this.currentWindow) {
      return;
    }
    try {
      this.currentWindow.on('touchOutside', this.touchOutsideCallback);
      this.isTouchOutsideListening = true;
      console.log("FloatWindow: 已注册 touchOutside 监听");
    } catch (error) {
      console.error("FloatWindow: 注册 touchOutside 监听失败:", JSON.stringify(error));
    }
  }

  private unregisterTouchOutsideListener(): void {
    if (!this.isTouchOutsideListening || !this.currentWindow) {
      return;
    }
    try {
      this.currentWindow.off('touchOutside', this.touchOutsideCallback);
      console.log("FloatWindow: 已解注册 touchOutside 监听");
    } catch (error) {
      console.error("FloatWindow: 解注册 touchOutside 监听失败:", JSON.stringify(error));
    } finally {
      this.isTouchOutsideListening = false;
    }
  }

  // ==================== 应用启动 ====================

  private launchApp(app: HapApp): void {
    console.log(`FloatWindow: 启动应用 ${app.name} (${app.package}), displayId=${this.displayId}`);
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      AppWindow.showAll();
      AppWindow.create(app.package, this.displayId, context);
      this.collapseToListIcon();
    } catch (error) {
      console.error(`FloatWindow: 创建应用窗口异常:`, JSON.stringify(error));
    }
  }

  // ==================== 图标拖动 ====================

  private onIconPanUpdate(event: GestureEvent): void {
    if (!this.currentWindow) {
      return;
    }
    const rect = this.currentWindow.getWindowProperties().windowRect;
    this.currentWindow.moveWindowTo(rect.left + event.offsetX, rect.top + event.offsetY)
      .catch((error: Error) => {
        console.error("FloatWindow: 拖动窗口失败:", JSON.stringify(error));
      });
  }

  // ==================== UI ====================

  build() {
    Stack() {
      if (this.isExpanded) {
        this.ListView()
      } else {
        this.IconView()
      }
    }
    .width('100%')
    .height('100%')
  }

  /** 展开态：应用列表。 */
  @Builder
  private ListView() {
    Column() {
      if (this.isLoading) {
        Column() {
          LoadingProgress()
            .width(40)
            .height(40)
            .color('#007DFF')
          Text('加载中...')
            .fontSize(12)
            .fontColor('#717786')
            .margin({ top: 8 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        Scroll(new Scroller()) {
          Grid() {
            ForEach(this.apps, (app: HapApp) => {
              GridItem() {
                this.AppItem(app)
              }
            }, (app: HapApp) => app.package)
          }
          .rowsTemplate(this.generateRowsTemplate())
          .columnsGap(12)
          .rowsGap(12)
          .width('100%')
        }
        .width('100%')
        .layoutWeight(1)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .padding({ left: 16, right: 16, top: 12, bottom: 12 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
    .borderRadius(20)
    .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.3)', offsetX: 0, offsetY: 4 })
  }

  /** 收起态：悬浮图标，支持拖动与点击展开。 */
  @Builder
  private IconView() {
    Column() {
      Image($r('app.media.ic_float_icon'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Contain)
        .borderRadius(8)
        .clip(true)
    }
    .padding(4)
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor(Color.Transparent)
    .borderRadius(16)
    .clip(true)
    .gesture(
      PanGesture(this.panOption)
        .onActionUpdate((event: GestureEvent) => {
          this.onIconPanUpdate(event);
        })
    )
    .onClick(() => {
      this.toggleWindow();
    })
  }

  @Builder
  private AppItem(app: HapApp) {
    Column({ space: 6 }) {
      Image(app.icon)
        .width(48)
        .height(48)
        .borderRadius(24)
      Text(app.name)
        .fontSize(12)
        .fontColor('#1C1B1B')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width(100)
    .padding(8)
    .onClick(() => {
      this.launchApp(app);
    })
  }

  private generateRowsTemplate(): string {
    return Array(this.rowCount).fill('1fr').join(' ');
  }
}

export class FloatWindowManager {
  static create(context: common.UIAbilityContext, displayId: number): void {
    FloatWindowController.create(context, displayId);
  }
}
