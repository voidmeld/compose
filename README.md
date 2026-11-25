# Compose performance

Latest: `8defb0582d9ba136ba21736fef9a4ec36c537118` on 2026-11-25T045329Z, measured on the CI Ubuntu runner by the paired performance shards.
Each value is the median of the candidate arm's samples; p95 is shown beside it. Change compares the previous main commit.

| Benchmark | Median | p95 | Change |
| --- | --- | --- | --- |
| animate-many/compose | 5.54 ms | 5.68 ms | -21.5% |
| animate-many/memory/mounted | 2246 KiB | 2246 KiB | +0.4% |
| animate-many/memory/teardown | 8 KiB | 8 KiB | — |
| animate-many/plain | 1.29 ms | 1.29 ms | -21.6% |
| animated-navigation.extreme/compose/burst | 4.47 ms | 5.46 ms | -43.9% |
| animated-navigation.extreme/compose/cold | 9.22 ms | 13.23 ms | -9.3% |
| animated-navigation.extreme/compose/counts | 50.58 ms | 50.58 ms | -38.9% |
| animated-navigation.extreme/compose/settle | 1.4 µs | 1.7 µs | +36.9% |
| animated-navigation.extreme/compose/steady | 18.63 ms | 18.95 ms | -46.8% |
| animated-navigation.extreme/compose/teardown | 2.45 ms | 2.86 ms | +0.6% |
| animated-navigation.extreme/memory/mounted | 7109 KiB | 7109 KiB | +0.0% |
| animated-navigation.extreme/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| animated-navigation.extreme/plain/burst | 747.3 µs | 835.5 µs | -46.7% |
| animated-navigation.extreme/plain/cold | 3.91 ms | 8.34 ms | -12.1% |
| animated-navigation.extreme/plain/settle | 0.9 µs | 1.3 µs | +48.3% |
| animated-navigation.extreme/plain/steady | 9.61 ms | 9.84 ms | -49.1% |
| animated-navigation.extreme/plain/teardown | 3.03 ms | 3.88 ms | -9.1% |
| animated-navigation.large/compose/burst | 3.22 ms | 3.35 ms | -18.9% |
| animated-navigation.large/compose/cold | 4.83 ms | 9.71 ms | -8.8% |
| animated-navigation.large/compose/counts | 49.52 ms | 49.52 ms | -26.4% |
| animated-navigation.large/compose/settle | 1.5 µs | 2.1 µs | +18.5% |
| animated-navigation.large/compose/steady | 21.86 ms | 22.19 ms | -21.3% |
| animated-navigation.large/compose/teardown | 1.37 ms | 1.56 ms | +3.6% |
| animated-navigation.large/memory/mounted | 3554 KiB | 3554 KiB | +0.0% |
| animated-navigation.large/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| animated-navigation.large/plain/burst | 506.9 µs | 609.0 µs | -28.7% |
| animated-navigation.large/plain/cold | 2.10 ms | 4.08 ms | -16.8% |
| animated-navigation.large/plain/settle | 0.8 µs | 1.2 µs | -13.8% |
| animated-navigation.large/plain/steady | 6.47 ms | 6.56 ms | -28.6% |
| animated-navigation.large/plain/teardown | 1.08 ms | 1.69 ms | -14.8% |
| animated-navigation.medium/compose/burst | 1.00 ms | 1.09 ms | -24.2% |
| animated-navigation.medium/compose/cold | 1.25 ms | 2.58 ms | -15.1% |
| animated-navigation.medium/compose/counts | 19.39 ms | 19.39 ms | -18.8% |
| animated-navigation.medium/compose/settle | 0.5 µs | 0.8 µs | -15.9% |
| animated-navigation.medium/compose/steady | 7.88 ms | 8.06 ms | -26.7% |
| animated-navigation.medium/compose/teardown | 265.1 µs | 465.7 µs | -18.4% |
| animated-navigation.medium/memory/mounted | 1183 KiB | 1183 KiB | +0.0% |
| animated-navigation.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| animated-navigation.medium/plain/burst | 186.9 µs | 228.6 µs | -16.6% |
| animated-navigation.medium/plain/cold | 560.7 µs | 1.30 ms | -2.7% |
| animated-navigation.medium/plain/settle | 0.3 µs | 15.0 µs | -29.3% |
| animated-navigation.medium/plain/steady | 2.20 ms | 2.22 ms | -13.9% |
| animated-navigation.medium/plain/teardown | 154.4 µs | 378.5 µs | -23.2% |
| branch-swap/compose | 4.11 ms | 5.55 ms | -5.8% |
| branch-swap/memory/mounted | 24 KiB | 24 KiB | +0.0% |
| branch-swap/memory/teardown | 0 KiB | 0 KiB | — |
| branch-swap/plain | 2.96 ms | 4.63 ms | +9.1% |
| cold-mount-100/compose | 800.6 µs | 1.38 ms | +12.6% |
| cold-mount-100/memory/mounted | 2396 KiB | 2396 KiB | -0.3% |
| cold-mount-100/memory/teardown | 0 KiB | 0 KiB | — |
| cold-mount-100/plain | 425.3 µs | 921.6 µs | -39.2% |
| cold-mount-1000/compose | 7.48 ms | 9.28 ms | -5.4% |
| cold-mount-1000/memory/mounted | 23552 KiB | 23552 KiB | +0.0% |
| cold-mount-1000/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| cold-mount-1000/plain | 5.71 ms | 6.23 ms | -6.8% |
| cold-mount-10000/compose | 92.59 ms | 155.82 ms | +17.8% |
| cold-mount-10000/memory/mounted | 237249 KiB | 237249 KiB | -0.0% |
| cold-mount-10000/memory/teardown | 0 KiB | 0 KiB | — |
| cold-mount-10000/plain | 85.33 ms | 127.25 ms | +72.7% |
| data-grid.extreme/compose/burst | 649.61 ms | 662.70 ms | -35.1% |
| data-grid.extreme/compose/cold | 378.61 ms | 404.96 ms | -34.5% |
| data-grid.extreme/compose/counts | 1079.20 ms | 1079.20 ms | -34.8% |
| data-grid.extreme/compose/settle | 2.3 µs | 3.0 µs | -3.4% |
| data-grid.extreme/compose/steady | 10.50 ms | 14.98 ms | -33.4% |
| data-grid.extreme/compose/teardown | 1.03 ms | 2.08 ms | -33.6% |
| data-grid.extreme/memory/mounted | 30549 KiB | 30549 KiB | +0.0% |
| data-grid.extreme/memory/teardown | 9 KiB | 9 KiB | +0.0% |
| data-grid.extreme/plain/burst | 588.84 ms | 598.91 ms | -33.7% |
| data-grid.extreme/plain/cold | 369.24 ms | 377.15 ms | -34.5% |
| data-grid.extreme/plain/settle | 2.5 µs | 3.2 µs | -10.9% |
| data-grid.extreme/plain/steady | 13.86 ms | 17.40 ms | -30.4% |
| data-grid.extreme/plain/teardown | 362.6 µs | 447.0 µs | -49.3% |
| data-grid.large/compose/burst | 128.44 ms | 138.79 ms | -17.1% |
| data-grid.large/compose/cold | 67.63 ms | 75.05 ms | -20.8% |
| data-grid.large/compose/counts | 215.13 ms | 215.13 ms | -10.0% |
| data-grid.large/compose/settle | 2.6 µs | 3.4 µs | +16.0% |
| data-grid.large/compose/steady | 10.06 ms | 17.75 ms | -20.0% |
| data-grid.large/compose/teardown | 560.0 µs | 1.25 ms | -13.2% |
| data-grid.large/memory/mounted | 7144 KiB | 7144 KiB | +0.0% |
| data-grid.large/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| data-grid.large/plain/burst | 101.16 ms | 105.65 ms | -16.0% |
| data-grid.large/plain/cold | 61.00 ms | 65.63 ms | -17.0% |
| data-grid.large/plain/settle | 3.1 µs | 3.6 µs | +32.8% |
| data-grid.large/plain/steady | 9.06 ms | 11.26 ms | -25.3% |
| data-grid.large/plain/teardown | 206.6 µs | 456.8 µs | -0.1% |
| data-grid.medium/compose/burst | 38.03 ms | 43.98 ms | -37.6% |
| data-grid.medium/compose/cold | 22.29 ms | 27.76 ms | -35.7% |
| data-grid.medium/compose/counts | 79.51 ms | 79.51 ms | -32.9% |
| data-grid.medium/compose/settle | 1.7 µs | 2.5 µs | +41.1% |
| data-grid.medium/compose/steady | 7.25 ms | 10.18 ms | -34.6% |
| data-grid.medium/compose/teardown | 197.5 µs | 398.3 µs | -38.5% |
| data-grid.medium/memory/mounted | 3735 KiB | 3735 KiB | +0.0% |
| data-grid.medium/memory/teardown | 0 KiB | 0 KiB | — |
| data-grid.medium/plain/burst | 32.35 ms | 34.47 ms | -38.1% |
| data-grid.medium/plain/cold | 20.17 ms | 21.17 ms | -38.8% |
| data-grid.medium/plain/settle | 1.3 µs | 2.3 µs | +21.3% |
| data-grid.medium/plain/steady | 5.08 ms | 7.34 ms | -33.8% |
| data-grid.medium/plain/teardown | 68.2 µs | 100.4 µs | -31.3% |
| dense-dashboard.extreme/compose/burst | 14.61 ms | 17.53 ms | -1.3% |
| dense-dashboard.extreme/compose/cold | 460.2 µs | 1.35 ms | -7.0% |
| dense-dashboard.extreme/compose/counts | 20.10 ms | 20.10 ms | -16.5% |
| dense-dashboard.extreme/compose/settle | 1.4 µs | 1.8 µs | +65.6% |
| dense-dashboard.extreme/compose/steady | 738.2 µs | 778.9 µs | -17.8% |
| dense-dashboard.extreme/compose/teardown | 483.9 µs | 936.0 µs | -4.2% |
| dense-dashboard.extreme/memory/mounted | 1346 KiB | 1346 KiB | -1.0% |
| dense-dashboard.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| dense-dashboard.extreme/plain/burst | 6.00 ms | 7.12 ms | -7.9% |
| dense-dashboard.extreme/plain/cold | 185.9 µs | 402.2 µs | -23.1% |
| dense-dashboard.extreme/plain/settle | 0.7 µs | 1.2 µs | +2.9% |
| dense-dashboard.extreme/plain/steady | 112.9 µs | 123.0 µs | -18.2% |
| dense-dashboard.extreme/plain/teardown | 174.7 µs | 244.6 µs | -20.4% |
| dense-dashboard.large/compose/burst | 7.65 ms | 10.71 ms | -17.5% |
| dense-dashboard.large/compose/cold | 363.0 µs | 1.09 ms | -0.5% |
| dense-dashboard.large/compose/counts | 15.14 ms | 15.14 ms | -11.9% |
| dense-dashboard.large/compose/settle | 1.3 µs | 2.7 µs | +8.3% |
| dense-dashboard.large/compose/steady | 740.9 µs | 802.5 µs | -17.7% |
| dense-dashboard.large/compose/teardown | 268.3 µs | 460.9 µs | -8.5% |
| dense-dashboard.large/memory/mounted | 715 KiB | 715 KiB | +0.7% |
| dense-dashboard.large/memory/teardown | 0 KiB | 0 KiB | — |
| dense-dashboard.large/plain/burst | 2.30 ms | 4.80 ms | -45.5% |
| dense-dashboard.large/plain/cold | 252.1 µs | 705.8 µs | +71.5% |
| dense-dashboard.large/plain/settle | 0.6 µs | 1.1 µs | -21.6% |
| dense-dashboard.large/plain/steady | 114.9 µs | 120.9 µs | -15.6% |
| dense-dashboard.large/plain/teardown | 107.3 µs | 212.8 µs | +0.5% |
| dense-dashboard.medium/compose/burst | 2.20 ms | 3.19 ms | -24.0% |
| dense-dashboard.medium/compose/cold | 151.9 µs | 254.0 µs | -35.5% |
| dense-dashboard.medium/compose/counts | 4.30 ms | 4.30 ms | -31.0% |
| dense-dashboard.medium/compose/settle | 0.5 µs | 0.8 µs | -23.3% |
| dense-dashboard.medium/compose/steady | 721.7 µs | 757.1 µs | -19.9% |
| dense-dashboard.medium/compose/teardown | 93.9 µs | 103.1 µs | -27.5% |
| dense-dashboard.medium/memory/mounted | 346 KiB | 346 KiB | -0.6% |
| dense-dashboard.medium/memory/teardown | 1 KiB | 1 KiB | — |
| dense-dashboard.medium/plain/burst | 965.6 µs | 2.06 ms | -32.7% |
| dense-dashboard.medium/plain/cold | 70.4 µs | 206.4 µs | -44.5% |
| dense-dashboard.medium/plain/settle | 0.5 µs | 0.8 µs | -22.5% |
| dense-dashboard.medium/plain/steady | 109.7 µs | 114.7 µs | -19.8% |
| dense-dashboard.medium/plain/teardown | 34.3 µs | 61.6 µs | -34.0% |
| entities-identity-churn-10.extreme/compose/burst | 49.65 ms | 63.27 ms | +13.0% |
| entities-identity-churn-10.extreme/compose/cold | 29.38 ms | 56.02 ms | +20.8% |
| entities-identity-churn-10.extreme/compose/counts | 186.04 ms | 186.04 ms | +8.2% |
| entities-identity-churn-10.extreme/compose/settle | 2.4 µs | 3.7 µs | -5.0% |
| entities-identity-churn-10.extreme/compose/steady | 53.58 ms | 70.69 ms | -3.9% |
| entities-identity-churn-10.extreme/compose/teardown | 1.25 ms | 1.44 ms | +7.2% |
| entities-identity-churn-10.extreme/memory/mounted | 4628 KiB | 4628 KiB | +0.0% |
| entities-identity-churn-10.extreme/memory/teardown | 9 KiB | 9 KiB | +800.0% |
| entities-identity-churn-10.extreme/plain/burst | 16.11 ms | 29.30 ms | +0.6% |
| entities-identity-churn-10.extreme/plain/cold | 8.38 ms | 14.56 ms | -15.6% |
| entities-identity-churn-10.extreme/plain/settle | 1.9 µs | 2.4 µs | -10.3% |
| entities-identity-churn-10.extreme/plain/steady | 30.97 ms | 41.79 ms | -7.8% |
| entities-identity-churn-10.extreme/plain/teardown | 393.6 µs | 522.5 µs | -3.9% |
| entities-identity-churn-10.large/compose/burst | 10.11 ms | 18.33 ms | -28.9% |
| entities-identity-churn-10.large/compose/cold | 8.09 ms | 16.37 ms | -19.8% |
| entities-identity-churn-10.large/compose/counts | 43.27 ms | 43.27 ms | -29.4% |
| entities-identity-churn-10.large/compose/settle | 2.3 µs | 2.7 µs | +79.5% |
| entities-identity-churn-10.large/compose/steady | 11.25 ms | 14.79 ms | -36.6% |
| entities-identity-churn-10.large/compose/teardown | 334.5 µs | 568.1 µs | -16.8% |
| entities-identity-churn-10.large/memory/mounted | 1883 KiB | 1883 KiB | +0.0% |
| entities-identity-churn-10.large/memory/teardown | 1 KiB | 1 KiB | — |
| entities-identity-churn-10.large/plain/burst | 4.23 ms | 5.34 ms | -0.9% |
| entities-identity-churn-10.large/plain/cold | 2.29 ms | 6.14 ms | -35.3% |
| entities-identity-churn-10.large/plain/settle | 1.1 µs | 1.7 µs | +49.9% |
| entities-identity-churn-10.large/plain/steady | 6.87 ms | 7.99 ms | -35.1% |
| entities-identity-churn-10.large/plain/teardown | 95.6 µs | 130.2 µs | -12.3% |
| entities-identity-churn-10.medium/compose/burst | 5.76 ms | 7.58 ms | -12.7% |
| entities-identity-churn-10.medium/compose/cold | 4.97 ms | 7.30 ms | -10.1% |
| entities-identity-churn-10.medium/compose/counts | 27.19 ms | 27.19 ms | -26.2% |
| entities-identity-churn-10.medium/compose/settle | 0.8 µs | 1.1 µs | -19.1% |
| entities-identity-churn-10.medium/compose/steady | 6.01 ms | 6.88 ms | -26.0% |
| entities-identity-churn-10.medium/compose/teardown | 162.9 µs | 231.2 µs | -22.4% |
| entities-identity-churn-10.medium/memory/mounted | 1024 KiB | 1024 KiB | +0.0% |
| entities-identity-churn-10.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-identity-churn-10.medium/plain/burst | 1.64 ms | 3.23 ms | -25.0% |
| entities-identity-churn-10.medium/plain/cold | 983.0 µs | 3.79 ms | -26.1% |
| entities-identity-churn-10.medium/plain/settle | 0.6 µs | 0.8 µs | -14.8% |
| entities-identity-churn-10.medium/plain/steady | 4.18 ms | 5.17 ms | -19.8% |
| entities-identity-churn-10.medium/plain/teardown | 43.6 µs | 171.2 µs | -22.5% |
| entities-identity-churn-50.extreme/compose/burst | 30.82 ms | 48.18 ms | -29.7% |
| entities-identity-churn-50.extreme/compose/cold | 22.32 ms | 42.39 ms | -36.7% |
| entities-identity-churn-50.extreme/compose/counts | 224.92 ms | 224.92 ms | -24.9% |
| entities-identity-churn-50.extreme/compose/settle | 2.3 µs | 2.8 µs | +12.4% |
| entities-identity-churn-50.extreme/compose/steady | 114.44 ms | 168.11 ms | -17.6% |
| entities-identity-churn-50.extreme/compose/teardown | 1.01 ms | 1.47 ms | -9.4% |
| entities-identity-churn-50.extreme/memory/mounted | 4617 KiB | 4617 KiB | -0.0% |
| entities-identity-churn-50.extreme/memory/teardown | 8 KiB | 8 KiB | +700.0% |
| entities-identity-churn-50.extreme/plain/burst | 11.85 ms | 18.97 ms | -15.9% |
| entities-identity-churn-50.extreme/plain/cold | 7.03 ms | 13.18 ms | -18.5% |
| entities-identity-churn-50.extreme/plain/settle | 2.1 µs | 2.8 µs | +22.5% |
| entities-identity-churn-50.extreme/plain/steady | 46.57 ms | 55.08 ms | -28.3% |
| entities-identity-churn-50.extreme/plain/teardown | 257.2 µs | 392.6 µs | -26.5% |
| entities-identity-churn-50.large/compose/burst | 16.11 ms | 24.90 ms | +8.8% |
| entities-identity-churn-50.large/compose/cold | 11.01 ms | 22.75 ms | +10.6% |
| entities-identity-churn-50.large/compose/counts | 122.39 ms | 122.39 ms | +12.7% |
| entities-identity-churn-50.large/compose/settle | 2.3 µs | 4.6 µs | -5.2% |
| entities-identity-churn-50.large/compose/steady | 53.69 ms | 66.37 ms | -1.8% |
| entities-identity-churn-50.large/compose/teardown | 468.9 µs | 719.0 µs | +9.9% |
| entities-identity-churn-50.large/memory/mounted | 1983 KiB | 1983 KiB | +0.0% |
| entities-identity-churn-50.large/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn-50.large/plain/burst | 5.33 ms | 7.78 ms | -4.0% |
| entities-identity-churn-50.large/plain/cold | 3.06 ms | 6.13 ms | -15.8% |
| entities-identity-churn-50.large/plain/settle | 1.6 µs | 2.1 µs | -6.5% |
| entities-identity-churn-50.large/plain/steady | 22.57 ms | 35.34 ms | -10.0% |
| entities-identity-churn-50.large/plain/teardown | 144.8 µs | 191.5 µs | +10.7% |
| entities-identity-churn-50.medium/compose/burst | 8.03 ms | 15.20 ms | -16.2% |
| entities-identity-churn-50.medium/compose/cold | 4.58 ms | 7.67 ms | -37.8% |
| entities-identity-churn-50.medium/compose/counts | 53.62 ms | 53.62 ms | -19.7% |
| entities-identity-churn-50.medium/compose/settle | 2.4 µs | 2.9 µs | +21.5% |
| entities-identity-churn-50.medium/compose/steady | 24.33 ms | 31.95 ms | -20.5% |
| entities-identity-churn-50.medium/compose/teardown | 275.0 µs | 538.6 µs | -20.0% |
| entities-identity-churn-50.medium/memory/mounted | 1138 KiB | 1138 KiB | +1.4% |
| entities-identity-churn-50.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn-50.medium/plain/burst | 3.06 ms | 6.53 ms | -8.7% |
| entities-identity-churn-50.medium/plain/cold | 1.27 ms | 2.41 ms | -28.0% |
| entities-identity-churn-50.medium/plain/settle | 1.8 µs | 2.1 µs | +26.3% |
| entities-identity-churn-50.medium/plain/steady | 8.50 ms | 12.03 ms | -14.2% |
| entities-identity-churn-50.medium/plain/teardown | 73.0 µs | 107.6 µs | -6.9% |
| entities-identity-churn.extreme/compose/burst | 57.82 ms | 79.91 ms | +1.6% |
| entities-identity-churn.extreme/compose/cold | 33.44 ms | 52.78 ms | -11.0% |
| entities-identity-churn.extreme/compose/counts | 290.26 ms | 290.26 ms | -3.2% |
| entities-identity-churn.extreme/compose/settle | 2.5 µs | 2.9 µs | +11.2% |
| entities-identity-churn.extreme/compose/steady | 98.60 ms | 139.07 ms | -11.2% |
| entities-identity-churn.extreme/compose/teardown | 1.49 ms | 1.86 ms | -12.0% |
| entities-identity-churn.extreme/memory/mounted | 4977 KiB | 4977 KiB | -0.3% |
| entities-identity-churn.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| entities-identity-churn.extreme/plain/burst | 19.79 ms | 27.45 ms | -7.0% |
| entities-identity-churn.extreme/plain/cold | 9.35 ms | 16.37 ms | +4.3% |
| entities-identity-churn.extreme/plain/settle | 2.8 µs | 3.2 µs | +18.8% |
| entities-identity-churn.extreme/plain/steady | 49.03 ms | 55.27 ms | -9.2% |
| entities-identity-churn.extreme/plain/teardown | 437.0 µs | 638.8 µs | -17.6% |
| entities-identity-churn.large/compose/burst | 10.61 ms | 17.97 ms | -27.2% |
| entities-identity-churn.large/compose/cold | 8.96 ms | 14.60 ms | -24.2% |
| entities-identity-churn.large/compose/counts | 68.15 ms | 68.15 ms | -36.3% |
| entities-identity-churn.large/compose/settle | 1.5 µs | 1.9 µs | -28.8% |
| entities-identity-churn.large/compose/steady | 24.62 ms | 34.29 ms | -23.4% |
| entities-identity-churn.large/compose/teardown | 312.1 µs | 613.0 µs | -29.8% |
| entities-identity-churn.large/memory/mounted | 1870 KiB | 1870 KiB | -0.5% |
| entities-identity-churn.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-identity-churn.large/plain/burst | 3.74 ms | 5.72 ms | -16.7% |
| entities-identity-churn.large/plain/cold | 3.13 ms | 5.87 ms | +11.9% |
| entities-identity-churn.large/plain/settle | 0.8 µs | 1.5 µs | -31.0% |
| entities-identity-churn.large/plain/steady | 11.58 ms | 19.88 ms | -25.0% |
| entities-identity-churn.large/plain/teardown | 89.5 µs | 191.3 µs | -28.4% |
| entities-identity-churn.medium/compose/burst | 5.95 ms | 11.71 ms | -24.5% |
| entities-identity-churn.medium/compose/cold | 4.03 ms | 6.00 ms | -14.9% |
| entities-identity-churn.medium/compose/counts | 28.32 ms | 28.32 ms | -28.7% |
| entities-identity-churn.medium/compose/settle | 1.8 µs | 2.6 µs | +96.5% |
| entities-identity-churn.medium/compose/steady | 10.55 ms | 14.91 ms | -21.9% |
| entities-identity-churn.medium/compose/teardown | 209.5 µs | 274.4 µs | -4.6% |
| entities-identity-churn.medium/memory/mounted | 1078 KiB | 1078 KiB | -0.8% |
| entities-identity-churn.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-identity-churn.medium/plain/burst | 2.52 ms | 3.63 ms | -0.6% |
| entities-identity-churn.medium/plain/cold | 1.68 ms | 3.05 ms | +24.4% |
| entities-identity-churn.medium/plain/settle | 1.2 µs | 1.8 µs | +48.8% |
| entities-identity-churn.medium/plain/steady | 4.47 ms | 8.34 ms | -35.7% |
| entities-identity-churn.medium/plain/teardown | 53.5 µs | 139.8 µs | -13.7% |
| entities-integrated.extreme/compose/burst | 16.59 ms | 18.80 ms | -23.0% |
| entities-integrated.extreme/compose/cold | 97.60 ms | 128.95 ms | -9.9% |
| entities-integrated.extreme/compose/counts | 318.60 ms | 318.60 ms | -16.3% |
| entities-integrated.extreme/compose/settle | 1.6 µs | 3.1 µs | -22.7% |
| entities-integrated.extreme/compose/steady | 86.27 ms | 119.81 ms | -20.2% |
| entities-integrated.extreme/compose/teardown | 47.58 ms | 49.62 ms | -18.1% |
| entities-integrated.extreme/memory/mounted | 43273 KiB | 43273 KiB | -1.2% |
| entities-integrated.extreme/memory/teardown | 8 KiB | 8 KiB | -11.1% |
| entities-integrated.extreme/plain/burst | 5.98 ms | 7.07 ms | -10.9% |
| entities-integrated.extreme/plain/cold | 23.37 ms | 49.66 ms | -3.5% |
| entities-integrated.extreme/plain/settle | 1.2 µs | 2.5 µs | -41.1% |
| entities-integrated.extreme/plain/steady | 24.81 ms | 41.44 ms | -17.4% |
| entities-integrated.extreme/plain/teardown | 22.49 ms | 25.52 ms | -15.5% |
| entities-integrated.large/compose/burst | 8.34 ms | 10.01 ms | -32.1% |
| entities-integrated.large/compose/cold | 37.51 ms | 52.75 ms | -15.5% |
| entities-integrated.large/compose/counts | 156.76 ms | 156.76 ms | -6.7% |
| entities-integrated.large/compose/settle | 2.2 µs | 3.3 µs | +14.4% |
| entities-integrated.large/compose/steady | 47.56 ms | 73.91 ms | -20.2% |
| entities-integrated.large/compose/teardown | 18.78 ms | 23.30 ms | -6.7% |
| entities-integrated.large/memory/mounted | 18093 KiB | 18093 KiB | -0.0% |
| entities-integrated.large/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| entities-integrated.large/plain/burst | 3.34 ms | 6.46 ms | +0.7% |
| entities-integrated.large/plain/cold | 13.50 ms | 19.69 ms | -6.4% |
| entities-integrated.large/plain/settle | 2.1 µs | 3.3 µs | +38.1% |
| entities-integrated.large/plain/steady | 13.83 ms | 24.96 ms | -0.4% |
| entities-integrated.large/plain/teardown | 7.51 ms | 11.24 ms | +8.0% |
| entities-integrated.medium/compose/burst | 5.31 ms | 9.65 ms | -31.2% |
| entities-integrated.medium/compose/cold | 15.41 ms | 24.28 ms | -29.4% |
| entities-integrated.medium/compose/counts | 65.60 ms | 65.60 ms | -43.0% |
| entities-integrated.medium/compose/settle | 1.1 µs | 1.6 µs | -42.0% |
| entities-integrated.medium/compose/steady | 23.67 ms | 30.07 ms | -45.9% |
| entities-integrated.medium/compose/teardown | 5.18 ms | 8.16 ms | -38.6% |
| entities-integrated.medium/memory/mounted | 9843 KiB | 9843 KiB | +0.1% |
| entities-integrated.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entities-integrated.medium/plain/burst | 1.66 ms | 5.55 ms | -45.6% |
| entities-integrated.medium/plain/cold | 4.76 ms | 12.36 ms | -3.1% |
| entities-integrated.medium/plain/settle | 0.8 µs | 1.3 µs | -53.1% |
| entities-integrated.medium/plain/steady | 7.49 ms | 10.17 ms | -38.6% |
| entities-integrated.medium/plain/teardown | 1.65 ms | 3.04 ms | -48.6% |
| entities-relevance-saturated.extreme/compose/burst | 64.65 ms | 73.22 ms | -5.7% |
| entities-relevance-saturated.extreme/compose/cold | 18.07 ms | 38.67 ms | -40.8% |
| entities-relevance-saturated.extreme/compose/counts | 183.67 ms | 183.67 ms | -14.2% |
| entities-relevance-saturated.extreme/compose/settle | 2.8 µs | 3.8 µs | +59.7% |
| entities-relevance-saturated.extreme/compose/steady | 41.90 ms | 67.13 ms | +2.3% |
| entities-relevance-saturated.extreme/compose/teardown | 12.11 ms | 13.17 ms | -3.7% |
| entities-relevance-saturated.extreme/memory/mounted | 13175 KiB | 13175 KiB | +0.0% |
| entities-relevance-saturated.extreme/memory/teardown | 1 KiB | 1 KiB | -88.9% |
| entities-relevance-saturated.extreme/plain/burst | 15.98 ms | 27.19 ms | +4.0% |
| entities-relevance-saturated.extreme/plain/cold | 7.38 ms | 16.86 ms | -13.9% |
| entities-relevance-saturated.extreme/plain/settle | 2.2 µs | 3.0 µs | +34.1% |
| entities-relevance-saturated.extreme/plain/steady | 56.48 ms | 78.38 ms | -40.4% |
| entities-relevance-saturated.extreme/plain/teardown | 3.55 ms | 5.25 ms | +18.5% |
| entities-relevance-saturated.large/compose/burst | 29.12 ms | 38.52 ms | +15.8% |
| entities-relevance-saturated.large/compose/cold | 9.05 ms | 20.15 ms | -18.0% |
| entities-relevance-saturated.large/compose/counts | 86.68 ms | 86.68 ms | -7.5% |
| entities-relevance-saturated.large/compose/settle | 2.9 µs | 3.7 µs | +111.5% |
| entities-relevance-saturated.large/compose/steady | 16.10 ms | 25.08 ms | +5.1% |
| entities-relevance-saturated.large/compose/teardown | 4.09 ms | 6.05 ms | +39.2% |
| entities-relevance-saturated.large/memory/mounted | 5281 KiB | 5281 KiB | -0.2% |
| entities-relevance-saturated.large/memory/teardown | 1 KiB | 1 KiB | -87.5% |
| entities-relevance-saturated.large/plain/burst | 7.27 ms | 10.76 ms | +19.7% |
| entities-relevance-saturated.large/plain/cold | 3.05 ms | 9.09 ms | -10.5% |
| entities-relevance-saturated.large/plain/settle | 2.7 µs | 3.4 µs | +121.6% |
| entities-relevance-saturated.large/plain/steady | 22.34 ms | 30.79 ms | -43.3% |
| entities-relevance-saturated.large/plain/teardown | 1.68 ms | 1.99 ms | +74.2% |
| entities-relevance-saturated.medium/compose/burst | 12.95 ms | 18.79 ms | +13.8% |
| entities-relevance-saturated.medium/compose/cold | 5.26 ms | 11.51 ms | +12.6% |
| entities-relevance-saturated.medium/compose/counts | 40.54 ms | 40.54 ms | +14.3% |
| entities-relevance-saturated.medium/compose/settle | 1.7 µs | 2.1 µs | -8.9% |
| entities-relevance-saturated.medium/compose/steady | 9.19 ms | 17.16 ms | +18.9% |
| entities-relevance-saturated.medium/compose/teardown | 1.27 ms | 1.54 ms | +11.1% |
| entities-relevance-saturated.medium/memory/mounted | 2636 KiB | 2636 KiB | -0.6% |
| entities-relevance-saturated.medium/memory/teardown | 1 KiB | 1 KiB | — |
| entities-relevance-saturated.medium/plain/burst | 3.56 ms | 6.07 ms | +42.6% |
| entities-relevance-saturated.medium/plain/cold | 1.88 ms | 7.80 ms | +25.2% |
| entities-relevance-saturated.medium/plain/settle | 1.2 µs | 2.6 µs | -21.3% |
| entities-relevance-saturated.medium/plain/steady | 16.87 ms | 21.39 ms | +11.8% |
| entities-relevance-saturated.medium/plain/teardown | 463.8 µs | 734.7 µs | -12.4% |
| entities-relevance-sweep.extreme/compose/burst | 148.33 ms | 173.92 ms | +5.6% |
| entities-relevance-sweep.extreme/compose/cold | 33.93 ms | 48.85 ms | +35.6% |
| entities-relevance-sweep.extreme/compose/counts | 386.12 ms | 386.12 ms | +3.4% |
| entities-relevance-sweep.extreme/compose/settle | 2.7 µs | 3.6 µs | +2.2% |
| entities-relevance-sweep.extreme/compose/steady | 127.03 ms | 184.40 ms | +4.9% |
| entities-relevance-sweep.extreme/compose/teardown | 16.49 ms | 20.38 ms | +9.6% |
| entities-relevance-sweep.extreme/memory/mounted | 13187 KiB | 13187 KiB | -0.1% |
| entities-relevance-sweep.extreme/memory/teardown | 8 KiB | 8 KiB | +0.0% |
| entities-relevance-sweep.extreme/plain/burst | 37.40 ms | 66.58 ms | +13.5% |
| entities-relevance-sweep.extreme/plain/cold | 13.14 ms | 34.18 ms | +50.5% |
| entities-relevance-sweep.extreme/plain/settle | 2.9 µs | 3.2 µs | +20.4% |
| entities-relevance-sweep.extreme/plain/steady | 30.05 ms | 51.77 ms | -7.2% |
| entities-relevance-sweep.extreme/plain/teardown | 4.60 ms | 5.29 ms | +15.4% |
| entities-relevance-sweep.large/compose/burst | 34.28 ms | 42.34 ms | -16.6% |
| entities-relevance-sweep.large/compose/cold | 7.58 ms | 16.20 ms | -26.4% |
| entities-relevance-sweep.large/compose/counts | 84.64 ms | 84.64 ms | -33.6% |
| entities-relevance-sweep.large/compose/settle | 2.2 µs | 3.1 µs | +33.3% |
| entities-relevance-sweep.large/compose/steady | 26.65 ms | 38.51 ms | -38.2% |
| entities-relevance-sweep.large/compose/teardown | 2.92 ms | 5.25 ms | -9.0% |
| entities-relevance-sweep.large/memory/mounted | 5297 KiB | 5297 KiB | +0.0% |
| entities-relevance-sweep.large/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| entities-relevance-sweep.large/plain/burst | 10.22 ms | 17.45 ms | +7.4% |
| entities-relevance-sweep.large/plain/cold | 2.56 ms | 7.85 ms | -53.8% |
| entities-relevance-sweep.large/plain/settle | 1.6 µs | 2.6 µs | +53.8% |
| entities-relevance-sweep.large/plain/steady | 6.91 ms | 11.43 ms | -32.2% |
| entities-relevance-sweep.large/plain/teardown | 1.35 ms | 2.18 ms | +38.9% |
| entities-relevance-sweep.medium/compose/burst | 18.11 ms | 28.56 ms | -20.0% |
| entities-relevance-sweep.medium/compose/cold | 6.94 ms | 10.84 ms | -0.4% |
| entities-relevance-sweep.medium/compose/counts | 62.31 ms | 62.31 ms | -11.9% |
| entities-relevance-sweep.medium/compose/settle | 1.0 µs | 1.4 µs | -46.1% |
| entities-relevance-sweep.medium/compose/steady | 18.41 ms | 27.98 ms | -14.2% |
| entities-relevance-sweep.medium/compose/teardown | 1.09 ms | 1.34 ms | -25.9% |
| entities-relevance-sweep.medium/memory/mounted | 2645 KiB | 2645 KiB | +0.0% |
| entities-relevance-sweep.medium/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| entities-relevance-sweep.medium/plain/burst | 4.19 ms | 8.46 ms | -13.6% |
| entities-relevance-sweep.medium/plain/cold | 1.97 ms | 4.35 ms | +0.9% |
| entities-relevance-sweep.medium/plain/settle | 0.7 µs | 0.8 µs | -57.5% |
| entities-relevance-sweep.medium/plain/steady | 4.33 ms | 5.99 ms | -21.3% |
| entities-relevance-sweep.medium/plain/teardown | 321.2 µs | 442.4 µs | -46.6% |
| entity-labels-sparse.extreme/compose/burst | 38.60 ms | 47.76 ms | +8.8% |
| entity-labels-sparse.extreme/compose/cold | 25.37 ms | 36.54 ms | -0.0% |
| entity-labels-sparse.extreme/compose/counts | 119.79 ms | 119.79 ms | +9.3% |
| entity-labels-sparse.extreme/compose/settle | 3.1 µs | 3.5 µs | +39.2% |
| entity-labels-sparse.extreme/compose/steady | 4.52 ms | 5.01 ms | +4.5% |
| entity-labels-sparse.extreme/compose/teardown | 15.32 ms | 18.32 ms | +6.8% |
| entity-labels-sparse.extreme/memory/mounted | 12981 KiB | 12981 KiB | -0.3% |
| entity-labels-sparse.extreme/memory/teardown | 9 KiB | 9 KiB | +800.0% |
| entity-labels-sparse.extreme/plain/burst | 9.36 ms | 15.18 ms | +4.7% |
| entity-labels-sparse.extreme/plain/cold | 8.75 ms | 14.87 ms | -9.6% |
| entity-labels-sparse.extreme/plain/settle | 1.7 µs | 2.9 µs | +8.7% |
| entity-labels-sparse.extreme/plain/steady | 945.5 µs | 1.07 ms | -14.1% |
| entity-labels-sparse.extreme/plain/teardown | 6.68 ms | 7.36 ms | +1.7% |
| entity-labels-sparse.large/compose/burst | 10.90 ms | 13.84 ms | -22.5% |
| entity-labels-sparse.large/compose/cold | 12.36 ms | 16.38 ms | +24.3% |
| entity-labels-sparse.large/compose/counts | 46.49 ms | 46.49 ms | -2.9% |
| entity-labels-sparse.large/compose/settle | 1.7 µs | 5.3 µs | -9.3% |
| entity-labels-sparse.large/compose/steady | 1.62 ms | 1.94 ms | -26.8% |
| entity-labels-sparse.large/compose/teardown | 4.02 ms | 5.30 ms | -17.9% |
| entity-labels-sparse.large/memory/mounted | 6744 KiB | 6744 KiB | -0.5% |
| entity-labels-sparse.large/memory/teardown | 0 KiB | 0 KiB | — |
| entity-labels-sparse.large/plain/burst | 4.02 ms | 5.17 ms | -24.7% |
| entity-labels-sparse.large/plain/cold | 4.73 ms | 7.03 ms | +11.5% |
| entity-labels-sparse.large/plain/settle | 0.9 µs | 1.6 µs | -12.5% |
| entity-labels-sparse.large/plain/steady | 413.6 µs | 477.9 µs | -20.8% |
| entity-labels-sparse.large/plain/teardown | 1.79 ms | 2.29 ms | -13.6% |
| entity-labels-sparse.medium/compose/burst | 4.11 ms | 9.07 ms | -24.9% |
| entity-labels-sparse.medium/compose/cold | 4.62 ms | 6.13 ms | +7.9% |
| entity-labels-sparse.medium/compose/counts | 18.18 ms | 18.18 ms | -5.0% |
| entity-labels-sparse.medium/compose/settle | 1.2 µs | 1.5 µs | +25.9% |
| entity-labels-sparse.medium/compose/steady | 726.5 µs | 788.6 µs | -15.9% |
| entity-labels-sparse.medium/compose/teardown | 1.24 ms | 1.54 ms | -11.0% |
| entity-labels-sparse.medium/memory/mounted | 2986 KiB | 2986 KiB | -0.4% |
| entity-labels-sparse.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entity-labels-sparse.medium/plain/burst | 1.20 ms | 2.76 ms | -16.7% |
| entity-labels-sparse.medium/plain/cold | 1.41 ms | 2.44 ms | +1.6% |
| entity-labels-sparse.medium/plain/settle | 0.6 µs | 0.8 µs | -9.1% |
| entity-labels-sparse.medium/plain/steady | 159.0 µs | 194.1 µs | -25.1% |
| entity-labels-sparse.medium/plain/teardown | 424.6 µs | 709.6 µs | -10.3% |
| entity-labels.extreme/compose/burst | 27.15 ms | 38.16 ms | -24.5% |
| entity-labels.extreme/compose/cold | 27.82 ms | 37.47 ms | -1.5% |
| entity-labels.extreme/compose/counts | 124.07 ms | 124.07 ms | -19.5% |
| entity-labels.extreme/compose/settle | 1.6 µs | 1.7 µs | -35.1% |
| entity-labels.extreme/compose/steady | 30.22 ms | 32.93 ms | -11.3% |
| entity-labels.extreme/compose/teardown | 12.21 ms | 14.77 ms | -16.8% |
| entity-labels.extreme/memory/mounted | 13484 KiB | 13484 KiB | -0.4% |
| entity-labels.extreme/memory/teardown | 8 KiB | 8 KiB | +0.0% |
| entity-labels.extreme/plain/burst | 9.92 ms | 11.71 ms | +6.6% |
| entity-labels.extreme/plain/cold | 8.80 ms | 12.64 ms | -8.6% |
| entity-labels.extreme/plain/settle | 0.9 µs | 1.4 µs | -39.9% |
| entity-labels.extreme/plain/steady | 836.3 µs | 1.04 ms | -21.3% |
| entity-labels.extreme/plain/teardown | 5.66 ms | 6.47 ms | -10.9% |
| entity-labels.large/compose/burst | 15.10 ms | 18.56 ms | -14.9% |
| entity-labels.large/compose/cold | 13.04 ms | 19.81 ms | -22.8% |
| entity-labels.large/compose/counts | 68.71 ms | 68.71 ms | -3.9% |
| entity-labels.large/compose/settle | 2.4 µs | 2.6 µs | +6.3% |
| entity-labels.large/compose/steady | 12.72 ms | 13.48 ms | -31.4% |
| entity-labels.large/compose/teardown | 5.26 ms | 6.10 ms | -6.0% |
| entity-labels.large/memory/mounted | 7022 KiB | 7022 KiB | -0.2% |
| entity-labels.large/memory/teardown | 0 KiB | 0 KiB | — |
| entity-labels.large/plain/burst | 3.83 ms | 5.88 ms | -20.2% |
| entity-labels.large/plain/cold | 5.60 ms | 8.47 ms | +17.2% |
| entity-labels.large/plain/settle | 1.3 µs | 2.0 µs | +21.0% |
| entity-labels.large/plain/steady | 425.0 µs | 602.8 µs | -14.3% |
| entity-labels.large/plain/teardown | 2.04 ms | 2.35 ms | -3.6% |
| entity-labels.medium/compose/burst | 5.08 ms | 6.99 ms | -10.7% |
| entity-labels.medium/compose/cold | 4.69 ms | 7.59 ms | -9.7% |
| entity-labels.medium/compose/counts | 24.04 ms | 24.04 ms | -8.8% |
| entity-labels.medium/compose/settle | 0.8 µs | 0.8 µs | -35.7% |
| entity-labels.medium/compose/steady | 6.28 ms | 6.87 ms | -8.0% |
| entity-labels.medium/compose/teardown | 1.37 ms | 1.56 ms | -9.8% |
| entity-labels.medium/memory/mounted | 3116 KiB | 3116 KiB | -0.4% |
| entity-labels.medium/memory/teardown | 0 KiB | 0 KiB | — |
| entity-labels.medium/plain/burst | 1.85 ms | 2.29 ms | +31.5% |
| entity-labels.medium/plain/cold | 1.50 ms | 3.99 ms | -36.5% |
| entity-labels.medium/plain/settle | 0.6 µs | 0.9 µs | -10.9% |
| entity-labels.medium/plain/steady | 209.8 µs | 225.1 µs | -1.8% |
| entity-labels.medium/plain/teardown | 516.9 µs | 545.7 µs | +7.7% |
| events/compose | 14.83 ms | 18.51 ms | +21.6% |
| events/memory/mounted | 9 KiB | 9 KiB | — |
| events/memory/teardown | 0 KiB | 0 KiB | — |
| events/plain | 12.70 ms | 14.38 ms | +24.0% |
| inspector.extreme/compose/burst | 5.88 ms | 9.05 ms | -30.7% |
| inspector.extreme/compose/cold | 17.45 ms | 26.78 ms | -12.7% |
| inspector.extreme/compose/counts | 35.07 ms | 35.07 ms | +3.5% |
| inspector.extreme/compose/settle | 1.9 µs | 2.5 µs | +103.3% |
| inspector.extreme/compose/steady | 231.3 µs | 287.2 µs | +6.5% |
| inspector.extreme/compose/teardown | 2.85 ms | 4.85 ms | +19.3% |
| inspector.extreme/memory/mounted | 18489 KiB | 18489 KiB | -0.0% |
| inspector.extreme/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| inspector.extreme/plain/burst | 1.24 ms | 1.42 ms | -30.0% |
| inspector.extreme/plain/cold | 5.99 ms | 10.92 ms | -25.3% |
| inspector.extreme/plain/settle | 0.8 µs | 1.3 µs | +14.5% |
| inspector.extreme/plain/steady | 62.7 µs | 104.3 µs | -9.7% |
| inspector.extreme/plain/teardown | 4.88 ms | 5.83 ms | -15.1% |
| inspector.large/compose/burst | 4.44 ms | 5.90 ms | +35.2% |
| inspector.large/compose/cold | 8.39 ms | 11.58 ms | +6.2% |
| inspector.large/compose/counts | 17.75 ms | 17.75 ms | +12.2% |
| inspector.large/compose/settle | 1.0 µs | 1.2 µs | -30.2% |
| inspector.large/compose/steady | 217.6 µs | 228.1 µs | +14.8% |
| inspector.large/compose/teardown | 1.25 ms | 2.01 ms | +0.8% |
| inspector.large/memory/mounted | 6582 KiB | 6582 KiB | -0.1% |
| inspector.large/memory/teardown | 0 KiB | 0 KiB | — |
| inspector.large/plain/burst | 731.6 µs | 880.3 µs | +17.0% |
| inspector.large/plain/cold | 2.97 ms | 7.69 ms | -14.1% |
| inspector.large/plain/settle | 0.6 µs | 0.9 µs | -6.6% |
| inspector.large/plain/steady | 65.8 µs | 92.2 µs | -14.4% |
| inspector.large/plain/teardown | 1.81 ms | 2.32 ms | -3.5% |
| inspector.medium/compose/burst | 1.18 ms | 1.38 ms | -22.5% |
| inspector.medium/compose/cold | 1.67 ms | 2.95 ms | -17.2% |
| inspector.medium/compose/counts | 3.73 ms | 3.73 ms | -25.5% |
| inspector.medium/compose/settle | 0.5 µs | 0.6 µs | -21.4% |
| inspector.medium/compose/steady | 151.9 µs | 162.7 µs | -21.0% |
| inspector.medium/compose/teardown | 357.7 µs | 403.7 µs | -11.8% |
| inspector.medium/memory/mounted | 1880 KiB | 1880 KiB | -0.1% |
| inspector.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| inspector.medium/plain/burst | 184.8 µs | 202.5 µs | -24.6% |
| inspector.medium/plain/cold | 1.13 ms | 1.89 ms | +22.5% |
| inspector.medium/plain/settle | 0.3 µs | 0.4 µs | -38.1% |
| inspector.medium/plain/steady | 47.3 µs | 48.6 µs | -20.7% |
| inspector.medium/plain/teardown | 275.4 µs | 370.0 µs | -17.1% |
| keyed-append/compose | 1.12 ms | 1.94 ms | -19.2% |
| keyed-append/memory/mounted | 2430 KiB | 2430 KiB | -0.3% |
| keyed-append/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-append/plain | 1.19 ms | 1.51 ms | -22.8% |
| keyed-insert/compose | 2.07 ms | 2.66 ms | -29.8% |
| keyed-insert/memory/mounted | 2434 KiB | 2434 KiB | +0.0% |
| keyed-insert/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| keyed-insert/plain | 1.38 ms | 1.75 ms | -21.5% |
| keyed-prepend/compose | 2.72 ms | 3.47 ms | -37.0% |
| keyed-prepend/memory/mounted | 2438 KiB | 2438 KiB | +0.0% |
| keyed-prepend/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-prepend/plain | 1.29 ms | 1.74 ms | -38.1% |
| keyed-remove/compose | 2.63 ms | 3.78 ms | +19.8% |
| keyed-remove/memory/mounted | 2437 KiB | 2437 KiB | -0.3% |
| keyed-remove/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-remove/plain | 1.67 ms | 2.98 ms | +10.2% |
| keyed-replace/compose | 55.41 ms | 62.77 ms | -11.2% |
| keyed-replace/memory/mounted | 2473 KiB | 2473 KiB | -0.6% |
| keyed-replace/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| keyed-replace/plain | 32.85 ms | 38.69 ms | -2.0% |
| keyed-reverse/compose | 2.31 ms | 2.37 ms | -29.1% |
| keyed-reverse/memory/mounted | 2434 KiB | 2434 KiB | +0.0% |
| keyed-reverse/memory/teardown | 1 KiB | 1 KiB | — |
| keyed-reverse/plain | 1.11 ms | 1.21 ms | -33.2% |
| keyed-rotate/compose | 2.43 ms | 2.78 ms | -22.3% |
| keyed-rotate/memory/mounted | 2433 KiB | 2433 KiB | +0.0% |
| keyed-rotate/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-rotate/plain | 1.07 ms | 1.37 ms | -26.6% |
| keyed-shuffle/compose | 2.37 ms | 2.54 ms | -24.9% |
| keyed-shuffle/memory/mounted | 2425 KiB | 2425 KiB | -0.3% |
| keyed-shuffle/memory/teardown | 0 KiB | 0 KiB | — |
| keyed-shuffle/plain | 1.14 ms | 1.25 ms | -24.0% |
| mount-cycles/compose | 25.50 ms | 26.83 ms | +8.5% |
| mount-cycles/memory/mounted | 0 KiB | 0 KiB | -100.0% |
| mount-cycles/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| mount-cycles/plain | 15.56 ms | 23.48 ms | -27.0% |
| mount-dispose/compose | 10.06 ms | 12.21 ms | +17.2% |
| mount-dispose/memory/mounted | 1 KiB | 1 KiB | — |
| mount-dispose/memory/teardown | 0 KiB | 0 KiB | — |
| mount-dispose/plain | 7.42 ms | 10.22 ms | -7.6% |
| ordered-window-scroll/compose | 255.9 µs | 266.6 µs | +21.8% |
| ordered-window-scroll/memory/mounted | 1191 KiB | 1191 KiB | +0.0% |
| ordered-window-scroll/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| projection-keyed-append-500/compose | 7.97 ms | 10.03 ms | -37.4% |
| projection-keyed-append-500/memory/mounted | 3426 KiB | 3426 KiB | +0.2% |
| projection-keyed-append-500/memory/teardown | 0 KiB | 0 KiB | — |
| projection-keyed-append-500/plain | 2.49 ms | 3.29 ms | +6.2% |
| projection-observe-100/compose | 1.42 ms | 2.22 ms | +27.3% |
| projection-observe-100/memory/mounted | 74 KiB | 74 KiB | +0.0% |
| projection-observe-100/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| projection-selection-500/compose | 1.32 ms | 1.37 ms | -4.9% |
| projection-selection-500/memory/mounted | 4342 KiB | 4342 KiB | -0.5% |
| projection-selection-500/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| projection-selection-500/plain | 174.6 µs | 176.2 µs | -5.9% |
| scene-2d.extreme/compose/burst | 27.15 ms | 35.33 ms | -11.2% |
| scene-2d.extreme/compose/cold | 10.17 ms | 19.02 ms | -6.3% |
| scene-2d.extreme/compose/counts | 195.20 ms | 195.20 ms | -11.5% |
| scene-2d.extreme/compose/settle | 1.5 µs | 1.8 µs | -28.8% |
| scene-2d.extreme/compose/steady | 86.40 ms | 100.96 ms | -9.4% |
| scene-2d.extreme/compose/teardown | 1.11 ms | 1.27 ms | -23.0% |
| scene-2d.extreme/memory/mounted | 10299 KiB | 10299 KiB | -0.1% |
| scene-2d.extreme/memory/teardown | 0 KiB | 0 KiB | — |
| scene-2d.extreme/plain/burst | 8.01 ms | 10.23 ms | -29.9% |
| scene-2d.extreme/plain/cold | 1.89 ms | 3.00 ms | +13.8% |
| scene-2d.extreme/plain/settle | 1.0 µs | 1.6 µs | -54.1% |
| scene-2d.extreme/plain/steady | 52.36 ms | 58.31 ms | -0.1% |
| scene-2d.extreme/plain/teardown | 500.9 µs | 672.5 µs | -21.7% |
| scene-2d.large/compose/burst | 29.19 ms | 38.62 ms | +3.0% |
| scene-2d.large/compose/cold | 5.56 ms | 8.87 ms | +10.4% |
| scene-2d.large/compose/counts | 199.29 ms | 199.29 ms | +20.8% |
| scene-2d.large/compose/settle | 2.2 µs | 3.2 µs | -4.3% |
| scene-2d.large/compose/steady | 91.65 ms | 99.40 ms | +17.3% |
| scene-2d.large/compose/teardown | 1.34 ms | 1.93 ms | +18.4% |
| scene-2d.large/memory/mounted | 4330 KiB | 4330 KiB | -0.5% |
| scene-2d.large/memory/teardown | 9 KiB | 9 KiB | +12.5% |
| scene-2d.large/plain/burst | 9.59 ms | 14.35 ms | +12.3% |
| scene-2d.large/plain/cold | 2.27 ms | 5.82 ms | +4.6% |
| scene-2d.large/plain/settle | 1.8 µs | 2.4 µs | -12.9% |
| scene-2d.large/plain/steady | 55.15 ms | 59.34 ms | +16.2% |
| scene-2d.large/plain/teardown | 604.4 µs | 1.01 ms | +6.7% |
| scene-2d.medium/compose/burst | 21.80 ms | 25.96 ms | -7.1% |
| scene-2d.medium/compose/cold | 3.55 ms | 5.42 ms | -9.3% |
| scene-2d.medium/compose/counts | 144.62 ms | 144.62 ms | -8.1% |
| scene-2d.medium/compose/settle | 1.1 µs | 1.6 µs | -34.4% |
| scene-2d.medium/compose/steady | 66.83 ms | 70.13 ms | -1.9% |
| scene-2d.medium/compose/teardown | 851.7 µs | 1.12 ms | -24.5% |
| scene-2d.medium/memory/mounted | 2407 KiB | 2407 KiB | -1.1% |
| scene-2d.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| scene-2d.medium/plain/burst | 5.72 ms | 9.59 ms | -31.7% |
| scene-2d.medium/plain/cold | 1.90 ms | 2.22 ms | +32.5% |
| scene-2d.medium/plain/settle | 0.8 µs | 1.2 µs | -47.4% |
| scene-2d.medium/plain/steady | 39.76 ms | 41.09 ms | -3.0% |
| scene-2d.medium/plain/teardown | 408.1 µs | 759.6 µs | -16.8% |
| scene-3d/compose | 7.81 ms | 9.58 ms | -16.1% |
| scene-3d/memory/mounted | 1382 KiB | 1382 KiB | +0.0% |
| scene-3d/memory/teardown | 0 KiB | 0 KiB | — |
| scene-3d/plain | 3.45 ms | 4.16 ms | -19.5% |
| session-cycle.extreme/compose/burst | 112.91 ms | 172.42 ms | -24.9% |
| session-cycle.extreme/compose/cold | 4.1 µs | 6.5 µs | -13.2% |
| session-cycle.extreme/compose/counts | 373.77 ms | 373.77 ms | +0.3% |
| session-cycle.extreme/compose/settle | 2.0 µs | 2.3 µs | -10.3% |
| session-cycle.extreme/compose/steady | 187.71 ms | 233.32 ms | -4.0% |
| session-cycle.extreme/compose/teardown | 2.2 µs | 2.9 µs | -18.0% |
| session-cycle.extreme/memory/mounted | 10 KiB | 10 KiB | +400.0% |
| session-cycle.extreme/memory/teardown | 9 KiB | 9 KiB | +800.0% |
| session-cycle.extreme/plain/burst | 109.39 ms | 155.85 ms | -24.7% |
| session-cycle.extreme/plain/cold | 4.4 µs | 9.9 µs | -9.0% |
| session-cycle.extreme/plain/settle | 2.0 µs | 2.4 µs | -24.1% |
| session-cycle.extreme/plain/steady | 197.47 ms | 238.82 ms | +1.9% |
| session-cycle.extreme/plain/teardown | 1.9 µs | 2.5 µs | -37.2% |
| session-cycle.large/compose/burst | 38.10 ms | 61.79 ms | -20.3% |
| session-cycle.large/compose/cold | 3.8 µs | 6.5 µs | -18.7% |
| session-cycle.large/compose/counts | 128.31 ms | 128.31 ms | -6.6% |
| session-cycle.large/compose/settle | 1.9 µs | 2.3 µs | -12.7% |
| session-cycle.large/compose/steady | 75.89 ms | 88.26 ms | +3.0% |
| session-cycle.large/compose/teardown | 1.9 µs | 2.3 µs | -13.5% |
| session-cycle.large/memory/mounted | 2 KiB | 2 KiB | +0.0% |
| session-cycle.large/memory/teardown | 0 KiB | 0 KiB | — |
| session-cycle.large/plain/burst | 46.39 ms | 53.28 ms | -21.5% |
| session-cycle.large/plain/cold | 3.8 µs | 5.8 µs | -19.9% |
| session-cycle.large/plain/settle | 1.6 µs | 2.2 µs | -31.1% |
| session-cycle.large/plain/steady | 55.40 ms | 74.55 ms | -8.2% |
| session-cycle.large/plain/teardown | 1.6 µs | 2.2 µs | -22.7% |
| session-cycle.medium/compose/burst | 16.92 ms | 20.32 ms | +53.4% |
| session-cycle.medium/compose/cold | 4.1 µs | 6.7 µs | +20.2% |
| session-cycle.medium/compose/counts | 43.71 ms | 43.71 ms | +14.1% |
| session-cycle.medium/compose/settle | 2.3 µs | 2.7 µs | +37.6% |
| session-cycle.medium/compose/steady | 21.16 ms | 36.76 ms | -7.5% |
| session-cycle.medium/compose/teardown | 2.2 µs | 2.6 µs | +38.4% |
| session-cycle.medium/memory/mounted | 1 KiB | 1 KiB | +0.0% |
| session-cycle.medium/memory/teardown | 0 KiB | 0 KiB | — |
| session-cycle.medium/plain/burst | 10.84 ms | 18.87 ms | -11.4% |
| session-cycle.medium/plain/cold | 4.3 µs | 5.4 µs | +12.0% |
| session-cycle.medium/plain/settle | 1.5 µs | 4.0 µs | -13.3% |
| session-cycle.medium/plain/steady | 22.42 ms | 24.65 ms | +28.2% |
| session-cycle.medium/plain/teardown | 1.6 µs | 2.7 µs | +4.9% |
| spatial-scene.extreme/compose/burst | 140.51 ms | 155.71 ms | -2.6% |
| spatial-scene.extreme/compose/cold | 10.71 ms | 17.80 ms | -4.8% |
| spatial-scene.extreme/compose/counts | 236.33 ms | 236.33 ms | -9.2% |
| spatial-scene.extreme/compose/settle | 2.7 µs | 3.3 µs | +25.5% |
| spatial-scene.extreme/compose/steady | 47.16 ms | 60.88 ms | -20.6% |
| spatial-scene.extreme/compose/teardown | 5.55 ms | 6.90 ms | +16.8% |
| spatial-scene.extreme/memory/mounted | 6236 KiB | 6236 KiB | -11.3% |
| spatial-scene.extreme/memory/teardown | 257 KiB | 257 KiB | +25600.0% |
| spatial-scene.extreme/plain/burst | 61.84 ms | 72.08 ms | -0.5% |
| spatial-scene.extreme/plain/cold | 3.17 ms | 7.90 ms | -50.5% |
| spatial-scene.extreme/plain/settle | 3.3 µs | 4.0 µs | +15.1% |
| spatial-scene.extreme/plain/steady | 64.85 ms | 75.15 ms | -25.3% |
| spatial-scene.extreme/plain/teardown | 2.17 ms | 2.80 ms | -12.2% |
| spatial-scene.large/compose/burst | 36.09 ms | 40.58 ms | +4.9% |
| spatial-scene.large/compose/cold | 3.20 ms | 5.31 ms | -31.5% |
| spatial-scene.large/compose/counts | 71.66 ms | 71.66 ms | +5.2% |
| spatial-scene.large/compose/settle | 1.9 µs | 2.7 µs | -8.8% |
| spatial-scene.large/compose/steady | 18.22 ms | 20.55 ms | +0.2% |
| spatial-scene.large/compose/teardown | 849.6 µs | 1.09 ms | -6.2% |
| spatial-scene.large/memory/mounted | 1897 KiB | 1897 KiB | -0.3% |
| spatial-scene.large/memory/teardown | 1 KiB | 1 KiB | — |
| spatial-scene.large/plain/burst | 15.82 ms | 18.67 ms | +7.5% |
| spatial-scene.large/plain/cold | 1.16 ms | 2.26 ms | +21.2% |
| spatial-scene.large/plain/settle | 1.9 µs | 2.8 µs | +8.8% |
| spatial-scene.large/plain/steady | 23.45 ms | 25.52 ms | +7.3% |
| spatial-scene.large/plain/teardown | 321.8 µs | 448.0 µs | +6.7% |
| spatial-scene.medium/compose/burst | 8.43 ms | 11.11 ms | -35.9% |
| spatial-scene.medium/compose/cold | 858.7 µs | 1.46 ms | -32.9% |
| spatial-scene.medium/compose/counts | 22.20 ms | 22.20 ms | -27.1% |
| spatial-scene.medium/compose/settle | 1.0 µs | 1.0 µs | -17.2% |
| spatial-scene.medium/compose/steady | 7.01 ms | 8.29 ms | -29.6% |
| spatial-scene.medium/compose/teardown | 232.2 µs | 255.9 µs | -21.4% |
| spatial-scene.medium/memory/mounted | 756 KiB | 756 KiB | -0.3% |
| spatial-scene.medium/memory/teardown | 0 KiB | 0 KiB | — |
| spatial-scene.medium/plain/burst | 3.52 ms | 4.95 ms | -22.8% |
| spatial-scene.medium/plain/cold | 335.6 µs | 1.08 ms | -20.5% |
| spatial-scene.medium/plain/settle | 0.7 µs | 0.9 µs | -10.4% |
| spatial-scene.medium/plain/steady | 7.14 ms | 7.94 ms | -22.5% |
| spatial-scene.medium/plain/teardown | 78.0 µs | 156.0 µs | -25.6% |
| status-panel/compose | 451.0 µs | 495.5 µs | -30.5% |
| status-panel/memory/mounted | 52 KiB | 52 KiB | +0.0% |
| status-panel/memory/teardown | 0 KiB | 0 KiB | — |
| status-panel/plain | 209.7 µs | 345.5 µs | -12.2% |
| unwind/compose | 3.80 ms | 5.25 ms | -27.5% |
| unwind/memory/mounted | 1 KiB | 1 KiB | — |
| unwind/memory/teardown | 0 KiB | 0 KiB | — |
| unwind/plain | 3.72 ms | 5.41 ms | -5.4% |
| update-batched/compose | 2.90 ms | 3.08 ms | +4.4% |
| update-batched/memory/mounted | 1991 KiB | 1991 KiB | -0.7% |
| update-batched/memory/teardown | 0 KiB | 0 KiB | — |
| update-batched/plain | 1.01 ms | 1.14 ms | -0.8% |
| update-fanout/compose | 1.08 ms | 1.14 ms | -30.9% |
| update-fanout/memory/mounted | 1934 KiB | 1934 KiB | -0.7% |
| update-fanout/memory/teardown | 0 KiB | 0 KiB | — |
| update-fanout/plain | 657.1 µs | 673.3 µs | -35.2% |
| update-leaf/compose | 45.2 µs | 55.2 µs | +17.7% |
| update-leaf/memory/mounted | 2955 KiB | 2955 KiB | -0.3% |
| update-leaf/memory/teardown | 0 KiB | 0 KiB | — |
| update-leaf/plain | 22.0 µs | 26.6 µs | +33.3% |
| update-repeated/compose | 256.5 µs | 283.3 µs | -1.4% |
| update-repeated/memory/mounted | 18 KiB | 18 KiB | +5.9% |
| update-repeated/memory/teardown | 1 KiB | 1 KiB | +0.0% |
| update-repeated/plain | 40.8 µs | 41.4 µs | -10.1% |
| virtual-filtered-list.extreme/compose/burst | 643.34 ms | 671.36 ms | -14.8% |
| virtual-filtered-list.extreme/compose/cold | 386.26 ms | 425.88 ms | -14.2% |
| virtual-filtered-list.extreme/compose/counts | 1025.44 ms | 1025.44 ms | -15.4% |
| virtual-filtered-list.extreme/compose/settle | 2.4 µs | 11.0 µs | +17.3% |
| virtual-filtered-list.extreme/compose/steady | 8.34 ms | 14.38 ms | -37.2% |
| virtual-filtered-list.extreme/compose/teardown | 463.4 µs | 814.9 µs | -14.9% |
| virtual-filtered-list.extreme/memory/mounted | 29174 KiB | 29174 KiB | -0.5% |
| virtual-filtered-list.extreme/memory/teardown | 16 KiB | 16 KiB | -5.9% |
| virtual-filtered-list.extreme/plain/burst | 590.67 ms | 599.79 ms | -14.8% |
| virtual-filtered-list.extreme/plain/cold | 369.15 ms | 376.35 ms | -15.8% |
| virtual-filtered-list.extreme/plain/settle | 2.8 µs | 11.3 µs | +15.7% |
| virtual-filtered-list.extreme/plain/steady | 9.23 ms | 15.09 ms | -14.3% |
| virtual-filtered-list.extreme/plain/teardown | 148.5 µs | 214.7 µs | -19.2% |
| virtual-filtered-list.large/compose/burst | 79.69 ms | 82.65 ms | -34.4% |
| virtual-filtered-list.large/compose/cold | 46.70 ms | 50.56 ms | -37.5% |
| virtual-filtered-list.large/compose/counts | 134.95 ms | 134.95 ms | -37.9% |
| virtual-filtered-list.large/compose/settle | 2.4 µs | 3.4 µs | +56.6% |
| virtual-filtered-list.large/compose/steady | 6.15 ms | 11.44 ms | -53.5% |
| virtual-filtered-list.large/compose/teardown | 199.6 µs | 275.3 µs | -41.9% |
| virtual-filtered-list.large/memory/mounted | 6582 KiB | 6582 KiB | +0.0% |
| virtual-filtered-list.large/memory/teardown | 8 KiB | 8 KiB | — |
| virtual-filtered-list.large/plain/burst | 68.29 ms | 72.45 ms | -38.6% |
| virtual-filtered-list.large/plain/cold | 42.92 ms | 44.33 ms | -37.8% |
| virtual-filtered-list.large/plain/settle | 2.2 µs | 2.8 µs | +55.3% |
| virtual-filtered-list.large/plain/steady | 5.41 ms | 7.35 ms | -26.8% |
| virtual-filtered-list.large/plain/teardown | 68.3 µs | 209.2 µs | -37.8% |
| virtual-filtered-list.medium/compose/burst | 26.03 ms | 30.90 ms | +21.7% |
| virtual-filtered-list.medium/compose/cold | 12.41 ms | 15.95 ms | +15.4% |
| virtual-filtered-list.medium/compose/counts | 58.24 ms | 58.24 ms | +14.5% |
| virtual-filtered-list.medium/compose/settle | 2.2 µs | 4.9 µs | +24.5% |
| virtual-filtered-list.medium/compose/steady | 9.88 ms | 14.81 ms | -5.2% |
| virtual-filtered-list.medium/compose/teardown | 212.9 µs | 373.3 µs | +19.5% |
| virtual-filtered-list.medium/memory/mounted | 1697 KiB | 1697 KiB | -0.5% |
| virtual-filtered-list.medium/memory/teardown | 0 KiB | 0 KiB | -100.0% |
| virtual-filtered-list.medium/plain/burst | 19.28 ms | 21.93 ms | +15.6% |
| virtual-filtered-list.medium/plain/cold | 11.23 ms | 13.65 ms | +14.7% |
| virtual-filtered-list.medium/plain/settle | 1.6 µs | 2.5 µs | +6.0% |
| virtual-filtered-list.medium/plain/steady | 6.65 ms | 7.40 ms | +5.5% |
| virtual-filtered-list.medium/plain/teardown | 63.8 µs | 171.1 µs | +3.5% |

