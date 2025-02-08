import { theme } from "../../stores/themeStore";

export const Button = (props) => {
  const baseStyle = `
    font-mono px-4 py-2 rounded
    transition-colors duration-200
    focus:outline-none focus:ring-2
    disabled:opacity-50 disabled:cursor-not-allowed
  `;

  const variants = {
    primary: `
      bg-${theme().primary}-500 hover:bg-${theme().primary}-600
      text-gray-100
      hover:text-gray-100
      focus:ring-${theme().primary}-400
    `,
    secondary: `
      border border-${theme().primary}-500
      text-${theme().primary}-500
      hover:bg-${theme().primary}-500 hover:text-gray-100
      focus:ring-${theme().primary}-400
    `,
    ghost: `
      text-${theme().primary}-500
      hover:bg-${theme().primary}-500/10
      focus:ring-${theme().primary}-400
    `,
    active: `
      bg-${theme().primary}-700 hover:bg-${theme().primary}-800
      text-gray-100
      focus:ring-${theme().primary}-400
    `
  };

  return (
    <button
      onClick={props.onClick}
      disabled={props.disabled}
      type={props.type || "button"}
      class={`
        ${baseStyle}
        ${variants[props.variant || "primary"]}
        ${props.class || ""}
      `}
    >
      {props.children}
    </button>
  );
};
