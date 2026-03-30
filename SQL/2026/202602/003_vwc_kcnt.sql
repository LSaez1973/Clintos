/*
--------------------------------------------------------
-- Vitácora de cambios, orden cronologico descendente --
--------------------------------------------------------

-- 05.02.2026: Todos los servicios ahora son FACTURABLE=1
vwc_kcnt_Capitado
vwc_kcnt_Evento
vwc_kcnt_PGP
vwc_kcnt_NoCobertura
vwc_kcnt
-- Fin vitácora --
*/

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


