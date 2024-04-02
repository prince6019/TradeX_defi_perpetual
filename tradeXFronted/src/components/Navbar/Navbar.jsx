import React, { useEffect, useState } from "react";
import "./Navbar.css";
import ConnectWallet from "../ConnectWallet/ConnectWallet";

const Navbar = () => {
  return (
    <div className="navbar">
      <div className="navbar_container">
        <div className="navbar_left_box">
          <h2>TradeX</h2>
        </div>
        <div className="navbar_right_box">
          <ConnectWallet />
        </div>
      </div>
    </div>
  );
};

export default Navbar;
