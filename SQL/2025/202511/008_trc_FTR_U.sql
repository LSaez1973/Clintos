drop Trigger dbo.trc_FTR_U    
go
Create Trigger dbo.trc_FTR_U    
on dbo.FTR for Update    
as  
begin  
 set xact_abort off; -- Para poder manipular eventos de error(catch) en triggers que afecten transacciones encadenadas. si no se usa SQL generara el error   
      -- 3998: Se ha detectado una transacción no confirmable al final del lote. Se ha revertido la transacción.  
 set nocount on;  
 if @@ROWCOUNT>1  
 begin  
  raiserror('No puede procesar mas de una Factura en una sola instrucción.',16,1);  
  rollback;  
  return;     
 end  
   
 declare   
  @TranCounter int, @N_FACTURA_COPAGOS varchar(20), @PROCEDENCIA varchar(20), @IDT varchar(20);  
              
 set @TranCounter = @@TRANCOUNT; -- Guarda el # de transacciones activas       
   
 begin try          
          
  if @TranCounter > 0            
   save transaction SaveTranc_trc_FTR_U;  -- ya existe una transaccion activa     
   
  if update (ORIGENINGASIS)  
  begin  
   -- Valida que no existan facturas de copagos sin relacionar a factura de EPS (selo se acepta una factura de Copagos por factura a EPS)   
   select top 1 @N_FACTURA_COPAGOS=a.N_FACTURA  
   from inserted d   
    join FTR a with(nolock) on a.NOREFERENCIA=d.NOREFERENCIA and a.ESTADO='P' and a.ORIGENINGASIS=d.ORIGENINGASIS and a.CNSFCT<>d.CNSFCT -- Facturas de copagos  
     and not exists (  
      -- Facturas relacionaas a una de EPS  
      select o.N_FACTURA   
      from FTROFR o with(nolock)   
      where o.N_FACTURA=a.N_FACTURA  
     )  
   where a.TIPOFAC in ('7','8','9')  
  
   if not @N_FACTURA_COPAGOS is null  
   begin  
    raiserror('Factura Existente: Para éste documento existe la Factura No. %s sin relacionar a una factura de EPS',16,1,@N_FACTURA_COPAGOS);  
   end  
  end  
  
   -- Obtiene el consecutivo de factura numérico    
  if update(N_FACTURA)    
  Begin    
   With x As (    
    SELECT CNSFCT, Val=Substring(N_FACTURA, PATINDEX('%[0-9]%', N_FACTURA), LEN(N_FACTURA))      
    From Inserted Where FCNSCNS Is null    
   )    
   Update dbo.FTR Set FCNSCNS = Left(x.Val,PATINDEX('%[^0-9]%', x.Val+'a')-1)    
   From dbo.FTR a     
    Join x On a.CNSFCT=x.CNSFCT  
   where a.FCNSID>0  
  
   -- Solo para la UT de IMAT SAS - Oncomedica  
   if db_name()='Clintos8_UT'  
   begin  
    update Agilis.dbo.FTR set N_FACTURA_FTRUT=a.N_FACTURA  
    from inserted a  
     join FTRUT b with (nolock) on a.CNSFCT=b.CNSFCT  
     join Agilis.dbo.FTR c with (nolock) on b.N_FACTURA=c.N_FACTURA  
    where b.BDEXT='Agilis'  
  
    update Clintos8.dbo.FTR set N_FACTURA_FTRUT=a.N_FACTURA  
    from inserted a  
     join FTRUT b with (nolock) on a.CNSFCT=b.CNSFCT  
     join Clintos8.dbo.FTR c with (nolock) on b.N_FACTURA=c.N_FACTURA  
    where b.BDEXT='Clintos8'  
  
    update Oncomedica8.dbo.FTR set N_FACTURA_FTRUT=a.N_FACTURA  
    from inserted a  
     join FTRUT b with (nolock) on a.CNSFCT=b.CNSFCT  
     join Oncomedica8.dbo.FTR c with (nolock) on b.N_FACTURA=c.N_FACTURA  
    where b.BDEXT='Oncomedica8'  
   end   
  end  
  
  -- Distribución de facturas copagos en las prestaciones 
  if update(IDT)
  begin
	  declare   
	   @FTR_GENERADA table (  
		CNSFCT varchar(40), N_FACTURA varchar(20), NOADMISION varchar(20), IDT varchar(20),   
		TIPOFAC varchar(1), COPAGOS decimal(14,2), ORIGENINGASIS varchar(20), ESTADO varchar(1)  
	   );   
	  declare @TOTALEXCEDENTE decimal(14,2), @string varchar(128), @ESTADO varchar(1);  
  
	  drop table if exists #ftrofr;  
	  drop table if exists #Datos_I;  
    
	  -- Asignar Estado Generada  
	  update FTR set GENERADA=1   
	  output inserted.CNSFCT, inserted.N_FACTURA, inserted.NOREFERENCIA, inserted.IDT, inserted.TIPOFAC, inserted.VR_TOTAL, inserted.ORIGENINGASIS, inserted.ESTADO   
	  into @FTR_GENERADA(CNSFCT,N_FACTURA,NOADMISION,IDT,TIPOFAC,COPAGOS,ORIGENINGASIS,ESTADO) -- Faturas Generadas  
	  from inserted a  
	   join FTR b on a.CNSFCT=b.CNSFCT  
	  where a.FCNSID>0 and a.FCNSCNS>0;    
   
	  if (select count(*) from @FTR_GENERADA)>0  
	  begin     
	   select @PROCEDENCIA=ORIGENINGASIS, @N_FACTURA_COPAGOS=N_FACTURA, @ESTADO=ESTADO, @IDT = IDT from @FTR_GENERADA;  
     
	   if @ESTADO='A'  
	   begin  
		if (select count(*) from vwc_Facturable a with(nolock) where a.N_FACTURACOPAGO=@N_FACTURA_COPAGOS  
		 -- and a.FACTURABLE=1 and coalesce(a.CLASENOPROC,'')<>'NP'  
		) > 0  
		 raiserror('ERROR: debe desvincular primero ésta factura de servicios relacionados por Copagos.',16,1);  
	   end  
  
	   -- select @ESTADO,@IDT  
  
	   if @ESTADO='P'  
	   begin  
		if @IDT like '_789' -- desde el formulario FormaFTR_Financ de Clarion se llena FTR:IDT cuando se está insertando ej. 7789, 8789, 9789  
		begin  
		 -- Indica que se está facturando todos los ITEMS del documento (cuando no es facturación por items)  
		 -- Se marcan el IDT tanto FTR como los items del documento origen que no estén facturados en copagos, ni en facturas   
		 update @FTR_GENERADA set IDT = dbo.fnc_GenFechaNumerica(getdate());  
		 update FTR set IDT = f.IDT from @FTR_GENERADA f where f.CNSFCT=FTR.CNSFCT;  
      
		 if @PROCEDENCIA='SALUD'  
		 begin  
		  -- obligado a usar vwc_Facturable_HADM_Todas para incluir admisiones con alta medica y no admin. 
		  -- No usar vwc_Facturable  
		  update vwc_Facturable_HADM_Todas set IDT=f.IDT   
		  from vwc_Facturable_HADM_Todas a  
		   join @FTR_GENERADA f on f.NOADMISION=a.NOADMISION and f.ORIGENINGASIS = @PROCEDENCIA and f.TIPOFAC in ('7','8','9') 
		  where coalesce(a.N_FACTURACOPAGO,'')='' and a.FACTURABLE=1 and coalesce(a.CLASENOPROC,'')<>'NP';  
		 end  
		 else  
		 if @PROCEDENCIA='CIT'  
		 begin  
		  update CIT set IDT=f.IDT   
		  from CIT a  
		   join @FTR_GENERADA f on f.NOADMISION=a.CONSECUTIVO and f.ORIGENINGASIS = @PROCEDENCIA and f.TIPOFAC in ('7','8','9')  
		  where a.FACTURADA=0 and coalesce(a.N_FACTURACOPAGO,'')='';  
		 end  
		 else  
		 if @PROCEDENCIA='CE'  
		 begin  
		  update AUTD set IDT=f.IDT   
		  from AUTD a  
		   join @FTR_GENERADA f on f.NOADMISION=a.IDAUT and f.ORIGENINGASIS = @PROCEDENCIA and f.TIPOFAC in ('7','8','9')  
		  where a.FACTURADA=0 and coalesce(a.N_FACTURACOPAGO,'')='';  
		 end  
		end  
      
		-- drop table #Datos_I  
		select ORIGEN,IDTERCEROCA,COBRARA,IDSERVICIOADM,IDSEDE,NOADMISION,FECHAALTA,IDAREA_ALTA,CCOSTO_ALTA,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,IDAFILIADO,NOPRESTACION,  
		 IDAUT,CNSCIT,FECHA,NOITEM,PREFIJO,IDSERVICIO,DESCSERVICIO,CANTIDAD,VALOR,VLR_SERVICI,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,PCOSTO,FACTURADA,  
		 N_FACTURA,IDPROVEEDOR,IDAREA,CCOSTO,IDCUM,NOINVIMA,KCNTRID,NUMCONTRATO,KNEGID,IDTARIFA,KCNTID,IDSERVICIOREL,AFIRCID,CNSFACT,MARCAFAC,CNSFCT,VFACTURAS,  
		 NOCOBRABLE,CLASEING,CAPITA,IDT,HPREDID,NOAUTORIZACION,CERRADA,N_FACTURACOPAGO,   
		 VALOREXCEDENTE=cast(0 as decimal(14,2)), TIPOFAC = cast(null as varchar(1))  
		into #Datos_I  
		from vwc_Facturable_HADM where 1=2  
		union all   
		select ORIGEN,IDTERCEROCA,COBRARA,IDSERVICIOADM,IDSEDE,NOADMISION,FECHAALTA,IDAREA_ALTA,CCOSTO_ALTA,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,IDAFILIADO,NOPRESTACION,  
		 IDAUT,CNSCIT,FECHA,NOITEM,PREFIJO,IDSERVICIO,DESCSERVICIO,CANTIDAD,VALOR=VLR_SERVICI,VLR_SERVICI,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,PCOSTO,FACTURADA,  
		 N_FACTURA,IDPROVEEDOR,IDAREA,CCOSTO,IDCUM,NOINVIMA,KCNTRID,NUMCONTRATO,KNEGID,IDTARIFA,KCNTID,IDSERVICIOREL,AFIRCID,CNSFACT,MARCAFAC,CNSFCT,VFACTURAS,  
		 NOCOBRABLE,CLASEING,CAPITA,IDT,HPREDID,NOAUTORIZACION,CERRADA,N_FACTURACOPAGO,  
		 VALOREXCEDENTE=cast(0 as decimal(14,2)), TIPOFAC = cast(null as varchar(1))   
		from vwc_Facturable_CIT where 1=2  
		union all   
		select ORIGEN,IDTERCEROCA,COBRARA,IDSERVICIOADM,IDSEDE,NOADMISION,FECHAALTA,IDAREA_ALTA,CCOSTO_ALTA,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,IDAFILIADO,NOPRESTACION,  
		 IDAUT,CNSCIT,FECHA,NOITEM,PREFIJO,IDSERVICIO,DESCSERVICIO,CANTIDAD,VALOR,VLR_SERVICI,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,PCOSTO,FACTURADA,  
		 N_FACTURA,IDPROVEEDOR,IDAREA,CCOSTO,IDCUM,NOINVIMA,KCNTRID,NUMCONTRATO,KNEGID,IDTARIFA,KCNTID,IDSERVICIOREL,AFIRCID,CNSFACT,MARCAFAC,CNSFCT,VFACTURAS,  
		 NOCOBRABLE,CLASEING,CAPITA,IDT,HPREDID,NOAUTORIZACION,CERRADA,N_FACTURACOPAGO,   
		 VALOREXCEDENTE=cast(0 as decimal(14,2)), TIPOFAC = cast(null as varchar(1))   
		from vwc_Facturable_AUT where 1=2;  
  
		--exec tempdb.sys.sp_help #Datos_I;  
		--print @PROCEDENCIA;  
  
		-- FTR.ORIGENINGASIS: 'Admisiones|#SALUD|Citas|#CIT|Consulta Externa|#CE'
		if @PROCEDENCIA='SALUD'  
		begin  
		 -- obligado a usar vwc_Facturable_HADM_Todas para incluir admisiones con alta medica y no admin. No usar vwc_Facturable  
		 -- Items marcados en proceso previo con IDT por documento   
		 insert into #Datos_I  
		 select a.ORIGEN,a.IDTERCEROCA,a.COBRARA,a.IDSERVICIOADM,a.IDSEDE,a.NOADMISION,a.FECHAALTA,a.IDAREA_ALTA,a.CCOSTO_ALTA,a.TIPOCONTRATO,a.TIPOTTEC,a.TIPOSISTEMA,a.IDAFILIADO,a.NOPRESTACION,  
		  a.IDAUT,a.CNSCIT,a.FECHA,a.NOITEM,a.PREFIJO,a.IDSERVICIO,a.DESCSERVICIO,a.CANTIDAD,a.VALOR,a.VLR_SERVICI,a.VALORCOPAGO,a.VALORPCOMP,a.VALORMODERADORA,a.DESCUENTO,a.PCOSTO,a.FACTURADA,  
		  a.N_FACTURA,a.IDPROVEEDOR,a.IDAREA,a.CCOSTO,a.IDCUM,a.NOINVIMA,a.KCNTRID,a.NUMCONTRATO,a.KNEGID,a.IDTARIFA,a.KCNTID,a.IDSERVICIOREL,a.AFIRCID,a.CNSFACT,MARCAFAC=a.MARCA,a.CNSFCT,a.VFACTURAS,  
		  a.NOCOBRABLE,a.CLASEING,a.CAPITA,a.IDT,a.HPREDID,a.NOAUTORIZACION,a.CERRADA,a.N_FACTURACOPAGO,   
		  VALOREXCEDENTE=cast(0 as decimal(14,2)), f.TIPOFAC   
		 from @FTR_GENERADA f  
		  -- obligado a usar vwc_Facturable_HADM_Todas para incluir admisiones con alta medica y no admin. No usar vwc_Facturable  
		  join dbo.vwc_Facturable_HADM_Todas a on a.NOADMISION=f.NOADMISION and a.IDT=f.IDT  
		 where f.TIPOFAC in ('7','8','9') and f.ORIGENINGASIS = @PROCEDENCIA and a.FACTURABLE=1 and coalesce(a.CLASENOPROC,'')<>'NP';  
		end  
		else  
		if @PROCEDENCIA='CIT'    
		begin    
		 --print @PROCEDENCIA;    
		 --select * from @FTR_GENERADA;    
		 -- Items marcados en proceso previo con IDT por documento    
		 insert into #Datos_I    
		 select a.ORIGEN,a.IDTERCEROCA,a.COBRARA,a.IDSERVICIOADM,a.IDSEDE,a.NOADMISION,a.FECHAALTA,a.IDAREA_ALTA,a.CCOSTO_ALTA,a.TIPOCONTRATO,a.TIPOTTEC,a.TIPOSISTEMA,a.IDAFILIADO,a.NOPRESTACION,    
		  a.IDAUT,a.CNSCIT,a.FECHA,a.NOITEM,a.PREFIJO,a.IDSERVICIO,a.DESCSERVICIO,a.CANTIDAD,a.VALORTOTAL,a.VLR_SERVICI,a.VALORCOPAGO,a.VALORPCOMP,a.VALORMODERADORA,a.DESCUENTO,a.PCOSTO,a.FACTURADA,    
		  a.N_FACTURA,a.IDPROVEEDOR,a.IDAREA,a.CCOSTO,a.IDCUM,a.NOINVIMA,a.KCNTRID,a.NUMCONTRATO,a.KNEGID,a.IDTARIFA,a.KCNTID,a.IDSERVICIOREL,a.AFIRCID,a.CNSFACT,MARCAFAC=a.MARCAFAC,a.CNSFCT,a.VFACTURAS,    
		  a.NOCOBRABLE,a.CLASEING,a.CAPITA,a.IDT,a.HPREDID,a.NOAUTORIZACION,a.CERRADA,a.N_FACTURACOPAGO,   
		  VALOREXCEDENTE=cast(0 as decimal(14,2)), f.TIPOFAC     
		 from @FTR_GENERADA f    
		  -- obligado a usar vwc_Facturable_CIT     
		  join dbo.vwc_Facturable_CIT a on a.CNSCIT=f.NOADMISION and a.IDT=f.IDT
		 where f.TIPOFAC in ('7','8','9') and f.ORIGENINGASIS = @PROCEDENCIA;    
		end    
		else    
		if @PROCEDENCIA='CE'     
		begin    
		 -- Items marcados en proceso previo con IDT por documento     
		 insert into #Datos_I    
		 select a.ORIGEN,a.IDTERCEROCA,a.COBRARA,a.IDSERVICIOADM,a.IDSEDE,a.NOADMISION,a.FECHAALTA,a.IDAREA_ALTA,a.CCOSTO_ALTA,a.TIPOCONTRATO,a.TIPOTTEC,a.TIPOSISTEMA,a.IDAFILIADO,a.NOPRESTACION,    
		  a.IDAUT,a.CNSCIT,a.FECHA,a.NOITEM,a.PREFIJO,a.IDSERVICIO,a.DESCSERVICIO,a.CANTIDAD,a.VALOR,a.VLR_SERVICI,a.VALORCOPAGO,a.VALORPCOMP,a.VALORMODERADORA,a.DESCUENTO,a.PCOSTO,a.FACTURADA,    
		  a.N_FACTURA,a.IDPROVEEDOR,a.IDAREA,a.CCOSTO,a.IDCUM,a.NOINVIMA,a.KCNTRID,a.NUMCONTRATO,a.KNEGID,a.IDTARIFA,a.KCNTID,a.IDSERVICIOREL,a.AFIRCID,a.CNSFACT,MARCAFAC=a.MARCAFAC,a.CNSFCT,a.VFACTURAS,    
		  a.NOCOBRABLE,a.CLASEING,a.CAPITA,a.IDT,a.HPREDID,a.NOAUTORIZACION,a.CERRADA,a.N_FACTURACOPAGO,   
		 VALOREXCEDENTE=cast(0 as decimal(14,2)), f.TIPOFAC     
		 from @FTR_GENERADA f    
		  -- obligado a usar vwc_Facturable_AUT    
		  join dbo.vwc_Facturable_AUT a on a.IDAUT=f.NOADMISION and a.IDT=f.IDT
		 where f.TIPOFAC in ('7','8','9') and f.ORIGENINGASIS = @PROCEDENCIA;    
		end  
  
		if (select count(*) from #Datos_I ) > 0  
		begin  
		 --select * from #Datos_I;  
		 -- Totales de la Factura  
		 with   
		 a as (  
		  -- Total acumulado por Admisiones que tienen copagos facturados, 
		  -- agrupadas ('Normal|#I|Copago|#7|Moderadora|#8|Pago Compartido|#9')  
		  select a.TIPOFAC, TOTALPRESTACION=sum(TOTALPRESTACION)  
		  from (  
		   select a.TIPOFAC, -- = case when a.ORIGEN='HADM' and a.TIPOFAC='8' then '7' else a.TIPOFAC end, 
			TOTALPRESTACION=coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0)  
		   from #Datos_I a  
		  ) a  
		  group by a.TIPOFAC  
		 )  
		 select a.TIPOFAC, a.TOTALPRESTACION, f.COPAGOS  
		 into #ftrofr  
		 from @FTR_GENERADA f cross join a;  
  
		 select @TOTALEXCEDENTE=TOTALPRESTACION-COPAGOS from #ftrofr;  
  
		 if @TOTALEXCEDENTE<0  
		 begin  
		  set @string = format(@TOTALEXCEDENTE,'C2', 'es-CO')  
		  raiserror('El Valor de la Factura de Copagos no puede superar el total de los Servicios prestados (%s)',16,1,@string);  
		 end  
  
		 -- Actualizacion del copago tomado de la factura relacionada al documento   
		 Update #Datos_I   
		 Set VALORCOPAGO = (coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0) * f.COPAGOS) / f.TOTALPRESTACION*1.00  
		 from #Datos_I a  
		  join #ftrofr f on a.TIPOFAC = f.TIPOFAC and f.TIPOFAC='7';  
		 -- Actualizacion de cuota moderadora tomado de la factura relacionada al documento       
		 Update #Datos_I   
		 Set VALORMODERADORA = (coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0) * f.COPAGOS) / f.TOTALPRESTACION*1.00  
		 from #Datos_I a  
		  join #ftrofr f on a.TIPOFAC = f.TIPOFAC and f.TIPOFAC='8';  
		 -- Actualizacion del pago compartido tomado de la factura relacionada al documento        
		 Update #Datos_I   
		 Set VALORPCOMP = (coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0) * f.COPAGOS) / f.TOTALPRESTACION*1.00  
		 from #Datos_I a  
		  join #ftrofr f on a.TIPOFAC = f.TIPOFAC and f.TIPOFAC='9';  
  

		 -- Ajuste por decimales segun el tipo de copagos, el ajuste se aplica a un solo item x admision y tipo copago  
		 with v as (  
		  select HPREDID = max(a.HPREDID),  
		   AJUSTE = f.COPAGOS - sum(case f.TIPOFAC when '7' then a.VALORCOPAGO when '8' then a.VALORMODERADORA when '9' then a.VALORPCOMP end)       
		  from #Datos_I a  
		   join #ftrofr f on f.TIPOFAC=a.TIPOFAC  
		  group by a.TIPOFAC, f.COPAGOS  
		 )  
		 update #Datos_I set   
		  VALORCOPAGO = VALORCOPAGO + iif(a.TIPOFAC='7',v.AJUSTE,0),  
		  VALORMODERADORA = VALORMODERADORA + iif(a.TIPOFAC='8',v.AJUSTE,0),  
		  VALORPCOMP = VALORPCOMP + iif(a.TIPOFAC='9',v.AJUSTE,0)  
		 from #Datos_I a  
		  join v on v.HPREDID = a.HPREDID  
		  --cross join #ftrofr f;  
  
		 if @PROCEDENCIA='SALUD'  
		 begin  
		  -- Procedencia Salud: HADM  
  
		  -- Recalculos en HPRED del valor total luego de los copagos  
		  update HPRED   
		  set N_FACTURACOPAGO=@N_FACTURA_COPAGOS, 
			VALORCOPAGO=coalesce(b.VALORCOPAGO,0), 
			VALORPCOMP=coalesce(b.VALORPCOMP,0),
			VALORMODERADORA=coalesce(b.VALORMODERADORA,0),
		   VALOREXCEDENTE = (coalesce(b.VALOR,0)*coalesce(b.CANTIDAD,0))-coalesce(b.VALORCOPAGO,0)-coalesce(b.VALORPCOMP,0)-coalesce(b.VALORMODERADORA,0), 
		   TIPOCOPAGO=b.TIPOFAC  
		  from dbo.HPRED a  
		   join #Datos_I b on b.ORIGEN='HADM' and a.HPREDID=b.HPREDID;   
      
		  update HPRE set VALORCOPAGO=b.VALORCOPAGO, VALORPCOMP=b.VALORPCOMP, VALORMODERADORA=b.VALORMODERADORA, VALOREXEDENTE=b.VALOREXCEDENTE  
		  from @FTR_GENERADA i   
		   join HPRE a on a.NOADMISION = i.NOADMISION  
		   cross apply (  
			select VALORCOPAGO=sum(VALORCOPAGO), VALORPCOMP=sum(VALORPCOMP), VALORMODERADORA=SUM(b.VALORMODERADORA), VALOREXCEDENTE=sum(VALOREXCEDENTE)   
			from HPRED b with(nolock) where b.NOPRESTACION=a.NOPRESTACION  
		   ) b  
  
		  update HADM set COPAGOVALOR = coalesce(b.VR_TOTAL,0), MODOCOPAGO='Propio', TIPOCOPAGO=b.TIPOFAC   
		  from @FTR_GENERADA i   
		   join HADM a on a.NOADMISION=i.NOADMISION  
		   outer apply (   
			-- Suma de todas las facturas de Copagos de la Admisión  
			select VR_TOTAL=sum(b.VR_TOTAL), TIPOFAC=min(b.TIPOFAC)   
			from FTR b with(nolock) where b.NOREFERENCIA=a.NOADMISION and b.GENERADA=1 and b.ESTADO='P' and b.ORIGENINGASIS=@PROCEDENCIA  
		   ) b  
		 end   
		 else  
		 if @PROCEDENCIA = 'CIT'  
		 begin          
		  update CIT set N_FACTURACOPAGO=@N_FACTURA_COPAGOS, 
			VALORCOPAGO = coalesce(b.VALORCOPAGO,0), 
			VALORMODERADORA = coalesce(b.VALORMODERADORA,0),
			VALORPCOMP = coalesce(b.VALORPCOMP,0),
		   VALOREXEDENTE = a.VALORTOTAL - coalesce(b.VALORCOPAGO,0) - coalesce(b.VALORMODERADORA,0) - coalesce(b.VALORPCOMP,0), 
		   TIPOCOPAGO=b.TIPOFAC  
		  from CIT a  
		   join #Datos_I b on b.ORIGEN='CIT' and b.HPREDID=a.CITID;   
		 end  
		 else  
		 if @PROCEDENCIA = 'CE'   
		 begin  
		  update AUTD set N_FACTURACOPAGO=@N_FACTURA_COPAGOS, 
			VALORCOPAGO = coalesce(b.VALORCOPAGO,0),
			VALORMODERADORA = coalesce(b.VALORMODERADORA,0),
			VALORPCOMP = coalesce(b.VALORPCOMP,0),
			VALOREXCEDENTE = (coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0)) - coalesce(b.VALORCOPAGO,0) - coalesce(b.VALORMODERADORA,0) - coalesce(b.VALORPCOMP,0),   
		   TIPOCOPAGO = b.TIPOFAC  
		  from dbo.AUTD a  
		   join #Datos_I b on b.ORIGEN='AUT' and b.HPREDID=a.AUTDID;   
      
		  update AUT set VALORCOPAGO = b.VALORCOPAGO, VALORMODERADORA = b.VALORMODERADORA, VALORPCOMP = b.VALORPCOMP, VALOREXEDENTE = b.VALOREXCEDENTE  
		  from  @FTR_GENERADA i   
		   join AUT a on a.IDAUT=i.NOADMISION  
		   cross apply (  
			select VALORCOPAGO=sum(VALORCOPAGO), VALORMODERADORA = sum(b.VALORMODERADORA), VALORPCOMP = sum(b.VALORPCOMP), VALOREXCEDENTE=sum(VALOREXCEDENTE)   
			from AUTD b with(nolock) where b.IDAUT=a.IDAUT  
		   ) b  
		 end  
		end  
	   end  
	  end  
  end
  -- FIN: Distribución de facturas copagos en las prestaciones 


  -- Anulación de Facturas en HADMF  
  if update (ESTADO)  
  begin  
   update FTR set USUARIOANULA=u.USUARIO, FECHAANULA=dbo.fnk_fecha_sin_mls(getdate())  
   from FTR a   
    join inserted b on a.CNSFCT=b.CNSFCT and b.ESTADO='A'  
    outer apply dbo.fnc_getSession(@@SPID) u  
  
   update HADMF set ESTADO='A'  
   from HADMF a join inserted b on a.N_FACTURA=b.N_FACTURA and b.ESTADO='A'  
  end  
 end try  
 begin catch  
  declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;  
         
  select       
   @ErrorMessage = coalesce(ERROR_MESSAGE(),'desconocido'),      
   @ErrorSeverity = ERROR_SEVERITY(),      
   @ErrorState = ERROR_STATE();    
        
  if @TranCounter = 0  -- En un trigger en valor mínimo es 1, cuando hay cero o una transacción abierta.  
   rollback transaction; -- en triggers nunca entra por acá  
  else   
  begin  
   -- ************ ADVERTENCIA con XACT_ABORT OFF ****************  
   rollback transaction SaveTranc_trc_FTR_U;   
   -- SET XACT_ABORT OFF: Tenga en cuenta cuando esté presente en el trigger,   
   -- modo OFF es requerido para poder manipular eventos de error(catch) en triggers que afecten transacciones encadenadas. si no se usa SQL generara el error  
   --    3998: Se ha detectado una transacción no confirmable al final del lote. Se ha revertido la transacción.  
   --  
   -- 1. Cuidado, el rollback aquí presente, que es de la transacción guardada NO revierte cambios.  
   -- 2. Ei el triggers se desencadenó dentro de un try catch sin una transacción previa, el catch revierte los cambios (rollback automático).  
   -- 3. Si antes de desencadenar el trigger existe al menos una transacción abierta, el commit o rollback de esa transación serán los que afecten lo sucedido.   
   -- Ej. si al eliminar un registro de esta tabla usted no usa try catch o no inicia transacción, en caso de error la transacción quedará confirmada (commit).      
  end  
  raiserror(@ErrorMessage,16,1);      
 end catch  
