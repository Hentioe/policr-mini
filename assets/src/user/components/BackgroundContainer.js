import { styled } from "twin.macro";

export default styled.div`
  background: ${({ src }) => `no-repeat url(${src})`};
  background-size: 100% auto;

  @media (max-width: 768px) {
    background-size: 768px auto;
  }
`;
