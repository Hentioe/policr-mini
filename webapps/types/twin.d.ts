import "twin.macro";
import { css as cssImport, styled as styledImport } from "solid-styled-components";

declare module "twin.macro" {
  // The styled and css imports
  const styled: typeof styledImport;
  const css: typeof cssImport;
}

declare module "solid-js" {
  namespace JSX {
    // The css/tw props on JSX elements
    interface HTMLAttributes<T> extends AriaAttributes, DOMAttributes<T> {
      tw?: string;
    }
    // The css/tw props on SVG elements
    interface SvgSVGAttributes<T>
      extends
        ContainerElementSVGAttributes<T>,
        NewViewportSVGAttributes<T>,
        ConditionalProcessingSVGAttributes,
        ExternalResourceSVGAttributes,
        StylableSVGAttributes,
        FitToViewBoxSVGAttributes,
        ZoomAndPanSVGAttributes,
        PresentationSVGAttributes
    {
      tw?: string;
    }
  }
}
