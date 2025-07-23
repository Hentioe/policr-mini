import { metaState } from "../state";

export default () => {
  return (
    <header>
      <h1>
        {metaState.title}
      </h1>
    </header>
  );
};
