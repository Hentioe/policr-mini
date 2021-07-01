import { styled } from "twin.macro";

export default styled.div`
  background: ${({ src }) => `no-repeat url(${src})`};
  background-size: 100% auto;

  @media (max-width: 768px) {
    background: ${({ mobileSrc }) => `no-repeat url(${mobileSrc})`};
    background-size: 100% auto;
  }
`;
