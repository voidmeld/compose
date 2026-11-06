# Compose performance

Latest: `38db8b8b170a6cae59f784d987709387a1eeb5eb` on 2026-11-06T153853Z, measured on the CI Ubuntu runner by the paired performance shards.
Each value is the median of the candidate arm's samples; p95 is shown beside it. Change compares the previous main commit.

| Benchmark | Median | p95 | Change |
| --- | --- | --- | --- |
| animate-many/compose | 6.95 ms | 7.27 ms | +126.7% |
| animate-many/memory/mounted | 2184 KiB | 2184 KiB | -0.4% |
| animate-many/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| animate-many/plain | 1.65 ms | 1.71 ms | +82.9% |
| animated-navigation.extreme/compose/burst | 4.15 ms | 4.40 ms | -36.4% |
| animated-navigation.extreme/compose/cold | 8.35 ms | 11.44 ms | -26.8% |
| animated-navigation.extreme/compose/counts | 47.61 ms | 47.61 ms | -30.1% |
| animated-navigation.extreme/compose/settle | 1.0 µs | 1.4 µs | +1.0% |
| animated-navigation.extreme/compose/steady | 17.14 ms | 17.75 ms | -33.8% |
| animated-navigation.extreme/compose/teardown | 1.99 ms | 3.30 ms | -19.4% |
| animated-navigation.extreme/memory/mounted | 6806 KiB | 6806 KiB | +0.0% |
| animated-navigation.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| animated-navigation.extreme/plain/burst | 776.1 µs | 807.7 µs | -26.9% |
| animated-navigation.extreme/plain/cold | 4.15 ms | 6.16 ms | -13.3% |
| animated-navigation.extreme/plain/settle | 1.2 µs | 1.6 µs | +15.4% |
| animated-navigation.extreme/plain/steady | 9.80 ms | 10.03 ms | -28.2% |
| animated-navigation.extreme/plain/teardown | 3.14 ms | 3.45 ms | -8.9% |
| animated-navigation.large/compose/burst | 3.81 ms | 3.90 ms | -2.2% |
| animated-navigation.large/compose/cold | 5.52 ms | 8.38 ms | -3.1% |
| animated-navigation.large/compose/counts | 56.30 ms | 56.30 ms | -2.3% |
| animated-navigation.large/compose/settle | 0.8 µs | 1.2 µs | -34.7% |
| animated-navigation.large/compose/steady | 26.22 ms | 26.71 ms | -1.8% |
| animated-navigation.large/compose/teardown | 1.09 ms | 1.83 ms | -23.7% |
| animated-navigation.large/memory/mounted | 3418 KiB | 3418 KiB | +0.2% |
| animated-navigation.large/memory/teardown | 0 KiB | 0 KiB | — |
| animated-navigation.large/plain/burst | 679.0 µs | 743.9 µs | -4.1% |
| animated-navigation.large/plain/cold | 1.62 ms | 3.50 ms | -20.8% |
| animated-navigation.large/plain/settle | 0.5 µs | 0.6 µs | -41.1% |
| animated-navigation.large/plain/steady | 8.93 ms | 9.34 ms | -1.3% |
| animated-navigation.large/plain/teardown | 1.05 ms | 1.18 ms | -11.9% |
| animated-navigation.medium/compose/burst | 606.3 µs | 878.5 µs | +1.3% |
| animated-navigation.medium/compose/cold | 1.13 ms | 1.97 ms | -4.3% |
| animated-navigation.medium/compose/counts | 10.39 ms | 10.39 ms | -2.3% |
| animated-navigation.medium/compose/settle | 0.4 µs | 1.3 µs | +21.8% |
| animated-navigation.medium/compose/steady | 4.53 ms | 8.36 ms | -3.9% |
| animated-navigation.medium/compose/teardown | 211.0 µs | 413.6 µs | -0.8% |
| animated-navigation.medium/memory/mounted | 1155 KiB | 1155 KiB | +0.0% |
| animated-navigation.medium/memory/teardown | 0 KiB | 0 KiB | — |
| animated-navigation.medium/plain/burst | 124.3 µs | 205.4 µs | +1.0% |
| animated-navigation.medium/plain/cold | 656.4 µs | 1.10 ms | -14.0% |
| animated-navigation.medium/plain/settle | 0.3 µs | 0.4 µs | +4.0% |
| animated-navigation.medium/plain/steady | 1.50 ms | 1.61 ms | +0.7% |
| animated-navigation.medium/plain/teardown | 124.7 µs | 249.5 µs | +5.8% |
| branch-swap/compose | 2.32 ms | 3.84 ms | -35.7% |
| branch-swap/memory/mounted | 23 KiB | 23 KiB | +53.3% |
| branch-swap/memory/teardown | 0 KiB | 0 KiB | — |
| branch-swap/plain | 2.09 ms | 3.70 ms | -23.6% |
| cold-mount-100/compose | 519.9 µs | 663.9 µs | -12.3% |
| cold-mount-100/memory/mounted | 2227 KiB | 2227 KiB | +0.4% |
| cold-mount-100/memory/teardown | 8 KiB | 8 KiB | — |
| cold-mount-100/plain | 426.9 µs | 838.7 µs | -21.6% |
| cold-mount-1000/compose | 5.39 ms | 9.97 ms | -33.3% |
| cold-mount-1000/memory/mounted | 21830 KiB | 21830 KiB | +0.0% |
| cold-mount-1000/memory/teardown | 0 KiB | 0 KiB | — |
| cold-mount-1000/plain | 5.13 ms | 7.06 ms | -22.6% |
| cold-mount-10000/compose | 98.26 ms | 140.66 ms | +32.9% |
| cold-mount-10000/memory/mounted | 218777 KiB | 218777 KiB | -0.0% |
| cold-mount-10000/memory/teardown | 0 KiB | 0 KiB | — |
| cold-mount-10000/plain | 71.24 ms | 99.17 ms | -7.1% |
| data-grid.extreme/compose/burst | 535.08 ms | 607.15 ms | -6.6% |
| data-grid.extreme/compose/cold | 328.65 ms | 406.99 ms | -6.3% |
| data-grid.extreme/compose/counts | 895.18 ms | 895.18 ms | -6.9% |
| data-grid.extreme/compose/settle | 2.4 µs | 3.0 µs | -14.5% |
| data-grid.extreme/compose/steady | 11.68 ms | 16.36 ms | -7.2% |
| data-grid.extreme/compose/teardown | 1.14 ms | 1.42 ms | +4.7% |
| data-grid.extreme/memory/mounted | 29228 KiB | 29228 KiB | -0.0% |
| data-grid.extreme/memory/teardown | 8 KiB | 8 KiB | -11.1% |
| data-grid.extreme/plain/burst | 467.64 ms | 501.04 ms | -3.4% |
| data-grid.extreme/plain/cold | 292.21 ms | 375.57 ms | -5.6% |
| data-grid.extreme/plain/settle | 2.7 µs | 3.3 µs | -6.0% |
| data-grid.extreme/plain/steady | 10.16 ms | 15.14 ms | -8.8% |
| data-grid.extreme/plain/teardown | 491.9 µs | 782.4 µs | -9.1% |
| data-grid.large/compose/burst | 135.96 ms | 143.65 ms | -2.9% |
| data-grid.large/compose/cold | 79.87 ms | 83.94 ms | -1.1% |
| data-grid.large/compose/counts | 259.53 ms | 259.53 ms | -3.7% |
| data-grid.large/compose/settle | 2.0 µs | 2.3 µs | -2.5% |
| data-grid.large/compose/steady | 15.84 ms | 23.23 ms | -8.9% |
| data-grid.large/compose/teardown | 507.1 µs | 586.6 µs | -2.0% |
| data-grid.large/memory/mounted | 6833 KiB | 6833 KiB | +0.1% |
| data-grid.large/memory/teardown | 0 KiB | 0 KiB | — |
| data-grid.large/plain/burst | 115.28 ms | 119.42 ms | -8.2% |
| data-grid.large/plain/cold | 72.86 ms | 78.12 ms | -7.3% |
| data-grid.large/plain/settle | 1.8 µs | 2.4 µs | -29.5% |
| data-grid.large/plain/steady | 9.89 ms | 14.64 ms | -14.6% |
| data-grid.large/plain/teardown | 224.6 µs | 394.4 µs | +10.0% |
| data-grid.medium/compose/burst | 40.26 ms | 45.44 ms | -19.0% |
| data-grid.medium/compose/cold | 22.73 ms | 26.43 ms | -19.5% |
| data-grid.medium/compose/counts | 85.01 ms | 85.01 ms | -16.4% |
| data-grid.medium/compose/settle | 2.3 µs | 2.9 µs | +5.4% |
| data-grid.medium/compose/steady | 8.73 ms | 12.08 ms | -28.1% |
| data-grid.medium/compose/teardown | 222.0 µs | 280.1 µs | -8.4% |
| data-grid.medium/memory/mounted | 3561 KiB | 3561 KiB | +0.0% |
| data-grid.medium/memory/teardown | 1 KiB | 1 KiB | — |
| data-grid.medium/plain/burst | 32.91 ms | 35.34 ms | -19.0% |
| data-grid.medium/plain/cold | 19.96 ms | 24.39 ms | -22.6% |
| data-grid.medium/plain/settle | 2.8 µs | 3.1 µs | +15.9% |
| data-grid.medium/plain/steady | 4.98 ms | 7.69 ms | -19.9% |
| data-grid.medium/plain/teardown | 68.7 µs | 96.2 µs | -16.9% |
| dense-dashboard.extreme/compose/burst | 13.81 ms | 20.98 ms | +57.8% |
| dense-dashboard.extreme/compose/cold | 503.4 µs | 776.9 µs | +64.0% |
| dense-dashboard.extreme/compose/counts | 25.34 ms | 25.34 ms | +109.3% |
| dense-dashboard.extreme/compose/settle | 1.1 µs | 1.8 µs | +77.1% |
| dense-dashboard.extreme/compose/steady | 853.9 µs | 871.2 µs | +85.0% |
| dense-dashboard.extreme/compose/teardown | 528.8 µs | 580.5 µs | +76.2% |
| dense-dashboard.extreme/memory/mounted | 1270 KiB | 1270 KiB | +0.0% |
| dense-dashboard.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| dense-dashboard.extreme/plain/burst | 6.79 ms | 9.21 ms | +74.0% |
| dense-dashboard.extreme/plain/cold | 235.9 µs | 452.5 µs | +76.9% |
| dense-dashboard.extreme/plain/settle | 0.8 µs | 1.1 µs | +55.7% |
| dense-dashboard.extreme/plain/steady | 131.2 µs | 132.9 µs | +73.1% |
| dense-dashboard.extreme/plain/teardown | 212.0 µs | 263.2 µs | +73.1% |
| dense-dashboard.large/compose/burst | 6.46 ms | 11.52 ms | -11.8% |
| dense-dashboard.large/compose/cold | 311.0 µs | 761.4 µs | -3.4% |
| dense-dashboard.large/compose/counts | 15.62 ms | 15.62 ms | +1.0% |
| dense-dashboard.large/compose/settle | 0.8 µs | 1.6 µs | -14.9% |
| dense-dashboard.large/compose/steady | 849.7 µs | 891.1 µs | -2.5% |
| dense-dashboard.large/compose/teardown | 242.4 µs | 349.2 µs | -5.2% |
| dense-dashboard.large/memory/mounted | 673 KiB | 673 KiB | +1.2% |
| dense-dashboard.large/memory/teardown | 8 KiB | 8 KiB | — |
| dense-dashboard.large/plain/burst | 2.62 ms | 3.73 ms | -22.6% |
| dense-dashboard.large/plain/cold | 113.9 µs | 356.4 µs | -14.1% |
| dense-dashboard.large/plain/settle | 0.7 µs | 1.0 µs | +0.0% |
| dense-dashboard.large/plain/steady | 132.1 µs | 149.6 µs | +0.5% |
| dense-dashboard.large/plain/teardown | 101.8 µs | 145.1 µs | +8.1% |
| dense-dashboard.medium/compose/burst | 1.72 ms | 2.94 ms | -9.0% |
| dense-dashboard.medium/compose/cold | 125.0 µs | 232.7 µs | -17.1% |
| dense-dashboard.medium/compose/counts | 3.04 ms | 3.04 ms | -32.4% |
| dense-dashboard.medium/compose/settle | 0.4 µs | 0.7 µs | -25.0% |
| dense-dashboard.medium/compose/steady | 440.8 µs | 449.3 µs | -2.4% |
| dense-dashboard.medium/compose/teardown | 68.2 µs | 79.3 µs | -4.0% |
| dense-dashboard.medium/memory/mounted | 321 KiB | 321 KiB | +0.0% |
| dense-dashboard.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| dense-dashboard.medium/plain/burst | 610.4 µs | 1.64 ms | -45.5% |
| dense-dashboard.medium/plain/cold | 60.2 µs | 162.5 µs | -11.5% |
| dense-dashboard.medium/plain/settle | 0.4 µs | 0.5 µs | -17.8% |
| dense-dashboard.medium/plain/steady | 69.5 µs | 76.1 µs | -4.2% |
| dense-dashboard.medium/plain/teardown | 26.7 µs | 40.6 µs | -26.7% |
| entities-identity-churn-10.extreme/compose/burst | 44.42 ms | 75.14 ms | +21.9% |
| entities-identity-churn-10.extreme/compose/cold | 30.61 ms | 48.68 ms | +37.2% |
| entities-identity-churn-10.extreme/compose/counts | 226.41 ms | 226.41 ms | +44.0% |
| entities-identity-churn-10.extreme/compose/settle | 2.2 µs | 2.5 µs | +45.1% |
| entities-identity-churn-10.extreme/compose/steady | 58.94 ms | 75.80 ms | +52.4% |
| entities-identity-churn-10.extreme/compose/teardown | 1.18 ms | 1.72 ms | +35.4% |
| entities-identity-churn-10.extreme/memory/mounted | 4230 KiB | 4230 KiB | +0.2% |
| entities-identity-churn-10.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn-10.extreme/plain/burst | 17.45 ms | 24.30 ms | +15.6% |
| entities-identity-churn-10.extreme/plain/cold | 7.47 ms | 18.20 ms | +21.5% |
| entities-identity-churn-10.extreme/plain/settle | 2.0 µs | 2.6 µs | +50.8% |
| entities-identity-churn-10.extreme/plain/steady | 31.09 ms | 38.13 ms | +29.9% |
| entities-identity-churn-10.extreme/plain/teardown | 367.2 µs | 573.2 µs | +18.2% |
| entities-identity-churn-10.large/compose/burst | 12.67 ms | 17.48 ms | -8.3% |
| entities-identity-churn-10.large/compose/cold | 8.90 ms | 14.70 ms | +1.5% |
| entities-identity-churn-10.large/compose/counts | 49.20 ms | 49.20 ms | -13.7% |
| entities-identity-churn-10.large/compose/settle | 2.2 µs | 2.7 µs | +14.3% |
| entities-identity-churn-10.large/compose/steady | 12.19 ms | 18.13 ms | -24.2% |
| entities-identity-churn-10.large/compose/teardown | 297.1 µs | 347.3 µs | -14.2% |
| entities-identity-churn-10.large/memory/mounted | 1677 KiB | 1677 KiB | +0.2% |
| entities-identity-churn-10.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-identity-churn-10.large/plain/burst | 3.33 ms | 7.56 ms | -33.8% |
| entities-identity-churn-10.large/plain/cold | 2.15 ms | 4.93 ms | -37.7% |
| entities-identity-churn-10.large/plain/settle | 1.2 µs | 1.7 µs | -20.8% |
| entities-identity-churn-10.large/plain/steady | 6.28 ms | 7.65 ms | -25.8% |
| entities-identity-churn-10.large/plain/teardown | 90.2 µs | 202.2 µs | -10.6% |
| entities-identity-churn-10.medium/compose/burst | 5.39 ms | 8.13 ms | +11.9% |
| entities-identity-churn-10.medium/compose/cold | 3.69 ms | 7.26 ms | +5.1% |
| entities-identity-churn-10.medium/compose/counts | 21.78 ms | 21.78 ms | -1.8% |
| entities-identity-churn-10.medium/compose/settle | 1.3 µs | 1.8 µs | +42.9% |
| entities-identity-churn-10.medium/compose/steady | 4.80 ms | 5.67 ms | -5.7% |
| entities-identity-churn-10.medium/compose/teardown | 141.4 µs | 216.3 µs | +2.3% |
| entities-identity-churn-10.medium/memory/mounted | 869 KiB | 869 KiB | +0.0% |
| entities-identity-churn-10.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn-10.medium/plain/burst | 1.49 ms | 2.55 ms | -11.3% |
| entities-identity-churn-10.medium/plain/cold | 976.9 µs | 2.66 ms | -5.1% |
| entities-identity-churn-10.medium/plain/settle | 0.7 µs | 0.9 µs | +40.6% |
| entities-identity-churn-10.medium/plain/steady | 2.78 ms | 5.31 ms | -3.2% |
| entities-identity-churn-10.medium/plain/teardown | 44.1 µs | 71.9 µs | -3.1% |
| entities-identity-churn-50.extreme/compose/burst | 42.10 ms | 60.99 ms | +12.6% |
| entities-identity-churn-50.extreme/compose/cold | 26.51 ms | 42.73 ms | -8.3% |
| entities-identity-churn-50.extreme/compose/counts | 264.73 ms | 264.73 ms | -15.2% |
| entities-identity-churn-50.extreme/compose/settle | 2.4 µs | 3.1 µs | -8.3% |
| entities-identity-churn-50.extreme/compose/steady | 138.91 ms | 153.94 ms | -3.8% |
| entities-identity-churn-50.extreme/compose/teardown | 1.05 ms | 2.03 ms | +3.5% |
| entities-identity-churn-50.extreme/memory/mounted | 4171 KiB | 4171 KiB | +0.2% |
| entities-identity-churn-50.extreme/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| entities-identity-churn-50.extreme/plain/burst | 14.21 ms | 25.08 ms | -14.2% |
| entities-identity-churn-50.extreme/plain/cold | 9.12 ms | 16.47 ms | +19.5% |
| entities-identity-churn-50.extreme/plain/settle | 2.4 µs | 3.3 µs | +2.1% |
| entities-identity-churn-50.extreme/plain/steady | 50.89 ms | 60.49 ms | -13.9% |
| entities-identity-churn-50.extreme/plain/teardown | 281.1 µs | 794.5 µs | -13.2% |
| entities-identity-churn-50.large/compose/burst | 16.01 ms | 23.54 ms | +40.5% |
| entities-identity-churn-50.large/compose/cold | 12.31 ms | 22.10 ms | +15.7% |
| entities-identity-churn-50.large/compose/counts | 118.64 ms | 118.64 ms | +37.3% |
| entities-identity-churn-50.large/compose/settle | 2.3 µs | 3.4 µs | +53.1% |
| entities-identity-churn-50.large/compose/steady | 56.61 ms | 74.06 ms | +40.4% |
| entities-identity-churn-50.large/compose/teardown | 448.9 µs | 606.2 µs | +43.5% |
| entities-identity-churn-50.large/memory/mounted | 1734 KiB | 1734 KiB | +1.9% |
| entities-identity-churn-50.large/memory/teardown | 9 KiB | 9 KiB | — |
| entities-identity-churn-50.large/plain/burst | 6.00 ms | 8.09 ms | +25.2% |
| entities-identity-churn-50.large/plain/cold | 4.71 ms | 8.39 ms | +86.6% |
| entities-identity-churn-50.large/plain/settle | 1.8 µs | 2.4 µs | +101.1% |
| entities-identity-churn-50.large/plain/steady | 21.58 ms | 31.39 ms | +40.4% |
| entities-identity-churn-50.large/plain/teardown | 130.2 µs | 187.8 µs | +40.5% |
| entities-identity-churn-50.medium/compose/burst | 8.73 ms | 14.73 ms | +2.9% |
| entities-identity-churn-50.medium/compose/cold | 5.09 ms | 12.55 ms | -0.6% |
| entities-identity-churn-50.medium/compose/counts | 66.18 ms | 66.18 ms | +9.2% |
| entities-identity-churn-50.medium/compose/settle | 1.6 µs | 2.3 µs | +19.8% |
| entities-identity-churn-50.medium/compose/steady | 25.05 ms | 32.88 ms | +11.6% |
| entities-identity-churn-50.medium/compose/teardown | 252.1 µs | 1.19 ms | +5.2% |
| entities-identity-churn-50.medium/memory/mounted | 961 KiB | 961 KiB | +0.8% |
| entities-identity-churn-50.medium/memory/teardown | 9 KiB | 9 KiB | +800.0% |
| entities-identity-churn-50.medium/plain/burst | 2.91 ms | 5.91 ms | -16.8% |
| entities-identity-churn-50.medium/plain/cold | 1.86 ms | 4.45 ms | +27.0% |
| entities-identity-churn-50.medium/plain/settle | 0.9 µs | 1.4 µs | -37.7% |
| entities-identity-churn-50.medium/plain/steady | 10.13 ms | 18.20 ms | -6.3% |
| entities-identity-churn-50.medium/plain/teardown | 75.5 µs | 140.3 µs | -5.3% |
| entities-identity-churn.extreme/compose/burst | 42.74 ms | 46.24 ms | -16.4% |
| entities-identity-churn.extreme/compose/cold | 29.22 ms | 30.26 ms | -6.3% |
| entities-identity-churn.extreme/compose/counts | 231.55 ms | 231.55 ms | -16.4% |
| entities-identity-churn.extreme/compose/settle | 2.0 µs | 2.4 µs | -14.7% |
| entities-identity-churn.extreme/compose/steady | 98.72 ms | 122.94 ms | -4.6% |
| entities-identity-churn.extreme/compose/teardown | 1.16 ms | 1.50 ms | -20.3% |
| entities-identity-churn.extreme/memory/mounted | 4612 KiB | 4612 KiB | +0.2% |
| entities-identity-churn.extreme/memory/teardown | 96 KiB | 96 KiB | +9.1% |
| entities-identity-churn.extreme/plain/burst | 17.56 ms | 27.83 ms | -4.1% |
| entities-identity-churn.extreme/plain/cold | 10.62 ms | 21.39 ms | +35.6% |
| entities-identity-churn.extreme/plain/settle | 2.1 µs | 2.5 µs | +8.1% |
| entities-identity-churn.extreme/plain/steady | 47.05 ms | 53.90 ms | -6.1% |
| entities-identity-churn.extreme/plain/teardown | 455.8 µs | 625.7 µs | -1.6% |
| entities-identity-churn.large/compose/burst | 8.49 ms | 13.64 ms | -12.2% |
| entities-identity-churn.large/compose/cold | 8.41 ms | 12.02 ms | +14.8% |
| entities-identity-churn.large/compose/counts | 65.08 ms | 65.08 ms | +4.2% |
| entities-identity-churn.large/compose/settle | 1.6 µs | 2.0 µs | -1.9% |
| entities-identity-churn.large/compose/steady | 18.59 ms | 26.42 ms | +4.6% |
| entities-identity-churn.large/compose/teardown | 244.4 µs | 419.9 µs | +10.6% |
| entities-identity-churn.large/memory/mounted | 1644 KiB | 1644 KiB | +0.0% |
| entities-identity-churn.large/memory/teardown | 1 KiB | 1 KiB | -87.5% |
| entities-identity-churn.large/plain/burst | 3.02 ms | 6.59 ms | -2.1% |
| entities-identity-churn.large/plain/cold | 1.75 ms | 3.31 ms | -4.6% |
| entities-identity-churn.large/plain/settle | 1.1 µs | 1.6 µs | +31.0% |
| entities-identity-churn.large/plain/steady | 9.19 ms | 11.40 ms | +5.7% |
| entities-identity-churn.large/plain/teardown | 75.6 µs | 99.5 µs | +10.3% |
| entities-identity-churn.medium/compose/burst | 5.04 ms | 9.00 ms | -9.9% |
| entities-identity-churn.medium/compose/cold | 3.68 ms | 8.57 ms | -10.3% |
| entities-identity-churn.medium/compose/counts | 26.27 ms | 26.27 ms | -17.7% |
| entities-identity-churn.medium/compose/settle | 1.7 µs | 2.3 µs | +65.0% |
| entities-identity-churn.medium/compose/steady | 9.75 ms | 12.68 ms | -9.6% |
| entities-identity-churn.medium/compose/teardown | 158.3 µs | 241.4 µs | -3.2% |
| entities-identity-churn.medium/memory/mounted | 924 KiB | 924 KiB | +0.0% |
| entities-identity-churn.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-identity-churn.medium/plain/burst | 1.90 ms | 3.34 ms | -24.9% |
| entities-identity-churn.medium/plain/cold | 1.20 ms | 3.42 ms | +15.3% |
| entities-identity-churn.medium/plain/settle | 1.1 µs | 1.5 µs | +57.0% |
| entities-identity-churn.medium/plain/steady | 4.82 ms | 6.66 ms | -16.0% |
| entities-identity-churn.medium/plain/teardown | 49.7 µs | 75.3 µs | +2.6% |
| entities-integrated.extreme/compose/burst | 16.86 ms | 26.16 ms | -6.9% |
| entities-integrated.extreme/compose/cold | 100.24 ms | 132.91 ms | -1.7% |
| entities-integrated.extreme/compose/counts | 324.62 ms | 324.62 ms | -9.6% |
| entities-integrated.extreme/compose/settle | 1.9 µs | 2.3 µs | +3.8% |
| entities-integrated.extreme/compose/steady | 81.41 ms | 110.37 ms | -10.2% |
| entities-integrated.extreme/compose/teardown | 45.50 ms | 58.21 ms | -13.9% |
| entities-integrated.extreme/memory/mounted | 40043 KiB | 40043 KiB | +0.0% |
| entities-integrated.extreme/memory/teardown | 17 KiB | 17 KiB | +88.9% |
| entities-integrated.extreme/plain/burst | 5.54 ms | 10.16 ms | -13.6% |
| entities-integrated.extreme/plain/cold | 24.42 ms | 51.87 ms | -20.4% |
| entities-integrated.extreme/plain/settle | 1.3 µs | 2.0 µs | -33.8% |
| entities-integrated.extreme/plain/steady | 22.96 ms | 36.88 ms | -16.9% |
| entities-integrated.extreme/plain/teardown | 22.59 ms | 28.02 ms | -12.9% |
| entities-integrated.large/compose/burst | 9.27 ms | 10.91 ms | -6.2% |
| entities-integrated.large/compose/cold | 40.70 ms | 57.97 ms | -5.2% |
| entities-integrated.large/compose/counts | 136.59 ms | 136.59 ms | -14.2% |
| entities-integrated.large/compose/settle | 1.5 µs | 1.8 µs | -27.7% |
| entities-integrated.large/compose/steady | 47.70 ms | 63.66 ms | -16.1% |
| entities-integrated.large/compose/teardown | 13.91 ms | 17.33 ms | -17.2% |
| entities-integrated.large/memory/mounted | 16524 KiB | 16524 KiB | -0.0% |
| entities-integrated.large/memory/teardown | 8 KiB | 8 KiB | -11.1% |
| entities-integrated.large/plain/burst | 2.90 ms | 3.50 ms | -21.5% |
| entities-integrated.large/plain/cold | 12.48 ms | 19.46 ms | -11.6% |
| entities-integrated.large/plain/settle | 1.0 µs | 1.7 µs | -47.3% |
| entities-integrated.large/plain/steady | 12.81 ms | 16.58 ms | -20.3% |
| entities-integrated.large/plain/teardown | 5.10 ms | 6.07 ms | -38.9% |
| entities-integrated.medium/compose/burst | 4.06 ms | 6.68 ms | -4.9% |
| entities-integrated.medium/compose/cold | 12.99 ms | 20.31 ms | -8.6% |
| entities-integrated.medium/compose/counts | 56.77 ms | 56.77 ms | -5.6% |
| entities-integrated.medium/compose/settle | 1.7 µs | 1.9 µs | -10.8% |
| entities-integrated.medium/compose/steady | 19.48 ms | 29.17 ms | -6.2% |
| entities-integrated.medium/compose/teardown | 5.14 ms | 6.65 ms | -13.1% |
| entities-integrated.medium/memory/mounted | 8954 KiB | 8954 KiB | -0.1% |
| entities-integrated.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entities-integrated.medium/plain/burst | 1.68 ms | 3.17 ms | +21.5% |
| entities-integrated.medium/plain/cold | 4.35 ms | 8.44 ms | +9.2% |
| entities-integrated.medium/plain/settle | 1.0 µs | 1.8 µs | -37.4% |
| entities-integrated.medium/plain/steady | 5.93 ms | 9.52 ms | -17.6% |
| entities-integrated.medium/plain/teardown | 1.78 ms | 3.00 ms | -28.5% |
| entities-relevance-saturated.extreme/compose/burst | 67.80 ms | 83.66 ms | -17.4% |
| entities-relevance-saturated.extreme/compose/cold | 19.39 ms | 33.80 ms | -18.7% |
| entities-relevance-saturated.extreme/compose/counts | 170.16 ms | 170.16 ms | -21.2% |
| entities-relevance-saturated.extreme/compose/settle | 2.9 µs | 3.5 µs | +13.5% |
| entities-relevance-saturated.extreme/compose/steady | 63.40 ms | 71.57 ms | +36.4% |
| entities-relevance-saturated.extreme/compose/teardown | 13.26 ms | 14.10 ms | +0.0% |
| entities-relevance-saturated.extreme/memory/mounted | 12006 KiB | 12006 KiB | +0.1% |
| entities-relevance-saturated.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| entities-relevance-saturated.extreme/plain/burst | 14.80 ms | 27.38 ms | -22.7% |
| entities-relevance-saturated.extreme/plain/cold | 6.46 ms | 18.35 ms | -33.4% |
| entities-relevance-saturated.extreme/plain/settle | 2.4 µs | 2.9 µs | +2.6% |
| entities-relevance-saturated.extreme/plain/steady | 57.12 ms | 80.33 ms | -25.3% |
| entities-relevance-saturated.extreme/plain/teardown | 3.91 ms | 4.96 ms | +2.1% |
| entities-relevance-saturated.large/compose/burst | 21.41 ms | 34.63 ms | -10.2% |
| entities-relevance-saturated.large/compose/cold | 8.70 ms | 10.97 ms | -3.9% |
| entities-relevance-saturated.large/compose/counts | 60.08 ms | 60.08 ms | -9.3% |
| entities-relevance-saturated.large/compose/settle | 2.3 µs | 2.7 µs | +7.8% |
| entities-relevance-saturated.large/compose/steady | 12.95 ms | 22.62 ms | -18.9% |
| entities-relevance-saturated.large/compose/teardown | 2.97 ms | 3.47 ms | -10.5% |
| entities-relevance-saturated.large/memory/mounted | 4816 KiB | 4816 KiB | +0.0% |
| entities-relevance-saturated.large/memory/teardown | 0 KiB | 0 KiB | — |
| entities-relevance-saturated.large/plain/burst | 5.33 ms | 8.67 ms | -7.7% |
| entities-relevance-saturated.large/plain/cold | 2.84 ms | 10.14 ms | -10.8% |
| entities-relevance-saturated.large/plain/settle | 2.2 µs | 2.6 µs | +9.3% |
| entities-relevance-saturated.large/plain/steady | 20.97 ms | 28.03 ms | -27.0% |
| entities-relevance-saturated.large/plain/teardown | 1.48 ms | 1.84 ms | +11.6% |
| entities-relevance-saturated.medium/compose/burst | 13.26 ms | 21.81 ms | +31.9% |
| entities-relevance-saturated.medium/compose/cold | 6.00 ms | 11.32 ms | +35.6% |
| entities-relevance-saturated.medium/compose/counts | 40.00 ms | 40.00 ms | +50.5% |
| entities-relevance-saturated.medium/compose/settle | 1.5 µs | 2.3 µs | +59.6% |
| entities-relevance-saturated.medium/compose/steady | 10.27 ms | 15.00 ms | +55.7% |
| entities-relevance-saturated.medium/compose/teardown | 1.38 ms | 1.80 ms | +51.3% |
| entities-relevance-saturated.medium/memory/mounted | 2411 KiB | 2411 KiB | -0.3% |
| entities-relevance-saturated.medium/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| entities-relevance-saturated.medium/plain/burst | 3.56 ms | 7.08 ms | +63.5% |
| entities-relevance-saturated.medium/plain/cold | 2.80 ms | 6.19 ms | +61.2% |
| entities-relevance-saturated.medium/plain/settle | 2.0 µs | 2.8 µs | +198.5% |
| entities-relevance-saturated.medium/plain/steady | 18.72 ms | 22.89 ms | +58.7% |
| entities-relevance-saturated.medium/plain/teardown | 656.6 µs | 870.0 µs | +117.3% |
| entities-relevance-sweep.extreme/compose/burst | 131.89 ms | 168.85 ms | +58.9% |
| entities-relevance-sweep.extreme/compose/cold | 32.90 ms | 66.46 ms | +21.3% |
| entities-relevance-sweep.extreme/compose/counts | 392.73 ms | 392.73 ms | +32.1% |
| entities-relevance-sweep.extreme/compose/settle | 2.5 µs | 2.8 µs | +35.3% |
| entities-relevance-sweep.extreme/compose/steady | 129.48 ms | 157.08 ms | +24.0% |
| entities-relevance-sweep.extreme/compose/teardown | 14.37 ms | 17.31 ms | +26.0% |
| entities-relevance-sweep.extreme/memory/mounted | 12034 KiB | 12034 KiB | -0.1% |
| entities-relevance-sweep.extreme/memory/teardown | 8 KiB | 8 KiB | -50.0% |
| entities-relevance-sweep.extreme/plain/burst | 27.69 ms | 53.89 ms | -5.1% |
| entities-relevance-sweep.extreme/plain/cold | 9.48 ms | 20.87 ms | +6.6% |
| entities-relevance-sweep.extreme/plain/settle | 2.6 µs | 3.2 µs | +36.4% |
| entities-relevance-sweep.extreme/plain/steady | 28.75 ms | 50.28 ms | +25.0% |
| entities-relevance-sweep.extreme/plain/teardown | 3.83 ms | 4.88 ms | +9.4% |
| entities-relevance-sweep.large/compose/burst | 36.62 ms | 43.07 ms | -2.8% |
| entities-relevance-sweep.large/compose/cold | 7.42 ms | 16.14 ms | -21.3% |
| entities-relevance-sweep.large/compose/counts | 105.64 ms | 105.64 ms | -10.8% |
| entities-relevance-sweep.large/compose/settle | 2.4 µs | 3.0 µs | +19.0% |
| entities-relevance-sweep.large/compose/steady | 29.65 ms | 40.69 ms | -18.5% |
| entities-relevance-sweep.large/compose/teardown | 3.17 ms | 3.34 ms | -4.4% |
| entities-relevance-sweep.large/memory/mounted | 4817 KiB | 4817 KiB | -0.2% |
| entities-relevance-sweep.large/memory/teardown | 0 KiB | 0 KiB | — |
| entities-relevance-sweep.large/plain/burst | 8.96 ms | 15.94 ms | -21.1% |
| entities-relevance-sweep.large/plain/cold | 4.05 ms | 9.24 ms | +18.6% |
| entities-relevance-sweep.large/plain/settle | 2.4 µs | 2.8 µs | +24.2% |
| entities-relevance-sweep.large/plain/steady | 7.67 ms | 13.19 ms | -17.3% |
| entities-relevance-sweep.large/plain/teardown | 1.52 ms | 1.84 ms | +5.8% |
| entities-relevance-sweep.medium/compose/burst | 17.61 ms | 24.15 ms | -17.3% |
| entities-relevance-sweep.medium/compose/cold | 4.87 ms | 12.25 ms | -11.7% |
| entities-relevance-sweep.medium/compose/counts | 63.43 ms | 63.43 ms | -13.6% |
| entities-relevance-sweep.medium/compose/settle | 1.0 µs | 1.2 µs | -49.2% |
| entities-relevance-sweep.medium/compose/steady | 18.05 ms | 23.75 ms | -16.5% |
| entities-relevance-sweep.medium/compose/teardown | 998.7 µs | 1.28 ms | -29.7% |
| entities-relevance-sweep.medium/memory/mounted | 2420 KiB | 2420 KiB | +0.4% |
| entities-relevance-sweep.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entities-relevance-sweep.medium/plain/burst | 5.49 ms | 7.53 ms | -8.6% |
| entities-relevance-sweep.medium/plain/cold | 1.61 ms | 2.76 ms | -33.5% |
| entities-relevance-sweep.medium/plain/settle | 0.8 µs | 1.0 µs | -35.1% |
| entities-relevance-sweep.medium/plain/steady | 4.46 ms | 7.18 ms | -8.8% |
| entities-relevance-sweep.medium/plain/teardown | 286.1 µs | 371.9 µs | -51.7% |
| entity-labels-sparse.extreme/compose/burst | 29.66 ms | 38.37 ms | +4.3% |
| entity-labels-sparse.extreme/compose/cold | 23.93 ms | 33.38 ms | -6.1% |
| entity-labels-sparse.extreme/compose/counts | 95.88 ms | 95.88 ms | -7.2% |
| entity-labels-sparse.extreme/compose/settle | 1.9 µs | 2.8 µs | +6.1% |
| entity-labels-sparse.extreme/compose/steady | 3.94 ms | 4.90 ms | -5.1% |
| entity-labels-sparse.extreme/compose/teardown | 12.27 ms | 13.67 ms | -3.8% |
| entity-labels-sparse.extreme/memory/mounted | 12219 KiB | 12219 KiB | +0.0% |
| entity-labels-sparse.extreme/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| entity-labels-sparse.extreme/plain/burst | 10.57 ms | 13.53 ms | +3.3% |
| entity-labels-sparse.extreme/plain/cold | 7.89 ms | 13.74 ms | +5.9% |
| entity-labels-sparse.extreme/plain/settle | 1.2 µs | 2.0 µs | -31.2% |
| entity-labels-sparse.extreme/plain/steady | 956.3 µs | 1.13 ms | -3.9% |
| entity-labels-sparse.extreme/plain/teardown | 6.07 ms | 7.41 ms | -7.1% |
| entity-labels-sparse.large/compose/burst | 12.29 ms | 18.52 ms | -2.2% |
| entity-labels-sparse.large/compose/cold | 12.24 ms | 17.11 ms | +21.6% |
| entity-labels-sparse.large/compose/counts | 41.55 ms | 41.55 ms | -12.0% |
| entity-labels-sparse.large/compose/settle | 1.3 µs | 1.9 µs | +3.2% |
| entity-labels-sparse.large/compose/steady | 1.93 ms | 2.59 ms | +2.4% |
| entity-labels-sparse.large/compose/teardown | 4.04 ms | 4.44 ms | +5.1% |
| entity-labels-sparse.large/memory/mounted | 6348 KiB | 6348 KiB | -0.1% |
| entity-labels-sparse.large/memory/teardown | 8 KiB | 8 KiB | +700.0% |
| entity-labels-sparse.large/plain/burst | 4.07 ms | 7.21 ms | +7.9% |
| entity-labels-sparse.large/plain/cold | 4.59 ms | 8.12 ms | -9.9% |
| entity-labels-sparse.large/plain/settle | 0.9 µs | 1.2 µs | -7.4% |
| entity-labels-sparse.large/plain/steady | 457.7 µs | 533.1 µs | -0.9% |
| entity-labels-sparse.large/plain/teardown | 1.81 ms | 2.13 ms | -2.8% |
| entity-labels-sparse.medium/compose/burst | 4.88 ms | 6.53 ms | +81.3% |
| entity-labels-sparse.medium/compose/cold | 5.34 ms | 7.36 ms | +52.2% |
| entity-labels-sparse.medium/compose/counts | 20.01 ms | 20.01 ms | +68.2% |
| entity-labels-sparse.medium/compose/settle | 0.8 µs | 2.0 µs | +5.4% |
| entity-labels-sparse.medium/compose/steady | 864.1 µs | 1.08 ms | +58.0% |
| entity-labels-sparse.medium/compose/teardown | 1.25 ms | 1.57 ms | +56.9% |
| entity-labels-sparse.medium/memory/mounted | 2816 KiB | 2816 KiB | -0.3% |
| entity-labels-sparse.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entity-labels-sparse.medium/plain/burst | 1.37 ms | 2.73 ms | +57.0% |
| entity-labels-sparse.medium/plain/cold | 2.09 ms | 2.43 ms | +41.3% |
| entity-labels-sparse.medium/plain/settle | 0.6 µs | 0.7 µs | +43.1% |
| entity-labels-sparse.medium/plain/steady | 203.2 µs | 219.4 µs | +62.8% |
| entity-labels-sparse.medium/plain/teardown | 475.6 µs | 584.5 µs | +42.7% |
| entity-labels.extreme/compose/burst | 27.29 ms | 34.02 ms | -28.8% |
| entity-labels.extreme/compose/cold | 25.73 ms | 32.64 ms | -2.5% |
| entity-labels.extreme/compose/counts | 118.48 ms | 118.48 ms | -19.2% |
| entity-labels.extreme/compose/settle | 1.2 µs | 1.3 µs | -45.8% |
| entity-labels.extreme/compose/steady | 31.13 ms | 34.99 ms | -11.2% |
| entity-labels.extreme/compose/teardown | 14.89 ms | 15.69 ms | +5.1% |
| entity-labels.extreme/memory/mounted | 12696 KiB | 12696 KiB | +0.0% |
| entity-labels.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entity-labels.extreme/plain/burst | 7.46 ms | 10.20 ms | -34.3% |
| entity-labels.extreme/plain/cold | 8.28 ms | 14.41 ms | +14.3% |
| entity-labels.extreme/plain/settle | 0.9 µs | 1.1 µs | -51.9% |
| entity-labels.extreme/plain/steady | 850.1 µs | 996.2 µs | -21.0% |
| entity-labels.extreme/plain/teardown | 5.28 ms | 5.49 ms | -23.1% |
| entity-labels.large/compose/burst | 13.68 ms | 23.16 ms | -16.5% |
| entity-labels.large/compose/cold | 12.16 ms | 17.69 ms | -7.3% |
| entity-labels.large/compose/counts | 67.40 ms | 67.40 ms | -5.5% |
| entity-labels.large/compose/settle | 1.6 µs | 1.9 µs | -13.2% |
| entity-labels.large/compose/steady | 15.64 ms | 16.69 ms | -8.7% |
| entity-labels.large/compose/teardown | 4.47 ms | 4.92 ms | -10.3% |
| entity-labels.large/memory/mounted | 6602 KiB | 6602 KiB | +0.0% |
| entity-labels.large/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| entity-labels.large/plain/burst | 4.43 ms | 6.07 ms | +7.7% |
| entity-labels.large/plain/cold | 4.96 ms | 7.55 ms | +4.6% |
| entity-labels.large/plain/settle | 1.0 µs | 1.3 µs | -12.5% |
| entity-labels.large/plain/steady | 466.4 µs | 491.9 µs | -7.5% |
| entity-labels.large/plain/teardown | 1.92 ms | 2.62 ms | -7.1% |
| entity-labels.medium/compose/burst | 5.02 ms | 6.47 ms | -8.0% |
| entity-labels.medium/compose/cold | 4.15 ms | 7.17 ms | -31.4% |
| entity-labels.medium/compose/counts | 23.45 ms | 23.45 ms | -15.3% |
| entity-labels.medium/compose/settle | 0.8 µs | 1.0 µs | -34.7% |
| entity-labels.medium/compose/steady | 6.39 ms | 7.66 ms | -1.3% |
| entity-labels.medium/compose/teardown | 1.27 ms | 1.45 ms | -13.8% |
| entity-labels.medium/memory/mounted | 2943 KiB | 2943 KiB | +0.0% |
| entity-labels.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| entity-labels.medium/plain/burst | 1.36 ms | 2.05 ms | -9.5% |
| entity-labels.medium/plain/cold | 1.65 ms | 3.38 ms | -31.6% |
| entity-labels.medium/plain/settle | 0.6 µs | 0.7 µs | -8.8% |
| entity-labels.medium/plain/steady | 204.9 µs | 251.4 µs | -2.8% |
| entity-labels.medium/plain/teardown | 518.8 µs | 689.2 µs | -2.4% |
| events/compose | 9.12 ms | 12.55 ms | -12.8% |
| events/memory/mounted | 1 KiB | 1 KiB | — |
| events/memory/teardown | 0 KiB | 0 KiB | — |
| events/plain | 8.97 ms | 10.91 ms | -15.9% |
| inspector.extreme/compose/burst | 5.55 ms | 7.94 ms | -25.5% |
| inspector.extreme/compose/cold | 15.88 ms | 25.05 ms | -15.9% |
| inspector.extreme/compose/counts | 23.49 ms | 23.49 ms | -31.6% |
| inspector.extreme/compose/settle | 1.4 µs | 1.9 µs | -12.7% |
| inspector.extreme/compose/steady | 207.7 µs | 321.3 µs | -15.5% |
| inspector.extreme/compose/teardown | 2.15 ms | 2.93 ms | -16.9% |
| inspector.extreme/memory/mounted | 17367 KiB | 17367 KiB | +0.0% |
| inspector.extreme/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| inspector.extreme/plain/burst | 1.16 ms | 1.55 ms | -18.8% |
| inspector.extreme/plain/cold | 6.21 ms | 8.67 ms | -20.7% |
| inspector.extreme/plain/settle | 0.8 µs | 1.3 µs | +16.9% |
| inspector.extreme/plain/steady | 51.7 µs | 82.0 µs | -21.3% |
| inspector.extreme/plain/teardown | 4.34 ms | 4.96 ms | -14.0% |
| inspector.large/compose/burst | 4.23 ms | 5.60 ms | +29.5% |
| inspector.large/compose/cold | 9.64 ms | 12.25 ms | +60.7% |
| inspector.large/compose/counts | 18.25 ms | 18.25 ms | +15.2% |
| inspector.large/compose/settle | 1.2 µs | 1.7 µs | +63.1% |
| inspector.large/compose/steady | 255.0 µs | 331.1 µs | +37.9% |
| inspector.large/compose/teardown | 1.29 ms | 1.54 ms | +37.3% |
| inspector.large/memory/mounted | 6189 KiB | 6189 KiB | -0.1% |
| inspector.large/memory/teardown | 1 KiB | 1 KiB | — |
| inspector.large/plain/burst | 847.5 µs | 1.07 ms | +47.2% |
| inspector.large/plain/cold | 2.93 ms | 7.12 ms | +14.6% |
| inspector.large/plain/settle | 0.9 µs | 1.3 µs | +85.7% |
| inspector.large/plain/steady | 70.3 µs | 98.8 µs | +40.8% |
| inspector.large/plain/teardown | 1.68 ms | 1.98 ms | +13.1% |
| inspector.medium/compose/burst | 1.46 ms | 1.72 ms | +124.1% |
| inspector.medium/compose/cold | 2.12 ms | 2.97 ms | +95.3% |
| inspector.medium/compose/counts | 5.47 ms | 5.47 ms | +133.4% |
| inspector.medium/compose/settle | 0.6 µs | 0.8 µs | +68.7% |
| inspector.medium/compose/steady | 207.3 µs | 230.3 µs | +105.0% |
| inspector.medium/compose/teardown | 391.0 µs | 515.7 µs | +113.6% |
| inspector.medium/memory/mounted | 1792 KiB | 1792 KiB | +0.1% |
| inspector.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| inspector.medium/plain/burst | 272.2 µs | 354.3 µs | +111.8% |
| inspector.medium/plain/cold | 956.2 µs | 2.46 ms | +57.1% |
| inspector.medium/plain/settle | 0.5 µs | 0.6 µs | +117.1% |
| inspector.medium/plain/steady | 60.2 µs | 75.6 µs | +94.0% |
| inspector.medium/plain/teardown | 329.8 µs | 540.6 µs | +60.2% |
| keyed-append/compose | 1.12 ms | 1.38 ms | -7.9% |
| keyed-append/memory/mounted | 2261 KiB | 2261 KiB | +0.0% |
| keyed-append/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-append/plain | 1.33 ms | 1.98 ms | -5.8% |
| keyed-insert/compose | 1.39 ms | 1.69 ms | -2.1% |
| keyed-insert/memory/mounted | 2265 KiB | 2265 KiB | +0.0% |
| keyed-insert/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-insert/plain | 789.3 µs | 978.2 µs | -11.4% |
| keyed-prepend/compose | 2.32 ms | 2.56 ms | -30.4% |
| keyed-prepend/memory/mounted | 2261 KiB | 2261 KiB | +0.0% |
| keyed-prepend/memory/teardown | 8 KiB | 8 KiB | — |
| keyed-prepend/plain | 1.01 ms | 1.27 ms | -23.3% |
| keyed-remove/compose | 2.55 ms | 2.86 ms | +39.0% |
| keyed-remove/memory/mounted | 2260 KiB | 2260 KiB | +0.0% |
| keyed-remove/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-remove/plain | 1.47 ms | 1.87 ms | +40.3% |
| keyed-replace/compose | 52.08 ms | 58.08 ms | -8.0% |
| keyed-replace/memory/mounted | 2288 KiB | 2288 KiB | +0.4% |
| keyed-replace/memory/teardown | 8 KiB | 8 KiB | — |
| keyed-replace/plain | 29.03 ms | 33.58 ms | -3.4% |
| keyed-reverse/compose | 1.33 ms | 1.41 ms | -2.7% |
| keyed-reverse/memory/mounted | 2256 KiB | 2256 KiB | -0.4% |
| keyed-reverse/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-reverse/plain | 639.5 µs | 716.2 µs | -1.7% |
| keyed-rotate/compose | 2.92 ms | 3.21 ms | +2.9% |
| keyed-rotate/memory/mounted | 2265 KiB | 2265 KiB | +0.0% |
| keyed-rotate/memory/teardown | 1 KiB | 1 KiB | -87.5% |
| keyed-rotate/plain | 1.23 ms | 1.39 ms | -0.0% |
| keyed-shuffle/compose | 3.13 ms | 3.39 ms | +134.3% |
| keyed-shuffle/memory/mounted | 2264 KiB | 2264 KiB | -0.4% |
| keyed-shuffle/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-shuffle/plain | 1.37 ms | 1.51 ms | +115.8% |
| mount-cycles/compose | 23.04 ms | 25.42 ms | -7.6% |
| mount-cycles/memory/mounted | 513 KiB | 513 KiB | — |
| mount-cycles/memory/teardown | 505 KiB | 505 KiB | +50400.0% |
| mount-cycles/plain | 16.10 ms | 19.41 ms | -10.8% |
| mount-dispose/compose | 9.58 ms | 13.41 ms | +35.4% |
| mount-dispose/memory/mounted | 0 KiB | 0 KiB | — |
| mount-dispose/memory/teardown | 0 KiB | 0 KiB | — |
| mount-dispose/plain | 8.65 ms | 11.73 ms | +42.6% |
| ordered-window-scroll/compose | 498.2 µs | 533.0 µs | +20.9% |
| ordered-window-scroll/memory/mounted | 1129 KiB | 1129 KiB | +1.4% |
| ordered-window-scroll/memory/teardown | 8 KiB | 8 KiB | — |
| projection-keyed-append-500/compose | 14.07 ms | 15.52 ms | +144.5% |
| projection-keyed-append-500/memory/mounted | 3192 KiB | 3192 KiB | -0.0% |
| projection-keyed-append-500/memory/teardown | 0 KiB | 0 KiB | — |
| projection-keyed-append-500/plain | 2.21 ms | 2.74 ms | +22.2% |
| projection-observe-100/compose | 1.69 ms | 1.80 ms | +45.5% |
| projection-observe-100/memory/mounted | 74 KiB | 74 KiB | +0.0% |
| projection-observe-100/memory/teardown | 1 KiB | 1 KiB | — |
| projection-selection-500/compose | 1.26 ms | 1.30 ms | -6.7% |
| projection-selection-500/memory/mounted | 4068 KiB | 4068 KiB | -0.2% |
| projection-selection-500/memory/teardown | 0 KiB | 0 KiB | — |
| projection-selection-500/plain | 178.7 µs | 196.4 µs | -2.2% |
| scene-2d.extreme/compose/burst | 26.43 ms | 34.08 ms | -16.3% |
| scene-2d.extreme/compose/cold | 9.88 ms | 21.49 ms | -10.9% |
| scene-2d.extreme/compose/counts | 186.17 ms | 186.17 ms | -13.8% |
| scene-2d.extreme/compose/settle | 1.2 µs | 1.4 µs | -47.3% |
| scene-2d.extreme/compose/steady | 84.42 ms | 91.84 ms | -6.2% |
| scene-2d.extreme/compose/teardown | 991.8 µs | 1.11 ms | -20.2% |
| scene-2d.extreme/memory/mounted | 9672 KiB | 9672 KiB | +0.1% |
| scene-2d.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| scene-2d.extreme/plain/burst | 9.02 ms | 12.62 ms | -17.8% |
| scene-2d.extreme/plain/cold | 1.48 ms | 2.63 ms | -7.1% |
| scene-2d.extreme/plain/settle | 0.9 µs | 1.3 µs | -57.6% |
| scene-2d.extreme/plain/steady | 47.80 ms | 56.28 ms | -0.5% |
| scene-2d.extreme/plain/teardown | 471.9 µs | 647.1 µs | -23.1% |
| scene-2d.large/compose/burst | 30.94 ms | 40.32 ms | +33.9% |
| scene-2d.large/compose/cold | 6.21 ms | 13.83 ms | +42.7% |
| scene-2d.large/compose/counts | 189.24 ms | 189.24 ms | +25.5% |
| scene-2d.large/compose/settle | 1.9 µs | 3.4 µs | +52.5% |
| scene-2d.large/compose/steady | 92.26 ms | 99.85 ms | +36.0% |
| scene-2d.large/compose/teardown | 1.50 ms | 1.79 ms | +79.1% |
| scene-2d.large/memory/mounted | 4047 KiB | 4047 KiB | -0.2% |
| scene-2d.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| scene-2d.large/plain/burst | 9.94 ms | 17.76 ms | +62.0% |
| scene-2d.large/plain/cold | 1.68 ms | 5.64 ms | +34.0% |
| scene-2d.large/plain/settle | 2.1 µs | 2.8 µs | +83.4% |
| scene-2d.large/plain/steady | 49.65 ms | 53.15 ms | +35.6% |
| scene-2d.large/plain/teardown | 662.3 µs | 963.9 µs | +58.0% |
| scene-2d.medium/compose/burst | 15.43 ms | 18.74 ms | -24.2% |
| scene-2d.medium/compose/cold | 4.30 ms | 4.55 ms | -8.8% |
| scene-2d.medium/compose/counts | 136.90 ms | 136.90 ms | -7.3% |
| scene-2d.medium/compose/settle | 0.8 µs | 0.9 µs | -62.0% |
| scene-2d.medium/compose/steady | 65.75 ms | 67.88 ms | -5.0% |
| scene-2d.medium/compose/teardown | 734.4 µs | 772.5 µs | -30.3% |
| scene-2d.medium/memory/mounted | 2274 KiB | 2274 KiB | +0.4% |
| scene-2d.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| scene-2d.medium/plain/burst | 5.26 ms | 7.55 ms | -13.9% |
| scene-2d.medium/plain/cold | 1.42 ms | 2.21 ms | -29.7% |
| scene-2d.medium/plain/settle | 0.8 µs | 1.0 µs | -64.3% |
| scene-2d.medium/plain/steady | 36.64 ms | 38.25 ms | -4.6% |
| scene-2d.medium/plain/teardown | 353.2 µs | 467.1 µs | -34.2% |
| scene-3d/compose | 7.65 ms | 8.32 ms | -23.9% |
| scene-3d/memory/mounted | 1286 KiB | 1286 KiB | +0.6% |
| scene-3d/memory/teardown | 0 KiB | 0 KiB | — |
| scene-3d/plain | 3.52 ms | 4.37 ms | -17.9% |
| session-cycle.extreme/compose/burst | 145.08 ms | 190.95 ms | +30.2% |
| session-cycle.extreme/compose/cold | 4.2 µs | 11.4 µs | -4.6% |
| session-cycle.extreme/compose/counts | 331.55 ms | 331.55 ms | -4.7% |
| session-cycle.extreme/compose/settle | 2.2 µs | 2.5 µs | -0.9% |
| session-cycle.extreme/compose/steady | 170.05 ms | 264.15 ms | -10.2% |
| session-cycle.extreme/compose/teardown | 1.9 µs | 2.2 µs | -16.2% |
| session-cycle.extreme/memory/mounted | 10 KiB | 10 KiB | +0.0% |
| session-cycle.extreme/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| session-cycle.extreme/plain/burst | 156.10 ms | 173.90 ms | +11.3% |
| session-cycle.extreme/plain/cold | 4.1 µs | 6.2 µs | -9.9% |
| session-cycle.extreme/plain/settle | 2.3 µs | 2.9 µs | -14.0% |
| session-cycle.extreme/plain/steady | 177.88 ms | 249.30 ms | -5.6% |
| session-cycle.extreme/plain/teardown | 2.1 µs | 2.5 µs | -15.3% |
| session-cycle.large/compose/burst | 41.68 ms | 70.93 ms | -24.9% |
| session-cycle.large/compose/cold | 3.4 µs | 6.4 µs | -18.2% |
| session-cycle.large/compose/counts | 127.28 ms | 127.28 ms | -16.8% |
| session-cycle.large/compose/settle | 1.9 µs | 2.6 µs | -1.1% |
| session-cycle.large/compose/steady | 67.59 ms | 92.42 ms | -3.7% |
| session-cycle.large/compose/teardown | 1.7 µs | 2.1 µs | -10.3% |
| session-cycle.large/memory/mounted | 2 KiB | 2 KiB | +0.0% |
| session-cycle.large/memory/teardown | 0 KiB | 0 KiB | — |
| session-cycle.large/plain/burst | 50.69 ms | 62.97 ms | -3.5% |
| session-cycle.large/plain/cold | 3.9 µs | 17.8 µs | -31.7% |
| session-cycle.large/plain/settle | 1.6 µs | 2.8 µs | -28.8% |
| session-cycle.large/plain/steady | 55.49 ms | 75.28 ms | -10.5% |
| session-cycle.large/plain/teardown | 1.5 µs | 2.3 µs | -17.3% |
| session-cycle.medium/compose/burst | 16.12 ms | 24.16 ms | +71.1% |
| session-cycle.medium/compose/cold | 4.7 µs | 6.7 µs | +61.5% |
| session-cycle.medium/compose/counts | 44.74 ms | 44.74 ms | +38.2% |
| session-cycle.medium/compose/settle | 1.5 µs | 1.9 µs | +30.5% |
| session-cycle.medium/compose/steady | 22.42 ms | 32.96 ms | +33.2% |
| session-cycle.medium/compose/teardown | 1.7 µs | 2.2 µs | +40.5% |
| session-cycle.medium/memory/mounted | 0 KiB | 0 KiB | -100.0% |
| session-cycle.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| session-cycle.medium/plain/burst | 10.43 ms | 15.45 ms | +24.8% |
| session-cycle.medium/plain/cold | 4.3 µs | 6.3 µs | +70.8% |
| session-cycle.medium/plain/settle | 1.5 µs | 2.5 µs | +44.8% |
| session-cycle.medium/plain/steady | 21.28 ms | 26.72 ms | +44.7% |
| session-cycle.medium/plain/teardown | 1.7 µs | 2.0 µs | +95.5% |
| spatial-scene.extreme/compose/burst | 122.41 ms | 133.59 ms | -7.0% |
| spatial-scene.extreme/compose/cold | 10.75 ms | 22.93 ms | -4.6% |
| spatial-scene.extreme/compose/counts | 255.50 ms | 255.50 ms | -8.8% |
| spatial-scene.extreme/compose/settle | 1.7 µs | 15.5 µs | -0.1% |
| spatial-scene.extreme/compose/steady | 53.20 ms | 58.63 ms | -3.2% |
| spatial-scene.extreme/compose/teardown | 3.23 ms | 4.25 ms | -23.0% |
| spatial-scene.extreme/memory/mounted | 5284 KiB | 5284 KiB | -0.0% |
| spatial-scene.extreme/memory/teardown | 8 KiB | 8 KiB | -11.1% |
| spatial-scene.extreme/plain/burst | 49.84 ms | 62.92 ms | -11.8% |
| spatial-scene.extreme/plain/cold | 3.34 ms | 5.28 ms | -15.7% |
| spatial-scene.extreme/plain/settle | 1.7 µs | 2.3 µs | -26.2% |
| spatial-scene.extreme/plain/steady | 77.24 ms | 84.35 ms | +0.1% |
| spatial-scene.extreme/plain/teardown | 1.22 ms | 1.33 ms | -18.2% |
| spatial-scene.large/compose/burst | 36.91 ms | 44.83 ms | +48.5% |
| spatial-scene.large/compose/cold | 4.65 ms | 6.30 ms | +37.6% |
| spatial-scene.large/compose/counts | 74.02 ms | 74.02 ms | +47.7% |
| spatial-scene.large/compose/settle | 1.9 µs | 2.7 µs | +57.9% |
| spatial-scene.large/compose/steady | 19.45 ms | 23.97 ms | +51.9% |
| spatial-scene.large/compose/teardown | 862.7 µs | 1.64 ms | +35.7% |
| spatial-scene.large/memory/mounted | 1750 KiB | 1750 KiB | -0.5% |
| spatial-scene.large/memory/teardown | 0 KiB | 0 KiB | — |
| spatial-scene.large/plain/burst | 17.77 ms | 22.56 ms | +70.4% |
| spatial-scene.large/plain/cold | 1.27 ms | 2.98 ms | +50.4% |
| spatial-scene.large/plain/settle | 2.1 µs | 2.8 µs | +98.2% |
| spatial-scene.large/plain/steady | 23.65 ms | 32.06 ms | +60.8% |
| spatial-scene.large/plain/teardown | 375.9 µs | 983.6 µs | +63.3% |
| spatial-scene.medium/compose/burst | 7.47 ms | 8.92 ms | -0.3% |
| spatial-scene.medium/compose/cold | 682.2 µs | 1.31 ms | -6.9% |
| spatial-scene.medium/compose/counts | 16.09 ms | 16.09 ms | -4.1% |
| spatial-scene.medium/compose/settle | 0.7 µs | 1.1 µs | -22.3% |
| spatial-scene.medium/compose/steady | 4.43 ms | 5.22 ms | -3.1% |
| spatial-scene.medium/compose/teardown | 145.7 µs | 237.6 µs | -9.3% |
| spatial-scene.medium/memory/mounted | 690 KiB | 690 KiB | +0.0% |
| spatial-scene.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| spatial-scene.medium/plain/burst | 3.67 ms | 5.50 ms | +20.2% |
| spatial-scene.medium/plain/cold | 296.2 µs | 1.24 ms | -0.0% |
| spatial-scene.medium/plain/settle | 0.7 µs | 1.4 µs | -6.7% |
| spatial-scene.medium/plain/steady | 4.69 ms | 5.35 ms | -4.4% |
| spatial-scene.medium/plain/teardown | 66.6 µs | 145.1 µs | -16.6% |
| status-panel/compose | 546.6 µs | 576.2 µs | -8.1% |
| status-panel/memory/mounted | 35 KiB | 35 KiB | +0.0% |
| status-panel/memory/teardown | 0 KiB | 0 KiB | — |
| status-panel/plain | 122.9 µs | 165.3 µs | +4.3% |
| unwind/compose | 3.90 ms | 7.00 ms | -11.5% |
| unwind/memory/mounted | 1 KiB | 1 KiB | +0.0% |
| unwind/memory/teardown | 0 KiB | 0 KiB | — |
| unwind/plain | 2.97 ms | 4.20 ms | -39.8% |
| update-batched/compose | 2.93 ms | 3.33 ms | -3.2% |
| update-batched/memory/mounted | 1868 KiB | 1868 KiB | +0.0% |
| update-batched/memory/teardown | 0 KiB | 0 KiB | — |
| update-batched/plain | 1.04 ms | 1.08 ms | +1.8% |
| update-fanout/compose | 1.63 ms | 1.71 ms | +109.6% |
| update-fanout/memory/mounted | 1812 KiB | 1812 KiB | +0.0% |
| update-fanout/memory/teardown | 0 KiB | 0 KiB | — |
| update-fanout/plain | 1.07 ms | 1.08 ms | +123.4% |
| update-leaf/compose | 23.3 µs | 25.7 µs | -30.8% |
| update-leaf/memory/mounted | 2739 KiB | 2739 KiB | -0.6% |
| update-leaf/memory/teardown | 0 KiB | 0 KiB | — |
| update-leaf/plain | 10.3 µs | 15.1 µs | -23.0% |
| update-repeated/compose | 288.2 µs | 322.8 µs | -1.3% |
| update-repeated/memory/mounted | 18 KiB | 18 KiB | +0.0% |
| update-repeated/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| update-repeated/plain | 38.2 µs | 44.0 µs | +1.3% |
| virtual-filtered-list.extreme/compose/burst | 855.12 ms | 937.14 ms | +82.6% |
| virtual-filtered-list.extreme/compose/cold | 494.93 ms | 590.39 ms | +63.0% |
| virtual-filtered-list.extreme/compose/counts | 1513.83 ms | 1513.83 ms | +99.5% |
| virtual-filtered-list.extreme/compose/settle | 2.4 µs | 2.7 µs | -6.7% |
| virtual-filtered-list.extreme/compose/steady | 15.83 ms | 19.95 ms | +94.0% |
| virtual-filtered-list.extreme/compose/teardown | 510.6 µs | 704.6 µs | +51.3% |
| virtual-filtered-list.extreme/memory/mounted | 27910 KiB | 27910 KiB | +0.0% |
| virtual-filtered-list.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| virtual-filtered-list.extreme/plain/burst | 863.64 ms | 901.52 ms | +91.8% |
| virtual-filtered-list.extreme/plain/cold | 555.07 ms | 586.09 ms | +95.9% |
| virtual-filtered-list.extreme/plain/settle | 2.9 µs | 3.4 µs | +7.9% |
| virtual-filtered-list.extreme/plain/steady | 11.23 ms | 12.96 ms | +68.3% |
| virtual-filtered-list.extreme/plain/teardown | 217.1 µs | 269.9 µs | +30.2% |
| virtual-filtered-list.large/compose/burst | 85.51 ms | 93.65 ms | -17.3% |
| virtual-filtered-list.large/compose/cold | 50.14 ms | 55.01 ms | -15.5% |
| virtual-filtered-list.large/compose/counts | 152.51 ms | 152.51 ms | -19.7% |
| virtual-filtered-list.large/compose/settle | 2.6 µs | 3.6 µs | +12.6% |
| virtual-filtered-list.large/compose/steady | 9.92 ms | 12.01 ms | -18.0% |
| virtual-filtered-list.large/compose/teardown | 240.8 µs | 325.0 µs | -8.3% |
| virtual-filtered-list.large/memory/mounted | 6305 KiB | 6305 KiB | +0.0% |
| virtual-filtered-list.large/memory/teardown | 9 KiB | 9 KiB | +0.0% |
| virtual-filtered-list.large/plain/burst | 74.05 ms | 80.40 ms | -16.6% |
| virtual-filtered-list.large/plain/cold | 46.69 ms | 52.33 ms | -17.0% |
| virtual-filtered-list.large/plain/settle | 2.9 µs | 3.3 µs | +27.1% |
| virtual-filtered-list.large/plain/steady | 5.64 ms | 6.89 ms | +2.3% |
| virtual-filtered-list.large/plain/teardown | 77.5 µs | 127.6 µs | -11.0% |
| virtual-filtered-list.medium/compose/burst | 25.51 ms | 31.21 ms | +43.0% |
| virtual-filtered-list.medium/compose/cold | 13.48 ms | 16.40 ms | +43.1% |
| virtual-filtered-list.medium/compose/counts | 61.20 ms | 61.20 ms | +38.9% |
| virtual-filtered-list.medium/compose/settle | 1.7 µs | 2.8 µs | +76.7% |
| virtual-filtered-list.medium/compose/steady | 12.33 ms | 20.50 ms | +35.9% |
| virtual-filtered-list.medium/compose/teardown | 199.8 µs | 237.2 µs | +43.1% |
| virtual-filtered-list.medium/memory/mounted | 1609 KiB | 1609 KiB | -0.1% |
| virtual-filtered-list.medium/memory/teardown | 9 KiB | 9 KiB | +0.0% |
| virtual-filtered-list.medium/plain/burst | 20.06 ms | 22.29 ms | +41.8% |
| virtual-filtered-list.medium/plain/cold | 11.80 ms | 12.87 ms | +36.0% |
| virtual-filtered-list.medium/plain/settle | 1.7 µs | 2.9 µs | +90.0% |
| virtual-filtered-list.medium/plain/steady | 5.29 ms | 9.31 ms | +12.5% |
| virtual-filtered-list.medium/plain/teardown | 63.3 µs | 96.4 µs | +35.0% |

