import React from "react";
import Radio from "@material-ui/core/Radio";
import RadioGroup, { RadioGroupProps } from "@material-ui/core/RadioGroup";
import FormControl from "@material-ui/core/FormControl";
import FormLabel from "@material-ui/core/FormLabel";
import FormControlLabel from "@material-ui/core/FormControlLabel";

type Props = {
  options: string[] /* minutely, hourly, daily */;
  onSelect: RadioGroupProps["onChange"];
  value: string;
};

export const AirChartBinningControl: React.FC<Props> = ({
  options,
  onSelect,
  children,
  value,
  ...rest
}) => {
  return (
    <FormControl component="fieldset" {...rest}>
      <FormLabel component="legend">Bin size</FormLabel>
      <RadioGroup
        aria-label="bin size"
        name="bin_size"
        value={value}
        onChange={onSelect}
      >
        {options.map((option) => (
          <FormControlLabel
            key={option}
            value={option}
            control={<Radio />}
            label={option}
          />
        ))}
      </RadioGroup>
    </FormControl>
  );
};
