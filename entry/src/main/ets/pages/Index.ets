import window from "@ohos.window";
import { JSON } from "@kit.ArkTS";
import { FloatWindowManager } from "../window/FloatWindow";
import { common } from "@kit.AbilityKit";
import { smartMobilityCommon } from "@kit.CarKit";

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';

  aboutToAppear(): void {
    this.createFloatWindow();
  }

  private createFloatWindow(): void {
    const displayId = 0;
    const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    FloatWindowManager.create(context, displayId); // displayId = 0 表示主屏幕
  }

  build() {
    Row()
      .width('100%')
      .height('100%')
      .backgroundColor(Color.Black)
  }
}
