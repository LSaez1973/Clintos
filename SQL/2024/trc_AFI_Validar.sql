-- Validar el tipo documento para menor de edad de 7 años y 18 años
alter table AFI add VALIDAEDADIPODOC bit;
alter table AFI add GRUPOPOBLACIONAL varchar(20);
go
-- eliminar default de pais COL
alter table CIU drop constraint DF__CIU__IDPAIS__473D5B1E;
go
alter table CIU add constraint DF_Blanco default '' for IDPAIS; 
go
sp_bindefault CERO, 'AFI.VALIDAEDADIPODOC'
go
alter table AFI disable trigger all
update afi set VALIDAEDADIPODOC=0 where VALIDAEDADIPODOC is null
alter table AFI enable trigger all
go
create index idx_AFI_CNS on AFI(CNS) include(IDAFILIADO,TIPO_DOC,DOCIDAFILIADO,FNACIMIENTO,IDPAIS,CIUDAD) with(online=on);
go
alter table HPRE add DURACIONTTO int; -- Duración Tratamiento
alter table HPRE add TIPOCOPAGO VARCHAR(20); -- Tipo Copago
alter table HPRE add N_FACTURACOPAGO varchar(16); -- No. Factura Copago
alter table HPRED add DURACIONTTO int; -- Duración Tratamiento
alter table HPRED add TIPOCOPAGO VARCHAR(20); -- Tipo Copago
-- alter table HPRED add N_FACTURACOPAGO varchar(16); -- No. Factura Copago
alter table AUT add DURACIONTTO int; -- Duración Tratamiento
alter table AUT add TIPOCOPAGO VARCHAR(20); -- Tipo Copago
-- alter table AUT add N_FACTURACOPAGO varchar(16); -- No. Factura Copago
alter table AUTD add DURACIONTTO int; -- Duración Tratamiento
alter table AUTD add TIPOCOPAGO VARCHAR(20); -- Tipo Copago
alter table AUTD add N_FACTURACOPAGO varchar(16); -- No. Factura Copago
alter table CIT add DURACIONTTO int; -- Duración Tratamiento
alter table CIT add TIPOCOPAGO VARCHAR(20); -- Tipo Copago
-- alter table CIT add N_FACTURACOPAGO varchar(16); -- No. Factura Copago
go

alter table PRE add REQ_DURACIONTTO smallint; -- Requiere Duración Tratamiento
go
update PRE set REQ_DURACIONTTO = 0 where REQ_DURACIONTTO is null;
go

-- Antes de continuar, Debe ejecutar vwa_HADM.sql
go

alter table HADM alter column VIAINGRESO varchar(10);
alter table HADM alter column CAUSAEXTERNA varchar(10);
alter table HADM alter column DESTINO varchar(20);
go

create index idx_HPRED_N_FACTURACOPAGO on HPRED(N_FACTURACOPAGO) with(online=on);
create index idx_AUTD_N_FACTURACOPAGO on AUTD(N_FACTURACOPAGO) with(online=on);
create index idx_CIT_N_FACTURACOPAGO on CIT(N_FACTURACOPAGO) with(online=on);
go

/*
update TGEN set DATO1='MENOR03M' where TABLA='AFI' and CAMPO='TIPO_DOC' AND CODIGO in ('RC','MS','CN');
update TGEN set DATO1='MENOR01A' where TABLA='AFI' and CAMPO='TIPO_DOC' AND CODIGO in ('RC','CN');
update TGEN set DATO1='MENOR07A' where TABLA='AFI' and CAMPO='TIPO_DOC' AND CODIGO='RC';
update TGEN set DATO1='MENOR18A' where TABLA='AFI' and CAMPO='TIPO_DOC' AND DATO1='MENOR18';
update TGEN set DATO1='TODOS' where TABLA='AFI' and CAMPO='TIPO_DOC' AND DATO1='AMBOS';
go

-- el campo TGEN.DATO1 indica el tipo de documento correcto según la edad
SELECT * FROM TGEN WHERE TABLA='AFI' AND CAMPO='TIPO_DOC' and DATO1 in ('MENOR03M') union all
SELECT * FROM TGEN WHERE TABLA='AFI' AND CAMPO='TIPO_DOC' and DATO1 in ('MENOR01A') union all
SELECT * FROM TGEN WHERE TABLA='AFI' AND CAMPO='TIPO_DOC' and DATO1 in ('MENOR07A') union all
SELECT * FROM TGEN WHERE TABLA='AFI' AND CAMPO='TIPO_DOC' and DATO1 in ('MENOR18A') union all
SELECT * FROM TGEN WHERE TABLA='AFI' AND CAMPO='TIPO_DOC' and DATO1 in ('MAYOR') union all
SELECT * FROM TGEN WHERE TABLA='AFI' AND CAMPO='TIPO_DOC' and DATO1 in ('TODOS')
go

drop table TGENDATO1D
drop table TGENDATO1
go
*/