## Trends over the last 2 main commits

```mermaid
xychart-beta
    title "animate-many/compose (median µs)"
    x-axis 1 --> 2
    line [3066.4, 6952.0]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [6516.1, 4147.1]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [11407.1, 8355.0]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [68091.2, 47605.1]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.0, 1.0]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [25890.3, 17137.2]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [2475.2, 1994.0]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [3896.2, 3809.1]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [5692.2, 5515.9]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [57607.9, 56296.6]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.2, 0.8]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [26697.4, 26221.7]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1432.5, 1092.3]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [598.2, 606.3]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [1178.6, 1128.0]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [10635.9, 10387.5]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.3, 0.4]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [4717.9, 4534.1]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [212.7, 211.0]
```

```mermaid
xychart-beta
    title "branch-swap/compose (median µs)"
    x-axis 1 --> 2
    line [3609.5, 2319.6]
```

```mermaid
xychart-beta
    title "cold-mount-100/compose (median µs)"
    x-axis 1 --> 2
    line [592.6, 519.9]
```

```mermaid
xychart-beta
    title "cold-mount-1000/compose (median µs)"
    x-axis 1 --> 2
    line [8085.8, 5389.9]
```

```mermaid
xychart-beta
    title "cold-mount-10000/compose (median µs)"
    x-axis 1 --> 2
    line [73945.7, 98256.1]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [572777.3, 535083.2]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [350893.5, 328646.9]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [961903.0, 895177.9]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.8, 2.4]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [12594.0, 11681.8]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1086.6, 1137.9]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [140083.3, 135962.2]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [80791.9, 79866.7]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [269572.2, 259528.8]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.0, 2.0]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [17382.0, 15842.8]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [517.4, 507.1]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [49689.5, 40264.0]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [28216.2, 22726.8]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [101676.4, 85010.8]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.2, 2.3]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [12139.2, 8725.2]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [242.3, 222.0]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [8748.3, 13808.9]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [306.9, 503.4]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [12107.6, 25337.6]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.6, 1.1]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [461.4, 853.9]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [300.0, 528.8]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [7315.2, 6455.4]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [321.9, 311.0]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [15457.3, 15616.4]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.9, 0.8]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [871.8, 849.7]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [255.7, 242.4]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [1884.9, 1716.2]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [150.8, 125.0]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [4488.4, 3035.8]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.6, 0.4]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [451.5, 440.8]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [71.1, 68.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [36450.3, 44418.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [22317.0, 30608.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [157183.8, 226408.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.5, 2.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [38679.7, 58936.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [870.1, 1178.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [13822.3, 12671.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [8768.9, 8903.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [56991.3, 49197.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.0, 2.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [16083.5, 12191.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [346.1, 297.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [4810.6, 5385.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [3510.0, 3688.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [22176.2, 21779.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.9, 1.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [5091.1, 4800.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [138.2, 141.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [37375.3, 42100.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [28909.8, 26506.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [312089.2, 264728.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.6, 2.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [144362.2, 138910.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1011.3, 1046.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [11392.1, 16006.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [10645.8, 12312.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [86389.6, 118638.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.5, 2.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [40309.4, 56606.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [312.8, 448.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [8485.7, 8733.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [5123.1, 5090.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [60621.5, 66177.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.3, 1.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [22448.9, 25049.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [239.6, 252.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [51119.4, 42743.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [31173.0, 29216.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [276895.4, 231546.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.3, 2.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [103496.4, 98719.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1459.8, 1163.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [9662.4, 8486.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [7331.9, 8413.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [62489.1, 65083.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.6, 1.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [17762.3, 18587.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [221.0, 244.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [5597.4, 5043.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [4098.3, 3677.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [31911.5, 26270.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.0, 1.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [10781.6, 9751.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [163.7, 158.3]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [18098.0, 16855.7]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [102015.1, 100238.6]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [358907.4, 324615.1]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.8, 1.9]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [90630.1, 81412.5]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [52871.1, 45496.4]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [9879.6, 9266.1]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [42924.1, 40697.9]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [159260.0, 136585.0]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.1, 1.5]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [56879.3, 47700.5]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [16802.1, 13908.2]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [4273.0, 4064.7]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [14214.0, 12986.0]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [60159.0, 56773.8]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.9, 1.7]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [20781.1, 19484.3]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [5912.5, 5137.9]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [82088.2, 67803.4]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [23851.0, 19385.3]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [215972.6, 170155.4]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.5, 2.9]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [46499.2, 63403.0]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [13254.3, 13259.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [23829.2, 21410.5]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [9046.6, 8698.0]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [66263.4, 60081.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.2, 2.3]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [15970.8, 12947.8]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [3313.5, 2966.7]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [10053.5, 13258.0]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [4425.1, 5999.0]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [26589.7, 40004.4]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.0, 1.5]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [6593.9, 10265.5]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [909.1, 1375.7]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [83025.5, 131890.1]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [27112.7, 32898.9]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [297306.3, 392730.6]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.9, 2.5]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [104435.7, 129482.8]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [11409.1, 14374.0]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [37687.9, 36619.3]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [9427.2, 7416.6]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [118464.0, 105642.9]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.0, 2.4]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [36383.7, 29649.6]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [3319.5, 3173.8]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [21304.8, 17609.9]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [5522.9, 4875.0]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [73432.0, 63426.8]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.9, 1.0]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [21627.0, 18049.0]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1421.5, 998.7]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [28431.3, 29661.9]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [25491.4, 23933.9]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [103374.1, 95880.0]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.8, 1.9]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [4152.6, 3939.8]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [12752.1, 12268.9]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [12559.3, 12285.7]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [10065.7, 12236.3]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [47228.6, 41552.7]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.2, 1.3]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [1880.4, 1925.6]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [3848.1, 4042.8]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [2692.8, 4883.0]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [3511.6, 5344.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [11899.6, 20010.0]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.8, 0.8]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [546.9, 864.1]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [793.8, 1245.8]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [38306.7, 27292.5]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [26392.1, 25728.0]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [146562.2, 118482.8]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.1, 1.2]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [35077.9, 31134.3]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [14166.4, 14892.9]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [16371.6, 13675.4]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [13125.5, 12164.0]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [71347.2, 67401.3]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.8, 1.6]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [17130.8, 15636.5]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [4985.7, 4474.5]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [5454.2, 5016.4]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [6039.1, 4145.2]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [27680.1, 23447.7]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.2, 0.8]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [6474.9, 6388.6]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1477.1, 1273.6]
```

