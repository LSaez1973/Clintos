/*--------------------------------------------------------
-- Vitácora de cambios, orden cronologico descendente --
--------------------------------------------------------

-- 16.06.2018: Inclusión de CLASEORDEN para buscar servicios contratados
vwc_kcnt_Capitado
vwc_kcnt_Evento
fnc_KCNT_unaEspecialidad_ClaseOrden
fnc_KCNT_unServicioADM_ClaseOrden
fnc_KCNT_unPrefijo_ClaseOrden
fnc_KCNT_unServicio_ClaseOrden

-- Fin vitácora --
*/
-- Resumen por Admision/Tipo COntrato/Servicio
/*
Create Function dbo.fnc_RsmTipoContrato_xHADM(@NOADMISION varchar(20))
returns varchar(12)
as
begin
	declare @TipoContrato varchar(12);
	with mem1 as (
		select N=ROW_NUMBER() over (partition by a.noadmision order by case a.TIPOCONTRATO when 'E' then 1 when 'C' then 2 when 'N' then 3 else 4 end), 
			a.NOADMISION, TIPOCONTRATO=coalesce(a.TIPOCONTRATO,'?'), a.S
		from (
			select a.NOADMISION, c.TIPOCONTRATO, S=sum(case when c.idservicio is null then 0 else 1 end)
			from hadm a 
				left join hpre b on a.NOADMISION=b.NOADMISION 
				left join hpred c on b.NOPRESTACION=c.NOPRESTACION
			where a.noadmision=@NOADMISION
			group by a.NOADMISION, c.TIPOCONTRATO
		) a
	)
	select @TipoContrato=case TIPOCONTRATO when 'E' then 'Evento' when 'C' then 'Capitación' when 'N' then 'No Cobertura' else 'Sin definir' end 
	from mem1
	return @TipoContrato
end
go*/

-- select dbo.fnc_TipoContrato_HADM_xHPRED(NOADMISION,IDAFILIADO,IDTERCERO),* from hadm
-- select dbo.fnc_TipoContrato_HADM_KCNT(NOADMISION,IDAFILIADO,IDTERCERO),* from hadm


-- No Cobrables

-- No Cobrables
drop view dbo.vwc_KCNTNC_AGS_U 
go
Create View dbo.vwc_KCNTNC_AGS_U with schemabinding
as
	select n.KCNTID, n.KCNTNCID, n.IDAGRUPACIONSER from dbo.KCNTNC n where n.TIPOSELAGS='U'
go
create unique clustered index idx_vwc_KCNTNC_AGS_U on vwc_KCNTNC_AGS_U(KCNTNCID, IDAGRUPACIONSER)
go

drop view dbo.vwc_KCNTNC_AGS_L 
go
Create View dbo.vwc_KCNTNC_AGS_L with schemabinding
as
	select n.KCNTID, n.KCNTNCID, IDAGRUPACIONSER=g.CODIGO from dbo.KCNTNC n, dbo.KCNTTG g 
	Where n.TIPOSELAGS='L' and g.tabla='KCNTNC' and g.campo='IDAGRUPACIONSER' and n.KCNTNCID=g.REGISTRO
go
create unique clustered index idx_vwc_KCNTNC_AGS_L on vwc_KCNTNC_AGS_L(KCNTNCID, IDAGRUPACIONSER)
go

drop view dbo.vwc_KCNTNC_AGS_T 
go
Create View dbo.vwc_KCNTNC_AGS_T with schemabinding
as
	select n.KCNTID, n.KCNTNCID, x1.IDAGRUPACIONSER from dbo.KCNTNC n, dbo.AGS x1 where n.TIPOSELAGS='T'
go
create unique clustered index idx_vwc_KCNTNC_AGS_T on vwc_KCNTNC_AGS_T(KCNTNCID, IDAGRUPACIONSER)
go

drop view dbo.vwc_KCNTNC_AGS 
go
Create View dbo.vwc_KCNTNC_AGS
as
	select KCNTID,KCNTNCID,IDAGRUPACIONSER from dbo.vwc_KCNTNC_AGS_U WITH (NoLock,NoExpand) union all
	select KCNTID,KCNTNCID,IDAGRUPACIONSER from dbo.vwc_KCNTNC_AGS_L WITH (NoLock,NoExpand) union all
	select KCNTID,KCNTNCID,IDAGRUPACIONSER from dbo.vwc_KCNTNC_AGS_T WITH (NoLock,NoExpand)
go
-- select * from vwc_KCNTNC_AGS

drop view dbo.vwc_KCNTNC_Areas_U 
go
Create View dbo.vwc_KCNTNC_Areas_U with schemabinding
as
	select n.KCNTID, n.KCNTNCID, n.IDAREA from dbo.KCNTNC n where n.TIPOSELAREA='U'
go
create unique clustered index idx_vwc_KCNTNC_Areas_U on vwc_KCNTNC_Areas_U(KCNTNCID, IDAREA)
go

drop view dbo.vwc_KCNTNC_Areas_L 
go
Create View dbo.vwc_KCNTNC_Areas_L with schemabinding
as
	select n.KCNTID, n.KCNTNCID, IDAREA=g.CODIGO from dbo.KCNTNC n, dbo.KCNTTG g 
	Where n.TIPOSELAREA='L' and g.tabla='KCNTNC' and g.campo='IDAREA' and n.KCNTNCID=g.REGISTRO
go
create unique clustered index idx_vwc_KCNTNC_Areas_L on vwc_KCNTNC_Areas_L(KCNTNCID, IDAREA)
go

drop view dbo.vwc_KCNTNC_Areas_T 
go
Create View dbo.vwc_KCNTNC_Areas_T with schemabinding
as
	select n.KCNTID, n.KCNTNCID, x1.IDAREA from dbo.KCNTNC n, dbo.AFU x1 where n.TIPOSELAREA='T'
go
create unique clustered index idx_vwc_KCNTNC_Areas_T on vwc_KCNTNC_Areas_T(KCNTNCID, IDAREA)
go

drop view dbo.vwc_KCNTNC_Areas 
go
Create View dbo.vwc_KCNTNC_Areas
as
	select KCNTID,KCNTNCID,IDAREA from dbo.vwc_KCNTNC_Areas_U WITH (NoLock,NoExpand) union all
	select KCNTID,KCNTNCID,IDAREA from dbo.vwc_KCNTNC_Areas_L WITH (NoLock,NoExpand) union all
	select KCNTID,KCNTNCID,IDAREA from dbo.vwc_KCNTNC_Areas_T WITH (NoLock,NoExpand)
go
-- select * from vwc_KCNTNC_Areas

-- Sedes de cobertura
drop view dbo.vwc_KCNTNC_Sedes_U
go
Create View dbo.vwc_KCNTNC_Sedes_U with schemabinding 
as
	select n.KCNTID,n.KCNTNCID, n.IDSEDE from dbo.KCNTNC n where n.TIPOSELSEDE='U'
go
create unique clustered index idx_vwc_KCNTNC_Sedes_U on vwc_KCNTNC_Sedes_U(IDSEDE,KCNTNCID)
go

drop view dbo.vwc_KCNTNC_Sedes_L
go
Create View dbo.vwc_KCNTNC_Sedes_L with schemabinding 
as
	select n.KCNTID,n.KCNTNCID, IDSEDE=g.CODIGO from dbo.KCNTNC n, dbo.KCNTTG g 
	where n.TIPOSELSEDE='L' and g.tabla='KCNTNC' and g.campo='IDSEDE' and n.KCNTNCID=g.REGISTRO	
go
create unique clustered index idx_vwc_KCNTNC_Sedes_L on vwc_KCNTNC_Sedes_L(IDSEDE,KCNTNCID)
go

drop view dbo.vwc_KCNTNC_Sedes_T
go
Create View dbo.vwc_KCNTNC_Sedes_T with schemabinding 
as
	select n.KCNTID, n.KCNTNCID, x1.IDSEDE from dbo.KCNTNC n, dbo.SED x1 where n.TIPOSELSEDE='T'
go
create unique clustered index idx_vwc_KCNTNC_Sedes_T on vwc_KCNTNC_Sedes_T(IDSEDE,KCNTNCID)
go

drop view dbo.vwc_KCNTNC_Sedes
go
Create View dbo.vwc_KCNTNC_Sedes 
as
	select KCNTID, KCNTNCID, IDSEDE from dbo.vwc_KCNTNC_Sedes_U with (NoLock,NoExpand)	union all
	select KCNTID, KCNTNCID, IDSEDE from dbo.vwc_KCNTNC_Sedes_L with (NoLock,noexpand)	union all
	select KCNTID, KCNTNCID, IDSEDE from dbo.vwc_KCNTNC_Sedes_T with (NoLock,noexpand)
go
-- select * from vwc_KCNTNC_Sedes


-- Areas de cobertura
drop view dbo.vwc_KCNT_Areas_U 
go
Create View dbo.vwc_KCNT_Areas_U with schemabinding
as
	select n.KCNTID, n.KNEGID, n.IDAREA from dbo.KNEG n where n.TIPOSELAREA='U'
go
create unique clustered index idx_vwc_KCNT_Areas_U on vwc_KCNT_Areas_U(KNEGID, IDAREA);
create nonclustered index idx_vwc_KCNT_Areas_T_IDAREA on dbo.vwc_KCNT_Areas_U (IDAREA) include (KNEGID);
go

drop view dbo.vwc_KCNT_Areas_L 
go
Create View dbo.vwc_KCNT_Areas_L with schemabinding
as
	select n.KCNTID, n.KNEGID, IDAREA=g.CODIGO from dbo.KNEG n, dbo.KCNTTG g 
	Where n.TIPOSELAREA='L' and g.tabla='KNEG' and g.campo='IDAREA' and n.KNEGID=g.REGISTRO
go
create unique clustered index idx_vwc_KCNT_Areas_L on vwc_KCNT_Areas_L(KNEGID, IDAREA)
create nonclustered index idx_vwc_KCNT_Areas_T_IDAREA on dbo.vwc_KCNT_Areas_L (IDAREA) include (KNEGID)
go

drop view dbo.vwc_KCNT_Areas_T 
go
Create View dbo.vwc_KCNT_Areas_T with schemabinding
as
	select n.KCNTID, n.KNEGID, x1.IDAREA from dbo.KNEG n, dbo.AFU x1 where n.TIPOSELAREA='T'
go
create unique clustered index idx_vwc_KCNT_Areas_T on vwc_KCNT_Areas_T(KNEGID, IDAREA)
create nonclustered index idx_vwc_KCNT_Areas_T_IDAREA on dbo.vwc_KCNT_Areas_T (IDAREA) include (KNEGID)
go


drop view dbo.vwc_KCNT_Areas 
go
Create View dbo.vwc_KCNT_Areas
as
	select KCNTID,KNEGID,IDAREA from dbo.vwc_KCNT_Areas_U WITH (NoLock,NoExpand) union all
	select KCNTID,KNEGID,IDAREA from dbo.vwc_KCNT_Areas_L WITH (NoLock,NoExpand) union all
	select KCNTID,KNEGID,IDAREA from dbo.vwc_KCNT_Areas_T WITH (NoLock,NoExpand)
go
-- select * from vwc_KCNT_Areas

-- Sedes de cobertura
drop view dbo.vwc_KCNT_Sedes_U
go
Create View dbo.vwc_KCNT_Sedes_U with schemabinding 
as
	select n.KCNTID,n.KNEGID, n.IDSEDE from dbo.KNEG n where n.TIPOSELSEDE='U'
go
create unique clustered index idx_vwc_KCNT_Sedes_U on vwc_KCNT_Sedes_U(IDSEDE,KNEGID)
go

drop view dbo.vwc_KCNT_Sedes_L
go
Create View dbo.vwc_KCNT_Sedes_L with schemabinding 
as
	select n.KCNTID,n.KNEGID, IDSEDE=g.CODIGO from dbo.KNEG n, dbo.KCNTTG g where n.TIPOSELSEDE='L' and g.tabla='KNEG' and g.campo='IDSEDE' and n.KNEGID=g.REGISTRO	
go
create unique clustered index idx_vwc_KCNT_Sedes_L on vwc_KCNT_Sedes_L(IDSEDE,KNEGID)
go

drop view dbo.vwc_KCNT_Sedes_T
go
Create View dbo.vwc_KCNT_Sedes_T with schemabinding 
as
	select n.KCNTID, n.KNEGID, x1.IDSEDE from dbo.KNEG n, dbo.SED x1 where n.TIPOSELSEDE='T'
go
create unique clustered index idx_vwc_KCNT_Sedes_T on vwc_KCNT_Sedes_T(IDSEDE,KNEGID)
go

drop view dbo.vwc_KCNT_Sedes
go
Create View dbo.vwc_KCNT_Sedes 
as
	select KCNTID, KNEGID, IDSEDE from dbo.vwc_KCNT_Sedes_U with (NoLock,NoExpand)	union all
	select KCNTID, KNEGID, IDSEDE from dbo.vwc_KCNT_Sedes_L with (NoLock,noexpand)	union all
	select KCNTID, KNEGID, IDSEDE from dbo.vwc_KCNT_Sedes_T with (NoLock,noexpand)
go
-- select * from vwc_KCNT_Sedes

drop view dbo.vwc_KCNT_BDP1;
go
create view dbo.vwc_KCNT_BDP1 with schemabinding
as
	select a.KCNTID, b.IDAFILIADO, b.ESTADO from dbo.KCNT a join dbo.KCNTAF b on a.KCNTID=b.KCNTID where a.BDPROPIA=1 
go
create unique clustered index idx_vwc_KCNT_BDP1 on vwc_KCNT_BDP1(KCNTID,IDAFILIADO,ESTADO);
CREATE NONCLUSTERED INDEX idx_vwc_KCNT_BDP1_IDAFILIADOESTADO ON [dbo].[vwc_KCNT_BDP1] ([IDAFILIADO],[ESTADO]);
go
drop view dbo.vwc_KCNT_BDP0;
go
create view dbo.vwc_KCNT_BDP0 with schemabinding
as
	select a.KCNTID, b.IDAFILIADO, b.ESTADO from dbo.KCNT a join dbo.AFI b on a.IDTERCERO=b.IDADMINISTRADORA where a.BDPROPIA=0
go
create unique clustered index idx_vwc_KCNT_BDP0 on vwc_KCNT_BDP0(KCNTID,IDAFILIADO,ESTADO);
CREATE NONCLUSTERED INDEX idx_vwc_KCNT_BDP0_IDAFILIADOESTADO ON [dbo].[vwc_KCNT_BDP0] ([IDAFILIADO],[ESTADO]);
go
drop view dbo.vwc_KCNT_BD;
go
create view dbo.vwc_KCNT_BD 
as
	select * from dbo.vwc_KCNT_BDP0 with(NoLock,noexpand) union all
	select * from dbo.vwc_KCNT_BDP1 with(NoLock,noexpand)
go

-- Agrupacion de Servicios por Servicios Administrativos
drop view dbo.vwc_AGSSER_PRES
go
Create View dbo.vwc_AGSSER_PRES with schemabinding
as
	select d.IDSERVICIOADM, b.IDAGRUPACIONSER, b.IDSERVICIO, c.PREFIJO, c.SEXO, ESTADOS=c.ESTADO
	from dbo.AGSD b 
		join dbo.SER c on b.IDSERVICIO=c.IDSERVICIO
		join dbo.PRES d on c.PREFIJO= d.PREFIJO
