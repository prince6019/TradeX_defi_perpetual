import React from "react";
import { BsTwitterX } from "react-icons/bs";
import { FaGithub, FaDiscord, FaTelegram } from "react-icons/fa";

import "./Footer.css";

const Footer = () => {
  return (
    <div className="footer">
      <div className="footer_container">
        <h3>TradeX</h3>
        <div className="footer_socialhandle">
          <BsTwitterX className="social_handle" />
          <FaGithub className="social_handle" />
          <FaDiscord className="social_handle" />
          <FaTelegram className="social_handle" />
        </div>
        <p>Made with ❤️️</p>
      </div>
    </div>
  );
};

export default Footer;
