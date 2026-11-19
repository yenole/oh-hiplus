import window from "@ohos.window";
import display from '@ohos.display';
import Want from '@ohos.app.ability.Want';
import { common, StartOptions } from "@kit.AbilityKit";
import { JSON } from '@kit.ArkTS';
import hilog from '@ohos.hilog';

// 导入 libohos.so 的 agentClick 函数
import libohos from 'libohos.so';
import { calculateDockSize } from '../utils/HiCarDockUtils';

@Entry
@Component
struct AppWindowContent {
  private panOption: PanGestureOptions = new PanGestureOptions({ direction: PanDirection.All });
  private xComponentController: XComponentController = new XComponentController();
  @State packageName: string = "";
  @State windowName: string = "";
  @State displayId: number = 0;
  private hostDisplayId: number = 0;
  @State isAppLoaded: boolean = false;
  @State isMenuVisible: boolean = false;
  @State isFullscreen: boolean = false;
  @State virtualWidth: number = 0;
  @State virtualHeight: number = 0;
  @State surfaceWidth: number = 0;
  @State surfaceHeight: number = 0;
  @State scaleRatio: number = 1; // 统一的缩放比例
  private currentWindow: window.Window | null = null;
  private touchStartX: number = 0;
  private touchStartY: number = 0;
  private resizeStartDisplayX: number = 0;
  private resizeStartDisplayY: number = 0;
  private touchStartTime: number = 0;
  private swipeTriggered: boolean = false;
  private swipeAnchorX: number = 0;
  private swipeAnchorY: number = 0;
  private swipeAnchorTime: number = 0;
  private readonly touchMoveThreshold: number = 12; // vp，点击允许的最大移动距离
  private readonly swipeInterval: number = 100; // ms
  private readonly longClickThreshold: number = 500; // ms
  private readonly minWindowWidthVp: number = 240;
  private readonly minWindowHeightVp: number = 320;
  private resizeStartWidth: number = 0;
  private resizeStartHeight: number = 0;
  private resizeStartX: number = 0;
  private resizeStartY: number = 0;
  private resizeMode: string = 'right';
  private resizeEdgeCandidate: string = '';
  private resizeGestureActive: boolean = false;
  private resizePending: boolean = false;
  private windowResizeInFlight: boolean = false;
  private pendingWindowWidth: number = 0;
  private pendingWindowHeight: number = 0;
  private pendingWindowX: number = 0;
  private pendingWindowY: number = 0;
  private pendingWindowMove: boolean = false;
  private restoreWindowX: number = 0;
  private restoreWindowY: number = 0;
  private restoreWindowWidth: number = 0;
  private restoreWindowHeight: number = 0;

  private getHostDisplayInfo(): display.Display {
    try {
      return this.hostDisplayId > 0
        ? display.getDisplayByIdSync(this.hostDisplayId)
        : display.getDefaultDisplaySync();
    } catch (error) {
      console.error(`AppWindowContent: 获取宿主屏幕 ${this.hostDisplayId} 失败:`, JSON.stringify(error));
      return display.getDefaultDisplaySync();
    }
  }

  private toVirtualX(xVp: number): number {
    return Math.floor(vp2px(xVp) * this.scaleRatio);
  }

  private toVirtualY(yVp: number): number {
    return Math.floor(vp2px(yVp) * this.scaleRatio);
  }

  private beginResize(mode: string): void {
    if (!this.currentWindow) {
      return;
    }
    const rect = this.currentWindow.getWindowProperties().windowRect;
    this.resizeStartWidth = rect.width;
    this.resizeStartHeight = rect.height;
    this.resizeStartX = rect.left;
    this.resizeStartY = rect.top;
    this.resizeMode = mode;
  }

  private resizeCurrentWindow(deltaXPx: number, deltaYPx: number): void {
    if (!this.currentWindow) {
      return;
    }
    try {
      const screen = this.getHostDisplayInfo();
      const density = screen.densityPixels;
      const dx = Math.floor(deltaXPx * density);
      const dy = Math.floor(deltaYPx * density);
      const minWidth = Math.floor(this.minWindowWidthVp * density);
      const minHeight = Math.floor(this.minWindowHeightVp * density);
      let width = this.resizeStartWidth;
      let height = this.resizeStartHeight;
      let x = this.resizeStartX;
      if (this.resizeMode === 'left') {
        width = Math.max(minWidth, Math.min(this.resizeStartX + this.resizeStartWidth,
          this.resizeStartWidth - dx));
        x = this.resizeStartX + this.resizeStartWidth - width;
      } else if (this.resizeMode === 'right') {
        width = Math.max(minWidth, Math.min(screen.width - this.resizeStartX,
          this.resizeStartWidth + dx));
      } else {
        height = Math.max(minHeight, Math.min(screen.height - this.resizeStartY,
          this.resizeStartHeight + dy));
      }
      this.pendingWindowWidth = width;
      this.pendingWindowHeight = height;
      this.pendingWindowX = x;
      this.pendingWindowY = this.resizeStartY;
      this.pendingWindowMove = this.resizeMode === 'left';
      this.applyPendingWindowResize();
    } catch (error) {
      console.error("AppWindowContent: 获取屏幕尺寸失败:", JSON.stringify(error));
    }
  }

