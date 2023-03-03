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

Haversine is trigonometric function that is common used to find the distance between two points on a sphere.

As part of the _Performance Aware Programming_ course we were asked to read in JSON file that contains multiple latitude+longitude pairs and calculate the average distance between points.

To complete this, I added a program called `haversine`.
It's used on the command line like so: `haversine TEST_FILE.json`.

`haversine` was implemented naively.
The initial version of this program used the std library implementation for json deserialization.

However, due to my inadequacies (lol) I couldn't manage to get much performance out the standard library because I had to read the file into memory and then call json parse on a huge `std.ArrayList(u8)`.

To remedy the slow performance, I did what Casey did in the prologue of the course, drop down to `C`.
Zig made this super easy and even managed to full cross-compile between my Windows host (the target) and my Linux VM (the host -- I like Linux for programming, as we all should 😉).

I used `yyjson` because it was one of the first things I could find.

To gather metrics, I ran this on an Arch Linux virtual machine.
The host machine is a Windows 11 computer running VirtualBox.

Here are the specs for the VM:

```
$ lscpu 
Architecture:            x86_64
  CPU op-mode(s):        32-bit, 64-bit
  Address sizes:         39 bits physical, 48 bits virtual
  Byte Order:            Little Endian
CPU(s):                  4
  On-line CPU(s) list:   0-3
Vendor ID:               GenuineIntel
  Model name:            11th Gen Intel(R) Core(TM) i7-1165G7 @ 2.80GHz
    CPU family:          6
    Model:               140
    Thread(s) per core:  1
    Core(s) per socket:  4
    Socket(s):           1
    Stepping:            1
    BogoMIPS:            5606.40
    Flags:               fpu vme de pse tsc msr pae mce cx8 apic sep mtrr pge mca cmov 
                         pat pse36 clflush mmx fxsr sse sse2 ht syscall nx rdtscp lm co
                         nstant_tsc rep_good nopl xtopology nonstop_tsc cpuid tsc_known
                         _freq pni pclmulqdq ssse3 cx16 pcid sse4_1 sse4_2 x2apic movbe
                          popcnt aes xsave avx rdrand hypervisor lahf_lm abm 3dnowprefe
                         tch invpcid_single fsgsbase bmi1 avx2 bmi2 invpcid rdseed clfl
                         ushopt md_clear flush_l1d arch_capabilities
Virtualization features: 
  Hypervisor vendor:     KVM
  Virtualization type:   full
Caches (sum of all):     
  L1d:                   192 KiB (4 instances)
  L1i:                   128 KiB (4 instances)
  L2:                    5 MiB (4 instances)
  L3:                    48 MiB (4 instances)
```

The Windows machine host has 16 GiB of ram with 8 cores.


Finally, here are my results:

```
# Results were run on Zig v0.11.0-dev.1796+c9e02d3e6.
# Compiled using -Doptimize=ReleaseFast

# Command being timed: ./zig-out/bin/haversine testdata/10mil.json
#
# 10mil.json contains 10e6 lat/long pairs, for 40e6 floating point numbers.

Result: 10006.911147247096 km
Input = 1044.237577 ms
Math = 678.872094 ms
Total = 1723.109671 ms
Throughput = 5.803461130942721e+06 haversines/second
```

Not too shabby, but definitely far from optimal!

#### Key Takeaways (Thus Far)

- Zig interop with C is so amazing.
- When in doubt, drop to C.
- Wikipedia is your best friend for understanding topics.

#### Coordinate Generation

In order to properly test our `haversine` function we need test data.
This project includes a utility called `coorgen`, which is short for coordinate generate.
It's used on the command line like so: `$ coorgen [N_COORDINATE_PAIRS] > coordinates.json`.

The default value for `N_COORDINATE_PAIRS` is 10e6 pairs, for 4*10e6 floating point numbers.

### 8086 Emulator

#### Iteration 1 (`MOV` Decoder)

Added a program that can decode `MOV` instructions.
Only register to register operations are supported.

Usage: `< ASSEMBLED_16_bit_8086_FILE 8086 > out.asm`

Verification: `nasm out.asm && diff out.asm ASSEMBLED_16_bit_8086_FILE`

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
