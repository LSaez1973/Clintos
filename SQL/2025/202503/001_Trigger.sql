drop Trigger if exists [dbo].[tra_HPRED_I]    
go
Create Trigger [dbo].[tra_HPRED_I]    
on [dbo].[HPRED] for insert    
as    
begin   
	if update(IDCIRUGIA)  
	begin  
		update HPRED set IDCIRUGIA=null from inserted where hpred.HPREDID=inserted.HPREDID and hpred.IDCIRUGIA=''   
	end  
	
	if update (VALOR) or update(CANTIDAD) or update(VALORCOPAGO) or update(VALORPCOMP) or update(NOCOBRABLE)
	begin
		with mem1 as (
			SELECT a.NOPRESTACION, VT=SUM(b.VALOR * b.CANTIDAD), VE = SUM(b.VALOREXCEDENTE), VC = SUM(b.VALORCOPAGO), VP = SUM(b.VALORPCOMP)
			FROM hpre a with (nolock)
				join (select distinct NOPRESTACION from inserted) h on a.NOPRESTACION=h.NOPRESTACION
				left join hpred b with (nolock) on a.NOPRESTACION=b.NOPRESTACION and coalesce(b.NOCOBRABLE,0)=0
			WHERE coalesce(a.CIRUGIA,'NO')='NO'
			group by a.NOPRESTACION 
		)
		UPDATE HPRE SET VALORTOTAL = coalesce(b.VT,0), VALOREXEDENTE = coalesce(b.VE,0), VALORCOPAGO = coalesce(b.VC,0), VALORPCOMP = coalesce(b.VP,0) 
		from hpre a join mem1 b on a.NOPRESTACION=b.NOPRESTACION;
	end
end  
go

