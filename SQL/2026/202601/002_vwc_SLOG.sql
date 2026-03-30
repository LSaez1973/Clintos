-- Campos Nuevos HCA
alter table HCA add UUID uniqueidentifier; -- ID de transacción para vincular con HCAD/HCASV/HCADL
alter table HCAD add UUID uniqueidentifier; -- ID de transacción para vincular con HCA
alter table HCADL add UUID uniqueidentifier; -- ID de transacción para vincular con HCA
alter table HCASV add UUID uniqueidentifier; -- ID de transacción para vincular con HCA
alter table HRED add UUID uniqueidentifier; -- ID de transacción para vincular con HCA
go
-- USUARIO: usuario que modifica
-- FECHAHC: Fecha modificación
-- IMPRESO: # de veces imprimido
alter table HCA add USUARIOCREACION varchar(12);
alter table HCA add FECHACREACION datetime;
alter table HCA add USUARIOIMPRIME varchar(12);
alter table HCA add FECHAIMPRIME datetime;
alter table HCA add USUARIOACCESO varchar(12);
alter table HCA add FECHAACCESO datetime;
go


-- Consulta de historial general de todos los campos y tablas HCA/HCAD/HCADL/HCASV


-- Tabla general para uso en optimización de consultas complejas
create table dbo.Multiplicador (N int primary key);
insert into dbo.Multiplicador (N) values (1), (2);
GO

-- Indices requeridos
create index idx_SLOG_TABLA_FECHA on SLOG(TABLA, FECHA);
create index idx_SLOGD_IDSLOG_CAMPO on SLOGD(IDSLOG, CAMPO);
go

-- Vista indexada auxiliar de SLOG para HC 
drop VIEW if exists dbo.vwc_SLOG_HCA0 
go
CREATE VIEW dbo.vwc_SLOG_HCA0 
WITH SCHEMABINDING 
AS
SELECT 
    l.FECHA AS FECHATRANS, l.IDSLOG, ld.ITEM, l.OEPRACION AS OPERACION, l.USUARIO, l.GRUPO, l.SYS_COMPUTERNAME,
    -- Usamos CAST para asegurar tipos de datos consistentes
    CAMPO = CASE 
        WHEN ld.CAMPO = 'UUID' AND n.N = 1 THEN CAST('UUID' AS VARCHAR(100))
        WHEN ld.CAMPO = 'UUID' AND n.N = 2 THEN CAST('UUID_ANT' AS VARCHAR(100))
        ELSE CAST(ld.CAMPO AS VARCHAR(100))
    END,
    DATO = CASE 
        WHEN ld.CAMPO = 'UUID' AND n.N = 1 THEN ld.DATO_NUE
        WHEN ld.CAMPO = 'UUID' AND n.N = 2 THEN ld.DATO_ANT
        WHEN l.OEPRACION = 'Elimina' THEN ld.DATO_ANT
        ELSE ld.DATO_NUE 
    END
FROM dbo.SLOG l  
	JOIN dbo.SLOGD ld ON ld.IDSLOG = l.IDSLOG
	JOIN dbo.Multiplicador n ON n.N <= 2 -- Referencia a tabla física
WHERE l.TABLA = 'HCA'
  AND ld.CAMPO IN ('CONSECUTIVO', 'IDAFILIADO', 'UUID', 'FECHAACCESO')
  AND ( (ld.CAMPO = 'UUID') OR (ld.CAMPO <> 'UUID' AND n.N = 1) )
  -- El filtro IS NOT NULL debe ser sobre la expresión completa
  AND CASE 
        WHEN ld.CAMPO = 'UUID' AND n.N = 1 THEN ld.DATO_NUE
        WHEN ld.CAMPO = 'UUID' AND n.N = 2 THEN ld.DATO_ANT
        WHEN l.OEPRACION = 'Elimina' THEN ld.DATO_ANT
        ELSE ld.DATO_NUE 
    END IS NOT NULL;
GO
-- Indice clustered de la vista
CREATE UNIQUE CLUSTERED INDEX IX_vwc_SLOG_HCA0 
ON dbo.vwc_SLOG_HCA0 (IDSLOG, ITEM, CAMPO);
GO

