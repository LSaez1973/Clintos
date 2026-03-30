drop PROCEDURE DBO.SPK_ANULA_FACT  
go
CREATE PROCEDURE DBO.SPK_ANULA_FACT  
	@N_FACTURA        VARCHAR(16),  
	@COMPANIA         VARCHAR(2),  
	@SEDE             VARCHAR(5),  
	@USUARIO          VARCHAR(12),  
	@RAZONCAMBIO      VARCHAR(255),  
	@SYS_COMPUTERNAME VARCHAR(254),  
	@USUARIO2         VARCHAR(12)  
AS  
DECLARE @NVOCONSEC     VARCHAR(20)  
DECLARE @NOADMISION     VARCHAR(16)  
DECLARE @IDTERCERO     VARCHAR(20)  
DECLARE @NUMFACTURAS    INT,
	@PROCEDENCIA varchar(20),
	@TIPOFIN varchar(1),
	@IDTERCERO_EXT varchar(20), -- ID Tercero de la CIA vinculada que facturó a la UT (Origen)
	@BD varchar(30), -- BD de Origen Factura
	@CNSFCT_EXT varchar(40), -- CNSFCT Origen factura
	@CNSFCT varchar(40) -- CNSFCT de nueva Factura UT

BEGIN  
    SELECT top (1) @NOADMISION = NOREFERENCIA, @IDTERCERO  = IDTERCERO, @TIPOFIN=TIPOFIN, @PROCEDENCIA=PROCEDENCIA, @CNSFCT=CNSFCT
    FROM FTR with (nolock) WHERE N_FACTURA = @N_FACTURA  
--    SELECT @NOADMISION     
--    DELETE FROM HADMF WHERE N_FACTURA = @N_FACTURA  

	if @PROCEDENCIA='FINANCIERO' or @TIPOFIN='U' 
	begin
		if @TIPOFIN='U'
		begin
			-- Desvinculación de facturas UT
			declare cdv1 cursor static for
			select IDTERCERO, BDEXT, CNSFCT_EXT from FTRUT with (nolock) where CNSFCT=@CNSFCT
			open cdv1
			fetch next from cdv1 into @IDTERCERO_EXT, @BD, @CNSFCT_EXT
			while @@FETCH_STATUS=0
			begin
				exec dbo.spc_FTRUT_DesVincular @IDTERCERO_EXT, @BD, @CNSFCT_EXT, @CNSFCT, @N_FACTURA, 'A'  
				fetch next from cdv1 into @IDTERCERO_EXT, @BD, @CNSFCT_EXT
			end
			deallocate cdv1
		end
	end
	else
	begin
		UPDATE HADM SET FACTURADA = 0, N_FACTURA = NULL, CNSFCT = NULL/*, FACTURADAPARCIAL = 1*/ WHERE NOADMISION = @NOADMISION  
		UPDATE HADMF SET ESTADO = 'A' WHERE N_FACTURA = @N_FACTURA     
		UPDATE HPRED SET FACTURADA = 0, N_FACTURA = NULL WHERE N_FACTURA = @N_FACTURA  
		UPDATE HADM SET FACTURADA = 0, N_FACTURA = NULL, CNSFCT = NULL WHERE N_FACTURA = @N_FACTURA 
		UPDATE CIT SET FACTURADA = 0, N_FACTURA = NULL, CNSFCT = NULL WHERE N_FACTURA = @N_FACTURA 
		UPDATE AUTD SET FACTURADA = 0, N_FACTURA = NULL, CNSFCT = NULL WHERE N_FACTURA = @N_FACTURA 
		UPDATE AUT SET FACTURADA = 0, N_FACTURA = NULL, CNSFCT = NULL WHERE N_FACTURA = @N_FACTURA 
  
  		SELECT @NUMFACTURAS = COUNT(*) FROM FTR WHERE PROCEDENCIA=@NOADMISION AND PROCEDENCIA='SALUD'  
		IF COALESCE(@NUMFACTURAS,0) > 0  
			UPDATE HADM SET VFACTURAS = 0 WHERE NOADMISION = @NOADMISION  
	end   

    UPDATE FTR SET ESTADO = 'A', RAZONANULACION = @RAZONCAMBIO  WHERE  N_FACTURA = @N_FACTURA  

END   
go

drop PROCEDURE dbo.spc_ANULAR_FACTURA  
go
CREATE PROCEDURE dbo.spc_ANULAR_FACTURA  
	@N_FACTURA        VARCHAR(16),  
	@COMPANIA         VARCHAR(2),  
	@SEDE             VARCHAR(5),  
	@USUARIO          VARCHAR(12),  
	@RAZONCAMBIO      VARCHAR(255),  
	@SYS_COMPUTERNAME VARCHAR(254),  
	@USUARIO2         VARCHAR(12)  
