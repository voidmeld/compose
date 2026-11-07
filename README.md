# Compose performance

Latest: `7de7928ccb462a03e0af7b8407b3c53262fc0a4d` on 2026-11-07T015518Z, measured on the CI Ubuntu runner by the paired performance shards.
Each value is the median of the candidate arm's samples; p95 is shown beside it. Change compares the previous main commit.

| Benchmark | Median | p95 | Change |
| --- | --- | --- | --- |
| animate-many/compose | 6.86 ms | 6.98 ms | +0.0% |
| animate-many/memory/mounted | 2208 KiB | 2208 KiB | +0.0% |
| animate-many/memory/teardown | 9 KiB | 9 KiB | +800.0% |
| animate-many/plain | 1.69 ms | 1.73 ms | +2.8% |
| animated-navigation.extreme/compose/burst | 6.45 ms | 6.67 ms | -19.9% |
| animated-navigation.extreme/compose/cold | 9.12 ms | 14.74 ms | -21.4% |
| animated-navigation.extreme/compose/counts | 66.07 ms | 66.07 ms | -21.7% |
| animated-navigation.extreme/compose/settle | 0.8 µs | 1.0 µs | -29.7% |
| animated-navigation.extreme/compose/steady | 25.91 ms | 26.45 ms | -21.9% |
| animated-navigation.extreme/compose/teardown | 2.22 ms | 2.59 ms | -23.5% |
| animated-navigation.extreme/memory/mounted | 6871 KiB | 6871 KiB | +0.0% |
| animated-navigation.extreme/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| animated-navigation.extreme/plain/burst | 1.05 ms | 1.11 ms | -27.0% |
| animated-navigation.extreme/plain/cold | 3.99 ms | 7.03 ms | -22.0% |
| animated-navigation.extreme/plain/settle | 0.7 µs | 1.1 µs | -41.2% |
| animated-navigation.extreme/plain/steady | 13.62 ms | 13.80 ms | -29.4% |
| animated-navigation.extreme/plain/teardown | 3.00 ms | 3.22 ms | -20.5% |
| animated-navigation.large/compose/burst | 3.95 ms | 4.12 ms | +114.0% |
| animated-navigation.large/compose/cold | 5.50 ms | 9.69 ms | +32.4% |
| animated-navigation.large/compose/counts | 62.96 ms | 62.96 ms | +117.4% |
| animated-navigation.large/compose/settle | 0.7 µs | 1.3 µs | -7.5% |
| animated-navigation.large/compose/steady | 27.19 ms | 28.09 ms | +124.8% |
| animated-navigation.large/compose/teardown | 1.26 ms | 1.38 ms | +96.3% |
| animated-navigation.large/memory/mounted | 3451 KiB | 3451 KiB | +0.0% |
| animated-navigation.large/memory/teardown | 0 KiB | 0 KiB | — |
| animated-navigation.large/plain/burst | 703.2 µs | 723.3 µs | +109.4% |
| animated-navigation.large/plain/cold | 2.25 ms | 3.90 ms | +68.7% |
| animated-navigation.large/plain/settle | 0.5 µs | 0.6 µs | +60.9% |
| animated-navigation.large/plain/steady | 9.15 ms | 9.23 ms | +102.5% |
| animated-navigation.large/plain/teardown | 1.07 ms | 1.33 ms | +46.7% |
| animated-navigation.medium/compose/burst | 994.6 µs | 1.09 ms | -24.9% |
| animated-navigation.medium/compose/cold | 1.31 ms | 2.18 ms | -20.6% |
| animated-navigation.medium/compose/counts | 18.52 ms | 18.52 ms | -17.6% |
| animated-navigation.medium/compose/settle | 0.5 µs | 0.7 µs | -21.5% |
| animated-navigation.medium/compose/steady | 7.58 ms | 7.72 ms | -27.5% |
| animated-navigation.medium/compose/teardown | 285.5 µs | 492.7 µs | -27.7% |
| animated-navigation.medium/memory/mounted | 1159 KiB | 1159 KiB | -0.7% |
| animated-navigation.medium/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| animated-navigation.medium/plain/burst | 174.6 µs | 206.1 µs | -23.4% |
| animated-navigation.medium/plain/cold | 494.1 µs | 1.42 ms | -28.1% |
| animated-navigation.medium/plain/settle | 0.3 µs | 0.4 µs | -31.8% |
| animated-navigation.medium/plain/steady | 2.13 ms | 2.20 ms | -18.6% |
| animated-navigation.medium/plain/teardown | 167.1 µs | 243.0 µs | -21.1% |
| branch-swap/compose | 3.03 ms | 5.23 ms | -27.4% |
| branch-swap/memory/mounted | 32 KiB | 32 KiB | +39.1% |
| branch-swap/memory/teardown | 9 KiB | 9 KiB | — |
| branch-swap/plain | 2.75 ms | 3.31 ms | -8.3% |
| cold-mount-100/compose | 593.0 µs | 740.6 µs | -17.5% |
| cold-mount-100/memory/mounted | 2252 KiB | 2252 KiB | +0.4% |
| cold-mount-100/memory/teardown | 0 KiB | 0 KiB | — |
| cold-mount-100/plain | 553.3 µs | 899.2 µs | -20.8% |
| cold-mount-1000/compose | 7.35 ms | 11.12 ms | +112.3% |
| cold-mount-1000/memory/mounted | 22094 KiB | 22094 KiB | +0.0% |
| cold-mount-1000/memory/teardown | 8 KiB | 8 KiB | +0.0% |
| cold-mount-1000/plain | 4.84 ms | 7.66 ms | +38.6% |
| cold-mount-10000/compose | 90.17 ms | 113.83 ms | +42.6% |
| cold-mount-10000/memory/mounted | 222924 KiB | 222924 KiB | +0.0% |
| cold-mount-10000/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| cold-mount-10000/plain | 51.65 ms | 80.53 ms | -38.8% |
| data-grid.extreme/compose/burst | 646.27 ms | 680.17 ms | -27.8% |
| data-grid.extreme/compose/cold | 388.90 ms | 407.07 ms | -26.8% |
| data-grid.extreme/compose/counts | 1083.97 ms | 1083.97 ms | -21.3% |
| data-grid.extreme/compose/settle | 2.2 µs | 3.3 µs | +1.8% |
| data-grid.extreme/compose/steady | 16.71 ms | 24.00 ms | -25.3% |
| data-grid.extreme/compose/teardown | 999.5 µs | 1.41 ms | -18.4% |
| data-grid.extreme/memory/mounted | 29236 KiB | 29236 KiB | -0.0% |
| data-grid.extreme/memory/teardown | 8 KiB | 8 KiB | +0.0% |
| data-grid.extreme/plain/burst | 583.12 ms | 593.39 ms | -24.7% |
| data-grid.extreme/plain/cold | 365.81 ms | 376.46 ms | -26.9% |
| data-grid.extreme/plain/settle | 2.5 µs | 3.0 µs | +9.4% |
| data-grid.extreme/plain/steady | 13.92 ms | 15.51 ms | -28.8% |
| data-grid.extreme/plain/teardown | 397.6 µs | 655.4 µs | -25.0% |
| data-grid.large/compose/burst | 136.48 ms | 143.89 ms | +67.6% |
| data-grid.large/compose/cold | 78.45 ms | 87.26 ms | +74.5% |
| data-grid.large/compose/counts | 244.02 ms | 244.02 ms | +62.1% |
| data-grid.large/compose/settle | 1.5 µs | 2.7 µs | -19.5% |
| data-grid.large/compose/steady | 15.33 ms | 21.38 ms | +83.5% |
| data-grid.large/compose/teardown | 504.0 µs | 970.6 µs | +39.6% |
| data-grid.large/memory/mounted | 6836 KiB | 6836 KiB | -0.0% |
| data-grid.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| data-grid.large/plain/burst | 117.26 ms | 123.24 ms | +70.3% |
| data-grid.large/plain/cold | 74.26 ms | 77.32 ms | +79.7% |
| data-grid.large/plain/settle | 2.0 µs | 2.4 µs | +5.3% |
| data-grid.large/plain/steady | 10.41 ms | 14.11 ms | +67.8% |
| data-grid.large/plain/teardown | 183.5 µs | 256.2 µs | +17.5% |
| data-grid.medium/compose/burst | 48.03 ms | 51.23 ms | -27.0% |
| data-grid.medium/compose/cold | 26.87 ms | 28.95 ms | -28.0% |
| data-grid.medium/compose/counts | 101.04 ms | 101.04 ms | -22.8% |
| data-grid.medium/compose/settle | 1.6 µs | 2.2 µs | -15.0% |
| data-grid.medium/compose/steady | 11.55 ms | 14.12 ms | -21.9% |
| data-grid.medium/compose/teardown | 239.6 µs | 257.9 µs | -23.5% |
| data-grid.medium/memory/mounted | 3555 KiB | 3555 KiB | -0.2% |
| data-grid.medium/memory/teardown | 0 KiB | 0 KiB | — |
| data-grid.medium/plain/burst | 40.99 ms | 42.68 ms | -24.3% |
| data-grid.medium/plain/cold | 25.22 ms | 28.04 ms | -26.5% |
| data-grid.medium/plain/settle | 1.4 µs | 1.8 µs | -40.0% |
| data-grid.medium/plain/steady | 6.24 ms | 7.82 ms | -17.1% |
| data-grid.medium/plain/teardown | 80.2 µs | 179.4 µs | -20.3% |
| dense-dashboard.extreme/compose/burst | 16.84 ms | 21.63 ms | +16.9% |
| dense-dashboard.extreme/compose/cold | 514.1 µs | 711.7 µs | -2.8% |
| dense-dashboard.extreme/compose/counts | 22.52 ms | 22.52 ms | -44.1% |
| dense-dashboard.extreme/compose/settle | 0.8 µs | 1.3 µs | -19.6% |
| dense-dashboard.extreme/compose/steady | 860.5 µs | 872.9 µs | -1.0% |
| dense-dashboard.extreme/compose/teardown | 520.8 µs | 555.0 µs | -3.2% |
| dense-dashboard.extreme/memory/mounted | 1278 KiB | 1278 KiB | +0.0% |
| dense-dashboard.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| dense-dashboard.extreme/plain/burst | 6.63 ms | 9.65 ms | -2.5% |
| dense-dashboard.extreme/plain/cold | 239.3 µs | 1.22 ms | -1.9% |
| dense-dashboard.extreme/plain/settle | 0.7 µs | 1.1 µs | -10.2% |
| dense-dashboard.extreme/plain/steady | 141.4 µs | 156.2 µs | +3.7% |
| dense-dashboard.extreme/plain/teardown | 208.8 µs | 386.9 µs | -1.2% |
| dense-dashboard.large/compose/burst | 7.06 ms | 10.49 ms | +49.5% |
| dense-dashboard.large/compose/cold | 284.4 µs | 434.3 µs | +55.6% |
| dense-dashboard.large/compose/counts | 16.56 ms | 16.56 ms | +87.7% |
| dense-dashboard.large/compose/settle | 0.8 µs | 0.8 µs | +25.0% |
| dense-dashboard.large/compose/steady | 871.4 µs | 933.9 µs | +101.4% |
| dense-dashboard.large/compose/teardown | 239.1 µs | 285.9 µs | +63.0% |
| dense-dashboard.large/memory/mounted | 684 KiB | 684 KiB | +2.4% |
| dense-dashboard.large/memory/teardown | 0 KiB | 0 KiB | — |
| dense-dashboard.large/plain/burst | 2.51 ms | 4.17 ms | +27.6% |
| dense-dashboard.large/plain/cold | 121.0 µs | 231.1 µs | +50.4% |
| dense-dashboard.large/plain/settle | 0.7 µs | 0.9 µs | +40.3% |
| dense-dashboard.large/plain/steady | 130.5 µs | 148.0 µs | +84.3% |
| dense-dashboard.large/plain/teardown | 112.9 µs | 147.2 µs | +61.1% |
| dense-dashboard.medium/compose/burst | 2.19 ms | 2.97 ms | -25.5% |
| dense-dashboard.medium/compose/cold | 146.9 µs | 367.5 µs | -31.7% |
| dense-dashboard.medium/compose/counts | 3.92 ms | 3.92 ms | -36.9% |
| dense-dashboard.medium/compose/settle | 0.5 µs | 1.3 µs | -25.4% |
| dense-dashboard.medium/compose/steady | 676.6 µs | 715.2 µs | -20.2% |
| dense-dashboard.medium/compose/teardown | 86.9 µs | 123.2 µs | -28.0% |
| dense-dashboard.medium/memory/mounted | 331 KiB | 331 KiB | +2.5% |
| dense-dashboard.medium/memory/teardown | 1 KiB | 1 KiB | — |
| dense-dashboard.medium/plain/burst | 814.6 µs | 2.42 ms | -29.0% |
| dense-dashboard.medium/plain/cold | 74.7 µs | 170.0 µs | -20.1% |
| dense-dashboard.medium/plain/settle | 0.5 µs | 0.6 µs | -22.0% |
| dense-dashboard.medium/plain/steady | 106.4 µs | 109.2 µs | -18.3% |
| dense-dashboard.medium/plain/teardown | 36.0 µs | 54.5 µs | -30.0% |
| entities-identity-churn-10.extreme/compose/burst | 44.23 ms | 63.05 ms | +3.5% |
| entities-identity-churn-10.extreme/compose/cold | 27.49 ms | 39.45 ms | -0.9% |
| entities-identity-churn-10.extreme/compose/counts | 181.18 ms | 181.18 ms | +6.6% |
| entities-identity-churn-10.extreme/compose/settle | 1.8 µs | 2.4 µs | -33.7% |
| entities-identity-churn-10.extreme/compose/steady | 48.06 ms | 61.50 ms | -2.7% |
| entities-identity-churn-10.extreme/compose/teardown | 1.12 ms | 1.48 ms | -21.8% |
| entities-identity-churn-10.extreme/memory/mounted | 4239 KiB | 4239 KiB | +0.4% |
| entities-identity-churn-10.extreme/memory/teardown | 1 KiB | 1 KiB | — |
| entities-identity-churn-10.extreme/plain/burst | 14.53 ms | 23.75 ms | -16.6% |
| entities-identity-churn-10.extreme/plain/cold | 10.56 ms | 21.08 ms | +58.8% |
| entities-identity-churn-10.extreme/plain/settle | 1.7 µs | 2.1 µs | -40.9% |
| entities-identity-churn-10.extreme/plain/steady | 29.95 ms | 37.88 ms | +32.4% |
| entities-identity-churn-10.extreme/plain/teardown | 369.0 µs | 434.6 µs | +2.8% |
| entities-identity-churn-10.large/compose/burst | 10.10 ms | 16.40 ms | -29.7% |
| entities-identity-churn-10.large/compose/cold | 8.73 ms | 13.82 ms | -31.2% |
| entities-identity-churn-10.large/compose/counts | 46.27 ms | 46.27 ms | -34.0% |
| entities-identity-churn-10.large/compose/settle | 1.1 µs | 1.4 µs | -47.1% |
| entities-identity-churn-10.large/compose/steady | 13.22 ms | 18.08 ms | -30.6% |
| entities-identity-churn-10.large/compose/teardown | 301.2 µs | 574.8 µs | -29.3% |
| entities-identity-churn-10.large/memory/mounted | 1685 KiB | 1685 KiB | +0.0% |
| entities-identity-churn-10.large/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn-10.large/plain/burst | 3.58 ms | 7.58 ms | -39.2% |
| entities-identity-churn-10.large/plain/cold | 2.68 ms | 5.96 ms | -24.6% |
| entities-identity-churn-10.large/plain/settle | 0.8 µs | 1.1 µs | -49.4% |
| entities-identity-churn-10.large/plain/steady | 7.99 ms | 8.71 ms | -29.1% |
| entities-identity-churn-10.large/plain/teardown | 88.3 µs | 131.4 µs | -26.4% |
| entities-identity-churn-10.medium/compose/burst | 5.95 ms | 9.01 ms | -29.7% |
| entities-identity-churn-10.medium/compose/cold | 4.13 ms | 6.10 ms | -23.9% |
| entities-identity-churn-10.medium/compose/counts | 26.24 ms | 26.24 ms | -22.2% |
| entities-identity-churn-10.medium/compose/settle | 0.7 µs | 1.0 µs | -37.8% |
| entities-identity-churn-10.medium/compose/steady | 6.20 ms | 6.83 ms | -27.8% |
| entities-identity-churn-10.medium/compose/teardown | 158.3 µs | 230.8 µs | -31.0% |
| entities-identity-churn-10.medium/memory/mounted | 870 KiB | 870 KiB | +0.0% |
| entities-identity-churn-10.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn-10.medium/plain/burst | 1.59 ms | 2.36 ms | -41.5% |
| entities-identity-churn-10.medium/plain/cold | 1.32 ms | 2.30 ms | -40.0% |
| entities-identity-churn-10.medium/plain/settle | 0.6 µs | 0.8 µs | -64.0% |
| entities-identity-churn-10.medium/plain/steady | 3.82 ms | 5.13 ms | -36.6% |
| entities-identity-churn-10.medium/plain/teardown | 42.3 µs | 59.8 µs | -44.7% |
| entities-identity-churn-50.extreme/compose/burst | 32.23 ms | 43.61 ms | -35.4% |
| entities-identity-churn-50.extreme/compose/cold | 24.97 ms | 50.54 ms | -28.6% |
| entities-identity-churn-50.extreme/compose/counts | 266.01 ms | 266.01 ms | -17.3% |
| entities-identity-churn-50.extreme/compose/settle | 2.2 µs | 2.6 µs | -3.1% |
| entities-identity-churn-50.extreme/compose/steady | 124.88 ms | 148.37 ms | -18.6% |
| entities-identity-churn-50.extreme/compose/teardown | 904.6 µs | 1.03 ms | -21.3% |
| entities-identity-churn-50.extreme/memory/mounted | 4179 KiB | 4179 KiB | +0.0% |
| entities-identity-churn-50.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-identity-churn-50.extreme/plain/burst | 13.25 ms | 22.50 ms | -26.4% |
| entities-identity-churn-50.extreme/plain/cold | 6.37 ms | 18.41 ms | -29.2% |
| entities-identity-churn-50.extreme/plain/settle | 1.9 µs | 2.6 µs | -8.4% |
| entities-identity-churn-50.extreme/plain/steady | 54.75 ms | 66.25 ms | -9.6% |
| entities-identity-churn-50.extreme/plain/teardown | 294.4 µs | 485.0 µs | -24.7% |
| entities-identity-churn-50.large/compose/burst | 15.07 ms | 20.06 ms | +28.9% |
| entities-identity-churn-50.large/compose/cold | 14.08 ms | 22.93 ms | +74.5% |
| entities-identity-churn-50.large/compose/counts | 110.42 ms | 110.42 ms | +22.2% |
| entities-identity-churn-50.large/compose/settle | 1.9 µs | 4.0 µs | -18.6% |
| entities-identity-churn-50.large/compose/steady | 49.58 ms | 63.55 ms | +15.6% |
| entities-identity-churn-50.large/compose/teardown | 410.0 µs | 507.8 µs | +27.4% |
| entities-identity-churn-50.large/memory/mounted | 1730 KiB | 1730 KiB | +0.0% |
| entities-identity-churn-50.large/memory/teardown | 8 KiB | 8 KiB | — |
| entities-identity-churn-50.large/plain/burst | 5.01 ms | 10.50 ms | -19.9% |
| entities-identity-churn-50.large/plain/cold | 2.81 ms | 5.52 ms | +19.0% |
| entities-identity-churn-50.large/plain/settle | 1.1 µs | 1.7 µs | -51.5% |
| entities-identity-churn-50.large/plain/steady | 20.54 ms | 27.87 ms | +16.7% |
| entities-identity-churn-50.large/plain/teardown | 145.8 µs | 162.5 µs | +21.3% |
| entities-identity-churn-50.medium/compose/burst | 7.48 ms | 11.22 ms | +40.0% |
| entities-identity-churn-50.medium/compose/cold | 5.70 ms | 9.61 ms | +66.7% |
| entities-identity-churn-50.medium/compose/counts | 62.52 ms | 62.52 ms | +55.0% |
| entities-identity-churn-50.medium/compose/settle | 1.4 µs | 1.8 µs | -10.9% |
| entities-identity-churn-50.medium/compose/steady | 24.14 ms | 31.07 ms | +49.2% |
| entities-identity-churn-50.medium/compose/teardown | 225.9 µs | 314.1 µs | +36.3% |
| entities-identity-churn-50.medium/memory/mounted | 953 KiB | 953 KiB | +0.0% |
| entities-identity-churn-50.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn-50.medium/plain/burst | 2.66 ms | 4.86 ms | +18.6% |
| entities-identity-churn-50.medium/plain/cold | 1.69 ms | 3.41 ms | +83.2% |
| entities-identity-churn-50.medium/plain/settle | 0.8 µs | 0.9 µs | -56.6% |
| entities-identity-churn-50.medium/plain/steady | 10.95 ms | 11.32 ms | +85.5% |
| entities-identity-churn-50.medium/plain/teardown | 66.5 µs | 108.9 µs | +17.2% |
| entities-identity-churn.extreme/compose/burst | 45.20 ms | 61.83 ms | +12.5% |
| entities-identity-churn.extreme/compose/cold | 30.16 ms | 50.62 ms | +4.7% |
| entities-identity-churn.extreme/compose/counts | 247.73 ms | 247.73 ms | +31.6% |
| entities-identity-churn.extreme/compose/settle | 2.1 µs | 4.7 µs | -12.8% |
| entities-identity-churn.extreme/compose/steady | 89.32 ms | 109.71 ms | +21.9% |
| entities-identity-churn.extreme/compose/teardown | 1.20 ms | 1.96 ms | +9.4% |
| entities-identity-churn.extreme/memory/mounted | 4533 KiB | 4533 KiB | -0.5% |
| entities-identity-churn.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-identity-churn.extreme/plain/burst | 17.73 ms | 29.92 ms | +22.3% |
| entities-identity-churn.extreme/plain/cold | 8.29 ms | 17.28 ms | +41.4% |
| entities-identity-churn.extreme/plain/settle | 1.8 µs | 2.2 µs | -22.8% |
| entities-identity-churn.extreme/plain/steady | 44.75 ms | 53.03 ms | +43.2% |
| entities-identity-churn.extreme/plain/teardown | 447.8 µs | 887.1 µs | +32.2% |
| entities-identity-churn.large/compose/burst | 12.36 ms | 14.35 ms | -16.1% |
| entities-identity-churn.large/compose/cold | 9.30 ms | 13.72 ms | -26.4% |
| entities-identity-churn.large/compose/counts | 75.45 ms | 75.45 ms | -19.0% |
| entities-identity-churn.large/compose/settle | 1.4 µs | 1.8 µs | -5.4% |
| entities-identity-churn.large/compose/steady | 24.31 ms | 29.53 ms | -20.6% |
| entities-identity-churn.large/compose/teardown | 292.3 µs | 438.6 µs | -20.5% |
| entities-identity-churn.large/memory/mounted | 1648 KiB | 1648 KiB | +0.0% |
| entities-identity-churn.large/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| entities-identity-churn.large/plain/burst | 3.75 ms | 5.49 ms | -19.9% |
| entities-identity-churn.large/plain/cold | 2.21 ms | 5.83 ms | -41.7% |
| entities-identity-churn.large/plain/settle | 0.8 µs | 1.1 µs | -20.7% |
| entities-identity-churn.large/plain/steady | 12.56 ms | 20.20 ms | -19.5% |
| entities-identity-churn.large/plain/teardown | 88.2 µs | 398.9 µs | -20.5% |
| entities-identity-churn.medium/compose/burst | 5.51 ms | 10.72 ms | -36.3% |
| entities-identity-churn.medium/compose/cold | 3.77 ms | 7.33 ms | -24.5% |
| entities-identity-churn.medium/compose/counts | 30.88 ms | 30.88 ms | -24.2% |
| entities-identity-churn.medium/compose/settle | 1.0 µs | 1.3 µs | -15.1% |
| entities-identity-churn.medium/compose/steady | 11.30 ms | 14.76 ms | -18.3% |
| entities-identity-churn.medium/compose/teardown | 162.9 µs | 182.9 µs | -21.0% |
| entities-identity-churn.medium/memory/mounted | 917 KiB | 917 KiB | +0.0% |
| entities-identity-churn.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| entities-identity-churn.medium/plain/burst | 2.34 ms | 4.17 ms | -12.8% |
| entities-identity-churn.medium/plain/cold | 1.09 ms | 2.24 ms | -17.2% |
| entities-identity-churn.medium/plain/settle | 0.7 µs | 1.0 µs | -25.2% |
| entities-identity-churn.medium/plain/steady | 5.33 ms | 7.61 ms | -32.1% |
| entities-identity-churn.medium/plain/teardown | 51.5 µs | 67.9 µs | -20.8% |
| entities-integrated.extreme/compose/burst | 14.53 ms | 25.34 ms | +50.9% |
| entities-integrated.extreme/compose/cold | 96.11 ms | 117.47 ms | +42.4% |
| entities-integrated.extreme/compose/counts | 309.58 ms | 309.58 ms | +51.6% |
| entities-integrated.extreme/compose/settle | 2.0 µs | 2.7 µs | +29.1% |
| entities-integrated.extreme/compose/steady | 75.66 ms | 103.34 ms | +37.2% |
| entities-integrated.extreme/compose/teardown | 51.57 ms | 57.13 ms | +41.0% |
| entities-integrated.extreme/memory/mounted | 40530 KiB | 40530 KiB | +0.0% |
| entities-integrated.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-integrated.extreme/plain/burst | 4.71 ms | 7.71 ms | +33.7% |
| entities-integrated.extreme/plain/cold | 34.63 ms | 47.83 ms | +48.2% |
| entities-integrated.extreme/plain/settle | 2.0 µs | 2.3 µs | +41.9% |
| entities-integrated.extreme/plain/steady | 20.76 ms | 29.03 ms | +21.9% |
| entities-integrated.extreme/plain/teardown | 23.23 ms | 24.68 ms | +32.5% |
| entities-integrated.large/compose/burst | 9.24 ms | 11.73 ms | +70.0% |
| entities-integrated.large/compose/cold | 43.09 ms | 51.29 ms | +52.0% |
| entities-integrated.large/compose/counts | 140.93 ms | 140.93 ms | +51.9% |
| entities-integrated.large/compose/settle | 1.5 µs | 1.9 µs | -25.2% |
| entities-integrated.large/compose/steady | 47.96 ms | 70.59 ms | +41.0% |
| entities-integrated.large/compose/teardown | 13.65 ms | 16.07 ms | +9.4% |
| entities-integrated.large/memory/mounted | 16653 KiB | 16653 KiB | +0.0% |
| entities-integrated.large/memory/teardown | 0 KiB | 0 KiB | — |
| entities-integrated.large/plain/burst | 2.90 ms | 5.31 ms | +63.9% |
| entities-integrated.large/plain/cold | 12.27 ms | 21.05 ms | +25.6% |
| entities-integrated.large/plain/settle | 1.2 µs | 1.7 µs | -15.9% |
| entities-integrated.large/plain/steady | 13.61 ms | 18.00 ms | +63.1% |
| entities-integrated.large/plain/teardown | 5.46 ms | 7.67 ms | +4.2% |
| entities-integrated.medium/compose/burst | 5.53 ms | 6.83 ms | -21.4% |
| entities-integrated.medium/compose/cold | 13.65 ms | 20.27 ms | -35.2% |
| entities-integrated.medium/compose/counts | 64.91 ms | 64.91 ms | -28.8% |
| entities-integrated.medium/compose/settle | 1.1 µs | 2.0 µs | -32.3% |
| entities-integrated.medium/compose/steady | 24.88 ms | 33.61 ms | -27.7% |
| entities-integrated.medium/compose/teardown | 5.19 ms | 5.49 ms | -20.6% |
| entities-integrated.medium/memory/mounted | 9021 KiB | 9021 KiB | -0.1% |
| entities-integrated.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-integrated.medium/plain/burst | 1.57 ms | 3.67 ms | -30.5% |
| entities-integrated.medium/plain/cold | 5.36 ms | 9.65 ms | -17.4% |
| entities-integrated.medium/plain/settle | 0.8 µs | 1.3 µs | -25.8% |
| entities-integrated.medium/plain/steady | 7.36 ms | 9.90 ms | -30.1% |
| entities-integrated.medium/plain/teardown | 1.62 ms | 2.38 ms | -35.3% |
| entities-relevance-saturated.extreme/compose/burst | 66.48 ms | 79.14 ms | -19.4% |
| entities-relevance-saturated.extreme/compose/cold | 23.00 ms | 31.54 ms | -14.3% |
| entities-relevance-saturated.extreme/compose/counts | 210.92 ms | 210.92 ms | -8.9% |
| entities-relevance-saturated.extreme/compose/settle | 2.2 µs | 2.8 µs | -3.2% |
| entities-relevance-saturated.extreme/compose/steady | 37.38 ms | 75.76 ms | -19.8% |
| entities-relevance-saturated.extreme/compose/teardown | 11.49 ms | 12.48 ms | -6.9% |
| entities-relevance-saturated.extreme/memory/mounted | 12158 KiB | 12158 KiB | +0.1% |
| entities-relevance-saturated.extreme/memory/teardown | 9 KiB | 9 KiB | — |
| entities-relevance-saturated.extreme/plain/burst | 17.86 ms | 33.29 ms | -10.1% |
| entities-relevance-saturated.extreme/plain/cold | 8.69 ms | 17.48 ms | -8.9% |
| entities-relevance-saturated.extreme/plain/settle | 2.1 µs | 2.5 µs | -4.1% |
| entities-relevance-saturated.extreme/plain/steady | 77.56 ms | 100.19 ms | -22.3% |
| entities-relevance-saturated.extreme/plain/teardown | 3.35 ms | 4.30 ms | -1.4% |
| entities-relevance-saturated.large/compose/burst | 21.90 ms | 30.28 ms | -18.1% |
| entities-relevance-saturated.large/compose/cold | 9.97 ms | 18.82 ms | -9.4% |
| entities-relevance-saturated.large/compose/counts | 60.78 ms | 60.78 ms | -25.5% |
| entities-relevance-saturated.large/compose/settle | 1.6 µs | 2.1 µs | -16.6% |
| entities-relevance-saturated.large/compose/steady | 15.64 ms | 22.16 ms | -19.1% |
| entities-relevance-saturated.large/compose/teardown | 2.83 ms | 3.61 ms | -12.5% |
| entities-relevance-saturated.large/memory/mounted | 4896 KiB | 4896 KiB | +0.3% |
| entities-relevance-saturated.large/memory/teardown | 0 KiB | 0 KiB | — |
| entities-relevance-saturated.large/plain/burst | 5.38 ms | 8.08 ms | -23.1% |
| entities-relevance-saturated.large/plain/cold | 4.59 ms | 8.47 ms | -6.3% |
| entities-relevance-saturated.large/plain/settle | 1.3 µs | 1.8 µs | -29.5% |
| entities-relevance-saturated.large/plain/steady | 27.17 ms | 37.87 ms | -27.7% |
| entities-relevance-saturated.large/plain/teardown | 1.08 ms | 1.34 ms | -20.1% |
| entities-relevance-saturated.medium/compose/burst | 12.59 ms | 16.84 ms | +68.2% |
| entities-relevance-saturated.medium/compose/cold | 5.13 ms | 7.75 ms | +37.6% |
| entities-relevance-saturated.medium/compose/counts | 37.16 ms | 37.16 ms | +70.0% |
| entities-relevance-saturated.medium/compose/settle | 1.3 µs | 3.1 µs | -3.6% |
| entities-relevance-saturated.medium/compose/steady | 7.68 ms | 11.24 ms | +49.7% |
| entities-relevance-saturated.medium/compose/teardown | 1.07 ms | 1.76 ms | +17.9% |
| entities-relevance-saturated.medium/memory/mounted | 2435 KiB | 2435 KiB | -0.3% |
| entities-relevance-saturated.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entities-relevance-saturated.medium/plain/burst | 3.16 ms | 7.11 ms | +55.5% |
| entities-relevance-saturated.medium/plain/cold | 2.53 ms | 5.95 ms | +107.0% |
| entities-relevance-saturated.medium/plain/settle | 1.2 µs | 1.8 µs | -24.8% |
| entities-relevance-saturated.medium/plain/steady | 16.87 ms | 20.63 ms | +74.7% |
| entities-relevance-saturated.medium/plain/teardown | 517.4 µs | 957.3 µs | -17.2% |
| entities-relevance-sweep.extreme/compose/burst | 114.30 ms | 142.76 ms | -1.8% |
| entities-relevance-sweep.extreme/compose/cold | 32.04 ms | 43.15 ms | +14.0% |
| entities-relevance-sweep.extreme/compose/counts | 353.54 ms | 353.54 ms | +8.7% |
| entities-relevance-sweep.extreme/compose/settle | 2.2 µs | 2.8 µs | -32.8% |
| entities-relevance-sweep.extreme/compose/steady | 121.72 ms | 142.24 ms | +4.0% |
| entities-relevance-sweep.extreme/compose/teardown | 12.82 ms | 14.91 ms | -9.4% |
| entities-relevance-sweep.extreme/memory/mounted | 12170 KiB | 12170 KiB | +0.0% |
| entities-relevance-sweep.extreme/memory/teardown | 8 KiB | 8 KiB | -50.0% |
| entities-relevance-sweep.extreme/plain/burst | 31.18 ms | 41.18 ms | -16.8% |
| entities-relevance-sweep.extreme/plain/cold | 9.33 ms | 18.88 ms | -4.2% |
| entities-relevance-sweep.extreme/plain/settle | 1.9 µs | 3.9 µs | -47.4% |
| entities-relevance-sweep.extreme/plain/steady | 27.09 ms | 45.68 ms | -23.9% |
| entities-relevance-sweep.extreme/plain/teardown | 3.48 ms | 3.90 ms | -13.9% |
| entities-relevance-sweep.large/compose/burst | 35.01 ms | 43.51 ms | -22.2% |
| entities-relevance-sweep.large/compose/cold | 8.97 ms | 22.50 ms | -22.1% |
| entities-relevance-sweep.large/compose/counts | 102.06 ms | 102.06 ms | -23.0% |
| entities-relevance-sweep.large/compose/settle | 1.9 µs | 2.4 µs | +2.1% |
| entities-relevance-sweep.large/compose/steady | 32.14 ms | 41.83 ms | -18.2% |
| entities-relevance-sweep.large/compose/teardown | 3.11 ms | 4.23 ms | -7.8% |
| entities-relevance-sweep.large/memory/mounted | 4897 KiB | 4897 KiB | +0.2% |
| entities-relevance-sweep.large/memory/teardown | 0 KiB | 0 KiB | — |
| entities-relevance-sweep.large/plain/burst | 9.87 ms | 21.89 ms | -3.6% |
| entities-relevance-sweep.large/plain/cold | 4.96 ms | 9.24 ms | +31.3% |
| entities-relevance-sweep.large/plain/settle | 1.2 µs | 2.1 µs | -15.8% |
| entities-relevance-sweep.large/plain/steady | 8.50 ms | 16.02 ms | -21.8% |
| entities-relevance-sweep.large/plain/teardown | 1.25 ms | 1.72 ms | +3.6% |
| entities-relevance-sweep.medium/compose/burst | 16.36 ms | 23.84 ms | +55.2% |
| entities-relevance-sweep.medium/compose/cold | 6.28 ms | 12.68 ms | +44.9% |
| entities-relevance-sweep.medium/compose/counts | 54.88 ms | 54.88 ms | +47.4% |
| entities-relevance-sweep.medium/compose/settle | 1.7 µs | 2.9 µs | +126.4% |
| entities-relevance-sweep.medium/compose/steady | 14.92 ms | 22.02 ms | +55.9% |
| entities-relevance-sweep.medium/compose/teardown | 1.33 ms | 1.55 ms | +89.7% |
| entities-relevance-sweep.medium/memory/mounted | 2444 KiB | 2444 KiB | -0.3% |
| entities-relevance-sweep.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| entities-relevance-sweep.medium/plain/burst | 4.66 ms | 12.24 ms | +20.8% |
| entities-relevance-sweep.medium/plain/cold | 1.76 ms | 4.28 ms | +41.1% |
| entities-relevance-sweep.medium/plain/settle | 1.7 µs | 2.2 µs | +196.3% |
| entities-relevance-sweep.medium/plain/steady | 4.29 ms | 8.08 ms | +33.9% |
| entities-relevance-sweep.medium/plain/teardown | 741.2 µs | 829.0 µs | +223.9% |
| entity-labels-sparse.extreme/compose/burst | 29.33 ms | 35.93 ms | +54.0% |
| entity-labels-sparse.extreme/compose/cold | 24.42 ms | 32.26 ms | +60.8% |
| entity-labels-sparse.extreme/compose/counts | 109.35 ms | 109.35 ms | +49.4% |
| entity-labels-sparse.extreme/compose/settle | 1.6 µs | 2.1 µs | -5.9% |
| entity-labels-sparse.extreme/compose/steady | 3.85 ms | 4.11 ms | +41.8% |
| entity-labels-sparse.extreme/compose/teardown | 12.07 ms | 13.34 ms | +34.8% |
| entity-labels-sparse.extreme/memory/mounted | 12339 KiB | 12339 KiB | -0.1% |
| entity-labels-sparse.extreme/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| entity-labels-sparse.extreme/plain/burst | 8.31 ms | 13.99 ms | +30.8% |
| entity-labels-sparse.extreme/plain/cold | 9.35 ms | 14.19 ms | +36.5% |
| entity-labels-sparse.extreme/plain/settle | 1.1 µs | 1.6 µs | +19.0% |
| entity-labels-sparse.extreme/plain/steady | 914.8 µs | 984.3 µs | +62.1% |
| entity-labels-sparse.extreme/plain/teardown | 5.75 ms | 6.35 ms | +25.9% |
| entity-labels-sparse.large/compose/burst | 12.33 ms | 15.72 ms | +67.9% |
| entity-labels-sparse.large/compose/cold | 11.25 ms | 16.93 ms | +87.2% |
| entity-labels-sparse.large/compose/counts | 39.16 ms | 39.16 ms | +72.8% |
| entity-labels-sparse.large/compose/settle | 1.1 µs | 1.7 µs | +8.1% |
| entity-labels-sparse.large/compose/steady | 1.83 ms | 1.99 ms | +57.1% |
| entity-labels-sparse.large/compose/teardown | 3.87 ms | 4.56 ms | +51.4% |
| entity-labels-sparse.large/memory/mounted | 6405 KiB | 6405 KiB | -0.2% |
| entity-labels-sparse.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entity-labels-sparse.large/plain/burst | 3.57 ms | 5.06 ms | +47.6% |
| entity-labels-sparse.large/plain/cold | 3.84 ms | 5.81 ms | +22.4% |
| entity-labels-sparse.large/plain/settle | 0.7 µs | 0.8 µs | +28.5% |
| entity-labels-sparse.large/plain/steady | 448.4 µs | 502.6 µs | +64.9% |
| entity-labels-sparse.large/plain/teardown | 1.70 ms | 1.92 ms | +44.3% |
| entity-labels-sparse.medium/compose/burst | 5.40 ms | 8.08 ms | +3.4% |
| entity-labels-sparse.medium/compose/cold | 6.49 ms | 8.00 ms | +63.9% |
| entity-labels-sparse.medium/compose/counts | 21.15 ms | 21.15 ms | +2.1% |
| entity-labels-sparse.medium/compose/settle | 1.0 µs | 1.4 µs | +13.8% |
| entity-labels-sparse.medium/compose/steady | 1.00 ms | 1.08 ms | +18.1% |
| entity-labels-sparse.medium/compose/teardown | 1.41 ms | 1.60 ms | +16.0% |
| entity-labels-sparse.medium/memory/mounted | 2831 KiB | 2831 KiB | +0.0% |
| entity-labels-sparse.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entity-labels-sparse.medium/plain/burst | 1.53 ms | 2.35 ms | +7.7% |
| entity-labels-sparse.medium/plain/cold | 1.95 ms | 4.13 ms | -2.3% |
| entity-labels-sparse.medium/plain/settle | 0.6 µs | 0.8 µs | -4.9% |
| entity-labels-sparse.medium/plain/steady | 209.5 µs | 287.7 µs | +1.2% |
| entity-labels-sparse.medium/plain/teardown | 572.8 µs | 699.1 µs | +20.5% |
| entity-labels.extreme/compose/burst | 28.54 ms | 33.91 ms | +57.2% |
| entity-labels.extreme/compose/cold | 20.88 ms | 33.36 ms | +34.0% |
| entity-labels.extreme/compose/counts | 111.86 ms | 111.86 ms | +55.4% |
| entity-labels.extreme/compose/settle | 1.9 µs | 3.0 µs | +38.0% |
| entity-labels.extreme/compose/steady | 23.83 ms | 33.60 ms | +74.2% |
| entity-labels.extreme/compose/teardown | 11.85 ms | 13.93 ms | +47.1% |
| entity-labels.extreme/memory/mounted | 12816 KiB | 12816 KiB | +0.0% |
| entity-labels.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entity-labels.extreme/plain/burst | 7.82 ms | 14.19 ms | +51.1% |
| entity-labels.extreme/plain/cold | 9.00 ms | 14.72 ms | +52.4% |
| entity-labels.extreme/plain/settle | 1.0 µs | 1.7 µs | +67.6% |
| entity-labels.extreme/plain/steady | 675.5 µs | 902.0 µs | +39.5% |
| entity-labels.extreme/plain/teardown | 5.60 ms | 6.29 ms | +40.6% |
| entity-labels.large/compose/burst | 13.43 ms | 18.59 ms | +78.3% |
| entity-labels.large/compose/cold | 12.66 ms | 16.36 ms | +43.4% |
| entity-labels.large/compose/counts | 65.78 ms | 65.78 ms | +75.1% |
| entity-labels.large/compose/settle | 1.2 µs | 1.8 µs | +13.9% |
| entity-labels.large/compose/steady | 15.28 ms | 18.56 ms | +142.4% |
| entity-labels.large/compose/teardown | 4.38 ms | 5.34 ms | +48.6% |
| entity-labels.large/memory/mounted | 6665 KiB | 6665 KiB | +0.1% |
| entity-labels.large/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| entity-labels.large/plain/burst | 3.94 ms | 5.08 ms | +64.4% |
| entity-labels.large/plain/cold | 4.17 ms | 6.80 ms | +31.0% |
| entity-labels.large/plain/settle | 0.7 µs | 1.0 µs | +7.3% |
| entity-labels.large/plain/steady | 446.8 µs | 460.2 µs | +58.5% |
| entity-labels.large/plain/teardown | 1.80 ms | 2.17 ms | +37.0% |
| entity-labels.medium/compose/burst | 4.19 ms | 5.42 ms | +66.9% |
| entity-labels.medium/compose/cold | 4.74 ms | 6.79 ms | +105.6% |
| entity-labels.medium/compose/counts | 16.96 ms | 16.96 ms | +46.4% |
| entity-labels.medium/compose/settle | 0.8 µs | 0.9 µs | +44.1% |
| entity-labels.medium/compose/steady | 4.15 ms | 5.58 ms | +75.3% |
| entity-labels.medium/compose/teardown | 1.15 ms | 1.41 ms | +64.9% |
| entity-labels.medium/memory/mounted | 2951 KiB | 2951 KiB | -0.5% |
| entity-labels.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entity-labels.medium/plain/burst | 1.28 ms | 2.46 ms | +39.2% |
| entity-labels.medium/plain/cold | 1.24 ms | 2.63 ms | +16.3% |
| entity-labels.medium/plain/settle | 0.6 µs | 0.8 µs | +45.1% |
| entity-labels.medium/plain/steady | 156.1 µs | 173.0 µs | +33.7% |
| entity-labels.medium/plain/teardown | 430.0 µs | 731.2 µs | +36.2% |
| events/compose | 10.47 ms | 13.63 ms | -20.9% |
| events/memory/mounted | 1 KiB | 1 KiB | — |
| events/memory/teardown | 0 KiB | 0 KiB | — |
| events/plain | 9.32 ms | 12.89 ms | -13.0% |
| inspector.extreme/compose/burst | 7.26 ms | 9.78 ms | -19.4% |
| inspector.extreme/compose/cold | 17.32 ms | 28.46 ms | -22.3% |
| inspector.extreme/compose/counts | 30.79 ms | 30.79 ms | -16.4% |
| inspector.extreme/compose/settle | 1.1 µs | 1.9 µs | -38.8% |
| inspector.extreme/compose/steady | 220.9 µs | 295.3 µs | -28.1% |
| inspector.extreme/compose/teardown | 2.22 ms | 2.73 ms | -27.2% |
| inspector.extreme/memory/mounted | 17423 KiB | 17423 KiB | -0.0% |
| inspector.extreme/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| inspector.extreme/plain/burst | 1.38 ms | 1.49 ms | -24.3% |
| inspector.extreme/plain/cold | 6.06 ms | 8.83 ms | -19.0% |
| inspector.extreme/plain/settle | 0.6 µs | 0.8 µs | -14.1% |
| inspector.extreme/plain/steady | 55.5 µs | 73.6 µs | -22.6% |
| inspector.extreme/plain/teardown | 4.82 ms | 5.31 ms | -9.2% |
| inspector.large/compose/burst | 4.64 ms | 9.74 ms | +107.7% |
| inspector.large/compose/cold | 8.45 ms | 13.39 ms | +63.7% |
| inspector.large/compose/counts | 21.62 ms | 21.62 ms | +60.3% |
| inspector.large/compose/settle | 1.3 µs | 2.0 µs | +138.8% |
| inspector.large/compose/steady | 297.1 µs | 485.9 µs | +110.2% |
| inspector.large/compose/teardown | 1.36 ms | 3.06 ms | +80.7% |
| inspector.large/memory/mounted | 6220 KiB | 6220 KiB | -0.1% |
| inspector.large/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| inspector.large/plain/burst | 868.2 µs | 1.05 ms | +115.2% |
| inspector.large/plain/cold | 3.48 ms | 7.51 ms | +44.3% |
| inspector.large/plain/settle | 0.7 µs | 1.0 µs | +89.5% |
| inspector.large/plain/steady | 71.3 µs | 91.4 µs | +80.7% |
| inspector.large/plain/teardown | 1.67 ms | 2.06 ms | +41.6% |
| inspector.medium/compose/burst | 1.47 ms | 2.04 ms | -2.0% |
| inspector.medium/compose/cold | 1.93 ms | 3.62 ms | -9.1% |
| inspector.medium/compose/counts | 6.58 ms | 6.58 ms | +41.0% |
| inspector.medium/compose/settle | 0.7 µs | 2.3 µs | +11.5% |
| inspector.medium/compose/steady | 222.8 µs | 297.0 µs | +6.1% |
| inspector.medium/compose/teardown | 439.6 µs | 743.2 µs | +14.1% |
| inspector.medium/memory/mounted | 1807 KiB | 1807 KiB | +0.0% |
| inspector.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| inspector.medium/plain/burst | 269.4 µs | 393.0 µs | +3.3% |
| inspector.medium/plain/cold | 1.25 ms | 2.86 ms | +7.9% |
| inspector.medium/plain/settle | 0.6 µs | 0.8 µs | +25.9% |
| inspector.medium/plain/steady | 77.1 µs | 91.0 µs | +33.2% |
| inspector.medium/plain/teardown | 460.2 µs | 574.5 µs | +38.2% |
| keyed-append/compose | 1.18 ms | 1.43 ms | +102.8% |
| keyed-append/memory/mounted | 2293 KiB | 2293 KiB | +0.3% |
| keyed-append/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| keyed-append/plain | 1.41 ms | 1.64 ms | +96.8% |
| keyed-insert/compose | 1.99 ms | 2.69 ms | -29.5% |
| keyed-insert/memory/mounted | 2289 KiB | 2289 KiB | +0.0% |
| keyed-insert/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| keyed-insert/plain | 1.12 ms | 1.48 ms | -25.4% |
| keyed-prepend/compose | 3.24 ms | 3.55 ms | -23.2% |
| keyed-prepend/memory/mounted | 2293 KiB | 2293 KiB | -0.4% |
| keyed-prepend/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| keyed-prepend/plain | 1.27 ms | 1.46 ms | -28.0% |
| keyed-remove/compose | 2.63 ms | 3.07 ms | +104.5% |
| keyed-remove/memory/mounted | 2285 KiB | 2285 KiB | +0.0% |
| keyed-remove/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| keyed-remove/plain | 1.62 ms | 2.17 ms | +107.1% |
| keyed-replace/compose | 49.64 ms | 56.86 ms | +34.2% |
| keyed-replace/memory/mounted | 2313 KiB | 2313 KiB | +0.0% |
| keyed-replace/memory/teardown | 9 KiB | 9 KiB | +0.0% |
| keyed-replace/plain | 27.37 ms | 35.95 ms | +26.9% |
| keyed-reverse/compose | 2.23 ms | 2.27 ms | -24.6% |
| keyed-reverse/memory/mounted | 2305 KiB | 2305 KiB | +0.3% |
| keyed-reverse/memory/teardown | 9 KiB | 9 KiB | +0.0% |
| keyed-reverse/plain | 936.4 µs | 961.4 µs | -24.6% |
| keyed-rotate/compose | 2.95 ms | 3.17 ms | +118.1% |
| keyed-rotate/memory/mounted | 2297 KiB | 2297 KiB | +0.3% |
| keyed-rotate/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| keyed-rotate/plain | 1.25 ms | 1.36 ms | +109.5% |
| keyed-shuffle/compose | 3.08 ms | 3.26 ms | +2.4% |
| keyed-shuffle/memory/mounted | 2297 KiB | 2297 KiB | +0.0% |
| keyed-shuffle/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-shuffle/plain | 1.37 ms | 1.48 ms | +4.2% |
| mount-cycles/compose | 24.89 ms | 28.55 ms | +44.3% |
| mount-cycles/memory/mounted | 0 KiB | 0 KiB | — |
| mount-cycles/memory/teardown | 0 KiB | 0 KiB | — |
| mount-cycles/plain | 17.03 ms | 18.89 ms | +34.4% |
| mount-dispose/compose | 10.83 ms | 13.15 ms | +68.6% |
| mount-dispose/memory/mounted | 0 KiB | 0 KiB | — |
| mount-dispose/memory/teardown | 0 KiB | 0 KiB | — |
| mount-dispose/plain | 8.79 ms | 11.36 ms | +39.0% |
| ordered-window-scroll/compose | 497.2 µs | 537.8 µs | +75.3% |
| ordered-window-scroll/memory/mounted | 1123 KiB | 1123 KiB | -0.7% |
| ordered-window-scroll/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| projection-keyed-append-500/compose | 13.43 ms | 14.46 ms | +0.0% |
| projection-keyed-append-500/memory/mounted | 3217 KiB | 3217 KiB | -0.2% |
| projection-keyed-append-500/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| projection-keyed-append-500/plain | 2.92 ms | 4.24 ms | +32.9% |
| projection-observe-100/compose | 1.57 ms | 2.05 ms | +55.8% |
| projection-observe-100/memory/mounted | 74 KiB | 74 KiB | +12.1% |
| projection-observe-100/memory/teardown | 8 KiB | 8 KiB | — |
| projection-selection-500/compose | 1.08 ms | 1.12 ms | +59.6% |
| projection-selection-500/memory/mounted | 4116 KiB | 4116 KiB | +0.4% |
| projection-selection-500/memory/teardown | 8 KiB | 8 KiB | — |
| projection-selection-500/plain | 145.9 µs | 153.3 µs | +26.1% |
| scene-2d.extreme/compose/burst | 24.65 ms | 36.37 ms | +49.0% |
| scene-2d.extreme/compose/cold | 8.50 ms | 15.65 ms | +36.7% |
| scene-2d.extreme/compose/counts | 166.18 ms | 166.18 ms | +69.3% |
| scene-2d.extreme/compose/settle | 1.8 µs | 2.3 µs | +36.4% |
| scene-2d.extreme/compose/steady | 64.46 ms | 73.05 ms | +42.7% |
| scene-2d.extreme/compose/teardown | 1.05 ms | 1.14 ms | +57.8% |
| scene-2d.extreme/memory/mounted | 9696 KiB | 9696 KiB | +0.0% |
| scene-2d.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| scene-2d.extreme/plain/burst | 7.21 ms | 12.32 ms | +30.4% |
| scene-2d.extreme/plain/cold | 1.30 ms | 4.19 ms | +19.4% |
| scene-2d.extreme/plain/settle | 1.5 µs | 2.1 µs | +132.3% |
| scene-2d.extreme/plain/steady | 37.91 ms | 44.14 ms | +42.4% |
| scene-2d.extreme/plain/teardown | 470.9 µs | 723.6 µs | +47.4% |
| scene-2d.large/compose/burst | 27.92 ms | 35.05 ms | +45.7% |
| scene-2d.large/compose/cold | 5.53 ms | 8.29 ms | +39.5% |
| scene-2d.large/compose/counts | 185.42 ms | 185.42 ms | +56.5% |
| scene-2d.large/compose/settle | 1.9 µs | 2.6 µs | -7.2% |
| scene-2d.large/compose/steady | 89.85 ms | 95.58 ms | +77.8% |
| scene-2d.large/compose/teardown | 1.29 ms | 1.40 ms | +26.6% |
| scene-2d.large/memory/mounted | 4079 KiB | 4079 KiB | +0.0% |
| scene-2d.large/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| scene-2d.large/plain/burst | 9.21 ms | 14.18 ms | +36.8% |
| scene-2d.large/plain/cold | 2.35 ms | 3.28 ms | +122.3% |
| scene-2d.large/plain/settle | 1.5 µs | 2.3 µs | -16.7% |
| scene-2d.large/plain/steady | 49.98 ms | 52.49 ms | +73.4% |
| scene-2d.large/plain/teardown | 593.2 µs | 707.0 µs | +14.6% |
| scene-2d.medium/compose/burst | 17.47 ms | 20.46 ms | +45.2% |
| scene-2d.medium/compose/cold | 3.69 ms | 4.90 ms | +89.2% |
| scene-2d.medium/compose/counts | 112.73 ms | 112.73 ms | +58.4% |
| scene-2d.medium/compose/settle | 1.6 µs | 2.0 µs | +110.4% |
| scene-2d.medium/compose/steady | 50.83 ms | 52.53 ms | +55.9% |
| scene-2d.medium/compose/teardown | 842.5 µs | 962.2 µs | +90.5% |
| scene-2d.medium/memory/mounted | 2282 KiB | 2282 KiB | +0.0% |
| scene-2d.medium/memory/teardown | 0 KiB | 0 KiB | — |
| scene-2d.medium/plain/burst | 6.11 ms | 8.03 ms | +93.3% |
| scene-2d.medium/plain/cold | 1.83 ms | 4.49 ms | +50.5% |
| scene-2d.medium/plain/settle | 1.5 µs | 2.8 µs | +192.0% |
| scene-2d.medium/plain/steady | 28.01 ms | 30.44 ms | +43.5% |
| scene-2d.medium/plain/teardown | 519.2 µs | 632.4 µs | +106.8% |
| scene-3d/compose | 6.01 ms | 8.56 ms | +79.6% |
| scene-3d/memory/mounted | 1302 KiB | 1302 KiB | +0.0% |
| scene-3d/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| scene-3d/plain | 2.83 ms | 3.33 ms | +64.9% |
| session-cycle.extreme/compose/burst | 150.80 ms | 193.11 ms | +54.3% |
| session-cycle.extreme/compose/cold | 4.2 µs | 6.6 µs | +1.7% |
| session-cycle.extreme/compose/counts | 339.46 ms | 339.46 ms | +37.7% |
| session-cycle.extreme/compose/settle | 2.1 µs | 2.5 µs | -9.0% |
| session-cycle.extreme/compose/steady | 152.48 ms | 261.62 ms | +20.3% |
| session-cycle.extreme/compose/teardown | 2.3 µs | 2.6 µs | +2.6% |
| session-cycle.extreme/memory/mounted | 10 KiB | 10 KiB | +400.0% |
| session-cycle.extreme/memory/teardown | 8 KiB | 8 KiB | +0.0% |
| session-cycle.extreme/plain/burst | 134.38 ms | 206.70 ms | +35.4% |
| session-cycle.extreme/plain/cold | 4.7 µs | 6.4 µs | -1.7% |
| session-cycle.extreme/plain/settle | 2.9 µs | 11.7 µs | +13.1% |
| session-cycle.extreme/plain/steady | 180.62 ms | 254.13 ms | +14.9% |
| session-cycle.extreme/plain/teardown | 2.6 µs | 3.3 µs | +2.4% |
| session-cycle.large/compose/burst | 39.59 ms | 49.09 ms | +16.6% |
| session-cycle.large/compose/cold | 4.3 µs | 7.0 µs | +12.5% |
| session-cycle.large/compose/counts | 107.87 ms | 107.87 ms | +26.9% |
| session-cycle.large/compose/settle | 1.9 µs | 2.3 µs | +8.4% |
| session-cycle.large/compose/steady | 67.20 ms | 79.57 ms | +38.9% |
| session-cycle.large/compose/teardown | 2.2 µs | 2.4 µs | +13.1% |
| session-cycle.large/memory/mounted | 2 KiB | 2 KiB | +100.0% |
| session-cycle.large/memory/teardown | 1 KiB | 1 KiB | — |
| session-cycle.large/plain/burst | 45.94 ms | 56.08 ms | +9.2% |
| session-cycle.large/plain/cold | 4.6 µs | 5.6 µs | +25.7% |
| session-cycle.large/plain/settle | 2.3 µs | 3.0 µs | +13.8% |
| session-cycle.large/plain/steady | 65.91 ms | 79.75 ms | +64.2% |
| session-cycle.large/plain/teardown | 2.1 µs | 2.6 µs | +17.8% |
| session-cycle.medium/compose/burst | 14.47 ms | 20.65 ms | +33.7% |
| session-cycle.medium/compose/cold | 3.4 µs | 7.0 µs | -14.6% |
| session-cycle.medium/compose/counts | 40.20 ms | 40.20 ms | +9.6% |
| session-cycle.medium/compose/settle | 1.3 µs | 1.5 µs | -28.8% |
| session-cycle.medium/compose/steady | 19.51 ms | 27.20 ms | +8.2% |
| session-cycle.medium/compose/teardown | 1.4 µs | 1.8 µs | -30.7% |
| session-cycle.medium/memory/mounted | 2 KiB | 2 KiB | — |
| session-cycle.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| session-cycle.medium/plain/burst | 12.83 ms | 16.65 ms | +80.8% |
| session-cycle.medium/plain/cold | 3.3 µs | 5.5 µs | -24.6% |
| session-cycle.medium/plain/settle | 1.3 µs | 12.3 µs | -35.7% |
| session-cycle.medium/plain/steady | 16.16 ms | 21.00 ms | +9.2% |
| session-cycle.medium/plain/teardown | 1.4 µs | 1.9 µs | -31.6% |
| spatial-scene.extreme/compose/burst | 124.29 ms | 140.01 ms | +36.9% |
| spatial-scene.extreme/compose/cold | 10.30 ms | 19.89 ms | +29.2% |
| spatial-scene.extreme/compose/counts | 260.10 ms | 260.10 ms | +54.4% |
| spatial-scene.extreme/compose/settle | 1.8 µs | 2.4 µs | -15.6% |
| spatial-scene.extreme/compose/steady | 53.45 ms | 66.84 ms | +60.8% |
| spatial-scene.extreme/compose/teardown | 3.22 ms | 5.50 ms | +6.6% |
| spatial-scene.extreme/memory/mounted | 5349 KiB | 5349 KiB | +10.8% |
| spatial-scene.extreme/memory/teardown | 1 KiB | 1 KiB | — |
| spatial-scene.extreme/plain/burst | 53.45 ms | 63.74 ms | +33.4% |
| spatial-scene.extreme/plain/cold | 3.74 ms | 11.22 ms | +30.8% |
| spatial-scene.extreme/plain/settle | 2.0 µs | 2.7 µs | -8.9% |
| spatial-scene.extreme/plain/steady | 75.65 ms | 80.43 ms | +78.9% |
| spatial-scene.extreme/plain/teardown | 1.55 ms | 2.85 ms | +50.5% |
| spatial-scene.large/compose/burst | 37.07 ms | 40.02 ms | +35.4% |
| spatial-scene.large/compose/cold | 3.30 ms | 7.04 ms | +7.5% |
| spatial-scene.large/compose/counts | 74.26 ms | 74.26 ms | +58.0% |
| spatial-scene.large/compose/settle | 1.2 µs | 1.6 µs | -53.5% |
| spatial-scene.large/compose/steady | 18.12 ms | 20.10 ms | +61.0% |
| spatial-scene.large/compose/teardown | 926.9 µs | 1.10 ms | +31.5% |
| spatial-scene.large/memory/mounted | 1767 KiB | 1767 KiB | -0.4% |
| spatial-scene.large/memory/teardown | 1 KiB | 1 KiB | — |
| spatial-scene.large/plain/burst | 13.09 ms | 16.37 ms | +24.2% |
| spatial-scene.large/plain/cold | 1.07 ms | 2.91 ms | -21.7% |
| spatial-scene.large/plain/settle | 1.0 µs | 1.5 µs | -48.1% |
| spatial-scene.large/plain/steady | 21.98 ms | 27.40 ms | +60.4% |
| spatial-scene.large/plain/teardown | 312.9 µs | 569.5 µs | +51.4% |
| spatial-scene.medium/compose/burst | 9.30 ms | 10.14 ms | -29.7% |
| spatial-scene.medium/compose/cold | 862.6 µs | 1.56 ms | -38.5% |
| spatial-scene.medium/compose/counts | 22.77 ms | 22.77 ms | -29.0% |
| spatial-scene.medium/compose/settle | 0.9 µs | 1.9 µs | -17.1% |
| spatial-scene.medium/compose/steady | 6.14 ms | 7.94 ms | -33.7% |
| spatial-scene.medium/compose/teardown | 213.2 µs | 266.5 µs | -35.1% |
| spatial-scene.medium/memory/mounted | 694 KiB | 694 KiB | +0.0% |
| spatial-scene.medium/memory/teardown | 0 KiB | 0 KiB | — |
| spatial-scene.medium/plain/burst | 2.77 ms | 4.93 ms | -47.8% |
| spatial-scene.medium/plain/cold | 340.2 µs | 864.3 µs | -20.7% |
| spatial-scene.medium/plain/settle | 0.7 µs | 1.1 µs | -18.3% |
| spatial-scene.medium/plain/steady | 5.89 ms | 7.33 ms | -32.2% |
| spatial-scene.medium/plain/teardown | 84.4 µs | 143.3 µs | -21.0% |
| status-panel/compose | 585.4 µs | 607.6 µs | +102.0% |
| status-panel/memory/mounted | 43 KiB | 43 KiB | +0.0% |
| status-panel/memory/teardown | 0 KiB | 0 KiB | — |
| status-panel/plain | 112.1 µs | 144.5 µs | +119.4% |
| unwind/compose | 3.70 ms | 4.92 ms | +2.6% |
| unwind/memory/mounted | 0 KiB | 0 KiB | — |
| unwind/memory/teardown | 0 KiB | 0 KiB | — |
| unwind/plain | 3.37 ms | 4.27 ms | +60.7% |
| update-batched/compose | 2.08 ms | 2.23 ms | +65.5% |
| update-batched/memory/mounted | 1900 KiB | 1900 KiB | +0.4% |
| update-batched/memory/teardown | 0 KiB | 0 KiB | — |
| update-batched/plain | 677.4 µs | 709.6 µs | +44.4% |
| update-fanout/compose | 1.61 ms | 1.72 ms | -0.4% |
| update-fanout/memory/mounted | 1836 KiB | 1836 KiB | -0.4% |
| update-fanout/memory/teardown | 0 KiB | 0 KiB | — |
| update-fanout/plain | 1.03 ms | 1.19 ms | -9.1% |
| update-leaf/compose | 33.8 µs | 43.5 µs | -17.7% |
| update-leaf/memory/mounted | 2788 KiB | 2788 KiB | +0.3% |
| update-leaf/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| update-leaf/plain | 13.1 µs | 14.5 µs | -17.0% |
| update-repeated/compose | 256.0 µs | 297.9 µs | +68.2% |
| update-repeated/memory/mounted | 17 KiB | 17 KiB | +88.9% |
| update-repeated/memory/teardown | 8 KiB | 8 KiB | — |
| update-repeated/plain | 31.0 µs | 32.5 µs | +51.5% |
| virtual-filtered-list.extreme/compose/burst | 814.73 ms | 927.25 ms | +5.8% |
| virtual-filtered-list.extreme/compose/cold | 508.55 ms | 541.77 ms | +6.1% |
| virtual-filtered-list.extreme/compose/counts | 1349.77 ms | 1349.77 ms | +5.0% |
| virtual-filtered-list.extreme/compose/settle | 2.0 µs | 2.3 µs | -4.7% |
| virtual-filtered-list.extreme/compose/steady | 15.53 ms | 19.67 ms | -4.5% |
| virtual-filtered-list.extreme/compose/teardown | 514.4 µs | 569.2 µs | +0.4% |
| virtual-filtered-list.extreme/memory/mounted | 27930 KiB | 27930 KiB | -0.0% |
| virtual-filtered-list.extreme/memory/teardown | 8 KiB | 8 KiB | -11.1% |
| virtual-filtered-list.extreme/plain/burst | 829.13 ms | 853.46 ms | +13.9% |
| virtual-filtered-list.extreme/plain/cold | 513.94 ms | 525.46 ms | +9.6% |
| virtual-filtered-list.extreme/plain/settle | 2.4 µs | 2.9 µs | +13.0% |
| virtual-filtered-list.extreme/plain/steady | 11.20 ms | 16.67 ms | +8.8% |
| virtual-filtered-list.extreme/plain/teardown | 175.4 µs | 381.8 µs | -8.0% |
| virtual-filtered-list.large/compose/burst | 95.13 ms | 102.87 ms | -25.5% |
| virtual-filtered-list.large/compose/cold | 57.49 ms | 61.50 ms | -27.7% |
| virtual-filtered-list.large/compose/counts | 178.34 ms | 178.34 ms | -23.2% |
| virtual-filtered-list.large/compose/settle | 1.7 µs | 2.0 µs | -22.6% |
| virtual-filtered-list.large/compose/steady | 11.79 ms | 14.81 ms | -15.7% |
| virtual-filtered-list.large/compose/teardown | 243.0 µs | 277.9 µs | -24.9% |
| virtual-filtered-list.large/memory/mounted | 6306 KiB | 6306 KiB | +0.1% |
| virtual-filtered-list.large/memory/teardown | 1 KiB | 1 KiB | — |
| virtual-filtered-list.large/plain/burst | 84.33 ms | 88.26 ms | -27.2% |
| virtual-filtered-list.large/plain/cold | 54.30 ms | 56.15 ms | -25.8% |
| virtual-filtered-list.large/plain/settle | 2.0 µs | 2.8 µs | +0.0% |
| virtual-filtered-list.large/plain/steady | 6.50 ms | 8.77 ms | -16.8% |
| virtual-filtered-list.large/plain/teardown | 82.7 µs | 105.6 µs | -19.7% |
| virtual-filtered-list.medium/compose/burst | 24.26 ms | 27.06 ms | +46.6% |
| virtual-filtered-list.medium/compose/cold | 12.33 ms | 13.13 ms | +44.0% |
| virtual-filtered-list.medium/compose/counts | 57.67 ms | 57.67 ms | +39.4% |
| virtual-filtered-list.medium/compose/settle | 0.9 µs | 1.2 µs | -63.9% |
| virtual-filtered-list.medium/compose/steady | 11.84 ms | 14.58 ms | +36.9% |
| virtual-filtered-list.medium/compose/teardown | 187.7 µs | 261.2 µs | +38.4% |
| virtual-filtered-list.medium/memory/mounted | 1611 KiB | 1611 KiB | -0.6% |
| virtual-filtered-list.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| virtual-filtered-list.medium/plain/burst | 19.10 ms | 20.88 ms | +55.7% |
| virtual-filtered-list.medium/plain/cold | 11.75 ms | 12.54 ms | +63.3% |
| virtual-filtered-list.medium/plain/settle | 0.9 µs | 1.4 µs | -64.7% |
| virtual-filtered-list.medium/plain/steady | 5.86 ms | 7.99 ms | +61.6% |
| virtual-filtered-list.medium/plain/teardown | 63.5 µs | 106.5 µs | +50.7% |

