# Local_Frequency_Table
## Overview
  This repository is about the paper "Local Frequency Table for Context-based Adaptive Arithmetic
Coding in Text Compression". This paper applies two techniques, which are the context-based frequency table and the local frequency table, to improve the compression ratio of adaptive arithmetic coding by 16.8% on average in text compression.
## Introduction to files
  1. `./src/Local_frequency_table.m`: This file applies the local frequency table on context-modeling-based adaptive arithmetic coding (CAAC). It outperforms adaptive arithmetic coding by 16.8% and context-modeling-based adaptive arithmetic coding by 11.01% on average on the compression rate.
  2. `./src/Control_group/Context_modeling_based_adaptive_arithmetic_coding.m` It is based on Adaptive Arithmetic Coding with the application of 6 different contexts. It outperforms Adaptive Arithmetic Coding by 11.06 % on the compression rate.
  3. `./src/Control_group/Adaptive_arithmetic_coding.m`: The implementation of [adaptive arithmetic coding](https://en.wikipedia.org/wiki/Arithmetic_coding#:~:text=Adaptive%20arithmetic%20coding,-See%20also%3A%20Context&text=Adaptation%20is%20the%20changing%20of,same%20step%20as%20in%20encoding.)
  4. `./src/Control_group/Static_arithmetic_coding.m`:The implementation of [arithmetic coding](https://en.wikipedia.org/wiki/Arithmetic_coding), with the pre-defined frequency table.
  5. `./src/Control_group/Huffman_coding.m`: The implementation of [Huffman coding](https://en.wikipedia.org/wiki/Huffman_coding)
  6. `./Test_patterns` Six test patterns used in the simulation
