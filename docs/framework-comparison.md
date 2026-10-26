# Framework comparison

Compose against other Roblox UI libraries on the same 24 runtime workloads.

- Compose commit: `ed40b10` (main, 2026-10-26)
- Run: [Framework comparison #40327417921](https://github.com/voidmeld/compose/actions/runs/40327417921) on the GitHub-hosted Ubuntu runner
- Verdict: release. Only passed measurements appear in the table.
- Method: [Manual framework comparison](benchmarks.md#manual-framework-comparison). The workflow runs the parity checks before timing, and both are headless cost-model measurements. They do not measure Roblox engine rendering.

Ratios divide by Compose, so a value below 1.00x is smaller than Compose. Rerun the workflow and replace this page to update it.

Headless cost-model samples. Time is per complete workload sample, including its iteration count. Ratios divide by Compose; lower is smaller. Heap is the mounted retained Luau estimate. Writes, Created, Connections and Deferred count the engine property writes, instances, signal connections and deferred tasks of the timed iterations. A zero heap baseline has no ratio. These results do not measure Roblox engine performance.

| Workload | Iterations | Framework | Median time (us) | / Compose | Median heap (KiB) | / Compose | Teardown (KiB) | Writes | Created | Connections | Deferred |
| --- | ---: | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| cold-mount-100 | 1 | bare | 586.787 | 0.76x | 571.000 | 1.00x | 16.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | compose | 775.113 | 1.00x | 569.000 | 1.00x | 17.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | fusion | 710.873 | 0.92x | 588.000 | 1.03x | 16.000 | 803 | 101 | 0 | 0 |
| cold-mount-100 | 1 | vide | 675.653 | 0.87x | 578.000 | 1.02x | 25.000 | 703 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react | 33441.697 | 43.14x | 877.000 | 1.54x | 264.000 | 200 | 101 | 0 | 1 |
| cold-mount-100 | 1 | blend | 1276.014 | 1.65x | 709.000 | 1.25x | 16.000 | 803 | 101 | 0 | 0 |
| cold-mount-100 | 1 | roact | 802.810 | 1.04x | 670.000 | 1.18x | 17.000 | 201 | 101 | 0 | 0 |
| cold-mount-100 | 1 | seam | 641.093 | 0.83x | 593.000 | 1.04x | 25.000 | 100 | 101 | 1 | 0 |
| cold-mount-100 | 1 | signals | 402.537 | 0.52x | 585.000 | 1.03x | 19.000 | 100 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react-reflex | 34128.796 | 44.03x | 877.000 | 1.54x | 280.000 | 200 | 101 | 0 | 1 |
| cold-mount-100 | 1 | fusion-charm | 831.639 | 1.07x | 572.000 | 1.01x | 9.000 | 803 | 101 | 0 | 0 |
| cold-mount-100 | 1 | react-upstream | 43975.271 | 56.73x | 878.000 | 1.54x | 272.000 | 200 | 101 | 0 | 1 |
| cold-mount-1000 | 1 | bare | 5054.365 | 0.81x | 5613.000 | 1.00x | 128.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | compose | 6254.652 | 1.00x | 5633.000 | 1.00x | 130.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | fusion | 8926.175 | 1.43x | 5664.000 | 1.01x | 129.000 | 8003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | vide | 8147.695 | 1.30x | 5655.000 | 1.00x | 122.000 | 7003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react | 48174.220 | 7.70x | 6832.000 | 1.21x | 847.000 | 2000 | 1001 | 0 | 1 |
| cold-mount-1000 | 1 | blend | 13897.434 | 2.22x | 6953.000 | 1.23x | 129.000 | 8003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | roact | 9428.358 | 1.51x | 6573.000 | 1.17x | 128.000 | 2001 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | seam | 8013.820 | 1.28x | 5682.000 | 1.01x | 128.000 | 1000 | 1001 | 1 | 0 |
| cold-mount-1000 | 1 | signals | 6186.140 | 0.99x | 5661.000 | 1.00x | 144.000 | 1000 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react-reflex | 45924.450 | 7.34x | 6832.000 | 1.21x | 855.000 | 2000 | 1001 | 0 | 1 |
| cold-mount-1000 | 1 | fusion-charm | 9648.085 | 1.54x | 5663.000 | 1.01x | 128.000 | 8003 | 1001 | 0 | 0 |
| cold-mount-1000 | 1 | react-upstream | 53817.074 | 8.60x | 6833.000 | 1.21x | 856.000 | 2000 | 1001 | 0 | 1 |
| cold-mount-10000 | 1 | bare | 74883.217 | 0.73x | 57037.000 | 0.99x | 2065.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | compose | 102446.568 | 1.00x | 57381.000 | 1.00x | 2058.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | fusion | 120455.224 | 1.18x | 57755.000 | 1.01x | 2049.000 | 80003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | vide | 111028.955 | 1.08x | 57592.000 | 1.00x | 2050.000 | 70003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react | 178923.618 | 1.75x | 67750.000 | 1.18x | 7922.000 | 20000 | 10001 | 0 | 1 |
| cold-mount-10000 | 1 | blend | 181827.235 | 1.77x | 70441.000 | 1.23x | 2050.000 | 80003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | roact | 119345.366 | 1.16x | 66767.000 | 1.16x | 2049.000 | 20001 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | seam | 88424.312 | 0.86x | 58022.000 | 1.01x | 2050.000 | 10000 | 10001 | 1 | 0 |
| cold-mount-10000 | 1 | signals | 83346.055 | 0.81x | 57582.000 | 1.00x | 2305.000 | 10000 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react-reflex | 172408.091 | 1.68x | 67750.000 | 1.18x | 7923.000 | 20000 | 10001 | 0 | 1 |
| cold-mount-10000 | 1 | fusion-charm | 124008.098 | 1.21x | 57755.000 | 1.01x | 2050.000 | 80003 | 10001 | 0 | 0 |
| cold-mount-10000 | 1 | react-upstream | 180146.967 | 1.76x | 67742.000 | 1.18x | 7923.000 | 20000 | 10001 | 0 | 1 |
| mount-dispose | 5 | bare | 7222.223 | 0.92x | 137.000 | 1.05x | 128.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | compose | 7887.457 | 1.00x | 130.000 | 1.00x | 137.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | fusion | 11301.459 | 1.43x | 129.000 | 0.99x | 129.000 | 8015 | 1005 | 0 | 0 |
| mount-dispose | 5 | vide | 8380.050 | 1.06x | 131.000 | 1.01x | 130.000 | 7015 | 1005 | 0 | 0 |
| mount-dispose | 5 | react | 46895.405 | 5.95x | 448.000 | 3.45x | 440.000 | 2000 | 1005 | 0 | 1 |
| mount-dispose | 5 | blend | 17971.187 | 2.28x | 129.000 | 0.99x | 129.000 | 8015 | 1005 | 0 | 0 |
| mount-dispose | 5 | roact | 10021.382 | 1.27x | 129.000 | 0.99x | 128.000 | 2005 | 1005 | 0 | 0 |
| mount-dispose | 5 | seam | 8693.182 | 1.10x | 129.000 | 0.99x | 129.000 | 1000 | 1005 | 5 | 0 |
| mount-dispose | 5 | signals | 6772.244 | 0.86x | 134.000 | 1.03x | 133.000 | 1000 | 1005 | 0 | 0 |
| mount-dispose | 5 | react-reflex | 48176.169 | 6.11x | 441.000 | 3.39x | 440.000 | 2000 | 1005 | 0 | 1 |
| mount-dispose | 5 | fusion-charm | 11528.487 | 1.46x | 129.000 | 0.99x | 129.000 | 8015 | 1005 | 0 | 0 |
| mount-dispose | 5 | react-upstream | 58069.574 | 7.36x | 433.000 | 3.33x | 433.000 | 2000 | 1005 | 0 | 1 |
| update-leaf | 50 | bare | 16.365 | 0.40x | 2808.000 | 1.00x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | compose | 40.536 | 1.00x | 2820.000 | 1.00x | 66.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | fusion | 149.053 | 3.68x | 2835.000 | 1.01x | 57.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | vide | 83.440 | 2.06x | 2835.000 | 1.01x | 65.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react | 71.890 | 1.77x | 3528.000 | 1.25x | 527.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | blend | 90.615 | 2.24x | 3485.000 | 1.24x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | roact | 51.591 | 1.27x | 3294.000 | 1.17x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | seam | 148.613 | 3.67x | 2849.000 | 1.01x | 64.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | signals | 95.979 | 2.37x | 2834.000 | 1.00x | 73.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react-reflex | 133.525 | 3.29x | 3531.000 | 1.25x | 527.000 | 50 | 0 | 50 | 0 |
| update-leaf | 50 | fusion-charm | 330.363 | 8.15x | 2838.000 | 1.01x | 65.000 | 50 | 0 | 0 | 0 |
| update-leaf | 50 | react-upstream | 69.555 | 1.72x | 3529.000 | 1.25x | 536.000 | 50 | 0 | 0 | 0 |
| update-fanout | 20 | bare | 1066.193 | 0.56x | 1715.000 | 0.92x | 64.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | compose | 1897.087 | 1.00x | 1869.000 | 1.00x | 65.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | fusion | 11194.311 | 5.90x | 1982.000 | 1.06x | 89.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | vide | 5625.136 | 2.97x | 1911.000 | 1.02x | 81.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react | 2192.409 | 1.16x | 2393.000 | 1.28x | 469.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | blend | 5065.179 | 2.67x | 2296.000 | 1.23x | 64.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | roact | 3055.122 | 1.61x | 2126.000 | 1.14x | 57.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | seam | 4398.233 | 2.32x | 2205.000 | 1.18x | 80.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | signals | 5729.081 | 3.02x | 2003.000 | 1.07x | 88.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react-reflex | 2275.608 | 1.20x | 2396.000 | 1.28x | 461.000 | 6000 | 0 | 20 | 0 |
| update-fanout | 20 | fusion-charm | 11451.638 | 6.04x | 1984.000 | 1.06x | 97.000 | 6000 | 0 | 0 | 0 |
| update-fanout | 20 | react-upstream | 2222.275 | 1.17x | 2386.000 | 1.28x | 461.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | bare | 1065.034 | 0.35x | 1723.000 | 0.89x | 64.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | compose | 3081.659 | 1.00x | 1933.000 | 1.00x | 73.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | fusion | 15197.602 | 4.93x | 2256.000 | 1.17x | 121.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | vide | 6813.984 | 2.21x | 2055.000 | 1.06x | 73.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react | 3637.295 | 1.18x | 2781.000 | 1.44x | 685.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | blend | 8241.344 | 2.67x | 2568.000 | 1.33x | 65.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | roact | 5199.433 | 1.69x | 2582.000 | 1.34x | 64.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | seam | 9046.465 | 2.94x | 2992.000 | 1.55x | 104.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | signals | 8157.085 | 2.65x | 2351.000 | 1.22x | 104.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react-reflex | 23972.170 | 7.78x | 3778.000 | 1.95x | 726.000 | 6000 | 0 | 6000 | 0 |
| update-batched | 20 | fusion-charm | 29191.071 | 9.47x | 2838.000 | 1.47x | 128.000 | 6000 | 0 | 0 | 0 |
| update-batched | 20 | react-upstream | 3601.424 | 1.17x | 2782.000 | 1.44x | 686.000 | 6000 | 0 | 0 | 0 |
| update-repeated | 10 | bare | 37.550 | 0.10x | 22.000 | 0.81x | 1.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | compose | 386.356 | 1.00x | 27.000 | 1.00x | 10.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | fusion | unsupported: No public transaction API coalesces the 500 source writes into one host property write. | — | — | — | — | — | — | — | — |
| update-repeated | 10 | vide | 743.268 | 1.92x | 17.000 | 0.63x | 2.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | react | 11999.225 | 31.06x | 372.000 | 13.78x | 372.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | blend | 5040.410 | 13.05x | 28.000 | 1.04x | 8.000 | 10 | 0 | 0 | 10 |
| update-repeated | 10 | roact | unsupported: Roact has no public batch transaction that coalesces 500 binding writes into one host property write. | — | — | — | — | — | — | — | — |
| update-repeated | 10 | seam | 2157.352 | 5.58x | 35.000 | 1.30x | 6.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | signals | 1374.145 | 3.56x | 17.000 | 0.63x | 1.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | react-reflex | 461.868 | 1.20x | 230.000 | 8.52x | 204.000 | 10 | 0 | 10 | 0 |
| update-repeated | 10 | fusion-charm | 2907.164 | 7.52x | 12.000 | 0.44x | 1.000 | 10 | 0 | 0 | 0 |
| update-repeated | 10 | react-upstream | 11863.442 | 30.71x | 365.000 | 13.52x | 373.000 | 10 | 0 | 0 | 0 |
| branch-swap | 20 | bare | 3100.551 | 0.70x | 147.000 | 1.01x | 128.000 | 500 | 510 | 0 | 0 |
| branch-swap | 20 | compose | 4431.499 | 1.00x | 145.000 | 1.00x | 130.000 | 500 | 510 | 0 | 0 |
| branch-swap | 20 | fusion | 6006.847 | 1.36x | 159.000 | 1.10x | 136.000 | 4030 | 510 | 0 | 0 |
| branch-swap | 20 | vide | 4922.063 | 1.11x | 161.000 | 1.11x | 130.000 | 3530 | 510 | 0 | 0 |
| branch-swap | 20 | react | 8134.930 | 1.84x | 709.000 | 4.89x | 354.000 | 1010 | 510 | 0 | 0 |
| branch-swap | 20 | blend | 9884.998 | 2.23x | 158.000 | 1.09x | 121.000 | 4030 | 510 | 0 | 0 |
| branch-swap | 20 | roact | 5340.425 | 1.21x | 155.000 | 1.07x | 128.000 | 1010 | 510 | 0 | 0 |
| branch-swap | 20 | seam | 4822.353 | 1.09x | 3011.000 | 20.77x | 149.000 | 500 | 510 | 10 | 0 |
| branch-swap | 20 | signals | unsupported: Signals has no native conditional Instance ownership primitive; adding a scene reconciler would change this state-only lane. | — | — | — | — | — | — | — | — |
| branch-swap | 20 | react-reflex | 8553.258 | 1.93x | 704.000 | 4.86x | 350.000 | 1010 | 510 | 20 | 0 |
| branch-swap | 20 | fusion-charm | 5762.143 | 1.30x | 146.000 | 1.01x | 129.000 | 4030 | 510 | 0 | 0 |
| branch-swap | 20 | react-upstream | 9489.633 | 2.14x | 638.000 | 4.40x | 283.000 | 1010 | 510 | 0 | 0 |
| ordered-window-scroll | 50 | bare | unsupported: the workload measures a Compose primitive's idle scroll cost; there is no hand-written equivalent to compare | — | — | — | — | — | — | — | — |
| ordered-window-scroll | 50 | compose | 551.550 | 1.00x | 1123.000 | 1.00x | 3.000 | 0 | 0 | 0 | 0 |
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
| keyed-append | 10 | bare | 1332.529 | 0.72x | 1764.000 | 0.78x | 64.000 | 100 | 50 | 0 | 0 |
| keyed-append | 10 | compose | 1863.434 | 1.00x | 2255.000 | 1.00x | 73.000 | 100 | 50 | 0 | 0 |
| keyed-append | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | vide | 1985.253 | 1.07x | 2339.000 | 1.04x | 65.000 | 400 | 50 | 0 | 0 |
| keyed-append | 10 | react | 13821.413 | 7.42x | 2848.000 | 1.26x | 337.000 | 150 | 50 | 0 | 0 |
| keyed-append | 10 | blend | 4501.265 | 2.42x | 3099.000 | 1.37x | 72.000 | 3500 | 50 | 0 | 0 |
| keyed-append | 10 | roact | 6641.806 | 3.56x | 2052.000 | 0.91x | 64.000 | 150 | 50 | 0 | 0 |
| keyed-append | 10 | seam | 12382.498 | 6.64x | 3506.000 | 1.55x | 142.000 | 350 | 50 | 100 | 50 |
| keyed-append | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | react-reflex | 14253.277 | 7.65x | 2851.000 | 1.26x | 347.000 | 150 | 50 | 10 | 0 |
| keyed-append | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-append | 10 | react-upstream | 14824.251 | 7.96x | 2841.000 | 1.26x | 337.000 | 150 | 50 | 0 | 0 |
| keyed-prepend | 10 | bare | 1719.796 | 0.31x | 1764.000 | 0.75x | 64.000 | 3100 | 50 | 0 | 0 |
| keyed-prepend | 10 | compose | 5503.892 | 1.00x | 2338.000 | 1.00x | 73.000 | 3100 | 50 | 0 | 0 |
| keyed-prepend | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | vide | 5518.159 | 1.00x | 2331.000 | 1.00x | 58.000 | 3400 | 50 | 0 | 0 |
| keyed-prepend | 10 | react | 20185.039 | 3.67x | 2787.000 | 1.19x | 336.000 | 3150 | 50 | 0 | 0 |
| keyed-prepend | 10 | blend | 4341.254 | 0.79x | 3107.000 | 1.33x | 73.000 | 3500 | 50 | 0 | 0 |
| keyed-prepend | 10 | roact | 8653.253 | 1.57x | 2059.000 | 0.88x | 64.000 | 3150 | 50 | 0 | 0 |
| keyed-prepend | 10 | seam | 13910.583 | 2.53x | 3512.000 | 1.50x | 141.000 | 3350 | 50 | 100 | 50 |
| keyed-prepend | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | react-reflex | 20356.227 | 3.70x | 2799.000 | 1.20x | 339.000 | 3150 | 50 | 10 | 0 |
| keyed-prepend | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-prepend | 10 | react-upstream | 21182.394 | 3.85x | 2788.000 | 1.19x | 329.000 | 3150 | 50 | 0 | 0 |
| keyed-insert | 10 | bare | 1539.404 | 0.42x | 1764.000 | 0.77x | 64.000 | 1600 | 50 | 0 | 0 |
| keyed-insert | 10 | compose | 3668.441 | 1.00x | 2296.000 | 1.00x | 70.000 | 1600 | 50 | 0 | 0 |
| keyed-insert | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | vide | 3601.116 | 0.98x | 2347.000 | 1.02x | 65.000 | 1900 | 50 | 0 | 0 |
| keyed-insert | 10 | react | 18054.760 | 4.92x | 2821.000 | 1.23x | 344.000 | 1650 | 50 | 0 | 0 |
| keyed-insert | 10 | blend | 4319.118 | 1.18x | 3107.000 | 1.35x | 73.000 | 3500 | 50 | 0 | 0 |
| keyed-insert | 10 | roact | 7827.518 | 2.13x | 2060.000 | 0.90x | 64.000 | 1650 | 50 | 0 | 0 |
| keyed-insert | 10 | seam | 13438.428 | 3.66x | 3505.000 | 1.53x | 141.000 | 1850 | 50 | 100 | 50 |
| keyed-insert | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | react-reflex | 17629.467 | 4.81x | 2824.000 | 1.23x | 339.000 | 1650 | 50 | 10 | 0 |
| keyed-insert | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-insert | 10 | react-upstream | 17329.463 | 4.72x | 2822.000 | 1.23x | 337.000 | 1650 | 50 | 0 | 0 |
| keyed-remove | 10 | bare | 1489.919 | 0.43x | 1759.000 | 0.77x | 64.000 | 1510 | 50 | 0 | 0 |
| keyed-remove | 10 | compose | 3480.366 | 1.00x | 2297.000 | 1.00x | 77.000 | 1510 | 50 | 0 | 0 |
| keyed-remove | 10 | fusion | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | vide | 3445.370 | 0.99x | 2339.000 | 1.02x | 65.000 | 1810 | 50 | 0 | 0 |
| keyed-remove | 10 | react | 17511.049 | 5.03x | 2740.000 | 1.19x | 344.000 | 1560 | 50 | 0 | 0 |
| keyed-remove | 10 | blend | 4328.923 | 1.24x | 3098.000 | 1.35x | 65.000 | 3400 | 50 | 0 | 0 |
| keyed-remove | 10 | roact | 7662.511 | 2.20x | 2051.000 | 0.89x | 64.000 | 1560 | 50 | 0 | 0 |
| keyed-remove | 10 | seam | 12729.665 | 3.66x | 3512.000 | 1.53x | 141.000 | 1810 | 50 | 100 | 50 |
| keyed-remove | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | react-reflex | 17610.451 | 5.06x | 2742.000 | 1.19x | 339.000 | 1560 | 50 | 10 | 0 |
| keyed-remove | 10 | fusion-charm | unsupported: The pinned native ForPairs mapper can reassign a removed key's scope to a retained key. The shrink step fails retained-node identity. | — | — | — | — | — | — | — | — |
| keyed-remove | 10 | react-upstream | 17858.180 | 5.13x | 2748.000 | 1.20x | 337.000 | 1560 | 50 | 0 | 0 |
| keyed-replace | 10 | bare | 26636.025 | 0.45x | 2232.000 | 0.91x | 512.000 | 6000 | 3000 | 0 | 0 |
| keyed-replace | 10 | compose | 59731.797 | 1.00x | 2466.000 | 1.00x | 258.000 | 6000 | 3000 | 0 | 0 |
| keyed-replace | 10 | fusion | 114007.619 | 1.91x | 4027.000 | 1.63x | 1025.000 | 27300 | 3000 | 0 | 0 |
| keyed-replace | 10 | vide | 51182.226 | 0.86x | 2834.000 | 1.15x | 514.000 | 24000 | 3000 | 0 | 0 |
| keyed-replace | 10 | react | 93942.888 | 1.57x | 4749.000 | 1.93x | 826.000 | 9000 | 3000 | 0 | 0 |
| keyed-replace | 10 | blend | 129760.741 | 2.17x | 5925.000 | 2.40x | 265.000 | 30000 | 3000 | 0 | 0 |
| keyed-replace | 10 | roact | 38529.974 | 0.65x | 2266.000 | 0.92x | 264.000 | 9000 | 3000 | 0 | 0 |
| keyed-replace | 10 | seam | 127393.532 | 2.13x | 31576.000 | 12.80x | 725.000 | 22500 | 3000 | 6000 | 3000 |
| keyed-replace | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-replace | 10 | react-reflex | 94291.685 | 1.58x | 4753.000 | 1.93x | 821.000 | 9000 | 3000 | 10 | 0 |
| keyed-replace | 10 | fusion-charm | 112506.823 | 1.88x | 4036.000 | 1.64x | 1025.000 | 27300 | 3000 | 0 | 0 |
| keyed-replace | 10 | react-upstream | 94309.761 | 1.58x | 4742.000 | 1.92x | 811.000 | 9000 | 3000 | 0 | 0 |
| keyed-reverse | 10 | bare | 1212.738 | 0.30x | 1760.000 | 0.75x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | compose | 4016.641 | 1.00x | 2334.000 | 1.00x | 74.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | fusion | 23111.159 | 5.75x | 3179.000 | 1.36x | 193.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | vide | 3579.340 | 0.89x | 2322.000 | 0.99x | 65.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | react | 59081.572 | 14.71x | 2732.000 | 1.17x | 334.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | blend | 2312.273 | 0.58x | 3065.000 | 1.31x | 72.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | roact | 7797.589 | 1.94x | 2051.000 | 0.88x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | seam | 11829.477 | 2.95x | 3044.000 | 1.30x | 140.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-reverse | 10 | react-reflex | 58925.498 | 14.67x | 2735.000 | 1.17x | 337.000 | 3000 | 0 | 10 | 0 |
| keyed-reverse | 10 | fusion-charm | 23070.172 | 5.74x | 3172.000 | 1.36x | 192.000 | 3000 | 0 | 0 | 0 |
| keyed-reverse | 10 | react-upstream | 58748.323 | 14.63x | 2725.000 | 1.17x | 335.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | bare | 1238.415 | 0.33x | 1760.000 | 0.75x | 64.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | compose | 3775.268 | 1.00x | 2333.000 | 1.00x | 73.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | fusion | 21257.989 | 5.63x | 3171.000 | 1.36x | 193.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | vide | 3501.604 | 0.93x | 2322.000 | 1.00x | 65.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | react | 37451.323 | 9.92x | 2732.000 | 1.17x | 334.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | blend | 2135.171 | 0.57x | 3057.000 | 1.31x | 73.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | roact | 7212.553 | 1.91x | 2051.000 | 0.88x | 57.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | seam | 11420.117 | 3.02x | 3045.000 | 1.31x | 140.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-rotate | 10 | react-reflex | 37496.096 | 9.93x | 2735.000 | 1.17x | 337.000 | 3000 | 0 | 10 | 0 |
| keyed-rotate | 10 | fusion-charm | 20909.013 | 5.54x | 3172.000 | 1.36x | 193.000 | 3000 | 0 | 0 | 0 |
| keyed-rotate | 10 | react-upstream | 37452.024 | 9.92x | 2725.000 | 1.17x | 335.000 | 3000 | 0 | 0 | 0 |
| keyed-shuffle | 10 | bare | 1344.823 | 0.33x | 1759.000 | 0.75x | 64.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | compose | 4024.932 | 1.00x | 2334.000 | 1.00x | 74.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | fusion | 23047.639 | 5.73x | 3179.000 | 1.36x | 193.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | vide | 3627.699 | 0.90x | 2322.000 | 0.99x | 65.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | react | 35636.995 | 8.85x | 2732.000 | 1.17x | 334.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | blend | 2363.467 | 0.59x | 3057.000 | 1.31x | 65.000 | 3000 | 0 | 0 | 0 |
| keyed-shuffle | 10 | roact | 7965.056 | 1.98x | 2051.000 | 0.88x | 65.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | seam | 12182.108 | 3.03x | 3053.000 | 1.31x | 141.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| keyed-shuffle | 10 | react-reflex | 36207.140 | 9.00x | 2736.000 | 1.17x | 338.000 | 2990 | 0 | 10 | 0 |
| keyed-shuffle | 10 | fusion-charm | 23319.023 | 5.79x | 3173.000 | 1.36x | 193.000 | 2990 | 0 | 0 | 0 |
| keyed-shuffle | 10 | react-upstream | 36791.756 | 9.14x | 2733.000 | 1.17x | 335.000 | 2990 | 0 | 0 | 0 |
| events | 5 | bare | 9997.138 | 0.72x | 137.000 | 0.99x | 128.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | compose | 13905.181 | 1.00x | 138.000 | 1.00x | 138.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | fusion | 17255.981 | 1.24x | 130.000 | 0.94x | 129.000 | 9015 | 1005 | 1000 | 0 |
| events | 5 | vide | 13166.674 | 0.95x | 130.000 | 0.94x | 129.000 | 8015 | 1005 | 1000 | 0 |
| events | 5 | react | 53500.299 | 3.85x | 470.000 | 3.41x | 469.000 | 2000 | 1005 | 1000 | 1 |
| events | 5 | blend | 26103.444 | 1.88x | 129.000 | 0.93x | 128.000 | 9015 | 1005 | 1000 | 0 |
| events | 5 | roact | 15427.662 | 1.11x | 121.000 | 0.88x | 129.000 | 2005 | 1005 | 1000 | 0 |
| events | 5 | seam | 13845.983 | 1.00x | 129.000 | 0.93x | 136.000 | 1000 | 1005 | 1005 | 0 |
| events | 5 | signals | 11208.913 | 0.81x | 146.000 | 1.06x | 152.000 | 1000 | 1005 | 1000 | 0 |
| events | 5 | react-reflex | 52167.030 | 3.75x | 478.000 | 3.46x | 469.000 | 2000 | 1005 | 1000 | 1 |
| events | 5 | fusion-charm | 16393.463 | 1.18x | 122.000 | 0.88x | 129.000 | 9015 | 1005 | 1000 | 0 |
| events | 5 | react-upstream | 61321.139 | 4.41x | 479.000 | 3.47x | 470.000 | 2000 | 1005 | 1000 | 1 |
| animate-many | 1 | bare | 1635.000 | 0.18x | 1547.000 | 0.63x | 32.000 | 6000 | 0 | 0 | 0 |
| animate-many | 1 | compose | 9024.401 | 1.00x | 2457.000 | 1.00x | 42.000 | 6000 | 0 | 1 | 0 |
| animate-many | 1 | fusion | 140606.881 | 15.58x | 2770.000 | 1.13x | 165.000 | 3600 | 0 | 0 | 0 |
| animate-many | 1 | vide | 10858.314 | 1.20x | 1976.000 | 0.80x | 53.000 | 6000 | 0 | 0 | 30 |
| animate-many | 1 | react | unsupported: React and ReactRoblox have no native spring primitive. Adding another animation library would change the comparison. | — | — | — | — | — | — | — | — |
| animate-many | 1 | blend | 12790.245 | 1.42x | 2735.000 | 1.11x | 96.000 | 6200 | 0 | 200 | 0 |
| animate-many | 1 | roact | unsupported: Roact has no native spring primitive. | — | — | — | — | — | — | — | — |
| animate-many | 1 | seam | 27641.120 | 3.06x | 3602.000 | 1.47x | 68.000 | 3600 | 0 | 0 | 0 |
| animate-many | 1 | signals | unsupported: Signals has no native spring primitive. | — | — | — | — | — | — | — | — |
| animate-many | 1 | react-reflex | unsupported: React and ReactRoblox have no native spring primitive. Adding another animation library would change the comparison. | — | — | — | — | — | — | — | — |
| animate-many | 1 | fusion-charm | 140640.379 | 15.58x | 2756.000 | 1.12x | 157.000 | 3600 | 0 | 0 | 0 |
| animate-many | 1 | react-upstream | unsupported: React and ReactRoblox have no native spring primitive. Adding another animation library would change the comparison. | — | — | — | — | — | — | — | — |
| status-panel | 20 | bare | 145.998 | 0.28x | 148.000 | 0.85x | 2.000 | 82 | 21 | 0 | 0 |
| status-panel | 20 | compose | 517.296 | 1.00x | 175.000 | 1.00x | 4.000 | 82 | 21 | 0 | 0 |
| status-panel | 20 | fusion | 2643.445 | 5.11x | 258.000 | 1.47x | 15.000 | 229 | 21 | 0 | 0 |
| status-panel | 20 | vide | 451.699 | 0.87x | 191.000 | 1.09x | 11.000 | 208 | 21 | 0 | 0 |
| status-panel | 20 | react | 2768.264 | 5.35x | 423.000 | 2.42x | 227.000 | 103 | 21 | 0 | 0 |
| status-panel | 20 | blend | 924.823 | 1.79x | 250.000 | 1.43x | 10.000 | 438 | 21 | 0 | 0 |
| status-panel | 20 | roact | 768.311 | 1.49x | 186.000 | 1.06x | 10.000 | 103 | 21 | 0 | 0 |
| status-panel | 20 | seam | unsupported: Seam's native computed-property type guard rejects the workload's synthetic Frame.Text property, whose default type is nil. | — | — | — | — | — | — | — | — |
| status-panel | 20 | signals | unsupported: Signals supplies state and effects, with no native keyed Instance collection or row lifetime primitive. | — | — | — | — | — | — | — | — |
| status-panel | 20 | react-reflex | 2904.954 | 5.62x | 433.000 | 2.47x | 223.000 | 103 | 21 | 60 | 0 |
| status-panel | 20 | fusion-charm | 3055.855 | 5.91x | 255.000 | 1.46x | 7.000 | 229 | 21 | 0 | 0 |
| status-panel | 20 | react-upstream | 2741.562 | 5.30x | 432.000 | 2.47x | 228.000 | 103 | 21 | 0 | 0 |
| mount-cycles | 1 | bare | 16574.332 | 0.66x | 257.000 | 1.98x | 256.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | compose | 25253.088 | 1.00x | 130.000 | 1.00x | 130.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | fusion | 29838.744 | 1.18x | 130.000 | 1.00x | 136.000 | 16290 | 1830 | 1800 | 0 |
| mount-cycles | 1 | vide | 21767.224 | 0.86x | 251.000 | 1.93x | 250.000 | 14490 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react | 71317.004 | 2.82x | 518.000 | 3.98x | 517.000 | 3600 | 1830 | 1800 | 1 |
| mount-cycles | 1 | blend | 47280.787 | 1.87x | 65.000 | 0.50x | 72.000 | 16290 | 1830 | 1800 | 0 |
| mount-cycles | 1 | roact | 27709.759 | 1.10x | 129.000 | 0.99x | 137.000 | 3630 | 1830 | 1800 | 0 |
| mount-cycles | 1 | seam | 24167.943 | 0.96x | 129.000 | 0.99x | 128.000 | 1800 | 1830 | 1830 | 0 |
| mount-cycles | 1 | signals | 18339.510 | 0.73x | 253.000 | 1.95x | 260.000 | 1800 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react-reflex | 70265.943 | 2.78x | 518.000 | 3.98x | 517.000 | 3600 | 1830 | 1800 | 1 |
| mount-cycles | 1 | fusion-charm | 29605.837 | 1.17x | 138.000 | 1.06x | 137.000 | 16290 | 1830 | 1800 | 0 |
| mount-cycles | 1 | react-upstream | 77541.021 | 3.07x | 511.000 | 3.93x | 510.000 | 3600 | 1830 | 1800 | 1 |
| scene-3d | 20 | bare | 3613.458 | 0.47x | 1067.000 | 0.84x | 32.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | compose | 7641.853 | 1.00x | 1266.000 | 1.00x | 34.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | fusion | 81571.616 | 10.67x | 1671.000 | 1.32x | 96.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | vide | 9863.357 | 1.29x | 1288.000 | 1.02x | 49.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react | 6696.018 | 0.88x | 1751.000 | 1.38x | 509.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | blend | 9495.322 | 1.24x | 1598.000 | 1.26x | 32.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | roact | unsupported: Roact assigns Instance.Name from reconciliation keys. Named children use dictionary keys, whose mounting order cannot satisfy this workload's ordered named-tree contract. | — | — | — | — | — | — | — | — |
| scene-3d | 20 | seam | 20685.007 | 2.71x | 2265.000 | 1.79x | 54.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | signals | 14881.013 | 1.95x | 1809.000 | 1.43x | 64.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react-reflex | 6765.988 | 0.89x | 1766.000 | 1.39x | 517.000 | 6000 | 0 | 40 | 0 |
| scene-3d | 20 | fusion-charm | 82615.955 | 10.81x | 1675.000 | 1.32x | 104.000 | 6000 | 0 | 0 | 0 |
| scene-3d | 20 | react-upstream | 6520.723 | 0.85x | 1752.000 | 1.38x | 510.000 | 6000 | 0 | 0 | 0 |
| unwind | 10 | bare | 3323.977 | 0.73x | 137.000 | 1.06x | 128.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | compose | 4567.868 | 1.00x | 129.000 | 1.00x | 129.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | fusion | 5802.596 | 1.27x | 129.000 | 1.00x | 128.000 | 5310 | 590 | 0 | 0 |
| unwind | 10 | vide | 4716.616 | 1.03x | 130.000 | 1.01x | 129.000 | 2360 | 590 | 0 | 0 |
| unwind | 10 | react | unsupported: A failed native render, including an error boundary, leaves abandoned cost-model host nodes after root unmount. It does not satisfy the partial-build rollback contract. | — | — | — | — | — | — | — | — |
| unwind | 10 | blend | unsupported: An error during native observable subscription leaves the partially created cost-model nodes without a returned cleanup resource. It does not satisfy failed-build rollback. | — | — | — | — | — | — | — | — |
| unwind | 10 | roact | unsupported: Roact's public mount API returns its cleanup handle only after a successful mount; failed render rollback is not guaranteed. | — | — | — | — | — | — | — | — |
| unwind | 10 | seam | 3869.753 | 0.85x | 129.000 | 1.00x | 129.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | signals | 3799.498 | 0.83x | 130.000 | 1.01x | 129.000 | 590 | 590 | 0 | 0 |
| unwind | 10 | react-reflex | unsupported: A failed native render, including an error boundary, leaves abandoned cost-model host nodes after root unmount. It does not satisfy the partial-build rollback contract. | — | — | — | — | — | — | — | — |
| unwind | 10 | fusion-charm | 5800.728 | 1.27x | 129.000 | 1.00x | 129.000 | 5310 | 590 | 0 | 0 |
| unwind | 10 | react-upstream | unsupported: A failed native render, including an error boundary, leaves abandoned cost-model host nodes after root unmount. It does not satisfy the partial-build rollback contract. | — | — | — | — | — | — | — | — |

## Source identities

Compose revision: `ed40b1034d0cb14cdf442e1f6129ea6cb12bcc52`. Full source state, tools, environment and command are in `context.json`.

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