## Trends over the last 9 main commits

```mermaid
xychart-beta
    title "animate-many/compose (median µs)"
    x-axis 1 --> 9
    line [3066.4, 6952.0, 6809.4, 7022.5, 6900.7, 5293.0, 3872.0, 6854.6, 6855.4]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [6516.1, 4147.1, 7924.7, 6800.6, 3730.7, 6629.9, 7069.6, 8045.7, 6446.7]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [11407.1, 8355.0, 11077.8, 10540.2, 5143.0, 10831.6, 10532.7, 11609.3, 9123.7]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [68091.2, 47605.1, 84532.8, 70635.7, 38164.3, 70361.3, 65787.2, 84392.1, 66069.4]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.0, 1.0, 1.1, 1.4, 0.4, 1.3, 1.4, 1.1, 0.8]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [25890.3, 17137.2, 33073.2, 27209.7, 14974.2, 26354.8, 22766.0, 33169.8, 25913.2]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [2475.2, 1994.0, 2796.3, 2870.3, 1046.7, 2665.2, 2373.1, 2903.9, 2221.8]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [3896.2, 3809.1, 3862.2, 1873.3, 1818.8, 3132.6, 3304.0, 1845.5, 3949.1]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [5692.2, 5515.9, 5845.7, 3938.9, 3716.9, 4867.6, 5782.8, 4150.4, 5496.4]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [57607.9, 56296.6, 57762.9, 28652.9, 28589.4, 47453.0, 49293.5, 28964.9, 62964.9]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.2, 0.8, 0.8, 0.6, 0.6, 0.7, 1.7, 0.8, 0.7]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [26697.4, 26221.7, 26378.1, 12144.9, 11941.8, 20669.0, 22107.0, 12098.4, 27192.9]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [1432.5, 1092.3, 1223.6, 766.2, 717.1, 1110.1, 1527.9, 640.8, 1258.0]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [598.2, 606.3, 1380.7, 1026.7, 1342.2, 1375.4, 581.3, 1323.8, 994.6]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [1178.6, 1128.0, 1758.0, 1216.6, 1529.7, 1743.3, 714.0, 1654.2, 1314.0]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [10635.9, 10387.5, 24309.0, 17291.5, 23136.2, 24026.4, 10503.0, 22483.8, 18522.5]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [0.3, 0.4, 0.7, 0.5, 0.6, 1.1, 0.3, 0.7, 0.5]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [4717.9, 4534.1, 10683.3, 7716.1, 10557.1, 10514.6, 4601.4, 10453.8, 7583.5]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [212.7, 211.0, 408.9, 271.2, 366.3, 479.0, 169.5, 395.0, 285.5]
```

