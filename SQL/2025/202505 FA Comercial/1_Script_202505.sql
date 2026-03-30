alter table KCNT add TIPOFACTURA varchar(1);
go
update KCNT set TIPOFACTURA='S' where TIPOFACTURA is null;
go
alter table FTR disable trigger all;
update FTR set CLASE='S';
alter table FTR enable trigger all;
go
update MND set SIMBOLO='$' where IDMONEDA='01';
update MND set SIMBOLO='USD $' where IDMONEDA='02';
go

