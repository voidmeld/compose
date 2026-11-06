# Compose performance

Latest: `e0c5cb59c5244911a40ce96e2a24b265bd8462b4` on 2026-11-06T175831Z, measured on the CI Ubuntu runner by the paired performance shards.
Each value is the median of the candidate arm's samples; p95 is shown beside it. Change compares the previous main commit.

| Benchmark | Median | p95 | Change |
| --- | --- | --- | --- |
| animate-many/compose | 7.02 ms | 7.21 ms | +3.1% |
| animate-many/memory/mounted | 2176 KiB | 2176 KiB | -0.4% |
| animate-many/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| animate-many/plain | 1.64 ms | 1.76 ms | +0.0% |
| animated-navigation.extreme/compose/burst | 6.80 ms | 7.27 ms | -14.2% |
| animated-navigation.extreme/compose/cold | 10.54 ms | 16.48 ms | -4.9% |
| animated-navigation.extreme/compose/counts | 70.64 ms | 70.64 ms | -16.4% |
| animated-navigation.extreme/compose/settle | 1.4 µs | 1.7 µs | +31.4% |
| animated-navigation.extreme/compose/steady | 27.21 ms | 27.77 ms | -17.7% |
| animated-navigation.extreme/compose/teardown | 2.87 ms | 3.32 ms | +2.6% |
| animated-navigation.extreme/memory/mounted | 6815 KiB | 6815 KiB | +0.0% |
| animated-navigation.extreme/memory/teardown | 9 KiB | 9 KiB | — |
| animated-navigation.extreme/plain/burst | 1.08 ms | 1.21 ms | -22.5% |
| animated-navigation.extreme/plain/cold | 3.94 ms | 9.24 ms | -21.1% |
| animated-navigation.extreme/plain/settle | 0.9 µs | 1.4 µs | +36.2% |
| animated-navigation.extreme/plain/steady | 13.49 ms | 13.99 ms | -29.3% |
| animated-navigation.extreme/plain/teardown | 3.44 ms | 4.27 ms | +1.0% |
| animated-navigation.large/compose/burst | 1.87 ms | 2.01 ms | -51.5% |
| animated-navigation.large/compose/cold | 3.94 ms | 6.00 ms | -32.6% |
| animated-navigation.large/compose/counts | 28.65 ms | 28.65 ms | -50.4% |
| animated-navigation.large/compose/settle | 0.6 µs | 0.8 µs | -33.0% |
| animated-navigation.large/compose/steady | 12.14 ms | 12.95 ms | -54.0% |
| animated-navigation.large/compose/teardown | 766.2 µs | 949.1 µs | -37.4% |
| animated-navigation.large/memory/mounted | 3419 KiB | 3419 KiB | +0.3% |
| animated-navigation.large/memory/teardown | 1 KiB | 1 KiB | — |
| animated-navigation.large/plain/burst | 326.3 µs | 345.3 µs | -52.3% |
| animated-navigation.large/plain/cold | 1.79 ms | 2.99 ms | -33.4% |
| animated-navigation.large/plain/settle | 0.3 µs | 0.8 µs | -45.7% |
| animated-navigation.large/plain/steady | 4.34 ms | 4.45 ms | -51.1% |
| animated-navigation.large/plain/teardown | 747.5 µs | 869.7 µs | -35.6% |
| animated-navigation.medium/compose/burst | 1.03 ms | 1.05 ms | -25.6% |
| animated-navigation.medium/compose/cold | 1.22 ms | 2.67 ms | -30.8% |
| animated-navigation.medium/compose/counts | 17.29 ms | 17.29 ms | -28.9% |
| animated-navigation.medium/compose/settle | 0.5 µs | 1.0 µs | -31.0% |
| animated-navigation.medium/compose/steady | 7.72 ms | 8.04 ms | -27.8% |
| animated-navigation.medium/compose/teardown | 271.2 µs | 310.3 µs | -33.7% |
| animated-navigation.medium/memory/mounted | 1164 KiB | 1164 KiB | +1.5% |
| animated-navigation.medium/memory/teardown | 9 KiB | 9 KiB | — |
| animated-navigation.medium/plain/burst | 175.3 µs | 190.4 µs | -22.8% |
| animated-navigation.medium/plain/cold | 428.9 µs | 1.12 ms | -37.4% |
| animated-navigation.medium/plain/settle | 0.3 µs | 0.4 µs | -31.0% |
| animated-navigation.medium/plain/steady | 2.17 ms | 2.22 ms | -18.6% |
| animated-navigation.medium/plain/teardown | 158.8 µs | 205.6 µs | -23.3% |
| branch-swap/compose | 3.41 ms | 5.00 ms | -4.1% |
| branch-swap/memory/mounted | 32 KiB | 32 KiB | +113.3% |
| branch-swap/memory/teardown | 1 KiB | 1 KiB | — |
| branch-swap/plain | 2.39 ms | 3.40 ms | -13.0% |
| cold-mount-100/compose | 445.1 µs | 998.5 µs | -49.7% |
| cold-mount-100/memory/mounted | 2228 KiB | 2228 KiB | +0.4% |
| cold-mount-100/memory/teardown | 1 KiB | 1 KiB | — |
| cold-mount-100/plain | 747.9 µs | 974.0 µs | -13.3% |
| cold-mount-1000/compose | 6.93 ms | 11.40 ms | -18.9% |
| cold-mount-1000/memory/mounted | 21830 KiB | 21830 KiB | -0.1% |
| cold-mount-1000/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| cold-mount-1000/plain | 3.62 ms | 6.77 ms | -43.6% |
| cold-mount-10000/compose | 59.10 ms | 85.48 ms | -37.3% |
| cold-mount-10000/memory/mounted | 218754 KiB | 218754 KiB | -0.0% |
| cold-mount-10000/memory/teardown | 1 KiB | 1 KiB | — |
| cold-mount-10000/plain | 65.35 ms | 75.52 ms | -2.6% |
| data-grid.extreme/compose/burst | 637.09 ms | 681.72 ms | -23.5% |
| data-grid.extreme/compose/cold | 377.50 ms | 414.79 ms | -26.8% |
| data-grid.extreme/compose/counts | 1085.25 ms | 1085.25 ms | -28.2% |
| data-grid.extreme/compose/settle | 2.6 µs | 3.4 µs | +18.3% |
| data-grid.extreme/compose/steady | 17.96 ms | 20.22 ms | -21.4% |
| data-grid.extreme/compose/teardown | 1.02 ms | 1.63 ms | -15.7% |
| data-grid.extreme/memory/mounted | 29228 KiB | 29228 KiB | -0.0% |
| data-grid.extreme/memory/teardown | 8 KiB | 8 KiB | -11.1% |
| data-grid.extreme/plain/burst | 575.29 ms | 587.02 ms | -26.2% |
| data-grid.extreme/plain/cold | 362.90 ms | 367.21 ms | -27.7% |
| data-grid.extreme/plain/settle | 2.8 µs | 4.7 µs | +17.3% |
| data-grid.extreme/plain/steady | 13.93 ms | 23.76 ms | -27.9% |
| data-grid.extreme/plain/teardown | 407.4 µs | 877.5 µs | -20.9% |
| data-grid.large/compose/burst | 79.05 ms | 83.84 ms | -42.3% |
| data-grid.large/compose/cold | 46.55 ms | 52.47 ms | -40.6% |
| data-grid.large/compose/counts | 134.29 ms | 134.29 ms | -45.7% |
| data-grid.large/compose/settle | 1.2 µs | 2.6 µs | -31.7% |
| data-grid.large/compose/steady | 9.01 ms | 12.82 ms | -41.1% |
| data-grid.large/compose/teardown | 308.6 µs | 364.7 µs | -41.8% |
| data-grid.large/memory/mounted | 6825 KiB | 6825 KiB | +0.0% |
| data-grid.large/memory/teardown | 0 KiB | 0 KiB | — |
| data-grid.large/plain/burst | 67.32 ms | 70.04 ms | -42.7% |
| data-grid.large/plain/cold | 42.08 ms | 44.11 ms | -43.0% |
| data-grid.large/plain/settle | 1.1 µs | 1.4 µs | -45.7% |
| data-grid.large/plain/steady | 5.67 ms | 7.76 ms | -48.1% |
| data-grid.large/plain/teardown | 117.8 µs | 172.2 µs | -37.9% |
| data-grid.medium/compose/burst | 54.34 ms | 61.08 ms | -13.9% |
| data-grid.medium/compose/cold | 30.15 ms | 33.26 ms | -16.2% |
| data-grid.medium/compose/counts | 106.19 ms | 106.19 ms | -17.5% |
| data-grid.medium/compose/settle | 2.4 µs | 3.1 µs | +37.9% |
| data-grid.medium/compose/steady | 11.98 ms | 16.85 ms | -6.5% |
| data-grid.medium/compose/teardown | 267.8 µs | 584.3 µs | -8.1% |
| data-grid.medium/memory/mounted | 3561 KiB | 3561 KiB | -0.2% |
| data-grid.medium/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| data-grid.medium/plain/burst | 40.37 ms | 41.95 ms | -24.8% |
| data-grid.medium/plain/cold | 25.90 ms | 29.72 ms | -23.6% |
| data-grid.medium/plain/settle | 1.8 µs | 3.1 µs | -5.7% |
| data-grid.medium/plain/steady | 6.48 ms | 8.86 ms | -2.2% |
| data-grid.medium/plain/teardown | 82.5 µs | 116.5 µs | -22.8% |
| dense-dashboard.extreme/compose/burst | 14.84 ms | 21.56 ms | +4.2% |
| dense-dashboard.extreme/compose/cold | 587.1 µs | 1.11 ms | +18.5% |
| dense-dashboard.extreme/compose/counts | 21.52 ms | 21.52 ms | -5.5% |
| dense-dashboard.extreme/compose/settle | 0.8 µs | 1.7 µs | -17.7% |
| dense-dashboard.extreme/compose/steady | 863.9 µs | 924.3 µs | -3.6% |
| dense-dashboard.extreme/compose/teardown | 500.2 µs | 554.5 µs | -4.5% |
| dense-dashboard.extreme/memory/mounted | 1262 KiB | 1262 KiB | -0.6% |
| dense-dashboard.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| dense-dashboard.extreme/plain/burst | 6.52 ms | 9.22 ms | -2.1% |
| dense-dashboard.extreme/plain/cold | 232.0 µs | 459.2 µs | -0.9% |
| dense-dashboard.extreme/plain/settle | 0.8 µs | 1.3 µs | -4.7% |
| dense-dashboard.extreme/plain/steady | 130.2 µs | 140.3 µs | -7.9% |
| dense-dashboard.extreme/plain/teardown | 220.6 µs | 354.9 µs | +0.5% |
| dense-dashboard.large/compose/burst | 5.93 ms | 10.15 ms | -24.5% |
| dense-dashboard.large/compose/cold | 196.1 µs | 700.7 µs | -37.2% |
| dense-dashboard.large/compose/counts | 9.62 ms | 9.62 ms | -36.0% |
| dense-dashboard.large/compose/settle | 0.7 µs | 0.9 µs | -19.7% |
| dense-dashboard.large/compose/steady | 434.1 µs | 453.0 µs | -49.6% |
| dense-dashboard.large/compose/teardown | 139.2 µs | 491.9 µs | -44.3% |
| dense-dashboard.large/memory/mounted | 664 KiB | 664 KiB | -0.2% |
| dense-dashboard.large/memory/teardown | 0 KiB | 0 KiB | — |
| dense-dashboard.large/plain/burst | 3.09 ms | 7.31 ms | +13.9% |
| dense-dashboard.large/plain/cold | 244.8 µs | 382.4 µs | +82.0% |
| dense-dashboard.large/plain/settle | 0.4 µs | 0.7 µs | -26.6% |
| dense-dashboard.large/plain/steady | 79.2 µs | 496.7 µs | -39.3% |
| dense-dashboard.large/plain/teardown | 86.5 µs | 736.8 µs | -10.6% |
| dense-dashboard.medium/compose/burst | 2.02 ms | 3.56 ms | -40.5% |
| dense-dashboard.medium/compose/cold | 164.2 µs | 287.3 µs | -17.6% |
| dense-dashboard.medium/compose/counts | 3.93 ms | 3.93 ms | -36.9% |
| dense-dashboard.medium/compose/settle | 0.5 µs | 0.8 µs | -25.4% |
| dense-dashboard.medium/compose/steady | 675.3 µs | 698.8 µs | -19.9% |
| dense-dashboard.medium/compose/teardown | 88.9 µs | 111.0 µs | -18.5% |
| dense-dashboard.medium/memory/mounted | 321 KiB | 321 KiB | +2.6% |
| dense-dashboard.medium/memory/teardown | 0 KiB | 0 KiB | — |
| dense-dashboard.medium/plain/burst | 1.07 ms | 2.21 ms | -14.8% |
| dense-dashboard.medium/plain/cold | 69.2 µs | 213.6 µs | -32.2% |
| dense-dashboard.medium/plain/settle | 0.5 µs | 0.6 µs | -32.8% |
| dense-dashboard.medium/plain/steady | 105.2 µs | 109.3 µs | -18.9% |
| dense-dashboard.medium/plain/teardown | 33.7 µs | 58.6 µs | -29.6% |
| entities-identity-churn-10.extreme/compose/burst | 27.10 ms | 37.55 ms | -41.9% |
| entities-identity-churn-10.extreme/compose/cold | 23.79 ms | 32.70 ms | -22.7% |
| entities-identity-churn-10.extreme/compose/counts | 143.08 ms | 143.08 ms | -31.1% |
| entities-identity-churn-10.extreme/compose/settle | 1.5 µs | 2.3 µs | -26.3% |
| entities-identity-churn-10.extreme/compose/steady | 26.67 ms | 37.44 ms | -48.8% |
| entities-identity-churn-10.extreme/compose/teardown | 774.0 µs | 1.00 ms | -30.6% |
| entities-identity-churn-10.extreme/memory/mounted | 4231 KiB | 4231 KiB | -0.2% |
| entities-identity-churn-10.extreme/memory/teardown | 1 KiB | 1 KiB | -87.5% |
| entities-identity-churn-10.extreme/plain/burst | 11.37 ms | 15.77 ms | -25.4% |
| entities-identity-churn-10.extreme/plain/cold | 7.65 ms | 14.64 ms | +1.2% |
| entities-identity-churn-10.extreme/plain/settle | 1.3 µs | 2.4 µs | -30.1% |
| entities-identity-churn-10.extreme/plain/steady | 18.66 ms | 26.30 ms | -38.6% |
| entities-identity-churn-10.extreme/plain/teardown | 335.5 µs | 481.6 µs | -8.5% |
| entities-identity-churn-10.large/compose/burst | 12.95 ms | 14.92 ms | -5.1% |
| entities-identity-churn-10.large/compose/cold | 12.42 ms | 17.89 ms | -2.4% |
| entities-identity-churn-10.large/compose/counts | 60.68 ms | 60.68 ms | -5.4% |
| entities-identity-churn-10.large/compose/settle | 1.9 µs | 3.2 µs | +16.8% |
| entities-identity-churn-10.large/compose/steady | 14.31 ms | 22.28 ms | -19.5% |
| entities-identity-churn-10.large/compose/teardown | 338.9 µs | 527.7 µs | -9.7% |
| entities-identity-churn-10.large/memory/mounted | 1669 KiB | 1669 KiB | +0.0% |
| entities-identity-churn-10.large/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn-10.large/plain/burst | 4.64 ms | 8.00 ms | -0.2% |
| entities-identity-churn-10.large/plain/cold | 3.43 ms | 7.11 ms | -7.2% |
| entities-identity-churn-10.large/plain/settle | 1.1 µs | 2.1 µs | -9.5% |
| entities-identity-churn-10.large/plain/steady | 8.40 ms | 9.56 ms | -25.4% |
| entities-identity-churn-10.large/plain/teardown | 109.1 µs | 167.2 µs | -8.8% |
| entities-identity-churn-10.medium/compose/burst | 5.11 ms | 8.36 ms | -32.7% |
| entities-identity-churn-10.medium/compose/cold | 3.38 ms | 5.11 ms | -37.0% |
| entities-identity-churn-10.medium/compose/counts | 22.94 ms | 22.94 ms | -30.9% |
| entities-identity-churn-10.medium/compose/settle | 0.9 µs | 1.1 µs | -16.1% |
| entities-identity-churn-10.medium/compose/steady | 5.91 ms | 7.34 ms | -28.8% |
| entities-identity-churn-10.medium/compose/teardown | 143.6 µs | 164.7 µs | -24.2% |
| entities-identity-churn-10.medium/memory/mounted | 869 KiB | 869 KiB | +0.0% |
| entities-identity-churn-10.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn-10.medium/plain/burst | 1.66 ms | 3.24 ms | -40.3% |
| entities-identity-churn-10.medium/plain/cold | 1.01 ms | 2.72 ms | -37.2% |
| entities-identity-churn-10.medium/plain/settle | 0.6 µs | 0.9 µs | -28.4% |
| entities-identity-churn-10.medium/plain/steady | 3.91 ms | 4.18 ms | -30.0% |
| entities-identity-churn-10.medium/plain/teardown | 43.7 µs | 62.9 µs | -24.2% |
| entities-identity-churn-50.extreme/compose/burst | 43.17 ms | 56.41 ms | +5.1% |
| entities-identity-churn-50.extreme/compose/cold | 23.70 ms | 51.97 ms | -20.0% |
| entities-identity-churn-50.extreme/compose/counts | 313.93 ms | 313.93 ms | +9.3% |
| entities-identity-churn-50.extreme/compose/settle | 2.3 µs | 2.9 µs | +22.5% |
| entities-identity-churn-50.extreme/compose/steady | 146.00 ms | 183.19 ms | -3.6% |
| entities-identity-churn-50.extreme/compose/teardown | 1.16 ms | 1.87 ms | +0.4% |
| entities-identity-churn-50.extreme/memory/mounted | 4163 KiB | 4163 KiB | +0.0% |
| entities-identity-churn-50.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-identity-churn-50.extreme/plain/burst | 15.79 ms | 23.52 ms | -5.7% |
| entities-identity-churn-50.extreme/plain/cold | 7.05 ms | 19.25 ms | -9.2% |
| entities-identity-churn-50.extreme/plain/settle | 2.7 µs | 3.1 µs | +8.1% |
| entities-identity-churn-50.extreme/plain/steady | 60.20 ms | 76.99 ms | -5.2% |
| entities-identity-churn-50.extreme/plain/teardown | 358.7 µs | 906.6 µs | -12.5% |
| entities-identity-churn-50.large/compose/burst | 8.83 ms | 12.62 ms | -38.0% |
| entities-identity-churn-50.large/compose/cold | 8.08 ms | 13.68 ms | -22.2% |
| entities-identity-churn-50.large/compose/counts | 60.85 ms | 60.85 ms | -43.9% |
| entities-identity-churn-50.large/compose/settle | 1.2 µs | 2.0 µs | -28.6% |
| entities-identity-churn-50.large/compose/steady | 29.13 ms | 37.57 ms | -42.8% |
| entities-identity-churn-50.large/compose/teardown | 225.9 µs | 318.6 µs | -43.3% |
| entities-identity-churn-50.large/memory/mounted | 1726 KiB | 1726 KiB | +0.5% |
| entities-identity-churn-50.large/memory/teardown | 1 KiB | 1 KiB | — |
| entities-identity-churn-50.large/plain/burst | 3.87 ms | 9.26 ms | -29.3% |
| entities-identity-churn-50.large/plain/cold | 1.90 ms | 5.85 ms | -35.6% |
| entities-identity-churn-50.large/plain/settle | 0.8 µs | 2.1 µs | -47.5% |
| entities-identity-churn-50.large/plain/steady | 11.61 ms | 18.72 ms | -47.4% |
| entities-identity-churn-50.large/plain/teardown | 97.9 µs | 166.4 µs | -28.5% |
| entities-identity-churn-50.medium/compose/burst | 5.05 ms | 9.27 ms | -35.3% |
| entities-identity-churn-50.medium/compose/cold | 3.55 ms | 7.65 ms | -45.3% |
| entities-identity-churn-50.medium/compose/counts | 40.69 ms | 40.69 ms | -34.5% |
| entities-identity-churn-50.medium/compose/settle | 1.3 µs | 1.8 µs | -17.9% |
| entities-identity-churn-50.medium/compose/steady | 14.48 ms | 20.29 ms | -38.6% |
| entities-identity-churn-50.medium/compose/teardown | 155.2 µs | 330.5 µs | -36.0% |
| entities-identity-churn-50.medium/memory/mounted | 953 KiB | 953 KiB | -0.8% |
| entities-identity-churn-50.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-identity-churn-50.medium/plain/burst | 2.72 ms | 4.14 ms | -1.4% |
| entities-identity-churn-50.medium/plain/cold | 861.2 µs | 2.55 ms | -55.3% |
| entities-identity-churn-50.medium/plain/settle | 0.8 µs | 1.2 µs | -25.3% |
| entities-identity-churn-50.medium/plain/steady | 6.10 ms | 8.44 ms | -44.2% |
| entities-identity-churn-50.medium/plain/teardown | 48.6 µs | 69.4 µs | -27.7% |
| entities-identity-churn.extreme/compose/burst | 38.37 ms | 54.75 ms | -15.1% |
| entities-identity-churn.extreme/compose/cold | 19.35 ms | 60.47 ms | -34.7% |
| entities-identity-churn.extreme/compose/counts | 151.48 ms | 151.48 ms | -36.8% |
| entities-identity-churn.extreme/compose/settle | 2.3 µs | 10.0 µs | +7.5% |
| entities-identity-churn.extreme/compose/steady | 60.70 ms | 66.86 ms | -30.9% |
| entities-identity-churn.extreme/compose/teardown | 814.1 µs | 1.42 ms | -35.1% |
| entities-identity-churn.extreme/memory/mounted | 4621 KiB | 4621 KiB | +2.1% |
| entities-identity-churn.extreme/memory/teardown | 105 KiB | 105 KiB | +10400.0% |
| entities-identity-churn.extreme/plain/burst | 11.99 ms | 21.17 ms | -31.8% |
| entities-identity-churn.extreme/plain/cold | 5.75 ms | 17.04 ms | -46.3% |
| entities-identity-churn.extreme/plain/settle | 1.7 µs | 2.4 µs | -19.8% |
| entities-identity-churn.extreme/plain/steady | 28.55 ms | 31.16 ms | -34.4% |
| entities-identity-churn.extreme/plain/teardown | 282.9 µs | 685.8 µs | -37.7% |
| entities-identity-churn.large/compose/burst | 11.00 ms | 20.58 ms | -12.2% |
| entities-identity-churn.large/compose/cold | 12.04 ms | 16.95 ms | +5.5% |
| entities-identity-churn.large/compose/counts | 76.01 ms | 76.01 ms | -18.3% |
| entities-identity-churn.large/compose/settle | 1.3 µs | 3.1 µs | -21.6% |
| entities-identity-churn.large/compose/steady | 23.34 ms | 34.06 ms | -18.9% |
| entities-identity-churn.large/compose/teardown | 314.6 µs | 342.2 µs | -10.1% |
| entities-identity-churn.large/memory/mounted | 1637 KiB | 1637 KiB | +0.1% |
| entities-identity-churn.large/memory/teardown | 1 KiB | 1 KiB | — |
| entities-identity-churn.large/plain/burst | 3.85 ms | 11.69 ms | -17.5% |
| entities-identity-churn.large/plain/cold | 3.94 ms | 4.40 ms | +0.9% |
| entities-identity-churn.large/plain/settle | 1.0 µs | 2.4 µs | -2.0% |
| entities-identity-churn.large/plain/steady | 11.65 ms | 19.43 ms | -22.4% |
| entities-identity-churn.large/plain/teardown | 99.2 µs | 333.5 µs | -12.3% |
| entities-identity-churn.medium/compose/burst | 7.11 ms | 11.57 ms | -5.3% |
| entities-identity-churn.medium/compose/cold | 4.31 ms | 6.33 ms | -12.4% |
| entities-identity-churn.medium/compose/counts | 35.76 ms | 35.76 ms | -6.6% |
| entities-identity-churn.medium/compose/settle | 1.9 µs | 3.1 µs | +86.8% |
| entities-identity-churn.medium/compose/steady | 11.48 ms | 17.15 ms | -18.9% |
| entities-identity-churn.medium/compose/teardown | 186.8 µs | 230.6 µs | -10.7% |
| entities-identity-churn.medium/memory/mounted | 909 KiB | 909 KiB | -1.6% |
| entities-identity-churn.medium/memory/teardown | 1 KiB | 1 KiB | — |
| entities-identity-churn.medium/plain/burst | 2.36 ms | 5.95 ms | -8.3% |
| entities-identity-churn.medium/plain/cold | 1.35 ms | 3.55 ms | -2.1% |
| entities-identity-churn.medium/plain/settle | 1.1 µs | 1.8 µs | +32.1% |
| entities-identity-churn.medium/plain/steady | 5.92 ms | 7.50 ms | -16.6% |
| entities-identity-churn.medium/plain/teardown | 60.9 µs | 143.3 µs | -4.3% |
| entities-integrated.extreme/compose/burst | 16.32 ms | 23.39 ms | -10.4% |
| entities-integrated.extreme/compose/cold | 98.79 ms | 124.33 ms | -10.8% |
| entities-integrated.extreme/compose/counts | 305.42 ms | 305.42 ms | -20.2% |
| entities-integrated.extreme/compose/settle | 1.7 µs | 3.5 µs | -20.0% |
| entities-integrated.extreme/compose/steady | 80.41 ms | 96.91 ms | -16.2% |
| entities-integrated.extreme/compose/teardown | 46.46 ms | 58.15 ms | -16.3% |
| entities-integrated.extreme/memory/mounted | 40035 KiB | 40035 KiB | +0.0% |
| entities-integrated.extreme/memory/teardown | 8 KiB | 8 KiB | — |
| entities-integrated.extreme/plain/burst | 5.56 ms | 6.82 ms | -8.2% |
| entities-integrated.extreme/plain/cold | 30.44 ms | 46.36 ms | -12.2% |
| entities-integrated.extreme/plain/settle | 1.4 µs | 1.8 µs | -29.8% |
| entities-integrated.extreme/plain/steady | 22.65 ms | 30.44 ms | -13.8% |
| entities-integrated.extreme/plain/teardown | 22.54 ms | 23.83 ms | -16.1% |
| entities-integrated.large/compose/burst | 5.35 ms | 10.56 ms | -44.2% |
| entities-integrated.large/compose/cold | 27.62 ms | 38.88 ms | -28.2% |
| entities-integrated.large/compose/counts | 92.54 ms | 92.54 ms | -32.2% |
| entities-integrated.large/compose/settle | 1.6 µs | 1.8 µs | -2.5% |
| entities-integrated.large/compose/steady | 29.50 ms | 43.60 ms | -41.4% |
| entities-integrated.large/compose/teardown | 10.97 ms | 17.56 ms | -22.7% |
| entities-integrated.large/memory/mounted | 16523 KiB | 16523 KiB | -0.1% |
| entities-integrated.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-integrated.large/plain/burst | 2.02 ms | 4.54 ms | -33.1% |
| entities-integrated.large/plain/cold | 7.42 ms | 15.28 ms | -39.7% |
| entities-integrated.large/plain/settle | 1.3 µs | 1.9 µs | -0.9% |
| entities-integrated.large/plain/steady | 8.98 ms | 16.25 ms | -34.6% |
| entities-integrated.large/plain/teardown | 5.08 ms | 8.05 ms | -8.5% |
| entities-integrated.medium/compose/burst | 5.47 ms | 6.21 ms | -21.2% |
| entities-integrated.medium/compose/cold | 20.76 ms | 22.11 ms | +9.3% |
| entities-integrated.medium/compose/counts | 68.61 ms | 68.61 ms | -24.8% |
| entities-integrated.medium/compose/settle | 1.2 µs | 1.8 µs | -27.7% |
| entities-integrated.medium/compose/steady | 25.16 ms | 28.53 ms | -26.7% |
| entities-integrated.medium/compose/teardown | 5.09 ms | 5.38 ms | -20.2% |
| entities-integrated.medium/memory/mounted | 8969 KiB | 8969 KiB | +0.1% |
| entities-integrated.medium/memory/teardown | 8 KiB | 8 KiB | — |
| entities-integrated.medium/plain/burst | 1.61 ms | 2.24 ms | -30.0% |
| entities-integrated.medium/plain/cold | 3.88 ms | 7.33 ms | -33.6% |
| entities-integrated.medium/plain/settle | 0.7 µs | 1.2 µs | -27.8% |
| entities-integrated.medium/plain/steady | 7.06 ms | 11.76 ms | -26.4% |
| entities-integrated.medium/plain/teardown | 1.62 ms | 2.26 ms | -30.2% |
| entities-relevance-saturated.extreme/compose/burst | 78.54 ms | 93.02 ms | -4.0% |
| entities-relevance-saturated.extreme/compose/cold | 29.58 ms | 55.20 ms | +8.6% |
| entities-relevance-saturated.extreme/compose/counts | 205.40 ms | 205.40 ms | -5.8% |
| entities-relevance-saturated.extreme/compose/settle | 2.6 µs | 3.4 µs | +24.7% |
| entities-relevance-saturated.extreme/compose/steady | 50.49 ms | 83.60 ms | -0.4% |
| entities-relevance-saturated.extreme/compose/teardown | 14.67 ms | 18.11 ms | +9.5% |
| entities-relevance-saturated.extreme/memory/mounted | 11989 KiB | 11989 KiB | -0.3% |
| entities-relevance-saturated.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-relevance-saturated.extreme/plain/burst | 16.05 ms | 35.65 ms | -16.0% |
| entities-relevance-saturated.extreme/plain/cold | 11.90 ms | 21.45 ms | +26.3% |
| entities-relevance-saturated.extreme/plain/settle | 2.2 µs | 3.1 µs | -2.7% |
| entities-relevance-saturated.extreme/plain/steady | 73.34 ms | 93.93 ms | -22.7% |
| entities-relevance-saturated.extreme/plain/teardown | 4.00 ms | 6.01 ms | +13.9% |
| entities-relevance-saturated.large/compose/burst | 27.01 ms | 35.48 ms | +0.4% |
| entities-relevance-saturated.large/compose/cold | 11.24 ms | 26.31 ms | +1.1% |
| entities-relevance-saturated.large/compose/counts | 74.22 ms | 74.22 ms | -5.1% |
| entities-relevance-saturated.large/compose/settle | 2.3 µs | 2.8 µs | +40.5% |
| entities-relevance-saturated.large/compose/steady | 17.83 ms | 25.04 ms | +1.2% |
| entities-relevance-saturated.large/compose/teardown | 3.45 ms | 4.72 ms | +16.1% |
| entities-relevance-saturated.large/memory/mounted | 4824 KiB | 4824 KiB | +0.2% |
| entities-relevance-saturated.large/memory/teardown | 16 KiB | 16 KiB | — |
| entities-relevance-saturated.large/plain/burst | 7.59 ms | 12.74 ms | +20.5% |
| entities-relevance-saturated.large/plain/cold | 3.27 ms | 9.50 ms | -36.2% |
| entities-relevance-saturated.large/plain/settle | 2.0 µs | 2.8 µs | +16.4% |
| entities-relevance-saturated.large/plain/steady | 27.59 ms | 36.15 ms | -22.0% |
| entities-relevance-saturated.large/plain/teardown | 1.40 ms | 1.59 ms | +16.7% |
| entities-relevance-saturated.medium/compose/burst | 6.88 ms | 12.13 ms | -34.8% |
| entities-relevance-saturated.medium/compose/cold | 3.25 ms | 7.59 ms | -34.0% |
| entities-relevance-saturated.medium/compose/counts | 23.52 ms | 23.52 ms | -32.9% |
| entities-relevance-saturated.medium/compose/settle | 0.9 µs | 2.0 µs | -7.0% |
| entities-relevance-saturated.medium/compose/steady | 4.38 ms | 8.70 ms | -43.9% |
| entities-relevance-saturated.medium/compose/teardown | 866.7 µs | 984.6 µs | -14.6% |
| entities-relevance-saturated.medium/memory/mounted | 2403 KiB | 2403 KiB | -0.7% |
| entities-relevance-saturated.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-relevance-saturated.medium/plain/burst | 1.66 ms | 3.73 ms | -39.2% |
| entities-relevance-saturated.medium/plain/cold | 1.15 ms | 4.47 ms | -51.7% |
| entities-relevance-saturated.medium/plain/settle | 0.9 µs | 2.0 µs | +2.3% |
| entities-relevance-saturated.medium/plain/steady | 8.91 ms | 12.63 ms | -46.6% |
| entities-relevance-saturated.medium/plain/teardown | 406.3 µs | 730.1 µs | -2.6% |
| entities-relevance-sweep.extreme/compose/burst | 102.90 ms | 131.55 ms | -26.1% |
| entities-relevance-sweep.extreme/compose/cold | 19.90 ms | 39.89 ms | -43.3% |
| entities-relevance-sweep.extreme/compose/counts | 279.45 ms | 279.45 ms | -25.5% |
| entities-relevance-sweep.extreme/compose/settle | 2.5 µs | 3.2 µs | +2.4% |
| entities-relevance-sweep.extreme/compose/steady | 87.49 ms | 109.24 ms | -26.2% |
| entities-relevance-sweep.extreme/compose/teardown | 12.19 ms | 13.73 ms | -16.2% |
| entities-relevance-sweep.extreme/memory/mounted | 12042 KiB | 12042 KiB | -0.1% |
| entities-relevance-sweep.extreme/memory/teardown | 9 KiB | 9 KiB | +12.5% |
| entities-relevance-sweep.extreme/plain/burst | 31.99 ms | 45.61 ms | -21.6% |
| entities-relevance-sweep.extreme/plain/cold | 6.42 ms | 17.56 ms | -32.4% |
| entities-relevance-sweep.extreme/plain/settle | 2.1 µs | 3.0 µs | -4.0% |
| entities-relevance-sweep.extreme/plain/steady | 20.10 ms | 35.92 ms | -28.5% |
| entities-relevance-sweep.extreme/plain/teardown | 3.89 ms | 4.48 ms | +3.0% |
| entities-relevance-sweep.large/compose/burst | 43.90 ms | 60.23 ms | +5.1% |
| entities-relevance-sweep.large/compose/cold | 9.94 ms | 25.39 ms | -7.4% |
| entities-relevance-sweep.large/compose/counts | 113.10 ms | 113.10 ms | -14.3% |
| entities-relevance-sweep.large/compose/settle | 2.1 µs | 2.6 µs | +23.8% |
| entities-relevance-sweep.large/compose/steady | 36.04 ms | 49.82 ms | -16.0% |
| entities-relevance-sweep.large/compose/teardown | 3.77 ms | 4.27 ms | +17.5% |
| entities-relevance-sweep.large/memory/mounted | 4833 KiB | 4833 KiB | +0.0% |
| entities-relevance-sweep.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-relevance-sweep.large/plain/burst | 10.29 ms | 19.87 ms | -8.4% |
| entities-relevance-sweep.large/plain/cold | 3.87 ms | 8.08 ms | +3.1% |
| entities-relevance-sweep.large/plain/settle | 1.6 µs | 2.7 µs | +0.0% |
| entities-relevance-sweep.large/plain/steady | 9.64 ms | 17.69 ms | -4.9% |
| entities-relevance-sweep.large/plain/teardown | 1.45 ms | 1.87 ms | +19.0% |
| entities-relevance-sweep.medium/compose/burst | 19.43 ms | 24.94 ms | -1.0% |
| entities-relevance-sweep.medium/compose/cold | 5.39 ms | 12.71 ms | -18.5% |
| entities-relevance-sweep.medium/compose/counts | 66.52 ms | 66.52 ms | -8.5% |
| entities-relevance-sweep.medium/compose/settle | 1.3 µs | 1.6 µs | +0.8% |
| entities-relevance-sweep.medium/compose/steady | 20.00 ms | 22.69 ms | +1.7% |
| entities-relevance-sweep.medium/compose/teardown | 1.11 ms | 1.44 ms | -11.2% |
| entities-relevance-sweep.medium/memory/mounted | 2412 KiB | 2412 KiB | -0.3% |
| entities-relevance-sweep.medium/memory/teardown | 1 KiB | 1 KiB | -87.5% |
| entities-relevance-sweep.medium/plain/burst | 4.81 ms | 5.40 ms | -3.5% |
| entities-relevance-sweep.medium/plain/cold | 1.76 ms | 3.54 ms | -9.3% |
| entities-relevance-sweep.medium/plain/settle | 0.7 µs | 5.4 µs | -25.2% |
| entities-relevance-sweep.medium/plain/steady | 4.28 ms | 9.04 ms | -19.5% |
| entities-relevance-sweep.medium/plain/teardown | 315.4 µs | 490.0 µs | -48.2% |
| entity-labels-sparse.extreme/compose/burst | 16.71 ms | 25.18 ms | -38.3% |
| entity-labels-sparse.extreme/compose/cold | 17.44 ms | 24.29 ms | -30.5% |
| entity-labels-sparse.extreme/compose/counts | 60.03 ms | 60.03 ms | -35.6% |
| entity-labels-sparse.extreme/compose/settle | 1.8 µs | 2.6 µs | +11.8% |
| entity-labels-sparse.extreme/compose/steady | 2.84 ms | 3.95 ms | -25.0% |
| entity-labels-sparse.extreme/compose/teardown | 9.10 ms | 10.47 ms | -25.5% |
| entity-labels-sparse.extreme/memory/mounted | 12211 KiB | 12211 KiB | -0.1% |
| entity-labels-sparse.extreme/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| entity-labels-sparse.extreme/plain/burst | 6.77 ms | 12.00 ms | -24.7% |
| entity-labels-sparse.extreme/plain/cold | 7.34 ms | 20.32 ms | -29.5% |
| entity-labels-sparse.extreme/plain/settle | 1.2 µs | 2.2 µs | -12.6% |
| entity-labels-sparse.extreme/plain/steady | 574.5 µs | 1.71 ms | -36.6% |
| entity-labels-sparse.extreme/plain/teardown | 4.80 ms | 9.38 ms | -20.8% |
| entity-labels-sparse.large/compose/burst | 7.05 ms | 9.98 ms | -42.2% |
| entity-labels-sparse.large/compose/cold | 7.45 ms | 10.02 ms | -38.7% |
| entity-labels-sparse.large/compose/counts | 25.62 ms | 25.62 ms | -48.3% |
| entity-labels-sparse.large/compose/settle | 1.2 µs | 2.0 µs | -1.6% |
| entity-labels-sparse.large/compose/steady | 1.14 ms | 1.33 ms | -39.1% |
| entity-labels-sparse.large/compose/teardown | 2.75 ms | 3.97 ms | -30.0% |
| entity-labels-sparse.large/memory/mounted | 6348 KiB | 6348 KiB | -0.1% |
| entity-labels-sparse.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entity-labels-sparse.large/plain/burst | 2.32 ms | 4.74 ms | -55.0% |
| entity-labels-sparse.large/plain/cold | 3.44 ms | 6.19 ms | -5.0% |
| entity-labels-sparse.large/plain/settle | 0.6 µs | 0.9 µs | -42.9% |
| entity-labels-sparse.large/plain/steady | 270.0 µs | 313.9 µs | -41.7% |
| entity-labels-sparse.large/plain/teardown | 1.34 ms | 1.94 ms | -31.8% |
| entity-labels-sparse.medium/compose/burst | 4.91 ms | 7.38 ms | +5.9% |
| entity-labels-sparse.medium/compose/cold | 5.27 ms | 7.44 ms | +21.7% |
| entity-labels-sparse.medium/compose/counts | 22.97 ms | 22.97 ms | +7.4% |
| entity-labels-sparse.medium/compose/settle | 0.8 µs | 1.0 µs | -11.1% |
| entity-labels-sparse.medium/compose/steady | 935.5 µs | 1.18 ms | +5.7% |
| entity-labels-sparse.medium/compose/teardown | 1.27 ms | 1.37 ms | -3.0% |
| entity-labels-sparse.medium/memory/mounted | 2816 KiB | 2816 KiB | -0.3% |
| entity-labels-sparse.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| entity-labels-sparse.medium/plain/burst | 1.59 ms | 2.10 ms | +16.5% |
| entity-labels-sparse.medium/plain/cold | 1.38 ms | 3.24 ms | -26.3% |
| entity-labels-sparse.medium/plain/settle | 0.6 µs | 0.7 µs | -17.9% |
| entity-labels-sparse.medium/plain/steady | 207.5 µs | 258.0 µs | +5.0% |
| entity-labels-sparse.medium/plain/teardown | 515.1 µs | 688.2 µs | -2.0% |
| entity-labels.extreme/compose/burst | 28.24 ms | 38.58 ms | -6.7% |
| entity-labels.extreme/compose/cold | 25.09 ms | 29.07 ms | +1.2% |
| entity-labels.extreme/compose/counts | 121.19 ms | 121.19 ms | -6.9% |
| entity-labels.extreme/compose/settle | 1.9 µs | 2.5 µs | +23.4% |
| entity-labels.extreme/compose/steady | 30.45 ms | 35.76 ms | -3.0% |
| entity-labels.extreme/compose/teardown | 11.86 ms | 12.73 ms | -1.9% |
| entity-labels.extreme/memory/mounted | 12696 KiB | 12696 KiB | +0.0% |
| entity-labels.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entity-labels.extreme/plain/burst | 7.58 ms | 12.01 ms | -22.3% |
| entity-labels.extreme/plain/cold | 8.79 ms | 12.09 ms | -19.6% |
| entity-labels.extreme/plain/settle | 0.9 µs | 1.4 µs | +2.3% |
| entity-labels.extreme/plain/steady | 851.1 µs | 938.8 µs | -7.4% |
| entity-labels.extreme/plain/teardown | 5.50 ms | 6.99 ms | -0.8% |
| entity-labels.large/compose/burst | 8.14 ms | 11.34 ms | -45.0% |
| entity-labels.large/compose/cold | 8.75 ms | 13.59 ms | -28.5% |
| entity-labels.large/compose/counts | 38.51 ms | 38.51 ms | -39.8% |
| entity-labels.large/compose/settle | 1.2 µs | 1.7 µs | -35.5% |
| entity-labels.large/compose/steady | 6.89 ms | 9.36 ms | -55.8% |
| entity-labels.large/compose/teardown | 3.13 ms | 4.52 ms | -28.9% |
| entity-labels.large/memory/mounted | 6593 KiB | 6593 KiB | -0.3% |
| entity-labels.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entity-labels.large/plain/burst | 3.10 ms | 4.71 ms | -20.4% |
| entity-labels.large/plain/cold | 2.22 ms | 5.24 ms | -52.2% |
| entity-labels.large/plain/settle | 0.7 µs | 1.0 µs | -6.6% |
| entity-labels.large/plain/steady | 261.1 µs | 305.2 µs | -42.1% |
| entity-labels.large/plain/teardown | 1.40 ms | 1.60 ms | -25.6% |
| entity-labels.medium/compose/burst | 4.98 ms | 6.67 ms | -4.0% |
| entity-labels.medium/compose/cold | 4.92 ms | 7.22 ms | -5.6% |
| entity-labels.medium/compose/counts | 23.38 ms | 23.38 ms | -9.1% |
| entity-labels.medium/compose/settle | 0.8 µs | 0.9 µs | -24.7% |
| entity-labels.medium/compose/steady | 6.42 ms | 6.81 ms | +0.0% |
| entity-labels.medium/compose/teardown | 1.26 ms | 1.48 ms | -5.0% |
| entity-labels.medium/memory/mounted | 2935 KiB | 2935 KiB | -0.3% |
| entity-labels.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entity-labels.medium/plain/burst | 1.43 ms | 2.21 ms | -5.8% |
| entity-labels.medium/plain/cold | 1.65 ms | 3.89 ms | -6.1% |
| entity-labels.medium/plain/settle | 0.7 µs | 4.0 µs | +1.5% |
| entity-labels.medium/plain/steady | 204.3 µs | 220.3 µs | -3.3% |
| entity-labels.medium/plain/teardown | 476.3 µs | 657.4 µs | -2.6% |
| events/compose | 9.92 ms | 14.57 ms | -10.0% |
| events/memory/mounted | 0 KiB | 0 KiB | -100.0% |
| events/memory/teardown | 0 KiB | 0 KiB | — |
| events/plain | 9.35 ms | 14.98 ms | -10.2% |
| inspector.extreme/compose/burst | 7.89 ms | 8.81 ms | -1.9% |
| inspector.extreme/compose/cold | 18.55 ms | 30.06 ms | -9.1% |
| inspector.extreme/compose/counts | 33.63 ms | 33.63 ms | -11.1% |
| inspector.extreme/compose/settle | 2.0 µs | 2.7 µs | +66.2% |
| inspector.extreme/compose/steady | 270.8 µs | 324.1 µs | +14.3% |
| inspector.extreme/compose/teardown | 3.01 ms | 3.44 ms | +30.1% |
| inspector.extreme/memory/mounted | 17367 KiB | 17367 KiB | +0.0% |
| inspector.extreme/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| inspector.extreme/plain/burst | 1.45 ms | 1.62 ms | -19.1% |
| inspector.extreme/plain/cold | 7.52 ms | 10.45 ms | +2.8% |
| inspector.extreme/plain/settle | 1.0 µs | 1.5 µs | +5.5% |
| inspector.extreme/plain/steady | 71.6 µs | 81.6 µs | -4.9% |
| inspector.extreme/plain/teardown | 5.20 ms | 5.64 ms | -3.4% |
| inspector.large/compose/burst | 2.06 ms | 3.39 ms | -49.4% |
| inspector.large/compose/cold | 5.15 ms | 6.37 ms | -20.4% |
| inspector.large/compose/counts | 13.88 ms | 13.88 ms | -26.4% |
| inspector.large/compose/settle | 0.7 µs | 0.9 µs | -17.8% |
| inspector.large/compose/steady | 142.8 µs | 177.0 µs | -37.3% |
| inspector.large/compose/teardown | 747.2 µs | 1.47 ms | -29.1% |
| inspector.large/memory/mounted | 6196 KiB | 6196 KiB | +0.0% |
| inspector.large/memory/teardown | 1 KiB | 1 KiB | — |
| inspector.large/plain/burst | 398.4 µs | 528.9 µs | -52.6% |
| inspector.large/plain/cold | 2.45 ms | 3.23 ms | -26.1% |
| inspector.large/plain/settle | 0.4 µs | 0.5 µs | -41.0% |
| inspector.large/plain/steady | 38.3 µs | 50.5 µs | -39.4% |
| inspector.large/plain/teardown | 1.12 ms | 1.34 ms | -28.0% |
| inspector.medium/compose/burst | 1.61 ms | 1.99 ms | +13.1% |
| inspector.medium/compose/cold | 2.82 ms | 3.65 ms | +62.9% |
| inspector.medium/compose/counts | 6.35 ms | 6.35 ms | +32.5% |
| inspector.medium/compose/settle | 0.7 µs | 1.1 µs | +18.0% |
| inspector.medium/compose/steady | 235.5 µs | 287.2 µs | +11.9% |
| inspector.medium/compose/teardown | 430.5 µs | 580.4 µs | +14.0% |
| inspector.medium/memory/mounted | 1791 KiB | 1791 KiB | +0.4% |
| inspector.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| inspector.medium/plain/burst | 273.8 µs | 391.4 µs | +10.5% |
| inspector.medium/plain/cold | 1.25 ms | 2.95 ms | +3.1% |
| inspector.medium/plain/settle | 0.5 µs | 0.8 µs | +20.7% |
| inspector.medium/plain/steady | 70.6 µs | 136.2 µs | +20.6% |
| inspector.medium/plain/teardown | 410.3 µs | 557.0 µs | +13.7% |
| keyed-append/compose | 616.2 µs | 763.4 µs | -45.2% |
| keyed-append/memory/mounted | 2254 KiB | 2254 KiB | -0.3% |
| keyed-append/memory/teardown | 1 KiB | 1 KiB | -87.5% |
| keyed-append/plain | 697.8 µs | 1.24 ms | -51.7% |
| keyed-insert/compose | 1.96 ms | 2.41 ms | -34.4% |
| keyed-insert/memory/mounted | 2258 KiB | 2258 KiB | +0.0% |
| keyed-insert/memory/teardown | 1 KiB | 1 KiB | — |
| keyed-insert/plain | 1.12 ms | 1.29 ms | -34.2% |
| keyed-prepend/compose | 3.25 ms | 3.53 ms | -26.0% |
| keyed-prepend/memory/mounted | 2261 KiB | 2261 KiB | -0.4% |
| keyed-prepend/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| keyed-prepend/plain | 1.39 ms | 1.61 ms | -21.5% |
| keyed-remove/compose | 1.30 ms | 1.61 ms | -52.3% |
| keyed-remove/memory/mounted | 2253 KiB | 2253 KiB | -0.3% |
| keyed-remove/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-remove/plain | 783.9 µs | 1.38 ms | -45.6% |
| keyed-replace/compose | 31.90 ms | 41.65 ms | -38.0% |
| keyed-replace/memory/mounted | 2288 KiB | 2288 KiB | +0.0% |
| keyed-replace/memory/teardown | 8 KiB | 8 KiB | +0.0% |
| keyed-replace/plain | 19.21 ms | 21.45 ms | -34.1% |
| keyed-reverse/compose | 2.26 ms | 2.32 ms | -22.1% |
| keyed-reverse/memory/mounted | 2265 KiB | 2265 KiB | -0.3% |
| keyed-reverse/memory/teardown | 9 KiB | 9 KiB | — |
| keyed-reverse/plain | 927.4 µs | 977.9 µs | -22.8% |
| keyed-rotate/compose | 1.45 ms | 1.62 ms | -51.8% |
| keyed-rotate/memory/mounted | 2265 KiB | 2265 KiB | +0.0% |
| keyed-rotate/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-rotate/plain | 623.7 µs | 686.0 µs | -48.6% |
| keyed-shuffle/compose | 3.08 ms | 3.23 ms | +2.2% |
| keyed-shuffle/memory/mounted | 2273 KiB | 2273 KiB | +0.8% |
| keyed-shuffle/memory/teardown | 9 KiB | 9 KiB | — |
| keyed-shuffle/plain | 1.33 ms | 1.41 ms | +5.6% |
| mount-cycles/compose | 16.19 ms | 17.75 ms | -30.8% |
| mount-cycles/memory/mounted | 0 KiB | 0 KiB | -100.0% |
| mount-cycles/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| mount-cycles/plain | 12.46 ms | 14.78 ms | -38.0% |
| mount-dispose/compose | 4.61 ms | 7.45 ms | -38.1% |
| mount-dispose/memory/mounted | 0 KiB | 0 KiB | -100.0% |
| mount-dispose/memory/teardown | 0 KiB | 0 KiB | — |
| mount-dispose/plain | 4.43 ms | 5.46 ms | -42.1% |
| ordered-window-scroll/compose | 260.5 µs | 269.1 µs | -48.4% |
| ordered-window-scroll/memory/mounted | 1122 KiB | 1122 KiB | -0.6% |
| ordered-window-scroll/memory/teardown | 1 KiB | 1 KiB | -87.5% |
| projection-keyed-append-500/compose | 13.72 ms | 16.03 ms | +35.7% |
| projection-keyed-append-500/memory/mounted | 3193 KiB | 3193 KiB | +0.0% |
| projection-keyed-append-500/memory/teardown | 9 KiB | 9 KiB | — |
| projection-keyed-append-500/plain | 2.48 ms | 3.88 ms | +1.9% |
| projection-observe-100/compose | 934.9 µs | 1.12 ms | -32.0% |
| projection-observe-100/memory/mounted | 66 KiB | 66 KiB | -10.8% |
| projection-observe-100/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| projection-selection-500/compose | 1.26 ms | 1.28 ms | -3.3% |
| projection-selection-500/memory/mounted | 4068 KiB | 4068 KiB | -0.2% |
| projection-selection-500/memory/teardown | 0 KiB | 0 KiB | — |
| projection-selection-500/plain | 179.6 µs | 189.9 µs | -10.1% |
| scene-2d.extreme/compose/burst | 22.46 ms | 30.25 ms | -25.3% |
| scene-2d.extreme/compose/cold | 12.19 ms | 15.36 ms | +3.0% |
| scene-2d.extreme/compose/counts | 210.64 ms | 210.64 ms | +0.5% |
| scene-2d.extreme/compose/settle | 1.2 µs | 2.4 µs | -18.2% |
| scene-2d.extreme/compose/steady | 87.20 ms | 97.21 ms | +2.7% |
| scene-2d.extreme/compose/teardown | 1.04 ms | 1.62 ms | -11.6% |
| scene-2d.extreme/memory/mounted | 9663 KiB | 9663 KiB | -0.0% |
| scene-2d.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| scene-2d.extreme/plain/burst | 8.87 ms | 22.75 ms | -2.8% |
| scene-2d.extreme/plain/cold | 1.47 ms | 2.56 ms | -13.9% |
| scene-2d.extreme/plain/settle | 1.0 µs | 1.8 µs | -1.0% |
| scene-2d.extreme/plain/steady | 47.33 ms | 53.53 ms | -1.7% |
| scene-2d.extreme/plain/teardown | 605.8 µs | 651.4 µs | +11.3% |
| scene-2d.large/compose/burst | 16.12 ms | 22.23 ms | -37.4% |
| scene-2d.large/compose/cold | 3.80 ms | 7.83 ms | -41.7% |
| scene-2d.large/compose/counts | 102.69 ms | 102.69 ms | -43.1% |
| scene-2d.large/compose/settle | 1.0 µs | 2.4 µs | -42.5% |
| scene-2d.large/compose/steady | 47.71 ms | 51.70 ms | -46.2% |
| scene-2d.large/compose/teardown | 692.5 µs | 1.08 ms | -38.1% |
| scene-2d.large/memory/mounted | 4047 KiB | 4047 KiB | +0.0% |
| scene-2d.large/memory/teardown | 1 KiB | 1 KiB | -87.5% |
| scene-2d.large/plain/burst | 4.56 ms | 7.34 ms | -52.3% |
| scene-2d.large/plain/cold | 1.16 ms | 1.40 ms | -23.8% |
| scene-2d.large/plain/settle | 0.8 µs | 1.4 µs | -46.7% |
| scene-2d.large/plain/steady | 29.41 ms | 31.24 ms | -38.9% |
| scene-2d.large/plain/teardown | 280.9 µs | 406.7 µs | -46.3% |
| scene-2d.medium/compose/burst | 18.40 ms | 22.40 ms | -25.4% |
| scene-2d.medium/compose/cold | 4.33 ms | 5.44 ms | +13.7% |
| scene-2d.medium/compose/counts | 143.45 ms | 143.45 ms | -3.5% |
| scene-2d.medium/compose/settle | 1.1 µs | 1.6 µs | -20.5% |
| scene-2d.medium/compose/steady | 66.62 ms | 69.38 ms | +1.8% |
| scene-2d.medium/compose/teardown | 799.9 µs | 1.00 ms | -21.3% |
| scene-2d.medium/memory/mounted | 2258 KiB | 2258 KiB | -0.4% |
| scene-2d.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| scene-2d.medium/plain/burst | 6.28 ms | 8.85 ms | +0.1% |
| scene-2d.medium/plain/cold | 1.34 ms | 2.08 ms | -35.9% |
| scene-2d.medium/plain/settle | 0.8 µs | 1.0 µs | -36.7% |
| scene-2d.medium/plain/steady | 36.87 ms | 38.24 ms | -4.0% |
| scene-2d.medium/plain/teardown | 375.5 µs | 556.1 µs | -22.0% |
| scene-3d/compose | 8.31 ms | 9.60 ms | -7.8% |
| scene-3d/memory/mounted | 1278 KiB | 1278 KiB | +0.0% |
| scene-3d/memory/teardown | 0 KiB | 0 KiB | — |
| scene-3d/plain | 3.71 ms | 4.43 ms | -0.9% |
| session-cycle.extreme/compose/burst | 117.15 ms | 200.46 ms | -12.2% |
| session-cycle.extreme/compose/cold | 3.8 µs | 8.7 µs | -18.5% |
| session-cycle.extreme/compose/counts | 315.90 ms | 315.90 ms | -12.6% |
| session-cycle.extreme/compose/settle | 2.0 µs | 2.3 µs | -19.7% |
| session-cycle.extreme/compose/steady | 177.28 ms | 243.21 ms | -15.0% |
| session-cycle.extreme/compose/teardown | 2.0 µs | 2.6 µs | -18.9% |
| session-cycle.extreme/memory/mounted | 10 KiB | 10 KiB | +0.0% |
| session-cycle.extreme/memory/teardown | 8 KiB | 8 KiB | — |
| session-cycle.extreme/plain/burst | 109.53 ms | 186.11 ms | -22.7% |
| session-cycle.extreme/plain/cold | 4.4 µs | 6.4 µs | -7.1% |
| session-cycle.extreme/plain/settle | 2.2 µs | 2.7 µs | -20.6% |
| session-cycle.extreme/plain/steady | 216.75 ms | 248.68 ms | -6.3% |
| session-cycle.extreme/plain/teardown | 2.0 µs | 2.5 µs | -23.5% |
| session-cycle.large/compose/burst | 38.27 ms | 60.18 ms | -20.0% |
| session-cycle.large/compose/cold | 3.9 µs | 6.8 µs | -4.7% |
| session-cycle.large/compose/counts | 126.15 ms | 126.15 ms | +0.6% |
| session-cycle.large/compose/settle | 1.9 µs | 2.2 µs | -3.0% |
| session-cycle.large/compose/steady | 71.63 ms | 88.39 ms | +0.8% |
| session-cycle.large/compose/teardown | 1.7 µs | 2.5 µs | -16.1% |
| session-cycle.large/memory/mounted | 1 KiB | 1 KiB | -50.0% |
| session-cycle.large/memory/teardown | 0 KiB | 0 KiB | — |
| session-cycle.large/plain/burst | 49.50 ms | 61.77 ms | +28.6% |
| session-cycle.large/plain/cold | 5.8 µs | 15.9 µs | +21.2% |
| session-cycle.large/plain/settle | 2.1 µs | 2.6 µs | -5.1% |
| session-cycle.large/plain/steady | 63.66 ms | 98.10 ms | -17.2% |
| session-cycle.large/plain/teardown | 1.8 µs | 2.1 µs | -8.0% |
| session-cycle.medium/compose/burst | 8.69 ms | 14.20 ms | -41.6% |
| session-cycle.medium/compose/cold | 3.8 µs | 5.4 µs | +14.9% |
| session-cycle.medium/compose/counts | 32.41 ms | 32.41 ms | -18.7% |
| session-cycle.medium/compose/settle | 1.5 µs | 2.0 µs | +2.6% |
| session-cycle.medium/compose/steady | 14.92 ms | 20.96 ms | -23.0% |
| session-cycle.medium/compose/teardown | 1.9 µs | 2.2 µs | +19.5% |
| session-cycle.medium/memory/mounted | 0 KiB | 0 KiB | — |
| session-cycle.medium/memory/teardown | 0 KiB | 0 KiB | — |
| session-cycle.medium/plain/burst | 5.38 ms | 13.18 ms | -52.8% |
| session-cycle.medium/plain/cold | 4.0 µs | 5.0 µs | +26.2% |
| session-cycle.medium/plain/settle | 1.6 µs | 2.9 µs | +37.7% |
| session-cycle.medium/plain/steady | 13.06 ms | 21.25 ms | -35.4% |
| session-cycle.medium/plain/teardown | 1.6 µs | 2.2 µs | +19.3% |
| spatial-scene.extreme/compose/burst | 79.05 ms | 88.47 ms | -41.8% |
| spatial-scene.extreme/compose/cold | 6.37 ms | 12.51 ms | -43.8% |
| spatial-scene.extreme/compose/counts | 181.29 ms | 181.29 ms | -32.0% |
| spatial-scene.extreme/compose/settle | 1.9 µs | 2.5 µs | -5.6% |
| spatial-scene.extreme/compose/steady | 26.46 ms | 36.99 ms | -50.9% |
| spatial-scene.extreme/compose/teardown | 2.00 ms | 4.03 ms | -52.0% |
| spatial-scene.extreme/memory/mounted | 5285 KiB | 5285 KiB | +0.0% |
| spatial-scene.extreme/memory/teardown | 9 KiB | 9 KiB | — |
| spatial-scene.extreme/plain/burst | 39.14 ms | 47.32 ms | -25.0% |
| spatial-scene.extreme/plain/cold | 3.17 ms | 6.12 ms | -9.1% |
| spatial-scene.extreme/plain/settle | 1.9 µs | 3.7 µs | -17.5% |
| spatial-scene.extreme/plain/steady | 44.23 ms | 48.61 ms | -41.1% |
| spatial-scene.extreme/plain/teardown | 1.04 ms | 1.41 ms | -18.0% |
| spatial-scene.large/compose/burst | 24.04 ms | 27.45 ms | -36.5% |
| spatial-scene.large/compose/cold | 2.40 ms | 3.86 ms | -29.7% |
| spatial-scene.large/compose/counts | 40.37 ms | 40.37 ms | -47.8% |
| spatial-scene.large/compose/settle | 1.6 µs | 2.3 µs | +0.6% |
| spatial-scene.large/compose/steady | 10.46 ms | 11.24 ms | -45.5% |
| spatial-scene.large/compose/teardown | 579.0 µs | 794.6 µs | -28.8% |
| spatial-scene.large/memory/mounted | 1759 KiB | 1759 KiB | +0.1% |
| spatial-scene.large/memory/teardown | 9 KiB | 9 KiB | — |
| spatial-scene.large/plain/burst | 8.83 ms | 11.17 ms | -36.9% |
| spatial-scene.large/plain/cold | 653.7 µs | 1.27 ms | -41.2% |
| spatial-scene.large/plain/settle | 0.7 µs | 0.9 µs | -59.2% |
| spatial-scene.large/plain/steady | 11.98 ms | 13.70 ms | -46.0% |
| spatial-scene.large/plain/teardown | 171.3 µs | 272.8 µs | -51.9% |
| spatial-scene.medium/compose/burst | 8.80 ms | 11.59 ms | -33.5% |
| spatial-scene.medium/compose/cold | 880.4 µs | 1.51 ms | -29.9% |
| spatial-scene.medium/compose/counts | 20.72 ms | 20.72 ms | -41.6% |
| spatial-scene.medium/compose/settle | 0.8 µs | 1.1 µs | -22.4% |
| spatial-scene.medium/compose/steady | 6.01 ms | 7.18 ms | -35.5% |
| spatial-scene.medium/compose/teardown | 205.3 µs | 251.3 µs | -28.6% |
| spatial-scene.medium/memory/mounted | 690 KiB | 690 KiB | +0.0% |
| spatial-scene.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| spatial-scene.medium/plain/burst | 3.58 ms | 4.66 ms | -22.2% |
| spatial-scene.medium/plain/cold | 337.3 µs | 629.5 µs | -21.6% |
| spatial-scene.medium/plain/settle | 0.6 µs | 0.9 µs | -27.1% |
| spatial-scene.medium/plain/steady | 6.04 ms | 7.69 ms | -25.8% |
| spatial-scene.medium/plain/teardown | 76.5 µs | 110.3 µs | -25.3% |
| status-panel/compose | 319.8 µs | 333.1 µs | -43.6% |
| status-panel/memory/mounted | 51 KiB | 51 KiB | +18.6% |
| status-panel/memory/teardown | 8 KiB | 8 KiB | — |
| status-panel/plain | 59.5 µs | 90.2 µs | -41.8% |
| unwind/compose | 3.98 ms | 7.07 ms | +11.9% |
| unwind/memory/mounted | 1 KiB | 1 KiB | +0.0% |
| unwind/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| unwind/plain | 3.24 ms | 3.99 ms | -10.8% |
| update-batched/compose | 3.05 ms | 3.44 ms | +4.7% |
| update-batched/memory/mounted | 1868 KiB | 1868 KiB | -0.4% |
| update-batched/memory/teardown | 0 KiB | 0 KiB | — |
| update-batched/plain | 1.04 ms | 1.08 ms | +2.5% |
| update-fanout/compose | 1.63 ms | 1.84 ms | +14.3% |
| update-fanout/memory/mounted | 1812 KiB | 1812 KiB | +0.0% |
| update-fanout/memory/teardown | 0 KiB | 0 KiB | — |
| update-fanout/plain | 1.06 ms | 1.15 ms | +20.9% |
| update-leaf/compose | 34.7 µs | 43.5 µs | -14.7% |
| update-leaf/memory/mounted | 2748 KiB | 2748 KiB | -0.3% |
| update-leaf/memory/teardown | 0 KiB | 0 KiB | — |
| update-leaf/plain | 13.4 µs | 16.7 µs | -19.2% |
| update-repeated/compose | 292.5 µs | 308.3 µs | -16.9% |
| update-repeated/memory/mounted | 9 KiB | 9 KiB | -50.0% |
| update-repeated/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| update-repeated/plain | 37.6 µs | 50.9 µs | -13.9% |
| virtual-filtered-list.extreme/compose/burst | 834.38 ms | 854.59 ms | +6.9% |
| virtual-filtered-list.extreme/compose/cold | 513.26 ms | 554.95 ms | +5.7% |
| virtual-filtered-list.extreme/compose/counts | 1375.82 ms | 1375.82 ms | +8.0% |
| virtual-filtered-list.extreme/compose/settle | 2.4 µs | 3.5 µs | -9.8% |
| virtual-filtered-list.extreme/compose/steady | 17.40 ms | 20.30 ms | +23.0% |
| virtual-filtered-list.extreme/compose/teardown | 521.1 µs | 565.6 µs | -0.3% |
| virtual-filtered-list.extreme/memory/mounted | 27919 KiB | 27919 KiB | +0.0% |
| virtual-filtered-list.extreme/memory/teardown | 1 KiB | 1 KiB | -87.5% |
| virtual-filtered-list.extreme/plain/burst | 780.97 ms | 798.82 ms | +7.6% |
| virtual-filtered-list.extreme/plain/cold | 494.58 ms | 517.91 ms | +6.1% |
| virtual-filtered-list.extreme/plain/settle | 2.6 µs | 3.8 µs | -4.7% |
| virtual-filtered-list.extreme/plain/steady | 10.51 ms | 14.28 ms | +2.3% |
| virtual-filtered-list.extreme/plain/teardown | 215.2 µs | 664.7 µs | +9.8% |
| virtual-filtered-list.large/compose/burst | 107.85 ms | 114.82 ms | -14.2% |
| virtual-filtered-list.large/compose/cold | 62.22 ms | 66.80 ms | -20.5% |
| virtual-filtered-list.large/compose/counts | 190.83 ms | 190.83 ms | -19.7% |
| virtual-filtered-list.large/compose/settle | 2.3 µs | 2.8 µs | +14.5% |
| virtual-filtered-list.large/compose/steady | 10.61 ms | 16.79 ms | -25.0% |
| virtual-filtered-list.large/compose/teardown | 268.4 µs | 437.4 µs | -7.6% |
| virtual-filtered-list.large/memory/mounted | 6304 KiB | 6304 KiB | -0.0% |
| virtual-filtered-list.large/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| virtual-filtered-list.large/plain/burst | 90.23 ms | 98.69 ms | -21.7% |
| virtual-filtered-list.large/plain/cold | 58.39 ms | 61.17 ms | -21.4% |
| virtual-filtered-list.large/plain/settle | 2.8 µs | 4.0 µs | +36.4% |
| virtual-filtered-list.large/plain/steady | 5.95 ms | 7.76 ms | -13.0% |
| virtual-filtered-list.large/plain/teardown | 88.2 µs | 250.4 µs | -24.6% |
| virtual-filtered-list.medium/compose/burst | 12.78 ms | 15.66 ms | -48.1% |
| virtual-filtered-list.medium/compose/cold | 6.79 ms | 7.55 ms | -46.6% |
| virtual-filtered-list.medium/compose/counts | 31.37 ms | 31.37 ms | -47.3% |
| virtual-filtered-list.medium/compose/settle | 0.8 µs | 1.0 µs | -41.8% |
| virtual-filtered-list.medium/compose/steady | 6.27 ms | 8.21 ms | -46.6% |
| virtual-filtered-list.medium/compose/teardown | 101.4 µs | 162.2 µs | -47.8% |
| virtual-filtered-list.medium/memory/mounted | 1601 KiB | 1601 KiB | -0.6% |
| virtual-filtered-list.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| virtual-filtered-list.medium/plain/burst | 10.33 ms | 11.97 ms | -44.5% |
| virtual-filtered-list.medium/plain/cold | 6.09 ms | 6.48 ms | -47.5% |
| virtual-filtered-list.medium/plain/settle | 0.6 µs | 0.9 µs | -38.9% |
| virtual-filtered-list.medium/plain/steady | 3.06 ms | 4.65 ms | -51.1% |
| virtual-filtered-list.medium/plain/teardown | 34.2 µs | 45.3 µs | -49.6% |

