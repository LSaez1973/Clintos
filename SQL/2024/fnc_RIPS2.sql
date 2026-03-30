drop function if exists fnc_RIPS_HPRED_SER_1_2;
go
CREATE function fnc_RIPS_HPRED_SER_1_2 (@N_FACTURA varchar(16), @ARCHIVORIPS varchar(10))                
returns table as return (  
	SELECT 'HPRED' AS TABLA,HPRED.HPREDID PRESTACIONID,CONSECUTIVO=HPRE.NOPRESTACION,HPRED.NOITEM AS ITEM,SER.CODIGORIPS,RENCP.ARCHIVO AS ARCHIVORIPS,                    
		0 AS PYP,HPRED.IDTERCEROCA AS IDCONTRATANTE,HPRED.IDPLAN,HPRED.N_FACTURA,AFI.IDAFILIADO,AFI.TIPO_DOC,AFI.DOCIDAFILIADO,                    
		HPRE.FECHA,HADM.FECHA AS FINGRESO, HADM.FECHAALTA AS FEGRESO,HPRED.IDSERVICIO,SER.IDALTERNA,                    
		SER.TIPOMED,LEFT(coalesce(SER.DESCSERVICIOCUPS,SER.DESCSERVICIO),60) AS DESCSERVICIO, LEFT(SER.NOM_GENERICO,60) AS NOMGENERICO,                    
		HADM.VIAINGRESO, HADM.DXEGRESO AS IDDX, NULL AS TIPODX,                    
		HADM.DXEGRESO AS DXSALIDA,HADM.DXSALIDA1 AS DXR1,HADM.DXSALIDA2 AS DXR2,HADM.DXSALIDA3 AS DXR3, HADM.COMPLICACION AS COMPLICACION, '' AS FORMAREALIZACION,                     
		HADM.CAUSABMUERTE AS CAUSAMUERTE, HADM.DESTINO AS DESTINO, HADM.ESTADOPSALIDA AS ESTADOSALIDA,                     
		CAST(ROUND(abs(COALESCE(HPRED.CANTIDAD,1)),0) AS INT) AS CANTIDAD,                     
		round(CAST(abs(COALESCE(HPRED.VALOR,0)) AS DECIMAL(15,2)),0) AS VALOR, round(CAST(abs(COALESCE(HPRED.VALORCOPAGO,0)) AS DECIMAL(15,2)),0) AS VALORCOPAGO, HADM.COPAGOVALOR AS VRCOPAGO, 0 AS VRMODERADORA,                    
		round(CAST(abs(COALESCE(HPRED.VALOR,0))*abs(COALESCE(HPRED.CANTIDAD,1)) AS DECIMAL(15,2)),0) AS VALORITEM,                     
		round(CAST(abs((COALESCE(HPRED.VALOR,0)*COALESCE(HPRED.CANTIDAD,1))-COALESCE(HPRED.VALORCOPAGO,0)) AS DECIMAL(15,2)),0) AS VRNETO,                    
		CIRUGIA=0,HPRED.IDCIRUGIA,HPRED.CONSECUTIVOCX,HPRED.KCNTRID,HPRED.KCNTID, HPRE.IDSEDE,                    
		SER.PREFIJO, SER.IDARTICULO, HPRE.IDMEDICO, HADM.TIPOTTEC, HADM.CAUSAEXTERNA, HPRE.TIPOPRESTACION,                     
		HADM.NOAUTORIZACION, HPRE.NUMAUTORIZA, HPRED_NOAUTORIZACION=HPRED.NOAUTORIZACION, HPRE.AMBITO, HADM.DXINGRESO, SER.IDCUM                    
	FROM dbo.HPRE  with (nolock)                   
		JOIN dbo.HPRED with (nolock) ON HPRED.NOPRESTACION = HPRE.NOPRESTACION                     
		LEFT JOIN dbo.HADM with (nolock) ON HADM.NOADMISION    = HPRE.NOADMISION                     
		JOIN dbo.AFI with (nolock)  ON AFI.IDAFILIADO     = HADM.IDAFILIADO                    
		JOIN dbo.SER  with (nolock) ON SER.IDSERVICIO     = HPRED.IDSERVICIO                    
		JOIN dbo.RENCP with (nolock) ON RENCP.IDCONCEPTORIPS = SER.CODIGORIPS                     
	WHERE hpred.N_FACTURA=@N_FACTURA and RENCP.ARCHIVO=@ARCHIVORIPS and HPRE.TIPOPRESTACION = 0 /*AND HPRED.VALOR > 0 */ AND (COALESCE(HPRE.CIRUGIA,'No')<>'Si')                    
		AND COALESCE(HADM.CLASENOPROC,'')<>'NP' -- Excluye los No procesar                    
		AND NOT (RENCP.ARCHIVO in ('AH','AU') AND HADM.CLASEING<>'A') -- Excluye las que no son del Modulo Hospitalario para AH y AU 
)
go

drop function if exists fnc_RIPS_HPRED_SER_2;
go
CREATE function fnc_RIPS_HPRED_SER_2 (@N_FACTURA varchar(16), @ARCHIVORIPS varchar(10))                
returns table as return (  
	 SELECT 'HPRED' AS TABLA,a.PRESTACIONID,a.CONSECUTIVO,a.ITEM,a.CODIGORIPS,a.ARCHIVORIPS,                  
	  0 AS PYP,FTR.IDTERCERO AS IDTERCEROFACT,a.IDCONTRATANTE,a.IDPLAN,a.N_FACTURA,a.IDAFILIADO,a.TIPO_DOC,a.DOCIDAFILIADO,                  
	  a.FECHA, /*a.FECHA AS */a.FINGRESO, na.NUMAUTORIZA as NUMAUTORIZA, a.FEGRESO,a.IDSERVICIO,a.IDALTERNA,                  
	  a.TIPOMED,ts.TIPOSERVICIO as TIPOSERVICIO, a.DESCSERVICIO, a.NOMGENERICO,                  
	  IFFA.DESCRIPCION AS FORMA,ICCN.DESCRIPCION AS CONCENTRACION,IUNI.DESCRIPCION AS UMEDIDA,                  
	  am.AMBITO AS AMBITO, PRE.FINALIDAD, a.VIAINGRESO, MES.PERSONAL_AT AS PERSONALAT,                   
	  dx.IDDX, a.TIPODX, DXSALIDA=coalesce(a.DXSALIDA,h.IDDX), DXR1=coalesce(a.DXR1,h.DX1), DXR2=coalesce(a.DXR2,h.DX2), DXR3=coalesce(a.DXR3,h.DX3),                  
	  a.COMPLICACION AS COMPLICACION, a.FORMAREALIZACION,                   
	  ce.CAUSAEXT AS CAUSAEXT, a.CAUSAMUERTE, a.DESTINO AS DESTINO, a.ESTADOSALIDA,                   
	  a.CANTIDAD, a.VALOR, a.VALORCOPAGO, a.VRCOPAGO, a.VRMODERADORA,   a.VALORITEM, a.VRNETO, FTR.ESTADO AS ESTADOFACTURA,CAPITADO=coalesce(KCNT.CAPITA,0),CIRUGIA=0,a.IDCIRUGIA,                  
	  a.CONSECUTIVOCX, a.KCNTRID, a.KCNTID, ttec.TIPOSISTEMA, a.IDSEDE, FTR.TIPOFIN                  
	 FROM fnc_RIPS_HPRED_SER_1_2(@N_FACTURA,@ARCHIVORIPS) a                   
	  LEFT JOIN  dbo.FTR with (nolock)  ON FTR.N_FACTURA = a.N_FACTURA                  
	  LEFT JOIN dbo.PRE with (nolock)  ON PRE.PREFIJO = a.PREFIJO                  
	  LEFT JOIN dbo.MED with (nolock)  ON MED.IDMEDICO = a.IDMEDICO                  
	  LEFT JOIN dbo.MES with (nolock)  ON MES.IDEMEDICA = MED.IDEMEDICA                  
	  LEFT JOIN dbo.IART with (nolock) ON IART.IDARTICULO = a.IDARTICULO                  
	  LEFT JOIN dbo.IFFA with (nolock) ON IFFA.IDFORFARM = IART.IDFORFARM                  
	  LEFT JOIN dbo.ICCN with (nolock) ON ICCN.IDCONCENTRA= IART.IDCONCENTRA                  
	  LEFT JOIN dbo.IUNI with (nolock) ON IUNI.IDUNIDAD = IART.IDUNIDAD                  
	  left join dbo.TTEC with (nolock) on a.TIPOTTEC=TTEC.TIPO                  
	  left join dbo.KCNT with (nolock) on a.KCNTID=KCNT.KCNTID                  
	  outer apply (                  
	   SELECT top 1 hc.IDDX, hc.TIPODX, hc.FINALIDAD, hc.DX1, hc.DX2, hc.DX3, hc.CAUSAEXT, b.DESCRIPCION                    
	   FROM dbo.HCA hc with (nolock)                    
		JOIN dbo.MDX b with (nolock) ON hc.IDDX = b.IDDX                    
	   where hc.IDAFILIADO=a.IDAFILIADO                   
		and hc.FECHA>=dbo.FNK_FECHA_SIN_HORA(a.FINGRESO) and hc.FECHA<dbo.FNK_FECHA_SIN_HORA(a.FEGRESO)+1                    
	   order by hc.FECHA desc                  
	  ) h                  
	  cross apply (                  
	   Select CAUSAEXT =                   
		case when coalesce(a.CAUSAEXTERNA,'')='' then                   
		 case when coalesce(h.CAUSAEXT,'') ='' then '13' else h.CAUSAEXT end                   
		else a.CAUSAEXTERNA end                  
	  ) ce                  
	  cross apply (                  
	   select IDDX =                   
		case when coalesce(a.IDDX,'')='' then                   
		 case when coalesce(h.IDDX,'')='' then                      
		  coalesce(a.DXINGRESO,'')                  
		 else h.IDDX end                  
		else a.IDDX end                  
	  ) dx                  
	  cross apply (                  
	   select NUMAUTORIZA =                   
	   case when coalesce(a.HPRED_NOAUTORIZACION,'')<>'' then a.HPRED_NOAUTORIZACION else                   
		case when coalesce(a.NUMAUTORIZA,'')='' then a.NOAUTORIZACION else a.NUMAUTORIZA end                   
	   end                  
	  ) na                   
	  cross apply (Select TIPOSERVICIO =  CASE a.CODIGORIPS                      
		WHEN '06' THEN '3'  WHEN '07' THEN '4' WHEN '08' THEN '3'  WHEN '09' THEN '1'                        
		WHEN '10' THEN '1'  WHEN '11' THEN '1' WHEN '14' THEN '2' else '1' END) ts                  
	  cross apply (Select AMBITO = CASE when coalesce(ltrim(rtrim(a.AMBITO)),'') = '' THEN '2' ELSE a.AMBITO END) am                  
	 where a.ARCHIVORIPS<>'AM'                  
      
	 union all                  
                  
	 -- Medicamentos cruzados con vwc_HPRED_IMOVH_Devoluciones para buscar el entregado de marca y no el generico                  
	 SELECT 'HPRED' AS TABLA,a.PRESTACIONID,a.CONSECUTIVO,a.ITEM,a.CODIGORIPS,a.ARCHIVORIPS,                  
	  0 AS PYP,FTR.IDTERCERO AS IDTERCEROFACT,a.IDCONTRATANTE,a.IDPLAN,a.N_FACTURA,a.IDAFILIADO,a.TIPO_DOC,a.DOCIDAFILIADO,                  
	  a.FECHA, /*a.FECHA AS */a.FINGRESO, na.NUMAUTORIZA as NUMAUTORIZA, a.FEGRESO, a.IDSERVICIO,                   
	  IDALTERNA = case when coalesce(IART.CODCUM,'')='' then a.IDCUM else IART.CODCUM end,                  
	  a.TIPOMED,ts.TIPOSERVICIO as TIPOSERVICIO, a.DESCSERVICIO, a.NOMGENERICO,                  
	  IFFA.DESCRIPCION AS FORMA,ICCN.DESCRIPCION AS CONCENTRACION,IUNI.DESCRIPCION AS UMEDIDA,                  
	  am.AMBITO AS AMBITO, PRE.FINALIDAD, a.VIAINGRESO, MES.PERSONAL_AT AS PERSONALAT,                   
	  dx.IDDX, a.TIPODX, DXSALIDA=coalesce(a.DXSALIDA,h.IDDX), DXR1=coalesce(a.DXR1,h.DX1), DXR2=coalesce(a.DXR2,h.DX2), DXR3=coalesce(a.DXR3,h.DX3),                    
	  a.COMPLICACION AS COMPLICACION, a.FORMAREALIZACION,                   
	  ce.CAUSAEXT AS CAUSAEXT, a.CAUSAMUERTE, a.DESTINO AS DESTINO, a.ESTADOSALIDA,                   
	  b.CANTIDAD,                   
	  VALOR = a.VALOR, --cast((a.VALOR/a.CANTIDAD)*b.CANTIDAD as decimal(14,0)),                   
	  VALORCOPAGO = cast((a.VALORCOPAGO/a.CANTIDAD)*b.CANTIDAD as decimal(14,0)), a.VRCOPAGO, a.VRMODERADORA,                 
	  VALORITEM = cast((a.VALORITEM/a.CANTIDAD)*b.CANTIDAD as decimal(14,0)),                   
	  VRNETO = cast((a.VRNETO/a.CANTIDAD)*b.CANTIDAD as decimal(14,0)),                   
	  FTR.ESTADO AS ESTADOFACTURA,CAPITADO=coalesce(KCNT.CAPITA,0),CIRUGIA=0,a.IDCIRUGIA,                  
	  a.CONSECUTIVOCX, a.KCNTRID, a.KCNTID, ttec.TIPOSISTEMA, a.IDSEDE, FTR.TIPOFIN                  
	 FROM fnc_RIPS_HPRED_SER_1_2(@N_FACTURA,@ARCHIVORIPS) a                  
	  LEFT JOIN  dbo.FTR with (nolock) ON FTR.N_FACTURA = a.N_FACTURA                  
	  --left join dbo.vwc_HPRED_IMOVH_Devoluciones b with (nolock) ON b.HPREDID = a.PRESTACIONID                  
	  outer apply dbo.fnc_HPRED_xIDARTICULO_Despachado(a.CONSECUTIVO,a.IDSERVICIO,a.PRESTACIONID,a.CANTIDAD) b                  
	  LEFT JOIN dbo.PRE with (nolock) ON PRE.PREFIJO = a.PREFIJO                  
	  LEFT JOIN dbo.MED with (nolock) ON MED.IDMEDICO = a.IDMEDICO                  
	  LEFT JOIN dbo.MES with (nolock)  ON MES.IDEMEDICA = MED.IDEMEDICA                  
	  LEFT JOIN dbo.IART with (nolock) ON IART.IDARTICULO = b.IDARTICULO                  
	  LEFT JOIN dbo.IFFA with (nolock) ON IFFA.IDFORFARM  = IART.IDFORFARM                  
	  LEFT JOIN dbo.ICCN with (nolock) ON ICCN.IDCONCENTRA= IART.IDCONCENTRA                  
	  LEFT JOIN dbo.IUNI with (nolock) ON IUNI.IDUNIDAD = IART.IDUNIDAD                  
	  left join dbo.TTEC with (nolock) on a.TIPOTTEC=TTEC.TIPO                  
	  left join dbo.KCNT with (nolock) on a.KCNTID=KCNT.KCNTID                  
	  outer apply (                  
	   SELECT top 1 hc.IDDX, hc.TIPODX, hc.FINALIDAD, hc.DX1, hc.DX2, hc.DX3, hc.CAUSAEXT, b.DESCRIPCION                    
	   FROM dbo.HCA hc with (nolock)                    
		JOIN dbo.MDX b with (nolock) ON hc.IDDX = b.IDDX                    
	   where hc.IDAFILIADO=a.IDAFILIADO                   
		and hc.FECHA>=dbo.FNK_FECHA_SIN_HORA(a.FINGRESO) and hc.FECHA<dbo.FNK_FECHA_SIN_HORA(a.FEGRESO)+1                    
	   order by hc.FECHA desc                  
	  ) h                  
	  cross apply (                  
	   select IDDX =                   
		case when coalesce(a.IDDX,'')='' then                   
		 case when coalesce(h.IDDX,'')='' then                      
		  coalesce(a.DXINGRESO,'')    
		 else h.IDDX end                  
		else a.IDDX end                  
	  ) dx                  
	  cross apply (Select CAUSAEXT = CASE a.CAUSAEXTERNA WHEN NULL THEN '13' WHEN '' THEN '13' ELSE a.CAUSAEXTERNA END) ce                  
		cross apply (                  
	   select NUMAUTORIZA =                   
	   case when coalesce(a.HPRED_NOAUTORIZACION,'')<>'' then a.HPRED_NOAUTORIZACION else                   
		case when coalesce(a.NUMAUTORIZA,'')='' then a.NOAUTORIZACION else a.NUMAUTORIZA end                   
	   end                  
	  ) na                    
	  cross apply (Select TIPOSERVICIO =  CASE a.CODIGORIPS                      
		WHEN '06' THEN '3'  WHEN '07' THEN '4' WHEN '08' THEN '3'  WHEN '09' THEN '1'                        
		WHEN '10' THEN '1'  WHEN '11' THEN '1' WHEN '14' THEN '2' else '1' END) ts                  
	  cross apply (Select AMBITO = CASE when coalesce(ltrim(rtrim(a.AMBITO)),'') = '' THEN '2' ELSE a.AMBITO END) am                  
	 where a.ARCHIVORIPS='AM' and coalesce(a.CANTIDAD,0)>0 and coalesce(b.CANTIDAD,0)>0 
)
go