drop function if exists dbo.fnc_SLOG_HCA;
go
create function dbo.fnc_SLOG_HCA (@CONSECUTIVO VARCHAR(20))
RETURNS TABLE AS RETURN (
    SELECT FECHATRANS, IDSLOG, ITEM, OPERACION, USUARIO, GRUPO, SYS_COMPUTERNAME, CONSECUTIVO, IDAFILIADO, UUID_ANT, UUID, FECHAACCESO
    FROM (
        -- Subconsulta que filtra usando la vista indexada antes de pivotar
        SELECT l.FECHATRANS, l.IDSLOG, l.ITEM, l.OPERACION, l.CAMPO, l.DATO, l.USUARIO, l.GRUPO, l.SYS_COMPUTERNAME
        FROM dbo.vwc_SLOG_HCA0 l WITH (nolock,noexpand)
        WHERE EXISTS (
            -- Localiza rápidamente el IDSLOG relacionado al consecutivo
            SELECT 1 
            FROM dbo.vwc_SLOG_HCA0 f WITH (nolock,noexpand)
            WHERE f.IDSLOG = l.IDSLOG and f.CAMPO = 'CONSECUTIVO' and f.DATO = @CONSECUTIVO
        )
    ) ld
    PIVOT (MAX(DATO) FOR CAMPO IN (CONSECUTIVO, IDAFILIADO, UUID_ANT, UUID, FECHAACCESO)) pv
)
GO


drop view if exists vwc_SLOG_HCA
go
create view vwc_SLOG_HCA
as
    SELECT FECHATRANS, IDSLOG, ITEM, OPERACION, USUARIO, GRUPO, SYS_COMPUTERNAME, CONSECUTIVO, IDAFILIADO, UUID_ANT, UUID, FECHAACCESO
    FROM (
        -- Subconsulta que filtra usando la vista indexada antes de pivotar
        SELECT l.FECHATRANS, l.IDSLOG, l.ITEM, l.OPERACION, l.CAMPO, l.DATO, l.USUARIO, l.GRUPO, l.SYS_COMPUTERNAME
        FROM dbo.vwc_SLOG_HCA0 l WITH (nolock,noexpand)
    ) ld
    PIVOT (MAX(DATO) FOR CAMPO IN (CONSECUTIVO, IDAFILIADO, UUID_ANT, UUID, FECHAACCESO)) pv		
go

