# Project Otis

This repository has pet-projects for me to learn about the [Zig programming language](https://ziglang.org).
Additionally, I'll try to implement data-oriented design and performance aware programming whenever possible.

> Data-oriented Design:
>
> A program optimization approach motivated by efficient usage of the CPU cache [...]
>
> The approach is to focus on the data layout, separating and sorting fields according to when they are needed, and to think about transformations of data. - [Wikipedia](https://en.wikipedia.org/wiki/Data-oriented_design)

> Performance-Aware Programming
>
> [Performance Aware Programming is] designed to give you all of the information you need to understand why software is either fast or slow, and to understand how the decisions you make affect the gradient of software performance. It’s an effort to try to get everyone back onto the same page where we're no longer writing software that's 1000x times slower than it should be, or 10,000x times slower than it should be. - [Casey Muratori](https://www.computerenhance.com/p/welcome-to-the-performance-aware)

## Current Projects

### Haversine

#### Coordinate Generation

In order to properly test our `haversine` function we need test data.
This project includes a utility called `coorgen`, which is short for coordinate generate.
It's used on the command line like so: `$ coorgen [N_COORDINATE_PAIRS] > coordinates.json`.

The default value for `N_COORDINATE_PAIRS` is 10e6 pairs, for 4*10e6 floating point numbers.

### Huffman Coding

> A Huffman code is a particular type of optimal prefix code that is commonly used for lossless data compression.
> \- [Wikipedia](https://en.wikipedia.org/wiki/Huffman_coding)

#### Build Instructions

```shell
cd huffman
zig build
```

#### Key Takeaways

- Instead of allocating nodes individually with a general purpose allocator (i.e. `malloc`/`std.heap.GeneralPurposeAllocator`), we should allocate them in a `std::vector`/`std.ArrayList` so they can be continuous in memory.
  The contiguous nature of the list is more cache-friendly, as opposed to the GPA
  that can allocate Nodes where it pleases.

  - When we need to perform operations that use pointers to Nodes we can now use an index.
    See also: [Handles are the better pointers](https://floooh.github.io/2018/06/17/handles-vs-pointers.html)
  - This leads to more efficiencies like the `MultiArrayList` below.

- It's trivially easy to implement [Parallel Arrays](https://en.wikipedia.org/wiki/Parallel_array) thanks to Zig's [`MultiArrayList`](https://github.com/ziglang/zig/blob/master/lib/std/multi_array_list.zig)

- When writing a BitVector, you can't just push a zero by only incrementing the length.

  - This assumption is based off that the pushed byte is already 0'ed out
  - Assumption fails if a `1` is pushed, then popped off, then a `0` is pushed

#### Performance Improvements Over Simple C++ Implementation (Creating the Tree Only)

Command to measure performance: `hyperfine --warmup 1000 --shell none ./zig-out/bin/huffman ./cpp/huffman-zig-c++ ./cpp/huffman-clang++ ./cpp/huffman-g++`

CPU Specs: `11th Gen Intel i7-1165G7 (8) @ 4.700GHz`

| Command                 | Compiler Version          | Mean [ms] | Min [ms] | Max [ms] |     Relative |
| :---------------------- | :------------------------ | --------: | -------: | -------: | -----------: |
| `./zig-out/bin/huffman` | 0.11.0-dev.1646+3f7e9ff59 | 0.1 ± 0.1 |      0.1 |      1.5 |         1.00 |
| `./cpp/huffman-zig-c++` | clang version 15.0.7      | 1.0 ± 0.1 |      0.4 |      1.5 |  6.90 ± 4.00 |
| `./cpp/huffman-clang++` | 14.0.0-1                  | 2.0 ± 0.1 |      1.6 |      2.4 | 14.45 ± 8.29 |
| `./cpp/huffman-g++`     | 11.3.0                    | 2.0 ± 0.1 |      1.4 |      2.9 | 14.34 ± 8.24 |

## Project TODOs

### Huffman Coding

- [ ] Read from stdin
- [x] Write a BitVector library
- [x] Implement Huffman Code Generation
- [ ] Write out the file.
  - [ ] Serialize the Huffman Tree
- [x] Write a simple implementation of Huffman Coding in C++ to compare performance.
- [ ] Write decompressing algorithm

## FAQs

Q: Why Project Otis?

A: My cat's name is Otis.
