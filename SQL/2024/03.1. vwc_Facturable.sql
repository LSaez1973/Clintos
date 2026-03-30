drop View dbo.vwc_Facturable_HADM_Todas
go
Create View dbo.vwc_Facturable_HADM_Todas --with schemabinding
as
	select ORIGEN='HADM', b.IDTERCEROCA, b.COBRARA, a.IDSERVICIOADM, h.IDSEDE, a.NOADMISION, h.FECHAALTA, h.IDAREA_ALTA, h.CCOSTO_ALTA, 
		b.TIPOCONTRATO, b.TIPOTTEC, b.TIPOSISTEMA, h.IDAFILIADO, NOPRESTACION=a.NOPRESTACION, IDAUT=cast(null as varchar(13)), 
		CNSCIT=cast(null as varchar(16)), a.FECHA, NOITEM=b.NOITEM, a.PREFIJO, b.IDSERVICIO, c.DESCSERVICIO,
		b.CANTIDAD,VALOR=b.VALOR*g.C,VLR_SERVICI=B.VALOR*B.CANTIDAD*g.C,
		VALORCOPAGO = case when b.TIPOCOPAGO=8 then cast(0 as decimal(14,2)) else b.VALORCOPAGO end, 
		VALORMODERADORA = case when b.TIPOCOPAGO=8 then b.VALORCOPAGO else cast(0 as decimal(14,2)) end,
		VALORPCOMP=cast(0 as decimal(14,2)),
		DESCUENTO=coalesce(b.DESCUENTO,0), b.PCOSTO, b.FACTURADA, b.N_FACTURA, b.IDPROVEEDOR, a.IDAREA,a.CCOSTO,c.IDCUM,f.NOINVIMA,KCNTRID=cast(0 as decimal(14,2)),
		d.NUMCONTRATO,b.KNEGID,b.IDTARIFA, b.KCNTID, b.IDSERVICIOREL, h.AFIRCID, CNSFACT=Null, h.MARCA, h.CNSFCT, h.VFACTURAS, NOCOBRABLE=coalesce(b.NOCOBRABLE,0), 
		h.CLASEING, CAPITA=coalesce(d.CAPITA,2), h.CERRADA, b.FACTURABLE, h.CLASENOPROC, b.IDT, b.HPREDID,
		NOAUTORIZACION=	case when coalesce(b.NOAUTORIZACION,'')<>'' then b.NOAUTORIZACION else
							case when coalesce(a.NUMAUTORIZA,'')<>'' then a.NUMAUTORIZA else h.NOAUTORIZACION end 
						end,
		b.N_FACTURACOPAGO, b.CIVA, b.PIVA, b.VIVA
	from dbo.hadm h With (NoLock) 
		join dbo.hpre a With (NoLock) On h.NOADMISION=a.NOADMISION
		join dbo.hpred b With (NoLock) on a.NOPRESTACION=b.NOPRESTACION
		left join dbo.ser c With (NoLock) on b.IDSERVICIO=c.IDSERVICIO
		left join dbo.kcnt d With (NoLock) on b.KCNTID=d.KCNTID
		left join dbo.iart f With (NoLock) on c.IDARTICULO=f.IDARTICULO
		cross apply (select C=case when coalesce(b.NOCOBRABLE,0) = 0 then 1 else 0 end) g
go

drop View dbo.vwc_Facturable_xItems
go
Create View dbo.vwc_Facturable_xItems 
as
	select 
		ORIGEN,IDTERCEROCA,COBRARA,IDSERVICIOADM,IDSEDE,NOADMISION,FECHAALTA,IDAREA_ALTA,CCOSTO_ALTA,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,IDAFILIADO,NOPRESTACION,
		IDAUT,CNSCIT,FECHA,NOITEM,PREFIJO,IDSERVICIO,DESCSERVICIO,CANTIDAD,VALOR,VLR_SERVICI,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,PCOSTO,FACTURADA,
		N_FACTURA,IDPROVEEDOR,IDAREA,CCOSTO,IDCUM,NOINVIMA,KCNTRID,NUMCONTRATO,KNEGID,IDTARIFA,KCNTID,IDSERVICIOREL,AFIRCID,CNSFACT,MARCAFAC=MARCA,CNSFCT,VFACTURAS,
		NOCOBRABLE,CLASEING,CAPITA,IDT,HPREDID,NOAUTORIZACION,CERRADA,N_FACTURACOPAGO,CIVA,PIVA,VIVA
	from dbo.vwc_Facturable_HADM_Todas
	where FACTURABLE=1 and coalesce(CLASENOPROC,'')<>'NP'