## Trends over the last 2 main commits

```mermaid
xychart-beta
    title "animate-many/compose (median µs)"
    x-axis 1 --> 2
    line [7066.0, 5543.7]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [7973.4, 4469.2]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [10165.4, 9216.8]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [82802.3, 50581.5]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.0, 1.4]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [35005.4, 18632.4]
```

```mermaid
xychart-beta
    title "animated-navigation.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [2433.2, 2448.0]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [3977.2, 3224.9]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [5290.3, 4827.2]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [67246.0, 49519.1]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.2, 1.5]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [27760.5, 21861.1]
```

```mermaid
xychart-beta
    title "animated-navigation.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1322.6, 1369.8]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [1323.9, 1003.8]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [1476.2, 1252.8]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [23867.1, 19387.9]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.6, 0.5]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [10761.6, 7884.6]
```

```mermaid
xychart-beta
    title "animated-navigation.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [324.9, 265.1]
```

```mermaid
xychart-beta
    title "branch-swap/compose (median µs)"
    x-axis 1 --> 2
    line [4364.7, 4110.5]
```

```mermaid
xychart-beta
    title "cold-mount-100/compose (median µs)"
    x-axis 1 --> 2
    line [711.2, 800.6]
```

```mermaid
xychart-beta
    title "cold-mount-1000/compose (median µs)"
    x-axis 1 --> 2
    line [7902.9, 7477.1]
```

