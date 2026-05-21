import libhdc  from "libhdc.so";


@Entry
@Component
struct HdcPage {
  @State message: string = '';

  build() {
    Column() {
      Text("获取应用列表")
        .padding({top:"100dp"})
        .fontSize('40fp')
        .onClick( async() => {
          console.log("->hdc try");
          this.message =await libhdc.hdc(1);
        })
      Text(this.message)
    }
    .height('100%')
    .width('100%')
  }
}