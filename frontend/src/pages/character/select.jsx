import { createSignal, Show, For, onMount, createEffect } from "solid-js";
import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import { 
    characters, 
    loadingCharacters, 
    characterError,
    characterActions
} from "@features/auth/stores/character";

const CharacterSelectPage = () => {
    const [selectedIndex, setSelectedIndex] = createSignal(0);
    const [error, setError] = createSignal("");
    
    let containerRef;

    const focusContainer = () => {
        containerRef?.focus();
    };

    onMount(() => {
        focusContainer();
    });

    // Focus after characters load
    createEffect(() => {
        const isLoading = loadingCharacters();
        if (!isLoading) {
            focusContainer();
        }
    });

    onMount(async () => {
        try {
            if (characterActions) {
                await characterActions.list();
            } else {
                setError("Character system not initialized. Please try again.");
            }
        } catch (err) {
            setError(err.message);
        }
    });

    const handleKeyDown = async (e) => {
        e.preventDefault();

        if (e.key === "Escape") {
            history.back();
            return;
        }
        
        if (e.key === "ArrowUp") {
            setSelectedIndex(prev => 
                prev > 0 ? prev - 1 : characters.length - 1
            );
            return;
        }
        
        if (e.key === "ArrowDown") {
            setSelectedIndex(prev => 
                prev < characters.length - 1 ? prev + 1 : 0
            );
            return;
        }

        if (e.key === "Enter" && characters.length > 0) {
            await handleCharacterSelect(characters[selectedIndex()]);
        }
    };

    const handleCharacterSelect = async (character) => {
        if (!characterActions) {
            setError("Character system not initialized. Please try again.");
            return;
        }

        try {
            setError("");
            await characterActions.select(character.id);
        } catch (err) {
            setError(err.message || "Failed to select character");
        }
    };

    return (
        <div
            class="fixed inset-0 flex items-center justify-center bg-black focus:outline-none"
            onKeyDown={handleKeyDown}
            tabIndex={0}
            ref={containerRef}
        >
            <div class={`bg-black p-8 w-full max-w-2xl font-mono ${theme().textBase} ${theme().border} ${theme().shadow}`}>
                <div class="mb-8">
                    <TerminalText class="text-2xl">Select Your Character</TerminalText>
                    <TerminalText class={`mt-2 ${theme().textDim}`}>
                        [Use arrow keys to navigate, ENTER to select, ESC to go back]
                    </TerminalText>
                    <div class={`h-px ${theme().textDimmest} mt-4`} />
                </div>

                <Show 
                    when={!loadingCharacters()} 
                    fallback={
                        <TerminalText class={theme().textDim}>
                            Loading characters...
                        </TerminalText>
                    }
                >
                    <Show 
                        when={characters.length > 0} 
                        fallback={
                            <TerminalText class={theme().textDim}>
                                No characters found. Create a new character to begin your adventure.
                            </TerminalText>
                        }
                    >
                        <div class="space-y-4">
                            <For each={characters}>
                                {(character, index) => (
                                    <div 
                                        class={`p-2 ${selectedIndex() === index() ? 
                                            `border ${theme().border}` : ''}`}
                                    >
                                        <TerminalText>
                                            [{index() + 1}] {character.name} - Level {character.level} {character.class}
                                        </TerminalText>
                                    </div>
                                )}
                            </For>
                        </div>
                    </Show>
                </Show>

                <Show when={error() || characterError()}>
                    <div class="bg-red-500 text-white p-2 rounded-lg mt-4">
                        <TerminalText>
                            {error() || characterError()}
                        </TerminalText>
                    </div>
                </Show>

                <div class={`mt-8 pt-4 border-t ${theme().textDimmest}`}>
                    <TerminalText class={theme().textDimmer}>
                        {characters.length > 0 
                            ? "Use arrow keys to select a character..." 
                            : "Press ESC to go back..."}
                    </TerminalText>
                </div>
            </div>
        </div>
    );
};

export default CharacterSelectPage;