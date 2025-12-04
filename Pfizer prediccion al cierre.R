# PREDICCIÓN PFIZER (PFE)
# ===============================================================

# Cargar librerías
library(quantmod)
library(tidyverse)
library(forecast)
library(tseries)
library(ggplot2)
library(gridExtra)  

# Fechas: últimos 7 años aproximados
start_date <- Sys.Date() %m-% years(7)
end_date   <- Sys.Date()

cat("Descargando datos de PFE desde", as.character(start_date), "hasta", as.character(end_date), "\n")

# Descargar datos
getSymbols("PFE", src = "yahoo", from = start_date, to = end_date, auto.assign = TRUE)

# Precio de cierre ajustado
pfe_close <- Ad(PFE)
df <- data.frame(Date = index(pfe_close),
                 Close = as.numeric(pfe_close))

# Detección y limpieza de outliers (método IQR)
Q1 <- quantile(df$Close, 0.25)
Q3 <- quantile(df$Close, 0.75)
IQR_val <- Q3 - Q1
lower_bound <- Q1 - 1.5 * IQR_val
upper_bound <- Q3 + 1.5 * IQR_val

df$Close_clean <- pmin(pmax(df$Close, lower_bound), upper_bound)

# Serie temporal limpia
ts_clean <- ts(df$Close_clean, frequency = 252)

# Transformación a retornos logarítmicos
ts_log  <- log(ts_clean)
ts_ret  <- diff(ts_log)                  # retornos log diarios
ts_ret  <- ts(ts_ret, frequency = 252)

# Eliminar el primer NA que genera diff
df_ret <- data.frame(
  Date   = df$Date[-1],
  Return = as.numeric(ts_ret)
)

# División de nuestra base de datos train/test (80% / 20%)
n          <- length(ts_ret)
train_size <- floor(0.8 * n)
train <- ts(ts_ret[1:train_size], frequency = 252)
test  <- ts(ts_ret[(train_size+1):n], frequency = 252)

# === LÍNEA DE VALIDACIÓN ===
if(any(is.na(train))) stop("NA detectado en train. Revisa la transformación.")

cat("\nTotal días con retorno:", n, "\n")
cat("Train:", train_size, "días | Test:", n - train_size, "días\n")

# Ajuste del mejor modelo ARIMA en train (sin estacionalidad)
best_model_train <- auto.arima(train, 
                               seasonal = FALSE,
                               stepwise = TRUE,
                               approximation = FALSE,
                               max.p = 5, max.q = 5, max.d = 2)

cat("\n=== MEJOR MODELO ENCONTRADO (train) ===\n")
print(best_model_train)

# Diagnóstico rápido de residuos
cat("\n=== Diagnóstico de residuos ===\n")
checkresiduals(best_model_train, silent = TRUE)

# Backtesting rolling window *
n_test     <- length(test)
forecasts  <- numeric(n_test)
lower80    <- numeric(n_test)
upper80    <- numeric(n_test)
lower95    <- numeric(n_test)
upper95    <- numeric(n_test)

cat("\nRealizando backtest rolling...\n")
pb <- txtProgressBar(min = 0, max = n_test, style = 3)

for(i in 1:n_test) {
  current_train <- ts_ret[1:(train_size + i - 1)]
  model_roll    <- Arima(current_train, model = best_model_train)
  fc            <- forecast(model_roll, h = 1, level = c(80, 95))
  
  forecasts[i]  <- as.numeric(fc$mean)
  lower80[i]    <- fc$lower[1,1]
  upper80[i]    <- fc$upper[1,1]
  lower95[i]    <- fc$lower[1,2]
  upper95[i]    <- fc$upper[1,2]
  
  setTxtProgressBar(pb, i)
}
close(pb)

# Métricas de error
mae  <- mean(abs(test - forecasts))
rmse <- sqrt(mean((test - forecasts)^2))
mape <- mean(abs((test - forecasts)/test)) * 100

cat("\n=== RESULTADOS BACKTEST ===\n")
cat("MAE :", round(mae, 6), "\n")
cat("RMSE:", round(rmse, 6), "\n")
cat("MAPE:", round(mape, 3), "%\n")

#  PRONÓSTICO REAL: Reentrenar con todos los datos
model_final <- Arima(ts_ret, model = best_model_train)  

cat("\nModelo final reentrenado con TODA la serie (máxima información)\n")

# Pronóstico 10 días hábiles adelante
h <- 10
fc_future <- forecast(model_final, h = h, level = c(80, 95))

# Convertir retornos pronosticados a precios (método exacto)
last_price <- tail(df$Close_clean, 1)

price_mean <- last_price * cumprod(exp(fc_future$mean))
price_lo80 <- last_price * cumprod(exp(fc_future$lower[,1]))
price_hi80 <- last_price * cumprod(exp(fc_future$upper[,1]))
price_lo95 <- last_price * cumprod(exp(fc_future$lower[,2]))
price_hi95 <- last_price * cumprod(exp(fc_future$upper[,2]))

# Data frame del pronóstico
future_dates <- seq(max(df$Date) + 1, by = "day", length.out = h)
future_dates <- future_dates[!weekdays(future_dates) %in% c("Saturday", "Sunday")]  # solo hábiles
if(length(future_dates) > h) future_dates <- future_dates[1:h]  # ajuste por festivos

pronostico_precios <- data.frame(
  Fecha = future_dates[1:h],
  Precio_Pronosticado = round(as.numeric(price_mean), 2),
  Inferior_80 = round(as.numeric(price_lo80), 2),
  Superior_80 = round(as.numeric(price_hi80), 2),
  Inferior_95 = round(as.numeric(price_lo95), 2),
  Superior_95 = round(as.numeric(price_hi95), 2)
)

cat("\n=== PRONÓSTICO DE PRECIOS PFIZER - PRÓXIMOS 10 DÍAS HÁBILES ===\n")
print(pronostico_precios)

# Gráfico final con pronósticos 
df_plot <- rbind(
  data.frame(Fecha = df$Date, Precio = df$Close_clean, Tipo = "Histórico"),
  data.frame(Fecha = pronostico_precios$Fecha, 
             Precio = pronostico_precios$Precio_Pronosticado, 
             Tipo = "Pronóstico")
)

ggplot() +
  geom_line(data = subset(df_plot, Tipo == "Histórico"), 
            aes(x = Fecha, y = Precio), color = "steelblue", size = 0.8) +
  geom_line(data = subset(df_plot, Tipo == "Pronóstico"), 
            aes(x = Fecha, y = Precio), color = "red", size = 1.2) +
  geom_ribbon(data = pronostico_precios, 
              aes(x = Fecha, ymin = Inferior_80, ymax = Superior_80), 
              fill = "orange", alpha = 0.3) +
  geom_ribbon(data = pronostico_precios, 
              aes(x = Fecha, ymin = Inferior_95, ymax = Superior_95), 
              fill = "orange", alpha = 0.2) +
  labs(title = "Pfizer (PFE) - Precio Histórico + Pronóstico 10 días",
       subtitle = paste("Modelo final:", best_model_train),
       y = "Precio de Cierre Ajustado (USD)", x = "Fecha") +
  theme_minimal(base_size = 13) +
  theme(plot.title = element_text(face = "bold"))

cat("\n¡Listo! Pronóstico actualizado al", as.character(Sys.Date()), "\n")
# Guardamos resultados en un archivo CSV
write.csv(pronostico_precios, "Pronostico_Pfizer_10dias.csv", row.names = FALSE)