import window from "@ohos.window";
import { JSON } from "@kit.ArkTS";
import { FloatWindowManager } from "../window/FloatWindow";
import { common } from "@kit.AbilityKit";
import { smartMobilityCommon } from "@kit.CarKit";

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  createFloatWindow() {

    let awareness = smartMobilityCommon.getSmartMobilityAwareness();
    console.log("->>>>>", awareness)
    let status = awareness.getSmartMobilityStatus(smartMobilityCommon.SmartMobilityType.HICAR)
    if (status.status == 0) {
      this.message = "请先连接HiCar"
      return
    }
    let displayId = status.data["DISPLAY_ID"].toString() || "0";
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    FloatWindowManager.create(context, parseInt(displayId)); // displayId = 0 表示主屏幕
  }

  build() {
    Row() {
      Column() {
        Button('显示悬浮窗')
          .margin({ top: 20 })
          .onClick(() => {
            this.createFloatWindow();
          })
      }
      .width('100%')
    }
    .height('100%')
    .backgroundColor(Color.Black)
  }
}