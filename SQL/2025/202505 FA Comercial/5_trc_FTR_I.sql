drop Trigger if exists dbo.trc_FTR_I
go
Create Trigger dbo.trc_FTR_I  
on dbo.FTR for insert
as
	if @@ROWCOUNT>1
	begin
		raiserror('No puede procesar mas de una Factura en una sola instrucción.',16,1);
		rollback;
		return;			
	end

	declare 
		@CNSFCT varchar(40),
		@REQUIERE_NOAUT_FTR smallint,
		@NOAUTORIZACION varchar(30),
		@NOREFERENCIA varchar(20),
		@MSJ_ERROR varchar(max),
		@PROCEDENCIA varchar(20),
		@TIPOFAC varchar(1),
		@FCNSID int,
		@FCNSCNS int,
		@USUARIOFACTURA varchar(12),
		@Cant_SinFacturar smallint,
		@Cant_SinEnviarDIAN smallint,
		@FTR_MAX_SINDIAN_xUSU smallint = coalesce(cast(dbo.FNK_ValorVariable('FTR_MAX_SINDIAN_xUSU') as smallint),0), 
		@FTR_MAX_SINNUM_xUSU smallint = coalesce(cast(dbo.FNK_ValorVariable('FTR_MAX_SINNUM_xUSU') as smallint),0),
		@OBS_SIGNACION varchar(1024), @N_FACTURA_COPAGOS varchar(20);

	--select @FTR_MAX_SINDIAN_xUSU,@FTR_MAX_SINNUM_xUSU

	-- Valida que no existan facturas de copagos sin relacionar a factura de EPS (selo se acepta una factura de Copagos por factura a EPS)	
	select top 1 @N_FACTURA_COPAGOS=a.N_FACTURA
	from inserted d 
		join FTR a with(nolock) on a.NOREFERENCIA=d.NOREFERENCIA and a.ESTADO='P' and a.ORIGENINGASIS=d.ORIGENINGASIS and a.CNSFCT<>d.CNSFCT -- Facturas de copagos
			and not exists (
				-- Facturas relacionaas a una de EPS
				select o.N_FACTURA 
				from FTROFR o with(nolock) 
				where o.N_FACTURA=a.N_FACTURA
			)
	where a.TIPOFAC in ('7','8','9')

	if not @N_FACTURA_COPAGOS is null
	begin
		raiserror('No puede facturar mas de un Copago/Moderdora porque ya tiene uno con la Factura No. %s',16,0,@N_FACTURA_COPAGOS);
		rollback;
		return;
	end

	select @CNSFCT=CNSFCT, @PROCEDENCIA = coalesce(PROCEDENCIA,''), @TIPOFAC=TIPOFAC, @FCNSID=FCNSID, @FCNSCNS=FCNSCNS, 
		@NOREFERENCIA=coalesce(NOREFERENCIA,''), @USUARIOFACTURA=USUARIOFACTURA
	from inserted
		
	if @FCNSID>0 and @FCNSCNS>0
	begin
		update FTR set GENERADA=1 where CNSFCT=@CNSFCT
	end

	if @FTR_MAX_SINNUM_xUSU>0
	begin
		select @Cant_SinFacturar=count(distinct IDT) from FTR with(nolock) 
		where CNSFCT<>@CNSFCT and GENERADA=0 and USUARIOFACTURA=@USUARIOFACTURA and ESTADO<>'A'

		if @Cant_SinFacturar>=@FTR_MAX_SINNUM_xUSU
		begin
			raiserror('Este usuario (%s) tiene %d Facturas pendientes por generar Número.',16,0,@USUARIOFACTURA,@Cant_SinFacturar);
			rollback;
			return;
		end
	end

	if @FTR_MAX_SINDIAN_xUSU>0
	begin
		select @Cant_SinEnviarDIAN=count(distinct IDT) from FTR with(nolock) 
		where CNSFCT<>@CNSFCT and coalesce(PORENVIAR,2)<2 and USUARIOFACTURA=@USUARIOFACTURA and ESTADO<>'A'

		if @Cant_SinEnviarDIAN>=@FTR_MAX_SINDIAN_xUSU
		begin
			raiserror('Este usuario (%s) tiene %d Facturas pendientes por enviar a la DIAN.',16,0,@USUARIOFACTURA,@Cant_SinEnviarDIAN);
			rollback;
			return;
		end
	end

	select @OBS_SIGNACION = b.OBS_SIGNACION	
	from FTR a with (nolock)
		join KCNT b with (nolock) on a.KCNTID=b.KCNTID
	where a.CNSFCT=@CNSFCT

	if @PROCEDENCIA in ('SALUD','CE','CI')
	begin
		if @NOREFERENCIA<>'MASIVA'
		begin
			-- Trae NOREFERENCIA
			if @PROCEDENCIA='SALUD'
				update FTR set IDADMINISTRADORA_AFI=b.IDADMINISTRADORA_AFI, NOAUTORIZACION=b.NOAUTORIZACION
				from (select CNSFCT=@CNSFCT, NOREFERENCIA=@NOREFERENCIA) a
					join HADM b with (nolock) on a.NOREFERENCIA=b.NOADMISION
					join FTR c with (nolock) on a.CNSFCT=c.CNSFCT
			else
			if @PROCEDENCIA='CI'
				update FTR set IDADMINISTRADORA_AFI=b.IDADMINISTRADORA_AFI, NOAUTORIZACION=b.NOAUTORIZACION
				from (select CNSFCT=@CNSFCT, NOREFERENCIA=@NOREFERENCIA) a
					join CIT b with (nolock) on a.NOREFERENCIA=b.CONSECUTIVO
					join FTR c with (nolock) on a.CNSFCT=c.CNSFCT
			else
			if @PROCEDENCIA='CE'
				update FTR set IDADMINISTRADORA_AFI=b.IDADMINISTRADORA_AFI, NOAUTORIZACION=b.NUMAUTORIZA
				from (select CNSFCT=@CNSFCT, NOREFERENCIA=@NOREFERENCIA) a
					join AUT b with (nolock) on a.NOREFERENCIA=b.IDAUT
					join FTR c with (nolock) on a.CNSFCT=c.CNSFCT

			select @REQUIERE_NOAUT_FTR=coalesce(b.REQUIERE_NOAUT_FTR,0), @NOAUTORIZACION = coalesce(a.NOAUTORIZACION,''),
				@MSJ_ERROR = case @PROCEDENCIA
					when 'SALUD' then 'Según el ID Contrato ('+ltrim(str(a.KCNTID))+'), se requiere el campo No. Autorización en la Admisión'
					when 'CI' then 'Según el ID Contrato ('+ltrim(str(a.KCNTID))+'), se requiere el campo No. Autorización en la Cita'
					when 'CE' then 'Según el ID Contrato ('+ltrim(str(a.KCNTID))+'), se requiere el campo No. Autorización en la Remisión de CE'
				end
			from FTR a with (nolock)
				join KCNT b with (nolock) on a.KCNTID=b.KCNTID
			where a.CNSFCT=@CNSFCT
		end

		if @REQUIERE_NOAUT_FTR=1 and @NOAUTORIZACION=''
		begin
			raiserror(@MSJ_ERROR,16,0);
		end
	end
	-- Signación DIAN y Tipo Factura ( (S)alud, (C)omercial )
	update FTR set OBS_SIGNACION=@OBS_SIGNACION, CLASE = coalesce(k.TIPOFACTURA,'S') 
	from KCNT k 
	where FTR.CNSFCT=@CNSFCT and k.KCNTID=FTR.KCNTID;
go