go
--create unique clustered index idx_vwc_AGSSER_PRES on vwc_AGSSER_PRES(IDSERVICIOADM,IDAGRUPACIONSER,PREFIJO,IDSERVICIO,SEXO,ESTADOS) 
create unique clustered index idx_vwc_AGSSER_PRES on vwc_AGSSER_PRES([IDSERVICIOADM],[PREFIJO],[IDAGRUPACIONSER],[IDSERVICIO],[SEXO],[ESTADOS]) 
go

drop Function dbo.fnc_AGSSER_PRES
go
Create Function dbo.fnc_AGSSER_PRES(@IDSERVICIOADM varchar(20),@PREFIJO varchar(6))
returns @tabla table (
	IDAGRUPACIONSER varchar(20),
	IDSERVICIO varchar(20),
	SEXO varchar(9),
	ESTADOS varchar(8),
	PRIMARY KEY (IDAGRUPACIONSER,IDSERVICIO)
)
as
begin
	insert into @tabla
	select a.IDAGRUPACIONSER, a.IDSERVICIO, a.SEXO, ESTADOS=a.ESTADOS
	from dbo.vwc_AGSSER_PRES a With (NoLock)
	where a.IDSERVICIOADM=@IDSERVICIOADM and a.PREFIJO=@PREFIJO
	return
end
go

-- Agrupacion de Servicios por Servicios por Especialidad
drop Function dbo.fnc_AGSSER_MESS
go
Create Function dbo.fnc_AGSSER_MESS(@IDSERVICIOADM varchar(20),@IDEMEDICA varchar(4))
returns @tabla table (
	IDAGRUPACIONSER varchar(20),
	IDSERVICIO varchar(20),
	SEXO varchar(9),
	ESTADOS varchar(8)
)
as
begin
	insert into @tabla
	select a.IDAGRUPACIONSER, a.IDSERVICIO, a.SEXO, ESTADOS=a.ESTADOS
	from dbo.vwc_AGSSER_PRES a With (NoLock)
		join dbo.MESS e With (NoLock) On a.IDSERVICIO= e.IDSERVICIO
	where a.IDSERVICIOADM=@IDSERVICIOADM and e.IDEMEDICA=@IDEMEDICA
	return
end
go

drop Function dbo.fnc_AGSSER_PRES_1
go
Create Function dbo.fnc_AGSSER_PRES_1(@IDSERVICIOADM varchar(20))
returns @tabla table (
	IDAGRUPACIONSER varchar(20),
	PREFIJO varchar(6),
	IDSERVICIO varchar(20),
	SEXO varchar(9),
	ESTADOS varchar(8)
)
as
begin
	insert into @tabla
	select a.IDAGRUPACIONSER, a.PREFIJO, a.IDSERVICIO, a.SEXO, ESTADOS=a.ESTADOS
	from vwc_AGSSER_PRES a With (NoLock)
	where a.IDSERVICIOADM=@IDSERVICIOADM
	return
end
go

drop view dbo.vwc_KNEG_AGS_SER_U
go
Create View dbo.vwc_KNEG_AGS_SER_U with schemabinding
as 
	select n.KNEGID, IDSERVICIO=d.IDSERVICIOAGS,REQAUTORIZACION=0, ESDEINV=0, PRESTXTERCEROS=0, DIASVENCE=0
	from dbo.KNEG n 
		join dbo.KCNTAGS a on n.KCNTID=a.KCNTID and n.IDAGRUPACIONSER=a.KCNTAGSID
		join dbo.KCNTAGSD d on a.KCNTAGSID=d.KCNTAGSID		
	where n.TIPOSELAGS='U'
go
create unique clustered index idx_vwc_KNEG_AGS_SER_U on vwc_KNEG_AGS_SER_U(IDSERVICIO,KNEGID)
go

drop view dbo.vwc_KNEG_AGS_SER_L
go
Create View dbo.vwc_KNEG_AGS_SER_L with schemabinding
as 
	select n.KNEGID, IDSERVICIO=d.IDSERVICIOAGS, REQAUTORIZACION=SUM(g.REQAUTORIZACION), ESDEINV=SUM(g.ESDEINV), PRESTXTERCEROS=SUM(g.PRESTXTERCEROS), DIASVENCE=SUM(G.DIASVENCE), CG=COUNT_BIG(*)
	from dbo.KNEG n
			join dbo.KCNTTG g on n.KCNTID=g.KCNTID and n.KNEGID=g.REGISTRO and g.tabla='KNEG' and g.campo='IDAGRUPACIONSER'
			join dbo.KCNTAGSD d on g.CODIGO=cast(d.KCNTAGSID as varchar(20))					
	where n.TIPOSELAGS='L'
	group by n.KNEGID, d.IDSERVICIOAGS
go
create unique clustered index idx_vwc_KNEG_AGS_SER_L on vwc_KNEG_AGS_SER_L(IDSERVICIO,KNEGID)
go

drop view dbo.vwc_KNEG_AGS_SER_T
go
Create View dbo.vwc_KNEG_AGS_SER_T with schemabinding
as 
	select n.KNEGID, x1.IDSERVICIO, REQAUTORIZACION=0, ESDEINV=0, PRESTXTERCEROS=0, DIASVENCE=0 
	from dbo.KNEG n, dbo.SER x1 where n.TIPOSELAGS='T' 
go
create unique clustered index idx_vwc_KNEG_AGS_SER_T on vwc_KNEG_AGS_SER_T(IDSERVICIO,KNEGID)
go

drop view dbo.vwc_KNEG_AGS_SER
go
Create View dbo.vwc_KNEG_AGS_SER 
as 
	select KNEGID, IDSERVICIO, REQAUTORIZACION, ESDEINV, PRESTXTERCEROS, DIASVENCE from dbo.vwc_KNEG_AGS_SER_U WITH (NoLock, NoExpand) 
	union all 
	select KNEGID, IDSERVICIO, case when REQAUTORIZACION>=1 then 1 else 0 end, case when ESDEINV>=1 then 1 else 0 end, case when PRESTXTERCEROS>=1 then 1 else 0 end, DIASVENCE/CG 
	from dbo.vwc_KNEG_AGS_SER_L WITH (NoLock, NoExpand) 
	union all 
	select KNEGID, IDSERVICIO, REQAUTORIZACION, ESDEINV, PRESTXTERCEROS, DIASVENCE from dbo.vwc_KNEG_AGS_SER_T WITH (NoLock, NoExpand)
go
-- select * from vwc_KNEG_AGS_SER
go

drop statistics vwc_MAESPRE.STAT_vwc_MAESPRE_PREFIJO
go

drop view dbo.vwc_KNEG_MAES
go
-- Servicios Administrativos por Negociación
drop view dbo.vwc_KNEG_MAES_U
go
Create View dbo.vwc_KNEG_MAES_U with schemabinding
as 
	select c.KNEGID, c.IDSERVICIOADM from dbo.KNEG c where c.TIPOSELSERVICIOADM='U'
go
create unique clustered index idx_vwc_KNEG_MAES_U on vwc_KNEG_MAES_U(KNEGID, IDSERVICIOADM)
go

drop view dbo.vwc_KNEG_MAES_L
go
Create View dbo.vwc_KNEG_MAES_L with schemabinding
as 
	select c.KNEGID, IDSERVICIOADM=g.CODIGO
	from dbo.KNEG c, dbo.KCNTTG g where g.tabla='KNEG' and g.campo='IDSERVICIOADM' and c.KNEGID=g.REGISTRO and c.TIPOSELSERVICIOADM='L' 
go
create unique clustered index idx_vwc_KNEG_MAES_L on vwc_KNEG_MAES_L(KNEGID, IDSERVICIOADM)
go

drop view dbo.vwc_KNEG_MAES_T
go
Create View dbo.vwc_KNEG_MAES_T with schemabinding
as 
	select c.KNEGID, x1.IDSERVICIOADM from dbo.KNEG c, dbo.MAES x1 where c.TIPOSELSERVICIOADM='T'
go
create unique clustered index idx_vwc_KNEG_MAES_T on vwc_KNEG_MAES_T(KNEGID, IDSERVICIOADM)
go

-- drop view dbo.vwc_KNEG_MAES
go
Create View dbo.vwc_KNEG_MAES with schemabinding
as 
	select KNEGID, IDSERVICIOADM from dbo.vwc_KNEG_MAES_U WITH (NoLock,NoExpand) union all 
	select KNEGID, IDSERVICIOADM from dbo.vwc_KNEG_MAES_L WITH (NoLock,NoExpand) union all 
	select KNEGID, IDSERVICIOADM from dbo.vwc_KNEG_MAES_T WITH (NoLock,NoExpand)
go
-- select * from vwc_KNEG_MAES

-- Listado de Prefijos por Servicios Administravos
drop View dbo.vwc_MAESPRE
go
Create View dbo.vwc_MAESPRE with schemabinding
as
	select a.IDSERVICIOADM, b.PREFIJO
	from dbo.maes a
		join dbo.pres b on a.IDSERVICIOADM=b.IDSERVICIOADM
go
create unique clustered index idx_vwc_MAESPRE on dbo.vwc_MAESPRE(IDSERVICIOADM, PREFIJO)
go  
-- select * from vwc_MAESPRE


drop view dbo.vwc_KNEG_MAES_SER
go
Create View dbo.vwc_KNEG_MAES_SER 
as 
	select a.KNEGID, a.IDSERVICIOADM, c.IDSERVICIO, c.PREFIJO, C.SEXO, C.ESTADO
	from dbo.vwc_KNEG_MAES a With (NoLock)
		join dbo.vwc_MAESPRE b With (NoLock) On a.IDSERVICIOADM=b.IDSERVICIOADM
		join dbo.SER c With (NoLock) On b.PREFIJO=c.PREFIJO
go
-- select * from vwc_KNEG_MAES_SER where KNEGID=4
-- select KNEGID,count(*) from vwc_KNEG_MAES_SER group by KNEGID

--Create statistics using a random 10 percent sampling rate
if (select count(*) from sys.stats where name='STAT_vwc_MAESPRE_PREFIJO')>0
begin
	drop statistics vwc_MAESPRE.STAT_vwc_MAESPRE_PREFIJO;
end
go
CREATE STATISTICS STAT_vwc_MAESPRE_PREFIJO ON dbo.vwc_MAESPRE(PREFIJO) WITH FULLSCAN --SAMPLE 10 PERCENT
go

-- Todos los Servicios por Negociación (Cruce de MAES*AGS)
drop view dbo.vwc_KNEG_SER
go
Create View dbo.vwc_KNEG_SER 
as
	select a.*,b.REQAUTORIZACION, b.ESDEINV, b.PRESTXTERCEROS 
	from dbo.vwc_KNEG_MAES_SER a With (NoLock) 
		join dbo.vwc_KNEG_AGS_SER b With (NoLock) On a.KNEGID=b.KNEGID and a.IDSERVICIO=b.IDSERVICIO
go

drop Function dbo.fnc_SER_Info
go
Create Function dbo.fnc_SER_Info(@IDSERVICIO varchar(20))
returns @fnc_SER_xPRE table(
	PREFIJO varchar(6),
	DESCSERVICIO varchar(255),
	SEXO varchar(9),
	ESTADO varchar(8) 
)
as
Begin
	insert into @fnc_SER_xPRE
	select PREFIJO, DESCSERVICIO,SEXO,ESTADO 
	from SER with(NoLock,index(idx_SER_SERVICIO)) where IDSERVICIO=@IDSERVICIO
	return
End
go

-- ***
-- Acción por No Cobertura: YA no se usa KCNV
drop view dbo.vwc_KCNV_ACCNOCUBIERTOS
go
Create View dbo.vwc_KCNV_ACCNOCUBIERTOS
as
	select c.KCNVID, c.IDTERCERO, c.FECHAINICIAL, c.FECHAFINAL, b.IDSERVICIO, b.PREFIJO, b.IDSERVICIOADM, b.SEXO, b.ESTADOS, a.ACCION
	from dbo.KCNVNC a With (NoLock)
		join dbo.vwc_AGSSER_PRES b with(NoLock,NoExpand) on a.IDAGRUPACIONSER=b.IDAGRUPACIONSER  
		join dbo.KCNV c With (NoLock) On a.KCNVID=c.KCNVID
	where a.TIPOSELAGS='U'
	union all
	select b.KCNVID, b.IDTERCERO, b.FECHAINICIAL, b.FECHAFINAL, x1.IDSERVICIO, x1.PREFIJO, x1.IDSERVICIOADM, x1.SEXO, x1.ESTADOS, a.ACCION
	from dbo.KCNVNC a With (NoLock)
		join dbo.KCNV b With (NoLock) On a.KCNVID=b.KCNVID 
		Cross Apply dbo.vwc_AGSSER_PRES x1 with(NoLock,NoExpand)
	where a.TIPOSELAGS='T'
go
-- select * from vwc_KCNV_ACCNOCUBIERTOS

drop function dbo.fnc_KCNVNC_unServicio
go
create function dbo.fnc_KCNVNC_unServicio(@IDTERCERO varchar(20), @IDSERVICIOADM varchar(20), @PREFIJO varchar(6),@FECHA datetime, @IDSERVICIO varchar(20))  
returns @fnc_KCNVNC_unServicio   
	table (  
		KCNVID int,  
		TIPOCONTRATO varchar(1),  
		COBRARA varchar(1),  
		IDTERCEROCA varchar(20),  
		VALOR decimal(22,6),  
		VALOR_CALC decimal(22,6),  
		SEXO varchar(9),  
		ESTADOS varchar(8),  
		ACCION varchar(12)  
	)  
as  
begin  
	insert into @fnc_KCNVNC_unServicio  
	select a.KCNVID, 'N', 'A', null, 0, 0, b.SEXO, b.ESTADOS, a.ACCION  
	from dbo.KCNVNC a With (NoLock)   
		join dbo.fnc_AGSSER_PRES(@IDSERVICIOADM,@PREFIJO) b on a.IDAGRUPACIONSER=b.IDAGRUPACIONSER and b.IDSERVICIO=@IDSERVICIO  
		join dbo.KCNV c With (NoLock) On a.KCNVID=c.KCNVID  
	where a.TIPOSELAGS='U' and c.IDTERCERO=@IDTERCERO and @FECHA between c.FECHAINICIAL and c.FECHAFINAL  
	union all  
	select a.KCNVID, 'N', 'A', null, 0, 0, x1.SEXO, x1.ESTADOS, a.ACCION  
	from dbo.KCNVNC a With (NoLock)  
		join dbo.KCNV b With (NoLock) On a.KCNVID=b.KCNVID 
		Cross Apply dbo.fnc_AGSSER_PRES(@IDSERVICIOADM,@PREFIJO) x1   
	where a.TIPOSELAGS='T' and b.IDTERCERO=@IDTERCERO and @FECHA between b.FECHAINICIAL and b.FECHAFINAL and x1.IDSERVICIO=@IDSERVICIO  
   
	Return;
