-- Campos CIE11
alter table HADM add DXINGRESO_CIE11 bigint;
alter table HADM add DXEGRESO_CIE11 bigint;
alter table HADM add DXSALIDA1_CIE11 bigint;
alter table HADM add DXSALIDA2_CIE11 bigint;
alter table HADM add DXSALIDA3_CIE11 bigint;
alter table HCA add IDDX_CIE11 bigint;
alter table HCA add DX1_CIE11 bigint;
alter table HCA add DX2_CIE11 bigint;
alter table HCA add DX3_CIE11 bigint;
alter table HRED add IDDX_CIE11 bigint;
alter table HRED add DX1_CIE11 bigint;
alter table HRED add DX2_CIE11 bigint;
alter table HRED add DX3_CIE11 bigint;
alter table IME add IDDX_CIE11 bigint;
alter table IME add IDDX1_CIE11 bigint;
go
alter table HADM add CAUSAMUERTE_CIE11 bigint;
alter table HADM add COMPLICACION_CIE11 bigint;
go


drop table if exists [dbo].[DXCIE11TMP]
go
CREATE TABLE [dbo].[DXCIE11TMP](
	[IDCIE11] [bigint] IDENTITY(1,1) NOT NULL,
	[FECHAREGISTRO] [datetime] NULL,
	[NOMBRETABLA] [varchar](20) NULL,
	[NOMBRECAMPO] [varchar](20) NULL,
	[CONSECUTIVO] [varchar](20) NULL,
	[CODIGODX] [varchar](30) NULL,
	[CLUSTERDX] [varchar](256) NULL,
	[TITULODX] [varchar](300) NULL,
	[URLDX] [varchar](1200) NULL,
	[COINCIDENCIADX] [varchar](255) NULL,
	[ESTADODX] [int] NULL,
 CONSTRAINT [PK_DXCIE11TMP_IDCIE11] PRIMARY KEY CLUSTERED 
(
	[IDCIE11] ASC
)
) ON [PRIMARY]
GO

EXEC sys.sp_addextendedproperty @name=N'MS_Description', @value=N'Tabla temporal para intercambio de información Dx CIE11' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'TABLE',@level1name=N'DXCIE11TMP'
GO

drop procedure if exists spc_gen_ID_REGISTRO_CIE11;
go
create procedure spc_gen_ID_REGISTRO_CIE11
	@TABLA varchar(64),
	@CAMPO varchar(64)
as
begin
	declare 
		@newID bigint;

	insert into DXCIE11TMP(FECHAREGISTRO,NOMBRETABLA,NOMBRECAMPO)
	values (dbo.fnk_fecha_sin_mls(getdate()), @TABLA, @CAMPO);
	
	select SCOPE_IDENTITY() as IDCIE11;
	
end
go

-- exec spc_gen_ID_REGISTRO_CIE11 'HADM','DXINGRESO_CIE11';

drop function if exists dbo.fnc_get_ID_REGISTRO_CIE11 
go
create function dbo.fnc_get_ID_REGISTRO_CIE11 (@IDCIE11 bigint)
returns table as return (
	select CODIGODX, TITULODX, CLUSTERDX, URLDX, COINCIDENCIADX, ESTADODX 
	from dbo.DXCIE11TMP with(nolock) where IDCIE11=@IDCIE11
)
go

-- select * from fnc_get_ID_REGISTRO_CIE11(14)

drop procedure if exists spc_set_CONSECUTIVO_CIE11;
go
create procedure spc_set_CONSECUTIVO_CIE11
	@IDCIE11 bigint,
	@CONSECUTIVO varchar(20)
as
begin
	update dbo.DXCIE11TMP set CONSECUTIVO=@CONSECUTIVO where IDCIE11=@IDCIE11;
end
go


