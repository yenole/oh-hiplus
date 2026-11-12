import window from "@ohos.window";
import display from '@ohos.display';
import Want from '@ohos.app.ability.Want';
import { common, StartOptions } from "@kit.AbilityKit";
import { JSON } from '@kit.ArkTS';
import hilog from '@ohos.hilog';

// 导入 libohos.so 的 agentClick 函数
import libohos from 'libohos.so';

@Entry
@Component
struct AppWindowContent {
  private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.All });
  private xComponentController: XComponentController = new XComponentController();
  @State packageName: string = "";
  @State windowName: string = "";
  @State displayId: number = 0;
  @State isAppLoaded: boolean = false;
  @State isMenuVisible: boolean = false;
  @State virtualWidth: number = 0;
  @State virtualHeight: number = 0;
  @State surfaceWidth: number = 0;
  @State surfaceHeight: number = 0;
  @State scaleRatio: number = 1; // 统一的缩放比例
  private currentWindow: window.Window | null = null;
  private touchStartX: number = 0;
  private touchStartY: number = 0;
  private touchLastX: number = 0;
  private touchLastY: number = 0;
  private touchStartTime: number = 0;
  private readonly touchMoveThreshold: number = 12; // vp，过滤轻微抖动
  private readonly swipeThreshold: number = 10; // vp
  private readonly longClickThreshold: number = 500; // ms

  private toVirtualX(xVp: number): number {
    return Math.floor(vp2px(xVp) * this.scaleRatio);
  }

  private toVirtualY(yVp: number): number {
    return Math.floor(vp2px(yVp) * this.scaleRatio);
  }

  private async forwardTouchClick(xVp: number, yVp: number): Promise<void> {
    const x = this.toVirtualX(xVp);
    const y = this.toVirtualY(yVp);
    try {
      const result: string = await libohos.displayClick(this.displayId, x, y);
      console.log(`AppWindowContent: displayClick(${x}, ${y}) 返回: ${result}`);
    } catch (error) {
      console.log(`AppWindowContent: 转发 click 失败:`, JSON.stringify(error));
    }
  }

  private async forwardTouchLongClick(xVp: number, yVp: number): Promise<void> {
    const x = this.toVirtualX(xVp);
    const y = this.toVirtualY(yVp);
    try {
      const result: string = await libohos.displayLongClick(this.displayId, x, y);
      console.log(`AppWindowContent: displayLongClick(${x}, ${y}) 返回: ${result}`);
    } catch (error) {
      console.log(`AppWindowContent: 转发 longclick 失败:`, JSON.stringify(error));
    }
  }

  private async forwardTouchSwipe(startXVp: number, startYVp: number, endXVp: number, endYVp: number, durationMs: number): Promise<void> {
    const startX = this.toVirtualX(startXVp);
    const startY = this.toVirtualY(startYVp);
    const endX = this.toVirtualX(endXVp);
    const endY = this.toVirtualY(endYVp);
    const distancePx = Math.sqrt((endX - startX) * (endX - startX) + (endY - startY) * (endY - startY));
    // displaySwipe 的 speed 使用 px/s；触摸耗时以 ms 计，至少按 1ms 避免除零。
    const speed = Math.max(1, Math.round(distancePx * 1000 / Math.max(1, durationMs)));
    try {
      const result: string = await libohos.displaySwipe(this.displayId, startX, startY, endX, endY, speed);
      console.log(`AppWindowContent: displaySwipe(${startX}, ${startY} -> ${endX}, ${endY}, speed=${speed}px/s) 返回: ${result}`);
    } catch (error) {
      console.log(`AppWindowContent: 转发 swipe 失败:`, JSON.stringify(error));
    }
  }

  aboutToAppear() {
    console.log("AppWindowContent: aboutToAppear - 页面即将加载");
    
    // 从 AppStorage 获取当前窗口名称
    this.windowName = AppStorage.get<string>("appWindow_current") || "";
    
    if (this.windowName) {
      // 使用窗口名称获取对应的包名和窗口实例
      this.packageName = AppStorage.get<string>(`appWindow_packageName_${this.windowName}`) || "";
      this.currentWindow = AppStorage.get<window.Window>(`appWindow_instance_${this.windowName}`) || null;
      console.log(`AppWindowContent: 窗口名: ${this.windowName}, 包名: ${this.packageName}`);
    } else {
      console.log(`AppWindowContent: 未找到窗口名称`);
    }
  }

  onPageShow() {
    console.log("AppWindowContent: onPageShow - 页面已显示");
  }

  onPageHide() {
    console.log("AppWindowContent: onPageHide - 页面已隐藏");
  }

  aboutToDisappear() {
    console.log("AppWindowContent: aboutToDisappear - 页面即将销毁");
    
    // 清理虚拟屏幕
    if (this.displayId > 0) {
      try {
        display.destroyVirtualScreen(this.displayId);
        console.log(`AppWindowContent: 虚拟屏幕已销毁 displayId=${this.displayId}`);
      } catch (error) {
        console.log(`AppWindowContent: 销毁虚拟屏幕失败:`, JSON.stringify(error));
      }
    }
  }

  private closeAppWindow(): void {
    this.isMenuVisible = false;
    if (!this.currentWindow) {
      console.log("AppWindowContent: 当前窗口实例不存在，无法关闭");
      return;
    }

    this.currentWindow.destroyWindow((err) => {
      if (err.code != 0) {
        console.log("AppWindowContent: 关闭窗口失败:", JSON.stringify(err));
      } else {
        console.log("AppWindowContent: 窗口已关闭");
        this.currentWindow = null;
      }
    });
  }

  async launchAppInVirtualScreen() {
    console.log(`AppWindowContent: 在虚拟屏幕中启动应用 ${this.packageName}`);

    try {
      // 获取主屏幕信息
      const mainDisplay = display.getDefaultDisplaySync();
      console.log(`AppWindowContent: 主屏幕信息: ${mainDisplay.width}x${mainDisplay.height}, density: ${mainDisplay.densityPixels}`);
      
      // 获取 XComponent 的 Surface ID 和尺寸
      const surfaceId = this.xComponentController.getXComponentSurfaceId();
      const surfaceRect = this.xComponentController.getXComponentSurfaceRect();
      this.surfaceWidth = surfaceRect.surfaceWidth;
      this.surfaceHeight = surfaceRect.surfaceHeight;
      console.log(`AppWindowContent: Surface ID: ${surfaceId}, Surface尺寸: ${this.surfaceWidth}x${this.surfaceHeight}`);

      // 判断主屏幕是横屏还是竖屏
      const isLandscape = mainDisplay.width > mainDisplay.height;
      
      // 虚拟屏幕的高度使用主屏幕的较大边（作为竖屏的高度）
      this.virtualHeight = isLandscape ? mainDisplay.width : mainDisplay.height;
      
      // 虚拟屏幕的宽度根据 Surface 的宽高比和虚拟屏幕高度计算
      // 保持 Surface 的宽高比例
      const surfaceAspectRatio = this.surfaceWidth / this.surfaceHeight;
      this.virtualWidth = Math.floor(this.virtualHeight * surfaceAspectRatio);
      
      // 计算统一的缩放比例（虚拟屏幕高度 / Surface高度）
      this.scaleRatio = this.virtualHeight / this.surfaceHeight;
      
      console.log(`AppWindowContent: 主屏幕方向: ${isLandscape ? '横屏' : '竖屏'}, Surface宽高比: ${surfaceAspectRatio.toFixed(2)}, 虚拟屏幕尺寸(竖屏): ${this.virtualWidth}x${this.virtualHeight}, 缩放比例: ${this.scaleRatio.toFixed(2)}`);

      // 创建虚拟屏幕
      this.displayId = await display.createVirtualScreen({
        name: `appWindow_${this.packageName}`,
        width: this.virtualWidth,
        height: this.virtualHeight,
        density: mainDisplay.densityPixels,
        surfaceId: surfaceId
      });

      console.log(`AppWindowContent: 虚拟屏幕创建成功, displayId: ${this.displayId}`);

      // 设置为独立显示
      await display.makeUnique(this.displayId);

      const virtualDisplay = display.getDisplayByIdSync(this.displayId);
      console.log(`AppWindowContent: 虚拟屏幕信息:`, 
        `density: ${virtualDisplay.densityPixels}, `,
        `size: ${virtualDisplay.width}x${virtualDisplay.height}`);

      // 在虚拟屏幕中启动应用
      // 模拟从桌面启动应用的方式
      const want: Want = {
        bundleName: this.packageName,
        action: "action.system.home",
        entities: ["entity.system.home"]
      };

      const startOptions: StartOptions = {
        displayId: this.displayId
      };

      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      context.startAbility(want, startOptions, (err) => {
        if (err.code != 0) {
          console.log(`AppWindowContent: 在虚拟屏幕启动应用失败:`, JSON.stringify(err));
        } else {
          console.log(`AppWindowContent: 应用已在虚拟屏幕中启动`);
          // 标记应用已加载，触发UI更新
          this.isAppLoaded = true;
        }
      });

    } catch (error) {
      console.log(`AppWindowContent: 启动应用异常:`, JSON.stringify(error));
    }
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      Column() {
        // XComponent 内容区域 - 始终存在但可能被遮挡
        XComponent({
          id: `appWindow_${this.packageName}`,
          type: XComponentType.SURFACE,
          controller: this.xComponentController
        })
        .width('100%')
        .height('100%')
        .onLoad(async () => {
          console.log("AppWindowContent: XComponent 加载完成，自动启动应用");
          // XComponent 加载完成后自动启动应用
          await this.launchAppInVirtualScreen();
        })
        .onTouch(async (event: TouchEvent) => {
          if (event.touches.length === 0) {
            return;
          }

          const touch = event.touches[0];
          const x = touch.x;
          const y = touch.y;

          if (event.type === TouchType.Down) {
            this.touchStartX = x;
            this.touchStartY = y;
            this.touchLastX = x;
            this.touchLastY = y;
            this.touchStartTime = Date.now();
            console.log(`AppWindowContent: touch down (${x.toFixed(1)}, ${y.toFixed(1)})`);
            return;
          }

          if (event.type === TouchType.Move) {
            this.touchLastX = x;
            this.touchLastY = y;
            return;
          }

          if (event.type === TouchType.Up) {
            const duration = Date.now() - this.touchStartTime;
            const deltaX = x - this.touchStartX;
            const deltaY = y - this.touchStartY;
            const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);

            if (distance >= this.swipeThreshold) {
              const direction = Math.abs(deltaX) > Math.abs(deltaY)
                ? (deltaX > 0 ? '右' : '左')
                : (deltaY > 0 ? '下' : '上');
              console.log(`AppWindowContent: 识别为 swipe-${direction}, 起点(${this.touchStartX.toFixed(1)}, ${this.touchStartY.toFixed(1)}), 终点(${x.toFixed(1)}, ${y.toFixed(1)}), 耗时${duration}ms`);
              await this.forwardTouchSwipe(this.touchStartX, this.touchStartY, x, y, duration);
            } else if (distance <= this.touchMoveThreshold && duration >= this.longClickThreshold) {
              console.log(`AppWindowContent: 识别为 longclick, 坐标(${x.toFixed(1)}, ${y.toFixed(1)}), 耗时${duration}ms`);
              await this.forwardTouchLongClick(x, y);
            } else if (distance <= this.touchMoveThreshold) {
              console.log(`AppWindowContent: 识别为 click, 坐标(${x.toFixed(1)}, ${y.toFixed(1)}), 耗时${duration}ms`);
              await this.forwardTouchClick(x, y);
            }
          }
        })
        
        // 如果应用未启动，显示遮罩层和图标
        if (!this.isAppLoaded) {
          Column() {
            Image($r('app.media.startIcon'))
              .width(80)
              .height(80)
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .backgroundColor('#FFFFFF')
          .position({ x: 0, y: 0 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor('#F5F5F5')
      .borderRadius(12)
      .clip(true)
      .shadow({
        radius: 20,
        color: 'rgba(0, 0, 0, 0.2)',
        offsetX: 0,
        offsetY: 4
      })

      // 顶部灰色拖动条 - 放在最上层，靠顶部
      Row() {
        // 中间的小灰条指示器
        Row()
          .width(60)
          .height(8)
          .borderRadius(4)
          .backgroundColor('#BBBBBB')
          .onClick(() => {
            this.isMenuVisible = !this.isMenuVisible;
            console.log(`AppWindowContent: ${this.isMenuVisible ? '打开' : '关闭'}头部菜单`);
          })
          .gesture(
            PanGesture(this.panOption)
              .onActionStart((event: GestureEvent) => {
                console.log("AppWindowContent: 开始拖动");
              })
              .onActionUpdate((event: GestureEvent) => {
                if (this.currentWindow) {
                  let properties = this.currentWindow.getWindowProperties();
                  let newX = properties.windowRect.left + event.offsetX;
                  let newY = properties.windowRect.top + event.offsetY;
                  this.currentWindow.moveWindowTo(newX, newY, (err) => {
                    if (err.code != 0) {
                      console.log("AppWindowContent: 移动窗口失败:", JSON.stringify(err));
                    }
                  });
                }
              })
              .onActionEnd((event: GestureEvent) => {
                console.log("AppWindowContent: 拖动结束");
              })
          )
      }
      .width(60)
      .height(20)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      if (this.isMenuVisible) {
        Column() {
          Image($r('app.media.ic_close'))
            .width(24)
            .height(24)
            .padding(4)
            .backgroundColor('#FFFFFF')
            .border({ width: 1, color: '#D9D9D9', radius: 6 })
            .onClick(() => this.closeAppWindow())
        }
        .width(120)
        .backgroundColor('#00000000')
        .position({ x: '50%', y: 40 })
      }
    }
    .width('100%')
    .height('100%')
  }
}