end  
go

drop function dbo.fnc_KCNVNC_unPrefijo
go
create function dbo.fnc_KCNVNC_unPrefijo(@IDTERCERO varchar(20), @IDSERVICIOADM varchar(20), @PREFIJO varchar(6),@FECHA datetime)
returns @fnc_KCNVNC_unPrefijo 
	table (
		KCNVID int,
		TIPOCONTRATO varchar(1),
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		SEXO varchar(9),
		ESTADOS varchar(8),
		ACCION varchar(12)
	)
as
begin
	insert into @fnc_KCNVNC_unPrefijo
	select a.KCNVID, 'N', 'A', null, b.IDSERVICIO, 0, 0, b.SEXO, b.ESTADOS, a.ACCION
	from dbo.KCNVNC a With (NoLock) 
		join dbo.fnc_AGSSER_PRES(@IDSERVICIOADM,@PREFIJO) b on a.IDAGRUPACIONSER=b.IDAGRUPACIONSER  
		join dbo.KCNV c With (NoLock) On a.KCNVID=c.KCNVID
	where a.TIPOSELAGS='U' and c.IDTERCERO=@IDTERCERO and @FECHA between c.FECHAINICIAL and c.FECHAFINAL
	union all
	select a.KCNVID, 'N', 'A', null, x1.IDSERVICIO, 0, 0, x1.SEXO, x1.ESTADOS, a.ACCION
	from dbo.KCNVNC a With (NoLock)
		join dbo.KCNV b With (NoLock) On a.KCNVID=b.KCNVID
		Cross Apply dbo.fnc_AGSSER_PRES(@IDSERVICIOADM,@PREFIJO) x1 
	where a.TIPOSELAGS='T' and b.IDTERCERO=@IDTERCERO and @FECHA between b.FECHAINICIAL and b.FECHAFINAL

	return 
end
go

drop function dbo.fnc_KCNVNC_unaEspecialidad
go
create function dbo.fnc_KCNVNC_unaEspecialidad(@IDTERCERO varchar(20), @IDSERVICIOADM varchar(20), @IDEMEDICA varchar(4),@FECHA datetime)
returns @fnc_KCNVNC_unPrefijo 
	table (
		KCNVID int,
		TIPOCONTRATO varchar(1),
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		SEXO varchar(9),
		ESTADOS varchar(8),
		ACCION varchar(12)
	)
as
begin
	insert into @fnc_KCNVNC_unPrefijo
	select a.KCNVID, 'N', 'A', null, b.IDSERVICIO, 0, 0, b.SEXO, b.ESTADOS, a.ACCION
	from dbo.KCNVNC a With (NoLock) 
		join dbo.fnc_AGSSER_MESS(@IDSERVICIOADM,@IDEMEDICA) b on a.IDAGRUPACIONSER=b.IDAGRUPACIONSER  
		join dbo.KCNV c With (NoLock) On a.KCNVID=c.KCNVID
	where a.TIPOSELAGS='U' and c.IDTERCERO=@IDTERCERO and @FECHA between c.FECHAINICIAL and c.FECHAFINAL
	union all
	select a.KCNVID, 'N', 'A', null, x1.IDSERVICIO, 0, 0, x1.SEXO, x1.ESTADOS, a.ACCION
	from dbo.KCNVNC a With (NoLock)
		join KCNV b With (NoLock) On a.KCNVID=b.KCNVID
		Cross Apply dbo.fnc_AGSSER_MESS(@IDSERVICIOADM,@IDEMEDICA) x1 
	where a.TIPOSELAGS='T' and b.IDTERCERO=@IDTERCERO and @FECHA between b.FECHAINICIAL and b.FECHAFINAL

	Return;
end
go

-- Usando en Aihc0.HCANE:Ficha_
drop function dbo.fnc_KCNVNC_unPrefijo_1
go
create function dbo.fnc_KCNVNC_unPrefijo_1(@IDTERCERO varchar(20), @IDSERVICIOADM varchar(20),@FECHA datetime)
returns @fnc_KCNVNC_unPrefijo 
	table (
		KCNVID int,
		TIPOCONTRATO varchar(1),
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		PREFIJO varchar(6),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		SEXO varchar(9),
		ESTADOS varchar(8),
		ACCION varchar(12)
	)
as
begin
	insert into @fnc_KCNVNC_unPrefijo
	select a.KCNVID, 'N', 'A', null, b.PREFIJO, b.IDSERVICIO, 0, 0, b.SEXO, b.ESTADOS, a.ACCION
	from dbo.KCNVNC a With (NoLock) 
		join dbo.fnc_AGSSER_PRES_1(@IDSERVICIOADM) b on a.IDAGRUPACIONSER=b.IDAGRUPACIONSER  
		join dbo.KCNV c With (NoLock) on a.KCNVID=c.KCNVID
	where a.TIPOSELAGS='U' and c.IDTERCERO=@IDTERCERO and @FECHA between c.FECHAINICIAL and c.FECHAFINAL
	union all
	select a.KCNVID, 'N', 'A', null, x1.PREFIJO, x1.IDSERVICIO, 0, 0, x1.SEXO, x1.ESTADOS, a.ACCION
	from dbo.KCNVNC a With (NoLock)
		join dbo.KCNV b With (NoLock) on a.KCNVID=b.KCNVID
		Cross Apply dbo.fnc_AGSSER_PRES_1(@IDSERVICIOADM) x1 
	where a.TIPOSELAGS='T' and b.IDTERCERO=@IDTERCERO and @FECHA between b.FECHAINICIAL and b.FECHAFINAL

	return 
end
go

-- Version Nueva 
-- Cambios 2020 Terminados
IF OBJECT_ID('dbo.vwc_Tarifas','v') is not null
	drop View dbo.vwc_Tarifas
go
IF OBJECT_ID('dbo.fnc_ValRedondeo','fn') is not null
	drop function dbo.fnc_ValRedondeo;
go
create function dbo.fnc_ValRedondeo(@Redondeo varchar(10)) 
returns int with schemabinding
as
begin
	declare @VREDONDEO int =
		case @Redondeo
			when 'Centena' then -2
			when 'Millar' then -3
			when 'Decena' then -1
			when 'Unidad' then 0
			when 'Un Dec.' then 1
			when 'Dos Dec.' then 2
			when 'SIN' then 8
		end
	return @VREDONDEO;
end
go
-- select dbo.fnc_ValRedondeo('Dos Dec.')

IF OBJECT_ID('dbo.vwc_Tarifas','v') is not null
	drop View dbo.vwc_Tarifas
go
Create View dbo.vwc_Tarifas with schemabinding
as	
	select a.IDTARIFA, c.ITEM, b.IDSERVICIO, d.PREFIJO, b.NOITEM, CIRUGIA=coalesce(e.CIRUGIA,0),
		FECHAINI=case when b.FECHAINI>=c.FECHAINI then b.FECHAINI else c.FECHAINI end, 
		FECHAFIN=case when b.FECHAFIN<=c.FECHAFIN then b.FECHAFIN else c.FECHAFIN end, 
		b.VALOR, c.FACTORDINERO, c.REDONDEO, VREDONDEO=dbo.fnc_ValRedondeo(c.REDONDEO), e.TIPOVALOR,
		VALOR_CALC = case when coalesce(e.TIPOVALOR,'')='D' then b.VALOR else b.VALOR*c.FACTORDINERO end, 
		d.SEXO, d.ESTADO, PAQUETE=e.CALCULADOPAQ
	from dbo.tar a 
		join dbo.tardv b on a.IDTARIFA=b.IDTARIFA
		join dbo.TARF c on a.IDTARIFA=c.IDTARIFA and not (b.FECHAFIN<=c.FECHAINI or c.FECHAFIN<=b.FECHAINI)
		join dbo.SER d on b.IDSERVICIO=d.IDSERVICIO
		join dbo.tard e on b.IDTARIFA=e.IDTARIFA and b.IDSERVICIO=e.IDSERVICIO
go

create unique clustered index pk_vwc_Tarifas on dbo.vwc_Tarifas([IDTARIFA],PREFIJO,[IDSERVICIO],[FECHAFIN] desc,[ITEM] desc,[NOITEM] desc,
	[FECHAINI],[VALOR],[FACTORDINERO],[REDONDEO],SEXO,ESTADO,TIPOVALOR)
GO
CREATE NONCLUSTERED INDEX idx_vwc_Tarifas2 ON [dbo].[vwc_Tarifas] ([IDTARIFA],[IDSERVICIO],[FECHAINI],[FECHAFIN])
go
CREATE NONCLUSTERED INDEX idx_vwc_Tarifas3 ON [dbo].[vwc_Tarifas] ([IDTARIFA],[IDSERVICIO], [FECHAFIN] desc, [ITEM] desc, [NOITEM] desc)
GO

drop function dbo.fnc_TarifaSerAdm;
go
create function dbo.fnc_TarifaSerAdm(@IDTARIFA varchar(5),@IDSERVICIOADM varchar(20), @FECHA datetime)
returns @tabla 
	table (
		ITEM int,
		NOITEM int,
		PREFIJO varchar(6),
		IDSERVICIO varchar(20),			
		VALOR decimal(18,6),			
		FACTORDINERO decimal(10,4),
		TIPOVALOR varchar(1),
		VALOR_CALC decimal(22,6),
		REDONDEO varchar(10),
		VREDONDEO int,		
		FECHAINI	datetime,
		FECHAFIN	datetime,
		CIRUGIA smallint,
		SEXO varchar(9),
		ESTADO varchar(8),
		PAQUETE smallint,
		PRIMARY KEY CLUSTERED (IDSERVICIO, FECHAFIN desc, ITEM desc, NOITEM )				
	)
as
begin
	-- Segun Resoluciones de Ley, el redondeo debe efectuarse al final de todos los calculos
	insert into @tabla
	select a.ITEM, a.NOITEM, a.PREFIJO, a.IDSERVICIO, a.VALOR, a.FACTORDINERO, a.TIPOVALOR, a.VALOR_CALC, a.REDONDEO, a.VREDONDEO, 
		a.FECHAINI, a.FECHAFIN, a.CIRUGIA, a.SEXO, a.ESTADO, a.PAQUETE 
	from (
		select P=ROW_NUMBER() over(partition by a.IDSERVICIO order by a.IDTARIFA, a.FECHAFIN desc, a.ITEM desc, a.NOITEM desc), 
			a.PREFIJO, a.ITEM, a.NOITEM, a.IDSERVICIO, a.VALOR, a.FACTORDINERO, a.TIPOVALOR, a.VALOR_CALC, a.REDONDEO, a.VREDONDEO,
			a.FECHAINI, a.FECHAFIN, a.SEXO, a.ESTADO, a.CIRUGIA, a.PAQUETE 
		from dbo.vwc_Tarifas a with (nolock,noexpand)
			join dbo.PRES b with (nolock) on a.PREFIJO=b.PREFIJO and b.IDSERVICIOADM=@IDSERVICIOADM
		where a.IDTARIFA=@IDTARIFA AND @fecha between a.FECHAINI and a.FECHAFIN
	) a 
	where p=1
	return;
			--FECHAINI=case when a.FECHAINI>=a.FECHAINI then a.FECHAINI else a.FECHAINI end, 
			--FECHAFIN=case when a.FECHAFIN<=a.FECHAFIN then a.FECHAFIN else a.FECHAFIN END,
end
go
-- select * from dbo.fnc_TarifaSerAdm('002C','IMAT','14/12/2019') where CIRUGIA=1
-- select * from dbo.fnc_TarifaSerAdm('002C','IMAT','14/12/2019') where TIPOVALOR='D'
-- select * from dbo.fnc_TarifaSerAdm('002C','IMAT','14/12/2019') where PREFIJO='100'

drop function dbo.fnc_TarifaPre;
go
create function dbo.fnc_TarifaPre(@IDTARIFA varchar(5),@PREFIJO varchar(6), @FECHA datetime)
returns @tabla 
	table (
		ITEM int,
		NOITEM int,
		IDSERVICIO varchar(20),			
		VALOR decimal(18,6),			
		FACTORDINERO decimal(10,4),
		TIPOVALOR varchar(1),
		VALOR_CALC decimal(22,6),
		REDONDEO varchar(10),
		VREDONDEO int,
		FECHAINI	datetime,
		FECHAFIN	datetime,
		CIRUGIA smallint,
		SEXO varchar(9),
		ESTADO varchar(8),
		PAQUETE smallint,
		PRIMARY KEY CLUSTERED (IDSERVICIO, FECHAFIN desc, ITEM desc, NOITEM )				
	)
as
begin
	-- Segun Resoluciones de Ley, el redondeo debe efectuarse al final de todos los calculos
	insert into @tabla
	select a.ITEM, a.NOITEM, a.IDSERVICIO, a.VALOR, a.FACTORDINERO, a.TIPOVALOR, a.VALOR_CALC, a.REDONDEO, a.VREDONDEO, 
		a.FECHAINI, a.FECHAFIN, a.CIRUGIA, a.SEXO, a.ESTADO, a.PAQUETE 
	from (
		select P=ROW_NUMBER() over(partition by a.IDSERVICIO order by a.IDTARIFA, a.FECHAFIN desc, a.ITEM desc, a.NOITEM desc), 
			a.ITEM, a.NOITEM, a.IDSERVICIO, a.VALOR, a.FACTORDINERO, a.TIPOVALOR, a.VALOR_CALC, a.REDONDEO, a.VREDONDEO,
			a.FECHAINI, a.FECHAFIN, a.SEXO, a.ESTADO, a.CIRUGIA, a.PAQUETE 
		from dbo.vwc_Tarifas a with (nolock,noexpand)
		where a.IDTARIFA=@IDTARIFA AND a.PREFIJO=@PREFIJO and @fecha between a.FECHAINI and a.FECHAFIN
	) a 
	where p=1
	return;
			--FECHAINI=case when a.FECHAINI>=a.FECHAINI then a.FECHAINI else a.FECHAINI end, 
			--FECHAFIN=case when a.FECHAFIN<=a.FECHAFIN then a.FECHAFIN else a.FECHAFIN END,
end
go
-- SELECT * FROM fnc_TarifaPre('001C','100','01/05/2020') where tipovalor='D' and cirugia=1

drop function dbo.fnc_TarifaSer;
go
create function dbo.fnc_TarifaSer(@IDTARIFA varchar(5),@IDSERVICIO varchar(20),@FECHA datetime)
returns @fnc_TarifaSer 
	table (
		P int,
		IDTARIFA varchar(5),
		ITEM int,
		IDSERVICIO varchar(20),
		NOITEM int,	
		VALOR decimal(18,6),			
		FACTORDINERO decimal(10,4),
		TIPOVALOR varchar(1),
		VALOR_CALC decimal(22,6),
		REDONDEO varchar(10),
		VREDONDEO int,		
		FECHAINI	datetime,
		FECHAFIN	datetime,
		CIRUGIA smallint,
		SEXO varchar(9),
		ESTADO varchar(8),
		PAQUETE smallint,
		PRIMARY KEY CLUSTERED (IDTARIFA,IDSERVICIO,FECHAFIN desc,ITEM desc,NOITEM desc)				
	)
