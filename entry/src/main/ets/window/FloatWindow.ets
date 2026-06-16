import window from "@ohos.window";
import display from "@ohos.display";
import { common } from "@kit.AbilityKit";
import Want from "@ohos.app.ability.Want";
import { AppWindow } from "./AppWindow";
import preferences from '@ohos.data.preferences';
import { HapApp } from "libohos.so";

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
      
      // 设置窗口大小
      win.resize(80, 80, (err) => {
        if (err.code != 0) {
          console.log("FloatWindowManager: 设置窗口大小失败:", JSON.stringify(err));
        } else {
          console.log("FloatWindowManager: 设置窗口大小成功: 80x80");
        }
      });
      
      // 设置窗口位置（左侧增加80px间隔）
      win.moveWindowTo(180, 100, (err) => {
        if (err.code != 0) {
          console.log("FloatWindowManager: 设置窗口位置失败:", JSON.stringify(err));
        } else {
          console.log("FloatWindowManager: 设置窗口位置成功: (180, 100)");
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

  toggleWindow() {
    if (!this.currentWindow) {
      console.log("FloatWindow: currentWindow 为 null");
      return;
    }

    this.isExpanded = !this.isExpanded;

    if (this.isExpanded) {
      // 展开：显示应用列表，适配整个屏幕并预留间隔
      // 根据 displayId 获取对应屏幕信息
      let screenInfo: display.Display;
      if (this.displayId === 0) {
        screenInfo = display.getDefaultDisplaySync();
      } else {
        try {
          screenInfo = display.getDisplayByIdSync(this.displayId);
        } catch (error) {
          console.error(`FloatWindow: 获取 display ${this.displayId} 失败:`, error);
          screenInfo = display.getDefaultDisplaySync();
        }
      }
      
      const screenWidth = screenInfo.width;
      const screenHeight = screenInfo.height;
      
      // 判断横竖屏
      const isLandscape = screenWidth > screenHeight;
      
      // 预留边距
      const margin = 60;
      const leftMargin = margin + 160; // 左侧额外增加160px
      const windowWidth = screenWidth - leftMargin - margin; // 左侧用leftMargin，右侧用margin
      const windowHeight = screenHeight - margin * 2;
      
      // 计算可以显示的行数
      const titleBarHeight = 50;
      const contentHeight = windowHeight - titleBarHeight;
      
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
       this.currentWindow.setWindowCornerRadius(20).then(()=>{})
    } else {
      // 收起：恢复原来的小图标，并移动到初始位置
      this.currentWindow.resize(80, 80, (err) => {
        if (err.code != 0) {
          console.log("FloatWindow: 调整窗口大小失败:", JSON.stringify(err));
        } else {
          console.log("FloatWindow: 窗口大小恢复为 80x80");
        }
      });
      
      // 移动到初始位置（左侧180px）
      this.currentWindow.moveWindowTo(180, 100, (err) => {
        if (err.code != 0) {
          console.log("FloatWindow: 移动窗口失败:", JSON.stringify(err));
        } else {
          console.log("FloatWindow: 窗口移动到初始位置 (180, 100)");
        }
      });
    }
  }

  launchApp(app: HapApp) {
    console.log(`FloatWindow: 启动应用 ${app.name} (${app.package}) on displayId=${this.displayId}`);
    
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      // 使用 AppWindow 创建悬浮框来显示应用，使用相同的 displayId
      AppWindow.create(app.package, this.displayId, context);
      
      // 启动后收起悬浮窗
      this.isExpanded = false;
      this.currentWindow?.resize(80, 80, (err) => {
        if (err.code != 0) {
          console.log("FloatWindow: 调整窗口大小失败:", JSON.stringify(err));
        }
      });
      
      // 移动到初始位置（左侧180px）
      this.currentWindow?.moveWindowTo(180, 100, (err) => {
        if (err.code != 0) {
          console.log("FloatWindow: 移动窗口失败:", JSON.stringify(err));
        } else {
          console.log("FloatWindow: 窗口移动到初始位置 (180, 100)");
        }
      });
    } catch (error) {
      console.log(`FloatWindow: 创建应用窗口异常:`, JSON.stringify(error));
    }
  }

  build() {
    Stack() {
      if (this.isExpanded) {
        // 展开状态：显示应用列表
        Column() {
          // 标题栏
          Row() {
            Text('应用列表')
              .fontSize(18)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1B1B')
            
            Blank()
            
            Text('✕')
              .fontSize(24)
              .fontColor('#717786')
              .onClick(() => {
                console.log("FloatWindow: 关闭应用列表");
                this.toggleWindow();
              })
          }
          .width('100%')
          .height(50)
          .padding({ left: 16, right: 16 })
          .backgroundColor('#F5F5F5')
          
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
            .width(60)
            .height(60)
            .fillColor('#2196F3')
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .backgroundColor(Color.Transparent)
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
