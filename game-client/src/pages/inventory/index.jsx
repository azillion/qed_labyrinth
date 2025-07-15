import { For, Show } from "solid-js";
import { NavBar } from "@components/shared/NavBar";
import { TerminalText } from "@components/ui/TerminalText";
import { inventory, isLoading, error } from "@features/game/stores/inventory";
import { inventoryActions } from "@features/game/stores/inventory";
import { theme } from "@stores/themeStore";

export const InventoryPage = () => {
    return (
        <div class={`min-h-screen bg-black text-gray-100 font-mono`}>
            <NavBar />
            <div class="p-6">
                <TerminalText class="text-2xl mb-6">Inventory</TerminalText>

                <Show when={isLoading()}>
                    <TerminalText class={theme().textDim}>Loading inventory...</TerminalText>
                </Show>

                <Show when={error()}>
                    <TerminalText class="text-red-500">{error()}</TerminalText>
                </Show>

                <Show when={!isLoading() && inventory.length === 0}>
                    <TerminalText class={theme().textDim}>Your inventory is empty.</TerminalText>
                </Show>

                <div class="space-y-4">
                    <For each={inventory}>
                        {(item) => (
                            <div class={`p-4 border rounded ${theme().border}`}>
                                <TerminalText class="text-lg text-white">
                                  {item.name} (x{item.quantity})
                                  <span
                                    class="ml-3 cursor-pointer text-red-400 hover:text-red-200"
                                    onClick={() => inventoryActions.drop(item.id)}
                                  >
                                    [drop]
                                  </span>
                                </TerminalText>
                                <TerminalText class={`mt-2 ${theme().textDim}`}>{item.description}</TerminalText>
                            </div>
                        )}
                    </For>
                </div>
            </div>
        </div>
    );
};