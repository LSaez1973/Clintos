drop trigger if exists [dbo].[tra_HPRED_I]      
go
Create Trigger [dbo].[tra_HPRED_I]      
on [dbo].[HPRED] for insert      
as      
begin     
 if update(IDCIRUGIA)    
 begin    
  update HPRED set IDCIRUGIA=null from inserted where hpred.HPREDID=inserted.HPREDID and hpred.IDCIRUGIA=''     
 end    
   
 if update (VALOR) or update(CANTIDAD) or update(VALORCOPAGO) or update(VALORPCOMP) or update(VALOREXCEDENTE)  
 begin  
   update a set VALOREXCEDENTE = (coalesce(b.VALOR,0)*coalesce(b.CANTIDAD,0))-coalesce(b.VALORCOPAGO,0)-coalesce(b.VALORPCOMP,0)
   from HPRED a  
    join inserted b on a.HPREDID=b.HPREDID;  

  with mem1 as (  
   SELECT a.NOPRESTACION, VT=SUM(b.VALOR * b.CANTIDAD), VE = SUM(b.VALOREXCEDENTE), VC = SUM(b.VALORCOPAGO), VP = SUM(b.VALORPCOMP)  
   FROM hpre a with (nolock)  
    join (select distinct NOPRESTACION from inserted) h on a.NOPRESTACION=h.NOPRESTACION  
    left join hpred b with (nolock) on a.NOPRESTACION=b.NOPRESTACION  
   WHERE coalesce(a.CIRUGIA,'NO')='NO'  
   group by a.NOPRESTACION  
  )  
  UPDATE HPRE SET VALORTOTAL = coalesce(b.VT,0), VALOREXEDENTE = coalesce(b.VE,0), VALORCOPAGO = coalesce(b.VC,0), VALORPCOMP = coalesce(b.VP,0)   
  from hpre a join mem1 b on a.NOPRESTACION=b.NOPRESTACION;  
 end  
end    
go

drop Trigger if exists [dbo].[tra_HPRED_U]      
go
Create Trigger [dbo].[tra_HPRED_U]      
on [dbo].[HPRED] for update      
as      
begin    
 set xact_abort off; -- Para poder manipular eventos de error(catch) en triggers que afecten transacciones encadenadas. si no se usa SQL generara el error     
  -- 3998: Se ha detectado una transacción no confirmable al final del lote. Se ha revertido la transacción.    
 set nocount on;    
    
 declare @TranCounter int;    
    
 set @TranCounter = @@TRANCOUNT; -- Guarda el # de transacciones activas         
     
 begin try            
            
  if @TranCounter > 0              
   save transaction SaveTranc_tra_HPRED_U;  -- ya existe una transaccion activa       
    
  if not update (FACTURADA) and (select count(*) from deleted where FACTURADA=1)>0   
   and not update(VALORCOPAGO) and not update(VALORPCOMP) and not update(VALOREXCEDENTE)    
  begin    
   raiserror('ERROR: Las prestaciones que intenta modificar se encuentran facturadas.',16,1)    
   rollback    
  end    
    
  if update(IDCIRUGIA)    
  begin    
   update HPRED set IDCIRUGIA=null from inserted where hpred.HPREDID=inserted.HPREDID and hpred.IDCIRUGIA=''     
  end    
    
  if update (VALOR) or update(CANTIDAD) or update(VALORCOPAGO) or update(VALORPCOMP) or update(VALOREXCEDENTE)   
  begin
   update a set VALOREXCEDENTE = (coalesce(b.VALOR,0)*coalesce(b.CANTIDAD,0))-coalesce(b.VALORCOPAGO,0)-coalesce(b.VALORPCOMP,0)
   from HPRED a  
    join inserted b on a.HPREDID=b.HPREDID;  

   with mem1 as (  
    SELECT a.NOPRESTACION, VT=SUM(b.VALOR * b.CANTIDAD), VE = SUM(b.VALOREXCEDENTE), VC = SUM(b.VALORCOPAGO), VP = SUM(b.VALORPCOMP)  
    FROM hpre a with (nolock)  
     join (select distinct NOPRESTACION from (select NOPRESTACION from inserted union all select NOPRESTACION from deleted) h) h on a.NOPRESTACION=h.NOPRESTACION  
     left join hpred b with (nolock) on a.NOPRESTACION=b.NOPRESTACION  
    WHERE coalesce(a.CIRUGIA,'NO')='NO'  
    group by a.NOPRESTACION  
   )  
   UPDATE HPRE SET VALORTOTAL = coalesce(b.VT,0), VALOREXEDENTE = coalesce(b.VE,0), VALORCOPAGO = coalesce(b.VC,0), VALORPCOMP = coalesce(b.VP,0)   
   from hpre a join mem1 b on a.NOPRESTACION=b.NOPRESTACION;  
  end  
  
  -- Valida que no se modifique el copago cuando ya se encuentra liquidado en los items de HPRED    
  if update(VALORCOPAGO) or update(VALORPCOMP)    
  begin    
   if (select count(*) from inserted  where FACTURADA=1) > 0    
   begin    
    raiserror('No es posible liquidar copagos en las prestaciones porque tiene Items facturados.',16,1)    
   end    
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
   rollback transaction SaveTranc_tra_HPRED_U;     
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

