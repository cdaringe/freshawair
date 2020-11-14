import Typography from "@material-ui/core/Typography";
import React from "react";
import { AirChart } from "./AirChart";
import { AirChartBinningControl } from "./AirChartBinningControl";
import { useQuery } from "./QueryContext";

export const AirChartPage: React.FC = () => {
  const [binningValue, setBinningValue] = React.useState("hour");
  const chart = <AirChart binningValue={binningValue} />;
  if (useQuery().focusMode) return chart;
  return (
    <>
      <Typography variant="h3">AirChart™</Typography>
      {chart}
      <AirChartBinningControl
        options={["minute", "hour", "day"]}
        value={binningValue}
        onSelect={(evt) => setBinningValue(evt.currentTarget.value!)}
      />
    </>
  );
};
