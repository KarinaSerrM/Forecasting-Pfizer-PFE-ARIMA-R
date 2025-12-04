# Forecasting-Pfizer-PFE-ARIMA-R

Este proyecto implementa un modelo estadístico de series temporales en **R** para predecir el precio de cierre ajustado de las acciones de **Pfizer Inc. (PFE)**. El script automatiza todo el flujo de trabajo: desde la extracción de datos financieros hasta la generación de pronósticos futuros con intervalos de confianza.

## Descripción del Proyecto

El objetivo es generar predicciones a corto plazo (10 días hábiles) basadas en el comportamiento histórico de los últimos 7 años. A diferencia de un ajuste simple, este código realiza una transformación de los datos a retornos logarítmicos para asegurar la estacionariedad y valida el modelo mediante una técnica robusta de *Rolling Window Backtesting*.

### Características Principales
* **Extracción Automática:** Descarga datos en tiempo real desde Yahoo Finance (`quantmod`).
* **Limpieza de Datos:** Detección y tratamiento de outliers utilizando el Rango Intercuartílico (IQR).
* **Modelado:** Selección automática del mejor modelo ARIMA (`auto.arima`) optimizado para retornos logarítmicos.
* **Validación Rigurosa:** Backtesting iterativo (Rolling Window) para evaluar la precisión del modelo fuera de la muestra (Out-of-sample).
* **Visualización:** Gráficos profesionales con `ggplot2` que muestran la serie histórica y el "fan chart" de predicción.

## Tecnologías y Librerías

El proyecto está desarrollado en **R**. Las dependencias principales son:

* `quantmod`: Descarga de datos financieros.
* `forecast`: Algoritmos ARIMA y herramientas de predicción.
* `tidyverse` & `ggplot2`: Manipulación de datos y gráficos.
* `tseries`: Pruebas de series temporales.

## Instalación y Uso

1.  **Clonar el repositorio:**
    ```bash
    git clone [https://github.com/TU_USUARIO/Pfizer-ARIMA-Stock-Predictor.git](https://github.com/TU_USUARIO/Forecasting-Pfizer-PFE-ARIMA-R.git)
    ```

2.  **Instalar librerías necesarias en R:**
    ```r
    install.packages(c("quantmod", "tidyverse", "forecast", "tseries", "ggplot2", "gridExtra"))
    ```

3.  **Ejecutar el script:**
    Abre el archivo `Pfizer prediccion al cierre.R` en RStudio y ejecútalo.

## Metodología

El script sigue los siguientes pasos lógicos:

1.  **Pre-procesamiento:** Se calculan los precios de cierre ajustados y se limpian valores extremos que podrían distorsionar el modelo (Clip IQR).
2.  **Transformación:** Se convierten los precios a **Retornos Logarítmicos Diarios** para estabilizar la varianza.
    $$ r_t = \ln(P_t) - \ln(P_{t-1}) $$
3.  **Entrenamiento:** Se divide la data en 80% Train y 20% Test.
4.  **Evaluación:** Se calculan métricas de error (MAE, RMSE, MAPE) simulando predicciones día a día sobre el conjunto de prueba.
5.  **Pronóstico Final:** Se re-entrena el modelo con el 100% de los datos y se proyectan 10 días, revirtiendo la transformación logarítmica para obtener precios en USD.

## Resultados

El script genera automáticamente:
* Un reporte en consola con las métricas de error (MAE, RMSE, MAPE).
* Un archivo CSV: `Pronostico_Pfizer_10dias.csv` con los valores esperados y rangos de volatilidad (80% y 95%).
* Un gráfico visual del pronóstico.

## Disclaimer Financiero

Este software es para fines educativos y de investigación únicamente. **No constituye asesoramiento financiero ni una recomendación de inversión.** El mercado de valores conlleva riesgos y los modelos predictivos no garantizan resultados futuros.

## Autor

**Karina Serrano**
https://www.linkedin.com/in/karina-serrano-data-science/

## Agradecimientos

- Yahoo Finance por proporcionar datos financieros históricos
- Comunidad R por las excelentes librerías de series temporales

---

⭐ Si este proyecto te resultó útil, considera darle una estrella en GitHub
