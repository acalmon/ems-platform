# Citations and Data Sources

**Document Purpose:** Comprehensive bibliography and data source documentation for EMS platform research

**Last Updated:** October 2025

---

## Primary Research Paper

van den Berg, P. L., Calmon, A. P., Gernert, A. K., Lemmens, S., Rabinovich, M., & Romero, G. (2024). The Value of Time- and Location-Commitment for Decentralized Emergency Medical Services. *Manufacturing & Service Operations Management* (Major Revision).

---

## Data Sources

### 1. Uber Movement Platform

#### Primary Data Source

**Platform:**
- **Name:** Uber Movement
- **Developer:** Uber Technologies, Inc.
- **Years Active:** 2017 - ~2022 (discontinued)
- **URL (archived):** https://movement.uber.com/ (no longer accessible)
- **Access Date:** March 2022 (data downloaded prior to platform closure)

**Dataset Specifics:**
- **Location:** Nairobi, Kenya
- **Temporal Coverage:** 2016-Q1 through 2020-Q1
- **Data Type:** Aggregated travel times between geographic zones
- **Format:** CSV files with zone-to-zone travel statistics
- **Privacy:** Anonymized and aggregated to protect individual privacy

#### Official Methodology Documentation

**Primary Reference:**
- Uber Technologies, Inc. (2017). *Movement: Travel Times Calculation Methodology*. Technical Report.
- **URL:** https://d3i4yxtzktqr9n.cloudfront.net/web-movement/static/pdfs/Movement-TravelTimesMethodology-76002ded22.pdf
- **Status:** Currently unavailable (503 error as of October 2025)
- **Note:** PDF should be archived if accessible via alternative means (Wayback Machine, institutional archive, etc.)

**Data Access Statement:**
> Uber Movement data is no longer publicly available as of 2022. The dataset used in this research was obtained prior to platform discontinuation and is preserved for academic research purposes. Researchers seeking similar data should contact Uber Technologies directly or explore alternative urban mobility datasets.

### 2. H3 Hexagonal Hierarchical Spatial Index

#### System Overview

**H3 Geospatial Indexing System:**
- **Developer:** Uber Technologies, Inc.
- **Release Year:** 2018 (open-sourced)
- **License:** Apache License 2.0
- **Status:** Actively maintained open-source project

#### Official Resources

1. **GitHub Repository:**
   - Uber Technologies, Inc. (2018). *H3: Uber's Hexagonal Hierarchical Spatial Index*.
   - GitHub: https://github.com/uber/h3
   - Accessed: October 2025

2. **Official Documentation:**
   - H3 Documentation. *H3 Geospatial Indexing System*.
   - URL: https://h3geo.org/
   - Accessed: October 2025

3. **Original Announcement:**
   - Uber Engineering. (2018, June 27). *H3: Uber's Hexagonal Hierarchical Spatial Index*. Uber Engineering Blog.
   - URL: https://www.uber.com/blog/h3/
   - Accessed: October 2025
   - **Note:** URL returns 404 error as of October 2025; content may be archived

#### Technical Specification

**Citation for H3 System:**
```
Uber Technologies, Inc. (2018). H3: A Hexagonal Hierarchical Geospatial Indexing System
[Computer software]. GitHub. https://github.com/uber/h3
```

### 3. Flare Operational Data

**Industry Partner:** Flare (rescue.co)
- Emergency Medical Services platform operating in Nairobi, Kenya
- Operational data provided under research partnership agreement
- **Data Period:** August 2017 - August 2021
- **Records:** 6,840 emergency incidents in Nairobi metropolitan area
- **Variables:** Incident locations, ambulance base locations, response times
- **Privacy:** Data subject to partnership confidentiality agreement; not publicly released
- **Contact:** Maria Rabinovich (maria@rescue.co)

**Data Statement:**
> Flare operational data is proprietary and subject to partnership agreements. It is not included in the public repository. Aggregated statistics and de-identified insights are reported in the research paper.

---

## Academic Literature: Uber Movement Methodology

### Journal Articles

1. **MDPI International Journal of Geo-Information (2020)**
   - Erhardt, G. D., Mucci, R. A., Cooper, D., Sana, B., Chen, M., & Castiglione, J. (2020). Do Transportation Network Companies Increase or Decrease Transit Ridership? Empirical Evidence from San Francisco. *IJGI*, 9(3), 184.
   - DOI: https://doi.org/10.3390/ijgi9030184
   - URL: https://www.mdpi.com/2220-9964/9/3/184
   - **Relevant Content:** Describes Uber Movement data structure using census tracts
   - **Note:** Does not specifically cover Nairobi or H3 hexagons

2. **Nature Scientific Data (2019)**
   - Aryandoust, A., van Vliet, O., & Patt, A. (2019). City-scale car traffic and parking density maps from Uber Movement travel time data. *Scientific Data*, 6(1), 158.
   - DOI: https://doi.org/10.1038/s41597-019-0159-6
   - URL: https://www.nature.com/articles/s41597-019-0159-6
   - **Relevant Content:** Methodology for converting Uber Movement data to traffic density maps

