use DxContable
go
drop view vwdx_INV_VentasPacientes_Clintos_con_LOTESERIE 
go
create view vwdx_INV_VentasPacientes_Clintos_con_LOTESERIE --with schemabinding  
as   
 select b.IDARTICULO, g.DESCRIPCION, c.PROCEDENCIA, c.NOADMISION, c.NOPRESTACION, b.HPREDID,  
  b.MANLOTESERIE, l.LOTESERIE, b.UBICACION, l.FECHAVENCE, l.CANTIDAD, DEVOLUCIONES=isnull(l.DEVOLUCIONES,0),   
  DISPONIBLES=l.CANTIDAD-isnull(l.DEVOLUCIONES,0), b.IDTRANSACCION, b.NUMDOCUMENTO,   
  CNSMOV=a.NUMDOCPED, b.ITEM, IMOVHID=b.FILA, IMOVHDID=l.AUTONUMBER, l.ITEMD, a.FECHACONF, b.PCOSTO, b.IDBODEGA  
 from dbo.IMOVH b   
  join dbo.IMOVSS c on c.IDTRANSACCION=b.IDTRANSACCION and c.NUMDOCUMENTO=b.NUMDOCUMENTO  
  join dbo.IMOVHD l on l.IDTRANSACCION=b.IDTRANSACCION and l.NUMDOCUMENTO=b.NUMDOCUMENTO   
   and l.IDARTICULO=b.IDARTICULO and l.ITEM=b.ITEM and b.CANTIDAD>0  
  join dbo.IMOV a on a.IDTRANSACCION=b.IDTRANSACCION and a.NUMDOCUMENTO=b.NUMDOCUMENTO and a.ESTADO='1'  
  join dbo.IART g on b.IDARTICULO = g.IDARTICULO   
 where b.IDTRANSACCION='SAL' and b.ESTADO=1 and b.CANTIDAD>0 and b.MANLOTESERIE=1    
go

drop view vwdx_INV_VentasPacientes_Clintos_sin_LOTESERIE
go
-- Ventas de Salud de articulo que no manejan lote  
create view vwdx_INV_VentasPacientes_Clintos_sin_LOTESERIE --with schemabinding  
as   
 select b.IDARTICULO, g.DESCRIPCION, c.PROCEDENCIA, c.NOADMISION, c.NOPRESTACION, b.HPREDID,   
  b.MANLOTESERIE, LOTESERIE=isnull(b.LOTESERIE,''), UBICACION=b.UBICACION, b.FECHAVENCE,  
  b.CANTIDAD, DEVOLUCIONES=isnull(b.DEVOLUCIONES,0), DISPONIBLES=b.CANTIDAD-isnull(b.DEVOLUCIONES,0),   
  a.IDTRANSACCION, a.NUMDOCUMENTO, CNSMOV=a.NUMDOCPED, IMOVHID=b.FILA, b.ITEM, a.FECHACONF, b.PCOSTO, b.IDBODEGA   
 from dbo.IMOVH b      
  join dbo.IMOV a on b.ESTADO=1 and b.CANTIDAD>0 and b.MANLOTESERIE=0      
   and a.IDTRANSACCION='SAL' and a.ESTADO='1'  
   and b.IDTRANSACCION=a.IDTRANSACCION and b.NUMDOCUMENTO=a.NUMDOCUMENTO   
  join dbo.IMOVSS c on c.IDTRANSACCION=a.IDTRANSACCION and c.NUMDOCUMENTO=a.NUMDOCUMENTO  
   --and c.PROCEDENCIA = 'SALUD' --in ('SALUD','CE','QXCX','QXPRO','PYP')   
  join dbo.IART g on b.IDARTICULO = g.IDARTICULO   
go

use Oncomedica8
go

