import { HomeAppSection } from './HomeAppsTab';

@Component
export struct HomeCarTab {
  @Link isCasting: boolean;

  build() {
    Column({ space: 16 }) {
      this.CarCard()
      HomeAppSection()
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
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
            this.isCasting = !this.isCasting;
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
    .borderRadius(24)
    .backgroundColor(Color.White)
    .shadow({ radius: 24, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 8 })
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.65)' })
  }

  @Builder
  private BatteryInfoCard() {
    Column({ space: 10 }) {
      Row() {
        Text('电量')
          .fontSize(12)
          .fontColor('#414754')

        Blank()

        Text('85%')
          .fontSize(12)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007DFF')
      }
      .width('100%')

      Stack({ alignContent: Alignment.Start }) {
        Rect()
          .width('100%')
          .height(6)
          .radius(3)
          .fill('#E5E2E1')

        Rect()
          .width('85%')
          .height(6)
          .radius(3)
          .fill('#007DFF')
      }
      .width('100%')
      .height(6)
    }
    .justifyContent(FlexAlign.Center)
    .height(56)
    .width('100%')
    .padding({ left: 12, right: 12 })
    .borderRadius(24)
    .backgroundColor(Color.White)
    .shadow({ radius: 24, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 8 })
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.65)' })
  }
}
