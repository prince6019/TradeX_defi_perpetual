import React, { useEffect, useState } from "react";
import "./LeftBox.css";
import { FaEthereum } from "react-icons/fa";
import BitcoinChart from "../../BitcoinComponent";
import axios from "axios";

const LeftBox = () => {
  const [ethereumData, setEthereumData] = useState({});
  // useEffect(() => {
  //   const fetchData = async () => {
  //     try {
  //       axios
  //         .get("http://localhost:8080/eth-usd-live-data")
  //         .then((response) => {
  //           const data = response.data;
  //           const dataJson = {
  //             price: data.PRICE,
  //             timestamp: data.LASTUPDATE,
  //             high: data.HIGH24HOUR,
  //             low: data.LOW24HOUR,
  //             change: data.CHANGEPCT24HOUR,
  //           };
  //           setEthereumData(dataJson);
  //         })
  //         .catch((e) => console.log(e));
  //     } catch (error) {
  //       console.error("Error fetching data:", error);
  //     }
  //   };

  //   fetchData();
  //   const interval = setInterval(fetchData, 30000); // Fetch data every minute

  //   return () => clearInterval(interval);
  // }, []);

  return (
    <div className="home_left_box">
      <div className="home_left_box_bar">
        <div className="home_left_box_bar_asset">
          <FaEthereum />
          <h1>ETH/USD</h1>
        </div>
        <div className="home_left_box_bar_price">
          <h3>{ethereumData.price}</h3>
        </div>
        <div className="home_left_box_bar_1">
          <span>24h change</span>
          <p>{ethereumData.change}</p>
        </div>
        <div className="home_left_box_bar_2">
          <span>24h High</span>
          <p>{ethereumData.high}</p>
        </div>
        <div className="home_left_box_bar_3">
          <span>24h Low</span>
          <p>{ethereumData.low}</p>
        </div>
      </div>
      <div className="home_left_box_price_chart">
        <BitcoinChart />
      </div>
      <div className="home_left_box_positions_heading">
        <p>Position</p>
        <p>Size</p>
        <p>Collateral</p>
        <p>Entry Price</p>
        <p>Liq Price</p>
      </div>
      <div className="home_left_box_positions">No open positions</div>
    </div>
  );
};

export default LeftBox;
