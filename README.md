# Local Frequency Table for Context-based Adaptive Arithmetic Coding in Text Compression

## Table of contents

<!--ts-->
   * [Overview](#overview)
   * [Algorithm](#algorithm)
   * [Introduction to the files](#introduction-to-the-files)
<!--te-->

## Overview

   1. This repository is about the paper "Local Frequency Table for Context-based Adaptive Arithmetic
Coding in Text Compression" accepted by [2022 IEEE ICCE-Taiwan](http://www.icce-tw.org/).
   2. We apply Context-based Adaptive Arithmetic Coding (CAAC) and a local frequency table to text compression.
   3. The compression ratio of the proposed algorithm increases by 16.81% compared to adaptive arithmetic coding.

## Algorithm

   1. We improve the compression by predicting the probability distribution of characters more accurately with the help of contexts.
   2. In CAAC, we classify the causal part into six contexts and use six frequency tables to count the frequency of characters under these contexts. Furthermore, we encode the input characters with different frequency tables corresponding to different contexts. With it, the probability of the input character can be predicted more accurately.
   3. However, CAAC fails to address specific contexts because the number of contexts grows exponentially in terms of the order of the context and it is impractical for the memory. To address this problem, the technique of the local frequency table is applied.
   4. The local frequency table multiplies the probability predicted by the global frequency table with the pre-trained parameter when dealing with common contexts. Therefore, it bridges the gap between the probability predicted by the global frequency table and the real probability. It is noteworthy that the local frequency table neither requires additional memory nor affects the global frequency table. Thereby, utilizing a local frequency table is a memory-efficient way to achieve a higher compression ratio.

## Introduction to the files
  1. `./src/Local_frequency_table.m`: This file applies the local frequency table on context-modeling-based adaptive arithmetic coding (CAAC). It outperforms adaptive arithmetic coding by 16.8% and context-modeling-based adaptive arithmetic coding by 11.01% on average on the compression ratio.
  2. `./src/Control_group/Context_modeling_based_adaptive_arithmetic_coding.m` It is based on Adaptive Arithmetic Coding with the application of 6 different contexts. It outperforms Adaptive Arithmetic Coding by 11.06 % on the compression ratio.
  3. `./src/Control_group/Adaptive_arithmetic_coding.m`: The implementation of [adaptive arithmetic coding](https://en.wikipedia.org/wiki/Arithmetic_coding#Adaptive_arithmetic_coding).
  4. `./src/Control_group/Static_arithmetic_coding.m`:The implementation of [arithmetic coding](https://en.wikipedia.org/wiki/Arithmetic_coding), with the pre-defined frequency table.
  5. `./src/Control_group/Huffman_coding.m`: The implementation of [Huffman coding](https://en.wikipedia.org/wiki/Huffman_coding).
  6. `./Test_patterns` Six test patterns used in the simulation.
