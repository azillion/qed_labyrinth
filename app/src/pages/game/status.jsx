import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import { status, isLoading, error, statusActions } from "@features/game/stores/status";
import { Show } from "solid-js";
import { onMount, onCleanup } from "solid-js";

const STATUS_REFRESH_INTERVAL = 1000 * 60 * 2; // 2 minutes

export const StatusFrame = () => {
    let interval;
    onMount(() => {
        statusActions.requestStatus();
        interval = setInterval(() => {
            statusActions.requestStatus();
        }, STATUS_REFRESH_INTERVAL);
    });

    onCleanup(() => {
        clearInterval(interval);
    });

    return (
        <div class={`h-1/3 bg-gray-900/95 border ${theme().border} backdrop-blur-sm rounded-lg p-4 overflow-y-auto`}>
            <TerminalText class="text-lg mb-2">Status</TerminalText>
            <Show 
                when={!isLoading()} 
                fallback={<TerminalText class="text-sm text-gray-400">Loading...</TerminalText>}
            >
                <Show 
                    when={!error()} 
                    fallback={<TerminalText class="text-sm text-red-400">{error()}</TerminalText>}
                >
                    <div class="grid grid-cols-2 gap-x-6 gap-y-2">
                        <div class="flex items-center justify-between">
                            <TerminalText class="text-sm text-gray-400">Health:</TerminalText>
                            <TerminalText>{status.health}</TerminalText>
                        </div>
                        
                        <div class="flex items-center justify-between">
                            <TerminalText class="text-sm text-gray-400">Exp:</TerminalText>
                            <TerminalText>{status.experience}</TerminalText>
                        </div>
                        
                        <div class="flex items-center justify-between">
                            <TerminalText class="text-sm text-gray-400">Mana:</TerminalText>
                            <TerminalText>{status.mana}</TerminalText>
                        </div>

                        <div class="flex items-center justify-between">
                            <TerminalText class="text-sm text-gray-400">Time:</TerminalText>
                            <TerminalText>{status.time_of_day}</TerminalText>
                        </div>
                    </div>
                </Show>
            </Show>
        </div>
    );
};