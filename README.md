# Compose performance

Latest: `0a37e0b8c2401abd917f05f036fdaa7f97fede83` on 2026-11-06T161056Z, measured on the CI Ubuntu runner by the paired performance shards.
Each value is the median of the candidate arm's samples; p95 is shown beside it. Change compares the previous main commit.

| Benchmark | Median | p95 | Change |
| --- | --- | --- | --- |
| animate-many/compose | 6.81 ms | 7.13 ms | -2.1% |
| animate-many/memory/mounted | 2184 KiB | 2184 KiB | +0.0% |
| animate-many/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| animate-many/plain | 1.64 ms | 1.66 ms | -0.5% |
| animated-navigation.extreme/compose/burst | 7.92 ms | 8.41 ms | +91.1% |
| animated-navigation.extreme/compose/cold | 11.08 ms | 16.40 ms | +32.6% |
| animated-navigation.extreme/compose/counts | 84.53 ms | 84.53 ms | +77.6% |
| animated-navigation.extreme/compose/settle | 1.1 µs | 1.5 µs | +4.0% |
| animated-navigation.extreme/compose/steady | 33.07 ms | 33.62 ms | +93.0% |
| animated-navigation.extreme/compose/teardown | 2.80 ms | 3.96 ms | +40.2% |
| animated-navigation.extreme/memory/mounted | 6814 KiB | 6814 KiB | +0.1% |
| animated-navigation.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| animated-navigation.extreme/plain/burst | 1.40 ms | 1.51 ms | +80.0% |
| animated-navigation.extreme/plain/cold | 4.99 ms | 7.78 ms | +20.3% |
| animated-navigation.extreme/plain/settle | 0.7 µs | 1.3 µs | -42.5% |
| animated-navigation.extreme/plain/steady | 19.09 ms | 20.40 ms | +94.8% |
| animated-navigation.extreme/plain/teardown | 3.41 ms | 4.66 ms | +8.5% |
| animated-navigation.large/compose/burst | 3.86 ms | 4.15 ms | +1.4% |
| animated-navigation.large/compose/cold | 5.85 ms | 9.86 ms | +6.0% |
| animated-navigation.large/compose/counts | 57.76 ms | 57.76 ms | +2.6% |
| animated-navigation.large/compose/settle | 0.8 µs | 1.5 µs | +9.3% |
| animated-navigation.large/compose/steady | 26.38 ms | 27.29 ms | +0.6% |
| animated-navigation.large/compose/teardown | 1.22 ms | 1.69 ms | +12.0% |
| animated-navigation.large/memory/mounted | 3410 KiB | 3410 KiB | -0.2% |
| animated-navigation.large/memory/teardown | 0 KiB | 0 KiB | — |
| animated-navigation.large/plain/burst | 683.6 µs | 747.1 µs | +0.7% |
| animated-navigation.large/plain/cold | 2.69 ms | 4.59 ms | +66.2% |
| animated-navigation.large/plain/settle | 0.6 µs | 0.8 µs | +10.2% |
| animated-navigation.large/plain/steady | 8.88 ms | 9.16 ms | -0.5% |
| animated-navigation.large/plain/teardown | 1.16 ms | 1.57 ms | +10.7% |
| animated-navigation.medium/compose/burst | 1.38 ms | 1.58 ms | +127.7% |
| animated-navigation.medium/compose/cold | 1.76 ms | 3.57 ms | +55.9% |
| animated-navigation.medium/compose/counts | 24.31 ms | 24.31 ms | +134.0% |
| animated-navigation.medium/compose/settle | 0.7 µs | 1.2 µs | +74.2% |
| animated-navigation.medium/compose/steady | 10.68 ms | 11.22 ms | +135.6% |
| animated-navigation.medium/compose/teardown | 408.9 µs | 568.1 µs | +93.8% |
| animated-navigation.medium/memory/mounted | 1147 KiB | 1147 KiB | -0.7% |
| animated-navigation.medium/memory/teardown | 0 KiB | 0 KiB | — |
| animated-navigation.medium/plain/burst | 227.0 µs | 298.3 µs | +82.6% |
| animated-navigation.medium/plain/cold | 685.2 µs | 1.51 ms | +4.4% |
| animated-navigation.medium/plain/settle | 0.5 µs | 1.3 µs | +73.5% |
| animated-navigation.medium/plain/steady | 2.67 ms | 2.72 ms | +78.1% |
| animated-navigation.medium/plain/teardown | 207.1 µs | 313.1 µs | +66.1% |
| branch-swap/compose | 3.55 ms | 6.29 ms | +53.0% |
| branch-swap/memory/mounted | 15 KiB | 15 KiB | -34.8% |
| branch-swap/memory/teardown | 0 KiB | 0 KiB | — |
| branch-swap/plain | 2.74 ms | 3.96 ms | +31.3% |
| cold-mount-100/compose | 885.4 µs | 1.17 ms | +70.3% |
| cold-mount-100/memory/mounted | 2219 KiB | 2219 KiB | -0.4% |
| cold-mount-100/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| cold-mount-100/plain | 862.5 µs | 1.06 ms | +102.0% |
| cold-mount-1000/compose | 8.55 ms | 12.27 ms | +58.6% |
| cold-mount-1000/memory/mounted | 21846 KiB | 21846 KiB | +0.1% |
| cold-mount-1000/memory/teardown | 8 KiB | 8 KiB | — |
| cold-mount-1000/plain | 6.42 ms | 7.10 ms | +25.2% |
| cold-mount-10000/compose | 94.24 ms | 96.85 ms | -4.1% |
| cold-mount-10000/memory/mounted | 218817 KiB | 218817 KiB | +0.0% |
| cold-mount-10000/memory/teardown | 0 KiB | 0 KiB | — |
| cold-mount-10000/plain | 67.12 ms | 78.62 ms | -5.8% |
| data-grid.extreme/compose/burst | 832.74 ms | 895.58 ms | +55.6% |
| data-grid.extreme/compose/cold | 515.84 ms | 577.94 ms | +57.0% |
| data-grid.extreme/compose/counts | 1510.85 ms | 1510.85 ms | +68.8% |
| data-grid.extreme/compose/settle | 2.2 µs | 2.3 µs | -10.3% |
| data-grid.extreme/compose/steady | 22.84 ms | 28.03 ms | +95.6% |
| data-grid.extreme/compose/teardown | 1.21 ms | 1.40 ms | +6.2% |
| data-grid.extreme/memory/mounted | 29237 KiB | 29237 KiB | +0.0% |
| data-grid.extreme/memory/teardown | 9 KiB | 9 KiB | +12.5% |
| data-grid.extreme/plain/burst | 780.02 ms | 831.11 ms | +66.8% |
| data-grid.extreme/plain/cold | 501.85 ms | 546.71 ms | +71.7% |
| data-grid.extreme/plain/settle | 2.4 µs | 3.1 µs | -9.3% |
| data-grid.extreme/plain/steady | 19.32 ms | 24.46 ms | +90.2% |
| data-grid.extreme/plain/teardown | 515.0 µs | 1.07 ms | +4.7% |
| data-grid.large/compose/burst | 137.05 ms | 147.38 ms | +0.8% |
| data-grid.large/compose/cold | 78.36 ms | 88.83 ms | -1.9% |
| data-grid.large/compose/counts | 247.43 ms | 247.43 ms | -4.7% |
| data-grid.large/compose/settle | 1.8 µs | 2.0 µs | -7.7% |
| data-grid.large/compose/steady | 15.30 ms | 18.88 ms | -3.4% |
| data-grid.large/compose/teardown | 530.1 µs | 849.0 µs | +4.5% |
| data-grid.large/memory/mounted | 6824 KiB | 6824 KiB | -0.1% |
| data-grid.large/memory/teardown | 0 KiB | 0 KiB | — |
| data-grid.large/plain/burst | 117.39 ms | 120.91 ms | +1.8% |
| data-grid.large/plain/cold | 73.87 ms | 76.32 ms | +1.4% |
| data-grid.large/plain/settle | 2.0 µs | 2.9 µs | +7.2% |
| data-grid.large/plain/steady | 10.92 ms | 16.41 ms | +10.4% |
| data-grid.large/plain/teardown | 189.6 µs | 234.0 µs | -15.6% |
| data-grid.medium/compose/burst | 63.12 ms | 66.91 ms | +56.8% |
| data-grid.medium/compose/cold | 35.97 ms | 42.00 ms | +58.3% |
| data-grid.medium/compose/counts | 128.71 ms | 128.71 ms | +51.4% |
| data-grid.medium/compose/settle | 1.8 µs | 2.1 µs | -24.4% |
| data-grid.medium/compose/steady | 12.81 ms | 17.69 ms | +46.8% |
| data-grid.medium/compose/teardown | 291.3 µs | 519.6 µs | +31.2% |
| data-grid.medium/memory/mounted | 3569 KiB | 3569 KiB | +0.2% |
| data-grid.medium/memory/teardown | 9 KiB | 9 KiB | +800.0% |
| data-grid.medium/plain/burst | 53.70 ms | 55.87 ms | +63.2% |
| data-grid.medium/plain/cold | 33.90 ms | 37.54 ms | +69.8% |
| data-grid.medium/plain/settle | 1.9 µs | 2.5 µs | -30.0% |
| data-grid.medium/plain/steady | 6.62 ms | 11.05 ms | +32.9% |
| data-grid.medium/plain/teardown | 106.8 µs | 228.5 µs | +55.5% |
| dense-dashboard.extreme/compose/burst | 14.24 ms | 20.32 ms | +3.1% |
| dense-dashboard.extreme/compose/cold | 495.3 µs | 862.9 µs | -1.6% |
| dense-dashboard.extreme/compose/counts | 22.77 ms | 22.77 ms | -10.1% |
| dense-dashboard.extreme/compose/settle | 1.0 µs | 1.4 µs | -6.6% |
| dense-dashboard.extreme/compose/steady | 896.4 µs | 937.2 µs | +5.0% |
| dense-dashboard.extreme/compose/teardown | 524.0 µs | 594.4 µs | -0.9% |
| dense-dashboard.extreme/memory/mounted | 1270 KiB | 1270 KiB | +0.0% |
| dense-dashboard.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| dense-dashboard.extreme/plain/burst | 6.66 ms | 8.14 ms | -1.9% |
| dense-dashboard.extreme/plain/cold | 234.2 µs | 442.1 µs | -0.7% |
| dense-dashboard.extreme/plain/settle | 0.8 µs | 1.4 µs | +2.5% |
| dense-dashboard.extreme/plain/steady | 141.4 µs | 150.5 µs | +7.8% |
| dense-dashboard.extreme/plain/teardown | 219.5 µs | 279.0 µs | +3.5% |
| dense-dashboard.large/compose/burst | 7.86 ms | 10.15 ms | +21.8% |
| dense-dashboard.large/compose/cold | 312.5 µs | 525.6 µs | +0.5% |
| dense-dashboard.large/compose/counts | 15.03 ms | 15.03 ms | -3.8% |
| dense-dashboard.large/compose/settle | 0.8 µs | 0.9 µs | +1.1% |
| dense-dashboard.large/compose/steady | 860.9 µs | 892.2 µs | +1.3% |
| dense-dashboard.large/compose/teardown | 250.0 µs | 511.6 µs | +3.1% |
| dense-dashboard.large/memory/mounted | 665 KiB | 665 KiB | -1.2% |
| dense-dashboard.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| dense-dashboard.large/plain/burst | 2.71 ms | 4.96 ms | +3.5% |
| dense-dashboard.large/plain/cold | 134.5 µs | 462.5 µs | +18.0% |
| dense-dashboard.large/plain/settle | 0.6 µs | 0.7 µs | -14.3% |
| dense-dashboard.large/plain/steady | 130.6 µs | 143.9 µs | -1.1% |
| dense-dashboard.large/plain/teardown | 96.8 µs | 175.1 µs | -4.9% |
| dense-dashboard.medium/compose/burst | 3.40 ms | 4.18 ms | +97.9% |
| dense-dashboard.medium/compose/cold | 199.3 µs | 529.4 µs | +59.4% |
| dense-dashboard.medium/compose/counts | 6.22 ms | 6.22 ms | +104.9% |
| dense-dashboard.medium/compose/settle | 0.7 µs | 0.8 µs | +69.1% |
| dense-dashboard.medium/compose/steady | 842.9 µs | 899.8 µs | +91.2% |
| dense-dashboard.medium/compose/teardown | 109.1 µs | 129.2 µs | +59.9% |
| dense-dashboard.medium/memory/mounted | 313 KiB | 313 KiB | -2.5% |
| dense-dashboard.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| dense-dashboard.medium/plain/burst | 1.25 ms | 2.44 ms | +105.3% |
| dense-dashboard.medium/plain/cold | 102.1 µs | 461.2 µs | +69.6% |
| dense-dashboard.medium/plain/settle | 0.7 µs | 1.0 µs | +81.4% |
| dense-dashboard.medium/plain/steady | 129.6 µs | 140.2 µs | +86.5% |
| dense-dashboard.medium/plain/teardown | 47.8 µs | 119.2 µs | +79.0% |
| entities-identity-churn-10.extreme/compose/burst | 46.64 ms | 60.31 ms | +5.0% |
| entities-identity-churn-10.extreme/compose/cold | 30.76 ms | 49.04 ms | +0.5% |
| entities-identity-churn-10.extreme/compose/counts | 207.64 ms | 207.64 ms | -8.3% |
| entities-identity-churn-10.extreme/compose/settle | 2.0 µs | 2.2 µs | -10.8% |
| entities-identity-churn-10.extreme/compose/steady | 52.06 ms | 55.58 ms | -11.7% |
| entities-identity-churn-10.extreme/compose/teardown | 1.12 ms | 1.26 ms | -5.3% |
| entities-identity-churn-10.extreme/memory/mounted | 4238 KiB | 4238 KiB | +0.2% |
| entities-identity-churn-10.extreme/memory/teardown | 8 KiB | 8 KiB | — |
| entities-identity-churn-10.extreme/plain/burst | 15.24 ms | 23.01 ms | -12.7% |
| entities-identity-churn-10.extreme/plain/cold | 7.56 ms | 14.52 ms | +1.1% |
| entities-identity-churn-10.extreme/plain/settle | 1.8 µs | 2.3 µs | -9.4% |
| entities-identity-churn-10.extreme/plain/steady | 30.37 ms | 39.55 ms | -2.3% |
| entities-identity-churn-10.extreme/plain/teardown | 366.5 µs | 527.2 µs | -0.2% |
| entities-identity-churn-10.large/compose/burst | 13.64 ms | 20.67 ms | +7.7% |
| entities-identity-churn-10.large/compose/cold | 12.73 ms | 16.49 ms | +42.9% |
| entities-identity-churn-10.large/compose/counts | 64.11 ms | 64.11 ms | +30.3% |
| entities-identity-churn-10.large/compose/settle | 1.6 µs | 2.0 µs | -28.5% |
| entities-identity-churn-10.large/compose/steady | 17.78 ms | 24.46 ms | +45.9% |
| entities-identity-churn-10.large/compose/teardown | 375.4 µs | 434.9 µs | +26.3% |
| entities-identity-churn-10.large/memory/mounted | 1669 KiB | 1669 KiB | -0.5% |
| entities-identity-churn-10.large/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn-10.large/plain/burst | 4.64 ms | 7.28 ms | +39.4% |
| entities-identity-churn-10.large/plain/cold | 3.70 ms | 6.99 ms | +71.9% |
| entities-identity-churn-10.large/plain/settle | 1.2 µs | 1.9 µs | -4.1% |
| entities-identity-churn-10.large/plain/steady | 11.26 ms | 13.95 ms | +79.2% |
| entities-identity-churn-10.large/plain/teardown | 119.6 µs | 147.4 µs | +32.7% |
| entities-identity-churn-10.medium/compose/burst | 7.59 ms | 11.20 ms | +41.0% |
| entities-identity-churn-10.medium/compose/cold | 5.37 ms | 8.10 ms | +45.6% |
| entities-identity-churn-10.medium/compose/counts | 33.20 ms | 33.20 ms | +52.5% |
| entities-identity-churn-10.medium/compose/settle | 1.1 µs | 2.3 µs | -20.3% |
| entities-identity-churn-10.medium/compose/steady | 8.30 ms | 10.14 ms | +72.9% |
| entities-identity-churn-10.medium/compose/teardown | 189.4 µs | 244.4 µs | +33.9% |
| entities-identity-churn-10.medium/memory/mounted | 869 KiB | 869 KiB | +0.0% |
| entities-identity-churn-10.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn-10.medium/plain/burst | 2.78 ms | 5.11 ms | +86.1% |
| entities-identity-churn-10.medium/plain/cold | 1.62 ms | 4.31 ms | +65.4% |
| entities-identity-churn-10.medium/plain/settle | 0.8 µs | 1.5 µs | +11.1% |
| entities-identity-churn-10.medium/plain/steady | 5.58 ms | 5.85 ms | +100.9% |
| entities-identity-churn-10.medium/plain/teardown | 57.7 µs | 147.0 µs | +30.9% |
| entities-identity-churn-50.extreme/compose/burst | 41.08 ms | 70.44 ms | -2.4% |
| entities-identity-churn-50.extreme/compose/cold | 29.63 ms | 48.07 ms | +11.8% |
| entities-identity-churn-50.extreme/compose/counts | 287.12 ms | 287.12 ms | +8.5% |
| entities-identity-churn-50.extreme/compose/settle | 1.9 µs | 3.4 µs | -21.1% |
| entities-identity-churn-50.extreme/compose/steady | 151.39 ms | 174.08 ms | +9.0% |
| entities-identity-churn-50.extreme/compose/teardown | 1.15 ms | 1.45 ms | +10.2% |
| entities-identity-churn-50.extreme/memory/mounted | 4163 KiB | 4163 KiB | -0.2% |
| entities-identity-churn-50.extreme/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| entities-identity-churn-50.extreme/plain/burst | 16.75 ms | 29.56 ms | +17.9% |
| entities-identity-churn-50.extreme/plain/cold | 7.77 ms | 16.14 ms | -14.8% |
| entities-identity-churn-50.extreme/plain/settle | 2.5 µs | 2.8 µs | +2.1% |
| entities-identity-churn-50.extreme/plain/steady | 63.51 ms | 87.48 ms | +24.8% |
| entities-identity-churn-50.extreme/plain/teardown | 409.8 µs | 999.5 µs | +45.8% |
| entities-identity-churn-50.large/compose/burst | 14.24 ms | 23.56 ms | -11.0% |
| entities-identity-churn-50.large/compose/cold | 10.39 ms | 19.88 ms | -15.6% |
| entities-identity-churn-50.large/compose/counts | 108.51 ms | 108.51 ms | -8.5% |
| entities-identity-churn-50.large/compose/settle | 1.6 µs | 1.9 µs | -29.3% |
| entities-identity-churn-50.large/compose/steady | 50.91 ms | 69.71 ms | -10.1% |
| entities-identity-churn-50.large/compose/teardown | 398.2 µs | 488.1 µs | -11.3% |
| entities-identity-churn-50.large/memory/mounted | 1718 KiB | 1718 KiB | -0.9% |
| entities-identity-churn-50.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-identity-churn-50.large/plain/burst | 5.48 ms | 12.88 ms | -8.7% |
| entities-identity-churn-50.large/plain/cold | 2.94 ms | 5.38 ms | -37.6% |
| entities-identity-churn-50.large/plain/settle | 1.6 µs | 1.9 µs | -10.9% |
| entities-identity-churn-50.large/plain/steady | 22.08 ms | 27.14 ms | +2.3% |
| entities-identity-churn-50.large/plain/teardown | 137.0 µs | 161.3 µs | +5.2% |
| entities-identity-churn-50.medium/compose/burst | 7.81 ms | 12.66 ms | -10.6% |
| entities-identity-churn-50.medium/compose/cold | 6.48 ms | 8.50 ms | +27.3% |
| entities-identity-churn-50.medium/compose/counts | 62.12 ms | 62.12 ms | -6.1% |
| entities-identity-churn-50.medium/compose/settle | 1.6 µs | 2.8 µs | +0.0% |
| entities-identity-churn-50.medium/compose/steady | 23.58 ms | 31.14 ms | -5.9% |
| entities-identity-churn-50.medium/compose/teardown | 242.6 µs | 289.1 µs | -3.8% |
| entities-identity-churn-50.medium/memory/mounted | 961 KiB | 961 KiB | +0.0% |
| entities-identity-churn-50.medium/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| entities-identity-churn-50.medium/plain/burst | 2.75 ms | 5.79 ms | -5.2% |
| entities-identity-churn-50.medium/plain/cold | 1.93 ms | 5.54 ms | +3.6% |
| entities-identity-churn-50.medium/plain/settle | 1.1 µs | 1.6 µs | +17.5% |
| entities-identity-churn-50.medium/plain/steady | 10.93 ms | 12.72 ms | +7.8% |
| entities-identity-churn-50.medium/plain/teardown | 67.2 µs | 154.9 µs | -10.9% |
| entities-identity-churn.extreme/compose/burst | 45.18 ms | 60.58 ms | +5.7% |
| entities-identity-churn.extreme/compose/cold | 29.63 ms | 53.68 ms | +1.4% |
| entities-identity-churn.extreme/compose/counts | 239.56 ms | 239.56 ms | +3.5% |
| entities-identity-churn.extreme/compose/settle | 2.1 µs | 2.6 µs | +5.6% |
| entities-identity-churn.extreme/compose/steady | 87.90 ms | 116.79 ms | -11.0% |
| entities-identity-churn.extreme/compose/teardown | 1.25 ms | 1.55 ms | +7.8% |
| entities-identity-churn.extreme/memory/mounted | 4525 KiB | 4525 KiB | -1.9% |
| entities-identity-churn.extreme/memory/teardown | 1 KiB | 1 KiB | -99.0% |
| entities-identity-churn.extreme/plain/burst | 17.58 ms | 30.15 ms | +0.1% |
| entities-identity-churn.extreme/plain/cold | 10.71 ms | 17.36 ms | +0.8% |
| entities-identity-churn.extreme/plain/settle | 2.1 µs | 2.6 µs | -2.4% |
| entities-identity-churn.extreme/plain/steady | 43.54 ms | 58.40 ms | -7.5% |
| entities-identity-churn.extreme/plain/teardown | 454.0 µs | 590.8 µs | -0.4% |
| entities-identity-churn.large/compose/burst | 12.53 ms | 15.76 ms | +47.6% |
| entities-identity-churn.large/compose/cold | 11.41 ms | 19.05 ms | +35.6% |
| entities-identity-churn.large/compose/counts | 93.02 ms | 93.02 ms | +42.9% |
| entities-identity-churn.large/compose/settle | 1.7 µs | 3.8 µs | +4.4% |
| entities-identity-churn.large/compose/steady | 28.78 ms | 39.69 ms | +54.9% |
| entities-identity-churn.large/compose/teardown | 350.0 µs | 434.1 µs | +43.2% |
| entities-identity-churn.large/memory/mounted | 1636 KiB | 1636 KiB | -0.5% |
| entities-identity-churn.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-identity-churn.large/plain/burst | 4.67 ms | 8.08 ms | +54.6% |
| entities-identity-churn.large/plain/cold | 3.90 ms | 6.91 ms | +122.9% |
| entities-identity-churn.large/plain/settle | 1.0 µs | 1.4 µs | -10.0% |
| entities-identity-churn.large/plain/steady | 15.01 ms | 18.31 ms | +63.4% |
| entities-identity-churn.large/plain/teardown | 113.1 µs | 178.8 µs | +49.6% |
| entities-identity-churn.medium/compose/burst | 7.51 ms | 13.10 ms | +48.9% |
| entities-identity-churn.medium/compose/cold | 4.92 ms | 7.00 ms | +33.7% |
| entities-identity-churn.medium/compose/counts | 38.26 ms | 38.26 ms | +45.7% |
| entities-identity-churn.medium/compose/settle | 1.0 µs | 2.0 µs | -40.0% |
| entities-identity-churn.medium/compose/steady | 14.15 ms | 22.15 ms | +45.1% |
| entities-identity-churn.medium/compose/teardown | 209.3 µs | 270.9 µs | +32.2% |
| entities-identity-churn.medium/memory/mounted | 924 KiB | 924 KiB | +0.0% |
| entities-identity-churn.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn.medium/plain/burst | 2.57 ms | 6.32 ms | +35.2% |
| entities-identity-churn.medium/plain/cold | 1.37 ms | 3.23 ms | +14.6% |
| entities-identity-churn.medium/plain/settle | 0.8 µs | 1.1 µs | -25.6% |
| entities-identity-churn.medium/plain/steady | 7.10 ms | 9.23 ms | +47.5% |
| entities-identity-churn.medium/plain/teardown | 63.6 µs | 130.6 µs | +27.8% |
| entities-integrated.extreme/compose/burst | 18.21 ms | 22.06 ms | +8.0% |
| entities-integrated.extreme/compose/cold | 110.79 ms | 148.54 ms | +10.5% |
| entities-integrated.extreme/compose/counts | 382.57 ms | 382.57 ms | +17.9% |
| entities-integrated.extreme/compose/settle | 2.1 µs | 2.5 µs | +10.0% |
| entities-integrated.extreme/compose/steady | 95.95 ms | 117.53 ms | +17.9% |
| entities-integrated.extreme/compose/teardown | 55.49 ms | 62.99 ms | +22.0% |
| entities-integrated.extreme/memory/mounted | 40034 KiB | 40034 KiB | -0.0% |
| entities-integrated.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-integrated.extreme/plain/burst | 6.05 ms | 9.31 ms | +9.3% |
| entities-integrated.extreme/plain/cold | 34.69 ms | 66.41 ms | +42.0% |
| entities-integrated.extreme/plain/settle | 2.0 µs | 3.0 µs | +48.8% |
| entities-integrated.extreme/plain/steady | 26.26 ms | 39.58 ms | +14.4% |
| entities-integrated.extreme/plain/teardown | 26.87 ms | 35.54 ms | +19.0% |
| entities-integrated.large/compose/burst | 9.58 ms | 10.85 ms | +3.4% |
| entities-integrated.large/compose/cold | 38.45 ms | 54.68 ms | -5.5% |
| entities-integrated.large/compose/counts | 136.42 ms | 136.42 ms | -0.1% |
| entities-integrated.large/compose/settle | 1.6 µs | 2.3 µs | +8.6% |
| entities-integrated.large/compose/steady | 50.36 ms | 68.38 ms | +5.6% |
| entities-integrated.large/compose/teardown | 14.20 ms | 19.02 ms | +2.1% |
| entities-integrated.large/memory/mounted | 16532 KiB | 16532 KiB | +0.0% |
| entities-integrated.large/memory/teardown | 9 KiB | 9 KiB | +12.5% |
| entities-integrated.large/plain/burst | 3.02 ms | 5.37 ms | +4.2% |
| entities-integrated.large/plain/cold | 12.30 ms | 19.06 ms | -1.4% |
| entities-integrated.large/plain/settle | 1.3 µs | 1.8 µs | +29.3% |
| entities-integrated.large/plain/steady | 13.73 ms | 17.30 ms | +7.1% |
| entities-integrated.large/plain/teardown | 5.55 ms | 7.99 ms | +8.7% |
| entities-integrated.medium/compose/burst | 6.94 ms | 10.75 ms | +70.8% |
| entities-integrated.medium/compose/cold | 19.00 ms | 29.61 ms | +46.3% |
| entities-integrated.medium/compose/counts | 91.26 ms | 91.26 ms | +60.7% |
| entities-integrated.medium/compose/settle | 1.6 µs | 3.8 µs | -4.2% |
| entities-integrated.medium/compose/steady | 34.31 ms | 47.52 ms | +76.1% |
| entities-integrated.medium/compose/teardown | 6.37 ms | 7.23 ms | +24.0% |
| entities-integrated.medium/memory/mounted | 8961 KiB | 8961 KiB | +0.1% |
| entities-integrated.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entities-integrated.medium/plain/burst | 2.30 ms | 5.71 ms | +36.9% |
| entities-integrated.medium/plain/cold | 5.85 ms | 12.10 ms | +34.6% |
| entities-integrated.medium/plain/settle | 1.0 µs | 1.7 µs | -2.8% |
| entities-integrated.medium/plain/steady | 9.60 ms | 14.91 ms | +61.7% |
| entities-integrated.medium/plain/teardown | 2.32 ms | 3.19 ms | +30.6% |
| entities-relevance-saturated.extreme/compose/burst | 81.77 ms | 105.49 ms | +20.6% |
| entities-relevance-saturated.extreme/compose/cold | 27.24 ms | 41.54 ms | +40.5% |
| entities-relevance-saturated.extreme/compose/counts | 218.07 ms | 218.07 ms | +28.2% |
| entities-relevance-saturated.extreme/compose/settle | 2.1 µs | 2.3 µs | -26.8% |
| entities-relevance-saturated.extreme/compose/steady | 50.69 ms | 83.42 ms | -20.0% |
| entities-relevance-saturated.extreme/compose/teardown | 13.40 ms | 16.61 ms | +1.1% |
| entities-relevance-saturated.extreme/memory/mounted | 12030 KiB | 12030 KiB | +0.2% |
| entities-relevance-saturated.extreme/memory/teardown | 1 KiB | 1 KiB | — |
| entities-relevance-saturated.extreme/plain/burst | 19.09 ms | 27.62 ms | +29.0% |
| entities-relevance-saturated.extreme/plain/cold | 9.42 ms | 19.97 ms | +45.7% |
| entities-relevance-saturated.extreme/plain/settle | 2.3 µs | 2.7 µs | -4.1% |
| entities-relevance-saturated.extreme/plain/steady | 94.83 ms | 108.01 ms | +66.0% |
| entities-relevance-saturated.extreme/plain/teardown | 3.52 ms | 5.05 ms | -10.0% |
| entities-relevance-saturated.large/compose/burst | 26.91 ms | 35.39 ms | +25.7% |
| entities-relevance-saturated.large/compose/cold | 11.11 ms | 13.81 ms | +27.8% |
| entities-relevance-saturated.large/compose/counts | 78.20 ms | 78.20 ms | +30.2% |
| entities-relevance-saturated.large/compose/settle | 1.7 µs | 2.1 µs | -28.8% |
| entities-relevance-saturated.large/compose/steady | 17.61 ms | 27.10 ms | +36.0% |
| entities-relevance-saturated.large/compose/teardown | 2.97 ms | 3.53 ms | +0.0% |
| entities-relevance-saturated.large/memory/mounted | 4816 KiB | 4816 KiB | +0.0% |
| entities-relevance-saturated.large/memory/teardown | 0 KiB | 0 KiB | — |
| entities-relevance-saturated.large/plain/burst | 6.30 ms | 8.47 ms | +18.1% |
| entities-relevance-saturated.large/plain/cold | 5.13 ms | 9.79 ms | +80.4% |
| entities-relevance-saturated.large/plain/settle | 1.7 µs | 1.9 µs | -23.7% |
| entities-relevance-saturated.large/plain/steady | 35.37 ms | 46.60 ms | +68.7% |
| entities-relevance-saturated.large/plain/teardown | 1.20 ms | 1.48 ms | -19.1% |
| entities-relevance-saturated.medium/compose/burst | 10.54 ms | 17.22 ms | -20.5% |
| entities-relevance-saturated.medium/compose/cold | 4.93 ms | 10.76 ms | -17.9% |
| entities-relevance-saturated.medium/compose/counts | 35.05 ms | 35.05 ms | -12.4% |
| entities-relevance-saturated.medium/compose/settle | 1.0 µs | 1.2 µs | -34.0% |
| entities-relevance-saturated.medium/compose/steady | 7.80 ms | 14.09 ms | -24.0% |
| entities-relevance-saturated.medium/compose/teardown | 1.01 ms | 1.04 ms | -26.2% |
| entities-relevance-saturated.medium/memory/mounted | 2419 KiB | 2419 KiB | +0.3% |
| entities-relevance-saturated.medium/memory/teardown | 9 KiB | 9 KiB | +800.0% |
| entities-relevance-saturated.medium/plain/burst | 2.73 ms | 5.56 ms | -23.1% |
| entities-relevance-saturated.medium/plain/cold | 2.38 ms | 4.55 ms | -14.8% |
| entities-relevance-saturated.medium/plain/settle | 0.8 µs | 2.9 µs | -58.0% |
| entities-relevance-saturated.medium/plain/steady | 16.69 ms | 19.80 ms | -10.9% |
| entities-relevance-saturated.medium/plain/teardown | 417.1 µs | 624.5 µs | -36.5% |
| entities-relevance-sweep.extreme/compose/burst | 139.16 ms | 177.03 ms | +5.5% |
| entities-relevance-sweep.extreme/compose/cold | 35.11 ms | 59.54 ms | +6.7% |
| entities-relevance-sweep.extreme/compose/counts | 375.33 ms | 375.33 ms | -4.4% |
| entities-relevance-sweep.extreme/compose/settle | 2.5 µs | 3.0 µs | -2.8% |
| entities-relevance-sweep.extreme/compose/steady | 118.56 ms | 148.97 ms | -8.4% |
| entities-relevance-sweep.extreme/compose/teardown | 14.54 ms | 16.57 ms | +1.1% |
| entities-relevance-sweep.extreme/memory/mounted | 12050 KiB | 12050 KiB | +0.1% |
| entities-relevance-sweep.extreme/memory/teardown | 8 KiB | 8 KiB | +0.0% |
| entities-relevance-sweep.extreme/plain/burst | 40.79 ms | 51.85 ms | +47.3% |
| entities-relevance-sweep.extreme/plain/cold | 9.49 ms | 35.25 ms | +0.1% |
| entities-relevance-sweep.extreme/plain/settle | 2.2 µs | 3.4 µs | -12.9% |
| entities-relevance-sweep.extreme/plain/steady | 28.09 ms | 42.96 ms | -2.3% |
| entities-relevance-sweep.extreme/plain/teardown | 3.77 ms | 6.55 ms | -1.5% |
| entities-relevance-sweep.large/compose/burst | 41.76 ms | 52.25 ms | +14.0% |
| entities-relevance-sweep.large/compose/cold | 10.73 ms | 23.39 ms | +44.7% |
| entities-relevance-sweep.large/compose/counts | 132.02 ms | 132.02 ms | +25.0% |
| entities-relevance-sweep.large/compose/settle | 1.7 µs | 2.3 µs | -29.4% |
| entities-relevance-sweep.large/compose/steady | 42.90 ms | 54.53 ms | +44.7% |
| entities-relevance-sweep.large/compose/teardown | 3.20 ms | 4.44 ms | +1.0% |
| entities-relevance-sweep.large/memory/mounted | 4833 KiB | 4833 KiB | +0.3% |
| entities-relevance-sweep.large/memory/teardown | 1 KiB | 1 KiB | — |
| entities-relevance-sweep.large/plain/burst | 11.24 ms | 20.77 ms | +25.4% |
| entities-relevance-sweep.large/plain/cold | 3.76 ms | 7.03 ms | -7.2% |
| entities-relevance-sweep.large/plain/settle | 1.6 µs | 2.0 µs | -34.7% |
| entities-relevance-sweep.large/plain/steady | 10.13 ms | 17.62 ms | +32.1% |
| entities-relevance-sweep.large/plain/teardown | 1.22 ms | 1.37 ms | -20.3% |
| entities-relevance-sweep.medium/compose/burst | 19.63 ms | 23.87 ms | +11.5% |
| entities-relevance-sweep.medium/compose/cold | 6.62 ms | 15.46 ms | +35.7% |
| entities-relevance-sweep.medium/compose/counts | 72.73 ms | 72.73 ms | +14.7% |
| entities-relevance-sweep.medium/compose/settle | 1.3 µs | 2.0 µs | +32.6% |
| entities-relevance-sweep.medium/compose/steady | 19.67 ms | 26.60 ms | +9.0% |
| entities-relevance-sweep.medium/compose/teardown | 1.25 ms | 1.47 ms | +25.3% |
| entities-relevance-sweep.medium/memory/mounted | 2420 KiB | 2420 KiB | +0.0% |
| entities-relevance-sweep.medium/memory/teardown | 8 KiB | 8 KiB | — |
| entities-relevance-sweep.medium/plain/burst | 4.99 ms | 7.85 ms | -9.2% |
| entities-relevance-sweep.medium/plain/cold | 1.94 ms | 5.91 ms | +20.9% |
| entities-relevance-sweep.medium/plain/settle | 1.0 µs | 1.6 µs | +17.2% |
| entities-relevance-sweep.medium/plain/steady | 5.32 ms | 11.69 ms | +19.3% |
| entities-relevance-sweep.medium/plain/teardown | 608.6 µs | 746.3 µs | +112.7% |
| entity-labels-sparse.extreme/compose/burst | 27.08 ms | 39.02 ms | -8.7% |
| entity-labels-sparse.extreme/compose/cold | 25.09 ms | 31.35 ms | +4.8% |
| entity-labels-sparse.extreme/compose/counts | 93.20 ms | 93.20 ms | -2.8% |
| entity-labels-sparse.extreme/compose/settle | 1.6 µs | 1.9 µs | -15.2% |
| entity-labels-sparse.extreme/compose/steady | 3.79 ms | 4.23 ms | -3.9% |
| entity-labels-sparse.extreme/compose/teardown | 12.21 ms | 12.93 ms | -0.5% |
| entity-labels-sparse.extreme/memory/mounted | 12219 KiB | 12219 KiB | +0.0% |
| entity-labels-sparse.extreme/memory/teardown | 9 KiB | 9 KiB | +800.0% |
| entity-labels-sparse.extreme/plain/burst | 8.99 ms | 12.69 ms | -14.9% |
| entity-labels-sparse.extreme/plain/cold | 10.41 ms | 16.36 ms | +32.0% |
| entity-labels-sparse.extreme/plain/settle | 1.4 µs | 2.0 µs | +14.3% |
| entity-labels-sparse.extreme/plain/steady | 906.6 µs | 1.09 ms | -5.2% |
| entity-labels-sparse.extreme/plain/teardown | 6.06 ms | 6.69 ms | -0.2% |
| entity-labels-sparse.large/compose/burst | 12.19 ms | 16.41 ms | -0.8% |
| entity-labels-sparse.large/compose/cold | 12.15 ms | 17.27 ms | -0.7% |
| entity-labels-sparse.large/compose/counts | 49.55 ms | 49.55 ms | +19.2% |
| entity-labels-sparse.large/compose/settle | 1.2 µs | 1.8 µs | -1.6% |
| entity-labels-sparse.large/compose/steady | 1.87 ms | 2.38 ms | -2.9% |
| entity-labels-sparse.large/compose/teardown | 3.93 ms | 4.36 ms | -2.9% |
| entity-labels-sparse.large/memory/mounted | 6357 KiB | 6357 KiB | +0.1% |
| entity-labels-sparse.large/memory/teardown | 1 KiB | 1 KiB | -87.5% |
| entity-labels-sparse.large/plain/burst | 5.17 ms | 6.65 ms | +26.9% |
| entity-labels-sparse.large/plain/cold | 3.62 ms | 7.83 ms | -21.1% |
| entity-labels-sparse.large/plain/settle | 1.0 µs | 1.5 µs | +12.6% |
| entity-labels-sparse.large/plain/steady | 463.0 µs | 520.0 µs | +1.2% |
| entity-labels-sparse.large/plain/teardown | 1.97 ms | 2.51 ms | +8.9% |
| entity-labels-sparse.medium/compose/burst | 4.64 ms | 6.41 ms | -5.0% |
| entity-labels-sparse.medium/compose/cold | 4.33 ms | 6.38 ms | -18.9% |
| entity-labels-sparse.medium/compose/counts | 21.39 ms | 21.39 ms | +6.9% |
| entity-labels-sparse.medium/compose/settle | 0.9 µs | 1.3 µs | +12.5% |
| entity-labels-sparse.medium/compose/steady | 884.8 µs | 1.03 ms | +2.4% |
| entity-labels-sparse.medium/compose/teardown | 1.31 ms | 1.43 ms | +4.8% |
| entity-labels-sparse.medium/memory/mounted | 2824 KiB | 2824 KiB | +0.3% |
| entity-labels-sparse.medium/memory/teardown | 1 KiB | 1 KiB | — |
| entity-labels-sparse.medium/plain/burst | 1.37 ms | 2.25 ms | -0.4% |
| entity-labels-sparse.medium/plain/cold | 1.88 ms | 2.48 ms | -10.3% |
| entity-labels-sparse.medium/plain/settle | 0.8 µs | 1.1 µs | +23.8% |
| entity-labels-sparse.medium/plain/steady | 197.7 µs | 210.7 µs | -2.7% |
| entity-labels-sparse.medium/plain/teardown | 525.9 µs | 754.4 µs | +10.6% |
| entity-labels.extreme/compose/burst | 30.27 ms | 35.06 ms | +10.9% |
| entity-labels.extreme/compose/cold | 24.79 ms | 33.75 ms | -3.6% |
| entity-labels.extreme/compose/counts | 130.23 ms | 130.23 ms | +9.9% |
| entity-labels.extreme/compose/settle | 1.5 µs | 2.2 µs | +29.3% |
| entity-labels.extreme/compose/steady | 31.37 ms | 37.15 ms | +0.8% |
| entity-labels.extreme/compose/teardown | 12.08 ms | 14.15 ms | -18.9% |
| entity-labels.extreme/memory/mounted | 12696 KiB | 12696 KiB | +0.0% |
| entity-labels.extreme/memory/teardown | 1 KiB | 1 KiB | — |
| entity-labels.extreme/plain/burst | 9.75 ms | 11.77 ms | +30.7% |
| entity-labels.extreme/plain/cold | 10.93 ms | 15.80 ms | +32.1% |
| entity-labels.extreme/plain/settle | 0.9 µs | 1.4 µs | +3.3% |
| entity-labels.extreme/plain/steady | 919.2 µs | 1.10 ms | +8.1% |
| entity-labels.extreme/plain/teardown | 5.55 ms | 6.25 ms | +5.2% |
| entity-labels.large/compose/burst | 14.80 ms | 17.77 ms | +8.2% |
| entity-labels.large/compose/cold | 12.24 ms | 17.84 ms | +0.6% |
| entity-labels.large/compose/counts | 63.96 ms | 63.96 ms | -5.1% |
| entity-labels.large/compose/settle | 1.8 µs | 2.6 µs | +16.5% |
| entity-labels.large/compose/steady | 15.59 ms | 20.82 ms | -0.3% |
| entity-labels.large/compose/teardown | 4.41 ms | 5.05 ms | -1.5% |
| entity-labels.large/memory/mounted | 6610 KiB | 6610 KiB | +0.1% |
| entity-labels.large/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| entity-labels.large/plain/burst | 3.89 ms | 5.25 ms | -12.2% |
| entity-labels.large/plain/cold | 4.65 ms | 7.35 ms | -6.3% |
| entity-labels.large/plain/settle | 0.8 µs | 1.7 µs | -22.5% |
| entity-labels.large/plain/steady | 451.2 µs | 549.1 µs | -3.2% |
| entity-labels.large/plain/teardown | 1.88 ms | 2.02 ms | -2.1% |
| entity-labels.medium/compose/burst | 5.18 ms | 8.77 ms | +3.3% |
| entity-labels.medium/compose/cold | 5.21 ms | 9.52 ms | +25.7% |
| entity-labels.medium/compose/counts | 25.73 ms | 25.73 ms | +9.7% |
| entity-labels.medium/compose/settle | 1.1 µs | 2.6 µs | +32.8% |
| entity-labels.medium/compose/steady | 6.42 ms | 6.91 ms | +0.5% |
| entity-labels.medium/compose/teardown | 1.33 ms | 1.65 ms | +4.4% |
| entity-labels.medium/memory/mounted | 2943 KiB | 2943 KiB | +0.0% |
| entity-labels.medium/memory/teardown | 9 KiB | 9 KiB | +800.0% |
| entity-labels.medium/plain/burst | 1.51 ms | 2.82 ms | +11.0% |
| entity-labels.medium/plain/cold | 1.75 ms | 5.06 ms | +6.2% |
| entity-labels.medium/plain/settle | 0.7 µs | 0.8 µs | +4.8% |
| entity-labels.medium/plain/steady | 211.2 µs | 238.9 µs | +3.1% |
| entity-labels.medium/plain/teardown | 488.8 µs | 627.9 µs | -5.8% |
| events/compose | 11.02 ms | 14.80 ms | +20.8% |
| events/memory/mounted | 1 KiB | 1 KiB | +0.0% |
| events/memory/teardown | 0 KiB | 0 KiB | — |
| events/plain | 10.41 ms | 11.84 ms | +16.1% |
| inspector.extreme/compose/burst | 8.04 ms | 9.31 ms | +45.0% |
| inspector.extreme/compose/cold | 20.41 ms | 24.30 ms | +28.5% |
| inspector.extreme/compose/counts | 37.82 ms | 37.82 ms | +61.0% |
| inspector.extreme/compose/settle | 1.2 µs | 1.6 µs | -10.9% |
| inspector.extreme/compose/steady | 236.8 µs | 325.6 µs | +14.0% |
| inspector.extreme/compose/teardown | 2.31 ms | 2.85 ms | +7.4% |
| inspector.extreme/memory/mounted | 17367 KiB | 17367 KiB | +0.0% |
| inspector.extreme/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| inspector.extreme/plain/burst | 1.79 ms | 2.03 ms | +54.7% |
| inspector.extreme/plain/cold | 7.32 ms | 11.14 ms | +17.9% |
| inspector.extreme/plain/settle | 0.9 µs | 1.6 µs | +9.7% |
| inspector.extreme/plain/steady | 75.3 µs | 82.2 µs | +45.5% |
| inspector.extreme/plain/teardown | 5.39 ms | 5.76 ms | +24.3% |
| inspector.large/compose/burst | 4.07 ms | 5.56 ms | -4.0% |
| inspector.large/compose/cold | 6.47 ms | 12.26 ms | -32.9% |
| inspector.large/compose/counts | 18.86 ms | 18.86 ms | +3.3% |
| inspector.large/compose/settle | 0.8 µs | 1.2 µs | -36.3% |
| inspector.large/compose/steady | 227.5 µs | 284.0 µs | -10.8% |
| inspector.large/compose/teardown | 1.05 ms | 1.98 ms | -18.2% |
| inspector.large/memory/mounted | 6196 KiB | 6196 KiB | +0.1% |
| inspector.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| inspector.large/plain/burst | 840.4 µs | 924.8 µs | -0.8% |
| inspector.large/plain/cold | 3.32 ms | 5.62 ms | +13.1% |
| inspector.large/plain/settle | 0.7 µs | 0.7 µs | -27.5% |
| inspector.large/plain/steady | 63.1 µs | 72.5 µs | -10.2% |
| inspector.large/plain/teardown | 1.56 ms | 1.74 ms | -7.1% |
| inspector.medium/compose/burst | 1.42 ms | 1.69 ms | -2.8% |
| inspector.medium/compose/cold | 1.73 ms | 3.69 ms | -18.3% |
| inspector.medium/compose/counts | 4.79 ms | 4.79 ms | -12.4% |
| inspector.medium/compose/settle | 0.6 µs | 1.0 µs | -4.7% |
| inspector.medium/compose/steady | 210.4 µs | 251.0 µs | +1.5% |
| inspector.medium/compose/teardown | 377.6 µs | 502.0 µs | -3.4% |
| inspector.medium/memory/mounted | 1784 KiB | 1784 KiB | -0.4% |
| inspector.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| inspector.medium/plain/burst | 247.6 µs | 276.5 µs | -9.0% |
| inspector.medium/plain/cold | 1.21 ms | 2.61 ms | +26.3% |
| inspector.medium/plain/settle | 0.4 µs | 0.6 µs | -15.5% |
| inspector.medium/plain/steady | 58.5 µs | 74.0 µs | -2.8% |
| inspector.medium/plain/teardown | 360.9 µs | 495.2 µs | +9.4% |
| keyed-append/compose | 1.12 ms | 1.58 ms | +0.2% |
| keyed-append/memory/mounted | 2261 KiB | 2261 KiB | +0.0% |
| keyed-append/memory/teardown | 8 KiB | 8 KiB | — |
| keyed-append/plain | 1.45 ms | 1.75 ms | +8.5% |
| keyed-insert/compose | 2.99 ms | 3.11 ms | +115.0% |
| keyed-insert/memory/mounted | 2257 KiB | 2257 KiB | -0.4% |
| keyed-insert/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-insert/plain | 1.70 ms | 2.08 ms | +115.9% |
| keyed-prepend/compose | 4.39 ms | 4.86 ms | +88.8% |
| keyed-prepend/memory/mounted | 2269 KiB | 2269 KiB | +0.4% |
| keyed-prepend/memory/teardown | 8 KiB | 8 KiB | +0.0% |
| keyed-prepend/plain | 1.77 ms | 2.07 ms | +74.8% |
| keyed-remove/compose | 2.73 ms | 2.97 ms | +7.1% |
| keyed-remove/memory/mounted | 2260 KiB | 2260 KiB | +0.0% |
| keyed-remove/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-remove/plain | 1.44 ms | 1.65 ms | -2.3% |
| keyed-replace/compose | 51.44 ms | 53.84 ms | -1.2% |
| keyed-replace/memory/mounted | 2288 KiB | 2288 KiB | +0.0% |
| keyed-replace/memory/teardown | 8 KiB | 8 KiB | +0.0% |
| keyed-replace/plain | 29.15 ms | 32.74 ms | +0.4% |
| keyed-reverse/compose | 2.90 ms | 3.07 ms | +118.5% |
| keyed-reverse/memory/mounted | 2272 KiB | 2272 KiB | +0.7% |
| keyed-reverse/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-reverse/plain | 1.20 ms | 1.38 ms | +87.7% |
| keyed-rotate/compose | 3.00 ms | 3.10 ms | +2.9% |
| keyed-rotate/memory/mounted | 2265 KiB | 2265 KiB | +0.0% |
| keyed-rotate/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| keyed-rotate/plain | 1.21 ms | 1.32 ms | -1.5% |
| keyed-shuffle/compose | 3.01 ms | 3.09 ms | -3.9% |
| keyed-shuffle/memory/mounted | 2256 KiB | 2256 KiB | -0.4% |
| keyed-shuffle/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-shuffle/plain | 1.26 ms | 1.35 ms | -8.2% |
| mount-cycles/compose | 23.40 ms | 32.56 ms | +1.5% |
| mount-cycles/memory/mounted | 1 KiB | 1 KiB | -99.8% |
| mount-cycles/memory/teardown | 1 KiB | 1 KiB | -99.8% |
| mount-cycles/plain | 20.10 ms | 21.37 ms | +24.9% |
| mount-dispose/compose | 7.44 ms | 11.61 ms | -22.3% |
| mount-dispose/memory/mounted | 1 KiB | 1 KiB | — |
| mount-dispose/memory/teardown | 0 KiB | 0 KiB | — |
| mount-dispose/plain | 7.65 ms | 8.03 ms | -11.5% |
| ordered-window-scroll/compose | 504.6 µs | 512.6 µs | +1.3% |
| ordered-window-scroll/memory/mounted | 1129 KiB | 1129 KiB | +0.0% |
| ordered-window-scroll/memory/teardown | 8 KiB | 8 KiB | +0.0% |
| projection-keyed-append-500/compose | 10.11 ms | 12.13 ms | -28.1% |
| projection-keyed-append-500/memory/mounted | 3192 KiB | 3192 KiB | +0.0% |
| projection-keyed-append-500/memory/teardown | 0 KiB | 0 KiB | — |
| projection-keyed-append-500/plain | 2.43 ms | 3.80 ms | +9.9% |
| projection-observe-100/compose | 1.38 ms | 1.91 ms | -18.5% |
| projection-observe-100/memory/mounted | 74 KiB | 74 KiB | +0.0% |
| projection-observe-100/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| projection-selection-500/compose | 1.31 ms | 1.35 ms | +3.8% |
| projection-selection-500/memory/mounted | 4076 KiB | 4076 KiB | +0.2% |
| projection-selection-500/memory/teardown | 0 KiB | 0 KiB | — |
| projection-selection-500/plain | 199.7 µs | 219.1 µs | +11.8% |
| scene-2d.extreme/compose/burst | 30.09 ms | 44.18 ms | +13.8% |
| scene-2d.extreme/compose/cold | 11.84 ms | 23.03 ms | +19.9% |
| scene-2d.extreme/compose/counts | 209.50 ms | 209.50 ms | +12.5% |
| scene-2d.extreme/compose/settle | 1.5 µs | 2.3 µs | +27.6% |
| scene-2d.extreme/compose/steady | 84.93 ms | 98.41 ms | +0.6% |
| scene-2d.extreme/compose/teardown | 1.18 ms | 2.32 ms | +19.0% |
| scene-2d.extreme/memory/mounted | 9664 KiB | 9664 KiB | -0.1% |
| scene-2d.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| scene-2d.extreme/plain/burst | 9.13 ms | 26.48 ms | +1.2% |
| scene-2d.extreme/plain/cold | 1.71 ms | 3.14 ms | +15.2% |
| scene-2d.extreme/plain/settle | 1.0 µs | 1.7 µs | +6.6% |
| scene-2d.extreme/plain/steady | 48.15 ms | 55.57 ms | +0.7% |
| scene-2d.extreme/plain/teardown | 544.3 µs | 657.7 µs | +15.3% |
| scene-2d.large/compose/burst | 25.74 ms | 34.35 ms | -16.8% |
| scene-2d.large/compose/cold | 6.52 ms | 11.61 ms | +4.9% |
| scene-2d.large/compose/counts | 180.38 ms | 180.38 ms | -4.7% |
| scene-2d.large/compose/settle | 1.8 µs | 2.0 µs | -6.8% |
| scene-2d.large/compose/steady | 88.66 ms | 96.63 ms | -3.9% |
| scene-2d.large/compose/teardown | 1.12 ms | 1.94 ms | -25.2% |
| scene-2d.large/memory/mounted | 4047 KiB | 4047 KiB | +0.0% |
| scene-2d.large/memory/teardown | 8 KiB | 8 KiB | — |
| scene-2d.large/plain/burst | 9.55 ms | 12.92 ms | -3.9% |
| scene-2d.large/plain/cold | 1.53 ms | 3.80 ms | -9.0% |
| scene-2d.large/plain/settle | 1.5 µs | 2.1 µs | -26.6% |
| scene-2d.large/plain/steady | 48.11 ms | 52.81 ms | -3.1% |
| scene-2d.large/plain/teardown | 522.9 µs | 719.4 µs | -21.0% |
| scene-2d.medium/compose/burst | 24.65 ms | 28.35 ms | +59.8% |
| scene-2d.medium/compose/cold | 3.80 ms | 5.92 ms | -11.5% |
| scene-2d.medium/compose/counts | 148.68 ms | 148.68 ms | +8.6% |
| scene-2d.medium/compose/settle | 1.4 µs | 1.9 µs | +63.1% |
| scene-2d.medium/compose/steady | 65.42 ms | 68.22 ms | -0.5% |
| scene-2d.medium/compose/teardown | 1.02 ms | 1.26 ms | +38.4% |
| scene-2d.medium/memory/mounted | 2266 KiB | 2266 KiB | -0.4% |
| scene-2d.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| scene-2d.medium/plain/burst | 6.27 ms | 12.87 ms | +19.2% |
| scene-2d.medium/plain/cold | 2.09 ms | 3.15 ms | +47.3% |
| scene-2d.medium/plain/settle | 1.3 µs | 2.1 µs | +68.2% |
| scene-2d.medium/plain/steady | 38.39 ms | 41.16 ms | +4.8% |
| scene-2d.medium/plain/teardown | 481.4 µs | 791.5 µs | +36.3% |
| scene-3d/compose | 9.01 ms | 9.50 ms | +17.8% |
| scene-3d/memory/mounted | 1278 KiB | 1278 KiB | -0.6% |
| scene-3d/memory/teardown | 0 KiB | 0 KiB | — |
| scene-3d/plain | 3.74 ms | 4.89 ms | +6.3% |
| session-cycle.extreme/compose/burst | 133.36 ms | 211.00 ms | -8.1% |
| session-cycle.extreme/compose/cold | 4.6 µs | 7.3 µs | +10.6% |
| session-cycle.extreme/compose/counts | 361.58 ms | 361.58 ms | +9.1% |
| session-cycle.extreme/compose/settle | 2.4 µs | 3.3 µs | +13.0% |
| session-cycle.extreme/compose/steady | 208.68 ms | 284.78 ms | +22.7% |
| session-cycle.extreme/compose/teardown | 2.4 µs | 3.6 µs | +27.8% |
| session-cycle.extreme/memory/mounted | 10 KiB | 10 KiB | +0.0% |
| session-cycle.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| session-cycle.extreme/plain/burst | 141.67 ms | 186.73 ms | -9.2% |
| session-cycle.extreme/plain/cold | 4.8 µs | 8.2 µs | +16.3% |
| session-cycle.extreme/plain/settle | 2.7 µs | 3.7 µs | +16.8% |
| session-cycle.extreme/plain/steady | 231.28 ms | 288.59 ms | +30.0% |
| session-cycle.extreme/plain/teardown | 2.6 µs | 3.6 µs | +23.8% |
| session-cycle.large/compose/burst | 47.86 ms | 69.27 ms | +14.8% |
| session-cycle.large/compose/cold | 4.0 µs | 6.8 µs | +19.9% |
| session-cycle.large/compose/counts | 125.33 ms | 125.33 ms | -1.5% |
| session-cycle.large/compose/settle | 2.0 µs | 2.6 µs | +7.5% |
| session-cycle.large/compose/steady | 71.04 ms | 102.41 ms | +5.1% |
| session-cycle.large/compose/teardown | 2.1 µs | 2.8 µs | +17.8% |
| session-cycle.large/memory/mounted | 2 KiB | 2 KiB | +0.0% |
| session-cycle.large/memory/teardown | 0 KiB | 0 KiB | — |
| session-cycle.large/plain/burst | 38.48 ms | 65.37 ms | -24.1% |
| session-cycle.large/plain/cold | 4.8 µs | 6.8 µs | +21.8% |
| session-cycle.large/plain/settle | 2.2 µs | 2.6 µs | +38.0% |
| session-cycle.large/plain/steady | 76.87 ms | 95.13 ms | +38.5% |
| session-cycle.large/plain/teardown | 2.0 µs | 2.8 µs | +30.7% |
| session-cycle.medium/compose/burst | 14.88 ms | 23.24 ms | -7.7% |
| session-cycle.medium/compose/cold | 3.3 µs | 5.3 µs | -29.2% |
| session-cycle.medium/compose/counts | 39.84 ms | 39.84 ms | -10.9% |
| session-cycle.medium/compose/settle | 1.5 µs | 3.1 µs | -1.3% |
| session-cycle.medium/compose/steady | 19.38 ms | 27.83 ms | -13.6% |
| session-cycle.medium/compose/teardown | 1.6 µs | 2.9 µs | -6.5% |
| session-cycle.medium/memory/mounted | 0 KiB | 0 KiB | — |
| session-cycle.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| session-cycle.medium/plain/burst | 11.40 ms | 19.59 ms | +9.4% |
| session-cycle.medium/plain/cold | 3.2 µs | 17.5 µs | -25.9% |
| session-cycle.medium/plain/settle | 1.1 µs | 1.4 µs | -25.0% |
| session-cycle.medium/plain/steady | 20.20 ms | 26.31 ms | -5.1% |
| session-cycle.medium/plain/teardown | 1.3 µs | 1.6 µs | -21.1% |
| spatial-scene.extreme/compose/burst | 135.92 ms | 150.63 ms | +11.0% |
| spatial-scene.extreme/compose/cold | 11.34 ms | 18.35 ms | +5.5% |
| spatial-scene.extreme/compose/counts | 266.53 ms | 266.53 ms | +4.3% |
| spatial-scene.extreme/compose/settle | 2.0 µs | 2.4 µs | +16.2% |
| spatial-scene.extreme/compose/steady | 53.84 ms | 61.42 ms | +1.2% |
| spatial-scene.extreme/compose/teardown | 4.16 ms | 5.21 ms | +28.9% |
| spatial-scene.extreme/memory/mounted | 5284 KiB | 5284 KiB | +0.0% |
| spatial-scene.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| spatial-scene.extreme/plain/burst | 52.15 ms | 58.42 ms | +4.6% |
| spatial-scene.extreme/plain/cold | 3.49 ms | 7.26 ms | +4.4% |
| spatial-scene.extreme/plain/settle | 2.3 µs | 2.9 µs | +37.9% |
| spatial-scene.extreme/plain/steady | 75.03 ms | 93.78 ms | -2.9% |
| spatial-scene.extreme/plain/teardown | 1.26 ms | 3.03 ms | +3.6% |
| spatial-scene.large/compose/burst | 37.84 ms | 44.07 ms | +2.5% |
| spatial-scene.large/compose/cold | 3.41 ms | 5.65 ms | -26.8% |
| spatial-scene.large/compose/counts | 77.28 ms | 77.28 ms | +4.4% |
| spatial-scene.large/compose/settle | 1.6 µs | 2.4 µs | -16.8% |
| spatial-scene.large/compose/steady | 19.17 ms | 20.86 ms | -1.4% |
| spatial-scene.large/compose/teardown | 813.6 µs | 1.01 ms | -5.7% |
| spatial-scene.large/memory/mounted | 1758 KiB | 1758 KiB | +0.5% |
| spatial-scene.large/memory/teardown | 0 KiB | 0 KiB | — |
| spatial-scene.large/plain/burst | 13.99 ms | 20.38 ms | -21.3% |
| spatial-scene.large/plain/cold | 1.11 ms | 2.54 ms | -12.8% |
| spatial-scene.large/plain/settle | 1.6 µs | 3.2 µs | -23.3% |
| spatial-scene.large/plain/steady | 22.20 ms | 26.90 ms | -6.1% |
| spatial-scene.large/plain/teardown | 355.8 µs | 745.5 µs | -5.4% |
| spatial-scene.medium/compose/burst | 13.24 ms | 16.45 ms | +77.3% |
| spatial-scene.medium/compose/cold | 1.26 ms | 2.15 ms | +84.2% |
| spatial-scene.medium/compose/counts | 35.50 ms | 35.50 ms | +120.5% |
| spatial-scene.medium/compose/settle | 1.0 µs | 1.5 µs | +41.2% |
| spatial-scene.medium/compose/steady | 9.31 ms | 11.02 ms | +110.4% |
| spatial-scene.medium/compose/teardown | 287.7 µs | 333.8 µs | +97.5% |
| spatial-scene.medium/memory/mounted | 690 KiB | 690 KiB | +0.0% |
| spatial-scene.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| spatial-scene.medium/plain/burst | 4.60 ms | 5.86 ms | +25.4% |
| spatial-scene.medium/plain/cold | 430.1 µs | 684.2 µs | +45.2% |
| spatial-scene.medium/plain/settle | 0.9 µs | 1.9 µs | +23.3% |
| spatial-scene.medium/plain/steady | 8.14 ms | 9.38 ms | +73.4% |
| spatial-scene.medium/plain/teardown | 102.4 µs | 118.4 µs | +53.7% |
| status-panel/compose | 567.0 µs | 621.0 µs | +3.7% |
| status-panel/memory/mounted | 43 KiB | 43 KiB | +22.9% |
| status-panel/memory/teardown | 0 KiB | 0 KiB | — |
| status-panel/plain | 102.1 µs | 335.1 µs | -16.9% |
| unwind/compose | 3.56 ms | 6.83 ms | -8.7% |
| unwind/memory/mounted | 1 KiB | 1 KiB | +0.0% |
| unwind/memory/teardown | 8 KiB | 8 KiB | — |
| unwind/plain | 3.63 ms | 4.40 ms | +22.2% |
| update-batched/compose | 2.92 ms | 3.24 ms | -0.4% |
| update-batched/memory/mounted | 1876 KiB | 1876 KiB | +0.4% |
| update-batched/memory/teardown | 0 KiB | 0 KiB | — |
| update-batched/plain | 1.02 ms | 1.08 ms | -2.0% |
| update-fanout/compose | 1.42 ms | 1.45 ms | -12.6% |
| update-fanout/memory/mounted | 1812 KiB | 1812 KiB | +0.0% |
| update-fanout/memory/teardown | 0 KiB | 0 KiB | — |
| update-fanout/plain | 874.0 µs | 882.2 µs | -18.2% |
| update-leaf/compose | 40.6 µs | 53.1 µs | +74.5% |
| update-leaf/memory/mounted | 2755 KiB | 2755 KiB | +0.6% |
| update-leaf/memory/teardown | 0 KiB | 0 KiB | — |
| update-leaf/plain | 16.6 µs | 18.1 µs | +61.3% |
| update-repeated/compose | 351.9 µs | 389.7 µs | +22.1% |
| update-repeated/memory/mounted | 18 KiB | 18 KiB | +0.0% |
| update-repeated/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| update-repeated/plain | 43.7 µs | 45.5 µs | +14.5% |
| virtual-filtered-list.extreme/compose/burst | 780.27 ms | 790.25 ms | -8.8% |
| virtual-filtered-list.extreme/compose/cold | 485.56 ms | 498.54 ms | -1.9% |
| virtual-filtered-list.extreme/compose/counts | 1273.98 ms | 1273.98 ms | -15.8% |
| virtual-filtered-list.extreme/compose/settle | 2.6 µs | 3.2 µs | +12.3% |
| virtual-filtered-list.extreme/compose/steady | 14.14 ms | 16.11 ms | -10.6% |
| virtual-filtered-list.extreme/compose/teardown | 522.8 µs | 575.3 µs | +2.4% |
| virtual-filtered-list.extreme/memory/mounted | 27918 KiB | 27918 KiB | +0.0% |
| virtual-filtered-list.extreme/memory/teardown | 8 KiB | 8 KiB | — |
| virtual-filtered-list.extreme/plain/burst | 725.59 ms | 737.05 ms | -16.0% |
| virtual-filtered-list.extreme/plain/cold | 466.26 ms | 471.35 ms | -16.0% |
| virtual-filtered-list.extreme/plain/settle | 2.7 µs | 3.8 µs | -5.2% |
| virtual-filtered-list.extreme/plain/steady | 10.27 ms | 14.77 ms | -8.6% |
| virtual-filtered-list.extreme/plain/teardown | 196.0 µs | 260.3 µs | -9.7% |
| virtual-filtered-list.large/compose/burst | 125.69 ms | 140.75 ms | +47.0% |
| virtual-filtered-list.large/compose/cold | 78.27 ms | 81.94 ms | +56.1% |
| virtual-filtered-list.large/compose/counts | 237.75 ms | 237.75 ms | +55.9% |
| virtual-filtered-list.large/compose/settle | 2.0 µs | 2.6 µs | -22.8% |
| virtual-filtered-list.large/compose/steady | 14.14 ms | 19.29 ms | +42.6% |
| virtual-filtered-list.large/compose/teardown | 290.6 µs | 528.7 µs | +20.7% |
| virtual-filtered-list.large/memory/mounted | 6305 KiB | 6305 KiB | +0.0% |
| virtual-filtered-list.large/memory/teardown | 9 KiB | 9 KiB | +0.0% |
| virtual-filtered-list.large/plain/burst | 115.19 ms | 119.27 ms | +55.6% |
| virtual-filtered-list.large/plain/cold | 74.32 ms | 84.59 ms | +59.2% |
| virtual-filtered-list.large/plain/settle | 2.1 µs | 3.0 µs | -28.2% |
| virtual-filtered-list.large/plain/steady | 6.84 ms | 10.60 ms | +21.2% |
| virtual-filtered-list.large/plain/teardown | 117.0 µs | 137.0 µs | +51.0% |
| virtual-filtered-list.medium/compose/burst | 24.63 ms | 27.45 ms | -3.5% |
| virtual-filtered-list.medium/compose/cold | 12.70 ms | 15.11 ms | -5.8% |
| virtual-filtered-list.medium/compose/counts | 59.53 ms | 59.53 ms | -2.7% |
| virtual-filtered-list.medium/compose/settle | 1.3 µs | 1.8 µs | -22.6% |
| virtual-filtered-list.medium/compose/steady | 11.74 ms | 21.97 ms | -4.8% |
| virtual-filtered-list.medium/compose/teardown | 194.4 µs | 268.6 µs | -2.7% |
| virtual-filtered-list.medium/memory/mounted | 1610 KiB | 1610 KiB | +0.1% |
| virtual-filtered-list.medium/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| virtual-filtered-list.medium/plain/burst | 18.60 ms | 20.31 ms | -7.3% |
| virtual-filtered-list.medium/plain/cold | 11.59 ms | 13.25 ms | -1.7% |
| virtual-filtered-list.medium/plain/settle | 1.0 µs | 1.6 µs | -39.0% |
| virtual-filtered-list.medium/plain/steady | 6.25 ms | 7.61 ms | +18.0% |
| virtual-filtered-list.medium/plain/teardown | 67.9 µs | 94.7 µs | +7.2% |

