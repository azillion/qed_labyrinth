import { useNavigate } from "@solidjs/router";
import { createMemo, createEffect, onCleanup } from "solid-js";

import { StatusFrame } from "./status";
import { InventoryFrame } from "./inventory";
import { AreaFrame } from "./area";
import { ChatFrame } from "./chat";
import { CommandInput } from "./command";
import { chatActions } from "../../features/game/stores/chat";
import { currentFocus } from "../../features/game/stores/game";

const GamePage = () => {
    const navigate = useNavigate();
    const isAreaFocused = createMemo(() => currentFocus() === "area");

    createEffect(() => {
        const handleKeyPress = (e) => {
            if (!isAreaFocused()) return;
            
            switch (e.key.toLowerCase()) {
                case 'w':
                    // Move north
                    chatActions.command("/north");
                    break;
                case 's':
                    // Move south
                    chatActions.command("/south");
                    break;
                case 'a':
                    // Move west
                    chatActions.command("/west");
                    break;
                case 'd':
                    // Move east
                    chatActions.command("/east");
                    break;
                case 'e':
                    // Move up
                    chatActions.command("/up");
                    break;
                case 'q':
                    // Move down
                    chatActions.command("/down");
                    break;
            }
        };

        window.addEventListener('keydown', handleKeyPress);
        
        onCleanup(() => {
            window.removeEventListener('keydown', handleKeyPress);
        });
    });

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