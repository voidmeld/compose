# Framework comparison

This page records measurements of Compose and other Roblox UI libraries on the same 24 runtime workloads.

- Compose commit: `00a663b` (main, 2026-10-26)
- Run: [Framework comparison #40459848319](https://github.com/voidmeld/compose/actions/runs/40459848319) on the GitHub-hosted Ubuntu runner
- Verdict: release. Only passed measurements appear in the table.
- Method: [Manual framework comparison](benchmarks.md#manual-framework-comparison). The workflow runs the parity checks before timing, and both are headless cost-model measurements. They do not measure Roblox engine rendering.

Each ratio divides a measurement by the Compose measurement. A value below 1.00x is smaller. To update this record, run the workflow again. Then replace this page with its results.

These samples use a headless cost model. Time covers one complete workload sample, including all its iterations. Lower ratios mean smaller measurements. Heap estimates retained Luau memory while mounted. Writes, Created, Connections and Deferred count property writes, instances, signal connections and deferred tasks during timed iterations. A zero heap baseline has no ratio. These results do not measure Roblox engine performance.

| Workload | Iterations | Framework | Median time (us) | / Compose | Median heap (KiB) | / Compose | Teardown (KiB) | Writes | Created | Connections | Deferred |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| cold-mount-100 | 1 | bare | 624.374 | 0.88x | 571.000 | 0.99x | 16.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | compose | 705.717 | 1.00x | 575.000 | 1.00x | 10.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | fusion | 942.502 | 1.34x | 580.000 | 1.01x | 24.000 | 803 | 101 | 0 | 0 |
| cold-mount-100 | 1 | vide | 843.055 | 1.19x | 578.000 | 1.01x | 17.000 | 703 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react | 34104.728 | 48.33x | 877.000 | 1.53x | 271.000 | 200 | 101 | 0 | 1 |
| cold-mount-100 | 1 | blend | 1451.407 | 2.06x | 709.000 | 1.23x | 16.000 | 803 | 101 | 0 | 0 |
| cold-mount-100 | 1 | roact | 1275.206 | 1.81x | 669.000 | 1.16x | 24.000 | 201 | 101 | 0 | 0 |
| cold-mount-100 | 1 | seam | 678.480 | 0.96x | 585.000 | 1.02x | 16.000 | 100 | 101 | 1 | 0 |
| cold-mount-100 | 1 | signals | 570.963 | 0.81x | 577.000 | 1.00x | 26.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react-reflex | 33765.721 | 47.85x | 877.000 | 1.53x | 279.000 | 200 | 101 | 0 | 1 |
| cold-mount-100 | 1 | fusion-charm | 1168.815 | 1.66x | 580.000 | 1.01x | 16.000 | 803 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react-upstream | 44818.343 | 63.51x | 877.000 | 1.53x | 273.000 | 200 | 101 | 0 | 1 |
| cold-mount-1000 | 1 | bare | 6901.319 | 0.83x | 5613.000 | 1.00x | 128.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | compose | 8295.307 | 1.00x | 5617.000 | 1.00x | 130.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | fusion | 12155.272 | 1.47x | 5663.000 | 1.01x | 128.000 | 8003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | vide | 10600.567 | 1.28x | 5662.000 | 1.01x | 129.000 | 7003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react | 47568.470 | 5.73x | 6833.000 | 1.22x | 855.000 | 2000 | 1001 | 0 | 1 |
| cold-mount-1000 | 1 | blend | 17563.115 | 2.12x | 6960.000 | 1.24x | 136.000 | 8003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | roact | 12054.263 | 1.45x | 6580.000 | 1.17x | 128.000 | 2001 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | seam | 9649.566 | 1.16x | 5682.000 | 1.01x | 136.000 | 1000 | 1001 | 1 | 0 |
| cold-mount-1000 | 1 | signals | 7962.798 | 0.96x | 5661.000 | 1.01x | 144.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react-reflex | 47340.224 | 5.71x | 6824.000 | 1.21x | 839.000 | 2000 | 1001 | 0 | 1 |
| cold-mount-1000 | 1 | fusion-charm | 12296.507 | 1.48x | 5664.000 | 1.01x | 128.000 | 8003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react-upstream | 57660.387 | 6.95x | 6825.000 | 1.22x | 848.000 | 2000 | 1001 | 0 | 1 |
| cold-mount-10000 | 1 | bare | 84836.754 | 0.75x | 57029.000 | 1.00x | 2049.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | compose | 113118.736 | 1.00x | 57124.000 | 1.00x | 2058.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | fusion | 146788.530 | 1.30x | 57747.000 | 1.01x | 2049.000 | 80003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | vide | 118197.053 | 1.04x | 57600.000 | 1.01x | 2058.000 | 70003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react | 192938.469 | 1.71x | 67765.000 | 1.19x | 7922.000 | 20000 | 10001 | 0 | 1 |
| cold-mount-10000 | 1 | blend | 180355.235 | 1.59x | 70433.000 | 1.23x | 2049.000 | 80003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | roact | 134431.929 | 1.19x | 66752.000 | 1.17x | 2050.000 | 20001 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | seam | 118401.843 | 1.05x | 58022.000 | 1.02x | 2049.000 | 10000 | 10001 | 1 | 0 |
| cold-mount-10000 | 1 | signals | 113427.232 | 1.00x | 57582.000 | 1.01x | 2305.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react-reflex | 195132.519 | 1.73x | 67765.000 | 1.19x | 7930.000 | 20000 | 10001 | 0 | 1 |
| cold-mount-10000 | 1 | fusion-charm | 134429.403 | 1.19x | 57747.000 | 1.01x | 2049.000 | 80003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react-upstream | 197533.870 | 1.75x | 67758.000 | 1.19x | 7923.000 | 20000 | 10001 | 0 | 1 |
| mount-dispose | 5 | bare | 8952.658 | 0.96x | 129.000 | 1.06x | 128.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | compose | 9296.789 | 1.00x | 122.000 | 1.00x | 129.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | fusion | 14879.837 | 1.60x | 129.000 | 1.06x | 128.000 | 8015 | 1005 | 0 | 0 |
| mount-dispose | 5 | vide | 11830.636 | 1.27x | 130.000 | 1.07x | 129.000 | 7015 | 1005 | 0 | 0 |
| mount-dispose | 5 | react | 49512.878 | 5.33x | 441.000 | 3.61x | 440.000 | 2000 | 1005 | 0 | 1 |
| mount-dispose | 5 | blend | 22561.345 | 2.43x | 129.000 | 1.06x | 128.000 | 8015 | 1005 | 0 | 0 |
| mount-dispose | 5 | roact | 14593.090 | 1.57x | 129.000 | 1.06x | 128.000 | 2005 | 1005 | 0 | 0 |
| mount-dispose | 5 | seam | 12155.885 | 1.31x | 129.000 | 1.06x | 128.000 | 1000 | 1005 | 5 | 0 |
| mount-dispose | 5 | signals | 9207.686 | 0.99x | 133.000 | 1.09x | 132.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | react-reflex | 49785.548 | 5.36x | 441.000 | 3.61x | 439.000 | 2000 | 1005 | 0 | 1 |
| mount-dispose | 5 | fusion-charm | 15583.050 | 1.68x | 129.000 | 1.06x | 136.000 | 8015 | 1005 | 0 | 0 |
| mount-dispose | 5 | react-upstream | 58899.016 | 6.34x | 434.000 | 3.56x | 440.000 | 2000 | 1005 | 0 | 1 |
| update-leaf | 50 | bare | 20.033 | 0.45x | 2808.000 | 1.00x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | compose | 44.379 | 1.00x | 2820.000 | 1.00x | 65.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | fusion | 172.870 | 3.90x | 2843.000 | 1.01x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | vide | 98.856 | 2.23x | 2842.000 | 1.01x | 65.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react | 89.904 | 2.03x | 3520.000 | 1.25x | 519.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | blend | 110.428 | 2.49x | 3485.000 | 1.24x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | roact | 67.732 | 1.53x | 3294.000 | 1.17x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | seam | 180.900 | 4.08x | 2849.000 | 1.01x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | signals | 106.485 | 2.40x | 2834.000 | 1.00x | 80.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react-reflex | 177.990 | 4.01x | 3524.000 | 1.25x | 527.000 | 50 | 0 | 50 | 0 |
| update-leaf | 50 | fusion-charm | 371.143 | 8.36x | 2838.000 | 1.01x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react-upstream | 87.038 | 1.96x | 3528.000 | 1.25x | 527.000 | 50 | 0 | 0 | 0 |
| update-fanout | 20 | bare | 1036.077 | 0.56x | 1715.000 | 0.91x | 64.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | compose | 1862.310 | 1.00x | 1876.000 | 1.00x | 65.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | fusion | 11510.808 | 6.18x | 1990.000 | 1.06x | 96.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | vide | 5711.912 | 3.07x | 1910.000 | 1.02x | 73.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react | 2275.044 | 1.22x | 2385.000 | 1.27x | 461.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | blend | 5063.203 | 2.72x | 2303.000 | 1.23x | 64.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | roact | 3400.970 | 1.83x | 2134.000 | 1.14x | 64.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | seam | 4507.198 | 2.42x | 2205.000 | 1.18x | 80.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | signals | 5874.718 | 3.15x | 2003.000 | 1.07x | 88.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react-reflex | 2385.982 | 1.28x | 2388.000 | 1.27x | 461.000 | 6000 | 0 | 20 | 0 |
| update-fanout | 20 | fusion-charm | 11496.118 | 6.17x | 1992.000 | 1.06x | 96.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react-upstream | 2252.152 | 1.21x | 2393.000 | 1.28x | 469.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | bare | 1036.658 | 0.35x | 1707.000 | 0.88x | 64.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | compose | 2961.635 | 1.00x | 1933.000 | 1.00x | 81.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | fusion | 15706.732 | 5.30x | 2257.000 | 1.17x | 128.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | vide | 6888.637 | 2.33x | 2054.000 | 1.06x | 73.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react | 3838.394 | 1.30x | 2781.000 | 1.44x | 686.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | blend | 8476.272 | 2.86x | 2576.000 | 1.33x | 64.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | roact | 5725.375 | 1.93x | 2582.000 | 1.34x | 65.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | seam | 9548.277 | 3.22x | 2992.000 | 1.55x | 104.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | signals | 8475.851 | 2.86x | 2351.000 | 1.22x | 104.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react-reflex | 25942.513 | 8.76x | 3778.000 | 1.95x | 725.000 | 6000 | 0 | 6000 | 0 |
| update-batched | 20 | fusion-charm | 31291.252 | 10.57x | 2838.000 | 1.47x | 136.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react-upstream | 3950.102 | 1.33x | 2789.000 | 1.44x | 693.000 | 6000 | 0 | 0 | 0 |
| update-repeated | 10 | bare | 38.101 | 0.15x | 14.000 | 1.27x | 8.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | compose | 256.151 | 1.00x | 11.000 | 1.00x | 2.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | fusion | unsupported: No public transaction API coalesces the 500 source writes into one host property write. | — | — | — | — | — | — | — | — |
| update-repeated | 10 | vide | 743.768 | 2.90x | 16.000 | 1.45x | 1.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | react | 12077.191 | 47.15x | 371.000 | 33.73x | 379.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | blend | 5095.083 | 19.89x | 28.000 | 2.55x | 0.000 | 10 | 0 | 0 | 10 |
| update-repeated | 10 | roact | unsupported: Roact has no public batch transaction that coalesces 500 binding writes into one host property write. | — | — | — | — | — | — | — | — |
| update-repeated | 10 | seam | 2233.527 | 8.72x | 27.000 | 2.45x | 5.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | signals | 1364.353 | 5.33x | 17.000 | 1.55x | 1.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | react-reflex | 450.536 | 1.76x | 230.000 | 20.91x | 204.000 | 10 | 0 | 10 | 0 |
| update-repeated | 10 | fusion-charm | 2915.348 | 11.38x | 28.000 | 2.55x | 9.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | react-upstream | 11936.158 | 46.60x | 372.000 | 33.82x | 372.000 | 10 | 0 | 0 | 0 |
| branch-swap | 20 | bare | 3599.383 | 0.86x | 147.000 | 1.01x | 128.000 | 500 | 510 | 0 | 0 |
| branch-swap | 20 | compose | 4198.248 | 1.00x | 145.000 | 1.00x | 129.000 | 500 | 510 | 0 | 0 |
| branch-swap | 20 | fusion | 7670.773 | 1.83x | 152.000 | 1.05x | 128.000 | 4030 | 510 | 0 | 0 |
| branch-swap | 20 | vide | 6226.940 | 1.48x | 152.000 | 1.05x | 129.000 | 3530 | 510 | 0 | 0 |
| branch-swap | 20 | react | 9035.146 | 2.15x | 709.000 | 4.89x | 347.000 | 1010 | 510 | 0 | 0 |
| branch-swap | 20 | blend | 11447.990 | 2.73x | 165.000 | 1.14x | 128.000 | 4030 | 510 | 0 | 0 |
| branch-swap | 20 | roact | 8065.164 | 1.92x | 162.000 | 1.12x | 128.000 | 1010 | 510 | 0 | 0 |
| branch-swap | 20 | seam | 6609.009 | 1.57x | 3011.000 | 20.77x | 150.000 | 500 | 510 | 10 | 0 |
| branch-swap | 20 | signals | unsupported: Signals has no native conditional Instance ownership primitive; adding a scene reconciler would change this state-only lane. | — | — | — | — | — | — | — | — |
| branch-swap | 20 | react-reflex | 9351.814 | 2.23x | 696.000 | 4.80x | 349.000 | 1010 | 510 | 20 | 0 |
| branch-swap | 20 | fusion-charm | 7096.644 | 1.69x | 90.000 | 0.62x | 65.000 | 4030 | 510 | 0 | 0 |
| branch-swap | 20 | react-upstream | 9384.603 | 2.24x | 701.000 | 4.83x | 347.000 | 1010 | 510 | 0 | 0 |
| ordered-window-scroll | 50 | bare | unsupported: the workload measures a Compose primitive's idle scroll cost; there is no hand-written equivalent to compare | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | compose | 534.374 | 1.00x | 1124.000 | 1.00x | 4.000 | 0 | 0 | 0 | 0 |
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
| keyed-append | 10 | bare | 1352.501 | 0.78x | 1756.000 | 0.78x | 64.000 | 100 | 50 | 0 | 0 |
| keyed-append | 10 | compose | 1741.683 | 1.00x | 2255.000 | 1.00x | 66.000 | 100 | 50 | 0 | 0 |
| keyed-append | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | vide | 1969.200 | 1.13x | 2339.000 | 1.04x | 65.000 | 400 | 50 | 0 | 0 |
| keyed-append | 10 | react | 14487.852 | 8.32x | 2848.000 | 1.26x | 336.000 | 150 | 50 | 0 | 0 |
| keyed-append | 10 | blend | 5140.609 | 2.95x | 3107.000 | 1.38x | 64.000 | 3500 | 50 | 0 | 0 |
| keyed-append | 10 | roact | 7102.565 | 4.08x | 2059.000 | 0.91x | 64.000 | 150 | 50 | 0 | 0 |
| keyed-append | 10 | seam | 13674.153 | 7.85x | 3506.000 | 1.55x | 141.000 | 350 | 50 | 100 | 50 |
| keyed-append | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | react-reflex | 14922.669 | 8.57x | 2843.000 | 1.26x | 346.000 | 150 | 50 | 10 | 0 |
| keyed-append | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | react-upstream | 15602.156 | 8.96x | 2848.000 | 1.26x | 337.000 | 150 | 50 | 0 | 0 |
| keyed-prepend | 10 | bare | 1740.601 | 0.38x | 1763.000 | 0.78x | 72.000 | 3100 | 50 | 0 | 0 |
| keyed-prepend | 10 | compose | 4559.757 | 1.00x | 2271.000 | 1.00x | 82.000 | 3100 | 50 | 0 | 0 |
| keyed-prepend | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | vide | 5442.517 | 1.19x | 2346.000 | 1.03x | 65.000 | 3400 | 50 | 0 | 0 |
| keyed-prepend | 10 | react | 21237.217 | 4.66x | 2787.000 | 1.23x | 344.000 | 3150 | 50 | 0 | 0 |
| keyed-prepend | 10 | blend | 4817.533 | 1.06x | 3099.000 | 1.36x | 64.000 | 3500 | 50 | 0 | 0 |
| keyed-prepend | 10 | roact | 9804.443 | 2.15x | 2052.000 | 0.90x | 64.000 | 3150 | 50 | 0 | 0 |
| keyed-prepend | 10 | seam | 14789.641 | 3.24x | 3505.000 | 1.54x | 141.000 | 3350 | 50 | 100 | 50 |
| keyed-prepend | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | react-reflex | 21151.284 | 4.64x | 2790.000 | 1.23x | 346.000 | 3150 | 50 | 10 | 0 |
| keyed-prepend | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | react-upstream | 22520.712 | 4.94x | 2788.000 | 1.23x | 344.000 | 3150 | 50 | 0 | 0 |
| keyed-insert | 10 | bare | 1587.002 | 0.51x | 1764.000 | 0.78x | 72.000 | 1600 | 50 | 0 | 0 |
| keyed-insert | 10 | compose | 3137.696 | 1.00x | 2258.000 | 1.00x | 69.000 | 1600 | 50 | 0 | 0 |
| keyed-insert | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | vide | 3854.964 | 1.23x | 2339.000 | 1.04x | 65.000 | 1900 | 50 | 0 | 0 |
| keyed-insert | 10 | react | 18948.835 | 6.04x | 2821.000 | 1.25x | 337.000 | 1650 | 50 | 0 | 0 |
| keyed-insert | 10 | blend | 4372.456 | 1.39x | 3099.000 | 1.37x | 64.000 | 3500 | 50 | 0 | 0 |
| keyed-insert | 10 | roact | 7612.453 | 2.43x | 2052.000 | 0.91x | 64.000 | 1650 | 50 | 0 | 0 |
| keyed-insert | 10 | seam | 13433.060 | 4.28x | 3505.000 | 1.55x | 141.000 | 1850 | 50 | 100 | 50 |
| keyed-insert | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | react-reflex | 18717.664 | 5.97x | 2816.000 | 1.25x | 346.000 | 1650 | 50 | 10 | 0 |
| keyed-insert | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | react-upstream | 18635.665 | 5.94x | 2821.000 | 1.25x | 344.000 | 1650 | 50 | 0 | 0 |
| keyed-remove | 10 | bare | 1516.164 | 0.51x | 1767.000 | 0.78x | 64.000 | 1510 | 50 | 0 | 0 |
| keyed-remove | 10 | compose | 3001.009 | 1.00x | 2255.000 | 1.00x | 70.000 | 1510 | 50 | 0 | 0 |
| keyed-remove | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | vide | 3795.861 | 1.26x | 2338.000 | 1.04x | 65.000 | 1810 | 50 | 0 | 0 |
| keyed-remove | 10 | react | 18856.249 | 6.28x | 2746.000 | 1.22x | 344.000 | 1560 | 50 | 0 | 0 |
| keyed-remove | 10 | blend | 4805.394 | 1.60x | 3099.000 | 1.37x | 64.000 | 3400 | 50 | 0 | 0 |
| keyed-remove | 10 | roact | 7814.107 | 2.60x | 2051.000 | 0.91x | 64.000 | 1560 | 50 | 0 | 0 |
| keyed-remove | 10 | seam | 14199.986 | 4.73x | 3504.000 | 1.55x | 140.000 | 1810 | 50 | 100 | 50 |
| keyed-remove | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | react-reflex | 18797.389 | 6.26x | 2742.000 | 1.22x | 339.000 | 1560 | 50 | 10 | 0 |
| keyed-remove | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | react-upstream | 18801.933 | 6.27x | 2740.000 | 1.22x | 337.000 | 1560 | 50 | 0 | 0 |
| keyed-replace | 10 | bare | 29436.021 | 0.44x | 2223.000 | 0.90x | 504.000 | 6000 | 3000 | 0 | 0 |
| keyed-replace | 10 | compose | 66928.605 | 1.00x | 2474.000 | 1.00x | 257.000 | 6000 | 3000 | 0 | 0 |
| keyed-replace | 10 | fusion | 130841.664 | 1.95x | 4035.000 | 1.63x | 1032.000 | 27300 | 3000 | 0 | 0 |
| keyed-replace | 10 | vide | 61390.722 | 0.92x | 2833.000 | 1.15x | 521.000 | 24000 | 3000 | 0 | 0 |
| keyed-replace | 10 | react | 104744.624 | 1.57x | 4750.000 | 1.92x | 818.000 | 9000 | 3000 | 0 | 0 |
| keyed-replace | 10 | blend | 144337.714 | 2.16x | 6174.000 | 2.50x | 505.000 | 30000 | 3000 | 0 | 0 |
| keyed-replace | 10 | roact | 44346.897 | 0.66x | 2274.000 | 0.92x | 256.000 | 9000 | 3000 | 0 | 0 |
| keyed-replace | 10 | seam | 146260.683 | 2.19x | 31568.000 | 12.76x | 732.000 | 22500 | 3000 | 6000 | 3000 |
| keyed-replace | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-replace | 10 | react-reflex | 102066.542 | 1.53x | 4752.000 | 1.92x | 828.000 | 9000 | 3000 | 10 | 0 |
| keyed-replace | 10 | fusion-charm | 125285.465 | 1.87x | 4036.000 | 1.63x | 1025.000 | 27300 | 3000 | 0 | 0 |
| keyed-replace | 10 | react-upstream | 101827.365 | 1.52x | 4742.000 | 1.92x | 818.000 | 9000 | 3000 | 0 | 0 |
| keyed-reverse | 10 | bare | 1214.419 | 0.35x | 1759.000 | 0.78x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | compose | 3457.719 | 1.00x | 2259.000 | 1.00x | 81.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | fusion | 24430.323 | 7.07x | 3171.000 | 1.40x | 192.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | vide | 3641.996 | 1.05x | 2322.000 | 1.03x | 65.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | react | 60009.943 | 17.36x | 2732.000 | 1.21x | 342.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | blend | 2390.187 | 0.69x | 3057.000 | 1.35x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | roact | 7963.940 | 2.30x | 2051.000 | 0.91x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | seam | 12900.077 | 3.73x | 3044.000 | 1.35x | 140.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-reverse | 10 | react-reflex | 59801.403 | 17.30x | 2727.000 | 1.21x | 345.000 | 3000 | 0 | 10 | 0 |
| keyed-reverse | 10 | fusion-charm | 25380.655 | 7.34x | 3172.000 | 1.40x | 192.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | react-upstream | 60394.867 | 17.47x | 2732.000 | 1.21x | 335.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | bare | 1221.834 | 0.33x | 1759.000 | 0.78x | 72.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | compose | 3713.735 | 1.00x | 2259.000 | 1.00x | 74.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | fusion | 24929.236 | 6.71x | 3171.000 | 1.40x | 192.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | vide | 3892.440 | 1.05x | 2322.000 | 1.03x | 65.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | react | 39868.115 | 10.74x | 2732.000 | 1.21x | 343.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | blend | 2496.648 | 0.67x | 3065.000 | 1.36x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | roact | 9053.168 | 2.44x | 2051.000 | 0.91x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | seam | 12852.793 | 3.46x | 3044.000 | 1.35x | 140.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-rotate | 10 | react-reflex | 40505.901 | 10.91x | 2735.000 | 1.21x | 337.000 | 3000 | 0 | 10 | 0 |
| keyed-rotate | 10 | fusion-charm | 25325.277 | 6.82x | 3165.000 | 1.40x | 192.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | react-upstream | 41199.141 | 11.09x | 2725.000 | 1.21x | 342.000 | 3000 | 0 | 0 | 0 |
| keyed-shuffle | 10 | bare | 1322.323 | 0.37x | 1751.000 | 0.78x | 56.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | compose | 3582.286 | 1.00x | 2259.000 | 1.00x | 82.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | fusion | 24853.646 | 6.94x | 3171.000 | 1.40x | 192.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | vide | 3676.454 | 1.03x | 2322.000 | 1.03x | 65.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | react | 38373.228 | 10.71x | 2732.000 | 1.21x | 335.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | blend | 2541.874 | 0.71x | 3064.000 | 1.36x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-shuffle | 10 | roact | 9064.045 | 2.53x | 2051.000 | 0.91x | 64.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | seam | 12986.181 | 3.63x | 3045.000 | 1.35x | 140.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-shuffle | 10 | react-reflex | 39298.279 | 10.97x | 2735.000 | 1.21x | 337.000 | 2990 | 0 | 10 | 0 |
| keyed-shuffle | 10 | fusion-charm | 25076.754 | 7.00x | 3172.000 | 1.40x | 192.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | react-upstream | 37436.393 | 10.45x | 2732.000 | 1.21x | 343.000 | 2990 | 0 | 0 | 0 |
| events | 5 | bare | 11033.038 | 0.80x | 129.000 | 1.06x | 128.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | compose | 13827.922 | 1.00x | 122.000 | 1.00x | 129.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | fusion | 20732.347 | 1.50x | 129.000 | 1.06x | 128.000 | 9015 | 1005 | 1000 | 0 |
| events | 5 | vide | 16954.407 | 1.23x | 130.000 | 1.07x | 129.000 | 8015 | 1005 | 1000 | 0 |
| events | 5 | react | 59295.698 | 4.29x | 470.000 | 3.85x | 462.000 | 2000 | 1005 | 1000 | 1 |
| events | 5 | blend | 33930.035 | 2.45x | 130.000 | 1.07x | 128.000 | 9015 | 1005 | 1000 | 0 |
| events | 5 | roact | 21787.540 | 1.58x | 129.000 | 1.06x | 128.000 | 2005 | 1005 | 1000 | 0 |
| events | 5 | seam | 19893.667 | 1.44x | 129.000 | 1.06x | 128.000 | 1000 | 1005 | 1005 | 0 |
| events | 5 | signals | 13239.254 | 0.96x | 145.000 | 1.19x | 144.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | react-reflex | 59719.464 | 4.32x | 477.000 | 3.91x | 477.000 | 2000 | 1005 | 1000 | 1 |
| events | 5 | fusion-charm | 22544.888 | 1.63x | 129.000 | 1.06x | 136.000 | 9015 | 1005 | 1000 | 0 |
| events | 5 | react-upstream | 64266.688 | 4.65x | 463.000 | 3.80x | 470.000 | 2000 | 1005 | 1000 | 1 |
| animate-many | 1 | bare | 1702.763 | 0.20x | 1539.000 | 0.64x | 32.000 | 6000 | 0 | 0 | 0 |
| animate-many | 1 | compose | 8524.550 | 1.00x | 2406.000 | 1.00x | 41.000 | 6000 | 0 | 1 | 0 |
| animate-many | 1 | fusion | 152082.155 | 17.84x | 2762.000 | 1.15x | 164.000 | 3600 | 0 | 0 | 0 |
| animate-many | 1 | vide | 11276.098 | 1.32x | 1976.000 | 0.82x | 53.000 | 6000 | 0 | 0 | 30 |
| animate-many | 1 | react | unsupported: React and ReactRoblox have no native spring primitive. Adding another animation library would change the comparison. | — | — | — | — | — | — | — | — |
| animate-many | 1 | blend | 13703.542 | 1.61x | 2743.000 | 1.14x | 96.000 | 6200 | 0 | 200 | 0 |
| animate-many | 1 | roact | unsupported: Roact has no native spring primitive. | — | — | — | — | — | — | — | — |
| animate-many | 1 | seam | 31403.055 | 3.68x | 3603.000 | 1.50x | 69.000 | 3600 | 0 | 0 | 0 |
| animate-many | 1 | signals | unsupported: Signals has no native spring primitive. | — | — | — | — | — | — | — | — |
| animate-many | 1 | react-reflex | unsupported: React and ReactRoblox have no native spring primitive. Adding another animation library would change the comparison. | — | — | — | — | — | — | — | — |
| animate-many | 1 | fusion-charm | 146024.673 | 17.13x | 2764.000 | 1.15x | 164.000 | 3600 | 0 | 0 | 0 |
| animate-many | 1 | react-upstream | unsupported: React and ReactRoblox have no native spring primitive. Adding another animation library would change the comparison. | — | — | — | — | — | — | — | — |
| status-panel | 20 | bare | 192.576 | 0.33x | 140.000 | 0.74x | 10.000 | 82 | 21 | 0 | 0 |
| status-panel | 20 | compose | 589.627 | 1.00x | 190.000 | 1.00x | 11.000 | 82 | 21 | 0 | 0 |
| status-panel | 20 | fusion | 2929.267 | 4.97x | 257.000 | 1.35x | 14.000 | 229 | 21 | 0 | 0 |
| status-panel | 20 | vide | 573.006 | 0.97x | 199.000 | 1.05x | 3.000 | 208 | 21 | 0 | 0 |
| status-panel | 20 | react | 2939.923 | 4.99x | 424.000 | 2.23x | 220.000 | 103 | 21 | 0 | 0 |
| status-panel | 20 | blend | 1093.318 | 1.85x | 250.000 | 1.32x | 2.000 | 438 | 21 | 0 | 0 |
| status-panel | 20 | roact | 845.138 | 1.43x | 178.000 | 0.94x | 2.000 | 103 | 21 | 0 | 0 |
| status-panel | 20 | seam | unsupported: Seam's native computed-property type guard rejects the workload's synthetic Frame.Text property, whose default type is nil. | — | — | — | — | — | — | — | — |
| status-panel | 20 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| status-panel | 20 | react-reflex | 3025.357 | 5.13x | 433.000 | 2.28x | 223.000 | 103 | 21 | 60 | 0 |
| status-panel | 20 | fusion-charm | 3238.728 | 5.49x | 263.000 | 1.38x | 14.000 | 229 | 21 | 0 | 0 |
| status-panel | 20 | react-upstream | 2743.398 | 4.65x | 431.000 | 2.27x | 228.000 | 103 | 21 | 0 | 0 |
| mount-cycles | 1 | bare | 21197.114 | 0.69x | 129.000 | 0.93x | 137.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | compose | 30508.996 | 1.00x | 138.000 | 1.00x | 138.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | fusion | 35256.660 | 1.16x | 257.000 | 1.86x | 256.000 | 16290 | 1830 | 1800 | 0 |
| mount-cycles | 1 | vide | 29189.907 | 0.96x | 258.000 | 1.87x | 257.000 | 14490 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react | 77297.451 | 2.53x | 518.000 | 3.75x | 517.000 | 3600 | 1830 | 1800 | 1 |
| mount-cycles | 1 | blend | 58723.854 | 1.92x | 137.000 | 0.99x | 128.000 | 16290 | 1830 | 1800 | 0 |
| mount-cycles | 1 | roact | 35807.792 | 1.17x | 257.000 | 1.86x | 257.000 | 3630 | 1830 | 1800 | 0 |
| mount-cycles | 1 | seam | 34850.469 | 1.14x | 257.000 | 1.86x | 256.000 | 1800 | 1830 | 1830 | 0 |
| mount-cycles | 1 | signals | 25399.167 | 0.83x | 261.000 | 1.89x | 260.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react-reflex | 77343.959 | 2.54x | 525.000 | 3.80x | 517.000 | 3600 | 1830 | 1800 | 1 |
| mount-cycles | 1 | fusion-charm | 34873.884 | 1.14x | 258.000 | 1.87x | 257.000 | 16290 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react-upstream | 86209.453 | 2.83x | 518.000 | 3.75x | 517.000 | 3600 | 1830 | 1800 | 1 |
| scene-3d | 20 | bare | 4524.229 | 0.48x | 1060.000 | 0.84x | 32.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | compose | 9337.074 | 1.00x | 1266.000 | 1.00x | 34.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | fusion | 87678.446 | 9.39x | 1671.000 | 1.32x | 97.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | vide | 11994.791 | 1.28x | 1288.000 | 1.02x | 42.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react | 8184.142 | 0.88x | 1752.000 | 1.38x | 502.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | blend | 10762.286 | 1.15x | 1606.000 | 1.27x | 32.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | roact | unsupported: Roact assigns Instance.Name from reconciliation keys. Named children use dictionary keys, whose mounting order cannot satisfy this workload's ordered named-tree contract. | — | — | — | — | — | — | — | — |
| scene-3d | 20 | seam | 23128.088 | 2.48x | 2273.000 | 1.80x | 54.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | signals | 16895.656 | 1.81x | 1809.000 | 1.43x | 64.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react-reflex | 8021.448 | 0.86x | 1757.000 | 1.39x | 509.000 | 6000 | 0 | 40 | 0 |
| scene-3d | 20 | fusion-charm | 90851.445 | 9.73x | 1675.000 | 1.32x | 96.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react-upstream | 7897.568 | 0.85x | 1752.000 | 1.38x | 509.000 | 6000 | 0 | 0 | 0 |
| unwind | 10 | bare | 4902.437 | 0.92x | 73.000 | 0.53x | 65.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | compose | 5322.275 | 1.00x | 137.000 | 1.00x | 137.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | fusion | 8028.228 | 1.51x | 129.000 | 0.94x | 128.000 | 5310 | 590 | 0 | 0 |
| unwind | 10 | vide | 7051.403 | 1.32x | 130.000 | 0.95x | 129.000 | 2360 | 590 | 0 | 0 |
| unwind | 10 | react | unsupported: A failed native render, including an error boundary, leaves abandoned cost-model host nodes after root unmount. It does not satisfy the partial-build rollback contract. | — | — | — | — | — | — | — | — |
| unwind | 10 | blend | unsupported: An error during native observable subscription leaves the partially created cost-model nodes without a returned cleanup resource. It does not satisfy failed-build rollback. | — | — | — | — | — | — | — | — |
| unwind | 10 | roact | unsupported: Roact's public mount API returns its cleanup handle only after a successful mount; failed render rollback is not guaranteed. | — | — | — | — | — | — | — | — |
| unwind | 10 | seam | 6134.460 | 1.15x | 129.000 | 0.94x | 128.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | signals | 5507.883 | 1.03x | 130.000 | 0.95x | 129.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | react-reflex | unsupported: A failed native render, including an error boundary, leaves abandoned cost-model host nodes after root unmount. It does not satisfy the partial-build rollback contract. | — | — | — | — | — | — | — | — |
| unwind | 10 | fusion-charm | 7830.231 | 1.47x | 137.000 | 1.00x | 136.000 | 5310 | 590 | 0 | 0 |
| unwind | 10 | react-upstream | unsupported: A failed native render, including an error boundary, leaves abandoned cost-model host nodes after root unmount. It does not satisfy the partial-build rollback contract. | — | — | — | — | — | — | — | — |

## Source identities

Compose revision: `00a663bd22fda7274b5973c61a23fbecf36fda45`. Full source state, tools, environment and command are in `context.json`.

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