## Trends over the last 3 main commits

```mermaid
xychart-beta
    title "animate-many/compose (median µs)"
    x-axis 1 --> 3
    line [3066.4, 6952.0, 6809.4]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [6516.1, 4147.1, 7924.7]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [11407.1, 8355.0, 11077.8]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [68091.2, 47605.1, 84532.8]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.0, 1.0, 1.1]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [25890.3, 17137.2, 33073.2]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [2475.2, 1994.0, 2796.3]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [3896.2, 3809.1, 3862.2]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [5692.2, 5515.9, 5845.7]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [57607.9, 56296.6, 57762.9]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.2, 0.8, 0.8]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [26697.4, 26221.7, 26378.1]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [1432.5, 1092.3, 1223.6]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [598.2, 606.3, 1380.7]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [1178.6, 1128.0, 1758.0]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [10635.9, 10387.5, 24309.0]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [0.3, 0.4, 0.7]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [4717.9, 4534.1, 10683.3]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [212.7, 211.0, 408.9]
```

```mermaid
xychart-beta
    title "branch-swap/compose (median µs)"
    x-axis 1 --> 3
    line [3609.5, 2319.6, 3549.8]
```

```mermaid
xychart-beta
    title "cold-mount-100/compose (median µs)"
    x-axis 1 --> 3
    line [592.6, 519.9, 885.4]
```

