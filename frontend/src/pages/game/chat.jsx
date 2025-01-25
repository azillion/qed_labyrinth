import { For, Show, createEffect, onMount, onCleanup } from "solid-js";
import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import {
    messages,
    isLoading,
    error,
    formatMessage,
} from "@features/game/stores/chat";
import { chatActions } from "@features/game/stores/chat";

const getMessageClass = (messageType) => {
    switch (messageType) {
        case 'System':
            return theme().textDim;
        case 'Emote':
            return theme().textDimmer;
        default:
            return theme().textBase;
    }
};

export const ChatFrame = () => {
    let chatContainerRef;

    onMount(() => {
        const intervalId = setInterval(() => {
           chatActions.requestChatHistory();
        }, 15000);

        onCleanup(() => clearInterval(intervalId));
    });

    // Auto-scroll to bottom when new messages arrive
    createEffect(() => {
        if (messages.length && chatContainerRef) {
            chatContainerRef.scrollTop = chatContainerRef.scrollHeight;
        }
    });

    return (
        <div 
            class={`w-1/3 bg-gray-900/95 border ${theme().border} backdrop-blur-sm 
                   rounded-lg p-4 flex flex-col`}
        >
            <TerminalText class="text-lg mb-2">Chat</TerminalText>
            
            <div 
                ref={chatContainerRef}
                class="flex-1 overflow-y-auto flex flex-col-reverse"
            >
                <div class="space-y-2">
                    <Show 
                        when={!isLoading()} 
                        fallback={<TerminalText>Loading messages...</TerminalText>}
                    >
                        <For each={messages}>
                            {(message) => (
                                <TerminalText class={getMessageClass(message.message_type)}>
                                    {formatMessage(message)}
                                </TerminalText>
                            )}
                        </For>
                    </Show>

                    <Show when={error()}>
                        <TerminalText class="text-red-500">
                            {error()}
                        </TerminalText>
                    </Show>

                    <Show when={!isLoading() && messages.length === 0}>
                        <TerminalText class={theme().textDim}>
                            No messages yet...
                        </TerminalText>
                    </Show>
                </div>
            </div>
        </div>
    );
};