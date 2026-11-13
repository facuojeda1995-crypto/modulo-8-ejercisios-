-- =========================================================================
-- PRE-ENTREGA: TABLA MAESTRA DE VARIABLES (FEATURES) PARA MACHINE LEARNING
-- Gestor: SQL Server (SSMS)
-- =========================================================================

-- 1. Base consolidada a nivel de detalle de pedido y categoría
WITH base_pedidos AS (
    SELECT 
        cli.cliente_id,
        cli.nombre AS nombre_cliente,
        cli.ciudad,
        ped.pedido_id,
        ped.fecha AS fecha_pedido,
        COALESCE(SUM(CAST(det.cantidad AS DECIMAL(10,2)) * pro.precio), 0.0) AS monto_pedido
    FROM clientes cli
    LEFT JOIN pedidos ped ON cli.cliente_id = ped.cliente_id
    LEFT JOIN detalles_pedido det ON ped.pedido_id = det.pedido_id
    LEFT JOIN productos pro ON det.producto_id = pro.producto_id
    GROUP BY cli.cliente_id, cli.nombre, cli.ciudad, ped.pedido_id, ped.fecha
),

-- 2. Agregación RFM (Recencia, Frecuencia, Monetario) y cálculo base por usuario
rfm_agregado AS (
    SELECT 
        cliente_id,
        nombre_cliente,
        ciudad,
        -- Monetario: Gasto total acumulado (LTV)
        COALESCE(SUM(monto_pedido), 0.0) AS valor_monetario,
        
        -- Frecuencia: Cantidad total de pedidos únicos
        COUNT(DISTINCT pedido_id) AS frecuencia_pedidos,
        
        -- Recencia: Días transcurridos desde la última compra respecto a una fecha de corte
        DATEDIFF(DAY, MAX(fecha_pedido), '2026-03-01') AS recencia_dias
    FROM base_pedidos
    GROUP BY cliente_id, nombre_cliente, ciudad
),

-- 3. Cálculo de métricas mensuales y promedio histórico por usuario para la Tendencia (Trend)
gasto_mensual AS (
    SELECT 
        cliente_id,
        YEAR(fecha_pedido) AS anio,
        MONTH(fecha_pedido) AS mes,
        SUM(monto_pedido) AS gasto_mes
    FROM base_pedidos
    WHERE fecha_pedido IS NOT NULL
    GROUP BY cliente_id, YEAR(fecha_pedido), MONTH(fecha_pedido)
),

tendencia_calculada AS (
    SELECT 
        gm.cliente_id,
        gm.anio,
        gm.mes,
        gm.gasto_mes,
        -- Promedio histórico del usuario usando funciones de ventana (PARTITION BY)
        AVG(gasto_mes) OVER (PARTITION BY gm.cliente_id) AS promedio_historico_gasto,
        -- Ordenamos para identificar el último mes registrado por cada cliente
        ROW_NUMBER() OVER (PARTITION BY gm.cliente_id ORDER BY gm.anio DESC, gm.mes DESC) AS num_fila
    FROM gasto_mensual gm
),

ultimo_mes_gasto AS (
    SELECT 
        cliente_id,
        gasto_mes AS gasto_ultimo_mes,
        promedio_historico_gasto
    FROM tendencia_calculada
    WHERE num_fila = 1
)

-- 4. Consulta final integrando todas las variables (features) y manejo robusto de nulos
SELECT 
    r.cliente_id,
    r.nombre_cliente,
    r.ciudad,
    COALESCE(r.recencia_dias, 999) AS recencia_dias,          -- 999 o valor estándar para inactivos
    COALESCE(r.frecuencia_pedidos, 0) AS frecuencia_pedidos,    -- 0 para clientes sin pedidos
    COALESCE(r.valor_monetario, 0.0) AS valor_monetario,        -- 0.0 para monetario nulo
    -- Tendencia (Trend): Delta de gasto entre el último mes y el promedio histórico
    COALESCE(u.gasto_ultimo_mes, 0.0) - COALESCE(u.promedio_historico_gasto, 0.0) AS tendencia_gasto
FROM rfm_agregado r
LEFT JOIN ultimo_mes_gasto u ON r.cliente_id = u.cliente_id;