
/* SQL Server DDL - Cliente.Estado incluido */
IF DB_ID(N'CourierFlash_III2025') IS NULL BEGIN CREATE DATABASE [CourierFlash_III2025]; END
GO
USE [CourierFlash_III2025];
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;
GO
IF OBJECT_ID('dbo.Pago','U') IS NOT NULL DROP TABLE dbo.Pago;
IF OBJECT_ID('dbo.Movimiento','U') IS NOT NULL DROP TABLE dbo.Movimiento;
IF OBJECT_ID('dbo.Paquete','U') IS NOT NULL DROP TABLE dbo.Paquete;
IF OBJECT_ID('dbo.Envio','U') IS NOT NULL DROP TABLE dbo.Envio;
IF OBJECT_ID('dbo.Sucursal_Empleado','U') IS NOT NULL DROP TABLE dbo.Sucursal_Empleado;
IF OBJECT_ID('dbo.Empleado','U') IS NOT NULL DROP TABLE dbo.Empleado;
IF OBJECT_ID('dbo.Vehiculo','U') IS NOT NULL DROP TABLE dbo.Vehiculo;
IF OBJECT_ID('dbo.Cliente','U') IS NOT NULL DROP TABLE dbo.Cliente;
IF OBJECT_ID('dbo.Sucursal','U') IS NOT NULL DROP TABLE dbo.Sucursal;
GO

CREATE TABLE dbo.Sucursal (
  codigo_interno INT PRIMARY KEY,
  Nombre NVARCHAR(80) NOT NULL,
  Provincia NVARCHAR(50) NOT NULL,
  Ciudad NVARCHAR(50) NOT NULL
);
GO

CREATE TABLE dbo.Cliente (
  Identificacion INT PRIMARY KEY,
  Nombre NVARCHAR(60) NOT NULL,
  Apellidos NVARCHAR(80) NOT NULL,
  Telefono NVARCHAR(20) NOT NULL,
  Email NVARCHAR(120) NOT NULL,
  Provincia NVARCHAR(50) NOT NULL,
  Canton NVARCHAR(50) NOT NULL,
  Distrito NVARCHAR(50) NOT NULL,
  Barrio NVARCHAR(80) NOT NULL,
  Estado NVARCHAR(10) NOT NULL CONSTRAINT DF_Cliente_Estado DEFAULT('Activo')
    CONSTRAINT CHK_Cliente_Estado CHECK (Estado IN (N'Activo', N'Inactivo'))
);
GO

CREATE TABLE dbo.Vehiculo (
  Placa INT PRIMARY KEY,
  Modelo NVARCHAR(40) NOT NULL,
  Capacidad_kg DECIMAL(10,2) NOT NULL,
  Estado NVARCHAR(15) NOT NULL
    CONSTRAINT CHK_Vehiculo_Estado CHECK (Estado IN (N'Disponible', N'En ruta', N'Mantenimiento'))
);
GO

CREATE TABLE dbo.Empleado (
  Codigo_Empleado INT PRIMARY KEY,
  Nombre NVARCHAR(60) NOT NULL,
  Apellidos NVARCHAR(80) NOT NULL,
  Puesto NVARCHAR(25) NOT NULL
    CONSTRAINT CHK_Empleado_Puesto CHECK (Puesto IN (N'Conductor', N'Operador de Bodega', N'Coordinador')),
  Fecha_contratacion DATE NOT NULL
);
GO

CREATE TABLE dbo.Envio (
  Envio_id INT IDENTITY(1,1) PRIMARY KEY,
  sucursal_origen INT NOT NULL REFERENCES dbo.Sucursal(codigo_interno),
  sucursal_destino INT NOT NULL REFERENCES dbo.Sucursal(codigo_interno),
  remitente_identificacion INT NOT NULL REFERENCES dbo.Cliente(Identificacion),
  destinatario_identificacion INT NOT NULL REFERENCES dbo.Cliente(Identificacion),
  fecha_creacion DATETIME2(0) NOT NULL,
  tarifa_pactada DECIMAL(12,2) NOT NULL,
  medio_pago_previsto NVARCHAR(20) NOT NULL
    CONSTRAINT CHK_Envio_MPP CHECK (medio_pago_previsto IN (N'Prepago', N'Contraentrega')),
  prioridad NVARCHAR(10) NOT NULL
    CONSTRAINT CHK_Envio_Prioridad CHECK (prioridad IN (N'Estándar', N'Exprés')),
  estado NVARCHAR(15) NOT NULL
    CONSTRAINT CHK_Envio_Estado CHECK (estado IN (N'Creado', N'En tránsito', N'En reparto', N'Entregado', N'Incidencia', N'Cancelado')),
  vehiculo_placa INT NULL REFERENCES dbo.Vehiculo(Placa),
  conductor_codigo INT NULL REFERENCES dbo.Empleado(Codigo_Empleado)
);
GO

