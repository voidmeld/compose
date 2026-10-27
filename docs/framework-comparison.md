# Framework comparison

This page records measurements of Compose and other Roblox UI libraries on the same 24 runtime workloads.

- Compose commit: `eabe9cc` (main, 2026-10-26)
- Run: [Framework comparison #40430957447](https://github.com/voidmeld/compose/actions/runs/40430957447) on the GitHub-hosted Ubuntu runner
- Verdict: release. Only passed measurements appear in the table.
- Method: [Manual framework comparison](benchmarks.md#manual-framework-comparison). The workflow runs the parity checks before timing, and both are headless cost-model measurements. They do not measure Roblox engine rendering.

Each ratio divides a measurement by the Compose measurement. A value below 1.00x is smaller. To update this record, run the workflow again. Then replace this page with its results.

These samples use a headless cost model. Time covers one complete workload sample, including all its iterations. Lower ratios mean smaller measurements. Heap estimates retained Luau memory while mounted. Writes, Created, Connections and Deferred count property writes, instances, signal connections and deferred tasks during timed iterations. A zero heap baseline has no ratio. These results do not measure Roblox engine performance.

| Workload | Iterations | Framework | Median time (us) | / Compose | Median heap (KiB) | / Compose | Teardown (KiB) | Writes | Created | Connections | Deferred |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| cold-mount-100 | 1 | bare | 690.977 | 1.19x | 571.000 | 0.99x | 24.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | compose | 580.900 | 1.00x | 577.000 | 1.00x | 17.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | fusion | 821.466 | 1.41x | 572.000 | 0.99x | 8.000 | 803 | 101 | 0 | 0 |
| cold-mount-100 | 1 | vide | 977.427 | 1.68x | 578.000 | 1.00x | 17.000 | 703 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react | 22969.042 | 39.54x | 877.000 | 1.52x | 272.000 | 200 | 101 | 0 | 1 |
| cold-mount-100 | 1 | blend | 1246.294 | 2.15x | 709.000 | 1.23x | 16.000 | 803 | 101 | 0 | 0 |
| cold-mount-100 | 1 | roact | 939.536 | 1.62x | 670.000 | 1.16x | 16.000 | 201 | 101 | 0 | 0 |
| cold-mount-100 | 1 | seam | 736.545 | 1.27x | 577.000 | 1.00x | 8.000 | 100 | 101 | 1 | 0 |
| cold-mount-100 | 1 | signals | 759.614 | 1.31x | 569.000 | 0.99x | 18.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react-reflex | 22940.435 | 39.49x | 869.000 | 1.51x | 264.000 | 200 | 101 | 0 | 1 |
| cold-mount-100 | 1 | fusion-charm | 886.482 | 1.53x | 588.000 | 1.02x | 24.000 | 803 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react-upstream | 29094.278 | 50.08x | 877.000 | 1.52x | 272.000 | 200 | 101 | 0 | 1 |
| cold-mount-1000 | 1 | bare | 7777.175 | 0.91x | 5613.000 | 1.00x | 128.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | compose | 8544.503 | 1.00x | 5625.000 | 1.00x | 121.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | fusion | 11255.906 | 1.32x | 5663.000 | 1.01x | 129.000 | 8003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | vide | 11581.048 | 1.36x | 5662.000 | 1.01x | 129.000 | 7003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react | 36352.550 | 4.25x | 6832.000 | 1.21x | 848.000 | 2000 | 1001 | 0 | 1 |
| cold-mount-1000 | 1 | blend | 16090.921 | 1.88x | 6960.000 | 1.24x | 128.000 | 8003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | roact | 10505.666 | 1.23x | 6580.000 | 1.17x | 136.000 | 2001 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | seam | 9468.886 | 1.11x | 5674.000 | 1.01x | 120.000 | 1000 | 1001 | 1 | 0 |
| cold-mount-1000 | 1 | signals | 7155.277 | 0.84x | 5661.000 | 1.01x | 152.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react-reflex | 34893.274 | 4.08x | 6825.000 | 1.21x | 847.000 | 2000 | 1001 | 0 | 1 |
| cold-mount-1000 | 1 | fusion-charm | 11463.428 | 1.34x | 5664.000 | 1.01x | 136.000 | 8003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react-upstream | 42953.787 | 5.03x | 6833.000 | 1.21x | 848.000 | 2000 | 1001 | 0 | 1 |
| cold-mount-10000 | 1 | bare | 82031.343 | 0.72x | 57029.000 | 0.99x | 2057.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | compose | 113656.179 | 1.00x | 57373.000 | 1.00x | 2058.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | fusion | 140860.965 | 1.24x | 57747.000 | 1.01x | 2049.000 | 80003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | vide | 118017.759 | 1.04x | 57575.000 | 1.00x | 2050.000 | 70003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react | 168054.725 | 1.48x | 67741.000 | 1.18x | 7922.000 | 20000 | 10001 | 0 | 1 |
| cold-mount-10000 | 1 | blend | 180268.390 | 1.59x | 70426.000 | 1.23x | 2049.000 | 80003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | roact | 128009.196 | 1.13x | 66752.000 | 1.16x | 2049.000 | 20001 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | seam | 113918.502 | 1.00x | 58006.000 | 1.01x | 2049.000 | 10000 | 10001 | 1 | 0 |
| cold-mount-10000 | 1 | signals | 89554.157 | 0.79x | 57582.000 | 1.00x | 2305.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react-reflex | 175054.800 | 1.54x | 67741.000 | 1.18x | 7914.000 | 20000 | 10001 | 0 | 1 |
| cold-mount-10000 | 1 | fusion-charm | 128523.236 | 1.13x | 57747.000 | 1.01x | 2049.000 | 80003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react-upstream | 181097.973 | 1.59x | 67750.000 | 1.18x | 7923.000 | 20000 | 10001 | 0 | 1 |
| mount-dispose | 5 | bare | 9452.977 | 0.95x | 129.000 | 0.99x | 128.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | compose | 9926.357 | 1.00x | 130.000 | 1.00x | 129.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | fusion | 14793.045 | 1.49x | 137.000 | 1.05x | 136.000 | 8015 | 1005 | 0 | 0 |
| mount-dispose | 5 | vide | 13276.160 | 1.34x | 137.000 | 1.05x | 137.000 | 7015 | 1005 | 0 | 0 |
| mount-dispose | 5 | react | 37823.561 | 3.81x | 448.000 | 3.45x | 440.000 | 2000 | 1005 | 0 | 1 |
| mount-dispose | 5 | blend | 20019.893 | 2.02x | 129.000 | 0.99x | 128.000 | 8015 | 1005 | 0 | 0 |
| mount-dispose | 5 | roact | 13194.183 | 1.33x | 137.000 | 1.05x | 136.000 | 2005 | 1005 | 0 | 0 |
| mount-dispose | 5 | seam | 11641.202 | 1.17x | 129.000 | 0.99x | 128.000 | 1000 | 1005 | 5 | 0 |
| mount-dispose | 5 | signals | 8259.009 | 0.83x | 125.000 | 0.96x | 124.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | react-reflex | 39146.640 | 3.94x | 440.000 | 3.38x | 440.000 | 2000 | 1005 | 0 | 1 |
| mount-dispose | 5 | fusion-charm | 14306.244 | 1.44x | 129.000 | 0.99x | 128.000 | 8015 | 1005 | 0 | 0 |
| mount-dispose | 5 | react-upstream | 46922.440 | 4.73x | 441.000 | 3.39x | 440.000 | 2000 | 1005 | 0 | 1 |
| update-leaf | 50 | bare | 19.024 | 0.45x | 2816.000 | 1.00x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | compose | 42.237 | 1.00x | 2812.000 | 1.00x | 57.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | fusion | 149.462 | 3.54x | 2836.000 | 1.01x | 65.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | vide | 80.634 | 1.91x | 2834.000 | 1.01x | 73.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react | 77.870 | 1.84x | 3520.000 | 1.25x | 527.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | blend | 94.199 | 2.23x | 3492.000 | 1.24x | 72.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | roact | 56.954 | 1.35x | 3294.000 | 1.17x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | seam | 152.415 | 3.61x | 2842.000 | 1.01x | 57.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | signals | 88.866 | 2.10x | 2834.000 | 1.01x | 72.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react-reflex | 147.092 | 3.48x | 3531.000 | 1.26x | 527.000 | 50 | 0 | 50 | 0 |
| update-leaf | 50 | fusion-charm | 306.148 | 7.25x | 2845.000 | 1.01x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react-upstream | 79.538 | 1.88x | 3528.000 | 1.25x | 527.000 | 50 | 0 | 0 | 0 |
| update-fanout | 20 | bare | 706.466 | 0.55x | 1715.000 | 0.92x | 64.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | compose | 1275.559 | 1.00x | 1861.000 | 1.00x | 58.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | fusion | 9053.524 | 7.10x | 1982.000 | 1.07x | 96.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | vide | 4278.047 | 3.35x | 1910.000 | 1.03x | 73.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react | 1462.697 | 1.15x | 2385.000 | 1.28x | 461.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | blend | 3856.352 | 3.02x | 2295.000 | 1.23x | 64.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | roact | 2470.990 | 1.94x | 2134.000 | 1.15x | 65.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | seam | 3491.963 | 2.74x | 2206.000 | 1.19x | 80.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | signals | 4738.516 | 3.71x | 2003.000 | 1.08x | 80.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react-reflex | 1535.828 | 1.20x | 2388.000 | 1.28x | 460.000 | 6000 | 0 | 20 | 0 |
| update-fanout | 20 | fusion-charm | 9331.198 | 7.32x | 1992.000 | 1.07x | 96.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react-upstream | 1479.398 | 1.16x | 2393.000 | 1.29x | 461.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | bare | 675.461 | 0.30x | 1715.000 | 0.89x | 64.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | compose | 2225.076 | 1.00x | 1925.000 | 1.00x | 66.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | fusion | 13445.376 | 6.04x | 2256.000 | 1.17x | 128.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | vide | 5220.912 | 2.35x | 2054.000 | 1.07x | 73.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react | 2672.870 | 1.20x | 2789.000 | 1.45x | 686.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | blend | 6606.169 | 2.97x | 2568.000 | 1.33x | 64.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | roact | 4661.787 | 2.10x | 2589.000 | 1.34x | 64.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | seam | 7900.845 | 3.55x | 2992.000 | 1.55x | 104.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | signals | 6375.856 | 2.87x | 2350.000 | 1.22x | 104.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react-reflex | 24121.676 | 10.84x | 3778.000 | 1.96x | 733.000 | 6000 | 0 | 6000 | 0 |
| update-batched | 20 | fusion-charm | 27949.008 | 12.56x | 2839.000 | 1.47x | 136.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react-upstream | 2758.204 | 1.24x | 2789.000 | 1.45x | 685.000 | 6000 | 0 | 0 | 0 |
| update-repeated | 10 | bare | 31.136 | 0.09x | 14.000 | 0.78x | 0.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | compose | 354.425 | 1.00x | 18.000 | 1.00x | 2.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | fusion | unsupported: No public transaction API coalesces the 500 source writes into one host property write. | — | — | — | — | — | — | — | — |
| update-repeated | 10 | vide | 619.577 | 1.75x | 25.000 | 1.39x | 10.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | react | 11179.839 | 31.54x | 371.000 | 20.61x | 371.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | blend | 4565.303 | 12.88x | 20.000 | 1.11x | 0.000 | 10 | 0 | 0 | 10 |
| update-repeated | 10 | roact | unsupported: Roact has no public batch transaction that coalesces 500 binding writes into one host property write. | — | — | — | — | — | — | — | — |
| update-repeated | 10 | seam | 1815.620 | 5.12x | 27.000 | 1.50x | 13.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | signals | 1147.299 | 3.24x | 17.000 | 0.94x | 1.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | react-reflex | 403.478 | 1.14x | 222.000 | 12.33x | 204.000 | 10 | 0 | 10 | 0 |
| update-repeated | 10 | fusion-charm | 2392.455 | 6.75x | 20.000 | 1.11x | 1.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | react-upstream | 10973.592 | 30.96x | 372.000 | 20.67x | 380.000 | 10 | 0 | 0 | 0 |
| branch-swap | 20 | bare | 3871.365 | 0.81x | 147.000 | 0.91x | 128.000 | 500 | 510 | 0 | 0 |
| branch-swap | 20 | compose | 4778.749 | 1.00x | 161.000 | 1.00x | 129.000 | 500 | 510 | 0 | 0 |
| branch-swap | 20 | fusion | 6744.401 | 1.41x | 152.000 | 0.94x | 136.000 | 4030 | 510 | 0 | 0 |
| branch-swap | 20 | vide | 5829.996 | 1.22x | 152.000 | 0.94x | 137.000 | 3530 | 510 | 0 | 0 |
| branch-swap | 20 | react | 7218.162 | 1.51x | 701.000 | 4.35x | 355.000 | 1010 | 510 | 0 | 0 |
| branch-swap | 20 | blend | 11051.820 | 2.31x | 166.000 | 1.03x | 128.000 | 4030 | 510 | 0 | 0 |
| branch-swap | 20 | roact | 6093.096 | 1.28x | 91.000 | 0.57x | 72.000 | 1010 | 510 | 0 | 0 |
| branch-swap | 20 | seam | 6155.478 | 1.29x | 3011.000 | 18.70x | 149.000 | 500 | 510 | 10 | 0 |
| branch-swap | 20 | signals | unsupported: Signals has no native conditional Instance ownership primitive; adding a scene reconciler would change this state-only lane. | — | — | — | — | — | — | — | — |
| branch-swap | 20 | react-reflex | 8700.136 | 1.82x | 704.000 | 4.37x | 349.000 | 1010 | 510 | 20 | 0 |
| branch-swap | 20 | fusion-charm | 6824.408 | 1.43x | 161.000 | 1.00x | 128.000 | 4030 | 510 | 0 | 0 |
| branch-swap | 20 | react-upstream | 8773.912 | 1.84x | 706.000 | 4.39x | 347.000 | 1010 | 510 | 0 | 0 |
| ordered-window-scroll | 50 | bare | unsupported: the workload measures a Compose primitive's idle scroll cost; there is no hand-written equivalent to compare | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | compose | 470.418 | 1.00x | 1131.000 | 1.00x | 12.000 | 0 | 0 | 0 | 0 |
| ordered-window-scroll | 50 | fusion | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | vide | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | react | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | blend | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | roact | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | seam | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | signals | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | react-reflex | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | fusion-charm | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | react-upstream | unsupported: No native ordered window collection with the workload's retained range and geometry contract. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | bare | 1062.804 | 0.76x | 1771.000 | 0.79x | 64.000 | 100 | 50 | 0 | 0 |
| keyed-append | 10 | compose | 1405.581 | 1.00x | 2247.000 | 1.00x | 65.000 | 100 | 50 | 0 | 0 |
| keyed-append | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | vide | 1571.153 | 1.12x | 2338.000 | 1.04x | 73.000 | 400 | 50 | 0 | 0 |
| keyed-append | 10 | react | 13693.958 | 9.74x | 2848.000 | 1.27x | 344.000 | 150 | 50 | 0 | 0 |
| keyed-append | 10 | blend | 4133.433 | 2.94x | 3099.000 | 1.38x | 64.000 | 3500 | 50 | 0 | 0 |
| keyed-append | 10 | roact | 6808.116 | 4.84x | 2052.000 | 0.91x | 64.000 | 150 | 50 | 0 | 0 |
| keyed-append | 10 | seam | 12034.433 | 8.56x | 3497.000 | 1.56x | 133.000 | 350 | 50 | 100 | 50 |
| keyed-append | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | react-reflex | 13757.595 | 9.79x | 2851.000 | 1.27x | 339.000 | 150 | 50 | 10 | 0 |
| keyed-append | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | react-upstream | 14246.064 | 10.14x | 2848.000 | 1.27x | 344.000 | 150 | 50 | 0 | 0 |
| keyed-prepend | 10 | bare | 1323.880 | 0.31x | 1771.000 | 0.76x | 64.000 | 3100 | 50 | 0 | 0 |
| keyed-prepend | 10 | compose | 4309.109 | 1.00x | 2329.000 | 1.00x | 65.000 | 3100 | 50 | 0 | 0 |
| keyed-prepend | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | vide | 4792.645 | 1.11x | 2339.000 | 1.00x | 73.000 | 3400 | 50 | 0 | 0 |
| keyed-prepend | 10 | react | 19590.135 | 4.55x | 2787.000 | 1.20x | 328.000 | 3150 | 50 | 0 | 0 |
| keyed-prepend | 10 | blend | 4572.320 | 1.06x | 3098.000 | 1.33x | 64.000 | 3500 | 50 | 0 | 0 |
| keyed-prepend | 10 | roact | 8328.103 | 1.93x | 2052.000 | 0.88x | 72.000 | 3150 | 50 | 0 | 0 |
| keyed-prepend | 10 | seam | 13472.821 | 3.13x | 3497.000 | 1.50x | 134.000 | 3350 | 50 | 100 | 50 |
| keyed-prepend | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | react-reflex | 19224.829 | 4.46x | 2791.000 | 1.20x | 339.000 | 3150 | 50 | 10 | 0 |
| keyed-prepend | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | react-upstream | 20365.335 | 4.73x | 2796.000 | 1.20x | 344.000 | 3150 | 50 | 0 | 0 |
| keyed-insert | 10 | bare | 1262.471 | 0.44x | 1771.000 | 0.77x | 64.000 | 1600 | 50 | 0 | 0 |
| keyed-insert | 10 | compose | 2885.566 | 1.00x | 2288.000 | 1.00x | 61.000 | 1600 | 50 | 0 | 0 |
| keyed-insert | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | vide | 3176.327 | 1.10x | 2339.000 | 1.02x | 66.000 | 1900 | 50 | 0 | 0 |
| keyed-insert | 10 | react | 17635.954 | 6.11x | 2813.000 | 1.23x | 336.000 | 1650 | 50 | 0 | 0 |
| keyed-insert | 10 | blend | 4112.724 | 1.43x | 3099.000 | 1.35x | 72.000 | 3500 | 50 | 0 | 0 |
| keyed-insert | 10 | roact | 7245.565 | 2.51x | 2051.000 | 0.90x | 64.000 | 1650 | 50 | 0 | 0 |
| keyed-insert | 10 | seam | 13564.397 | 4.70x | 3497.000 | 1.53x | 133.000 | 1850 | 50 | 100 | 50 |
| keyed-insert | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | react-reflex | 17694.360 | 6.13x | 2824.000 | 1.23x | 339.000 | 1650 | 50 | 10 | 0 |
| keyed-insert | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | react-upstream | 17592.118 | 6.10x | 2821.000 | 1.23x | 344.000 | 1650 | 50 | 0 | 0 |
| keyed-remove | 10 | bare | 1200.367 | 0.44x | 1759.000 | 0.77x | 64.000 | 1510 | 50 | 0 | 0 |
| keyed-remove | 10 | compose | 2728.177 | 1.00x | 2290.000 | 1.00x | 69.000 | 1510 | 50 | 0 | 0 |
| keyed-remove | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | vide | 2937.227 | 1.08x | 2338.000 | 1.02x | 65.000 | 1810 | 50 | 0 | 0 |
| keyed-remove | 10 | react | 16943.503 | 6.21x | 2747.000 | 1.20x | 336.000 | 1560 | 50 | 0 | 0 |
| keyed-remove | 10 | blend | 4289.364 | 1.57x | 3098.000 | 1.35x | 64.000 | 3400 | 50 | 0 | 0 |
| keyed-remove | 10 | roact | 7376.317 | 2.70x | 2043.000 | 0.89x | 64.000 | 1560 | 50 | 0 | 0 |
| keyed-remove | 10 | seam | 13630.431 | 5.00x | 3496.000 | 1.53x | 132.000 | 1810 | 50 | 100 | 50 |
| keyed-remove | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | react-reflex | 16268.338 | 5.96x | 2749.000 | 1.20x | 339.000 | 1560 | 50 | 10 | 0 |
| keyed-remove | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | react-upstream | 17403.363 | 6.38x | 2739.000 | 1.20x | 336.000 | 1560 | 50 | 0 | 0 |
| keyed-replace | 10 | bare | 29051.889 | 0.47x | 2231.000 | 0.82x | 512.000 | 6000 | 3000 | 0 | 0 |
| keyed-replace | 10 | compose | 62396.920 | 1.00x | 2722.000 | 1.00x | 505.000 | 6000 | 3000 | 0 | 0 |
| keyed-replace | 10 | fusion | 106563.605 | 1.71x | 4027.000 | 1.48x | 1017.000 | 27300 | 3000 | 0 | 0 |
| keyed-replace | 10 | vide | 52614.846 | 0.84x | 2841.000 | 1.04x | 521.000 | 24000 | 3000 | 0 | 0 |
| keyed-replace | 10 | react | 94301.715 | 1.51x | 4749.000 | 1.74x | 825.000 | 9000 | 3000 | 0 | 0 |
| keyed-replace | 10 | blend | 123229.218 | 1.97x | 6173.000 | 2.27x | 504.000 | 30000 | 3000 | 0 | 0 |
| keyed-replace | 10 | roact | 41212.435 | 0.66x | 2514.000 | 0.92x | 512.000 | 9000 | 3000 | 0 | 0 |
| keyed-replace | 10 | seam | 148949.394 | 2.39x | 31568.000 | 11.60x | 724.000 | 22500 | 3000 | 6000 | 3000 |
| keyed-replace | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-replace | 10 | react-reflex | 92956.781 | 1.49x | 4752.000 | 1.75x | 820.000 | 9000 | 3000 | 10 | 0 |
| keyed-replace | 10 | fusion-charm | 102299.562 | 1.64x | 4029.000 | 1.48x | 1025.000 | 27300 | 3000 | 0 | 0 |
| keyed-replace | 10 | react-upstream | 90923.121 | 1.46x | 4750.000 | 1.75x | 826.000 | 9000 | 3000 | 0 | 0 |
| keyed-reverse | 10 | bare | 951.199 | 0.29x | 1759.000 | 0.75x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | compose | 3321.040 | 1.00x | 2333.000 | 1.00x | 65.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | fusion | 21128.411 | 6.36x | 3171.000 | 1.36x | 192.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | vide | 2679.800 | 0.81x | 2322.000 | 1.00x | 73.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | react | 50834.231 | 15.31x | 2732.000 | 1.17x | 335.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | blend | 2030.688 | 0.61x | 3057.000 | 1.31x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | roact | 6755.448 | 2.03x | 2043.000 | 0.88x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | seam | 10433.637 | 3.14x | 3045.000 | 1.31x | 132.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-reverse | 10 | react-reflex | 50503.020 | 15.21x | 2735.000 | 1.17x | 338.000 | 3000 | 0 | 10 | 0 |
| keyed-reverse | 10 | fusion-charm | 20597.906 | 6.20x | 3180.000 | 1.36x | 192.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | react-upstream | 51021.240 | 15.36x | 2732.000 | 1.17x | 335.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | bare | 915.957 | 0.27x | 1759.000 | 0.75x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | compose | 3383.294 | 1.00x | 2333.000 | 1.00x | 65.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | fusion | 21687.889 | 6.41x | 3163.000 | 1.36x | 184.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | vide | 3176.808 | 0.94x | 2322.000 | 1.00x | 73.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | react | 35603.229 | 10.52x | 2732.000 | 1.17x | 343.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | blend | 2132.523 | 0.63x | 3057.000 | 1.31x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | roact | 7215.253 | 2.13x | 2050.000 | 0.88x | 65.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | seam | 11570.127 | 3.42x | 3037.000 | 1.30x | 132.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-rotate | 10 | react-reflex | 35720.650 | 10.56x | 2735.000 | 1.17x | 338.000 | 3000 | 0 | 10 | 0 |
| keyed-rotate | 10 | fusion-charm | 22103.146 | 6.53x | 3173.000 | 1.36x | 192.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | react-upstream | 35027.239 | 10.35x | 2724.000 | 1.17x | 334.000 | 3000 | 0 | 0 | 0 |
| keyed-shuffle | 10 | bare | 986.492 | 0.29x | 1759.000 | 0.75x | 64.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | compose | 3355.911 | 1.00x | 2333.000 | 1.00x | 74.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | fusion | 22254.150 | 6.63x | 3171.000 | 1.36x | 192.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | vide | 3056.719 | 0.91x | 2322.000 | 1.00x | 73.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | react | 32890.627 | 9.80x | 2725.000 | 1.17x | 335.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | blend | 2190.064 | 0.65x | 3057.000 | 1.31x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-shuffle | 10 | roact | 7140.724 | 2.13x | 2043.000 | 0.88x | 56.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | seam | 11325.291 | 3.37x | 3045.000 | 1.31x | 133.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-shuffle | 10 | react-reflex | 33442.823 | 9.97x | 2735.000 | 1.17x | 337.000 | 2990 | 0 | 10 | 0 |
| keyed-shuffle | 10 | fusion-charm | 22889.944 | 6.82x | 3180.000 | 1.36x | 193.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | react-upstream | 33189.986 | 9.89x | 2725.000 | 1.17x | 335.000 | 2990 | 0 | 0 | 0 |
| events | 5 | bare | 10503.927 | 0.81x | 129.000 | 0.99x | 128.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | compose | 12948.440 | 1.00x | 130.000 | 1.00x | 137.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | fusion | 17636.520 | 1.36x | 137.000 | 1.05x | 136.000 | 9015 | 1005 | 1000 | 0 |
| events | 5 | vide | 16069.609 | 1.24x | 122.000 | 0.94x | 129.000 | 8015 | 1005 | 1000 | 0 |
| events | 5 | react | 41910.385 | 3.24x | 470.000 | 3.62x | 469.000 | 2000 | 1005 | 1000 | 1 |
| events | 5 | blend | 30127.166 | 2.33x | 129.000 | 0.99x | 136.000 | 9015 | 1005 | 1000 | 0 |
| events | 5 | roact | 19595.577 | 1.51x | 137.000 | 1.05x | 136.000 | 2005 | 1005 | 1000 | 0 |
| events | 5 | seam | 17984.110 | 1.39x | 129.000 | 0.99x | 121.000 | 1000 | 1005 | 1005 | 0 |
| events | 5 | signals | 12949.120 | 1.00x | 137.000 | 1.05x | 144.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | react-reflex | 44475.725 | 3.43x | 470.000 | 3.62x | 469.000 | 2000 | 1005 | 1000 | 1 |
| events | 5 | fusion-charm | 19602.042 | 1.51x | 130.000 | 1.00x | 137.000 | 9015 | 1005 | 1000 | 0 |
| events | 5 | react-upstream | 50184.572 | 3.88x | 470.000 | 3.62x | 470.000 | 2000 | 1005 | 1000 | 1 |
| animate-many | 1 | bare | 1263.656 | 0.17x | 1555.000 | 0.63x | 32.000 | 6000 | 0 | 0 | 0 |
| animate-many | 1 | compose | 7434.275 | 1.00x | 2456.000 | 1.00x | 41.000 | 6000 | 0 | 1 | 0 |
| animate-many | 1 | fusion | 128232.885 | 17.25x | 2754.000 | 1.12x | 157.000 | 3600 | 0 | 0 | 0 |
| animate-many | 1 | vide | 8659.384 | 1.16x | 1976.000 | 0.80x | 53.000 | 6000 | 0 | 0 | 30 |
| animate-many | 1 | react | unsupported: React and ReactRoblox have no native spring primitive. Adding another animation library would change the comparison. | — | — | — | — | — | — | — | — |
| animate-many | 1 | blend | 11164.313 | 1.50x | 2735.000 | 1.11x | 97.000 | 6200 | 0 | 200 | 0 |
| animate-many | 1 | roact | unsupported: Roact has no native spring primitive. | — | — | — | — | — | — | — | — |
| animate-many | 1 | seam | 25833.462 | 3.47x | 3603.000 | 1.47x | 76.000 | 3600 | 0 | 0 | 0 |
| animate-many | 1 | signals | unsupported: Signals has no native spring primitive. | — | — | — | — | — | — | — | — |
| animate-many | 1 | react-reflex | unsupported: React and ReactRoblox have no native spring primitive. Adding another animation library would change the comparison. | — | — | — | — | — | — | — | — |
| animate-many | 1 | fusion-charm | 127787.463 | 17.19x | 2772.000 | 1.13x | 172.000 | 3600 | 0 | 0 | 0 |
| animate-many | 1 | react-upstream | unsupported: React and ReactRoblox have no native spring primitive. Adding another animation library would change the comparison. | — | — | — | — | — | — | — | — |
| status-panel | 20 | bare | 180.848 | 0.49x | 140.000 | 0.73x | 10.000 | 82 | 21 | 0 | 0 |
| status-panel | 20 | compose | 372.837 | 1.00x | 191.000 | 1.00x | 12.000 | 82 | 21 | 0 | 0 |
| status-panel | 20 | fusion | 2073.636 | 5.56x | 250.000 | 1.31x | 7.000 | 229 | 21 | 0 | 0 |
| status-panel | 20 | vide | 391.269 | 1.05x | 199.000 | 1.04x | 11.000 | 208 | 21 | 0 | 0 |
| status-panel | 20 | react | 2049.006 | 5.50x | 431.000 | 2.26x | 220.000 | 103 | 21 | 0 | 0 |
| status-panel | 20 | blend | 731.347 | 1.96x | 258.000 | 1.35x | 2.000 | 438 | 21 | 0 | 0 |
| status-panel | 20 | roact | 651.379 | 1.75x | 178.000 | 0.93x | 2.000 | 103 | 21 | 0 | 0 |
| status-panel | 20 | seam | unsupported: Seam's native computed-property type guard rejects the workload's synthetic Frame.Text property, whose default type is nil. | — | — | — | — | — | — | — | — |
| status-panel | 20 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| status-panel | 20 | react-reflex | 2299.757 | 6.17x | 441.000 | 2.31x | 230.000 | 103 | 21 | 60 | 0 |
| status-panel | 20 | fusion-charm | 2319.449 | 6.22x | 263.000 | 1.38x | 14.000 | 229 | 21 | 0 | 0 |
| status-panel | 20 | react-upstream | 2180.137 | 5.85x | 431.000 | 2.26x | 220.000 | 103 | 21 | 0 | 0 |
| mount-cycles | 1 | bare | 19872.328 | 0.80x | 257.000 | 1.86x | 264.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | compose | 24813.168 | 1.00x | 138.000 | 1.00x | 137.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | fusion | 31179.415 | 1.26x | 130.000 | 0.94x | 129.000 | 16290 | 1830 | 1800 | 0 |
| mount-cycles | 1 | vide | 25182.505 | 1.01x | 258.000 | 1.87x | 265.000 | 14490 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react | 60458.322 | 2.44x | 518.000 | 3.75x | 517.000 | 3600 | 1830 | 1800 | 1 |
| mount-cycles | 1 | blend | 46812.130 | 1.89x | 136.000 | 0.99x | 136.000 | 16290 | 1830 | 1800 | 0 |
| mount-cycles | 1 | roact | 32752.735 | 1.32x | 258.000 | 1.87x | 257.000 | 3630 | 1830 | 1800 | 0 |
| mount-cycles | 1 | seam | 29040.601 | 1.17x | 256.000 | 1.86x | 256.000 | 1800 | 1830 | 1830 | 0 |
| mount-cycles | 1 | signals | 20481.230 | 0.83x | 253.000 | 1.83x | 260.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react-reflex | 60149.340 | 2.42x | 525.000 | 3.80x | 516.000 | 3600 | 1830 | 1800 | 1 |
| mount-cycles | 1 | fusion-charm | 31622.317 | 1.27x | 257.000 | 1.86x | 265.000 | 16290 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react-upstream | 65894.755 | 2.66x | 526.000 | 3.81x | 525.000 | 3600 | 1830 | 1800 | 1 |
| scene-3d | 20 | bare | 3880.735 | 0.47x | 1068.000 | 0.85x | 32.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | compose | 8241.299 | 1.00x | 1258.000 | 1.00x | 25.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | fusion | 76752.085 | 9.31x | 1671.000 | 1.33x | 104.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | vide | 9987.923 | 1.21x | 1296.000 | 1.03x | 41.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react | 5966.992 | 0.72x | 1759.000 | 1.40x | 509.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | blend | 9590.017 | 1.16x | 1598.000 | 1.27x | 32.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | roact | unsupported: Roact assigns Instance.Name from reconciliation keys. Named children use dictionary keys, whose mounting order cannot satisfy this workload's ordered named-tree contract. | — | — | — | — | — | — | — | — |
| scene-3d | 20 | seam | 19807.614 | 2.40x | 2266.000 | 1.80x | 54.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | signals | 14525.787 | 1.76x | 1802.000 | 1.43x | 64.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react-reflex | 5991.839 | 0.73x | 1758.000 | 1.40x | 510.000 | 6000 | 0 | 40 | 0 |
| scene-3d | 20 | fusion-charm | 76459.322 | 9.28x | 1675.000 | 1.33x | 96.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react-upstream | 5987.018 | 0.73x | 1760.000 | 1.40x | 509.000 | 6000 | 0 | 0 | 0 |
| unwind | 10 | bare | 3174.623 | 0.60x | 129.000 | 1.00x | 128.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | compose | 5291.049 | 1.00x | 129.000 | 1.00x | 128.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | fusion | 6759.950 | 1.28x | 129.000 | 1.00x | 129.000 | 5310 | 590 | 0 | 0 |
| unwind | 10 | vide | 6015.557 | 1.14x | 138.000 | 1.07x | 137.000 | 2360 | 590 | 0 | 0 |
| unwind | 10 | react | unsupported: A failed native render, including an error boundary, leaves abandoned cost-model host nodes after root unmount. It does not satisfy the partial-build rollback contract. | — | — | — | — | — | — | — | — |
| unwind | 10 | blend | unsupported: An error during native observable subscription leaves the partially created cost-model nodes without a returned cleanup resource. It does not satisfy failed-build rollback. | — | — | — | — | — | — | — | — |
| unwind | 10 | roact | unsupported: Roact's public mount API returns its cleanup handle only after a successful mount; failed render rollback is not guaranteed. | — | — | — | — | — | — | — | — |
| unwind | 10 | seam | 5730.074 | 1.08x | 129.000 | 1.00x | 128.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | signals | 4915.487 | 0.93x | 122.000 | 0.95x | 121.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | react-reflex | unsupported: A failed native render, including an error boundary, leaves abandoned cost-model host nodes after root unmount. It does not satisfy the partial-build rollback contract. | — | — | — | — | — | — | — | — |
| unwind | 10 | fusion-charm | 6149.711 | 1.16x | 129.000 | 1.00x | 128.000 | 5310 | 590 | 0 | 0 |
| unwind | 10 | react-upstream | unsupported: A failed native render, including an error boundary, leaves abandoned cost-model host nodes after root unmount. It does not satisfy the partial-build rollback contract. | — | — | — | — | — | — | — | — |

## Source identities

Compose revision: `eabe9ccc4c025f3c19856689d7f72ca47637cfb8`. Full source state, tools, environment and command are in `context.json`.

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