## Trends over the last 4 main commits

```mermaid
xychart-beta
    title "animate-many/compose (median µs)"
    x-axis 1 --> 4
    line [3066.4, 6952.0, 6809.4, 7022.5]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [6516.1, 4147.1, 7924.7, 6800.6]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [11407.1, 8355.0, 11077.8, 10540.2]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [68091.2, 47605.1, 84532.8, 70635.7]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.0, 1.0, 1.1, 1.4]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [25890.3, 17137.2, 33073.2, 27209.7]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [2475.2, 1994.0, 2796.3, 2870.3]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [3896.2, 3809.1, 3862.2, 1873.3]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [5692.2, 5515.9, 5845.7, 3938.9]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [57607.9, 56296.6, 57762.9, 28652.9]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.2, 0.8, 0.8, 0.6]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [26697.4, 26221.7, 26378.1, 12144.9]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [1432.5, 1092.3, 1223.6, 766.2]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [598.2, 606.3, 1380.7, 1026.7]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [1178.6, 1128.0, 1758.0, 1216.6]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [10635.9, 10387.5, 24309.0, 17291.5]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [0.3, 0.4, 0.7, 0.5]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [4717.9, 4534.1, 10683.3, 7716.1]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [212.7, 211.0, 408.9, 271.2]
```

