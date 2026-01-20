import pandas as pd
import argparse
from simulation import run_single_simulation


def main():
    parser = argparse.ArgumentParser(description="Run the QED Labyrinth Progression Simulator.")
    parser.add_argument("--runs", type=int, default=100, help="Number of simulation runs to perform.")
    parser.add_argument("--hours", type=int, default=200, help="Total simulated hours for each run.")
    parser.add_argument(
        "--archetype",
        type=str,
        default="Balanced",
        choices=["Balanced", "PowerGamer", "Roleplayer"],
        help="Player archetype to simulate.",
    )
    parser.add_argument(
        "--output", type=str, default="simulation_results.csv", help="Filename for the output CSV."
    )
    args = parser.parse_args()

    print(f"--- Running Simulation ---")
    print(f"Runs: {args.runs}, Hours: {args.hours}, Archetype: {args.archetype}")

    all_results = []
    for i in range(args.runs):
        print(f"Running simulation {i + 1}/{args.runs}...")
        df = run_single_simulation(archetype=args.archetype, total_hours=args.hours)
        df["run_id"] = i
        all_results.append(df)

    final_df = pd.concat(all_results)

    print(f"\nSimulation complete. Saving results to {args.output}")
    final_df.to_csv(args.output, index=False)


if __name__ == "__main__":
    main() 