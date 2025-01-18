/* @refresh reload */
import { render } from "solid-js/web";
import { Router, Route } from "@solidjs/router";

import "./index.css";
import "./styles/base.css";
import { messageHandlers } from "@lib/socket";
import App from "./App";

import GamePage from "@pages/game";
const root = document.getElementById("root");

if (import.meta.env.DEV && !(root instanceof HTMLElement)) {
  throw new Error(
    "Root element not found. Did you forget to add it to your index.html? Or maybe the id attribute got misspelled?",
  );
}

render(() => (
  <App>
      <Router>
        <Route path="/" component={GamePage} />
      </Router>
  </App>
), root);