drop view if exists vwc_SLOG_HCAD
go
create view vwc_SLOG_HCAD
as
	with 
	_hcad as (
		select pv.FECHATRANS, pv.IDSLOG, pv.ITEM, TABLA='HCAD', OPERACION=pv.OEPRACION, pv.CONSECUTIVO, pv.SECUENCIA, 
			CAMPO = coalesce(pv.CAMPO, hd.CAMPO), md.DESCCAMPO, 
			DATO_ANT = case t.TIPOCAMPO
				when 'Alfanumerico' then pv.ALFANUMERICO_ANT
				when 'Lista' then pv.ALFANUMERICO_ANT
				when 'Agilis' then pv.ALFANUMERICO_ANT
				when 'Fecha' then pv.FECHA_ANT
				when 'FechaHora' then pv.FECHA_ANT
				else  pv.MEMO_ANT
			end,
			DATO_NUE = case t.TIPOCAMPO
				when 'Alfanumerico' then pv.ALFANUMERICO
				when 'Lista' then pv.ALFANUMERICO
				when 'Agilis' then pv.ALFANUMERICO
				when 'Fecha' then pv.FECHA
				when 'FechaHora' then pv.FECHA
				else pv.MEMO
			end, 
			hd.TIPOCAMPO, pv.USUARIO, pv.GRUPO, pv.SYS_COMPUTERNAME, pv.UUID
		from (
			select FECHATRANS=l.FECHA, l.IDSLOG, ld.ITEM, l.OEPRACION, l.USUARIO, l.GRUPO, l.SYS_COMPUTERNAME, d.*
			from SLOG l with(nolock) 
				join SLOGD ld with(nolock) on ld.IDSLOG=l.IDSLOG and l.TABLA = 'HCAD'
				cross apply (values 
					(ld.CAMPO, ld.DATO_NUE),
					(ld.CAMPO + '_ANT', ld.DATO_ANT)
			) AS d (_CAMPO, DATO)
			where ld.CAMPO in ('CONSECUTIVO','SECUENCIA','CAMPO','TIPOCAMPO','ALFANUMERICO','MEMO','FECHA','UUID')
		) ld 
			pivot (max(ld.DATO) for _CAMPO in (CONSECUTIVO,SECUENCIA,CAMPO,TIPOCAMPO,ALFANUMERICO_ANT,ALFANUMERICO,MEMO_ANT,MEMO,FECHA,FECHA_ANT,UUID)) pv	
			-- Datos de la HC para obtener campos que no se movieron en el log, ej. TIPOCAMPO
			left join HCAD hd with(nolock) on hd.CONSECUTIVO = pv.CONSECUTIVO and hd.SECUENCIA=pv.SECUENCIA
			-- Plantilla con que fue generada la HC
			left join MPLD md with(nolock) on md.CLASEPLANTILLA = hd.CLASEPLANTILLA and md.SECUENCIA=pv.SECUENCIA
			-- Tipo campo Prefijo|HC cruzar con mpld por MPLD.CLASEPLANTILLAORG y MPLD.CAMPOORG
			left join MPLD mh with(nolock) on mh.CLASEPLANTILLA = md.CLASEPLANTILLAORG and mh.CAMPO=md.CAMPOORG
			cross apply (select TIPOCAMPO = coalesce(pv.TIPOCAMPO,hd.TIPOCAMPO)) t0
			cross apply (select TIPOCAMPO = iif(t0.TIPOCAMPO in ('HC','Prefijo'), mh.TIPO_CAMPO, t0.TIPOCAMPO)) t
	),
	_hcadl as (
		select pv.FECHATRANS, pv.IDSLOG, pv.ITEM, TABLA='HCADL', OPERACION=pv.OEPRACION, pv.CONSECUTIVO, pv.SECUENCIA, 
			CAMPO = coalesce(hd.CAMPO, md.CAMPO), DESCCAMPO=VALORLISTA,
			DATO_ANT = CHECKM_ANT, DATO_NUE=CHECKM, hd.TIPOCAMPO, pv.USUARIO, pv.GRUPO, pv.SYS_COMPUTERNAME, pv.UUID
		from (
			select FECHATRANS = l.FECHA, l.IDSLOG, ld.ITEM, l.OEPRACION, l.USUARIO, l.GRUPO, l.SYS_COMPUTERNAME, d.*
			from SLOG l with(nolock) 
				join SLOGD ld with(nolock) on ld.IDSLOG=l.IDSLOG and l.TABLA = 'HCADL'
				cross apply (values 
					(ld.CAMPO, ld.DATO_NUE),
					(ld.CAMPO + '_ANT', ld.DATO_ANT)
			) AS d (_CAMPO, DATO)
			where ld.CAMPO in ('CONSECUTIVO','SECUENCIA','VALORLISTA','CHECKM','UUID')
		) ld 
			pivot (max(ld.DATO) for _CAMPO in (CONSECUTIVO,SECUENCIA,VALORLISTA,CHECKM_ANT,CHECKM,UUID)) pv	
			-- Datos de la HC para obtener campos que no se movieron en el log, ej. CAMPO
			left join HCAD hd with(nolock) on hd.CONSECUTIVO = pv.CONSECUTIVO and hd.SECUENCIA=pv.SECUENCIA
			-- Plantilla con que fue generada la HC
			left join MPLD md with(nolock) on md.CLASEPLANTILLA = hd.CLASEPLANTILLA and md.SECUENCIA=pv.SECUENCIA
	)
	select * from _hcad union all
	select * from _hcadl
go

