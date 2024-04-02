import { createSlice } from "@reduxjs/toolkit";

export const userSlice = createSlice({
  name: "wallet",
  initialState: {
    address: "",
    isConnected: false,
    signer: {},
  },
  reducers: {
    setUserAddress: (state, action) => {
      state.address = action.payload;
    },
    changeConnection: (state) => {
      state.isConnected = !state.isConnected;
    },
    setSigner: (state, action) => {
      state.signer = action.payload;
    },
  },
});

export const { setUserAddress, changeConnection, setSigner } =
  userSlice.actions;

export default userSlice.reducer;
