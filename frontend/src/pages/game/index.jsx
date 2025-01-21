import { StatusFrame } from "./status";
import { InventoryFrame } from "./inventory";
import { AreaFrame } from "./area";
import { ChatFrame } from "./chat";
import { CommandInput } from "./command";

const GamePage = () => {
    return (
        <div class="h-screen bg-black text-gray-100 font-mono flex flex-col">
            {/* Top Section - Status & Inventory */}
            <div class="h-1/4 flex gap-4 p-4">
                <StatusFrame />
                <InventoryFrame />
            </div>

            {/* Middle Section - Main Area & Chat */}
            <div class="flex-1 flex gap-4 px-4">
                <AreaFrame />
                <ChatFrame />
            </div>

            {/* Command Input */}
            <CommandInput />
        </div>
    );
};

export default GamePage;