-- TGEN: Grupos de opciones para TGEN
create table TGENG (
	TABLA varchar(15) not null, --			Ej. AFI
	CAMPO varchar(20) not null, --			Ej. TIPO_DOC
	GRUPO varchar(255) not null,--			Ej. EDADES
	DESCRIPCION varchar(50) not null, --	Ej. Tipos de documentos por Edades
	constraint TGENG_PK primary key clustered (TABLA, CAMPO, GRUPO)
);
-- TGEN: Detalles de Grupos de opciones por el campo DATO1
create table TGENGD (
	IDTGENGD int identity not null,
	TABLA varchar(15) not null,
	CAMPO varchar(20) not null,
	GRUPO varchar(255) not null,--					Ej. EDADES 
	CODIGO varchar(50) not null, --					Ej. RC
	DESCRIPCION varchar(50) not null, --			Ej. RC va de 0 a 7 años no cumplidos
	VALOR1A real, -- Valor de referencia 1.			Ej. 0 (edad inicial)
	VALOR1B real, -- Valor de referencia 2.			Ej. 7 (edad final)
	DATO1A varchar(255), -- Dato de referencia 1.	Ej. A (A)ños, M(eses), D(ías)
	DATO1B varchar(255), -- Dato de referencia 2.		
	constraint TGENGD_PK primary key clustered (TABLA, CAMPO, GRUPO, CODIGO, IDTGENGD),
	index idxu_TGENGD unique nonclustered (TABLA, CAMPO, GRUPO, CODIGO, VALOR1A, VALOR1B, DATO1A, DATO1B)
);
ALTER TABLE TGENGD ADD CONSTRAINT FK_TGEN_TGENDATO1 FOREIGN KEY (TABLA, CAMPO, GRUPO) 
REFERENCES TGENG(TABLA, CAMPO, GRUPO);
go
alter table TGENG alter column DESCRIPCION varchar(256) not null;
alter table TGENGD alter column DESCRIPCION varchar(128) not null;
go
-- DATO1='EDADES' control de edades que competen al tipo de documento
insert into TGENG(TABLA,CAMPO,GRUPO,DESCRIPCION)
select TABLA='AFI',CAMPO='TIPO_DOC',DATO1='EDADES',DESCRIPCION='Tipos de documentos por Edades'; 
go
select * from TGENG
go
-- truncate table TGENGD;
go
insert into TGENGD(TABLA,CAMPO,GRUPO,CODIGO,DESCRIPCION,VALOR1A,VALOR1B,DATO1A)
select TABLA,CAMPO,GRUPO='EDADES',CODIGO,DESCRIPCION='De 0 a 3 meses no cumplidos', 0, 3, 'M' from TGEN where TABLA='AFI' and CAMPO='TIPO_DOC' AND CODIGO in ('RC','MS','CN') union all
select TABLA,CAMPO,GRUPO='EDADES',CODIGO,DESCRIPCION='De 0 a 1 año no cumplidos', 0, 1, 'A' from TGEN where TABLA='AFI' and CAMPO='TIPO_DOC' AND CODIGO in ('RC','CN') union all
select TABLA,CAMPO,GRUPO='EDADES',CODIGO,DESCRIPCION='De 1 a 7 años no cumplidos', 1, 7, 'A' from TGEN where TABLA='AFI' and CAMPO='TIPO_DOC' AND CODIGO in ('RC') union all
select TABLA,CAMPO,GRUPO='EDADES',CODIGO,DESCRIPCION='De 7 a 18 años no cumplidos', 7, 18, 'A' from TGEN where TABLA='AFI' and CAMPO='TIPO_DOC' and DATO1='MENOR18A' union all
select TABLA,CAMPO,GRUPO='EDADES',CODIGO,DESCRIPCION='De 18 años en adelante', 18, 200, 'A' from TGEN where TABLA='AFI' and CAMPO='TIPO_DOC' and DATO1='MAYOR' union all
select TABLA,CAMPO,GRUPO='EDADES',CODIGO,DESCRIPCION='De 0 a 200 Años', 0, 200, 'A' from TGEN where TABLA='AFI' and CAMPO='TIPO_DOC' and DATO1='TODOS'
go
select * from TGENGD where codigo='RC'
go