end  
go

/*

Create Trigger dbo.trc_FTR_U    
on dbo.FTR for Update    
as  
begin  
 set xact_abort off; -- Para poder manipular eventos de error(catch) en triggers que afecten transacciones encadenadas. si no se usa SQL generara el error   
      -- 3998: Se ha detectado una transacción no confirmable al final del lote. Se ha revertido la transacción.  
 set nocount on;  
 if @@ROWCOUNT>1  
 begin  
  raiserror('No puede procesar mas de una Factura en una sola instrucción.',16,1);  
  rollback;  
  return;     
 end  
   
 declare   
  @TranCounter int, @N_FACTURA_COPAGOS varchar(20), @PROCEDENCIA varchar(20), @IDT varchar(20);  
              
 set @TranCounter = @@TRANCOUNT; -- Guarda el # de transacciones activas       
   
 begin try          
          
  if @TranCounter > 0            
   save transaction SaveTranc_trc_FTR_U;  -- ya existe una transaccion activa     
   
  if update (ORIGENINGASIS)  
  begin  
   -- Valida que no existan facturas de copagos sin relacionar a factura de EPS (selo se acepta una factura de Copagos por factura a EPS)   
   select top 1 @N_FACTURA_COPAGOS=a.N_FACTURA  
   from inserted d   
    join FTR a with(nolock) on a.NOREFERENCIA=d.NOREFERENCIA and a.ESTADO='P' and a.ORIGENINGASIS=d.ORIGENINGASIS and a.CNSFCT<>d.CNSFCT -- Facturas de copagos  
     and not exists (  
      -- Facturas relacionaas a una de EPS  
      select o.N_FACTURA   
      from FTROFR o with(nolock)   
      where o.N_FACTURA=a.N_FACTURA  
     )  
   where a.TIPOFAC in ('7','8','9')  
  
   if not @N_FACTURA_COPAGOS is null  
   begin  
    raiserror('Factura Existente: Para éste documento existe la Factura No. %s sin relacionar a una factura de EPS',16,1,@N_FACTURA_COPAGOS);  
   end  
  end  
  
   -- Obtiene el consecutivo de factura numérico    
  if update(N_FACTURA)    
  Begin    
   With x As (    
    SELECT CNSFCT, Val=Substring(N_FACTURA, PATINDEX('%[0-9]%', N_FACTURA), LEN(N_FACTURA))      
    From Inserted Where FCNSCNS Is null    
   )    
   Update dbo.FTR Set FCNSCNS = Left(x.Val,PATINDEX('%[^0-9]%', x.Val+'a')-1)    
   From dbo.FTR a     
    Join x On a.CNSFCT=x.CNSFCT  
   where a.FCNSID>0  
  
   -- Solo para la UT de IMAT SAS - Oncomedica  
   if db_name()='Clintos8_UT'  
   begin  
    update Agilis.dbo.FTR set N_FACTURA_FTRUT=a.N_FACTURA  
    from inserted a  
     join FTRUT b with (nolock) on a.CNSFCT=b.CNSFCT  
     join Agilis.dbo.FTR c with (nolock) on b.N_FACTURA=c.N_FACTURA  
    where b.BDEXT='Agilis'  
  
    update Clintos8.dbo.FTR set N_FACTURA_FTRUT=a.N_FACTURA  
    from inserted a  
     join FTRUT b with (nolock) on a.CNSFCT=b.CNSFCT  
     join Clintos8.dbo.FTR c with (nolock) on b.N_FACTURA=c.N_FACTURA  
    where b.BDEXT='Clintos8'  
  
    update Oncomedica8.dbo.FTR set N_FACTURA_FTRUT=a.N_FACTURA  
    from inserted a  
     join FTRUT b with (nolock) on a.CNSFCT=b.CNSFCT  
     join Oncomedica8.dbo.FTR c with (nolock) on b.N_FACTURA=c.N_FACTURA  
    where b.BDEXT='Oncomedica8'  
   end   
  end  
  
  -- Distribución de facturas copagos en las prestaciones  
  declare   
   @FTR_GENERADA table (  
    CNSFCT varchar(40), N_FACTURA varchar(20), NOADMISION varchar(20), IDT varchar(20),   
    TIPOFAC varchar(1), COPAGOS decimal(14,2), ORIGENINGASIS varchar(20), ESTADO varchar(1)  
   );   
  declare @TOTALEXCEDENTE decimal(14,2), @string varchar(128), @ESTADO varchar(1);  
  
  drop table if exists #ftrofr;  
  drop table if exists #Datos_I;  
    
  -- Asignar Estado Generada  
  update FTR set GENERADA=1   
  output inserted.CNSFCT, inserted.N_FACTURA, inserted.NOREFERENCIA, inserted.IDT, inserted.TIPOFAC, inserted.VR_TOTAL, inserted.ORIGENINGASIS, inserted.ESTADO   
  into @FTR_GENERADA(CNSFCT,N_FACTURA,NOADMISION,IDT,TIPOFAC,COPAGOS,ORIGENINGASIS,ESTADO) -- Faturas Generadas  
  from inserted a  
   join FTR b on a.CNSFCT=b.CNSFCT  
  where a.FCNSID>0 and a.FCNSCNS>0;    
   
  if (select count(*) from @FTR_GENERADA)>0  
  begin     
   select @PROCEDENCIA=ORIGENINGASIS, @N_FACTURA_COPAGOS=N_FACTURA, @ESTADO=ESTADO, @IDT = IDT from @FTR_GENERADA;  
     
   if @ESTADO='A'  
   begin  
    if (select count(*) from vwc_Facturable a with(nolock) where a.N_FACTURACOPAGO=@N_FACTURA_COPAGOS  
     -- and a.FACTURABLE=1 and coalesce(a.CLASENOPROC,'')<>'NP'  
    ) > 0  
     raiserror('ERROR: debe desvincular primero ésta factura de servicios relacionados por Copagos.',16,1);  
   end  
  
   -- select @ESTADO,@IDT  
  
   if @ESTADO='P'  
   begin  
    if @IDT like '_789' -- desde el formulario FormaFTR_Financ de Clarion se llena FTR:IDT cuando se está insertando ej. 7789, 8789, 9789  
    begin  
     -- Indica que se está facturando todos los ITEMS del documento (cuando no es facturación por items)  
     -- Se marcan el IDT tanto FTR como los items del documento origen que no estén facturados en copagos, ni en facturas   
     update @FTR_GENERADA set IDT = dbo.fnc_GenFechaNumerica(getdate());  
     update FTR set IDT = f.IDT from @FTR_GENERADA f where f.CNSFCT=FTR.CNSFCT;  
      
     if @PROCEDENCIA='SALUD'  
     begin  
      -- obligado a usar vwc_Facturable_HADM_Todas para incluir admisiones con alta medica y no admin. No usar vwc_Facturable  
      update vwc_Facturable_HADM_Todas set IDT=f.IDT   
      from vwc_Facturable_HADM_Todas a  
       join @FTR_GENERADA f on f.NOADMISION=a.NOADMISION   
      where coalesce(a.N_FACTURACOPAGO,'')='' and a.FACTURABLE=1 and coalesce(a.CLASENOPROC,'')<>'NP';  
     end  
     else  
     if @PROCEDENCIA='CIT'  
     begin  
      update CIT set IDT=f.IDT   
      from CIT a  
       join @FTR_GENERADA f on f.NOADMISION=a.CONSECUTIVO  
      where a.FACTURADA=0 and coalesce(a.N_FACTURACOPAGO,'')='';  
     end  
     else  
     if @PROCEDENCIA='CE'  
     begin  
      update AUTD set IDT=f.IDT   
      from AUTD a  
       join @FTR_GENERADA f on f.NOADMISION=a.IDAUT  
      where a.FACTURADA=0 and coalesce(a.N_FACTURACOPAGO,'')='';  
     end  
    end  
      
    -- drop table #Datos_I  
    select ORIGEN,IDTERCEROCA,COBRARA,IDSERVICIOADM,IDSEDE,NOADMISION,FECHAALTA,IDAREA_ALTA,CCOSTO_ALTA,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,IDAFILIADO,NOPRESTACION,  
     IDAUT,CNSCIT,FECHA,NOITEM,PREFIJO,IDSERVICIO,DESCSERVICIO,CANTIDAD,VALOR,VLR_SERVICI,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,PCOSTO,FACTURADA,  
     N_FACTURA,IDPROVEEDOR,IDAREA,CCOSTO,IDCUM,NOINVIMA,KCNTRID,NUMCONTRATO,KNEGID,IDTARIFA,KCNTID,IDSERVICIOREL,AFIRCID,CNSFACT,MARCAFAC,CNSFCT,VFACTURAS,  
     NOCOBRABLE,CLASEING,CAPITA,IDT,HPREDID,NOAUTORIZACION,CERRADA,N_FACTURACOPAGO,   
     VALOREXCEDENTE=cast(0 as decimal(14,2)), TIPOFAC = cast(null as varchar(1))  
    into #Datos_I  
    from vwc_Facturable_HADM where 1=2  
    union all   
    select ORIGEN,IDTERCEROCA,COBRARA,IDSERVICIOADM,IDSEDE,NOADMISION,FECHAALTA,IDAREA_ALTA,CCOSTO_ALTA,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,IDAFILIADO,NOPRESTACION,  
     IDAUT,CNSCIT,FECHA,NOITEM,PREFIJO,IDSERVICIO,DESCSERVICIO,CANTIDAD,VALOR=VLR_SERVICI,VLR_SERVICI,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,PCOSTO,FACTURADA,  
     N_FACTURA,IDPROVEEDOR,IDAREA,CCOSTO,IDCUM,NOINVIMA,KCNTRID,NUMCONTRATO,KNEGID,IDTARIFA,KCNTID,IDSERVICIOREL,AFIRCID,CNSFACT,MARCAFAC,CNSFCT,VFACTURAS,  
     NOCOBRABLE,CLASEING,CAPITA,IDT,HPREDID,NOAUTORIZACION,CERRADA,N_FACTURACOPAGO,  
     VALOREXCEDENTE=cast(0 as decimal(14,2)), TIPOFAC = cast(null as varchar(1))   
    from vwc_Facturable_CIT where 1=2  
    union all   
    select ORIGEN,IDTERCEROCA,COBRARA,IDSERVICIOADM,IDSEDE,NOADMISION,FECHAALTA,IDAREA_ALTA,CCOSTO_ALTA,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,IDAFILIADO,NOPRESTACION,  
     IDAUT,CNSCIT,FECHA,NOITEM,PREFIJO,IDSERVICIO,DESCSERVICIO,CANTIDAD,VALOR,VLR_SERVICI,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,PCOSTO,FACTURADA,  
     N_FACTURA,IDPROVEEDOR,IDAREA,CCOSTO,IDCUM,NOINVIMA,KCNTRID,NUMCONTRATO,KNEGID,IDTARIFA,KCNTID,IDSERVICIOREL,AFIRCID,CNSFACT,MARCAFAC,CNSFCT,VFACTURAS,  
     NOCOBRABLE,CLASEING,CAPITA,IDT,HPREDID,NOAUTORIZACION,CERRADA,N_FACTURACOPAGO,   
     VALOREXCEDENTE=cast(0 as decimal(14,2)), TIPOFAC = cast(null as varchar(1))   
    from vwc_Facturable_AUT where 1=2;  
  
    --exec tempdb.sys.sp_help #Datos_I;  
    --print @PROCEDENCIA;  
  
    if @PROCEDENCIA='SALUD'  
    begin  
     -- obligado a usar vwc_Facturable_HADM_Todas para incluir admisiones con alta medica y no admin. No usar vwc_Facturable  
     -- Items marcados en proceso previo con IDT por documento   
     insert into #Datos_I  
     select a.ORIGEN,a.IDTERCEROCA,a.COBRARA,a.IDSERVICIOADM,a.IDSEDE,a.NOADMISION,a.FECHAALTA,a.IDAREA_ALTA,a.CCOSTO_ALTA,a.TIPOCONTRATO,a.TIPOTTEC,a.TIPOSISTEMA,a.IDAFILIADO,a.NOPRESTACION,  
      a.IDAUT,a.CNSCIT,a.FECHA,a.NOITEM,a.PREFIJO,a.IDSERVICIO,a.DESCSERVICIO,a.CANTIDAD,a.VALOR,a.VLR_SERVICI,a.VALORCOPAGO,a.VALORPCOMP,a.VALORMODERADORA,a.DESCUENTO,a.PCOSTO,a.FACTURADA,  
      a.N_FACTURA,a.IDPROVEEDOR,a.IDAREA,a.CCOSTO,a.IDCUM,a.NOINVIMA,a.KCNTRID,a.NUMCONTRATO,a.KNEGID,a.IDTARIFA,a.KCNTID,a.IDSERVICIOREL,a.AFIRCID,a.CNSFACT,MARCAFAC=a.MARCA,a.CNSFCT,a.VFACTURAS,  
      a.NOCOBRABLE,a.CLASEING,a.CAPITA,a.IDT,a.HPREDID,a.NOAUTORIZACION,a.CERRADA,a.N_FACTURACOPAGO,   
      VALOREXCEDENTE=cast(0 as decimal(14,2)), f.TIPOFAC   
     from @FTR_GENERADA f  
      -- obligado a usar vwc_Facturable_HADM_Todas para incluir admisiones con alta medica y no admin. No usar vwc_Facturable  
      join dbo.vwc_Facturable_HADM_Todas a on a.NOADMISION=f.NOADMISION and a.IDT=f.IDT  
     where f.TIPOFAC in ('7','8','9') and a.FACTURABLE=1 and coalesce(a.CLASENOPROC,'')<>'NP';  
    end  
    else  
    if @PROCEDENCIA='CIT'    
    begin    
     --print @PROCEDENCIA;    
     --select * from @FTR_GENERADA;    
     -- Items marcados en proceso previo con IDT por documento    
     insert into #Datos_I    
     select a.ORIGEN,a.IDTERCEROCA,a.COBRARA,a.IDSERVICIOADM,a.IDSEDE,a.NOADMISION,a.FECHAALTA,a.IDAREA_ALTA,a.CCOSTO_ALTA,a.TIPOCONTRATO,a.TIPOTTEC,a.TIPOSISTEMA,a.IDAFILIADO,a.NOPRESTACION,    
      a.IDAUT,a.CNSCIT,a.FECHA,a.NOITEM,a.PREFIJO,a.IDSERVICIO,a.DESCSERVICIO,a.CANTIDAD,a.VALORTOTAL,a.VLR_SERVICI,a.VALORCOPAGO,a.VALORPCOMP,a.VALORMODERADORA,a.DESCUENTO,a.PCOSTO,a.FACTURADA,    
      a.N_FACTURA,a.IDPROVEEDOR,a.IDAREA,a.CCOSTO,a.IDCUM,a.NOINVIMA,a.KCNTRID,a.NUMCONTRATO,a.KNEGID,a.IDTARIFA,a.KCNTID,a.IDSERVICIOREL,a.AFIRCID,a.CNSFACT,MARCAFAC=a.MARCAFAC,a.CNSFCT,a.VFACTURAS,    
      a.NOCOBRABLE,a.CLASEING,a.CAPITA,a.IDT,a.HPREDID,a.NOAUTORIZACION,a.CERRADA,a.N_FACTURACOPAGO,   
      VALOREXCEDENTE=cast(0 as decimal(14,2)), f.TIPOFAC     
     from @FTR_GENERADA f    
      -- obligado a usar vwc_Facturable_CIT     
      join dbo.vwc_Facturable_CIT a on a.CNSCIT=f.NOADMISION and a.IDT=f.IDT;    
    end    
    else    
    if @PROCEDENCIA='CE'     
    begin    
     -- Items marcados en proceso previo con IDT por documento     
     insert into #Datos_I    
     select a.ORIGEN,a.IDTERCEROCA,a.COBRARA,a.IDSERVICIOADM,a.IDSEDE,a.NOADMISION,a.FECHAALTA,a.IDAREA_ALTA,a.CCOSTO_ALTA,a.TIPOCONTRATO,a.TIPOTTEC,a.TIPOSISTEMA,a.IDAFILIADO,a.NOPRESTACION,    
      a.IDAUT,a.CNSCIT,a.FECHA,a.NOITEM,a.PREFIJO,a.IDSERVICIO,a.DESCSERVICIO,a.CANTIDAD,a.VALOR,a.VLR_SERVICI,a.VALORCOPAGO,a.VALORPCOMP,a.VALORMODERADORA,a.DESCUENTO,a.PCOSTO,a.FACTURADA,    
      a.N_FACTURA,a.IDPROVEEDOR,a.IDAREA,a.CCOSTO,a.IDCUM,a.NOINVIMA,a.KCNTRID,a.NUMCONTRATO,a.KNEGID,a.IDTARIFA,a.KCNTID,a.IDSERVICIOREL,a.AFIRCID,a.CNSFACT,MARCAFAC=a.MARCAFAC,a.CNSFCT,a.VFACTURAS,    
      a.NOCOBRABLE,a.CLASEING,a.CAPITA,a.IDT,a.HPREDID,a.NOAUTORIZACION,a.CERRADA,a.N_FACTURACOPAGO,   
     VALOREXCEDENTE=cast(0 as decimal(14,2)), f.TIPOFAC     
     from @FTR_GENERADA f    
      -- obligado a usar vwc_Facturable_AUT    
      join dbo.vwc_Facturable_AUT a on a.IDAUT=f.NOADMISION and a.IDT=f.IDT;    
    end  
  
    if (select count(*) from #Datos_I ) > 0  
    begin  
     --select * from #Datos_I;  
     -- Totales de la Factura  
     with   
     a as (  
      -- Total acumulado por Admisiones que tienen copagos facturados, agrupadas (7:Copago, 8:moderadora, 9:Pago Comp.)  
      select a.TIPOFAC, TOTALPRESTACION=sum(TOTALPRESTACION)  
      from (  
       select TIPOFAC = case when a.ORIGEN='HADM' and a.TIPOFAC='8' then '7' else a.TIPOFAC end, TOTALPRESTACION=coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0)  
       from #Datos_I a  
      ) a  
      group by a.TIPOFAC  
     )  
     select a.TIPOFAC, a.TOTALPRESTACION, f.COPAGOS  
     into #ftrofr  
     from @FTR_GENERADA f cross join a;  
  
     select @TOTALEXCEDENTE=TOTALPRESTACION-COPAGOS from #ftrofr;  
  
     if @TOTALEXCEDENTE<0  
     begin  
      set @string = format(@TOTALEXCEDENTE,'C2', 'es-CO')  
      raiserror('El Valor de la Factura de Copagos no puede superar el total de los Servicios prestados (%s)',16,1,@string);  
     end  
  
     -- Actualizacion del copago tomado de la factura relacionada al documento   
     Update #Datos_I   
     Set VALORCOPAGO = (coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0) * f.COPAGOS) / f.TOTALPRESTACION*1.00  
     from #Datos_I a  
      cross join #ftrofr f   
     where f.TIPOFAC='7';  
     -- Actualizacion de cuota moderadora tomado de la factura relacionada al documento       
     Update #Datos_I   
     Set VALORMODERADORA = (coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0) * f.COPAGOS) / f.TOTALPRESTACION*1.00  
     from #Datos_I a  
      cross join #ftrofr f   
     where f.TIPOFAC='8';  
     -- Actualizacion del pago compartido tomado de la factura relacionada al documento        
     Update #Datos_I   
     Set VALORPCOMP = (coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0) * f.COPAGOS) / f.TOTALPRESTACION*1.00  
     from #Datos_I a  
      cross join #ftrofr f   
     where f.TIPOFAC='9';  
  
     -- Ajuste por decimales segun el tipo de copagos, el ajuste se aplica a un solo item x admision y tipo copago  
     with v as (  
      select HPREDID = max(a.HPREDID),  
       AJUSTE = f.COPAGOS - sum(case f.TIPOFAC when '7' then a.VALORCOPAGO when '8' then a.VALORMODERADORA when '9' then a.VALORPCOMP end)       
      from #Datos_I a  
       cross join #ftrofr f   
      group by f.COPAGOS  
     )  
     update #Datos_I set   
      VALORCOPAGO = VALORCOPAGO + iif(f.TIPOFAC='7',v.AJUSTE,0),  
      VALORMODERADORA = VALORMODERADORA + iif(f.TIPOFAC='8',v.AJUSTE,0),  
      VALORPCOMP = VALORPCOMP + iif(f.TIPOFAC='9',v.AJUSTE,0)  
     from #Datos_I a  
      join v on v.HPREDID = a.HPREDID  
      cross join #ftrofr f;  
  
     if @PROCEDENCIA='SALUD'  
     begin  
      -- Procedencia Salud: HADM  
  
      -- Recalculos en HPRED del valor total luego de los copagos  
      update HPRED   
      set N_FACTURACOPAGO=@N_FACTURA_COPAGOS, VALORCOPAGO=coalesce(b.VALORCOPAGO,0), VALORPCOMP=coalesce(b.VALORPCOMP,0),  
       VALOREXCEDENTE = (coalesce(b.VALOR,0)*coalesce(b.CANTIDAD,0))-coalesce(b.VALORCOPAGO,0)-coalesce(b.VALORPCOMP,0), TIPOCOPAGO=b.TIPOFAC  
      from dbo.HPRED a  
       join #Datos_I b on b.ORIGEN='HADM' and a.HPREDID=b.HPREDID;   
      
      update HPRE set VALORCOPAGO=b.VALORCOPAGO, VALORPCOMP=b.VALORPCOMP, VALOREXEDENTE=b.VALOREXCEDENTE  
      from @FTR_GENERADA i   
       join HPRE a on a.NOADMISION = i.NOADMISION  
       cross apply (  
        select VALORCOPAGO=sum(VALORCOPAGO), VALORPCOMP=sum(VALORPCOMP), VALOREXCEDENTE=sum(VALOREXCEDENTE)   
        from HPRED b with(nolock) where b.NOPRESTACION=a.NOPRESTACION  
       ) b  
  
      update HADM set COPAGOVALOR = coalesce(b.VR_TOTAL,0), MODOCOPAGO='Propio', TIPOCOPAGO=b.TIPOFAC   
      from @FTR_GENERADA i   
       join HADM a on a.NOADMISION=i.NOADMISION  
       outer apply (   
        -- Suma de todas las facturas de Copagos de la Admisión  
        select VR_TOTAL=sum(b.VR_TOTAL), TIPOFAC=min(b.TIPOFAC)   
        from FTR b with(nolock) where b.NOREFERENCIA=a.NOADMISION and b.GENERADA=1 and b.ESTADO='P' and b.ORIGENINGASIS=@PROCEDENCIA  
       ) b  
     end   
     else  
     if @PROCEDENCIA = 'CIT'  
     begin          
      update CIT set N_FACTURACOPAGO=@N_FACTURA_COPAGOS, VALORCOPAGO = coalesce(b.VALORCOPAGO,0), VALORMODERADORA = coalesce(b.VALORMODERADORA,0),   
       VALOREXEDENTE = a.VALORTOTAL - coalesce(b.VALORCOPAGO,0) - coalesce(b.VALORMODERADORA,0), TIPOCOPAGO=b.TIPOFAC  
      from CIT a  
       join #Datos_I b on b.ORIGEN='CIT' and b.HPREDID=a.CITID;   
     end  
     else  
     if @PROCEDENCIA = 'CE'   
     begin  
      update AUTD set N_FACTURACOPAGO=@N_FACTURA_COPAGOS, VALORCOPAGO = coalesce(b.VALORCOPAGO,0),VALOREXCEDENTE = (coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0))-coalesce(b.VALORCOPAGO,0),   
       TIPOCOPAGO = b.TIPOFAC  
      from dbo.AUTD a  
       join #Datos_I b on b.ORIGEN='AUT' and b.HPREDID=a.AUTDID;   
      
      update AUT set VALORCOPAGO = b.VALORCOPAGO, VALOREXEDENTE = b.VALOREXCEDENTE  
      from  @FTR_GENERADA i   
       join AUT a on a.IDAUT=i.NOADMISION  
       cross apply (  
        select VALORCOPAGO=sum(VALORCOPAGO), VALOREXCEDENTE=sum(VALOREXCEDENTE)   
        from AUTD b with(nolock) where b.IDAUT=a.IDAUT  
       ) b  
     end  
    end  
   end  
  end  
    
  -- Anulación de Facturas en HADMF  
  if update (ESTADO)  
  begin  
   update FTR set USUARIOANULA=u.USUARIO, FECHAANULA=dbo.fnk_fecha_sin_mls(getdate())  
   from FTR a   
    join inserted b on a.CNSFCT=b.CNSFCT and b.ESTADO='A'  
    outer apply dbo.fnc_getSession(@@SPID) u  
  
   update HADMF set ESTADO='A'  
   from HADMF a join inserted b on a.N_FACTURA=b.N_FACTURA and b.ESTADO='A'  
  end  
 end try  
 begin catch  
  declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;  
         
  select       
   @ErrorMessage = coalesce(ERROR_MESSAGE(),'desconocido'),      
   @ErrorSeverity = ERROR_SEVERITY(),      
   @ErrorState = ERROR_STATE();    
        
  if @TranCounter = 0  -- En un trigger en valor mínimo es 1, cuando hay cero o una transacción abierta.  
   rollback transaction; -- en triggers nunca entra por acá  
  else   
  begin  
   -- ************ ADVERTENCIA con XACT_ABORT OFF ****************  
   rollback transaction SaveTranc_trc_FTR_U;   
   -- SET XACT_ABORT OFF: Tenga en cuenta cuando esté presente en el trigger,   
   -- modo OFF es requerido para poder manipular eventos de error(catch) en triggers que afecten transacciones encadenadas. si no se usa SQL generara el error  
   --    3998: Se ha detectado una transacción no confirmable al final del lote. Se ha revertido la transacción.  
   --  
   -- 1. Cuidado, el rollback aquí presente, que es de la transacción guardada NO revierte cambios.  
   -- 2. Ei el triggers se desencadenó dentro de un try catch sin una transacción previa, el catch revierte los cambios (rollback automático).  
   -- 3. Si antes de desencadenar el trigger existe al menos una transacción abierta, el commit o rollback de esa transación serán los que afecten lo sucedido.   
   -- Ej. si al eliminar un registro de esta tabla usted no usa try catch o no inicia transacción, en caso de error la transacción quedará confirmada (commit).      
  end  
  raiserror(@ErrorMessage,16,1);      
 end catch  
end  

*/
