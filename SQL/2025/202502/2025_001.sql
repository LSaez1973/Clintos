-- 16.feb.2024
alter table TGEN add ESTADO varchar(12);
alter table TGEN add CONCATCODIGOYDESC tinyint;
go

/*
insert into USVGS(IDVARIABLE,DESCRIPCION,TP_VARIABLE,DATO)
values ('AFITIPODOC_VALMAXLON','Validar maxima longitud del documento por tipo en Afiliados','Alfanumerica',1);
go
-- select * from TGEN where tabla='AFI' and campo='TIPO_DOC'
update tgen set valor2=10 where CODIGO='CC' and tabla='AFI' and campo='TIPO_DOC';
update tgen set valor2=6 where CODIGO='CE' and tabla='AFI' and campo='TIPO_DOC'; 
update tgen set valor2=16 where CODIGO='CD' and tabla='AFI' and campo='TIPO_DOC';
update tgen set valor2=16 where CODIGO='PA' and tabla='AFI' and campo='TIPO_DOC';
update tgen set valor2=16 where CODIGO='SC' and tabla='AFI' and campo='TIPO_DOC';
update tgen set valor2=15 where CODIGO='PE' and tabla='AFI' and campo='TIPO_DOC';
update tgen set valor2=11 where CODIGO='RC' and tabla='AFI' and campo='TIPO_DOC';
update tgen set valor2=11 where CODIGO='TI' and tabla='AFI' and campo='TIPO_DOC';
update tgen set valor2=9 where CODIGO='CN' and tabla='AFI' and campo='TIPO_DOC';
update tgen set valor2=10 where CODIGO='AS' and tabla='AFI' and campo='TIPO_DOC';
update tgen set valor2=12 where CODIGO='MS' and tabla='AFI' and campo='TIPO_DOC';		
go
select dbo.fnk_ValorVariable('AFITIPODOC_VALMAXLON')
*/

drop Function [dbo].[fna_TGEN_CLARION_FROM]
go
Create Function [dbo].[fna_TGEN_CLARION_FROM](@TABLA varchar(15), @CAMPO varchar(20))  
returns varchar(max)  
as  
begin  
 declare @opciones varchar(max);  
 
 select @opciones = string_agg(DESCRIPCION+'|#'+CODIGO, '|') WITHIN GROUP ( ORDER by codigo)
 from (
	select CODIGO, DESCRIPCION
	from tgen with(nolock)
	where tabla=@TABLA and CAMPO=@CAMPO and coalesce(estado,'Activo')='Activo' and coalesce(CONCATCODIGOYDESC,0)=0
	union all
	select CODIGO, CODIGO+' - '+DESCRIPCION from tgen with(nolock)
	where tabla=@TABLA and CAMPO=@CAMPO and coalesce(estado,'Activo')='Activo' and coalesce(CONCATCODIGOYDESC,0)=1
 ) g
 
 return @opciones;
 /*
	Create Function [dbo].[fna_TGEN_CLARION_FROM](@TABLA varchar(15), @CAMPO varchar(20))  
	returns varchar(max)  
	as  
	begin  
		declare @opciones varchar(max);  
		select @opciones = coalesce(@opciones+'|'+DESCRIPCION+'|#'+CODIGO,DESCRIPCION+'|#'+CODIGO)  
		from tgen where tabla=@TABLA and CAMPO=@CAMPO  
		return @opciones;  
	end  
 */
end  
go

-- select * from tgen where tabla='afi'
-- select [dbo].[fna_TGEN_CLARION_FROM]('AFI','TIPO_DOC')
go
-- 22.feb.2024
-- alter table AFI add FECHACREACION datetime;
alter table AFI add USUARIOCREACION varchar(20);
alter table AFI add PCCREACION varchar(64);
go
-- 28.ago.2024
alter table CIT alter column FINALIDAD varchar(20);
alter table AFI alter column TIPODISCAPACIDAD varchar(10);
go
alter table AFI add FECHAACTUALIZA datetime;
alter table AFI add USUARIOACTUALIZA varchar(20);
alter table AFI add PCACTUALIZA varchar(64);
alter table afi alter column TIPOAFILIADO varchar(20)
go
alter table CIT add MODALIDADATE varchar(20);
go
-- 23.oct.2024
CREATE TABLE DBO.FTROFR (
	CNSFTR                VARCHAR(40)  NOT NULL , 
	N_FACTURA             VARCHAR(16)  NOT NULL , 
	ORIGENINGASIS         VARCHAR(20) , 
	VALORTOTAL            DECIMAL(14,2) 
);
ALTER TABLE FTROFR ADD CONSTRAINT FTROFRCNSFTRN_FACTURA PRIMARY KEY CLUSTERED (CNSFTR,N_FACTURA);
go        
ALTER TABLE FTROFR WITH NOCHECK ADD CONSTRAINT FK_FTROFR_FTROFRCNSFTRN_FACTURA FOREIGN KEY (CNSFTR )
 REFERENCES FTR ( CNSFCT )  ON UPDATE CASCADE  ON DELETE NO ACTION;
