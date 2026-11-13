CREATE TABLE clientes (
    cliente_id INT PRIMARY KEY,
    nombre VARCHAR(50),
    ciudad VARCHAR(50)
);

CREATE TABLE pedidos (
    pedido_id INT PRIMARY KEY,
    cliente_id INT,
    fecha DATE
);

CREATE TABLE productos (
    producto_id INT PRIMARY KEY,
    nombre_producto VARCHAR(50),
    categoria VARCHAR(50),
    precio DECIMAL(10,2)
);

CREATE TABLE detalles_pedido (
    detalle_id INT PRIMARY KEY,
    pedido_id INT,
    producto_id INT,
    cantidad INT
);
-- Inserción de datos de prueba
INSERT INTO clientes VALUES (1, 'Ana', 'Madrid'), (2, 'Carlos', 'Barcelona'), (3, 'Lucía', 'Madrid'), (4, 'Marcos', 'Valencia');
INSERT INTO pedidos VALUES (101, 1, '2026-01-01'), (102, 1, '2026-01-02'), (103, 1, '2026-01-03'), (104, 2, '2026-01-04'), (105, 2, '2026-01-05');
INSERT INTO productos VALUES (1, 'Manzana', 'Alimentos', 2.00), (2, 'Laptop', 'Tecnología', 1000.00), (3, 'Leche', 'Alimentos', 1.50);
INSERT INTO detalles_pedido VALUES (1, 101, 1, 5), (2, 101, 2, 1), (3, 102, 3, 10), (4, 103, 1, 20), (5, 104, 2, 2);

--consulta 1 
SELECT 
    c.cliente_id,
    c.nombre,
    c.ciudad,
    -- Calculamos el gasto total (cantidad * precio) y si es NULL (sin compras), ponemos 0.0
    COALESCE(SUM(CAST(dp.cantidad AS DECIMAL(10,2)) * precio), 0.0) AS gasto_total,
    COUNT(DISTINCT p.pedido_id) AS total_compras
FROM clientes c
LEFT JOIN pedidos p ON c.cliente_id = p.cliente_id
LEFT JOIN detalles_pedido dp ON p.pedido_id = dp.pedido_id
LEFT JOIN productos p_prod ON dp.producto_id = p_prod.producto_id
GROUP BY c.cliente_id, c.nombre, c.ciudad;

--consulta 2 uso de case when
SELECT 
    c.cliente_id,
    c.nombre,
    c.ciudad,
    COALESCE(SUM(CAST(dp.cantidad AS DECIMAL(10,2)) * precio), 0.0) AS gasto_total,
    COUNT(DISTINCT p.pedido_id) AS total_compras,
    
    -- Gasto exclusivo en Alimentos
    COALESCE(SUM(CASE WHEN p_prod.categoria = 'Alimentos' THEN CAST(dp.cantidad AS DECIMAL(10,2)) * p_prod.precio ELSE 0 END), 0.0) AS gasto_alimentos,
    
    -- Gasto exclusivo en Tecnología
    COALESCE(SUM(CASE WHEN p_prod.categoria = 'Tecnología' THEN CAST(dp.cantidad AS DECIMAL(10,2)) * p_prod.precio ELSE 0 END), 0.0) AS gasto_tecnologia
FROM clientes c
LEFT JOIN pedidos p ON c.cliente_id = p.cliente_id
LEFT JOIN detalles_pedido dp ON p.pedido_id = dp.pedido_id
LEFT JOIN productos p_prod ON dp.producto_id = p_prod.producto_id
GROUP BY c.cliente_id, c.nombre, c.ciudad;

--consulta 3 segmentacion de activos 
SELECT 
    c.cliente_id,
    c.nombre,
    c.ciudad,
    COALESCE(SUM(CAST(dp.cantidad AS DECIMAL(10,2)) * p_prod.precio), 0.0) AS gasto_total,
    COUNT(DISTINCT p.pedido_id) AS total_compras,
    COALESCE(SUM(CASE WHEN p_prod.categoria = 'Alimentos' THEN CAST(dp.cantidad AS DECIMAL(10,2)) * p_prod.precio ELSE 0 END), 0.0) AS gasto_alimentos,
    COALESCE(SUM(CASE WHEN p_prod.categoria = 'Tecnología' THEN CAST(dp.cantidad AS DECIMAL(10,2)) * p_prod.precio ELSE 0 END), 0.0) AS gasto_tecnologia,
    -- Gasto promedio calculado de forma segura
    CASE 
        WHEN COUNT(DISTINCT p.pedido_id) > 0 
        THEN COALESCE(SUM(CAST(dp.cantidad AS DECIMAL(10,2)) * p_prod.precio), 0.0) / COUNT(DISTINCT p.pedido_id) 
        ELSE 0.0 
    END AS gasto_promedio
FROM clientes c
LEFT JOIN pedidos p ON c.cliente_id = p.cliente_id
LEFT JOIN detalles_pedido dp ON p.pedido_id = dp.pedido_id
LEFT JOIN productos p_prod ON dp.producto_id = p_prod.producto_id
GROUP BY c.cliente_id, c.nombre, c.ciudad
-- Filtro obligatorio utilizando HAVING sobre columnas agregadas
HAVING COUNT(DISTINCT p.pedido_id) >= 3 
   AND (COALESCE(SUM(CAST(dp.cantidad AS DECIMAL(10,2)) * p_prod.precio), 0.0) / NULLIF(COUNT(DISTINCT p.pedido_id), 0)) > 50.0;

   --consulta 4 ranking y resumen
   WITH resumen_clientes AS (
    SELECT 
        c.cliente_id,
        c.nombre,
        c.ciudad,
        COALESCE(SUM(CAST(dp.cantidad AS DECIMAL(10,2)) * p_prod.precio), 0.0) AS gasto_total,
        COUNT(DISTINCT p.pedido_id) AS total_compras,
        COALESCE(SUM(CASE WHEN p_prod.categoria = 'Alimentos' THEN CAST(dp.cantidad AS DECIMAL(10,2)) * p_prod.precio ELSE 0 END), 0.0) AS gasto_alimentos,
        COALESCE(SUM(CASE WHEN p_prod.categoria = 'Tecnología' THEN CAST(dp.cantidad AS DECIMAL(10,2)) * p_prod.precio ELSE 0 END), 0.0) AS gasto_tecnologia,
        CASE 
            WHEN COUNT(DISTINCT p.pedido_id) > 0 
            THEN COALESCE(SUM(CAST(dp.cantidad AS DECIMAL(10,2)) * p_prod.precio), 0.0) / COUNT(DISTINCT p.pedido_id) 
            ELSE 0.0 
        END AS gasto_promedio
    FROM clientes c
    LEFT JOIN pedidos p ON c.cliente_id = p.cliente_id
    LEFT JOIN detalles_pedido dp ON p.pedido_id = dp.pedido_id
    LEFT JOIN productos p_prod ON dp.producto_id = p_prod.producto_id
    GROUP BY c.cliente_id, c.nombre, c.ciudad
)
SELECT 
    cliente_id,
    nombre,
    ciudad,
    gasto_total,
    total_compras,
    gasto_alimentos,
    gasto_tecnologia,
    ROUND(gasto_promedio, 2) AS gasto_promedio,
    -- Función de ventana para rankear según el gasto total dentro de su propia ciudad
    DENSE_RANK() OVER (PARTITION BY ciudad ORDER BY gasto_total DESC) AS ranking_cliente_ciudad
FROM resumen_clientes;