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
  @State virtualWidth: number = 0;
  @State virtualHeight: number = 0;
  @State surfaceWidth: number = 0;
  @State surfaceHeight: number = 0;
  @State scaleRatio: number = 1; // 统一的缩放比例
  private currentWindow: window.Window | null = null;

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
          if (event.type === TouchType.Down) {
            const surfaceX_vp = event.touches[0].x;
            const surfaceY_vp = event.touches[0].y;
            
            // 将 vp 转换为 px（使用 display 的 densityPixels）
            const surfaceX_px = vp2px(surfaceX_vp);
            const surfaceY_px = vp2px(surfaceY_vp);
            
            // 使用统一的缩放比例计算虚拟屏幕坐标
            const virtualX = Math.floor(surfaceX_px * this.scaleRatio);
            const virtualY = Math.floor(surfaceY_px * this.scaleRatio);
            
            console.log(`AppWindowContent: 触摸事件 ${event.type}`);
            console.log(`  Surface坐标(vp): (${surfaceX_vp.toFixed(2)}, ${surfaceY_vp.toFixed(2)})`);
            console.log(`  Surface坐标(px): (${surfaceX_px}, ${surfaceY_px})`);
            console.log(`  虚拟屏幕坐标: (${virtualX}, ${virtualY}), 缩放比例: ${this.scaleRatio.toFixed(2)}`);
            
            // 将转换后的坐标转发到 libohos.so 的 agentClick
            try {
              const result:string = await libohos.displayClick(this.displayId, virtualX, virtualY);
              console.log(`AppWindowContent: agentClick 返回: ${result}`);
            } catch (error) {
              console.log(`AppWindowContent: 转发触摸事件失败:`, JSON.stringify(error));
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
          .height(5)
          .borderRadius(2.5)
          .backgroundColor('#BBBBBB')
      }
      .width('100%')
      .height(40)
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
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
    .width('100%')
    .height('100%')
  }
}
