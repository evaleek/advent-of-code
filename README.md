My solutions to Advent of Code problems.

# Benchmarks

Measured with 10,000 iterations on my Ryzen 9 5900X with Zig `ReleaseFast`.
The input is read and allocated from the file,
and I then repeatedly measure the runtime of the solution function on the allocated input
(so no IO time is included).

## 2025

| DD/P | Mean runtime ± standard deviation |
| ---- | --------------------------------- |
| 01/1 | 72.2 µs ± 1.0 µs                  |
| 01/2 | 83.8 µs ± 0.6 µs                  |
| 02/1 | 10.361 ms ± 0.140 ms              |
| 02/2 | 7.708 ms ± 0.181 ms               |
| 03/1 | 17.1 µs ± 0.5 µs                  |
| 03/2 | 0.138 ms ± 2.4 µs                 |
| 04/1 | 0.136 ms ± 1.2 µs                 |
| 04/2 | 0.580 ms ± 2.3 µs                 |
| 05/1 | 40.5 µs ± 0.6 µs                  |
| 05/2 | 11.6 µs ± 0.3 µs                  |
| 06/1 | 33.2 µs ± 0.5 µs                  |
| 06/2 | 26.2 µs ± 0.7 µs                  |
| 07/1 | 2.5 µs ± 0.2 µs                   |
| 07/2 | 9.8 µs ± 0.2 µs                   |
