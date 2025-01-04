import { TerminalText } from "../atoms/TerminalText";

export const TerminalOption = (props) => (
  <TerminalText class={`${props.selected ? "text-blue-400" : ""}`}>
    {`[${props.number}] ${props.text} ${props.selected ? "<" : ""}`}
  </TerminalText>
);
