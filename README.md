# VAD for Multi‑Mic or Single‑Mic Talker Recordings

This repository contains MATLAB code for **voice activity detection (VAD)** in multi‑talker conversations.  
It supports two recording setups:

*   **1 microphone per talker**, or
*   **3 microphones per talker** (mouth + auxiliary mics)

The algorithm combines:

*   **Energy‑based detection** using RMS thresholds derived from each recording
*   **Crosstalk suppression** using RMS level differences and cross‑correlation
*   Optional smoothing and post‑processing to merge short gaps and remove spurious bursts

The core function is:

    corrVAD.m

which computes:

*   Frame‑wise power (`power`)
*   Cross‑correlations (`rs`, `lags`)
*   Speech activity decisions (`actArr`)
*   Speech segment onsets (`idx`)

You can run the VAD with only a multi‑channel audio matrix and the sampling rate, or provide optional microphone layout information for more control.

***

## License

This code is released under the **Apache License 2.0**.  
See the `LICENSE` file for details.

***

## Attribution (CC‑BY)

If you use this code in academic work, please cite the study whose VAD description inspired this implementation:

**Slomianka, V., May, T., & Dau, T. (2025).  
*Adaptions in eye‑movement behavior during face‑to‑face communication in noise.*  
Frontiers in Psychology. <https://doi.org/10.3389/fpsyg.2025.1584937>**

This article is published under **CC‑BY**, which allows reuse with proper attribution.

***