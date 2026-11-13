import window from "@ohos.window";
import display from "@ohos.display";
import { common } from "@kit.AbilityKit";
import Want from "@ohos.app.ability.Want";
import { AppWindow } from "./AppWindow";
import preferences from '@ohos.data.preferences';
import { HapApp } from "libohos.so";
import { calculateDockSize, calculateFloatIconLayout, FloatIconLayout } from "../utils/HiCarDockUtils";

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

export class FloatWindowManager {
  private static windowInstance: window.Window | null = null;
  
  static create(context: common.UIAbilityContext, displayId: number): void {
    // 如果已经存在窗口实例，先销毁
    if (FloatWindowManager.windowInstance) {
      console.log("FloatWindowManager: 已存在悬浮窗实例，先销毁");
      FloatWindowManager.windowInstance.destroyWindow((err) => {
        if (err.code != 0) {
          console.log("FloatWindowManager: 销毁旧窗口失败:", JSON.stringify(err));
        } else {
          console.log("FloatWindowManager: 旧窗口已销毁");
        }
      });
      FloatWindowManager.windowInstance = null;
    }
    
    console.log(`FloatWindowManager: 开始创建悬浮窗... displayId=${displayId}`);
    
    window.createWindow({
      name: "floatWindow",
      windowType: window.WindowType.TYPE_FLOAT,
      ctx: context,
      displayId: displayId
    }, (err, win) => {
      console.log("FloatWindowManager: createWindow 回调执行");
      
      if (err.code != 0) {
        console.log("FloatWindowManager: 创建悬浮窗失败:", JSON.stringify(err));
        return;
      }
      
      console.log("FloatWindowManager: 悬浮窗创建成功，开始设置窗口属性");
      
      // 保存窗口实例
      FloatWindowManager.windowInstance = win;
      
      // 将窗口实例和 displayId 保存到全局存储
      AppStorage.setOrCreate("floatWindow", win);
      AppStorage.setOrCreate("floatWindowDisplayId", displayId);
      console.log(`FloatWindowManager: 窗口实例已保存到 AppStorage, displayId=${displayId}`);
      
      // 设置窗口大小：图标边长按 vp 换算为 px，保证不同分辨率下物理尺寸一致。
      const iconLayout = getFloatIconLayout(displayId);
      win.resize(iconLayout.size, iconLayout.size, (err) => {
        if (err.code != 0) {
          console.log("FloatWindowManager: 设置窗口大小失败:", JSON.stringify(err));
        } else {
          console.log(`FloatWindowManager: 设置窗口大小成功: ${iconLayout.size}x${iconLayout.size}`);
        }
      });
      // 设置系统悬浮窗圆角，确保窗口本身的透明区域也被裁切为圆角。
      win.setWindowCornerRadius(iconLayout.radius).catch((error: Error) => {
        console.log("FloatWindowManager: 设置悬浮窗圆角失败:", JSON.stringify(error));
      });

      // 图标位置：Dock 右侧 + 顶部间距，均按 vp 换算并限制在屏幕内。
      win.moveWindowTo(iconLayout.x, iconLayout.y, (err) => {
        if (err.code != 0) {
          console.log("FloatWindowManager: 设置窗口位置失败:", JSON.stringify(err));
        } else {
          console.log(`FloatWindowManager: 设置窗口位置成功: (${iconLayout.x}, ${iconLayout.y})`);
        }
      });
      
      // 加载悬浮窗内容
      console.log("FloatWindowManager: 开始加载页面内容: window/FloatWindow");
      win.loadContent("window/FloatWindow", (err) => {
        if (err.code != 0) {
          console.log("FloatWindowManager: 加载页面内容失败:", JSON.stringify(err));
          return;
        }
        console.log("FloatWindowManager: 页面内容加载成功");
        
        // 显示窗口
        win.showWindow((err) => {
          if (err.code != 0) {
            console.log("FloatWindowManager: 显示窗口失败:", JSON.stringify(err));
          } else {
            console.log("FloatWindowManager: 悬浮窗显示成功");
          }
        });
      });
    });
  }
}

