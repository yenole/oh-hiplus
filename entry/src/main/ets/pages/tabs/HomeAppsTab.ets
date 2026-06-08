@Component
export struct HomeAppsTab {
  private readonly recentApps: AppItem[] = [
    { name: '优酷', icon: '▶', iconColor: '#BA1A1A', bgColor: '#FCEAEA' },
    { name: '腾讯视频', icon: '●', iconColor: '#00A870', bgColor: '#E8F8F0' },
    { name: '网易云音乐', icon: '♪', iconColor: '#C20C0C', bgColor: '#FCE7E7' },
    { name: '浏览器', icon: '○', iconColor: '#007DFF', bgColor: '#E8F2FF' }
  ];

  build() {
    Scroll() {
      Column({ space: 20 }) {

        Column({ space: 16 }) {
          Row() {
            Text('最近使用')
              .fontSize(15)
              .fontWeight(FontWeight.Bold)
              .fontColor('#1C1B1B')

            Blank()

            Text('查看更多')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#007DFF')
          }
          .width('100%')

          Row() {
            ForEach(this.recentApps, (app: AppItem) => {
              this.RecentAppItem(app)
            }, (app: AppItem) => app.name)
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
        }
        .width('100%')

        Column({ space: 16 }) {
          Text('全部分类')
            .fontSize(15)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1B1B')
            .width('100%')

          this.VideoCategoryCard()
          this.MusicCategoryCard()
          this.ToolsCategoryCard()
        }
        .width('100%')
      }
      .width('100%')
      .padding({ left: 16, right: 16, top: 8, bottom: 120 })
    }
    .height('100%')
    .width('100%')
    .scrollBar(BarState.Off)
  }

  @Builder
  private RecentAppItem(app: AppItem) {
    Column({ space: 8 }) {
      Stack({ alignContent: Alignment.Center }) {
        Text(app.icon)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor(app.iconColor)
      }
      .width(56)
      .height(56)
      .borderRadius(18)
      .backgroundColor(app.bgColor)
      .shadow({ radius: 20, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 6 })
      .border({ width: 1, color: 'rgba(255, 255, 255, 0.65)' })

      Text(app.name)
        .fontSize(12)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1B1B')
        .maxLines(1)
    }
    .width(68)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  private VideoCategoryCard() {
    Column({ space: 8 }) {
      this.CategoryTitle($r('app.media.ic_category_video'), '视频类')

      Grid() {
        GridItem() {
          this.AppRowItem('▶', '优酷')
        }

        GridItem() {
          this.AppRowItem('●', '腾讯视频')
        }

        GridItem() {
          this.AppRowItem('爱', '爱奇艺')
        }

        GridItem() {
          this.AppRowItem('芒', '芒果TV')
        }
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(4)
      .rowsGap(2)
      .width('100%')
      .height(84)
      .clip(false)
    }
    .width('100%')
    .padding(16)
    .borderRadius(24)
    .backgroundColor(Color.White)
    .shadow({ radius: 24, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 8 })
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.65)' })
  }

  @Builder
  private MusicCategoryCard() {
    Column({ space: 8 }) {
      this.CategoryTitle($r('app.media.ic_category_music'), '音乐类')

      Grid() {
        GridItem() {
          this.AppRowItem('≋', '网易云')
        }

        GridItem() {
          this.AppRowItem('♫', 'QQ音乐')
        }

        GridItem() {
          this.AppRowItem('◎', '酷狗')
        }
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(4)
      .width('100%')
      .height(44)
    }
    .width('100%')
    .padding(16)
    .borderRadius(24)
    .backgroundColor(Color.White)
    .shadow({ radius: 24, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 8 })
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.65)' })
  }

  @Builder
  private ToolsCategoryCard() {
    Column({ space: 8 }) {
      this.CategoryTitle($r('app.media.ic_category_tools'), '工具类')

      Column({ space: 0 }) {
        this.ToolRow($r('app.media.ic_tool_local_file'), '本地文件')
        this.ToolRow($r('app.media.ic_tool_browser'), '浏览器')
      }
      .width('100%')
    }
    .width('100%')
    .padding(16)
    .borderRadius(24)
    .backgroundColor(Color.White)
    .shadow({ radius: 24, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 8 })
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.65)' })
  }

  @Builder
  private CategoryTitle(icon: Resource, title: string) {
    Row({ space: 8 }) {
      Image(icon)
        .width(30)
        .height(30)

      Text(title)
        .fontSize(15)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1B1B')
    }
    .width('100%')
  }

  @Builder
  private AppRowItem(icon: string, label: string) {
    Row({ space: 8 }) {
      Stack({ alignContent: Alignment.Center }) {
        Text(icon)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#007DFF')
      }
      .width(32)
      .height(32)
      .borderRadius(16)
      .backgroundColor('rgba(0, 125, 255, 0.10)')

      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1B1B')
        .maxLines(1)
    }
    .width('100%')
    .height(44)
    .padding({ left: 4, right: 4 })
  }

  @Builder
  private ToolRow(icon: Resource, label: string) {
    Row({ space: 12 }) {
      Image(icon)
        .width(28)
        .height(28)

      Text(label)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1B1B')

      Blank()

      Text('›')
        .fontSize(20)
        .fontColor('#717786')
    }
    .width('100%')
    .height(44)
    .padding({ left: 4, right: 4 })
  }
}

@Component
export struct HomeAppSection {
  private readonly apps: AppItem[] = [
    { name: '优酷', icon: '▶', iconColor: '#BA1A1A', bgColor: '#FCEAEA' },
    { name: '腾讯视频', icon: '●', iconColor: '#93000A', bgColor: '#F8E8EA' },
    { name: '网易云音乐', icon: '♪', iconColor: '#C20C0C', bgColor: '#FCE7E7' },
    { name: '本地文件', icon: '□', iconColor: '#007DFF', bgColor: '#E8F2FF' }
  ];

  build() {
    Column({ space: 12 }) {
      Grid() {
        ForEach(this.apps, (app: AppItem) => {
          GridItem() {
            this.AppCard(app)
          }
        }, (app: AppItem) => app.name)
      }
      .columnsTemplate('1fr 1fr')
      .columnsGap(8)
      .rowsGap(12)
      .width('100%')
      .height(124)
    }
    .width('100%')
  }

  @Builder
  private AppCard(app: AppItem) {
    Row({ space: 12 }) {
      Stack({ alignContent: Alignment.Center }) {
        Text(app.icon)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(app.iconColor)
      }
      .width(32)
      .height(32)
      .borderRadius(8)
      .backgroundColor(app.bgColor)

      Text(app.name)
        .fontSize(14)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1B1B')
        .maxLines(1)
    }
    .width('100%')
    .height(48)
    .padding({ left: 12, right: 12 })
    .borderRadius(24)
    .backgroundColor(Color.White)
    .shadow({ radius: 24, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 8 })
    .border({ width: 1, color: 'rgba(255, 255, 255, 0.65)' })
  }
}

interface AppItem {
  name: string;
  icon: string;
  iconColor: string;
  bgColor: string;
}
