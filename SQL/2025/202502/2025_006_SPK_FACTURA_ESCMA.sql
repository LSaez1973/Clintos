drop PROCEDURE dbo.SPK_FACTURA_ESCMA
go
-- ---------------------------------------------------- 
-- ULTIMOS CAMBIOS:
-- 11.nov.2024.LSaez: Relación de facturas de Moderadora
-- 11.mar.2019.LSaez: FACTURARAIDTERPART: Control para facturar a tercero Particular dbo.fnk_ValorVariable('IDTERPART')
-- 22.ene.2019.LSaez: Manejo de campos para Facturación electrónica 
CREATE PROCEDURE dbo.SPK_FACTURA_ESCMA
	@PROCEDENCIA Varchar(20),
	@CNSRPDX   VARCHAR(20),    
	@NIT       VARCHAR(20),    
	@COMPANIA  VARCHAR(2),    
	@IDSEDE    VARCHAR(5),    
	@USUARIO   VARCHAR(12),    
	@IDTERCERO VARCHAR(20),    
	@IDPLAN    VARCHAR(6),    
	@OBSERVACION VARCHAR(255),    
	@IDTERCEROCA1 VARCHAR(20),
	@IDT bigint=0
AS    
	DECLARE @CNSFTR      VARCHAR(20)           
	DECLARE @DV          INT    
	DECLARE @DATO3       VARCHAR(20)    
	DECLARE @DATO2       VARCHAR(80)     
	DECLARE @VRTOTAL     DECIMAL(14,2)    
	DECLARE @VRSERV      DECIMAL(14,2)     
	DECLARE @VRCOPA      DECIMAL(14,2)    
	DECLARE @VRMODERA    DECIMAL(14,2)  
	DECLARE @VRPACO      DECIMAL(14,2)    
	DECLARE @OK          INT      
	DECLARE @VRDTO       DECIMAL(14,2)     
	DECLARE @VRABONO     DECIMAL(14,2)    
	DECLARE @TTEC        VARCHAR(10)    
	DECLARE @IDTERCEROCA VARCHAR(20)        
	DECLARE @SYS_COMPUTERNAME VARCHAR(254)    
	DECLARE @FTR_IDTRANSACCION  VARCHAR(20)    
	DECLARE @FTR_CONCEPTO       VARCHAR(254),
		@AFIRCID int,
		@KCNTID Int,
		@KCNTRID Int,
		@CA varchar(1),
		@TIPOCONTRATO Varchar(1),
		@NOCONTRATO Varchar(30),
		@TIPOSISTEMA Varchar(12),
		@N_FACTURA varchar(20), @ERROR_FCNS varchar(20), @MSJERROR_FCNS varchar(256), @FCNSID int, @FCNSCNS bigint,
		@EFACTURA smallint, @PREFIJOFTR varchar(10), @IDAREA VARCHAR(20),
		@C_IDTERPART smallint, @IDTERPART varchar(20)=dbo.fnk_ValorVariable('IDTERPART'),
		@FTRS SmallInt=0, @N_FACTURAS Varchar(Max), @ORIGEN Varchar(20), @RAZONSOCIAL Varchar(120);
	Declare @FTRD Table (
		CNSFTR varchar(40) NULL,
		N_CUOTA smallint NULL,
		FECHA datetime NULL,
		DB_CR varchar(2) NULL,
		IDPROVEEDOR Varchar(20) Null,
		AREAPRESTACION varchar(20) NULL,
		AREAFUNCONT varchar(20) NULL,
		UBICACION varchar(16) NULL,
		VR_TOTAL float NULL,
		IMPUTACION varchar(16) NULL,
		CCOSTO varchar(20) NULL,
		PREFIJO varchar(6) NULL,
		ANEXO varchar(1024) NULL,
		REFERENCIA varchar(40) NULL,
		IDCIRUGIA varchar(20) NULL,
		CANTIDAD decimal(18, 6) NULL,
		VALOR decimal(14, 2) NULL,
		VLR_SERVICI decimal(14, 2) NULL,
		VLR_COPAGOS decimal(14, 2) NULL,
		VLR_PAGCOMP decimal(14, 2) NULL,
		NOADMISION varchar(16) NULL,
		NOPRESTACION varchar(16) NULL,
		NOITEM smallint NULL,
		N_FACTURA varchar(16) NULL,
		SUBCCOSTO varchar(4) NULL,
		PCOSTO decimal(14, 2) NULL,
		FECHAPREST datetime NULL,
		VLRNOTADB decimal(14, 2) NULL,
		VLRNOTACR decimal(14, 2) NULL,
		TIPO varchar(20) NULL,
		IDIMPUESTO varchar(10) NULL,
		IDCLASE varchar(10) NULL,
		ITEM smallint NULL,
		VLRIMPUESTO decimal(14, 2) NULL,
		PIVA decimal(14, 5) NULL,
		VIVA decimal(14, 2) NULL,
		TIPOCONTRATOARS varchar(8) NULL,
		ARSTIPOCONTRATO varchar(11) NULL,
		ANO varchar(4) NULL,
		MES varchar(2) NULL,
		NAFILIADOS int NULL,
		IDPLAN varchar(6) NULL,
		IDTRANSACCION varchar(6) NULL,
		NUMDOCUMENTO varchar(16) NULL,
		VLR_PCOSTO decimal(14, 2) NULL,
		VALORMODERADORA decimal(14, 2) NULL,
		IDCUM varchar(20) NULL,
		NOINVIMA varchar(50) NULL,
		IDTARIFA varchar(5) NULL,
		KNEGID int NULL,
		KCNTID int NULL,
		NUMCONTRATO varchar(30) NULL,
		TIPOCONTRATO varchar(1) NULL,
		VLR_UPC decimal(22, 6) NULL,
		VLR_UPCNETA_M8P decimal(16, 2) NULL,
		VLRP_CAPITADO decimal(22, 6) NULL,
		KCNTRID int NULL,
		DESCUENTO decimal(16, 2) NULL,
		IDCONCEPTODTO varchar(5) NULL,
		IDSERVICIOREL varchar(20) NULL,
		PROCESO varchar(50) NULL,
		NOAUTORIZACION varchar(20)
	);
	Declare @TERCA Table (
		IDTERCEROCA Varchar(20) Null, 
		COBRARA Varchar(1) Null, 
		TIPOCONTRATO Varchar(20) Null, 
		NOCONTRATO Varchar(30) Null, 
		KCNTID Int null, 
		AFIRCID Int Null,
		TIPOSISTEMA Varchar(12) null
	);
	declare @FTR_Result as dbo.FTR_Result_Type;
	declare @Tabla_N_FACTURA table (N_FACTURA varchar(20), FCNSID bigint, ESTADO varchar(20), ERRORMSG varchar(max), FCNSCNS bigint);
	declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int, @cant_trans int, @QueryText varchar(max), @Proceso Varchar(50)='SPK_FACTURA_ESCMA', @error_grave smallint=0;
