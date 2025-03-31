USE EMPRESA;

SET GLOBAL log_bin_trust_function_creators = 1;
-- ------------------------------------------------------------------------------
-- FUNCION ALEATORIA ENTRE UN RANGO DE NUMERO
DELIMITER //
CREATE FUNCTION f_aleatorio (min INT, max INT) 
RETURNS int
BEGIN
	DECLARE vresultado INT;
	SELECT FLOOR((RAND() * (max-min+1))+min) INTO vresultado;
	RETURN vresultado;
END //
DELIMITER ;

SELECT f_aleatorio(1,10) AS RESULTADO;

-- ------------------------------------------------------------------------------
-- FUNCIONES PARA OBTENER CLIENTE, PRODUCTO, VENDEDOR DE FORMA ALEATORIA

-- Funcion para obtener un ciente  aleatorio
DELIMITER //
CREATE FUNCTION f_cliente_aleatorio() RETURNS varchar(11) 
BEGIN
	DECLARE vresultado VARCHAR(11);
	DECLARE vmax INT;
	DECLARE valeatorio INT;

	SELECT COUNT(*) INTO vmax FROM clientes; -- contar los clientes existentes
    -- un numero aleatorio entre 1 y la cantidad de clientes (1 - 16)
	SET valeatorio = f_aleatorio(1,vmax); 
    --  Reducir -1 para evitar errores de indice (0 - 15)
	SET valeatorio = valeatorio-1; 
    -- Seleccionamos uno en posicion de Limit(de 0 a 15 , 1 el mismo )
	SELECT DNI INTO vresultado FROM clientes LIMIT valeatorio,1;
	RETURN vresultado;
END //
DELIMITER ;

SELECT COUNT(*)  FROM clientes;
SELECT * FROM CLIENTES LIMIT 3; 
SELECT DNI  FROM clientes LIMIT 0,1; -- Primer cliente
SELECT DNI  FROM clientes LIMIT 1,1;  -- Segundo cliente
SELECT DNI  FROM clientes LIMIT 15,1; -- Ultimo cliente
SELECT DNI  FROM clientes LIMIT 16,1; -- No existe cliente en indice 16
SELECT f_cliente_aleatorio() AS CLIENTE;

-- Funcion para obtener un producto aleatorio
DELIMITER //
CREATE FUNCTION f_producto_aleatorio() RETURNS varchar(10)
BEGIN
DECLARE vresultado VARCHAR(10);
DECLARE vmax INT;
DECLARE valeatorio INT;
SELECT COUNT(*) INTO vmax FROM productos;
SET valeatorio = f_aleatorio(1,vmax);
SET valeatorio = valeatorio-1;
SELECT CODIGO INTO vresultado FROM productos LIMIT valeatorio,1;
RETURN vresultado;
END //
DELIMITER ;

SELECT f_producto_aleatorio() AS CLIENTE;

-- Funcion para obtener un vendedor aleatorio
DELIMITER //
CREATE FUNCTION f_vendedor_aleatorio() RETURNS varchar(5) CHARSET utf8mb4
BEGIN
DECLARE vresultado VARCHAR(5);
DECLARE vmax INT;
DECLARE valeatorio INT;
SELECT COUNT(*) INTO vmax FROM vendedores;
SET valeatorio = f_aleatorio(1,vmax);
SET valeatorio = valeatorio-1;
SELECT MATRICULA INTO vresultado FROM vendedores LIMIT valeatorio,1;
RETURN vresultado;
END //
DELIMITER ;

SELECT f_vendedor_aleatorio() AS CLIENTE;
-- ------------------------------------------------------------------------------
SELECT MAX(NUMERO) FROM facturas;
SELECT COUNT(*) FROM facturas;
SELECT NUMERO FROM FACTURAS ORDER BY NUMERO DESC LIMIT 88000;


-- Borrando y modificando tablas por error de PK
DROP TABLE facturas;
CREATE TABLE facturas(
NUMERO INT NOT NULL,
FECHA DATE,
DNI VARCHAR(11) NOT NULL,
MATRICULA VARCHAR(5) NOT NULL,
IMPUESTO FLOAT,
PRIMARY KEY (NUMERO),
FOREIGN KEY (DNI) REFERENCES clientes(DNI),
FOREIGN KEY (MATRICULA) REFERENCES vendedores(MATRICULA)
);

DROP TABLE items;
CREATE TABLE items(
NUMERO INT NOT NULL,
CODIGO VARCHAR(10) NOT NULL,
CANTIDAD INT,
PRECIO FLOAT,
PRIMARY KEY (NUMERO, CODIGO),
FOREIGN KEY (NUMERO) REFERENCES facturas(NUMERO),
FOREIGN KEY (CODIGO) REFERENCES productos(CODIGO)
);

