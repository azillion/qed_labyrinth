import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import { loreActions } from "@features/game/stores/lore";

const toTitleCase = (str) => {
  return str.charAt(0).toUpperCase() + str.slice(1);
};

export const LoreCard = (props) => {
  const card = props.card;

  const handleActivate = () => {
    loreActions.activateCard(card.id);
  };

  const handleDeactivate = () => {
    loreActions.deactivateCard(card.id);
  };

  return (
    <div
      class={`p-4 border rounded ${theme().border} ${
        card.isActive ? "bg-green-900/20" : "bg-gray-900/50"
      }`}
    >
      <TerminalText class="text-lg text-white">{card.title}</TerminalText>
      <TerminalText class={`mt-2 ${theme().textDim}`}>
        {card.description}
      </TerminalText>

      {/* Bonus Stats */}
      {card.bonusesList && card.bonusesList.length > 0 && (
        <div class="mt-2 space-y-1">
          {card.bonusesList.map((bonus) => (
            <TerminalText class="text-sm text-blue-300">
              {toTitleCase(bonus.type)}: +{bonus.value}
            </TerminalText>
          ))}
        </div>
      )}
      <div
        class={`mt-4 pt-2 border-t ${theme().border} flex justify-between items-center`}
      >
        <TerminalText class="text-yellow-400">
          Power Cost: {card.powerCost}
        </TerminalText>
        {card.isActive ? (
          <button
            onClick={handleDeactivate}
            class="text-red-400 hover:text-red-200"
          >
            [Deactivate]
          </button>
        ) : (
          <button
            onClick={handleActivate}
            class="text-green-400 hover:text-green-200"
          >
            [Activate]
          </button>
        )}
      </div>
    </div>
  );
}; 