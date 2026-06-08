@Component
export struct HomeProfileTab {
  @Prop isCasting: boolean;

  build() {
    Column({ space: 16 }) {
      this.ProfileHeader()

      Grid() {
        GridItem() {
          this.StatCard('12.4k', '积分')
        }

        GridItem() {
          this.StatCard('08', '优惠券')
        }

        GridItem() {
          this.StatCard('24', '订单')
        }
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(12)
      .width('100%')
      .height(88)

      Column({ space: 0 }) {
        this.MenuRow($r('app.media.ic_profile_security'), '系统设置')
        this.MenuDivider()
        this.MenuRow($r('app.media.ic_profile_devices'), '投屏设置')
        this.MenuDivider()
        this.MenuRow($r('app.media.ic_profile_feedback'), '意见反馈')
        this.MenuDivider()
        this.MenuRow($r('app.media.ic_profile_about'), '关于')
      }
      .width('100%')
      .borderRadius(24)
      .backgroundColor(Color.White)
      .shadow({ radius: 24, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 8 })
      .border({ width: 1, color: 'rgba(255, 255, 255, 0.65)' })
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }

  @Builder
  private ProfileHeader() {
    Column({ space: 12 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        Stack({ alignContent: Alignment.Center }) {
          Text('比')
            .fontSize(36)
            .fontWeight(FontWeight.Bold)
            .fontColor(Color.White)
        }
        .width(96)
        .height(96)
        .borderRadius(48)
        .linearGradient({
          angle: 135,
          colors: [['#007DFF', 0.0], ['#8BB8FF', 1.0]]
        })
        .border({ width: 4, color: Color.White })
        .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 6 })

        Stack({ alignContent: Alignment.Center }) {
          Image($r('app.media.ic_profile_verified'))
            .width(20)
            .height(20)
        }
        .width(24)
        .height(24)
        .borderRadius(12)
        .backgroundColor('#007DFF')
        .border({ width: 2, color: Color.White })
      }
      .width(104)
      .height(104)

      Column({ space: 6 }) {
        Text('比丢小淘气')
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1B1B')

        Text('钻享会员')
          .fontSize(10)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007DFF')
          .padding({ left: 12, right: 12, top: 3, bottom: 3 })
          .borderRadius(10)
          .backgroundColor('rgba(0, 125, 255, 0.10)')
      }
      .alignItems(HorizontalAlign.Center)
    }
    .alignItems(HorizontalAlign.Center)
    .width('100%')
    .padding({ top: 8, bottom: 8 })
  }

  @Builder
  private StatCard(value: string, label: string) {
    Column({ space: 4 }) {
      Text(value)
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1B1B')

      Text(label)
        .fontSize(12)
        .fontColor('#414754')
    }
    .justifyContent(FlexAlign.Center)
    .width('100%')
    .height(72)
    .borderRadius(24)
    .backgroundColor(Color.White)
    .shadow({ radius: 24, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 8 })
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.65)' })
  }

  @Builder
  private MenuRow(icon: Resource, label: string) {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        Image(icon)
          .width(20)
          .height(20)
      }
      .width(28)
      .height(28)
      .borderRadius(14)
      .backgroundColor('#F6F3F2')

      Text(label)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1B1B')

      Blank()

      Image($r('app.media.ic_profile_chevron'))
        .width(20)
        .height(20)
    }
    .width('100%')
    .height(56)
    .padding({ left: 16, right: 16 })
  }

  @Builder
  private MenuDivider() {
    Divider()
      .strokeWidth(1)
      .color('#EEEAE8')
      .margin({ left: 56, right: 16 })
  }
}
