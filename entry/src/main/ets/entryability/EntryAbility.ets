import { AbilityConstant, Configuration, UIAbility, Want } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { ThemeUtils } from '../utils/ThemeUtils';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  private mainWindow: window.Window | null = null;

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  async onWindowStageCreate(windowStage: window.WindowStage): Promise<void> {
    try {
      this.mainWindow = windowStage.getMainWindowSync();
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to get main window: %{public}s', JSON.stringify(error));
    }
    // await windowStage.loadContent('pages/EntryPage');
    // setWindowBackgroundColor 必须在 loadContent 生效后调用，否则会抛 1300002
    windowStage.loadContent('pages/HomePage')
      .then(() => {
        this.applyWindowBackground();
      })
      .catch(() => {
      })

    // AppStorage.setOrCreate("entryAbility", this)
  }

  /**
   * 系统深浅色模式变化时同步刷新窗口底色，避免切换瞬间露出不匹配的窗口背景。
   */
  onConfigurationUpdate(newConfig: Configuration): void {
    this.applyWindowBackground();
  }

  private applyWindowBackground(): void {
    if (!this.mainWindow) {
      return;
    }
    try {
      const color = ThemeUtils.resolveColorString(this.context, $r('app.color.bg_page').id);
      if (!color) {
        return;
      }
      this.mainWindow.setWindowBackgroundColor(color);
    } catch (error) {
      hilog.error(DOMAIN, 'testTag', 'Failed to apply window background: %{public}s', JSON.stringify(error));
    }
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    this.mainWindow = null;
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
