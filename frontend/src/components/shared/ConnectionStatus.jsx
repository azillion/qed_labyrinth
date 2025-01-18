import { createSignal, createEffect } from 'solid-js';
import { connectionStatus } from '../../lib/socket';
import { isReconnecting, retryCount } from '../../lib/socket/connection';
import { theme } from '../../stores/themeStore';

export const ConnectionStatus = () => {
	const statusMessages = {
		connected: 'Connected',
		disconnected: 'Disconnected',
		connecting: 'Connecting...',
		error: 'Connection Error',
		failed: 'Connection Failed',
	};

	const statusStyles = {
		connected: 'bg-green-500',
		disconnected: 'bg-red-500',
		connecting: 'bg-yellow-500',
		error: 'bg-red-500',
		failed: 'bg-red-500',
	};

	const [status, setStatus] = createSignal(connectionStatus());
	const [visible, setVisible] = createSignal(false);

	createEffect(() => {
		// monitor changes in connection status
		const newStatus = connectionStatus();
		if (newStatus !== status()) {
			setStatus(newStatus);
			setVisible(true);
			setTimeout(() => setVisible(false), 5000);
		}
	});

	return (
		<Show when={visible()}>
			<div
				class={`fixed bottom-4 right-4 p-2 rounded-lg bg-gray-900/95 border ${theme().border}`}
			>
				<div class="flex items-center space-x-2">
					<div class={`w-2 h-2 rounded-full ${statusStyles[status()]}`} />
					<span class={`text-sm ${theme().textBase}`}>
						{statusMessages[status()]}
						{isReconnecting() && ` (Attempt ${retryCount()})`}
					</span>
				</div>
			</div>
		</Show>
	);
};

