const GamePage = () => {
    return (
        <div class="h-screen bg-black p-4">
            {/* Top Section - Status & Inventory */}
            <div class="h-1/4 flex gap-4 mb-4">
                <div class="w-1/2 bg-gray-900/95 border border-gray-700 backdrop-blur-sm rounded-lg p-4">
                    Status Frame
                </div>
                <div class="w-1/2 bg-gray-900/95 border border-gray-700 backdrop-blur-sm rounded-lg p-4">
                    Inventory Frame
                </div>
            </div>

            {/* Middle Section - Main Area & Chat */}
            <div class="h-2/3 flex gap-4 mb-4">
                <div class="w-2/3 bg-gray-900/95 border border-gray-700 backdrop-blur-sm rounded-lg p-4">
                    Main Area Frame
                </div>
                <div class="w-1/3 bg-gray-900/95 border border-gray-700 backdrop-blur-sm rounded-lg p-4">
                    Chat Frame
                </div>
            </div>

            {/* Bottom Section - Command Input */}
            <div class="h-12">
                <input
                    type="text"
                    class="w-full h-full bg-gray-900/95 border border-gray-700 backdrop-blur-sm rounded-lg px-4
                 text-gray-100 font-mono focus:outline-none focus:border-blue-500"
                    placeholder="Enter command..."
                />
            </div>
        </div>
    );
};

export default GamePage;