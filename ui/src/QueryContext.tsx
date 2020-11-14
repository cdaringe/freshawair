import React, { useContext, useEffect, useState } from "react";
import { getQuery } from "./query";
export const QueryContext = React.createContext(getQuery());
export const Provider: React.FC = (props) => {
  const [ctx, setCtx] = useState(getQuery());
  useEffect(() => {
    const onStateChange = () => setCtx(getQuery());
    window.addEventListener("popstate", onStateChange);
    return () => window.removeEventListener("popstate", onStateChange);
  }, []);
  return <QueryContext.Provider value={ctx} {...props} />;
};
export const useQuery = () => {
  return useContext(QueryContext);
};