```mermaid
xychart-beta
    title "cold-mount-1000/compose (median µs)"
    x-axis 1 --> 3
    line [8085.8, 5389.9, 8549.6]
```

```mermaid
xychart-beta
    title "cold-mount-10000/compose (median µs)"
    x-axis 1 --> 3
    line [73945.7, 98256.1, 94238.7]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [572777.3, 535083.2, 832744.6]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [350893.5, 328646.9, 515839.7]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [961903.0, 895177.9, 1510853.2]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.8, 2.4, 2.2]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [12594.0, 11681.8, 22844.9]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [1086.6, 1137.9, 1208.9]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [140083.3, 135962.2, 137048.1]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [80791.9, 79866.7, 78358.1]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [269572.2, 259528.8, 247425.1]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.0, 2.0, 1.8]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [17382.0, 15842.8, 15303.1]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [517.4, 507.1, 530.1]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [49689.5, 40264.0, 63124.3]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [28216.2, 22726.8, 35966.3]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [101676.4, 85010.8, 128707.0]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.2, 2.3, 1.8]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [12139.2, 8725.2, 12812.2]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [242.3, 222.0, 291.3]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [8748.3, 13808.9, 14242.7]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [306.9, 503.4, 495.3]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [12107.6, 25337.6, 22769.2]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [0.6, 1.1, 1.0]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [461.4, 853.9, 896.4]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [300.0, 528.8, 524.0]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [7315.2, 6455.4, 7861.5]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [321.9, 311.0, 312.5]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [15457.3, 15616.4, 15030.0]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [0.9, 0.8, 0.8]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [871.8, 849.7, 860.9]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [255.7, 242.4, 250.0]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [1884.9, 1716.2, 3396.7]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [150.8, 125.0, 199.3]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [4488.4, 3035.8, 6218.8]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [0.6, 0.4, 0.7]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [451.5, 440.8, 842.9]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [71.1, 68.2, 109.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [36450.3, 44418.2, 46637.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [22317.0, 30608.9, 30755.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [157183.8, 226408.0, 207640.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.5, 2.2, 2.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [38679.7, 58936.7, 52064.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [870.1, 1178.4, 1115.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [13822.3, 12671.8, 13643.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [8768.9, 8903.6, 12727.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [56991.3, 49197.8, 64112.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.0, 2.2, 1.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [16083.5, 12191.6, 17784.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [346.1, 297.1, 375.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [4810.6, 5385.1, 7593.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [3510.0, 3688.3, 5372.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [22176.2, 21779.2, 33203.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [0.9, 1.3, 1.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [5091.1, 4800.2, 8300.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [138.2, 141.4, 189.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [37375.3, 42100.8, 41076.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [28909.8, 26506.8, 29632.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [312089.2, 264728.7, 287119.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.6, 2.4, 1.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [144362.2, 138910.8, 151388.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [1011.3, 1046.8, 1153.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [11392.1, 16006.5, 14237.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [10645.8, 12312.2, 10388.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [86389.6, 118638.8, 108507.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.5, 2.3, 1.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [40309.4, 56606.6, 50910.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [312.8, 448.9, 398.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [8485.7, 8733.8, 7811.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [5123.1, 5090.8, 6479.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [60621.5, 66177.5, 62123.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.3, 1.6, 1.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [22448.9, 25049.9, 23583.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [239.6, 252.1, 242.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [51119.4, 42743.7, 45181.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [31173.0, 29216.5, 29632.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [276895.4, 231546.3, 239558.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.3, 2.0, 2.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [103496.4, 98719.9, 87903.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [1459.8, 1163.1, 1253.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [9662.4, 8486.1, 12526.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [7331.9, 8413.6, 11406.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [62489.1, 65083.5, 93016.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.6, 1.6, 1.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [17762.3, 18587.4, 28783.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [221.0, 244.4, 350.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [5597.4, 5043.1, 7507.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [4098.3, 3677.5, 4917.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [31911.5, 26270.5, 38265.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.0, 1.7, 1.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [10781.6, 9751.3, 14145.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [163.7, 158.3, 209.3]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [18098.0, 16855.7, 18205.9]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [102015.1, 100238.6, 110792.2]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [358907.4, 324615.1, 382570.8]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.8, 1.9, 2.1]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [90630.1, 81412.5, 95946.8]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [52871.1, 45496.4, 55490.6]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [9879.6, 9266.1, 9580.3]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [42924.1, 40697.9, 38453.5]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [159260.0, 136585.0, 136418.7]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.1, 1.5, 1.6]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [56879.3, 47700.5, 50360.1]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [16802.1, 13908.2, 14198.2]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [4273.0, 4064.7, 6941.6]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [14214.0, 12986.0, 18998.1]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [60159.0, 56773.8, 91261.8]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.9, 1.7, 1.6]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [20781.1, 19484.3, 34314.8]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [5912.5, 5137.9, 6370.7]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [82088.2, 67803.4, 81772.9]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [23851.0, 19385.3, 27237.7]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [215972.6, 170155.4, 218067.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.5, 2.9, 2.1]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [46499.2, 63403.0, 50693.5]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [13254.3, 13259.6, 13403.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [23829.2, 21410.5, 26910.9]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [9046.6, 8698.0, 11112.7]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [66263.4, 60081.6, 78201.5]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.2, 2.3, 1.7]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [15970.8, 12947.8, 17610.3]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [3313.5, 2966.7, 2967.8]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [10053.5, 13258.0, 10542.4]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [4425.1, 5999.0, 4925.5]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [26589.7, 40004.4, 35054.4]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.0, 1.5, 1.0]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [6593.9, 10265.5, 7799.1]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [909.1, 1375.7, 1014.9]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [83025.5, 131890.1, 139155.5]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [27112.7, 32898.9, 35114.3]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [297306.3, 392730.6, 375325.7]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.9, 2.5, 2.5]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [104435.7, 129482.8, 118556.7]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [11409.1, 14374.0, 14539.1]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [37687.9, 36619.3, 41760.4]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [9427.2, 7416.6, 10731.1]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [118464.0, 105642.9, 132017.4]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.0, 2.4, 1.7]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [36383.7, 29649.6, 42899.0]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [3319.5, 3173.8, 3204.1]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [21304.8, 17609.9, 19632.8]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [5522.9, 4875.0, 6616.8]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [73432.0, 63426.8, 72731.7]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.9, 1.0, 1.3]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [21627.0, 18049.0, 19673.0]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [1421.5, 998.7, 1251.6]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [28431.3, 29661.9, 27082.8]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [25491.4, 23933.9, 25087.3]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [103374.1, 95880.0, 93198.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.8, 1.9, 1.6]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [4152.6, 3939.8, 3787.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [12752.1, 12268.9, 12210.0]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [12559.3, 12285.7, 12193.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [10065.7, 12236.3, 12145.6]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [47228.6, 41552.7, 49545.9]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.2, 1.3, 1.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [1880.4, 1925.6, 1869.1]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [3848.1, 4042.8, 3927.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [2692.8, 4883.0, 4638.9]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [3511.6, 5344.2, 4334.1]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [11899.6, 20010.0, 21389.0]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [0.8, 0.8, 0.9]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [546.9, 864.1, 884.8]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [793.8, 1245.8, 1305.4]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [38306.7, 27292.5, 30271.6]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [26392.1, 25728.0, 24789.0]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [146562.2, 118482.8, 130233.0]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.1, 1.2, 1.5]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [35077.9, 31134.3, 31374.2]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [14166.4, 14892.9, 12081.1]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [16371.6, 13675.4, 14796.5]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [13125.5, 12164.0, 12241.7]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [71347.2, 67401.3, 63961.0]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.8, 1.6, 1.8]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [17130.8, 15636.5, 15592.5]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [4985.7, 4474.5, 4408.6]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [5454.2, 5016.4, 5182.8]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [6039.1, 4145.2, 5211.5]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [27680.1, 23447.7, 25731.3]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.2, 0.8, 1.1]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [6474.9, 6388.6, 6421.2]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [1477.1, 1273.6, 1329.9]
```