```mermaid
xychart-beta
    title "cold-mount-10000/compose (median µs)"
    x-axis 1 --> 2
    line [78609.4, 92594.9]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [1000995.4, 649605.7]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [577895.2, 378612.6]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [1654603.7, 1079198.6]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.4, 2.3]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [15779.8, 10502.8]
```

```mermaid
xychart-beta
    title "data-grid.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1548.2, 1027.8]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [154890.4, 128444.6]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [85427.7, 67633.1]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [239021.5, 215132.1]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.3, 2.6]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [12579.7, 10061.1]
```

```mermaid
xychart-beta
    title "data-grid.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [645.5, 560.0]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [60973.5, 38031.4]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [34661.7, 22286.8]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [118514.1, 79511.4]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.2, 1.7]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [11085.7, 7253.2]
```

```mermaid
xychart-beta
    title "data-grid.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [321.2, 197.5]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [14803.3, 14614.1]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [494.7, 460.2]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [24076.5, 20102.2]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.9, 1.4]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [898.5, 738.2]
```

```mermaid
xychart-beta
    title "dense-dashboard.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [505.0, 483.9]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [9267.5, 7649.3]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [364.9, 363.0]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [17186.9, 15138.1]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.2, 1.3]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [900.6, 740.9]
```

```mermaid
xychart-beta
    title "dense-dashboard.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [293.1, 268.3]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [2903.0, 2205.0]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [235.7, 151.9]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [6235.9, 4301.7]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.7, 0.5]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [900.7, 721.7]
```

