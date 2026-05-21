import display from '@ohos.display';
import Want from '@ohos.app.ability.Want';
import { common, StartOptions } from "@kit.AbilityKit";
import { JSON } from '@kit.ArkTS';

@Entry
@Component
struct AppPage {
  @State message: string = 'Hello World';
  @State displayId:number = 0;
  ctcl: XComponentController = new XComponentController();

  build() {
    Column(){
//       Text("投屏").height(100).onClick(() => {
//         console.log("->>>click");
//         let want:Want = {
//           bundleName:"com.tencent.wechat",
//           abilityName: "EntryAbility"
//         }
//         let options :StartOptions = {
//          displayId:  this.displayId
//         };
//         console.log("->display:",options)
// let context =        this.getUIContext().getHostContext() as common.UIAbilityContext
//
//         context.startAbility(want,options,()=>{})
//       })
      XComponent({
        id: "test2",
        type: XComponentType.SURFACE,
        controller: this.ctcl
      }).onLoad(async () => {
        console.log("->>>>", this.ctcl.getXComponentSurfaceId())
        let rect =   this.ctcl.getXComponentSurfaceRect()
        console.log("->>rect:",JSON.stringify(rect));
        // this.ctcl.setXComponentSurfaceRect({
        //   surfaceWidth: 2832/2 ,
        //   surfaceHeight: 1080,
        // })
        this.displayId = await display.createVirtualScreen({
          name: "vHightDisplay",
          width: rect.surfaceWidth,
          height: rect.surfaceHeight,
          density: 3,
          surfaceId: this.ctcl.getXComponentSurfaceId()
        })
        await display.makeUnique(this.displayId)
        console.log("->>>>display id", this.displayId)
        const vd = display.getDisplayByIdSync(this.displayId)
        console.log("display:", vd.densityPixels, vd.sourceMode, vd.width, vd.height)

        const vdd = display.getDefaultDisplaySync()
        console.log("vdisplay:", vdd.densityPixels, vdd.sourceMode, vdd.width, vdd.height);

        let want: Want = {
          bundleName: "com.autonavi.amapauto",
          abilityName: "com.autonavi.auto.remote.fill.UsbFillActivity"
        }
        let option: StartOptions = {
          displayId: vd.id,
        };
        ( this.getUIContext().getHostContext() as common.UIAbilityContext).startAbility(want,option,(err)=>{
          console.log("->>err",JSON.stringify(err))
        })

        // AppStorage.get<UIAbility>("ability")?.context.startAbility(want, option, (err, data) => {
        //   if (err.code != 0) {
        //     this.message = err.message
        //     return
        //   }
        //   console.log(`startAbility:${JSON.stringify(err)}  ${data}`)
        // })
      })
    }
    .height('100%')
    .width('100%')
  }
}