import { pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import { bundleManager } from '@kit.AbilityKit';
import router from '@ohos.router';

@Entry
@Component
export struct AboutPage {
  @State versionName: string = '读取中...';

  aboutToAppear() {
    this.loadVersion();
  }

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: 18 }) {
          this.AppIntroduction()
          this.OfficialAccountCard()
          this.InfoCard()
        }
        .width('100%')
        .padding({ left: 16, right: 16, top: 12, bottom: 32 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
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

      Text('关于')
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
  private AppIntroduction() {
    Column({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        Image($r('app.media.startIcon'))
          .width(64)
          .height(64)
          .borderRadius(18)
      }
      .width(80)
      .height(80)
      .borderRadius(22)
      .backgroundColor('#EAF3FF')
      .shadow({ radius: 16, color: 'rgba(0, 125, 255, 0.18)', offsetX: 0, offsetY: 6 })

      Text('Hi时刻')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1B1B')

      Text('让车机连接更简单，让精彩一路相伴')
        .fontSize(13)
        .fontColor('#7A7F8A')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .padding({ top: 8, bottom: 8 })
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private OfficialAccountCard() {
    Column({ space: 14 }) {
      Row() {
        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.ic_profile_about'))
            .width(20)
            .height(20)
        }
        .width(36)
        .height(36)
        .borderRadius(18)
        .backgroundColor('#EAF3FF')

        Column({ space: 3 }) {
          Text('公众号')
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1C1B1B')
          Text('获取更新、教程与使用帮助')
            .fontSize(12)
            .fontColor('#7A7F8A')
        }
        .alignItems(HorizontalAlign.Start)
        .margin({ left: 12 })

        Blank()

        Text('Hi时刻')
          .fontSize(14)
          .fontColor('#007DFF')
      }
      .width('100%')

      Column({ space: 8 }) {
        Text('关注公众号：Hi时刻')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1B1B')
          .width('100%')

        Text('关注后可获取版本更新、车机投屏教程和功能配置说明。授权登录时，也请将页面显示的授权码发送给“Hi时刻”。')
          .fontSize(13)
          .lineHeight(21)
          .fontColor('#596170')
          .width('100%')
      }

      Button('复制公众号名称')
        .width('100%')
        .height(44)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#007DFF')
        .backgroundColor('#EAF3FF')
        .borderRadius(22)
        .onClick(() => {
          this.copyOfficialAccount();
        })
    }
    .width('100%')
    .padding(18)
    .borderRadius(20)
    .backgroundColor(Color.White)
    .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.10)', offsetX: 0, offsetY: 8 })
  }

  @Builder
  private InfoCard() {
    Column() {
      this.InfoRow('版本', this.versionName)
      Divider()
        .strokeWidth(1)
        .color('#EEEAE8')
        .margin({ left: 52 })
      this.InfoRow('服务说明', 'Hi时刻提供')
      Divider()
        .strokeWidth(1)
        .color('#EEEAE8')
        .margin({ left: 52 })
      this.InfoRow('用户协议与隐私', '请合理使用应用')
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .borderRadius(20)
    .backgroundColor(Color.White)
    .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.10)', offsetX: 0, offsetY: 8 })
  }

  @Builder
  private InfoRow(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor('#1C1B1B')
      Blank()
      Text(value)
        .fontSize(13)
        .fontColor('#9A9EA8')
    }
    .width('100%')
    .height(56)
  }

  private copyOfficialAccount() {
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, 'Hi时刻');
    pasteboard.getSystemPasteboard().setData(pasteData);
    promptAction.showToast({ message: '公众号名称已复制', duration: 2000 });
  }

  private loadVersion() {
    try {
      const bundleInfo = bundleManager.getBundleInfoForSelfSync(
        bundleManager.BundleFlag.GET_BUNDLE_INFO_WITH_APPLICATION
      );
      this.versionName = bundleInfo.versionName || '未知';
    } catch (error) {
      console.error('读取应用版本失败', error);
      this.versionName = '未知';
    }
  }
}