```mermaid
xychart-beta
    title "dense-dashboard.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [129.6, 93.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [43944.8, 49652.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [24318.3, 29383.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [171957.2, 186039.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.5, 2.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [55777.6, 53577.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1166.2, 1250.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [14223.9, 10112.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [10085.2, 8093.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [61324.7, 43273.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.3, 2.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [17757.5, 11250.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [402.0, 334.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [6598.0, 5759.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [5533.0, 4973.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [36821.5, 27186.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.0, 0.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [8122.5, 6013.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-10.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [209.9, 162.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [43856.4, 30819.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [35272.0, 22316.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [299395.8, 224918.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.0, 2.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [138828.9, 114442.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1113.1, 1008.7]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [14799.5, 16107.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [9959.0, 11012.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [108575.7, 122392.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.4, 2.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [54663.7, 53686.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [426.8, 468.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [9587.3, 8032.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [7363.0, 4577.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [66811.1, 53620.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.0, 2.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [30611.6, 24331.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn-50.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [343.8, 275.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [56918.5, 57816.9]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [37585.3, 33439.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [299971.8, 290261.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.2, 2.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [111100.1, 98602.0]
```

```mermaid
xychart-beta
    title "entities-identity-churn.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1695.6, 1492.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [14579.0, 10613.4]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [11822.7, 8962.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [106981.6, 68152.6]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.1, 1.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [32130.3, 24615.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [444.3, 312.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [7886.3, 5951.2]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [4741.2, 4034.3]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [39739.3, 28322.1]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.9, 1.8]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [13505.6, 10554.5]
```

