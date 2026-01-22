import { For, onMount } from "solid-js";
import { NavBar } from "@components/shared/NavBar";
import { TerminalText } from "@components/ui/TerminalText";
import { LoreCard } from "@components/features/LoreCard";
import {
  lore,
  loreActions,
  proficiencyLevel,
  powerBudget,
  currentPowerUsed,
  activeCards,
} from "@features/game/stores/lore";

export const SagaPage = () => {
  onMount(() => {
    loreActions.requestCollection();
  });

  return (
    <div class={`min-h-screen bg-black text-gray-100 font-mono`}>
      <NavBar />
      <div class="p-6">
        <div class="flex justify-between items-center mb-6">
          <TerminalText class="text-2xl">Your Saga</TerminalText>
          <TerminalText class="text-xl">
            Level {proficiencyLevel()} - Power Budget: {currentPowerUsed()} / {powerBudget()}
          </TerminalText>
        </div>

        <div class="grid grid-cols-1 md:grid-cols-2 gap-8">
          {/* Active Memory Column */}
          <div>
            <TerminalText class="text-xl mb-4 border-b border-gray-700 pb-2">
              Active Memory
            </TerminalText>
            <div class="space-y-4">
              <For
                each={activeCards()}
                fallback={<TerminalText class="text-gray-500">No active cards.</TerminalText>}
              >
                {(card) => <LoreCard card={card} />}
              </For>
            </div>
          </div>

          {/* Card Collection Column */}
          <div>
            <TerminalText class="text-xl mb-4 border-b border-gray-700 pb-2">
              Card Collection
            </TerminalText>
            <div class="space-y-4 max-h-[70vh] overflow-y-auto pr-2">
              <For
                each={lore.cards}
                fallback={<TerminalText class="text-gray-500">You have not yet earned any Lore Cards.</TerminalText>}
              >
                {(card) => <LoreCard card={card} />}
              </For>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}; 