drop function if exists fnc_RIPS_HPRED_CIR_2;
go
CREATE function fnc_RIPS_HPRED_CIR_2 (@N_FACTURA varchar(16), @ARCHIVORIPS varchar(10))                
returns table as return (               
	with                   
	 qHPRED as (                  
	  select ITEM=ROW_NUMBER() OVER (partition by NOPRESTACION order by IDCIRUGIA), NOPRESTACION,IDCIRUGIA,                  
	   CONSECUTIVOCX,IDTERCEROCA,IDPLAN,N_FACTURA,VALOR,VALORCOPAGO,VALORITEM,VRNETO,TIPOCONTRATO,KCNTRID,KCNTID,HPRED_NOAUTORIZACION                  
	  from (                  
	   select a.NOPRESTACION,a.IDCIRUGIA,a.CONSECUTIVOCX,a.IDTERCEROCA,a.IDPLAN,a.N_FACTURA,a.TIPOCONTRATO,a.KCNTRID,a.KCNTID,                   
		HPRED_NOAUTORIZACION=a.NOAUTORIZACION,                  
		SUM(round(CAST(abs(COALESCE(a.VALOR,0)) AS DECIMAL(15,2)),0)) AS VALOR,                   
		SUM(round(CAST(abs(COALESCE(a.VALORCOPAGO,0)) AS DECIMAL(15,2)),0)) AS VALORCOPAGO, 0 AS VRCOPAGO, 0 AS VRMODERADORA,                  
		SUM(round(CAST(abs(COALESCE(a.VALOR,0))*abs(COALESCE(a.CANTIDAD,1)) AS DECIMAL(15,2)),0)) AS VALORITEM,                   
		SUM(round(CAST(abs((COALESCE(a.VALOR,0)*COALESCE(a.CANTIDAD,1))-COALESCE(a.VALORCOPAGO,0)) AS DECIMAL(15,2)),0)) AS VRNETO                  
	   from dbo.HPRED a JOIN dbo.HPRE b ON a.NOPRESTACION=b.NOPRESTACION                  
	   WHERE a.N_FACTURA=@N_FACTURA and b.CIRUGIA='Si' --AND A.VALOR > 0                   
	   GROUP BY  a.NOPRESTACION,a.IDCIRUGIA,a.CONSECUTIVOCX,a.IDTERCEROCA,a.IDPLAN,a.N_FACTURA,a.TIPOCONTRATO,a.KCNTRID,a.KCNTID, a.NOAUTORIZACION                  
	  ) a                  
	 )                  
	 SELECT DISTINCT                   
	  'HPRED' AS TABLA,                  
	  PRESTACIONID=HPRE.NOPRESTACION,                  
	  CONSECUTIVO=HPRE.NOPRESTACION,                  
	  ITEM=qHPRED.ITEM,                  
	  SER.CODIGORIPS,                  
	  RENCP.ARCHIVO AS ARCHIVORIPS,                  
	  0 AS PYP,                  
	  FTR.IDTERCERO AS IDTERCEROFACT,                  
	  qHPRED.IDTERCEROCA AS IDCONTRATANTE,                  
	  qHPRED.IDPLAN,                  
	  qHPRED.N_FACTURA,                  
	  AFI.IDAFILIADO,                  
	  AFI.TIPO_DOC,                  
	  AFI.DOCIDAFILIADO,                  
	  HPRE.FECHA,                  
	  HADM.FECHA AS FINGRESO,                   
	  na.NUMAUTORIZA,                   
	  HADM.FECHAALTA AS FEGRESO,                  
	  IDSERVICIO=qHPRED.IDCIRUGIA,                  
	  SER.IDALTERNA,                   
	  SER.TIPOMED,                   
	  ts.TIPOSERVICIO,                   
	  LEFT(coalesce(SER.DESCSERVICIOCUPS,SER.DESCSERVICIO),60) AS DESCSERVICIO,                   
	  LEFT(SER.NOM_GENERICO,60) AS NOMGENERICO,                  
	  IFFA.DESCRIPCION AS FORMA,                  
	  ICCN.DESCRIPCION AS CONCENTRACION,                  
	  IUNI.DESCRIPCION AS UMEDIDA,                   
	  1 AS CANTIDAD,                   
	  am.AMBITO,                  
	  --case when hpred.finalidad='' then PRE.FINALIDAD when hpred.finalidad is null then PRE.FINALIDAD else hpred.finalidad end as FINALIDAD,                    
	  PRE.FINALIDAD,                   
	  HADM.VIAINGRESO,                   
	  MES.PERSONAL_AT AS PERSONALAT,                   
	  --HADM.DXEGRESO AS IDDX,      -- <-- Dx. de ingreso del procedimiento.  Si no está definido llega vacío a la vista VWA_RIPS                  
	  dx.IDDX, TIPODX=2, DXSALIDA=coalesce(HADM.DXEGRESO,h.IDDX), DXR1=coalesce(HADM.DXSALIDA1,h.DX1),                   
	  DXR2=coalesce(HADM.DXSALIDA2,h.DX2), DXR3=coalesce(HADM.DXSALIDA3,h.DX3),                  
	  /*CASE HADM.DXINGRESO WHEN NULL THEN HADM.DXEGRESO WHEN '' THEN HADM.DXEGRESO ELSE HADM.DXINGRESO END IDDX,                    
	  2 AS TIPODX,                   
	  HADM.DXEGRESO AS DXSALIDA,                   
	  '' AS DXR1,                   
	  '' AS DXR2,                   
	  '' AS DXR3, */                  
	  HADM.COMPLICACION AS COMPLICACION,                   
	  '' AS FORMAREALIZACION,                   
	  ce.CAUSAEXT,                   
	  HADM.CAUSABMUERTE AS CAUSAMUERTE,                   
	  HADM.DESTINO AS DESTINO,                   
	  HADM.ESTADOPSALIDA AS ESTADOSALIDA,                   
	  qHPRED.VALOR,                   
	  qHPRED.VALORCOPAGO, FTR.VALORCOPAGO AS VRCOPAGO, FTR.VALORMODERADORA AS VRMODERADORA,                   
	  qHPRED.VALORITEM,                   
	  qHPRED.VRNETO,                  
	  FTR.ESTADO AS ESTADOFACTURA,                  
	  CAPITADO=coalesce(KCNT.CAPITA,0),                   
	  CIRUGIA=1,                  
	  qHPRED.IDCIRUGIA,                  
	  qHPRED.CONSECUTIVOCX,                  
	  qHPRED.KCNTRID,                  
	  qHPRED.KCNTID,                  
	  ttec.TIPOSISTEMA,                  
	  HPRE.IDSEDE, FTR.TIPOFIN                  
	 FROM dbo.HPRE                   
	  INNER JOIN qHPRED ON qHPRED.NOPRESTACION = HPRE.NOPRESTACION                  
	  INNER JOIN dbo.HADM  ON HADM.NOADMISION  = HPRE.NOADMISION                  
	  INNER JOIN dbo.AFI   ON AFI.IDAFILIADO     = HADM.IDAFILIADO                  
	  INNER JOIN dbo.SER   ON SER.IDSERVICIO     = qHPRED.IDCIRUGIA                  
	  LEFT JOIN  dbo.FTR   ON FTR.N_FACTURA      = qHPRED.N_FACTURA                  
	  LEFT JOIN dbo.PRE   ON PRE.PREFIJO        = SER.PREFIJO                  
	  LEFT JOIN dbo.RENCP ON RENCP.IDCONCEPTORIPS = SER.CODIGORIPS                  
	  LEFT JOIN dbo.MED   ON MED.IDMEDICO       = HPRE.IDMEDICO                  
	  LEFT JOIN dbo.MES   ON MES.IDEMEDICA      = MED.IDEMEDICA                  
	  LEFT JOIN dbo.IART ON IART.IDARTICULO = SER.IDARTICULO                  
	  LEFT JOIN dbo.IFFA ON IFFA.IDFORFARM  = IART.IDFORFARM                  
	  LEFT JOIN dbo.ICCN ON ICCN.IDCONCENTRA= IART.IDCONCENTRA                  
	  LEFT JOIN dbo.IUNI ON IUNI.IDUNIDAD   = IART.IDUNIDAD    left join dbo.TTEC on hadm.tipottec=ttec.tipo                  
	  left join KCNT with (nolock)  on qHPRED.KCNTID=KCNT.KCNTID                  
	  outer apply (                  
	   SELECT top 1 hc.IDDX, hc.TIPODX, hc.FINALIDAD, hc.DX1, hc.DX2, hc.DX3, hc.CAUSAEXT, b.DESCRIPCION                    
	   FROM dbo.HCA hc with (nolock)                    
		JOIN dbo.MDX b with (nolock) ON hc.IDDX = b.IDDX                    
	   where hc.IDAFILIADO=HADM.IDAFILIADO                   
		and hc.FECHA>=dbo.FNK_FECHA_SIN_HORA(HADM.FECHA) and hc.FECHA<dbo.FNK_FECHA_SIN_HORA(HADM.FECHAALTA)+1                    
	   order by hc.FECHA desc                  
	  ) h                  
	  cross apply (                  
	   select IDDX =                   
		case when coalesce(HADM.DXEGRESO,'')='' then                   
		 case when coalesce(h.IDDX,'')='' then                      
		  coalesce(HADM.DXINGRESO,'')                  
		 else h.IDDX end                  
		else HADM.DXEGRESO end                  
	  ) dx                  
	  cross apply (Select CAUSAEXT = CASE HADM.CAUSAEXTERNA WHEN NULL THEN '13' WHEN '' THEN '13' ELSE HADM.CAUSAEXTERNA END) ce                  
	  cross apply (                  
	   select NUMAUTORIZA =                   
	   case when coalesce(qHPRED.HPRED_NOAUTORIZACION,'')<>'' then qHPRED.HPRED_NOAUTORIZACION else                   
		case when coalesce(HPRE.NUMAUTORIZA,'')='' then HADM.NOAUTORIZACION else HPRE.NUMAUTORIZA end                   
	   end                  
	  ) na                  
	  cross apply (Select TIPOSERVICIO =  CASE RENCP.IDCONCEPTORIPS                      
		WHEN '06' THEN '3'  WHEN '07' THEN '4' WHEN '08' THEN '3'  WHEN '09' THEN '1'                        
		WHEN '10' THEN '1'  WHEN '11' THEN '1' WHEN '14' THEN '2' else '1' END) ts                  
	  cross apply (Select AMBITO = CASE when coalesce(ltrim(rtrim(HPRE.AMBITO)),'') = '' THEN '2' ELSE HPRE.AMBITO END) am                  
	 WHERE RENCP.ARCHIVO=@ARCHIVORIPS and HPRE.TIPOPRESTACION = 0 AND COALESCE(HADM.CLASENOPROC,'')<>'NP' -- Excluye los No procesar                  
	  AND NOT (RENCP.ARCHIVO in ('AH','AU') AND HADM.CLASEING<>'A') -- Excluye las que no son del Modulo Hospitalario para AH y AU 
);
go