```mermaid
xychart-beta
    title "entities-identity-churn.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [219.7, 209.5]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [21545.6, 16593.9]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [108357.4, 97604.6]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [380852.7, 318600.3]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.1, 1.6]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [108117.0, 86268.3]
```

```mermaid
xychart-beta
    title "entities-integrated.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [58095.6, 47581.7]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [12272.4, 8336.9]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [44369.0, 37505.6]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [167975.4, 156757.3]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.9, 2.2]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [59586.7, 47559.2]
```

```mermaid
xychart-beta
    title "entities-integrated.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [20125.3, 18784.0]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [7716.5, 5306.9]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [21813.3, 15408.9]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [115027.8, 65603.9]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.9, 1.1]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [43725.5, 23670.9]
```

```mermaid
xychart-beta
    title "entities-integrated.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [8434.1, 5180.9]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [68538.4, 64651.8]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [30533.7, 18067.7]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [214046.5, 183672.4]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.7, 2.8]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [40959.9, 41895.2]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [12574.4, 12110.7]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [25138.0, 29117.1]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [11042.2, 9049.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [93732.8, 86681.3]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.4, 2.9]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [15319.7, 16098.0]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [2935.6, 4085.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [11385.0, 12950.9]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [4668.4, 5256.4]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [35454.1, 40535.5]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.8, 1.7]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [7724.8, 9185.6]
```