as
begin
	insert into @fnc_TarifaSer
	select * from (
		select P=ROW_NUMBER() over(partition by IDTARIFA,IDSERVICIO order by FECHAFIN desc,ITEM desc,NOITEM desc), 
			a.IDTARIFA, a.ITEM, a.IDSERVICIO, a.NOITEM,  
			a.VALOR, a.FACTORDINERO, a.TIPOVALOR, a.VALOR_CALC, a.REDONDEO, a.VREDONDEO,
			a.FECHAINI, a.FECHAFIN, a.CIRUGIA, a.SEXO, a.ESTADO, a.PAQUETE
		from dbo.vwc_Tarifas a with (nolock,noexpand)
		where a.IDTARIFA=@IDTARIFA and a.IDSERVICIO=@IDSERVICIO and @FECHA between a.FECHAINI and a.FECHAFIN
	) a where p=1
	return;
			--FECHAINI=case when a.FECHAINI>=a.FECHAINI then a.FECHAINI else a.FECHAINI end, 
			--FECHAFIN=case when a.FECHAFIN<=a.FECHAFIN then a.FECHAFIN else a.FECHAFIN END,
end
go

-- SELECT * FROM fnc_TarifaSer('001','01107','01/09/2019')

drop view dbo.vwc_kcnt_Evento
go
create view dbo.vwc_kcnt_Evento with schemabinding
as
	select a.IDTERCERO, a.TIPOCONTRATO, a.TIPOTTEC, a.TIPOSISTEMA, a.FECHAINICIAL, a.FECHAFINAL, a.KCNTID, b.KNEGID, b.SECUENCIA, b.IDTARIFA, 
		b.FACTOR, b.COBRARA, ESTADO_KCNT=a.ESTADO, ESTADO_KNEG=b.ESTADO, b.NOCOBRABLE, b.COBRARAKCNTID, a.IDMODELOPCA, 
		CLASEORDEN=coalesce(a.CLASEORDEN,''), FACTURABLE=1, a.BDPROPIA
	from dbo.KCNT a 
		join dbo.KNEG b on a.KCNTID=b.KCNTID 
	where a.TIPOCONTRATO='E'
go
create unique clustered index idx_vwc_kcnt_Evento_pkey on vwc_kcnt_Evento(KCNTID,KNEGID);
go
create index idx_vwc_kcnt_Evento on vwc_kcnt_Evento (KCNTID,KNEGID) include (IDTERCERO,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,FECHAINICIAL,FECHAFINAL,
	SECUENCIA,IDTARIFA,FACTOR,COBRARA,ESTADO_KCNT,ESTADO_KNEG,NOCOBRABLE,COBRARAKCNTID,IDMODELOPCA,CLASEORDEN,FACTURABLE,BDPROPIA);
go

drop view dbo.vwc_kcnt_Capitado
go
create view dbo.vwc_kcnt_Capitado with schemabinding
as
	select a.IDTERCERO, a.TIPOCONTRATO, a.TIPOTTEC, a.TIPOSISTEMA, a.FECHAINICIAL, a.FECHAFINAL, a.KCNTID, b.KNEGID, b.SECUENCIA, b.IDTARIFA, 
		b.FACTOR, b.COBRARA, ESTADO_KCNT=a.ESTADO, ESTADO_KNEG=b.ESTADO, b.NOCOBRABLE, b.COBRARAKCNTID, a.IDMODELOPCA, 
		CLASEORDEN=coalesce(a.CLASEORDEN,''), FACTURABLE = 1, a.BDPROPIA
	from dbo.KCNT a
		join dbo.KNEG b on a.KCNTID=b.KCNTID 
	where a.TIPOCONTRATO='C'
go
create unique clustered index idx_vwc_kcnt_Capitado_pkey on vwc_kcnt_Capitado(KCNTID,KNEGID);
go
create index idx_vwc_kcnt_Capitado on vwc_kcnt_Capitado (KCNTID,KNEGID) include (IDTERCERO,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,FECHAINICIAL,FECHAFINAL,
	SECUENCIA,IDTARIFA,FACTOR,COBRARA,ESTADO_KCNT,ESTADO_KNEG,NOCOBRABLE,COBRARAKCNTID,IDMODELOPCA,CLASEORDEN,FACTURABLE,BDPROPIA);
go

drop view dbo.vwc_kcnt_PGP
go
create view dbo.vwc_kcnt_PGP with schemabinding
as
	select a.IDTERCERO, a.TIPOCONTRATO, a.TIPOTTEC, a.TIPOSISTEMA, a.FECHAINICIAL, a.FECHAFINAL, a.KCNTID, b.KNEGID, b.SECUENCIA, b.IDTARIFA, 
		b.FACTOR, b.COBRARA, ESTADO_KCNT=a.ESTADO, ESTADO_KNEG=b.ESTADO, b.NOCOBRABLE, b.COBRARAKCNTID, a.IDMODELOPCA, 
		CLASEORDEN=coalesce(a.CLASEORDEN,''), FACTURABLE = 1, a.BDPROPIA
	from dbo.KCNT a
		join dbo.KNEG b on a.KCNTID=b.KCNTID 
	where a.TIPOCONTRATO='P'
go
create unique clustered index idx_vwc_kcnt_PGP_pkey on vwc_kcnt_PGP(KCNTID,KNEGID);
go
create index idx_vwc_kcnt_PGP on vwc_kcnt_PGP (KCNTID,KNEGID) include (IDTERCERO,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,FECHAINICIAL,FECHAFINAL,
	SECUENCIA,IDTARIFA,FACTOR,COBRARA,ESTADO_KCNT,ESTADO_KNEG,NOCOBRABLE,COBRARAKCNTID,IDMODELOPCA,CLASEORDEN,FACTURABLE,BDPROPIA);
go

drop view dbo.vwc_kcnt_NoCobertura
go
create view dbo.vwc_kcnt_NoCobertura with schemabinding
as
	select a.IDTERCERO, a.TIPOCONTRATO, a.TIPOTTEC, a.TIPOSISTEMA, a.FECHAINICIAL, a.FECHAFINAL, a.KCNTID, b.KNEGID, b.SECUENCIA, b.IDTARIFA, 
		b.FACTOR, b.COBRARA, ESTADO_KCNT=a.ESTADO, ESTADO_KNEG=b.ESTADO, b.NOCOBRABLE, b.COBRARAKCNTID, a.IDMODELOPCA, 
		CLASEORDEN=coalesce(a.CLASEORDEN,''), FACTURABLE=1, a.BDPROPIA
	from dbo.KCNT a
		join dbo.KNEG b on a.KCNTID=b.KCNTID 
	where a.TIPOCONTRATO='N'
go

create unique clustered index idx_vwc_kcnt_NoCobertura_pkey on vwc_kcnt_NoCobertura(KCNTID,KNEGID);
go
create index idx_vwc_kcnt_NoCobertura on vwc_kcnt_NoCobertura (KCNTID,KNEGID) include (IDTERCERO,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,FECHAINICIAL,FECHAFINAL,
	SECUENCIA,IDTARIFA,FACTOR,COBRARA,ESTADO_KCNT,ESTADO_KNEG,NOCOBRABLE,COBRARAKCNTID,IDMODELOPCA,CLASEORDEN,FACTURABLE,BDPROPIA);
go

drop view dbo.vwc_kcnt
go
create view dbo.vwc_kcnt --with schemabinding
as
	select PRIORIDAD=1,* from dbo.vwc_kcnt_Capitado with (noexpand) union all
	select PRIORIDAD=2,* from dbo.vwc_kcnt_PGP with (noexpand) union all
	select PRIORIDAD=3,* from dbo.vwc_kcnt_Evento with (noexpand) union all
	select PRIORIDAD=4,* from dbo.vwc_kcnt_NoCobertura with (noexpand)
go


/* BD del CAMUI
drop view dbo.vwc_kcnt_Evento
go
create view dbo.vwc_kcnt_Evento with schemabinding
as
	select a.IDTERCERO, a.TIPOCONTRATO, a.TIPOTTEC, a.TIPOSISTEMA, a.FECHAINICIAL, a.FECHAFINAL, a.KCNTID, b.KNEGID, b.SECUENCIA, b.IDTARIFA, 
		b.FACTOR, b.COBRARA, ESTADO_KCNT=a.ESTADO, ESTADO_KNEG=b.ESTADO, b.NOCOBRABLE, b.COBRARAKCNTID, a.IDMODELOPCA, 
		CLASEORDEN=coalesce(a.CLASEORDEN,''), FACTURABLE=1, a.BDPROPIA
	from dbo.KCNT a 
		join dbo.KNEG b on a.KCNTID=b.KCNTID 
	where a.TIPOCONTRATO='E'
go
create unique clustered index idx_vwc_kcnt_Evento_pkey on vwc_kcnt_Evento(KCNTID,KNEGID)
create nonclustered index idx_vwc_kcnt_Evento_include on vwc_kcnt_Evento(KCNTID,KNEGID)
include (IDTERCERO,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,FECHAINICIAL,FECHAFINAL,
	SECUENCIA,IDTARIFA,FACTOR,COBRARA,ESTADO_KCNT,ESTADO_KNEG,NOCOBRABLE,COBRARAKCNTID,IDMODELOPCA,CLASEORDEN,FACTURABLE,BDPROPIA);
go

drop view dbo.vwc_kcnt_Capitado
go
create view dbo.vwc_kcnt_Capitado with schemabinding
as
	select a.IDTERCERO, a.TIPOCONTRATO, a.TIPOTTEC, a.TIPOSISTEMA, a.FECHAINICIAL, a.FECHAFINAL, a.KCNTID, b.KNEGID, b.SECUENCIA, b.IDTARIFA, 
		b.FACTOR, b.COBRARA, ESTADO_KCNT=a.ESTADO, ESTADO_KNEG=b.ESTADO, b.NOCOBRABLE, b.COBRARAKCNTID, a.IDMODELOPCA, 
		CLASEORDEN=coalesce(a.CLASEORDEN,''), FACTURABLE=0, a.BDPROPIA
	from dbo.KCNT a
		join dbo.KNEG b on a.KCNTID=b.KCNTID 
	where a.TIPOCONTRATO='C'
go
create unique clustered index idx_vwc_kcnt_Capitado_pkey on vwc_kcnt_Capitado(KCNTID,KNEGID);
create nonclustered index idx_vwc_kcnt_Capitado_include on vwc_kcnt_Capitado(KCNTID,KNEGID) 
include(IDTERCERO,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,FECHAINICIAL,FECHAFINAL,
	SECUENCIA,IDTARIFA,FACTOR,COBRARA,ESTADO_KCNT,ESTADO_KNEG,NOCOBRABLE,COBRARAKCNTID,IDMODELOPCA,CLASEORDEN,FACTURABLE,BDPROPIA);
go

drop view dbo.vwc_kcnt_PGP
go
create view dbo.vwc_kcnt_PGP with schemabinding
as
	select a.IDTERCERO, a.TIPOCONTRATO, a.TIPOTTEC, a.TIPOSISTEMA, a.FECHAINICIAL, a.FECHAFINAL, a.KCNTID, b.KNEGID, b.SECUENCIA, b.IDTARIFA, 
		b.FACTOR, b.COBRARA, ESTADO_KCNT=a.ESTADO, ESTADO_KNEG=b.ESTADO, b.NOCOBRABLE, b.COBRARAKCNTID, a.IDMODELOPCA, 
		CLASEORDEN=coalesce(a.CLASEORDEN,''), FACTURABLE=0, a.BDPROPIA
	from dbo.KCNT a
		join dbo.KNEG b on a.KCNTID=b.KCNTID 
	where a.TIPOCONTRATO='P'
go
create unique clustered index idx_vwc_kcnt_PGP_pkey on vwc_kcnt_PGP(KCNTID,KNEGID);
create nonclustered index idx_vwc_kcnt_PGP_include on vwc_kcnt_PGP (KCNTID,KNEGID)
include(IDTERCERO,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,FECHAINICIAL,FECHAFINAL,
	SECUENCIA,IDTARIFA,FACTOR,COBRARA,ESTADO_KCNT,ESTADO_KNEG,NOCOBRABLE,COBRARAKCNTID,IDMODELOPCA,CLASEORDEN,FACTURABLE,BDPROPIA);
go

drop view dbo.vwc_kcnt_NoCobertura
go
create view dbo.vwc_kcnt_NoCobertura with schemabinding
as
	select a.IDTERCERO, a.TIPOCONTRATO, a.TIPOTTEC, a.TIPOSISTEMA, a.FECHAINICIAL, a.FECHAFINAL, a.KCNTID, b.KNEGID, b.SECUENCIA, b.IDTARIFA, 
		b.FACTOR, b.COBRARA, ESTADO_KCNT=a.ESTADO, ESTADO_KNEG=b.ESTADO, b.NOCOBRABLE, b.COBRARAKCNTID, a.IDMODELOPCA, 
		CLASEORDEN=coalesce(a.CLASEORDEN,''), FACTURABLE=1, a.BDPROPIA
	from dbo.KCNT a
		join dbo.KNEG b on a.KCNTID=b.KCNTID 
	where a.TIPOCONTRATO='N'
go
create unique clustered index idx_vwc_kcnt_NoCobertura_pkey on vwc_kcnt_NoCobertura(KCNTID,KNEGID);
create nonclustered index idx_vwc_kcnt_NoCobertura_include on vwc_kcnt_NoCobertura(KCNTID,KNEGID) 
include(IDTERCERO,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,FECHAINICIAL,FECHAFINAL,
	SECUENCIA,IDTARIFA,FACTOR,COBRARA,ESTADO_KCNT,ESTADO_KNEG,NOCOBRABLE,COBRARAKCNTID,IDMODELOPCA,CLASEORDEN,FACTURABLE,BDPROPIA);
go
*/

drop view dbo.vwc_kcnt
go
create view dbo.vwc_kcnt --with schemabinding
as
	select PRIORIDAD=1,* from dbo.vwc_kcnt_Capitado with (noexpand) union all
	select PRIORIDAD=2,* from dbo.vwc_kcnt_PGP with (noexpand) union all
	select PRIORIDAD=3,* from dbo.vwc_kcnt_Evento with (noexpand) union all
	select PRIORIDAD=4,* from dbo.vwc_kcnt_NoCobertura with (noexpand)
go
-- SELECT * FROM vwc_kcnt where PRIORIDAD in(2,3)


-- ***********************************************************
-- Funciones de Busqueda de Servicios Contratados
-- ***********************************************************

drop function fnc_KCNT_SeleccionFinal;
go
drop Type dbo.KCNT_SerContratados 
go

	Create Type dbo.KCNT_SerContratados 
	as table(
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10),
		TIPOCONTRATO varchar(1),
		TIPOSISTEMA Varchar(12),
		IDTARIFA varchar(5),
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10),
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12),
		ESTADON varchar(12),
		ESTADOA varchar(8),		
		ESTADOS varchar(8),
		SEXO varchar(9),
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12), -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5), 
		--Primary Key nonclustered hash (KCNTID,KNEGID,PRIORIDAD,SECUENCIA,IDSERVICIO) with (bucket_count=100000),
		Primary Key nonclustered hash (IDSERVICIO,PRIORIDAD,KCNTID,SECUENCIA,KNEGID) with (bucket_count=200000)
	)
	with (memory_optimized=on);