drop function if exists fnc_RIPS_HPRED_2;
go
CREATE function fnc_RIPS_HPRED_2 (@N_FACTURA varchar(16), @ARCHIVORIPS varchar(10))                
returns table as return (               
	select               
		TABLA,PRESTACIONID,CONSECUTIVO,ITEM,CODIGORIPS,ARCHIVORIPS,PYP,IDTERCEROFACT,IDCONTRATANTE,IDPLAN,N_FACTURA,IDAFILIADO,TIPO_DOC,DOCIDAFILIADO,FECHA,FINGRESO,NUMAUTORIZA,              
		FEGRESO,IDSERVICIO,IDALTERNA,TIPOMED,TIPOSERVICIO,DESCSERVICIO,NOMGENERICO,FORMA,CONCENTRACION,UMEDIDA,CANTIDAD,AMBITO,FINALIDAD,VIAINGRESO,PERSONALAT,IDDX,TIPODX,              
		DXSALIDA,DXR1,DXR2,DXR3,COMPLICACION,FORMAREALIZACION,CAUSAEXT,CAUSAMUERTE,DESTINO,ESTADOSALIDA,VALOR,VALORCOPAGO,VRCOPAGO,VRMODERADORA,VALORITEM,VRNETO,ESTADOFACTURA,CAPITADO,CIRUGIA,              
		IDCIRUGIA,CONSECUTIVOCX,KCNTRID,KCNTID,TIPOSISTEMA,IDSEDE,TIPOFIN                
	from dbo.fnc_RIPS_HPRED_SER_2(@N_FACTURA,@ARCHIVORIPS)
	where N_FACTURA=@N_FACTURA and ARCHIVORIPS=@ARCHIVORIPS
	union all              
	select              
		TABLA,PRESTACIONID,CONSECUTIVO,ITEM,CODIGORIPS,ARCHIVORIPS,PYP,IDTERCEROFACT,IDCONTRATANTE,IDPLAN,N_FACTURA,IDAFILIADO,TIPO_DOC,DOCIDAFILIADO,FECHA,FINGRESO,NUMAUTORIZA,              
		FEGRESO,IDSERVICIO,IDALTERNA,TIPOMED,TIPOSERVICIO,DESCSERVICIO,NOMGENERICO,FORMA,CONCENTRACION,UMEDIDA,CANTIDAD,AMBITO,FINALIDAD,VIAINGRESO,PERSONALAT,IDDX,TIPODX,              
		DXSALIDA,DXR1,DXR2,DXR3,COMPLICACION,FORMAREALIZACION,CAUSAEXT,CAUSAMUERTE,DESTINO,ESTADOSALIDA,VALOR,VALORCOPAGO,VRCOPAGO,VRMODERADORA,VALORITEM,VRNETO,ESTADOFACTURA,CAPITADO,CIRUGIA,              
		IDCIRUGIA,CONSECUTIVOCX,KCNTRID,KCNTID,TIPOSISTEMA,IDSEDE,TIPOFIN                  
	from dbo.fnc_RIPS_HPRED_CIR_2(@N_FACTURA,@ARCHIVORIPS) 
)
go

