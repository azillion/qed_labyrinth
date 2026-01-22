import { createSignal } from "solid-js";
import { socketManager } from "@lib/socket";

export const [metrics, setMetrics] = createSignal(null);
export const [isLoading, setIsLoading] = createSignal(false);

export const adminHandlers = {
  'AdminMetrics': (payload) => {
    try {
      // The payload is a stringified JSON, so we need to parse it.
      const parsedMetrics = JSON.parse(payload.metrics);
      setMetrics(JSON.stringify(parsedMetrics, null, 2)); // Pretty-print the JSON
    } catch (e) {
      console.error("Failed to parse metrics JSON:", e);
      setMetrics("Error: Invalid JSON received from server.");
    }
    setIsLoading(false);
  }
};

export const adminActions = {
  requestMetrics: () => {
    setIsLoading(true);
    setMetrics(null); // Clear previous metrics
    socketManager.send('RequestAdminMetrics');
  }
};