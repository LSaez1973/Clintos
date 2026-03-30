drop Function dbo.fnc_MaxHorasDevSinConf
go
-- Inventario: Clintos->DxContable  
-- *Contiene consulta unida de movimientos de ambas BD   
Create Function dbo.fnc_MaxHorasDevSinConf(@NOADMISION varchar(20),@USUARIO varchar(12))  
returns @tabla table (CantHBloq int, Horas decimal(14,2), Cant int, Minutos int, Bloq int, Tiempo varchar(10), pbloq decimal(7,2), hpbloq decimal(7,2),TipoBloq char(1))  
as  
begin   
 declare   
  @hbloq varchar(80) =  coalesce(dbo.fnk_ValorVariable('HPRE_BLOQ_DEVPENDINV'),''),  
  @pbloq decimal(7,2) = coalesce(dbo.fnk_ValorVariable('HPRE_PBLO_DEVPENDINV'),100)*0.01,  
  @IDINVMOVPREDEV varchar(2) = dbo.fnk_ValorVariable('IDINVMOVPREDEV'),  
  @hpbloq decimal(7,2),   
  @cantHBloq int = 0,  
  @cant int=0,  
  @horas decimal(14,2)=0,  
  @shoras varchar(20),  
  @scant varchar(20),  
  @FechaIni datetime = dateadd(year,-1,getdate());  
 declare 
	@tMOVPREDEV table (USUARIO varchar(12), NOADMISION varchar(16), FECHAADMISION datetime, FECHADOCUMENTO datetime)
  
 if @hbloq<>'' and cast(@hbloq as int)>=0  
 begin  
  set @cantHBloq = cast(@hbloq as int);  
  set @hpbloq = @cantHBloq*@pbloq;  
  
  --select @hpbloq,@cantHBloq,@pbloq  end  
    
	insert into @tMOVPREDEV
	select a.USUARIO, a.NOADMISION, b.FECHA, m.FECHADOCUMENTO  
    from DxContable.dbo.IMOVSS a with(nolock)  
     join DxContable.dbo.IMOV m with(nolock) on a.IDTRANSACCION=m.IDTRANSACCION and a.NUMDOCUMENTO=m.NUMDOCUMENTO   
      and a.PROCEDENCIA = 'DEVSALUD'  
     join hadm b with (nolock) on a.NOADMISION = b.NOADMISION collate Modern_Spanish_CI_AS and b.FECHA>=@FechaIni  
    where m.ESTADO='0' and m.IDTIPOMOV=@IDINVMOVPREDEV 
		and (a.USUARIO=@USUARIO or a.NOADMISION=@NOADMISION);

  -- Busca Bloqueo por Usuario  
  with   
  tmp_c(horas,cant) as (  
   -- Inv.Asistencial  
   select h.horas, cant=count(*)  
   from imov a with (nolock)   
    join hadm b with (nolock) on a.NODOCUMENTO=b.NOADMISION and b.FECHA>=@FechaIni  
    cross apply (select horas=datediff(minute,a.fechamov,getdate())) h  
   where a.USUARIO=@USUARIO and a.PROCEDENCIA = 'SALUD' and a.ESTADO='0'   
    and a.IDTIPOMOV=@IDINVMOVPREDEV and h.horas/60.00 >= @cantHBloq  
    and coalesce(a.PROCESO,'')<>'DOXA_PR'  
   group by h.horas  
  ),  
  tmp_dx(horas,cant) as (  
   -- DxContable  
   select h.horas, cant=count(*)  
   from @tMOVPREDEV m   
	cross apply (select horas=datediff(minute,m.FECHADOCUMENTO,getdate())) h  
   where m.USUARIO=@USUARIO and h.horas/60.00 >= @cantHBloq      
   group by h.horas  
  ),  
  tmp_2 as (select * from tmp_c union all select * from tmp_dx)  
  insert into @tabla  
  select @cantHBloq, horas=max(horas)/60.00, cant=sum(cant), minutos=max(horas), 1,  
   ltrim(str(cast(max(horas)/60.00 as int)))+'h:'+right('0'+ltrim(str(max(horas)-(cast(max(horas)/60.00 as int)*60))),2)+'m',  
   @pbloq, @hpbloq, 'U'  
  from tmp_2   
  having sum(cant) is not null  
  
  -- Busca Advertencia por Usuario  
  if (select count(*) from @tabla)=0  
  begin  
   with   
   tmp_c(horas,cant) as (  
    -- Inv.Asistencial  
    select h.horas,cant=count(*)  
    from imov a with (nolock) join   
     hadm b with (nolock) on a.NODOCUMENTO=b.NOADMISION and b.FECHA>=@FechaIni  
		cross apply (select horas=datediff(minute,a.fechamov,getdate())) h  
    where a.USUARIO=@USUARIO and a.PROCEDENCIA = 'SALUD' and a.ESTADO='0'   
     and a.IDTIPOMOV=@IDINVMOVPREDEV and h.horas/60.00 > @hpbloq  
     and coalesce(a.PROCESO,'')<>'DOXA_PR'  
    group by h.horas  
   ),  
   tmp_dx(horas,cant) as (  
    -- DxContable
	select h.horas, cant=count(*)  
	from @tMOVPREDEV m   
		cross apply (select horas=datediff(minute,m.FECHADOCUMENTO,getdate())) h  
	where m.USUARIO=@USUARIO and h.horas/60.00 > @cantHBloq      
	group by h.horas   
   ),  
   tmp_2 as (select * from tmp_c union all select * from tmp_dx)  
   insert into @tabla  
   select @cantHBloq, horas=max(horas)/60.00, cant=sum(cant), minutos=max(horas), 0,  
    ltrim(str(cast(max(horas)/60.00 as int)))+'h:'+right('0'+ltrim(str(max(horas)-(cast(max(horas)/60.00 as int)*60))),2)+'m',  
    @pbloq, @hpbloq, 'U'  
   from tmp_2  
   having sum(cant) is not null;  
  
   -- Busca Bloqueo por Admisión  
   if (select count(*) from @tabla)=0  
   begin      
    with   
    tmp_c(horas,cant) as (  
     -- Inv.Asistencial  
     select h.horas, cant=count(*)  
     from imov a with (nolock)   
      join hadm b with (nolock) on a.NODOCUMENTO=b.NOADMISION and b.FECHA>=@FechaIni   
     cross apply (select horas=datediff(minute,a.fechamov,getdate())) h  
     where a.NODOCUMENTO=@NOADMISION and a.PROCEDENCIA = 'SALUD' and a.ESTADO='0'   
      and a.IDTIPOMOV=@IDINVMOVPREDEV and h.horas/60.00 >= @cantHBloq  
      and coalesce(a.PROCESO,'')<>'DOXA_PR'  
     group by h.horas  
    ),  
    tmp_dx(horas,cant) as (  
     -- DxContable  
	 select h.horas, cant=count(*)  
	 from @tMOVPREDEV m   
		cross apply (select horas=datediff(minute,m.FECHADOCUMENTO,getdate())) h  
	 where m.NOADMISION=NOADMISION and h.horas/60.00 >= @cantHBloq      
	 group by h.horas    
    ),  
    tmp_2 as (select * from tmp_c union all select * from tmp_dx)   
    insert into @tabla  
    select @cantHBloq, horas=max(horas)/60.00, cant=sum(cant), minutos=max(horas), 1,  
     ltrim(str(cast(max(horas)/60.00 as int)))+'h:'+right('0'+ltrim(str(max(horas)-(cast(max(horas)/60.00 as int)*60))),2)+'m',  
     @pbloq, @hpbloq, 'A'  
    from tmp_2  
    having sum(cant) is not null  
    -- Busca Advertencia por Admisión  
    if (select count(*) from @tabla)=0  
    begin      
     with   
     tmp_c(horas,cant) as (  
      -- Inv.Asistencial  
      select h.horas, cant=count(*)  
      from imov a with (nolock)   
       join hadm b with (nolock) on a.NODOCUMENTO=b.NOADMISION and b.FECHA>=@FechaIni  
      cross apply (select horas=datediff(minute,a.fechamov,getdate())) h  
      where a.NODOCUMENTO=@NOADMISION and a.PROCEDENCIA = 'SALUD' and a.ESTADO='0'   
       and a.IDTIPOMOV=@IDINVMOVPREDEV and h.horas/60.00 > @hpbloq  
       and coalesce(a.PROCESO,'')<>'DOXA_PR'  
      group by h.horas  
     ),   
     tmp_dx(horas,cant) as (  
      -- DxContable  
	  select h.horas, cant=count(*)  
	  from @tMOVPREDEV m   
		cross apply (select horas=datediff(minute,m.FECHADOCUMENTO,getdate())) h  
	  where m.NOADMISION=NOADMISION and h.horas/60.00 > @cantHBloq      
	  group by h.horas    
     ),  
     tmp_2 as (select * from tmp_c union all select * from tmp_dx)    
     insert into @tabla  
     select @cantHBloq, horas=max(horas)/60.00, cant=sum(cant), minutos=max(horas), 0,  
      ltrim(str(cast(max(horas)/60.00 as int)))+'h:'+right('0'+ltrim(str(max(horas)-(cast(max(horas)/60.00 as int)*60))),2)+'m',  
      @pbloq, @hpbloq, 'A'  
     from tmp_2  
     having sum(cant) is not null  
    end  
   end  
  end  
 end  
 return;  
