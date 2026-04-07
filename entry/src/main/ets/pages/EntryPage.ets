import { smartMobilityCommon } from "@kit.CarKit";
import hilog from "@ohos.hilog";
import { JSON } from "@kit.ArkTS";
import display from "@ohos.display";
import Want from "@ohos.app.ability.Want";
import { StartOptions, UIAbility } from "@kit.AbilityKit";
import { } from "@kit.InputKit"


@Entry
@Component
struct EntryPage {
  @State message: string = '';
  @State displayId: number = 0;

  build() {
    Column() {
      Line().height(20)
      Text("获取 HiCar 状态")
        .onClick(() => {
          let awareness = smartMobilityCommon.getSmartMobilityAwareness();
          let status = awareness.getSmartMobilityStatus(smartMobilityCommon.SmartMobilityType.HICAR)
          this.message = JSON.stringify(status);
          hilog.debug(0x0000, "TAG", JSON.stringify(status))
        })
      Line().height(20)
      Text("获取屏幕信息").onClick(() => {
        let info = display.getDefaultDisplaySync();
        console.log(`info:${JSON.stringify(info)}`);
        display.getAllDisplays((e, list) => {
          if (e.code != 0) {
            this.message = `错误：${e.message}`
          } else {
            this.message = `${JSON.stringify(list.slice(1), null, 2)}`
          }
        })
      })
      Line().height(20)
      Text("测试").onClick(async () => {
        let want: Want = {
          bundleName: "com.yenole.demo",
          abilityName: "EntryAbility"
          // abilityName: "CarAbility"
        }
        let option: StartOptions = {
          displayId: this.displayId
        }
        console.log("->>option:", JSON.stringify(option))
        await AppStorage.get<UIAbility>("ability")?.context.startAbility(want, option)
      })
      Line().height(20)
      Text("投屏").onClick(() => {
        console.log("投屏")
        let want: Want = {
          bundleName: "com.yenole.hiplus",
          abilityName: "CarAbility"
        }

        // let awareness = smartMobilityCommon.getSmartMobilityAwareness();
        // console.log("->>>>>", awareness)
        // let status = awareness.getSmartMobilityStatus(smartMobilityCommon.SmartMobilityType.HICAR)
        // if (status.status == 0) {
        //   this.message = "请先连接HiCar"
        //   return
        // }
        // let displayId = status.data["DISPLAY_ID"].toString() || "0";
        let displayId = "0"
        this.message = `提取内容：${displayId}`
        let option: StartOptions = {
          displayId: parseInt(displayId),
        }
        AppStorage.get<UIAbility>("ability")?.context.startAbility(want, option, (err, data) => {
          if (err.code != 0) {
            this.message = err.message
            return
          }
          console.log(`startAbility:${JSON.stringify(err)}  ${data}`)
        })
      })
      Line().height(20)
      Text(this.message)

      // XComponent({
      //   id: "test2",
      //   type: XComponentType.SURFACE,
      //   controller: this.ctcl
      // }).onLoad(async () => {
      //   console.log("->>>>", this.ctcl.getXComponentSurfaceId())
      //   this.ctcl.setXComponentSurfaceRect({
      //     surfaceWidth: 1316 / 2,
      //     surfaceHeight: 2832 / 2,
      //   })
      //   this.displayId = await display.createVirtualScreen({
      //     name: "vHightDisplay",
      //     width: 1316 / 2,
      //     height: 2832 / 2,
      //     density: 3.5 / 2,
      //     surfaceId: this.ctcl.getXComponentSurfaceId()
      //   })
      //   await display.makeUnique(this.displayId)
      //   console.log("->>>>display id", this.displayId)
      //   const vd = display.getDisplayByIdSync(this.displayId)
      //   console.log("display:", vd.densityPixels, vd.sourceMode, vd.width, vd.height)
      //
      //   const vdd = display.getDefaultDisplaySync()
      //   console.log("vdisplay:", vdd.densityPixels, vdd.sourceMode, vdd.width, vdd.height);
      //
      //   // let want: Want = {
      //   //   bundleName: "com.yenole.hiplus",
      //   //   abilityName: "CarAbility"
      //   // }
      //   // let option: StartOptions = {
      //   //   displayId: id,
      //   // }
      //   // AppStorage.get<UIAbility>("ability")?.context.startAbility(want, option, (err, data) => {
      //   //   if (err.code != 0) {
      //   //     this.message = err.message
      //   //     return
      //   //   }
      //   //   console.log(`startAbility:${JSON.stringify(err)}  ${data}`)
      //   // })
      // })
      Line().height(20)
    }

    // RelativeContainer() {
    //   Text(this.message)
    //     .id('HelloWorld')
    //     .fontSize($r('app.float.page_text_font_size'))
    //     .fontWeight(FontWeight.Bold)
    //     .alignRules({
    //       center: { anchor: '__container__', align: VerticalAlign.Center },
    //       middle: { anchor: '__container__', align: HorizontalAlign.Center }
    //     })
    //     .onClick(() => {
    //       this.message = 'Welcome';
    //     })
    // }
    .height('100%')
    .width('100%')
  }
}