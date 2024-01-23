# Adaptive Control System for Speed Harmonization
The **purpose of speed harmonization** is to change traffic speed on links that approach areas of traffic congestion, bottlenecks, incidents, special events, and other conditions that affect flow. Speed harmonization assists in maintaining **flow**, reducing unnecessary stops and starts, and maintaining consistent speeds.
Note: A link refers to a segment of a roadway.
The Speed Harmonization System is inspired from https://www.arc-it.net/html/servicepackages/sp68.html#tab-3.

The Speed Harmonization System, which takes into account numerous traffic, environmental, and road surface elements, demonstrates the features of a **nonlinear dynamic system**. Each of these elements has the potential to significantly impact traffic flow in complex ways that are not strictly characterized by linearity or predictability.

Utilizing a **data-driven methodology** for the speed harmonization system, particularly inside a MATLAB environment, might be a practical and enlightening decision for several reasons. This strategy primarily utilizes extensive data (including traffic, environmental, and road conditions) to create models and forecast the most effective speed restrictions.

The model's input will be composed of:
1. Traffic conditions (by using data from https://utd19.ethz.ch/)
   a. Speed
   b. Flow
   c. Density
2. Environmental conditions
   a. Temperature
   b. WindSpeed
   c. Humidity
   d. Precipitation
   e. Visibility
3. Road surface conditions
   a. Surface Temperature
   b. Moisture
   c. Icing
   d. Salinity

The model's output will be the optimal speed for each road Segment x Lane.