import { Component } from 'solid-js';

interface MobileNavProps {
  onAction: (action: string) => void;
  stats: {
    ap: { current: number; max: number };
    mp: { current: number; max: number };
  };
}

const MobileNav: Component<MobileNavProps> = (props) => {
  return (
    <nav class="border-t border-amber-900/30 bg-stone-900/80 px-2 py-2 safe-bottom">
      {/* Compact stat indicators */}
      <div class="flex items-center justify-center gap-4 mb-2 text-xs">
        <div class="flex items-center gap-1">
          <span class="text-blue-400">MP</span>
          <span class="text-stone-500">{props.stats.mp.current}/{props.stats.mp.max}</span>
        </div>
        <div class="flex items-center gap-1">
          <span class="text-amber-400">AP</span>
          <span class="text-stone-500">{props.stats.ap.current}/{props.stats.ap.max}</span>
        </div>
      </div>

      {/* Quick action buttons */}
      <div class="grid grid-cols-4 gap-2">
        <NavButton onClick={() => props.onAction('look')}>Look</NavButton>
        <NavButton onClick={() => props.onAction('north')}>North</NavButton>
        <NavButton onClick={() => props.onAction('rest')}>Rest</NavButton>
        <NavButton onClick={() => props.onAction('help')}>Help</NavButton>
      </div>

      {/* Direction pad - second row */}
      <div class="grid grid-cols-4 gap-2 mt-2">
        <NavButton onClick={() => props.onAction('west')}>West</NavButton>
        <NavButton onClick={() => props.onAction('south')}>South</NavButton>
        <NavButton onClick={() => props.onAction('east')}>East</NavButton>
        <NavButton onClick={() => props.onAction('inventory')}>Inv</NavButton>
      </div>
    </nav>
  );
};

const NavButton: Component<{ children: any; onClick: () => void }> = (props) => {
  return (
    <button 
      onClick={props.onClick}
      class="px-2 py-3 text-xs uppercase tracking-wider text-stone-400 border border-stone-700 active:border-amber-900/50 active:text-amber-200 active:bg-amber-900/10 transition rounded"
    >
      {props.children}
    </button>
  );
};

export default MobileNav;