```mermaid
xychart-beta
    title "branch-swap/compose (median µs)"
    x-axis 1 --> 4
    line [3609.5, 2319.6, 3549.8, 3405.8]
```

```mermaid
xychart-beta
    title "cold-mount-100/compose (median µs)"
    x-axis 1 --> 4
    line [592.6, 519.9, 885.4, 445.1]
```

```mermaid
xychart-beta
    title "cold-mount-1000/compose (median µs)"
    x-axis 1 --> 4
    line [8085.8, 5389.9, 8549.6, 6933.2]
```

```mermaid
xychart-beta
    title "cold-mount-10000/compose (median µs)"
    x-axis 1 --> 4
    line [73945.7, 98256.1, 94238.7, 59096.4]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [572777.3, 535083.2, 832744.6, 637093.8]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [350893.5, 328646.9, 515839.7, 377498.6]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [961903.0, 895177.9, 1510853.2, 1085251.1]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.8, 2.4, 2.2, 2.6]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [12594.0, 11681.8, 22844.9, 17958.7]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [1086.6, 1137.9, 1208.9, 1019.3]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [140083.3, 135962.2, 137048.1, 79047.3]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [80791.9, 79866.7, 78358.1, 46545.2]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [269572.2, 259528.8, 247425.1, 134287.8]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.0, 2.0, 1.8, 1.2]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [17382.0, 15842.8, 15303.1, 9007.1]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [517.4, 507.1, 530.1, 308.6]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [49689.5, 40264.0, 63124.3, 54341.9]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [28216.2, 22726.8, 35966.3, 30152.5]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [101676.4, 85010.8, 128707.0, 106187.2]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.2, 2.3, 1.8, 2.4]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [12139.2, 8725.2, 12812.2, 11984.4]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [242.3, 222.0, 291.3, 267.8]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [8748.3, 13808.9, 14242.7, 14836.6]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [306.9, 503.4, 495.3, 587.1]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [12107.6, 25337.6, 22769.2, 21520.0]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [0.6, 1.1, 1.0, 0.8]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [461.4, 853.9, 896.4, 863.9]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [300.0, 528.8, 524.0, 500.2]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [7315.2, 6455.4, 7861.5, 5932.0]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [321.9, 311.0, 312.5, 196.1]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [15457.3, 15616.4, 15030.0, 9619.3]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [0.9, 0.8, 0.8, 0.7]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [871.8, 849.7, 860.9, 434.1]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [255.7, 242.4, 250.0, 139.2]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [1884.9, 1716.2, 3396.7, 2022.7]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [150.8, 125.0, 199.3, 164.2]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [4488.4, 3035.8, 6218.8, 3927.1]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [0.6, 0.4, 0.7, 0.5]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [451.5, 440.8, 842.9, 675.3]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [71.1, 68.2, 109.1, 88.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [36450.3, 44418.2, 46637.6, 27103.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [22317.0, 30608.9, 30755.4, 23786.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [157183.8, 226408.0, 207640.3, 143081.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.5, 2.2, 2.0, 1.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [38679.7, 58936.7, 52064.1, 26669.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [870.1, 1178.4, 1115.4, 774.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [13822.3, 12671.8, 13643.0, 12953.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [8768.9, 8903.6, 12727.0, 12419.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [56991.3, 49197.8, 64112.9, 60677.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.0, 2.2, 1.6, 1.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [16083.5, 12191.6, 17784.2, 14312.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [346.1, 297.1, 375.4, 338.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [4810.6, 5385.1, 7593.1, 5112.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [3510.0, 3688.3, 5372.0, 3383.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [22176.2, 21779.2, 33203.4, 22936.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [0.9, 1.3, 1.1, 0.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [5091.1, 4800.2, 8300.0, 5909.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [138.2, 141.4, 189.4, 143.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [37375.3, 42100.8, 41076.4, 43172.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [28909.8, 26506.8, 29632.4, 23700.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [312089.2, 264728.7, 287119.4, 313931.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.6, 2.4, 1.9, 2.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [144362.2, 138910.8, 151388.1, 146004.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [1011.3, 1046.8, 1153.3, 1158.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [11392.1, 16006.5, 14237.9, 8830.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [10645.8, 12312.2, 10388.0, 8077.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [86389.6, 118638.8, 108507.3, 60853.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.5, 2.3, 1.6, 1.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [40309.4, 56606.6, 50910.5, 29130.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [312.8, 448.9, 398.2, 225.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [8485.7, 8733.8, 7811.5, 5053.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [5123.1, 5090.8, 6479.6, 3545.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [60621.5, 66177.5, 62123.7, 40694.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.3, 1.6, 1.6, 1.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [22448.9, 25049.9, 23583.9, 14477.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [239.6, 252.1, 242.6, 155.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [51119.4, 42743.7, 45181.7, 38370.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [31173.0, 29216.5, 29632.0, 19346.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [276895.4, 231546.3, 239558.4, 151482.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.3, 2.0, 2.1, 2.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [103496.4, 98719.9, 87903.0, 60700.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [1459.8, 1163.1, 1253.7, 814.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [9662.4, 8486.1, 12526.7, 11002.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [7331.9, 8413.6, 11406.1, 12037.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [62489.1, 65083.5, 93016.9, 76013.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.6, 1.6, 1.7, 1.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [17762.3, 18587.4, 28783.0, 23340.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [221.0, 244.4, 350.0, 314.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [5597.4, 5043.1, 7507.7, 7112.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [4098.3, 3677.5, 4917.8, 4309.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [31911.5, 26270.5, 38265.0, 35758.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.0, 1.7, 1.0, 1.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [10781.6, 9751.3, 14145.6, 11476.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [163.7, 158.3, 209.3, 186.8]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [18098.0, 16855.7, 18205.9, 16320.2]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [102015.1, 100238.6, 110792.2, 98791.5]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [358907.4, 324615.1, 382570.8, 305419.8]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.8, 1.9, 2.1, 1.7]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [90630.1, 81412.5, 95946.8, 80410.1]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [52871.1, 45496.4, 55490.6, 46463.3]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [9879.6, 9266.1, 9580.3, 5350.4]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [42924.1, 40697.9, 38453.5, 27622.0]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [159260.0, 136585.0, 136418.7, 92540.6]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.1, 1.5, 1.6, 1.6]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [56879.3, 47700.5, 50360.1, 29499.8]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [16802.1, 13908.2, 14198.2, 10974.4]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [4273.0, 4064.7, 6941.6, 5470.1]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [14214.0, 12986.0, 18998.1, 20759.9]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [60159.0, 56773.8, 91261.8, 68607.4]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.9, 1.7, 1.6, 1.2]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [20781.1, 19484.3, 34314.8, 25155.4]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [5912.5, 5137.9, 6370.7, 5086.2]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [82088.2, 67803.4, 81772.9, 78539.9]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [23851.0, 19385.3, 27237.7, 29579.2]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [215972.6, 170155.4, 218067.6, 205395.8]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.5, 2.9, 2.1, 2.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [46499.2, 63403.0, 50693.5, 50493.5]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [13254.3, 13259.6, 13403.6, 14674.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [23829.2, 21410.5, 26910.9, 27013.4]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [9046.6, 8698.0, 11112.7, 11237.4]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [66263.4, 60081.6, 78201.5, 74218.9]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.2, 2.3, 1.7, 2.3]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [15970.8, 12947.8, 17610.3, 17826.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [3313.5, 2966.7, 2967.8, 3445.2]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [10053.5, 13258.0, 10542.4, 6875.4]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [4425.1, 5999.0, 4925.5, 3251.8]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [26589.7, 40004.4, 35054.4, 23518.5]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.0, 1.5, 1.0, 0.9]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [6593.9, 10265.5, 7799.1, 4375.5]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [909.1, 1375.7, 1014.9, 866.7]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [83025.5, 131890.1, 139155.5, 102900.1]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [27112.7, 32898.9, 35114.3, 19901.5]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [297306.3, 392730.6, 375325.7, 279449.1]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.9, 2.5, 2.5, 2.5]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [104435.7, 129482.8, 118556.7, 87490.4]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [11409.1, 14374.0, 14539.1, 12187.9]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [37687.9, 36619.3, 41760.4, 43897.0]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [9427.2, 7416.6, 10731.1, 9936.2]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [118464.0, 105642.9, 132017.4, 113098.8]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.0, 2.4, 1.7, 2.1]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [36383.7, 29649.6, 42899.0, 36038.5]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [3319.5, 3173.8, 3204.1, 3765.1]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [21304.8, 17609.9, 19632.8, 19428.5]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [5522.9, 4875.0, 6616.8, 5391.1]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [73432.0, 63426.8, 72731.7, 66518.2]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.9, 1.0, 1.3, 1.3]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [21627.0, 18049.0, 19673.0, 19997.6]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [1421.5, 998.7, 1251.6, 1111.8]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [28431.3, 29661.9, 27082.8, 16711.4]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [25491.4, 23933.9, 25087.3, 17441.6]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [103374.1, 95880.0, 93198.2, 60028.1]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.8, 1.9, 1.6, 1.8]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [4152.6, 3939.8, 3787.2, 2841.3]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [12752.1, 12268.9, 12210.0, 9099.8]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [12559.3, 12285.7, 12193.2, 7053.5]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [10065.7, 12236.3, 12145.6, 7446.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [47228.6, 41552.7, 49545.9, 25620.0]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.2, 1.3, 1.2, 1.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [1880.4, 1925.6, 1869.1, 1138.5]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [3848.1, 4042.8, 3927.2, 2747.9]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [2692.8, 4883.0, 4638.9, 4912.8]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [3511.6, 5344.2, 4334.1, 5274.7]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [11899.6, 20010.0, 21389.0, 22972.4]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [0.8, 0.8, 0.9, 0.8]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [546.9, 864.1, 884.8, 935.5]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [793.8, 1245.8, 1305.4, 1265.7]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [38306.7, 27292.5, 30271.6, 28243.8]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [26392.1, 25728.0, 24789.0, 25091.7]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [146562.2, 118482.8, 130233.0, 121188.5]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.1, 1.2, 1.5, 1.9]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [35077.9, 31134.3, 31374.2, 30446.4]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [14166.4, 14892.9, 12081.1, 11856.0]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [16371.6, 13675.4, 14796.5, 8143.5]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [13125.5, 12164.0, 12241.7, 8754.9]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [71347.2, 67401.3, 63961.0, 38511.1]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.8, 1.6, 1.8, 1.2]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [17130.8, 15636.5, 15592.5, 6886.2]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [4985.7, 4474.5, 4408.6, 3132.6]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [5454.2, 5016.4, 5182.8, 4977.7]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [6039.1, 4145.2, 5211.5, 4920.9]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [27680.1, 23447.7, 25731.3, 23381.3]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.2, 0.8, 1.1, 0.8]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [6474.9, 6388.6, 6421.2, 6421.9]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [1477.1, 1273.6, 1329.9, 1262.9]
```

