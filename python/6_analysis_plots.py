import os
import sys
sys.stdout.reconfigure(encoding='utf-8')
import pandas as pd
import matplotlib.pyplot as plt
from project_paths import MODEL_PTH, EVAL_JSON, CONFUSION_MATRIX_PNG, PLOTS_DIR, EXCEL_DIR, DATA_DIR

BENCHMARK_CSV = DATA_DIR / 'matlab_benchmark_results.csv'
RUNTIME_CSV = DATA_DIR / 'robot_runtime_log.csv'

def main():
    plots = []

    if BENCHMARK_CSV.is_file():
        df = pd.read_csv(BENCHMARK_CSV)
        if {'method', 'cost'}.issubset(df.columns):
            fig, ax = plt.subplots(figsize=(8, 4))
            ax.bar(df['method'].astype(str), df['cost'])
            ax.set_title('Benchmark Cost by Method')
            ax.set_ylabel('Cost')
            ax.grid(axis='y', alpha=0.3)
            plt.xticks(rotation=20)
            out = PLOTS_DIR / 'benchmark_costs.png'
            fig.tight_layout()
            fig.savefig(out, dpi=200)
            plt.close(fig)
            plots.append(str(out))
        if {'method', 'time'}.issubset(df.columns):
            fig, ax = plt.subplots(figsize=(8, 4))
            ax.bar(df['method'].astype(str), df['time'])
            ax.set_title('Benchmark Time by Method')
            ax.set_ylabel('Time (s)')
            ax.grid(axis='y', alpha=0.3)
            plt.xticks(rotation=20)
            out = PLOTS_DIR / 'benchmark_times.png'
            fig.tight_layout()
            fig.savefig(out, dpi=200)
            plt.close(fig)
            plots.append(str(out))

    if RUNTIME_CSV.is_file():
        rt = pd.read_csv(RUNTIME_CSV)
        num_cols = [c for c in ['cost', 'exec_time', 'x', 'y', 'z'] if c in rt.columns]
        if num_cols:
            fig, ax = plt.subplots(figsize=(10, 4))
            rt[num_cols].plot(kind='bar', ax=ax)
            ax.set_title('Runtime Log Overview')
            ax.grid(axis='y', alpha=0.3)
            out = PLOTS_DIR / 'runtime_overview.png'
            fig.tight_layout()
            fig.savefig(out, dpi=200)
            plt.close(fig)
            plots.append(str(out))

    if EVAL_JSON.is_file():
        print(f'Loaded eval summary: {EVAL_JSON}')
    if CONFUSION_MATRIX_PNG.is_file():
        print(f'Found confusion matrix: {CONFUSION_MATRIX_PNG}')

    print('Generated plots:')
    for p in plots:
        print(' -', p)

if __name__ == '__main__':
    main()