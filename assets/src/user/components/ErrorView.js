import React from "react";

const ErrorView = ({ children: children }) => {
  return <div>{children}</div>;
};

const ErrorParagraph = ({ children: children }) => {
  return (
    <ErrorView>
      <p>{children}</p>
    </ErrorView>
  );
};

export default ErrorView;
export { ErrorParagraph };
