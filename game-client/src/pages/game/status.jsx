import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import { character } from "@features/auth/stores/character";
import { Show } from "solid-js";

export const StatusFrame = () => {

    return (
        <div class={`h-1/3 bg-gray-900/95 border ${theme().border} backdrop-blur-sm rounded-lg p-4 overflow-y-auto`}>
            <TerminalText class="text-lg mb-2">Status</TerminalText>
            <div class="grid grid-cols-2 gap-x-6 gap-y-2">
                <div class="flex items-center justify-between">
                    <TerminalText class="text-sm text-gray-400">Health:</TerminalText>
                    <TerminalText>{character.health} / {character.max_health}</TerminalText>
                </div>
                
                <div class="flex items-center justify-between">
                    <TerminalText class="text-sm text-gray-400">Action Points:</TerminalText>
                    <TerminalText>{character.action_points} / {character.max_action_points}</TerminalText>
                </div>
            </div>
        </div>
    );
};