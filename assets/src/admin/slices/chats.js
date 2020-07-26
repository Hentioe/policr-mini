import { createSlice } from "@reduxjs/toolkit";

const initialState = {
  isLoaded: false,
  list: [],
  selected: null,
};

const chats = createSlice({
  name: "chats",
  initialState,
  reducers: {
    receiveChats: (state, action) =>
      Object.assign({}, state, {
        isLoaded: true,
        list: action.payload,
      }),
    selectChat: (state, action) =>
      Object.assign({}, state, { selected: action.payload }),
  },
});

export const { receiveChats, selectChat } = chats.actions;
export default chats.reducer;