/* ROM
	Create Type dbo.KCNT_SerContratados 
	as table(
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10),
		TIPOCONTRATO varchar(1),
		TIPOSISTEMA Varchar(12),
		IDTARIFA varchar(5),
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10),
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12),
		ESTADON varchar(12),
		ESTADOA varchar(8),		
		ESTADOS varchar(8),
		SEXO varchar(9),
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12), -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5)
		Primary Key nonclustered (IDSERVICIO,PRIORIDAD,KCNTID,SECUENCIA,KNEGID) 
	)
Select KCNTID, IDCONTRATO, TIPOCONTRATOREGIMEN, KCNTCAID, CLASEATENCION, KCNTCAEID, IDEMEDICA, MEDDESCRIPCION, BDPROPIA, ESTADOA From dbo.fnc_KCNT_Contratos_xVigencia('Prefijo','01','901097473','EPS','41749809','03','ROM','700','23/12/2021','',2)

*/

/*
	-- es el CAMU
	Create Type dbo.KCNT_SerContratados 
	as table(
		KCNTID int not null,
		KNEGID int not null,
		PRIORIDAD int not null,
		SECUENCIA int not null,
		TIPOTTEC varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		TIPOCONTRATO varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS,
		TIPOSISTEMA Varchar(12) COLLATE SQL_Latin1_General_CP1_CI_AS,
		IDTARIFA varchar(5) COLLATE SQL_Latin1_General_CP1_CI_AS,
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10) COLLATE SQL_Latin1_General_CP1_CI_AS,
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1) COLLATE SQL_Latin1_General_CP1_CI_AS,
		IDTERCEROCA varchar(20) COLLATE SQL_Latin1_General_CP1_CI_AS,
		IDSERVICIO varchar(20) COLLATE Latin1_General_BIN2 not null,
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12) COLLATE SQL_Latin1_General_CP1_CI_AS,
		ESTADON varchar(12) COLLATE SQL_Latin1_General_CP1_CI_AS,
		ESTADOA varchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS,		
		ESTADOS varchar(8) COLLATE SQL_Latin1_General_CP1_CI_AS,
		SEXO varchar(9) COLLATE SQL_Latin1_General_CP1_CI_AS,
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12) COLLATE SQL_Latin1_General_CP1_CI_AS, -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5) COLLATE SQL_Latin1_General_CP1_CI_AS, 
		--Primary Key nonclustered hash (KCNTID,KNEGID,PRIORIDAD,SECUENCIA,IDSERVICIO) with (bucket_count=200000),
		Primary Key nonclustered hash (IDSERVICIO,PRIORIDAD,KCNTID,SECUENCIA,KNEGID) with (bucket_count=200000)
	)
	with (memory_optimized=on);
	*/
go

drop function dbo.fnc_KCNT_Cobrar_A;
go
create function dbo.fnc_KCNT_Cobrar_A (@IDTERCERO varchar(20), @COBRARA varchar(1), @KCNTID int) 
returns varchar(20)
as
begin
	declare @Cobrar_A varchar(20);
	-- Actualiza
	select @Cobrar_A = 
		case @COBRARA 
			when 'C' then @IDTERCERO 
			when 'O' then (select IDTERCERO from dbo.KCNT with (nolock) where KCNTID=@KCNTID) 
			when 'A' then null 
		end
	return @Cobrar_A;
end
go

--drop function dbo.fnc_KCNT_SeleccionFinal; 
go
create function dbo.fnc_KCNT_SeleccionFinal (
	@IDSEDE varchar(5), @IDAREA varchar(20), @MODOSELECCION smallint, @IDTERCERO varchar(20), @IDTARIFA varchar(5), 
	@Servicios as KCNT_SerContratados readonly) 
returns @Resultado
	table (
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10),
		TIPOCONTRATO varchar(1),
		TIPOSISTEMA Varchar(12),
		IDTARIFA varchar(5),
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10),
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12),
		ESTADON varchar(12),
		ESTADOA varchar(8),		
		ESTADOS varchar(8),
		SEXO varchar(9),
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12), -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5), 
		Primary Key (IDSERVICIO,KCNTID,PRIORIDAD,SECUENCIA,KNEGID)
	)
as
begin
	declare @Tabla as KCNT_SerContratados;
	
	if @MODOSELECCION in (1,2)
		begin	
			if (coalesce(@IDTARIFA,'')='')
			insert into @Tabla select * from @Servicios
		else
			insert into @Tabla select * from @Servicios where IDTARIFA = coalesce(@IDTARIFA,IDTARIFA)

		if @MODOSELECCION = 1 -- Toma servicios distintos (Sin servicios repetidos)
		begin
			-- Elimina contratos que manejan BD Propia donde el afiliado no esté activo
			delete @Tabla where BDPROPIA=1 and left(ESTADOA,1)<>'A';
			-- Filtrado por IDSERVICIO, orden por PRIORIDAD, CONTRATO y SECUENCIA de negociación, paciente Activo cuendo BDPROPIA=1
			with m1 as (
				select n=row_number() over(partition by IDSERVICIO order by ESTADOC,PRIORIDAD,KCNTID,SECUENCIA)
				from @Tabla 
			)
			delete m1 where m1.n > 1;
		end
		else
		if @MODOSELECCION = 2 -- Toma servicios distintos de cada contrato (pueden haber servicios repetidos de distintos contratos)
		begin
			-- Filtrado por IDSERVICIO y CONTRATO, orden por PRIORIDAD, CONTRATO y SECUENCIA de negociación, no importa el estado del paciente
			with m1 as (
				select n=row_number() over(partition by IDSERVICIO,KCNTID order by ESTADOC,PRIORIDAD,KCNTID,SECUENCIA)
				from @Tabla
			)
			delete m1 where m1.n > 1;
		end

		-- Estipular NO Cobrables y Tercero a Cobrar		
		update @Tabla 
		set NOCOBRABLE = 1,
			IDTERCEROCA = dbo.fnc_KCNT_Cobrar_A(@IDTERCERO, COBRARA, COBRARAKCNTID) -- Actualiza Tercero al que se Cobra. 
		from @Tabla a 
			cross apply (select IDAGRUPACIONSER from dbo.vwc_KCNTNC_AGS x with (nolock) where a.KCNTID=x.KCNTID) b
			join AGSD c on c.IDAGRUPACIONSER=b.IDAGRUPACIONSER and c.IDSERVICIO=a.IDSERVICIO
			cross apply (select IDAREA from dbo.vwc_KCNTNC_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KCNTID=x.KCNTID) xa
			cross apply (select IDSEDE from dbo.vwc_KCNTNC_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KCNTID=x.KCNTID) xs

		update @Tabla set IDTERCEROCA = dbo.fnc_KCNT_Cobrar_A(@IDTERCERO, COBRARA, COBRARAKCNTID) -- Actualiza Tercero al que se Cobra. 
			
		insert into @Resultado select * from @Tabla
	end
	return;
end
go

/* CAMU
create function dbo.fnc_KCNT_SeleccionFinal (
	@IDSEDE varchar(5), @IDAREA varchar(20), @MODOSELECCION smallint, @IDTERCERO varchar(20), @Servicios as KCNT_SerContratados readonly) 
returns @Resultado
	table (
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10) collate database_default,
		TIPOCONTRATO varchar(1) collate database_default,
		TIPOSISTEMA Varchar(12) collate database_default,
		IDTARIFA varchar(5) collate database_default,
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10) collate database_default,
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20) collate database_default,
		IDSERVICIO varchar(20) collate SQL_Latin1_General_CP1_CI_AS,
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12) collate database_default,
		ESTADON varchar(12) collate database_default,
		ESTADOA varchar(8) collate database_default,		
		ESTADOS varchar(8) collate database_default,
		SEXO varchar(9) collate database_default,
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12) collate database_default, -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5) collate database_default, 
		Primary Key (IDSERVICIO,KCNTID,PRIORIDAD,SECUENCIA,KNEGID)
	)
as
begin
	declare @Tabla as KCNT_SerContratados;
	if @MODOSELECCION in (1,2)
	begin
		insert into @Tabla select * from @Servicios;
	
		if @MODOSELECCION = 1 -- Toma servicios distintos (Sin servicios repetidos)
		begin
			-- Elimina contratos que manejan BD Propia donde el afiliado no esté activo
			delete @Tabla where BDPROPIA=1 and left(ESTADOA,1)<>'A';
			-- Filtrado por IDSERVICIO, orden por PRIORIDAD, CONTRATO y SECUENCIA de negociación, paciente Activo cuendo BDPROPIA=1
			with m1 as (
				select n=row_number() over(partition by IDSERVICIO order by ESTADOC,PRIORIDAD,KCNTID,SECUENCIA)
				from @Tabla 
			)
			delete m1 where m1.n > 1;
		end
		else
		if @MODOSELECCION = 2 -- Toma servicios distintos de cada contrato (pueden haber servicios repetidos de distintos contratos)
		begin
			-- Filtrado por IDSERVICIO y CONTRATO, orden por PRIORIDAD, CONTRATO y SECUENCIA de negociación, no importa el estado del paciente
			with m1 as (
				select n=row_number() over(partition by IDSERVICIO,KCNTID order by ESTADOC,PRIORIDAD,KCNTID,SECUENCIA)
				from @Tabla
			)
			delete m1 where m1.n > 1;
		end

		-- Estipular NO Cobrables y Tercero a Cobrar		
		update @Tabla 
		set NOCOBRABLE = 1,
			IDTERCEROCA = dbo.fnc_KCNT_Cobrar_A(@IDTERCERO, COBRARA, COBRARAKCNTID) -- Actualiza Tercero al que se Cobra. 
		from @Tabla a 
			cross apply (select IDAGRUPACIONSER from dbo.vwc_KCNTNC_AGS x with (nolock) where a.KCNTID=x.KCNTID) b
			join AGSD c on c.IDAGRUPACIONSER=b.IDAGRUPACIONSER and c.IDSERVICIO=a.IDSERVICIO collate SQL_Latin1_General_CP1_CI_AS
			cross apply (select IDAREA from dbo.vwc_KCNTNC_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KCNTID=x.KCNTID) xa
			cross apply (select IDSEDE from dbo.vwc_KCNTNC_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KCNTID=x.KCNTID) xs

		update @Tabla set IDTERCEROCA = dbo.fnc_KCNT_Cobrar_A(@IDTERCERO, COBRARA, COBRARAKCNTID) -- Actualiza Tercero al que se Cobra. 
			
		insert into @Resultado select * from @Tabla
	end
	return;
end
go
*/

drop function dbo.fnc_KCNT_unServicioADM
go
create function dbo.fnc_KCNT_unServicioADM(
	@IDSEDE varchar(5), @IDTERCERO varchar(20), @TIPOTTEC varchar(10), @IDAFILIADO varchar(20), @IDAREA varchar(20), @IDSERVICIOADM varchar(20), 
	@FECHA datetime, @KCNTID int, @MODOSELECCION smallint) 
returns @Resultado
	table (
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10),
		TIPOCONTRATO varchar(1),
		TIPOSISTEMA Varchar(12),
		IDTARIFA varchar(5),
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10),
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12),
		ESTADON varchar(12),
		ESTADOA varchar(8),		
		ESTADOS varchar(8),
		SEXO varchar(9),
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12), -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5), 
		Primary Key (KCNTID,KNEGID,PRIORIDAD,SECUENCIA,IDSERVICIO)
	)
as
begin
	declare @Tabla as dbo.KCNT_SerContratados;

	if @KCNTID>0
		-- Busca solo en el contrato suministrado
		insert into @Tabla
		select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
			x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
			VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
			a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
		from dbo.vwc_kcnt a with(nolock)
			cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
			cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
			left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO --and b.ESTADO='A'
			cross apply dbo.fnc_TarifaSerAdm(a.IDTARIFA,@IDSERVICIOADM,@FECHA) x1
			join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM and x1.IDSERVICIO=d.IDSERVICIO
			cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
		where a.KCNTID=@KCNTID 		
	else
		-- Busca en todos los Contratos posibles
		insert into @Tabla
		select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
			x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
			VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
			a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
		from dbo.vwc_kcnt a with(nolock)
			cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
			cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
			left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
			cross apply dbo.fnc_TarifaSerAdm(a.IDTARIFA,@IDSERVICIOADM,@FECHA) x1
			join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM and x1.IDSERVICIO=d.IDSERVICIO
			cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
		where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC;	

	-- Filtrado por PRIORIDAD de Contrato y SECUENCIA de negociación
	-- Actualiza Tercero al que se Cobra (IDTERCEROCA).
	insert into @Resultado
	select * from dbo.fnc_KCNT_SeleccionFinal(@IDSEDE,@IDAREA,@MODOSELECCION,@IDTERCERO,null,@Tabla) 

	return;
end
go

drop function dbo.fnc_KCNT_unServicioADM_ClaseOrden
go
create function dbo.fnc_KCNT_unServicioADM_ClaseOrden(
	@IDSEDE varchar(5), @IDTERCERO varchar(20), @TIPOTTEC varchar(10), @IDAFILIADO varchar(20), @IDAREA varchar(20), @IDSERVICIOADM varchar(20), 
	@FECHA datetime, @CLASEORDEN varchar(20), @KCNTID int, @MODOSELECCION smallint) 
returns @Resultado
	table (
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10),
		TIPOCONTRATO varchar(1),
		TIPOSISTEMA Varchar(12),
		IDTARIFA varchar(5),
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10),
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12),
		ESTADON varchar(12),
		ESTADOA varchar(8),		
		ESTADOS varchar(8),
		SEXO varchar(9),
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12), -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5), 
		Primary Key (KCNTID,KNEGID,PRIORIDAD,SECUENCIA,IDSERVICIO)
	)
as
begin
	declare @Tabla as dbo.KCNT_SerContratados;

	if @KCNTID>0
		-- Busca solo en el contrato suministrado
		if coalesce(@CLASEORDEN,'')='PyP'
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				cross apply dbo.fnc_TarifaSerAdm(a.IDTARIFA,@IDSERVICIOADM,@FECHA) x1
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM and x1.IDSERVICIO=d.IDSERVICIO
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.KCNTID=@KCNTID and a.CLASEORDEN=@CLASEORDEN
		else
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				cross apply dbo.fnc_TarifaSerAdm(a.IDTARIFA,@IDSERVICIOADM,@FECHA) x1
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM and x1.IDSERVICIO=d.IDSERVICIO
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.KCNTID=@KCNTID and a.CLASEORDEN<>'PyP'
	else
		-- Busca en todos los Contratos posibles
		if coalesce(@CLASEORDEN,'')='PyP'
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				cross apply dbo.fnc_TarifaSerAdm(a.IDTARIFA,@IDSERVICIOADM,@FECHA) x1
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM and x1.IDSERVICIO=d.IDSERVICIO
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC and a.CLASEORDEN=@CLASEORDEN;	
		else
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				cross apply dbo.fnc_TarifaSerAdm(a.IDTARIFA,@IDSERVICIOADM,@FECHA) x1
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM and x1.IDSERVICIO=d.IDSERVICIO
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC and a.CLASEORDEN<>'PyP';	

	-- Filtrado por PRIORIDAD de Contrato y SECUENCIA de negociación
	-- Actualiza Tercero al que se Cobra (IDTERCEROCA).
	insert into @Resultado
	select * from dbo.fnc_KCNT_SeleccionFinal(@IDSEDE,@IDAREA,@MODOSELECCION, @IDTERCERO, null, @Tabla)
	return;
