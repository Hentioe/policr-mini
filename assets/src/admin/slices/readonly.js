import { createSlice } from "@reduxjs/toolkit";

const initialState = {
  shown: false,
};

const readonly = createSlice({
  name: "readonly",
  initialState,
  reducers: {
    shown: (state, action) =>
      Object.assign({}, state, { shown: action.payload }),
  },
});

export const { shown } = readonly.actions;
export default readonly.reducer;
