import { createSlice } from "@reduxjs/toolkit";

const initialState = {
  isLoaded: false,
  list: [],
  selected: null,
  loadedSelected: null,
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
    loadSelected: (state, action) =>
      Object.assign({}, state, { loadedSelected: action.payload }),
  },
});

export const { receiveChats, selectChat, loadSelected } = chats.actions;
export default chats.reducer;
