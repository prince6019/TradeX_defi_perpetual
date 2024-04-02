import React from "react";
import "./Home.css";
import LeftBox from "./LeftBox/LeftBox";
import RightBox from "./RightBox/RightBox";
import { useEffect } from "react";
import axios from "axios";

const Home = () => {
  //     useEffect(() => {
  //       const fetchData = async () => {
  //         try {
  //           axios
  //             .get(
  //               "https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin&x_cg_demo_api_key=CG-c2kM6HKMr5rwMF4pSShTt8Fp"
  //             )
  //             .then((response) => console.log(response.data[0].current_price));
  //         } catch (error) {
  //           console.error("Error fetching data:", error);
  //         }
  //       };

  //     fetchData();
  //     const interval = setInterval(fetchData, 60000); // Fetch data every minute

  //     return () => clearInterval(interval);
  //   }, []);
  return (
    <div className="home">
      <div className="home_container">
        <LeftBox />
        <RightBox />
      </div>
    </div>
  );
};

export default Home;
