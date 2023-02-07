# Load Data
require(quantmod)
SP500_1988_2022 <- as.matrix(getSymbols("^SP500TR", 
                                        env = NULL, 
                                        from = "1988-01-01",
                                        to = "2022-12-01",
                                        periodicity = "daily"))

# Daily log returns
SP500return <- NULL
for( i in 2:length(SP500_1988_2022[,6])){
  SP500return[i-1] <- log(SP500_1988_2022[i,6]/SP500_1988_2022[i-1,6])
}





#Plot Daily Closing Prices and Daily Returns
Date <- as.Date(rownames(SP500_1988_2022))
Price <- as.numeric(SP500_1988_2022[,6])

Date_Price <- data.frame(Date, Price, stringsAsFactors = FALSE)
plot(Date_Price, type="l", xlab="Date", ylab="Price")

Date_Return <- data.frame(Date[-1], SP500return, stringsAsFactors = FALSE)
plot(Date_Return, type="l", xlab="Date")







#Starting Values omega, alpha, beta ; a.k.a parameters of garch
Starting_Values <- c(0.00001, 0.05, 0.8)

# Create function that stores the "Garch value" for each return:
Garch_Recursion <- function(omega, alpha, beta, return){
  # conditional variance matrix:
  Sigma2 <- NULL
  # Store "garch value" for each return:
  for (i in 1:length(return)){
    # Initial variance -> unconditional variance/long run variance/sample variance
    if (i == 1){
      Sigma2[i] <- var(return)
    } 
    else
      # garch(1,1) model:
      Sigma2[i] <- omega + alpha*(return[i-1])^2 + beta*Sigma2[i-1]
  }
  return(Sigma2)
}





# Garch loglikelihood function
Garch_Loglikelihood <- function(garch_parameters, return){
  # Create conditional variance matrix using garch recursion function:
  omega <- garch_parameters[1]
  alpha <- garch_parameters[2]
  beta <- garch_parameters[3]
  conditional_variance <- Garch_Recursion(omega, alpha, beta, return)
  #Loglikelihood function estimation
  Loglikelihood_value <- -0.5*sum(log(2*pi) + log(conditional_variance) + return^2/conditional_variance )
  return(-Loglikelihood_value)# (-) because optim minimizes by default
}





# General garch(1,1) function:
require(matlib) # for sqrt
GARCH <- function(garch_parameters, return){
  
  # Maximize loglike by calling garch_loglike in optim function
  MLE <- optim(garch_parameters, Garch_Loglikelihood, gr = NULL, return)
  Estimated_omega <- MLE$par[1]
  Estimated_alpha <- MLE$par[2]
  Estimated_beta <- MLE$par[3]
  
  # Applying estimated parameters to model (computing sigma2_1 to sigma2_t)
  Estimated_sigma2 <- Garch_Recursion(Estimated_omega, Estimated_alpha, Estimated_beta, SP500return)
  Expectation_estimatedsigma2 <- mean(Estimated_sigma2)
  
  # Expectation of future variance by setting innovations to zero => return = 0 :
  Future_sigma2 <- Estimated_omega + Estimated_beta*Expectation_estimatedsigma2
  
  # Filtered volatility
  Filtered_volatility <- sqrt(Future_sigma2)
  
  # Future_sigma2 from t+1 to t+30 for Confidence Interval
  Future_variance <- NULL 
  for (i in 1:30){
    if(i==1){
      Future_variance[i] <- Future_sigma2 
    }
    else{
      Future_variance[i] <- Estimated_omega + Estimated_alpha*mean(return^2) + Estimated_beta*Future_variance[i-1]
    }
  }
  
  # 95% Confidence Interval
  Lower <- NULL
  Upper <- NULL
  Margin <- qt(0.975, df= length(return)-1)*sqrt(var(return))/sqrt(length(return))
  for (i in 1:30) {
    Lower[i] <- c(sqrt(Future_variance[i]) - Margin)
    Upper[i] <- c(sqrt(Future_variance[i]) + Margin)
  }
  Confidence_interval <- cbind(Lower, Upper)
  
  # Verify how often the realizations 30 days ahead violate the confidence interval
  Verification1 <- c(Filtered_volatility >= Confidence_interval[, 1] & Filtered_volatility<=Confidence_interval[, 2])
  
  
  # Printing Everything:
  
  print(paste("Estimated omega:", round(Estimated_omega, digits= 6)))
  print(paste("Estimated alpha:", round(Estimated_alpha, digits= 4)))
  print(paste("Estimated beta:", round(Estimated_beta, digits= 4))) 
  print(paste("Filtered Volatility:", round(Filtered_volatility, digits= 4)))
  print("Confidence Interval for each day in a 30 day prediction period:")
  print(round(Confidence_interval, digits= 6))
  print(paste("Percentage that does not violate CI:", round(sum(Verification1)/30, digits= 4) * 100, "%" ))
  plot(Verification1 , type="l", xlab="Days")
  
}

# Run program
GARCH(Starting_Values, SP500return)