drop function if exists dbo.fnc_SLOG_HCAD
go
create function dbo.fnc_SLOG_HCAD(@CONSECUTIVO varchar(20))
returns table as return ( 
	with 
	_hca as (
		select l.FECHATRANS, l.IDSLOG, l.ITEM, TABLA='HCA', l.OPERACION, l.CONSECUTIVO, SECUENCIA=null, 
			d.CAMPO, DESCCAMPO = null, d.DATO_ANT, d.DATO_NUE, TIPOCAMPO='', l.USUARIO, l.GRUPO, l.SYS_COMPUTERNAME, l.UUID
		from vwc_SLOG_HCA l  
			join SLOGD d with(nolock) on d.IDSLOG = l.IDSLOG and d.ITEM = l.ITEM
		where not d.CAMPO in ('CONSECUTIVO','UUID')
			and l.CONSECUTIVO = @CONSECUTIVO
	),
	_hcad as (
		select pv.FECHATRANS, pv.IDSLOG, pv.ITEM, TABLA='HCAD', OPERACION=pv.OEPRACION, pv.CONSECUTIVO, pv.SECUENCIA, 
			CAMPO = coalesce(pv.CAMPO, hd.CAMPO), md.DESCCAMPO, 
			DATO_ANT = case t.TIPOCAMPO
				when 'Alfanumerico' then pv.ALFANUMERICO_ANT
				when 'Lista' then pv.ALFANUMERICO_ANT
				when 'Agilis' then pv.ALFANUMERICO_ANT
				when 'Fecha' then pv.FECHA_ANT
				when 'FechaHora' then pv.FECHA_ANT
				else  pv.MEMO_ANT
			end,
			DATO_NUE = case t.TIPOCAMPO
				when 'Alfanumerico' then pv.ALFANUMERICO
				when 'Lista' then pv.ALFANUMERICO
				when 'Agilis' then pv.ALFANUMERICO
				when 'Fecha' then pv.FECHA
				when 'FechaHora' then pv.FECHA
				else pv.MEMO
			end, 
			hd.TIPOCAMPO, pv.USUARIO, pv.GRUPO, pv.SYS_COMPUTERNAME, pv.UUID
		from (
			select FECHATRANS=l.FECHA, l.IDSLOG, ld.ITEM, l.OEPRACION, l.USUARIO, l.GRUPO, l.SYS_COMPUTERNAME, d.*
			from SLOG l with(nolock) 
				join SLOGD ld with(nolock) on ld.IDSLOG=l.IDSLOG and l.TABLA = 'HCAD'
				cross apply (values 
					(ld.CAMPO, ld.DATO_NUE),
					(ld.CAMPO + '_ANT', ld.DATO_ANT)
			) AS d (_CAMPO, DATO)
			where ld.CAMPO in ('CONSECUTIVO','SECUENCIA','CAMPO','TIPOCAMPO','ALFANUMERICO','MEMO','FECHA','UUID')
		) ld 
			pivot (max(ld.DATO) for _CAMPO in (CONSECUTIVO,SECUENCIA,CAMPO,TIPOCAMPO,ALFANUMERICO_ANT,ALFANUMERICO,MEMO_ANT,MEMO,FECHA,FECHA_ANT,UUID)) pv	
			-- Datos de la HC para obtener campos que no se movieron en el log, ej. TIPOCAMPO
			left join HCAD hd with(nolock) on hd.CONSECUTIVO = pv.CONSECUTIVO and hd.SECUENCIA=pv.SECUENCIA
			-- Plantilla con que fue generada la HC
			left join MPLD md with(nolock) on md.CLASEPLANTILLA = hd.CLASEPLANTILLA and md.SECUENCIA=pv.SECUENCIA
			-- Tipo campo Prefijo|HC cruzar con mpld por MPLD.CLASEPLANTILLAORG y MPLD.CAMPOORG
			left join MPLD mh with(nolock) on mh.CLASEPLANTILLA = md.CLASEPLANTILLAORG and mh.CAMPO=md.CAMPOORG
			cross apply (select TIPOCAMPO = coalesce(pv.TIPOCAMPO,hd.TIPOCAMPO)) t0
			cross apply (select TIPOCAMPO = iif(t0.TIPOCAMPO in ('HC','Prefijo'), mh.TIPO_CAMPO, t0.TIPOCAMPO)) t
		where pv.CONSECUTIVO = @CONSECUTIVO
	),
	_hcadl as (
		select pv.FECHATRANS, pv.IDSLOG, pv.ITEM, TABLA='HCADL', OPERACION=pv.OEPRACION, pv.CONSECUTIVO, pv.SECUENCIA, 
			CAMPO = coalesce(hd.CAMPO, md.CAMPO), DESCCAMPO=VALORLISTA,
			DATO_ANT = CHECKM_ANT, DATO_NUE=CHECKM, hd.TIPOCAMPO, pv.USUARIO, pv.GRUPO, pv.SYS_COMPUTERNAME, pv.UUID
		from (
			select FECHATRANS = l.FECHA, l.IDSLOG, ld.ITEM, l.OEPRACION, l.USUARIO, l.GRUPO, l.SYS_COMPUTERNAME, d.*
			from SLOG l with(nolock) 
				join SLOGD ld with(nolock) on ld.IDSLOG=l.IDSLOG and l.TABLA = 'HCADL'
				cross apply (values 
					(ld.CAMPO, ld.DATO_NUE),
					(ld.CAMPO + '_ANT', ld.DATO_ANT)
			) AS d (_CAMPO, DATO)
			where ld.CAMPO in ('CONSECUTIVO','SECUENCIA','VALORLISTA','CHECKM','UUID')
		) ld 
			pivot (max(ld.DATO) for _CAMPO in (CONSECUTIVO,SECUENCIA,VALORLISTA,CHECKM_ANT,CHECKM,UUID)) pv	
			-- Datos de la HC para obtener campos que no se movieron en el log, ej. CAMPO
			left join HCAD hd with(nolock) on hd.CONSECUTIVO = pv.CONSECUTIVO and hd.SECUENCIA=pv.SECUENCIA
			-- Plantilla con que fue generada la HC
			left join MPLD md with(nolock) on md.CLASEPLANTILLA = hd.CLASEPLANTILLA and md.SECUENCIA=pv.SECUENCIA
		where pv.CONSECUTIVO = @CONSECUTIVO
	)
	select * from _hca union all
	select * from _hcad union all
	select * from _hcadl 
)
go