go

drop View dbo.vwc_Facturable_HADM
go
Create View dbo.vwc_Facturable_HADM 
as
	select 
		ORIGEN,IDTERCEROCA,COBRARA,IDSERVICIOADM,IDSEDE,NOADMISION,FECHAALTA,IDAREA_ALTA,CCOSTO_ALTA,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,IDAFILIADO,NOPRESTACION,
		IDAUT,CNSCIT,FECHA,NOITEM,PREFIJO,IDSERVICIO,DESCSERVICIO,CANTIDAD,VALOR,VLR_SERVICI,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,PCOSTO,FACTURADA,
		N_FACTURA,IDPROVEEDOR,IDAREA,CCOSTO,IDCUM,NOINVIMA,KCNTRID,NUMCONTRATO,KNEGID,IDTARIFA,KCNTID,IDSERVICIOREL,AFIRCID,CNSFACT,MARCAFAC=MARCA,CNSFCT,VFACTURAS,
		NOCOBRABLE,CLASEING,CAPITA,IDT,HPREDID,NOAUTORIZACION,CERRADA,N_FACTURACOPAGO, CIVA, PIVA, VIVA
	from dbo.vwc_Facturable_HADM_Todas
	where CERRADA=1 and FACTURABLE=1 and coalesce(CLASENOPROC,'')<>'NP'
go

drop View vwc_Facturable_HADMOM
go
Create View dbo.vwc_Facturable_HADMOM 
as
	select ORIGEN='HADM-OM', b.IDTERCEROCA, b.COBRARA, a.IDSERVICIOADM, h.IDSEDE, a.NOADMISION, h.FECHAALTA, h.IDAREA_ALTA, h.CCOSTO_ALTA, 
		a.TIPOCONTRATO, a.TIPOTTEC, a.TIPOSISTEMA, a.IDAFILIADO, NOPRESTACION=cast(null as varchar(16)), IDAUT=a.IDAUT, CNSCIT=cast(null as varchar(16)), 
		a.FECHA, NOITEM=b.NO_ITEM, a.PREFIJO,b.IDSERVICIO,c.DESCSERVICIO, b.CANTIDAD,VALOR=b.VALOR*g.C,VLR_SERVICI=B.VALOR*B.CANTIDAD*g.C,
		VALORCOPAGO = case when b.TIPOCOPAGO=8 then cast(0 as decimal(14,2)) else b.VALORCOPAGO end, 
		VALORMODERADORA = case when b.TIPOCOPAGO=8 then b.VALORCOPAGO else cast(0 as decimal(14,2)) end,
		VALORPCOMP=cast(0 as decimal(14,2)),
		DESCUENTO=coalesce(a.DESCUENTO,0), b.PCOSTO, b.FACTURADA, b.N_FACTURA, 
		a.IDPROVEEDOR,a.IDAREA,a.CCOSTO,c.IDCUM,f.NOINVIMA,KCNTRID=cast(0 as int),d.NUMCONTRATO,b.KNEGID,b.IDTARIFA,d.KCNTID, IDSERVICIOREL=Null, a.AFIRCID, 
		a.CNSFACT, a.MARCAFAC, a.CNSFCT, a.VFACTURAS, NOCOBRABLE=coalesce(b.NOCOBRABLE,0), CLASEING='', CAPITA=coalesce(d.CAPITA,2), IDT=cast(null as varchar(20)), 
		HPREDID=b.AUTDID,NOAUTORIZACION=a.NUMAUTORIZA,CERRADA=1, b.N_FACTURACOPAGO, b.CIVA, b.PIVA, b.VIVA
	from dbo.aut a With (NoLock) 
		join dbo.autd b With (NoLock) on a.IDAUT=b.IDAUT
		left join dbo.ser c With (NoLock) on b.IDSERVICIO=c.IDSERVICIO
		left join dbo.kcnt d With (NoLock) on a.KCNTID=d.KCNTID 
		left join dbo.iart f With (NoLock) on c.IDARTICULO=f.IDARTICULO
		join dbo.hadm h With (NoLock) on a.NOADMISION=h.NOADMISION
		cross apply (select C=case when coalesce(b.NOCOBRABLE,0) = 0 then 1 else 0 end) g
	where h.CERRADA=1 and b.FACTURABLE=1 and coalesce(h.CLASENOPROC,'')<>'NP' -- and a.ESTADO='Atendido' 
		and 1=2 -- No se facturan, las OM se deben cargar por prestación, osea que se facturan por HADM
