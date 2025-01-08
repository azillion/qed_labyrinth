import { createSignal, Show, onMount, onCleanup } from "solid-js";
import { TerminalText } from "../atoms/TerminalText";
import { TerminalInput } from "../atoms/TerminalInput";
import { TerminalOption } from "../molecules/TerminalOption";
import { GAME_NAME } from "../../lib/constants";
import { theme } from "../../stores/themeStore";
import { messageHandlers } from "../../lib/socket";
import { authError } from '../../lib/auth';

export const AuthFrame = () => {
	const [step, setStep] = createSignal("select");
	const [mode, setMode] = createSignal(null);
	const [username, setUsername] = createSignal("");
	const [password, setPassword] = createSignal("");
	const [email, setEmail] = createSignal("");
	const [error, setError] = createSignal("");

	const handleKeyDown = (e) => {
		if (e.key === "Escape") {
			setStep("select");
		}
		if (e.key === "Enter" && step() === "username" && username() === "") {
			setError("Username cannot be empty");
			return;
		} else if (e.key === "Enter" && step() === "password" && password() === "") {
			setError("Password cannot be empty");
			return;
		} else if (e.key === "Enter" && step() === "email" && email() === "") {
			setError("Email cannot be empty");
			return;
		}
		setError("");
		if (step() === "select") {
			if (e.key === "1") {
				setMode("login");
				setStep("username");
			} else if (e.key === "2") {
				setMode("register");
				setStep("username");
			}
		} else if (e.key === "Enter") {
			if (step() === "username") {
				setStep("password");
			} else if (step() === "password") {
				if (mode() === "register") {
					setStep("email");
				} else {
					handleSubmit();
				}
			} else if (step() === "email") {
				handleSubmit();
			}
		}
	};

	// Replace the handleSubmit function with:
	const handleSubmit = () => {
		if (mode() === 'login') {
			messageHandlers.auth.login(username(), password());
		} else {
			messageHandlers.auth.register(username(), password(), email());
		}
	};

	// Add subscription in onMount:
	onMount(() => {
		document.querySelector('[tabindex="0"]').focus();

		const unsub = messageHandlers.auth.subscribe((type, payload) => {
			if (type === 'AuthSuccess') {
				window.authToken = payload.token;
			} else if (type === 'Error') {
				setError(payload.message);
			}
		});

		onCleanup(() => unsub());
	});

	return (
		<div
			class="fixed inset-0 flex items-center justify-center bg-black focus:outline-none"
			onKeyDown={handleKeyDown}
			tabIndex={0}
		>
			<div
				class={`bg-black p-8 w-full max-w-2xl font-mono 
                   ${theme().textBase} ${theme().border} ${theme().shadow}`}
			>
				<div class="mb-8">
					<TerminalText class="text-2xl">Welcome to {GAME_NAME}</TerminalText>
					<TerminalText class={`mt-2 ${theme().textDim}`}>
						[Connection established at {new Date().toLocaleTimeString()}]
					</TerminalText>
					<div class={`h-px ${theme().textDimmest} mt-4`} />
				</div>

				<Show when={step() === "select"}>
					<div class="space-y-4">
						<TerminalText>Available commands:</TerminalText>
						<TerminalOption
							number="1"
							text="LOGIN to existing account"
							selected={mode() === "login"}
						/>
						<TerminalOption
							number="2"
							text="CREATE new adventurer"
							selected={mode() === "register"}
						/>
					</div>
				</Show>

				<Show when={error()}>
					<div class="bg-red-500 text-white p-2 rounded-lg mt-4">
						<TerminalText>{error()}</TerminalText>
					</div>
				</Show>

				<Show when={authError()}>
					<div class="bg-red-500 text-white p-2 rounded-lg mt-4">
						<TerminalText>{authError()}</TerminalText>
					</div>
				</Show>

				<Show when={step() === "username"}>
					<div class="space-y-4">
						<TerminalText class={theme().textBase}>
							{mode() === "login"
								? "=== Adventurer Login ==="
								: "=== New Adventurer Creation ==="}
						</TerminalText>
						<div class="flex items-center">
							<TerminalText class={theme().textBase}>&gt;</TerminalText>
							<div class="ml-2 flex-1">
								<TerminalInput
									value={username()}
									onInput={setUsername}
									placeholder="Enter username"
									autofocus={true}
								/>
							</div>
						</div>
					</div>
				</Show>

				<Show when={step() === "password"}>
					<div class="space-y-4">
						<div class="flex items-center">
							<TerminalText class={theme().textBase}>&gt;</TerminalText>
							<div class="ml-2 flex-1">
								<TerminalInput
									type="password"
									value={password()}
									onInput={setPassword}
									placeholder="Enter password"
									autofocus={true}
								/>
							</div>
						</div>
					</div>
				</Show>

				<Show when={step() === "email"}>
					<div class="space-y-4">
						<div class="flex items-center">
							<TerminalText class={theme().textBase}>&gt;</TerminalText>
							<div class="ml-2 flex-1">
								<TerminalInput value={email()} onInput={setEmail} placeholder="Enter email" autofocus={true} />
							</div>
						</div>
					</div>
				</Show>

				<div class={`mt-8 pt-4 border-t ${theme().textDimmest}`}>
					<TerminalText class={theme().textDimmer}>
						{step() === "select"
							? "Type 1 or 2 to select an option..."
							: step() === "username"
								? "Enter your username and press RETURN..."
								: step() === "password"
									? "Enter your password and press RETURN..."
									: "Enter your email and press RETURN..."}
					</TerminalText>
				</div>
			</div>
		</div>
	);
};
