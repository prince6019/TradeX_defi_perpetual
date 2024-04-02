import React, { useContext, useEffect, useState } from "react";
import "./ConnectWallet.css";
import { AiOutlineClose } from "react-icons/ai";
import { IoExitOutline } from "react-icons/io5";
import { FaAngleDown } from "react-icons/fa";
import { ethers } from "ethers";
import { useSelector, useDispatch } from "react-redux";
import {
  setUserAddress,
  changeConnection,
  setSigner,
} from "../features/userSlice";

const ConnectWallet = () => {
  const [walletConnected, setWalletConnected] = useState(false);
  const [showModal, setShowModal] = useState(false);
  const [address, setAddress] = useState(null);
  const [showDropdown, setShowDropdown] = useState(false);
  const dispatch = useDispatch();

  let provider;
  let signer;

  useEffect(() => {
    if (address != null) {
      console.log(typeof address);
      dispatch(setUserAddress(address));
      setShowModal(false);
    }
  }, [address]);

  useEffect(() => {
    window.ethereum.on("accountsChanged", handleAccountsChanged);
  }, []);

  const handleDropdown = async () => {
    await window.ethereum.request({
      method: "wallet_revokePermissions",
      params: [
        {
          eth_accounts: {},
        },
      ],
    });
    setShowDropdown(false);
    dispatch(changeConnection());
    dispatch(setSigner({}));
    dispatch(setUserAddress(""));
  };

  const handleAccountsChanged = async (accounts) => {
    if (accounts.length == 0) {
      setAddress(null);
      setWalletConnected(false);
    } else if (accounts[0] != address) {
      console.log("type of address is : ", typeof accounts[0]);
      setAddress(accounts[0]);
    }
  };

  const handleWallet = async () => {
    if (!walletConnected) {
      setShowModal(true);
    } else {
      setShowDropdown(!showDropdown);
    }
  };

  const connectWithMetamask = async () => {
    if (window.ethereum) {
      //checks if metamask is installed
      provider = new ethers.providers.Web3Provider(window.ethereum);
      await provider
        .send("eth_requestAccounts", [])
        .then((accounts) => {
          if (accounts && accounts.length > 0) {
            setAddress(accounts[0]);
            setWalletConnected(true);
            console.log("user is connected");
          }
        })
        .catch((error) => console.log(error));
      signer = provider.getSigner();
      dispatch(changeConnection());
      dispatch(setSigner(signer));
    } else {
      alert("install metamask");
    }
  };
  return (
    <div className="ConnectWallet">
      <button onClick={() => handleWallet()}>
        {walletConnected
          ? address.slice(0, 5) + "..." + address.slice(-5) + " 🔽"
          : "Connect Wallet"}
      </button>
      {showDropdown && (
        <div className="wallet_dropdown" onClick={() => handleDropdown()}>
          <p>Disconnect</p>
          <IoExitOutline />
        </div>
      )}
      {showModal && (
        <div className="navbar_modal">
          <dialog open>
            <div className="wallet_options">
              <div className="modal_header">
                <h2>Wallets</h2>
                <AiOutlineClose
                  className="close_icon"
                  onClick={() => setShowModal(false)}
                />
              </div>
              <button onClick={() => connectWithMetamask()}>Metamask</button>
              <button>Coinbase Wallet</button>
              <button>WalletConnect</button>
            </div>
          </dialog>
        </div>
      )}
    </div>
  );
};

export default ConnectWallet;
