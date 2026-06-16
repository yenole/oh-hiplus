@CustomDialog
export struct PortInputDialog {
  controller: CustomDialogController;
  @State inputPort: string = '';
  onConfirm?: (port: string) => void;

  build() {
    Column({ space: 16 }) {
      Text('设置无线调试端口')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1B1B')
        .width('100%')

      Text('请输入无线调试端口号（例如：5555）')
        .fontSize(14)
        .fontColor('#666666')
        .width('100%')

      TextInput({ placeholder: '请输入端口号', text: this.inputPort })
        .type(InputType.Number)
        .maxLength(5)
        .onChange((value: string) => {
          this.inputPort = value;
        })
        .width('100%')
        .height(48)
        .borderRadius(8)
        .backgroundColor('#F5F5F5')

      Row({ space: 12 }) {
        Button('取消')
          .fontSize(16)
          .fontColor('#666666')
          .backgroundColor('#F5F5F5')
          .width('48%')
          .height(44)
          .borderRadius(8)
          .onClick(() => {
            this.controller.close();
          })

        Button('确定')
          .fontSize(16)
          .fontColor(Color.White)
          .backgroundColor('#007DFF')
          .width('48%')
          .height(44)
          .borderRadius(8)
          .onClick(() => {
            if (this.inputPort && this.onConfirm) {
              this.onConfirm(this.inputPort);
            }
            this.controller.close();
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .padding(24)
    .margin({ left: 24, right: 24 })
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(16)
  }
}
