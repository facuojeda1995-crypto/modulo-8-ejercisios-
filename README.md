vamos a explicar el razonamiento de cada consulta... 

consulta 1: el objetivo es obtener todas las columnas originales y añadir el promedio de gasto 
de ese cliente específico sin reducir las filas (sin GROUP BY).
use: PARTITION BY cliente_id agrupa los cálculos por cliente de forma aislada, 
permitiendo ver cada pedido al lado del promedio general del comprador.

consulta 2 :el objetivo es Calcular el total acumulado de ventas de la empresa ordenado cronológicamente.
use:  ORDER BY fecha dentro de OVER() es obligatorio para que la función SUM() 
actúe como un acumulativo progresivo (fila por fila en función del tiempo).

consulta 3 : el objetivo fue calcular qué porcentaje representa cada pedido respecto al total de su categoría.
Use: PARTITION BY categoria para sumar el importe total de toda la categoría en esa "ventana" 
y dividir el importe individual del pedido entre ese total.

¿Por qué se eligió `PARTITION BY cliente_id` en el primer punto?
Se utiliza `PARTITION BY cliente_id` para seccionar o dividir el conjunto de datos 
en "ventanas" lógicas independientes por cada cliente. 
De esta forma, la función de agregación `AVG(importe)` calcula el promedio de gasto exclusivamente en función de las compras
de ese usuario en particular, sin mezclar los datos de otros clientes. 
Al mismo tiempo, como es una función de ventana y no un `GROUP BY`, 
la consulta devuelve **todas las filas originales**, permitiendo comparar 
el importe de un pedido puntual contra el comportamiento histórico de su respectivo comprador.

¿Cómo cambia el resultado si quitas el `ORDER BY fecha` en el segundo punto (Ventas Acumuladas)?
Si se omite el `ORDER BY fecha` dentro de la cláusula `OVER()`, 
la función `SUM(importe)` deja de calcular un acumulativo progresivo ordenado en el tiempo. 
En su lugar, el motor SQL aplica la suma sobre **toda la partición completa** para cada fila de manera estática. 
Esto daría como resultado que todas las filas muestren la **suma total global de la empresa** repetida en cada registro,
perdiendo por completo la noción de crecimiento cronológico acumulado.



### 2. ¿Cómo cambia el resultado si quitas el `ORDER BY fecha` en el segundo punto (Ventas Acumuladas)?
Si se omite el `ORDER BY fecha` dentro de la cláusula `OVER()`, la función `SUM(importe)` deja de calcular un acumulativo progresivo (*running total* o suma móvil) ordenado en el tiempo. En su lugar, el motor SQL aplica la suma sobre **toda la partición completa** (o sobre toda la tabla si no hay partición) para cada fila de manera estática. Esto daría como resultado que todas las filas muestren exactamente la **suma total global de la empresa** repetida en cada registro, perdiendo por completo la noción de crecimiento cronológico acumulado.
