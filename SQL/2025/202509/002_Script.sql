-- Variables de sistema para habilitacion de campos CIE 10 y 11
insert into usvgs(IDVARIABLE, DESCRIPCION, TP_VARIABLE, DATO) values
('REQDXCIE10','Requiere Dx CIE 10','Alfanumerica','1'),
('REQDXCIE11','Requiere Dx CIE 11','Alfanumerica','0')
go

select dbo.FNK_ValorVariable('REQDXCIE10')
go

-- Politicas de seguridad de la app

/*  
--------------------------------------------------------------  
declare @pJson varchar(max);  
set @pJson = '{"code":100,"data":[{"id_sucursal":2794,"id_comercio":1072,"nombre":"Test Coins Chicó","email":"flopez@puntosleal.com","direccion":"Cl 0 cra 0","id_ciudad":1,"latitud":4.675905499999999,"longitud":-74.04175130000002,"hora_desde":"01:00:00","
hora_hasta":"01:00:00","telefono":"33333333333","comentarios":"no","estado":"activa","estado_admin":"pendiente","id_franquicia":0,"fecha_creacion":"2019-08-22 22:16:29","camara_dispositivo":"n","codigo_credibanco":"0","pos_integrado":"s","fecha_apagado":n
ull,"id_externo":0,"visible_app":"n","lc":1,"sucursal_virtual":0,"cod_pais":"CO"}]}'  
select * from  [dbo].[SmartParseJSON] (@pJson)  
--------------------------------------------------------------  
*/  
create FUNCTION [dbo].[SmartParseJSON] (@json NVARCHAR(MAX))  
RETURNS @Parsed TABLE (Parent NVARCHAR(MAX),Path NVARCHAR(MAX),Level INT,Param NVARCHAR(4000),Type NVARCHAR(255),Value NVARCHAR(MAX),GenericPath NVARCHAR(MAX))  
AS  
BEGIN  
    -- Author: Vitaly Borisov  
    -- Create date: 2018-03-23  
    ;WITH crData AS (  
        SELECT CAST(NULL AS NVARCHAR(4000)) COLLATE DATABASE_DEFAULT AS [Parent]  
            ,j.[Key] AS [Param],j.Value,j.Type  
            ,j.[Key] AS [Path],0 AS [Level]  
            ,j.[Key] AS [GenericPath]  
        FROM OPENJSON(@json) j  
        UNION ALL  
        SELECT CAST(d.Path AS NVARCHAR(4000)) COLLATE DATABASE_DEFAULT AS [Parent]  
            ,j.[Key] AS [Param],j.Value,j.Type   
            ,d.Path + CASE d.Type WHEN 5 THEN '.' WHEN 4 THEN '[' ELSE '' END + j.[Key] + CASE d.Type WHEN 4 THEN ']' ELSE '' END AS [Path]  
            ,d.Level+1  
            ,d.GenericPath + CASE d.Type WHEN 5 THEN '.' + j.[Key] ELSE '' END AS [GenericPath]  
        FROM crData d   
        CROSS APPLY OPENJSON(d.Value) j  
        WHERE ISJSON(d.Value) = 1  
    )  
    INSERT INTO @Parsed(Parent, Path, Level, Param, Type, Value, GenericPath)  
    SELECT d.Parent,d.Path,d.Level,d.Param  
        ,CASE d.Type   
            WHEN 1 THEN CASE WHEN TRY_CONVERT(UNIQUEIDENTIFIER,d.Value) IS NOT NULL THEN 'UNIQUEIDENTIFIER' ELSE 'NVARCHAR(MAX)' END   
            WHEN 2 THEN 'INT'   
            WHEN 3 THEN 'BIT'   
            WHEN 4 THEN 'Array'   
            WHEN 5 THEN 'Object'   
                ELSE 'NVARCHAR(MAX)'  
         END AS [Type]  
        ,CASE   
            WHEN d.Type = 3 AND d.Value = 'true' THEN '1'  
            WHEN d.Type = 3 AND d.Value = 'false' THEN '0'  
                ELSE d.Value  
         END AS [Value]  
        ,d.GenericPath  
    FROM crData d  
    OPTION(MAXRECURSION 1000) /*Limit to 1000 levels deep*/  
    ;  
    RETURN;  
