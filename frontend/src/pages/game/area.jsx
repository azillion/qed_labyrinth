import { Show } from "solid-js";
import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import { area, isLoading, error } from "@features/game/stores/area";

export const AreaFrame = () => {
    return (
        <div class={`w-2/3 bg-gray-900/95 border ${theme().border} backdrop-blur-sm rounded-lg p-4 overflow-y-auto`}>
            <Show when={!isLoading()} fallback={<TerminalText>Loading area...</TerminalText>}>
                <Show when={area.name} fallback={<TerminalText>No area loaded</TerminalText>}>
                    <TerminalText class="text-xl mb-4">{area.name}</TerminalText>
                    <TerminalText class="mb-4">
                        <pre innerHTML={area.description} class="whitespace-pre-wrap" />
                    </TerminalText>
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
    );
};