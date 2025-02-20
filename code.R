library('SDEtools')

#Volatility parameters

#reverting parameter rate
lambda <- 2
#mean volatility
xi <- 0.08
#Volatility of volatility
gamma <- 0.05
#starting point
x0 <- 0.1
#risk-free rate
r <- 0.05

s0 <-1
#Time definitions
dt <- 0.005
t <- seq(0,1,dt)
steps <- length(t)
length(t)

#number of simulations chosen to compute
n <- 10000

#creating matrix for values generated by square-root diffusion model-volatility
Y <- matrix(0, nrow = steps, ncol = n)

#Creating matrix for entries data points in monte carlo simulation of stock prices
Z <- matrix(0, nrow = nrow(Y), ncol = ncol(Y))

#mean of all stock prices
M <- matrix(0, nrow = nrow(Y), ncol = 1)


#Colour Matrix
colours <- matrix(0, nrow = 1,ncol = ncol(Z))

Y_number <- matrix(0,nrow = 1, ncol = ncol(Y))
Z_number <- matrix(0,nrow = 1, ncol = ncol(Z))

#Setting parameters for the stock price generation

Z[1,] <- s0
Y[1,] <- x0

z <- rnorm(nrow(Z), 0, 1)

#nested loop which creates a set of volatility using the square-root diffusion measures
#then using the volatility for each t value creates a new data set for each set of 
#volatility.

#Then plots the volatility set and the stock price path side by side.

for(j in 1:ncol(Y)) {
 if (j== ncol(Y)) {
   Y_number[j] <- paste("V", ncol(Y), sep = "")
   Z_number[j] <- paste("Sim", ncol(Y), sep = "")
   colnames(Y) <- Y_number
   colnames(Z) <- Z_number
   for(i in 2:nrow(Y)) {Y[i,j] <- rCIR(n = 1,x0=Y[i-1,j],lambda=lambda,xi=xi,gamma=gamma,dt)
   z <- rnorm(nrow(Z), 0, 1)
   Z[i,j] <- Z[i-1,j] + Z[i-1,j] * r * dt + sqrt(Y[i-1,j]) * Z[i-1,j] * z[i] * Re(sqrt(dt))
   }
   print(mean(Z))
   print(var(Z[steps,]))
 } else{
   par(mfrow=c(1,2))
  z <- rnorm(nrow(Z), 0, 1)

  for(i in 2:nrow(Y)) {Y[i,j] <- rCIR(n = 1,x0=Y[i-1,j],lambda=lambda,xi=xi,gamma=gamma,dt)
  
    Z[i,j] <- Z[i-1,j] + Z[i-1,j] * r * dt + sqrt(Y[i-1,j]) * Z[i-1,j] * z[i] * Re(sqrt(dt))
  }
  colours[j] <- rgb(runif(1),runif(1),runif(1))
  Y_number[j] <- paste("V", j, sep = "")
  Z_number[j] <- paste("Sim", j, sep = "")
  
 }
}
M <- matrix(apply(Z, 1, mean), ncol = 1)

#the Euler discretization requires that when multiplying by the last term for the
#stock price, it must be multiplied by the square-root of dt. However, from 
#analysis there is less variation when it is not square-rooted.

#setting up the space to plot the different data sets and creating an empty plot

par(mfrow=c(1,2))
plot(t, type = "n", xlim = c(0,max(t)), ylim = c(0,max(Z)),ylab =  "S(t)", xlab = "t")

#plots all stock price sample paths on the same graph

for(j in 1:ncol(Z)){

  lines(t,Z[,j], col = paste(colours[j],sep = ""))
}

lines(t,M, col = "black", lwd = 2)

plot(t, type = "n", xlim = c(0,max(t)), ylim = c(0,max(Y)),ylab =  "V(t)", xlab = "t")

#plots all volatility sample paths on the same graph

for(j in 1:ncol(Z)){
  
  lines(t, Y[,j], col = paste(colours[j],sep = ""))
}
par(mfrow=c(1,2))
hist(Y[201,],breaks = 100, freq = FALSE,main = "p.d.f of V(201)", xlab = "Volatility")

hist(Z[201,], breaks = 100, freq = FALSE, main = "p.d.f of S(201)", xlab = "Stock Price")

ln_st<- log(Z)
par(mfrow = c(1,2))
plot(t, type = "n", xlim = c(0,max(t)), ylim = c(min(ln_st),max(ln_st)),ylab =  "ln S(t)", xlab = "t")

#plots all stock price sample paths on the same graph