  private async applyPendingWindowResize(): Promise<void> {
    if (this.windowResizeInFlight || !this.currentWindow || this.pendingWindowWidth <= 0 || this.pendingWindowHeight <= 0) {
      return;
    }
    this.windowResizeInFlight = true;
    try {
      while (this.currentWindow && this.pendingWindowWidth > 0 && this.pendingWindowHeight > 0) {
        const width = this.pendingWindowWidth;
        const height = this.pendingWindowHeight;
        const x = this.pendingWindowX;
        const y = this.pendingWindowY;
        const move = this.pendingWindowMove;
        this.pendingWindowWidth = 0;
        this.pendingWindowHeight = 0;
        await this.currentWindow.resize(width, height);
        if (move) {
          await this.currentWindow.moveWindowTo(x, y);
        }
      }
    } catch (error) {
      console.error("AppWindowContent: 调整窗口大小失败:", JSON.stringify(error));
    } finally {
      this.windowResizeInFlight = false;
      if (this.pendingWindowWidth > 0 && this.pendingWindowHeight > 0) {
        this.applyPendingWindowResize();
      }
    }
  }

  private async toggleFullscreen(): Promise<void> {
    if (!this.currentWindow) {
      return;
    }
    try {
      const screen = this.getHostDisplayInfo();
      const dockWidth = calculateDockSize(screen.width, screen.height, screen.densityPixels);
      const availableWidth = Math.max(1, screen.width - dockWidth);
      if (!this.isFullscreen) {
        const rect = this.currentWindow.getWindowProperties().windowRect;
        this.restoreWindowX = rect.left;
        this.restoreWindowY = rect.top;
        this.restoreWindowWidth = rect.width;
        this.restoreWindowHeight = rect.height;
        await this.currentWindow.moveWindowTo(dockWidth, 0);
        await this.currentWindow.resize(availableWidth, screen.height);
        this.isFullscreen = true;
      } else {
        await this.currentWindow.moveWindowTo(this.restoreWindowX, this.restoreWindowY);
        await this.currentWindow.resize(this.restoreWindowWidth, this.restoreWindowHeight);
        this.isFullscreen = false;
      }
      this.isMenuVisible = false;
      await new Promise<void>((resolve: () => void) => setTimeout(resolve, 100));
      await this.updateVirtualDisplaySize();
    } catch (error) {
      console.error("AppWindowContent: 切换全屏状态失败:", JSON.stringify(error));
    }
  }