CREATE TABLE dbo.Paquete (
  Etiqueta INT PRIMARY KEY,
  Envio_id INT NOT NULL REFERENCES dbo.Envio(Envio_id),
  peso_kg DECIMAL(10,2) NOT NULL,
  alto_cm DECIMAL(10,2) NOT NULL,
  ancho_cm DECIMAL(10,2) NOT NULL,
  largo_cm DECIMAL(10,2) NOT NULL,
  contenido_declarado NVARCHAR(120) NOT NULL,
  valor_asegurado DECIMAL(12,2) NULL
);
GO

CREATE TABLE dbo.Movimiento (
  Movimiento_id INT IDENTITY(1,1) PRIMARY KEY,
  envio_id INT NOT NULL REFERENCES dbo.Envio(Envio_id),
  fecha_hora DATETIME2(0) NOT NULL,
  tipo_evento NVARCHAR(25) NOT NULL
    CONSTRAINT CHK_Mov_Tipo CHECK (tipo_evento IN (N'Recibido en bodega', N'Transferido a ruta', N'En tránsito', N'En reparto', N'Entregado', N'Incidencia')),
  sucursal_codigo INT NOT NULL REFERENCES dbo.Sucursal(codigo_interno),
  observacion NVARCHAR(200) NULL,
  conductor_codigo INT NULL REFERENCES dbo.Empleado(Codigo_Empleado),
  vehiculo_placa INT NULL REFERENCES dbo.Vehiculo(Placa)
);
GO

CREATE TABLE dbo.Pago (
  Pago_id INT IDENTITY(1,1) PRIMARY KEY,
  envio_id INT NOT NULL REFERENCES dbo.Envio(Envio_id),
  monto DECIMAL(12,2) NOT NULL,
  fecha DATETIME2(0) NOT NULL,
  metodo_pago NVARCHAR(20) NOT NULL
    CONSTRAINT CHK_Pago_Metodo CHECK (metodo_pago IN (N'Tarjeta', N'Transferencia', N'Efectivo')),
  estado NVARCHAR(12) NOT NULL
    CONSTRAINT CHK_Pago_Estado CHECK (estado IN (N'Registrado', N'Anulado'))
);
GO

CREATE TABLE dbo.Sucursal_Empleado (
  codigo_empleado INT NOT NULL REFERENCES dbo.Empleado(Codigo_Empleado),
  sucursal_codigo INT NOT NULL REFERENCES dbo.Sucursal(codigo_interno),
  fecha_inicio DATE NOT NULL,
  fecha_fin DATE NULL,
  puesto_en_periodo NVARCHAR(30) NULL,
  CONSTRAINT PK_Sucursal_Empleado PRIMARY KEY (codigo_empleado, sucursal_codigo, fecha_inicio)
);
GO

--Eliminación controlada

DELETE FROM dbo.Pago;
DELETE FROM dbo.Movimiento;
DELETE FROM dbo.Paquete;
DELETE FROM dbo.Envio;
DELETE FROM dbo.Sucursal_Empleado;
DELETE FROM dbo.Empleado;
DELETE FROM dbo.Vehiculo;
DELETE FROM dbo.Cliente;
DELETE FROM dbo.Sucursal;
GO

-- 1) Insertar datos de forma controlada

--Insertar datos Sucursal
INSERT INTO dbo.Sucursal (codigo_interno, Nombre, Provincia, Ciudad)
VALUES (101, 'Sucursal Central', 'San José', 'San José');

INSERT INTO dbo.Sucursal (codigo_interno, Nombre, Provincia, Ciudad)
VALUES (102, 'Sucursal Heredia', 'Heredia', 'Heredia');

INSERT INTO dbo.Sucursal (codigo_interno, Nombre, Provincia, Ciudad)
VALUES (103, 'Sucursal Alajuela', 'Alajuela', 'Alajuela');
GO

--Insertar datos Cliente
INSERT INTO dbo.Cliente (Identificacion, Nombre, Apellidos, Telefono, Email, Provincia, Canton, Distrito, Barrio, Estado)
VALUES (1010, 'Carlos', 'Mora', '88887777', 'carlos.mora@example.com', 'San José', 'San José', 'Pavas', 'Rohrmoser', 'Activo' );

