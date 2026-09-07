import { promptAction } from '@kit.ArkUI';
import { pasteboard } from '@kit.BasicServicesKit';
import router from '@ohos.router';

@Entry
@Component
export struct FeedbackPage {
  @State feedbackType: string = '功能建议';
  @State description: string = '';
  @State contact: string = '';
  @State isSubmitting: boolean = false;
  @State showGuide: boolean = false;

  build() {
    Column() {
      this.Header()

      Scroll() {
        Column({ space: 18 }) {
          Column({ space: 6 }) {
            Text('告诉我们你的想法')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1B1B')
              .width('100%')
            Text('每一条反馈都会帮助 Hi时刻变得更好')
              .fontSize(13)
              .fontColor('#7A7F8A')
              .width('100%')
          }
          .width('100%')
          .padding({ top: 8, left: 4 })

          Column({ space: 12 }) {
            Text('反馈类型')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1C1B1B')
              .width('100%')

            Row({ space: 8 }) {
              this.TypeButton('功能建议')
              this.TypeButton('问题反馈')
              this.TypeButton('使用咨询')
            }
            .width('100%')
          }
          .width('100%')
          .padding(16)
          .borderRadius(20)
          .backgroundColor(Color.White)
          .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.10)', offsetX: 0, offsetY: 8 })

          Column({ space: 12 }) {
            Text('详细描述')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1C1B1B')
              .width('100%')

            TextArea({ placeholder: '请描述你的建议或遇到的问题', text: this.description })
              .height(132)
              .width('100%')
              .fontSize(15)
              .padding(14)
              .maxLength(300)
              .textAlign(TextAlign.Start)
              .backgroundColor('#F7F8FA')
              .borderRadius(12)
              .onChange((value: string) => {
                this.description = value;
              })

            Text(`${this.description.length}/300`)
              .fontSize(12)
              .fontColor('#9A9EA8')
              .width('100%')
              .textAlign(TextAlign.End)
          }
          .width('100%')
          .padding(16)
          .borderRadius(20)
          .backgroundColor(Color.White)
          .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.10)', offsetX: 0, offsetY: 8 })

          Column({ space: 12 }) {
            Text('联系方式（选填）')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor('#1C1B1B')
              .width('100%')

            TextInput({ placeholder: '方便我们回复你，例如微信号', text: this.contact })
              .height(48)
              .width('100%')
              .fontSize(15)
              .padding({ left: 14, right: 14 })
              .backgroundColor('#F7F8FA')
              .borderRadius(12)
              .onChange((value: string) => {
                this.contact = value;
              })
          }
          .width('100%')
          .padding(16)
          .borderRadius(20)
          .backgroundColor(Color.White)
          .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.10)', offsetX: 0, offsetY: 8 })

          Button(this.isSubmitting ? '提交中...' : '提交反馈')
            .width('100%')
            .height(48)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor(Color.White)
            .backgroundColor('#007DFF')
            .borderRadius(24)
            .enabled(!this.isSubmitting)
            .onClick(() => {
              this.submitFeedback();
            })

          Text('暂不需要填写联系方式，我们也会认真阅读你的反馈。')
            .fontSize(12)
            .fontColor('#9A9EA8')
            .width('100%')
            .textAlign(TextAlign.Center)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 32 })
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F7F9')
    .bindSheet($$this.showGuide, this.FeedbackGuide(), {
      height: 430,
      dragBar: true,
      showClose: false,
      maskColor: 'rgba(0, 0, 0, 0.45)'
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

      Text('意见反馈')
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
  private TypeButton(type: string) {
    Button(type)
      .layoutWeight(1)
      .height(38)
      .fontSize(13)
      .fontColor(this.feedbackType === type ? '#007DFF' : '#596170')
      .backgroundColor(this.feedbackType === type ? '#EAF3FF' : '#F7F8FA')
      .borderRadius(19)
      .onClick(() => {
        this.feedbackType = type;
      })
  }

  private async submitFeedback() {
    if (!this.description.trim()) {
      promptAction.showToast({ message: '请先填写反馈内容', duration: 2000 });
      return;
    }
    if (this.description.length > 300) {
      promptAction.showToast({ message: '反馈内容不能超过 300 字', duration: 2000 });
      return;
    }

    this.isSubmitting = true;
    this.showGuide = true;
    this.isSubmitting = false;
  }

  @Builder
  private FeedbackGuide() {
    Column({ space: 16 }) {
      Column({ space: 6 }) {
        Text('通过公众号提交反馈')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1B1B')
        Text('复制内容后，在微信发送给公众号“Hi时刻”')
          .fontSize(13)
          .fontColor('#7A7F8A')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)

      Column({ space: 10 }) {
        this.GuideStep('1', '复制反馈内容', () => {
          this.copyFeedbackContent();
        })
        this.GuideStep('2', '复制公众号名称：Hi时刻', () => {
          this.copyOfficialAccount();
        })
        this.GuideStep('3', '打开微信，搜索并发送给“Hi时刻”', () => {
          promptAction.showToast({ message: '请打开微信搜索公众号：Hi时刻', duration: 2500 });
        })
      }
      .width('100%')

      Row({ space: 10 }) {
        Button('查看反馈内容')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor('#007DFF')
          .backgroundColor('#EAF3FF')
          .borderRadius(22)
          .onClick(() => {
            this.copyFeedbackContent();
          })
        Button('知道了')
          .layoutWeight(1)
          .height(44)
          .fontSize(15)
          .fontColor(Color.White)
          .backgroundColor('#007DFF')
          .borderRadius(22)
          .onClick(() => {
            this.showGuide = false;
          })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24, top: 22, bottom: 30 })
    .justifyContent(FlexAlign.SpaceBetween)
    .backgroundColor(Color.White)
  }

  @Builder
  private GuideStep(number: string, title: string, onClick: () => void) {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        Text(number)
          .fontSize(13)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
      }
      .width(28)
      .height(28)
      .borderRadius(14)
      .backgroundColor('#007DFF')

      Text(title)
        .fontSize(14)
        .fontColor('#1C1B1B')
        .layoutWeight(1)

      Text('复制')
        .fontSize(13)
        .fontColor('#007DFF')
        .onClick(() => {
          onClick();
        })
    }
    .width('100%')
    .height(40)
  }

  private feedbackContent(): string {
    let content = `【${this.feedbackType}】\n${this.description.trim()}`;
    if (this.contact.trim()) {
      content += `\n联系方式：${this.contact.trim()}`;
    }
    return content;
  }

  private copyFeedbackContent() {
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, this.feedbackContent());
    pasteboard.getSystemPasteboard().setData(pasteData);
    promptAction.showToast({ message: '反馈内容已复制', duration: 2000 });
  }

  private copyOfficialAccount() {
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, 'Hi时刻');
    pasteboard.getSystemPasteboard().setData(pasteData);
    promptAction.showToast({ message: '公众号名称已复制', duration: 2000 });
  }
}
