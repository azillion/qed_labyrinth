import { For, Show } from "solid-js";
import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import { inventory, isLoading } from "@features/game/stores/inventory";

export const InventoryFrame = () => {
    return (
        <div class={`w-1/3 bg-gray-900/95 border ${theme().border} backdrop-blur-sm rounded-lg p-4 overflow-y-auto`}>
            <TerminalText class="text-lg mb-2">Inventory</TerminalText>
            
            <Show when={isLoading()}>
                <TerminalText class={theme().textDim}>...</TerminalText>
            </Show>

            <div class="space-y-2">
                <For each={inventory} fallback={<TerminalText class={theme().textDim}>Empty</TerminalText>}>
                    {(item) => (
                        <TerminalText>
                            {item.name} <span class={theme().textDimmer}>(x{item.quantity})</span>
                        </TerminalText>
                    )}
                </For>
            </div>
        </div>
    );
};