end 
go

/*

-- Inventario: Clintos->DxContable  
-- *Contiene consulta unida de movimientos de ambas BD   
Create Function dbo.fnc_MaxHorasDevSinConf(@NOADMISION varchar(20),@USUARIO varchar(12))  
returns @tabla table (CantHBloq int, Horas decimal(14,2), Cant int, Minutos int, Bloq int, Tiempo varchar(10), pbloq decimal(7,2), hpbloq decimal(7,2),TipoBloq char(1))  
as  
begin   
 declare   
  @hbloq varchar(80) =  coalesce(dbo.fnk_ValorVariable('HPRE_BLOQ_DEVPENDINV'),''),  
  @pbloq decimal(7,2) = coalesce(dbo.fnk_ValorVariable('HPRE_PBLO_DEVPENDINV'),100)*0.01,  
  @IDINVMOVPREDEV varchar(2) = dbo.fnk_ValorVariable('IDINVMOVPREDEV'),  
  @hpbloq decimal(7,2),   
  @cantHBloq int = 0,  
  @cant int=0,  
  @horas decimal(14,2)=0,  
  @shoras varchar(20),  
  @scant varchar(20),  
  @FechaIni datetime = dateadd(year,-1,getdate());  
    
 if @hbloq<>'' and cast(@hbloq as int)>=0  
 begin  
  set @cantHBloq = cast(@hbloq as int);  
  set @hpbloq = @cantHBloq*@pbloq;  
  
  --select @hpbloq,@cantHBloq,@pbloq  end  
    
  -- Busca Bloqueo por Usuario  
  with   
  tmp_c(horas,cant) as (  
   -- Inv.Asistencial  
   select h.horas, cant=count(*)  
   from imov a with (nolock)   
    join hadm b with (nolock) on a.NODOCUMENTO=b.NOADMISION and b.FECHA>=@FechaIni  
    cross apply (select horas=datediff(minute,a.fechamov,getdate())) h  
   where a.USUARIO=@USUARIO and a.PROCEDENCIA = 'SALUD' and a.ESTADO='0'   
    and a.IDTIPOMOV=@IDINVMOVPREDEV and h.horas/60.00 >= @cantHBloq  
    and coalesce(a.PROCESO,'')<>'DOXA_PR'  
   group by h.horas  
  ),  
  tmp_dx(horas,cant) as (  
   -- DxContable  
   select h.horas,cant=count(*)  
   from DxContable.dbo.IMOVSS a with(nolock)  
    join DxContable.dbo.IMOV m with(nolock) on a.IDTRANSACCION=m.IDTRANSACCION and a.NUMDOCUMENTO=m.NUMDOCUMENTO   
     and a.PROCEDENCIA = 'DEVSALUD'   
    cross apply (select horas=datediff(minute,m.FECHADOCUMENTO,getdate())) h  
    join hadm b with (nolock) on a.NOADMISION = b.NOADMISION collate Modern_Spanish_CI_AS and b.FECHA>=@FechaIni  
   where a.USUARIO=@USUARIO and m.ESTADO='0' and m.IDTIPOMOV=@IDINVMOVPREDEV and h.horas/60.00 >= @cantHBloq      
   group by h.horas  
  ),  
  tmp_2 as (select * from tmp_c union all select * from tmp_dx)  
  insert into @tabla  
  select @cantHBloq, horas=max(horas)/60.00, cant=sum(cant), minutos=max(horas), 1,  
   ltrim(str(cast(max(horas)/60.00 as int)))+'h:'+right('0'+ltrim(str(max(horas)-(cast(max(horas)/60.00 as int)*60))),2)+'m',  
   @pbloq, @hpbloq, 'U'  
  from tmp_2   
  having sum(cant) is not null  
  
  -- Busca Advertencia por Usuario  
  if (select count(*) from @tabla)=0  
  begin  
   with   
   tmp_c(horas,cant) as (  
    -- Inv.Asistencial  
    select h.horas,cant=count(*)  
    from imov a with (nolock) join   
     hadm b with (nolock) on a.NODOCUMENTO=b.NOADMISION and b.FECHA>=@FechaIni  
     cross apply (select horas=datediff(minute,a.fechamov,getdate())) h  
    where a.USUARIO=@USUARIO and a.PROCEDENCIA = 'SALUD' and a.ESTADO='0'   
     and a.IDTIPOMOV=@IDINVMOVPREDEV and h.horas/60.00 > @hpbloq  
     and coalesce(a.PROCESO,'')<>'DOXA_PR'  
    group by h.horas  
   ),  
   tmp_dx(horas,cant) as (  
    -- DxContable  
    select h.horas,cant=count(*)  
    from DxContable.dbo.IMOVSS a with(nolock)  
     join DxContable.dbo.IMOV m with(nolock) on a.IDTRANSACCION=m.IDTRANSACCION and a.NUMDOCUMENTO=m.NUMDOCUMENTO   
      and a.PROCEDENCIA = 'DEVSALUD'  
     cross apply (select horas=datediff(minute,m.FECHADOCUMENTO,getdate())) h  
     join hadm b with (nolock) on a.NOADMISION = b.NOADMISION collate Modern_Spanish_CI_AS and b.FECHA>=@FechaIni  
    where a.USUARIO=@USUARIO and m.ESTADO='0' and m.IDTIPOMOV=@IDINVMOVPREDEV and h.horas/60.00 > @hpbloq      
    group by h.horas  
   ),  
   tmp_2 as (select * from tmp_c union all select * from tmp_dx)  
   insert into @tabla  
   select @cantHBloq, horas=max(horas)/60.00, cant=sum(cant), minutos=max(horas), 0,  
    ltrim(str(cast(max(horas)/60.00 as int)))+'h:'+right('0'+ltrim(str(max(horas)-(cast(max(horas)/60.00 as int)*60))),2)+'m',  
    @pbloq, @hpbloq, 'U'  
   from tmp_2  
   having sum(cant) is not null;  
  
   -- Busca Bloqueo por Admisión  
   if (select count(*) from @tabla)=0  
   begin      
    with   
    tmp_c(horas,cant) as (  
     -- Inv.Asistencial  
     select h.horas, cant=count(*)  
     from imov a with (nolock)   
      join hadm b with (nolock) on a.NODOCUMENTO=b.NOADMISION and b.FECHA>=@FechaIni   
     cross apply (select horas=datediff(minute,a.fechamov,getdate())) h  
     where a.NODOCUMENTO=@NOADMISION and a.PROCEDENCIA = 'SALUD' and a.ESTADO='0'   
      and a.IDTIPOMOV=@IDINVMOVPREDEV and h.horas/60.00 >= @cantHBloq  
      and coalesce(a.PROCESO,'')<>'DOXA_PR'  
     group by h.horas  
    ),  
    tmp_dx(horas,cant) as (  
     -- DxContable  
     select h.horas,cant=count(*)  
     from DxContable.dbo.IMOVSS a with(nolock)  
      join DxContable.dbo.IMOV m with(nolock) on a.IDTRANSACCION=m.IDTRANSACCION and a.NUMDOCUMENTO=m.NUMDOCUMENTO   
       and a.PROCEDENCIA = 'DEVSALUD'  
      cross apply (select horas=datediff(minute,m.FECHADOCUMENTO,getdate())) h  
      join hadm b with (nolock) on a.NOADMISION = b.NOADMISION collate Modern_Spanish_CI_AS and b.FECHA>=@FechaIni  
     where a.NOADMISION=@NOADMISION and m.ESTADO='0' and m.IDTIPOMOV=@IDINVMOVPREDEV and h.horas/60.00 >= @cantHBloq      
     group by h.horas  
    ),  
    tmp_2 as (select * from tmp_c union all select * from tmp_dx)   
    insert into @tabla  
    select @cantHBloq, horas=max(horas)/60.00, cant=sum(cant), minutos=max(horas), 1,  
     ltrim(str(cast(max(horas)/60.00 as int)))+'h:'+right('0'+ltrim(str(max(horas)-(cast(max(horas)/60.00 as int)*60))),2)+'m',  
     @pbloq, @hpbloq, 'A'  
    from tmp_2  
    having sum(cant) is not null  
    -- Busca Advertencia por Admisión  
    if (select count(*) from @tabla)=0  
    begin      
     with   
     tmp_c(horas,cant) as (  
      -- Inv.Asistencial  
      select h.horas, cant=count(*)  
      from imov a with (nolock)   
       join hadm b with (nolock) on a.NODOCUMENTO=b.NOADMISION and b.FECHA>=@FechaIni  
      cross apply (select horas=datediff(minute,a.fechamov,getdate())) h  
      where a.NODOCUMENTO=@NOADMISION and a.PROCEDENCIA = 'SALUD' and a.ESTADO='0'   
       and a.IDTIPOMOV=@IDINVMOVPREDEV and h.horas/60.00 > @hpbloq  
       and coalesce(a.PROCESO,'')<>'DOXA_PR'  
      group by h.horas  
     ),   
     tmp_dx(horas,cant) as (  
      -- DxContable  
      select h.horas,cant=count(*)  
      from DxContable.dbo.IMOVSS a with(nolock)  
       join DxContable.dbo.IMOV m with(nolock) on a.IDTRANSACCION=m.IDTRANSACCION and a.NUMDOCUMENTO=m.NUMDOCUMENTO   
        and a.PROCEDENCIA = 'DEVSALUD'  
       cross apply (select horas=datediff(minute,m.FECHADOCUMENTO,getdate())) h  
       join hadm b with (nolock) on a.NOADMISION = b.NOADMISION collate Modern_Spanish_CI_AS and b.FECHA>=@FechaIni  
      where a.NOADMISION=@NOADMISION and m.ESTADO='0' and m.IDTIPOMOV=@IDINVMOVPREDEV and h.horas/60.00 > @hpbloq      
      group by h.horas  
     ),  
     tmp_2 as (select * from tmp_c union all select * from tmp_dx)    
     insert into @tabla  
     select @cantHBloq, horas=max(horas)/60.00, cant=sum(cant), minutos=max(horas), 0,  
      ltrim(str(cast(max(horas)/60.00 as int)))+'h:'+right('0'+ltrim(str(max(horas)-(cast(max(horas)/60.00 as int)*60))),2)+'m',  
      @pbloq, @hpbloq, 'A'  
     from tmp_2  
     having sum(cant) is not null  
    end  
   end  
  end  
 end  
 return;  
end  
go
*/