END  
--------------------------------------------------------------  
--- fin  
--------------------------------------------------------------  
go

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[CIACNT]') AND type in (N'U'))
	DROP TABLE [dbo].[CIACNT]
GO
/*
CREATE TABLE DxContable.dbo.CIACNT (
    ID  bigint not null identity(1,1) , 
    FECHA  DATETIME DEFAULT dbo.fnk_Fecha_Sin_Mls(getdate()),
	EQUIPO VARCHAR(50),
	USUARIO VARCHAR(50),
	JSONDATA VARCHAR(max)
)
ALTER TABLE DxContable.dbo.CIACNT ADD CONSTRAINT CIACNTID PRIMARY KEY CLUSTERED (ID)
go
*/
use Oncomedica8
go
Create View dbo.CIACNT
as
	select * from DxContable.dbo.CIACNT
go

use Clintos8
go
Create View dbo.CIACNT
as
	select * from DxZF.dbo.CIACNT
go

-- Log de password de usuarios
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'dbo.USUCNT') AND type in (N'U'))
DROP TABLE dbo.USUCNT
GO
CREATE TABLE dbo.USUCNT(
	ITEM bigint not null IDENTITY(1,1),
	COMPANIA varchar(2) NOT NULL,
	USUARIO varchar(12) NOT NULL,
	PASSWORD varchar(1000) NULL,
	IDEMPRESA decimal(19, 0) NULL,
	EMAIL varchar(100) NULL,
	CELULAR varchar(30) NULL,
	CODIGO varchar(10) NULL,
	ESTADO tinyint NULL,
	FECHAADICION datetime NULL DEFAULT dbo.fnk_Fecha_Sin_Mls(getdate()),
 CONSTRAINT USUCNTCOMPANIA PRIMARY KEY CLUSTERED 
(	COMPANIA ASC,	USUARIO ASC,	ITEM ASC) ON [PRIMARY]
) ON [PRIMARY]
GO

-- Importar Contraseñas

alter table USUSU alter column CLAVE varchar(1000);
alter table USUSU add CLAVEV1 varchar(8); -- Guarda la contraseña encriptada con el algoritmo de clarion
go
update USUSU set CLAVEV1=CLAVE, CLAVE=HASHBYTES('SHA2_512',DBO.FNK_ENCRIPTA(CLAVE,''))
go
insert into USUCNT (COMPANIA, USUARIO, PASSWORD, EMAIL, CELULAR, CODIGO, ESTADO) 
select COMPANIA, USUARIO,  CLAVE, email=null, CELULAR=null, NULL, case when estado='Activo' then 1 else 0 end 
from USUSU 
go
-- Activacion de Log de auditoria para Clintos8 de las siguientes tablas:
-- El usuario de windows debe tener permisos de escritura en la carpeta c:\DBases\Scripts\
exec dbo.spCreateLogTrigger 'USUSU','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
exec dbo.spCreateLogTrigger 'USGRU','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
exec dbo.spCreateLogTrigger 'USGRUH','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
exec dbo.spCreateLogTrigger 'SSAC','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
--exec dbo.spCreateLogTrigger 'cweb.USGRU','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
--exec dbo.spCreateLogTrigger 'cweb.USGRUH','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
--exec dbo.spCreateLogTrigger 'cweb.SSAC','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
go


select * from USUSU
select * from fna_verTriggers('USUSU','dbo')
select * from fna_verTriggers('USGRU','dbo')
select * from fna_verTriggers('USGRUH','dbo')
select * from fna_verTriggers('SSAC','dbo')
/*
drop trigger trUSUSU_AUTOLOG
drop trigger trUSGRU_AUTOLOG
drop trigger trUSGRUH_AUTOLOG
drop trigger trSSAC_AUTOLOG
*/
select  c.Param, c.VALUE, a.FECHA 
from CIACNT a 
	inner join (select top 1 ID from  CIACNT order by fecha desc ) as b on a.ID = b.ID 
	cross apply [dbo].[SmartParseJSON] (a.jsondata) c
go

-- update USUSU set CLAVE=HASHBYTES('SHA2_512','NuevaClave') where USUARIO='xyz'


