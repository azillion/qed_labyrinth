import { createSignal, Show, onMount } from "solid-js";

import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import { characterActions, characterError } from "@features/auth/stores/character";

const CharacterCreatePage = () => {
    const [step, setStep] = createSignal('name');
    const [name, setName] = createSignal("");
    const [error, setError] = createSignal("");

    const totalPoints = 20;
    const [might, setMight] = createSignal(1);
    const [finesse, setFinesse] = createSignal(1);
    const [wits, setWits] = createSignal(1);
    const [grit, setGrit] = createSignal(1);
    const [presence, setPresence] = createSignal(1);
    const [remainingPoints, setRemainingPoints] = createSignal(totalPoints - 5);

    let containerRef;

    const focusContainer = () => {
        containerRef?.focus();
    };

    onMount(() => {
        focusContainer();
    });

    const handleKeyDown = async (e) => {
        // Only handle keyboard events when we're on the name step
        if (step() !== 'name') {
            return;
        }

        e.preventDefault();

        if (e.key === "Escape") {
            history.back();
            return;
        }

        if (e.key === "Enter" && name().trim()) {
            setStep('stats');
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
            await characterActions.create({
                name: name().trim(),
                might: might(),
                finesse: finesse(),
                wits: wits(),
                grit: grit(),
                presence: presence()
            });
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

                <Show when={step() === 'name'}>
                    <div class="space-y-4">
                        <TerminalText>Enter character name:</TerminalText>
                        <div class={`p-2 border ${theme().border}`}>
                            <TerminalText>{name() || "_"}</TerminalText>
                        </div>
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
                            Type your character name...
                        </TerminalText>
                    </div>
                </Show>

                <Show when={step() === 'stats'}>
                    <div class="flex flex-col md:flex-row gap-8">
                        <div class="space-y-6 w-full md:w-1/2">
                            <TerminalText class="text-xl">Allocate Attribute Points</TerminalText>
                            <TerminalText class={theme().textDim}>
                                Points Remaining: {remainingPoints()}
                            </TerminalText>
                            
                            <div class="space-y-4">
                                <div class="flex justify-between items-center">
                                    <TerminalText>Might:</TerminalText>
                                    <div class="flex items-center gap-4">
                                        <button 
                                            onClick={() => {
                                                if (might() > 1) {
                                                    setMight(might() - 1);
                                                    setRemainingPoints(remainingPoints() + 1);
                                                }
                                            }}
                                            class={`w-8 h-8 border text-center cursor-pointer hover:bg-gray-700 ${theme().border} ${theme().textBase} ${might() > 1 ? '' : 'opacity-50 cursor-not-allowed'}`}
                                            disabled={might() <= 1}
                                        >
                                            -
                                        </button>
                                        <TerminalText class="w-8 text-center">{might()}</TerminalText>
                                        <button 
                                            onClick={() => {
                                                if (remainingPoints() > 0) {
                                                    setMight(might() + 1);
                                                    setRemainingPoints(remainingPoints() - 1);
                                                }
                                            }}
                                            class={`w-8 h-8 border text-center cursor-pointer hover:bg-gray-700 ${theme().border} ${theme().textBase} ${remainingPoints() > 0 ? '' : 'opacity-50 cursor-not-allowed'}`}
                                            disabled={remainingPoints() <= 0}
                                        >
                                            +
                                        </button>
                                    </div>
                                </div>

                                <div class="flex justify-between items-center">
                                    <TerminalText>Finesse:</TerminalText>
                                    <div class="flex items-center gap-4">
                                        <button 
                                            onClick={() => {
                                                if (finesse() > 1) {
                                                    setFinesse(finesse() - 1);
                                                    setRemainingPoints(remainingPoints() + 1);
                                                }
                                            }}
                                            class={`w-8 h-8 border text-center cursor-pointer hover:bg-gray-700 ${theme().border} ${theme().textBase} ${finesse() > 1 ? '' : 'opacity-50 cursor-not-allowed'}`}
                                            disabled={finesse() <= 1}
                                        >
                                            -
                                        </button>
                                        <TerminalText class="w-8 text-center">{finesse()}</TerminalText>
                                        <button 
                                            onClick={() => {
                                                if (remainingPoints() > 0) {
                                                    setFinesse(finesse() + 1);
                                                    setRemainingPoints(remainingPoints() - 1);
                                                }
                                            }}
                                            class={`w-8 h-8 border text-center cursor-pointer hover:bg-gray-700 ${theme().border} ${theme().textBase} ${remainingPoints() > 0 ? '' : 'opacity-50 cursor-not-allowed'}`}
                                            disabled={remainingPoints() <= 0}
                                        >
                                            +
                                        </button>
                                    </div>
                                </div>

                                <div class="flex justify-between items-center">
                                    <TerminalText>Wits:</TerminalText>
                                    <div class="flex items-center gap-4">
                                        <button 
                                            onClick={() => {
                                                if (wits() > 1) {
                                                    setWits(wits() - 1);
                                                    setRemainingPoints(remainingPoints() + 1);
                                                }
                                            }}
                                            class={`w-8 h-8 border text-center cursor-pointer hover:bg-gray-700 ${theme().border} ${theme().textBase} ${wits() > 1 ? '' : 'opacity-50 cursor-not-allowed'}`}
                                            disabled={wits() <= 1}
                                        >
                                            -
                                        </button>
                                        <TerminalText class="w-8 text-center">{wits()}</TerminalText>
                                        <button 
                                            onClick={() => {
                                                if (remainingPoints() > 0) {
                                                    setWits(wits() + 1);
                                                    setRemainingPoints(remainingPoints() - 1);
                                                }
                                            }}
                                            class={`w-8 h-8 border text-center cursor-pointer hover:bg-gray-700 ${theme().border} ${theme().textBase} ${remainingPoints() > 0 ? '' : 'opacity-50 cursor-not-allowed'}`}
                                            disabled={remainingPoints() <= 0}
                                        >
                                            +
                                        </button>
                                    </div>
                                </div>

                                <div class="flex justify-between items-center">
                                    <TerminalText>Grit:</TerminalText>
                                    <div class="flex items-center gap-4">
                                        <button 
                                            onClick={() => {
                                                if (grit() > 1) {
                                                    setGrit(grit() - 1);
                                                    setRemainingPoints(remainingPoints() + 1);
                                                }
                                            }}
                                            class={`w-8 h-8 border text-center cursor-pointer hover:bg-gray-700 ${theme().border} ${theme().textBase} ${grit() > 1 ? '' : 'opacity-50 cursor-not-allowed'}`}
                                            disabled={grit() <= 1}
                                        >
                                            -
                                        </button>
                                        <TerminalText class="w-8 text-center">{grit()}</TerminalText>
                                        <button 
                                            onClick={() => {
                                                if (remainingPoints() > 0) {
                                                    setGrit(grit() + 1);
                                                    setRemainingPoints(remainingPoints() - 1);
                                                }
                                            }}
                                            class={`w-8 h-8 border text-center cursor-pointer hover:bg-gray-700 ${theme().border} ${theme().textBase} ${remainingPoints() > 0 ? '' : 'opacity-50 cursor-not-allowed'}`}
                                            disabled={remainingPoints() <= 0}
                                        >
                                            +
                                        </button>
                                    </div>
                                </div>

                                <div class="flex justify-between items-center">
                                    <TerminalText>Presence:</TerminalText>
                                    <div class="flex items-center gap-4">
                                        <button 
                                            onClick={() => {
                                                if (presence() > 1) {
                                                    setPresence(presence() - 1);
                                                    setRemainingPoints(remainingPoints() + 1);
                                                }
                                            }}
                                            class={`w-8 h-8 border text-center cursor-pointer hover:bg-gray-700 ${theme().border} ${theme().textBase} ${presence() > 1 ? '' : 'opacity-50 cursor-not-allowed'}`}
                                            disabled={presence() <= 1}
                                        >
                                            -
                                        </button>
                                        <TerminalText class="w-8 text-center">{presence()}</TerminalText>
                                        <button 
                                            onClick={() => {
                                                if (remainingPoints() > 0) {
                                                    setPresence(presence() + 1);
                                                    setRemainingPoints(remainingPoints() - 1);
                                                }
                                            }}
                                            class={`w-8 h-8 border text-center cursor-pointer hover:bg-gray-700 ${theme().border} ${theme().textBase} ${remainingPoints() > 0 ? '' : 'opacity-50 cursor-not-allowed'}`}
                                            disabled={remainingPoints() <= 0}
                                        >
                                            +
                                        </button>
                                    </div>
                                </div>
                            </div>

                            <button 
                                onClick={handleCreateCharacter}
                                class="w-full p-2 border bg-green-600 text-white hover:bg-green-700"
                            >
                                Create Character
                            </button>
                        </div>

                        {/* Right column: Stat information */}
                        <div class="space-y-4 w-full md:w-1/2 max-h-[70vh] overflow-y-auto pr-2">
                            <TerminalText class="text-xl">Attribute Information</TerminalText>

                            <TerminalText class="text-lg mt-4">Core Attributes</TerminalText>
                            <TerminalText><strong>Might</strong>: Represents raw physical power. Increases melee damage, carrying capacity, and physical feats.</TerminalText>
                            <TerminalText><strong>Finesse</strong>: Precision, speed, and coordination. Increases hit chance, dodge, and stealth skills.</TerminalText>
                            <TerminalText><strong>Wits</strong>: Quick thinking and awareness. Increases critical chance, tactical skills, and ability to notice details.</TerminalText>
                            <TerminalText><strong>Grit</strong>: Resilience and toughness. Increases maximum Health and resistance to negative effects.</TerminalText>
                            <TerminalText><strong>Presence</strong>: Social influence and leadership. Affects reputation changes, NPC reactions, and social abilities.</TerminalText>
                        </div>
                    </div>
                </Show>
            </div>
        </div>
    );
};

export default CharacterCreatePage;
