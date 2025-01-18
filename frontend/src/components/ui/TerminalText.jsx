export const TerminalText = (props) => (
  <div class={`font-mono text-gray-100 ${props.class || ""}`}>
    {props.children}
  </div>
);
