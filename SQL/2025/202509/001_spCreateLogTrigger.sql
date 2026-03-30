drop Function [dbo].[fna_verTriggers]
go
Create Function [dbo].[fna_verTriggers](@Tabla varchar(128), @Esquema varchar(32)='dbo')  
returns @fna_verTriggers  
 table(  
  tr_nombre varchar(128),  
  tr_owner varchar(128),  
  tr_schema varchar(128),  
  tr_update smallint,  
  tr_delete smallint,  
  tr_insert smallint,  
  tr_after smallint,  
  tr_insteadof smallint,  
  tr_disable smallint  
 )  
as  
begin   
 insert into @fna_verTriggers  
 select   
   o.name AS trigger_name   
  ,USER_NAME(o.uid) AS trigger_owner   
  ,s.name AS table_schema   
  ,OBJECTPROPERTY( id, 'ExecIsUpdateTrigger') AS isupdate   
  ,OBJECTPROPERTY( id, 'ExecIsDeleteTrigger') AS isdelete   
  ,OBJECTPROPERTY( id, 'ExecIsInsertTrigger') AS isinsert   
  ,OBJECTPROPERTY( id, 'ExecIsAfterTrigger') AS isafter   
  ,OBJECTPROPERTY( id, 'ExecIsInsteadOfTrigger') AS isinsteadof   
  ,OBJECTPROPERTY(id, 'ExecIsTriggerDisabled') AS [disabled]   
 from sysobjects o  
  INNER JOIN sys.tables t ON o.parent_obj = t.object_id   
  INNER JOIN sys.schemas s ON t.schema_id = s.schema_id   
 where o.type = 'TR' and OBJECT_NAME(parent_obj)=@Tabla and s.name=@Esquema  
 return;  
end  
go

drop view if exists dbo.vwDBTypes
go
create view dbo.vwDBTypes
As
	Select name from systypes with(nolock) where xusertype<=256
go
-- select * from dbo.vwDBTypes;

drop view if exists dbo.vwTR;
go
CREATE VIEW dbo.vwTR
As
	SELECT 
		 sysobjects.name AS trigger_name 
		,USER_NAME(sysobjects.uid) AS trigger_owner 
		,s.name AS table_schema 
		,OBJECT_NAME(parent_obj) AS table_name 
		,OBJECTPROPERTY( id, 'ExecIsUpdateTrigger') AS isupdate 
		,OBJECTPROPERTY( id, 'ExecIsDeleteTrigger') AS isdelete 
		,OBJECTPROPERTY( id, 'ExecIsInsertTrigger') AS isinsert 
		,OBJECTPROPERTY( id, 'ExecIsAfterTrigger') AS isafter 
		,OBJECTPROPERTY( id, 'ExecIsInsteadOfTrigger') AS isinsteadof 
		,OBJECTPROPERTY(id, 'ExecIsTriggerDisabled') AS [disabled] 
	FROM sysobjects with(nolock)
	--INNER JOIN sysusers with(nolock) ON sysobjects.uid = sysusers.uid 
	INNER JOIN sys.tables t with(nolock) 
		ON sysobjects.parent_obj = t.object_id 
	INNER JOIN sys.schemas s with(nolock)
		ON t.schema_id = s.schema_id 
	WHERE sysobjects.type = 'TR'
go
-- select * from dbo.vwTR;

drop view if exists dbo.vwPK
go
-- Version con schema
create view dbo.vwPK
As
	-- All schemas
	SELECT TABLE_SCHEMA, TABLE_NAME=TABLE_SCHEMA+'.'+TABLE_NAME, CONSTRAINT_NAME, COLUMN_NAME, ORDINAL_POSITION
	FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE with(nolock)
	WHERE OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_SCHEMA+'.'+CONSTRAINT_NAME), 'IsPrimaryKey') = 1

	union all

	-- dbo
	SELECT TABLE_SCHEMA, TABLE_NAME, CONSTRAINT_NAME, COLUMN_NAME, ORDINAL_POSITION
	FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE with(nolock)
	WHERE OBJECTPROPERTY(OBJECT_ID(CONSTRAINT_SCHEMA+'.'+CONSTRAINT_NAME), 'IsPrimaryKey') = 1 and TABLE_SCHEMA='dbo'