```mermaid
xychart-beta
    title "events/compose (median µs)"
    x-axis 1 --> 3
    line [10464.1, 9121.0, 11019.8]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [7448.2, 5545.2, 8042.0]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [18874.4, 15878.8, 20409.9]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [34335.8, 23488.3, 37816.7]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.6, 1.4, 1.2]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [245.7, 207.7, 236.8]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [2590.5, 2153.7, 2312.0]
```

```mermaid
xychart-beta
    title "inspector.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [3270.5, 4234.2, 4065.4]
```

```mermaid
xychart-beta
    title "inspector.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [6003.2, 9644.5, 6469.4]
```

```mermaid
xychart-beta
    title "inspector.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [15848.8, 18252.6, 18863.7]
```

```mermaid
xychart-beta
    title "inspector.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [0.8, 1.2, 0.8]
```

```mermaid
xychart-beta
    title "inspector.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [184.9, 255.0, 227.5]
```

```mermaid
xychart-beta
    title "inspector.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [939.1, 1289.4, 1054.6]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [652.7, 1463.0, 1421.7]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [1084.4, 2117.8, 1731.0]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [2345.3, 5474.4, 4793.9]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [0.4, 0.6, 0.6]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [101.1, 207.3, 210.4]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [183.0, 391.0, 377.6]
```

