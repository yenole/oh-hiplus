import { smartMobilityCommon } from "@kit.CarKit";
import hilog from "@ohos.hilog";
import { JSON } from "@kit.ArkTS";
import display from "@ohos.display";
import Want from "@ohos.app.ability.Want";
import { StartOptions, UIAbility,common } from "@kit.AbilityKit";
import { } from "@kit.InputKit"
import  window from  "@ohos.window";




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
      Text("投屏").onClick(() => {
        console.log("投屏")
        let want: Want = {
          bundleName: "com.yenole.hiplus",
          abilityName: "CarAbility"
        }

        let awareness = smartMobilityCommon.getSmartMobilityAwareness();
        console.log("->>>>>", awareness)
        let status = awareness.getSmartMobilityStatus(smartMobilityCommon.SmartMobilityType.HICAR)
        // if (status.status == 0) {
        //   this.message = "请先连接HiCar"
        //   return
        // }
        let displayId = status.data["DISPLAY_ID"].toString() || "0";
        this.message = `提取内容：${displayId}`
        const hdisplay =        display.getDisplayByIdSync(this.displayId);
        console.log("->display:",JSON.stringify(hdisplay))

        window.createWindow({name :"hiplus","windowType":8,ctx:this.getUIContext().getHostContext(),"displayId": parseInt( displayId)},(err,win)=>{
          if (err.code!=0) {
            console.log("->>>",err);
            return
          }
          win.resize(hdisplay.height,hdisplay.width);
          // win.moveWindowTo(,0)
          win.loadContent("pages/AppPage")
          win.showWindow(()=>{})

        })
        return;
        let option: StartOptions = {
          displayId: parseInt(displayId),
        }
        let  context = this.getUIContext().getHostContext() as common.UIAbilityContext;
        console.log("context:",context);
         context.startAbility(want,(err,data)=>{
           console.log("err:",err);
         })
        // AppStorage.get<UIAbility>("ability")?.context.startAbility(want, option, (err, data) => {
        //   if (err.code != 0) {
        //     this.message = err.message
        //     return
        //   }
        //   console.log(`startAbility:${JSON.stringify(err)}  ${data}`)
        // })
      })
      Line().height(20)
      Text(this.message)
      Line().height(20)
    }
    .height('100%')
    .width('100%')
  }
}