ALTER TABLE FTROFR CHECK CONSTRAINT FK_FTROFR_FTROFRCNSFTRN_FACTURA;
GO
create unique index idx_FTROFR_N_FACTURA on FTROFR (N_FACTURA,CNSFTR);
go
alter table FTR add ORIGENINGASIS VARCHAR(20);
go
-- ORIGENINGASIS se usará para identificar las factras de procedencia FINANCIERO de que ingreso de salud vienen (SALUD,CIR,CE)
alter table FTR disable trigger all;
update FTR set ORIGENINGASIS=PROCEDENCIA where ORIGENINGASIS is null;
alter table FTR enable trigger all;
go

-- 28.oct.2024
alter table SER add R2CODGRUPOSER varchar(20);
alter table SER add R2AMBITO varchar(20);
alter table SER add R2MODATENCION varchar(20);
go
alter table HADM alter column TIPOAFILIADO varchar(10) null;
go
-- 05.nov.2024
alter table CIT add IDT varchar(20);
alter table AUTD add IDT varchar(20);
go

CREATE NONCLUSTERED INDEX idx_HPRED_FACTURABLE_IDT ON [dbo].[HPRED] ([FACTURABLE],[IDT]) INCLUDE ([IDSERVICIO]) 
with(online=on);
GO
CREATE NONCLUSTERED INDEX idx_AUTD_FACTURABLE_IDT ON [dbo].[AUTD] ([FACTURABLE],[IDT]) INCLUDE ([IDSERVICIO]) 
with(online=on);
GO
CREATE NONCLUSTERED INDEX idx_CIT_FACTURABLE_IDT ON [dbo].[CIT] ([FACTURABLE],[IDT]) INCLUDE ([IDSERVICIO]) 
with(online=on);
GO
-- 03:24

alter table ftrd disable trigger all
go
-- 27.nov.2024
alter table FTRD add 
	ORIGEN varchar(20),
	PRESTACIONID int,
	FTRDID int identity not null;
go

alter table ftrd enable trigger all
go
-- 05:21 

alter table FMAS add
	INVESTIGACION bit,
	OBSINVESTIGACION varchar(max);
go

CREATE NONCLUSTERED INDEX idx_FTRD_FTRDID ON FTRD (FTRDID) with(online=on);
CREATE NONCLUSTERED INDEX idx_FTRD_ORIGEN ON FTRD (ORIGEN,PRESTACIONID) include(FTRDID) with(online=on);
GO

-- 02.dic.2024
alter table HPRED add CIVA bit;
alter table HPRED add PIVA decimal(14,5);
alter table HPRED add VIVA decimal(14,2);
alter table HPRED add VALORCONIVA decimal(14,2);
alter table CIT add CIVA bit;
alter table CIT add PIVA decimal(14,5);
alter table CIT add VIVA decimal(14,2);
alter table CIT add VALORCONIVA decimal(14,2);
alter table AUTD add CIVA bit;
alter table AUTD add PIVA decimal(14,5);
alter table AUTD add VIVA decimal(14,2);
alter table AUTD add VALORCONIVA decimal(14,2);
go
alter table FMASD add CODANONIMIZADO varchar(20)
go
delete dep where DPTO='_';
delete CIU where DPTO='_';
update DEP set IDPAIS='COL' where IDPAIS is null
go

alter table RENR alter column AMBITO varchar(10);
alter table RENR alter column VIAINGRESO varchar(10);
alter table RENR alter column CAUSAEXT varchar(10);
go

drop function if exists fnc_PorcentajesIMP
go
Create function fnc_PorcentajesIMP(@IDIMPUESTO varchar(4), @FECHA datetime)
returns table as return (
	select a.*, b.*
	from FIMPD a
		cross apply (
			select top 1 PORCENTAJE=b.VALOR
			from FIMPDV b
			where a.IDIMPUESTO=b.IDIMPUESTO and a.IDCLASE=b.IDCLASE and b.FECHAINI<=@FECHA order by FECHAINI desc
		) b
	where a.IDIMPUESTO=@IDIMPUESTO
)
go
-- select * from fnc_PorcentajesIMP('IVA',getdate()) order by PORCENTAJE desc
go