go
-- select * from dbo.vwPK

-- ver versi n de sql
-- select cast(cast(SERVERPROPERTY('productversion') as char(3)) as decimal(14,2)) 

drop View if exists dbo.vwPK_List;
go
-- multiversion sin string_agg
Create View dbo.vwPK_List
as	
	select [Schema]=TABLE_SCHEMA, [Table]=a.TABLE_NAME, PK=b.[PK]
	from dbo.vwPK a with(nolock)
		cross apply (select [PK] = stuff((select ',' + COLUMN_NAME from dbo.vwPK b with(nolock) where a.TABLE_NAME=b.TABLE_NAME for xml path('')), 1, 1, '') ) b 
	group by TABLE_SCHEMA, a.TABLE_NAME, b.PK
go

drop View if exists dbo.vwPK_List;
go
-- con string_agg para version >=14 (2017 y posteriores) 
Create View dbo.vwPK_List
as
	select [Schema]=TABLE_SCHEMA, [Table]=TABLE_NAME, [PK]=string_agg(COLUMN_NAME,',') within group (order by Ordinal_Position)
	from dbo.vwPK with(nolock) group by TABLE_SCHEMA,TABLE_NAME
go

-- select * from dbo.vwPK_List
 
drop View if exists dbo.vwTablas;
go
-- Version con schema
Create View dbo.vwTablas as
	-- all schemas
	select id=a.object_id, esquema=schema_name(a.schema_id), Tabla = schema_name(a.schema_id)+'.'+a.name, 
		PK_Index = b.name, Tipo='T'
	from sys.tables a  with(nolock)
		 left join sys.indexes b with(nolock) on a.object_id=b.object_id and b.is_primary_key=1
	where a.type='U' 
	-- Vistas
	union all 
	select id=a.object_id, esquema=schema_name(a.schema_id), Tabla=schema_name(a.schema_id)+'.'+a.name, PK_Index = b.name, Tipo='V'
	from sys.views a with(nolock)
		 outer apply (select b.name, is_primary_key=1 from sys.indexes b with(nolock) where a.object_id=b.object_id and b.type_desc='CLUSTERED') b
	
	union all

	-- dbo
	select id=a.object_id, esquema=schema_name(a.schema_id), Tabla = a.name, PK_Index = b.name, Tipo='T'
	from sys.tables a with(nolock)
		 left join sys.indexes b with(nolock) on a.object_id=b.object_id and b.is_primary_key=1
	where a.type='U' and schema_name(a.schema_id)='dbo'
	-- Vistas
	union all
	select id=a.object_id, esquema=schema_name(a.schema_id), Tabla=a.name, PK_Index = b.name, Tipo='V'
	from sys.views a with(nolock)
		 outer apply (select b.name, is_primary_key=1 from sys.indexes b with(nolock) where a.object_id=b.object_id and b.type_desc='CLUSTERED') b
	where schema_name(a.schema_id)='dbo'
go
-- select * from dbo.vwTablas
go


drop View if exists dbo.vwIndex;
go
-- Version con schema
Create View dbo.vwIndex
as
	Select a.id, a.esquema, a.Tabla, b.index_id, nombre=b.name, pk = b.is_primary_key
	From dbo.vwTablas a with(nolock)
		 join sys.indexes b with(nolock) on a.id=b.object_id and b.index_id>0 
	where a.Tipo='T'
	union all
	Select a.id, a.esquema, a.Tabla, b.index_id, nombre=b.name, pk = case when b.type_desc='CLUSTERED' then 1 else 0 end
	From dbo.vwTablas a with(nolock)
		 join sys.indexes b with(nolock) on a.id=b.object_id and b.index_id>0 
	where a.Tipo='V'
go
-- select * from dbo.vwIndex
go