```mermaid
xychart-beta
    title "keyed-append/compose (median µs)"
    x-axis 1 --> 3
    line [1217.7, 1121.3, 1123.5]
```

```mermaid
xychart-beta
    title "keyed-insert/compose (median µs)"
    x-axis 1 --> 3
    line [1418.3, 1388.8, 2985.6]
```

```mermaid
xychart-beta
    title "keyed-prepend/compose (median µs)"
    x-axis 1 --> 3
    line [3339.2, 2323.0, 4385.8]
```

```mermaid
xychart-beta
    title "keyed-remove/compose (median µs)"
    x-axis 1 --> 3
    line [1834.7, 2550.5, 2731.1]
```

```mermaid
xychart-beta
    title "keyed-replace/compose (median µs)"
    x-axis 1 --> 3
    line [56638.2, 52082.4, 51437.5]
```

```mermaid
xychart-beta
    title "keyed-reverse/compose (median µs)"
    x-axis 1 --> 3
    line [1366.2, 1329.2, 2904.2]
```

```mermaid
xychart-beta
    title "keyed-rotate/compose (median µs)"
    x-axis 1 --> 3
    line [2837.0, 2918.3, 3001.8]
```

```mermaid
xychart-beta
    title "keyed-shuffle/compose (median µs)"
    x-axis 1 --> 3
    line [1337.6, 3134.0, 3010.8]
```