3. **EPJ Data Science (2020)**
   - Najmi, A., Rashidi, T. H., & Abbasi, M. (2020). A weighted travel time index based on data from Uber Movement. *EPJ Data Science*, 9, 21.
   - DOI: https://doi.org/10.1140/epjds/s13688-020-00241-y
   - URL: https://epjdatascience.springeropen.com/articles/10.1140/epjds/s13688-020-00241-y
   - **Relevant Content:** Travel time index construction using Uber Movement data

### Conference Papers & Technical Reports

4. **Stanford CS224W Project (2017)**
   - Pearson, M. *Traffic Flow Analysis Using Uber Movement Data*. Stanford University CS224W Final Project Report.
   - URL: http://snap.stanford.edu/class/cs224w-2017/projects/cs224w-11-final.pdf
   - **Relevant Content:** Graph-based analysis of Uber Movement travel time networks

### Transportation Research Articles

5. **Transportation Research Part A (2021)**
   - Shabanpour, R., Golshani, N., Tayarani, M., Auld, J., & Mohammadian, A. (2021). Analysis of human movement in the Miami metropolitan area utilizing Uber Movement data. *Transportation Research Part A: Policy and Practice*, 149, 50-63.
   - DOI: https://doi.org/10.1016/j.tra.2021.04.016
   - **Relevant Content:** Demonstrates use of Uber Movement for metropolitan mobility analysis

---

## Technical References: Graph Theory & Algorithms

### Shortest Path Algorithms

6. **Dijkstra's Algorithm**
   - Dijkstra, E. W. (1959). A note on two problems in connexion with graphs. *Numerische Mathematik*, 1(1), 269-271.
   - DOI: https://doi.org/10.1007/BF01386390
   - **Usage:** Shortest path calculation in Distance Matrix.R

### R Package Documentation

7. **igraph R Package**
   - Csardi, G., & Nepusz, T. (2006). The igraph software package for complex network research. *InterJournal*, Complex Systems, 1695.
   - URL: https://igraph.org/r/
   - CRAN: https://CRAN.R-project.org/package=igraph
   - **Usage:** Graph construction and shortest path algorithms

8. **tidyverse R Packages**
   - Wickham, H., et al. (2019). Welcome to the tidyverse. *Journal of Open Source Software*, 4(43), 1686.
   - DOI: https://doi.org/10.21105/joss.01686
   - URL: https://www.tidyverse.org/
   - **Usage:** Data manipulation in read_uber_data.r

9. **lubridate R Package**
   - Grolemund, G., & Wickham, H. (2011). Dates and times made easy with lubridate. *Journal of Statistical Software*, 40(3), 1-25.
   - DOI: https://doi.org/10.18637/jss.v040.i03
   - **Usage:** Date parsing and handling

---

## Related Research: EMS & Location Optimization

### Emergency Medical Services Literature

10. **Maximum Expected Covering Location Problem (MEXCLP)**
    - Daskin, M. S. (1983). A maximum expected covering location model: Formulation, properties and heuristic solution. *Transportation Science*, 17(1), 48-70.
    - DOI: https://doi.org/10.1287/trsc.17.1.48
    - **Relevance:** Foundation for coverage optimization model (Paper Section 3.2)

11. **EMS Location Reviews**
    - Bélanger, V., Ruiz, A., & Soriano, P. (2019). Recent optimization models and trends in location, relocation, and dispatching of emergency medical vehicles. *European Journal of Operational Research*, 272(1), 1-23.
    - DOI: https://doi.org/10.1016/j.ejor.2018.02.055
    - **Relevance:** Literature review positioning

12. **LMIC EMS Context**
    - Boutilier, J. J., & Chan, T. C. Y. (2020). Ambulance emergency response optimization in developing countries. *Operations Research*, 68(5), 1315-1334.
    - DOI: https://doi.org/10.1287/opre.2019.1969
    - **Relevance:** Similar low- and middle-income country context

---

## Media & Industry Sources: Uber Movement Nairobi

### Uber Blog Posts

13. **Nairobi Movement Launch**
    - Uber Movement Team. (2019). *Nairobi's growing nucleus and deteriorating speeds*. Medium: Uber Movement.
    - URL: https://medium.com/uber-movement/nairobis-growing-nucleus-and-deteriorating-speeds-9fc8a019a1fd
    - Accessed: October 2025

14. **Nairobi Floods Analysis**
    - Uber Movement Team. *How March Floods Affected Nairobi Travel Times*. Medium: Uber Movement.
    - URL: https://medium.com/uber-movement/how-march-floods-affected-nairobi-travel-times-eaf850285004
    - **Relevance:** Example of Nairobi-specific Uber Movement analysis

### News Articles

