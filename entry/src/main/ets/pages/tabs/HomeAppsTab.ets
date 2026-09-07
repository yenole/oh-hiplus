import {haps} from "libohos.so";
import { HapApp } from "../../../../../libs";
import preferences from '@ohos.data.preferences';

@Component
export struct HomeAppsTab {
  @State private videoApps: HapApp[] = [];
  @State private musicApps: HapApp[] = [];
  @State private navigationApps: HapApp[] = [];
  @State private otherCategories: Map<string, HapApp[]> = new Map();
  @State private isLoading: boolean = true;
  @State private isRefreshing: boolean = false;
  @State private showCategorySheet: boolean = false;
  @State private selectedCategory: string = '';
  @State private selectedCategoryApps: HapApp[] = [];
  private hapApps: HapApp[] = [];
  private readonly CACHE_KEY = 'hap_apps_cache';
  private wirelessDebugPort: number = 0;

  aboutToAppear(): void {
    this.loadApps();
  }

  private async getWirelessDebugPort(): Promise<number> {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'app_preferences');
      const savedPort = await prefs.get('wireless_debug_port', '') as string;
      
      if (savedPort) {
        return parseInt(savedPort);
      }
      
      return 0;
    } catch (error) {
      console.error('HomeAppsTab: Failed to get wireless debug port', error);
      return 0;
    }
  }

  private async loadFromCache(): Promise<HapApp[] | null> {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'hap_apps_storage');
      
      const cachedData = await prefs.get(this.CACHE_KEY, '');
      
      if (cachedData) {
        const apps = JSON.parse(cachedData as string) as HapApp[];
        console.info('HomeAppsTab: Loaded apps from cache');
        return apps;
      }
      
      return null;
    } catch (error) {
      console.error('HomeAppsTab: Failed to load cache', error);
      return null;
    }
  }

  private async saveToCache(apps: HapApp[]): Promise<void> {
    try {
      const context = getContext(this);
      const prefs = await preferences.getPreferences(context, 'hap_apps_storage');
      
      await prefs.put(this.CACHE_KEY, JSON.stringify(apps));
      await prefs.flush();
      
      console.info('HomeAppsTab: Saved apps to cache');
    } catch (error) {
      console.error('HomeAppsTab: Failed to save cache', error);
    }
  }

  private async refreshApps(): Promise<void> {
    this.isRefreshing = true;
    
    try {
      // 获取无线调试端口
      if (this.wirelessDebugPort === 0) {
        this.wirelessDebugPort = await this.getWirelessDebugPort();
      }
      
      if (this.wirelessDebugPort === 0) {
        console.error('HomeAppsTab: Wireless debug port not set');
        return;
      }
      
      // 从API重新加载所有应用
      const allApps: HapApp[] = await haps(this.wirelessDebugPort);
      
      // 过滤掉 com.huawei.hmos.hicar 包名
      const apps = allApps.filter(app => app.package !== 'com.huawei.hmos.hicar');
      
      // 保存到缓存
      await this.saveToCache(apps);
      
      // 更新数据
      this.hapApps = apps;
      this.videoApps = apps.filter(app => app.category === '影视与直播');
      this.musicApps = apps.filter(app => app.category === '音乐');
      this.navigationApps = apps.filter(app => app.category === '出行导航');
      
      const otherApps = apps.filter(app => 
        app.category !== '影视与直播' && 
        app.category !== '音乐' && 
        app.category !== '出行导航'
      );
      const categoryMap = new Map<string, HapApp[]>();
      otherApps.forEach(app => {
        const category = app.category || '其他';
        if (!categoryMap.has(category)) {
          categoryMap.set(category, []);
        }
        categoryMap.get(category)!.push(app);
      });
      this.otherCategories = categoryMap;
      
      console.info('HomeAppsTab: Apps refreshed successfully');
    } catch (error) {
      console.error('HomeAppsTab: Failed to refresh apps', error);
    } finally {
      this.isRefreshing = false;
    }
  }

  private async loadApps(): Promise<void> {
    // 如果已经加载过，直接返回
    if (this.hapApps.length > 0) {
      console.info('HomeAppsTab: Apps already loaded, skipping...');
      return;
    }

    this.isLoading = true;

    // 获取无线调试端口
    this.wirelessDebugPort = await this.getWirelessDebugPort();
    
    if (this.wirelessDebugPort === 0) {
      console.error('HomeAppsTab: Wireless debug port not set');
      this.isLoading = false;
      return;
    }

    // 关闭自动刷新时优先使用缓存，否则进入应用页时获取最新列表
    const appPreferences = await preferences.getPreferences(getContext(this), 'app_preferences');
    const autoRefresh = await appPreferences.get('auto_refresh_apps', true) as boolean;
    const cachedApps = autoRefresh ? null : await this.loadFromCache();
    let apps: HapApp[];
    
    if (cachedApps) {
      apps = cachedApps;
    } else {
      // 从API加载所有应用
      const allApps: HapApp[] = await haps(this.wirelessDebugPort);
      
      // 过滤掉 com.huawei.hmos.hicar 包名
      apps = allApps.filter(app => app.package !== 'com.huawei.hmos.hicar');
      
      // 保存到缓存
      await this.saveToCache(apps);
    }
    
    this.hapApps = apps;
    
    // 筛选视频类应用 - category = 影视与直播
    this.videoApps = apps.filter(app => app.category === '影视与直播');
    
    // 筛选音乐类应用 - category = 音乐
    this.musicApps = apps.filter(app => app.category === '音乐');
    
    // 筛选出行导航类应用 - category = 出行导航
    this.navigationApps = apps.filter(app => app.category === '出行导航');
    
    // 其他分类归类为工具类，按 category 分组
    const otherApps = apps.filter(app => 
      app.category !== '影视与直播' && 
      app.category !== '音乐' && 
      app.category !== '出行导航'
    );
    const categoryMap = new Map<string, HapApp[]>();
    otherApps.forEach(app => {
      const category = app.category || '其他';
      if (!categoryMap.has(category)) {
        categoryMap.set(category, []);
      }
      categoryMap.get(category)!.push(app);
    });
    this.otherCategories = categoryMap;
    
    this.isLoading = false;
    
    console.info('HomeAppsTab: Loading apps...');
    for (let app of apps) {
      console.log(`->${app.name} ${app.package} ${app.category}`);
    }
    console.info(`HomeAppsTab: Loaded ${this.videoApps.length} video apps with category = 影视与直播`);
    console.info(`HomeAppsTab: Loaded ${this.musicApps.length} music apps with category = 音乐`);
    console.info(`HomeAppsTab: Loaded ${this.navigationApps.length} navigation apps with category = 出行导航`);
    console.info(`HomeAppsTab: Loaded ${otherApps.length} other apps in ${this.otherCategories.size} categories`);
  }

  build() {
    if (this.isLoading) {
      Column() {
        LoadingProgress()
          .width(60)
          .height(60)
          .color('#007DFF')
        
        Text('加载中...')
          .fontSize(14)
          .fontColor('#717786')
          .margin({ top: 12 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else {
      Refresh({ refreshing: $$this.isRefreshing }) {
        Scroll() {
          Column({ space: 20 }) {
            this.NavigationCategoryCard()
            this.MusicCategoryCard()
            this.VideoCategoryCard()
            this.ToolsCategoryCard()
          }
          .width('100%')
          .padding({ left: 16, right: 16, top: 8, bottom: 120 })
          .alignItems(HorizontalAlign.Start)
        }
        .height('100%')
        .width('100%')
        .scrollBar(BarState.Off)
        .align(Alignment.Top)
      }
      .onRefreshing(() => {
        this.refreshApps();
      })
      .width('100%')
      .height('100%')
      .bindSheet($$this.showCategorySheet, this.CategoryDetailSheet(), {
        height: '70%',
        backgroundColor: Color.White,
        dragBar: false,
        showClose: false
      })
    }
  }

  @Builder
  private CategoryDetailSheet() {
    Column({ space: 0 }) {
      // 标题栏
      Text(this.selectedCategory)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#1C1B1B')
        .width('100%')
        .height(60)
        .textAlign(TextAlign.Center)
        .padding(16)

      Scroll() {
        Column({ space: 12 }) {
          ForEach(this.selectedCategoryApps, (app: HapApp) => {
            this.AppDetailItem(app)
          }, (app: HapApp) => app.package)
        }
        .width('100%')
        .padding({ left: 16, right: 16, bottom: 32 })
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  private AppDetailItem(app: HapApp) {
    Row({ space: 12 }) {
      Image(app.icon)
        .width(48)
        .height(48)
        .borderRadius(24)

      Column({ space: 4 }) {
        Text(app.name)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
          .fontColor('#1C1B1B')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(app.package)
          .fontSize(12)
          .fontColor('#717786')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width('100%')
    .padding(12)
    .borderRadius(12)
    .backgroundColor('#F5F5F5')
  }

  @Builder
  private VideoCategoryCard() {
    Column({ space: 8 }) {
      this.CategoryTitle($r('app.media.ic_category_video'), '视频类')

      Grid() {
        ForEach(this.videoApps, (app: HapApp) => {
          GridItem() {
            this.AppRowItemWithIcon(app.icon, app.name)
          }
        }, (app: HapApp) => app.package)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(8)
      .width('100%')
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
        ForEach(this.musicApps, (app: HapApp) => {
          GridItem() {
            this.AppRowItemWithIcon(app.icon, app.name)
          }
        }, (app: HapApp) => app.package)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(8)
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
  private NavigationCategoryCard() {
    Column({ space: 8 }) {
      this.CategoryTitle($r('app.media.ic_category_navigation'), '出行导航')

      Grid() {
        ForEach(this.navigationApps, (app: HapApp) => {
          GridItem() {
            this.AppRowItemWithIcon(app.icon, app.name)
          }
        }, (app: HapApp) => app.package)
      }
      .columnsTemplate('1fr 1fr 1fr')
      .columnsGap(12)
      .rowsGap(8)
      .width('100%')
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
  private ToolsCategoryCard() {
    Column({ space: 8 }) {
      this.CategoryTitle($r('app.media.ic_category_tools'), '工具类')

      Column({ space: 0 }) {
        ForEach(Array.from(this.otherCategories.entries()), (entry: [string, HapApp[]]) => {
          this.CategoryRow(entry[0], entry[1].length)
        }, (entry: [string, HapApp[]]) => entry[0])
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
  private AppRowItemWithIcon(icon: string, label: string) {
    Row({ space: 8 }) {
      Image(icon)
        .width(32)
        .height(32)
        .borderRadius(16)

      Text(label)
        .fontSize(13)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1B1B')
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .layoutWeight(1)
    }
    .width('100%')
    .height(44)
    .padding({ left: 4, right: 4 })
  }

  @Builder
  private CategoryRow(category: string, count: number) {
    Row({ space: 12 }) {
      Text(category)
        .fontSize(15)
        .fontWeight(FontWeight.Medium)
        .fontColor('#1C1B1B')

      Blank()

      Text(`${count}`)
        .fontSize(14)
        .fontWeight(FontWeight.Medium)
        .fontColor('#717786')

      Text('›')
        .fontSize(20)
        .fontColor('#717786')
    }
    .width('100%')
    .height(44)
    .padding({ left: 4, right: 4 })
    .onClick(() => {
      this.selectedCategory = category;
      this.selectedCategoryApps = this.otherCategories.get(category) || [];
      this.showCategorySheet = true;
    })
  }
}
