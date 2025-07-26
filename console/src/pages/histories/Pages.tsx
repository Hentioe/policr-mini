import { Tabs } from "@ark-ui/solid/tabs";
import { Index, JSX } from "solid-js";

const Root = (props: { defaultPage?: string; children: JSX.Element }) => {
  return (
    <Tabs.Root defaultValue={props.defaultPage} lazyMount unmountOnExit>
      {props.children}
    </Tabs.Root>
  );
};

const Head = (props: { list: string[] }) => {
  return (
    <Tabs.List>
      <Index each={props.list}>
        {(item) => <Tabs.Trigger value={item()}>{item()}</Tabs.Trigger>}
      </Index>
      <Tabs.Indicator />
    </Tabs.List>
  );
};

const Content = (props: { title: string; children: JSX.Element }) => {
  return <Tabs.Content value={props.title}>{props.children}</Tabs.Content>;
};

export const Pages = {
  Root,
  Head,
  Content,
};