```mermaid
xychart-beta
    title "events/compose (median µs)"
    x-axis 1 --> 4
    line [10464.1, 9121.0, 11019.8, 9922.2]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [7448.2, 5545.2, 8042.0, 7887.1]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [18874.4, 15878.8, 20409.9, 18550.5]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [34335.8, 23488.3, 37816.7, 33632.2]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.6, 1.4, 1.2, 2.0]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [245.7, 207.7, 236.8, 270.8]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [2590.5, 2153.7, 2312.0, 3007.8]
```

```mermaid
xychart-beta
    title "inspector.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [3270.5, 4234.2, 4065.4, 2059.0]
```

```mermaid
xychart-beta
    title "inspector.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [6003.2, 9644.5, 6469.4, 5148.0]
```

```mermaid
xychart-beta
    title "inspector.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [15848.8, 18252.6, 18863.7, 13882.7]
```

```mermaid
xychart-beta
    title "inspector.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [0.8, 1.2, 0.8, 0.7]
```

```mermaid
xychart-beta
    title "inspector.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [184.9, 255.0, 227.5, 142.8]
```

```mermaid
xychart-beta
    title "inspector.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [939.1, 1289.4, 1054.6, 747.2]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [652.7, 1463.0, 1421.7, 1608.0]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [1084.4, 2117.8, 1731.0, 2819.9]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [2345.3, 5474.4, 4793.9, 6353.6]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [0.4, 0.6, 0.6, 0.7]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [101.1, 207.3, 210.4, 235.5]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [183.0, 391.0, 377.6, 430.5]
```

