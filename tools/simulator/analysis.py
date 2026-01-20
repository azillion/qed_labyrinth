import pandas as pd
import matplotlib.pyplot as plt
import argparse
from config import STAT_POWER_WEIGHTS, STAT_BONUS_KEYS


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
    plt.grid(True, linestyle='--', linewidth=0.5)
    plt.tight_layout()
    plt.savefig("level_vs_time.png")
    plt.close()

    # --- Plot 2: Average Power Score vs. Time ---
    avg_power_over_time = df.groupby('hour')['player_power_score'].mean()
    plt.figure(figsize=(12, 7))
    avg_power_over_time.plot(linewidth=2, color='orange')
    plt.title("Average Player Power Score vs. Hours Played", fontsize=16)
    plt.xlabel("Hours Played", fontsize=12)
    plt.ylabel("Average Power Score", fontsize=12)
    plt.grid(True, linestyle='--', linewidth=0.5)
    plt.tight_layout()
    plt.savefig("power_vs_time.png")
    plt.close()

    # --- Plot 3: Power Score Composition ---
    # Recalculate power from stats to ensure accuracy
    df['power_from_stats'] = 0
    for stat in STAT_BONUS_KEYS:
        weight = STAT_POWER_WEIGHTS.get(stat, 1.0)
        df['power_from_stats'] += df[stat] * weight

    power_composition = df.groupby('hour')[['power_from_stats', 'total_gear_score']].mean()
    plt.figure(figsize=(12, 7))
    plt.stackplot(
        power_composition.index,
        power_composition['power_from_stats'],
        power_composition['total_gear_score'],
        labels=['Power from Stats (Cards+Gear)', 'Power from Gear (GearScore)'],
        colors=['#3498db', '#e74c3c']
    )
    plt.title("Composition of Player Power Score Over Time", fontsize=16)
    plt.xlabel("Hours Played", fontsize=12)
    plt.ylabel("Power Score", fontsize=12)
    plt.legend(loc='upper left')
    plt.grid(True, linestyle='--', linewidth=0.5)
    plt.tight_layout()
    plt.savefig("power_composition.png")
    plt.close()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Analyze progression simulation results.")
    parser.add_argument("--input", type=str, default="simulation_results.csv", help="Input CSV file to analyze.")
    args = parser.parse_args()
    analyze(args.input)
