/*
-- ----------------------------------------------------------------------------
RIPS Electronicos V2

Puntos importantes:
1. Definir el Sexo (Masculino/femenino/ambos) en la tabla de diagnósticos
2. Definir el Sexo (Masculino/femenino/ambos) en la tabla de servicios
3. Configurar el campo R2SECCION en la tabla SER IMPRESCINDIBLE!!!!!

-- ----------------------------------------------------------------------------
*/
INSERT INTO USVGS(IDVARIABLE,DESCRIPCION,TP_VARIABLE,DATO)
SELECT 'RIPSV2','RIPS Electrónicos','Alfanumerica','NO';
go

-- AFI Afiliados
ALTER TABLE AFI ALTER COLUMN TIPOAFILIADO VARCHAR(10) null;
go
/*
ALTER TABLE AFI ADD IDPAISORI VARCHAR(3) null;
go
ALTER TABLE AFI ADD IDPAISRES VARCHAR(3) null;
go
*/

-- HTAD Tipo admisión
ALTER TABLE HTAD ADD R2SECCION TINYINT null; -- validar con RIPSESEC
go

-- CIT
ALTER TABLE CIT ALTER COLUMN TIPOCOPAGO VARCHAR(20);
GO
ALTER TABLE CIT ADD N_FACTURACOPAGO varchar(16);
GO

-- AUT
ALTER TABLE AUT ALTER COLUMN TIPOCOPAGO VARCHAR(20);
GO
ALTER TABLE AUT ADD N_FACTURACOPAGO varchar(16);
GO

-- SER Tabla de servicios (CRUD)
ALTER TABLE SER ADD R2SECCION TINYINT null;-- validar con R2SEC
go
ALTER TABLE SER ADD R2CODSERVICIO VARCHAR(10) NULL; --código servicio quirúrgicos
go
ALTER TABLE SER ADD R2TIPOSERVICIO VARCHAR(2) NULL; 
go
ALTER TABLE SER ADD R2OTROSSER VARCHAR(2) NULL; -- Códigos otros servicios
go
ALTER TABLE SER ADD R2TIPOMEDPOS VARCHAR(2) NULL; 
go
-- AFU Areas funcionales (CRUD)
ALTER TABLE AFU ADD R2SECCION TINYINT null;
go
ALTER TABLE AFU ADD R2CODSERVICIO VARCHAR(10) NULL; -- Código Servicios Internación
go
ALTER TABLE AFU ADD R2CODGRUPOSER VARCHAR(10) NULL; -- Código grupo de servicios
go
ALTER TABLE AFU ADD R2AMBITO VARCHAR(2) NULL; -- Código Ambito
go
ALTER TABLE AFU ADD R2MODATENCION VARCHAR(2) NULL; -- Código Ambito
go

-- HCA Historias clínicas (OJO se activa si variable RIPSV2 = SI)
ALTER TABLE HCA ADD R2CAUSAEXT VARCHAR(2) NULL; -- Causa Externa
go

-- HADM Admisiones (CRUD)
ALTER TABLE HADM ADD R2DESTINO VARCHAR(2) NULL;
GO
ALTER TABLE HADM ADD FECHAMUERTE DATETIME NULL;
GO
ALTER TABLE HADM ADD EDADGEST SMALLINT NULL;
GO
ALTER TABLE HADM ADD PESONACER SMALLINT NULL;
GO

-- HPRE
ALTER TABLE HPRE ADD TIPOCOPAGO VARCHAR(20);
GO

-- HPRED
ALTER TABLE HPRED ADD CODMIPRES VARCHAR(20) null;
go
ALTER TABLE HPRED ADD N_FACTURACOPAGO VARCHAR(16) null;
go

-- MES (CRUD)
ALTER TABLE MES ADD R2CODSERVICIO VARCHAR(10) NULL; -- Código servicios Consulta Externa
GO

-- *************** OJO cambios tablas DOXA *************************************
-- Artículos Medicamentos  (CRUD)

ALTER TABLE IART ADD CODIUM VARCHAR(20) NULL; -- TablaReferencia_IUM__1.csv
go
-- ALTER TABLE IART ADD CODCUM VARCHAR(20) NULL;
go
ALTER TABLE IART ADD CODINVIMA VARCHAR(20) NULL;
go
ALTER TABLE IART ADD CODUPR VARCHAR(20) NULL -- TablaReferencia_UPR__1.csv
go
ALTER TABLE IART ADD CODR2CCN VARCHAR(5) NULL -- TablaReferencia_UPR__1.csv
go
ALTER TABLE IART ADD CODR2UNI VARCHAR(5) NULL -- TablaReferencia_UPR__1.csv
go
ALTER TABLE IART ADD CODR2FFA VARCHAR(10) NULL -- TablaReferencia_UPR__1.csv
go
-- 17.JUN.2024 FDIAZP ES
ALTER TABLE IGEN ADD CODDCI VARCHAR(20) NULL; -- TablaReferencia_DCI__1.csv
GO
-- *****************************************************************************

-- ALTER TABLE PAI ADD CODPAISISO2 VARCHAR(3) NULL;
-- go
-- Ya existe en PAI el campo ISOALFA3
-- ALTER TABLE PAI ADD CODPAISISO3 VARCHAR(3) NULL;