```mermaid
xychart-beta
    title "events/compose (median µs)"
    x-axis 1 --> 2
    line [10464.1, 9121.0]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [7448.2, 5545.2]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [18874.4, 15878.8]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [34335.8, 23488.3]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.6, 1.4]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [245.7, 207.7]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [2590.5, 2153.7]
```

```mermaid
xychart-beta
    title "inspector.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [3270.5, 4234.2]
```

```mermaid
xychart-beta
    title "inspector.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [6003.2, 9644.5]
```

```mermaid
xychart-beta
    title "inspector.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [15848.8, 18252.6]
```

```mermaid
xychart-beta
    title "inspector.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.8, 1.2]
```

```mermaid
xychart-beta
    title "inspector.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [184.9, 255.0]
```

```mermaid
xychart-beta
    title "inspector.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [939.1, 1289.4]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [652.7, 1463.0]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [1084.4, 2117.8]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [2345.3, 5474.4]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.4, 0.6]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [101.1, 207.3]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [183.0, 391.0]
```

```mermaid
xychart-beta
    title "keyed-append/compose (median µs)"
    x-axis 1 --> 2
    line [1217.7, 1121.3]
```

```mermaid
xychart-beta
    title "keyed-insert/compose (median µs)"
    x-axis 1 --> 2
    line [1418.3, 1388.8]
```

