import React from "react";

const ErrorView = ({ children: children }) => {
  return <div>{children}</div>;
};

const ErrorViewParagraph = ({ children: children }) => {
  return (
    <ErrorView>
      <p>{children}</p>
    </ErrorView>
  );
};

export default ErrorView;
export { ErrorViewParagraph };
