import { Component, createSignal } from 'solid-js';

interface CommandInputProps {
  onSubmit: (command: string) => void;
}

const CommandInput: Component<CommandInputProps> = (props) => {
  const [input, setInput] = createSignal('');
  const [history, setHistory] = createSignal<string[]>([]);
  const [historyIndex, setHistoryIndex] = createSignal(-1);

  const handleSubmit = (e: Event) => {
    e.preventDefault();
    const command = input().trim();
    if (command) {
      props.onSubmit(command);
      setHistory((prev) => [...prev, command]);
      setHistoryIndex(-1);
      setInput('');
    }
  };

  const handleKeyDown = (e: KeyboardEvent) => {
    if (e.key === 'ArrowUp') {
      e.preventDefault();
      const hist = history();
      if (hist.length > 0) {
        const newIndex = historyIndex() === -1 
          ? hist.length - 1 
          : Math.max(0, historyIndex() - 1);
        setHistoryIndex(newIndex);
        setInput(hist[newIndex]);
      }
    } else if (e.key === 'ArrowDown') {
      e.preventDefault();
      const hist = history();
      if (historyIndex() !== -1) {
        const newIndex = historyIndex() + 1;
        if (newIndex >= hist.length) {
          setHistoryIndex(-1);
          setInput('');
        } else {
          setHistoryIndex(newIndex);
          setInput(hist[newIndex]);
        }
      }
    }
  };

  return (
    <form onSubmit={handleSubmit} class="border-t border-amber-900/30 bg-stone-900/50 p-3">
      <div class="flex items-center gap-2">
        <span class="text-amber-900/60 text-lg">&gt;</span>
        <input
          type="text"
          value={input()}
          onInput={(e) => setInput(e.currentTarget.value)}
          onKeyDown={handleKeyDown}
          placeholder="Enter command..."
          class="flex-1 bg-transparent text-stone-200 placeholder:text-stone-600 outline-none text-base min-w-0"
          autocomplete="off"
          autocapitalize="none"
        />
        <button
          type="submit"
          class="px-3 py-2 text-xs uppercase tracking-wider text-amber-200/70 border border-amber-900/40 hover:border-amber-800/60 active:bg-amber-900/20 transition shrink-0"
        >
          Send
        </button>
      </div>
    </form>
  );
};

export default CommandInput;