drop Trigger [dbo].[tra_HADM_Cierre]
go
-- Inventario: Clintos->DxContable
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
			-- DxContable
			select @mess = @mess + char(9)+cast(DESCRIPCION as char(30)) + str(IMOV) + char(13)+char(10)
			from (
				select c.DESCRIPCION, IMOV=count(*) 
				from DxContable.dbo.IMOVSS a with(nolock)
					join DxContable.dbo.IMOV m with(nolock) on a.IDTRANSACCION=m.IDTRANSACCION and a.NUMDOCUMENTO=m.NUMDOCUMENTO 
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
drop function if exists dbo.fnc_INV_VentasPacientes_xNOADMISION
go
-- *Contiene consulta unida de movimientos de ambas BD 
create function dbo.fnc_INV_VentasPacientes_xNOADMISION(@NOADMISION varchar(20), @PROCEDENCIA varchar(20)) 
returns table as return(
	select b.IDARTICULO, b.HPREDID, b.IMOVHID, b.IMOVHDID, b.MANLOTESERIE, b.NOLOTE, b.UBICACION, b.FECHAVENCE,
		DISPONIBLES=sum(b.DISPONIBLES), CANTIDAD=sum(b.CANTIDAD), DEVOLUCIONES=sum(b.DEVOLUCIONES), b.PCOSTO, b.IDBODEGA 
	from (
			-- * PROCEDENCIA QXPRO: NOADMISION=CXPS.NOADMISION (a veces null), NOPRESTACION=CXPS.NOPROGRAMACION,  HPREDID=CXPSPF.CXPSPFID
		-- Con LOTESERIE: IMOVHID será IMOVHD.AUTONUMBER
		select IDARTICULO=a.IDARTICULO collate database_default, 
			a.MANLOTESERIE, NOLOTE=a.LOTESERIE collate database_default, UBICACION=a.UBICACION collate database_default, a.FECHAVENCE,
			a.CANTIDAD, a.DEVOLUCIONES, a.DISPONIBLES, a.IDTRANSACCION, a.NUMDOCUMENTO, PROCEDENCIA=a.PROCEDENCIA collate database_default, 
			TABLA='IMOVHD', a.NOADMISION, NOPRESTACION=a.NOPRESTACION collate database_default, a.HPREDID, 
			CNSMOV=a.CNSMOV collate database_default, a.IMOVHID, a.ITEM, a.IMOVHDID, a.ITEMD, FECHA=a.FECHACONF, a.PCOSTO, IDBODEGA=a.IDBODEGA collate database_default    
		from DxContable.dbo.vwdx_INV_VentasPacientes_Clintos_con_LOTESERIE a with(nolock/*,noexpand*/) 
		where a.NOADMISION = @NOADMISION and a.PROCEDENCIA=@PROCEDENCIA --a.PROCEDENCIA in ('SALUD','QXPRO')
		union all
		-- Sin LOTESERIE: IMOVHID será IMOVH.FILA
		select IDARTICULO=a.IDARTICULO collate database_default,  
			a.MANLOTESERIE, NOLOTE=a.LOTESERIE collate database_default, UBICACION=a.UBICACION collate database_default, a.FECHAVENCE,
			a.CANTIDAD, a.DEVOLUCIONES, a.DISPONIBLES, IDTRANSACCION=a.IDTRANSACCION collate database_default, NUMDOCUMENTO=a.NUMDOCUMENTO collate database_default, 
			PROCEDENCIA=a.PROCEDENCIA collate database_default, TABLA='IMOVH', NOADMISION=a.NOADMISION collate database_default, 
			NOPRESTACION=a.NOPRESTACION collate database_default, a.HPREDID, 
			CNSMOV=a.CNSMOV collate database_default, a.IMOVHID, a.ITEM, IMOVHDID=null, ITEMD=null, FECHA=a.FECHACONF, a.PCOSTO, IDBODEGA=a.IDBODEGA collate database_default   
		from DxContable.dbo.vwdx_INV_VentasPacientes_Clintos_sin_LOTESERIE a with(nolock/*,noexpand*/)
			left join DxContable.dbo.IMOVHD l with(nolock) on l.IDTRANSACCION=a.IDTRANSACCION and l.NUMDOCUMENTO=a.NUMDOCUMENTO 
				and l.IDARTICULO=a.IDARTICULO and l.ITEM=a.ITEM 
		where a.NOADMISION = @NOADMISION and a.PROCEDENCIA=@PROCEDENCIA --and a.PROCEDENCIA in ('SALUD','QXPRO') 
			and l.NUMDOCUMENTO is null 
		union all
		-- Inv.Asistencial
		select IDARTICULO=a.IDARTICULO collate database_default,  
			MANLOTESERIE=1, NOLOTE=a.NOLOTE collate database_default, UBICACION=a.UBICACION collate database_default, a.FECHAVENCE,
			a.CANTIDAD, a.DEVOLUCIONES, a.DISPONIBLES, IDTRANSACCION=null, NUMDOCUMENTO=null, PROCEDENCIA=a.PROCEDENCIA collate database_default, 
			TABLA='IMOVH', NOADMISION=a.NOADMISION collate database_default, NOPRESTACION=a.NOPRESTACION collate database_default, a.HPREDID, 
			CNSMOV=a.CNSMOV collate database_default, a.IMOVHID, a.ITEM, IMOVHDID=null, ITEMD=null, FECHA=a.FECHACONF, a.PCOSTO, a.IDBODEGA   
		from vwc_INV_VentasPacientes_HPRED a with(nolock,noexpand) 
		where a.NOADMISION = @NOADMISION and a.PROCEDENCIA=@PROCEDENCIA -- and a.PROCEDENCIA in ('SALUD','QXPRO')
	) b
	group by b.IDARTICULO, b.HPREDID, b.IMOVHID, b.IMOVHDID, b.MANLOTESERIE, b.NOLOTE, b.UBICACION, b.FECHAVENCE, b.PCOSTO, b.IDBODEGA
)	
go


drop function if exists dbo.fnc_INV_VentasPacientes_xNOPROGRAMACION
go
-- *Contiene consulta unida de movimientos de ambas BD 
create function dbo.fnc_INV_VentasPacientes_xNOPROGRAMACION(@NOPROGRAMACION varchar(20), @PROCEDENCIA varchar(20)) 
returns table as return(
	select b.IDARTICULO, b.HPREDID, b.IMOVHID, b.IMOVHDID, b.MANLOTESERIE, b.NOLOTE, b.UBICACION, b.FECHAVENCE,
		DISPONIBLES=sum(b.DISPONIBLES), CANTIDAD=sum(b.CANTIDAD), DEVOLUCIONES=sum(b.DEVOLUCIONES), b.PCOSTO, b.IDBODEGA 
	from (
			-- * PROCEDENCIA QXPRO: NOADMISION=CXPS.NOADMISION (a veces null), NOPRESTACION=CXPS.NOPROGRAMACION,  HPREDID=CXPSPF.CXPSPFID
		-- Con LOTESERIE: IMOVHID será IMOVHD.AUTONUMBER
		select IDARTICULO=a.IDARTICULO collate database_default, 
			a.MANLOTESERIE, NOLOTE=a.LOTESERIE collate database_default, UBICACION=a.UBICACION collate database_default, a.FECHAVENCE,
			a.CANTIDAD, a.DEVOLUCIONES, a.DISPONIBLES, a.IDTRANSACCION, a.NUMDOCUMENTO, PROCEDENCIA=a.PROCEDENCIA collate database_default, 
			TABLA='IMOVHD', a.NOADMISION, NOPRESTACION=a.NOPRESTACION collate database_default, a.HPREDID, 
			CNSMOV=a.CNSMOV collate database_default, a.IMOVHID, a.ITEM, a.IMOVHDID, a.ITEMD, FECHA=a.FECHACONF, a.PCOSTO, IDBODEGA=a.IDBODEGA collate database_default   
		from DxContable.dbo.vwdx_INV_VentasPacientes_Clintos_con_LOTESERIE a with(nolock/*,noexpand*/) 
		where a.NOPRESTACION = @NOPROGRAMACION and a.PROCEDENCIA=@PROCEDENCIA --a.PROCEDENCIA in ('SALUD','QXPRO')
		union all
		-- Sin LOTESERIE: IMOVHID será IMOVH.FILA
		select IDARTICULO=a.IDARTICULO collate database_default,  
			a.MANLOTESERIE, NOLOTE=a.LOTESERIE collate database_default, UBICACION=a.UBICACION collate database_default, a.FECHAVENCE,
			a.CANTIDAD, a.DEVOLUCIONES, a.DISPONIBLES, IDTRANSACCION=a.IDTRANSACCION collate database_default, NUMDOCUMENTO=a.NUMDOCUMENTO collate database_default, 
			PROCEDENCIA=a.PROCEDENCIA collate database_default, TABLA='IMOVH', NOADMISION=a.NOADMISION collate database_default, 
			NOPRESTACION=a.NOPRESTACION collate database_default, a.HPREDID, 
			CNSMOV=a.CNSMOV collate database_default, a.IMOVHID, a.ITEM, IMOVHDID=null, ITEMD=null, FECHA=a.FECHACONF, a.PCOSTO, IDBODEGA=a.IDBODEGA collate database_default   
		from DxContable.dbo.vwdx_INV_VentasPacientes_Clintos_sin_LOTESERIE a with(nolock/*,noexpand*/)
			left join DxContable.dbo.IMOVHD l with(nolock) on l.IDTRANSACCION=a.IDTRANSACCION and l.NUMDOCUMENTO=a.NUMDOCUMENTO 
				and l.IDARTICULO=a.IDARTICULO and l.ITEM=a.ITEM 
		where a.NOPRESTACION = @NOPROGRAMACION and a.PROCEDENCIA=@PROCEDENCIA --and a.PROCEDENCIA in ('SALUD','QXPRO') 
			and l.NUMDOCUMENTO is null 
		union all
		-- Inv.Asistencial
		select IDARTICULO=a.IDARTICULO collate database_default,  
			MANLOTESERIE=1, NOLOTE=a.NOLOTE collate database_default, UBICACION=a.UBICACION collate database_default, a.FECHAVENCE,
			a.CANTIDAD, a.DEVOLUCIONES, a.DISPONIBLES, IDTRANSACCION=null, NUMDOCUMENTO=null, PROCEDENCIA=a.PROCEDENCIA collate database_default, 
			TABLA='IMOVH', NOADMISION=a.NOADMISION collate database_default, NOPRESTACION=a.NOPRESTACION collate database_default, a.HPREDID, 
			CNSMOV=a.CNSMOV collate database_default, a.IMOVHID, a.ITEM, IMOVHDID=null, ITEMD=null, FECHA=a.FECHACONF, a.PCOSTO, a.IDBODEGA   
		from vwc_INV_VentasPacientes_HPRED a with(nolock,noexpand) 
		where a.NOPRESTACION = @NOPROGRAMACION and a.PROCEDENCIA=@PROCEDENCIA -- and a.PROCEDENCIA in ('SALUD','QXPRO')
	) b
	group by b.IDARTICULO, b.HPREDID, b.IMOVHID, b.IMOVHDID, b.MANLOTESERIE, b.NOLOTE, b.UBICACION, b.FECHAVENCE, b.PCOSTO, b.IDBODEGA
)	
go