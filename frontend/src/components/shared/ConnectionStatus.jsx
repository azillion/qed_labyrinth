import { createSignal, createEffect, Show } from 'solid-js';
import { socketManager } from '@lib/socket';
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

	const [visible, setVisible] = createSignal(false);
	const [status] = socketManager.connectionStatus;

	createEffect(() => {
		const currentStatus = status();
		if (currentStatus && currentStatus !== 'connected') {
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
						{socketManager.isReconnecting && ` (Attempt ${socketManager.retryCount})`}
					</span>
				</div>
			</div>
		</Show>
	);
};

