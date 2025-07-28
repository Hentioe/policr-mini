export default (props: { color?: string; size?: string }) => {
  const sizeToRem = () => {
    switch (props.size) {
      case "sm":
        return "1rem";
      case "lg":
        return "1.5rem";
      case "xl":
        return "2rem";
      default:
        return "1.25rem"; // 默认大小
    }
  };

  return (
    <svg xmlns="http://www.w3.org/2000/svg" width={sizeToRem()} height={sizeToRem()} viewBox="0 0 24 24">
      <path
        fill="none"
        stroke={props.color ? props.color : "currentColor"}
        stroke-dasharray="16"
        stroke-dashoffset="16"
        stroke-linecap="round"
        stroke-linejoin="round"
        stroke-width={2}
        d="M12 3c4.97 0 9 4.03 9 9"
      >
        <animate fill="freeze" attributeName="stroke-dashoffset" dur="0.06s" values="16;0" />
        <animateTransform
          attributeName="transform"
          dur="0.45s"
          repeatCount="indefinite"
          type="rotate"
          values="0 12 12;360 12 12"
        />
      </path>
    </svg>
  );
};