```mermaid
xychart-beta
    title "entities-relevance-saturated.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1145.7, 1272.3]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [140397.7, 148326.6]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [25019.6, 33925.3]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [373375.2, 386115.4]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.6, 2.7]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [121050.5, 127031.9]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [15043.8, 16492.8]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [41078.1, 34277.5]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [10292.0, 7577.0]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [127397.4, 84635.3]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.6, 2.2]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [43098.3, 26645.0]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [3211.8, 2923.8]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [22636.1, 18106.0]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [6971.5, 6940.3]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [70724.6, 62309.9]
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
    line [21462.4, 18406.4]
```

```mermaid
xychart-beta
    title "entities-relevance-sweep.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1468.9, 1088.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [35492.8, 38602.6]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [25381.9, 25373.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [109609.2, 119787.4]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.2, 3.1]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [4326.5, 4520.8]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [14348.5, 15324.6]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [14055.7, 10898.0]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [9940.6, 12355.7]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [47881.0, 46492.0]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.8, 1.7]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [2208.7, 1616.4]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [4892.3, 4018.5]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [5473.9, 4110.7]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [4287.2, 4624.6]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [19123.3, 18176.0]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.9, 1.2]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [863.8, 726.5]
```

```mermaid
xychart-beta
    title "entity-labels-sparse.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1391.5, 1238.5]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [35946.3, 27146.4]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [28235.2, 27816.7]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [154106.7, 124071.9]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.4, 1.6]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [34056.0, 30224.5]
```

