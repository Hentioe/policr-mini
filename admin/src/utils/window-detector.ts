interface WindowWidthDetectorOptions {
  cssVariable: string;
  defaultThreshold?: number;
  debounceDelay?: number;
  onNarrow: () => void;
  onWide: () => void;
}

export default class WindowDetector {
  private threshold: number;
  private debounceDelay: number;
  private lastState: "narrow" | "wide" | null = null;
  private debounceTimer: ReturnType<typeof setTimeout> | null = null;
  private onNarrow: () => void;
  private onWide: () => void;
  private isInitialized = false;

  constructor(options: WindowWidthDetectorOptions) {
    const {
      cssVariable,
      defaultThreshold = 1200,
      debounceDelay = 250,
      onNarrow,
      onWide,
    } = options;

    this.threshold = this.getThreshold(cssVariable, defaultThreshold);
    this.debounceDelay = debounceDelay;
    this.onNarrow = onNarrow;
    this.onWide = onWide;
  }

  private getThreshold(cssVariable: string, defaultValue: number): number {
    try {
      const cssValue = getComputedStyle(document.documentElement)
        .getPropertyValue(cssVariable).trim();

      if (!cssValue) return defaultValue;

      // 创建临时元素来计算实际像素值
      const tempElement = document.createElement("div");
      tempElement.style.position = "absolute";
      tempElement.style.visibility = "hidden";
      tempElement.style.width = cssValue;
      document.body.appendChild(tempElement);

      const pixelValue = tempElement.offsetWidth;
      document.body.removeChild(tempElement);

      return pixelValue > 0 ? pixelValue : defaultValue;
    } catch {
      return defaultValue;
    }
  }

  private checkWidth(): void {
    const isNarrow = window.innerWidth < this.threshold;

    if (isNarrow && this.lastState !== "narrow") {
      this.onNarrow();
    } else if (!isNarrow && this.lastState !== "wide") {
      this.onWide();
    }

    this.lastState = isNarrow ? "narrow" : "wide";
  }

  private handleResize = (): void => {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
    this.debounceTimer = setTimeout(() => this.checkWidth(), this.debounceDelay);
  };

  public init(): void {
    if (this.isInitialized) return;

    this.checkWidth(); // 初始检测
    window.addEventListener("resize", this.handleResize);
    this.isInitialized = true;
  }

  public destroy(): void {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
    window.removeEventListener("resize", this.handleResize);
    this.isInitialized = false;
  }

  public getThresholdValue(): number {
    return this.threshold;
  }

  public getCurrentWidth(): number {
    return window.innerWidth;
  }
}
