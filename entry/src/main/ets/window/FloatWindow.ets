import window from "@ohos.window";
import display from "@ohos.display";
import { common } from "@kit.AbilityKit";
import { FloatAppListWindowManager } from "./FloatAppListWindow";
import { calculateDockSize, calculateFloatIconLayout, FloatIconLayout } from "../utils/HiCarDockUtils";

const STORAGE_FLOAT_WINDOW: string = 'floatWindow';
const STORAGE_DISPLAY_ID: string = 'floatWindowDisplayId';

function getFloatIconLayout(displayId: number): FloatIconLayout {
  let screenInfo: display.Display;
  try {
    screenInfo = displayId === 0 ? display.getDefaultDisplaySync() : display.getDisplayByIdSync(displayId);
  } catch (error) {
    console.error(`FloatWindow: 获取 display ${displayId} 失败，使用默认屏幕信息:`, error);
    screenInfo = display.getDefaultDisplaySync();
  }
  const dockSize = calculateDockSize(screenInfo.width, screenInfo.height, screenInfo.densityPixels);
  return calculateFloatIconLayout(screenInfo.width, screenInfo.height, screenInfo.densityPixels, dockSize);
}

class FloatWindowController {
  static create(context: common.UIAbilityContext, displayId: number): void {
    window.createWindow({
      name: "floatWindow",
      windowType: window.WindowType.TYPE_FLOAT,
      ctx: context,
      displayId: displayId
    }, (err, win) => {
      if (err.code != 0) {
        console.error("FloatWindowController: 创建图标悬浮窗失败:", JSON.stringify(err));
        return;
      }
      AppStorage.setOrCreate(STORAGE_FLOAT_WINDOW, win);
      AppStorage.setOrCreate(STORAGE_DISPLAY_ID, displayId);
      FloatWindowController.applyIconLayout(win, displayId);
      win.loadContent("window/FloatWindow", (loadErr) => {
        if (loadErr.code != 0) {
          console.error("FloatWindowController: 加载图标页面失败:", JSON.stringify(loadErr));
          return;
        }
        win.showWindow((showErr) => {
          if (showErr.code != 0) {
            console.error("FloatWindowController: 显示图标窗口失败:", JSON.stringify(showErr));
          }
        });
      });
    });
  }

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
  }
}

@Entry
@Component
struct FloatWindow {
  private displayId: number = 0;
  private currentWindow: window.Window | null = null;
  private readonly panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.All });

  aboutToAppear(): void {
    this.currentWindow = AppStorage.get<window.Window>(STORAGE_FLOAT_WINDOW) || null;
    this.displayId = AppStorage.get<number>(STORAGE_DISPLAY_ID) || 0;
  }

  private onIconPanUpdate(event: GestureEvent): void {
    if (!this.currentWindow) {
      return;
    }
    const rect = this.currentWindow.getWindowProperties().windowRect;
    this.currentWindow.moveWindowTo(rect.left + event.offsetX, rect.top + event.offsetY)
      .catch((error: Error) => {
        console.error("FloatWindow: 拖动图标窗口失败:", JSON.stringify(error));
      });
  }

  private openAppList(): void {
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    FloatAppListWindowManager.show(context, this.displayId);
  }

  build() {
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
        .onActionUpdate((event: GestureEvent) => this.onIconPanUpdate(event))
    )
    .onClick(() => this.openAppList())
  }
}

export class FloatWindowManager {
  static create(context: common.UIAbilityContext, displayId: number): void {
    FloatWindowController.create(context, displayId);
  }

  static show(onShown?: () => void): void {
    const iconWindow = AppStorage.get<window.Window>(STORAGE_FLOAT_WINDOW);
    if (!iconWindow) {
      onShown?.();
      return;
    }
    iconWindow.showWindow((err) => {
      if (err.code != 0) {
        console.error("FloatWindowManager: 显示图标窗口失败:", JSON.stringify(err));
      }
      onShown?.();
    });
  }
}
