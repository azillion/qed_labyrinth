import { createSignal, Show, onMount } from "solid-js";

import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import { characterActions, characterError } from "@features/auth/stores/character";

const CharacterCreatePage = () => {
    const [name, setName] = createSignal("");
    const [error, setError] = createSignal("");

    let containerRef;

    const focusContainer = () => {
        containerRef?.focus();
    };

    onMount(() => {
        focusContainer();
    });

    const handleKeyDown = async (e) => {
        e.preventDefault();

        if (e.key === "Escape") {
            history.back();
            return;
        }

        if (e.key === "Enter" && name().trim()) {
            await handleCreateCharacter();
            return;
        } else if (e.key.length === 1) {
            // Only allow letters and numbers, max 20 characters
            if (/^[a-zA-Z0-9]$/.test(e.key) && name().length < 20) {
                setName(prev => prev + e.key);
            }
        } else if (e.key === "Backspace") {
            setName(prev => prev.slice(0, -1));
        }
    };

    const handleCreateCharacter = async () => {
        if (!characterActions) {
            setError("Character system not initialized. Please try again.");
            return;
        }

        if (!name().trim()) {
            setError("Please enter a character name");
            return;
        }

        try {
            setError("");
            await characterActions.create({ name: name().trim() });
        } catch (err) {
            setError(err.message || "Failed to create character");
        }
    };

    return (
        <div
            class="fixed inset-0 flex items-center justify-center bg-black focus:outline-none transition-all duration-300 ease-in-out"
            onKeyDown={handleKeyDown}
            tabIndex={0}
            ref={containerRef}
        >
            <div class={`bg-black p-8 w-full max-w-4xl font-mono ${theme().textBase} ${theme().border} ${theme().shadow}`}>
                <div class="mb-8">
                    <TerminalText class="text-2xl">Create New Character</TerminalText>
                    <TerminalText class={`mt-2 ${theme().textDim}`}>
                        [Type to enter name, ENTER to create, ESC to go back]
                    </TerminalText>
                    <div class={`h-px ${theme().textDimmest} mt-4`} />
                </div>

                <div class="space-y-4">
                    <TerminalText>Enter character name:</TerminalText>
                    <div class={`p-2 border ${theme().border}`}>
                        <TerminalText>{name() || "_"}</TerminalText>
                    </div>

                    <Show when={error() || characterError()}>
                        <div class="bg-red-500 text-white p-2 rounded-lg mt-4">
                            <TerminalText>
                                {error() || characterError()}
                            </TerminalText>
                        </div>
                    </Show>

                    <div class={`mt-8 pt-4 border-t ${theme().textDimmest}`}>
                        <TerminalText class={theme().textDimmer}>
                            Type your character name and press Enter to create...
                        </TerminalText>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default CharacterCreatePage;
