import { combineReducers } from "redux";

import modalReducer from "../user/slices/modal";

export default combineReducers({
  modal: modalReducer,
});