INSERT INTO dbo.Cliente (Identificacion, Nombre, Apellidos, Telefono, Email, Provincia, Canton, Distrito, Barrio, Estado)
VALUES (1020, 'María', 'Gómez', '88886666', 'maria.gomez@example.com', 'Heredia', 'Heredia', 'San Francisco', 'Ulloa', 'Activo' );

INSERT INTO dbo.Cliente (Identificacion, Nombre, Apellidos, Telefono, Email, Provincia, Canton, Distrito, Barrio, Estado)
VALUES (1030, 'Pedro', 'Rojas', '88885555', 'pedro.rojas@example.com', 'Alajuela', 'Alajuela', 'San Antonio', 'Centro', 'Activo' );
GO

--Insertar datos Vehiculo
INSERT INTO dbo.Vehiculo (Placa, Modelo, Capacidad_kg, Estado)
VALUES (301, 'Toyota Hiace', 1200, 'Disponible');

INSERT INTO dbo.Vehiculo (Placa, Modelo, Capacidad_kg, Estado)
VALUES (302, 'Nissan NV350', 1000, 'En ruta');

INSERT INTO dbo.Vehiculo (Placa, Modelo, Capacidad_kg, Estado)
VALUES (303, 'Hyundai H1', 900, 'Mantenimiento');
GO

--Insertar datos Empleado
INSERT INTO dbo.Empleado (Codigo_Empleado, Nombre, Apellidos, Puesto, Fecha_contratacion)
VALUES (501, 'José', 'Ramírez', 'Conductor', '2020-05-01');

INSERT INTO dbo.Empleado (Codigo_Empleado, Nombre, Apellidos, Puesto, Fecha_contratacion)
VALUES (502, 'Ana', 'Campos', 'Operador de Bodega', '2021-03-15');

INSERT INTO dbo.Empleado (Codigo_Empleado, Nombre, Apellidos, Puesto, Fecha_contratacion)
VALUES (503, 'Luis', 'Fernández', 'Coordinador', '2019-08-20');
GO

--Insertar datos Sucursal_Empleado
INSERT INTO dbo.Sucursal_Empleado (codigo_empleado, sucursal_codigo, fecha_inicio, fecha_fin, puesto_en_periodo)
VALUES (501, 101, '2022-01-01', NULL, 'Conductor');

INSERT INTO dbo.Sucursal_Empleado (codigo_empleado, sucursal_codigo, fecha_inicio, fecha_fin, puesto_en_periodo)
VALUES (502, 102, '2021-06-01', NULL, 'Operador de Bodega');

INSERT INTO dbo.Sucursal_Empleado (codigo_empleado, sucursal_codigo, fecha_inicio, fecha_fin, puesto_en_periodo)
VALUES (503, 103, '2020-01-01', NULL, 'Coordinador');
GO

--Insertar datos Envio (REVISAR PROBLEMA CON IDENTITY)
INSERT INTO dbo.Envio (sucursal_origen, sucursal_destino, remitente_identificacion, destinatario_identificacion, fecha_creacion, tarifa_pactada, medio_pago_previsto, prioridad, estado, vehiculo_placa, conductor_codigo)
VALUES (101, 102, 1010, 1020, '2025-10-05 09:00:00', 5000, 'Prepago', 'Estándar', 'Creado', 301, 501 );

INSERT INTO dbo.Envio (sucursal_origen, sucursal_destino, remitente_identificacion, destinatario_identificacion, fecha_creacion, tarifa_pactada, medio_pago_previsto, prioridad, estado, vehiculo_placa, conductor_codigo)
VALUES (101, 103, 1020, 1030, '2025-10-10 14:30:00', 8500, 'Contraentrega', 'Exprés', 'En tránsito', 302, 501 );

INSERT INTO dbo.Envio (sucursal_origen, sucursal_destino, remitente_identificacion, destinatario_identificacion, fecha_creacion, tarifa_pactada, medio_pago_previsto, prioridad, estado, vehiculo_placa, conductor_codigo)
VALUES (102, 101, 1030, 1010, '2025-09-25 16:45:00', 4200, 'Prepago', 'Estándar', 'Entregado', 301, 501 );
GO

--Insertar datos Paquete
INSERT INTO dbo.Paquete (Etiqueta, Envio_id, peso_kg, alto_cm, ancho_cm, largo_cm, contenido_declarado, valor_asegurado)
VALUES (9001, 1, 2.5, 20, 15, 10, 'Documentos', 0);

