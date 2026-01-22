import { Component } from 'solid-js';

interface HeaderProps {
  onMenuClick: () => void;
  stats: {
    name: string;
    hp: { current: number; max: number };
    location: string;
  };
}

const Header: Component<HeaderProps> = (props) => {
  const hpPercent = () => (props.stats.hp.current / props.stats.hp.max) * 100;

  return (
    <header class="border-b border-amber-900/30 bg-stone-950 px-3 py-2 safe-top">
      <div class="flex items-center justify-between gap-3">
        {/* Menu button */}
        <button 
          onClick={props.onMenuClick}
          class="p-2 -ml-2 text-stone-400 hover:text-amber-200 transition"
          aria-label="Open menu"
        >
          <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>

        {/* Title - hidden on very small screens */}
        <h1 class="hidden xs:block font-serif text-sm tracking-[0.1em] text-amber-200/80 uppercase">
          Dark Grimoire
        </h1>

        {/* Compact stats bar */}
        <div class="flex-1 flex items-center justify-end gap-3">
          {/* HP bar - compact */}
          <div class="flex items-center gap-2">
            <span class="text-xs text-stone-500">HP</span>
            <div class="w-16 sm:w-24 h-2 bg-stone-800 rounded-sm overflow-hidden">
              <div 
                class="h-full bg-red-900/80 transition-all duration-300"
                style={{ width: `${hpPercent()}%` }}
              />
            </div>
            <span class="text-xs text-stone-400 min-w-[3rem] text-right">
              {props.stats.hp.current}/{props.stats.hp.max}
            </span>
          </div>
        </div>
      </div>
    </header>
  );
};

export default Header;