  private async updateVirtualDisplaySize(): Promise<void> {
    if (!this.currentWindow) {
      return;
    }
    const screenBounds = this.getHostDisplayInfo();
    const dockWidth = calculateDockSize(screenBounds.width, screenBounds.height, screenBounds.densityPixels);
    const availableWidth = Math.max(1, screenBounds.width - dockWidth);
    const windowRect = this.currentWindow.getWindowProperties().windowRect;
    this.isFullscreen = windowRect.left <= dockWidth && windowRect.top <= 0 &&
      windowRect.width >= availableWidth && windowRect.height >= screenBounds.height;
    if (this.displayId <= 0 || this.resizePending) {
      return;
    }
    this.resizePending = true;
    let nextDisplayId: number = 0;
    let stage: string = '读取 Surface 尺寸';
    try {
      const surfaceId = this.xComponentController.getXComponentSurfaceId();
      const surfaceRect = this.xComponentController.getXComponentSurfaceRect();
      const nextSurfaceWidth = surfaceRect.surfaceWidth;
      const nextSurfaceHeight = surfaceRect.surfaceHeight;
      if (nextSurfaceWidth <= 0 || nextSurfaceHeight <= 0 ||
        (nextSurfaceWidth === this.surfaceWidth && nextSurfaceHeight === this.surfaceHeight)) {
        return;
      }

      const mainDisplay = display.getDefaultDisplaySync();
      const isLandscape = mainDisplay.width > mainDisplay.height;
      const nextVirtualHeight = isLandscape ? mainDisplay.width : mainDisplay.height;
      const nextVirtualWidth = Math.floor(nextVirtualHeight * nextSurfaceWidth / nextSurfaceHeight);
      const previousDisplayId = this.displayId;
      let previousDisplayDestroyed: boolean = false;
      const createVirtualScreen = async (): Promise<number> => {
        return await display.createVirtualScreen({
          name: `appWindow_${this.packageName}_${Date.now()}`,
          width: nextVirtualWidth,
          height: nextVirtualHeight,
          density: mainDisplay.densityPixels,
          surfaceId: surfaceId
        });
      };
      stage = '创建新虚拟屏幕';
      console.info(`AppWindowContent: 创建新虚拟屏幕，Surface=${nextSurfaceWidth}x${nextSurfaceHeight}, ` +
        `display=${nextVirtualWidth}x${nextVirtualHeight}, oldDisplayId=${previousDisplayId}`);
      try {
        nextDisplayId = await createVirtualScreen();
      } catch (createError) {
        const errorText = JSON.stringify(createError);
        console.error("AppWindowContent: 首次创建新虚拟屏幕失败:", errorText);
        if (!errorText.includes('1400001')) {
          console.error(`AppWindowContent: 阶段“${stage}”失败，Surface=${nextSurfaceWidth}x${nextSurfaceHeight}:`, errorText);
          return;
        }
        stage = '释放旧虚拟屏幕后重试创建';
        await display.destroyVirtualScreen(previousDisplayId);
        previousDisplayDestroyed = true;
        nextDisplayId = await createVirtualScreen();
      }
      stage = '设置新虚拟屏幕为独立显示';
      await display.makeUnique(nextDisplayId);

      const want: Want = {
        bundleName: this.packageName,
        action: "action.system.home",
        entities: ["entity.system.home"]
      };
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      stage = '在新虚拟屏幕启动应用';
      await context.startAbility(want, { displayId: nextDisplayId });

      this.surfaceWidth = nextSurfaceWidth;
      this.surfaceHeight = nextSurfaceHeight;
      this.virtualWidth = nextVirtualWidth;
      this.virtualHeight = nextVirtualHeight;
      this.scaleRatio = nextVirtualHeight / nextSurfaceHeight;
      this.displayId = nextDisplayId;

      if (!previousDisplayDestroyed) {
        stage = '销毁旧虚拟屏幕';
        try {
          await display.destroyVirtualScreen(previousDisplayId);
          console.info(`AppWindowContent: 旧虚拟屏幕 ${previousDisplayId} 已销毁`);
        } catch (error) {
          console.error(`AppWindowContent: 销毁旧虚拟屏幕 ${previousDisplayId} 失败:`, JSON.stringify(error));
        }
      }
      console.info(`AppWindowContent: 应用已切换到新虚拟屏幕 ${nextVirtualWidth}x${nextVirtualHeight}`);
    } catch (error) {
      console.error(`AppWindowContent: 阶段“${stage}”失败，Surface=${this.surfaceWidth}x${this.surfaceHeight}:`, JSON.stringify(error));
      if (nextDisplayId > 0 && nextDisplayId !== this.displayId) {
        try {
          await display.destroyVirtualScreen(nextDisplayId);
          console.info(`AppWindowContent: 已清理未完成切换的新虚拟屏幕 ${nextDisplayId}`);
        } catch (cleanupError) {
          console.error(`AppWindowContent: 清理新虚拟屏幕 ${nextDisplayId} 失败:`, JSON.stringify(cleanupError));
        }
      }
    } finally {
      this.resizePending = false;
    }
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
    const speed = Math.max(1, Math.round(distancePx * 1000 / Math.max(1, durationMs) * 1.8));
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
      this.hostDisplayId = AppStorage.get<number>(`appWindow_hostDisplayId_${this.windowName}`) || 0;
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
          const displayX = touch.displayX;
          const displayY = touch.displayY;

          if (event.type === TouchType.Down) {
            this.touchStartX = x;
            this.touchStartY = y;
            this.resizeStartDisplayX = displayX;
            this.resizeStartDisplayY = displayY;
            this.touchStartTime = Date.now();
            this.swipeAnchorX = x;
            this.swipeAnchorY = y;
            this.swipeAnchorTime = this.touchStartTime;
            this.swipeTriggered = false;
            this.resizeGestureActive = false;
            this.resizeEdgeCandidate = '';
            if (!this.isFullscreen && this.currentWindow) {
              const density = this.getHostDisplayInfo().densityPixels;
              const rect = this.currentWindow.getWindowProperties().windowRect;
              const widthVp = rect.width / density;
              const heightVp = rect.height / density;
              const edgeBandVp = 24;
              if (y >= heightVp - edgeBandVp) {
                this.resizeEdgeCandidate = 'bottom';
              } else if (x <= edgeBandVp) {
                this.resizeEdgeCandidate = 'left';
              } else if (x >= widthVp - edgeBandVp) {
                this.resizeEdgeCandidate = 'right';
              }
              if (this.resizeEdgeCandidate) {
                this.beginResize(this.resizeEdgeCandidate);
              }
            }
            console.log(`AppWindowContent: touch down (${x.toFixed(1)}, ${y.toFixed(1)})`);
            return;
          }

          if (event.type === TouchType.Move) {
            const resizeDeltaX = displayX - this.resizeStartDisplayX;
            const resizeDeltaY = displayY - this.resizeStartDisplayY;
            const resizeDistance = Math.sqrt(resizeDeltaX * resizeDeltaX + resizeDeltaY * resizeDeltaY);
            const resizeThresholdVp = this.touchMoveThreshold;
            if (this.resizeGestureActive ||
              (this.resizeEdgeCandidate !== '' && resizeDistance > resizeThresholdVp)) {
              this.resizeGestureActive = true;
              this.resizeCurrentWindow(resizeDeltaX, resizeDeltaY);
              return;
            }
            const now = Date.now();
            const deltaX = x - this.swipeAnchorX;
            const deltaY = y - this.swipeAnchorY;
            const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);
            if (now - this.swipeAnchorTime >= this.swipeInterval && distance > this.touchMoveThreshold) {
              const swipeStartX = this.swipeAnchorX;
              const swipeStartY = this.swipeAnchorY;
              const swipeDuration = Math.max(1, now - this.swipeAnchorTime);
              this.swipeTriggered = true;
              this.swipeAnchorX = x;
              this.swipeAnchorY = y;
              this.swipeAnchorTime = now;
              console.log(`AppWindowContent: swipe 达到${this.swipeInterval}ms间隔，转发 (${swipeStartX.toFixed(1)}, ${swipeStartY.toFixed(1)}) -> (${x.toFixed(1)}, ${y.toFixed(1)}), 耗时${swipeDuration}ms`);
              // 不阻塞 Touch Move 事件处理，避免等待 native swipe 入队造成触摸卡顿。
              this.forwardTouchSwipe(swipeStartX, swipeStartY, x, y, swipeDuration);
            }
            return;
          }

