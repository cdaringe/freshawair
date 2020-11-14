import React from "react";
import "./App.css";
import { Layout } from "./Layout";
import { AirChartPage } from "./AirChartPage";
import { Provider } from "./QueryContext";

function App() {
  return (
    <Provider>
      <Layout children={<AirChartPage />} />
    </Provider>
  );
}

export default App;
