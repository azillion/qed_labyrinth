import { useNavigate } from "@solidjs/router";

import { StatusFrame } from "./status";
import { InventoryFrame } from "./inventory";
import { AreaFrame } from "./area";
import { ChatFrame } from "./chat";
import { CommandInput } from "./command";

const GamePage = () => {
    const navigate = useNavigate();

    return (
        <div class="h-screen bg-black text-gray-100 font-mono flex flex-col">
            <button onClick={() => navigate("/map")}>Map</button>
            {/* Top Section - Status & Inventory */}
            <div class="h-[25%] flex gap-4 p-4">
                <StatusFrame />
                <InventoryFrame />
            </div>

            {/* Middle Section - Main Area & Chat */}
            <div class="h-[65%] flex gap-4 px-4">
                <AreaFrame />
                <ChatFrame />
            </div>

            {/* Command Input */}
            <div class="h-[10%]">
                <CommandInput />
            </div>
        </div>
    );
};

export default GamePage;