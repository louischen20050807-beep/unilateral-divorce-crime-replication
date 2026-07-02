# Revisiting "The Impact of Unilateral Divorce on Crime"

A replication and reassessment of Cáceres-Delpiano and Giolito (2012, *Journal of Labor Economics*) using heterogeneity-robust difference-in-differences estimators.

**Author:** Louis Chen (Queen's University)

## Overview

Between the late 1960s and the early 1980s, most U.S. states adopted unilateral divorce laws, which allowed one spouse to end a marriage without the other's consent. Cáceres-Delpiano and Giolito (2012) find that these reforms raised violent crime by roughly nine percent, with the effect emerging as exposed cohorts of children aged into their late teens and twenties.

This project replicates their analysis and tests whether the result holds up against methods that were not available in 2012. I reproduce the paper's two-way fixed effects (TWFE) estimates for violent crime and institutionalization, estimate an event study to check the timing of the effect, and re-estimate the violent-crime effect with the heterogeneity-robust DID_l estimator of de Chaisemartin and d'Haultfœuille (2024), along with placebo tests on the pre-reform years.

The original results hold up. My TWFE estimates place the effect between eight and ten percent across control sets, the event study shows no pre-trends and an effect that builds over time, and the DID_l estimates track the TWFE results closely, which indicates that negative weighting is not driving the published estimate.

This project began as the final empirical assignment for ECON 452 (Applied Econometrics) at Queen's University. I have since reworked it into a standalone replication study: correcting and rebuilding the figures, restructuring the analysis into a single reproducible script, and rewriting the paper to stand on its own. As of a literature search conducted in July 2026, no published replication of the paper's crime result exists (see `docs/literature_check.md`).

## Repository contents

| Path | Contents |
|---|---|
| `paper/` | The full write-up (PDF) |
| `code/master.do` | The complete analysis: treatment coding, figures, TWFE table, event study, census analysis, DID_l estimation |
| `figures/` | All figures as exported by the code |
| `docs/` | Literature check documenting that no prior replication exists |

## Data (not included)

Two datasets are required. Neither can be redistributed here, but both are straightforward to obtain:

1. **UCR state-year crime panel (`ucr.dta`), 1965–1996.** State-year violent and property crime rates per 100,000 residents plus control variables, as used in Cáceres-Delpiano and Giolito (2012). This file was provided through course materials; equivalent data are available from the Bureau of Justice Statistics and the sources listed in the original paper's data appendix.

2. **IPUMS USA census extract (`usa_00001.dta`).** U.S. censuses 1960, 1970, 1980, 1990, and 2000 from [IPUMS USA](https://usa.ipums.org/usa/), with the following variables: YEAR, SAMPLE, SERIAL, HHWT, CLUSTER, STATEFIP, STRATA, GQ, PERNUM, PERWT, SEX, AGE, RACE, RACED, BPL, BPLD. The analysis restricts to men aged 15–24. IPUMS terms of use prohibit redistributing extracts, but the extract is free to rebuild with an IPUMS account.

Place both `.dta` files in the same folder as `master.do`.

## How to reproduce

1. Stata 17 or later.
2. Install the estimator package once: `ssc install did_multiplegt_dyn`
3. Set the working directory to the folder containing `master.do` and the data, then run: `do master.do`

The script produces `analysis_log.txt` (a full text log of every result) and the four figures. Expected checks are noted in the code comments: the treatment tabulation should return 882/750 state-year observations, and the merged census sample should contain 3,360,455 observations.

## Main results

| | (1) Basic | (2) + Demographic | (3) + Aggregate | (4) + Policy |
|---|---|---|---|---|
| Unilateral divorce | 0.0965* | 0.0722 | 0.0785* | 0.0823* |
| | (0.0486) | (0.0488) | (0.0450) | (0.0489) |

*Dependent variable: log violent crime rate, UCR 1965–1996, N = 1,632 (1,613 in cols 3–4). State and year fixed effects in all columns; standard errors clustered by state; \* p < 0.10.*

The DID_l dynamic effects rise from 0.01 in the first year after adoption to 0.10–0.13 by years six through ten, and the five pre-reform placebo estimates are individually insignificant (joint p = 0.18).

## References

- Cáceres-Delpiano, J., and E. Giolito. 2012. "The Impact of Unilateral Divorce on Crime." *Journal of Labor Economics* 30(1): 215–248.
- de Chaisemartin, C., and X. d'Haultfœuille. 2020. "Two-Way Fixed Effects Estimators with Heterogeneous Treatment Effects." *American Economic Review* 110(9): 2964–2996.
- de Chaisemartin, C., and X. d'Haultfœuille. 2024. "Difference-in-Differences Estimators of Intertemporal Treatment Effects." *Review of Economics and Statistics* 106(6).
- Friedberg, L. 1998. "Did Unilateral Divorce Raise Divorce Rates? Evidence from Panel Data." *American Economic Review* 88(3): 608–627.