alter table TGEN add DESCRIPCION2 varchar(512);
go
-- Grupo Poblacional
insert into TGEN(TABLA,CAMPO,CODIGO,DESCRIPCION,VALOR1,DATO1,DATO2,VALOR2.ESTADO,CONCATCODIGOYDESC,DESCRIPCION2)
select TABLA,CAMPO='GRUPOPOBLACIONAL',CODIGO,DESCRIPCION,VALOR1,DATO1,DATO2,VALOR2,ESTADO,CONCATCODIGOYDESC,DESCRIPCION2 
from TGEN where campo='GRUPOATESPECIAL'
go

-- DATO1='LONGDOC' control de la cantidad de caracteres maximo y minimo que competen al tipo de documento
-- delete TGENG where TABLA='AFI' and CAMPO='TIPO_DOC' and grupo='LONGDOC';
insert into TGENG(TABLA,CAMPO,GRUPO,DESCRIPCION)
select TABLA='AFI',CAMPO='TIPO_DOC',DATO1='LONGDOC',DESCRIPCION='Cantidad de caracteres max y min por documento y Digito por grupo poblacional [VALOR1A=min, VALOR1B=max, DATO1A=Tipo.Pob.Esp., DATO1B=Digito.ID]'; 
go
-- delete TGENGD where TABLA='AFI' and CAMPO='TIPO_DOC' and grupo='LONGDOC';
go

-- rivizar antes que los codigos siguientes sean los nuevos
select * from TGEN p where p.TABLA='AFI' and p.CAMPO='GRUPOPOBLACIONAL'
go

with tdp (TIPODOC,CODPOB) as (
	select 'AS','[1,14,16,17,25]' union all select 'MS','[1,2,10,17,22]'
)
insert into TGENGD(TABLA,CAMPO,GRUPO,CODIGO,DESCRIPCION,VALOR1A,VALOR1B,DATO1A,DATO1B)
select g.TABLA,g.CAMPO,GRUPO='LONGDOC',g.CODIGO,DESCRIPCION= g.DESCRIPCION+' - '+p.DESCRIPCION+'', 5, g.VALOR2, DATO1A = p.CODIGO, DATO1B='I'
from TGEN g 
	join tdp on g.CODIGO=tdp.TIPODOC
	cross apply (
		select * from TGEN p where p.TABLA='AFI' and p.CAMPO='GRUPOPOBLACIONAL'
			and p.CODIGO in (select value from openjson(tdp.CODPOB))
	) p
where g.TABLA='AFI' and g.CAMPO='TIPO_DOC' AND g.CODIGO in ('AS','MS')
go
-- select * from TGEN where TABLA='AFI' and CAMPO='GRUPOATESPECIAL' 


