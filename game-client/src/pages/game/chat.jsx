import { For, Show, createEffect, onMount, onCleanup } from "solid-js";
import { TerminalText } from "@components/ui/TerminalText";
import { theme } from "@stores/themeStore";
import {
    messages,
    isLoading,
    error,
} from "@features/game/stores/chat";

const getMessageClass = (messageType) => {
    switch (messageType[0]) {
        case 'System':
            return theme().textDim;
        case 'Emote':
            return theme().textDimmer;
        case 'CommandSuccess':
            return theme().textSuccess;
        case 'CommandFailed':
            return theme().textError;
        default:
            return theme().textBase;
    }
};

/**
 * Format lines in a message
 * @param {string} message - The message to format
 * @returns {string} The formatted message
 */
const formatLinesInMessage = (message) => {
    if (message == null || message == undefined) return '';
    if (message.includes('\n')) {
        const lines = message.split('\n');
        return lines.map(line => `<p>${line}</p>`).join('');
    }
    return message;
};

// Message formatting helpers
export const formatMessage = (message) => {
    const formattedContent = formatLinesInMessage(message.content);
    
    switch (message.message_type) {
        case 'Chat':
            return `${message.sender_name}: ${formattedContent}`;
        case 'Emote':
            return `* ${message.sender_name} ${formattedContent}`;
        case 'System':
            return formattedContent;
        case 'CommandSuccess':
            return formattedContent;
        case 'CommandFailed':
            return formattedContent;
        default:
            return formattedContent;
    }
};


export const ChatFrame = () => {
    let chatContainerRef;

    // onMount(() => {
    //     const intervalId = setInterval(() => {
    //        chatActions.requestChatHistory();
    //     }, 15000);

    //     onCleanup(() => clearInterval(intervalId));
    // });

    // Auto-scroll to bottom when new messages arrive
    createEffect(() => {
        if (messages.length && chatContainerRef) {
            chatContainerRef.scrollTop = chatContainerRef.scrollHeight;
        }
    });

    return (
        <div 
            class={`h-full bg-gray-900/95 border ${theme().border} backdrop-blur-sm 
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
                                <TerminalText class={getMessageClass(message.message_type)} 
                                    setInnerHTML={true}
                                >
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