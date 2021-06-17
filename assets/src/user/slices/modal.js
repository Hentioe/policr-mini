import { createSlice } from "@reduxjs/toolkit";
import React from "react";

const initialState = {
  isOpen: false,
  title: "I'm a Modal ...",
  content: <span>I'm Modal content ...</span>,
};

const modal = createSlice({
  name: "modal",
  initialState,
  reducers: {
    open: (state, action) =>
      Object.assign({}, state, {
        isOpen: true,
        title: action.payload.title,
        content: action.payload.content,
      }),
    close: (state, _action) => Object.assign({}, state, { isOpen: false }),
  },
});

export const { open, close } = modal.actions;
export default modal.reducer;
