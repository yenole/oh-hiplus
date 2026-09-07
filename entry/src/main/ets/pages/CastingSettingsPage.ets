import preferences from '@ohos.data.preferences';
import router from '@ohos.router';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';

@Entry
@Component
export struct CastingSettingsPage {
  @State autoOpenFloatWindow: boolean = true;
  @State keepScreenAwake: boolean = true;
  @State showTouchHint: boolean = true;
  @State isSaving: boolean = false;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private preferencesInstance: preferences.Preferences | null = null;

  aboutToAppear() {
    this.loadSettings();
  }

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: 18 }) {
          this.ConnectionCard()

          Column({ space: 6 }) {
            Text('投屏体验')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#7A7F8A')
              .width('100%')
              .margin({ left: 4 })

            Column() {
              this.SwitchRow('自动打开悬浮窗', '连接车机后自动显示应用悬浮窗', this.autoOpenFloatWindow, (value: boolean) => {
                this.autoOpenFloatWindow = value;
              })
              Divider()
                .strokeWidth(1)
                .color('#EEEAE8')
                .margin({ left: 52 })
              this.SwitchRow('保持屏幕常亮', '投屏期间避免手机自动锁屏', this.keepScreenAwake, (value: boolean) => {
                this.keepScreenAwake = value;
              })
              Divider()
                .strokeWidth(1)
                .color('#EEEAE8')
                .margin({ left: 52 })
              this.SwitchRow('显示操作提示', '首次使用时显示投屏操作说明', this.showTouchHint, (value: boolean) => {
                this.showTouchHint = value;
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
            .borderRadius(20)
            .backgroundColor(Color.White)
            .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.10)', offsetX: 0, offsetY: 8 })
          }
          .width('100%')

          Column({ space: 6 }) {
            Text('使用说明')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#7A7F8A')
              .width('100%')
              .margin({ left: 4 })

            Column({ space: 10 }) {
              this.HelpRow('1', '确认手机与车机处于同一网络环境')
              this.HelpRow('2', '点击首页“投屏”按钮开始连接')
              this.HelpRow('3', '打开悬浮窗后选择需要启动的应用')
            }
            .width('100%')
            .padding(16)
            .borderRadius(20)
            .backgroundColor(Color.White)
            .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.10)', offsetX: 0, offsetY: 8 })
          }
          .width('100%')
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 24 })
      }
      .layoutWeight(1)
      .width('100%')
      .align(Alignment.Top)
      .scrollBar(BarState.Off)

      Button(this.isSaving ? '保存中...' : '保存设置')
        .width('calc(100% - 32vp)')
        .height(48)
        .margin({ left: 16, right: 16, bottom: 16 })
        .fontSize(16)
        .fontWeight(FontWeight.Medium)
        .fontColor(Color.White)
        .backgroundColor('#007DFF')
        .borderRadius(24)
        .enabled(!this.isSaving)
        .onClick(() => {
          this.saveSettings();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7F9')
  }

  @Builder
  private Header() {
    Row() {
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_profile_chevron'))
          .width(22)
          .height(22)
          .rotate({ angle: 180 })
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
      .onClick(() => {
        router.back();
      })

      Text('投屏设置')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1B1B')
        .margin({ left: 8 })

      Blank()
    }
    .width('100%')
    .height(64)
    .padding({ left: 12, right: 16 })
  }

  @Builder
  private ConnectionCard() {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Circle()
          .width(12)
          .height(12)
          .fill('#25C281')
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor('#E8FAF2')

      Column({ space: 4 }) {
        Text('车机连接状态')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1C1B1B')
        Text('已准备好投屏')
          .fontSize(12)
          .fontColor('#25A875')
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      Blank()

      Text('正常')
        .fontSize(14)
        .fontColor('#25A875')
    }
    .width('100%')
    .padding(16)
    .borderRadius(20)
    .backgroundColor(Color.White)
    .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.10)', offsetX: 0, offsetY: 8 })
  }

  @Builder
  private SwitchRow(title: string, description: string, value: boolean, onChange: (value: boolean) => void) {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Image($r('app.media.ic_profile_devices'))
          .width(20)
          .height(20)
      }
      .width(36)
      .height(36)
      .borderRadius(18)
      .backgroundColor('#F6F3F2')

      Column({ space: 3 }) {
        Text(title)
          .fontSize(15)
          .fontColor('#1C1B1B')
        Text(description)
          .fontSize(12)
          .fontColor('#7A7F8A')
      }
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })

      Blank()

      Toggle({ type: ToggleType.Switch, isOn: value })
        .selectedColor('#007DFF')
        .onChange((isOn: boolean) => {
          onChange(isOn);
        })
    }
    .width('100%')
    .height(68)
  }

  @Builder
  private HelpRow(number: string, text: string) {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        Text(number)
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(26)
      .height(26)
      .borderRadius(13)
      .backgroundColor('#007DFF')

      Text(text)
        .fontSize(13)
        .fontColor('#596170')
        .layoutWeight(1)
    }
    .width('100%')
    .height(32)
  }

  private async loadSettings() {
    try {
      this.preferencesInstance = await preferences.getPreferences(this.context, 'app_preferences');
      this.autoOpenFloatWindow = await this.preferencesInstance.get('auto_open_float_window', true) as boolean;
      this.keepScreenAwake = await this.preferencesInstance.get('keep_screen_awake', true) as boolean;
      this.showTouchHint = await this.preferencesInstance.get('show_touch_hint', true) as boolean;
    } catch (error) {
      console.error('加载投屏设置失败', error);
    }
  }

  private async saveSettings() {
    try {
      this.isSaving = true;
      if (!this.preferencesInstance) {
        this.preferencesInstance = await preferences.getPreferences(this.context, 'app_preferences');
      }
      await this.preferencesInstance.put('auto_open_float_window', this.autoOpenFloatWindow);
      await this.preferencesInstance.put('keep_screen_awake', this.keepScreenAwake);
      await this.preferencesInstance.put('show_touch_hint', this.showTouchHint);
      await this.preferencesInstance.flush();
      promptAction.showToast({ message: '投屏设置已保存', duration: 2000 });
    } catch (error) {
      console.error('保存投屏设置失败', error);
      promptAction.showToast({ message: '保存失败，请重试', duration: 2000 });
    } finally {
      this.isSaving = false;
    }
  }
}