```mermaid
xychart-beta
    title "entity-labels.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [14673.6, 12207.9]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [17732.3, 15097.1]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [16897.1, 13038.8]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [71479.3, 68708.5]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.2, 2.4]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [18561.6, 12725.0]
```

```mermaid
xychart-beta
    title "entity-labels.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [5599.3, 5261.8]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [5689.1, 5080.1]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [5193.7, 4689.2]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [26376.9, 24044.1]
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
    line [6834.0, 6284.3]
```

```mermaid
xychart-beta
    title "entity-labels.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1516.4, 1367.4]
```

```mermaid
xychart-beta
    title "events/compose (median µs)"
    x-axis 1 --> 2
    line [12197.4, 14827.2]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [8488.5, 5878.7]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [19992.7, 17445.9]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [33878.1, 35074.4]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.9, 1.9]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [217.2, 231.3]
```

```mermaid
xychart-beta
    title "inspector.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [2387.5, 2847.7]
```

```mermaid
xychart-beta
    title "inspector.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [3280.9, 4437.2]
```

```mermaid
xychart-beta
    title "inspector.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [7897.4, 8389.0]
```

```mermaid
xychart-beta
    title "inspector.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [15822.8, 17748.2]
```

```mermaid
xychart-beta
    title "inspector.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.4, 1.0]
```

