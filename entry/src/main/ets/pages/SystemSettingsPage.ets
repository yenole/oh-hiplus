import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import { promptAction } from '@kit.ArkUI';
import router from '@ohos.router';

@Entry
@Component
export struct SystemSettingsPage {
  @State debugPort: string = '';
  @State autoRefreshApps: boolean = true;
  @State isSaving: boolean = false;
  private preferencesInstance: preferences.Preferences | null = null;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  aboutToAppear() {
    this.loadSettings();
  }

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: 16 }) {
          Column({ space: 6 }) {
            Text('调试连接')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#7A7F8A')
              .width('100%')
              .margin({ left: 4 })

            Column({ space: 14 }) {
              Row() {
                Stack({ alignContent: Alignment.Center }) {
                  Image($r('app.media.ic_profile_security'))
                    .width(20)
                    .height(20)
                }
                .width(36)
                .height(36)
                .borderRadius(18)
                .backgroundColor('#EAF3FF')

                Column({ space: 3 }) {
                  Text('无线调试端口')
                    .fontSize(16)
                    .fontWeight(FontWeight.Medium)
                    .fontColor('#1C1B1B')
                  Text('用于连接车机调试服务')
                    .fontSize(12)
                    .fontColor('#7A7F8A')
                }
                .alignItems(HorizontalAlign.Start)
                .margin({ left: 12 })

                Blank()

                Text(this.debugPort ? this.debugPort : '未设置')
                  .fontSize(14)
                  .fontColor(this.debugPort ? '#007DFF' : '#9A9EA8')
              }
              .width('100%')

              TextInput({ placeholder: '请输入 1 - 65535 的端口号', text: this.debugPort })
                .type(InputType.Number)
                .maxLength(5)
                .height(48)
                .width('100%')
                .padding({ left: 14, right: 14 })
                .fontSize(15)
                .borderRadius(12)
                .backgroundColor('#F7F8FA')
                .onChange((value: string) => {
                  this.debugPort = value;
                })

              Text('修改端口后，重新连接车机才能生效。')
                .fontSize(12)
                .fontColor('#9A9EA8')
                .width('100%')
            }
            .width('100%')
            .padding(16)
            .borderRadius(20)
            .backgroundColor(Color.White)
            .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.10)', offsetX: 0, offsetY: 8 })
          }
          .width('100%')

          Column({ space: 6 }) {
            Text('应用管理')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#7A7F8A')
              .width('100%')
              .margin({ left: 4 })

            Column() {
              this.SwitchRow('启动时刷新应用列表', '进入应用页时自动获取最新列表', this.autoRefreshApps, (value: boolean) => {
                this.autoRefreshApps = value;
                this.saveBooleanSetting('auto_refresh_apps', value);
              })
              Divider()
                .strokeWidth(1)
                .color('#EEEAE8')
                .margin({ left: 52 })
              this.ActionRow('清除应用缓存', '删除本地保存的应用列表', () => {
                this.clearAppsCache();
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
            Text('其他')
              .fontSize(13)
              .fontWeight(FontWeight.Medium)
              .fontColor('#7A7F8A')
              .width('100%')
              .margin({ left: 4 })

            Column() {
              this.ActionRow('恢复默认设置', '清空端口并恢复应用列表自动刷新', () => {
                this.resetSettings();
              })
            }
            .width('100%')
            .padding({ left: 16, right: 16 })
            .borderRadius(20)
            .backgroundColor(Color.White)
            .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.10)', offsetX: 0, offsetY: 8 })
          }
          .width('100%')

        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Start)
        .padding({ left: 16, right: 16, top: 12, bottom: 16 })
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
          this.saveDebugPort();
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7F9')
  }

  @Builder
  private SwitchRow(title: string, description: string, value: boolean, onChange: (value: boolean) => void) {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Image($r('app.media.ic_category_tools'))
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
  private ActionRow(title: string, description: string, onClick: () => void) {
    Row() {
      Stack({ alignContent: Alignment.Center }) {
        Image($r('app.media.ic_category_tools'))
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

      Image($r('app.media.ic_profile_chevron'))
        .width(20)
        .height(20)
    }
    .width('100%')
    .height(68)
    .onClick(() => {
      onClick();
    })
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

      Text('系统设置')
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

  private async loadSettings() {
    try {
      this.preferencesInstance = await preferences.getPreferences(this.context, 'app_preferences');
      this.debugPort = await this.preferencesInstance.get('wireless_debug_port', '') as string;
      this.autoRefreshApps = await this.preferencesInstance.get('auto_refresh_apps', true) as boolean;
    } catch (error) {
      console.error('加载系统设置失败', error);
    }
  }

  private async saveBooleanSetting(key: string, value: boolean) {
    try {
      if (!this.preferencesInstance) {
        this.preferencesInstance = await preferences.getPreferences(this.context, 'app_preferences');
      }
      await this.preferencesInstance.put(key, value);
      await this.preferencesInstance.flush();
    } catch (error) {
      console.error('保存系统设置失败', error);
    }
  }

  private async clearAppsCache() {
    try {
      const appsPreferences = await preferences.getPreferences(this.context, 'hap_apps_storage');
      await appsPreferences.delete('hap_apps_cache');
      await appsPreferences.flush();
      promptAction.showToast({ message: '应用缓存已清除', duration: 2000 });
    } catch (error) {
      console.error('清除应用缓存失败', error);
      promptAction.showToast({ message: '清除失败，请重试', duration: 2000 });
    }
  }

  private async resetSettings() {
    this.debugPort = '';
    this.autoRefreshApps = true;
    try {
      if (!this.preferencesInstance) {
        this.preferencesInstance = await preferences.getPreferences(this.context, 'app_preferences');
      }
      await this.preferencesInstance.delete('wireless_debug_port');
      await this.preferencesInstance.put('auto_refresh_apps', true);
      await this.preferencesInstance.flush();
      promptAction.showToast({ message: '已恢复默认设置', duration: 2000 });
    } catch (error) {
      console.error('恢复默认设置失败', error);
      promptAction.showToast({ message: '恢复失败，请重试', duration: 2000 });
    }
  }

  private async saveDebugPort() {
    const port = parseInt(this.debugPort);
    if (!this.debugPort || isNaN(port) || port < 1 || port > 65535) {
      promptAction.showToast({ message: '请输入 1 - 65535 的有效端口', duration: 2000 });
      return;
    }

    try {
      this.isSaving = true;
      if (!this.preferencesInstance) {
        this.preferencesInstance = await preferences.getPreferences(this.context, 'app_preferences');
      }
      await this.preferencesInstance.put('wireless_debug_port', this.debugPort);
      await this.preferencesInstance.flush();
      promptAction.showToast({ message: '调试端口已保存', duration: 2000 });
    } catch (error) {
      console.error('保存调试端口失败', error);
      promptAction.showToast({ message: '保存失败，请重试', duration: 2000 });
    } finally {
      this.isSaving = false;
    }
  }
}
