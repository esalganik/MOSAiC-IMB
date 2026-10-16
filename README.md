# MOSAiC ice mass balance buoy observations

Snow and sea-ice thickness evolve through winter growth, snow accumulation and summer melt. Autonomous thermistor-chain observations provide a continuous view of these changes and their associated thermal structure.
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.23406150.svg)](https://doi.org/10.5281/zenodo.23406150)

This repository brings together processed observations from **29 buoys** deployed during the MOSAiC expedition in 2019–2020: **11 SIMBAs, 16 Digital Thermistor Chains (DTCs), SIMB I3 and IMB 2020M29**. Each record spans its available observation period; coverage and the number of contributing instruments vary through time.

**Evgenii Salganik**  
Alfred Wegener Institute, Helmholtz Centre for Polar and Marine Research (AWI)

## Dataset

The NetCDF contains snow and ice thickness, top-surface and ice-bottom interface elevations, geographic positions, and native temperature and heating-response profiles. The heating response provides information about the material surrounding the sensors and complements the environmental temperature measurements when interpreting interfaces.

Elevations are positive upward in each instrument’s source coordinate system. Snow and ice thickness are calculated as differences between the selected interfaces. The processing retains buoy-specific corrections and uses a surface-partition model referenced to the initial ice-surface elevation. Details and assumptions are described in [PROCESSING.md](PROCESSING.md).

Hourly ensemble means and standard deviations describe the seasonal evolution across the available records. Both statistics are smoothed with a seven-day moving mean; individual records remain unsmoothed by this step. DTC26 is retained as a ridge-site record but excluded from the ensemble summaries. DTC11 and DTC12 are excluded from the ice-thickness summary, following the earlier instrument selection. Raw statistics, inclusion flags and contributing-buoy counts are included in the file.

## Figures and sources

Five figures show surface and bottom interfaces over temperature and heating response, together with mean snow and ice thickness and instrument counts. The MATLAB script in `scripts/` reproduces these figures directly from `data/MOSAiC_IMB_extended_v1.nc` without the original MAT files.

SIMBA and DTC observations originate from PANGAEA; I3 and 2020M29 were downloaded from [Meereisportal](https://data.meereisportal.de/). Per-buoy source references are stored in the NetCDF. Please cite this processed product using [CITATION.cff](CITATION.cff) and acknowledge the original observational datasets.

Code: **MIT**. Data, figures and documentation: **CC BY 4.0**, subject to original source rights. See [LICENSE.md](LICENSE.md).
