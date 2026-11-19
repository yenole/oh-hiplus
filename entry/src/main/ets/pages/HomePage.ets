import { HomeAppsTab } from './tabs/HomeAppsTab';
import { HomeCarTab } from './tabs/HomeCarTab';
import { HomeProfileTab } from './tabs/HomeProfileTab';

@Entry
@Component
struct HomePage {
  @State isCasting: boolean = false;
  @State selectedTab: number = 0;
  private swiperController: SwiperController = new SwiperController();

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        this.TopBar()

        Swiper(this.swiperController) {
          this.TabContent(0)
          this.TabContent(1)
          this.TabContent(2)
        }
        .layoutWeight(1)
        .width('100%')
        .index(this.selectedTab)
        .loop(false)
        .indicator(false)
        .duration(300)
        .onChange((index: number) => {
          this.selectedTab = index;
        })
      }
      .height('100%')
      .width('100%')

      this.BottomNavBar()
    }
    .height('100%')
    .width('100%')
    .backgroundColor($r('app.color.bg_page'))
  }

  @Builder
  private TabContent(index: number) {
    if (index === 0) {
      HomeCarTab({ isCasting: $isCasting })
        .height('100%')
        .width('100%')
    } else if (index === 1) {
      HomeAppsTab()
        .height('100%')
        .width('100%')
    } else {
      HomeProfileTab({ isCasting: this.isCasting })
        .height('100%')
        .width('100%')
    }
  }

  @Builder
  private TopBar() {
    Row() {
      Text(this.currentTitle())
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Blank()

      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_notification'))
          .width(24)
          .height(24)
      }
      .width(40)
      .height(40)
      .backgroundColor(Color.Transparent)
    }
    .width('100%')
    .height(64)
    .padding({ left: 16, right: 16 })
  }

  private currentTitle(): string {
    if (this.selectedTab === 0) {
      return 'Hi时刻';
    }
    if (this.selectedTab === 1) {
      return '我的应用';
    }
    return '我的';
  }

  @Builder
  private BottomNavBar() {
    Stack({ alignContent: Alignment.Center }) {
      Row()
        .width(236)
        .height(32)
        .borderRadius(16)
        .backgroundColor($r('app.color.nav_glow_bg'))
        .shadow({ radius: 36, color: $r('app.color.nav_glow_shadow'), offsetX: 0, offsetY: 0 })
        .position({ x: 38, y: 28 })

      Row()
        .width(178)
        .height(24)
        .borderRadius(12)
        .backgroundColor($r('app.color.nav_glass'))
        .shadow({ radius: 24, color: $r('app.color.nav_glass_shadow'), offsetX: 0, offsetY: 0 })
        .position({ x: 66, y: 12 })

      Row() {
        this.NavItem(0, $r('app.media.tab_car_active'), $r('app.media.tab_car'), '爱车')
        this.NavItem(1, $r('app.media.tab_apps_active'), $r('app.media.tab_apps'), '应用')
        this.NavItem(2, $r('app.media.tab_profile_active'), $r('app.media.tab_profile'), '我的')
      }
      .height(60)
      .width(292)
      .padding({ left: 8, right: 8 })
      .borderRadius(30)
      .backgroundColor($r('app.color.nav_bg'))
      .border({ width: 1, color: $r('app.color.nav_border') })
      .shadow({ radius: 34, color: $r('app.color.nav_shadow'), offsetX: 0, offsetY: 10 })
    }
    .width(312)
    .height(80)
    .margin({ bottom: 4 })
    .align(Alignment.Bottom)
  }

  @Builder
  private NavItem(index: number, activeIcon: Resource, icon: Resource, label: string) {
    Stack({ alignContent: Alignment.Center }) {
      if (this.selectedTab === index) {
        Row()
          .width(72)
          .height(44)
          .borderRadius(22)
          .backgroundColor($r('app.color.accent_soft'))
          .shadow({ radius: 22, color: $r('app.color.accent_glow'), offsetX: 0, offsetY: 0 })
      }

      Column({ space: 2 }) {
        Image(this.selectedTab === index ? activeIcon : icon)
          .width(22)
          .height(22)

        Text(label)
          .fontSize(12)
          .fontWeight(this.selectedTab === index ? FontWeight.Bold : FontWeight.Medium)
          .fontColor(this.selectedTab === index ? $r('app.color.accent') : $r('app.color.text_secondary'))
      }
      .justifyContent(FlexAlign.Center)
    }
    .width(92)
    .height(60)
    .onClick(() => {
      this.selectedTab = index;
      this.swiperController.changeIndex(index);
    })
  }
}
