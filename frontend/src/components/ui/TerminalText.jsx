export const TerminalText = ({ children, class: className, setInnerHTML = false }) => (
  setInnerHTML ? (
    <div class={`font-mono text-gray-100 ${className || ""}`} innerHTML={children} />
  ) : (
    <div class={`font-mono text-gray-100 ${className || ""}`}>
      {children}
    </div>
  )
);