```mermaid
xychart-beta
    title "keyed-prepend/compose (median µs)"
    x-axis 1 --> 2
    line [3339.2, 2323.0]
```

```mermaid
xychart-beta
    title "keyed-remove/compose (median µs)"
    x-axis 1 --> 2
    line [1834.7, 2550.5]
```

```mermaid
xychart-beta
    title "keyed-replace/compose (median µs)"
    x-axis 1 --> 2
    line [56638.2, 52082.4]
```

```mermaid
xychart-beta
    title "keyed-reverse/compose (median µs)"
    x-axis 1 --> 2
    line [1366.2, 1329.2]
```

```mermaid
xychart-beta
    title "keyed-rotate/compose (median µs)"
    x-axis 1 --> 2
    line [2837.0, 2918.3]
```

```mermaid
xychart-beta
    title "keyed-shuffle/compose (median µs)"
    x-axis 1 --> 2
    line [1337.6, 3134.0]
```

```mermaid
xychart-beta
    title "mount-cycles/compose (median µs)"
    x-axis 1 --> 2
    line [24941.5, 23043.1]
```

```mermaid
xychart-beta
    title "mount-dispose/compose (median µs)"
    x-axis 1 --> 2
    line [7076.9, 9579.0]
```

```mermaid
xychart-beta
    title "ordered-window-scroll/compose (median µs)"
    x-axis 1 --> 2
    line [412.1, 498.2]
```

