import { common } from '@kit.AbilityKit';

/**
 * 主题相关工具：把颜色资源按当前系统深浅色解析成可直接传给原生接口的颜色字符串。
 */
export class ThemeUtils {
  /**
   * 解析颜色资源为 #RRGGBB 或 #AARRGGBB 字符串。
   * @param context UIAbility 上下文，用于访问 resourceManager
   * @param resId 颜色资源 id，可通过 $r('app.color.xxx').id 获取
   * @returns 颜色字符串；解析失败时返回空字符串
   */
  static resolveColorString(context: common.UIAbilityContext, resId: number): string {
    try {
      const color: number = context.resourceManager.getColorSync(resId);
      const argb = color >>> 0;
      const alpha = (argb >>> 24) & 0xFF;
      const rgb = (argb & 0xFFFFFF).toString(16).padStart(6, '0');
      return alpha === 0xFF ? `#${rgb}` : `#${alpha.toString(16).padStart(2, '0')}${rgb}`;
    } catch (error) {
      console.error('ThemeUtils: 解析颜色资源失败', JSON.stringify(error));
      return '';
    }
  }
}