          if (event.type === TouchType.Up) {
            if (this.resizeGestureActive) {
              this.resizeGestureActive = false;
              this.resizeEdgeCandidate = '';
              await new Promise<void>((resolve: () => void) => setTimeout(resolve, 100));
              await this.updateVirtualDisplaySize();
              return;
            }
            this.resizeEdgeCandidate = '';
            const duration = Date.now() - this.touchStartTime;
            const deltaX = x - this.touchStartX;
            const deltaY = y - this.touchStartY;
            const distance = Math.sqrt(deltaX * deltaX + deltaY * deltaY);

            if (this.swipeTriggered) {
              return;
            }

            if (distance <= this.touchMoveThreshold && duration >= this.longClickThreshold) {
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
          .backgroundColor($r('app.color.bg_card'))
          .position({ x: 0, y: 0 })
        }
      }
      .width('100%')
      .height('100%')
      .backgroundColor($r('app.color.bg_fill'))
      .borderRadius(12)
      .clip(true)
      .shadow({
        radius: 20,
        color: $r('app.color.shadow_float'),
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
          .backgroundColor($r('app.color.drag_handle'))
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
                if (this.isFullscreen) {
                  return;
                }
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
      .margin({ top: 6 })
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)

      if (this.isMenuVisible) {
        Row({ space: 8 }) {
          Image(this.isFullscreen ? $r('app.media.ic_restore') : $r('app.media.ic_fullscreen'))
            .width(32)
            .height(32)
            .padding(4)
            .backgroundColor($r('app.color.bg_card'))
            .border({ width: 1, color: $r('app.color.border_control'), radius: 6 })
            .onClick(() => this.toggleFullscreen())

          Image($r('app.media.ic_close'))
            .width(32)
            .height(32)
            .padding(4)
            .backgroundColor($r('app.color.bg_card'))
            .border({ width: 1, color: $r('app.color.border_control'), radius: 6 })
            .onClick(() => this.closeAppWindow())
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.Transparent)
        .position({ x: 0, y: 30 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.bg_page'))
  }
}
