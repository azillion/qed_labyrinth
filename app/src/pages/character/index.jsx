import { createSignal, Show } from "solid-js";
import { TerminalText } from "@components/ui/TerminalText";
import { TerminalOption } from "@components/shared/TerminalOption";
import { theme } from "@stores/themeStore";
import CharacterSelectPage from "./select";
import CharacterCreatePage from "./creation";

const CharacterPage = () => {
    const [step, setStep] = createSignal('select');
    const [error, setError] = createSignal('');

    const handleKeyDown = (e) => {
        if (e.key === "Escape") {
            setStep("select");
        }

        if (step() === "select") {
            if (e.key === "1") {
                setStep("character-select");
            } else if (e.key === "2") {
                setStep("character-create");
            }
        }
    };

    return (
        <div
            class="fixed inset-0 flex items-center justify-center bg-black focus:outline-none"
            onKeyDown={handleKeyDown}
            tabIndex={0}
        >
            <div class={`bg-black p-8 w-full max-w-2xl font-mono ${theme().textBase} ${theme().border} ${theme().shadow}`}>
                <div class="mb-8">
                    <TerminalText class="text-2xl">Character Selection</TerminalText>
                    <div class={`h-px ${theme().textDimmest} mt-4`} />
                </div>

                <Show when={step() === "select"}>
                    <div class="space-y-4">
                        <TerminalText>Available commands:</TerminalText>
                        <TerminalOption
                            number="1"
                            text="SELECT existing character"
                        />
                        <TerminalOption
                            number="2"
                            text="CREATE new character"
                        />
                    </div>
                </Show>

                <Show when={step() === "character-select"}>
                    <CharacterSelectPage />
                </Show>

                <Show when={step() === "character-create"}>
                    <CharacterCreatePage />
                </Show>

                <Show when={error()}>
                    <div class="bg-red-500 text-white p-2 rounded-lg mt-4">
                        <TerminalText>{error()}</TerminalText>
                    </div>
                </Show>

                <Show when={step() === "select"}>
                    <div class={`mt-8 pt-4 border-t ${theme().textDimmest}`}>
                        <TerminalText class={theme().textDimmer}>
                            Type 1 or 2 to select an option...
                        </TerminalText>
                    </div>
                </Show>
            </div>
        </div>
    );
};

export default CharacterPage;
