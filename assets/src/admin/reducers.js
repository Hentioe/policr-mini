import { combineReducers } from "redux";

import chatsReducer from "./slices/chats";
import readonlyReducer from "./slices/readonly";

export default combineReducers({
  chats: chatsReducer,
  readonly: readonlyReducer,
});
