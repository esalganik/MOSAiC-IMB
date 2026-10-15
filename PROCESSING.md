# Processing

Original MAT records are processed consistently across their available 2019–2020 coverage, retaining buoy-specific corrections and interface estimates. There is no April change of processing method.

- Elevations are positive upward in each buoy’s source datum.
- Snow thickness = top surface − ice top.
- Ice thickness = ice top − ice bottom.
- Ice top is partitioned from the top surface at the initial reference: initial `fb` for DTCs, zero for SIMBA/other IMB records. Snow becomes zero when the surface reaches that reference. This is a processing assumption.

Hourly data use linear interpolation without extrapolation. Missing values remain NaN. Native profiles retain their own times and sensor elevations. I3 has no independent heating data. Inherited exclusions are retained; `snow_excluded` flags the additional hourly snow masks.

All 29 individual buoy records are retained. DTC26 is excluded from both summary means as a ridge site. DTC11 and DTC12 are excluded from the ice mean, following the earlier CS2 selection. Separate inclusion flags are stored in the NetCDF.

Means and sample standard deviations require at least two available buoys. Each is smoothed separately with a centred seven-day moving mean; missing gaps remain missing. Individual records are not smoothed. The summary shows mean ±1 SD and unsmoothed contributor counts. Raw statistics are also stored.

Sources: individual SIMBA PANGAEA datasets; [DTC collection](https://doi.org/10.1594/PANGAEA.964023); I3 and 2020M29 downloaded from [Meereisportal](https://data.meereisportal.de/). The original [I3 archive citation](https://doi.org/10.18739/A20Z70Z01) is retained. Per-buoy references are in the NetCDF.
