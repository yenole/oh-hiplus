import {hapVersion, initAgent, startAgent} from "libohos.so";
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
    if (!this.wirelessDebugPort) {
      console.error('无线调试端口未设置，无法初始化投屏 Agent');
      this.showPortInputDialog();
      return;
    }

    const port = parseInt(this.wirelessDebugPort, 10);
    initAgent(port)
      .then((result: string) => {
        console.info(`initAgent succeeded: ${result}`);
        return startAgent(port);
      })
      .then((result: string) => {
        console.info(`startAgent succeeded: ${result}`);
      })
      .catch((error: Error) => {
        console.error('初始化或启动投屏 Agent 失败:', error);
      });

    let awareness = smartMobilityCommon.getSmartMobilityAwareness();
    let status = awareness.getSmartMobilityStatus(smartMobilityCommon.SmartMobilityType.HICAR)
    if (status.status == 0) {
      this.getUIContext().getPromptAction().showToast({
        message: '请先连接HiCar！'
      });
      return;
             const want: Want = {
       bundleName: this.context.abilityInfo.bundleName,
       abilityName: 'LauncherAbility'
     };
    
     this.context.startAbility(want, (err) => {
       if (err.code) {
         console.error(`Failed to start LauncherAbility. Code: ${err.code}, message: ${err.message}`);
         return;
       }
       console.info('Succeeded in starting LauncherAbility.');
       this.isCasting = true;
     });

      return
    }
    let displayId = status.data["DISPLAY_ID"].toString() || "0";
    let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
    FloatWindowManager.create(context, parseInt(displayId)); // displayId = 0 表示主屏幕

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
      maskColor: $r('app.color.mask_color'),
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
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .textAlign(TextAlign.Center)

        Text('请输入无线调试端口号（例如：5555）')
          .fontSize(14)
          .fontColor($r('app.color.text_secondary'))
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
          .backgroundColor($r('app.color.bg_fill'))

        Row({ space: 12 }) {
          Button('取消')
            .fontSize(16)
            .fontColor($r('app.color.text_secondary'))
            .backgroundColor($r('app.color.bg_fill'))
            .layoutWeight(1)
            .height(44)
            .borderRadius(8)
            .onClick(() => {
              this.showPortInputSheet = false;
            })

          Button('确定')
            .fontSize(16)
            .fontColor($r('app.color.text_on_accent'))
            .backgroundColor($r('app.color.accent'))
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
    .backgroundColor($r('app.color.bg_sheet'))
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
            .fontColor($r('app.color.text_primary'))

          Row({ space: 6 }) {
            Circle()
              .width(8)
              .height(6)
              .fill($r('app.color.accent'))

            Text(this.isCasting ? '已连接 | 投屏中' : '已连接 | 待机中')
              .fontSize(12)
              .fontWeight(FontWeight.Medium)
              .fontColor($r('app.color.text_secondary'))
          }
        }
        .margin({ left: 16, top: 16 })

        Row() {
          Blank()

          Row({ space: 8 }) {
            Text(this.isCasting ? '停止投屏' : '投屏')
              .fontSize(14)
              .fontWeight(FontWeight.Medium)
              .fontColor(this.isCasting ? $r('app.color.text_on_accent') : $r('app.color.text_primary'))
          }
          .height(40)
          .padding({ left: 16, right: 16 })
          .borderRadius(20)
          .backgroundColor(this.isCasting ? $r('app.color.accent') : $r('app.color.bg_pill'))
          .shadow({ radius: 8, color: $r('app.color.shadow_soft'), offsetX: 0, offsetY: 2 })
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
      .backgroundColor($r('app.color.bg_card'))
      .borderRadius({ bottomLeft: 24, bottomRight: 24 })
    }
    .width('100%')
    .backgroundColor($r('app.color.bg_card'))
    .borderRadius(24)
    .shadow({ radius: 24, color: $r('app.color.shadow_card'), offsetX: 0, offsetY: 8 })
    .border({ width: 1, color: $r('app.color.bg_card_border') })
  }

  @Builder
  private CarHeroBackground() {
    Stack({ alignContent: Alignment.Center }) {
      Column()
        .width('100%')
        .height('100%')
        .linearGradient({
          angle: 135,
          colors: [
            [$r('app.color.hero_gradient_start'), 0.0],
            [$r('app.color.hero_gradient_mid'), 0.52],
            [$r('app.color.hero_gradient_end'), 1.0]
          ]
        })

      Image($r('app.media.home_car'))
        .width('100%')
        .height('100%')
        .objectFit(ImageFit.Cover)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.hero_base'))
  }

  @Builder
  private RangeInfoCard() {
    Column({ space: 6 }) {
      Text('剩余续航')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))

      Text('520 km')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .height(56)
    .width('100%')
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.bg_card'))
    .border({ width: 1, color: $r('app.color.bg_card_border') })
  }

  @Builder
  private BatteryInfoCard() {
    Column({ space: 6 }) {
      Text('今日温度')
        .fontSize(12)
        .fontColor($r('app.color.text_secondary'))

      Text('24°C')
        .fontSize(16)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))
    }
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Center)
    .height(56)
    .width('100%')
    .padding({ left: 12, right: 12 })
    .backgroundColor($r('app.color.bg_card'))
    .border({ width: 1, color: $r('app.color.bg_card_border') })
  }
}
