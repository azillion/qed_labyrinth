import { Component, For, createEffect } from 'solid-js';
import type { GameMessage } from '../App';

interface GameViewProps {
  messages: GameMessage[];
}

const GameView: Component<GameViewProps> = (props) => {
  let scrollContainer: HTMLDivElement | undefined;

  createEffect(() => {
    const _ = props.messages.length;
    if (scrollContainer) {
      scrollContainer.scrollTop = scrollContainer.scrollHeight;
    }
  });

  const getMessageClass = (type: GameMessage['type']) => {
    const baseClass = 'leading-relaxed text-sm sm:text-base';
    switch (type) {
      case 'system':
        return `${baseClass} text-stone-400`;
      case 'action':
        return `${baseClass} text-amber-200/80 font-medium`;
      case 'speech':
        return `${baseClass} text-emerald-400`;
      case 'combat':
        return `${baseClass} text-red-400`;
      case 'error':
        return `${baseClass} text-red-500`;
      default:
        return baseClass;
    }
  };

  return (
    <div 
      ref={scrollContainer}
      class="flex-1 overflow-y-auto px-4 py-3 space-y-3 min-h-0"
    >
      <For each={props.messages}>
        {(message) => (
          <p class={getMessageClass(message.type)}>
            {message.content}
          </p>
        )}
      </For>
    </div>
  );
};

export default GameView;
