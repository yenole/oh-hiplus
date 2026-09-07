import { v1Authorize, v1Login, V1User } from 'libohos.so';
import { pasteboard } from '@kit.BasicServicesKit';
import { promptAction } from '@kit.ArkUI';
import preferences from '@ohos.data.preferences';
import { common } from '@kit.AbilityKit';
import router from '@ohos.router';

@Component
export struct HomeProfileTab {
  @Prop isCasting: boolean;
  @State isAuthSheetVisible: boolean = false;
  @State authCode: string = '';
  @State isLoading: boolean = false;
  @State userInfo: V1User | null = null;
  @State nickname: string = 'Hi时刻';
  @State avatar: string = 'Hi';
  @State isRefreshing: boolean = false;
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;
  private preferencesInstance: preferences.Preferences | null = null;

  async aboutToAppear() {
    await this.initPreferences();
    await this.loadUserData();
  }

  build() {
    Refresh({ refreshing: $$this.isRefreshing }) {
      Column({ space: 16 }) {
        this.ProfileHeader()

        Grid() {
          GridItem() {
            this.StatCard('128', '投屏次数')
          }

          GridItem() {
            this.StatCard('03', '连接设备')
          }

          GridItem() {
            this.StatCard('36h', '使用时长')
          }
        }
        .columnsTemplate('1fr 1fr 1fr')
        .columnsGap(12)
        .width('100%')
        .height(88)

        Column({ space: 0 }) {
          this.MenuRow($r('app.media.ic_profile_security'), '系统设置', () => {
            router.pushUrl({ url: 'pages/SystemSettingsPage' });
          })
          this.MenuDivider()
          this.MenuRow($r('app.media.ic_profile_devices'), '投屏设置', () => {
            router.pushUrl({ url: 'pages/CastingSettingsPage' });
          })
          this.MenuDivider()
          this.MenuRow($r('app.media.ic_profile_feedback'), '意见反馈', () => {
            router.pushUrl({ url: 'pages/FeedbackPage' });
          })
          this.MenuDivider()
          this.MenuRow($r('app.media.ic_profile_about'), '关于', () => {
            router.pushUrl({ url: 'pages/AboutPage' });
          })
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
    .onRefreshing(() => {
      this.handleRefresh();
    })
    .width('100%')
    .height('100%')
    .bindSheet($$this.isAuthSheetVisible, this.AuthSheet(), {
      height: this.userInfo ? 240 : 360,
      dragBar: true,
      blurStyle: BlurStyle.COMPONENT_ULTRA_THICK,
      showClose: false
    })
  }

  @Builder
  private ProfileHeader() {
    Column({ space: 12 }) {
      Stack({ alignContent: Alignment.BottomEnd }) {
        if (this.avatar.startsWith('http')) {
          // 显示网络图片
          Image(this.avatar)
            .width(96)
            .height(96)
            .borderRadius(48)
            .border({ width: 4, color: Color.White })
            .shadow({ radius: 16, color: 'rgba(0, 0, 0, 0.12)', offsetX: 0, offsetY: 6 })
            .onClick(() => {
              this.handleAvatarClick();
            })
        } else {
          // 显示文字头像
          Stack({ alignContent: Alignment.Center }) {
            Text(this.avatar)
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
          .onClick(() => {
            this.handleAvatarClick();
          })
        }

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
        Text(this.nickname)
          .fontSize(24)
          .fontWeight(FontWeight.Bold)
          .fontColor('#1C1B1B')

        if (this.userInfo && this.userInfo.member) {
          Text(this.userInfo.member)
            .fontSize(10)
            .fontWeight(FontWeight.Bold)
            .fontColor('#007DFF')
            .padding({ left: 12, right: 12, top: 3, bottom: 3 })
            .borderRadius(10)
            .backgroundColor('rgba(0, 125, 255, 0.10)')
        }
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
  private MenuRow(icon: Resource, label: string, onClick?: () => void) {
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
    .onClick(() => {
      if (onClick) {
        onClick();
      }
    })
  }

  @Builder
  private MenuDivider() {
    Divider()
      .strokeWidth(1)
      .color('#EEEAE8')
      .margin({ left: 56, right: 16 })
  }

  @Builder
  private AuthSheet() {
    Column() {
      Column({ space: 24 }) {
        Column({ space: 12 }) {
          Text(this.userInfo ? '退出登录' : '授权登录')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#1C1B1B')

          if (!this.userInfo) {
            Text('点击复制授权码，发送至公众号：Hi时刻')
              .fontSize(14)
              .fontColor('#414754')
          } else {
            Text('确认退出当前账号？')
              .fontSize(14)
              .fontColor('#414754')
          }
        }
        .alignItems(HorizontalAlign.Center)
        .width('100%')
        .padding({ top: 24 })

        if (this.authCode && !this.userInfo) {
          Text(this.authCode)
            .fontSize(16)
            .fontWeight(FontWeight.Medium)
            .fontColor('#1C1B1B')
            .padding(16)
            .width('100%')
            .borderRadius(12)
            .backgroundColor('#F6F3F2')
            .textAlign(TextAlign.Center)
            .onClick(() => {
              this.copyToClipboard(this.authCode);
            })
        }
      }
      .width('100%')
      .layoutWeight(1)

      if (this.userInfo) {
        Button('退出登录')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#FF3B30')
          .borderRadius(24)
          .onClick(() => {
            this.handleLogout();
          })
      } else {
        Button(this.isLoading ? '加载中...' : '确认授权')
          .width('100%')
          .height(48)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .backgroundColor('#007DFF')
          .borderRadius(24)
          .enabled(!this.isLoading && !!this.authCode)
          .onClick(() => {
            this.handleLogin();
          })
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 24, right: 24, bottom: 40 })
    .justifyContent(FlexAlign.SpaceBetween)
  }

  private async initPreferences() {
    try {
      this.preferencesInstance = await preferences.getPreferences(this.context, 'user_preferences');
    } catch (error) {
      console.error('初始化Preferences失败', error);
    }
  }

  private async loadUserData() {
    if (!this.preferencesInstance) {
      return;
    }

    try {
      const token = await this.preferencesInstance.get('user_token', '') as string;
      const userInfoStr = await this.preferencesInstance.get('user_info', '') as string;

      if (token && userInfoStr) {
        this.userInfo = JSON.parse(userInfoStr) as V1User;
        this.nickname = this.userInfo.nick || 'Hi时刻';
        // 如果有头像地址则使用头像，否则使用昵称首字
        if (this.userInfo.face && this.userInfo.face.startsWith('http')) {
          this.avatar = this.userInfo.face;
        } else {
          this.avatar = this.userInfo.nick ? this.userInfo.nick.charAt(0) : 'Hi';
        }
      }
    } catch (error) {
      console.error('加载用户数据失败', error);
    }
  }

  private async saveUserData(token: string, user: V1User) {
    if (!this.preferencesInstance) {
      return;
    }

    try {
      await this.preferencesInstance.put('user_token', token);
      await this.preferencesInstance.put('user_info', JSON.stringify(user));
      await this.preferencesInstance.flush();
    } catch (error) {
      console.error('保存用户数据失败', error);
    }
  }

  private async handleAvatarClick() {
    this.isAuthSheetVisible = true;
    
    // 只有未登录时才获取授权码
    if (!this.userInfo) {
      this.authCode = '';
      
      try {
        this.isLoading = true;
        const code = await v1Authorize();
        this.authCode = code;
      } catch (error) {
        console.error('获取授权码失败', error);
      } finally {
        this.isLoading = false;
      }
    }
  }

  private async handleLogin() {
    try {
      this.isLoading = true;
      const user = await v1Login(this.authCode);
      console.log('登录成功', JSON.stringify(user));
      
      // 保存用户信息和token
      await this.saveUserData(this.authCode, user);
      
      // 更新UI
      this.userInfo = user;
      this.nickname = user.nick || 'Hi时刻';
      // 如果有头像地址则使用头像，否则使用昵称首字
      if (user.face && user.face.startsWith('http')) {
        this.avatar = user.face;
      } else {
        this.avatar = user.nick ? user.nick.charAt(0) : 'Hi';
      }
      
      // 显示授权成功提示
      promptAction.showToast({
        message: '授权成功',
        duration: 2000
      });
      
      // 关闭Sheet
      this.isAuthSheetVisible = false;
      this.authCode = '';
    } catch (error) {
      console.error('登录失败', error);
      promptAction.showToast({
        message: '授权失败，请重试',
        duration: 2000
      });
    } finally {
      this.isLoading = false;
    }
  }

  private copyToClipboard(text: string) {
    const pasteData = pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, text);
    const systemPasteboard = pasteboard.getSystemPasteboard();
    systemPasteboard.setData(pasteData);
    
    promptAction.showToast({
      message: '授权码已复制',
      duration: 2000
    });
  }

  private async handleLogout() {
    if (!this.preferencesInstance) {
      return;
    }

    try {
      // 清除本地存储的用户数据
      await this.preferencesInstance.delete('user_token');
      await this.preferencesInstance.delete('user_info');
      await this.preferencesInstance.flush();
      
      // 重置状态
      this.userInfo = null;
      this.nickname = 'Hi时刻';
      this.avatar = 'Hi';
      
      // 显示提示
      promptAction.showToast({
        message: '已退出登录',
        duration: 2000
      });
      
      // 关闭Sheet
      this.isAuthSheetVisible = false;
    } catch (error) {
      console.error('退出登录失败', error);
    }
  }

  private async handleRefresh() {
    if (!this.userInfo || !this.preferencesInstance) {
      this.isRefreshing = false;
      return;
    }

    try {
      // 获取保存的token
      const token = await this.preferencesInstance.get('user_token', '') as string;
      if (!token) {
        this.isRefreshing = false;
        return;
      }

      // 使用token重新登录获取最新用户信息
      const user = await v1Login(token);
      
      // 更新用户信息
      await this.saveUserData(token, user);
      this.userInfo = user;
      this.nickname = user.nick || 'Hi时刻';
      
      // 更新头像
      if (user.face && user.face.startsWith('http')) {
        this.avatar = user.face;
      } else {
        this.avatar = user.nick ? user.nick.charAt(0) : 'Hi';
      }

      promptAction.showToast({
        message: '刷新成功',
        duration: 2000
      });
    } catch (error) {
      console.error('刷新用户信息失败', error);
      promptAction.showToast({
        message: '刷新失败',
        duration: 2000
      });
    } finally {
      this.isRefreshing = false;
    }
  }
}
