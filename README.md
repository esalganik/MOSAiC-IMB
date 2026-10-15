# MOSAiC ice mass balance buoy data

Interfaces, snow and ice thickness, temperature and heating response from **29 buoys**: 11 SIMBAs, 16 DTCs, I3 and 2020M29. Records cover their available periods during 2019–2020.

**Evgenii Salganik — Alfred Wegener Institute, Helmholtz Centre for Polar and Marine Research (AWI)**

## Reproduce the figures

Place `MOSAiC_IMB_extended_v1.nc` in `data/`. In MATLAB R2024a or a compatible version, run:

```matlab
run('scripts/plot_MOSAiC_IMB_extended.m')
```

Only the NetCDF is required. Five PNGs are saved to `figures/`: surface and bottom interfaces over temperature and heating, plus mean snow/ice thickness and contributing-buoy counts.

See [PROCESSING.md](PROCESSING.md) for definitions and selection. Source references are stored in the NetCDF. Cite this product using [CITATION.cff](CITATION.cff) and credit its original sources.

Code: MIT. Data, figures and documentation: CC BY 4.0, subject to source rights. See [LICENSE.md](LICENSE.md).
