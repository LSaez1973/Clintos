drop table DBO.AFIALEFR
drop TABLE DBO.AFIALE 
drop table DBO.MDCI
drop table DBO.ALE
drop table DBO.ALET
go

-- ===============================================================================
-- Diccionario: C:\Dev11\ClintosDx\Agilis.dct  Fecha:23.JUN.2021 Hora: 6:47PM
-- ===============================================================================

         CREATE TABLE DBO.MDCI (
            IDMDCI                SMALLINT IDENTITY NOT NULL , 
            CODIGO                VARCHAR(20) NOT NULL, 
            DESCRIPCION           VARCHAR(255) NOT NULL, 
            IDMDCI_PADRE          SMALLINT   
         )
        ALTER TABLE MDCI
        ADD CONSTRAINT MDCIIDMDCI
        PRIMARY KEY CLUSTERED (IDMDCI)
        
         CREATE TABLE DBO.AFIALE (
            IDAFIALE              SMALLINT IDENTITY   NOT NULL , 
            IDAFILIADO            VARCHAR(20) NOT NULL, 
            IDALET                SMALLINT NOT NULL  , 
            IDALE                 INT        , 
            DETALLES              VARCHAR(4000) , 
            IDMDCI                SMALLINT   , 
            DXCONDFAM_CIE10       VARCHAR(10) , 
            DXCONDFAM_CIE11       INT        , 
            PARENTANTFAM          VARCHAR(20) , 
            FECHAINICIO           DATETIME   , 
            FECHACREACION         DATETIME   
         )
        ALTER TABLE AFIALE
        ADD CONSTRAINT AFIALEIDAFIALE
        PRIMARY KEY CLUSTERED (IDAFIALE)
        
         CREATE TABLE DBO.ALET (
            IDALET                SMALLINT IDENTITY   NOT NULL , 
            TIPOALERGIA           VARCHAR(20) NOT NULL, 
            NOMBRE                VARCHAR(255) NOT NULL, 
            CLASE                 VARCHAR(2) NOT NULL
         )
        ALTER TABLE ALET
        ADD CONSTRAINT ALETIDALET
        PRIMARY KEY CLUSTERED (IDALET)
        
         CREATE TABLE DBO.ALE (
            IDALE                 INT IDENTITY NOT NULL , 
            IDALET                SMALLINT NOT NULL  , 
            CODIGO                VARCHAR(20) NOT NULL, 
            NOMBRE                VARCHAR(255) NOT NULL
         )
        ALTER TABLE ALE
        ADD CONSTRAINT ALEIDALE
        PRIMARY KEY CLUSTERED (IDALE)
        
         CREATE TABLE DBO.AFIALEFR (
            IDAFIALEFR            SMALLINT IDENTITY   NOT NULL , 
            IDAFIALE              SMALLINT    NOT NULL , 
            TIPOFACTOR            VARCHAR(20) NOT NULL, 
            NOMBREFACTOR          VARCHAR(255) NOT NULL
         )
        ALTER TABLE AFIALEFR
        ADD CONSTRAINT AFIALEFRIDAFIALEFR
        PRIMARY KEY CLUSTERED (IDAFIALEFR)
go        

-- -------------------------------------------------------------------------------
-- Definición de Llaves Foraneas 
-- -------------------------------------------------------------------------------

ALTER TABLE AFIALE WITH NOCHECK ADD CONSTRAINT FK_AFIALE_AFIALEIDAFILIADO FOREIGN KEY (IDAFILIADO )
 REFERENCES AFI ( IDAFILIADO )  ON UPDATE CASCADE  ON DELETE NO ACTION;
ALTER TABLE AFIALE CHECK CONSTRAINT FK_AFIALE_AFIALEIDAFILIADO;
GO

ALTER TABLE AFIALE WITH NOCHECK ADD CONSTRAINT FK_AFIALE_AFIALEIDALET FOREIGN KEY (IDALET )
 REFERENCES ALET ( IDALET )  ON UPDATE CASCADE  ON DELETE NO ACTION;
ALTER TABLE AFIALE CHECK CONSTRAINT FK_AFIALE_AFIALEIDALET;
GO

ALTER TABLE AFIALEFR WITH NOCHECK ADD CONSTRAINT FK_AFIALEFR_AFIAIDAFILIADO FOREIGN KEY (IDAFIALE )
 REFERENCES AFIALE ( IDAFIALE )  ON UPDATE CASCADE  ON DELETE NO ACTION;
ALTER TABLE AFIALEFR CHECK CONSTRAINT FK_AFIALEFR_AFIAIDAFILIADO;
GO

ALTER TABLE ALE WITH NOCHECK ADD CONSTRAINT FK_ALE_ALEIDALET FOREIGN KEY (IDALET )
 REFERENCES ALET ( IDALET )  ON UPDATE CASCADE  ON DELETE NO ACTION;
ALTER TABLE ALE CHECK CONSTRAINT FK_ALE_ALEIDALET;
GO

-- -------------------------------------------------------------------------------
-- Generación de Indices Adicionales 
-- -------------------------------------------------------------------------------