```mermaid
xychart-beta
    title "keyed-append/compose (median µs)"
    x-axis 1 --> 4
    line [1217.7, 1121.3, 1123.5, 616.2]
```

```mermaid
xychart-beta
    title "keyed-insert/compose (median µs)"
    x-axis 1 --> 4
    line [1418.3, 1388.8, 2985.6, 1957.4]
```

```mermaid
xychart-beta
    title "keyed-prepend/compose (median µs)"
    x-axis 1 --> 4
    line [3339.2, 2323.0, 4385.8, 3245.3]
```

```mermaid
xychart-beta
    title "keyed-remove/compose (median µs)"
    x-axis 1 --> 4
    line [1834.7, 2550.5, 2731.1, 1302.2]
```

```mermaid
xychart-beta
    title "keyed-replace/compose (median µs)"
    x-axis 1 --> 4
    line [56638.2, 52082.4, 51437.5, 31895.5]
```

```mermaid
xychart-beta
    title "keyed-reverse/compose (median µs)"
    x-axis 1 --> 4
    line [1366.2, 1329.2, 2904.2, 2262.2]
```

```mermaid
xychart-beta
    title "keyed-rotate/compose (median µs)"
    x-axis 1 --> 4
    line [2837.0, 2918.3, 3001.8, 1448.0]
```