AS  
DECLARE @NVOCONSEC     VARCHAR(20)  
DECLARE @NOADMISION     VARCHAR(16)  
DECLARE @IDTERCERO     VARCHAR(20)  
DECLARE @NUMFACTURAS    INT,  
	@TranCounter int,
	@PROCEDENCIA varchar(20),
	@TIPOFIN varchar(1),
	@IDTERCERO_EXT varchar(20), -- ID Tercero de la CIA vinculada que facturó a la UT (Origen)
	@BD varchar(30), -- BD de Origen Factura
	@CNSFCT_EXT varchar(40), -- CNSFCT Origen factura
	@CNSFCT varchar(40) -- CNSFCT de nueva Factura UT
BEGIN
	-- Control de Transacciones
	set @TranCounter = @@TRANCOUNT; -- Guarda el # de transacciones activas     
    if @TranCounter > 0  
        save transaction SaveTranc_spc_ANULAR_FACTURA;  -- ya existe una transaccion activa
    else  
        begin transaction;  -- Nueva transaccion 

	begin try    
		UPDATE FTR SET ESTADO = 'A', RAZONANULACION = @RAZONCAMBIO  WHERE  N_FACTURA = @N_FACTURA  

		UPDATE HADMF SET ESTADO = 'A' WHERE N_FACTURA = @N_FACTURA     
		UPDATE HPRED SET FACTURADA = 0, N_FACTURA = NULL WHERE N_FACTURA = @N_FACTURA  
		UPDATE HADM SET FACTURADA = 0, N_FACTURA = NULL, CNSFCT = NULL WHERE N_FACTURA = @N_FACTURA 
		UPDATE CIT SET FACTURADA = 0, N_FACTURA = NULL, CNSFCT = NULL WHERE N_FACTURA = @N_FACTURA 
		UPDATE AUTD SET FACTURADA = 0, N_FACTURA = NULL, CNSFCT = NULL WHERE N_FACTURA = @N_FACTURA 
		UPDATE AUT SET FACTURADA = 0, N_FACTURA = NULL, CNSFCT = NULL WHERE N_FACTURA = @N_FACTURA 
  
  		SELECT @NUMFACTURAS = COUNT(*) FROM FTR WHERE PROCEDENCIA=@NOADMISION AND PROCEDENCIA='SALUD'  
		IF COALESCE(@NUMFACTURAS,0) > 0  
			UPDATE HADM SET VFACTURAS = 0 WHERE NOADMISION = @NOADMISION   

		SELECT top (1) @TIPOFIN=TIPOFIN, @CNSFCT=CNSFCT FROM FTR with (nolock) WHERE N_FACTURA = @N_FACTURA  

		if @TIPOFIN='U'
		begin
			-- Desvinculación de facturas UT
			declare cdv1 cursor static for
			select IDTERCERO, BDEXT, CNSFCT_EXT from FTRUT with (nolock) where CNSFCT=@CNSFCT
			open cdv1
			fetch next from cdv1 into @IDTERCERO_EXT, @BD, @CNSFCT_EXT
			while @@FETCH_STATUS=0
			begin
				exec dbo.spc_FTRUT_DesVincular @IDTERCERO_EXT, @BD, @CNSFCT_EXT, @CNSFCT, @N_FACTURA, 'A' 
				fetch next from cdv1 into @IDTERCERO_EXT, @BD, @CNSFCT_EXT
			end
			deallocate cdv1
		end

 		if @TranCounter = 0  -- Solo cuando la transaccion inició con este SP.
			commit transaction; 
	end try
	begin catch	
		if @TranCounter = 0  -- Solo cuando la transaccion inició con este SP.
            rollback transaction;  
        else  
        -- Transaction started before procedure called, do not roll back modifications made before the procedure was called.  
        if XACT_STATE() <> -1  
			-- If the transaction is still valid, just roll back to the savepoint set at the start of the stored procedure.  
            rollback transaction SaveTranc_spc_ANULAR_FACTURA;  
            -- If the transaction is uncommitable, a rollback to the savepoint is not allowed because the savepoint rollback writes to  
            -- the log. Just return to the caller, which should roll back the outer transaction.		
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;  				
		select   
			@ErrorMessage = 'Error al tratar de ANULAR FACTURA ('+coalesce(ERROR_MESSAGE(),'desconocido')+')',  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE();
		raiserror(@ErrorMessage,@ErrorSeverity,@ErrorState);
	end catch   
END   
go