for(j in 1:ncol(Z)){
  
  lines(t,ln_st[,j], col = paste(colours[j],sep = ""))
}

hist(ln_st[201,], freq = FALSE, breaks = 100, main = "p.d.f of ln S(201)", xlab = "ln S(201)")

#plots the distribution of Y, by adding [x,] for the row you can see the density of each row

#follows a noncentral chi-square distribution therefore does what I expect.

#begin constructing the characteristic function used in the Heston model:

#Characteristic function for Heston model created, now implement into pricing model

Option.pricer <- function(K ,S_t ,T_ ,t_ ,x_i ,rho_ ,sigma ,kappa ,s_0 ,x_0 ,i ) {

  #K      = Strike price
  #S_t    = Spot price
  #u      = variable of the characteristic function being integrated
  #T_     = Contract maturity date
  #t_     = Current time
  #x_i    = Mean of volatility
  #rho_   = Correlation between two Brownian motions
  #sigma  = Volatility of Volatility
  #kappa  = Rate of mean reversion
  #s_0    = Initial Spot price
  #x_0    = Initial Volatility
  #i      = Risk-free rate
  
  tau<- (T_ - t_)
  
  #define parameters and the Heston characteristic function
  Hestoncf <- function(u, tau, kappa, sigma, rho_, x_i, s_0, i,x_0) {
    
    E <- kappa - sigma * (1i) * u * rho_
    d <- sqrt(E^2 + (sigma^2) * (u^2 + u * 1i))
    tau2 <- (d * tau )/ 2
    A1 <- (u^2 + 1i * u) * sinh(tau2)
    A2 <- (d / x_0) * cosh(tau2) + (E / x_0) * sinh(tau2)
    A <- A1 / A2
    D <- log(d / x_0) + ((kappa - d) * tau) / 2 - log((d + E) / (2 * x_0) + ((d - E) * exp(-d * tau)) / (2 * x_0))
    F_ <- S_t * exp(i * tau)
    cf <- exp(((1i * u) * log(F_ / s0)) - ((kappa * x_i * rho_ *1i * u * tau) / sigma) - A + ((2 * kappa * x_i * D) / sigma^2))
    return(cf)
  }
  
  # Compute P1 and P2
  P1_integrand <- function(u) {
    hcf <- Hestoncf(u - 1i, tau, kappa, sigma, rho_, x_i, s_0, i, x_0)
    p1 <- Re((exp(-1i * log(K / s_0) * u) / (1i * u)) * hcf / Hestoncf(-1i, tau, kappa, sigma, rho_, x_i, s_0, i, x_0))
    return(p1)
  }
  
  P2_integrand <- function(u) {
    hcf <- Hestoncf(u, tau, kappa, sigma, rho_, x_i, s_0, i, x_0)
    p2 <- Re(exp(-1i * log(K / s_0) * u) / (1i * u) * hcf)
    return(p2)
  }
  
  #Probability 1 and 2 for spot price being >/= to the strike price
  P1_value <- integrate(P1_integrand, lower = 0, upper = 200, subdivisions = 2000)$value
  
  
  P2_value <- integrate(P2_integrand, lower = 0, upper = 200, subdivisions = 2000)$value
  
  P1 <- 0.5 + (1 / pi) * P1_value
  P2 <- 0.5 + (1 / pi) * P2_value
  
  #The actual price of the contract
  
  call <-  S_t * P1 - exp(-i * tau) * K * P2
  put  <-  call - S_t + K*exp(-i * tau)
  
  return(list(P1 = P1 ,P2 = P2 ,call = call ,tau = tau, put = put))
}

#Test parameters
rho<- -0.9
T <- max(t)


Option_price_1 <- matrix(1,nrow = nrow(Z),ncol = ncol(Z))
Option_price_2 <- matrix(1,nrow = nrow(Z),ncol = ncol(Z))
tau_values <- matrix(1, nrow = nrow(Z), ncol = ncol(Z))
P1_Values <- matrix(1, nrow = nrow(Z), ncol = ncol(Z))
P2_Values <- matrix(1, nrow = nrow(Z), ncol = ncol(Z))
tau_values_2 <- matrix(1, nrow = nrow(Z), ncol = ncol(Z))
P1_Values_2 <- matrix(1, nrow = nrow(Z), ncol = ncol(Z))
P2_Values_2 <- matrix(1, nrow = nrow(Z), ncol = ncol(Z))
Put.Options.1 <- matrix(1,nrow = nrow(Z),ncol = ncol(Z))
Put.Options.2 <- matrix(1,nrow = nrow(Z),ncol = ncol(Z))


