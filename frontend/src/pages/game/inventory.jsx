import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";

export const InventoryFrame = () => {
    return (
        <div class={`w-1/2 bg-gray-900/95 border ${theme().border} backdrop-blur-sm rounded-lg p-4 overflow-y-auto`}>
            <TerminalText class="text-lg mb-2">Inventory</TerminalText>
            {/* Inventory content will go here */}
        </div>
    );
};