import { createMemo, createEffect, onCleanup } from "solid-js";

import { StatusFrame } from "./status";
import { AreaFrame } from "./area";
import { ChatFrame } from "./chat";
import { CommandInput } from "./command";
import { chatActions } from "../../features/game/stores/chat";
import { currentFocus } from "../../features/game/stores/game";
import { NavBar } from "../../components/shared/NavBar";

const GamePage = () => {
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
            <NavBar />
            <div class="h-[85%] flex gap-4 p-4">
                <AreaFrame />
                {/* Middle Section - Main Area & Chat */}
                <div class="w-1/2 flex flex-col gap-4">
                    <StatusFrame />
                    <ChatFrame />
                </div>
            </div>

            {/* Command Input */}
            <div class="h-[10%]">
                <CommandInput />
            </div>
        </div>
    );
};

export default GamePage;