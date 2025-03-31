# Sistema de Ventas y Facturación 🧾

## Descripción 📂

Este proyecto simula un sistema de ventas y facturación para una empresa, donde se crean ventas (facturas) con productos aleatorios, y se mantiene un registro de los totales de facturación por fecha. Utiliza procedimientos almacenados y triggers para generar las ventas, actualizar la facturación y mantener la integridad de los datos.

## Características

1. **Generación de Ventas (Facturas) Aleatorias**:  
   - Se genera una venta (factura) con un número único.
   - La factura contiene un cliente y un vendedor aleatorios.
   - Se asignan entre 1 y el número máximo de ítems aleatorios por factura.
   - Cada ítem se asocia a un producto aleatorio con su cantidad y precio.

2. **Procedimientos Almacenados**:  
   - `sp_venta`: Crea una factura con productos aleatorios y los inserta en la base de datos.
   - `SP_FACTURACION`: Calcula el total de ventas por fecha y lo inserta en la tabla `facturacion`.

3. **Triggers**:  
   - `TG_FACTURACION_INSERT`: Se activa después de insertar un ítem en la tabla `items`, recalculando el total de la facturación.
   - `TG_FACTURACION_DELETE`: Se activa después de eliminar un ítem, actualizando el total de la facturación.
   - `TG_FACTURACION_UPDATE`: Se activa después de actualizar un ítem, recalculando la facturación.

4. **Tabla de Facturación**:  
   - La tabla `facturacion` contiene los totales de ventas por fecha.
   - Se actualiza automáticamente cada vez que se inserta, elimina o actualiza un ítem.

## Uso ⚙️

1. **Generar Ventas**:  
   - Se puede llamar al procedimiento `sp_venta` pasando la fecha de la venta, el número máximo de ítems por venta y la cantidad máxima de cada producto en la venta.
   - Ejemplo de llamada:
     ```
     CALL sp_venta('2023-11-15', 10, 5);
     ```

2. **Ver Facturación**:  
   - Se puede consultar el total de facturación por fecha con la siguiente consulta:
     ```
     SELECT * FROM facturacion WHERE fecha = '2023-11-15';
     ```

3. **Triggers Automáticos**:  
   - Los triggers `TG_FACTURACION_INSERT`, `TG_FACTURACION_DELETE` y `TG_FACTURACION_UPDATE` mantienen la tabla de facturación actualizada automáticamente cuando se inserta, elimina o actualiza un ítem en la tabla `items`.

## Requisitos

- **Base de Datos MySQL**: Este proyecto está diseñado para funcionar con MySQL y usa procedimientos almacenados y triggers.

  
