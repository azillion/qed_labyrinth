import { TerminalText } from "@components/ui/TerminalText";
import { character } from "@features/auth/stores/character";

export const CharacterSheetPage = () => {
    return (
        <div class={`min-h-screen bg-gray-900 text-green-400 font-mono p-6`}>
            <TerminalText class="text-2xl mb-6">Character Sheet</TerminalText>
            
            <div class="mb-8">
                <TerminalText class="text-xl mb-4">Core Attributes</TerminalText>
                <div class="ml-4 space-y-2">
                    <TerminalText>Might: {character.core_attributes.might}</TerminalText>
                    <TerminalText>Finesse: {character.core_attributes.finesse}</TerminalText>
                    <TerminalText>Wits: {character.core_attributes.wits}</TerminalText>
                    <TerminalText>Grit: {character.core_attributes.grit}</TerminalText>
                    <TerminalText>Presence: {character.core_attributes.presence}</TerminalText>
                </div>
            </div>

            <div class="mb-8">
                <TerminalText class="text-xl mb-4">Combat Stats</TerminalText>
                <div class="ml-4 space-y-2">
                    <TerminalText>Physical Power: {character.derived_stats.physical_power}</TerminalText>
                    <TerminalText>Spell Power: {character.derived_stats.spell_power}</TerminalText>
                    <TerminalText>Accuracy: {character.derived_stats.accuracy}</TerminalText>
                    <TerminalText>Evasion: {character.derived_stats.evasion}</TerminalText>
                    <TerminalText>Armor: {character.derived_stats.armor}</TerminalText>
                    <TerminalText>Resolve: {character.derived_stats.resolve}</TerminalText>
                </div>
            </div>
        </div>
    );
};