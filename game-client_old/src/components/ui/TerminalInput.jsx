import { theme } from "../../stores/themeStore";

export const TerminalInput = (props) => (
  <input
    ref={props.ref}
    type={props.type || "text"}
    value={props.value}
    onInput={(e) => props.onInput(e.currentTarget.value)}
    class={`bg-transparent border-none outline-none font-mono 
            w-full focus:ring-0 caret-${theme().primary}-500
            ${theme().textBase} placeholder:${theme().textDimmer}`}
    placeholder={props.placeholder}
    autofocus={props.autofocus}
  />
);
