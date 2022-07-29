# Local Frequency Table for Context-based Adaptive Arithmetic Coding in Text Compression
## Overview
   1. This repository is about the paper "Local Frequency Table for Context-based Adaptive Arithmetic
Coding in Text Compression" accepted by [2022 IEEE ICCE-Taiwan](http://www.icce-tw.org/). 
   2. We replace the frequency table with a more context-specific local frequency table to improve the compression ratio of Context-based Adaptive Arithmetic Coding (CAAC) by 6.5%.
   3. The probability of the character depends on its contexts. However, the number of contexts grows exponentially in terms of the number of characters in the context. As a result, CAAC fails to consider the specific context. In this paper, when the local frequency table estimates the probability of the character that highly depends on its contexts, it multiplies the estimated probability derived from CAAC with the pre-trained parameter. In this way, the local frequency table estimates the probability more accurately. As a result, the data is further compressed.
## Introduction to files
  1. `./src/Local_frequency_table.m`: This file applies the local frequency table on context-modeling-based adaptive arithmetic coding (CAAC). It outperforms adaptive arithmetic coding by 16.8% and context-modeling-based adaptive arithmetic coding by 11.01% on average on the compression rate.
  2. `./src/Control_group/Context_modeling_based_adaptive_arithmetic_coding.m` It is based on Adaptive Arithmetic Coding with the application of 6 different contexts. It outperforms Adaptive Arithmetic Coding by 11.06 % on the compression rate.
  3. `./src/Control_group/Adaptive_arithmetic_coding.m`: The implementation of [adaptive arithmetic coding](https://en.wikipedia.org/wiki/Arithmetic_coding#:~:text=Adaptive%20arithmetic%20coding,-See%20also%3A%20Context&text=Adaptation%20is%20the%20changing%20of,same%20step%20as%20in%20encoding.).
  4. `./src/Control_group/Static_arithmetic_coding.m`:The implementation of [arithmetic coding](https://en.wikipedia.org/wiki/Arithmetic_coding), with the pre-defined frequency table.
  5. `./src/Control_group/Huffman_coding.m`: The implementation of [Huffman coding](https://en.wikipedia.org/wiki/Huffman_coding).
  6. `./Test_patterns` Six test patterns used in the simulation.