15. **Uber Movement Kenya Launch**
    - Innov8tiv. (2019). *Uber Movement, the data sharing portal by Uber now available to the public in Kenya*.
    - URL: https://innov8tiv.com/uber-movement-the-data-sharing-portal-by-uber-now-available-to-the-public-in-kenya/
    - Accessed: October 2025

16. **Business Daily Africa**
    - Business Daily. (2019, May 13). *Uber launches Nairobi traffic data website*.
    - URL: https://www.businessdailyafrica.com/bd/corporate/companies/uber-launches-nairobi-traffic-data-website-2202634
    - Accessed: October 2025

---

## Educational Resources

### Tutorials & Guides

17. **QGIS Tutorial: Travel Time Analysis**
    - Ujaval Gandhi. *Travel Time Analysis with Uber Movement (QGIS3)*. QGIS Tutorials and Tips.
    - URL: https://www.qgistutorials.com/en/docs/3/travel_time_analysis.html
    - Accessed: October 2025
    - **Relevance:** Practical guide to working with Uber Movement data structure

18. **Towards Data Science Articles**
    - Multiple articles on Uber Movement data analysis methodology
    - URL: https://towardsdatascience.com/ (search "Uber Movement")
    - **Relevance:** Community tutorials on data processing approaches

---

## Data Archival & Preservation

### Recommended Archives

**Wayback Machine (Internet Archive):**
- URL: https://web.archive.org/
- **Suggested captures:** Uber Movement methodology PDF, H3 blog post, Nairobi-specific content
- **Note:** Researchers should attempt to locate archived versions of unavailable resources

**Zenodo / Figshare:**
- **Recommendation:** Upload processed datasets (Distances.txt, Distances_StdDev.txt) to academic repository
- **Purpose:** Ensure long-term accessibility for reproducibility
- **DOI:** To be assigned upon upload

---

## Citation Format Examples

### BibTeX Format

```bibtex
@misc{uber_movement_2017,
  author = {{Uber Technologies, Inc.}},
  title = {Uber Movement: Travel Times Data},
  year = {2017--2022},
  note = {Data platform discontinued. Accessed March 2022},
  url = {https://movement.uber.com/}
}

@software{uber_h3_2018,
  author = {{Uber Technologies, Inc.}},
  title = {H3: Uber's Hexagonal Hierarchical Spatial Index},
  year = {2018},
  publisher = {GitHub},
  url = {https://github.com/uber/h3},
  note = {Open-source software}
}

@article{daskin1983maxclp,
  author = {Daskin, Mark S.},
  title = {A maximum expected covering location model: Formulation, properties and heuristic solution},
  journal = {Transportation Science},
  volume = {17},
  number = {1},
  pages = {48--70},
  year = {1983},
  doi = {10.1287/trsc.17.1.48}
}
```

### APA Format

```
Uber Technologies, Inc. (2017-2022). Uber Movement: Travel times data [Data platform].
    https://movement.uber.com/ (Platform discontinued; data accessed March 2022)

Uber Technologies, Inc. (2018). H3: Uber's hexagonal hierarchical spatial index [Computer software].
    GitHub. https://github.com/uber/h3

Daskin, M. S. (1983). A maximum expected covering location model: Formulation, properties and
    heuristic solution. Transportation Science, 17(1), 48-70. https://doi.org/10.1287/trsc.17.1.48
```

---

## Data Availability Statement (Template for Paper)

### Suggested Text

> **Data Availability:** The Uber Movement travel time data used in this study was obtained from the Uber Movement platform (movement.uber.com) in March 2022, prior to the platform's discontinuation. Uber Movement provided aggregated, anonymized travel time data for Nairobi, Kenya, covering the period from 2016-Q1 to 2020-Q1. As the platform is no longer operational, this specific dataset is not publicly accessible. Processed distance matrices (mean travel times and standard deviations) derived from the Uber Movement data will be made available upon publication at [repository URL]. Flare operational data is proprietary and subject to partnership confidentiality agreements; aggregated statistics are reported in the paper. The data processing code is available at https://github.com/[username]/ems-platform.

---

## Acknowledgments

### Data Providers

- **Uber Technologies:** For making Movement data available for research purposes (2017-2022)
- **Flare:** For providing operational EMS data under research partnership
- **Uber Open Source:** For maintaining the H3 spatial indexing system

### Data Collection

- Original Uber Movement data: Aggregated from Uber ride GPS traces in Nairobi
- Flare incident data: Collected through operational EMS dispatch system
- Data anonymization: Performed by Uber (Movement) and research team (Flare)

---

**Document End**

**Note to Researchers:** Given the discontinuation of Uber Movement and potential link rot, it is recommended to:
1. Archive local copies of all cited PDFs and web resources
2. Use DOIs when available for permanent reference
3. Document access dates for all web resources
4. Consider uploading processed datasets to academic repositories (Zenodo, Figshare, etc.) for long-term preservation

For questions about citations or data sources, contact:
- Andre P. Calmon (andre.calmon@gatech.edu)
- Pieter L. van den Berg (vandenberg@rsm.nl)