```mermaid
xychart-beta
    title "branch-swap/compose (median µs)"
    x-axis 1 --> 9
    line [3609.5, 2319.6, 3549.8, 3405.8, 1982.7, 3084.6, 4391.8, 4174.1, 3029.6]
```

```mermaid
xychart-beta
    title "cold-mount-100/compose (median µs)"
    x-axis 1 --> 9
    line [592.6, 519.9, 885.4, 445.1, 390.3, 654.2, 754.1, 718.7, 593.0]
```

```mermaid
xychart-beta
    title "cold-mount-1000/compose (median µs)"
    x-axis 1 --> 9
    line [8085.8, 5389.9, 8549.6, 6933.2, 5008.1, 8021.9, 4561.7, 3463.8, 7354.0]
```

```mermaid
xychart-beta
    title "cold-mount-10000/compose (median µs)"
    x-axis 1 --> 9
    line [73945.7, 98256.1, 94238.7, 59096.4, 91513.5, 96319.1, 82259.3, 63209.5, 90166.9]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [572777.3, 535083.2, 832744.6, 637093.8, 901025.5, 925169.9, 449606.0, 895257.3, 646273.1]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [350893.5, 328646.9, 515839.7, 377498.6, 538166.5, 557904.7, 284386.4, 531496.5, 388897.8]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [961903.0, 895177.9, 1510853.2, 1085251.1, 1502399.1, 1611360.1, 785389.3, 1377677.2, 1083973.3]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.8, 2.4, 2.2, 2.6, 2.1, 2.4, 2.2, 2.2, 2.2]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [12594.0, 11681.8, 22844.9, 17958.7, 23673.8, 23322.2, 11155.7, 22361.8, 16709.6]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [1086.6, 1137.9, 1208.9, 1019.3, 1268.8, 1343.4, 835.2, 1224.3, 999.5]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [140083.3, 135962.2, 137048.1, 79047.3, 75260.8, 109163.6, 121880.1, 81408.7, 136478.5]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [80791.9, 79866.7, 78358.1, 46545.2, 43756.7, 58099.4, 68778.5, 44967.9, 78451.2]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [269572.2, 259528.8, 247425.1, 134287.8, 131710.6, 188468.8, 214177.9, 150547.4, 244022.4]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.0, 2.0, 1.8, 1.2, 2.0, 1.9, 2.7, 1.9, 1.5]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [17382.0, 15842.8, 15303.1, 9007.1, 8005.9, 11625.0, 12919.6, 8353.8, 15332.2]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [517.4, 507.1, 530.1, 308.6, 332.9, 426.4, 518.6, 361.1, 504.0]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [49689.5, 40264.0, 63124.3, 54341.9, 32137.1, 50132.9, 54919.9, 65755.5, 48028.9]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [28216.2, 22726.8, 35966.3, 30152.5, 18330.7, 26916.9, 30108.2, 37334.5, 26866.3]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [101676.4, 85010.8, 128707.0, 106187.2, 62031.4, 100197.9, 110205.4, 130840.7, 101043.6]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.2, 2.3, 1.8, 2.4, 0.6, 1.9, 2.1, 1.9, 1.6]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [12139.2, 8725.2, 12812.2, 11984.4, 6457.6, 10768.7, 11263.0, 14779.4, 11549.9]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [242.3, 222.0, 291.3, 267.8, 145.7, 280.3, 272.6, 313.2, 239.6]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [8748.3, 13808.9, 14242.7, 14836.6, 15612.8, 11708.1, 9145.2, 14405.4, 16835.5]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [306.9, 503.4, 495.3, 587.1, 524.3, 393.3, 329.8, 528.9, 514.1]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [12107.6, 25337.6, 22769.2, 21520.0, 21897.1, 18320.5, 13760.6, 40266.5, 22521.9]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [0.6, 1.1, 1.0, 0.8, 0.9, 0.8, 1.1, 1.0, 0.8]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [461.4, 853.9, 896.4, 863.9, 868.1, 685.9, 487.3, 868.8, 860.5]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [300.0, 528.8, 524.0, 500.2, 563.4, 420.3, 338.6, 537.9, 520.8]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [7315.2, 6455.4, 7861.5, 5932.0, 3664.7, 4865.3, 7559.3, 4721.2, 7058.8]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [321.9, 311.0, 312.5, 196.1, 172.6, 252.5, 330.9, 182.8, 284.4]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [15457.3, 15616.4, 15030.0, 9619.3, 9006.3, 13093.5, 13144.9, 8826.0, 16562.2]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [0.9, 0.8, 0.8, 0.7, 0.5, 0.6, 1.5, 0.6, 0.8]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [871.8, 849.7, 860.9, 434.1, 430.1, 673.3, 710.2, 432.8, 871.4]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [255.7, 242.4, 250.0, 139.2, 128.8, 202.4, 271.9, 146.7, 239.1]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [1884.9, 1716.2, 3396.7, 2022.7, 3071.6, 3206.4, 1423.0, 2945.6, 2193.3]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [150.8, 125.0, 199.3, 164.2, 201.4, 241.3, 96.5, 215.2, 146.9]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [4488.4, 3035.8, 6218.8, 3927.1, 6262.4, 5300.8, 2445.0, 6213.6, 3921.4]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [0.6, 0.4, 0.7, 0.5, 0.7, 0.7, 0.4, 0.7, 0.5]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [451.5, 440.8, 842.9, 675.3, 830.4, 863.8, 440.0, 847.9, 676.6]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [71.1, 68.2, 109.1, 88.9, 111.5, 129.0, 60.7, 120.6, 86.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [36450.3, 44418.2, 46637.6, 27103.8, 44981.1, 29543.4, 40066.6, 42717.5, 44228.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [22317.0, 30608.9, 30755.4, 23786.9, 40570.4, 19153.7, 28343.7, 27744.4, 27490.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [157183.8, 226408.0, 207640.3, 143081.0, 226763.2, 128206.5, 171885.4, 169973.5, 181184.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.5, 2.2, 2.0, 1.5, 2.5, 2.0, 1.5, 2.8, 1.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [38679.7, 58936.7, 52064.1, 26669.0, 61811.9, 29113.4, 45991.2, 49404.1, 48062.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [870.1, 1178.4, 1115.4, 774.0, 1244.2, 740.3, 1065.2, 1427.6, 1116.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [13822.3, 12671.8, 13643.0, 12953.8, 6143.0, 14759.8, 12995.7, 14364.3, 10095.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [8768.9, 8903.6, 12727.0, 12419.1, 6935.5, 10733.2, 8614.4, 12686.5, 8728.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [56991.3, 49197.8, 64112.9, 60677.1, 28433.4, 57838.2, 57671.1, 70144.7, 46269.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.0, 2.2, 1.6, 1.9, 0.7, 1.8, 2.0, 2.1, 1.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [16083.5, 12191.6, 17784.2, 14312.6, 8120.2, 16453.6, 16282.2, 19046.9, 13218.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [346.1, 297.1, 375.4, 338.9, 182.0, 354.6, 362.7, 426.3, 301.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [4810.6, 5385.1, 7593.1, 5112.8, 6878.8, 6650.5, 3288.9, 8470.5, 5951.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [3510.0, 3688.3, 5372.0, 3383.4, 4891.2, 5151.2, 2409.5, 5430.8, 4134.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [22176.2, 21779.2, 33203.4, 22936.2, 34013.7, 31437.1, 16138.3, 33707.6, 26238.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [0.9, 1.3, 1.1, 0.9, 1.2, 1.1, 0.5, 1.2, 0.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [5091.1, 4800.2, 8300.0, 5909.2, 8141.7, 8237.8, 3705.4, 8586.3, 6200.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [138.2, 141.4, 189.4, 143.6, 208.6, 209.6, 100.5, 229.5, 158.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [37375.3, 42100.8, 41076.4, 43172.5, 28018.8, 41299.1, 37898.2, 49926.6, 32228.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [28909.8, 26506.8, 29632.4, 23700.6, 16677.6, 22767.7, 28551.6, 34974.5, 24971.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [312089.2, 264728.7, 287119.4, 313931.9, 170730.7, 360065.4, 295547.6, 321512.6, 266009.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.6, 2.4, 1.9, 2.3, 2.1, 2.0, 2.6, 2.3, 2.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [144362.2, 138910.8, 151388.1, 146004.0, 82765.7, 135865.1, 159344.1, 153493.1, 124879.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [1011.3, 1046.8, 1153.3, 1158.5, 635.9, 966.8, 1114.4, 1149.1, 904.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [11392.1, 16006.5, 14237.9, 8830.8, 17379.2, 12261.9, 15344.8, 11689.2, 15070.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [10645.8, 12312.2, 10388.0, 8077.7, 10611.2, 7955.1, 10922.4, 8068.7, 14082.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [86389.6, 118638.8, 108507.3, 60853.6, 129304.7, 73934.5, 103471.9, 90339.3, 110422.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.5, 2.3, 1.6, 1.2, 1.9, 1.8, 1.4, 2.4, 1.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [40309.4, 56606.6, 50910.5, 29130.8, 63002.5, 34672.3, 46041.0, 42900.9, 49581.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [312.8, 448.9, 398.2, 225.9, 469.2, 278.4, 371.5, 321.9, 410.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [8485.7, 8733.8, 7811.5, 5053.3, 3913.2, 6868.0, 7233.3, 5340.6, 7477.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [5123.1, 5090.8, 6479.6, 3545.3, 2939.0, 4644.6, 4523.8, 3418.2, 5696.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [60621.5, 66177.5, 62123.7, 40694.0, 32773.8, 53100.7, 61894.0, 40328.5, 62517.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.3, 1.6, 1.6, 1.3, 0.7, 1.6, 2.2, 1.6, 1.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [22448.9, 25049.9, 23583.9, 14477.3, 11837.6, 20245.0, 21639.9, 16174.8, 24137.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [239.6, 252.1, 242.6, 155.2, 117.2, 204.8, 234.3, 165.7, 225.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [51119.4, 42743.7, 45181.7, 38370.3, 33338.8, 36817.5, 52885.4, 40171.8, 45201.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [31173.0, 29216.5, 29632.0, 19346.5, 15753.8, 25514.4, 27023.7, 28801.0, 30156.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [276895.4, 231546.3, 239558.4, 151482.1, 126042.6, 202144.3, 260291.3, 188217.0, 247726.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.3, 2.0, 2.1, 2.3, 1.7, 2.3, 2.5, 2.4, 2.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [103496.4, 98719.9, 87903.0, 60700.8, 49561.0, 86888.2, 112427.9, 73292.0, 89321.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [1459.8, 1163.1, 1253.7, 814.1, 700.5, 1030.1, 1378.4, 1097.2, 1200.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [9662.4, 8486.1, 12526.7, 11002.8, 13446.7, 15085.5, 8379.8, 14725.8, 12360.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [7331.9, 8413.6, 11406.1, 12037.1, 13160.2, 12731.3, 5986.0, 12621.4, 9295.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [62489.1, 65083.5, 93016.9, 76013.1, 98085.9, 98527.4, 51915.0, 93148.1, 75454.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.6, 1.6, 1.7, 1.3, 2.0, 1.7, 1.1, 1.5, 1.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [17762.3, 18587.4, 28783.0, 23340.3, 29455.6, 33017.1, 15327.8, 30626.8, 24307.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [221.0, 244.4, 350.0, 314.6, 386.7, 384.2, 198.7, 367.8, 292.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [5597.4, 5043.1, 7507.7, 7112.6, 3457.9, 6040.7, 6526.1, 8643.7, 5508.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [4098.3, 3677.5, 4917.8, 4309.4, 3034.9, 4284.9, 4653.8, 4991.2, 3768.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [31911.5, 26270.5, 38265.0, 35758.5, 17029.0, 34046.6, 35379.4, 40732.1, 30879.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.0, 1.7, 1.0, 1.9, 0.6, 1.6, 1.4, 1.1, 1.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [10781.6, 9751.3, 14145.6, 11476.1, 7059.7, 11350.6, 12871.8, 13831.7, 11296.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [163.7, 158.3, 209.3, 186.8, 106.1, 185.4, 191.4, 206.3, 162.9]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [18098.0, 16855.7, 18205.9, 16320.2, 17509.3, 20570.2, 12111.1, 9626.9, 14530.4]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [102015.1, 100238.6, 110792.2, 98791.5, 86043.8, 111031.3, 76896.5, 67500.7, 96114.6]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [358907.4, 324615.1, 382570.8, 305419.8, 287951.5, 321960.0, 269473.8, 204158.1, 309577.5]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.8, 1.9, 2.1, 1.7, 1.7, 1.9, 2.0, 1.6, 2.0]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [90630.1, 81412.5, 95946.8, 80410.1, 73987.2, 97008.8, 73582.9, 55127.3, 75657.9]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [52871.1, 45496.4, 55490.6, 46463.3, 40502.6, 51955.2, 48082.4, 36583.8, 51571.9]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [9879.6, 9266.1, 9580.3, 5350.4, 5000.3, 7911.5, 9138.6, 5431.2, 9235.0]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [42924.1, 40697.9, 38453.5, 27622.0, 23282.1, 34452.0, 37474.1, 28353.5, 43086.1]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [159260.0, 136585.0, 136418.7, 92540.6, 75726.6, 116205.8, 145691.2, 92771.0, 140925.6]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.1, 1.5, 1.6, 1.6, 1.2, 1.6, 2.2, 2.0, 1.5]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [56879.3, 47700.5, 50360.1, 29499.8, 25632.1, 39134.3, 49897.4, 34021.1, 47956.3]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [16802.1, 13908.2, 14198.2, 10974.4, 8656.6, 14230.7, 18168.2, 12469.9, 13648.1]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [4273.0, 4064.7, 6941.6, 5470.1, 7091.9, 7241.2, 3606.4, 7034.6, 5526.8]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [14214.0, 12986.0, 18998.1, 20759.9, 20252.4, 22768.0, 13202.3, 21049.2, 13647.3]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [60159.0, 56773.8, 91261.8, 68607.4, 94840.7, 109979.7, 46066.0, 91208.7, 64907.3]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.9, 1.7, 1.6, 1.2, 1.4, 1.7, 1.0, 1.6, 1.1]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [20781.1, 19484.3, 34314.8, 25155.4, 35931.8, 41195.2, 16863.5, 34416.2, 24878.1]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [5912.5, 5137.9, 6370.7, 5086.2, 6899.6, 7628.9, 3519.9, 6540.0, 5189.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [82088.2, 67803.4, 81772.9, 78539.9, 42827.9, 75203.6, 74827.0, 82527.1, 66483.1]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [23851.0, 19385.3, 27237.7, 29579.2, 16205.6, 25539.7, 24187.8, 26855.5, 23002.8]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [215972.6, 170155.4, 218067.6, 205395.8, 129067.0, 218719.0, 211515.3, 231455.2, 210915.3]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.5, 2.9, 2.1, 2.6, 1.9, 2.5, 2.5, 2.2, 2.2]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [46499.2, 63403.0, 50693.5, 50493.5, 26077.2, 49900.4, 50230.3, 46598.9, 37383.9]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [13254.3, 13259.6, 13403.6, 14674.6, 8911.1, 13251.9, 13962.6, 12345.3, 11488.0]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [23829.2, 21410.5, 26910.9, 27013.4, 14236.6, 24208.8, 23728.7, 26738.0, 21901.0]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [9046.6, 8698.0, 11112.7, 11237.4, 6143.2, 9343.6, 10313.4, 10994.3, 9966.1]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [66263.4, 60081.6, 78201.5, 74218.9, 39404.5, 69251.9, 67363.7, 81625.4, 60775.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.2, 2.3, 1.7, 2.3, 1.1, 2.0, 1.9, 1.9, 1.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [15970.8, 12947.8, 17610.3, 17826.6, 11242.1, 15433.1, 16862.1, 19331.5, 15639.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [3313.5, 2966.7, 2967.8, 3445.2, 1914.9, 3360.7, 3073.0, 3235.1, 2831.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [10053.5, 13258.0, 10542.4, 6875.4, 13588.9, 8448.7, 11354.4, 7488.6, 12592.2]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [4425.1, 5999.0, 4925.5, 3251.8, 5590.3, 3641.1, 6085.1, 3730.8, 5133.8]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [26589.7, 40004.4, 35054.4, 23518.5, 43107.2, 20771.7, 35914.6, 21858.7, 37161.7]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.0, 1.5, 1.0, 0.9, 2.0, 1.7, 0.9, 1.4, 1.3]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [6593.9, 10265.5, 7799.1, 4375.5, 8267.5, 5658.1, 7360.6, 5130.7, 7683.1]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [909.1, 1375.7, 1014.9, 866.7, 1424.9, 998.3, 1033.6, 908.9, 1071.7]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [83025.5, 131890.1, 139155.5, 102900.1, 157933.2, 128808.8, 112296.6, 116395.3, 114298.7]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [27112.7, 32898.9, 35114.3, 19901.5, 33750.6, 20001.5, 26640.6, 28100.9, 32036.3]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [297306.3, 392730.6, 375325.7, 279449.1, 480733.4, 287660.1, 322358.3, 325178.3, 353539.8]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.9, 2.5, 2.5, 2.5, 2.8, 2.8, 1.9, 3.2, 2.2]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [104435.7, 129482.8, 118556.7, 87490.4, 162273.4, 97620.2, 109193.4, 117043.1, 121722.7]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [11409.1, 14374.0, 14539.1, 12187.9, 16437.6, 13724.4, 12383.5, 14144.5, 12818.0]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [37687.9, 36619.3, 41760.4, 43897.0, 20442.0, 38915.7, 45255.8, 44982.1, 35007.1]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [9427.2, 7416.6, 10731.1, 9936.2, 7900.6, 9398.3, 9938.4, 11517.2, 8967.2]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [118464.0, 105642.9, 132017.4, 113098.8, 71443.8, 123886.3, 120574.8, 132620.0, 102062.1]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.0, 2.4, 1.7, 2.1, 1.2, 2.1, 2.6, 1.8, 1.9]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [36383.7, 29649.6, 42899.0, 36038.5, 24323.9, 38124.3, 41637.8, 39291.2, 32139.9]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [3319.5, 3173.8, 3204.1, 3765.1, 2211.6, 3346.3, 3590.8, 3373.3, 3109.6]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [21304.8, 17609.9, 19632.8, 19428.5, 17153.1, 19140.6, 13680.9, 10539.8, 16358.8]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [5522.9, 4875.0, 6616.8, 5391.1, 4632.0, 5418.8, 3748.9, 4334.6, 6279.5]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [73432.0, 63426.8, 72731.7, 66518.2, 62374.3, 65043.1, 44806.4, 37229.6, 54883.7]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.9, 1.0, 1.3, 1.3, 1.6, 1.5, 1.7, 0.8, 1.7]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [21627.0, 18049.0, 19673.0, 19997.6, 17951.3, 19922.5, 12042.0, 9569.3, 14921.4]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [1421.5, 998.7, 1251.6, 1111.8, 1133.0, 1281.3, 1123.1, 703.5, 1334.7]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [28431.3, 29661.9, 27082.8, 16711.4, 16256.2, 24942.1, 43425.5, 19047.2, 29329.5]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [25491.4, 23933.9, 25087.3, 17441.6, 14649.4, 20662.4, 25099.0, 15188.8, 24417.5]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [103374.1, 95880.0, 93198.2, 60028.1, 47563.7, 81598.1, 107155.7, 73201.1, 109348.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.8, 1.9, 1.6, 1.8, 1.2, 1.8, 2.9, 1.7, 1.6]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [4152.6, 3939.8, 3787.2, 2841.3, 2146.5, 3306.4, 4976.5, 2718.0, 3853.1]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [12752.1, 12268.9, 12210.0, 9099.8, 7657.4, 10987.1, 15200.5, 8955.6, 12069.7]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [12559.3, 12285.7, 12193.2, 7053.5, 7719.0, 11258.9, 13191.0, 7344.2, 12331.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [10065.7, 12236.3, 12145.6, 7446.2, 7340.1, 9091.0, 13532.7, 6013.0, 11254.0]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [47228.6, 41552.7, 49545.9, 25620.0, 20398.0, 37816.7, 43649.2, 22653.6, 39155.5]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.2, 1.3, 1.2, 1.2, 1.0, 1.4, 2.3, 1.0, 1.1]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [1880.4, 1925.6, 1869.1, 1138.5, 1131.8, 1602.8, 2237.8, 1167.6, 1834.0]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [3848.1, 4042.8, 3927.2, 2747.9, 2759.1, 3661.9, 4768.6, 2555.1, 3867.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [2692.8, 4883.0, 4638.9, 4912.8, 5026.0, 4027.1, 3463.0, 5225.9, 5403.1]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [3511.6, 5344.2, 4334.1, 5274.7, 5181.4, 4438.3, 3135.4, 3961.6, 6491.8]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [11899.6, 20010.0, 21389.0, 22972.4, 20570.5, 16988.5, 13171.6, 20709.0, 21150.4]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [0.8, 0.8, 0.9, 0.8, 0.9, 0.7, 1.0, 0.9, 1.0]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [546.9, 864.1, 884.8, 935.5, 884.1, 730.7, 550.6, 847.0, 1000.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [793.8, 1245.8, 1305.4, 1265.7, 1223.0, 1121.5, 872.8, 1219.1, 1413.7]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [38306.7, 27292.5, 30271.6, 28243.8, 29005.1, 33304.8, 17732.8, 18157.2, 28538.7]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [26392.1, 25728.0, 24789.0, 25091.7, 22204.5, 27675.8, 16504.3, 15582.8, 20883.5]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [146562.2, 118482.8, 130233.0, 121188.5, 115298.7, 136017.8, 81709.5, 71988.5, 111855.8]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.1, 1.2, 1.5, 1.9, 1.9, 1.9, 2.1, 1.3, 1.9]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [35077.9, 31134.3, 31374.2, 30446.4, 26594.6, 34700.1, 15230.3, 13680.6, 23826.6]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [14166.4, 14892.9, 12081.1, 11856.0, 11411.3, 12865.8, 9445.8, 8055.2, 11851.0]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [16371.6, 13675.4, 14796.5, 8143.5, 6921.8, 11737.9, 14799.3, 7533.0, 13435.0]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [13125.5, 12164.0, 12241.7, 8754.9, 8206.7, 13934.9, 13016.5, 8828.1, 12657.0]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [71347.2, 67401.3, 63961.0, 38511.1, 29591.2, 53168.0, 63281.7, 37574.1, 65780.9]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.8, 1.6, 1.8, 1.2, 0.8, 1.7, 2.4, 1.1, 1.2]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [17130.8, 15636.5, 15592.5, 6886.2, 5727.0, 10867.3, 12969.4, 6304.5, 15282.4]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [4985.7, 4474.5, 4408.6, 3132.6, 2490.9, 4133.6, 4825.8, 2950.0, 4383.6]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [5454.2, 5016.4, 5182.8, 4977.7, 4705.2, 5603.2, 3075.2, 2510.4, 4189.9]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [6039.1, 4145.2, 5211.5, 4920.9, 4320.8, 5134.9, 2887.4, 2303.4, 4736.5]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [27680.1, 23447.7, 25731.3, 23381.3, 18913.6, 25673.9, 12663.2, 11587.3, 16963.5]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.2, 0.8, 1.1, 0.8, 1.0, 1.0, 0.9, 0.5, 0.8]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [6474.9, 6388.6, 6421.2, 6421.9, 4371.6, 6821.4, 2934.7, 2369.4, 4152.8]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [1477.1, 1273.6, 1329.9, 1262.9, 1139.0, 1501.8, 949.3, 700.5, 1154.9]
```