-- TGENG: TABLA='AFI',CAMPO='TIPO_DOC',DATO1='USOXPAIS'
-- delete TGENG where TABLA='AFI' and CAMPO='TIPO_DOC' and grupo='USOXPAIS';
insert into TGENG(TABLA,CAMPO,GRUPO,DESCRIPCION)
select TABLA='AFI',CAMPO='TIPO_DOC',DATO1='USOXPAIS',DESCRIPCION='Paises que usan el tipo de documento [DATO1A=IDPAIS]'; 
go
-- delete TGENGD where TABLA='AFI' and CAMPO='TIPO_DOC' and grupo='LONGDOC';
go
insert into TGENGD(TABLA,CAMPO,GRUPO,CODIGO,DESCRIPCION,DATO1A)
select g.TABLA,g.CAMPO,GRUPO='USOXPAIS',g.CODIGO,DESCRIPCION='Colombia', DATO1A = 'COL'
from TGEN g where g.TABLA='AFI' and g.CAMPO='TIPO_DOC' AND not g.CODIGO in ('PA','CD','SC','SV','CE','PE')  
union all
select g.TABLA,g.CAMPO,GRUPO='USOXPAIS',g.CODIGO,DESCRIPCION='Venezuela', DATO1A = 'VEN'
from TGEN g where g.TABLA='AFI' and g.CAMPO='TIPO_DOC' AND g.CODIGO in ('PA','CD','SC','SV','CE','PE')  
union all
select g.TABLA,g.CAMPO,GRUPO='USOXPAIS',g.CODIGO,DESCRIPCION='Resto de Extranjeros', DATO1A = 'EXT'
from TGEN g where g.TABLA='AFI' and g.CAMPO='TIPO_DOC' AND g.CODIGO in ('PA','CD','SC','SV','CE','PE','AS','MS')  
go
select * from TGENGD where GRUPO='USOXPAIS'