drop Trigger if exists[dbo].[tra_HPRED_D]      
go
Create Trigger [dbo].[tra_HPRED_D]      
on [dbo].[HPRED] for delete      
as      
begin     
 if (select count(*) from deleted where FACTURADA=1)>0    
 begin    
  raiserror('ERROR: Las prestaciones que intenta eliminar se encuentran facturadas.',16,1)    
  rollback    
 end    
  
 if update (VALOR) or update(CANTIDAD) or update(VALORCOPAGO) or update(VALORPCOMP) or update(VALOREXCEDENTE)  
 begin  
  with mem1 as (  
   SELECT a.NOPRESTACION, VT=SUM(b.VALOR * b.CANTIDAD), VE = SUM(b.VALOREXCEDENTE), VC = SUM(b.VALORCOPAGO), VP = SUM(b.VALORPCOMP)  
   FROM hpre a with (nolock)  
    join (select distinct NOPRESTACION from deleted) h on a.NOPRESTACION=h.NOPRESTACION  
    left join hpred b with (nolock) on a.NOPRESTACION=b.NOPRESTACION  
   WHERE coalesce(a.CIRUGIA,'NO')='NO'  
   group by a.NOPRESTACION  
  )  
  UPDATE HPRE SET VALORTOTAL = coalesce(b.VT,0), VALOREXEDENTE = coalesce(b.VE,0), VALORCOPAGO = coalesce(b.VC,0), VALORPCOMP = coalesce(b.VP,0)   
  from hpre a join mem1 b on a.NOPRESTACION=b.NOPRESTACION;  
 end  
end    
go


alter table hpre disable trigger all
go
with mem1 as (
	SELECT a.NOPRESTACION, VT=SUM(b.VALOR * b.CANTIDAD), VE = SUM(b.VALOREXCEDENTE), VC = SUM(b.VALORCOPAGO), VP = SUM(b.VALORPCOMP)
	FROM hpre a with (nolock)
		left join hpred b with (nolock) on a.NOPRESTACION=b.NOPRESTACION
	WHERE coalesce(a.CIRUGIA,'NO')='NO'
	group by a.NOPRESTACION
)
UPDATE HPRE SET VALORTOTAL = coalesce(b.VT,0), VALOREXEDENTE = coalesce(b.VE,0), VALORCOPAGO = coalesce(b.VC,0), VALORPCOMP = coalesce(b.VP,0) 
--select b.VT,a.VALORTOTAL, a.*
from hpre a 
	join mem1 b on a.NOPRESTACION=b.NOPRESTACION
where a.VALORTOTAL<>coalesce(b.VT,0)
go
alter table hpre enable trigger all
go