```mermaid
xychart-beta
    title "events/compose (median µs)"
    x-axis 1 --> 9
    line [10464.1, 9121.0, 11019.8, 9922.2, 6474.8, 13785.7, 12735.9, 13242.7, 10469.1]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [7448.2, 5545.2, 8042.0, 7887.1, 4081.4, 7770.0, 7596.4, 9007.9, 7263.5]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [18874.4, 15878.8, 20409.9, 18550.5, 11659.9, 18757.1, 18454.7, 22287.5, 17322.6]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [34335.8, 23488.3, 37816.7, 33632.2, 18349.1, 30508.1, 33686.5, 36844.1, 30794.3]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.6, 1.4, 1.2, 2.0, 0.7, 1.4, 1.7, 1.8, 1.1]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [245.7, 207.7, 236.8, 270.8, 131.2, 267.8, 236.9, 307.4, 220.9]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [2590.5, 2153.7, 2312.0, 3007.8, 1361.7, 3037.5, 2600.4, 3046.3, 2216.3]
```

```mermaid
xychart-beta
    title "inspector.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [3270.5, 4234.2, 4065.4, 2059.0, 4547.1, 2198.1, 4192.0, 2232.7, 4637.6]
```

```mermaid
xychart-beta
    title "inspector.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [6003.2, 9644.5, 6469.4, 5148.0, 8219.5, 4556.1, 6687.1, 5165.1, 8453.0]
```

