Introduction
The project we chose was based on implementing a program in R that would allow the estimation
of a #GARCH(1,1) model to check whether it was a meaningful model for checking its a valuable tool
for financial predictions. Specifically, the points requested were as follows:

• Write a general function that estimates a GARCH(1,1) for a time series, and that returns the
parameters, standard errors and the filtered variance process.
• Download at least 15 years of daily SP 500 data and estimate the GARCH model
• Use the estimated parameters and the filtered volatility to simulate a 95% confidence interval
for a 30 day prediction period. Do this for every day in your sample.
• Verify how often the realizations 30 days ahead violate the confidence interval. Make a nice
plot.