go

drop View dbo.vwc_Facturable_AUT
go
Create View dbo.vwc_Facturable_AUT 
as
	select ORIGEN='AUT', a.IDTERCEROCA, a.COBRARA, a.IDSERVICIOADM, a.IDSEDE, a.NOADMISION, FECHAALTA=a.FECHA, IDAREA_ALTA=a.IDAREA, CCOSTO_ALTA=a.CCOSTO, 
		a.TIPOCONTRATO, a.TIPOTTEC, a.TIPOSISTEMA, a.IDAFILIADO, NOPRESTACION=cast(null as varchar(16)), IDAUT=a.IDAUT, CNSCIT=cast(null as varchar(16)), 
		a.FECHA, NOITEM=b.NO_ITEM, a.PREFIJO, b.IDSERVICIO,c.DESCSERVICIO,b.CANTIDAD,VALOR=b.VALOR*g.C,VLR_SERVICI=B.VALOR*B.CANTIDAD*g.C,b.VALORCOPAGO,
		VALORPCOMP=cast(0 as decimal(14,2)),VALORMODERADORA=cast(0 as decimal(14,2)),DESCUENTO=coalesce(a.DESCUENTO,0),b.PCOSTO, b.FACTURADA, b.N_FACTURA, a.IDPROVEEDOR,
		a.IDAREA,a.CCOSTO,c.IDCUM,f.NOINVIMA,KCNTRID=cast(0 as int),d.NUMCONTRATO,b.KNEGID,b.IDTARIFA,d.KCNTID, IDSERVICIOREL=Null, a.AFIRCID, a.CNSFACT, a.MARCAFAC,
		b.CNSFCT, a.VFACTURAS, NOCOBRABLE=coalesce(b.NOCOBRABLE,0), CLASEING='', CAPITA=coalesce(d.CAPITA,2), b.IDT, 
		HPREDID=b.AUTDID,NOAUTORIZACION=a.NUMAUTORIZA,CERRADA=1, b.N_FACTURACOPAGO, b.CIVA, b.PIVA, b.VIVA 
	from dbo.aut a With (NoLock) 
		join dbo.autd b With (NoLock) on a.IDAUT=b.IDAUT
		left join dbo.ser c With (NoLock) on b.IDSERVICIO=c.IDSERVICIO
		left join dbo.kcnt d With (NoLock) on a.KCNTID=d.KCNTID 
		left join dbo.iart f With (NoLock) on c.IDARTICULO=f.IDARTICULO
		cross apply (select C=case when coalesce(b.NOCOBRABLE,0) = 0 then 1 else 0 end) g
	where b.FACTURABLE=1 --and a.ESTADO='Atendido' 
go

drop View dbo.vwc_Facturable_CIT
go
Create View dbo.vwc_Facturable_CIT 
as
	select ORIGEN='CIT', a.IDTERCEROCA, a.COBRARA, a.IDSERVICIOADM, a.IDSEDE, a.NOADMISION, FECHAALTA=a.FECHA, IDAREA_ALTA=a.IDAREA, CCOSTO_ALTA=a.CCOSTO, 
		a.TIPOCONTRATO, a.TIPOTTEC, a.TIPOSISTEMA, a.IDAFILIADO, 
		NOPRESTACION=cast(null as varchar(16)), IDAUT=cast(null as varchar(16)), CNSCIT=a.CONSECUTIVO, a.FECHA, NOITEM=cast(1 as int), c.PREFIJO, a.IDSERVICIO,c.DESCSERVICIO,
		CANTIDAD=1,VALORTOTAL=a.VALORTOTAL*g.C,VLR_SERVICI=a.VALORTOTAL*g.C,a.VALORCOPAGO,VALORPCOMP=cast(0 as decimal(14,2)),a.VALORMODERADORA,DESCUENTO=coalesce(a.DESCUENTO,0),
		PCOSTO=a.VALORTOTALCOS, a.FACTURADA, a.N_FACTURA, IDPROVEEDOR=a.IDMEDICO,
		a.IDAREA,a.CCOSTO,c.IDCUM,f.NOINVIMA,KCNTRID=cast(0 as int),d.NUMCONTRATO,a.KNEGID,a.IDTARIFA,d.KCNTID, IDSERVICIOREL=Null, a.AFIRCID, a.CNSFACT, a.MARCAFAC,
		a.CNSFCT, a.VFACTURAS, NOCOBRABLE=coalesce(a.NOCOBRABLE,0), CLASEING='', CAPITA=coalesce(d.CAPITA,2), a.IDT, 
		HPREDID=a.CITID, a.NOAUTORIZACION,CERRADA=1, a.N_FACTURACOPAGO, a.CIVA, a.PIVA, a.VIVA
	from dbo.cit a With (NoLock) 
		left join dbo.ser c With (NoLock) on a.IDSERVICIO=c.IDSERVICIO
		left join dbo.kcnt d With (NoLock) on a.KCNTID=d.KCNTID 
		left join dbo.iart f With (NoLock) on c.IDARTICULO=f.IDARTICULO
		cross apply (select C=case when coalesce(a.NOCOBRABLE,0) = 0 then 1 else 0 end) g
	where a.FACTURABLE=1 and Not a.FECHALLEGA Is null
