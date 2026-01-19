# corr\_VAD

**corr\_VAD** is a MATLAB implementation of a **voice activity detection (VAD)** algorithm designed for multi‑talker conversational recordings.  
It supports different microphone layouts:

*   **1 microphone per talker**, or
*   **3 microphones per talker** (mouth + 2 auxiliary microphones)

The algorithm combines:

*   **Energy‑based thresholding** using RMS power
*   **Cross‑correlation analysis** for crosstalk suppression
*   **Automatic layout detection** (or optional manual configuration)
*   **Post‑processing** to merge gaps and remove short bursts

The main function, `corrVAD.m`, computes:

*   Windowed RMS power
*   Cross‑correlation features
*   Per‑talker speech activity decisions
*   Speech onset indices

This implementation is based on the methodological description in the referenced publication but is original software licensed under Apache‑2.0.

***

## License

This software is released under the **Apache License 2.0**.  
See the `LICENSE` file for details.

***

## Attribution (CC‑BY Requirement)

This repository implements methods **inspired by** the following CC‑BY‑licensed article.  
If you use this software in academic work, please cite:

**Slomianka, V., May, T., & Dau, T. (2025).  
*Adaptions in eye‑movement behavior during face‑to‑face communication in noise.*  
Frontiers in Psychology. <https://doi.org/10.3389/fpsyg.2025.1584937>**

The article is published under **CC‑BY**, which permits reuse with attribution.

***

## How to Cite This Repository

A citation file is included. GitHub will display a **“Cite this repository”** option based on the `CITATION.cff`.

***