```mermaid
xychart-beta
    title "mount-cycles/compose (median µs)"
    x-axis 1 --> 3
    line [24941.5, 23043.1, 23398.1]
```

```mermaid
xychart-beta
    title "mount-dispose/compose (median µs)"
    x-axis 1 --> 3
    line [7076.9, 9579.0, 7445.0]
```

```mermaid
xychart-beta
    title "ordered-window-scroll/compose (median µs)"
    x-axis 1 --> 3
    line [412.1, 498.2, 504.6]
```

```mermaid
xychart-beta
    title "projection-keyed-append-500/compose (median µs)"
    x-axis 1 --> 3
    line [5754.2, 14069.9, 10109.7]
```

```mermaid
xychart-beta
    title "projection-observe-100/compose (median µs)"
    x-axis 1 --> 3
    line [1160.9, 1688.5, 1375.7]
```

```mermaid
xychart-beta
    title "projection-selection-500/compose (median µs)"
    x-axis 1 --> 3
    line [1347.5, 1257.8, 1305.3]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [31592.1, 26430.2, 30086.2]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [11079.4, 9876.1, 11841.3]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [216069.1, 186166.0, 209496.7]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.2, 1.2, 1.5]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [90044.4, 84419.8, 84931.4]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [1242.8, 991.8, 1179.9]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [23109.8, 30942.5, 25739.8]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [4352.7, 6212.1, 6516.0]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [150813.2, 189240.1, 180380.0]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.3, 1.9, 1.8]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [67819.6, 92259.3, 88664.7]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [835.3, 1495.8, 1118.6]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [20349.9, 15428.8, 24654.7]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [4709.8, 4295.8, 3803.5]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [147623.1, 136904.9, 148677.3]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.2, 0.8, 1.4]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [69181.6, 65753.4, 65422.7]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [1053.9, 734.4, 1016.7]
```

