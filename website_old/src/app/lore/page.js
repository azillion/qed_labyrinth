import { Hero } from "@/components/hero"
import { Footer } from "@/components/footer"

export default function LorePage() {
  return (
    <div className="min-h-screen bg-background text-foreground flex flex-col">
      <Hero>
        <div className="max-w-3xl mx-auto">
          <h1 className="text-6xl font-bold text-stone-100 font-serif tracking-wide drop-shadow-lg mb-12">
            Entryway
          </h1>
          
          <div className="prose prose-invert prose-lg mx-auto max-h-[60vh] overflow-y-auto">
            <div className="whitespace-pre-line font-serif leading-relaxed text-stone-200/90 drop-shadow">
              {"You stand where the map grows thin—\n" +
              "here, where the village exhales its charms\n" +
              "into the damp throat of twilight.\n" +
              "Rowan limbs sag above doorways,\n" +
              "their berries like clots of old blood\n" +
              "warding what whispers through the cracks\n" +
              "in the world's wet ledger. Listen:\n" +
              "the soil hums a counter-song\n" +
              "to the stars' cold mathematics.\n" +
              "Even the church bells wear their tolling\n" +
              "like a bridle, holding back the hour\n" +
              "when the sky forgets its name.\n\n" +

              "This is no land of bright heralds.\n" +
              "The market's true currency is fear—\n" +
              "vervain twined with grave dirt,\n" +
              "psalms scratched on river stones,\n" +
              "the way a shepherd's song frays\n" +
              "at the edge where the moor begins\n" +
              "its slow argument with reason.\n" +
              "You'll learn the price of paths:\n" +
              "some lanes lead to hearth-smoke,\n" +
              "others to clearings where pines\n" +
              "whisper in angles that itch\n" +
              "behind your eyes. Merchants return\n" +
              "with frost in their beards and pockets\n" +
              "full of silence. Watch their hands—\n" +
              "see how they tremble counting coins.\n\n" +

              "The nobles claim their castle stones\n" +
              "remember an older order, but climb\n" +
              "the tower stairs at midnight\n" +
              "and you'll hear the mortar hum\n" +
              "a hymn no priest would bless.\n" +
              "The woods? Keep your blade bright\n" +
              "and your prayers brighter. Trees here\n" +
              "grow two shadows: one for the sun,\n" +
              "one for what gutters beneath the bark\n" +
              "like a lamp you shouldn't name.\n" +
              "Shepherds will tell you—those who still\n" +
              "have tongues to tell—how mists move\n" +
              "against the wind here, how flocks\n" +
              "return with too many teeth, too few eyes,\n" +
              "and wool that smells of storm-cellars\n" +
              "where something learned to breathe.\n\n" +

              "Child of salt and candleflame,\n" +
              "this is how you'll survive:\n" +
              "mend the fraying rituals,\n" +
              "barter dread at the crossroads,\n" +
              "kneel when the bells convulse\n" +
              "their bronze throats at dusk.\n" +
              "But mark this well—the earth\n" +
              "dreams in a language of fractures.\n" +
              "Plowmen find glyphs in the frost.\n" +
              "Midwives burn the afterbirth\n" +
              "lest it crawl back, keening.\n" +
              "Every ward weakens. Every prayer\n" +
              "is a door held shut with both hands.\n\n" +

              "Now step forward.\n" +
              "The soil knows your weight already.\n" +
              "The shadows have rehearsed your name.\n" +
              "What will you add to the ledger—\n" +
              "another scar on the oak's thick skin?\n" +
              "A new verse to the wind's dark psalm?\n" +
              "Or will you be the one who stares too long\n" +
              "at the patterns the river etches in clay,\n" +
              "who follows the will-o'-wisp's sly arithmetic\n" +
              "into the glade where the air goes…\n" +
              "quiet…\n" +
              "soft…\n" +
              "alive…\n\n" +

              "(Choose slowly.\n" +
              "The trees are listening.)"
              }
            </div>
          </div>
        </div>
      </Hero>
      <Footer />
    </div>
  );
}
