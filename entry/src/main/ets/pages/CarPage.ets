import { floatingBall, PiPWindow, typeNode } from '@kit.ArkUI';
import { UIAbility } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

@Entry
@Component
struct CarPage {
  @State message: string = '打开悬浮窗口';
  private floatintBallCtrl: floatingBall.FloatingBallController | undefined;

  build() {
    RelativeContainer() {
      Text("打开悬浮窗口")
        .fontSize($r('app.float.page_text_font_size'))
        .fontWeight(FontWeight.Bold)
        .alignRules({
          center: { anchor: '__container__', align: VerticalAlign.Center },
          middle: { anchor: '__container__', align: HorizontalAlign.Center }
        })
        .onClick(async () => {
          if (this.floatintBallCtrl != null) {
            return;
          }
          console.log('->float：->', floatingBall.isFloatingBallEnabled())

          this.floatintBallCtrl = await floatingBall.create({
            context: this.getUIContext().getHostContext()
          })
          console.log('->>>float', this.floatintBallCtrl);
          this.floatintBallCtrl.on("click", async () => {

          })
          let startParams: floatingBall.FloatingBallParams = {
            template: floatingBall.FloatingBallTemplate.EMPHATIC,
            title: 'Hi时刻',
            content: '这是内容'
          };
          this.floatintBallCtrl?.startFloatingBall(startParams).catch((e: BusinessError) => {
            console.log('->>erro', e.code, e.message)
          })
          console.log(`开启悬浮框`)
          // let config: PiPWindow.PiPConfiguration = {
          //   context: (AppStorage.get("ability") as UIAbility).context,
          //   componentController: new XComponentController(),
          //   templateType: PiPWindow.PiPTemplateType.VIDEO_CALL,
          //   contentWidth: 1,
          //   contentHeight: 1,
          // }
          // let content = typeNode.createNode(this.getUIContext(), "XComponent", {
          //   type: XComponentType.NODE,
          //   controller: config.componentController
          // })
          // let ctr = await PiPWindow.create(config, content)
          // AppStorage.setOrCreate("pipctrl", ctr)
          // ctr.on("stateChange", (state: PiPWindow.PiPState, reason: string) => {
          //   console.log(`state:${state} reason:${reason}`)
          //   if (state == PiPWindow.PiPState.STOPPED) {
          //     console.log(`销毁打开布局`)
          //   }
          // })
          // ctr.on("controlEvent", (param: PiPWindow.ControlEventParam) => {
          //   console.log(`controlEvent:${param}`)
          // })
          // ctr.setAutoStartEnabled(true)
          // ctr.startPiP()
          // console.log("->开启悬浮结束")
        })
    }
    .height('100%')
    .width('100%')
  }

  onPageHide(): void {
    console.log(`onPageHide`)
    if (AppStorage.has("pip_ctrl")) {
      (AppStorage.get("pip_ctrl") as PiPWindow.PiPController).startPiP()
    }
  }

  onPageShow(): void {
    console.log(`onPageShow`)
    if (AppStorage.has("pip_ctrl")) {
      (AppStorage.get("pip_ctrl") as PiPWindow.PiPController).startPiP()
    }
  }
}