drop View if exists dbo.vwCampos 
go
-- Version con Schema
Create View dbo.vwCampos as  
	-- all Schemas
	select esquema=schema_name(a.schema_id),TablaID=a.object_id, tabla = schema_name(a.schema_id)+'.'+a.name, 
		CampoID=b.Column_id, campo=b.name, tipo=c.name, long=b.max_length,   
		[precision]=b.precision, escala=b.scale, [identity]=b.is_identity, nullable=b.is_nullable,  
		PKey=case when e.column_id is null then 0 else 1 end  
	from (select object_id, schema_id,name from sys.objects with(nolock) where type in ('tf','u','v') and not name like '%.%') a   
	  inner join sys.columns b with(nolock) on a.object_id=b.object_id  
	  inner join sys.types c with(nolock) on  b.user_type_id = c.user_type_id  --b.system_type_id = c.system_type_id
	  left join sys.indexes d with(nolock) on b.object_id=d.object_id and d.is_primary_key=1  
	  left join sys.index_columns e with(nolock) on d.object_id=e.object_id and d.index_id=e.index_id and b.column_id=e.column_id  
	-- where a.name='CXPSPF'
	union all
	-- dbo
	select esquema=schema_name(a.schema_id),TablaID=a.object_id, tabla = a.name, 
		CampoID=b.Column_id, campo=b.name, tipo=c.name, long=b.max_length,   
		[precision]=b.precision, escala=b.scale, [identity]=b.is_identity, nullable=b.is_nullable,  
		PKey=case when e.column_id is null then 0 else 1 end  
	from (select object_id, schema_id,name from sys.objects with(nolock) where type in ('tf','u','v') and not name like '%.%') a   
	  inner join sys.columns b with(nolock) on a.object_id=b.object_id  
	  inner join sys.types c with(nolock) on  b.user_type_id = c.user_type_id  --b.system_type_id = c.system_type_id
	  left join sys.indexes d with(nolock) on b.object_id=d.object_id and d.is_primary_key=1  
	  left join sys.index_columns e with(nolock) on d.object_id=e.object_id and d.index_id=e.index_id and b.column_id=e.column_id  
	where schema_name(a.schema_id)='dbo' 
		-- and a.name='CXPSPF'
go

drop view vwDBCampos
go
create view vwDBCampos
as
select esquema,IDTabla=TablaID,Tabla,IDCampo=CampoID,Campo,ColOrder=CampoID,
	Tipo,Longitud=long,Precicion=precision,Escala,k=PKey,Autoinc=[identity],Nullable
from vwCampos
go

/*select * From vwCampos where Tabla='USGRU' and not Tipo in ('text','ntext','image') order by CampoID;  
select * From vwDBCampos where Tabla='USGRU' and not Tipo in ('text','ntext','image') order by ColOrder;  
*/


drop view if exists dbo.vwIndexCampos;
go
-- Version con Schema
Create View dbo.vwIndexCampos
as
Select a.esquema, a.Tabla, a.id, a.Index_id, a.Nombre, Pos=b.key_ordinal, [Desc]=b.is_descending_key, Campo=c.[name], Autoinc=c.is_identity
From dbo.vwIndex a with(nolock)
	inner join sys.index_columns b with(nolock) on a.id = b.object_id and a.index_id=b.index_id and b.key_ordinal>0
	inner join sys.columns c with(nolock) on b.object_id=c.object_id and b.column_id=c.column_id
go
-- select * from dbo.vwIndexCampos order by esquema,tabla,nombre,pos

