-- 06.nov.2025
-- Variable que guarda el Dx CIE-11 de Ingreso en nuevas admisiones
insert into usvgs(IDVARIABLE, DESCRIPCION, TP_VARIABLE, DATO) 
values ('DXDEFAULTHADM_C11','Dx CIE-11 de Ingreso en nuevas admisiones','Alfanumerica','')
go

-- 27.nov.2025
alter table CIT add VALORPCOMP decimal(14,2);
alter table HPRE add VALORMODERADORA decimal(14,2);
alter table HPRED add VALORMODERADORA decimal(14,2);
alter table AUT add VALORPCOMP decimal(14,2);
alter table AUT add VALORMODERADORA decimal(14,2);
alter table AUTD add VALORPCOMP decimal(14,2);
alter table AUTD add VALORMODERADORA decimal(14,2);
go
exec sp_bindefault CERO, 'HPRED.VALORPCOMP';
exec sp_bindefault CERO, 'HPRE.VALORMODERADORA';
exec sp_bindefault CERO, 'HPRED.VALORMODERADORA';
exec sp_bindefault CERO, 'AUT.VALORPCOMP';
exec sp_bindefault CERO, 'AUT.VALORMODERADORA';
exec sp_bindefault CERO, 'AUTD.VALORPCOMP';
exec sp_bindefault CERO, 'AUTD.VALORMODERADORA';
go
alter table HPRED disable trigger all;
alter table HPRE disable trigger all;
alter table CIT disable trigger all;
alter table AUT disable trigger all;
alter table AUTD disable trigger all;
update CIT set VALORPCOMP = 0 where VALORPCOMP is null;
update HPRE set VALORMODERADORA = 0 where VALORMODERADORA is null;
update HPRED set VALORMODERADORA = 0 where VALORMODERADORA is null;
update AUT set VALORPCOMP = 0 where VALORPCOMP is null;
update AUT set VALORMODERADORA = 0 where VALORMODERADORA is null;
update AUTD set VALORPCOMP = 0 where VALORPCOMP is null;
update AUTD set VALORMODERADORA = 0 where VALORMODERADORA is null;
alter table HPRED enable trigger all;
alter table HPRE enable trigger all;
alter table CIT enable trigger all;
alter table AUT enable trigger all;
alter table AUTD enable trigger all;
go
/*
(27650 rows affected)
(3674321 rows affected)
(8306435 rows affected)
(26 rows affected)
(26 rows affected)
(48 rows affected)
(48 rows affected)
*/
--  00:21:29


-- Vista VW_PRE_HADM compilarla con el campo VALORMODERADORA
go

alter table CIT disable trigger all;
update CIT set TIPOCOPAGO='7' where TIPOCOPAGO = 'C';
update CIT set TIPOCOPAGO='8' where TIPOCOPAGO = 'M';
update CIT set TIPOCOPAGO='N' where TIPOCOPAGO = 'L';
alter table CIT enable trigger all;
go

-- Pasar las moderadoras cobradas a su nuevo campo
alter table HPRED disable trigger all;
update HPRED set VALORMODERADORA = VALORPCOMP, VALORPCOMP=0 where TIPOCOPAGO='8' and VALORPCOMP > 0
update HPRED set VALORMODERADORA = VALORCOPAGO, VALORCOPAGO=0 where TIPOCOPAGO='8' and VALORCOPAGO > 0
alter table HPRED enable trigger all;
go
-- 00:03:19



-- Resumen en HPRE
alter table HPRE disable trigger all;
with hd as (
	select NOPRESTACION, VALORCOPAGO=sum(isnull(VALORCOPAGO,0)), VALORPCOMP=sum(isnull(VALORPCOMP,0)), 
		VALORMODERADORA=SUM(isnull(b.VALORMODERADORA,0)), VALOREXCEDENTE=sum(isnull(VALOREXCEDENTE,0))   
	from HPRED b with(nolock) 
	group by NOPRESTACION
	having SUM(b.VALORMODERADORA)<>0
) 
update HPRE set VALORCOPAGO=hd.VALORCOPAGO, VALORPCOMP=hd.VALORPCOMP, VALORMODERADORA=hd.VALORMODERADORA, VALOREXEDENTE=hd.VALOREXCEDENTE  
from hpre h   
	join hd on hd.NOPRESTACION = h.NOPRESTACION;
alter table HPRE enable trigger all;
go
-- 00:01:32






