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

drop Trigger if exists dbo.trc_MutualSer_HADM
go
Create Trigger dbo.trc_MutualSer_HADM
on HADM for insert,update
as
	return;
	/*
	declare 
		@IDTERCERO_MS varchar(20)='806008394',
		@IDTERCERO_UT varchar(20)='901441501';

	-- Union Temporal con Mutual Ser 
	if (select count(*) from inserted where IDTERCERO=@IDTERCERO_UT and FECHA<'01/01/2021') > 0
	begin
		raiserror ('NOTIFICACION: No se permiten admisiones para Union Temporal de fechas menores al 1 de enero de 2021.',16,1);
		rollback;
	end
	*/
go


drop trigger if exists tk_HADM_ALTA;
go
drop Trigger [dbo].[tra_HADM_Cierre]
go
-- Inventario: Clintos->DxZF
-- *Contiene consulta unida de movimientos de ambas BD 
Create Trigger [dbo].[tra_HADM_Cierre]
on [dbo].[HADM] for update
as
begin
	set nocount on;
	
	if update(CERRADA) 
	begin

		if (select count(*) from inserted where CERRADA in (0,1))>1  
		begin  
			raiserror('Masivamente NO está permitido Pasar a Abierta o Alta Médica el campo CERRADA de Admisiones.',16,1);  
			rollback transaction;  
			return;  
		end  

		if (select count(*)
			from inserted a join HHAB b with(nolock) on a.NOADMISION=b.NOADMISION
			where a.CERRADA=1) > 0
			begin
				raiserror('CAMA OCUPADA: Antes de dar Alta Administrativa, el paciente debe haber desocupado la cama asignada.',16,1);
				rollback
				return
			end
		end

		if update(IDAFILIADO) 
		begin  
			if (
				select top (1) Cant 
				from (
					select a.CLASEING,Cant=count(*) 
					from HADM a with (nolock) 
						join inserted b on a.IDAFILIADO=b.IDAFILIADO   
					where a.CLASEING in ('A','M') and a.CERRADA=0 and b.CERRADA=0 
					group by a.CLASEING
				) h
				order by Cant desc
			) > 1  
			begin  
				raiserror('No está permitido tener mas de una Admisión Hospitalaria o Ambulatoria en estado Abierta del mismo paciente.',16,1);  
				rollback transaction;  
				return;  
			end  
		end  

		if (select dbo.FNK_VALORVARIABLE('PALTASINCONF'))='SI' -- deja dar alta sin verificar pendients en inventario
			return;

		if (select count(*) from inserted)>1
		begin
			raiserror('No es posible actualizar el campo CERRADA de la Admisión en mas de un registro con una sola instrucción SQL.',16,1);
			rollback;
			return;
		end

		declare
			@NoAdmision varchar(20),
			@Cerrada smallint,
			@deff varchar(max) = char(13)+char(10)+char(13)+char(10)+char(9)+cast('TIPO MOVIMIENTO' as char(34))+'CANTIDAD' + char(13)+char(10),
			@mess varchar(max);
		set  @mess=@deff;
		select @NoAdmision=NOADMISION, @Cerrada=CERRADA from inserted
		if (@Cerrada=1) -- La admisión pasa a Alta Administrativa (CERRADA=1)
		begin
			-- DxZF
			select @mess = @mess + char(9)+cast(DESCRIPCION as char(30)) + str(IMOV) + char(13)+char(10)
			from (
				select c.DESCRIPCION, IMOV=count(*) 
				from DxZF.dbo.IMOVSS a with(nolock)
					join DxZF.dbo.IMOV m with(nolock) on a.IDTRANSACCION=m.IDTRANSACCION and a.NUMDOCUMENTO=m.NUMDOCUMENTO 
						and a.PROCEDENCIA like '%SALUD'
					join HPRE b with(nolock) on a.NOPRESTACION collate database_default = b.NOPRESTACION 
					join ITMO c with(nolock) on m.IDTIPOMOV collate database_default = c.IDTIPOMOV
				where m.ESTADO='0' and b.NOADMISION=@NoAdmision
				group by c.DESCRIPCION
			) a
			if @mess<>@deff
			begin
				set @mess = @mess + char(13)+char(10);
				raiserror('La Admisión tiene Movimientos pendiente por confirmar en Suminstros.: %s',16,1,@mess);
				rollback
				return			
			end

			-- Inv.Asistencial
			select @mess = @mess + char(9)+cast(DESCRIPCION as char(30)) + str(IMOV) + char(13)+char(10)
			from (
				select c.DESCRIPCION, IMOV=count(*) 
				from IMOV a with(nolock)
					join HPRE b with(nolock) on a.NOPRESTACION=b.NOPRESTACION
					join ITMO c with(nolock) on a.IDTIPOMOV=c.IDTIPOMOV
				where a.ESTADO='0' and b.NOADMISION=@NoAdmision and coalesce(a.PROCESO,'')<>'DOXA_PR'
				group by c.DESCRIPCION
			) a
			if @mess<>@deff
			begin
				set @mess = @mess + char(13)+char(10);
				raiserror('La Admisión tiene Movimientos pendiente por confirmar en Suminstros (Inv.Asistencial).: %s',16,1,@mess);
				rollback
				return			
			end
		end 
	end
