# Advent of Code 2024

My attempt to solve AoC 2024 in [Zig](https://github.com/ziglang/zig/). I am not
yet super familiar with the language, so don't expect the most beautiful,
idiomatic Zig code. This is really just me trying to learn.

## Supported Zig version

I'm using the nightly version of Zig to solve these tasks. At the time of
writing, this is `0.14.0-dev.2465+70de2f3a7`. Note that Zig is still in active
development and new versions might have braking changes, so it is not guaranteed
that the code works with any other version.

## How to run

You can find the solution for each day in the `dayXY` directories. They are all
self-contained and can simply be executed using `zig run`. 

As an example, here you can see how to run the solution to day 1:

```
$ zig run day01/main.zig
Total distance: 2742123
Similarity score: 21328497
Task took 8 ms to complete.
```

**Note:** At the moment, the applications assume they are being called from the
repository root. If you call them from anywhere else, they won't be able to find
the input for the day. I might fix this in the future.

Basically all of the solutions contain some tests with the sample input, you
can run these using `zig test <dayXY>/main.zig`.