```mermaid
xychart-beta
    title "keyed-shuffle/compose (median µs)"
    x-axis 1 --> 4
    line [1337.6, 3134.0, 3010.8, 3078.2]
```

```mermaid
xychart-beta
    title "mount-cycles/compose (median µs)"
    x-axis 1 --> 4
    line [24941.5, 23043.1, 23398.1, 16185.9]
```

```mermaid
xychart-beta
    title "mount-dispose/compose (median µs)"
    x-axis 1 --> 4
    line [7076.9, 9579.0, 7445.0, 4609.4]
```

```mermaid
xychart-beta
    title "ordered-window-scroll/compose (median µs)"
    x-axis 1 --> 4
    line [412.1, 498.2, 504.6, 260.5]
```

```mermaid
xychart-beta
    title "projection-keyed-append-500/compose (median µs)"
    x-axis 1 --> 4
    line [5754.2, 14069.9, 10109.7, 13717.9]
```

```mermaid
xychart-beta
    title "projection-observe-100/compose (median µs)"
    x-axis 1 --> 4
    line [1160.9, 1688.5, 1375.7, 934.9]
```

```mermaid
xychart-beta
    title "projection-selection-500/compose (median µs)"
    x-axis 1 --> 4
    line [1347.5, 1257.8, 1305.3, 1261.8]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [31592.1, 26430.2, 30086.2, 22463.2]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [11079.4, 9876.1, 11841.3, 12194.2]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [216069.1, 186166.0, 209496.7, 210635.3]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.2, 1.2, 1.5, 1.2]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [90044.4, 84419.8, 84931.4, 87195.8]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [1242.8, 991.8, 1179.9, 1042.6]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [23109.8, 30942.5, 25739.8, 16117.3]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [4352.7, 6212.1, 6516.0, 3797.0]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [150813.2, 189240.1, 180380.0, 102688.1]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.3, 1.9, 1.8, 1.0]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [67819.6, 92259.3, 88664.7, 47707.5]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [835.3, 1495.8, 1118.6, 692.5]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [20349.9, 15428.8, 24654.7, 18400.6]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [4709.8, 4295.8, 3803.5, 4326.4]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [147623.1, 136904.9, 148677.3, 143451.4]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.2, 0.8, 1.4, 1.1]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [69181.6, 65753.4, 65422.7, 66617.4]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [1053.9, 734.4, 1016.7, 799.9]
```

