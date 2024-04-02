const express = require("express");
const cors = require("cors");
const axios = require("axios");

const app = express();

app.use(express.json());
app.use(cors());
const api =
  "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=ETH&tsyms=USD";

app.get("/eth-usd-live-data", (req, res) => {
  try {
    axios
      .get(api)
      .then((response) => {
        console.log(response.data.RAW.ETH.USD);
        const data = response.data.RAW.ETH.USD;
        res.send(data);
      })
      .catch((error) => console.log(error));
  } catch (e) {
    console.log(e);
  }
});

app.listen("8080", (req, res) => {
  console.log("listening on port 8080");
});