```mermaid
xychart-beta
    title "scene-3d/compose (median µs)"
    x-axis 1 --> 3
    line [10050.2, 7649.9, 9011.1]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [111388.5, 145081.3, 133361.3]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [4.4, 4.2, 4.6]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [347844.7, 331552.2, 361578.0]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.2, 2.2, 2.4]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [189371.2, 170051.3, 208681.3]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [2.3, 1.9, 2.4]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [55471.8, 41682.9, 47858.1]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [4.1, 3.4, 4.0]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [152922.2, 127280.8, 125332.5]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.9, 1.9, 2.0]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [70217.2, 67586.5, 71040.2]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [1.9, 1.7, 2.1]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [9419.6, 16119.8, 14877.2]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [2.9, 4.7, 3.3]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [32366.0, 44739.0, 39841.4]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.2, 1.5, 1.5]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [16834.7, 22422.0, 19376.8]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [1.2, 1.7, 1.6]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [131626.4, 122408.9, 135923.1]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [11274.4, 10752.6, 11344.1]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [280294.2, 255499.9, 266526.7]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.7, 1.7, 2.0]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [54938.1, 53195.1, 53842.8]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [4193.8, 3229.5, 4161.6]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [24854.0, 36908.9, 37836.4]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [3382.2, 4654.1, 3405.2]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [50109.8, 74015.2, 77275.2]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.2, 1.9, 1.6]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [12804.6, 19446.0, 19168.6]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [635.6, 862.7, 813.6]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [7485.6, 7465.0, 13238.7]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [732.5, 682.2, 1256.5]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [16776.7, 16094.7, 35495.1]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [0.9, 0.7, 1.0]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [4566.2, 4426.4, 9311.4]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [160.7, 145.7, 287.7]
```