BEGIN
	-- select top 1 @QueryText=Query from dbo.fnDBA_QueryOpenTransaction() where session_id=@@spid;
	if coalesce(@IDT,0)=0
		set @IDT = dbo.fnc_GenFechaNumerica(getdate()); 

	SET @SYS_COMPUTERNAME = HOST_NAME()
	-- Validacion de Transacciones abiertas
	begin try
		if (@@TRANCOUNT>0)
		begin
			set @cant_trans=@@TRANCOUNT;
			rollback transaction;
			raiserror('FAVOR AVISAR A SISTEMAS: Existen transacciones abiertas previas al inicio de Facturacion. (%d)',16,1,@cant_trans);
		End
        
		set @ORIGEN = Case @PROCEDENCIA When 'CI' Then 'CIT' When 'CE' Then 'AUT' Else Null End
		If @ORIGEN is Null
        Begin
			raiserror('El Origen de los documentos no está identificado. (ORIGEN=%d)',16,1,@ORIGEN);
        end
	end try
	begin catch		  				
		select   
			@ErrorMessage = 'Error al ejecutar '+@Proceso+':'+char(13)+char(10)+coalesce(ERROR_MESSAGE(),'(desconocido)'),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE();

		exec dbo.SPC_ADD_SP_ERROR @ORIGEN = @Proceso, @ERROR = @ErrorMessage, @DOCUMENTO = @CNSRPDX, @IDSEDE = @IDSEDE, @USUARIO = @USUARIO, 
			@SYS_COMPUTERNAME = @SYS_COMPUTERNAME, @QUERYTEXT = @QueryText

		raiserror(@ErrorMessage,@ErrorSeverity,@ErrorState);
		return;
	end catch

	-- Inicio proceso de Facturación
	begin Try
		begin transaction
		-- LSaez.05.Feb.2018
		-- Corrección de @IDSEDE, cuando ésta llega nula o vacia, estaba generando consecutivo de Factura sin sedes 
		-- 1. Verifica que IDSEDE que viene en el parámetro exista
		select @IDSEDE = (select a.IDSEDE from SED a where a.IDSEDE=@IDSEDE);
		-- 2. Sino existe la sede suministrada; toma la del Equipo Facturador o la primera sede de la tabla SED
		if coalesce(@IDSEDE,'')=''
		begin
			select @IDSEDE = coalesce(b.IDSEDE,c.IDSEDE) 
			from dbo.UBEQ a With (NoLock)
				left join dbo.SED b With (NoLock) on a.IDSEDE=b.IDSEDE
				outer apply (select top (1) IDSEDE from dbo.SED With (NoLock) order by IDSEDE) c
			where a.SYS_ComputerName=HOST_NAME()		
		end
			
		-- SACAR DE DONDE SE TOMA EL CCOSTO
   
		SELECT @FTR_IDTRANSACCION = LTRIM(RTRIM(dbo.FNK_VALORVARIABLE('FTR_IDTRANSACCION')));
		SELECT @FTR_CONCEPTO = LTRIM(RTRIM(dbo.FNK_VALORVARIABLE('FTR_CONCEPTO')));
		SELECT @DATO3 = LEFT(dbo.FNK_VALORVARIABLE('IDFDEPFACTURACION'),20);        
		SELECT @DATO2 = dbo.FNK_VALORVARIABLE('IDMONEDABASE');    
	           	
		Insert Into @TERCA (IDTERCEROCA, COBRARA, TIPOCONTRATO, NOCONTRATO, KCNTID, AFIRCID, TIPOSISTEMA)
        Select distinct a.IDTERCEROCA, a.COBRARA, a.TIPOCONTRATO, NOCONTRATO=Coalesce(a.NUMCONTRATO, ''), a.KCNTID, a.AFIRCID, c.TIPOSISTEMA
        From dbo.vwc_Facturable a
			Left Join dbo.KCNT b With (NoLock) On a.KCNTID=b.KCNTID  
			Left Join dbo.TTEC c With (NoLock) On b.TIPOTTEC=c.TIPO
		Where a.ORIGEN=@ORIGEN and a.CNSFACT=@CNSRPDX 
			And Coalesce(a.FACTURADA, 0)=0 And a.MARCAFAC=1	And a.TIPOCONTRATO<>'C' -- Validaciones adicionales por si cambiaron despues de marcados
			
			--And (a.IDTERCEROCA = (CASE WHEN @IDTERCEROCA1='' THEN a.IDTERCEROCA ELSE @IDTERCEROCA1 END) OR    
			--	(a.IDTERCEROCA IS NULL AND @IDTERCERO=@IDTERCEROCA1 AND @IDTERCEROCA1<>'') OR    
			--	(a.IDTERCEROCA IS NULL AND @IDTERCEROCA1=''));    

		-- Control para facturar a tercero Particular
		-- LSaez.11.mar.2019: FACTURARAIDTERPART: Control para facturar a tercero Particular dbo.fnk_ValorVariable('IDTERPART')
		if dbo.fnk_ValorVariable('FACTURARAIDTERPART')='0'
		begin
			select @C_IDTERPART = (select count(*) from @TERCA where IDTERCEROCA=@IDTERPART)
			if @C_IDTERPART>0
			begin
				set @MSJERROR_FCNS = 'ERROR: No está permitido facturar a nombre del tercero particular(%s).'+char(13)+char(10)+char(9)+
					'Se encontraron %d Items con ese Tercero en el registro masivo.';
				Set @error_grave = 1;
				raiserror(@MSJERROR_FCNS,16,1,@IDTERPART,@C_IDTERPART);
			end
		end

		Declare CUR_FTR Cursor Static Local Read_Only for
		Select IDTERCEROCA, COBRARA, TIPOCONTRATO, KCNTRID=0, NOCONTRATO, KCNTID, AFIRCID, TIPOSISTEMA 
		From @TERCA

        Open CUR_FTR;
        
		Fetch Next From CUR_FTR
        Into @IDTERCEROCA, @CA, @TIPOCONTRATO, @KCNTRID, @NOCONTRATO, @KCNTID, @AFIRCID, @TIPOSISTEMA;

		If Coalesce(@@FETCH_STATUS,0)!=0
		Begin
			Set @error_grave = 1;
			raiserror('No hay Documentos marcados para facturar.',16,1);
        End
        
        While @@FETCH_STATUS=0
        Begin
			-- Se Crea tabla temporal con Identity...
			-- La tabla se destruye y crea nuevamente en el bucle para que el identity se resetee en 0
			Delete @FTRD;
			
			Insert Into @FTRD (
				CNSFTR, N_CUOTA, FECHA, DB_CR, IDPROVEEDOR, AREAPRESTACION, AREAFUNCONT, UBICACION, VR_TOTAL, IMPUTACION, CCOSTO, 
				PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD, VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, 
				NOADMISION,	NOPRESTACION, NOITEM, N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST, VLRNOTADB, VLRNOTACR, TIPO, IDIMPUESTO, 
				IDCLASE, ITEM, VLRIMPUESTO, PIVA, VIVA, TIPOCONTRATOARS, ARSTIPOCONTRATO, ANO, MES, NAFILIADOS, IDPLAN, 
				IDTRANSACCION, NUMDOCUMENTO, VLR_PCOSTO, VALORMODERADORA, IDCUM, NOINVIMA, IDTARIFA, IDSERVICIOREL, KNEGID, 
				KCNTRID, KCNTID, PROCESO, NOAUTORIZACION)
			Select CNSFTR=@CNSFTR, N_CUOTA=Row_Number() Over (Order By a.IDSERVICIO, a.FECHA), FECHA=dbo.FNK_FECHA_SIN_MLS(GetDate()), DB_CR='DB', 
				IDPROVEEDOR, AREAPRESTACION=a.IDAREA, AREAFUNCONT=a.IDAREA, UBICACION=Null, VR_TOTAL=a.VALOR * a.CANTIDAD, IMPUTACION=0, CCOSTO=a.CCOSTO, 
				PREFIJO=a.PREFIJO, ANEXO=a.DESCSERVICIO, REFERENCIA=a.IDSERVICIO, IDCIRUGIA=Null, CANTIDAD=a.CANTIDAD, VALOR=a.VALOR, 
				VLR_SERVICI=a.VALOR * a.CANTIDAD, VLR_COPAGOS=a.VALORCOPAGO, 
				VLR_PAGCOMP=a.VALORPCOMP, NOADMISION=case a.ORIGEN when 'HADM' then a.NOADMISION when 'CIT' then a.CNSCIT when 'AUT' then a.IDAUT end, 
				NOPRESTACION=a.NOPRESTACION, NOITEM=a.NOITEM, N_FACTURA=@N_FACTURA, 
				SUBCCOSTO=Null, PCOSTO=0, FECHAPREST=a.FECHA, VLRNOTADB=0, VLRNOTACR=0, TIPO=Null, IDIMPUESTO=Null, IDCLASE=Null, ITEM=Null, 
				VLRIMPUESTO=0, PIVA=0, VIVA=0, TIPOCONTRATOARS=Null, ARSTIPOCONTRATO=Null, ANO=Null, MES=Null, NAFILIADOS=Null, IDPLAN=Null, 
				IDTRANSACCION='FTR', NUMDOCUMENTO=@CNSFTR, VLR_PCOSTO=0, VALORMODERADORA=a.VALORMODERADORA, IDCUM=a.IDCUM, NOINVIMA=a.NOINVIMA, 
				IDTARIFA=a.IDTARIFA, a.IDSERVICIOREL, KNEGID=a.KNEGID, a.KCNTRID, a.KCNTID, @Proceso, NOAUTORIZACION
			From dbo.vwc_Facturable a
			Where a.ORIGEN=@ORIGEN and a.CNSFACT=@CNSRPDX And a.IDTERCEROCA=@IDTERCEROCA And a.KCNTID=@KCNTID And a.TIPOCONTRATO=@TIPOCONTRATO 
				And Coalesce(a.FACTURADA, 0)=0 And a.MARCAFAC=1;   			      
				
			UPDATE @FTRD SET     
				CANTIDAD    = coalesce(CANTIDAD,0),    
				VALOR       = coalesce(VALOR,0),  
				VLR_SERVICI = coalesce(VLR_SERVICI,0),  				 
				VLR_COPAGOS = coalesce(VLR_COPAGOS,0),  
				VALORMODERADORA  = coalesce(VALORMODERADORA,0),  
				VLR_PAGCOMP = coalesce(VLR_PAGCOMP,0)

			UPDATE @FTRD SET VR_TOTAL = VLR_SERVICI - VLR_COPAGOS - VALORMODERADORA - VLR_PAGCOMP
					         
			SELECT @OK = COUNT(*) FROM @FTRD where VLR_SERVICI>0 -- Solo servicios con valor  
			IF @OK > 0    
			BEGIN    
				-- 21.dic.2018.LSaez: Generación de No.Factura controlado por la tabla FCNS
				-- Toma Area de @FTRD
				select top (1) @IDAREA=AREAPRESTACION from @FTRD
				-- Se agregaro el parámetros @IDAREA_ALTA a SPC_GENNUMEROFACTURA_FCNS, este SP no usa RPDX
				insert into @Tabla_N_FACTURA (N_FACTURA, FCNSID, ESTADO, ERRORMSG, FCNSCNS)
				EXEC dbo.SPC_GENNUMEROFACTURA_FCNS @COMPANIA, @IDSEDE, @IDAREA

				select @N_FACTURA=null, @ERROR_FCNS=null, @MSJERROR_FCNS=null, @FCNSID=null;

				select @N_FACTURA=N_FACTURA, @ERROR_FCNS=ESTADO, @MSJERROR_FCNS=ERRORMSG, @FCNSID=FCNSID, @FCNSCNS=FCNSCNS 
				from @Tabla_N_FACTURA

				-- PRINT ' N_FACTURA = '+ coalesce(@N_FACTURA,'null')

				if @ERROR_FCNS = 'OK'
				begin	  
					EXEC dbo.SPK_GENCONSECUTIVO @COMPANIA = @COMPANIA, @SEDE = @IDSEDE, @PREFIJO = '@CNSFTR',  @NVOCONSEC = @CNSFTR OUTPUT  
					SELECT @CNSFTR = @IDSEDE + REPLACE(SPACE(8 - LEN(@CNSFTR))+LTRIM(RTRIM(@CNSFTR)),SPACE(1),0)
       
					-- PRINT 'CNSFCT ='+@CNSFTR

					-- LSaez.22.mar.2018 Si se factura a nombre del Afiliado, Crea entonces a este como Tercero
					-- esto si @IDTERCEROF=IDAFILIADO y el Tercero no existe en la tabla TER
					-- en el caso de Particulares, @IDTERCEROF ya vendría a este punto creado en TER
					--exec dbo.spc_TER_InsertFromAsistencial 'AFI', @IDTERCEROF;

					select @EFACTURA=EFACTURA, @PREFIJOFTR=PREFIJO from dbo.FCNS With (NoLock) where FCNSID=@FCNSID;

					SELECT @DV = a.DIASVENCIMIENTO, @TTEC= a.TIPOTTEC     
					FROM dbo.KCNT a With (NoLock)
					WHERE a.KCNTID=@KCNTID    
    			
					Select @VRDTO = 0, @VRABONO = 0, @DV = Case When Coalesce(@DV,0) = 0 Then 30 Else @DV end    
        
					SELECT @VRTOTAL = Coalesce(Sum(VR_TOTAL),0), @VRSERV = Coalesce(SUM(VLR_SERVICI),0), @VRCOPA = Coalesce(SUM(VLR_COPAGOS),0),    
						@VRPACO  = Coalesce(SUM(VLR_PAGCOMP),0), @VRMODERA= Coalesce(SUM(VALORMODERADORA),0)  
					FROM @FTRD               
       		           
					Set  @VRTOTAL = @VRSERV - @VRCOPA - @VRMODERA - @VRPACO - @VRDTO - @VRABONO    

					IF @VRTOTAL < 0
					Begin
						Set Language English; -- formato de decimales con punto (.) 
						set @MSJERROR_FCNS = 'ERROR: El valor total de la factura quedaría Negativo. (Tercero=%s, Tipo Contrato=%s)'+char(13)+char(10)+char(9)+
							'@VRTOTAL = @VRSERV - @VRCOPA - @VRMODERA - @VRPACO - @VRDTO - @VRABONO =>'+char(13)+char(10)+char(9)+
							 format(Cast(@VRTOTAL As Decimal(14,2)),'#,##0.00')+' = '+
							 format(Cast(@VRSERV As Decimal(14,2)),'#,##0.00')+' - '+
							 format(Cast(@VRCOPA As Decimal(14,2)),'#,##0.00')+' - '+
							 format(Cast(@VRMODERA As Decimal(14,2)),'#,##0.00')+' - '+
							 format(Cast(@VRPACO As Decimal(14,2)),'#,##0.00')+' - '+
							 format(Cast(@VRDTO As Decimal(14,2)),'#,##0.00')+' - '+
							 format(Cast(@VRABONO As Decimal(14,2)),'#,##0.00');
						Set Language Spanish;
						raiserror(@MSJERROR_FCNS,16,1,@IDTERCEROCA,@TIPOCONTRATO); 						
					End
					
					select @RAZONSOCIAL = RAZONSOCIAL from TER with (nolock) where IDTERCERO=@IDTERCEROCA

					INSERT INTO dbo.FTR(
						IDTRANSACCION, CONCEPTO, NUMDOCUMENTO, FECHADOCUMENTO, CNSFCT, COMPANIA, 
						CLASE, IDTERCERO, N_FACTURA, F_FACTURA, F_VENCE, IDSEDE,    
						VR_TOTAL, COBRADOR, VENDEDOR, MONEDA, OCOMPRA, ESTADO, F_CANCELADO,    
						IDAFILIADO, EMPLEADO, NOREFERENCIA, PROCEDENCIA, TIPOFAC, OBSERVACION,    
						TIPOVENTA, VALORCOPAGO, DESCUENTO, VALORPCOMP, CREDITO, INDCARTERA,    
						INDCXC, MARCACONT, CONTABILIZADA, NROCOMPROBANTE, MARCA, INDASIGCXC,    
						IMPRESO, VALORSERVICIOS, CLASEANULACION, CNSLOG, USUARIOFACTURA, FECHAFAC,    
						MIVA, PIVA, VR_ABONOS, IDPLAN, FECHAPASOCXC, TIPOFIN, CNSFMAS, IDAREA_ALTA,    
						CCOSTO_ALTA, IDDEP, TIPOTTEC, CUENTACXC, VALORMODERADORA,
						RAZONSOCIAL, TIPOCONTRATO, KCNTRID, NUMCONTRATO, TIPOSISTEMA, KCNTID,
						FCNSID, EFACTURA, PREFIJOFTR, PORENVIAR, ERROR, ERRORMSG, IMPUTABLE, PROCESO, FCNSCNS, IDT)     
					SELECT @FTR_IDTRANSACCION, @FTR_CONCEPTO, @CNSFTR, DBO.FNK_FECHA_SIN_MLS(GETDATE()),
						@CNSFTR, @COMPANIA, 'C', @IDTERCEROCA, @N_FACTURA, GETDATE(), GETDATE()+@DV, @IDSEDE,   
						@VRTOTAL, NULL, NULL, @DATO2, NULL, 'P', NULL, NULL, @USUARIO, 'VARIOS',    
						@PROCEDENCIA, 'M', @OBSERVACION , 'Credito', @VRCOPA, @VRDTO, @VRPACO, 0, 0, 0, 0, 0, NULL, 0, 0, 0, @VRSERV, NULL, NULL, @USUARIO,    
						GETDATE(), 0, 0, @VRABONO, @IDPLAN, NULL, 'C', NULL, @IDAREA, NULL, @DATO3, @TTEC, null, @VRMODERA,
						@RAZONSOCIAL, @TIPOCONTRATO, @KCNTRID, @NOCONTRATO, @TIPOSISTEMA, @KCNTID,
						@FCNSID, @EFACTURA, @PREFIJOFTR, PORENVIAR=0, ERROR=0, ERRORMSG='', IMPUTABLE=0, @Proceso, @FCNSCNS, @IDT;    
           
					Insert Into dbo.FTRD (
						CNSFTR, N_CUOTA, FECHA, DB_CR, AREAPRESTACION, AREAFUNCONT, UBICACION, VR_TOTAL, IMPUTACION, CCOSTO, 
						PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD, VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, NOADMISION, 
						NOPRESTACION, NOITEM, N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST, VLRNOTADB, VLRNOTACR, TIPO, IDIMPUESTO, 
						IDCLASE, ITEM, VLRIMPUESTO, PIVA, VIVA, TIPOCONTRATOARS, ARSTIPOCONTRATO, ANO, MES, NAFILIADOS, IDPLAN, 
						IDTRANSACCION, NUMDOCUMENTO, VLR_PCOSTO, VALORMODERADORA, IDCUM, NOINVIMA, IDTARIFA, IDSERVICIOREL, KNEGID, 
						KCNTRID, KCNTID, PROCESO, NOAUTORIZACION)
					Select @CNSFTR, N_CUOTA, FECHA, DB_CR, AREAPRESTACION, AREAFUNCONT, UBICACION, VR_TOTAL, IMPUTACION, CCOSTO, 
						PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD, VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, NOADMISION, 
						NOPRESTACION, NOITEM, @N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST, VLRNOTADB, VLRNOTACR, TIPO, IDIMPUESTO, 
						IDCLASE, ITEM, VLRIMPUESTO, PIVA, VIVA, TIPOCONTRATOARS, ARSTIPOCONTRATO, ANO, MES, NAFILIADOS, IDPLAN, 
						IDTRANSACCION, NUMDOCUMENTO, VLR_PCOSTO, VALORMODERADORA, IDCUM, NOINVIMA, IDTARIFA, IDSERVICIOREL, KNEGID, 
						KCNTRID, KCNTID, @Proceso, NOAUTORIZACION
					From @FTRD 
					
					Set @N_FACTURAS=Coalesce(@N_FACTURAS+', '+@N_FACTURA, @N_FACTURA);
					
					Set @FTRS += 1;
       
					-- GENERA LA DEDUCCION DE IMPUESTOS ESPERADA    
					EXEC dbo.SPK_FAC_IMPDEDUC @NIT = @NIT, @CNSFTR = @CNSFTR, @FACT = @N_FACTURA, @VALORTOTAL = @VRTOTAL        
				
					If @ORIGEN='CIT'
					begin
 						Update dbo.vwc_Facturable_CIT 
						Set FACTURADA=1, N_FACTURA=@N_FACTURA, CNSFCT = @CNSFTR, VFACTURAS = 0, MARCAFAC = 0 
						Where CNSFACT=@CNSRPDX And IDTERCEROCA=@IDTERCEROCA And KCNTID=@KCNTID And TIPOCONTRATO=@TIPOCONTRATO 

						insert into FTROFR (CNSFTR,N_FACTURA,VALORTOTAL)
						select distinct CNSFTR=@CNSFTR, a.N_FACTURA, a.VR_TOTAL
						from vwc_Facturable_CIT d 
							join FTR a with(nolock) on a.NOREFERENCIA=d.NOADMISION and a.TIPOFAC in ('7','8','9') and a.ORIGENINGASIS='CIT' and a.GENERADA=1 and a.ESTADO='P'  
								and not exists (select N_FACTURA from FTROFR o with(nolock) where o.N_FACTURA=a.N_FACTURA)
						Where d.CNSFACT=@CNSRPDX And d.IDTERCEROCA=@IDTERCEROCA And d.KCNTID=@KCNTID And d.TIPOCONTRATO=@TIPOCONTRATO 
					end
					Else
					if @ORIGEN='AUT'
					Begin
						-- 1. Actualiza vista (tabla=AUTD)
						Update dbo.vwc_Facturable_AUT
						Set FACTURADA=1, N_FACTURA=@N_FACTURA, CNSFCT=@CNSFTR 
						Where CNSFACT=@CNSRPDX And IDTERCEROCA=@IDTERCEROCA And KCNTID=@KCNTID And TIPOCONTRATO=@TIPOCONTRATO; 

						-- 2. Actualiza (tabla=AUT)
						-- Las AUT solo estan marcadas como facturadas cuando todas las AUTD.FACTURADA=1
						with m1 as(
							select IDAUT,
								FACTURADA=min(facturada), -- Si hay prestaciones sin facturar; FACTURADA será 0. 
								N_FACTURA=max(n_factura), -- Trae el N_FACTURA mayor de las ordenes facturadas, por que una orden puede terner varias facturas  
								VFACTURAS=sum(case when N_FACTURA<>'' then 1 else 0 end) -- Contador de facturas distintas
							from (
								-- Buscar Facturas distintas para la admisión cuando está facturada
								select IDAUT,FACTURADA=coalesce(FACTURADA,0), N_FACTURA=coalesce(case when FACTURADA=1 then N_FACTURA else '' end,'')
								from dbo.vwc_Facturable_AUT 
								where CNSFACT=@CNSRPDX And IDTERCEROCA=@IDTERCEROCA And KCNTID=@KCNTID And TIPOCONTRATO=@TIPOCONTRATO 
								group by IDAUT,coalesce(FACTURADA,0), coalesce(case when FACTURADA=1 then N_FACTURA else '' end,'')
							) x
							Group By x.IDAUT
						)    
						-- 2. Actualiza (tabla=AUT)
						Update dbo.AUT 
						Set	FACTURADA = b.FACTURADA, 
							VFACTURAS = case when b.VFACTURAS>0 then 1 else 0 end, -- Si hay por lo menos una factura; entonces es de varias facturas.
							N_FACTURA = Coalesce(c.N_FACTURA,b.N_FACTURA),
							CNSFCT = Coalesce(c.CNSFCT,@CNSFTR),
							MARCAFAC = 0
						from dbo.AUT a With (NoLock)
							join m1 b on a.IDAUT=b.IDAUT
							-- Si la orden se resuelve como facturada; busca N_FACTURA en FTR (si es de varias facturas, toma el N_FACTURA mayor) 
							left join dbo.FTR c With (NoLock) On b.N_FACTURA=c.N_FACTURA and b.FACTURADA=1

						insert into FTROFR (CNSFTR,N_FACTURA,VALORTOTAL)
						select distinct CNSFTR=@CNSFTR, a.N_FACTURA, a.VR_TOTAL
						from vwc_Facturable_AUT d 
							join FTR a with(nolock) on a.NOREFERENCIA=d.NOADMISION and a.TIPOFAC in ('7','8','9') and a.ORIGENINGASIS='CE' and a.GENERADA=1 and a.ESTADO='P'  
								and not exists (select N_FACTURA from FTROFR o with(nolock) where o.N_FACTURA=a.N_FACTURA)
						Where d.CNSFACT=@CNSRPDX And d.IDTERCEROCA=@IDTERCEROCA And d.KCNTID=@KCNTID And d.TIPOCONTRATO=@TIPOCONTRATO
					end	
					insert into @FTR_Result (TipoDoc,Documento,N_Factura,Error,Msg_Error) values ('MASIVO-'+@PROCEDENCIA,@IDTERCEROCA+'-'+ltrim(str(@KCNTID)),@N_FACTURA,0,'Generada.');
				end
				else
				begin
					-- Error en Generacion de N_FACTURA
					set @MSJERROR_FCNS = coalesce(@MSJERROR_FCNS,'Error en Generacion de N_FACTURA, la función no devolvió registros.');
					raiserror(@MSJERROR_FCNS,16,1);
				end						
			END
			else
			begin
				-- Error en Generacion de N_FACTURA
				set @MSJERROR_FCNS ='No existen servicios con valores mayor que cero para Facturar.';
				raiserror(@MSJERROR_FCNS,16,1);
			end

			FETCH NEXT FROM CUR_FTR    
			INTO  @IDTERCEROCA, @CA, @TIPOCONTRATO, @KCNTRID, @NOCONTRATO, @KCNTID, @AFIRCID, @TIPOSISTEMA;    
		END    
		CLOSE CUR_FTR    
		DEALLOCATE CUR_FTR    
		
		-- Guarda resultados de la facturación
		insert into FTR_Log (IDT,Fecha,TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber,ErrorSeverity,ErrorState,Origen,Usuario,PC)
		select @IDT,getdate(),TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber=null,ErrorSeverity=null,ErrorState=null,Origen=@Proceso,Usuario=@USUARIO,PC=@SYS_COMPUTERNAME 
		from @FTR_Result; 
		
		if (@@TRANCOUNT>0)
			commit
	end try
	begin catch
		IF CURSOR_STATUS('global','CUR_FTR')>=-1
		BEGIN
			DEALLOCATE CUR_FTR
		END					
		select   
			@ErrorMessage = 'Error al ejecutar '+@Proceso+':'+char(13)+char(10)+coalesce(ERROR_MESSAGE(),'(desconocido)'),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE();

		if (@@TRANCOUNT>0)	 
			rollback transaction;

		If @error_grave = 0
			-- Guarda resultados del error de facturación
			insert into FTR_Log (IDT,Fecha,TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber,ErrorSeverity,ErrorState,Origen,Usuario,PC)
			select @IDT,getdate(),'MASIVO'+@PROCEDENCIA,@IDTERCERO,'',Error=1,Msg_Error=Error_Message(),Error_Number(),Error_Severity(),Error_State(),Origen=@Proceso,Usuario=@USUARIO,PC=@SYS_COMPUTERNAME 
		else
			Raiserror(@ErrorMessage,@ErrorSeverity,@ErrorState);
	end catch
END
go