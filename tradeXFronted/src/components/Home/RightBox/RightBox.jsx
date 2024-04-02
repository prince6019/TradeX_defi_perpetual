import React, { useContext, useEffect, useState } from "react";
import "./RightBox.css";
import { BsGraphDownArrow, BsGraphUpArrow } from "react-icons/bs";
import { MdOutlineSwapHoriz, MdOutlineSwapVert } from "react-icons/md";
import daiImg from "../../../images/multi-collateral-dai-dai-logo.svg";
import ethImg from "../../../images/ethereum-eth-logo.svg";
import { useSelector, useDispatch } from "react-redux";
import { Signer, ethers } from "ethers";
import contractAddress from "../../constants/contractAddress.json";
import TradeXAbi from "../../constants/contractAbi.json";
import axios from "axios";

const RightBox = () => {
  const [toggle, setToggle] = useState(1);
  const [daiInput, setDaiInput] = useState(0);
  const [ethInput, setEthInput] = useState(0);
  //
  const [leverage, setLeverage] = useState(0);
  const [exitPrice, setExitPrice] = useState(0);
  const [ethPrice, setEthPrice] = useState(0);
  const [positionFee, setPositionFee] = useState(0);

  const userAddress = useSelector((state) => state.wallet.address);
  const isConnected = useSelector((state) => state.wallet.isConnected);
  const userSigner = useSelector((state) => state.wallet.signer);

  function handleClick() {
    console.log("right box", userAddress);
    console.log("right box", isConnected);
    console.log("right box", userSigner);
    console.log("trade addrsss:", contractAddress.contractAddresses.TradeX);
    console.log(TradeXAbi);
  }

  useEffect(() => {
    async function _do() {
      if (ethPrice == 0 || ethInput == 0 || daiInput == 0) {
        return;
      }
      const ethinWei = BigInt(ethInput * 1e18);
      const ethValue = BigInt(ethInput * ethPrice * 1e18);
      const daiValue = BigInt(daiInput * 1e18);
      console.log("ethvalue : ", ethValue);
      console.log("daivalue : ", daiValue);

      const tradeX = new ethers.Contract(
        contractAddress.contractAddresses.TradeX,
        TradeXAbi.abi,
        userSigner
      );
      const leverage = await tradeX.calculateLeverage(ethValue, daiValue);
      console.log(Number(leverage));
      setLeverage(Number(leverage) / 100);

      const LiqPrice = await tradeX.calculateExitPrice(
        ethValue,
        ethinWei,
        daiValue
      );
      console.log("LiqPrice : ", Number(LiqPrice / 1e18));
      setExitPrice(Number(LiqPrice / 1e18).toFixed(2));

      const fee = await tradeX.calculatePositionFee(ethinWei);
      console.log("positionFee : ", Number(fee / 1e18).toFixed(5));
      setPositionFee(Number(fee / 1e18).toFixed(4));
    }
    _do();
  }, [ethPrice]);

  useEffect(() => {
    const getData = async () => {
      if (daiInput == 0 || ethInput == 0) {
        return;
      }
      let ethPrice;
      try {
        axios
          .get("http://localhost:8080/eth-usd-live-data")
          .then((response) => {
            const data = response.data;
            ethPrice = data.PRICE;
            ethPrice = ethPrice.toFixed(2);
            setEthPrice(ethPrice);
          })
          .catch((e) => console.log(e));
      } catch (error) {
        console.error("Error fetching data:", error);
      }

      console.log("yo");
    };
    getData();
  }, [daiInput, ethInput]);

  useEffect(() => {
    if (!isConnected) {
      document.getElementById("info_button").innerHTML = "Connect Button";
    } else if (
      isConnected &&
      ((daiInput == 0 && ethInput == 0) ||
        (daiInput == 0 && ethInput != 0) ||
        (daiInput != 0 && ethInput == 0))
    ) {
      document.getElementById("info_button").innerHTML = "Enter Amount";
    } else if (isConnected && daiInput != 0 && ethInput != 0) {
      document.getElementById("info_button").innerHTML = "open Position";
    }
  }, []);

  return (
    <div className="home_right_box">
      <div className="home_right_box_exchange">
        <div className="home_right_box_bar">
          <div
            onClick={() => setToggle(1)}
            style={{
              backgroundColor: toggle === 1 && "#14FFEC",
            }}
          >
            <BsGraphUpArrow />
            <p>Long</p>
          </div>
          <div
            onClick={() => setToggle(2)}
            style={{
              backgroundColor: toggle === 2 && "#14FFEC",
            }}
          >
            <BsGraphDownArrow />
            <p>Short</p>
          </div>
          <div
            onClick={() => setToggle(3)}
            style={{
              backgroundColor: toggle === 3 && "#14FFEC",
            }}
          >
            <MdOutlineSwapHoriz />
            <p>Swap</p>
          </div>
        </div>
        <div className="home_right_box_exhange_buy_input">
          <div>
            <p>Pay</p>
            <p>Balance</p>
          </div>
          <div>
            <input
              className="dai_input"
              type="number"
              onChange={(e) => setDaiInput(e.target.value)}
              placeholder="0.0"
              value={daiInput}
            />
            <div className="dai_box">
              <img src={daiImg} alt="dai" />
              <p>DAI</p>
            </div>
          </div>
        </div>
        <div className="swap_button">
          <MdOutlineSwapVert className="exchange_swap" />
        </div>
        <div className="home_right_box_exhange_eth_input">
          <div>
            <p>{toggle === 1 ? "Long" : "Short"}</p>
            <p>Leverage: 20.00x</p>
          </div>
          <div>
            <input
              className="eth_input"
              type="number"
              onChange={(e) => setEthInput(e.target.value)}
              placeholder="0.0"
              value={ethInput}
            />
            <div className="dai_box">
              <img src={ethImg} alt="dai" />
              <p>ETH</p>
            </div>
          </div>
        </div>
        {/* first info div */}
        <div className="exchange_info">
          <div>
            <p>Collateral In</p>
            <p>{daiInput} DAI</p>
          </div>
          <div>
            <p>Leverage</p>
            <p>{leverage}x</p>
          </div>
          <div>
            <p>Entry Price</p>
            <p>${ethPrice} </p>
          </div>
          <div>
            <p>Liq. Price</p>
            <p>$ {exitPrice}</p>
          </div>
          <div>
            <p>Fees</p>
            <p>$ {positionFee}</p>
          </div>
        </div>
        <button
          id="info_button"
          className="wallet_connect"
          onClick={handleClick}
        >
          {/* {!isConnected ? "connect Button" : isConnected && daiInput == 0 ?} */}
        </button>
      </div>
      {/* last right div  */}
      <div className="home_right_box_exchange_info">
        <h2>{toggle === 1 ? "Long ETH" : "Short ETH"}</h2>
        <div className="home_right_box_exchange_details">
          <div>
            <p>Entry Price</p>
            <p>$2309.58</p>
          </div>
          <div>
            <p>Exit Price</p>
            <p>$2245.009</p>
          </div>
          <div>
            <p>Borrow Fee</p>
            <p>0.0013%/1h</p>
          </div>
          <div>
            <p>Available Liquidity</p>
            <p>$11,999,660.99</p>
          </div>
        </div>
      </div>
    </div>
  );
};

export default RightBox;