drop VIEW if exists dbo.vwFK_Aux
go
-- Version con Schema
CREATE VIEW dbo.vwFK_Aux
As
	-- all Schemas
	SELECT FK_esquema=FK.CONSTRAINT_SCHEMA, FK_Tabla = FK.TABLE_SCHEMA+'.'+FK.TABLE_NAME, FK_Columna = CU.COLUMN_NAME, 
		PK_esquema=c.UNIQUE_CONSTRAINT_SCHEMA, PK_Tabla = KC.Tabla, PK_Columna = KC.campo, Constraint_Name = C.CONSTRAINT_NAME, cu.Ordinal_Position, C.UNIQUE_CONSTRAINT_NAME
	FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS FK with(nolock)
		JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS C with(nolock) ON C.CONSTRAINT_NAME = FK.CONSTRAINT_NAME and c.CONSTRAINT_SCHEMA=FK.CONSTRAINT_SCHEMA
		JOIN  INFORMATION_SCHEMA.KEY_COLUMN_USAGE CU with(nolock) ON CU.CONSTRAINT_NAME = FK.CONSTRAINT_NAME and cu.CONSTRAINT_SCHEMA=FK.CONSTRAINT_SCHEMA
		join dbo.vwIndexCampos KC with(nolock) on kc.nombre = c.UNIQUE_CONSTRAINT_NAME and kc.Pos = cu.ORDINAL_POSITION and kc.esquema=C.UNIQUE_CONSTRAINT_SCHEMA
	-- where FK.Constraint_Name='FK_IMOVH_IMOVHIDARTICULO' 
	union all	
	-- dbo
	SELECT FK_esquema=FK.CONSTRAINT_SCHEMA, FK_Tabla = FK.TABLE_NAME, FK_Columna = CU.COLUMN_NAME, 
		PK_esquema=c.UNIQUE_CONSTRAINT_SCHEMA, PK_Tabla = KC.Tabla, PK_Columna = KC.campo, Constraint_Name = C.CONSTRAINT_NAME, cu.Ordinal_Position, C.UNIQUE_CONSTRAINT_NAME
	FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS FK with(nolock)
		JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS C with(nolock) ON C.CONSTRAINT_NAME = FK.CONSTRAINT_NAME and c.CONSTRAINT_SCHEMA=FK.CONSTRAINT_SCHEMA
		JOIN  INFORMATION_SCHEMA.KEY_COLUMN_USAGE CU with(nolock) ON CU.CONSTRAINT_NAME = FK.CONSTRAINT_NAME and cu.CONSTRAINT_SCHEMA=FK.CONSTRAINT_SCHEMA
		join dbo.vwIndexCampos KC with(nolock) on kc.nombre = c.UNIQUE_CONSTRAINT_NAME and kc.Pos = cu.ORDINAL_POSITION and kc.esquema=C.UNIQUE_CONSTRAINT_SCHEMA
	where FK.TABLE_SCHEMA='dbo' -- and FK.Constraint_Name='FK_IMOVH_IMOVHIDARTICULO' 
go
-- select * from dbo.vwFK_Aux where Constraint_Name = 'FK_NAV_BrowseLooperC_ID'

drop VIEW if exists dbo.vwFK
go
CREATE VIEW dbo.vwFK as
	select * from dbo.sys_vwFK with(nolock);
go
-- select * from dbo.vwFK

drop Table if exists dbo.sys_vwFK
go
Create Table dbo.sys_vwFK(
	FK_Esquema  sysname not null,
	FK_Tabla	sysname not null,
	FK_Columna	sysname not null,
	PK_Esquema  sysname not null,
	PK_Tabla	sysname not null,
	PK_Columna	sysname not null,
	Constraint_Name	sysname not null,
	Ordinal_Position int  not null	
);
Alter Table dbo.sys_vwFK add constraint PK_Constraint_Name_OrdPos 
primary key clustered (Constraint_Name,Ordinal_Position,FK_Tabla,PK_Tabla);
go
create Index IDX_sys_vwFK_FK_Tabla_FK_Columna on dbo.sys_vwFK(FK_Tabla,FK_Columna) include (Constraint_Name,PK_Tabla);
go


drop Procedure if exists dbo.spFill_vwFK 
go
-- Version con Schema
Create Procedure dbo.spFill_vwFK 
	@Motor varchar(30)
as
begin
	if @Motor='MSSQL2005+'
	begin
		truncate table dbo.sys_vwFK;

		insert into dbo.sys_vwFK(FK_Esquema,FK_Tabla,FK_Columna,PK_Esquema,PK_Tabla,PK_Columna,Constraint_Name,Ordinal_Position)
		SELECT a.FK_Esquema, FK_Tabla=f.tabla, FK_Columna=f.campo, a.PK_Esquema, PK_Tabla=p.tabla, PK_Columna=p.campo, a.Constraint_Name, a.Ordinal_Position 
		from dbo.vwFK_Aux a with(nolock)
			join dbo.vwCampos p with(nolock) on a.PK_Tabla=p.tabla and a.PK_Columna=p.campo and a.PK_Esquema = p.Esquema
			join dbo.vwCampos f with(nolock) on a.FK_Tabla=f.tabla and a.FK_Columna=f.campo and a.FK_Esquema = f.Esquema
	end
end
go

--exec dbo.spFill_vwFK 'MSSQL2005+';

-- select * from dbo.sys_vwFK;
go