```mermaid
xychart-beta
    title "inspector.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [15848.8, 18252.6, 18863.7, 13882.7, 21141.3, 12984.7, 17583.5, 13489.3, 21616.7]
```

```mermaid
xychart-beta
    title "inspector.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [0.8, 1.2, 0.8, 0.7, 1.8, 0.6, 0.8, 0.5, 1.3]
```

```mermaid
xychart-beta
    title "inspector.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [184.9, 255.0, 227.5, 142.8, 294.1, 145.9, 234.4, 141.4, 297.1]
```

```mermaid
xychart-beta
    title "inspector.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [939.1, 1289.4, 1054.6, 747.2, 1560.4, 839.3, 1087.1, 752.4, 1359.5]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [652.7, 1463.0, 1421.7, 1608.0, 1429.8, 1117.0, 914.2, 1501.6, 1471.1]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [1084.4, 2117.8, 1731.0, 2819.9, 1695.4, 1733.6, 1427.9, 2126.8, 1933.7]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [2345.3, 5474.4, 4793.9, 6353.6, 4594.8, 3720.8, 3175.4, 4664.1, 6578.4]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [0.4, 0.6, 0.6, 0.7, 0.6, 0.5, 0.7, 0.6, 0.7]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [101.1, 207.3, 210.4, 235.5, 200.8, 172.3, 158.6, 210.0, 222.8]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [183.0, 391.0, 377.6, 430.5, 364.3, 301.9, 329.8, 385.2, 439.6]
```

