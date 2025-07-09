import { TerminalText } from "@components/ui/TerminalText";
import { character } from "@features/auth/stores/character";
import { NavBar } from "@components/shared/NavBar";

export const CharacterSheetPage = () => {
    return (
        <div class={`min-h-screen bg-gray-900 text-green-400 font-mono`}>
            <NavBar />
            <div class="p-6">
                <TerminalText class="text-2xl mb-6">Character Sheet</TerminalText>
            
            <div class="mb-8">
                <TerminalText class="text-xl mb-4">Core Attributes</TerminalText>
                <div class="ml-4 space-y-2">
                    <TerminalText>Might: {character.coreAttributes.might}</TerminalText>
                    <TerminalText>Finesse: {character.coreAttributes.finesse}</TerminalText>
                    <TerminalText>Wits: {character.coreAttributes.wits}</TerminalText>
                    <TerminalText>Grit: {character.coreAttributes.grit}</TerminalText>
                    <TerminalText>Presence: {character.coreAttributes.presence}</TerminalText>
                </div>
            </div>

            <div class="mb-8">
                <TerminalText class="text-xl mb-4">Combat Stats</TerminalText>
                <div class="ml-4 space-y-2">
                    <TerminalText>Physical Power: {character.derivedStats.physicalPower}</TerminalText>
                    <TerminalText>Spell Power: {character.derivedStats.spellPower}</TerminalText>
                    <TerminalText>Accuracy: {character.derivedStats.accuracy}</TerminalText>
                    <TerminalText>Evasion: {character.derivedStats.evasion}</TerminalText>
                    <TerminalText>Armor: {character.derivedStats.armor}</TerminalText>
                    <TerminalText>Resolve: {character.derivedStats.resolve}</TerminalText>
                </div>
            </div>
            </div>
        </div>
    );
};