drop Function fnGenScriptTrigger
go
Create Function fnGenScriptTrigger(  
 @Tabla nvarchar(30),  
 @DeadLockPriority smallint,  
 @DBase_Log varchar(60)  
)  
returns varchar(max)  
as  
Begin  
 declare   
  @sqlText varchar(max),  
  @nomTrigger varchar(50),
  @nomTrigger_old varchar(50),
  @table_schema varchar(50),
  @keyFields varchar(max),  
  @Columnas varchar(max),  
  @KeyColCast varchar(max),  
  @ColCast varchar(max);  
  
 Select @keyFields = COALESCE (@keyFields + ','+ column_name, column_name)   
 From vwPK where Table_name=@Tabla order by Ordinal_Position;  
  
 Select @Columnas = COALESCE (@Columnas + ','+ Campo, Campo)   
 From vwDBCampos where Tabla=@Tabla and not Tipo in ('text','ntext','image') order by ColOrder;  
  
 if @keyFields is null  
  set @keyFields = @Columnas;  
  
 Select @KeyColCast = COALESCE (@KeyColCast + ', ['+campo+']=cast(COALESCE('
	+case when Tipo in ('geography','geometry','hierarchyid','sql_variant','timestamp','uniqueidentifier','xml') 
	then 'convert(varchar(max),'+campo+')' else campo end
	+','+case when Tipo in ('Numeric','Decimal') then '0' else char(39)+char(39) end+') as nvarchar(max))',
	'['+campo+']=cast(COALESCE('+case when Tipo in ('geography','geometry','hierarchyid','sql_variant','timestamp','uniqueidentifier','xml') 
	then 'convert(varchar(max),'+campo+')' else campo end+','+case when Tipo in ('Numeric','Decimal') then '0' 
	else char(39)+char(39) end+') as nvarchar(max))')   
 From vwDBCampos where Tabla=@Tabla and not Tipo in ('text','ntext','image') order by ColOrder;    
  
 Select @ColCast = COALESCE (@ColCast + ', ['+campo+']=cast(COALESCE('+case when Tipo in ('geography','geometry','hierarchyid','sql_variant','timestamp','uniqueidentifier','xml') then 'convert(varchar(max),'+campo+')' else campo end+','+case when Tipo in 
('Numeric','Decimal') then '0' else char(39)+char(39) end+') as nvarchar(max))','['+campo+']=cast(COALESCE('+case when Tipo in ('geography','geometry','hierarchyid','sql_variant','timestamp','uniqueidentifier','xml') then 'convert(varchar(max),'+campo+')'
 else campo end+','+case when Tipo in ('Numeric','Decimal') then '0' else char(39)+char(39) end+') as nvarchar(max))')   
 From vwDBCampos where Tabla=@Tabla and not Tipo in ('text','ntext','image') order by ColOrder;  
  
 if @KeyColCast is null  
  set @KeyColCast = @ColCast;  
  
 select @nomTrigger_old=trigger_name, @table_schema=table_schema 
 from dbo.vwTR where trigger_name='tr'+Upper(replace(@Tabla,'.','_'))+'_AUTOLOG';
 
 set @nomTrigger_old = coalesce(@nomTrigger_old,'');

 select @nomTrigger='tr_'+Upper(replace(@Tabla,'.','_'))+'_AUTOLOG', @table_schema=esquema 
 from dbo.vwTablas where Tabla = @Tabla;  
 
 if @DeadLockPriority=0  
  set @DeadLockPriority=5;  

 set @sqlText = '';

 if exists(select name from sysobjects where name=@nomTrigger_old and xtype='tr')  
 begin  
	set @sqlText = @sqlText + '
	print ''Eliminando Trigger: '+@table_schema+'.'+@nomTrigger_old+''';  
	drop trigger '+@table_schema+'.'+@nomTrigger_old+'  
	go
	';  	
 end  

 if exists(select name from sysobjects where name=@nomTrigger and xtype='tr')  
 begin  
	set @sqlText = @sqlText + '
	print ''Eliminando Trigger: '+@table_schema+'.'+@nomTrigger+''';  
	drop trigger '+@table_schema+'.'+@nomTrigger+'  
	go
	';  	
 end  

	set @sqlText = @sqlText + '
