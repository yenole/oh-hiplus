import {hapVersion} from "libohos.so";
import { common, Want } from '@kit.AbilityKit';
import { smartMobilityCommon } from "@kit.CarKit";
import preferences from '@ohos.data.preferences';
import { FloatWindowManager } from "../../window/FloatWindow";
import { PortInputDialog } from "../../components/PortInputDialog";


interface GeneratedObjectLiteralInterface_1 {
  bundleName: string;
  abilityName: string;
}

@Component
export struct HomeCarTab {
  @Link isCasting: boolean;
  private context = getContext(this) as common.UIAbilityContext;
  @State wirelessDebugPort: string = '';
  @State showPortInputSheet: boolean = false;
  private preferencesInstance: preferences.Preferences | null = null;

  aboutToAppear(): void {
    this.onPageLoad();
  }

  private async onPageLoad(): Promise<void> {
    // 页面加载时执行的代码
    console.info('HomeCarTab page loaded');
    
    // 初始化 Preferences
    this.preferencesInstance = await preferences.getPreferences(this.context, 'app_preferences');
    
    // 获取无线调试端口
    await this.getWirelessDebugPort();
    
    // 在这里添加你需要的初始化逻辑
    if (this.wirelessDebugPort) {
      const port = parseInt(this.wirelessDebugPort);
      const version: string = await hapVersion(port, "com.huawei.hmos.hicar")
      console.log(`->>version:${version}`)
    }
  }

  /**
   * 获取无线调试端口，如果没有则弹框让用户输入
   */
  private async getWirelessDebugPort(): Promise<void> {
    try {
      if (!this.preferencesInstance) {
        console.error('Preferences not initialized');
        return;
      }
      
      const savedPort = await this.preferencesInstance.get('wireless_debug_port', '') as string;
      
      if (savedPort) {
        this.wirelessDebugPort = savedPort;
        console.log(`已加载保存的无线调试端口: ${savedPort}`);
      } else {
        // 没有保存的端口，弹框让用户输入
        this.showPortInputDialog();
      }
    } catch (error) {
      console.error('获取无线调试端口失败:', error);
    }
  }

  /**
   * 显示端口输入对话框
   */
  private showPortInputDialog(): void {
    this.showPortInputSheet = true;
  }

  private startLauncherAbility(): void {
return
    let awareness = smartMobilityCommon.getSmartMobilityAwareness();
    let status = awareness.getSmartMobilityStatus(smartMobilityCommon.SmartMobilityType.HICAR)
    if (status.status == 0) {
      return
    }
    let displayId = status.data["DISPLAY_ID"].toString() || "0";
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    FloatWindowManager.create(context, parseInt(displayId)); // displayId = 0 表示主屏幕
    // const want: Want = {
    //   bundleName: this.context.abilityInfo.bundleName,
    //   abilityName: 'LauncherAbility'
    // };
    //
    // this.context.startAbility(want, (err) => {
    //   if (err.code) {
    //     console.error(`Failed to start LauncherAbility. Code: ${err.code}, message: ${err.message}`);
    //     return;
    //   }
    //   console.info('Succeeded in starting LauncherAbility.');
    //   this.isCasting = true;
    // });
  }

