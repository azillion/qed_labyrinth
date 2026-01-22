import { Component, createSignal } from 'solid-js';
import GameView from './components/GameView';
import Sidebar from './components/Sidebar';
import CommandInput from './components/CommandInput';
import Header from './components/Header';
import MobileNav from './components/MobileNav';

export type GameMessage = {
  id: number;
  type: 'system' | 'action' | 'speech' | 'combat' | 'error';
  content: string;
  timestamp: Date;
};

const App: Component = () => {
  const [messages, setMessages] = createSignal<GameMessage[]>([
    {
      id: 1,
      type: 'system',
      content: 'Welcome to The Dark Grimoire.',
      timestamp: new Date(),
    },
    {
      id: 2,
      type: 'system',
      content: 'You find yourself in the town square of Dundee. The cobblestones beneath your feet are worn smooth by countless travelers. A fountain burbles softly in the center, and torches flicker in iron sconces along the walls.',
      timestamp: new Date(),
    },
    {
      id: 3,
      type: 'system',
      content: 'Exits: North (Market), East (Inn), South (Gate), West (Temple)',
      timestamp: new Date(),
    },
  ]);

  const [sidebarOpen, setSidebarOpen] = createSignal(false);

  const [characterStats] = createSignal({
    name: 'Wanderer',
    level: 1,
    hp: { current: 100, max: 100 },
    mp: { current: 50, max: 50 },
    ap: { current: 10, max: 10 },
    gold: 25,
    location: 'Dundee - Town Square',
  });

  const handleCommand = (command: string) => {
    setMessages((prev) => [
      ...prev,
      {
        id: Date.now(),
        type: 'action',
        content: `> ${command}`,
        timestamp: new Date(),
      },
    ]);

    setTimeout(() => {
      const responses: Record<string, string> = {
        look: 'You look around the town square. Merchants hawk their wares, and adventurers pass by on their journeys.',
        north: 'You head north toward the market district.',
        help: 'Commands: look, north, south, east, west, say <message>, attack <target>',
      };

      const response = responses[command.toLowerCase()] || 
        `You try to "${command}" but nothing happens.`;

      setMessages((prev) => [
        ...prev,
        {
          id: Date.now(),
          type: 'system',
          content: response,
          timestamp: new Date(),
        },
      ]);
    }, 300);
  };

  const handleQuickAction = (action: string) => {
    handleCommand(action);
  };

  return (
    <div class="h-[100dvh] flex flex-col bg-stone-950 overflow-hidden">
      {/* Header - minimal on mobile */}
      <Header 
        onMenuClick={() => setSidebarOpen(true)} 
        stats={characterStats()}
      />
      
      {/* Main content */}
      <main class="flex-1 flex flex-col min-h-0">
        <GameView messages={messages()} />
        <CommandInput onSubmit={handleCommand} />
      </main>

      {/* Mobile bottom nav with quick actions */}
      <MobileNav onAction={handleQuickAction} stats={characterStats()} />

      {/* Sidebar overlay for mobile */}
      <Sidebar 
        stats={characterStats()} 
        isOpen={sidebarOpen()} 
        onClose={() => setSidebarOpen(false)} 
      />
    </div>
  );
};

export default App;