K1 <- 0.5
K2 <- 2

for(j in 1:ncol(Z)){
  
  for(i in 1:nrow(Z)){
    option_data <- Option.pricer(K1, S_t = Z[i, j], T_ = T, t_ = t[i], xi, rho, gamma, lambda, s0, x0, r)
    Option_price_1[i, j] <- option_data$call
    tau_values[i, j] <- option_data$tau
    P1_Values[i, j] <- option_data$P1
    P2_Values[i, j] <- option_data$P2
    Put.Options.1[i,j] <- option_data$put
  }
  
}

for(j in 1:ncol(Z)){
  
  for(i in 1:nrow(Z)){
    option_data <- Option.pricer(K2, S_t = Z[i, j], T, t[i], xi, rho, gamma, lambda, s0, x0, r)
    Option_price_2[i, j] <- option_data$call
    tau_values_2[i, j] <- option_data$tau
    P1_Values_2[i, j] <- option_data$P1
    P2_Values_2[i, j] <- option_data$P2 
    Put.Options.2[i,j] <- option_data$put
  }
  
}

M_O1 <- matrix(apply(Option_price_1, 1, mean), ncol = 1)
M_O2 <- matrix(apply(Option_price_2, 1, mean), ncol = 1)
M.O1.put <- matrix(apply(Put.Options.1, 1, mean), ncol = 1)
M.O2.put <- matrix(apply(Put.Options.2, 1, mean), ncol = 1)

par(mfrow=c(1,2))
plot(t, type = "n", xlim = c(0,max(t)), ylim = c(min(Option_price_1,Option_price_2),max(Option_price_1,Option_price_2)),ylab =  "Call Option prices", xlab = "t",main = paste("Strike price K = ", K1))


#plotting all option prices on one graph
for(j in 1:ncol(Option_price_1)){
  
  lines(t,Option_price_1[,j], col = paste(colours[j],sep = ""))
}

lines(t, M_O1, col = "black",lwd = 3)
lines(t, M_O2, col = "navy",lwd = 3)


plot(t, type = "n", xlim = c(0,max(t)), ylim = c(min(Option_price_2),max(Option_price_2)),ylab =  "Call Option prices", xlab = "t",main = paste("Strike price K = ", K2))


for(j in 1:ncol(Option_price_2)){
  
  lines(t,Option_price_2[,j], col = paste(colours[j],sep = ""))
}

lines(t, M_O1, col = "black",lwd = 3)
lines(t, M_O2, col = "navy",lwd = 3)

plot(t, type = "n", xlim = c(0,max(t)), ylim = c(min(Put.Options.1,Put.Options.2),max(Put.Options.1,Put.Options.2)),ylab =  "Put Option prices", xlab = "t",main = paste("Strike price K = ", K1))

for(j in 1:ncol(Put.Options.1)){
  
  lines(t,Put.Options.1[,j], col = paste(colours[j],sep = ""))
}

lines(t, M.O1.put, col = "black",lwd = 3)
lines(t, M.O2.put, col = "navy",lwd = 3)

plot(t, type = "n", xlim = c(0,max(t)), ylim = c(min(Put.Options.1,Put.Options.2),max(Put.Options.1,Put.Options.2)),ylab =  "Put Option prices", xlab = "t",main = paste("Strike price K = ", K2))

for(j in 1:ncol(Put.Options.2)){
  
  lines(t,Put.Options.2[,j], col = paste(colours[j],sep = ""))
}

lines(t, M.O1.put, col = "black",lwd = 3)
lines(t, M.O2.put, col = "navy",lwd = 3)


K.test <- seq(min(Z),max(Z), (max(Z)-min(Z))/200)

Option.price.K <- matrix(0,nrow = length(K.test),ncol = ncol(Z))

for (j in 1:ncol(Option.price.K)) {
  for (i in 1:nrow(Option.price.K)) {
    Option.price.K[i,j] <- Option.pricer(K=K.test[i],S_t = Z[21,j],T_ = 201,t_ = 21,x_i = xi,rho_ = rho,sigma = gamma,kappa = lambda,s_0 = s0,x_0 = x0,i = r)$call
  }
}

plot(K.test, type = "n", xlim = c(min(K.test),max(K.test)), ylim = c(min(Option.price.K),max(Option.price.K)),ylab =  "Option prices wrt K", xlab = "K",main = paste("Days to maturity =", 180))


for (i in 1:ncol(Option.price.K)) {
  lines(K.test, Option.price.K[,i], col = paste(colours[i],sep = ""))
}

