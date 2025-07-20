import pandas as pd
import matplotlib.pyplot as plt
import argparse


def analyze(input_file):
    print(f"--- Analyzing Simulation Results from {input_file} ---")
    df = pd.read_csv(input_file)

    # --- Plot 1: Average Level vs. Time ---
    avg_level_over_time = df.groupby('hour')['level'].mean()

    plt.figure(figsize=(12, 7))
    avg_level_over_time.plot(linewidth=2)
    plt.title("Average Player Level vs. Hours Played", fontsize=16)
    plt.xlabel("Hours Played", fontsize=12)
    plt.ylabel("Average Level", fontsize=12)
    plt.grid(True, which='both', linestyle='--', linewidth=0.5)
    plt.tight_layout()

    output_filename = "level_vs_time.png"
    plt.savefig(output_filename)
    print(f"Saved plot: {output_filename}")
    plt.close()

    # --- Plot 2: Average Power Score vs. Time ---
    avg_power_over_time = df.groupby('hour')['player_power_score'].mean()

    plt.figure(figsize=(12, 7))
    avg_power_over_time.plot(linewidth=2, color='orange')
    plt.title("Average Player Power Score vs. Hours Played", fontsize=16)
    plt.xlabel("Hours Played", fontsize=12)
    plt.ylabel("Average Power Score", fontsize=12)
    plt.grid(True, which='both', linestyle='--', linewidth=0.5)
    plt.tight_layout()

    output_filename = "power_vs_time.png"
    plt.savefig(output_filename)
    print(f"Saved plot: {output_filename}")
    plt.close()

    # --- Plot 3: Power Score Composition ---
    # Calculate power from cards by subtracting gear score from total power
    df['power_from_cards'] = df['player_power_score'] - df['total_gear_score']

    # Group and get the mean of each component
    power_composition = df.groupby('hour')[['power_from_cards', 'total_gear_score']].mean()

    plt.figure(figsize=(12, 7))
    plt.stackplot(
        power_composition.index,
        power_composition['power_from_cards'],
        power_composition['total_gear_score'],
        labels=['Power from Lore Cards', 'Power from Gear'],
        colors=['#3498db', '#e74c3c']
    )
    plt.title("Composition of Player Power Score Over Time", fontsize=16)
    plt.xlabel("Hours Played", fontsize=12)
    plt.ylabel("Total Power Score", fontsize=12)
    plt.legend(loc='upper left')
    plt.grid(True, which='both', linestyle='--', linewidth=0.5)
    plt.tight_layout()

    output_filename = "power_composition.png"
    plt.savefig(output_filename)
    print(f"Saved plot: {output_filename}")
    plt.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Analyze progression simulation results.")
    parser.add_argument("--input", type=str, default="simulation_results.csv", help="Input CSV file to analyze.")
    args = parser.parse_args()
    analyze(args.input) 