import { children } from "solid-js";

export const TerminalText = (props) => {
    const c = children(() => props.children);
    return props.setInnerHTML ? (
        <div class={`font-mono text-gray-100 ${props.class || ""}`} innerHTML={c()} />
    ) : (
        <div class={`font-mono text-gray-100 ${props.class || ""}`}>
            {c()}
        </div>
    );
};
