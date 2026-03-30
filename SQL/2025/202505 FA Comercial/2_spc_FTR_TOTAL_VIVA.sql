drop procedure spc_FTR_TOTAL_VIVA;
go
create procedure spc_FTR_TOTAL_VIVA(@N_FACTURA varchar(16))
as
begin
	alter table ftrd disable trigger all;
	
	with biva as (
		select f.N_FACTURA, f.CNSFCT, b.*, i.TIVA
		From FTR f with(nolock)
			cross apply (
				select d.PIVA, BASEIVA=sum(d.VLR_SERVICI)
				From FTRD d with(nolock) 
				where d.CNSFTR=f.CNSFCT and d.PIVA>0 
				group by d.PIVA
			) b
			cross apply (select TIVA=cast(b.PIVA*b.BASEIVA*0.01 as decimal(14,0))) i
		where f.N_FACTURA = @N_FACTURA
	)
	--select d.REFERENCIA, d.VALOR, d.CANTIDAD, d.VLR_SERVICI, d.PIVA, d.VIVA, ni.nVIVA, d.VR_TOTAL, nv.nVR_TOTAL, b.BASEIVA, b.TIVA
	update d set VIVA=ni.nVIVA, VR_TOTAL=nv.nVR_TOTAL
	from biva b
		join FTRD d with(nolock) on d.CNSFTR=b.CNSFCT and d.PIVA=b.PIVA and d.PIVA>0
		cross apply (select nVIVA = cast((d.VLR_SERVICI * b.TIVA) / b.BASEIVA as decimal(14,2))) ni
		cross apply (select nVR_TOTAL = round(d.VLR_SERVICI + ni.nVIVA,0)) nv;

	-- Ajuste del por redondeo
	with biva as (
		select f.N_FACTURA, f.CNSFCT, b.*, i.TIVA, AJUSTE=i.TIVA-b.VIVA
		From FTR f with(nolock)
			cross apply (
				select d.PIVA, BASEIVA=sum(d.VLR_SERVICI), VIVA=sum(VIVA)
				From FTRD d with(nolock) 
				where d.CNSFTR=f.CNSFCT and d.PIVA>0 
				group by d.PIVA
			) b
			cross apply (select TIVA=cast(b.PIVA*b.BASEIVA*0.01 as decimal(14,0))) i
		where f.N_FACTURA = @N_FACTURA
	)
	update d set VIVA=d.VIVA+b.AJUSTE, VR_TOTAL=round(d.VR_TOTAL+b.AJUSTE,0)
	from biva b
		cross apply (
			select top (1) c.FTRDID 
			from FTRD c with(nolock) where c.CNSFTR=b.CNSFCT and c.PIVA=b.PIVA and c.PIVA>0
		) c 
		join FTRD d on d.FTRDID=c.FTRDID
	where b.AJUSTE<>0

	alter table ftrd enable trigger all;

	alter table ftr disable trigger all;	
	update f set VIVA=d.VIVA, VR_TOTAL=nt.nVLR_TOTAL
	--select f.VR_TOTAL, nt.nVLR_TOTAL, Diff=f.VR_TOTAL - nt.nVLR_TOTAL, f.VIVA, b.nVIVA, deiffIVA= f.VIVA-b.nVIVA  
	from ftr f with(nolock)
		cross apply (select VLR_SERVICI = sum(VLR_SERVICI), VIVA=sum(VIVA) from ftrd d with(nolock) where d.CNSFTR=f.CNSFCT) d
		cross apply (select nVLR_TOTAL = d.VLR_SERVICI + d.VIVA - f.VALORCOPAGO - f.VALORMODERADORA - f.VALORPCOMP - f.DESCUENTO) nt
	where f.N_FACTURA = @N_FACTURA;
	alter table ftr enable trigger all;
end
go

/*
drop procedure spc_FTR_TOTAL_VIVA;
go
create procedure spc_FTR_TOTAL_VIVA(@N_FACTURA varchar(16))
as
begin
	alter table ftrd disable trigger all;
	
	with biva as (
		select f.N_FACTURA, f.CNSFCT, b.*, i.TIVA
		From FTR f with(nolock)
			cross apply (
				select d.PIVA, BASEIVA=sum(d.VLR_SERVICI)
				From FTRD d with(nolock) 
				where d.CNSFTR=f.CNSFCT and d.PIVA>0 
				group by d.PIVA
			) b
			cross apply (select TIVA=cast(b.PIVA*b.BASEIVA*0.01 as decimal(14,0))) i
		where f.N_FACTURA = @N_FACTURA
	)
	--select d.REFERENCIA, d.VALOR, d.CANTIDAD, d.VLR_SERVICI, d.PIVA, d.VIVA, ni.nVIVA, d.VR_TOTAL, nv.nVR_TOTAL, b.BASEIVA, b.TIVA
	update d set VIVA=ni.nVIVA, VR_TOTAL=nv.nVR_TOTAL
	from biva b
		join FTRD d with(nolock) on d.CNSFTR=b.CNSFCT and d.PIVA=b.PIVA and d.PIVA>0
		cross apply (select nVIVA = cast((d.VLR_SERVICI * b.TIVA) / b.BASEIVA as decimal(14,0))) ni
		cross apply (select nVR_TOTAL = d.VLR_SERVICI + ni.nVIVA) nv;

	-- Ajuste del por redondeo
	with biva as (
		select f.N_FACTURA, f.CNSFCT, b.*, i.TIVA, AJUSTE=i.TIVA-b.VIVA
		From FTR f with(nolock)
			cross apply (
				select d.PIVA, BASEIVA=sum(d.VLR_SERVICI), VIVA=sum(VIVA)
				From FTRD d with(nolock) 
				where d.CNSFTR=f.CNSFCT and d.PIVA>0 
				group by d.PIVA
			) b
			cross apply (select TIVA=cast(b.PIVA*b.BASEIVA*0.01 as decimal(14,0))) i
		where f.N_FACTURA = @N_FACTURA
	)
	update d set VIVA=d.VIVA+b.AJUSTE, VR_TOTAL=d.VR_TOTAL+b.AJUSTE
	from biva b
		cross apply (
			select top (1) c.FTRDID 
			from FTRD c with(nolock) where c.CNSFTR=b.CNSFCT and c.PIVA=b.PIVA and c.PIVA>0
		) c 
		join FTRD d on d.FTRDID=c.FTRDID
	where b.AJUSTE<>0

	alter table ftrd enable trigger all;

	alter table ftr disable trigger all;	
	update f set VIVA=d.VIVA, VR_TOTAL=nt.nVLR_TOTAL
	--select f.VR_TOTAL, nt.nVLR_TOTAL, Diff=f.VR_TOTAL - nt.nVLR_TOTAL, f.VIVA, b.nVIVA, deiffIVA= f.VIVA-b.nVIVA  
	from ftr f with(nolock)
		cross apply (select VLR_SERVICI = sum(VLR_SERVICI), VIVA=sum(VIVA) from ftrd d with(nolock) where d.CNSFTR=f.CNSFCT) d
		cross apply (select nVLR_TOTAL = d.VLR_SERVICI + d.VIVA - f.VALORCOPAGO - f.VALORMODERADORA - f.VALORPCOMP - f.DESCUENTO) nt
	where f.N_FACTURA = @N_FACTURA;
	alter table ftr enable trigger all;
end
go
*/