drop function [dbo].[fnc_RIPS_2]                                           
go
CREATE function dbo.fnc_RIPS_2 (@N_FACTURA varchar(16), @ARCHIVORIPS varchar(10))                
returns table as return (                                         
	with cp as (                                        
	 SELECT CLASEPLANTILLA=Value FROM fnc_split( dbo.fnk_ValorVariable('@MplTeleconsultaOdx') , ',' )                                        
	)                                        
	SELECT                                
	 'CIT' AS TABLA,CIT.CITID PRESTACIONID,CIT.CONSECUTIVO,1 AS ITEM,SER.CODIGORIPS,RENCP.ARCHIVO AS ARCHIVORIPS,                                        
	 CASE CIT.CLASEORDEN WHEN 'PyP' THEN 1 ELSE 0 END AS PYP, FTR.IDTERCERO AS IDTERCEROFACT,CIT.IDCONTRATANTE,CIT.IDPLAN,                                        
	 CIT.N_FACTURA,AFI.IDAFILIADO,AFI.TIPO_DOC,AFI.DOCIDAFILIADO,CIT.FECHA, NULL AS FINGRESO,CIT.NOAUTORIZACION,NULL AS FEGRESO,                                
	 CIT.IDSERVICIO,SER.IDALTERNA,SER.TIPOMED, TIPOSERVICIO = CASE RENCP.IDCONCEPTORIPS                                            
	 WHEN '06' THEN '3' WHEN '07' THEN '4' WHEN '08' THEN '3' WHEN '09' THEN '1' WHEN '10' THEN '1' WHEN '11' THEN '1'                                              
	 WHEN '14' THEN '2' END,                                        
	 LEFT (coalesce(SER.DESCSERVICIOCUPS,SER.DESCSERVICIO),60) AS DESCSERVICIO, '' AS NOMGENERICO,'' AS FORMA,'' AS CONCENTRACION,                                
	 '' AS UMEDIDA,CAST(1 AS INT) AS  CANTIDAD, '01' AS AMBITO, COALESCE(h.FINALIDAD,                                
	 COALESCE(case when CIT.FINALIDAD='' then null else CIT.FINALIDAD end,PRE.FINALIDAD)) AS FINALIDAD, '01' AS VIAINGRESO,                                         
	 '' AS PERSONALAT, H.IDDX,                             
	 CASE H.TIPODX WHEN NULL THEN '1' WHEN 'Impr Dx' THEN '1' WHEN 'Presuntivo' THEN '1' WHEN 'Definitivo' THEN '3'                             
	 WHEN 'Conf Nuevo' THEN '2' WHEN 'Conf Repet' THEN '3' ELSE '1' END AS TIPODX,                               
	 '' AS DXSALIDA, H.DX1, H.DX2, H.DX3, '' AS COMPLICACION,                                         
	 '' AS FORMAREALIZACION, case when COALESCE(h.CAUSAEXT,COALESCE(CIT.IDCAUSAEXT,'13'))='' then '13'                                 
	 else COALESCE(h.CAUSAEXT,COALESCE(CIT.IDCAUSAEXT,'13')) end AS  CAUSAEXT, '' AS CAUSAMUERTE, '' AS DESTINO, '1' AS ESTADOSALIDA,                                         
	 COALESCE(CIT.VALORTOTAL,0) AS VALOR, COALESCE(CIT.VALORMODERADORA,0) AS VALORCOPAGO, FTR.VALORCOPAGO AS VRCOPAGO, FTR.VALORMODERADORA AS VRMODERADORA,                            
	 --CASE WHEN CIT.VALORCOPAGO <> 0 THEN '02' WHEN CIT.VALORMODERADORA <> 0 THEN '01' ELSE '04' END AS TIPOPAGOMODERADOR,                             
	 COALESCE(CIT.VALORTOTAL,0) AS VALORITEM, round(COALESCE(CIT.VALORTOTAL,0)-COALESCE(CIT.VALORMODERADORA,0) ,0) AS VRNETO, FTR.ESTADO AS ESTADOFACTURA,                                
	 CAPITADO=coalesce(KCNT.CAPITA,0),0 CIRUGIA,IDCIRUGIA=cast('' as varchar(20)),CONSECUTIVOCX=cast('' as varchar(20)), cit.KCNTRID,                                
	 cit.KCNTID,ttec.TIPOSISTEMA, CIT.IDSEDE, FTR.TIPOFIN                                        
	FROM                                 
	 CIT with (nolock)                                         
	 INNER JOIN AFI with (nolock) ON AFI.IDAFILIADO = CIT.IDAFILIADO                                        
	 INNER JOIN SER with (nolock)  ON SER.IDSERVICIO = CIT.IDSERVICIO                                        
	 LEFT  JOIN PRE with (nolock)  ON PRE.PREFIJO    = SER.PREFIJO                                        
	 LEFT  JOIN RENCP with (nolock)  ON RENCP.IDCONCEPTORIPS = SER.CODIGORIPS                                        
	 LEFT JOIN  FTR with (nolock)  ON FTR.N_FACTURA  = CIT.N_FACTURA                                        
	 LEFT join TTEC with (nolock)  on CIT.TIPOTTEC=TTEC.TIPO                                        
	 LEFT join KCNT with (nolock)  on CIT.KCNTID=KCNT.KCNTID                                        
	 outer apply (                                
	 SELECT                                 
	  top 1 a.IDDX,a.TIPODX,FINALIDAD=case when a.FINALIDAD='' then null else a.FINALIDAD end, a.DX1,a.DX2,a.DX3,a.CAUSAEXT,b.DESCRIPCION                                
	 FROM                                 
	  dbo.HCA a with (nolock)                                
	  JOIN dbo.MDX b with (nolock) ON a.IDDX = b.IDDX                                
	 where               
	  a.PROCEDENCIA='CE' and a.IDAFILIADO=cit.IDAFILIADO                                
	  and (-- Busca por CONSECUTIVO de cita                                        
	  (coalesce(a.CNSCITA,'')<>'' and a.CNSCITA=CIT.CONSECUTIVO) or  -- Busca por HC hechas ese mismo medico y día de la cita                                        
	  (/*coalesce(a.CNSCITA,'')='' and */a.IDMEDICO=cit.IDMEDICO                                   
	  and a.FECHA >= dbo.FNK_FECHA_SIN_MLS(CIT.fecha)                                 
	  and a.FECHA < dbo.FNK_FECHA_SIN_MLS(CIT.fecha)+1)                                        
		)                                            
	 order by a.FECHA                                        
	 ) h --dbo.fnc_HCA_Afiliado(cit.IDAFILIADO,cit.fecha) h                                  
                                 
	WHERE CIT.N_FACTURA=@N_FACTURA and RENCP.ARCHIVO=@ARCHIVORIPS and
	 CIT.CITASIMULTANEA = 0 AND CIT.IDAFILIADO IS NOT NULL and CIT.TIPOCITA='Cita' and (coalesce(CUMPLIDA,0)=1                                 
	 or (coalesce(CUMPLIDA,0)=0 and coalesce(FACTURADA,0)=1)) and coalesce(ser.tiposervicio,'')<>'04'                                        
	 --and CIT.N_FACTURA='ONCO253'                                        
                                        
	UNION ALL                                        
                                        
	-- CIT Citas simultáneas (Aportado por Erick y Pacho: 30.nov.2020)                               
	SELECT                                 
	 'CIT' AS TABLA,CIT.CITID PRESTACIONID,CIT.CONSECUTIVO,1 AS ITEM,SER.CODIGORIPS,RENCP.ARCHIVO AS ARCHIVORIPS,                                
	 CASE CIT.CLASEORDEN WHEN 'PyP' THEN 1 ELSE 0 END AS PYP, FTR.IDTERCERO AS IDTERCEROFACT,CIT.IDCONTRATANTE,CIT.IDPLAN,                                
	 CIT.N_FACTURA,AFI.IDAFILIADO,AFI.TIPO_DOC,AFI.DOCIDAFILIADO,CIT.FECHA, NULL AS FINGRESO,CIT.NOAUTORIZACION,NULL AS FEGRESO,                                
	 CIT.IDSERVICIO,SER.IDALTERNA,SER.TIPOMED, TIPOSERVICIO = CASE RENCP.IDCONCEPTORIPS                                 
	 WHEN '06' THEN '3' WHEN '07' THEN '4' WHEN '08' THEN '3' WHEN '09' THEN '1' WHEN '10' THEN '1' WHEN '11' THEN '1'                                 
	 WHEN '14' THEN '2' END,                                        
	 LEFT (SER.DESCSERVICIO,60) AS DESCSERVICIO, '' AS NOMGENERICO,'' AS FORMA,'' AS CONCENTRACION,'' AS UMEDIDA,CAST(1 AS INT) AS  CANTIDAD,                                    
	 '1' AS AMBITO, COALESCE(case when CIT.FINALIDAD='' then null else CIT.FINALIDAD end,PRE.FINALIDAD) AS FINALIDAD,                                        
	 '2' AS VIAINGRESO, '' AS PERSONALAT, CIT.IDDX,                             
	 CASE CIT.TIPODX WHEN NULL THEN '1' WHEN 'Impr Dx' THEN '1' WHEN 'Presuntivo' THEN '1' WHEN 'Definitivo' THEN '3'                             
	 WHEN 'Conf Nuevo' THEN '2' WHEN 'Conf Repet' THEN '3' ELSE '1' END AS TIPODX,                                        
	 '' AS DXSALIDA, CIT.IDDX, CIT.DXRELACIONADO, '' AS DX3, CIT.COMPLICACION, '' AS FORMAREALIZACION,                                 
	 CASE CIT.IDCAUSAEXT WHEN NULL THEN '13' WHEN '' THEN '13' else CIT.IDCAUSAEXT END  CAUSAEXT, '' AS CAUSAMUERTE, '' AS DESTINO,                                         
	 '1' AS ESTADOSALIDA, COALESCE(CIT.VALORTOTAL,0) AS VALOR, COALESCE(CIT.VALORMODERADORA,0) AS VALORCOPAGO, FTR.VALORCOPAGO AS VRCOPAGO, FTR.VALORMODERADORA AS VRMODERADORA,                            
	 --CASE WHEN CIT.VALORCOPAGO <> 0 THEN '02' WHEN CIT.VALORMODERADORA <> 0 THEN '01' ELSE '04' END AS TIPOPAGOMODERADOR,                             
	 COALESCE(CIT.VALORTOTAL,0) AS VALORITEM, round(COALESCE(CIT.VALORTOTAL,0)-COALESCE(CIT.VALORMODERADORA,0) ,0) AS VRNETO,                                        
	 FTR.ESTADO AS ESTADOFACTURA, CAPITADO=case when cit.TIPOCONTRATO='C' then 1 else 0 end,0 CIRUGIA,                                 
	 IDCIRUGIA=cast('' as varchar(20)),CONSECUTIVOCX=cast('' as varchar(20)), cit.KCNTRID,cit.KCNTID,ttec.TIPOSISTEMA, CIT.IDSEDE, FTR.TIPOFIN                                        
	FROM                                 
	 CIT                                
	 INNER JOIN AFI ON AFI.IDAFILIADO = CIT.IDAFILIADO                                 
	 INNER JOIN SER ON SER.IDSERVICIO = CIT.IDSERVICIO                          
	 LEFT JOIN PRE ON PRE.PREFIJO    = SER.PREFIJO                                
	 LEFT JOIN RENCP ON RENCP.IDCONCEPTORIPS = SER.CODIGORIPS                                
	 LEFT JOIN  FTR ON FTR.N_FACTURA  = CIT.N_FACTURA                                 
	 LEFT JOIN ttec on cit.tipottec=ttec.tipo                                        
	WHERE CIT.N_FACTURA=@N_FACTURA and RENCP.ARCHIVO=@ARCHIVORIPS and
	 CIT.CITASIMULTANEA = 1 AND CIT.IDAFILIADO IS NOT NULL and TIPOCITA='Cita'                                         
	 and (coalesce(CUMPLIDA,0)=1 or (coalesce(CUMPLIDA,0)=0 and coalesce(FACTURADA,0)=1))                                        
                                        
	UNION ALL                                        
                                        
	-- <27.11.2020: NUEVO AJUSTE PARA SACAR TELECONSULTAS ODONTOLOGICAS POR APARTE> (Aportado por Erick y Pacho: 30.nov.2020)                                        
	SELECT                                
	 'CIT' AS TABLA, CIT.CITID PRESTACIONID, CIT.CONSECUTIVO, 1 AS ITEM, SER.CODIGORIPS, RENCP.ARCHIVO AS ARCHIVORIPS,                                 
	 CASE CIT.CLASEORDEN WHEN 'PyP' THEN 1 ELSE 0 END AS PYP, FTR.IDTERCERO AS IDTERCEROFACT, CIT.IDCONTRATANTE, CIT.IDPLAN,                                 
	 CIT.N_FACTURA, AFI.IDAFILIADO,  AFI.TIPO_DOC, AFI.DOCIDAFILIADO, CIT.FECHA, NULL AS FINGRESO, CIT.NOAUTORIZACION,                                 
	 NULL AS FEGRESO, CIT.IDSERVICIO, SER.IDALTERNA, SER.TIPOMED, TIPOSERVICIO  = CASE RENCP.IDCONCEPTORIPS                                            
	 WHEN '06' THEN '3' WHEN '07' THEN '4'  WHEN '08' THEN '3' WHEN '09' THEN '1'  WHEN '10' THEN '1' WHEN '11' THEN '1'                                
	 WHEN '14' THEN '2' END,                                 
	 LEFT (SER.DESCSERVICIO,60) AS DESCSERVICIO, '' AS NOMGENERICO, '' AS FORMA, '' AS CONCENTRACION, '' AS UMEDIDA, CAST(1 AS INT) AS CANTIDAD,                             
	 '1' AS AMBITO,  /* [AMBITO] */ coalesce(h.FINALIDAD,PRE.FINALIDAD) AS FINALIDAD, /*[FINALIDAD]*/ '2' AS VIAINGRESO,                                         
	  COALESCE(CIT.PERSONAL_AT,'5') AS PERSONALAT, -- [PERSONAL ATIENDE]                                      
	  H.IDDX AS IDDX,    -- [DX PRINCIPAL]                                        
	 CASE H.TIPODX WHEN NULL THEN '1' WHEN 'Impr Dx' THEN '1' WHEN 'Presuntivo' THEN '1' WHEN 'Definitivo' THEN '3'                            
	 WHEN 'Conf Nuevo' THEN '2' WHEN 'Conf Repet' THEN '3' ELSE '1' END AS TIPODX,        -- [TIPO DX]                                        
	  '' AS DXSALIDA,                                        
	  H.DX1 AS DX1,    -- [DX RELACIONADO 1]                                        
	  H.DX2 AS DX2,    -- [DX RELACIONADO 2]                                        
	  H.DX3 AS DX3,    -- [DX RELACIONADO 3]                                         
	  '' AS COMPLICACION,                                         
	  '' AS FORMAREALIZACION,                                         
	  --H.CAUSAEXT AS CAUSAEXT,    -- [CAUSA EXTERNA]                                        
	  case when COALESCE(h.CAUSAEXT,COALESCE(CIT.IDCAUSAEXT,'13'))='' then '13' else COALESCE(h.CAUSAEXT,COALESCE(CIT.IDCAUSAEXT,'13')) end AS  CAUSAEXT,                                         
	  '' AS CAUSAMUERTE,                                         
	  '' AS DESTINO,                                         
	  '1' AS ESTADOSALIDA,                                         
	  COALESCE(CIT.VALORTOTAL,0) AS VALOR,                                         
	  COALESCE(CIT.VALORMODERADORA,0) AS VALORCOPAGO, FTR.VALORCOPAGO AS VRCOPAGO, FTR.VALORMODERADORA AS VRMODERADORA,                           
	  --CASE WHEN CIT.VALORCOPAGO <> 0 THEN '02' WHEN CIT.VALORMODERADORA <> 0 THEN '01' ELSE '04' END AS TIPOPAGOMODERADOR,                            
	  COALESCE(CIT.VALORTOTAL,0) AS VALORITEM,                     
	  round(COALESCE(CIT.VALORTOTAL,0)-COALESCE(CIT.VALORMODERADORA,0) ,0) AS VRNETO,                                        
	  FTR.ESTADO AS ESTADOFACTURA,                                        
	  CAPITADO=case when cit.TIPOCONTRATO='C' then 1 else 0 end,                                        
	  0 CIRUGIA,                                        
	  IDCIRUGIA=cast('' as varchar(20)),                                        
	  CONSECUTIVOCX=cast('' as varchar(20)),                                        
	  cit.KCNTRID,                                        
	  cit.KCNTID,                                        
	  ttec.TIPOSISTEMA,                                        
	  CIT.IDSEDE, FTR.TIPOFIN                      
	FROM                                 
	 CIT with (nolock)                                         
	 INNER JOIN AFI with (nolock)  ON AFI.IDAFILIADO = CIT.IDAFILIADO                                        
	 INNER JOIN SER with (nolock)  ON SER.IDSERVICIO = CIT.IDSERVICIO                                        
	 LEFT  JOIN PRE with (nolock)  ON PRE.PREFIJO    = SER.PREFIJO                                        
	 LEFT  JOIN RENCP with (nolock)  ON RENCP.IDCONCEPTORIPS = SER.CODIGORIPS                                        
	 LEFT JOIN  FTR with (nolock)  ON FTR.N_FACTURA = CIT.N_FACTURA                                        
	 left join ttec with (nolock)  on cit.tipottec=ttec.tipo                                        
	 outer apply (                                        
		SELECT                                
	   top 1 a.CONSECUTIVO, a.IDDX, a.TIPODX, FINALIDAD=case when a.FINALIDAD='' then null else a.FINALIDAD end,                                        
	   a.DX1,a.DX2,a.DX3,a.CAUSAEXT,b.DESCRIPCION                                          
		FROM                                 
	   dbo.HCA a with (nolock)                                          
	   join dbo.MDX b with (nolock) ON a.IDDX = b.IDDX                                         
		-- join cp on a.CLASEPLANTILLA=cp.CLASEPLANTILLA  ????? de donde sale esta tabla ?????'                                
		WHERE                                
	   a.PROCEDENCIA='CE' and a.IDAFILIADO=cit.IDAFILIADO                                         
	   and (-- Busca por CONSECUTIVO de cita                                        
	   (coalesce(a.CNSCITA,'')<>'' and a.CNSCITA=CIT.CONSECUTIVO)                                        
	   or                                        
	   -- Busca por HC hechas ese mismo medico y día de la cita                                        
	   (/*coalesce(a.CNSCITA,'')='' and */a.IDMEDICO=cit.IDMEDICO                                         
	   and a.FECHA >= dbo.FNK_FECHA_SIN_MLS(CIT.fecha) and a.FECHA < dbo.FNK_FECHA_SIN_MLS(CIT.fecha)+1)                                        
		)                                            
	   order by a.FECHA                                        
	 ) h                                
	WHERE CIT.N_FACTURA=@N_FACTURA and RENCP.ARCHIVO=@ARCHIVORIPS and                                         
	 CIT.CITASIMULTANEA = 0 AND CIT.IDAFILIADO IS NOT NULL and TIPOCITA='Cita'                                         
	 and (coalesce(CUMPLIDA,0)=1 or (coalesce(CUMPLIDA,0)=0 and coalesce(FACTURADA,0)=1))                                         
	 and coalesce(ser.tiposervicio,'')='04' and h.consecutivo is not null                                        
                                        
	UNION ALL                                        
                                        
	-- AUTD/AUT                                        
	SELECT                                 
	 'AUTD' AS TABLA,AUTD.AUTDID PRESTACIONID,AUT.NOAUT,AUTD.NO_ITEM AS ITEM,SER.CODIGORIPS,RENCP.ARCHIVO AS ARCHIVORIPS,                                        
	 CASE AUT.CLASEORDEN WHEN 'PyP' THEN 1 ELSE 0 END AS PYP,                                        
	 FTR.IDTERCERO AS IDTERCEROFACT,AUT.IDCONTRATANTE,AUTD.IDPLAN,                                        
	 AUTD.N_FACTURA,AFI.IDAFILIADO,AFI.TIPO_DOC,AFI.DOCIDAFILIADO,AUT.FECHA,                                        
	 NULL AS FINGRESO,AUT.NUMAUTORIZA,NULL AS FEGRESO,AUTD.IDSERVICIO,SER.IDALTERNA,SER.TIPOMED,            
	 TIPOSERVICIO = CASE RENCP.IDCONCEPTORIPS                                 
	 WHEN '06' THEN '3' WHEN '07' THEN '4' WHEN '08' THEN '3' WHEN '09' THEN '1' WHEN '10' THEN '1'                                              
	 WHEN '11' THEN '1' WHEN '14' THEN '2' END,                                        
	 LEFT(coalesce(SER.DESCSERVICIOCUPS,SER.DESCSERVICIO),60) AS DESCSERVICIO, LEFT(SER.NOM_GENERICO,60) AS NOMGENERICO, IFFA.DESCRIPCION AS FORMA,                                
	 ICCN.DESCRIPCION AS CONCENTRACION,IUNI.DESCRIPCION AS UMEDIDA,CAST(ROUND(abs(COALESCE(AUTD.CANTIDAD,1)),0) AS INT) AS CANTIDAD,                                         
	 '1' as AMBITO, case RENCP.ARCHIVO  WHEN 'AC' then COALESCE(h.FINALIDAD,COALESCE(AUT.FINALIDAD,PRE.FINALIDAD))                                         
	 else COALESCE(AUT.FINALIDAD,PRE.FINALIDAD) end AS FINALIDAD, '2' AS VIAINGRESO, MES.PERSONAL_AT AS PERSONALAT, H.IDDX,                                         
	 CASE H.TIPODX WHEN NULL THEN '1' WHEN 'Impr Dx' THEN '1' WHEN 'Presuntivo' THEN '1' WHEN 'Definitivo' THEN '3'                             
	 WHEN 'Conf Nuevo' THEN '2' WHEN 'Conf Repet' THEN '3' ELSE '1' END AS TIPODX, '' AS DXSALIDA, H.DX1 AS DXR1, H.DX2 AS DXR2,                                         
	 H.DX3 AS DXR3, '' AS COMPLICACION, '' AS FORMAREALIZACION,                               
	 case when COALESCE(h.CAUSAEXT,COALESCE(AUT.IDCAUSAEXT,'13'))='' then '13' else COALESCE(h.CAUSAEXT,COALESCE(AUT.IDCAUSAEXT,'13')) end AS CAUSAEXT,                                          
	 '' AS CAUSAMUERTE, '' AS DESTINO, '1' AS ESTADOSALIDA,  round(CAST(abs(COALESCE(AUTD.VALOR,0)) AS DECIMAL(15,2)),0) AS VALOR,                                         
	 round(CAST(abs(COALESCE(AUTD.VALORCOPAGO,0)) AS DECIMAL(15,2)),0) AS VALORCOPAGO,  FTR.VALORCOPAGO AS VRCOPAGO, FTR.VALORMODERADORA AS VRMODERADORA,                           
	 round(CAST(abs(COALESCE(AUTD.VALOR,0)*COALESCE(AUTD.CANTIDAD,1)) AS DECIMAL(15,2)),0) AS VALORITEM,                                         
	 round(CAST(abs((COALESCE(AUTD.VALOR,0)*COALESCE(AUTD.CANTIDAD,1))-COALESCE(AUTD.VALORCOPAGO,0)) AS DECIMAL(15,2)),0) AS VRNETO,                                        
	 FTR.ESTADO AS ESTADOFACTURA,CAPITADO=coalesce(KCNT.CAPITA,0),0 CIRUGIA,IDCIRUGIA=cast('' as varchar(20)),CONSECUTIVOCX=cast('' as varchar(20)),                                        
	 AUTD.KCNTRID,AUT.KCNTID,ttec.TIPOSISTEMA, AUT.IDSEDE, FTR.TIPOFIN                                        
	FROM                                 
	 AUT with (nolock)                    
	 INNER JOIN AUTD with (nolock)  ON AUTD.IDAUT = AUT.IDAUT                                        
	 INNER JOIN AFI with (nolock)  ON AFI.IDAFILIADO = AUT.IDAFILIADO                                        
	 INNER JOIN SER with (nolock)  ON SER.IDSERVICIO = AUTD.IDSERVICIO                                        
	 LEFT  JOIN PRE with (nolock)  ON PRE.PREFIJO    = SER.PREFIJO                                        
	 LEFT  JOIN RENCP with (nolock)  ON RENCP.IDCONCEPTORIPS = SER.CODIGORIPS                                        
	 LEFT  JOIN HCA with (nolock)  ON HCA.CONSECUTIVO = AUT.CONSECUTIVOHCA                                        
	 LEFT  JOIN MED with (nolock)  ON MED.IDMEDICO = AUT.IDSOLICITANTE                                        
	 LEFT  JOIN MES with (nolock)  ON MES.IDEMEDICA = MED.IDEMEDICA                                        
	 LEFT  JOIN FTR with (nolock)  ON FTR.N_FACTURA  = AUTD.N_FACTURA                                        
	 LEFT  JOIN IART with (nolock)  ON IART.IDARTICULO = SER.IDARTICULO                                        
	 LEFT  JOIN IFFA with (nolock)  ON IFFA.IDFORFARM  = IART.IDFORFARM                                        
	 LEFT  JOIN ICCN with (nolock)  ON ICCN.IDCONCENTRA= IART.IDCONCENTRA                                        
	 LEFT  JOIN IUNI with (nolock)  ON IUNI.IDUNIDAD   = IART.IDUNIDAD                                        
	 left join ttec with (nolock)  on aut.tipottec=ttec.tipo                          
	 left join KCNT with (nolock)  on AUT.KCNTID=KCNT.KCNTID                                        
	 outer apply (                                  
		SELECT                                
	   top 1 a.IDDX,a.TIPODX,a.FINALIDAD,a.DX1,a.DX2,a.DX3,a.CAUSAEXT,b.DESCRIPCION                                          
		FROM                                 
	   dbo.HCA a with (nolock)                                          
	   JOIN dbo.MDX b with (nolock) ON a.IDDX = b.IDDX                                          
		where                                 
	   a.PROCEDENCIA='CE' and a.IDAFILIADO=AUT.IDAFILIADO                                         
	   and a.FECHA >= dbo.FNK_FECHA_SIN_MLS(AUT.fecha) and a.FECHA < dbo.FNK_FECHA_SIN_MLS(AUT.fecha)+1                                          
	   order by a.FECHA desc                                 
	  ) h --dbo.fnc_HCA_Afiliado(AUT.IDAFILIADO,AUT.FECHA) H                                         
	WHERE AUTD.N_FACTURA=@N_FACTURA and RENCP.ARCHIVO=@ARCHIVORIPS and
	 AUT.PEXTERNA = 0 AND AUT.ESTADO='Pendiente' AND COALESCE(AUT.PEXTERNA,0) = 0                                        
                                        
	UNION ALL                                        
                                        
	-- HPRED/HPRE                                        
	select * from dbo.fnc_RIPS_HPRED_2 (@N_FACTURA,@ARCHIVORIPS) ---CONSULTA SUELTA SIN CONDICIONES, ¿PARA QUÉ?                                       
                                        
	UNION ALL                                        
                                        
	-- HADM  -- AH y AU segun horas de estancia CAPITADO y NO CAPITADO                                        
	-- RIPSESTANCIAHORAS:  Cantidad de horas mínimas de estancia para generar Rips AH                                        
	-- RIPSESTANCIAAUTOMAT: Genera Archivo AH/AU automáticamenete dependiendo de RIPSESTANCIAHORAS                                        
	SELECT                                 
	 'HADM' AS TABLA,HADM.HADMID PRESTACIONID,HADM.NOADMISION,1 AS ITEM,'NA' AS CODIGORIPS, ar.ARCHIVORIPS, 0 AS PYP, FTR.IDTERCERO AS IDTERCEROFACT,                                
	 HADM.IDTERCERO AS IDCONTRATANTE,HADM.IDPLAN, P.N_FACTURA, AFI.IDAFILIADO,AFI.TIPO_DOC,AFI.DOCIDAFILIADO,HADM.FECHA, HADM.FECHA AS FINGRESO,                      
	 HADM.NOAUTORIZACION, case when HADM.CERRADA>=1 then HADM.FECHAALTA else p.FECHAFIN end AS FEGRESO, '' AS IDSERVICIO,'' AS IDALTERNA, '' AS TIPOMED,                                
	 '' AS TIPOSERVICIO,'' AS DESCSERVICIO, '' AS NOMGENERICO,'' AS FORMA,'' AS CONCENTRACION,'' AS UMEDIDA, CANTIDAD = case when ar.ARCHIVORIPS='AU'                                 
	 or h.Horas<=24 then 1 else cast(h.Horas / 24 as int) end, '2' AS AMBITO, '' AS FINALIDAD, HADM.VIAINGRESO, '' AS PERSONALAT, HADM.DXINGRESO AS IDDX,                                         
	 '' AS TIPODX, HADM.DXEGRESO AS DXSALIDA, HADM.DXSALIDA1 AS DXR1, HADM.DXSALIDA2 AS DXR2, HADM.DXSALIDA3 AS DXR3, HADM.COMPLICACION AS COMPLICACION,                                         
	 '' AS FORMAREALIZACION, CASE HADM.CAUSAEXTERNA WHEN NULL THEN '13' WHEN '' THEN '13' ELSE COALESCE(HADM.CAUSAEXTERNA,'13') END AS CAUSAEXT,                                         
	 HADM.CAUSABMUERTE AS CAUSAMUERTE, case when HADM.DESTINO in (4,5,6) then 1 else coalesce(HADM.DESTINO,1) end AS DESTINO,                  
	 HADM.ESTADOPSALIDA AS ESTADOSALIDA, 0 AS VALOR, 0 AS VALORCOPAGO, FTR.VALORCOPAGO AS VRCOPAGO, FTR.VALORMODERADORA AS VRMODERADORA,  0 AS VALORITEM, 0 AS VRNETO, FTR.ESTADO AS ESTADOFACTURA,                                 
	 CAPITADO = coalesce(KCNT.CAPITA,0), 0 CIRUGIA,IDCIRUGIA=cast('' as varchar(20)), CONSECUTIVOCX=cast('' as varchar(20)), KCNTRID=0, HADM.KCNTID,                                 
	 ttec.TIPOSISTEMA,HADM.IDSEDE, FTR.TIPOFIN             
	FROM                                 
	 HADM with (nolock)                                         
	 INNER JOIN AFI with (nolock)  ON AFI.IDAFILIADO = HADM.IDAFILIADO                                        
	 JOIN KCNT with (nolock) on HADM.KCNTID=KCNT.KCNTID --and KCNT.TIPOCONTRATO='C'                                        
	 LEFT JOIN  AFU with (nolock)  ON AFU.IDAREA     = HADM.IDAREA_ALTA                                        
	 LEFT JOIN  FTR with (nolock)  ON FTR.N_FACTURA  = HADM.N_FACTURA                                        
	 LEFT JOIN  HTAD with (nolock)  ON HTAD.TIPOADM  = HADM.TIPOADM                                        
	 --join (select distinct a.NOADMISION,b.KCNTRID,b.KCNTID from hpre a with (nolock) join hpred b with (nolock) on a.NOPRESTACION=b.NOPRESTACION where b.TIPOCONTRATO='C') x1 on hadm.NOADMISION=x1.NOADMISION                                         
	 LEFT JOIN ttec on hadm.tipottec=ttec.tipo                                        
	 outer apply (                                        
	  select                                 
	   a.N_FACTURA, FECHAFIN=max(b.FECHA) from HPRED a with(nolock)                                         
	   join HPRE b with(nolock) on a.NOPRESTACION=b.NOPRESTACION and b.NOADMISION=HADM.NOADMISION                                        
	   group by a.N_FACTURA                                        
	 ) p                                        
	 outer apply (select Horas = DATEDIFF(HOUR,HADM.FECHA,case when HADM.CERRADA>=1 then HADM.FECHAALTA else p.FECHAFIN end)) h                                        
	 outer apply (select HORASBASE=cast(coalesce(dbo.FNK_VALORVARIABLE('RIPSESTANCIAHORAS'),6) as int)) hb                                        
	 outer apply (select ARCHIVORIPS = CASE WHEN h.Horas > HB.HORASBASE THEN 'AH' ELSE 'AU' END) ar                            
                                        
	WHERE /* HADM.CERRADA >= case when KCNT.CAPITA=1 then 0 else 1 end AND */                                
	  -- Ya NO se filtra por CERRADA, porque pueden haber items facturados y la admision abierta                                         
	 HADM.N_FACTURA=@N_FACTURA and 'NA'=@ARCHIVORIPS and HTAD.RIPS_AH_AU=1                                         
	 AND COALESCE(HADM.CLASENOPROC,'')<>'NP' -- Excluye los NO Procesar                                        
	 AND HADM.CLASEING='A' -- Incluye solo Hospitalaria para AH y AU                                        
	 -- Si Genera Estancia Automática             
	 and dbo.FNK_VALORVARIABLE('RIPSESTANCIAAUTOMAT')='Si' or dbo.FNK_VALORVARIABLE('RIPSESTANCIAAUTOMAT')='1'                                        
                                        
	/* Ya estan Capitado y No Capitado en una sola consulta en el bloque anterior */ 
);
go



