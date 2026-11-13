--creacion de tabla pedidos
CREATE TABLE pedidos (
    pedido_id INT,
    cliente_id INT,
    fecha DATE,
    importe DECIMAL(10,2),
    categoria VARCHAR(50)
);

-- Insertamos datos de ejemplo para las pruebas
INSERT INTO pedidos VALUES 
(1, 101, '2026-01-01', 150.0, 'Electrónica'),
(2, 102, '2026-01-02', 45.5, 'Hogar'),
(3, 101, '2026-01-03', 300.0, 'Electrónica'),
(4, 103, '2026-01-03', 1200.0, 'Electrónica'),
(5, 102, '2026-01-04', 500.0, 'Hogar'),
(6, 101, '2026-01-05', 50.0, 'Hogar'),
(7, 104, '2026-01-06', 80.0, 'Ropa'),
(8, 103, '2026-01-06', 250.0, 'Ropa');

--ejercisio 1 - promedio historico 
SELECT 
    pedido_id,
    cliente_id,
    fecha,
    importe,
    categoria,
    CAST(AVG(importe) OVER (PARTITION BY cliente_id) AS DECIMAL(10,2)) AS promedio_gasto_cliente
FROM pedidos;

--consulta 2 - ventas acumuladas 
SELECT 
    fecha,
    importe,
    SUM(importe) OVER (ORDER BY fecha, pedido_id) AS ventas_acumuladas
FROM pedidos;
--consulta 3 - porcentaje de contribucion por categoria
SELECT 
    pedido_id,
    categoria,
    importe,
    SUM(importe) OVER (PARTITION BY categoria) AS total_categoria,
    CAST((importe * 100.0 / SUM(importe) OVER (PARTITION BY categoria)) AS DECIMAL(5,2)) AS porcentaje_contribucion_categoria
FROM pedidos;


