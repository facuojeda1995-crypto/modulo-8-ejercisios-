# Pipeline de Ingeniería de Datos para Machine Learning (Feature Store)

## 📌 Propósito
Consolidar la capacidad de preparar datos para Machine Learning directamente desde la base de datos, 
optimizando el rendimiento, asegurando la consistencia de las variables y aplicando buenas prácticas de ingeniería de datos en SQL Server (SSMS).

---

## 🛠️ Pasos de Implementación
1. **Configuración del Entorno:** Creación de un repositorio en GitHub para alojar las consultas SQL y la documentación del proceso analítico.
2. **Definición de Features (Variables):** Implementación de una consulta modular utilizando CTEs y funciones de ventana para extraer las métricas clave de comportamiento por usuario:
   - **`recencia_dias`:** Días transcurridos desde la última compra del usuario respecto a una fecha de corte estándar.
   - **`frecuencia_pedidos`:** Cantidad de pedidos únicos realizados.
   - **`valor_monetario`:** Gasto total acumulado (LTV).
   - **`tendencia_gasto`:** Delta de gasto entre el último mes activo y el promedio histórico del usuario (calculado mediante `OVER` y `PARTITION BY`).
3. **Manejo de Nulos:** Uso estratégico de la función `COALESCE` para garantizar que los usuarios sin actividad reciente o sin historial devuelvan valores numéricos estables (`0` o marcas de tiempo por defecto) en lugar de valores nulos que interrumpan el entrenamiento del modelo.
4. **Documentación:** Explicación analítica del objetivo de cada *feature* y su valor predictivo para modelos de abandono (Churn).

---

## 📊 Diccionario Analítico de Features y Utilidad para Churn

recencia_dias (¿Cuándo fue su última compra?)

    Qué mide: Los días que pasaron desde su última compra.

    Por qué sirve para Churn: Es la señal de alarma más rápida. Si un cliente habitual deja de comprar por mucho tiempo, lo más seguro es que esté a punto de irse.

frecuencia_pedidos (¿Qué tan seguido compra?)

    Qué mide: La cantidad total de pedidos que hizo.

    Por qué sirve para Churn: Mide su hábito de compra. Los clientes que compran una sola vez y no vuelven son los más propensos al abandono.

valor_monetario (¿Cuánto dinero deja?)

    Qué mide: El gasto total acumulado del cliente.

    Por qué sirve para Churn: Mide el valor del cliente. Si un cliente que gasta mucho empieza a alejarse, el negocio pierde ingresos importantes, por lo que detectarlo a tiempo ayuda a retenerlo.

tendencia_gasto (¿Está gastando más o menos?)

    Qué mide: La diferencia entre lo que gastó este último mes comparado con su promedio de siempre.

    Por qué sirve para Churn: Detecta el desgaste (fatigue churn). Si notas que su gasto baja mes a mes, es una señal clara de que está perdiendo interés antes de irse del todo.

## ⚠️ Consideraciones y Errores Comunes Evitados

* **Uso correcto del `GROUP BY`:** Se agruparon de manera estricta todas las columnas dimensionales al combinar funciones de agregado, evitando fallos de sintaxis en el motor relacional.
* **Consistencia temporal:** Control estricto de las fechas para evitar periodos de tiempo incorrectos que sesguen las métricas de tendencia mensual y el promedio histórico.