drop procedure dbo.spc_WD_JSONINVOICEGENERATION_CP_2
go
-- ===============================================================                                                  
-- PROCESO PARA GENERAR ARCHIVO JSON DE FACTURAS                                                                                    
-- SPC_WD_JSONINVOICEGENERATION Versión 1.0                                                  
-- ===============================================================                                                  
-- Change Log:                                                                                                
----Construcción RIPS JSON: Resolución 1036-2806-1557-2275-558                                              
----Armando objeto de DATOS RELATIVOS A LA TRANSACCIÓN Inicio                                              
CREATE PROCEDURE dbo.spc_WD_JSONINVOICEGENERATION_CP_2 
	@N_FACTURA_P VARCHAR(20), 
	@FECHAINI DATETIME, 
	@FECHAFIN DATETIME, 
	@TIPOSISTEMA VARCHAR(30), 
	@IDTERCERO VARCHAR(50), 
	@KCNTID VARCHAR(16) 
AS 
BEGIN
	DECLARE @N_FACTURA VARCHAR(20) = @N_FACTURA_P;
	DECLARE @RJSON NVARCHAR(MAX);
	-- Declara una variable para almacenar el JSON                
	DECLARE @FECHA_INI datetime = cast(@FECHAINI as date);
	--DECLARE @FECHA_FIN datetime = cast(cast(cast(@FECHAFIN as date) as varchar(10))+' 23:59:59:997' as datetime);  
	DECLARE @FECHA_FIN DATETIME = DATEADD(
	  MILLISECOND, 
	  -3, 
	  DATEADD(
		DAY, 
		1, 
		CAST(@FECHAFIN AS DATETIME)
	  )
	);
	DECLARE @TIPO_SISTEMA VARCHAR(20) = @TIPOSISTEMA;
	DECLARE @IDTERCEROC VARCHAR(50) = @IDTERCERO;
	DECLARE @KCNTIDC int = @KCNTID 
	--Cargamos los datos recursivos a RIPSRE                    
	--EXEC SPC_RECURSIVA @N_FACTURA_P                     
	
	if not exists(select uno=1 from RIPSJS where N_FACTURA=@N_FACTURA)
	begin
		INSERT INTO RIPSJS (N_FACTURA, RJSON, TIPO, ESTADO, FECHA_REG) 
		VALUES (@N_FACTURA,@RJSON, 'CP', 1, GETDATE());
	end

	update RIPSJS set  
	  RJSON = (
		SELECT 
		  DISTINCT '812007194' [numDocumentoIdObligado], 
		  @N_FACTURA [numFactura], 
		  '' [tipoNota], 
		  '' [numNota], 
		  (
			----Armando objeto de DATOS RELATIVOS A LA TRANSACCIÓN Fin                                              
			----Armando objeto de USUARIOS Inicio                                              
			SELECT 
			  DISTINCT TRIM(V.TIPO_DOC) [tipoDocumentoIdentificacion], 
			  TRIM(V.IDAFILIADO) [numDocumentoIdentificacion], 
			  --TRIM (A.TIPOAFILIADO) [tipoUsuario], --Original                                        
			  '02' [tipoUsuario], 
			  FORMAT(
				CAST (A.FNACIMIENTO as datetime2), 
				'yyyy-MM-dd'
			  ) [fechaNacimiento], 
			  --CASE WHEN A.SEXO = 'Femenino' THEN 'F' WHEN A.SEXO = 'Masculino' THEN 'M' END  [codSexo],       
			  'F' [codSexo], 
			  P.ISONUM [codPaisResidencia], 
			  A.CIUDAD [codMunicipioResidencia], 
			  CASE WHEN A.ZONA = 'U' THEN '02' WHEN A.ZONA = 'R' THEN '01' END [codZonaTerritorialResidencia], 
			  --  A.INCAPACIDADLABORAL [incapacidad], .- Ver de donde sacarlo                                  
			  'NO' [incapacidad], 
			  v.CNS as [consecutivo], 
			  170 [codPaisOrigen], 
			  ----Armando objeto de USUARIOS Fin                                              
			  ----Armando objeto de SERVICIOS con arreglo de CONSULTAS Inicio                                              
			  (
				SELECT 
				  '230010094901' [codPrestador], 
				  FORMAT(
					CAST (FECHA as datetime2), 
					'yyyy-MM-dd HH:mm'
				  ) [fechaInicioAtencion], 
				  NOAUTORIZACION [numAutorizacion], 
				  IDALTERNA [codConsulta], 
				  --AMBITO [modalidadGrupoServicioTecSal],                                   
				  '01' [modalidadGrupoServicioTecSal], 
				  --VIAINGRESO [grupoServicios],--Original                                    
				  '05' [grupoServicios], 
				  328 [codServicio], 
				  -- FINALIDAD [finalidadTecnologiaSalud], --Original                                    
				  '15' [finalidadTecnologiaSalud], 
				  --CAUSAEXT [causaMotivoAtencion],  --Original                                    
				  '26' [causaMotivoAtencion], 
				  IDDX [codDiagnosticoPrincipal], 
				  null [codDiagnosticoRelacionado1], 
				  --Ver como poder el valor real y cuando no se tenga queda null                              
				  null [codDiagnosticoRelacionado2], 
				  null [codDiagnosticoRelacionado3], 
				  CASE WHEN TIPODX = 1 THEN '01' WHEN TIPODX = 2 THEN '02' WHEN TIPODX = 3 THEN '03' WHEN TIPODX IS NULL THEN '01' END [tipoDiagnosticoPrincipal], 
				  'CC' [tipoDocumentoIdentificacion], 
				  TRIM(IDAFILIADO) [numDocumentoIdentificacion], 
				  CAST (VALOR AS INT) [vrServicio], 
				  --CASE WHEN (VRMODERADORA) >0 THEN '02' WHEN VRMODERADORA =0 THEN '05' END [conceptoRecaudo], -- Para intercosultas 04 No aplica pago moderador y valor Cero (0) - Existe una diferencia en lo de MINSALUD y lo que se envia en la factura                 
              
				  /*CASE WHEN (SELECT distinct(A.VALORMODERADORA) FROM FTR A WITH (NOLOCK) INNER JOIN VWA_RIPS_2 B ON A.N_FACTURA = B.N_FACTURA                         
				  WHERE A.N_FACTURA = @N_FACTURA and A.PROCEDENCIA ='CI') >0 THEN '02' ELSE '05' END*/
				  05 [conceptoRecaudo], 
              
				  /*CASE WHEN (SELECT distinct(A.VALORMODERADORA) FROM FTR A WITH (NOLOCK) INNER JOIN VWA_RIPS_2 B ON A.N_FACTURA = B.N_FACTURA                         
				  WHERE A.N_FACTURA = @N_FACTURA and A.PROCEDENCIA ='CI') IS NULL THEN 0                     
				  ELSE (SELECT distinct(A.VALORMODERADORA) FROM FTR A WITH (NOLOCK) INNER JOIN VWA_RIPS_2 B ON A.N_FACTURA = B.N_FACTURA                         
				  WHERE A.N_FACTURA = @N_FACTURA and A.PROCEDENCIA ='CI') END*/
				  0 [valorPagoModerador], 
				  '' [numFEVPagoModerador], 
				  ROW_NUMBER() OVER (
					ORDER BY 
					  (
						Select 
						  1
					  )
				  ) [consecutivo] 
				FROM 
				  dbo.fnc_RIPS_2(@N_FACTURA,'AC')  
				WHERE 
				  /*ARCHIVORIPS = 'AC' 
				  AND VALOR > 0 
				  AND IDCONTRATANTE = @IDTERCEROC 
				  AND KCNTID = @KCNTIDC 
				  and CAPITADO = 1 
				  AND FECHA BETWEEN @FECHA_INI 
				  AND @FECHA_FIN 
				  AND TIPOSISTEMA = @TIPO_SISTEMA 
				  AND (
					IDDX IS NOT NULL 
					OR IDDX <> ''
				  ) */
				  VALORITEM > 0 FOR JSON PATH, 
				  INCLUDE_NULL_VALUES --ROOT('consultas'),                                                   
				  ) AS [servicios.consultas], 
			  ----Armando objeto de SERVICIOS con arreglo de CONSULTAS Fin                                              
			  ----Armando objeto de SERVICIOS con arreglo de PROCEDIMIENTOS inicio                                              
			  (
				SELECT 
				  '230010094901' codPrestador, 
				  FECHA fechaInicioAtencion, 
				  '' idMIPRES, 
				  NOAUTORIZACION numAutorizacion, 
				  IDALTERNA codProcedimiento, 
				  --AMBITO [modalidadGrupoServicioTecSal],                             
				  '01' viaIngresoServicioSalud, 
				  --VIAINGRESO [grupoServicios],--Original                   
				  '01' modalidadGrupoServicioTecSal, 
				  '01' grupoServicios, 
				  1102 codServicio, 
				  '15' finalidadTecnologiaSalud, 
				  'CC' tipoDocumentoIdentificacion, 
				  TRIM (IDAFILIADO) numDocumentoIdentificacion, 
				  IDDX codDiagnosticoPrincipal, 
				  null codDiagnosticoRelacionado, 
				  --Ver como poder el valor real y cuando no se tenga queda null                                          
				  null codComplicacion, 
				  VALOR vrServicio, 
				  --CASE WHEN VALORCOPAGO >0 THEN '01' WHEN VALORCOPAGO =0 THEN '05' END [conceptoRecaudo],                  
              
				  /*CASE WHEN ROW_NUMBER() OVER (ORDER BY (Select 1)) =1 THEN (CASE WHEN (SELECT distinct(A.VALORCOPAGO) FROM FTR A INNER JOIN VWA_RIPS_2 B ON A.N_FACTURA = B.N_FACTURA                   
				  WHERE A.N_FACTURA = @N_FACTURA and A.PROCEDENCIA ='SALUD') >0 THEN '01' ELSE '05' END) ELSE '05' END*/
				  05 conceptoRecaudo, 
              
				  /*CASE WHEN ROW_NUMBER() OVER (ORDER BY (Select 1)) =1 THEN (SELECT distinct(A.VALORCOPAGO) FROM FTR A INNER JOIN VWA_RIPS_2 B ON A.N_FACTURA = B.N_FACTURA                   
				  WHERE A.N_FACTURA = @N_FACTURA and A.PROCEDENCIA ='SALUD') ELSE 0 END*/
				  0 valorPagoModerador, 
				  '' numFEVPagoModerador, 
				  ROW_NUMBER() OVER (
					ORDER BY 
					  (
						Select 
						  1
					  )
				  ) consecutivo 
				FROM 
				  dbo.fnc_RIPS_2(@N_FACTURA,'AP')  
				WHERE 
				  /*ARCHIVORIPS = 'AP' 
				  AND IDCONTRATANTE = @IDTERCEROC 
				  AND KCNTID = @KCNTIDC 
				  and CAPITADO = 1 
				  AND FECHA BETWEEN @FECHA_INI 
				  AND @FECHA_FIN 
				  AND TIPOSISTEMA = @TIPO_SISTEMA 
				  AND (
					IDDX IS NOT NULL 
					OR IDDX <> ''
				  ) 
				  and */VALORITEM > 0 
				  AND VALOR > 0 
				  AND TIPOSERVICIO is not NULL FOR JSON PATH, 
				  INCLUDE_NULL_VALUES --ROOT('procedimientos'),                                             
				  ) AS [servicios.procedimientos], 
			  ----Armando objeto de SERVICIOS con arreglo de PROCEDIMIENTOS Fin                                              
			  ----Armando objeto de SERVICIOS con arreglo de URGENCIAS Inicio                                              
			  (
				SELECT 
				  '230010094901' [codPrestador], 
				  FORMAT(
					CAST (FINGRESO as datetime2), 
					'yyyy-MM-dd HH:mm'
				  ) [fechaInicioAtencion], 
				  '26' [causaMotivoAtencion], 
				  IDDX [codDiagnosticoPrincipal], 
				  DXSALIDA [codDiagnosticoPrincipalE], 
				  null [codDiagnosticoRelacionadoE1], 
				  --Ver como poder el valor real y cuando no se tenga queda null                                                   
				  null [codDiagnosticoRelacionadoE2], 
				  null [codDiagnosticoRelacionadoE3], 
				  CASE WHEN ESTADOSALIDA = '1' THEN '01' WHEN ESTADOSALIDA = '2' THEN '02' END [condicionDestinoUsuarioEgreso], 
				  --null [codDiagnosticoCausaMuerte],  --Ver como poder el valor real y cuando no se tenga queda null             
				  CASE WHEN ESTADOSALIDA = '2' THEN CAUSAMUERTE ELSE null END [codDiagnosticoCausaMuerte], 
				  FORMAT(
					CAST (FECHA as datetime2), 
					'yyyy-MM-dd HH:mm'
				  ) [fechaEgreso], 
				  ROW_NUMBER() OVER (
					ORDER BY 
					  (
						Select 
						  1
					  )
				  ) [consecutivo] 
				FROM 
				  dbo.fnc_RIPS_2(@N_FACTURA,'AU') 
				WHERE 
				  --N_FACTURA = @N_FACTURA                                                   
				  /*ARCHIVORIPS = 'AU' 
				  AND IDCONTRATANTE = @IDTERCEROC 
				  AND KCNTID = @KCNTIDC 
				  and CAPITADO = 1 
				  AND FECHA BETWEEN @FECHA_INI 
				  AND @FECHA_FIN 
				  AND TIPOSISTEMA = @TIPO_SISTEMA 
				  AND (
					IDDX IS NOT NULL 
					OR IDDX <> ''
				  ) 
				  and */VALORITEM > 0 --AND TIPOSERVICIO <> 'NULL'  
				  FOR JSON PATH, 
				  INCLUDE_NULL_VALUES --ROOT('urgencias'),                                       
				  ) AS [servicios.urgencias], 
			  ----Armando objeto de SERVICIOS con arreglo de URGENCIAS Fin                                              
			  ----Armando objeto de SERVICIOS con arreglo de HOSPITALIZACIÓN Inicio                                              
			  (
				SELECT 
				  '230010094901' [codPrestador], 
				  '03' [viaIngresoServicioSalud], 
				  FORMAT(
					CAST (FINGRESO as datetime2), 
					'yyyy-MM-dd HH:mm'
				  ) [fechaInicioAtencion], 
				  NOAUTORIZACION [numAutorizacion], 
				  '26' [causaMotivoAtencion], 
				  IDDX [codDiagnosticoPrincipal], 
				  DXSALIDA [codDiagnosticoPrincipalE], 
				  null [codDiagnosticoRelacionadoE1], 
				  --Ver como poder el valor real y cuando no se tenga queda null                                                
				  null [codDiagnosticoRelacionadoE2], 
				  null [codDiagnosticoRelacionadoE3], 
				  IDDX [codComplicacion], 
				  CASE WHEN ESTADOSALIDA = '1' THEN '01' WHEN ESTADOSALIDA = '2' THEN '02' END [condicionDestinoUsuarioEgreso], 
				  CASE WHEN ESTADOSALIDA = '2' THEN DXSALIDA END [codDiagnosticoCausaMuerte], 
				  FORMAT(
					CAST (FINGRESO as datetime2), 
					'yyyy-MM-dd HH:mm'
				  ) [fechaEgreso], 
				  ROW_NUMBER() OVER (
					ORDER BY 
					  (
						Select 
						  1
					  )
				  ) [consecutivo] 
				FROM 
				  dbo.fnc_RIPS_2(@N_FACTURA,'AH') 
				WHERE 
				  --N_FACTURA = @N_FACTURA                                                   
				  /*ARCHIVORIPS = 'AH' 
				  AND IDCONTRATANTE = @IDTERCEROC 
				  AND KCNTID = @KCNTIDC 
				  and CAPITADO = 1 
				  AND FECHA BETWEEN @FECHA_INI 
				  AND @FECHA_FIN 
				  AND TIPOSISTEMA = @TIPO_SISTEMA 
				  AND (
					IDDX IS NOT NULL 
					OR IDDX <> ''
				  ) 
				  and*/ VALORITEM > 0 --AND TIPOSERVICIO <>NULL  
				  FOR JSON PATH, 
				  INCLUDE_NULL_VALUES --ROOT('hospitalización'),                                                
				  ) AS [servicios.hospitalizacion], 
			  ----Armando objeto de SERVICIOS con arreglo de HOSPITALIZACIÓN Fin                                              
			  ----Armando objeto de SERVICIOS con arreglo de RECIEN NACIDOS Inicio                                              
			  (
				SELECT 
				  '230010094901' [codPrestador], 
				  TRIM(TIPO_DOC) [tipoDocumentoIdentificacion], 
				  TRIM(IDAFILIADO) [numDocumentoIdentificacion], 
				  FORMAT(
					CAST (A.FNACIMIENTO as datetime2), 
					'yyyy-MM-dd'
				  ) [fechaNacimiento], 
				  '' [edadGestacional], 
				  '' [numConsultasCPrenatal], 
				  CASE WHEN A.SEXO = 'Femenino' THEN 'F' WHEN A.SEXO = 'Masculino' THEN 'M' END [codSexoBiologico], 
				  '' [peso], 
				  IDDX [codDiagnosticoPrincipal], 
				  CASE WHEN ESTADOSALIDA = '1' THEN '01' WHEN ESTADOSALIDA = '2' THEN '02' END [condicionDestinoUsuarioEgreso], 
				  '' [codDiagnosticoCausaMuerte], 
				  FECHA [fechaEgreso], 
				  ROW_NUMBER() OVER (
					ORDER BY 
					  (
						Select 
						  1
					  )
				  ) [consecutivo] 
				FROM 
				  dbo.fnc_RIPS_2(@N_FACTURA,'AN') 
				WHERE 
				  --N_FACTURA = @N_FACTURA                                                   
				  /*ARCHIVORIPS = 'AN' 
				  AND IDCONTRATANTE = @IDTERCEROC 
				  AND KCNTID = @KCNTIDC 
				  and CAPITADO = 1 
				  AND FECHA BETWEEN @FECHA_INI 
				  AND @FECHA_FIN 
				  AND TIPOSISTEMA = @TIPO_SISTEMA 
				  AND (
					IDDX IS NOT NULL 
					OR IDDX <> ''
				  ) 
				  and */VALORITEM > 0 --AND TIPOSERVICIO <>NULL  
				  FOR JSON PATH, 
				  INCLUDE_NULL_VALUES --ROOT('recienNacidos'),                                                 
				  ) AS [servicios.recienNacidos], 
			  ----Armando objeto de SERVICIOS con arreglo de RECIEN NACIDOS Fin                                              
			  ----Armando objeto de SERVICIOS con arreglo de MEDICAMENTOS Inicio                                              
          
			  /*     (                                                  
					SELECT                                                
					 '230010094901' [codPrestador],                                            
				  NOAUTORIZACION [numAutorizacion],                                            
				  '' [idMIPRES],                    
				  FORMAT(CAST (FECHA as datetime2), 'yyyy-MM-dd HH:mm') [fechaDispensAdmon],                                            
				  IDDX [codDiagnosticoPrincipal],                                                  
				  null [codDiagnosticoRelacionado],  --Ver como poder el valor real y cuando no se tenga queda null                                            
				  --CODIGORIPS [tipoMedicamento],--Original                                    
			   '01' [tipoMedicamento],                                    
				  IDALTERNA [codTecnologiaSalud],                                            
				  --DESCSERVICIO [nomTecnologiaSalud],  --Original                                    
			   null [nomTecnologiaSalud],                                      
				  --CONCENTRACION [concentracionMedicamento], --Original                                    
			   0 [concentracionMedicamento],                                     
				  --UMEDIDA [unidadMedida],  --Original                                    
			  0 [unidadMedida],                                     
			  --FORMA [formaFarmaceutica], --Original                                    
			   null [formaFarmaceutica],                                    
				  1 [unidadMinDispensa],                                            
				  CANTIDAD [cantidadMedicamento],                                                  
				  1 [diasTratamiento],                                            
				  'CC' [tipoDocumentoIdentificacion],  --Tomar la persona que ordena el médicamento                                           
				  TRIM(V.IDAFILIADO) [numDocumentoIdentificacion],  --Tomar la persona que ordena el médicamento                                        
				  VALOR [vrUnitMedicamento],                                             
				  CAST (VALORITEM AS INT) [vrServicio],                                            
				  '05' [conceptoRecaudo],                                            
				  0 [valorPagoModerador],                           
				  '' [numFEVPagoModerador],                                            
					 ROW_NUMBER() OVER (ORDER BY (Select 1)) [consecutivo]                                                              
					FROM                                                   
					 VWA_RIPS_2 WITH (NOLOCK)                                                  
					WHERE                                                    
					 --N_FACTURA = @N_FACTURA                                                   
					ARCHIVORIPS = 'AM'                              
					AND VALOR >0  
				 AND IDCONTRATANTE = @IDTERCEROC  AND KCNTID =@KCNTIDC and CAPITADO=1 AND FECHA BETWEEN @FECHA_INI AND @FECHA_FIN AND TIPOSISTEMA =@TIPO_SISTEMA  
				 AND (IDDX IS NOT NULL OR IDDX <>'') and VALORITEM>0  
					FOR JSON PATH, INCLUDE_NULL_VALUES --ROOT('medicamentos'),                                                 
				   ) AS [servicios.medicamentos],                                               
			  ----Armando objeto de SERVICIOS con arreglo de MEDICAMENTOS Fin                                              
			  ----Armando objeto de SERVICIOS con arreglo de OTROS SERVICIOS Inicio                                              
			  */
			  (
				SELECT 
				  '230010094901' [codPrestador], 
				  NOAUTORIZACION [numAutorizacion], 
				  '' [idMIPRES], 
				  FORMAT(
					CAST (FECHA as datetime2), 
					'yyyy-MM-dd HH:mm'
				  ) [fechaSuministroTecnologia], 
				  --              
				  '01' [tipoOS], 
				  --valor temporal                                          
				  IDALTERNA [codTecnologiaSalud], 
				  DESCSERVICIO [nomTecnologiaSalud], 
				  CANTIDAD [cantidadOS], 
				  'CC' [tipoDocumentoIdentificacion], 
				  TRIM(IDAFILIADO) [numDocumentoIdentificacion], 
				  VALOR [vrUnitOS], 
				  VALORITEM [vrServicio], 
				  '05' [conceptoRecaudo], 
				  0 [valorPagoModerador], 
				  '' [numFEVPagoModerador], 
				  ROW_NUMBER() OVER (
					ORDER BY 
					  (
						Select 
						  1
					  )
				  ) [consecutivo] 
				FROM 
				  dbo.fnc_RIPS_2(@N_FACTURA,'AT') 
				WHERE 
				  --N_FACTURA = @N_FACTURA                                                   
				  ARCHIVORIPS = 'AT' 
				  AND VALOR > 0 
				  AND IDCONTRATANTE = @IDTERCEROC 
				  AND KCNTID = @KCNTIDC 
				  and CAPITADO = 1 
				  AND FECHA BETWEEN @FECHA_INI 
				  AND @FECHA_FIN 
				  AND TIPOSISTEMA = @TIPO_SISTEMA 
				  AND (
					IDDX IS NOT NULL 
					OR IDDX <> ''
				  ) 
				  and VALORITEM > 0 FOR JSON PATH, 
				  INCLUDE_NULL_VALUES --ROOT('otrosServicios'),                                                 
				  ) AS [servicios.otrosServicios] ----Armando objeto de SERVICIOS con arreglo de OTROS SERVICIOS Fin                                              
			FROM 
			  (select distinct CNS=row_number() over(order by IDAFILIADO,TIPO_DOC), IDAFILIADO,TIPO_DOC from VWA_RIPS_2 V WITH (NOLOCK) where V.N_FACTURA = @N_FACTURA and V.VALORITEM > 0) V  
			  INNER JOIN AFI A WITH (NOLOCK) ON V.IDAFILIADO = A.IDAFILIADO 
			  INNER JOIN PAI P WITH (NOLOCK) ON A.IDPAIS = P.IDPAIS 
			/*WHERE 
			  --V.N_FACTURA = @N_FACTURA  
			  V.IDCONTRATANTE = @IDTERCEROC 
			  AND V.KCNTID = @KCNTIDC 
			  and V.CAPITADO = 1 
			  AND V.FECHA BETWEEN @FECHA_INI 
			  AND @FECHA_FIN 
			  AND V.TIPOSISTEMA = @TIPO_SISTEMA 
			  AND (
				V.IDDX IS NOT NULL 
				OR V.IDDX <> ''
			  ) 
			  and V.VALORITEM > 0 */FOR JSON AUTO, 
			  INCLUDE_NULL_VALUES
		  ) as usuarios -- ROOT('usuarios'), INCLUDE_NULL_VALUES)--;                                    
		  --FROM  VWA_RIPS_2 WITH (NOLOCK)                                                  
		  --WHERE                                                    
		  --N_FACTURA = @N_FACTURA                                                   
		  FOR JSON PATH, 
		  WITHOUT_ARRAY_WRAPPER
	  )
	  where N_FACTURA=@N_FACTURA

	-- AS JsonDownload                                                  
end
go

 /*
  SELECT * FROM vwc_Facturable WHERE N_FACTURA ='FONC150130'
  
  SELECT * FROM fnc_rips_2('FONC150130','AM')
  
  SELECT * FROM vwa_rips_2 where N_FACTURA='FONC150130' and ARCHIVORIPS='AM' 
  */


  EXEC SPC_WD_JSONINVOICEGENERATION_CP_2 'FONC150130', '1/11/2024','30/11/2024', 'Contributivo', '900156264', 56

    select js.*
  from RIPSJS j with(nolock)
	cross apply openjson(j.RJSON) js
  where j.N_FACTURA='FONC150130';

  update RIPSJS set RJSON=null  where N_FACTURA='FONC150130';


  select js.numDocumentoIdObligado, js.numFactura, js.tipoNota, js.numNota, u.*
  from RIPSJS j with(nolock)
	cross apply openjson(j.RJSON) with (
		numDocumentoIdObligado varchar(20),
		numFactura varchar(20),
		tipoNota	varchar(1),
		numNota	varchar(20),
		usuarios nvarchar(max) as json 
	) js
	cross apply openjson(js.usuarios) u
  where j.N_FACTURA='FONC150130';

	