Option.price.K.90 <- matrix(0,nrow = length(K.test),ncol = ncol(Z))

for (j in 1:ncol(Option.price.K)) {
  for (i in 1:nrow(Option.price.K)) {
    Option.price.K.90[i,j] <- Option.pricer(K=K.test[i],S_t = Z[111,j],T_ = 201,t_ = 111,x_i = xi,rho_ = rho,sigma = gamma,kappa = lambda,s_0 = s0,x_0 = x0,i = r)$call
  }
}

plot(K.test, type = "n", xlim = c(min(K.test),max(K.test)), ylim = c(min(Option.price.K.90),max(Option.price.K.90)),ylab =  "Option prices wrt K", xlab = "K",main = paste("Days to maturity =", 90))


for (i in 1:ncol(Option.price.K.90)) {
  lines(K.test, Option.price.K.90[,i], col = paste(colours[i],sep = ""))
}

Option.price.K.60 <- matrix(0,nrow = length(K.test),ncol = ncol(Z))

for (j in 1:ncol(Option.price.K)) {
  for (i in 1:nrow(Option.price.K)) {
    Option.price.K.60[i,j] <- Option.pricer(K=K.test[i],S_t = Z[141,j],T_ = 201,t_ = 141,x_i = xi,rho_ = rho,sigma = gamma,kappa = lambda,s_0 = s0,x_0 = x0,i = r)$call
  }
}

plot(K.test, type = "n", xlim = c(min(K.test),max(K.test)), ylim = c(min(Option.price.K.60),max(Option.price.K.60)),ylab =  "Option prices wrt K", xlab = "K",main = paste("Days to maturity =", 60))


for (i in 1:ncol(Option.price.K.60)) {
  lines(K.test, Option.price.K.60[,i], col = paste(colours[i],sep = ""))
}

Option.price.K.30 <- matrix(0,nrow = length(K.test),ncol = ncol(Z))

for (j in 1:ncol(Option.price.K)) {
  for (i in 1:nrow(Option.price.K)) {
    Option.price.K.30[i,j] <- Option.pricer(K=K.test[i],S_t = Z[171,j],T_ = 201,t_ = 171,x_i = xi,rho_ = rho,sigma = gamma,kappa = lambda,s_0 = s0,x_0 = x0,i = r)$call
  }
}

plot(K.test, type = "n", xlim = c(min(K.test),max(K.test)), ylim = c(min(Option.price.K.30),max(Option.price.K.30)),ylab =  "Option prices wrt K", xlab = "K",main = paste("Days to maturity =", 30))


for (i in 1:ncol(Option.price.K.30)) {
  lines(K.test, Option.price.K.30[,i], col = paste(colours[i],sep = ""))
}

Option.price.K.20 <- matrix(0,nrow = length(K.test),ncol = ncol(Z))

for (j in 1:ncol(Option.price.K)) {
  for (i in 1:nrow(Option.price.K)) {
    Option.price.K.20[i,j] <- Option.pricer(K=K.test[i],S_t = Z[181,j],T_ = 201,t_ = 181,x_i = xi,rho_ = rho,sigma = gamma,kappa = lambda,s_0 = s0,x_0 = x0,i = r)$call
  }
}

plot(K.test, type = "n", xlim = c(min(K.test),max(K.test)), ylim = c(min(Option.price.K.20),max(Option.price.K.20)),ylab =  "Option prices wrt K", xlab = "K",main = paste("Days to maturity =", 20))


for (i in 1:ncol(Option.price.K.20)) {
  lines(K.test, Option.price.K.20[,i], col = paste(colours[i],sep = ""))
}

Option.price.K.10 <- matrix(0,nrow = length(K.test),ncol = ncol(Z))

for (j in 1:ncol(Option.price.K)) {
  for (i in 1:nrow(Option.price.K)) {
    Option.price.K.10[i,j] <- Option.pricer(K=K.test[i],S_t = Z[191,j],T_ = 201,t_ = 191,x_i = xi,rho_ = rho,sigma = gamma,kappa = lambda,s_0 = s0,x_0 = x0,i = r)$call
  }
}

plot(K.test, type = "n", xlim = c(min(K.test),max(K.test)), ylim = c(min(Option.price.K.10),max(Option.price.K.10)),ylab =  "Option prices wrt K", xlab = "K",main = paste("Days to maturity =", 10))


for (i in 1:ncol(Option.price.K.10)) {
  lines(K.test, Option.price.K.10[,i], col = paste(colours[i],sep = ""))
}
