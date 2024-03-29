import { AiFillGithub } from "solid-icons/ai";
import { BiLogosTelegram } from "solid-icons/bi";
import { FaBrandsBloggerB } from "solid-icons/fa";
import { IoLanguageOutline } from "solid-icons/io";
import { createSignal, Index, JSXElement } from "solid-js";
import tw, { styled } from "twin.macro";

const Root = styled.div({
  ...tw`w-[5rem] py-2 flex flex-col`,
});

type ActiveProp = {
  active?: boolean;
};

type HoveredProp = {
  hovered?: boolean;
};

type disableInteractiveProp = {
  disableInteractive?: boolean;
};

const ItemBoxRoot = styled.div(() => [
  tw`flex relative items-center justify-center px-2 my-2`,
]);

const ItemBoxLeft = styled.div((ps: ActiveProp & HoveredProp) => [
  tw`absolute left-0 w-[0.3rem] h-[0.6rem] rounded-r`,
  ps.hovered && !ps.active ? tw`bg-blue-400/40 h-[2rem]` : tw`bg-transparent`,
  ps.active && tw`bg-blue-400`,
]);

const ItemBox = (props: { children: JSXElement } & ActiveProp & disableInteractiveProp) => {
  const [hovered, setHovered] = createSignal(false);

  let rootEl: HTMLDivElement | undefined;

  const handleHoverSwitch = () => {
    if (!props.disableInteractive) {
      setHovered(!hovered());
    }
  };

  return (
    <ItemBoxRoot ref={rootEl} onMouseEnter={handleHoverSwitch} onMouseLeave={handleHoverSwitch}>
      <ItemBoxLeft active={props.active} hovered={hovered()} />
      {props.children}
    </ItemBoxRoot>
  );
};

const GroupBox = styled.div((ps: ActiveProp & disableInteractiveProp) => [
  tw`w-[3rem] lg:w-[3.5rem] h-[3rem] lg:h-[3.5rem] flex items-center justify-center rounded-xl`,
  ps.active ? tw`bg-white/40` : !ps.disableInteractive && tw`hover:bg-white/20`,
  !ps.disableInteractive && tw`cursor-pointer`,
]);

type IconSchemeProp = {
  scheme?: "github" | "blog" | "language" | "telegram";
};

const IconBox = styled(GroupBox)((ps: IconSchemeProp) => [
  tw`rounded-full bg-white/40 transition duration-300`,
  ps.scheme === "language" && tw`hover:bg-green-500 text-green-500 hover:text-white hover:rounded-2xl `,
  ps.scheme === "blog" && tw`hover:bg-amber-400 text-amber-400 hover:text-white hover:rounded-2xl `,
  ps.scheme === "github" && tw`hover:bg-black text-black hover:text-white hover:rounded-2xl `,
  ps.scheme === "telegram" && tw`hover:bg-sky-400 text-sky-400 hover:text-white hover:rounded-2xl `,
]);

export default () => {
  return (
    <Root>
      <div>
        <ItemBox disableInteractive>
          <GroupBox disableInteractive>
            <img title="Avatar" src="/images/avatar-100x100.jpg" tw="rounded-full" />
          </GroupBox>
        </ItemBox>
      </div>
      <div tw="flex-1 overflow-y-auto" class="hidden-scrollbar">
        <Index each={[1, 2, 3, 4, 5, 6, 7, 8, 9]}>
          {(i) => (
            <ItemBox active={i() === 2}>
              <GroupBox active={i() === 2}>
                <img
                  title={`Group ${i() + 1}`}
                  src="/images/telegram-128x128.png"
                  tw="rounded-full w-[80%] h-[80%]"
                />
              </GroupBox>
            </ItemBox>
          )}
        </Index>
      </div>
      <div>
        <ItemBox disableInteractive>
          <IconBox scheme="telegram">
            <BiLogosTelegram size="1.5rem" />
          </IconBox>
        </ItemBox>
        <ItemBox disableInteractive>
          <IconBox scheme="blog">
            <FaBrandsBloggerB size="1.5rem" />
          </IconBox>
        </ItemBox>
        <ItemBox disableInteractive>
          <IconBox scheme="github">
            <AiFillGithub size="1.5rem" />
          </IconBox>
        </ItemBox>
        <ItemBox disableInteractive>
          <IconBox scheme="language">
            <IoLanguageOutline size="1.5rem" />
          </IconBox>
        </ItemBox>
      </div>
    </Root>
  );
};