```mermaid
xychart-beta
    title "projection-keyed-append-500/compose (median µs)"
    x-axis 1 --> 2
    line [5754.2, 14069.9]
```

```mermaid
xychart-beta
    title "projection-observe-100/compose (median µs)"
    x-axis 1 --> 2
    line [1160.9, 1688.5]
```

```mermaid
xychart-beta
    title "projection-selection-500/compose (median µs)"
    x-axis 1 --> 2
    line [1347.5, 1257.8]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [31592.1, 26430.2]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [11079.4, 9876.1]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [216069.1, 186166.0]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.2, 1.2]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [90044.4, 84419.8]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1242.8, 991.8]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [23109.8, 30942.5]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [4352.7, 6212.1]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [150813.2, 189240.1]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.3, 1.9]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [67819.6, 92259.3]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [835.3, 1495.8]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [20349.9, 15428.8]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [4709.8, 4295.8]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [147623.1, 136904.9]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.2, 0.8]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [69181.6, 65753.4]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1053.9, 734.4]
```

```mermaid
xychart-beta
    title "scene-3d/compose (median µs)"
    x-axis 1 --> 2
    line [10050.2, 7649.9]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [111388.5, 145081.3]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [4.4, 4.2]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [347844.7, 331552.2]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.2, 2.2]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [189371.2, 170051.3]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [2.3, 1.9]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [55471.8, 41682.9]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [4.1, 3.4]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [152922.2, 127280.8]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.9, 1.9]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [70217.2, 67586.5]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1.9, 1.7]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [9419.6, 16119.8]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [2.9, 4.7]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [32366.0, 44739.0]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.2, 1.5]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [16834.7, 22422.0]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1.2, 1.7]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [131626.4, 122408.9]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [11274.4, 10752.6]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [280294.2, 255499.9]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.7, 1.7]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [54938.1, 53195.1]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [4193.8, 3229.5]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [24854.0, 36908.9]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [3382.2, 4654.1]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [50109.8, 74015.2]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.2, 1.9]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [12804.6, 19446.0]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [635.6, 862.7]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [7485.6, 7465.0]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [732.5, 682.2]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [16776.7, 16094.7]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.9, 0.7]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [4566.2, 4426.4]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [160.7, 145.7]
```

