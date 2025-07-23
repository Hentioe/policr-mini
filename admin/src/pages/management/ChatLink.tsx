export default (props: { username?: string }) => {
  return (
    <>
      {props.username
        ? (
          <a href={`https://t.me/${props.username}`} class="text-zinc-600 hover:underline" target="_blank">
            @{props.username}
          </a>
        )
        : <span>无</span>}
    </>
  );
};