```mermaid
xychart-beta
    title "status-panel/compose (median µs)"
    x-axis 1 --> 3
    line [594.8, 546.6, 567.0]
```

```mermaid
xychart-beta
    title "unwind/compose (median µs)"
    x-axis 1 --> 3
    line [4404.4, 3896.7, 3558.7]
```

```mermaid
xychart-beta
    title "update-batched/compose (median µs)"
    x-axis 1 --> 3
    line [3025.0, 2927.0, 2916.4]
```

```mermaid
xychart-beta
    title "update-fanout/compose (median µs)"
    x-axis 1 --> 3
    line [777.2, 1629.0, 1423.8]
```

```mermaid
xychart-beta
    title "update-leaf/compose (median µs)"
    x-axis 1 --> 3
    line [33.7, 23.3, 40.6]
```

```mermaid
xychart-beta
    title "update-repeated/compose (median µs)"
    x-axis 1 --> 3
    line [291.8, 288.2, 351.9]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/burst (median µs)"
    x-axis 1 --> 3
    line [468218.5, 855118.6, 780270.5]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/cold (median µs)"
    x-axis 1 --> 3
    line [303705.7, 494927.2, 485557.0]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/counts (median µs)"
    x-axis 1 --> 3
    line [758775.9, 1513830.2, 1273975.2]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.5, 2.4, 2.6]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/steady (median µs)"
    x-axis 1 --> 3
    line [8156.9, 15826.4, 14142.7]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [337.4, 510.6, 522.8]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/burst (median µs)"
    x-axis 1 --> 3
    line [103439.2, 85508.3, 125691.5]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/cold (median µs)"
    x-axis 1 --> 3
    line [59355.8, 50136.7, 78271.4]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/counts (median µs)"
    x-axis 1 --> 3
    line [189934.0, 152506.8, 237753.9]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/settle (median µs)"
    x-axis 1 --> 3
    line [2.3, 2.6, 2.0]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/steady (median µs)"
    x-axis 1 --> 3
    line [12089.3, 9916.3, 14136.9]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [262.7, 240.8, 290.6]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/burst (median µs)"
    x-axis 1 --> 3
    line [17844.8, 25511.5, 24629.5]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/cold (median µs)"
    x-axis 1 --> 3
    line [9422.5, 13481.1, 12703.5]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/counts (median µs)"
    x-axis 1 --> 3
    line [44077.6, 61203.3, 59533.4]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/settle (median µs)"
    x-axis 1 --> 3
    line [1.0, 1.7, 1.3]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/steady (median µs)"
    x-axis 1 --> 3
    line [9077.3, 12332.6, 11738.6]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/teardown (median µs)"
    x-axis 1 --> 3
    line [139.6, 199.8, 194.4]
```