@Entry
@Component
struct FloatWindow {
  private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.All });
  private currentWindow: window.Window | null = null;
  @State isExpanded: boolean = false;
  @State apps: HapApp[] = [];
  @State isLoading: boolean = false;
  @State rowCount: number = 1; // 可以显示的行数
  private displayId: number = 0; // FloatWindow 的 displayId
  private readonly CACHE_KEY = 'hap_apps_cache';
  // 应用列表展开时注册的窗口外部点击回调，收起时需要解注册。
  private touchOutsideCallback: Callback<void> = () => {
    console.log("FloatWindow: 检测到窗口外部点击，收起应用列表");
    this.collapseToListIcon();
  };
  private isTouchOutsideListening: boolean = false;

  aboutToAppear() {
    console.log("FloatWindow: aboutToAppear - 页面即将加载");
    // 从 AppStorage 获取窗口实例
    this.currentWindow = AppStorage.get<window.Window>("floatWindow") || null;
    console.log("FloatWindow: 从 AppStorage 获取窗口:", this.currentWindow != null);
    
    // 获取 displayId
    this.displayId = AppStorage.get<number>("floatWindowDisplayId") || 0;
    console.log(`FloatWindow: 获取 displayId=${this.displayId}`);
    
    // 加载应用列表
    this.loadAppsFromCache();
  }

  onPageShow() {
    console.log("FloatWindow: onPageShow - 页面已显示");
  }

  onPageHide() {
    console.log("FloatWindow: onPageHide - 页面已隐藏");
  }

  aboutToDisappear() {
    console.log("FloatWindow: aboutToDisappear - 页面即将销毁");
    this.unregisterTouchOutsideListener();
  }

  /**
   * 注册窗口外部点击监听：应用列表展开时，点击窗口之外区域收起列表。
   */
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

  /**
   * 解注册窗口外部点击监听，避免列表收起后仍然响应外部点击。
   */
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

  private async loadAppsFromCache(): Promise<void> {
    this.isLoading = true;
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const prefs = await preferences.getPreferences(context, 'hap_apps_storage');
      
      const cachedData = await prefs.get(this.CACHE_KEY, '');
      
      if (cachedData) {
        this.apps = JSON.parse(cachedData as string) as HapApp[];
        console.log(`FloatWindow: 从缓存加载了 ${this.apps.length} 个应用`);
      } else {
        console.log('FloatWindow: 缓存为空');
      }
    } catch (error) {
      console.error('FloatWindow: 加载缓存失败', error);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 收起应用列表并恢复悬浮图标样式（尺寸、圆角、位置、监听）。
   * 外部点击、启动应用后、以及再次点击图标都走这里，保证行为一致。
   */
  private collapseToListIcon(): void {
    if (!this.currentWindow) {
      this.currentWindow = AppStorage.get<window.Window>("floatWindow") || null;
    }
    if (!this.currentWindow) {
      console.log("FloatWindow: currentWindow 为 null，无法恢复图标态");
      this.isExpanded = false;
      return;
    }

    // 先切 UI 为图标态，再改窗口尺寸，避免中间态露出半张列表。
    this.isExpanded = false;
    this.unregisterTouchOutsideListener();
    AppWindow.showAll();

    const iconLayout = getFloatIconLayout(this.displayId);
    this.currentWindow.resize(iconLayout.size, iconLayout.size, (err) => {
      if (err.code != 0) {
        console.log("FloatWindow: 调整窗口大小失败:", JSON.stringify(err));
      } else {
        console.log(`FloatWindow: 窗口大小恢复为 ${iconLayout.size}x${iconLayout.size}`);
      }
    });
    this.currentWindow.setWindowCornerRadius(iconLayout.radius).catch((error: Error) => {
      console.log("FloatWindow: 恢复悬浮窗圆角失败:", JSON.stringify(error));
    });

    // 移动到 Dock 右侧的初始位置。
    this.currentWindow.moveWindowTo(iconLayout.x, iconLayout.y, (err) => {
      if (err.code != 0) {
        console.log("FloatWindow: 移动窗口失败:", JSON.stringify(err));
      } else {
        console.log(`FloatWindow: 窗口移动到初始位置 (${iconLayout.x}, ${iconLayout.y})`);
      }
    });
  }

  toggleWindow() {
    if (!this.currentWindow) {
      console.log("FloatWindow: currentWindow 为 null");
      return;
    }

    this.isExpanded = !this.isExpanded;

    if (this.isExpanded) {
      // 隐藏所有已打开的应用悬浮窗口。
      AppWindow.minimizeAll();
      // 确保应用列表悬浮窗口显示在前台。
      this.currentWindow.showWindow((err) => {
        if (err.code != 0) {
          console.error("FloatWindow: 将应用列表窗口提到前台失败:", JSON.stringify(err));
        }
      });
      // 展开：显示应用列表，适配整个屏幕并预留间隔
      const screenInfo = getScreenInfo(this.displayId);

      const screenWidth = screenInfo.width;
      const screenHeight = screenInfo.height;
      
      // 判断横竖屏
      const isLandscape = screenWidth > screenHeight;
      
      // 预留边距
      const margin = 60;
      const dockWidth = getDockSize(screenInfo);
      const leftMargin = margin + dockWidth; // 左侧额外预留 HiCar Dock 宽度
      const windowWidth = screenWidth - leftMargin - margin; // 左侧用leftMargin，右侧用margin
      const windowHeight = screenHeight - margin * 2;
      
      // 计算可以显示的行数（已移除标题栏，列表直接占满窗口高度）
      const contentHeight = windowHeight;
      
      // 根据横竖屏和容器高度动态计算行数
      // 横屏：显示3行，竖屏：显示更多行
      if (isLandscape) {
        this.rowCount = 3; // 横屏固定3行
      } else {
        // 竖屏根据高度计算，每个应用项约82px
        const appItemHeight = 82; // 48图标 + 6间距 + 12文字 + 16padding
        this.rowCount = Math.floor(contentHeight / appItemHeight);
      }
      
      console.log(`FloatWindow: 屏幕=${screenWidth}x${screenHeight}, ${isLandscape ? '横屏' : '竖屏'}, displayId=${this.displayId}, 左边距=${leftMargin}, 右边距=${margin}, 窗口=${windowWidth}x${windowHeight}, 位置=(${leftMargin},${margin}), 行数=${this.rowCount}`);
      
      // 左侧使用leftMargin，上下使用margin
      const newX = leftMargin;
      const newY = margin;

      // 先移动窗口位置，再调整大小
      this.currentWindow.moveWindowTo(newX, newY, (err) => {
        if (err.code != 0) {
          console.log("FloatWindow: 移动窗口失败:", JSON.stringify(err));
        } else {
          console.log(`FloatWindow: 窗口移动到 (${newX},${newY})`);
        }
      });

      this.currentWindow.resize(windowWidth, windowHeight, (err) => {
        if (err.code != 0) {
          console.log("FloatWindow: 调整窗口大小失败:", JSON.stringify(err));
        } else {
          console.log(`FloatWindow: 窗口大小调整为 ${windowWidth}x${windowHeight}`);
        }
      });
      // 设置窗口圆角
       this.currentWindow.setWindowCornerRadius(8).then(()=>{})
      // 应用列表展示期间监听窗口外部点击，点击列表外区域自动收起。
      this.registerTouchOutsideListener();
    } else {
      // 收起：恢复悬浮图标样式，统一由 collapseToListIcon 处理。
      this.isExpanded = true;
      this.collapseToListIcon();
    }
  }

  launchApp(app: HapApp) {
    console.log(`FloatWindow: 启动应用 ${app.name} (${app.package}) on displayId=${this.displayId}`);
    
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      // 选择应用时恢复现有窗口，再创建并显示所选应用。
      AppWindow.showAll();
      // 使用 AppWindow 创建悬浮框来显示应用，使用相同的 displayId
      AppWindow.create(app.package, this.displayId, context);
      
      // 启动后收起应用列表，恢复悬浮图标样式。
      this.collapseToListIcon();
    } catch (error) {
      console.log(`FloatWindow: 创建应用窗口异常:`, JSON.stringify(error));
    }
  }

  build() {
    Stack() {
      if (this.isExpanded) {
        // 展开状态：显示应用列表
        Column() {
          // 应用列表
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
      } else {
        // 收起状态：显示悬浮图标
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
            .onActionStart((event: GestureEvent) => {
              console.log("FloatWindow: 开始拖动");
            })
            .onActionUpdate((event: GestureEvent) => {
              if (this.currentWindow) {
                let properties = this.currentWindow.getWindowProperties();
                let newX = properties.windowRect.left + event.offsetX;
                let newY = properties.windowRect.top + event.offsetY;
                
                this.currentWindow.moveWindowTo(newX, newY, (err) => {
                  if (err.code != 0) {
                    console.log("FloatWindow: 移动窗口失败:", JSON.stringify(err));
                  }
                });
              }
            })
            .onActionEnd((event: GestureEvent) => {
              console.log("FloatWindow: 拖动结束");
            })
        )
        .onClick(() => {
          console.log("FloatWindow: 点击图标，切换窗口状态");
          this.toggleWindow();
        })
      }
    }
    .width('100%')
    .height('100%')
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
    // 根据行数生成模板，例如 rowCount=3 -> '1fr 1fr 1fr'
    const rows = Array(this.rowCount).fill('1fr').join(' ');
    console.log(`FloatWindow: 生成行模板: ${rows}`);
    return rows;
  }
}