use Oncomedica8
go
-- Se deben volver a regenerar todos los triggers porque se dispuso de un indice clustered en vista de SLOG/SLOGD
-- ejecute y copiar el resultado y pegar en el editor sql y ejecute los scripts de generación de trigers de audiroría
select 'exec dbo.spCreateLogTrigger '''+object_name(parent_obj)+''',''agilisusr'',''Ag1l152012'',''c:\DBases\Scripts\'',5,''Oncomedica8.dbo.'';' 
from sysobjects where name like 'tr%autolog'
go
-- Pegar quí...
exec dbo.spCreateLogTrigger 'USGRU','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
exec dbo.spCreateLogTrigger 'USGRU','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
exec dbo.spCreateLogTrigger 'SSAC','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
exec dbo.spCreateLogTrigger 'USGRUH','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
exec dbo.spCreateLogTrigger 'USUSU','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
exec dbo.spCreateLogTrigger 'HCA','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
exec dbo.spCreateLogTrigger 'HCAD','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
exec dbo.spCreateLogTrigger 'HCADL','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
exec dbo.spCreateLogTrigger 'HCASV','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
exec dbo.spCreateLogTrigger 'HRED','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Oncomedica8.dbo.';
go


use Clintos8
go
-- Se deben volver a regenerar todos los triggers porque se dispuso de un indice clustered en vista de SLOG/SLOGD
-- ejecute y copiar el resultado y pegar en el editor sql y ejecute los scripts de generación de trigers de audiroría
select 'exec dbo.spCreateLogTrigger '''+object_name(parent_obj)+''',''agilisusr'',''Ag1l152012'',''c:\DBases\Scripts\'',5,''Clintos8.dbo.'';' 
from sysobjects where name like 'tr%autolog'
go
-- Pegar quí...
exec dbo.spCreateLogTrigger 'USGRU','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Clintos8.dbo.';
exec dbo.spCreateLogTrigger 'USGRU','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Clintos8.dbo.';
exec dbo.spCreateLogTrigger 'HCA','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Clintos8.dbo.';
exec dbo.spCreateLogTrigger 'HCAD','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Clintos8.dbo.';
exec dbo.spCreateLogTrigger 'HCADL','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Clintos8.dbo.';
exec dbo.spCreateLogTrigger 'HCASV','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Clintos8.dbo.';
exec dbo.spCreateLogTrigger 'HRED','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Clintos8.dbo.';
exec dbo.spCreateLogTrigger 'SSAC','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Clintos8.dbo.';
exec dbo.spCreateLogTrigger 'USGRU','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Clintos8.dbo.';
exec dbo.spCreateLogTrigger 'USGRUH','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Clintos8.dbo.';
exec dbo.spCreateLogTrigger 'USUSU','agilisusr','Ag1l152012','c:\DBases\Scripts\',5,'Clintos8.dbo.';
go


/*
select * from vwc_SLOG_HCA where CONSECUTIVO = '0102153133'
select * from vwc_SLOG_HCA where OPERACION = 'Elimina'
select * from dbo.fnc_SLOG_HCA('0102153133') order by FECHATRANS desc
select * from dbo.fnc_SLOG_HCAD('0102153133') where OPERACION='Elimina'
*/

