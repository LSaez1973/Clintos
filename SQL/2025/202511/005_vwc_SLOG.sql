CREATE NONCLUSTERED INDEX IDX_SLODG_IDSLOG ON [dbo].[SLOGD] ([IDSLOG]) INCLUDE ([ITEM],[CAMPO],[DATO_ANT],[DATO_NUE])
GO
CREATE NONCLUSTERED INDEX IDX_SLOGD_CAMPO ON [dbo].[SLOGD] ([CAMPO]) INCLUDE ([IDSLOG],[ITEM],[DATO_ANT],[DATO_NUE])
GO
CREATE NONCLUSTERED INDEX IDX_SLOG_TABLA ON [dbo].[SLOG] ([TABLA])
go

drop view if exists vwc_SLOG
go
Create view vwc_SLOG
as
select a.IDSLOG, a.FECHA, a.TABLA, OPERACION=a.OEPRACION, a.GRUPO, a.USUARIO, a.IDPROCEDIMIENTO, a.SYS_COMPUTERNAME,
	b.ITEM, b.CAMPO, b.DATO_ANT, b.DATO_NUE
from SLOG a with(nolock)
	join SLOGD b with(nolock) on b.IDSLOG=a.IDSLOG
go

-- Consulta de historial de cambio de Accesos
drop function if exists dbo.fnc_SLOG_HIS_USUSU_FECHAACCESO 
go
create function dbo.fnc_SLOG_HIS_USUSU_FECHAACCESO (@USUARIO varchar(12))
returns table as return (
	select l.FECHA, l.OPERACION, FECHA_ANT=cast(l.DATO_ANT as datetime), FECHA_NUE=cast(l.DATO_NUE as datetime), 
		USUARIOTRANS=l.USUARIO, NOMBREUSUARIO=u.NOMBRE, l.GRUPO, l.SYS_COMPUTERNAME, l.IDSLOG, l.ITEM 
	from vwc_SLOG l 
		cross apply (
			select u.USUARIO
			from SLOGD ld with(nolock)
				cross apply (select USUARIO = coalesce(ld.DATO_ANT,ld.DATO_NUE)) u
			where u.USUARIO = @USUARIO and ld.IDSLOG = l.IDSLOG and ld.ITEM = l.ITEM and ld.CAMPO='USUARIO'
			
		) ld
		left join USUSU u with(nolock) on u.USUARIO = l.USUARIO
	where TABLA='USUSU' and CAMPO='FECHAACCESO'
)
go

--select * from dbo.fnc_SLOG_HIS_USUSU_FECHAACCESO('agilis')

-- Consulta de historial de cambio de Perfiles
drop function if exists dbo.fnc_SLOG_HIS_USUSU_GRUPOS 
go
create function dbo.fnc_SLOG_HIS_USUSU_GRUPOS (@USUARIO varchar(12))
returns table as return (
	select l.FECHA, l.OPERACION, DATO_ANT=dbo.fna_Encripta(l.DATO_ANT,''), DATO_NUE=dbo.fna_Encripta(l.DATO_NUE,''), 
		USUARIOTRANS=l.USUARIO, NOMBREUSUARIO=u.NOMBRE, l.GRUPO, l.SYS_COMPUTERNAME, l.IDSLOG, l.ITEM 
	from vwc_SLOG l 
		cross apply (
			select u.USUARIO
			from SLOGD ld with(nolock)
				cross apply (select USUARIO = coalesce(ld.DATO_ANT,ld.DATO_NUE)) u
			where u.USUARIO = @USUARIO and ld.IDSLOG = l.IDSLOG and ld.ITEM = l.ITEM and ld.CAMPO='USUARIO'
			
		) ld
		left join USUSU u with(nolock) on u.USUARIO = l.USUARIO
	where TABLA='USUSU' and CAMPO='GRUPO'
)
go