go

drop View dbo.vwc_Facturable
go
Create View dbo.vwc_Facturable
as
	select * from dbo.vwc_Facturable_HADM
	/* No se facturan, las OM se deben cargar por prestación, osea que se facturan por HADM
	union all 
	select * from dbo.vwc_Facturable_HADMOM*/
	union all
	select * from dbo.vwc_Facturable_AUT
	union all
	select * from dbo.vwc_Facturable_CIT
go

-- select * from vwc_Facturable
-- select * from vwc_Facturable where VIVA>0


drop VIEW [dbo].[VW_PRE_HADM]
go
-- -----------------------------------------  
CREATE VIEW [dbo].[VW_PRE_HADM]    
AS    
	SELECT FMAS.CNSFMAS, HPRE.NOADMISION, HPRE.NOPRESTACION, PRE.PREFIJO, HPRED.IDSERVICIO, HPRED.VALOR, HPRED.CANTIDAD,    
		vt.VALORTOTAL, VALORCOPAGO = coalesce(HPRED.VALORCOPAGO,0), /*+ cop.COPAGO_DIST*/ 
		VALORPCOMP=coalesce(HPRED.VALORPCOMP,0), ve.VALOREXCEDENTE, HPRED.IDCIRUGIA, HPRED.TIPOSERCIRUGIA,
		NOAUTORIZACION_HADM=HADM.NOAUTORIZACION, NOAUTORIZACION_HPRE=HPRE.NUMAUTORIZA, NOAUTORIZACION_HPRED=HPRED.NOAUTORIZACION, 
		VALORCOPAGO_HADM=coalesce(HADM.COPAGOVALOR,0), HPRED.NOITEM, HPRED.HPREDID, HPRED.CIVA, HPRED.PIVA, HPRED.VIVA
	FROM HPRED with(nolock)
		join HPRE with(nolock) on HPRED.NOPRESTACION = HPRE.NOPRESTACION    
		join SER with(nolock) on HPRED.IDSERVICIO = SER.IDSERVICIO
		join PRE with(nolock) on SER.PREFIJO = PRE.PREFIJO 
		join FMASD with(nolock) on HPRE.NOADMISION = FMASD.NOADMISION
		join FMAS with(nolock) on FMAS.CNSFMAS = FMASD.CNSFMAS		
		join HADM with(nolock) on HPRE.NOADMISION = HADM.NOADMISION
		cross apply (select VALORTOTAL = ((coalesce(HPRED.VALOR,0)+coalesce(HPRED.VIVA,0)) * coalesce(HPRED.CANTIDAD,0))) vt
		--cross apply (select VALORTOTAL = sum(vt.VALORTOTAL) over (partition by HADM.NOADMISION)) th
		--cross apply (select COPAGO_DIST = case when th.VALORTOTAL=0 then 0 else ((coalesce(HADM.COPAGOVALOR,0) * vt.VALORTOTAL) / th.VALORTOTAL) end) cop
		cross apply (select VALOREXCEDENTE = vt.VALORTOTAL - coalesce(HPRED.VALORCOPAGO,0) - coalesce(HPRED.VALORPCOMP,0)/*- cop.COPAGO_DIST*/) ve
go