Create Trigger '+@nomTrigger+'  
on '+@Tabla+' for insert, delete, update  
as  
 set nocount on;  
 SET DEADLOCK_PRIORITY '+ltrim(str(@DeadLockPriority))+';  -- prioridad ante un interbloqueo (deadlock)  
   
 if CONTEXT_INFO()=convert(varbinary(max),'''+@nomTrigger+''')  
 begin  
  print ''Trigger ignorado por Context: ''+coalesce(cast(CONTEXT_INFO() as varchar(30)),''nulo'');  
  return;  
 end   
  
 Declare @evento nvarchar(max)='''', @CNSLOG varchar(20), @COMPANIA varchar(2), @SEDE varchar(5);    
 declare @SLOGD table (ITEM smallint, CAMPO varchar(100), DATO_ANT varchar(max), DATO_NUE varchar(max));   
 declare @TData Table (APP varchar(256), CIA varchar(2), SEDE varchar(5), USUARIO varchar(30), GRUPO varchar(20), PC varchar(254));  
  
 insert into @TData(APP, CIA, SEDE, USUARIO, GRUPO, PC)  
 select APP, CIA, SEDE, USUARIO, GRUPO, PC from dbo.fnc_getSession(@@SPID)  
  
 SELECT @COMPANIA=CIA, @SEDE=SEDE FROM @TData  
  
 if coalesce(@COMPANIA,'''')<>''''  
 begin  
  select @evento =   
  case   
   when not exists(select * from inserted) then ''D''   
   when exists(select * from deleted) then ''U''  
   else ''I''   
  end  
  
  if @evento=''I''  
  begin  
   if (select count(*) from inserted) = 0  
    return;  
  
   Insert into '+@DBase_Log+'SLOG (FECHA,TABLA,OEPRACION,GRUPO,USUARIO,IDPROCEDIMIENTO,SYS_COMPUTERNAME)   
   select getdate(),'''+@Tabla+''',''Inserta'',GRUPO,USUARIO,APP,PC from @TData;  
  
   with   
   cols(cns,t,c,v) as (  
    select _log_cns_,_log_t_,c,v from (  
     select _log_cns_=Row_number() over(order by '+@keyFields+'),_log_t_=''D'','+@KeyColCast+' from inserted  
    ) x  
    unpivot (v for c in ('+@Columnas+')) p  
   ),  
   res(cns,c,o,a,d) as (  
    select * from (select cols.*, c.ColOrder from cols join vwDBCampos c on cols.c = c.Campo and c.Tabla='''+@Tabla+''') x  
    pivot (max(v) for t in (A,D)) p   
   )  
   insert into '+@DBase_Log+'SLOGD (IDSLOG,ITEM,CAMPO,DATO_ANT,DATO_NUE)  
   select SCOPE_IDENTITY(),cns,c,a,d from res  
   order by cns,o   
  end  
  else  
  if @evento=''D''  
  begin  
   if (select count(*) from deleted) = 0  
    return;  
  
   Insert into '+@DBase_Log+'SLOG (FECHA,TABLA,OEPRACION,GRUPO,USUARIO,IDPROCEDIMIENTO,SYS_COMPUTERNAME)   
   select getdate(),'''+@Tabla+''',''Elimina'',GRUPO,USUARIO,APP,PC from @TData;  
  
   with   
   cols(cns,t,c,v) as (  
    select _log_cns_,_log_t_,c,v from (  
     select _log_cns_=Row_number() over(order by '+@keyFields+'),_log_t_=''A'','+@ColCast+' from deleted  
    ) x  
    unpivot (v for c in ('+@Columnas+')) p  
   ),  
   res(cns,c,o,a,d) as (  
    select * from (select cols.*, c.ColOrder from cols join vwDBCampos c on cols.c = c.Campo and c.Tabla='''+@Tabla+''') x  
    pivot (max(v) for t in (A,D)) p   
   )  
   insert into '+@DBase_Log+'SLOGD (IDSLOG,ITEM,CAMPO,DATO_ANT,DATO_NUE)  
   select SCOPE_IDENTITY(),cns,c,a,d from res  
   order by cns,o   
  end  
  else  
  if @evento=''U''  
  begin  
   if (select count(*) from inserted) = 0  
    return;  
  
   with   
   cols(cns,t,c,v) as (  
    select _log_cns_,_log_t_,c,v from (  
     select _log_cns_=Row_number() over(order by '+@keyFields+'),_log_t_=''A'','+@ColCast+' from deleted  
     union all  
     select _log_cns_=Row_number() over(order by '+@keyFields+'),_log_t_=''D'','+@ColCast+' from inserted  
    ) x  
    unpivot (v for c in ('+@Columnas+')) p  
   ),  
   res(cns,c,a,d,o,k) as (  
    select cns,c,a,d,ColOrder,k from (select cols.*, c.ColOrder,k=case when c.k=0 then 999 else c.k end from cols join vwDBCampos c on cols.c = c.Campo and c.Tabla='''+@Tabla+''') x  
    pivot (max(v) for t in (A,D)) p   
    where A<>D or k<999  
   )  
   insert into @SLOGD (ITEM,CAMPO,DATO_ANT,DATO_NUE)  
   select cns,c,a,d from res  
   order by cns,k,o;  
  
   -- seleccionando solo registros con cambios en al menos un campo  
   with m1 as (  
    select ITEM,Cant=sum(case when DATO_ANT<>DATO_NUE then 1 else 0 end) from @SLOGD group by ITEM  
   )  
   delete @SLOGD  
   from @SLOGD a join m1 on a.ITEM=m1.ITEM where m1.Cant=0  
     
   -- Inserta LOG solo si hubo campos con cambios  
   if (select count(*) from @SLOGD)>0  
   begin  
    Insert into '+@DBase_Log+'SLOG (FECHA,TABLA,OEPRACION,GRUPO,USUARIO,IDPROCEDIMIENTO,SYS_COMPUTERNAME)   
    select getdate(),'''+@Tabla+''',''Cambio'',GRUPO,USUARIO,APP,PC from @TData;  
      
    insert into '+@DBase_Log+'SLOGD (IDSLOG,ITEM,CAMPO,DATO_ANT,DATO_NUE)  
    select SCOPE_IDENTITY(),ITEM,CAMPO,DATO_ANT,DATO_NUE from @SLOGD;  
   end        
  end  
 end  
 else  
 begin  
  print ''ADVERTENCIA: No se guard  el Log por que el Usuario no inici  una sesi n desde Clintos'';  
 end  
   
 -- set nocount off;  
go';  
 return @sqlText   
End  
go

drop Procedure spCreateLogTrigger  
go
Create Procedure spCreateLogTrigger  
 @Tabla varchar(30),  
 @User varchar(30),  
 @Pass varchar(30),  
 @FilePath varchar(128),  
 @DeadLockPriority smallint,  
 @DBase_Log varchar(60)  
as  
Begin  
 -- Generaci n del Script en Disco que crea el Trigger  
 declare   
  @Filename varchar(max) = 'tr_'+replace(@Tabla,'.','_')+'_AUTOLOG.sql',  
  @Machine varchar(255) = convert(varchar(255),SERVERPROPERTY('MachineName')),  
  @Instance varchar(255) = @@servicename;  
 declare   
  @Server  varchar(512) = @Machine, --+case when coalesce(@Instance,'')='' then '' else '\'+@Instance end,  
  @cmd nvarchar(4000);  
  
 --SET @cmd = 'bcp "select dbo.fnGenScriptTrigger('''+@Tabla+''','''+ltrim(str(@DeadLockPriority))+''')" queryout "'+@FilePath+@Filename+'" -U garth -P pw -c -S '+@Server+' -d '+db_name()+' -U '+@User+' -P '+@Pass;  
 SET @cmd = 'bcp "select dbo.fnGenScriptTrigger('''+@Tabla+''','''+ltrim(str(@DeadLockPriority))+''','''+@DBase_Log+''')" queryout "'+@FilePath+@Filename+'" -U garth -P pw -c -S '+@Server+' -d '+db_name()+' -U '+@User+' -P '+@Pass;  
 print @cmd;  
 EXEC master..xp_cmdshell @cmd;  
  
 -- Ejecucion del script almacenado en disco  
 set @cmd = 'sqlcmd -S ' + @Server + ' -d ' + db_name() + ' -i "' + @FilePath + @Filename +'"';    
 print @cmd;  
 EXEC xp_cmdshell @cmd;  
End  
go