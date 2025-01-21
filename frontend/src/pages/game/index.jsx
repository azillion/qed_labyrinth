import { createSignal, onMount, Show } from "solid-js";
import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import { area, isLoading, error, areaActions } from "@features/game/stores/area";

const GamePage = () => {
    const [commandInput, setCommandInput] = createSignal("");

    // Command history handling
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

    // Command history navigation
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
        <div class="h-screen bg-black text-gray-100 font-mono flex flex-col">
            {/* Top Section - Status & Inventory */}
            <div class="h-1/4 flex gap-4 p-4">
                <div class={`w-1/2 bg-gray-900/95 border ${theme().border} backdrop-blur-sm rounded-lg p-4 overflow-y-auto`}>
                    <TerminalText class="text-lg mb-2">Status</TerminalText>
                    {/* Status content will go here */}
                </div>
                <div class={`w-1/2 bg-gray-900/95 border ${theme().border} backdrop-blur-sm rounded-lg p-4 overflow-y-auto`}>
                    <TerminalText class="text-lg mb-2">Inventory</TerminalText>
                    {/* Inventory content will go here */}
                </div>
            </div>

            {/* Middle Section - Main Area & Chat */}
            <div class="flex-1 flex gap-4 px-4">
                {/* Main Area Display */}
                <div class={`w-2/3 bg-gray-900/95 border ${theme().border} backdrop-blur-sm rounded-lg p-4 overflow-y-auto`}>
                    <Show when={!isLoading()} fallback={<TerminalText>Loading area...</TerminalText>}>
                        <Show when={area.name} fallback={<TerminalText>No area loaded</TerminalText>}>
                            <TerminalText class="text-xl mb-4">{area.name}</TerminalText>
                            <TerminalText class="mb-4">{area.description}</TerminalText>
                            <Show when={area.exits.length > 0}>
                                <TerminalText class={`${theme().textDim}`}>
                                    Exits: {area.exits.map(exit => exit.direction).join(", ")}
                                </TerminalText>
                            </Show>
                        </Show>
                    </Show>
                    <Show when={error()}>
                        <TerminalText class="text-red-500 mt-4">{error()}</TerminalText>
                    </Show>
                </div>

                {/* Chat Section */}
                <div class={`w-1/3 bg-gray-900/95 border ${theme().border} backdrop-blur-sm rounded-lg p-4 overflow-y-auto`}>
                    <TerminalText class="text-lg mb-2">Chat</TerminalText>
                    {/* Chat messages will go here */}
                </div>
            </div>

            {/* Command Input */}
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
        </div>
    );
};

export default GamePage;