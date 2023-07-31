# Distributed_household_opt

Title: Energy Flows and Optimization Model for Danish Prosumer Households
Introduction

This GitHub repository contains the code and data associated with a research paper focused on energy flows and optimization models for Danish prosumer households. The study aims to investigate the impact of taxing self-consumed solar production in various scenarios, considering the rapid growth of solar PV, heat pumps, and electric vehicles in residential buildings in Denmark.
Data Description

The research uses hourly electricity consumption data from smart meters linked to socio-economic consumer categories, defining household characteristics based on dwelling type, occupancy, dwelling area, and income level. The dataset includes 35 categories, each connected to 1000 randomized synthetic profiles of electricity consumption.
Mathematical Formulation of the Optimization Model

The paper formulates an optimization model focusing on the least-cost operation of equipment while fulfilling technical constraints. The objective function minimizes the total cost for each household and hourly time steps, considering operational costs associated with meeting basic electricity, heat, and electric vehicle demand. The model includes electricity taxes, grid tariffs, and tax refunds for exports, and it differentiates between BAU (business as usual) and NTAX (new tax) scenarios.
Constraints

The constraints of the optimization model cover the supply of basic electricity and heat demand in households, electricity imports, and exports from the grid, PV production, and battery charging and discharging. The model also considers smart charging of electric vehicles, including the availability of the vehicle and trip constraints.
Case Study

The research focuses on Danish prosumer households and their characteristics based on socio-economic categories. The study considers single-family houses and semi-detached houses with various occupancy rates, dwelling areas, and income levels. It further assumes that each household owns solar PV, a battery, and an electric vehicle, and heat pumps and heat storage supply the heat for each building.
Conclusion

The research provides insights into the impact of taxing self-consumed solar production and optimizing energy flows in Danish prosumer households. The findings contribute to the understanding of the energy landscape and electricity cost distribution in the context of increasing adoption of solar PV, heat pumps, and electric vehicles in residential buildings.

No liability taken if you burn your CPU or if the there are mistakes in the description text above.
For more details, please refer to the full paper under review: https://arxiv.org/ftp/arxiv/papers/2306/2306.11566.pdf.