drop trigger if exists dbo.trc_AFI_Validar;
go
Create trigger dbo.trc_AFI_Validar      
on AFI      
for insert,update      
as      
begin
	/*
	Controlar los tipos de documentos en relación a la edad del paciente.
	- Si la unidad de medida de la edad está expresada en días, el tipo de documento debe ser: RC, MS o CN. 
	- Para pacientes de 3 meses, el tipo de documento será “RC: Registro civil” o “CN: Certificado de nacido vivo”. 
	- Para pacientes de 7 años, el tipo de documento será “RC: Registro civil”. 
	- Los pacientes entre 7 y 17 años, deben identificarse con “TI: Tarjeta de identidad”. 
	- Si la edad es mayor o igual a 19 años, el tipo de identificación no puede ser RC, TI, MS, CN. Recuerde que se consideró en este caso el período de transición del menor a adulto para el cambio de identificación. 
	- Para los adultos, mayores o iguales a 18 años y de nacionalidad colombiana, el documento con el cual se deben identificar es la “CC: Cédula de ciudadanía”. 
	- Si la unidad de medida de la edad es meses el tipo de documento no puede ser CC, TI, AS. 
	- Si el tipo documento es AS la edad debe ser mayor a 17 años. 
	- Si el tipo de documento es “TI: Tarjeta de identidad” (U01 = “TI”) o “CC: Cédula de ciudadanía” (U01 = “CC”) el número del documento de identificación (U02) debe incluir únicamente números.
	*/

	declare 
		@USUARIO varchar(20), @PC varchar(64), @mensajeError varchar(max), @Edades varchar(max), @EValidas smallint,
		@string1 varchar(128), @ln1 varchar(32) = char(13)+char(10), @ln2 varchar(32) = char(13)+char(10)+char(13)+char(10),
		@COMPANIA_DEF varchar(2), @IDSEDE_DEF varchar(5), @PRE varchar(20), @CNS int,    
		@IDPAIS varchar(5), @CIUDAD varchar(5), @DOCSINDOC int, @DIGDOCGP varchar(1), @AUTONUMDOC varchar(20);    

	select @USUARIO=USUARIO, @PC=PC from fnc_getSession(@@spid); 

	if update(IDAFILIADO)      
	begin  
		-- Validación de Caracteres especiales y formato de afiliado reciennacido      
		-- Solo acepta numeros y letras      
		-- para pacente recien nacido, alfanumerico terminado del -1 al -9      
		if (select count(*)      
			from inserted a       
			where (      
				(IDAFILIADO like '%[^a-zA-Z0-9]%' and IDAFILIADO not like '%[-][1-9]') -- NO Alfanumerico que no terminen en -1 al -9      
				or IDAFILIADO like '%[^a-zA-Z0-9]%[-][1-9]')       -- NO Alfanumerico terminen en -1 al -9      
		) > 0      
		begin
			set @mensajeError = @ln2+'Error de Caracteres: En el campo ID AFILIADO solo se permiten Letras(A-Z) y/o Números(0-9).'+@ln2;
			raiserror(@mensajeError,16,1);      
			rollback      
			return      
		end      
	end      
      
	if update(EMAIL)      
	begin      
		-- Validacion de Email      
		if (      
			select count(*) from inserted a where dbo.fnc_ValidEmail(EMAIL)=0      
		) > 0      
		begin
			set @mensajeError = @ln2+'Error de eMail: debe proporcionar un formato valido Ej. miMail@miServer.com'+@ln2;
			raiserror(@mensajeError,16,1);  
			rollback      
			return      
		end      
	end     
	     
	-- IDPAIS y CIUDADNAC: Son los de origen (nacimiento)
	-- CIUDAD: La de recidencia en colombia
	if update(IDPAIS) or update(CIUDAD) or update(TIPO_DOC) or update(CIUDADNAC) or update(DOCIDAFILIADO) or update(FNACIMIENTO)   
	begin    
		if update(CIUDADNAC)    
		begin    
			update AFI set IDPAIS=d.IDPAIS    
			from inserted b  
				join AFI a with(nolock) on a.CNS=b.CNS    
				join CIU c with(nolock) on b.CIUDADNAC=c.CIUDAD    
				join DEP d with(nolock) on c.DPTO=d.DPTO    
		end;

		if update(IDPAIS) or update(TIPO_DOC) or update(FNACIMIENTO) or update(CIUDADNAC)
		begin
			-- Valida tipo documento segun edad
			select @Edades=string_agg(@ln1+g.DESCRIPCION,''), @EValidas=sum(v.V)
			from inserted i with(nolock)
				join AFI a with(nolock) on a.CNS=i.CNS
				join TGENGD g with(nolock) on g.TABLA='AFI' and g.CAMPO='TIPO_DOC' and g.GRUPO='EDADES' AND g.CODIGO=a.TIPO_DOC 
				cross apply dbo.fnc_Edad_AMD(a.FNACIMIENTO,getdate()) amd
				cross apply (
					select V =
					case g.DATO1A
						when 'A' then iif(amd.A>=g.VALOR1A and amd.A<g.VALOR1B,1,0)
						when 'M' then iif(amd.A=0 and amd.M>=g.VALOR1A and amd.M<g.VALOR1B,1,0)
						when 'D' then iif(amd.A=0 and amd.M=0 and amd.D>=g.VALOR1A and amd.D<g.VALOR1B,1,0)
					end
				) v
			where a.IDPAIS='COL' and a.VALIDAEDADIPODOC=1 

			if @EValidas = 0      
			begin 
				set @mensajeError = @ln2+'El Tipo de Documento solo es válido para las siguientes edades: %s'+@ln2;
				raiserror(@mensajeError,16,1,@Edades);      
				rollback      
				return      
			end  
		end;
    	
		--select * from TGENGD g where  g.TABLA='AFI' and g.CAMPO='TIPO_DOC' and g.GRUPO='USOXPAIS' AND g.DATO1A='EXT'
		-- Validar tipo documento por Pais de Origen
		with pb as (
			select distinct IDPAIS = g.DATO1A from TGENGD g with(nolock) where g.TABLA='AFI' and g.CAMPO='TIPO_DOC' and g.GRUPO='USOXPAIS'
		)
		select top 1 @mensajeError='Tipo Doc='+a.TIPO_DOC+', Pais='+a.IDPAIS 
		from inserted i with(nolock)
			join AFI a with(nolock) on a.CNS=i.CNS
			left join pb on pb.IDPAIS = a.IDPAIS 
			left join TGENGD g with(nolock) on g.TABLA='AFI' and g.CAMPO='TIPO_DOC' and g.GRUPO='USOXPAIS' AND g.CODIGO=a.TIPO_DOC and g.DATO1A=coalesce(pb.IDPAIS,'EXT')		
		where g.DATO1A is null;
		
		if not @mensajeError is null
		begin
			set @mensajeError = @ln2+'El tipo de documento no es permitido para el país de procedencia ('+@mensajeError+')'+@ln2;
			raiserror(@mensajeError,16,1);    
			rollback;    
			return;    
		end  


    /*
	  -- Procesar documentos actualizado de extranjero a Colombiano    
	  if not update(DOCIDAFILIADO)    
	  begin    
	   update AFI set DOCIDAFILIADO = b.DOCIDAFILIADOEXT    
	   from AFI a     
		join inserted b on a.CNS=b.CNS    
		left join deleted c on a.CNS=c.CNS    
	   where a.IDPAIS='COL' and coalesce(c.IDPAIS,'COL')<>'COL' 
		and not c.IDAFILIADO is null -- debe ser modo update  
	  end    
    
	  -- 1. Procesar DOCIDAFILIADO de extranjeros con documento    
	  update AFI set DOCIDAFILIADO = a.IDPAIS + b.DOCIDAFILIADOEXT     
	  from AFI a     
	   join inserted b on a.CNS=b.CNS    
	  where a.IDPAIS<>'COL' and a.TIPO_DOC in ('PA','CD','SC','SV','CE','PE')     
    
	  -- 2. Procesar IDAFILIADO de extranjeros con documento, debe ir despues del 1.    
	  update AFI set IDAFILIADO = a.IDPAIS + b.DOCIDAFILIADOEXT     
	  from AFI a     
	   join inserted b on a.CNS=b.CNS    
	   left join deleted c on a.CNS=c.CNS    
	  where a.IDPAIS<>'COL' and a.TIPO_DOC in ('PA','CD','SC','SV','CE','PE')  
		and c.IDAFILIADO is null -- debe ser modo insert  
  		*/
    
		select top 1 @COMPANIA_DEF = COMPANIA from CIA with(nolock);    
		select top 1 @IDSEDE_DEF = IDSEDE from SED with(nolock);    

		-- Procesar Afiliados sin documentos para COLOMBIANOS
	
	-- select * from TGENGD g with(nolock) where g.TABLA='AFI' and g.CAMPO='TIPO_DOC' and g.GRUPO='LONGDOC' AND g.CODIGO in ('AS','MS') 

	  declare cx1 cursor local static for    
	  select a.CIUDADNAC, a.CNS, g.DATO1B    
	  from inserted b     
	   join AFI a with(nolock) on a.CNS=b.CNS
	   join TGENGD g with(nolock) on g.TABLA='AFI' and g.CAMPO='TIPO_DOC' and g.GRUPO='LONGDOC' 
			AND g.CODIGO=ltrim(rtrim(a.TIPO_DOC)) and ltrim(rtrim(g.DATO1A))=ltrim(rtrim(a.GRUPOPOBLACIONAL))
	   left join deleted c on a.CNS=c.CNS 
	  where a.IDPAIS='COL' and left(a.DOCIDAFILIADO,6)<>left(a.CIUDADNAC+g.DATO1B,6)
	 and (c.IDAFILIADO is null  -- insertando  
	  or a.IDPAIS<>c.IDPAIS  -- cambio el pais  
	  or a.TIPO_DOC<>c.TIPO_DOC -- cambio el tipo documento
	  or a.CIUDADNAC<>c.CIUDADNAC
	  )  
	  open cx1;    
	  fetch next from cx1 into @CIUDAD, @CNS, @DIGDOCGP;    
	  while @@FETCH_STATUS=0    
	  begin    
	   set @PRE = '@CIU'+@CIUDAD+@DIGDOCGP;    
	   exec dbo.SPK_GENCONSECUTIVO @COMPANIA_DEF, '', @PRE, @DOCSINDOC output;   

	   set @AUTONUMDOC = @CIUDAD + @DIGDOCGP + format(@DOCSINDOC,'#0000');    

	   -- Procesar IDAFILIADO   
	   update AFI set IDAFILIADO = case when d.IDAFILIADO is null then @AUTONUMDOC else a.IDAFILIADO end, DOCIDAFILIADO = @AUTONUMDOC    
	   from inserted i     
	    join AFI a with(nolock) on a.CNS=i.CNS
		left join deleted d on a.CNS=d.CNS    
	   where a.CNS=@CNS; 
    
	   fetch next from cx1 into @CIUDAD, @CNS, @DIGDOCGP;    
	  end    
	  deallocate cx1;      
   
	  -- Procesar Afiliados sin documentos para extranjeros   
    
	  declare cx1 cursor local static for    
	  select b.IDPAIS, a.CNS    
	  from inserted b     
	   join AFI a with(nolock) on a.CNS=b.CNS    
	   left join deleted c on a.CNS=c.CNS    
	  where a.IDPAIS<>'COL' and a.TIPO_DOC in ('AS','MS')  
	 and (c.IDAFILIADO is null  -- insertando  
	  or a.IDPAIS<>c.IDPAIS  -- cambio el pais  
	  or a.TIPO_DOC<>c.TIPO_DOC -- cambio el tipo documento  
	  )  
	  open cx1;    
	  fetch next from cx1 into @IDPAIS, @CNS;    
	  while @@FETCH_STATUS=0    
	  begin    
	   set @PRE = '@PAI'+@IDPAIS;    
	   exec dbo.SPK_GENCONSECUTIVO @COMPANIA_DEF, '', @PRE, @DOCSINDOC output;    

	   set @AUTONUMDOC = @IDPAIS + format(@DOCSINDOC,'#000000');    
     
	   -- Procesar IDAFILIADO   
	   update AFI set IDAFILIADO = case when d.IDAFILIADO is null then @AUTONUMDOC else a.IDAFILIADO end, DOCIDAFILIADO = @AUTONUMDOC  
	   from inserted i     
	    join AFI a with(nolock) on a.CNS=i.CNS
		left join deleted d on a.CNS=d.CNS    
	   where a.CNS=@CNS 
    
	   fetch next from cx1 into @IDPAIS, @CNS;    
	  end    
	  deallocate cx1;      
    
		if dbo.fnk_ValorVariable('AFITIPODOC_VALMAXLON')=1
		begin
			-- Controlar los tamaños de los caracteres por cada tipo de documento 
			select @mensajeError = string_agg('Tipo Documento:'+rtrim(a.TIPO_DOC)+', Documento:'+a.DOCIDAFILIADO+' (long='+ltrim(str(cast(isnull(cc.C,0) as int)))+', min='+ltrim(str(cast(coalesce(g.VALOR1A,0) as int)))+', max='+ltrim(str(cast(coalesce(g.VALOR1B,0) as int)))+')',', ') 
			from inserted i 
				join AFI a with(nolock) on a.CNS=i.CNS
				join TGENGD g with(nolock) on g.TABLA='AFI' and g.CAMPO='TIPO_DOC' and g.GRUPO='LONGDOC' 
					AND g.CODIGO=ltrim(rtrim(a.TIPO_DOC)) and ltrim(rtrim(g.DATO1A))=ltrim(rtrim(a.GRUPOPOBLACIONAL))
				cross apply (select C=len(a.DOCIDAFILIADO) where not len(a.DOCIDAFILIADO) between g.VALOR1A and g.VALOR1B) cc
			where a.IDPAIS='COL' and coalesce(cc.C,0)>0;

			if not @mensajeError is null
			begin
				set @mensajeError = @ln2+'El documento supera el máximo de caracteres permitidos o tipo documento no configurado en TGENGD:'+@ln1+@mensajeError+@ln2;
				raiserror(@mensajeError,16,1);    
				rollback;    
				return;    
			end  
		end

		select @string1 = string_agg('Tipo Documenro='+a.TIPO_DOC+' y Grupo Poblacional='+coalesce(a.GRUPOPOBLACIONAL,''),', ') 
		from (
			select distinct a.TIPO_DOC,a.GRUPOPOBLACIONAL from inserted i join AFI a with(nolock) on i.CNS=a.CNS
			where a.IDAFILIADO='QWERTYTREWQ'
		) a

		if not @string1 is null
		begin
			set @mensajeError = @ln2+'El No. de Documento no puede ser QWERTYTREWQ cuando (%s) '+@ln2;
			raiserror(@mensajeError,16,1,@string1);    
			rollback;    
			return;    
		end      

	 end    

	 -- Datos de cración del Afiliado
	if (select count(*) from deleted where IDAFILIADO is null)>0
	begin
		-- Trigger en Modo Insert
		update AFI set FECHACREACION=dbo.fnk_fecha_sin_mls(getdate()), USUARIOCREACION=@USUARIO, PCCREACION=@PC
		from AFI a join inserted b on a.CNS=b.CNS;
	end
	else
	begin
		-- Trigger en Modo Update
		update AFI set FECHAACTUALIZA=dbo.fnk_fecha_sin_mls(getdate()), USUARIOACTUALIZA=@USUARIO, PCACTUALIZA=@PC
		from AFI a join inserted b on a.CNS=b.CNS;
	end

end      
go