drop view IGEN
go
create view IGEN
as
	select
		IDGENERICO=IDGENERICO collate database_default,
		DESCRIPCION=DESCRIPCION collate database_default,
		IDCLASE=cast(IDCLASE as varchar(2)) collate database_default,
		IDSUBCLASE=cast(IDSUBCLASE as varchar(4)) collate database_default,
		IDGRUPO=cast(IDGRUPO as varchar(4)) collate database_default,
		IDPRINACTIVO=cast(IDATC as varchar(4)) collate database_default,
		IDFORFARM=IDFORFARM collate database_default,
		IDCONCENTRA=IDCONCENTRA collate database_default,
		IDUNIDAD=IDUNIDAD collate database_default,
		IDTGENERICO=IDTGENERICO collate database_default,
		CODDCI=CODDCI collate database_default
	from DxContable.dbo.IGEN with(nolock)
go


-- rips FACTURAS
create table FTRR2(
	CNSFCT	varchar	(40) not null,
	R2ENVIO VARCHAR(MAX) NULL,
	R2RESPUESTA VARCHAR(MAX) NULL,
	ESTADO SMALLINT -- 0 Pendiente 1: procesado 2: Enviado 
    CONSTRAINT PK_FTRR2 PRIMARY KEY CLUSTERED (CNSFCT),
	CONSTRAINT FK_FTRR2_FTR FOREIGN KEY (CNSFCT) REFERENCES FTR (CNSFCT)
);
go


-- RIPS Secciones
create table R2SEC(
	R2SECCION TINYINT not null,
	DESCRIPCION varchar(100) null,
    CONSTRAINT PK_R2SEC PRIMARY KEY CLUSTERED (R2SECCION)
);

insert into R2SEC(R2SECCION,DESCRIPCION)
select 1,'consultas'
union all
select 2,'medicamentos'
union all
select 3,'procedimientos'
union all
select 4,'urgencias'
union all
select 5,'hospitalizaciones'
union all
select 6,'recienNacidos'
union all
select 7,'otrosServicios'
go

/*
-- ----------------------------------------------------------------------------
Tablas oficiales de códigos de los diferentes campos de RIPS electrónicos
-- ----------------------------------------------------------------------------
*/
-- drop table R2SISPRO

CREATE TABLE R2SISPRO(
	TABLA VARCHAR(50) NOT NULL,
	CODIGO VARCHAR(20) NOT NULL,
	NOMBRE VARCHAR(500) NULL,
	DESCRIPCION VARCHAR(500) NULL,
	HABILITADO VARCHAR(20) NOT NULL,
	APLICACION VARCHAR(20) NOT NULL,
	ISSTANDARDGEL VARCHAR(20) NOT NULL,
	ISSTANDARDMSPS VARCHAR(20) NOT NULL,
	EXTRA_I_CONSULTAS VARCHAR(20) NOT NULL,
	EXTRA_II_PROCEDIMIENTOS VARCHAR(20) NOT NULL,
	EXTRA_III_URGENCIAS VARCHAR(20) NOT NULL,
	EXTRA_IV_HOSPITALIZACION VARCHAR(20) NOT NULL,
	EXTRA_V_RNACIDOS VARCHAR(20) NOT NULL,
	EXTRA_VI VARCHAR(20) NOT NULL,
	EXTRA_VII VARCHAR(20) NOT NULL,
	EXTRA_VIII VARCHAR(20) NOT NULL,
	EXTRA_IX VARCHAR(20) NOT NULL,
	EXTRA_X VARCHAR(20) NOT NULL,
	VALORREGISTRO VARCHAR(20) NOT NULL,
	USUARIORESPONSABLE VARCHAR(20) NOT NULL,
	FECHA_ACTUALIZACION VARCHAR(20) NOT NULL,
	ISPUBLICPRIVATE VARCHAR(20) NOT NULL
    CONSTRAINT PK_R2SISPRO PRIMARY KEY CLUSTERED (TABLA,CODIGO)
)
go
/*
-- Importar las tablas de validación de SISPRO para RIPS electrónicos
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_UPR__1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_CUPSRips__1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSAmbitoRealizaProcedimiento_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSCausaExternaVersion2_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSDestinoUsrSalidaObservacion__1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSEstadoSalida_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSFinalidadConsultaVersion2_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSFinalidadProcedimiento_1-2.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSFormaActoQuirurgico_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSPersonalAtiende__1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSTipoDiagnosticoPrincipalVersion2_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSTipoServicio__1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSTipoUsuarioVersion2_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSVialngresolPS_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_TipoldPISIS_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_TipoPagoCompartido_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_TipoPagoModerador__1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_IPSCodHabilitacion__2-2.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_IPSCodHabilitacion__1-2.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_ModalidadAtencion__1-2.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_VialngresoUsuario__1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_GrupoServicios_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_Servicios_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_CIE10__1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_RIPSFinalidadProcedimiento_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_CondicionyDestinoUsuarioEgreso__1-2.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_IPSnoREPS_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_Sexo__1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_TipoMedicamentoPOSVersion21.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_IUM_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_CatalogoCUMs__2.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_CatalogoCUMs__1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_DCl1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_UMM_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_FFM_1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
BULK INSERT R2SISPRO FROM 'c:\TMP\TablaReferencia_TipoOtrosServicios__1.csv' WITH (FIRSTROW = 2,FIELDTERMINATOR = ',',ROWTERMINATOR = '\n');
go
*/