end
go

/*
Create Trigger [dbo].[tra_HADM_Cierre]  
on [dbo].[HADM] for update  
as  
begin  
 set nocount on;  
   
 if update(CERRADA)   
 begin  
  if (select dbo.FNK_VALORVARIABLE('PALTASINCONF'))='SI' -- deja dar alta sin verificar pendients en inventario  
   return;  
  
  if (select count(*) from inserted)>1  
  begin  
   raiserror('No es posible actualizar el campo CERRADA de la Admisión en mas de un registro con una sola instrucción SQL.',16,1);  
   rollback;  
   return;  
  end  
  
  declare  
   @NoAdmision varchar(20),  
   @Cerrada smallint,  
   @deff varchar(max) = char(13)+char(10)+char(13)+char(10)+char(9)+cast('TIPO MOVIMIENTO' as char(34))+'CANTIDAD' + char(13)+char(10),  
   @mess varchar(max);  
  set  @mess=@deff;  
  select @NoAdmision=NOADMISION, @Cerrada=CERRADA from inserted  
  if (@Cerrada=1) -- La admisión pasa a Alta Administrativa (CERRADA=1)  
  begin  
   -- DxContable  
   select @mess = @mess + char(9)+cast(DESCRIPCION as char(30)) + str(IMOV) + char(13)+char(10)  
   from (  
    select c.DESCRIPCION, IMOV=count(*)   
    from DxZF.dbo.IMOVSS a with(nolock)  
     join DxZF.dbo.IMOV m with(nolock) on a.IDTRANSACCION=m.IDTRANSACCION and a.NUMDOCUMENTO=m.NUMDOCUMENTO   
      and a.PROCEDENCIA like '%SALUD'  
     join HPRE b with(nolock) on a.NOPRESTACION = b.NOPRESTACION collate SQL_1xCompat_CP850_CI_AS  
     join ITMO c with(nolock) on m.IDTIPOMOV = c.IDTIPOMOV collate SQL_1xCompat_CP850_CI_AS  
    where m.ESTADO='0' and b.NOADMISION=@NoAdmision  
    group by c.DESCRIPCION  
   ) a  
   if @mess<>@deff  
   begin  
    set @mess = @mess + char(13)+char(10);  
    raiserror('La Admisión tiene Movimientos pendiente por confirmar en Suminstros.: %s',16,1,@mess);  
    rollback  
    return     
   end  
  
   -- Inv.Asistencial  
   select @mess = @mess + char(9)+cast(DESCRIPCION as char(30)) + str(IMOV) + char(13)+char(10)  
   from (  
    select c.DESCRIPCION, IMOV=count(*)   
    from IMOV a with(nolock)  
     join HPRE b with(nolock) on a.NOPRESTACION=b.NOPRESTACION  
     join ITMO c with(nolock) on a.IDTIPOMOV=c.IDTIPOMOV  
    where a.ESTADO='0' and b.NOADMISION=@NoAdmision and coalesce(a.PROCESO,'')<>'DOXA_PR'  
    group by c.DESCRIPCION  
   ) a  
   if @mess<>@deff  
   begin  
    set @mess = @mess + char(13)+char(10);  
    raiserror('La Admisión tiene Movimientos pendiente por confirmar en Suminstros (Inv.Asistencial).: %s',16,1,@mess);  
    rollback  
    return     
   end  
  end   
 end  
end  
*/

drop Procedure dbo.spc_TER_InsertFromAsistencial
go
-- Create by LSaez.22.Mar.2018  
Create Procedure dbo.spc_TER_InsertFromAsistencial  
 @TABLA varchar(20),  -- Nombre de la tabla del origen del tercero ('AFI','AFIRC')  
 @IDTERCERO varchar(20), -- La id del nuevo tercero, cuando @TABLA='AFIRC' viene el valor de AFIRCID  
 @CLIENTE bit=0 -- Crea el tercero con la categoria TERCATCLIENTE  
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
  NATJURIDICA Varchar(11) null  
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

