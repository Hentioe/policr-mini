import { JSX, onMount } from "solid-js";
import tw, { styled } from "twin.macro";
import { useGlobalStore } from "../globalStore";

const Drawer = styled.div({
  boxShadow: `0 0 2px rgba(0,0,0,0.15)`,
  ...tw`h-screen flex w-[16rem] lg:w-[20rem] absolute lg:relative left-[-16rem] lg:left-0 transition-all duration-500 z-50`,
});

const GESTURE_DISTANCE = 50;
const MIX_GESTURE_ANGLE = 25;

// 根据起始坐标和当前坐标判断是否为抽屉手势
function isDrawerGesture(startX: number, startY: number, currentX: number, currentY: number) {
  let angle = (Math.atan2(currentY - startY, currentX - startX) * 180) / Math.PI;

  // 如果当前 x 坐标 > 起始 x 坐标,则判断为右滑,否则为左滑
  // 根据方向调整角度到 0-90 度范围内
  if (currentX > startX) {
    angle = Math.abs(angle);
  } else {
    angle = 180 - Math.abs(angle);
  }

  return angle >= 0 && angle <= MIX_GESTURE_ANGLE;
}

export default (props: { children: JSX.Element }) => {
  const { store, setDrawerEl, draw } = useGlobalStore();

  let drawer: HTMLDivElement | undefined;

  let startX: number | undefined;
  let startY: number | undefined;

  const handleTouchStart = (e: TouchEvent) => {
    startX = e.touches[0].pageX;
    startY = e.touches[0].pageY;
  };

  const handleTouchMove = (e: TouchEvent) => {
    // 滑动过程中持续获取坐标
    const currentX = e.touches[0].pageX;
    const currentY = e.touches[0].pageY;

    if (startX != null && startY != null) {
      if (isDrawerGesture(startX, startY, currentX, currentY)) {
        if (needOut(currentX)) {
          draw(false);
          // 支持不离手的连续滑动，需要更新起始坐标。
          startX = currentX;
          startY = currentY;
        } else if (needIn(currentX)) {
          draw(true);
          // 支持不离手的连续滑动，需要更新起始坐标。
          startX = currentX;
          startY = currentY;
        }
      }
    }
  };

  const needOut = (currentX: number) => {
    if (startX != null && !store.drawerIsOut) {
      return currentX - startX > GESTURE_DISTANCE;
    }
  };

  const needIn = (currentX: number) => {
    if (startX != null && store.drawerIsOut) {
      return (currentX <= 0 && startX > 0) || startX - currentX > GESTURE_DISTANCE;
    }
  };

  onMount(() => {
    if (drawer != null) {
      setDrawerEl(drawer);
    }
  });

  return (
    <Drawer
      ref={drawer}
      onTouchStart={handleTouchStart}
      onTouchMove={handleTouchMove}
    >
      {props.children}
    </Drawer>
  );
};
