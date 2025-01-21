import { createSignal } from "solid-js";
import { theme } from "@stores/themeStore";
import { messageHandlers } from "@lib/socket";

export const CommandInput = () => {
    const [commandInput, setCommandInput] = createSignal("");
    const [commandHistory, setCommandHistory] = createSignal([]);
    const [historyIndex, setHistoryIndex] = createSignal(-1);

    const addToHistory = (input) => {
        setCommandHistory(prev => [...prev, input]);
        setHistoryIndex(-1);
    };

    const handleInput = async (e) => {
        if (e.key !== "Enter" || !commandInput().trim()) return;

        const input = commandInput().trim();
        addToHistory(input);

        // Route to appropriate handler based on prefix
        if (input.startsWith('/')) {
            try {
                await messageHandlers.game.command(input);
            } catch (err) {
                console.error("Command failed:", err);
            }
        } else {
            try {
                await messageHandlers.chat.send(input);
            } catch (err) {
                console.error("Chat failed:", err);
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
                onKeyPress={handleInput}
                class={`w-full bg-gray-900/95 border ${theme().border} backdrop-blur-sm 
                       rounded-lg px-4 py-2 font-mono ${theme().textBase}
                       focus:outline-none focus:ring-1 focus:${theme().border}`}
                placeholder="Type /help for commands or just chat..."
            />
        </div>
    );
};