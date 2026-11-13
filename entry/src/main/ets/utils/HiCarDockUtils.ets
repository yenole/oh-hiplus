/** HiCar Dock 的摆放位置。 */
export enum DockPosition {
  LEFT = 'LEFT',
  BOTTOM = 'BOTTOM'
}

/** 将 dp 按 density 转为 px，按参考实现四舍五入。 */
export function roundPx(dp: number, density: number): number {
  if (!Number.isFinite(dp) || dp < 0) {
    throw new Error('dp 必须是大于或等于 0 的有限数值');
  }
  if (!Number.isFinite(density) || density < 0) {
    throw new Error('density 必须是大于或等于 0 的有限数值');
  }
  return Math.floor(dp * density + 0.5);
}

/**
 * 判断屏幕宽高比是否至少为 1.33。
 * 比值先四舍五入到小数点后 4 位，再进行阈值判断。
 */
export function isAspectRatioAtLeast133(screenWidthPx: number, screenHeightPx: number): boolean {
  if (screenHeightPx === 0) {
    return true;
  }
  if (!Number.isFinite(screenWidthPx) || screenWidthPx < 0 ||
      !Number.isFinite(screenHeightPx) || screenHeightPx < 0) {
    throw new Error('屏幕宽高必须是大于或等于 0 的有限数值');
  }

  const ratio: number = Math.floor((screenWidthPx / screenHeightPx) * 10000 + 0.5) / 10000;
  return ratio >= 1.33;
}

/** 判断屏幕宽度是否小于约 1000 dp。 */
export function isWidthBelowApprox1000dp(screenWidthPx: number, density: number): boolean {
  if (!Number.isFinite(screenWidthPx) || screenWidthPx < 0) {
    throw new Error('screenWidthPx 必须是大于或等于 0 的有限数值');
  }
  if (!Number.isFinite(density) || density < 0) {
    throw new Error('density 必须是大于或等于 0 的有限数值');
  }
  return screenWidthPx < density * 1000 + 0.5;
}

/**
 * 根据分辨率和 density 计算 HiCar Dock 尺寸（px）。
 * 宽高比至少 1.33 且屏幕宽度小于约 1000dp 时使用 80dp，其余情况使用 96dp。
 */
export function calculateDockSize(
  screenWidthPx: number,
  screenHeightPx: number,
  density: number
): number {
  if (!Number.isFinite(density) || density < 0) {
    throw new Error('density 必须是大于或等于 0 的有限数值');
  }

  if (isAspectRatioAtLeast133(screenWidthPx, screenHeightPx) &&
      isWidthBelowApprox1000dp(screenWidthPx, density)) {
    return roundPx(80, density);
  }
  return roundPx(96, density);
}

/** 悬浮图标边长（vp）。 */
export const FLOAT_ICON_SIZE_VP: number = 40;
/** 悬浮图标圆角（vp）。 */
export const FLOAT_ICON_RADIUS_VP: number = 8;
/** 悬浮图标距屏幕顶部与 Dock 右侧的间距（vp）。 */
export const FLOAT_ICON_MARGIN_VP: number = 50;

/**
 * 将 vp 按屏幕 density 换算为窗口 API 所需的 px。
 * window.resize / moveWindowTo / setWindowCornerRadius 均使用 px，
 * 直接写死 px 会导致不同分辨率下图标物理尺寸不一致。
 */
export function vp2px(vp: number, density: number): number {
  if (!Number.isFinite(vp) || vp < 0) {
    throw new Error('vp 必须是大于或等于 0 的有限数值');
  }
  if (!Number.isFinite(density) || density <= 0) {
    throw new Error('density 必须是大于 0 的有限数值');
  }
  return roundPx(vp, density);
}

/**
 * 根据屏幕信息计算悬浮图标的尺寸与位置（px）。
 * @param screenWidthPx 屏幕宽度（px）
 * @param screenHeightPx 屏幕高度（px）
 * @param density 屏幕密度
 * @param dockSizePx HiCar Dock 宽度（px）
 */
export interface FloatIconLayout {
  size: number;
  radius: number;
  x: number;
  y: number;
}

export function calculateFloatIconLayout(
  screenWidthPx: number,
  screenHeightPx: number,
  density: number,
  dockSizePx: number
): FloatIconLayout {
  const size: number = vp2px(FLOAT_ICON_SIZE_VP, density);
  const margin: number = vp2px(FLOAT_ICON_MARGIN_VP, density);
  // 图标放在 Dock 右侧，Dock 放底部时左边距回退为普通间距。
  const dockOffset: number = Number.isFinite(dockSizePx) && dockSizePx > 0 ? dockSizePx : 0;
  const maxX: number = Math.max(margin, screenWidthPx - size - margin);
  const x: number = Math.min(margin + dockOffset, maxX);
  const y: number = Math.max(0, Math.min(margin, screenHeightPx - size - margin));

  return {
    size,
    radius: vp2px(FLOAT_ICON_RADIUS_VP, density),
    x,
    y
  };
}

/**
 * 根据屏幕宽高比计算 HiCar Dock 的摆放位置。
 * 当 H 为 0 或 H/W <= 0.75 时放左侧，否则放底部；无效或未提供分辨率时默认左侧。
 */
export function calculateDockPosition(W: number = 0, H: number = 0): DockPosition {
  if (!Number.isFinite(W) || W <= 0 || !Number.isFinite(H) || H < 0 || H === 0) {
    return DockPosition.LEFT;
  }

  return H / W <= 0.75 ? DockPosition.LEFT : DockPosition.BOTTOM;
}