-- VOLVIENDO A INSERTAR DATOS
INSERT INTO items
SELECT NUMERO, CODIGO_DEL_PRODUCTO AS CODIGO, CANTIDAD, PRECIO
FROM jugos_ventas.items_facturas;

INSERT INTO facturas
SELECT NUMERO, FECHA_VENTA AS FECHA, DNI, MATRICULA, IMPUESTO
FROM jugos_ventas.facturas;
-- ------------------------------------------------------------------------------

-- PROCEDIMIENTO ALMACENADOS PARA GENERAR VENTAS 
-- Simula la creación de una venta (FACTURA) con items aleatorios
DELIMITER //
CREATE PROCEDURE sp_venta(fecha DATE, maxitems INT, maxcantidad INT)
BEGIN
	DECLARE vcliente VARCHAR(11);
	DECLARE vproducto VARCHAR(10);
	DECLARE vvendedor VARCHAR(5);
	DECLARE vcantidad INT;
	DECLARE vprecio FLOAT;
	DECLARE vitens INT;
	DECLARE vnfactura INT;
	DECLARE vcontador INT DEFAULT 1;
	DECLARE vnumitems INT;
    -- Obtener el próximo número de factura (máximo actual + 1)
	SELECT MAX(NUMERO) + 1 INTO vnfactura FROM facturas;
	-- Asignar cliente y vendedor aleatorios usando funciones 
	SET vcliente = f_cliente_aleatorio();
	SET vvendedor = f_vendedor_aleatorio();
    
    -- Insertando la factura principal
	INSERT INTO facturas (NUMERO, FECHA, DNI, MATRICULA, IMPUESTO) 
	VALUES (vnfactura, fecha, vcliente, vvendedor, 0.16);
    -- Cuantos items tendra la factura (numero aletorio desde 1 hasta el maximo de items)
	SET vitens = f_aleatorio(1,  maxitems);
    
        -- Bucle para agregar items a la factura
		WHILE vcontador <= vitens DO
			SET vproducto =  f_producto_aleatorio();
	        -- Verificar si el producto ya está en la factura
			SELECT COUNT(*) INTO vnumitems 
			FROM items
			WHERE CODIGO = vproducto AND NUMERO = vnfactura;
		        -- Si el producto no está en la factura, agregarlo
				IF vnumitems = 0 THEN
				  SET vcantidad = f_aleatorio(1, maxcantidad);
				  -- Obtengo precio del producto
				  SELECT PRECIO INTO vprecio FROM productos 
				  WHERE CODIGO = vproducto;
				  
				  INSERT INTO items(NUMERO, CODIGO, CANTIDAD, PRECIO) 
				  VALUES(vnfactura, vproducto, vcantidad, vprecio);
				END IF;
			SET vcontador = vcontador+1;
            
		END WHILE;
END //

-- Probando el procedimiento de generar ventas
SET SQL_SAFE_UPDATES = 0;
CALL sp_venta('2023-11-15', 10, 5); -- Ejemplo de llamada
SET SQL_SAFE_UPDATES = 1;

SELECT  MAX(NUMERO)FROM FACTURAS;
SELECT * FROM FACTURAS  ORDER BY NUMERO DESC LIMIT 3;


-- ------------------------------------------------------------------------------
-- TRIGGERS 
-- Tabla de facturacion
CREATE TABLE facturacion(
FECHA DATE NULL,
VENTA_TOTAL FLOAT
);

-- Procedimiento general para insertar nuevos totales de facturacion
DELIMITER // 

CREATE PROCEDURE SP_FACTURACION()
BEGIN 
	DELETE FROM facturacion;
	INSERT INTO facturacion
	SELECT A.FECHA, SUM(B.CANTIDAD * B.PRECIO) AS VENTA_TOTAL
	FROM facturas A
	INNER JOIN
	items B
	ON A.NUMERO = B.NUMERO
	GROUP BY A.FECHA;
END //
DELIMITER ;

-- Trigger que se dispara despues de insertar
DELIMITER //
CREATE TRIGGER TG_FACTURACION_INSERT 
AFTER INSERT ON items
FOR EACH ROW BEGIN
 CALL SP_FACTURACION();
END //

-- Trigger que se dispara despues de eliminar
DELIMITER //
CREATE TRIGGER TG_FACTURACION_DELETE
AFTER DELETE ON items
FOR EACH ROW BEGIN
	 CALL SP_FACTURACION();
END //

-- Trigger que se dispara despues de actualizar
DELIMITER //
CREATE TRIGGER TG_FACTURACION_UPDATE
AFTER UPDATE ON items
FOR EACH ROW BEGIN
	 CALL SP_FACTURACION();
END //

-- Probando el trigger
SET SQL_SAFE_UPDATES = 0;

call  sp_venta('20210622', 15, 100);
SELECT * FROM facturacion where fecha = '20210622';