drop Procedure spc_TER_InsertFromAsistencial
go
-- Create by LSaez.22.Mar.2018
Create Procedure dbo.spc_TER_InsertFromAsistencial
	@TABLA varchar(20),		-- Nombre de la tabla del origen del tercero ('AFI','AFIRC')
	@IDTERCERO varchar(20),	-- La id del nuevo tercero, cuando @TABLA='AFIRC' viene el valor de AFIRCID
	@CLIENTE bit=0	-- Crea el tercero con la categoria TERCATCLIENTE
as
Begin
	declare @Datos table (
		IDTERCERO varchar(20) null, 
		RAZONSOCIAL varchar(120) null, 
		NIT varchar(20) null, 
		DV varchar(1) null, 
		TIPO_ID varchar(3) null, 
		DIRECCION varchar(60) null, 
		CIUDAD varchar(5) null, 
		TELEFONOS varchar(35) null, 
		ESTADO varchar(10) null, 
		ENVIODICAJA smallint null,
		MODOCOPAGO varchar(6) null,
		DIASVTO smallint null,
		ESEXTRANJERO smallint null, 
		EMAIL varchar(200) null, -- El de la tabla TER tiene 200 caracteres
		PRIMERAPELLIDO varchar(50) null, 
		SEGUNDOAPELLIDO varchar(50) null, 
		PRIMERNOMBRE varchar(50) null, 
		SEGUNDONOMBRE varchar(50) null,
		ZONAPOSTAL varchar(10) Null,
		NATJURIDICA	Varchar(11) null
	);
	declare 
		@TERCATCLIENTE varchar(20) = dbo.FNK_VALORVARIABLE('TERCATCLIENTE'),
		@IDTERCONTABLEPART varchar(20) = dbo.FNK_VALORVARIABLE('IDTERCONTABLEPART');

	set nocount on;
	begin try
		begin tran		
		if @TABLA='AFI'
		begin
			-- El Tercero se saca del Afiliado
			insert into @Datos
			SELECT DOCIDAFILIADO, 
				RAZONSOCIAL=replace(ltrim(rtrim(PAPELLIDO))+' '+ltrim(rtrim(coalesce(SAPELLIDO,'')))+' '+ltrim(rtrim(PNOMBRE))+' '+ltrim(rtrim(coalesce(SNOMBRE,''))),'  ',' '), 
				IDAFILIADO, DV='', TIPO_ID=TIPO_DOC, DIRECCION=left(DIRECCION,60), CIUDAD, TELEFONORES, 'Activo', 1, 'Normal', 0, 0, EMAIL,
				PAPELLIDO, SAPELLIDO, PNOMBRE, SNOMBRE, ZONAPOSTAL, 'Natural'
			FROM dbo.AFI with (nolock) WHERE IDAFILIADO = @IDTERCERO
		end
		else
		if @TABLA='AFIRC'
		begin
			-- El Tercero se saca del Responsable del Afiliado, (Ej. para menores de edad)
			insert into @Datos
			SELECT IDTERCERO, RAZONSOCIAL, IDTERCERO, DV='', TIPO_ID=TIPO_DOC, DIRECCION=left(DIRECCION,60), CIUDAD, TELEFONOS, 'Activo', 1, 'Normal', 0, 0, EMAIL,
				coalesce(PAPELLIDO,'nulo'), coalesce(SAPELLIDO,'nulo'), coalesce(PNOMBRE,'nulo'), coalesce(SNOMBRE,'nulo'), ZONAPOSTAL, NATJURIDICA
			FROM dbo.AFIRC with (nolock) WHERE AFIRCID = @IDTERCERO
		end

		--select * from @Datos

		MERGE dbo.TER AS t  
		USING @Datos s ON t.IDTERCERO = s.IDTERCERO
		WHEN MATCHED THEN  
			UPDATE 
			SET RAZONSOCIAL=s.RAZONSOCIAL, DIRECCION=s.DIRECCION, CIUDAD=s.CIUDAD, TELEFONOS=s.TELEFONOS, 
				EMAIL=s.EMAIL, PRIMERAPELLIDO=s.PRIMERAPELLIDO, SEGUNDOAPELLIDO=s.SEGUNDOAPELLIDO, 
				PRIMERNOMBRE=s.PRIMERNOMBRE, SEGUNDONOMBRE=s.SEGUNDONOMBRE, ZONAPOSTAL=s.ZONAPOSTAL, NATJURIDICA=coalesce(t.NATJURIDICA,s.NATJURIDICA),
				TIPOREGIMEN=coalesce(t.TIPOREGIMEN,'S'), ACT_ECONOMICA=coalesce(t.ACT_ECONOMICA,'0090'), IDACTIVIDAD=coalesce(t.ACT_ECONOMICA,'0090'), 
				F_INSCRIPTO=coalesce(t.F_INSCRIPTO,dbo.fnk_fecha_sin_mls(getdate()))
		WHEN NOT MATCHED THEN  
			INSERT (IDTERCERO, RAZONSOCIAL, NIT, DV, TIPO_ID, DIRECCION, CIUDAD, TELEFONOS, ESTADO, ENVIODICAJA, MODOCOPAGO, DIASVTO, 
				ESEXTRANJERO, EMAIL, PRIMERAPELLIDO, SEGUNDOAPELLIDO, PRIMERNOMBRE, SEGUNDONOMBRE, ZONAPOSTAL, NATJURIDICA, 
				TIPOREGIMEN, ACT_ECONOMICA, IDACTIVIDAD, F_INSCRIPTO)  
			VALUES (IDTERCERO, RAZONSOCIAL, NIT, DV, TIPO_ID, DIRECCION, CIUDAD, TELEFONOS, ESTADO, ENVIODICAJA, MODOCOPAGO, DIASVTO, 
				ESEXTRANJERO, EMAIL, PRIMERAPELLIDO, SEGUNDOAPELLIDO, PRIMERNOMBRE, SEGUNDONOMBRE, ZONAPOSTAL, NATJURIDICA, 
				'S', '0090', '0090', dbo.fnk_fecha_sin_mls(getdate())
			); 

		-- Inserta código de responsdabilidad fiscal por default.
		Insert Into dbo.TERRF (IDTERCERO, CODRESPONSABILIDAD, FECHA, ESTADO)
		Select  a.IDTERCERO, b.CODRESPONSABILIDAD , dbo.FNK_FECHA_SIN_MLS(GetDate()), 'A'
		From @Datos a 
			Cross Apply (Select CODRESPONSABILIDAD = dbo.FNK_VALORVARIABLE('TER_CODTERRF')) b
			Join dbo.TGEN c With (NoLock) On c.TABLA='TERRF' And c.CAMPO='CODRESPONSABILIDAD' And c.CODIGO=b.CODRESPONSABILIDAD
			Left Join dbo.TERRF d With (NoLock) On a.IDTERCERO=d.IDTERCERO And b.CODRESPONSABILIDAD=d.CODRESPONSABILIDAD
		Where d.CODRESPONSABILIDAD Is null;

		if @CLIENTE=1
		begin
			-- Lo agrega como categoría Cliente, si aun no la tiene 
			insert into TEXCA(IDTERCERO,IDCATEGORIA,ESTADO)
			select IDTERCERO=d.IDTERCERO, IDCATEGORIA=@TERCATCLIENTE, ESTADO='Activo'
			from @Datos d
			where not d.IDTERCERO in (select a.IDTERCERO from TEXCA a with(nolock) where a.IDTERCERO=d.IDTERCERO and a.IDCATEGORIA=@TERCATCLIENTE)
			
			-- Lo agrega como tipo de tercero Particular, sino tiene alguno
			insert into TERTTEC(IDTERCERO,TIPOTTEC)
			select IDTERCERO=d.IDTERCERO, TIPOTTEC=@IDTERCONTABLEPART
			from @Datos d
			where not d.IDTERCERO in (select a.IDTERCERO from TERTTEC a with(nolock) where a.IDTERCERO=d.IDTERCERO /*and a.TIPOTTEC=@IDTERCONTABLEPART*/)
		end

		if (@@TRANCOUNT>0)
			commit
	end try
	begin catch				
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;  				
		select   
			@ErrorMessage = 'Error al ejecutar spc_TER_InsertFromAsistencial:'+char(13)+char(10)+coalesce(ERROR_MESSAGE(),'(desconocido)'),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE();
		if (@@TRANCOUNT>0)	 
			rollback transaction;
		raiserror(@ErrorMessage,@ErrorSeverity,@ErrorState);
	end catch
end
go

-----------------------------