end
go

drop function dbo.fnc_KCNT_unServicio_xTAR
go
create function dbo.fnc_KCNT_unServicio_xTAR(
	@IDTARIFA varchar(5), @IDSEDE varchar(5), @IDTERCERO varchar(20), @TIPOTTEC varchar(10), @IDAFILIADO varchar(20), @IDAREA varchar(20), @IDSERVICIOADM varchar(20), 
	@IDSERVICIO varchar(20), @FECHA datetime, @KCNTID int, @MODOSELECCION smallint) 
returns @Resultado
	table (
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10),
		TIPOCONTRATO varchar(1),
		TIPOSISTEMA Varchar(12),
		IDTARIFA varchar(5),
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10),
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12),
		ESTADON varchar(12),
		ESTADOA varchar(8),		
		ESTADOS varchar(8),
		SEXO varchar(9),
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12), -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5), 
		Primary Key (KCNTID,KNEGID,PRIORIDAD,SECUENCIA,IDSERVICIO)
	)
as
begin
	declare @Tabla as dbo.KCNT_SerContratados;

	if @KCNTID>0
		-- Busca solo en el contrato suministrado
		insert into @Tabla
		select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
			x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
			VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
			a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
		from dbo.vwc_kcnt a with(nolock)
			cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
			cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
			left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
			join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=@IDSERVICIO
			cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
			cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
		where a.KCNTID=@KCNTID 		
	else
		-- Busca en todos los Contratos posibles
		insert into @Tabla
		select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
			x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
			VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
			a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
		from dbo.vwc_kcnt a with(nolock)
			cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
			cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
			left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
			join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=@IDSERVICIO
			cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
			cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
		where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC;	

	-- Filtrado por PRIORIDAD de Contrato y SECUENCIA de negociación
	-- Actualiza Tercero al que se Cobra (IDTERCEROCA).
	insert into @Resultado
	select * from dbo.fnc_KCNT_SeleccionFinal(@IDSEDE,@IDAREA,@MODOSELECCION, @IDTERCERO, @IDTARIFA, @Tabla)

	return;
end
go

drop function dbo.fnc_KCNT_unServicio
go
create function dbo.fnc_KCNT_unServicio(
	@IDSEDE varchar(5), @IDTERCERO varchar(20), @TIPOTTEC varchar(10), @IDAFILIADO varchar(20), @IDAREA varchar(20), @IDSERVICIOADM varchar(20), 
	@IDSERVICIO varchar(20), @FECHA datetime, @KCNTID int, @MODOSELECCION smallint) 
returns @Resultado
	table (
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10),
		TIPOCONTRATO varchar(1),
		TIPOSISTEMA Varchar(12),
		IDTARIFA varchar(5),
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10),
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12),
		ESTADON varchar(12),
		ESTADOA varchar(8),		
		ESTADOS varchar(8),
		SEXO varchar(9),
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12), -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5), 
		Primary Key (KCNTID,KNEGID,PRIORIDAD,SECUENCIA,IDSERVICIO)
	)
as
begin
	declare @Tabla as dbo.KCNT_SerContratados;

	if @KCNTID>0
		-- Busca solo en el contrato suministrado
		insert into @Tabla
		select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
			x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
			VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
			a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
		from dbo.vwc_kcnt a with(nolock)
			cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
			cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
			left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
			join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=@IDSERVICIO
			cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
			cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
		where a.KCNTID=@KCNTID 		
	else
		-- Busca en todos los Contratos posibles
		insert into @Tabla
		select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
			x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
			VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
			a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
		from dbo.vwc_kcnt a with(nolock)
			cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
			cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
			left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
			join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=@IDSERVICIO
			cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
			cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
		where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC;	

	-- Filtrado por PRIORIDAD de Contrato y SECUENCIA de negociación
	-- Actualiza Tercero al que se Cobra (IDTERCEROCA).
	insert into @Resultado
	select * from dbo.fnc_KCNT_SeleccionFinal(@IDSEDE,@IDAREA,@MODOSELECCION, @IDTERCERO, null, @Tabla)

	return;
end
go

drop function dbo.fnc_KCNT_unServicio_ClaseOrden
go
create function dbo.fnc_KCNT_unServicio_ClaseOrden(
	@IDSEDE varchar(5), @IDTERCERO varchar(20), @TIPOTTEC varchar(10), @IDAFILIADO varchar(20), @IDAREA varchar(20), @IDSERVICIOADM varchar(20), 
	@IDSERVICIO varchar(20), @FECHA datetime, @CLASEORDEN varchar(20), @KCNTID int, @MODOSELECCION smallint) 
returns @Resultado
	table (
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10),
		TIPOCONTRATO varchar(1),
		TIPOSISTEMA Varchar(12),
		IDTARIFA varchar(5),
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10),
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12),
		ESTADON varchar(12),
		ESTADOA varchar(8),		
		ESTADOS varchar(8),
		SEXO varchar(9),
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12), -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5), 
		Primary Key (KCNTID,KNEGID,PRIORIDAD,SECUENCIA,IDSERVICIO)
	)
as
begin
	declare @Tabla as dbo.KCNT_SerContratados;

	if @KCNTID>0
		-- Busca solo en el contrato suministrado
		if coalesce(@CLASEORDEN,'')='PyP'
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=@IDSERVICIO
				cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.KCNTID=@KCNTID and a.CLASEORDEN=@CLASEORDEN 		
		else
			-- Busca solo en el contrato suministrado
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=@IDSERVICIO
				cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.KCNTID=@KCNTID and a.CLASEORDEN<>'PyP'

	else
		-- Busca en todos los Contratos posibles
		if coalesce(@CLASEORDEN,'')='PyP'
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=@IDSERVICIO
				cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC and a.CLASEORDEN=@CLASEORDEN;	
		else
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=@IDSERVICIO
				cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC and a.CLASEORDEN<>'PyP';	
	-- Filtrado por PRIORIDAD de Contrato y SECUENCIA de negociación
	-- Actualiza Tercero al que se Cobra (IDTERCEROCA).
	insert into @Resultado
	select * from dbo.fnc_KCNT_SeleccionFinal(@IDSEDE,@IDAREA,@MODOSELECCION, @IDTERCERO, null, @Tabla)

	return;
end
go

/* Ayuda comentada para Clarion
!function dbo.fnc_KCNT_unPrefijo(
!    @IDSEDE varchar(5), @IDTERCERO varchar(20), @TIPOTTEC varchar(10), @IDAFILIADO varchar(20), @IDAREA varchar(20), @IDSERVICIOADM varchar(20), 
!    @PREFIJO varchar(6), @FECHA datetime, @KCNTID int, @MODOSELECCION smallint)
!
!   @KCNTID: 0 = Busca en todos los Contratos posibles, >0 = Busca solo en ese KCNTID Contrato
!   @MODOSELECCION: 1= Un servicio por cada contrato, 2 = Trae servicios repetidos de distintos contratos
*/
drop function dbo.fnc_KCNT_unPrefijo
go
create function dbo.fnc_KCNT_unPrefijo(
	@IDSEDE varchar(5), @IDTERCERO varchar(20), @TIPOTTEC varchar(10), @IDAFILIADO varchar(20), @IDAREA varchar(20), @IDSERVICIOADM varchar(20), 
	@PREFIJO varchar(6), @FECHA datetime, @KCNTID int, @MODOSELECCION smallint) 
returns @Resultado
	table (
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10),
		TIPOCONTRATO varchar(1),
		TIPOSISTEMA Varchar(12),
		IDTARIFA varchar(5),
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10),
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12),
		ESTADON varchar(12),
		ESTADOA varchar(8),		
		ESTADOS varchar(8),
		SEXO varchar(9),
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12), -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5), 
		Primary Key (KCNTID,KNEGID,PRIORIDAD,SECUENCIA,IDSERVICIO)
	)
as
begin
	declare @Tabla as dbo.KCNT_SerContratados;

	if @KCNTID>0
		-- Busca solo en el contrato suministrado
		insert into @Tabla
		select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
			x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
			VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
			a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
		from dbo.vwc_kcnt a with(nolock)
			cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
			cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
			left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
			cross apply dbo.fnc_TarifaPre(a.IDTARIFA,@PREFIJO,@FECHA) x1
			join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=x1.IDSERVICIO
			cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
		where a.KCNTID=@KCNTID 		
	else
		-- Busca en todos los Contratos posibles
		insert into @Tabla
		select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
			x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
			VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
			a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
		from dbo.vwc_kcnt a with(nolock)
			cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
			cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
			left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
			cross apply dbo.fnc_TarifaPre(a.IDTARIFA,@PREFIJO,@FECHA) x1
			join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=x1.IDSERVICIO
			cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
		where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC;	

	-- Filtrado por PRIORIDAD de Contrato y SECUENCIA de negociación
	-- Actualiza Tercero al que se Cobra (IDTERCEROCA).
	insert into @Resultado
	select * from dbo.fnc_KCNT_SeleccionFinal(@IDSEDE,@IDAREA,@MODOSELECCION, @IDTERCERO, null, @Tabla)

	return;
end
go

drop function dbo.fnc_KCNT_unPrefijo_ClaseOrden
go
create function dbo.fnc_KCNT_unPrefijo_ClaseOrden(
	@IDSEDE varchar(5), @IDTERCERO varchar(20), @TIPOTTEC varchar(10), @IDAFILIADO varchar(20), @IDAREA varchar(20), @IDSERVICIOADM varchar(20), 
	@PREFIJO varchar(6), @FECHA datetime, @CLASEORDEN varchar(20), @KCNTID int, @MODOSELECCION smallint) 
returns @Resultado
	table (
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10),
		TIPOCONTRATO varchar(1),
		TIPOSISTEMA Varchar(12),
		IDTARIFA varchar(5),
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10),
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12),
		ESTADON varchar(12),
		ESTADOA varchar(8),		
		ESTADOS varchar(8),
		SEXO varchar(9),
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12), -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5), 
		Primary Key (KCNTID,KNEGID,PRIORIDAD,SECUENCIA,IDSERVICIO)
	)
as
begin
	declare @Tabla as dbo.KCNT_SerContratados;

	if @KCNTID>0
		-- Busca solo en el contrato suministrado
		if coalesce(@CLASEORDEN,'')='PyP'
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				cross apply dbo.fnc_TarifaPre(a.IDTARIFA,@PREFIJO,@FECHA) x1
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=x1.IDSERVICIO
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.KCNTID=@KCNTID and a.CLASEORDEN=@CLASEORDEN		
		else
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				cross apply dbo.fnc_TarifaPre(a.IDTARIFA,@PREFIJO,@FECHA) x1
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=x1.IDSERVICIO
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.KCNTID=@KCNTID and a.CLASEORDEN<>'PyP'		

	else
		-- Busca en todos los Contratos posibles
		if coalesce(@CLASEORDEN,'')='PyP'
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				cross apply dbo.fnc_TarifaPre(a.IDTARIFA,@PREFIJO,@FECHA) x1
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=x1.IDSERVICIO
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC and a.CLASEORDEN=@CLASEORDEN;	
		else
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				cross apply dbo.fnc_TarifaPre(a.IDTARIFA,@PREFIJO,@FECHA) x1
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=x1.IDSERVICIO
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC and a.CLASEORDEN<>'PyP';	
		
	-- Filtrado por PRIORIDAD de Contrato y SECUENCIA de negociación
	-- Actualiza Tercero al que se Cobra (IDTERCEROCA).
	insert into @Resultado
	select * from dbo.fnc_KCNT_SeleccionFinal(@IDSEDE,@IDAREA,@MODOSELECCION, @IDTERCERO, null, @Tabla)

	return;
end
go

drop function dbo.fnc_KCNT_unaEspecialidad
go
create function dbo.fnc_KCNT_unaEspecialidad(
	@IDSEDE varchar(5), @IDTERCERO varchar(20), @TIPOTTEC varchar(10), @IDAFILIADO varchar(20), @IDAREA varchar(20), @IDSERVICIOADM varchar(20), 
	@IDEMEDICA varchar(4), @FECHA datetime, @KCNTID int, @MODOSELECCION smallint)
returns @Resultado
	table (
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10),
		TIPOCONTRATO varchar(1),
		TIPOSISTEMA Varchar(12),
		IDTARIFA varchar(5),
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10),
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12),
		ESTADON varchar(12),
		ESTADOA varchar(8),		
		ESTADOS varchar(8),
		SEXO varchar(9),
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12), -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5), 
		Primary Key (KCNTID,KNEGID,PRIORIDAD,SECUENCIA,IDSERVICIO)
	)
as
begin
	declare @Tabla as dbo.KCNT_SerContratados;

	if @KCNTID>0
		-- Busca solo en el contrato suministrado
		insert into @Tabla
		select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
			x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
			VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
			a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
		from dbo.vwc_kcnt a with(nolock)
			cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
			cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
			left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
			join dbo.MESS c with (nolock) on c.IDEMEDICA=@IDEMEDICA 
			join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID AND d.IDSERVICIO=c.IDSERVICIO and d.IDSERVICIOADM=@IDSERVICIOADM
			cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
			cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
		where a.KCNTID=@KCNTID 		
	else
		-- Busca en todos los Contratos posibles
		insert into @Tabla
		select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
			x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
			VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
			a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
		from dbo.vwc_kcnt a with(nolock)
			cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
			cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
			left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
			join dbo.MESS c with (nolock) on c.IDEMEDICA=@IDEMEDICA 
			join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID AND d.IDSERVICIO=c.IDSERVICIO and d.IDSERVICIOADM=@IDSERVICIOADM
			cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
			cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
		where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC;	

	-- Filtrado por PRIORIDAD de Contrato y SECUENCIA de negociación
	-- Actualiza Tercero al que se Cobra (IDTERCEROCA).
	insert into @Resultado
	select * from dbo.fnc_KCNT_SeleccionFinal(@IDSEDE,@IDAREA,@MODOSELECCION, @IDTERCERO, null, @Tabla)

	return;
end
go

drop function dbo.fnc_KCNT_unaEspecialidad_ClaseOrden
go
create function dbo.fnc_KCNT_unaEspecialidad_ClaseOrden(
	@IDSEDE varchar(5), @IDTERCERO varchar(20), @TIPOTTEC varchar(10), @IDAFILIADO varchar(20), @IDAREA varchar(20), @IDSERVICIOADM varchar(20), 
	@IDEMEDICA varchar(4), @FECHA datetime, @CLASEORDEN varchar(20), @KCNTID int, @MODOSELECCION smallint)