```mermaid
xychart-beta
    title "scene-3d/compose (median µs)"
    x-axis 1 --> 4
    line [10050.2, 7649.9, 9011.1, 8309.7]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [111388.5, 145081.3, 133361.3, 117151.1]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [4.4, 4.2, 4.6, 3.8]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [347844.7, 331552.2, 361578.0, 315896.8]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.2, 2.2, 2.4, 2.0]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [189371.2, 170051.3, 208681.3, 177283.5]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [2.3, 1.9, 2.4, 2.0]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [55471.8, 41682.9, 47858.1, 38268.2]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [4.1, 3.4, 4.0, 3.9]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [152922.2, 127280.8, 125332.5, 126145.5]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.9, 1.9, 2.0, 1.9]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [70217.2, 67586.5, 71040.2, 71631.7]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [1.9, 1.7, 2.1, 1.7]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [9419.6, 16119.8, 14877.2, 8687.9]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [2.9, 4.7, 3.3, 3.8]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [32366.0, 44739.0, 39841.4, 32409.8]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.2, 1.5, 1.5, 1.5]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [16834.7, 22422.0, 19376.8, 14924.2]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [1.2, 1.7, 1.6, 1.9]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [131626.4, 122408.9, 135923.1, 79047.5]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [11274.4, 10752.6, 11344.1, 6370.1]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [280294.2, 255499.9, 266526.7, 181289.9]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.7, 1.7, 2.0, 1.9]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [54938.1, 53195.1, 53842.8, 26463.3]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [4193.8, 3229.5, 4161.6, 1998.5]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [24854.0, 36908.9, 37836.4, 24036.9]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [3382.2, 4654.1, 3405.2, 2395.1]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [50109.8, 74015.2, 77275.2, 40372.0]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.2, 1.9, 1.6, 1.6]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [12804.6, 19446.0, 19168.6, 10456.3]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [635.6, 862.7, 813.6, 579.0]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [7485.6, 7465.0, 13238.7, 8798.9]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [732.5, 682.2, 1256.5, 880.4]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [16776.7, 16094.7, 35495.1, 20724.3]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [0.9, 0.7, 1.0, 0.8]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [4566.2, 4426.4, 9311.4, 6005.6]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [160.7, 145.7, 287.7, 205.3]
```

