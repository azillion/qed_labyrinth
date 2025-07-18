import { For, Show, onMount } from "solid-js";
import { NavBar } from "@components/shared/NavBar";
import { TerminalText } from "@components/ui/TerminalText";
import { inventory, equipment, isLoading, error, inventoryActions } from "@features/game/stores/inventory";
import { theme } from "@stores/themeStore";

const EquipmentSlot = (props) => (
  <div class="flex justify-between items-center">
    <TerminalText class="capitalize w-24">{props.slot}:</TerminalText>
    <TerminalText class={`flex-grow p-2 border-b ${theme().border}`}>
      <Show when={props.item} fallback={<span class={theme().textDim}>- Empty -</span>}>
        {props.item?.name}
        <span
          class="ml-3 cursor-pointer text-yellow-400 hover:text-yellow-200"
          onClick={() => {
            const slotName = props.slot; // e.g., "mainHand"
            const slotEnum = slotName.replace(/([a-z0-9])([A-Z])/g, '$1_$2').toUpperCase(); // "MAIN_HAND"
            inventoryActions.unequip(slotEnum);
          }}
        >
          [unequip]
        </span>
      </Show>
    </TerminalText>
  </div>
);

export const InventoryPage = () => {
  onMount(async () => {
    await inventoryActions.request();
  });

  return (
    <div class={`min-h-screen bg-black text-gray-100 font-mono`}>
      <NavBar />
      <div class="p-6 grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* Equipment Column */}
        <div>
          <TerminalText class="text-2xl mb-6">Equipped</TerminalText>
          <div class="space-y-4">
            <EquipmentSlot slot="mainHand" item={equipment.mainHand} />
            <EquipmentSlot slot="offHand" item={equipment.offHand} />
            <EquipmentSlot slot="head" item={equipment.head} />
            <EquipmentSlot slot="chest" item={equipment.chest} />
            <EquipmentSlot slot="legs" item={equipment.legs} />
            <EquipmentSlot slot="feet" item={equipment.feet} />
          </div>
        </div>

        {/* Inventory Column */}
        <div>
          <TerminalText class="text-2xl mb-6">Inventory</TerminalText>

          <Show when={isLoading()}>
            <TerminalText class={theme().textDim}>Loading...</TerminalText>
          </Show>

          <Show when={error()}>
            <TerminalText class="text-red-500">{error()}</TerminalText>
          </Show>

          <Show when={!isLoading() && inventory.length === 0}>
            <TerminalText class={theme().textDim}>Your inventory is empty.</TerminalText>
          </Show>

          <div class="space-y-4">
            <For each={inventory}>
              {(item) => (
                <div class={`p-4 border rounded ${theme().border}`}>
                  <TerminalText class="text-lg text-white">
                    {item.name} (x{item.quantity})
                    <span
                      class="ml-3 cursor-pointer text-green-400 hover:text-green-200"
                      onClick={() => inventoryActions.equip(item.id)}
                    >
                      [equip]
                    </span>
                    <span
                      class="ml-3 cursor-pointer text-red-400 hover:text-red-200"
                      onClick={() => inventoryActions.drop(item.id)}
                    >
                      [drop]
                    </span>
                  </TerminalText>
                  <TerminalText class={`mt-2 ${theme().textDim}`}>{item.description}</TerminalText>
                </div>
              )}
            </For>
          </div>
        </div>
      </div>
    </div>
  );
};