-- =====================================================================
-- ELIMINAR ÍNDICES EXISTENTES ANTES DE RECREARLOS
-- =====================================================================

-- Tabla MDCI
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'MDCICODIGO' AND object_id = OBJECT_ID('MDCI'))
    DROP INDEX MDCICODIGO ON MDCI;

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'MDCIDESCRIPCION' AND object_id = OBJECT_ID('MDCI'))
    DROP INDEX MDCIDESCRIPCION ON MDCI;

-- Tabla AFIALE
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'AFIALEIDAFILIADO' AND object_id = OBJECT_ID('AFIALE'))
    DROP INDEX AFIALEIDAFILIADO ON AFIALE;

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'AFIELEIDMDCI' AND object_id = OBJECT_ID('AFIALE'))
    DROP INDEX AFIELEIDMDCI ON AFIALE;

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'AFIALEIDALET' AND object_id = OBJECT_ID('AFIALE'))
    DROP INDEX AFIALEIDALET ON AFIALE;

-- Tabla ALET
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ALETTIPOALERGIA' AND object_id = OBJECT_ID('ALET'))
    DROP INDEX ALETTIPOALERGIA ON ALET;

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ALETNOMBRE' AND object_id = OBJECT_ID('ALET'))
    DROP INDEX ALETNOMBRE ON ALET;

-- Tabla ALE
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ALEIDALET' AND object_id = OBJECT_ID('ALE'))
    DROP INDEX ALEIDALET ON ALE;

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ALECODIGO' AND object_id = OBJECT_ID('ALE'))
    DROP INDEX ALECODIGO ON ALE;

IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'ALENOMBRE' AND object_id = OBJECT_ID('ALE'))
    DROP INDEX ALENOMBRE ON ALE;

-- Tabla AFIALEFR
IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'AFIALEFRTIPOFACTOR' AND object_id = OBJECT_ID('AFIALEFR'))
    DROP INDEX AFIALEFRTIPOFACTOR ON AFIALEFR;

GO

-- =====================================================================
-- CREAR ÍNDICES
-- =====================================================================

CREATE UNIQUE INDEX MDCICODIGO ON MDCI (CODIGO)
CREATE INDEX MDCIDESCRIPCION ON MDCI (DESCRIPCION)
CREATE UNIQUE INDEX AFIALEIDAFILIADO ON AFIALE (IDAFILIADO,IDAFIALE)
CREATE INDEX AFIELEIDMDCI ON AFIALE (IDMDCI,IDAFILIADO)
CREATE INDEX AFIALEIDALET ON AFIALE (IDALET,IDAFIALE)
CREATE UNIQUE INDEX ALETTIPOALERGIA ON ALET (TIPOALERGIA)
CREATE UNIQUE INDEX ALETNOMBRE ON ALET (NOMBRE)
CREATE UNIQUE INDEX ALEIDALET ON ALE (IDALET,IDALE)
CREATE UNIQUE INDEX ALECODIGO ON ALE (CODIGO)
CREATE UNIQUE INDEX ALENOMBRE ON ALE (NOMBRE)
CREATE UNIQUE INDEX AFIALEFRTIPOFACTOR ON AFIALEFR (TIPOFACTOR,IDAFIALE)
GO


-- Tipos de alergias, el campo CLASE está quemado en la app y es el que se tomará para RDA
insert into ALET (TIPOALERGIA,NOMBRE,CLASE) values
('01','Medicamento','01'),
('02','Alimento','02'),
('03','Sustancia del ambiente','03'),
('04','Sustancia que entran en contacto con la piel','04'),
('05','Picadura de insectos','05'),
('06','Otra','06')
go

-- Configurar Server para importar desde excel
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE;
EXEC sp_configure 'Ad Hoc Distributed Queries', 1;
RECONFIGURE;
go
-- Habilitar Driver para importar
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1
EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1
GO

-- Importa de excel los códigos DCI
insert into MDCI (CODIGO,DESCRIPCION)
SELECT Codigo, Nombre 
FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
    'Excel 8.0;Database=c:\DBases\Scripts\MDCI.xls;HDR=YES',
    'SELECT * FROM [MDCI$]');
go

-- Campos de Tipo de Incapacidad en TGEN
insert into TGEN(TABLA,CAMPO,CODIGO,DESCRIPCION) values
('AFIALE','PARENTANTFAM','01','Padres'),
('AFIALE','PARENTANTFAM','02','Hermanos'),
('AFIALE','PARENTANTFAM','03','Tios'),
('AFIALE','PARENTANTFAM','04','Abuelos')
go

-- Campos de Tipo de Factor de Riesgo en TGEN
insert into TGEN(TABLA,CAMPO,CODIGO,DESCRIPCION) values
('AFIALEFR','TIPOFACTOR','01','Químicos'),
('AFIALEFR','TIPOFACTOR','02','Físicos'),
('AFIALEFR','TIPOFACTOR','03','Biomecánicos'),
('AFIALEFR','TIPOFACTOR','04','Psicosociales'),
('AFIALEFR','TIPOFACTOR','05','Biológicos'),
('AFIALEFR','TIPOFACTOR','06','Otros')
go

