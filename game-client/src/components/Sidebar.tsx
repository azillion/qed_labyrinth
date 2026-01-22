import { Component, Show } from 'solid-js';

interface CharacterStats {
  name: string;
  level: number;
  hp: { current: number; max: number };
  mp: { current: number; max: number };
  ap: { current: number; max: number };
  gold: number;
  location: string;
}

interface SidebarProps {
  stats: CharacterStats;
  isOpen: boolean;
  onClose: () => void;
}

const Sidebar: Component<SidebarProps> = (props) => {
  return (
    <>
      {/* Backdrop */}
      <Show when={props.isOpen}>
        <div 
          class="fixed inset-0 bg-black/60 z-40"
          onClick={props.onClose}
        />
      </Show>

      {/* Sidebar panel */}
      <aside 
        class={`fixed top-0 left-0 h-full w-72 max-w-[85vw] bg-stone-950 border-r border-amber-900/30 z-50 transform transition-transform duration-300 ease-out ${
          props.isOpen ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Header */}
        <div class="flex items-center justify-between p-4 border-b border-amber-900/20">
          <h2 class="font-serif text-amber-200/90 tracking-wider uppercase text-sm">
            Character
          </h2>
          <button 
            onClick={props.onClose}
            class="p-1 text-stone-400 hover:text-amber-200 transition"
            aria-label="Close menu"
          >
            <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Character Info */}
        <div class="p-4 border-b border-amber-900/20">
          <h3 class="font-serif text-amber-200/90 tracking-wider uppercase mb-1">
            {props.stats.name}
          </h3>
          <p class="text-stone-500 text-sm">Level {props.stats.level}</p>
        </div>

        {/* Stats */}
        <div class="p-4 space-y-4 border-b border-amber-900/20">
          <StatBar 
            label="HP" 
            current={props.stats.hp.current} 
            max={props.stats.hp.max} 
            color="bg-red-900/80"
          />
          <StatBar 
            label="MP" 
            current={props.stats.mp.current} 
            max={props.stats.mp.max} 
            color="bg-blue-900/80"
          />
          <StatBar 
            label="AP" 
            current={props.stats.ap.current} 
            max={props.stats.ap.max} 
            color="bg-amber-900/80"
          />
        </div>

        {/* Location */}
        <div class="p-4 border-b border-amber-900/20">
          <p class="text-stone-500 text-xs uppercase tracking-wider mb-1">Location</p>
          <p class="text-stone-300 text-sm">{props.stats.location}</p>
        </div>

        {/* Gold */}
        <div class="p-4 border-b border-amber-900/20">
          <p class="text-stone-500 text-xs uppercase tracking-wider mb-1">Gold</p>
          <p class="text-amber-200 font-medium text-lg">{props.stats.gold}</p>
        </div>

        {/* Menu links */}
        <nav class="p-4">
          <p class="text-stone-500 text-xs uppercase tracking-wider mb-3">Menu</p>
          <div class="space-y-1">
            <MenuButton>Inventory</MenuButton>
            <MenuButton>Skills</MenuButton>
            <MenuButton>Quests</MenuButton>
            <MenuButton>Map</MenuButton>
            <MenuButton>Settings</MenuButton>
          </div>
        </nav>
      </aside>
    </>
  );
};

const StatBar: Component<{ label: string; current: number; max: number; color: string }> = (props) => {
  const percent = () => (props.current / props.max) * 100;
  
  return (
    <div>
      <div class="flex justify-between text-xs mb-1">
        <span class="text-stone-500">{props.label}</span>
        <span class="text-stone-400">{props.current}/{props.max}</span>
      </div>
      <div class="h-3 bg-stone-800 rounded-sm overflow-hidden">
        <div 
          class={`h-full ${props.color} transition-all duration-300`}
          style={{ width: `${percent()}%` }}
        />
      </div>
    </div>
  );
};

const MenuButton: Component<{ children: any }> = (props) => {
  return (
    <button class="w-full text-left px-3 py-2 text-sm text-stone-400 hover:text-amber-200 hover:bg-stone-900/50 transition rounded">
      {props.children}
    </button>
  );
};

export default Sidebar;