-- Consulta de historial general de todos los campos
drop function if exists dbo.fnc_SLOG_HIS_USUSU
go
create function dbo.fnc_SLOG_HIS_USUSU (@USUARIO varchar(12))
returns table as return (
	select l.FECHA, l.OPERACION, l.CAMPO, l.DATO_ANT, l.DATO_NUE, 
		USUARIOTRANS=l.USUARIO, NOMBREUSUARIO=u.NOMBRE, l.GRUPO, l.SYS_COMPUTERNAME, l.IDSLOG, l.ITEM 
	from vwc_SLOG l 
		cross apply (
			select u.USUARIO
			from SLOGD ld with(nolock)
				cross apply (select USUARIO = coalesce(ld.DATO_ANT,ld.DATO_NUE)) u
			where u.USUARIO = @USUARIO and ld.IDSLOG = l.IDSLOG and ld.ITEM = l.ITEM and ld.CAMPO='USUARIO'
			
		) ld
		left join USUSU u with(nolock) on u.USUARIO = l.USUARIO
	where TABLA='USUSU' 
)
go

-- select * from dbo.fnc_SLOG_HIS_USUSU('agilis') order by fecha desc

-- Campos Nuevos USUSU
alter table USUSU add USUARIOCREACION varchar(12)
alter table USUSU add FECHACREACION datetime
alter table USUSU add FECHARETIRO datetime
alter table USUSU add FECHAACCESO datetime
go


drop Function if exists [dbo].[fna_segAccesoApp]
go
Create Function [dbo].[fna_segAccesoApp] ( 
	@Usuario varchar(12)
)
returns @fna_segAcceso table (idProcedimiento varchar(30), IdControl varchar(100), NombreControl varchar(80), Acceso smallint, ShowControl varchar(20), Tipo varchar(20))
as
begin
	declare 
		@Grupo varchar(8),
		@Acceso smallint,
		@ShowControl varchar(20),
		@ControlName varchar(100);
	 
	select @Grupo = dbo.fna_Encripta(Grupo,'') from USUSU with(nolock) where usuario=@Usuario

	if @Grupo='PPAL' or @Grupo in (select Codigo from tgen with(nolock) where tabla='SSAC' and Campo = 'USERADMIN')
	begin
		insert into @fna_segAcceso 
		select idprocedimiento='*Todos*', IdControl='*Todos*', NombreControl='*Acceso Admin a toda la aplicación*', 1, 'Enable', 'Admin'
		return;
	end
	else
	if @Grupo='PPAL' or @Grupo in (select Codigo from tgen where tabla='SSAC' and Campo = 'USERAUDIT')
	begin
		insert into @fna_segAcceso 
		select idprocedimiento='*Todos*', IdControl='*Todos*', NombreControl='*Acceso Auditor a toda la aplicación*', 1, 'Enable', 'Auditor'
		return;
	end

	insert into @fna_segAcceso 
	select a.idprocedimiento, a.IDCONTROL, NombreControl = a.DESCRIPCION, 
		Acceso=
		case when c.ACCESO is null then 
			case when b.PERMISO is null then
				case when coalesce(a.REQACCESO,0)=0 then 1 else 0 end
			else b.PERMISO end
		else c.ACCESO end,
		ShowControl=
		case when c.ACCESO is null then 
			case when b.PERMISO is null then
				case when coalesce(a.REQACCESO,0)=0 then coalesce(a.SHOWCONTROL,'Enable') else coalesce(a.SHOWCONTROL,'Hide') end
			else b.SHOWCONTROL end
		else c.SHOWCONTROL end,
		Tipo=
		case when c.ACCESO is null then 
			case when b.PERMISO is null then 'Control' else 'Grupo' end
		else 'Usuario' end
	from usproh a with(nolock)
		 left join ususu u with(nolock) on u.usuario=@Usuario
		 left join usgruh b with(nolock) on a.IDPROCEDIMIENTO=b.IDPROCEDIMIENTO and a.IDCONTROL=b.IDCONTROL and b.GRUPO=case when u.usuario is null then null else @Grupo end
		 left join ssac c with(nolock) on a.IDPROCEDIMIENTO=c.IDPROCEDIMIENTO and a.IDCONTROL=c.IDCONTROL and c.GRUPO=@Grupo and c.USUARIO=@Usuario
	return;
end
go

-- select * from dbo.fna_segAccesoApp ('AGILIS');
-- select * from dbo.fna_segAccesoApp ('AJULIOF');