returns @Resultado
	table (
		KCNTID int,
		KNEGID int,
		PRIORIDAD int,
		SECUENCIA int,
		TIPOTTEC varchar(10),
		TIPOCONTRATO varchar(1),
		TIPOSISTEMA Varchar(12),
		IDTARIFA varchar(5),
		ITEM_TAR int,
		FACTOR_TAR float,
		REDONDEO_TAR varchar(10),
		VREDONDEO_TAR int,
		FACTOR float,
		COBRARA varchar(1),
		IDTERCEROCA varchar(20),
		IDSERVICIO varchar(20),
		VALOR decimal(22,6),
		VALOR_CALC decimal(22,6),
		REQAUTORIZACION smallint,
		PRESTXTERCEROS smallint, -- servicio prestado por un Tercero
		ESDEINV smallint,
		BDPROPIA smallint,
		ESTADOC varchar(12),
		ESTADON varchar(12),
		ESTADOA varchar(8),		
		ESTADOS varchar(8),
		SEXO varchar(9),
		NOCOBRABLE int,
		FACTURABLE int,
		ACCION varchar(12), -- Cobertura|Imprimir
		COBRARAKCNTID int,
		IDMODELOPCA VARCHAR(5), 
		Primary Key (KCNTID,KNEGID,PRIORIDAD,SECUENCIA,IDSERVICIO)
	)
as
begin
	declare @Tabla as dbo.KCNT_SerContratados;

	if @KCNTID>0
		-- Busca solo en el contrato suministrado
		if coalesce(@CLASEORDEN,'')='PyP'
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				join dbo.MESS c with (nolock) on c.IDEMEDICA=@IDEMEDICA 
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=c.IDSERVICIO
				cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.KCNTID=@KCNTID and a.CLASEORDEN=@CLASEORDEN		
		else
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				join dbo.MESS c with (nolock) on c.IDEMEDICA=@IDEMEDICA 
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=c.IDSERVICIO
				cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.KCNTID=@KCNTID and a.CLASEORDEN<>'PyP'		

	else
		-- Busca en todos los Contratos posibles
		if coalesce(@CLASEORDEN,'')='PyP'
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				join dbo.MESS c with (nolock) on c.IDEMEDICA=@IDEMEDICA 
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=c.IDSERVICIO
				cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC and a.CLASEORDEN=@CLASEORDEN;	
		else
			insert into @Tabla
			select a.KCNTID, a.KNEGID, a.PRIORIDAD, a.SECUENCIA, a.TIPOTTEC, a.TIPOCONTRATO, a.TIPOSISTEMA, a.IDTARIFA, ITEM_TAR=x1.ITEM, x1.FACTORDINERO, 
				x1.REDONDEO, x1.VREDONDEO, a.FACTOR, a.COBRARA, IDTERCEROCA=null, d.IDSERVICIO, x1.VALOR, 
				VALOR_CALC = round((x1.VALOR_CALC*a.FACTOR),x1.VREDONDEO), d.REQAUTORIZACION, d.PRESTXTERCEROS, d.ESDEINV, a.BDPROPIA, a.ESTADO_KCNT, 
				a.ESTADO_KNEG, e.ESTADOA, x1.ESTADO, x1.SEXO, a.NOCOBRABLE, a.FACTURABLE, ACCION='Cobertura',a.COBRARAKCNTID, a.IDMODELOPCA
			from dbo.vwc_kcnt a with(nolock)
				cross apply (select IDAREA from dbo.vwc_KCNT_Areas x with (nolock) where x.IDAREA=@IDAREA and a.KNEGID=x.KNEGID) x2
				cross apply (select IDSEDE from dbo.vwc_KCNT_Sedes x with (nolock) where x.IDSEDE=@IDSEDE and a.KNEGID=x.KNEGID) x3
				left join dbo.vwc_KCNT_BD b with (nolock) on a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A'
				join dbo.MESS c with (nolock) on c.IDEMEDICA=@IDEMEDICA 
				join dbo.vwc_KNEG_SER d with (nolock) on a.KNEGID=d.KNEGID and d.IDSERVICIOADM=@IDSERVICIOADM AND d.IDSERVICIO=c.IDSERVICIO
				cross apply dbo.fnc_TarifaSer(a.IDTARIFA,d.IDSERVICIO,@FECHA) x1
				cross apply (select ESTADOA = coalesce(b.ESTADO,case when a.BDPROPIA=1 then 'X' else 'A' end)) e
			where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and	a.TIPOTTEC=@TIPOTTEC and a.CLASEORDEN<>'PyP';	

	-- Filtrado por PRIORIDAD de Contrato y SECUENCIA de negociación
	-- Actualiza Tercero al que se Cobra (IDTERCEROCA).
	insert into @Resultado
	select * from dbo.fnc_KCNT_SeleccionFinal(@IDSEDE,@IDAREA,@MODOSELECCION, @IDTERCERO, null, @Tabla)
	
	return ;
end
go

/*
select * from dbo.fnc_KCNT_unServicioADM('01','812007194','IPS','','10','IMAT','14/12/2019',201,1)
select * from dbo.fnc_KCNT_unaEspecialidad('01','812007194','IPS','','10','IMAT','01','14/12/2019',0,1)
select * from dbo.fnc_KCNT_unPrefijo('01','812007194','IPS','','10','IMAT','700','14/12/2019',0,1)
select * from dbo.fnc_KCNT_unPrefijo('01','812007194','IPS','','10','IMAT','250','14/12/2019',0,1)
select * from dbo.fnc_KCNT_unPrefijo('01','812007194','IPS','','10','IMAT','100','14/12/2019',0,1) 
select * from dbo.fnc_KCNT_unServicio('01','812007194','IPS','','10','IMAT','860205C','14/12/2019',0,1) 

select * from dbo.fnc_KCNT_Contratos_xVigencia('ServicioADM','01','812007194','IPS','','10','IMAT','01','14/12/2019','',2);
select * from dbo.fnc_KCNT_Contratos_xVigencia('Especialidad','01','812007194','IPS','','10','IMAT','001','14/12/2019','',2);
select * from dbo.fnc_KCNT_Contratos_xVigencia('Prefijo','01','812007194','IPS','','10','IMAT','100','14/12/2019','',2);
select * from dbo.fnc_KCNT_Contratos_xVigencia('Servicio','01','812007194','IPS','','10','IMAT','860205C','14/12/2019','',2);

select * from dbo.fnc_KCNT_Contratos_xVigencia('Especialidad','01','812007194','IPS','','10','IMAT','004','14/12/2019','',2);

*/

-- Devuelve los contratos y su cobertura de atención especificada en los parámetros
drop Function dbo.fnc_KCNT_KCNTCA;
go
Create Function dbo.fnc_KCNT_KCNTCA(@KCNTID bigint)
returns varchar(max)
as
begin
	declare @Desc varchar(max);
			select @Desc =  coalesce(@Desc+char(13)+char(10)+c.CLASEATENCION+coalesce(', ('+e.DESCRIPCION+')',''),c.CLASEATENCION+coalesce(', ('+e.DESCRIPCION+')',''))
			from dbo.KCNTCA c with (nolock) 
				left join dbo.KCNTCAE d with (nolock) on c.KCNTCAID=d.KCNTCAID
				left join dbo.MES e with (nolock) on d.IDEMEDICA=e.IDEMEDICA
			where c.KCNTID=@KCNTID
	return @Desc;
end
go

-- Devuelve los contratos y su cobertura de atención especificada en los parámetros
drop Function dbo.fnc_KCNT_Contratos_xVigencia;
go
Create Function dbo.fnc_KCNT_Contratos_xVigencia(
	@MODO varchar(20), @IDSEDE varchar(5), @IDTERCERO varchar(20), @TIPOTTEC varchar(10), @IDAFILIADO varchar(20), @IDAREA varchar(20), @IDSERVICIOADM varchar(20), 
	@IDSER varchar(20), @FECHA datetime, @CLASEORDEN varchar(20), @MODOSELECCION smallint) 
returns @Resultado table (
	KCNTID int,
	IDCONTRATO varchar(30),
	TIPOCONTRATOREGIMEN varchar(max),
	BDPROPIA smallint,
	ESTADOA varchar(8),
	KCNTCAID int, 
	CLASEATENCION varchar(max),
	KCNTCAEID int,
	IDEMEDICA varchar(4),
	MEDDESCRIPCION varchar(45),
	IDADMINISTRADORA_AFI varchar(20),
	NOMADMIN_AFI varchar(120) 
)
as
begin
	declare @ModoSeleccion_Ori smallint = @MODOSELECCION;
	declare @TKCNTID table (KCNTID int, ESTADOA varchar(8));

	if @MODOSELECCION=0
		set @MODOSELECCION = 1

	set @FECHA = cast(cast(@FECHA as date) as datetime);
	if @MODO='Admision'
	begin
		if @MODOSELECCION = 1
		begin
			-- Modo de seleccion automático, el paciente debe estar Activo en KCNTAF cuando BDPROPIA=1
			insert into @TKCNTID 
			select top 1 a.KCNTID, a.ESTADOA
			from (
				select a.KCNTID, ESTADOA = coalesce(b.ESTADO,'X'),
					P=Case TIPOCONTRATO 
						When 'C' Then 1
						When 'P' Then 2
						When 'E' then 3
						When 'N' then 4
						Else 5 
					end 
				from dbo.KCNT a with (nolock) 
					outer apply (
						-- Pacientes deben estar en BD
						select top (1) b.ESTADO 
						from KCNTAF b with (nolock) where a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A' 
					) b
				where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and a.TIPOTTEC=@TIPOTTEC
					and a.ESTADO='Activo' and ((coalesce(a.BDPROPIA,0)=1 and coalesce(b.ESTADO,'X')='A') or coalesce(a.BDPROPIA,0)=0)
			) a
			order by a.P
		end
		else
		if @MODOSELECCION = 2
		begin
			-- Modo de seleccion multicontratos
			insert into @TKCNTID 
			select a.KCNTID, ESTADOA = coalesce(b.ESTADO,'X') 
			from dbo.KCNT a with (nolock) 
				outer apply (
					-- Pacientes deben estar en BD
					select top (1) b.ESTADO 
					from KCNTAF b with (nolock) where a.KCNTID=b.KCNTID and b.IDAFILIADO=@IDAFILIADO and b.ESTADO='A' 
				) b
			where a.IDTERCERO=@IDTERCERO and @FECHA between a.FECHAINICIAL and a.FECHAFINAL and a.TIPOTTEC=@TIPOTTEC
				and a.ESTADO='Activo' -- and ((coalesce(a.BDPROPIA,0)=1 and coalesce(b.ESTADO,'X')='A') or coalesce(a.BDPROPIA,0)=0)
		end		
	end
	else
	if coalesce(@CLASEORDEN,'')='' 
	begin
		if @MODO='ServicioADM'
			insert into @TKCNTID select distinct KCNTID, ESTADOA 
			from dbo.fnc_KCNT_unServicioADM(@IDSEDE, @IDTERCERO, @TIPOTTEC, @IDAFILIADO, @IDAREA, @IDSERVICIOADM, @FECHA, 0, @MODOSELECCION) a
			where a.ESTADOC='Activo'
		else 
		if @MODO='Especialidad'
			insert into @TKCNTID select distinct KCNTID, ESTADOA
			from dbo.fnc_KCNT_unaEspecialidad(@IDSEDE, @IDTERCERO, @TIPOTTEC, @IDAFILIADO, @IDAREA, @IDSERVICIOADM, @IDSER, @FECHA, 0, @MODOSELECCION) a
			where a.ESTADOC='Activo'
		else 
		if @MODO='Prefijo'
			insert into @TKCNTID select distinct KCNTID, ESTADOA
			from dbo.fnc_KCNT_unPrefijo(@IDSEDE, @IDTERCERO, @TIPOTTEC, @IDAFILIADO, @IDAREA, @IDSERVICIOADM, @IDSER, @FECHA, 0, @MODOSELECCION) a
			where a.ESTADOC='Activo'
		else 
		if @MODO='Servicio'
			insert into @TKCNTID select distinct KCNTID, ESTADOA
			from dbo.fnc_KCNT_unServicio(@IDSEDE, @IDTERCERO, @TIPOTTEC, @IDAFILIADO, @IDAREA, @IDSERVICIOADM, @IDSER, @FECHA, 0, @MODOSELECCION) a
			where a.ESTADOC='Activo'
	end
	else
	begin
		if @MODO='ServicioADM'
			insert into @TKCNTID select distinct KCNTID, ESTADOA
			from dbo.fnc_KCNT_unServicioADM_ClaseOrden(@IDSEDE, @IDTERCERO, @TIPOTTEC, @IDAFILIADO, @IDAREA, @IDSERVICIOADM, @FECHA, @CLASEORDEN, 0, @MODOSELECCION) a
			where a.ESTADOC='Activo'
		else 
		if @MODO='Especialidad'
			insert into @TKCNTID select distinct KCNTID, ESTADOA
			from dbo.fnc_KCNT_unaEspecialidad_ClaseOrden(@IDSEDE, @IDTERCERO, @TIPOTTEC, @IDAFILIADO, @IDAREA, @IDSERVICIOADM, @IDSER, @FECHA, @CLASEORDEN, 0, @MODOSELECCION) a
			where a.ESTADOC='Activo'
		else 
		if @MODO='Prefijo'
			insert into @TKCNTID select distinct KCNTID, ESTADOA
			from dbo.fnc_KCNT_unPrefijo_ClaseOrden(@IDSEDE, @IDTERCERO, @TIPOTTEC, @IDAFILIADO, @IDAREA, @IDSERVICIOADM, @IDSER, @FECHA, @CLASEORDEN, 0, @MODOSELECCION) a
			where a.ESTADOC='Activo'
		else 
		if @MODO='Servicio'
			insert into @TKCNTID select distinct KCNTID, ESTADOA
			from dbo.fnc_KCNT_unServicio_ClaseOrden(@IDSEDE, @IDTERCERO, @TIPOTTEC, @IDAFILIADO, @IDAREA, @IDSERVICIOADM, @IDSER, @FECHA, @CLASEORDEN, 0, @MODOSELECCION) a
			where a.ESTADOC='Activo'
	end

	if (select count(*) from @TKCNTID)=0
		-- Sin Contratación configurada, no hay servicios contratados
		insert into @Resultado(KCNTID,TIPOCONTRATOREGIMEN) values (0,dbo.fnc_TipoContratoRegimen(null,null,null)) 
	else
	begin
		-- Hay contratación
		if @ModoSeleccion_Ori=0
		begin
			insert into @Resultado (KCNTID,IDCONTRATO,TIPOCONTRATOREGIMEN,BDPROPIA,ESTADOA,KCNTCAID,CLASEATENCION,KCNTCAEID,IDEMEDICA,MEDDESCRIPCION,IDADMINISTRADORA_AFI)
			select top (1) a.KCNTID, b.NUMCONTRATO, dbo.fnc_TipoContratoRegimen(b.TIPOCONTRATO, b.TIPOTTEC, b.TIPOSISTEMA), coalesce(b.BDPROPIA,0), a.ESTADOA,
				null, CLASEATENCION=dbo.fnc_KCNT_KCNTCA(a.KCNTID), null, null, null, b.IDADMINISTRADORA_AFI
			from @TKCNTID a 
				join dbo.KCNT b with (nolock) on a.KCNTID=b.KCNTID
				cross apply (
					select P=Case b.TIPOCONTRATO 
						When 'C' Then 1
						When 'P' Then 2
						When 'E' then 3
						When 'N' then 4
						Else 5 
					end 
				) p
			order by p.P
		end
		else
		begin
			insert into @Resultado (KCNTID,IDCONTRATO,TIPOCONTRATOREGIMEN,BDPROPIA,ESTADOA,KCNTCAID,CLASEATENCION,KCNTCAEID,IDEMEDICA,MEDDESCRIPCION,IDADMINISTRADORA_AFI,NOMADMIN_AFI)
			select a.KCNTID, b.NUMCONTRATO, dbo.fnc_TipoContratoRegimen(b.TIPOCONTRATO, b.TIPOTTEC, b.TIPOSISTEMA), coalesce(b.BDPROPIA,0), a.ESTADOA,
				null, CLASEATENCION=dbo.fnc_KCNT_KCNTCA(a.KCNTID), null, null, null, b.IDADMINISTRADORA_AFI, c.RAZONSOCIAL
			from @TKCNTID a 
				join dbo.KCNT b with(nolock) on a.KCNTID=b.KCNTID
				left join TER c with(nolock) on c.IDTERCERO=b.IDADMINISTRADORA_AFI
		end
	end
	return;