```mermaid
xychart-beta
    title "inspector.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [189.5, 217.6]
```

```mermaid
xychart-beta
    title "inspector.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1237.9, 1247.6]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [1527.7, 1183.3]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [2017.3, 1670.7]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [5005.1, 3727.9]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [0.6, 0.5]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [192.2, 151.9]
```

```mermaid
xychart-beta
    title "inspector.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [405.5, 357.7]
```

```mermaid
xychart-beta
    title "keyed-append/compose (median µs)"
    x-axis 1 --> 2
    line [1388.4, 1121.1]
```

```mermaid
xychart-beta
    title "keyed-insert/compose (median µs)"
    x-axis 1 --> 2
    line [2947.2, 2067.9]
```

```mermaid
xychart-beta
    title "keyed-prepend/compose (median µs)"
    x-axis 1 --> 2
    line [4310.0, 2715.8]
```

```mermaid
xychart-beta
    title "keyed-remove/compose (median µs)"
    x-axis 1 --> 2
    line [2195.4, 2629.4]
```

```mermaid
xychart-beta
    title "keyed-replace/compose (median µs)"
    x-axis 1 --> 2
    line [62427.3, 55411.9]
```

```mermaid
xychart-beta
    title "keyed-reverse/compose (median µs)"
    x-axis 1 --> 2
    line [3260.2, 2310.3]
```

```mermaid
xychart-beta
    title "keyed-rotate/compose (median µs)"
    x-axis 1 --> 2
    line [3123.4, 2426.1]
```

```mermaid
xychart-beta
    title "keyed-shuffle/compose (median µs)"
    x-axis 1 --> 2
    line [3153.5, 2368.2]
```

```mermaid
xychart-beta
    title "mount-cycles/compose (median µs)"
    x-axis 1 --> 2
    line [23507.6, 25502.7]
```

```mermaid
xychart-beta
    title "mount-dispose/compose (median µs)"
    x-axis 1 --> 2
    line [8589.5, 10063.8]
```

```mermaid
xychart-beta
    title "ordered-window-scroll/compose (median µs)"
    x-axis 1 --> 2
    line [210.1, 255.9]
```

```mermaid
xychart-beta
    title "projection-keyed-append-500/compose (median µs)"
    x-axis 1 --> 2
    line [12737.8, 7972.3]
```

```mermaid
xychart-beta
    title "projection-observe-100/compose (median µs)"
    x-axis 1 --> 2
    line [1114.2, 1418.0]
```

```mermaid
xychart-beta
    title "projection-selection-500/compose (median µs)"
    x-axis 1 --> 2
    line [1383.2, 1315.4]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [30587.6, 27153.8]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [10856.9, 10168.8]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [220548.6, 195202.9]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.1, 1.5]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [95344.4, 86399.7]
```

```mermaid
xychart-beta
    title "scene-2d.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1440.2, 1108.3]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [28331.7, 29194.4]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [5033.3, 5556.1]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [164944.4, 199293.7]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.3, 2.2]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [78144.2, 91648.4]
```

```mermaid
xychart-beta
    title "scene-2d.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1131.9, 1340.4]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [23453.3, 21799.1]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [3916.3, 3552.1]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [157341.3, 144619.5]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.6, 1.1]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [68137.6, 66827.8]
```

```mermaid
xychart-beta
    title "scene-2d.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1127.7, 851.7]
```

```mermaid
xychart-beta
    title "scene-3d/compose (median µs)"
    x-axis 1 --> 2
    line [9311.5, 7812.6]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [150273.0, 112911.0]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [4.7, 4.1]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [372778.1, 373769.6]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.2, 2.0]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [195514.6, 187714.9]
```

```mermaid
xychart-beta
    title "session-cycle.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [2.7, 2.2]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [47787.7, 38098.6]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [4.7, 3.8]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [137328.3, 128306.1]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.1, 1.9]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [73648.7, 75887.3]
```

```mermaid
xychart-beta
    title "session-cycle.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [2.2, 1.9]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [11026.1, 16918.2]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [3.4, 4.1]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [38312.0, 43711.1]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.6, 2.3]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [22879.8, 21158.9]
```

```mermaid
xychart-beta
    title "session-cycle.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [1.6, 2.2]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [144191.5, 140514.2]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [11248.1, 10707.8]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [260366.7, 236326.5]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.2, 2.7]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [59382.1, 47163.0]
```

```mermaid
xychart-beta
    title "spatial-scene.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [4749.9, 5546.4]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [34412.2, 36085.4]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [4669.2, 3198.3]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [68108.7, 71660.9]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.1, 1.9]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [18186.3, 18219.7]
```

```mermaid
xychart-beta
    title "spatial-scene.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [905.4, 849.6]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [13158.0, 8429.4]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [1280.2, 858.7]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [30461.1, 22198.7]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.2, 1.0]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [9951.3, 7008.1]
```

```mermaid
xychart-beta
    title "spatial-scene.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [295.6, 232.2]
```

```mermaid
xychart-beta
    title "status-panel/compose (median µs)"
    x-axis 1 --> 2
    line [648.8, 451.0]
```

```mermaid
xychart-beta
    title "unwind/compose (median µs)"
    x-axis 1 --> 2
    line [5245.3, 3804.5]
```

```mermaid
xychart-beta
    title "update-batched/compose (median µs)"
    x-axis 1 --> 2
    line [2780.0, 2903.7]
```

```mermaid
xychart-beta
    title "update-fanout/compose (median µs)"
    x-axis 1 --> 2
    line [1566.5, 1082.5]
```

```mermaid
xychart-beta
    title "update-leaf/compose (median µs)"
    x-axis 1 --> 2
    line [38.4, 45.2]
```

```mermaid
xychart-beta
    title "update-repeated/compose (median µs)"
    x-axis 1 --> 2
    line [260.3, 256.5]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/burst (median µs)"
    x-axis 1 --> 2
    line [755372.8, 643335.3]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/cold (median µs)"
    x-axis 1 --> 2
    line [450019.9, 386255.9]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/counts (median µs)"
    x-axis 1 --> 2
    line [1211615.7, 1025435.3]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/settle (median µs)"
    x-axis 1 --> 2
    line [2.1, 2.4]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/steady (median µs)"
    x-axis 1 --> 2
    line [13279.0, 8339.0]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.extreme/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [544.4, 463.4]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/burst (median µs)"
    x-axis 1 --> 2
    line [121470.1, 79686.1]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/cold (median µs)"
    x-axis 1 --> 2
    line [74703.0, 46699.4]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/counts (median µs)"
    x-axis 1 --> 2
    line [217228.4, 134954.8]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.5, 2.4]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/steady (median µs)"
    x-axis 1 --> 2
    line [13239.5, 6151.5]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.large/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [343.3, 199.6]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/burst (median µs)"
    x-axis 1 --> 2
    line [21378.5, 26026.2]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/cold (median µs)"
    x-axis 1 --> 2
    line [10758.2, 12413.2]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/counts (median µs)"
    x-axis 1 --> 2
    line [50886.2, 58244.0]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/settle (median µs)"
    x-axis 1 --> 2
    line [1.8, 2.2]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/steady (median µs)"
    x-axis 1 --> 2
    line [10427.3, 9883.8]
```

```mermaid
xychart-beta
    title "virtual-filtered-list.medium/compose/teardown (median µs)"
    x-axis 1 --> 2
    line [178.1, 212.9]
```
