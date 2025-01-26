import { Show, createMemo } from "solid-js";
import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import { area, isLoading, error } from "../../features/game/stores/area";
import { chatActions } from "@features/game/stores/chat";

const EXIT_DIRECTION_TO_COMMAND = {
    north: "/north",
    south: "/south",
    east: "/east",
    west: "/west",
    up: "/up",
    down: "/down",
};

const DIRECTION_ORDER = {
    north: 0,
    south: 1,
    east: 2,
    west: 3,
    up: 4,
    down: 5
};

export const AreaFrame = () => {
    const hasArea = createMemo(() => {
        console.log('Current area name:', area.name);
        return Boolean(area.name);
    });
    
    const orderedExits = createMemo(() => {
        return [...area.exits].sort((a, b) => 
            DIRECTION_ORDER[a.direction] - DIRECTION_ORDER[b.direction]
        );
    });

    const hasExits = createMemo(() => {
        console.log('Current area exits:', area.exits);
        return area.exits.length > 0;
    });

    return (
        <div class={`w-2/3 bg-gray-900/95 border ${theme().border} backdrop-blur-sm rounded-lg p-4 overflow-y-auto`}>
            <Show when={!isLoading()} fallback={<TerminalText>Loading area...</TerminalText>}>
                {hasArea() ? (
                    <>
                        <TerminalText class="text-xl mb-4">{area.name}</TerminalText>
                        <TerminalText class="mb-4">
                            <pre innerHTML={area.description} class="whitespace-pre-wrap max-h-[20vh] overflow-y-auto" />
                        </TerminalText>
                        {hasExits() && (
                            <TerminalText class={`${theme().textDim}`}>
                                Exits:{" "}
                                {orderedExits().map((exit, i) => (
                                    <>
                                        <span 
                                            class="cursor-pointer hover:text-white transition-colors select-none"
                                            onClick={() => chatActions.command(EXIT_DIRECTION_TO_COMMAND[exit.direction])}
                                        >
                                            {exit.direction}
                                        </span>
                                        <span class="text-gray-500 select-none">{i < area.exits.length - 1 ? ", " : ""}</span>
                                    </>
                                ))}
                            </TerminalText>
                        )}
                    </>
                ) : (
                    <TerminalText>No area loaded</TerminalText>
                )}
            </Show>
            <Show when={error()}>
                <TerminalText class="text-red-500 mt-4">{error()}</TerminalText>
            </Show>
        </div>
    );
};