import { createSignal } from "solid-js";
import { theme } from "@stores/themeStore";
import { areaActions } from "@features/game/stores/area";

export const CommandInput = () => {
    const [commandInput, setCommandInput] = createSignal("");
    const [commandHistory, setCommandHistory] = createSignal([]);
    const [historyIndex, setHistoryIndex] = createSignal(-1);

    const addToHistory = (command) => {
        setCommandHistory(prev => [...prev, command]);
        setHistoryIndex(-1);
    };

    const handleCommand = async (e) => {
        if (e.key !== "Enter" || !commandInput().trim()) return;

        const command = commandInput().trim().toLowerCase();
        addToHistory(command);

        // Basic movement commands
        if (command.startsWith("go ")) {
            const direction = command.split(" ")[1];
            try {
                await areaActions.move(direction);
            } catch (err) {
                console.error("Movement failed:", err);
            }
        } else if (command.startsWith("look ")) {
            const target = command.split(" ")[1];
            try {
                await areaActions.examine(target);
            } catch (err) {
                console.error("Examination failed:", err);
            }
        }

        setCommandInput("");
    };

    const handleKeyDown = (e) => {
        if (e.key === "ArrowUp") {
            e.preventDefault();
            const history = commandHistory();
            if (historyIndex() < history.length - 1) {
                const newIndex = historyIndex() + 1;
                setHistoryIndex(newIndex);
                setCommandInput(history[history.length - 1 - newIndex]);
            }
        } else if (e.key === "ArrowDown") {
            e.preventDefault();
            if (historyIndex() > 0) {
                const newIndex = historyIndex() - 1;
                setHistoryIndex(newIndex);
                setCommandInput(commandHistory()[commandHistory().length - 1 - newIndex]);
            } else if (historyIndex() === 0) {
                setHistoryIndex(-1);
                setCommandInput("");
            }
        }
    };

    return (
        <div class="p-4">
            <input
                type="text"
                value={commandInput()}
                onInput={(e) => setCommandInput(e.currentTarget.value)}
                onKeyDown={handleKeyDown}
                onKeyPress={handleCommand}
                class={`w-full bg-gray-900/95 border ${theme().border} backdrop-blur-sm 
                       rounded-lg px-4 py-2 font-mono ${theme().textBase}
                       focus:outline-none focus:ring-1 focus:${theme().border}`}
                placeholder="Enter command (e.g., 'go north', 'look around')..."
            />
        </div>
    );
};