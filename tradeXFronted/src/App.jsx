import { useEffect, useState } from "react";
import "./App.css";
import Navbar from "./components/Navbar/Navbar";
import Footer from "./components/Footer/Footer";
import Home from "./components/Home/Home";
import { Provider } from "react-redux";
import store from "./components/Store";

function App() {
  return (
    <Provider store={store}>
      <div className="app">
        <div className="app_container">
          <Navbar />
          <Home />
          <Footer />
        </div>
      </div>
    </Provider>
  );
}

export default App;
