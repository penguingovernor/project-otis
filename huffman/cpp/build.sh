#! /usr/bin/env bash

main() {
	local -r CXXS=("zig c++" "clang++" "g++")
	for ((i = 0; i < ${#CXXS[@]}; i++)); do
  		${CXXS[i]} main.cc \
			-std=c++20 -Wall -Werror -Wextra -Wpedantic \
			-g -Ofast -o "huffman-${CXXS[i]// /-}"
	done
}

main
