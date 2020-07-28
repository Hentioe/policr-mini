function getIdFromLocation(location) {
  const re = /^\/admin\/chats\/(-\d+)\//i;
  const found = location.pathname.match(re);
  if (found && found.length == 2) {
    const [, id] = found;
    return id;
  }

  return null;
}

export { getIdFromLocation };