drop Trigger if exists [dbo].[tra_HPRED_I]    
go
Create Trigger [dbo].[tra_HPRED_I]    
on [dbo].[HPRED] for insert    
as    
begin   
	if update(IDCIRUGIA)  
	begin  
		update HPRED set IDCIRUGIA=null from inserted where hpred.HPREDID=inserted.HPREDID and hpred.IDCIRUGIA=''   
	end  
	
	if update (VALOR) or update(CANTIDAD) or update(VALORCOPAGO) or update(VALORPCOMP) or update(NOCOBRABLE)
	begin
		with mem1 as (
			SELECT a.NOPRESTACION, VT=SUM(b.VALOR * b.CANTIDAD), VE = SUM(b.VALOREXCEDENTE), VC = SUM(b.VALORCOPAGO), VP = SUM(b.VALORPCOMP)
			FROM hpre a with (nolock)
				join (select distinct NOPRESTACION from inserted) h on a.NOPRESTACION=h.NOPRESTACION
				left join hpred b with (nolock) on a.NOPRESTACION=b.NOPRESTACION and coalesce(b.NOCOBRABLE,0)=0
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
		-- 3998: Se ha detectado una transacci n no confirmable al final del lote. Se ha revertido la transacci n.  
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
  
  		if update (VALOR) or update(CANTIDAD) or update(VALORCOPAGO) or update(VALORPCOMP) or update(NOCOBRABLE)
		begin
			with mem1 as (
				SELECT a.NOPRESTACION, VT=SUM(b.VALOR * b.CANTIDAD), VE = SUM(b.VALOREXCEDENTE), VC = SUM(b.VALORCOPAGO), VP = SUM(b.VALORPCOMP)
				FROM hpre a with (nolock)
					join (select distinct NOPRESTACION from inserted) h on a.NOPRESTACION=h.NOPRESTACION
					left join hpred b with (nolock) on a.NOPRESTACION=b.NOPRESTACION and coalesce(b.NOCOBRABLE,0)=0
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
        
		if @TranCounter = 0  -- En un trigger en valor m nimo es 1, cuando hay cero o una transacci n abierta.  
			rollback transaction; -- en triggers nunca entra por ac   
		else   
		begin  
			-- ************ ADVERTENCIA con XACT_ABORT OFF ****************  
			rollback transaction SaveTranc_tra_HPRED_U;   
			-- SET XACT_ABORT OFF: Tenga en cuenta cuando est  presente en el trigger,   
			-- modo OFF es requerido para poder manipular eventos de error(catch) en triggers que afecten transacciones encadenadas. si no se usa SQL generara el error  
			--    3998: Se ha detectado una transacci n no confirmable al final del lote. Se ha revertido la transacci n.  
			--  
			-- 1. Cuidado, el rollback aqu  presente, que es de la transacci n guardada NO revierte cambios.  
			-- 2. Ei el triggers se desencaden  dentro de un try catch sin una transacci n previa, el catch revierte los cambios (rollback autom tico).  
			-- 3. Si antes de desencadenar el trigger existe al menos una transacci n abierta, el commit o rollback de esa transaci n ser n los que afecten lo sucedido.   
			-- Ej. si al eliminar un registro de esta tabla usted no usa try catch o no inicia transacci n, en caso de error la transacci n quedar  confirmada (commit).      
		end  
		raiserror(@ErrorMessage,16,1);      
	end catch  
end  
go

Drop Trigger if exists [dbo].[tra_HPRED_D]    
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

	if update (VALOR) or update(CANTIDAD) or update(VALORCOPAGO) or update(VALORPCOMP) or update(NOCOBRABLE)
	begin
		with mem1 as (
			SELECT a.NOPRESTACION, VT=SUM(b.VALOR * b.CANTIDAD), VE = SUM(b.VALOREXCEDENTE), VC = SUM(b.VALORCOPAGO), VP = SUM(b.VALORPCOMP)
			FROM hpre a with (nolock)
				join (select distinct NOPRESTACION from deleted) h on a.NOPRESTACION=h.NOPRESTACION
				left join hpred b with (nolock) on a.NOPRESTACION=b.NOPRESTACION and coalesce(b.NOCOBRABLE,0)=0
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
		left join hpred b with (nolock) on a.NOPRESTACION=b.NOPRESTACION and coalesce(b.NOCOBRABLE,0)=0
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


drop trigger dbo.tra_HPRE_BLOQDEV  
go
create trigger dbo.tra_HPRE_BLOQDEV  
on HPRE for insert,update  
as  
begin   
	set nocount on;  
 
 	-- Control para ignorar el trigger con context_info()  
	if context_info() = convert(varbinary(128),'Skip_Trigger_HPRE:All')  
		or context_info() = convert(varbinary(128),'Skip_Trigger_HPRE:tra_HPRE_BLOQDEV')  
		return;  

	declare 
		@Cant1 int, @Cant2 int;  
	
	select @Cant1=count(*), @Cant2=sum(b.FACTURADA) from deleted a join hpred b with(nolock) on a.NOPRESTACION=b.NOPRESTACION; 
	
	if @Cant2>0 and @Cant1=@Cant2  
	begin  
		raiserror('ERROR: La prestacion que intenta modificar se encuentra totalmente facturada.',16,1)  
		rollback transaction;
	end  
    
	declare   
		@dbloq varchar(80) = coalesce(dbo.fnk_ValorVariable('HPRE_BLOQ_DEVPENDINV'),''),  
		@canthbloq int = 0,  
		@NOADMISION varchar(20),  
		@cant int=0,  
		@horas decimal(14,2),  
		@shoras varchar(20),  
		@scant varchar(20),  
		@Minutos int,  
		@Bloq int,  
		@Tipo char(1),  
		@tiempo varchar(10),  
		@TipoBloq char(1);  
		--print @dbloq;   
  
	if update(PREFIJO)  
	begin  
		-- Mantiene actualizada la integridad de configuración de la prestación segun los parámetros del prefijo  
		update HPRE set ESDEINV=coalesce(c.MINVENTARIOS,0)  
		from HPRE a join inserted b on a.NOPRESTACION=b.NOPRESTACION join PRE c with(nolock) on b.PREFIJO=c.PREFIJO   
	end  
  
	if @dbloq<>'' and cast(@dbloq as int)>=0  
	begin  
		-- Solo prestaciones que mueven inventario que no sean ambulatorias
		select top 1 @NOADMISION=i.NOADMISION
		from inserted i 
			join HADM h with(nolock) on h.NOADMISION=i.NOADMISION and h.CLASEING<>'M'
			join HPRE p with(nolock) on p.NOPRESTACION=i.NOPRESTACION and p.ESDEINV=1;
  
		if coalesce(@NOADMISION,'')<>''
		begin
			select @TipoBloq=TipoBloq,@Tipo=Tipo, @Bloq=Bloq, @cant=Cant, @tiempo=Tiempo   
			from dbo.fnc_HADM_getTipoBloq(@NOADMISION);  
				/*if @Tipo='A'  
				begin  
				if @horas between @cantdbloq/2.00 and @cantdbloq  
				begin  
				select @shoras = convert(varchar,convert(decimal(8,2),@cantdbloq)/2), @scant=@cant;  
				raiserror('ADVERTENCIA: Esta Admisión contiene %s devoluciones pendientes por confirmar en Inventario con mas de %s horas de espera',16,1,@scant,@shoras);;  
				end  
				else  
				*/  
			if @Tipo='B'  
			begin  
				if @TipoBloq='A'  
					raiserror('  PACIENTE BLOQUEADO: Esta Admisión contiene %d devoluciones pendientes por confirmar en Inventario con el siguiente tiempo de espera: %s   ',16,1,@cant,@tiempo);  
				else  
				if @TipoBloq='U'
					raiserror('  USUARIO BLOQUEADO: Tiene %d devoluciones pendientes por confirmar en Inventario con el siguiente tiempo de espera: %s   ',16,1,@cant,@tiempo);  
				rollback transaction;  
				return;  
			end
		end
	end
	set nocount off;  
end  
go

-- 18.mar.2025
create index idx_HPRE_NOADMISION_FECHA_NOPRESTACION on HPRE (NOADMISION, FECHA DESC, NOPRESTACION DESC)
include(IDPLAN, IDAREAH, NIVELATENCION, IDAREA, IDSEDE, VALORTOTAL, VALORCOPAGO,
	VALOREXEDENTE, IMPRESO, USUARIO, VALORPCOMP, CIRUGIA, PCUBRIMIENTO, CONSECUTIVO, ESDEINV, PEDIDOINV, PREFIJO,
	IMPRESOP, COBRARA, IDTERCEROCA, ENLAB, LABO_RESESTADO, IDSERVICIOADM, ESPAQUETE
) with (online=on)
go

drop view if exists vwc_HPREHPRED_COUNT 
go
create view vwc_HPREHPRED_COUNT with schemabinding
as
	select NOPRESTACION,count_big(*) as CONT
	from dbo.HPRED group by NOPRESTACION
go
create unique clustered index pk_vwc_HPREHPRED_COUNT on vwc_HPREHPRED_COUNT(NOPRESTACION)
go

drop Trigger [dbo].[tra_HPRE_D]      
go
Create Trigger [dbo].[tra_HPRE_D]      
on [dbo].[HPRE] instead of delete      
as      
begin     
 if (select top (1) b.CONT from deleted a join vwc_HPREHPRED_COUNT b with(nolock) on a.NOPRESTACION=b.NOPRESTACION)>0    
 begin    
  raiserror('ERROR: La prestacion que intenta modificar tiene servicios cargados.',16,1)    
  rollback
  return
 end

 delete HPRE where NOPRESTACION in (select NOPRESTACION from deleted)
end    
go

CREATE NONCLUSTERED INDEX idx_IDEVD_CXPSPFIDIMOVHID ON [dbo].[IDEVD] ([CXPSPFID],[IMOVHID]) INCLUDE ([CANTIDADDEVUELTA])
GO