```mermaid
xychart-beta
    title "keyed-append/compose (median µs)"
    x-axis 1 --> 9
    line [1217.7, 1121.3, 1123.5, 616.2, 544.3, 830.1, 912.0, 582.5, 1181.1]
```

```mermaid
xychart-beta
    title "keyed-insert/compose (median µs)"
    x-axis 1 --> 9
    line [1418.3, 1388.8, 2985.6, 1957.4, 2688.9, 2692.3, 1280.3, 2815.6, 1985.6]
```

```mermaid
xychart-beta
    title "keyed-prepend/compose (median µs)"
    x-axis 1 --> 9
    line [3339.2, 2323.0, 4385.8, 3245.3, 1938.3, 3308.6, 2890.6, 4215.3, 3235.5]
```

```mermaid
xychart-beta
    title "keyed-remove/compose (median µs)"
    x-axis 1 --> 9
    line [1834.7, 2550.5, 2731.1, 1302.2, 2681.1, 1287.8, 2556.8, 1286.6, 2631.5]
```

```mermaid
xychart-beta
    title "keyed-replace/compose (median µs)"
    x-axis 1 --> 9
    line [56638.2, 52082.4, 51437.5, 31895.5, 28628.9, 45286.9, 50297.1, 36995.3, 49638.2]
```