drop View if exists vwc_INV_VentasPacientes_HPRED
go
Create View vwc_INV_VentasPacientes_HPRED with schemabinding
as
	select IDARTICULO=b.IDARTICULO collate database_default, 
		NOLOTE=b.IDARTICULO collate database_default, UBICACION=b.IDARTICULO collate database_default, b.FECHAVENCE,
		b.CANTIDAD, DEVOLUCIONES=coalesce(b.DEVOLUCIONES,0), DISPONIBLES=b.CANTIDAD-coalesce(b.DEVOLUCIONES,0), 
		PROCEDENCIA=a.PROCEDENCIA collate database_default, e.NOADMISION, NOPRESTACION=a.NOPRESTACION collate database_default, 
		b.HPREDID, d.IDSERVICIO, f.DESCSERVICIO, CNSMOV=a.CNSMOV collate database_default, b.IMOVHID, b.ITEM,   
		a.FECHACONF, e.USUARIO, d.FACTURADA, b.PCOSTO, a.IDBODEGA   
	from dbo.IMOVH b    
		join dbo.IMOV a on b.CNSMOV=a.CNSMOV and b.ESTADO=1 and b.CANTIDAD>0 
			and a.PROCEDENCIA in ('SALUD','CE','QXCX','QXPRO','PYP')
			and a.ESTADO='1' and a.TIPOVENTA=1  and coalesce(a.PROCESO,'')<>'DOXA_PR'   
		join dbo.HPRED d on d.HPREDID=b.HPREDID  
		join dbo.HPRE e on d.NOPRESTACION=e.NOPRESTACION  
		join dbo.SER f on d.IDSERVICIO=f.IDSERVICIO  
go
create unique clustered index vwc_INV_VentasPacientes_HPRED_pk on vwc_INV_VentasPacientes_HPRED(HPREDID,PROCEDENCIA,IMOVHID);
go
create nonclustered index idx_vwc_INV_VentasPacientes_HPRED_NOADMISION ON [dbo].[vwc_INV_VentasPacientes_HPRED] ([NOADMISION])
INCLUDE ([IDARTICULO],[NOLOTE],[UBICACION],[FECHAVENCE],[CANTIDAD],[DEVOLUCIONES],[DISPONIBLES],[PROCEDENCIA],[NOPRESTACION],[HPREDID],
	[IDSERVICIO],[DESCSERVICIO],[CNSMOV],[ITEM],[FECHACONF],[USUARIO],[FACTURADA],[PCOSTO])
with (online=on)
GO
create nonclustered index idx_vwc_INV_VentasPacientes_HPRED_IDARTICULO ON [dbo].[vwc_INV_VentasPacientes_HPRED] ([IDARTICULO])
INCLUDE ([NOLOTE],[UBICACION],[FECHAVENCE],[CANTIDAD],[DEVOLUCIONES],[DISPONIBLES],[PROCEDENCIA],[NOADMISION],[NOPRESTACION],[HPREDID],[IDSERVICIO],
	[DESCSERVICIO],[CNSMOV],[ITEM],[FECHACONF],[USUARIO],[FACTURADA],[PCOSTO])
with (online=on)
GO
CREATE NONCLUSTERED INDEX idx_vwc_INV_VentasPacientes_HPRED_SALUD ON [dbo].[vwc_INV_VentasPacientes_HPRED] ([PROCEDENCIA],[NOADMISION])
INCLUDE ([IDARTICULO],[NOLOTE],[UBICACION],[FECHAVENCE],[CANTIDAD],[DEVOLUCIONES],[DISPONIBLES],[PCOSTO])
with (online=on)
GO
CREATE NONCLUSTERED INDEX idx_vwc_INV_VentasPacientes_HPRED_QXPRO ON [dbo].[vwc_INV_VentasPacientes_HPRED] ([PROCEDENCIA],[NOPRESTACION])
INCLUDE ([IDARTICULO],[NOLOTE],[UBICACION],[FECHAVENCE],[CANTIDAD],[DEVOLUCIONES],[DISPONIBLES],[PCOSTO])
with (online=on)
GO


