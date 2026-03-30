drop PROCEDURE DBO.spc_FTR_GENERAR_FACTURA
go
CREATE PROCEDURE DBO.spc_FTR_GENERAR_FACTURA
   @CNSFCT VARCHAR(40)  
AS  
begin
	declare 
		@Tabla_N_FACTURA table (N_FACTURA varchar(20), FCNSID bigint, ESTADO varchar(20), ERRORMSG varchar(max), FCNSCNS bigint);
	declare 
		@COMPANIA VARCHAR(2), @IDSEDE VARCHAR(5), @IDAREA VARCHAR(20), @EFACTURA smallint, @TIPOFAC varchar(2),
		@N_FACTURA VARCHAR(20), @FCNSID smallint, @ESTADO varchar(12), @ERRORMSG varchar(max), @PREFIJOFTR varchar(10), 
		@FCNSCNS bigint, @CNSFACTURA varchar(20), @GENERADA smallint, @DVENCE smallint, @F_FACTURA datetime;

	begin try
		begin transaction;
		select @COMPANIA=COMPANIA, @IDSEDE=IDSEDE, @IDAREA=IDAREA_FTR, @CNSFACTURA=N_FACTURA, @GENERADA=GENERADA,
			@DVENCE=datediff(day,F_FACTURA,F_VENCE), @TIPOFAC=TIPOFAC
		from FTR with(nolock) where CNSFCT=@CNSFCT

		if @@ROWCOUNT=0
		begin
			raiserror ('No se encontró el Documento con Consecutivo No. %s.',16,1,@CNSFCT);
		end
		
		if @GENERADA=1
		begin
			raiserror ('Otra sesión ha generada la Factura No. %s. para este registro.',16,1,@CNSFACTURA);
		end

		-- Procesa la factura 
		insert into @Tabla_N_FACTURA (N_FACTURA, FCNSID, ESTADO, ERRORMSG, FCNSCNS)
		EXEC dbo.SPC_GENNUMEROFACTURA_FCNS @COMPANIA, @IDSEDE, @IDAREA

		select @N_FACTURA=a.N_FACTURA, @FCNSID=a.FCNSID, @ESTADO=a.ESTADO, @ERRORMSG=a.ERRORMSG, 
			@FCNSCNS=a.FCNSCNS,	@EFACTURA=b.EFACTURA, @PREFIJOFTR=b.PREFIJO
		from @Tabla_N_FACTURA a
			join dbo.FCNS b with(NoLock) on a.FCNSID=b.FCNSID

		if @ESTADO='OK'
		begin
			select @F_FACTURA = cast(cast(getdate() as date) as datetime), @DVENCE=coalesce(@DVENCE,0);

			if @TIPOFAC in ('7','8','9')
			begin
				-- Procesa la factura que son Copagos, Moderadora o Pago Compartido
				update FTR set N_FACTURA=@N_FACTURA, EFACTURA=@EFACTURA, PREFIJOFTR = @PREFIJOFTR,
					FCNSID=@FCNSID, FCNSCNS = @FCNSCNS, CUFE = '', PORENVIAR = 0, ERROR = 0, ERRORMSG = '', 
					IMPUTABLE = 0, GENERADA = 1, FECHAFAC=dbo.fnk_fecha_sin_mls(getdate()),
					F_FACTURA=@F_FACTURA, F_VENCE=@F_FACTURA + @DVENCE, IDT=@TIPOFAC+'789'
				where CNSFCT=@CNSFCT
			end
			else
			begin
				-- Procesa la factura que son Copagos, Moderadora o Pago Compartido
				update FTR set N_FACTURA=@N_FACTURA, EFACTURA=@EFACTURA, PREFIJOFTR = @PREFIJOFTR,
					FCNSID=@FCNSID, FCNSCNS = @FCNSCNS, CUFE = '', PORENVIAR = 0, ERROR = 0, ERRORMSG = '', 
					IMPUTABLE = 0, GENERADA = 1, FECHAFAC=dbo.fnk_fecha_sin_mls(getdate()),
					F_FACTURA=@F_FACTURA, F_VENCE=@F_FACTURA + @DVENCE
				where CNSFCT=@CNSFCT
			end

			update FTRD set N_FACTURA=@N_FACTURA WHERE CNSFTR=@CNSFCT;

			update KCNTFC set N_FACTURA=@N_FACTURA WHERE N_FACTURA=@CNSFACTURA;
		end
		else
		begin
		   raiserror ('Error en Generacion de N_FACTURA, la función no devolvió registros.',16,1);
		end

		if (@@TRANCOUNT>0)
			commit;
		SELECT N_FACTURA=@N_FACTURA, FCNSID=@FCNSID, PREFIJOFTR=@PREFIJOFTR, FCNSCNS=@FCNSCNS;
	end try
	begin catch
		declare 
			@ErrorMessage NVARCHAR(4000), @ErrorSeverity INT, @ErrorState INT;  
		select @ErrorMessage = ERROR_MESSAGE(), @ErrorSeverity = ERROR_SEVERITY(), @ErrorState = ERROR_STATE();  

		if @@TRANCOUNT>0
			rollback

		Raiserror(@ErrorMessage, @ErrorSeverity, @ErrorState);

		SELECT N_FACTURA='';
	end catch
end
go
