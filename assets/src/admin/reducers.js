import { combineReducers } from "redux";

import chatsReducer from "./slices/chats";

export default combineReducers({
  chats: chatsReducer,
});
