# Framework comparison

This page records measurements of Compose and other Roblox UI libraries on the same 24 runtime workloads.

- Compose commit: `99df90e` (main, 2026-10-28)
- Run: [Framework comparison #40615017433](https://github.com/voidmeld/compose/actions/runs/40615017433) on the GitHub-hosted Ubuntu runner
- Mode: as-shipped. Verdict: release. Only passed measurements appear in the table.
- Method: [Manual framework comparison](benchmarks.md#manual-framework-comparison). Each library is measured as it ships: Compose runs native code because it ships `--!native`, and the other libraries run as they ship. Each worker loads each library one time and warms it, collects garbage before each sample, rotates lane order and runs Compose through the same comparison driver as the other libraries. The workloads `ordered-window-scroll`, `unwind`, `update-repeated` and `status-panel` measure Compose contracts. Leave them out of a summary count; see [Workloads with Compose contracts](benchmarks.md#workloads-with-compose-contracts). The workflow runs the parity checks before timing, and both are headless cost-model measurements. They do not measure Roblox engine rendering.
- Control lanes: `compose-direct` runs the direct Compose cases without the comparison driver, so the difference to `compose` is the driver cost. `react-usestate` runs only `update-repeated` with React state, which merges writes; the `react` lane uses bindings in every workload.

Each ratio divides a measurement by the Compose measurement. A value below 1.00x is smaller. To update this record, run the workflow again. Then replace this page with its results.

Headless cost-model samples. Time is per complete workload sample, including its iteration count. Ratios divide by Compose; lower is smaller. Heap is the mounted retained Luau estimate. Writes, Created, Connections and Deferred count the engine property writes, instances, signal connections and deferred tasks of the timed iterations. A zero heap baseline has no ratio. These results do not measure Roblox engine performance.

| Workload | Iterations | Framework | Median time (us) | / Compose | Median heap (KiB) | / Compose | Teardown (KiB) | Writes | Created | Connections | Deferred |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| cold-mount-100 | 1 | bare | 538.169 | 0.86x | 555.000 | 0.99x | 0.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | compose | 623.669 | 1.00x | 558.000 | 1.00x | 0.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | compose-direct | 734.021 | 1.18x | 558.000 | 1.00x | 0.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | fusion | 1064.051 | 1.71x | 564.000 | 1.01x | 1.000 | 803 | 101 | 0 | 0 |
| cold-mount-100 | 1 | vide | 935.195 | 1.50x | 547.000 | 0.98x | 0.000 | 703 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react | 930.108 | 1.49x | 606.000 | 1.09x | 1.000 | 200 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| cold-mount-100 | 1 | blend | 1171.663 | 1.88x | 693.000 | 1.24x | 0.000 | 803 | 101 | 0 | 0 |
| cold-mount-100 | 1 | roact | 981.305 | 1.57x | 654.000 | 1.17x | 0.000 | 201 | 101 | 0 | 0 |
| cold-mount-100 | 1 | seam | 853.542 | 1.37x | 577.000 | 1.03x | 1.000 | 100 | 101 | 1 | 0 |
| cold-mount-100 | 1 | signals | 793.636 | 1.27x | 559.000 | 1.00x | 1.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react-reflex | 1061.607 | 1.70x | 606.000 | 1.09x | 1.000 | 200 | 101 | 0 | 0 |
| cold-mount-100 | 1 | fusion-charm | 880.598 | 1.41x | 563.000 | 1.01x | 0.000 | 803 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react-upstream | 1169.059 | 1.87x | 606.000 | 1.09x | 1.000 | 200 | 101 | 0 | 0 |
| cold-mount-1000 | 1 | bare | 6887.844 | 1.16x | 5485.000 | 1.00x | 0.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | compose | 5915.007 | 1.00x | 5480.000 | 1.00x | 0.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | compose-direct | 6131.219 | 1.04x | 5480.000 | 1.00x | 0.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | fusion | 7611.790 | 1.29x | 5535.000 | 1.01x | 0.000 | 8003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | vide | 7453.375 | 1.26x | 5470.000 | 1.00x | 0.000 | 7003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react | 13127.768 | 2.22x | 5978.000 | 1.09x | 1.000 | 2000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| cold-mount-1000 | 1 | blend | 14697.168 | 2.48x | 6824.000 | 1.25x | 0.000 | 8003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | roact | 10388.317 | 1.76x | 6452.000 | 1.18x | 8.000 | 2001 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | seam | 8718.184 | 1.47x | 5547.000 | 1.01x | 0.000 | 1000 | 1001 | 1 | 0 |
| cold-mount-1000 | 1 | signals | 7825.338 | 1.32x | 5509.000 | 1.01x | 8.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react-reflex | 12595.377 | 2.13x | 5970.000 | 1.09x | 0.000 | 2000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | fusion-charm | 9796.245 | 1.66x | 5535.000 | 1.01x | 8.000 | 8003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react-upstream | 11796.609 | 1.99x | 5986.000 | 1.09x | 1.000 | 2000 | 1001 | 0 | 0 |
| cold-mount-10000 | 1 | bare | 61172.961 | 0.81x | 54973.000 | 1.00x | 0.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | compose | 75072.928 | 1.00x | 55074.000 | 1.00x | 0.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | compose-direct | 102307.762 | 1.36x | 55067.000 | 1.00x | 1.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | fusion | 99438.386 | 1.32x | 55730.000 | 1.01x | 0.000 | 80003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | vide | 89220.428 | 1.19x | 54825.000 | 1.00x | 0.000 | 70003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react | 141419.290 | 1.88x | 59828.000 | 1.09x | 1.000 | 20000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| cold-mount-10000 | 1 | blend | 151883.528 | 2.02x | 68384.000 | 1.24x | 0.000 | 80003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | roact | 118543.628 | 1.58x | 64695.000 | 1.17x | 0.000 | 20001 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | seam | 91743.360 | 1.22x | 55973.000 | 1.02x | 0.000 | 10000 | 10001 | 1 | 0 |
| cold-mount-10000 | 1 | signals | 65379.383 | 0.87x | 55285.000 | 1.00x | 0.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react-reflex | 128754.339 | 1.72x | 59828.000 | 1.09x | 9.000 | 20000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | fusion-charm | 102090.720 | 1.36x | 55714.000 | 1.01x | 0.000 | 80003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react-upstream | 128885.686 | 1.72x | 59828.000 | 1.09x | 1.000 | 20000 | 10001 | 0 | 0 |
| mount-dispose | 5 | bare | 6647.110 | 0.93x | 1.000 | 1.00x | 1.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | compose | 7142.218 | 1.00x | 1.000 | 1.00x | 0.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | compose-direct | 7129.925 | 1.00x | 0.000 | 0.00x | 0.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | fusion | 8112.587 | 1.14x | 1.000 | 1.00x | 1.000 | 8015 | 1005 | 0 | 0 |
| mount-dispose | 5 | vide | 6153.703 | 0.86x | 1.000 | 1.00x | 1.000 | 7015 | 1005 | 0 | 0 |
| mount-dispose | 5 | react | 9359.508 | 1.31x | 0.000 | 0.00x | 0.000 | 2000 | 1005 | 0 | 0 |
| mount-dispose | 5 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| mount-dispose | 5 | blend | 13158.169 | 1.84x | 1.000 | 1.00x | 0.000 | 8015 | 1005 | 0 | 0 |
| mount-dispose | 5 | roact | 8331.428 | 1.17x | 1.000 | 1.00x | 0.000 | 2005 | 1005 | 0 | 0 |
| mount-dispose | 5 | seam | 6978.566 | 0.98x | 1.000 | 1.00x | 0.000 | 1000 | 1005 | 5 | 0 |
| mount-dispose | 5 | signals | 6084.615 | 0.85x | 1.000 | 1.00x | 0.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | react-reflex | 9923.131 | 1.39x | 4.000 | 4.00x | 0.000 | 2000 | 1005 | 0 | 0 |
| mount-dispose | 5 | fusion-charm | 8537.220 | 1.20x | 9.000 | 9.00x | 0.000 | 8015 | 1005 | 0 | 0 |
| mount-dispose | 5 | react-upstream | 9910.071 | 1.39x | 5.000 | 5.00x | 4.000 | 2000 | 1005 | 0 | 0 |
| update-leaf | 50 | bare | 18.533 | 0.34x | 2744.000 | 1.00x | 0.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | compose | 53.817 | 1.00x | 2755.000 | 1.00x | 0.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | compose-direct | 36.225 | 0.67x | 2755.000 | 1.00x | 0.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | fusion | 100.091 | 1.86x | 2772.000 | 1.01x | 0.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | vide | 58.118 | 1.08x | 2738.000 | 0.99x | 0.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react | 47.552 | 0.88x | 2994.000 | 1.09x | 1.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| update-leaf | 50 | blend | 61.618 | 1.14x | 3421.000 | 1.24x | 0.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | roact | 40.071 | 0.74x | 3238.000 | 1.18x | 0.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | seam | 93.637 | 1.74x | 2793.000 | 1.01x | 0.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | signals | 63.826 | 1.19x | 2762.000 | 1.00x | 1.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react-reflex | 91.544 | 1.70x | 2995.000 | 1.09x | 1.000 | 50 | 0 | 50 | 0 |
| update-leaf | 50 | fusion-charm | 201.064 | 3.74x | 2773.000 | 1.01x | 0.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react-upstream | 52.765 | 0.98x | 2994.000 | 1.09x | 1.000 | 50 | 0 | 0 | 0 |
| update-fanout | 20 | bare | 541.239 | 0.61x | 1651.000 | 0.92x | 0.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | compose | 892.240 | 1.00x | 1804.000 | 1.00x | 8.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | compose-direct | 885.379 | 0.99x | 1804.000 | 1.00x | 0.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | fusion | 5961.886 | 6.68x | 1894.000 | 1.05x | 0.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | vide | 2918.143 | 3.27x | 1815.000 | 1.01x | 1.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react | 993.242 | 1.11x | 1925.000 | 1.07x | 1.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| update-fanout | 20 | blend | 2587.433 | 2.90x | 2231.000 | 1.24x | 0.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | roact | 1384.605 | 1.55x | 2078.000 | 1.15x | 0.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | seam | 2307.771 | 2.59x | 2126.000 | 1.18x | 0.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | signals | 2773.235 | 3.11x | 1915.000 | 1.06x | 0.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react-reflex | 1026.622 | 1.15x | 1926.000 | 1.07x | 1.000 | 6000 | 0 | 20 | 0 |
| update-fanout | 20 | fusion-charm | 6297.235 | 7.06x | 1896.000 | 1.05x | 0.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react-upstream | 1066.573 | 1.20x | 1925.000 | 1.07x | 1.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | bare | 548.299 | 0.30x | 1651.000 | 0.84x | 0.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | compose | 1804.168 | 1.00x | 1957.000 | 1.00x | 0.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | compose-direct | 1520.019 | 0.84x | 1860.000 | 0.95x | 0.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | fusion | 8700.397 | 4.82x | 2129.000 | 1.09x | 0.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | vide | 3814.398 | 2.11x | 1960.000 | 1.00x | 0.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react | 1950.900 | 1.08x | 2096.000 | 1.07x | 1.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| update-batched | 20 | blend | 4496.681 | 2.49x | 2504.000 | 1.28x | 0.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | roact | 2786.615 | 1.54x | 2510.000 | 1.28x | 0.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | seam | 5613.581 | 3.11x | 2887.000 | 1.48x | 0.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | signals | 4621.761 | 2.56x | 2246.000 | 1.15x | 0.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react-reflex | 24001.934 | 13.30x | 2368.000 | 1.21x | 0.000 | 6000 | 0 | 20 | 0 |
| update-batched | 20 | fusion-charm | 17761.819 | 9.84x | 2703.000 | 1.38x | 0.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react-upstream | 2054.627 | 1.14x | 2096.000 | 1.07x | 0.000 | 6000 | 0 | 0 | 0 |
| update-repeated | 10 | bare | 23.886 | 0.13x | 14.000 | 0.82x | 0.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | compose | 181.795 | 1.00x | 17.000 | 1.00x | 1.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | compose-direct | 158.179 | 0.87x | 17.000 | 1.00x | 0.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | fusion | 16046.591 | 88.27x | 18.000 | 1.06x | 0.000 | 5000 | 0 | 0 | 0 |
| update-repeated | 10 | vide | 433.186 | 2.38x | 15.000 | 0.88x | 0.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | react | 1431.910 | 7.88x | 15.000 | 0.88x | 1.000 | 5000 | 0 | 0 | 0 |
| update-repeated | 10 | react-usestate | 7789.010 | 42.85x | 4.000 | 0.24x | 4.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | blend | 4353.875 | 23.95x | 21.000 | 1.24x | 1.000 | 10 | 0 | 0 | 10 |
| update-repeated | 10 | roact | 3366.101 | 18.52x | 18.000 | 1.06x | 0.000 | 5000 | 0 | 0 | 0 |
| update-repeated | 10 | seam | 2891.653 | 15.91x | 33.000 | 1.94x | 1.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | signals | 803.165 | 4.42x | 9.000 | 0.53x | 0.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | react-reflex | 1909.989 | 10.51x | 16.000 | 0.94x | 1.000 | 10 | 0 | 10 | 0 |
| update-repeated | 10 | fusion-charm | 1697.367 | 9.34x | 20.000 | 1.18x | 0.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | react-upstream | 1755.295 | 9.66x | 16.000 | 0.94x | 1.000 | 5000 | 0 | 0 | 0 |
| branch-swap | 20 | bare | 2538.679 | 0.78x | 20.000 | 0.62x | 0.000 | 500 | 510 | 0 | 0 |
| branch-swap | 20 | compose | 3236.856 | 1.00x | 32.000 | 1.00x | 0.000 | 500 | 510 | 0 | 0 |
| branch-swap | 20 | compose-direct | 3147.190 | 0.97x | 32.000 | 1.00x | 0.000 | 500 | 510 | 0 | 0 |
| branch-swap | 20 | fusion | 3888.421 | 1.20x | 32.000 | 1.00x | 0.000 | 4030 | 510 | 0 | 0 |
| branch-swap | 20 | vide | 3138.447 | 0.97x | 32.000 | 1.00x | 0.000 | 3530 | 510 | 0 | 0 |
| branch-swap | 20 | react | 5792.851 | 1.79x | 373.000 | 11.66x | 18.000 | 1010 | 510 | 0 | 0 |
| branch-swap | 20 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| branch-swap | 20 | blend | 6871.683 | 2.12x | 30.000 | 0.94x | 0.000 | 4030 | 510 | 0 | 0 |
| branch-swap | 20 | roact | 3751.944 | 1.16x | 27.000 | 0.84x | 0.000 | 1010 | 510 | 0 | 0 |
| branch-swap | 20 | seam | 3310.086 | 1.02x | 30.000 | 0.94x | 1.000 | 500 | 510 | 10 | 0 |
| branch-swap | 20 | signals | unsupported: Signals has no native conditional Instance ownership primitive; adding a scene reconciler would change this state-only lane. | — | — | — | — | — | — | — | — |
| branch-swap | 20 | react-reflex | 5571.316 | 1.72x | 368.000 | 11.50x | 12.000 | 1010 | 510 | 20 | 0 |
| branch-swap | 20 | fusion-charm | 4073.651 | 1.26x | 34.000 | 1.06x | 1.000 | 4030 | 510 | 0 | 0 |
| branch-swap | 20 | react-upstream | 5439.697 | 1.68x | 375.000 | 11.72x | 20.000 | 1010 | 510 | 0 | 0 |
| ordered-window-scroll | 50 | bare | unsupported: the workload measures a Compose primitive's idle scroll cost; there is no hand-written equivalent to compare | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | compose | 301.025 | 1.00x | 1112.000 | 1.00x | 0.000 | 0 | 0 | 0 | 0 |
| ordered-window-scroll | 50 | compose-direct | 305.357 | 1.01x | 1120.000 | 1.01x | 1.000 | 0 | 0 | 0 | 0 |
| ordered-window-scroll | 50 | fusion | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | vide | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | react | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | blend | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | roact | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | seam | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | signals | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | react-reflex | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | fusion-charm | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | react-upstream | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | bare | 797.606 | 0.79x | 1692.000 | 0.77x | 0.000 | 100 | 50 | 0 | 0 |
| keyed-append | 10 | compose | 1012.281 | 1.00x | 2193.000 | 1.00x | 1.000 | 100 | 50 | 0 | 0 |
| keyed-append | 10 | compose-direct | 998.039 | 0.99x | 2190.000 | 1.00x | 1.000 | 100 | 50 | 0 | 0 |
| keyed-append | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | vide | 1135.738 | 1.12x | 2273.000 | 1.04x | 0.000 | 400 | 50 | 0 | 0 |
| keyed-append | 10 | react | 9639.248 | 9.52x | 2502.000 | 1.14x | 0.000 | 150 | 50 | 0 | 0 |
| keyed-append | 10 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | blend | 3042.402 | 3.01x | 3035.000 | 1.38x | 0.000 | 3500 | 50 | 0 | 0 |
| keyed-append | 10 | roact | 4574.668 | 4.52x | 1996.000 | 0.91x | 0.000 | 150 | 50 | 0 | 0 |
| keyed-append | 10 | seam | 9273.165 | 9.16x | 3441.000 | 1.57x | 1.000 | 100 | 50 | 100 | 50 |
| keyed-append | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | react-reflex | 10427.412 | 10.30x | 2511.000 | 1.15x | 5.000 | 150 | 50 | 10 | 0 |
| keyed-append | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | react-upstream | 10010.481 | 9.89x | 2509.000 | 1.14x | 6.000 | 150 | 50 | 0 | 0 |
| keyed-prepend | 10 | bare | 1025.321 | 0.32x | 1700.000 | 0.75x | 1.000 | 3100 | 50 | 0 | 0 |
| keyed-prepend | 10 | compose | 3224.777 | 1.00x | 2268.000 | 1.00x | 1.000 | 3100 | 50 | 0 | 0 |
| keyed-prepend | 10 | compose-direct | 2768.857 | 0.86x | 2190.000 | 0.97x | 1.000 | 3100 | 50 | 0 | 0 |
| keyed-prepend | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | vide | 3253.000 | 1.01x | 2273.000 | 1.00x | 0.000 | 3400 | 50 | 0 | 0 |
| keyed-prepend | 10 | react | 13487.327 | 4.18x | 2457.000 | 1.08x | 0.000 | 3150 | 50 | 0 | 0 |
| keyed-prepend | 10 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | blend | 3089.553 | 0.96x | 3035.000 | 1.34x | 0.000 | 3500 | 50 | 0 | 0 |
| keyed-prepend | 10 | roact | 5729.074 | 1.78x | 1996.000 | 0.88x | 0.000 | 3150 | 50 | 0 | 0 |
| keyed-prepend | 10 | seam | 10219.966 | 3.17x | 3441.000 | 1.52x | 1.000 | 3100 | 50 | 100 | 50 |
| keyed-prepend | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | react-reflex | 12830.625 | 3.98x | 2458.000 | 1.08x | 5.000 | 3150 | 50 | 10 | 0 |
| keyed-prepend | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | react-upstream | 12981.283 | 4.03x | 2457.000 | 1.08x | 5.000 | 3150 | 50 | 0 | 0 |
| keyed-insert | 10 | bare | 922.035 | 0.45x | 1692.000 | 0.76x | 0.000 | 1600 | 50 | 0 | 0 |
| keyed-insert | 10 | compose | 2054.597 | 1.00x | 2238.000 | 1.00x | 1.000 | 1600 | 50 | 0 | 0 |
| keyed-insert | 10 | compose-direct | 1857.319 | 0.90x | 2190.000 | 0.98x | 0.000 | 1600 | 50 | 0 | 0 |
| keyed-insert | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | vide | 2078.835 | 1.01x | 2273.000 | 1.02x | 0.000 | 1900 | 50 | 0 | 0 |
| keyed-insert | 10 | react | 11611.575 | 5.65x | 2482.000 | 1.11x | 0.000 | 1650 | 50 | 0 | 0 |
| keyed-insert | 10 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | blend | 3136.595 | 1.53x | 3035.000 | 1.36x | 0.000 | 3500 | 50 | 0 | 0 |
| keyed-insert | 10 | roact | 5033.344 | 2.45x | 1996.000 | 0.89x | 0.000 | 1650 | 50 | 0 | 0 |
| keyed-insert | 10 | seam | 9279.186 | 4.52x | 3441.000 | 1.54x | 1.000 | 1600 | 50 | 100 | 50 |
| keyed-insert | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | react-reflex | 11706.277 | 5.70x | 2484.000 | 1.11x | 5.000 | 1650 | 50 | 10 | 0 |
| keyed-insert | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | react-upstream | 11360.561 | 5.53x | 2482.000 | 1.11x | 5.000 | 1650 | 50 | 0 | 0 |
| keyed-remove | 10 | bare | 865.720 | 0.45x | 1695.000 | 0.76x | 0.000 | 1510 | 50 | 0 | 0 |
| keyed-remove | 10 | compose | 1942.649 | 1.00x | 2227.000 | 1.00x | 1.000 | 1510 | 50 | 0 | 0 |
| keyed-remove | 10 | compose-direct | 1736.618 | 0.89x | 2186.000 | 0.98x | 1.000 | 1510 | 50 | 0 | 0 |
| keyed-remove | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | vide | 1988.288 | 1.02x | 2273.000 | 1.02x | 0.000 | 1810 | 50 | 0 | 0 |
| keyed-remove | 10 | react | 11225.425 | 5.78x | 2409.000 | 1.08x | 0.000 | 1560 | 50 | 0 | 0 |
| keyed-remove | 10 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | blend | 2966.058 | 1.53x | 3027.000 | 1.36x | 0.000 | 3400 | 50 | 0 | 0 |
| keyed-remove | 10 | roact | 4965.032 | 2.56x | 1995.000 | 0.90x | 0.000 | 1560 | 50 | 0 | 0 |
| keyed-remove | 10 | seam | 9784.244 | 5.04x | 3439.000 | 1.54x | 0.000 | 1510 | 50 | 100 | 50 |
| keyed-remove | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | react-reflex | 12126.348 | 6.24x | 2410.000 | 1.08x | 5.000 | 1560 | 50 | 10 | 0 |
| keyed-remove | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | react-upstream | 12006.498 | 6.18x | 2408.000 | 1.08x | 5.000 | 1560 | 50 | 0 | 0 |
| keyed-replace | 10 | bare | 22033.101 | 0.55x | 1711.000 | 0.77x | 0.000 | 6000 | 3000 | 0 | 0 |
| keyed-replace | 10 | compose | 39904.600 | 1.00x | 2208.000 | 1.00x | 1.000 | 6000 | 3000 | 0 | 0 |
| keyed-replace | 10 | compose-direct | 42592.135 | 1.07x | 2209.000 | 1.00x | 1.000 | 6000 | 3000 | 0 | 0 |
| keyed-replace | 10 | fusion | 67293.675 | 1.69x | 3002.000 | 1.36x | 0.000 | 27300 | 3000 | 0 | 0 |
| keyed-replace | 10 | vide | 41288.485 | 1.03x | 2313.000 | 1.05x | 0.000 | 24000 | 3000 | 0 | 0 |
| keyed-replace | 10 | react | 67248.537 | 1.69x | 3931.000 | 1.78x | 0.000 | 9000 | 3000 | 0 | 0 |
| keyed-replace | 10 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| keyed-replace | 10 | blend | 88954.240 | 2.23x | 5661.000 | 2.56x | 1.000 | 30000 | 3000 | 0 | 0 |
| keyed-replace | 10 | roact | 35385.055 | 0.89x | 2010.000 | 0.91x | 0.000 | 9000 | 3000 | 0 | 0 |
| keyed-replace | 10 | seam | 89208.674 | 2.24x | 3479.000 | 1.58x | 1.000 | 6000 | 3000 | 6000 | 3000 |
| keyed-replace | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-replace | 10 | react-reflex | 71881.077 | 1.80x | 3932.000 | 1.78x | 0.000 | 9000 | 3000 | 10 | 0 |
| keyed-replace | 10 | fusion-charm | 79054.614 | 1.98x | 3005.000 | 1.36x | 1.000 | 27300 | 3000 | 0 | 0 |
| keyed-replace | 10 | react-upstream | 69499.472 | 1.74x | 3931.000 | 1.78x | 8.000 | 9000 | 3000 | 0 | 0 |
| keyed-reverse | 10 | bare | 734.300 | 0.33x | 1696.000 | 0.75x | 1.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | compose | 2249.372 | 1.00x | 2267.000 | 1.00x | 1.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | compose-direct | 1948.977 | 0.87x | 2185.000 | 0.96x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | fusion | 14746.839 | 6.56x | 2986.000 | 1.32x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | vide | 1971.070 | 0.88x | 2256.000 | 1.00x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | react | 35577.918 | 15.82x | 2394.000 | 1.06x | 4.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| keyed-reverse | 10 | blend | 1426.918 | 0.63x | 2993.000 | 1.32x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | roact | 4715.520 | 2.10x | 1995.000 | 0.88x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | seam | 8003.432 | 3.56x | 3439.000 | 1.52x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-reverse | 10 | react-reflex | 36179.678 | 16.08x | 2394.000 | 1.06x | 0.000 | 3000 | 0 | 10 | 0 |
| keyed-reverse | 10 | fusion-charm | 15022.192 | 6.68x | 2980.000 | 1.31x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | react-upstream | 36578.054 | 16.26x | 2386.000 | 1.05x | 4.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | bare | 718.116 | 0.27x | 1696.000 | 0.75x | 1.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | compose | 2653.700 | 1.00x | 2267.000 | 1.00x | 1.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | compose-direct | 1997.561 | 0.75x | 2185.000 | 0.96x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | fusion | 14627.238 | 5.51x | 2979.000 | 1.31x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | vide | 2106.515 | 0.79x | 2256.000 | 1.00x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | react | 24493.136 | 9.23x | 2394.000 | 1.06x | 4.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| keyed-rotate | 10 | blend | 1390.954 | 0.52x | 2993.000 | 1.32x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | roact | 4919.429 | 1.85x | 1995.000 | 0.88x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | seam | 7783.179 | 2.93x | 3440.000 | 1.52x | 1.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-rotate | 10 | react-reflex | 24151.060 | 9.10x | 2394.000 | 1.06x | 0.000 | 3000 | 0 | 10 | 0 |
| keyed-rotate | 10 | fusion-charm | 14507.858 | 5.47x | 2981.000 | 1.31x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | react-upstream | 24404.613 | 9.20x | 2386.000 | 1.05x | 4.000 | 3000 | 0 | 0 | 0 |
| keyed-shuffle | 10 | bare | 750.575 | 0.31x | 1696.000 | 0.75x | 0.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | compose | 2440.741 | 1.00x | 2267.000 | 1.00x | 1.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | compose-direct | 2066.143 | 0.85x | 2185.000 | 0.96x | 0.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | fusion | 14344.572 | 5.88x | 2979.000 | 1.31x | 0.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | vide | 2026.334 | 0.83x | 2256.000 | 1.00x | 0.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | react | 22746.597 | 9.32x | 2394.000 | 1.06x | 4.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| keyed-shuffle | 10 | blend | 1390.122 | 0.57x | 2993.000 | 1.32x | 0.000 | 3000 | 0 | 0 | 0 |
| keyed-shuffle | 10 | roact | 4823.372 | 1.98x | 1995.000 | 0.88x | 0.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | seam | 7636.325 | 3.13x | 3440.000 | 1.52x | 1.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-shuffle | 10 | react-reflex | 22267.286 | 9.12x | 2394.000 | 1.06x | 0.000 | 2990 | 0 | 10 | 0 |
| keyed-shuffle | 10 | fusion-charm | 14984.124 | 6.14x | 2980.000 | 1.31x | 0.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | react-upstream | 23761.845 | 9.74x | 2386.000 | 1.05x | 4.000 | 2990 | 0 | 0 | 0 |
| events | 5 | bare | 12603.746 | 0.77x | 1.000 | 1.00x | 0.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | compose | 16319.247 | 1.00x | 1.000 | 1.00x | 0.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | compose-direct | 12956.810 | 0.79x | 1.000 | 1.00x | 0.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | fusion | 16092.610 | 0.99x | 1.000 | 1.00x | 0.000 | 9015 | 1005 | 1000 | 0 |
| events | 5 | vide | 12402.249 | 0.76x | 1.000 | 1.00x | 0.000 | 8015 | 1005 | 1000 | 0 |
| events | 5 | react | 17323.180 | 1.06x | 4.000 | 4.00x | 3.000 | 2000 | 1005 | 1000 | 0 |
| events | 5 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| events | 5 | blend | 21275.541 | 1.30x | 1.000 | 1.00x | 0.000 | 9015 | 1005 | 1000 | 0 |
| events | 5 | roact | 14344.851 | 0.88x | 1.000 | 1.00x | 0.000 | 2005 | 1005 | 1000 | 0 |
| events | 5 | seam | 12397.056 | 0.76x | 1.000 | 1.00x | 0.000 | 1000 | 1005 | 1005 | 0 |
| events | 5 | signals | 9514.807 | 0.58x | 1.000 | 1.00x | 0.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | react-reflex | 18386.378 | 1.13x | 0.000 | 0.00x | 3.000 | 2000 | 1005 | 1000 | 0 |
| events | 5 | fusion-charm | 15884.234 | 0.97x | 1.000 | 1.00x | 0.000 | 9015 | 1005 | 1000 | 0 |
| events | 5 | react-upstream | 16573.266 | 1.02x | 4.000 | 4.00x | 3.000 | 2000 | 1005 | 1000 | 0 |
| animate-many | 1 | bare | 1017.138 | 0.26x | 1516.000 | 0.66x | 0.000 | 6000 | 0 | 0 | 0 |
| animate-many | 1 | compose | 3968.300 | 1.00x | 2282.000 | 1.00x | 0.000 | 6000 | 0 | 1 | 0 |
| animate-many | 1 | compose-direct | 3966.678 | 1.00x | 2282.000 | 1.00x | 0.000 | 6000 | 0 | 1 | 0 |
| animate-many | 1 | fusion | 94569.750 | 23.83x | 2590.000 | 1.13x | 0.000 | 3600 | 0 | 0 | 0 |
| animate-many | 1 | vide | 5716.839 | 1.44x | 1910.000 | 0.84x | 0.000 | 6000 | 0 | 0 | 30 |
| animate-many | 1 | react | unsupported: React and ReactRoblox have no native spring primitive. Adding another animation library would change the comparison. | — | — | — | — | — | — | — | — |
| animate-many | 1 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| animate-many | 1 | blend | 8351.989 | 2.10x | 2631.000 | 1.15x | 0.000 | 6200 | 0 | 200 | 0 |
| animate-many | 1 | roact | unsupported: Roact has no native spring primitive. | — | — | — | — | — | — | — | — |
| animate-many | 1 | seam | 16873.539 | 4.25x | 3537.000 | 1.55x | 0.000 | 3600 | 0 | 0 | 0 |
| animate-many | 1 | signals | unsupported: Signals has no native spring primitive. | — | — | — | — | — | — | — | — |
| animate-many | 1 | react-reflex | unsupported: React and ReactRoblox have no native spring primitive. Adding another animation library would change the comparison. | — | — | — | — | — | — | — | — |
| animate-many | 1 | fusion-charm | 96679.575 | 24.36x | 2599.000 | 1.14x | 0.000 | 3600 | 0 | 0 | 0 |
| animate-many | 1 | react-upstream | unsupported: React and ReactRoblox have no native spring primitive. Adding another animation library would change the comparison. | — | — | — | — | — | — | — | — |
| status-panel | 20 | bare | 766.444 | 0.73x | 138.000 | 0.75x | 0.000 | 82 | 21 | 0 | 0 |
| status-panel | 20 | compose | 1048.821 | 1.00x | 185.000 | 1.00x | 1.000 | 82 | 21 | 0 | 0 |
| status-panel | 20 | compose-direct | 1052.772 | 1.00x | 171.000 | 0.92x | 0.000 | 82 | 21 | 0 | 0 |
| status-panel | 20 | fusion | 2871.567 | 2.74x | 244.000 | 1.32x | 0.000 | 229 | 21 | 0 | 0 |
| status-panel | 20 | vide | 1191.011 | 1.14x | 188.000 | 1.02x | 0.000 | 208 | 21 | 0 | 0 |
| status-panel | 20 | react | 2276.948 | 2.17x | 203.000 | 1.10x | 7.000 | 103 | 21 | 0 | 0 |
| status-panel | 20 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| status-panel | 20 | blend | 2323.528 | 2.22x | 248.000 | 1.34x | 0.000 | 438 | 21 | 0 | 0 |
| status-panel | 20 | roact | 2298.495 | 2.19x | 176.000 | 0.95x | 0.000 | 103 | 21 | 0 | 0 |
| status-panel | 20 | seam | unsupported: Seam's native computed-property type guard rejects the workload's synthetic Frame.Text property, whose default type is nil. | — | — | — | — | — | — | — | — |
| status-panel | 20 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| status-panel | 20 | react-reflex | 2318.296 | 2.21x | 214.000 | 1.16x | 8.000 | 103 | 21 | 20 | 0 |
| status-panel | 20 | fusion-charm | 2323.348 | 2.22x | 249.000 | 1.35x | 0.000 | 229 | 21 | 0 | 0 |
| status-panel | 20 | react-upstream | 2670.518 | 2.55x | 211.000 | 1.14x | 8.000 | 103 | 21 | 0 | 0 |
| mount-cycles | 1 | bare | 22361.861 | 0.73x | 0.000 | 0.00x | 0.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | compose | 30791.691 | 1.00x | 1.000 | 1.00x | 0.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | compose-direct | 30132.014 | 0.98x | 0.000 | 0.00x | 0.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | fusion | 31288.333 | 1.02x | 0.000 | 0.00x | 0.000 | 16290 | 1830 | 1800 | 0 |
| mount-cycles | 1 | vide | 26620.859 | 0.86x | 0.000 | 0.00x | 0.000 | 14490 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react | 39169.676 | 1.27x | 23.000 | 23.00x | 20.000 | 3600 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| mount-cycles | 1 | blend | 39211.888 | 1.27x | 1.000 | 1.00x | 0.000 | 16290 | 1830 | 1800 | 0 |
| mount-cycles | 1 | roact | 23738.272 | 0.77x | 1.000 | 1.00x | 0.000 | 3630 | 1830 | 1800 | 0 |
| mount-cycles | 1 | seam | 22053.649 | 0.72x | 0.000 | 0.00x | 0.000 | 1800 | 1830 | 1830 | 0 |
| mount-cycles | 1 | signals | 14481.566 | 0.47x | 0.000 | 0.00x | 0.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react-reflex | 33855.539 | 1.10x | 20.000 | 20.00x | 20.000 | 3600 | 1830 | 1800 | 0 |
| mount-cycles | 1 | fusion-charm | 21309.640 | 0.69x | 0.000 | 0.00x | 0.000 | 16290 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react-upstream | 36044.359 | 1.17x | 26.000 | 26.00x | 18.000 | 3600 | 1830 | 1800 | 0 |
| scene-3d | 20 | bare | 6668.121 | 0.66x | 1036.000 | 0.83x | 0.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | compose | 10080.876 | 1.00x | 1250.000 | 1.00x | 0.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | compose-direct | 9744.757 | 0.97x | 1233.000 | 0.99x | 0.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | fusion | 66571.178 | 6.60x | 1567.000 | 1.25x | 0.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | vide | 10757.878 | 1.07x | 1236.000 | 0.99x | 1.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react | 8485.693 | 0.84x | 1243.000 | 0.99x | 1.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| scene-3d | 20 | blend | 11687.318 | 1.16x | 1567.000 | 1.25x | 0.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | roact | unsupported: Roact assigns Instance.Name from reconciliation keys. Named children use dictionary keys, whose mounting order cannot satisfy this workload's ordered named-tree contract. | — | — | — | — | — | — | — | — |
| scene-3d | 20 | seam | 18394.547 | 1.82x | 2223.000 | 1.78x | 0.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | signals | 14120.584 | 1.40x | 1745.000 | 1.40x | 0.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react-reflex | 7691.639 | 0.76x | 1245.000 | 1.00x | 1.000 | 6000 | 0 | 20 | 0 |
| scene-3d | 20 | fusion-charm | 68899.231 | 6.83x | 1578.000 | 1.26x | 0.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react-upstream | 8210.143 | 0.81x | 1243.000 | 0.99x | 1.000 | 6000 | 0 | 0 | 0 |
| unwind | 10 | bare | 3184.884 | 0.82x | 1.000 | 1.00x | 1.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | compose | 3864.621 | 1.00x | 1.000 | 1.00x | 0.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | compose-direct | 4052.200 | 1.05x | 1.000 | 1.00x | 0.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | fusion | 4666.293 | 1.21x | 1.000 | 1.00x | 0.000 | 5310 | 590 | 0 | 0 |
| unwind | 10 | vide | unsupported: Vide releases Instances only through cleanup registrations. This lane registers cleanup on each owned root, so a build that fails before its root exists leaves the created parts without an owner. | — | — | — | — | — | — | — | — |
| unwind | 10 | react | unsupported: A failed native render, including an error boundary, leaves abandoned cost-model host nodes after root unmount. It does not satisfy the partial-build rollback contract. | — | — | — | — | — | — | — | — |
| unwind | 10 | react-usestate | unsupported: This variant differs from the react lane only in update-repeated, where it uses useState; the other workloads are the react lane. | — | — | — | — | — | — | — | — |
| unwind | 10 | blend | unsupported: An error during native observable subscription leaves the partially created cost-model nodes without a returned cleanup resource. It does not satisfy failed-build rollback. | — | — | — | — | — | — | — | — |
| unwind | 10 | roact | unsupported: Roact's public mount API returns its cleanup handle only after a successful mount; failed render rollback is not guaranteed. | — | — | — | — | — | — | — | — |
| unwind | 10 | seam | 3468.300 | 0.90x | 1.000 | 1.00x | 0.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | signals | 3201.289 | 0.83x | 1.000 | 1.00x | 1.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | react-reflex | unsupported: A failed native render, including an error boundary, leaves abandoned cost-model host nodes after root unmount. It does not satisfy the partial-build rollback contract. | — | — | — | — | — | — | — | — |
| unwind | 10 | fusion-charm | 4812.915 | 1.25x | 1.000 | 1.00x | 0.000 | 5310 | 590 | 0 | 0 |
| unwind | 10 | react-upstream | unsupported: A failed native render, including an error boundary, leaves abandoned cost-model host nodes after root unmount. It does not satisfy the partial-build rollback contract. | — | — | — | — | — | — | — | — |

## Source identities

Compose revision: `99df90ec9709c82b486cef27c7a78de33c526fcf`. Full source state, tools, environment and command are in `context.json`.

| Dependency | Version | Commit | Tree | Rights |
| --- | --- | --- | --- | --- |
| fusion | 0.3 | `77e603534ff4013f4049611826ff0309d6000b15` | `715bdf3acd2205f106fc78f5171a56b056323bd0` | MIT |
| vide | 0.4.1 | `5ed4c01940e6bd578fb83253cfbeda0a6c05177c` | `8890f5044158a71592249e2d91646715b98ca4aa` | MIT |
| react | 17.2.1 | `2e652e7ecf269b2611f5b58642c6740fc616f858` | `4aee0834a5e16530171de5ada97126de47cf9c22` | MIT |
| luau-polyfill | 1.2.6 | `cff549d58f24c25f47188459cb24b545cc804830` | `a460ce6c6d9ed0a1ead2100ef8a8f4918df9b2b3` | MIT |
| symbol | 1.0.1 | `15781517cf5df85a8dd0b2181b0c3f86bcc7b6c0` | `69b5eb96fd7f36dadd3c3845afeca585f86dff87` | MIT |
| react-promise | 3.5.0 | `22ee6a02ad333d8182e72fc0d02e43f9d82b8109` | `e2f1f8eb417ae562cc4d53b8f20c534193c0b985` | MIT |
| blend | 12.51.1 | `75c7ed8f4f6a1b04c6885b7980451153b17222b4` | `2009d55e28e2b20153bba3d986db4d8e7eb5df18` | MIT |
| roact | v1.4.4 | `956891b70fdc5410e44e9664719cd0a9f7e6fabd` | `e2b1b9bdf99349d27b8f43b92b3b684a921edc8a` | MIT |
| seam | v1.1.0 | `bc45faa36e2f059ca6fe25f7f7896c16a163abf6` | `44606c00e1f0301f9574b437c322d12042aa9b33` | MIT |
| signals | 0.9.0-unreleased | `25b9a8335e1d5da7b917576356b9ae4c890bcb17` | `2b883aca6fac60b2af44c5deffd739e510e9619a` | MIT |
| reflex | v4.3.1 | `fa0cc3c1ebaafdc70ced5bfc0fa8b2300b8694b2` | `7bec758e4cb240c4e13a8b788de876e7b58f5f01` | MIT |
| charm | charm-v0.11.1 | `af4eb5262d640cf89c56217ab7feb403e939cbd2` | `c1383c7832d8ba663eb68b21b9b7341c874a7007` | MIT |
| react-upstream | v17.1.3 | `7455fb005c68ec63326fcfb6b311da99800980b6` | `096ed4ad4c787f62fa5044ecfb41ed1008619619` | MIT |
| polyfill-upstream | v1.2.3 | `8100f5c609c78d8e0876e502aa3e1f59472b00b7` | `ac7e8886467f0b316614c2c839c883566bec8ad3` | MIT |
| promise-upstream | v3.3.0 | `4508fc738f73c555ceebeb89e7dff1427b8f1e8b` | `427bec669c31bb81aae57dea74d7d9d30308901a` | MIT |
| symbol-upstream | v1.0.0 | `ec62c72f79d94829af867223fc7297912e54deca` | `950e084e0e501b8ce955c6fd2b5b6b509ebef1e9` | MIT |
| reflex-promise | v4.0.0 | `2c6f433903275e689ba1d48402d4a9d6fdc605a5` | `a71184ef76af30ec1270a70b523f352057410942` | MIT |

Raw samples, calibration attempts, parity results and heap readings are in the evidence artifact. Unsupported rows are omissions with reasons, not performance results. Missing evidence does not qualify as a complete comparison.
