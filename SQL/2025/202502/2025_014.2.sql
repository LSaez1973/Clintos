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

-- select top 3 * from VWA_INVDESPINTD_IDEV
