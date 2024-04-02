import React, { useEffect, useRef, useState } from "react";
import axios from "axios";
import { Line } from "react-chartjs-2";
import * as d3 from "d3";
const BitcoinChart = () => {
  const chartRef = useRef();

  useEffect(() => {
    const apiUrl =
      "https://api.coingecko.com/api/v3/coins/bitcoin/market_chart";
    const days = 30;

    const fetchData = async () => {
      try {
        const response = await fetch(
          `${apiUrl}?vs_currency=usd&days=${days}&interval=daily`
        );
        const data = await response.json();
        return data.prices;
      } catch (error) {
        console.error("Error fetching data:", error);
      }
    };

    const createChart = async () => {
      const prices = await fetchData();

      const margin = { top: 20, right: 20, bottom: 30, left: 50 };
      const width = 800 - margin.left - margin.right;
      const height = 400 - margin.top - margin.bottom;

      const svg = d3
        .select(chartRef.current)
        .append("svg")
        .attr("width", width + margin.left + margin.right)
        .attr("height", height + margin.top + margin.bottom)
        .append("g")
        .attr("transform", `translate(${margin.left},${margin.top})`);

      const x = d3
        .scaleTime()
        .domain(d3.extent(prices, (d) => new Date(d[0])))
        .range([0, width]);

      const y = d3
        .scaleLinear()
        .domain([0, d3.max(prices, (d) => d[1])])
        .range([height, 0]);

      const line = d3
        .line()
        .x((d) => x(new Date(d[0])))
        .y((d) => y(d[1]));

      // Add the line chart
      svg
        .append("path")
        .datum(prices)
        .attr("fill", "none")
        .attr(
          "stroke",
          prices[prices.length - 1][1] >= prices[0][1] ? "#4CAF50" : "red"
        )
        .attr("stroke-width", 2)
        .attr("d", line);

      // Add X axis
      svg
        .append("g")
        .attr("transform", `translate(0, ${height})`)
        .call(d3.axisBottom(x));

      // Add Y axis
      svg.append("g").call(d3.axisLeft(y));

      // Add tooltip
      const focus = svg
        .append("g")
        .attr("class", "focus")
        .style("display", "none");

      focus
        .append("circle")
        .attr("r", 5)
        .style(
          "fill",
          prices[prices.length - 1][1] >= prices[0][1] ? "#4CAF50" : "red"
        );

      focus.append("text").attr("x", 9).attr("dy", ".35em");

      svg
        .append("rect")
        .attr("width", width)
        .attr("height", height)
        .style("fill", "none")
        .style("pointer-events", "all")
        .on("mouseover", () => focus.style("display", null))
        .on("mouseout", () => focus.style("display", "none"))
        .on("mousemove", mousemove);

      function mousemove(event) {
        const bisectDate = d3.bisector((d) => new Date(d[0])).left;
        const x0 = x.invert(d3.pointer(event)[0]);
        const i = bisectDate(prices, x0, 1);
        const d0 = prices[i - 1];
        const d1 = prices[i];
        const d = x0 - new Date(d0[0]) > new Date(d1[0]) - x0 ? d1 : d0;
        focus.attr("transform", `translate(${x(new Date(d[0]))},${y(d[1])})`);
        focus.select("text").text(() => `$${d[1].toFixed(2)}`);
      }
    };

    createChart();
  }, []);

  return <div ref={chartRef}></div>;
};

// const BitcoinChart = () => {
//   // useEffect(() => {
//   //   const fetchData = async () => {
//   // try {
//   //   axios
//   //     .get("http://localhost:8080/eth-usd-live-data")
//   //     .then((response) => {
//   //       console.log(response.data.LASTUPDATE);
//   //       console.log(response.data.PRICE);
//   // })
//   //     .catch((e) => console.log(e));
//   // } catch (error) {
//   //   console.error("Error fetching data:", error);
//   // }
//   //     console.log("yo");
//   //   };

//   //   fetchData();
//   //   const interval = setInterval(fetchData, 60000); // Fetch data every minute

//   //   return () => clearInterval(interval);
//   // }, []);

//   return (
//     <div>
//       <div className="ethereum_chart" id="ethereumChart"></div>
//     </div>
//   );
// };

export default BitcoinChart;