```mermaid
xychart-beta
    title "status-panel/compose (median µs)"
    x-axis 1 --> 4
    line [594.8, 546.6, 567.0, 319.8]
```

```mermaid
xychart-beta
    title "unwind/compose (median µs)"
    x-axis 1 --> 4
    line [4404.4, 3896.7, 3558.7, 3983.7]
```

```mermaid
xychart-beta
    title "update-batched/compose (median µs)"
    x-axis 1 --> 4
    line [3025.0, 2927.0, 2916.4, 3054.1]
```

```mermaid
xychart-beta
    title "update-fanout/compose (median µs)"
    x-axis 1 --> 4
    line [777.2, 1629.0, 1423.8, 1627.8]
```

```mermaid
xychart-beta
    title "update-leaf/compose (median µs)"
    x-axis 1 --> 4
    line [33.7, 23.3, 40.6, 34.7]
```

```mermaid
xychart-beta
    title "update-repeated/compose (median µs)"
    x-axis 1 --> 4
    line [291.8, 288.2, 351.9, 292.5]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/burst (median µs)"
    x-axis 1 --> 4
    line [468218.5, 855118.6, 780270.5, 834379.1]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/cold (median µs)"
    x-axis 1 --> 4
    line [303705.7, 494927.2, 485557.0, 513263.7]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/counts (median µs)"
    x-axis 1 --> 4
    line [758775.9, 1513830.2, 1273975.2, 1375818.0]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.5, 2.4, 2.6, 2.4]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/steady (median µs)"
    x-axis 1 --> 4
    line [8156.9, 15826.4, 14142.7, 17395.9]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [337.4, 510.6, 522.8, 521.1]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/burst (median µs)"
    x-axis 1 --> 4
    line [103439.2, 85508.3, 125691.5, 107855.0]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/cold (median µs)"
    x-axis 1 --> 4
    line [59355.8, 50136.7, 78271.4, 62224.0]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/counts (median µs)"
    x-axis 1 --> 4
    line [189934.0, 152506.8, 237753.9, 190827.8]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/settle (median µs)"
    x-axis 1 --> 4
    line [2.3, 2.6, 2.0, 2.3]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/steady (median µs)"
    x-axis 1 --> 4
    line [12089.3, 9916.3, 14136.9, 10607.7]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [262.7, 240.8, 290.6, 268.4]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/burst (median µs)"
    x-axis 1 --> 4
    line [17844.8, 25511.5, 24629.5, 12779.6]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/cold (median µs)"
    x-axis 1 --> 4
    line [9422.5, 13481.1, 12703.5, 6786.8]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/counts (median µs)"
    x-axis 1 --> 4
    line [44077.6, 61203.3, 59533.4, 31373.7]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/settle (median µs)"
    x-axis 1 --> 4
    line [1.0, 1.7, 1.3, 0.8]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/steady (median µs)"
    x-axis 1 --> 4
    line [9077.3, 12332.6, 11738.6, 6268.6]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/teardown (median µs)"
    x-axis 1 --> 4
    line [139.6, 199.8, 194.4, 101.4]
```