/*
1-Edad gestacional en semanas
2-Embarazo múltiple si o no 
3-Numero de nacidos vivos
4- numero del certificado de cada nacido vivo

Condiciones 
si el embarazo es múltiple es si
debe preguntar cuál es el número de nacidos vivos, dependiendo del numero de nacidos vivos mostrar la cantidad de campos para escribir los números de certificados de nacidos vivos.

si el embarazo múltiple es NO
por defecto en numero de nacidos vivos colocar 1 y generar un solo campo para escribir el número de certificado de nacido vivo.
*/

alter table IME add TIPO varchar(2);                -- Tipo de incapacidad, 01: Medica, 02:Maternidad (TGEN)
alter table IME add LMEDADGEST decimal(7,2);        -- 1- Edad gestacional en semanas
alter table IME add LMEMBARAZOMULT varchar(2);      -- 2- Embarazo múltiple si o no 
alter table IME add LMNUMNACVIV tinyint;            -- 3- Numero de nacidos vivos
alter table IME add LMNUMCERTNACVIV varchar(128);   -- 4- Numero del certificado de cada nacido vivo
go

-- Campos de Tipo de Incapacidad en TGEN
insert into TGEN(TABLA,CAMPO,CODIGO,DESCRIPCION) values
('IME','CONTINGENCIA','EC','Médica General'),
('IME','CONTINGENCIA','LM','Licencia de Maternidad'),
('IME','CONTINGENCIA','AT','Accidente Trabajo'),
('IME','CONTINGENCIA','EP','Enfermedad Profesional'),
('IME','CONTINGENCIA','TT','Accidente de tránsito')
go

-- Unidad de medida de la duración del tratamiento: Código Unidad de Tiempo
alter table HPRED add CODUNIDURACIONTTO varchar(20);
go
-- Códigos de Unidad de Tiempo para Duración en TGEN
insert into TGEN(TABLA,CAMPO,CODIGO,DESCRIPCION) values
('HPRED','CODUNIDURACIONTTO','1','Minutos'),
('HPRED','CODUNIDURACIONTTO','2','Horas'),
('HPRED','CODUNIDURACIONTTO','3','Días'),
('HPRED','CODUNIDURACIONTTO','4','Semanas'),
('HPRED','CODUNIDURACIONTTO','5','Meses'),
('HPRED','CODUNIDURACIONTTO','6','Años'),
('HPRED','CODUNIDURACIONTTO','7','Según Respuesta al Tratamiento')
go

-- Campos adicionales del tratamiento
alter table HPRED add IDUNIDADTTO varchar(5);
alter table HPRED add IDFORFARMTTO varchar(2);
alter table HPRED add VIATTO varchar(20); -- se toma de TGEN OMED,VIA
alter table HPRED add FRECUENCIATTO int
alter table HPRED add CODUNIFRECUENCIATTO varchar(20)
go

-- Códigos de Unidad de Tiempo para Frecuencia en TGEN
insert into TGEN(TABLA,CAMPO,CODIGO,DESCRIPCION) values
('HPRED','CODUNIFRECUENCIATTO','1','Minutos'),
('HPRED','CODUNIFRECUENCIATTO','2','Horas'),
('HPRED','CODUNIFRECUENCIATTO','3','Días'),
('HPRED','CODUNIFRECUENCIATTO','4','Semanas'),
('HPRED','CODUNIFRECUENCIATTO','5','Meses'),
('HPRED','CODUNIFRECUENCIATTO','6','Años')
go


-- AUNA: Oncomedica8
use Oncomedica8
go
drop view IFFA  
go
create view IFFA  
as  
 select   
  IDFORFARM=IDFORFARM collate database_default,  
  DESCRIPCION=left(DESCRIPCION,50) collate database_default,  
  IDITAR=left(IDITAR,2) collate database_default  
  from DxContable.dbo.IFFA with(nolock)  
go

-- AUNA: Clintos8
use Clintos8
go

drop view IFFA  
go
create view IFFA  
as  
 select   
  IDFORFARM=IDFORFARM collate database_default,  
  DESCRIPCION=left(DESCRIPCION,50) collate database_default,  
  IDITAR=left(IDITAR,2) collate database_default  
  from DxZF.dbo.IFFA with(nolock)  
go


-- Otros Clientes
use Clintos8
go
drop view IFFA  
go
create view IFFA  
as  
 select   
  IDFORFARM=IDFORFARM collate database_default,  
  DESCRIPCION=left(DESCRIPCION,50) collate database_default,  
  IDITAR=left(IDITAR,2) collate database_default  
  from DxContable.dbo.IFFA with(nolock)  
go

select * from tgen where tabla='omed' and campo='via'


TGEN:TABLA = 'R2SISPRO'
TGEN:CAMPO = 'VIAINGUSUARIO'
GLO:CAMPOTGEN = 'VIAINGUSUARIO'

TGEN:TGENTABLA
TGEN:CODIGO
Brw:TGEN

ITPPageOfPages
ReportPageNumber