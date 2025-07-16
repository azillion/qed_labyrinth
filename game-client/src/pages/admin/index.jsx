import { Show } from "solid-js";
import { NavBar } from "@components/shared/NavBar";
import { Button } from "@components/ui/Button";
import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import { metrics, isLoading, adminActions } from "@features/game/stores/admin";

const AdminPage = () => {
  return (
    <div class={`min-h-screen bg-black text-gray-100 font-mono`}>
      <NavBar />
      <div class="p-6">
        <TerminalText class="text-2xl mb-6">Admin Dashboard</TerminalText>

        <div class="mb-8">
          <Button onClick={adminActions.requestMetrics} disabled={isLoading()}>
            {isLoading() ? "Loading Metrics..." : "Refresh Engine Metrics"}
          </Button>
        </div>

        <Show when={metrics()}>
          <TerminalText class="text-lg mb-4">Engine Metrics Report</TerminalText>
          <pre class={`p-4 border rounded ${theme().border} bg-gray-900/50 overflow-x-auto`}>
            {metrics()}
          </pre>
        </Show>
      </div>
    </div>
  );
};

export default AdminPage; 