```mermaid
xychart-beta
    title "keyed-reverse/compose (median µs)"
    x-axis 1 --> 9
    line [1366.2, 1329.2, 2904.2, 2262.2, 3010.7, 2985.1, 1281.3, 2955.9, 2227.3]
```

```mermaid
xychart-beta
    title "keyed-rotate/compose (median µs)"
    x-axis 1 --> 9
    line [2837.0, 2918.3, 3001.8, 1448.0, 1299.3, 2297.1, 2375.3, 1351.1, 2946.5]
```

```mermaid
xychart-beta
    title "keyed-shuffle/compose (median µs)"
    x-axis 1 --> 9
    line [1337.6, 3134.0, 3010.8, 3078.2, 3095.3, 2318.3, 1502.6, 3006.3, 3079.7]
```

```mermaid
xychart-beta
    title "mount-cycles/compose (median µs)"
    x-axis 1 --> 9
    line [24941.5, 23043.1, 23398.1, 16185.9, 17338.0, 23324.6, 25604.5, 17252.1, 24893.2]
```

```mermaid
xychart-beta
    title "mount-dispose/compose (median µs)"
    x-axis 1 --> 9
    line [7076.9, 9579.0, 7445.0, 4609.4, 10316.6, 5700.8, 7319.8, 6423.1, 10826.5]
```