end
go

/*
select * from dbo.fnc_KCNT_Contratos_xVigencia('Especialidad','01','812007194','IPS','','10','IMAT','001','14/12/2019','',2);
select * from dbo.fnc_KCNT_Contratos_xVigencia('Admision','01','812007194','IPS','','10','IMAT','001','14/12/2019','',1);
*/

-- Devuelve la descripción del Tipo de Contrato y Regimen 
drop Function dbo.fnc_TipoContratoRegimen;
go
Create Function dbo.fnc_TipoContratoRegimen(@TIPOCONTRATO varchar(1), @TIPOTTEC varchar(10),  @TIPOSISTEMA Varchar(12)) 
returns varchar(max)
as
begin
	declare @TipoContratoRegimen varchar(max);
	if @TIPOCONTRATO='' set @TIPOCONTRATO = null;
	if @TIPOTTEC='' set @TIPOTTEC = null;
	if @TIPOSISTEMA='' set @TIPOSISTEMA = null;

	select @TipoContratoRegimen =
		Case @TIPOCONTRATO 
			When 'C' Then 'Capita'
			When 'P' Then 'PGP'
			When 'E' then 'Evento'
			When 'N' then 'No Cobertura'
			Else 'Sin TipoContrato' end + Coalesce(', '+@TIPOTTEC,', Sin TipoTercero')+':'+coalesce(@TIPOSISTEMA,'Sin Régimen') 

	return Coalesce(@TipoContratoRegimen,'Sin Contrato')
end
Go
-- Select dbo.fnc_TipoContratoRegimen(TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA),* From cit Where Not IDAFILIADO Is null

-- Tipo Contrato por Citas segun servicio: Aici0002.clw, Aici0040.clw, Aici0043.clw
drop  Function dbo.fnc_TipoContrato_CIT;
go
Create Function dbo.fnc_TipoContrato_CIT(@KCNTRID int) 
returns varchar(max)
as
begin
	declare @TipoContrato varchar(max);
	select @TipoContrato=
		Case a.TIPOCONTRATO 
			When 'C' Then 'Capita'+Coalesce(', '+c.TIPOSISTEMA,' TTEC?')
			When 'P' Then 'PGP'+Coalesce(', '+c.TIPOSISTEMA,' TTEC?') 
			When 'E' then 'Evento'+Coalesce(', '+c.TIPOSISTEMA,' TTEC?') 
			When 'N' then 'No Cobertura'+Coalesce(', '+c.TIPOSISTEMA,' TTEC?') 			
			Else 'No Válido'+Coalesce(', '+c.TIPOSISTEMA,' TTEC?') 
		End 
	from dbo.KCNT a with (nolock) 
		join dbo.KCNTR b with (nolock) on a.KCNTID=b.KCNTID and b.KCNTRID=@KCNTRID
		left join dbo.TTEC c with (nolock) on a.TIPOTTEC=c.TIPO
	return Coalesce(@TipoContrato,'Sin Contrato')
end
Go
-- Select dbo.fnc_TipoContrato_CIT(KCNTRID),* From cit Where Not IDAFILIADO Is null


/*
Create Function dbo.fnc_TipoContrato_CIT_xSER(@IDSERVICIO varchar(20), @FECHA datetime, @AFILIADO varchar(20), @IDTERCERO varchar(20))
returns varchar(max)
as
begin
	declare @TipoContrato varchar(max);
	Set @FECHA = Cast(Cast(@FECHA As Date) As DateTime);
	with mem1 as (
		select top (1) a1.TIPOCONTRATO, a1.TIPOTTEC, BD=Case when b1.KCNTID Is Null Then 0 Else 1 end
		from dbo.KCNT a1 With (NoLock)
			Left Join dbo.vwc_KCNT_BD b1 With (NoLock) On a1.KCNTID=b1.KCNTID and b1.IDAFILIADO=@AFILIADO And left(b1.ESTADO,1)='A'
		where a1.IDTERCERO=@IDTERCERO And @FECHA Between a1.FECHAINICIAL And a1.FECHAFINAL
		order by case a1.TIPOCONTRATO when 'C' then 1 When 'P' Then 2 when 'E' then 3 when 'N' then 4 else 5 end				
	)
	select @TipoContrato=
		Case TIPOCONTRATO 
			When 'C' then Case When BD=1 Then 'Capita'+Coalesce(', '+TIPOTTEC,' TTEC?') Else 'Capita sin BD' End
			When 'P' then Case When BD=1 Then 'PGP'+Coalesce(', '+TIPOTTEC,' TTEC?') Else 'PGP sin BD' End 
			When 'E' then 'Evento'+Coalesce(', '+TIPOTTEC,' TTEC?') 
			When 'N' then 'No Cobertura'+Coalesce(', '+TIPOTTEC,' TTEC?') 			
			Else 'No Válido' 
		End 
	from mem1
	return Coalesce(@TipoContrato,'Sin Contrato')
end
Go
*/
-- Select dbo.fnc_TipoContrato_CIT(KCNTRID),* From cit Where Not IDAFILIADO Is null


drop function dbo.fnc_TipoContrato_xAFI_KCNT
go
create function dbo.fnc_TipoContrato_xAFI_KCNT(@IDSEDE varchar(5), @IDTERCERO varchar(20), @IDAFILIADO varchar(20), @TIPOTTEC varchar(10), @FECHA datetime)
returns @fnc_Tabla 
	table (
		KCNTID int,
		KCNTRID int,
		IDCONTRATO varchar(30),
		DESCRIPCION varchar(100),
		TIPOCONTRATO varchar(1) 
	)
as
begin
	insert into @fnc_Tabla
	select distinct a.KCNTID, a1.KCNTRID, a1.IDCONTRATO, a.DESCRIPCION, a.TIPOCONTRATO
	from dbo.kcnt a
		join dbo.kcntr a1 on a.KCNTID=a1.KCNTID and a1.TIPOTTEC=@TIPOTTEC and a1.ESTADO='Activo'
		join dbo.kneg b on a.KCNTID=b.KCNTID and b.ESTADO='Activo'
		join dbo.vwc_KCNT_BD c on b.KCNTID=c.KCNTID and c.IDAFILIADO=@IDAFILIADO and left(c.ESTADO,1)='A'
		join dbo.vwc_KCNT_Sedes d on d.IDSEDE=@IDSEDE and d.KNEGID=b.KNEGID
	where a.IDTERCERO=@IDTERCERO and a.ESTADO='Activo' and a.TIPOCONTRATO='C'and @FECHA between a1.FECHAINICIAL and a1.FECHAFINAL
	union all 
	select distinct a.KCNTID, a1.KCNTRID, a1.IDCONTRATO, a.DESCRIPCION, a.TIPOCONTRATO
	from dbo.kcnt a
		join dbo.kcntr a1 on a.KCNTID=a1.KCNTID and a1.TIPOTTEC=@TIPOTTEC and a1.ESTADO='Activo'
		join dbo.kneg b on a.KCNTID=b.KCNTID and b.ESTADO='Activo'
		join dbo.vwc_KCNT_Sedes d on d.IDSEDE=@IDSEDE and d.KNEGID=b.KNEGID
	where a.IDTERCERO=@IDTERCERO and a.ESTADO='Activo' and a.TIPOCONTRATO='E' and @FECHA between a1.FECHAINICIAL and a1.FECHAFINAL;
	return
end
go

-- Tipo Contrato por Admision segun Prestaciones: 
-- Ahad0002.clw, Ahad0070.clw, Ahad0079.clw
-- Ahc0022.clw, Ahc0023.clw, Ahc0024.clw, Ahc0025.clw, Ahc0026.clw, Ahc0027.clw, Ahc0028.clw, Ahc0033.clw
drop  Function dbo.fnc_TipoContrato_HADM_xHPRED;
go
Create Function dbo.fnc_TipoContrato_HADM_xHPRED(@NOADMISION varchar(20), @IDAFILIADO varchar(20), @IDTERCERO varchar(20))
returns varchar(12)
as
begin
	declare @IDSEDE varchar(5), @TIPOTTEC varchar(10), @FECHA datetime, @TipoContrato varchar(12);
	
	select @IDSEDE=IDSEDE, @TIPOTTEC=TIPOTTEC, @FECHA=FECHA from HADM where NOADMISION=@NOADMISION;

	with mem1 as (
		select N=ROW_NUMBER() over (partition by a.noadmision order by case a.TIPOCONTRATO when 'E' then 1 when 'C' then 2 when 'N' then 3 else 4 end), 
			a.NOADMISION, 
			TIPOCONTRATO=coalesce(a.TIPOCONTRATO,coalesce((
				select top 1 TIPOCONTRATO
				from dbo.fnc_TipoContrato_xAFI_KCNT(@IDSEDE, @IDTERCERO, @IDAFILIADO, @TIPOTTEC, @FECHA) a
				order by case a.TIPOCONTRATO when 'C' then 1 when 'E' then 2 when 'N' then 3 else 4 end),'P')
			)
		from (
			select distinct a.NOADMISION, c.TIPOCONTRATO
			from hadm a 
				left join hpre b on a.NOADMISION=b.NOADMISION 
				left join hpred c on b.NOPRESTACION=c.NOPRESTACION
			where a.noadmision=@NOADMISION
		) a
	)
	select top 1 @TipoContrato=case TIPOCONTRATO when 'E' then 'Evento' when 'C' then 'Capitación' when 'N' then 'No Cobertura' when 'P' then 'Particular' else 'Sin definir' end 
	from mem1
	return @TipoContrato
end
Go

-- aici0013.clw
drop function dbo.fnc_KCNT_Contratos_xAfiliado
go
create function dbo.fnc_KCNT_Contratos_xAfiliado(@IDTERCERO varchar(20), @IDAFILIADO varchar(20), @TIPOTTEC varchar(10), @FECHA datetime)
returns @fnc_Tabla 
	table (
		KCNTID int,
		IDSERVICIOADM varchar(20),
		DESCSERVADM varchar(255),  
		IDCONTRATO varchar(30),
		DESCRIPCION varchar(100),
		TIPOCONTRATO varchar(1) 
	)
as
Begin
	-- TIPOCONTRATO: C=Capita, E=Evento, P=PGP, N=No Cobertura
	insert into @fnc_Tabla
	-- Contratos de Capita y PGP
	select distinct a.KCNTID, d.IDSERVICIOADM, e.DESCSERVICIO, a.IDCONTRATO, a.DESCRIPCION, a.TIPOCONTRATO
	from dbo.KCNT a With (NoLock)
		join dbo.KNEG b With (NoLock) On a.KCNTID=b.KCNTID and b.ESTADO='Activo'
		join dbo.vwc_KCNT_BD c With (NoLock) On b.KCNTID=c.KCNTID and c.IDAFILIADO=@IDAFILIADO and c.ESTADO='A'
		join (select distinct KNEGID,IDSERVICIOADM from dbo.vwc_KNEG_SER With (NoLock)) d on b.KNEGID=d.KNEGID
		join dbo.MAES e With (NoLock) On d.IDSERVICIOADM=e.IDSERVICIOADM 
	where a.IDTERCERO=@IDTERCERO and a.TIPOTTEC=@TIPOTTEC And a.ESTADO='Activo' 
		And a.TIPOCONTRATO In ('C','P') And @FECHA between a.FECHAINICIAL and a.FECHAFINAL
	union all 
	-- Todos los contratos que no son Capita o PGP
	select distinct a.KCNTID, d.IDSERVICIOADM, e.DESCSERVICIO, a.IDCONTRATO, a.DESCRIPCION, a.TIPOCONTRATO
	from dbo.KCNT a With (NoLock)
		join dbo.KNEG b With (NoLock) On a.KCNTID=b.KCNTID and b.ESTADO='Activo'
		join (select distinct KNEGID,IDSERVICIOADM from dbo.vwc_KNEG_SER With (NoLock)) d on b.KNEGID=d.KNEGID 
		join dbo.MAES e With (NoLock) On d.IDSERVICIOADM=e.IDSERVICIOADM 
	where a.IDTERCERO=@IDTERCERO and a.TIPOTTEC=@TIPOTTEC And a.ESTADO='Activo' 
		And Not a.TIPOCONTRATO In ('C','P') and @FECHA between a.FECHAINICIAL and a.FECHAFINAL;
	return
end
Go


-- Tipo Contrato segun prioridad de Contratacion
If Exists (Select name From sysobjects Where name='fnc_TipoContrato_HADM_KCNT')
	Drop Function dbo.fnc_TipoContrato_HADM_KCNT;
Go
/*
Create Function dbo.fnc_TipoContrato_HADM_KCNT(@NOADMISION varchar(20), @AFILIADO varchar(20), @IDTERCERO varchar(20))
returns varchar(50)
as
begin
	declare @TipoContrato varchar(12);
	with mem1 as (
		select N=ROW_NUMBER() over (partition by a.noadmision order by case a.TIPOCONTRATO when 'C' then 1 when 'E' then 2 when 'N' then 3 else 4 end), 
			a.NOADMISION, 
			TIPOCONTRATO=coalesce(a.TIPOCONTRATO,coalesce((
				select top 1 TIPOCONTRATO
				from dbo.KCNT a With (NoLock)
					join vwc_KCNT_BD b on a.KCNTID=b.KCNTID and left(b.ESTADO,1)='A'
				where a.IDTERCERO=@IDTERCERO and b.IDAFILIADO=@AFILIADO
				order by case a.TIPOCONTRATO when 'C' then 1 when 'E' then 2 when 'N' then 3 else 4 end),'P')
			)
		from (
			select distinct a.NOADMISION, c.TIPOCONTRATO
			from dbo.HADM a With (NoLock) 
				left join dbo.HPRE b With (NoLock) On a.NOADMISION=b.NOADMISION 
				left join dbo.HPRED c With (NoLock) on b.NOPRESTACION=c.NOPRESTACION
			where a.NOADMISION=@NOADMISION
		) a
	)
	select top 1 @TipoContrato=TIPOCONTRATO	from mem1
	return @TipoContrato
end
go
*/