```mermaid
xychart-beta
    title "status-panel/compose (median µs)"
    x-axis 1 --> 2
    line [594.8, 546.6]
```

```mermaid
xychart-beta
    title "unwind/compose (median µs)"
    x-axis 1 --> 2
    line [4404.4, 3896.7]
```

```mermaid
xychart-beta
    title "update-batched/compose (median µs)"
    x-axis 1 --> 2
    line [3025.0, 2927.0]
```

```mermaid
xychart-beta
    title "update-fanout/compose (median µs)"
    x-axis 1 --> 2
    line [777.2, 1629.0]
```

```mermaid
xychart-beta
    title "update-leaf/compose (median µs)"
    x-axis 1 --> 2
    line [33.7, 23.3]
```

```mermaid
xychart-beta
    title "update-repeated/compose (median µs)"
    x-axis 1 --> 2
    line [291.8, 288.2]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [468218.5, 855118.6]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [303705.7, 494927.2]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [758775.9, 1513830.2]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.5, 2.4]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [8156.9, 15826.4]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [337.4, 510.6]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [103439.2, 85508.3]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [59355.8, 50136.7]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [189934.0, 152506.8]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.3, 2.6]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [12089.3, 9916.3]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [262.7, 240.8]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [17844.8, 25511.5]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [9422.5, 13481.1]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [44077.6, 61203.3]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.0, 1.7]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [9077.3, 12332.6]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [139.6, 199.8]
```