drop VIEW if exists dbo.VWA_INVDESPINTD_IDEV 
go
CREATE VIEW dbo.VWA_INVDESPINTD_IDEV 
AS	
	-- Devoluciones SALUD
	select PROCEDENCIA=cast('SALUD' as varchar(20)), h.NOPRESTACION, h.FECHA, 
		b.IDARTICULO, DESCRIPCION=i.DESCRIPCION, h.HPREDID, b.IMOVHID, b.IMOVHDID, b.MANLOTESERIE, b.NOLOTE, b.FECHAVENCE, 
		b.UBICACION, CANTIDAD = d.CantDisponible, b.SalidasConf, b.Devoluciones, 
		DevSinConf=coalesce(c.DevSinConf,0), DevSinConf_IMOV = coalesce(e.CANTIDAD,0), 
		h.IDSERVICIO, s.DESCSERVICIO, h.NOITEM, h.USUARIO, a.NOADMISION, CantHPRED = h.CANTIDAD, b.PCOSTO, IDBODEGADESPACHO=b.IDBODEGA 
	from vwc_HPRED_PEDIDOINV_xNOADMISION a with (nolock,noexpand) 
		outer apply (
			select b.IDARTICULO, b.HPREDID, b.IMOVHID, b.IMOVHDID, b.MANLOTESERIE, b.NOLOTE, b.UBICACION, b.FECHAVENCE,
				Disponibles=b.DISPONIBLES, SalidasConf=b.CANTIDAD, Devoluciones=b.DEVOLUCIONES, b.PCOSTO, b.IDBODEGA 
			from dbo.fnc_INV_VentasPacientes_xNOADMISION(a.NOADMISION,'SALUD') b
		) b
		left join dbo.vwc_HPRED_PEDIDOINV h with (nolock,noexpand) on h.NOADMISION=a.NOADMISION and h.HPREDID=b.HPREDID
		left join IART i with(nolock) on i.IDARTICULO=b.IDARTICULO
		left join dbo.vwc_IDEVD_Devolviendo_xHPREDID c with (nolock,noexpand) on c.PROCEDENCIA='SALUD' and c.HPREDID=b.HPREDID and c.IDARTICULO=b.IDARTICULO 
			and c.MANLOTESERIE=b.MANLOTESERIE and c.NOLOTE=b.NOLOTE
		left join dbo.vwc_INV_Devoluciones_SinConf e with (nolock/*,noexpand*/) on e.PROCEDENCIA = 'DEVSALUD' and e.HPREDID=b.HPREDID and b.IDARTICULO=e.IDARTICULO
			and e.MANLOTESERIE=b.MANLOTESERIE and e.NOLOTE=b.NOLOTE
		outer apply (select CantDisponible = coalesce(b.Disponibles,0) - coalesce(c.DevSinConf,0) - coalesce(e.CANTIDAD,0) ) d
		left join SER s with(nolock) on s.IDSERVICIO=h.IDSERVICIO
	where d.CantDisponible>0
	union all
	-- Devoluciones QXPRO
	select PROCEDENCIA=cast('QXPRO' as varchar(20)), NOPRESTACION=cast(ltrim(rtrim(str(a.NOPROGRAMACION))) as varchar(20)), h.FECHA, 
		b.IDARTICULO, DESCRIPCION=i.DESCRIPCION, HPREDID=b.HPREDID, b.IMOVHID, b.IMOVHDID, b.MANLOTESERIE, b.NOLOTE, b.FECHAVENCE, 
		b.UBICACION, CANTIDAD = d.CantDisponible, b.SalidasConf, b.Devoluciones, 
		DevSinConf=coalesce(c.DevSinConf,0), DevSinConf_IMOV = coalesce(e.CANTIDAD,0), 
		h.IDSERVICIO, s.DESCSERVICIO, h.NOITEM, h.USUARIO, h.NOADMISION, CantHPRED = h.CANTIDAD, b.PCOSTO, IDBODEGADESPACHO=b.IDBODEGA 
	from vwc_CXPS_PEDIDOINV_xNOPROGRAMACION a with (nolock,noexpand) 
		outer apply (
			select b.IDARTICULO, b.HPREDID, b.IMOVHID, b.IMOVHDID, b.MANLOTESERIE, b.NOLOTE, b.UBICACION, b.FECHAVENCE,
				Disponibles=b.DISPONIBLES, SalidasConf=b.CANTIDAD, Devoluciones=b.DEVOLUCIONES, b.PCOSTO, b.IDBODEGA 
			from dbo.fnc_INV_VentasPacientes_xNOPROGRAMACION(a.NOPROGRAMACION,'QXPRO') b
		) b
		left join dbo.vwc_CXPS_PEDIDOINV h with (nolock,noexpand) on h.NOPROGRAMACION=a.NOPROGRAMACION and h.CXPSPFID=b.HPREDID
		left join IART i with(nolock) on i.IDARTICULO=b.IDARTICULO
		left join dbo.vwc_IDEVD_Devolviendo_xHPREDID c with (nolock,noexpand) on c.PROCEDENCIA='QXPRO' and c.HPREDID=b.HPREDID and c.IDARTICULO=b.IDARTICULO 
			and c.MANLOTESERIE=b.MANLOTESERIE and c.NOLOTE=b.NOLOTE
		left join dbo.vwc_INV_Devoluciones_SinConf e with (nolock/*,noexpand*/) on e.PROCEDENCIA = 'DEVQXPRO' and e.HPREDID=b.HPREDID and e.IDARTICULO=b.IDARTICULO
			and e.MANLOTESERIE=b.MANLOTESERIE and e.NOLOTE=b.NOLOTE
		outer apply (select CantDisponible = coalesce(b.Disponibles,0) - coalesce(c.DevSinConf,0) - coalesce(e.CANTIDAD,0) ) d
		left join SER s with(nolock) on s.IDSERVICIO=h.IDSERVICIO
	where d.CantDisponible>0
go