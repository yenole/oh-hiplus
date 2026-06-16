import window from "@ohos.window";
import display from "@ohos.display";
import { common } from "@kit.AbilityKit";
import Want from "@ohos.app.ability.Want";

export class AppWindow {
  private static windowCounter: number = 0;

  /**
   * 创建并显示悬浮窗
   * @param packageName - 应用包名
   * @param displayId - 显示屏ID
   * @param context - UIAbility上下文
   */
  static create(packageName: string, displayId: number, context: common.UIAbilityContext): void {
    console.log(`AppWindow: 开始创建悬浮窗 - 包名: ${packageName}, displayId: ${displayId}`);

    // 生成唯一窗口名称（移除包名中的特殊字符）
    const sanitizedPackageName = packageName.replace(/[^a-zA-Z0-9]/g, '_');
    const timestamp = Date.now();
    const windowName = `appWindow_${sanitizedPackageName}_${timestamp}`;

    // 创建窗口配置
    const config: window.Configuration = {
      name: windowName,
      windowType: window.WindowType.TYPE_FLOAT,
      ctx: context,
      displayId: displayId
    };

    // 创建悬浮窗
    window.createWindow(config, (err, win) => {
      if (err.code != 0) {
        console.log(`AppWindow: 创建悬浮窗失败:`, JSON.stringify(err));
        return;
      }

      console.log(`AppWindow: 悬浮窗创建成功 - 窗口名称: ${windowName}`);

      // 获取显示屏信息
      let screenInfo: display.Display;
      try {
        if (displayId) {
          screenInfo = display.getDisplayByIdSync(displayId);
        } else {
          screenInfo = display.getDefaultDisplaySync();
        }
      } catch (error) {
        console.log(`AppWindow: 获取显示屏信息失败:`, JSON.stringify(error));
        screenInfo = display.getDefaultDisplaySync();
      }

      // 设置悬浮窗大小和位置
      const screenWidth = screenInfo.width;
      const screenHeight = screenInfo.height;
      
      // 判断横竖屏
      const isLandscape = screenWidth > screenHeight;
      
      // 窗口高度填充屏幕，宽度根据横竖屏调整
      const windowHeight = screenHeight;
      const windowWidth = isLandscape ? Math.floor(screenWidth * 0.3) : Math.floor(screenWidth * 0.8);

      // 计算位置（靠右或居中）
      const posX = isLandscape ? (screenWidth - windowWidth) : Math.floor((screenWidth - windowWidth) / 2);
      const posY = 0;

      console.log(`AppWindow: 屏幕尺寸: ${screenWidth}x${screenHeight}, 横屏: ${isLandscape}, 窗口大小: ${windowWidth}x${windowHeight}, 位置: (${posX}, ${posY})`);

      // 设置窗口大小
      win.resize(windowWidth, windowHeight, (err) => {
        if (err.code != 0) {
          console.log(`AppWindow: 设置窗口大小失败:`, JSON.stringify(err));
        } else {
          console.log(`AppWindow: 窗口大小设置成功: ${windowWidth}x${windowHeight}`);
        }
      });

      // 设置窗口位置
      win.moveWindowTo(posX, posY, (err) => {
        if (err.code != 0) {
          console.log(`AppWindow: 设置窗口位置失败:`, JSON.stringify(err));
        } else {
          console.log(`AppWindow: 窗口位置设置成功: (${posX}, ${posY})`);
        }
      });

      // 设置窗口圆角
      try {
        win.setWindowCornerRadius(12);
        console.log(`AppWindow: 窗口圆角设置成功: 12px`);
      } catch (error) {
        console.log(`AppWindow: 设置窗口圆角失败:`, JSON.stringify(error));
      }

      // 将包名和窗口实例存储到AppStorage，使用唯一的key，供UI组件使用
      AppStorage.setOrCreate(`appWindow_packageName_${windowName}`, packageName);
      AppStorage.setOrCreate(`appWindow_instance_${windowName}`, win);
      AppStorage.setOrCreate(`appWindow_current`, windowName); // 设置当前窗口名称

      // 加载悬浮窗UI内容
      win.loadContent("pages/AppWindowContent", (err) => {
        if (err.code != 0) {
          console.log(`AppWindow: 加载页面内容失败:`, JSON.stringify(err));
          return;
        }

        console.log(`AppWindow: 页面内容加载成功`);

        // 显示窗口
        win.showWindow((err) => {
          if (err.code != 0) {
            console.log(`AppWindow: 显示窗口失败:`, JSON.stringify(err));
          } else {
            console.log(`AppWindow: 悬浮窗显示成功`);
          }
        });
      });
    });
  }
}
