import React from "react";
import CssBaseline from "@material-ui/core/CssBaseline";
import Typography from "@material-ui/core/Typography";
import { makeStyles } from "@material-ui/core/styles";
import Container from "@material-ui/core/Container";
import Link from "@material-ui/core/Link";
import { useQuery } from "./QueryContext";

function Copyright() {
  return (
    <Typography variant="body2" color="textSecondary">
      {"Copyright © "}
      <Link color="inherit" href="https://material-ui.com/">
        Your Website
      </Link>
      {" "}
      {new Date().getFullYear()}
      {"."}
    </Typography>
  );
}

const useStyles = makeStyles((theme) => ({
  root: {
    display: "flex",
    flexDirection: "column",
    minHeight: "100vh",
  },
  main: {
    // marginTop: theme.spacing(8),
    // marginBottom: theme.spacing(2),
  },
  footer: {
    padding: theme.spacing(3, 2),
    marginTop: "auto",
    backgroundColor: theme.palette.type === "light"
      ? theme.palette.grey[200]
      : theme.palette.grey[800],
  },
}));
export const Layout: React.FC = ({ children }) => {
  const classes = useStyles();
  if (useQuery().focusMode) return children as any;
  return (
    <div className={classes.root}>
      <CssBaseline />
      <Container component="main" className={`${classes.main}`} maxWidth="sm">
        {children}
        {/* <Typography variant="h5" component="h2" gutterBottom>
          {"Pin a footer to the bottom of the viewport."}
          {"The footer will move as the main element of the page grows."}
        </Typography>
        <Typography variant="body1">Sticky footer placeholder.</Typography> */}
      </Container>
      <footer className={classes.footer}>
        <Container maxWidth="sm">
          <Typography variant="body1">
            My sticky footer can be found here.
          </Typography>
          <Copyright />
        </Container>
      </footer>
    </div>
  );
};