```mermaid
xychart-beta
    title "ordered-window-scroll/compose (median µs)"
    x-axis 1 --> 9
    line [412.1, 498.2, 504.6, 260.5, 499.9, 279.8, 497.2, 283.6, 497.2]
```

```mermaid
xychart-beta
    title "projection-keyed-append-500/compose (median µs)"
    x-axis 1 --> 9
    line [5754.2, 14069.9, 10109.7, 13717.9, 13328.0, 8025.1, 6147.2, 13427.8, 13434.0]
```

```mermaid
xychart-beta
    title "projection-observe-100/compose (median µs)"
    x-axis 1 --> 9
    line [1160.9, 1688.5, 1375.7, 934.9, 1415.9, 968.3, 1530.8, 1005.7, 1566.5]
```

```mermaid
xychart-beta
    title "projection-selection-500/compose (median µs)"
    x-axis 1 --> 9
    line [1347.5, 1257.8, 1305.3, 1261.8, 1068.3, 1262.7, 719.6, 676.6, 1079.6]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [31592.1, 26430.2, 30086.2, 22463.2, 21523.7, 24285.9, 20744.8, 16546.0, 24652.7]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [11079.4, 9876.1, 11841.3, 12194.2, 9875.0, 9544.3, 6930.8, 6222.6, 8504.1]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [216069.1, 186166.0, 209496.7, 210635.3, 184504.6, 191644.0, 125173.0, 98138.8, 166182.6]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.2, 1.2, 1.5, 1.2, 1.8, 1.8, 2.0, 1.3, 1.8]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [90044.4, 84419.8, 84931.4, 87195.8, 80201.7, 82861.3, 47222.8, 45168.3, 64460.1]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [1242.8, 991.8, 1179.9, 1042.6, 955.6, 1098.7, 856.5, 664.8, 1049.1]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [23109.8, 30942.5, 25739.8, 16117.3, 28514.7, 16486.9, 22867.7, 19154.9, 27915.9]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [4352.7, 6212.1, 6516.0, 3797.0, 6126.6, 3638.2, 6242.7, 3964.5, 5529.0]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [150813.2, 189240.1, 180380.0, 102688.1, 198929.2, 99484.8, 182090.2, 118447.5, 185417.9]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.3, 1.9, 1.8, 1.0, 2.6, 1.7, 1.1, 2.1, 1.9]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [67819.6, 92259.3, 88664.7, 47707.5, 91878.3, 48122.8, 87585.4, 50539.3, 89850.7]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [835.3, 1495.8, 1118.6, 692.5, 1280.0, 748.7, 974.1, 1020.3, 1291.8]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [20349.9, 15428.8, 24654.7, 18400.6, 17606.8, 19713.7, 13415.7, 12028.0, 17466.5]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [4709.8, 4295.8, 3803.5, 4326.4, 3189.5, 5236.1, 3027.0, 1949.6, 3688.0]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [147623.1, 136904.9, 148677.3, 143451.4, 123739.5, 146270.1, 80785.3, 71179.9, 112733.2]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.2, 0.8, 1.4, 1.1, 1.2, 1.6, 1.9, 0.8, 1.6]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [69181.6, 65753.4, 65422.7, 66617.4, 56988.1, 67387.5, 36236.5, 32601.2, 50828.0]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [1053.9, 734.4, 1016.7, 799.9, 697.2, 1040.7, 717.3, 442.3, 842.5]
```

```mermaid
xychart-beta
    title "scene-3d/compose (median µs)"
    x-axis 1 --> 9
    line [10050.2, 7649.9, 9011.1, 8309.7, 6569.6, 8881.9, 4148.2, 3349.5, 6014.4]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [111388.5, 145081.3, 133361.3, 117151.1, 134745.1, 130563.4, 100054.0, 97734.6, 150799.8]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [4.4, 4.2, 4.6, 3.8, 4.3, 3.6, 4.3, 4.1, 4.2]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [347844.7, 331552.2, 361578.0, 315896.8, 329766.9, 342300.6, 247069.9, 246438.3, 339456.9]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.2, 2.2, 2.4, 2.0, 2.0, 1.8, 2.5, 2.3, 2.1]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [189371.2, 170051.3, 208681.3, 177283.5, 150659.9, 182076.0, 153677.9, 126781.8, 152483.2]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [2.3, 1.9, 2.4, 2.0, 1.9, 2.0, 3.2, 2.2, 2.3]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [55471.8, 41682.9, 47858.1, 38268.2, 43969.3, 40155.1, 44128.3, 33941.7, 39588.5]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [4.1, 3.4, 4.0, 3.9, 3.5, 4.1, 3.8, 3.8, 4.3]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [152922.2, 127280.8, 125332.5, 126145.5, 114593.6, 135971.7, 76286.2, 84978.1, 107871.8]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.9, 1.9, 2.0, 1.9, 1.6, 1.8, 2.1, 1.8, 1.9]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [70217.2, 67586.5, 71040.2, 71631.7, 65993.8, 72685.1, 47925.9, 48387.7, 67198.3]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [1.9, 1.7, 2.1, 1.7, 1.5, 2.2, 2.3, 1.9, 2.2]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [9419.6, 16119.8, 14877.2, 8687.9, 14987.9, 10928.0, 10870.2, 10819.3, 14465.4]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [2.9, 4.7, 3.3, 3.8, 4.1, 3.9, 2.9, 4.0, 3.4]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [32366.0, 44739.0, 39841.4, 32409.8, 45078.7, 32597.1, 35938.6, 36686.8, 40200.6]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.2, 1.5, 1.5, 1.5, 1.7, 1.9, 1.0, 1.8, 1.3]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [16834.7, 22422.0, 19376.8, 14924.2, 24496.6, 14205.7, 21114.2, 18033.5, 19508.8]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [1.2, 1.7, 1.6, 1.9, 2.0, 2.0, 0.9, 2.0, 1.4]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [131626.4, 122408.9, 135923.1, 79047.5, 80922.8, 114343.7, 133949.1, 90807.2, 124292.5]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [11274.4, 10752.6, 11344.1, 6370.1, 6350.3, 8515.9, 10293.5, 7967.4, 10297.6]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [280294.2, 255499.9, 266526.7, 181289.9, 146193.2, 201768.3, 242178.1, 168507.4, 260099.7]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.7, 1.7, 2.0, 1.9, 2.2, 1.9, 2.3, 2.1, 1.8]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [54938.1, 53195.1, 53842.8, 26463.3, 28588.3, 37962.4, 40035.6, 33240.0, 53446.2]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [4193.8, 3229.5, 4161.6, 1998.5, 2138.0, 3152.1, 4304.1, 3025.3, 3224.2]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [24854.0, 36908.9, 37836.4, 24036.9, 44486.3, 21756.2, 31049.8, 27386.1, 37067.9]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [3382.2, 4654.1, 3405.2, 2395.1, 3754.2, 2566.4, 3158.1, 3069.9, 3298.8]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [50109.8, 74015.2, 77275.2, 40372.0, 80626.4, 41172.5, 66448.4, 47004.9, 74256.6]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.2, 1.9, 1.6, 1.6, 2.3, 1.5, 1.0, 2.5, 1.2]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [12804.6, 19446.0, 19168.6, 10456.3, 19958.5, 10121.6, 18226.0, 11259.8, 18123.0]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [635.6, 862.7, 813.6, 579.0, 1398.1, 511.6, 763.5, 704.6, 926.9]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [7485.6, 7465.0, 13238.7, 8798.9, 12763.6, 13901.7, 5485.9, 13225.4, 9296.4]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [732.5, 682.2, 1256.5, 880.4, 1341.3, 1368.0, 535.5, 1401.6, 862.6]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [16776.7, 16094.7, 35495.1, 20724.3, 34643.5, 34933.7, 12514.3, 32054.8, 22767.8]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [0.9, 0.7, 1.0, 0.8, 1.1, 1.3, 0.5, 1.1, 0.9]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [4566.2, 4426.4, 9311.4, 6005.6, 9340.5, 9664.8, 4187.2, 9258.5, 6136.5]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [160.7, 145.7, 287.7, 205.3, 299.3, 373.1, 133.7, 328.6, 213.2]
```

```mermaid
xychart-beta
    title "status-panel/compose (median µs)"
    x-axis 1 --> 9
    line [594.8, 546.6, 567.0, 319.8, 265.0, 394.2, 439.7, 289.9, 585.4]
```

```mermaid
xychart-beta
    title "unwind/compose (median µs)"
    x-axis 1 --> 9
    line [4404.4, 3896.7, 3558.7, 3983.7, 4089.5, 4763.5, 2435.5, 3601.8, 3696.0]
```

```mermaid
xychart-beta
    title "update-batched/compose (median µs)"
    x-axis 1 --> 9
    line [3025.0, 2927.0, 2916.4, 3054.1, 2189.1, 3105.9, 1319.8, 1255.6, 2077.4]
```

```mermaid
xychart-beta
    title "update-fanout/compose (median µs)"
    x-axis 1 --> 9
    line [777.2, 1629.0, 1423.8, 1627.8, 1621.0, 1109.3, 831.7, 1618.1, 1611.5]
```

```mermaid
xychart-beta
    title "update-leaf/compose (median µs)"
    x-axis 1 --> 9
    line [33.7, 23.3, 40.6, 34.7, 19.6, 36.0, 36.8, 41.1, 33.8]
```

```mermaid
xychart-beta
    title "update-repeated/compose (median µs)"
    x-axis 1 --> 9
    line [291.8, 288.2, 351.9, 292.5, 264.7, 286.9, 148.3, 152.2, 256.0]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/burst (median µs)"
    x-axis 1 --> 9
    line [468218.5, 855118.6, 780270.5, 834379.1, 822280.8, 614925.3, 502437.3, 770366.5, 814734.6]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/cold (median µs)"
    x-axis 1 --> 9
    line [303705.7, 494927.2, 485557.0, 513263.7, 523189.8, 382561.4, 315618.4, 479243.4, 508549.5]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/counts (median µs)"
    x-axis 1 --> 9
    line [758775.9, 1513830.2, 1273975.2, 1375818.0, 1299789.2, 1024087.0, 821108.4, 1285355.1, 1349767.7]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.5, 2.4, 2.6, 2.4, 2.2, 2.6, 2.5, 2.1, 2.0]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/steady (median µs)"
    x-axis 1 --> 9
    line [8156.9, 15826.4, 14142.7, 17395.9, 15076.2, 11696.2, 9624.9, 16265.5, 15530.1]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [337.4, 510.6, 522.8, 521.1, 540.1, 460.0, 501.9, 512.5, 514.4]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/burst (median µs)"
    x-axis 1 --> 9
    line [103439.2, 85508.3, 125691.5, 107855.0, 65857.2, 104018.9, 111490.5, 127745.8, 95131.8]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/cold (median µs)"
    x-axis 1 --> 9
    line [59355.8, 50136.7, 78271.4, 62224.0, 40375.8, 64316.5, 67638.8, 79525.8, 57494.6]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/counts (median µs)"
    x-axis 1 --> 9
    line [189934.0, 152506.8, 237753.9, 190827.8, 118574.4, 195517.4, 197619.7, 232156.8, 178342.3]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/settle (median µs)"
    x-axis 1 --> 9
    line [2.3, 2.6, 2.0, 2.3, 0.8, 2.1, 2.6, 2.2, 1.7]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/steady (median µs)"
    x-axis 1 --> 9
    line [12089.3, 9916.3, 14136.9, 10607.7, 5998.1, 11145.0, 12021.9, 13983.7, 11785.5]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [262.7, 240.8, 290.6, 268.4, 155.5, 262.8, 273.1, 323.6, 243.0]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/burst (median µs)"
    x-axis 1 --> 9
    line [17844.8, 25511.5, 24629.5, 12779.6, 25017.7, 14298.0, 23142.1, 16545.8, 24260.5]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/cold (median µs)"
    x-axis 1 --> 9
    line [9422.5, 13481.1, 12703.5, 6786.8, 13017.4, 7925.2, 12287.7, 8563.9, 12334.4]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/counts (median µs)"
    x-axis 1 --> 9
    line [44077.6, 61203.3, 59533.4, 31373.7, 63554.6, 35221.9, 54334.2, 41356.2, 57669.1]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/settle (median µs)"
    x-axis 1 --> 9
    line [1.0, 1.7, 1.3, 0.8, 2.0, 1.4, 0.9, 2.5, 0.9]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/steady (median µs)"
    x-axis 1 --> 9
    line [9077.3, 12332.6, 11738.6, 6268.6, 14641.4, 7523.1, 11206.2, 8643.8, 11835.7]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/teardown (median µs)"
    x-axis 1 --> 9
    line [139.6, 199.8, 194.4, 101.4, 199.4, 122.2, 180.2, 135.6, 187.7]
```