  build() {
    Column({ space: 16 }) {
      this.CarCard()
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
    .bindSheet($$this.showPortInputSheet, this.PortInputSheetBuilder(), {
      height: SheetSize.FIT_CONTENT,
      showClose: false,
      dragBar: true,
      maskColor: 'rgba(0, 0, 0, 0.6)',
      shouldDismiss: (sheetDismiss: SheetDismiss) => {
        console.log("sheet should dismiss")
      }
    })
  }

  @Builder
  private PortInputSheetBuilder() {
    Scroll() {
      Column({ space: 16 }) {
        Text('设置无线调试端口')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1B1B')
          .width('100%')
          .textAlign(TextAlign.Center)

        Text('请输入无线调试端口号（例如：5555）')
          .fontSize(14)
          .fontColor('#666666')
          .width('100%')

        TextInput({ placeholder: '请输入端口号', text: this.wirelessDebugPort })
          .type(InputType.Number)
          .maxLength(5)
          .onChange((value: string) => {
            this.wirelessDebugPort = value;
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
            .layoutWeight(1)
            .height(44)
            .borderRadius(8)
            .onClick(() => {
              this.showPortInputSheet = false;
            })

          Button('确定')
            .fontSize(16)
            .fontColor(Color.White)
            .backgroundColor('#007DFF')
            .layoutWeight(1)
            .height(44)
            .borderRadius(8)
            .onClick(async () => {
              if (this.wirelessDebugPort && this.preferencesInstance) {
                await this.preferencesInstance.put('wireless_debug_port', this.wirelessDebugPort);
                await this.preferencesInstance.flush();
                console.log(`已保存无线调试端口: ${this.wirelessDebugPort}`);
                this.showPortInputSheet = false;
              }
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
      }
      .padding({ left: 24, right: 24, top: 24, bottom: 40 })
      .width('100%')
    }
    .scrollable(ScrollDirection.Vertical)
    .scrollBar(BarState.Off)
    .width('100%')
    .backgroundColor(Color.White)
  }

  @Builder
  private CarCard() {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        this.CarHeroBackground()

        Column({ space: 6 }) {
          Text('我的爱车')
            .fontSize(20)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1B1B')

          Row({ space: 6 }) {
            Circle()
              .width(8)
              .height(6)
              .fill('#007DFF')

            Text(this.isCasting ? '已连接 | 投屏中' : '已连接 | 待机中')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor('#414754')
          }
        }
        .margin({ left: 16, top: 16 })

        Row() {
          Blank()

          Row({ space: 8 }) {
            Text(this.isCasting ? '停止投屏' : '投屏')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isCasting ? Color.White : '#1C1B1B')
          }
          .height(40)
          .padding({ left: 16, right: 16 })
          .borderRadius(20)
          .backgroundColor(this.isCasting ? '#007DFF' : 'rgba(255, 255, 255, 0.92)')
          .shadow({ radius: 8, color: 'rgba(0, 0, 0, 0.08)', offsetX: 0, offsetY: 2 })
          .onClick(() => {
            if (!this.isCasting) {
              this.startLauncherAbility();
            } else {
              this.isCasting = false;
            }
          })
        }
        .width('100%')
        .padding({ right: 16 })
        .position({ x: 0, y: 136 })
      }
      .width('100%')
      .height(192)
      .borderRadius({ topLeft: 24, topRight: 24 })
      .clip(true)

      Grid() {
        GridItem() {
          this.RangeInfoCard()
        }

        GridItem() {
          this.BatteryInfoCard()
        }
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(12)
      .width('100%')
      .height(88)
      .padding(16)
      .backgroundColor(Color.White)
      .borderRadius({ bottomLeft: 24, bottomRight: 24 })
    }
    .width('100%')
    .backgroundColor(Color.White)
    .borderRadius(24)
    .shadow({ radius: 24, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 8 })
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.65)' })
  }

  @Builder
  private CarHeroBackground() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [['#F7FAFF', 0.0], ['#EAF1FA', 0.52], ['#D9E4F2', 1.0]]
        })

      Image($r('app.media.home_car'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F6F3F2')
  }

  @Builder
  private RangeInfoCard() {
    Column({ space: 6 }) {
      Text('剩余续航')
        .fontSize(12)
        .fontColor('#414754')

      Text('520 km')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1B1B')
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .height(56)
    .width('100%')
    .padding({ left: 12, right: 12 })
    .backgroundColor(Color.White)
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.65)' })
  }

  @Builder
  private BatteryInfoCard() {
    Column({ space: 6 }) {
      Text('今日温度')
        .fontSize(12)
        .fontColor('#414754')

      Text('24°C')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1B1B')
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .height(56)
    .width('100%')
    .padding({ left: 12, right: 12 })
    .backgroundColor(Color.White)
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.65)' })
  }
}