INSERT INTO dbo.Paquete (Etiqueta, Envio_id, peso_kg, alto_cm, ancho_cm, largo_cm, contenido_declarado, valor_asegurado)
VALUES (9002, 2, 10, 50, 40, 30, 'Electrónicos', 2000);

INSERT INTO dbo.Paquete (Etiqueta, Envio_id, peso_kg, alto_cm, ancho_cm, largo_cm, contenido_declarado, valor_asegurado)
VALUES (9003, 3, 5, 25, 20, 15, 'Ropa', 500);
GO

--Insertar datos Movimiento
INSERT INTO dbo.Movimiento (envio_id, fecha_hora, tipo_evento, sucursal_codigo, observacion, conductor_codigo, vehiculo_placa)
VALUES (1, '2025-01-05 10:00', 'Recibido en bodega', 101, 'Ingreso inicial', 501, 301);

INSERT INTO dbo.Movimiento (envio_id, fecha_hora, tipo_evento, sucursal_codigo, observacion, conductor_codigo, vehiculo_placa)
VALUES (1, '2025-01-05 13:00', 'Transferido a ruta', 101, 'Salida a entrega', 501, 301);

INSERT INTO dbo.Movimiento (envio_id, fecha_hora, tipo_evento, sucursal_codigo, observacion, conductor_codigo, vehiculo_placa)
VALUES (2, '2025-01-10 15:00', 'En tránsito', 102, 'En viaje', 501, 302);

INSERT INTO dbo.Movimiento (envio_id, fecha_hora, tipo_evento, sucursal_codigo, observacion, conductor_codigo, vehiculo_placa)
VALUES (3, '2025-01-12 18:00', 'Entregado', 101, 'Cliente recibió el paquete', 501, 301);
GO

--Insertar datos Pago
INSERT INTO dbo.Pago (envio_id, monto, fecha, metodo_pago, estado)
VALUES (1, 5000, '2025-01-05 09:15:00', 'Tarjeta', 'Registrado');

INSERT INTO dbo.Pago (envio_id, monto, fecha, metodo_pago, estado)
VALUES (2, 8500, '2025-10-10 14:40:00', 'Efectivo', 'Registrado');

INSERT INTO dbo.Pago (envio_id, monto, fecha, metodo_pago, estado)
VALUES (3, 4200, '2025-10-12 17:00:00', 'Transferencia', 'Registrado');
GO

-- 2) Reporte de envíos por sucursal
SELECT
	Sucursal.Nombre AS [Sucursal de origen],
	COUNT(DISTINCT Envio.Envio_id) AS [Envíos (último mes)],
	SUM(Pago.monto) AS [Ingreso total (CRC)]

FROM dbo.Envio
INNER JOIN dbo.Sucursal
	ON Envio.sucursal_origen = Sucursal.codigo_interno
INNER JOIN dbo.Pago
	ON Envio.Envio_id = Pago.envio_id
WHERE Envio.fecha_creacion BETWEEN '2025-09-01' AND '2025-10-31'
GROUP BY Sucursal.Nombre;
GO

-- 3) Indicadores de envío
SELECT 
	Envio.Envio_id AS [EnvíoID],
	COUNT(Paquete.Envio_id) AS [Piezas],
	SUM(Paquete.peso_kg) AS [Peso total (kg)],
	Envio.tarifa_pactada AS [Ingreso proyectado (CRC)]

FROM dbo.Envio
INNER JOIN dbo.Paquete
	ON Envio.Envio_id = Paquete.Envio_id
WHERE Envio.fecha_creacion between '2025-10-01' AND '2025-10-31'
GROUP BY Envio.Envio_id, Envio.tarifa_pactada;
GO

-- 4) Clientes con pagos recientes
SELECT 
	Cliente.Identificacion AS [Documento],
	Cliente.Nombre + ' ' + Cliente.Apellidos AS [Nombre completo],
	Pago.monto AS [Monton pagado],
	Pago.metodo_pago AS [Método de pago],
	Pago.fecha AS [Fecha de pago]

FROM dbo.Cliente
INNER JOIN dbo.Envio
	ON Cliente.Identificacion = remitente_identificacion
INNER JOIN dbo.Pago
	ON Envio.Envio_id = Pago.envio_id
WHERE Pago.fecha BETWEEN '2025-10-01' AND '2025-10-31'
GO

-- 5) Ingresos por ruta
SELECT 
	Envio.sucursal_origen + '-' + Envio.sucursal_destino AS [Ruta (origen-destino)],
	COUNT(Envio.Envio_id) AS [Veces enviada],
	SUM(Pago.monto) AS [Ingreso total (CRC)]


