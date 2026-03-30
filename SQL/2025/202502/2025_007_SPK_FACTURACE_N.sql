drop Procedure dbo.SPK_FACTURACE_N
go
-- ----------------------------------------------------
-- ULTIMOS CAMBIOS:
-- 11.nov.2024.LSaez: Relación de facturas de Moderadora
-- 5.nov.2019.LSaez: Solo para versión 8 de Clintos.
-- 22.mar.2019.LSaez: Control para facturar a Menores de Edad
-- 11.mar.2019.LSaez: FACTURARAIDTERPART: Control para facturar a tercero Particular dbo.fnk_ValorVariable('IDTERPART')
-- 22.ene.2019.LSaez: Manejo de campos para Facturación electrónica 
-- ----------------------------------------------------
Create Procedure dbo.SPK_FACTURACE_N
    @NOAUT        Varchar(16),
    @NIT          Varchar(20),
    @COMPANIA     Varchar(2),
    @IDSEDE       Varchar(5),
    @USUARIO      Varchar(12),
    @PRE1         Varchar(6),
    @PRE2         Varchar(6),
    @PRE3         Varchar(6),
    @PRE4         Varchar(6),
    @PRE5         Varchar(6),
    @PROC         Varchar(2),
    @IDTERCEROCA1 Varchar(20),
    @CETIPOHOSP   Varchar(6) =FALSE, -- PARAM. Que Especifica el tipo de manejo de Planes - Contratos 
    @IDPLANPAR    Varchar(6) =Null,   -- EL PLAN EN CEHOSP
	@IDT		  bigint=0 -- ID Transacción
--WITH ENCRYPTION
As
Begin
	Declare @CNSFTR Varchar(20);
	Declare @FACTURADA SmallInt;
	Declare @IDTERCERO Varchar(20);
	Declare @IDPLAN Varchar(6);
	Declare @DATO Varchar(80);
	Declare @IDTERCERO1 Varchar(20);
	Declare @OK Int;
	Declare @CA Varchar(15);
	Declare @IDAFILIADO Varchar(20);
	Declare @DV SmallInt;
	Declare @TV Varchar(10);
	Declare @CCOSTO Varchar(6);
	Declare @IDAREA Varchar(20);
	Declare @EC SmallInt;
	Declare @IDTERCEROF Varchar(20);
	Declare @DESCUENTO Decimal(14, 2);
	Declare @TIPODTO Varchar(1);
	Declare @VRTOTAL Decimal(14, 2);
	Declare @VRSERV Decimal(14, 2);
	Declare @VRCOPA Decimal(14, 2);
	Declare @VRPACO Decimal(14, 2);
	declare @VRMODERA    decimal(14,2)
	Declare @VRDTO Decimal(14, 2);
	Declare @VRABONO Decimal(14, 2);
	Declare @DATO3 Varchar(20);
	Declare @TTEC Varchar(10);
	Declare @NODESCUENTACOPAGO SmallInt;
	Declare @CUENTACXC Varchar(16);
	Declare @DATOCCOSTO Varchar(80);
	Declare @SOAT SmallInt;
	Declare @CNSHACTRAN Varchar(20);
	Declare @IDTERCEROCA Varchar(20);
	Declare @SYS_COMPUTERNAME Varchar(254);
	Declare @FTR_IDTRANSACCION Varchar(20);
	Declare @FTR_CONCEPTO Varchar(254), @AFIRCID Int, @IDTERCERO_RC Varchar(20), @N_FACTURA Varchar(20), @ERROR_FCNS Varchar(20), @MSJERROR_FCNS Varchar(256), @FCNSID Int, 
		@EFACTURA SmallInt, @PREFIJOFTR Varchar(10), @C_IDTERPART SmallInt, @IDTERPART Varchar(20) =dbo.FNK_VALORVARIABLE('IDTERPART'), @KCNTID Int, @TIPOSISTEMA Varchar(12), 
		@TIPOCONTRATO Varchar(1), @NUMCONTRATO Varchar(30), @RAZONSOCIAL Varchar(120), @FTRS SmallInt=0, @N_FACTURAS Varchar(Max), @IDAUT Varchar(20), @FCNSCNS bigint;
	declare @Tabla_N_FACTURA table (N_FACTURA varchar(20), FCNSID bigint, ESTADO varchar(20), ERRORMSG varchar(max), FCNSCNS bigint);
	declare @FTR_Result as dbo.FTR_Result_Type;
	Declare @TERCA As dbo.IDTERCERO_Type;
	Declare @ErrorMessage NVarchar(4000), @ErrorSeverity Int, @ErrorState Int, @cant_trans Int, @QueryText Varchar(Max), @Proceso varchar(50)='SPK_FACTURACE_N';

    -- Select Top 1 @QueryText=Query From dbo.fnDBA_QueryOpenTransaction() Where session_id=@@SPID;
    Set @SYS_COMPUTERNAME=Host_Name();

	if coalesce(@IDT,0)=0
		set @IDT = dbo.fnc_GenFechaNumerica(getdate()); 

    -- Validacion de Transacciones abiertas
    Begin Try
        If (@@TRANCOUNT>0)
        Begin
            Set @cant_trans=@@TRANCOUNT;
            Rollback Transaction;
            Raiserror('FAVOR AVISAR A SISTEMAS: Existen transacciones abiertas previas al inicio de Facturacion. (%d)', 16, 1, @cant_trans);
        End;
    End Try
    Begin Catch
        Select @ErrorMessage=N'Error al ejecutar '+@Proceso+':'+Char(13)+Char(10)+Coalesce(Error_Message(), '(desconocido)'), @ErrorSeverity=Error_Severity(), @ErrorState=Error_State();
        Exec dbo.SPC_ADD_SP_ERROR @Proceso, @ErrorMessage, @NOAUT, @IDSEDE, @USUARIO, @SYS_COMPUTERNAME, @QueryText;
        Raiserror(@ErrorMessage, @ErrorSeverity, @ErrorState);
		return;
    End Catch;

    -- Inicio proceso de Facturación
    Begin Try
        Begin Transaction;
        -- LSaez.05.Feb.2018
        -- Corrección de @IDSEDE, cuando ésta llega nula o vacia, estaba generando consecutivo de Factura sin sedes 
        -- 1. Verifica que IDSEDE que viene en el parámetro exista
        Select @IDSEDE= (Select a.IDSEDE From dbo.SED a With (NoLock) Where a.IDSEDE=@IDSEDE);
        -- 2. Sino existe la sede suministrada; toma la del Equipo Facturador o la primera sede de la tabla SED
        If Coalesce(@IDSEDE, '')=''
        Begin
            Select @IDSEDE=Coalesce(b.IDSEDE, c.IDSEDE)
            From dbo.UBEQ a With (NoLock)
                 Left Join dbo.SED b With (NoLock) On a.IDSEDE=b.IDSEDE
                 Outer Apply (Select Top (1) IDSEDE From dbo.SED With (NoLock) Order By IDSEDE) c
            Where a.SYS_ComputerName=Host_Name();
        End;

        -- SACAR DE DONDE SE TOMA EL CCOSTO
		Select @DATOCCOSTO=dbo.FNK_VALORVARIABLE('CCOSTOENPRESTACION');
		Select @FTR_IDTRANSACCION=LTrim(rtrim(dbo.FNK_VALORVARIABLE('FTR_IDTRANSACCION')));
		Select @FTR_CONCEPTO=LTrim(rtrim(dbo.FNK_VALORVARIABLE('FTR_CONCEPTO')));
		Select @DATO3=Left(dbo.FNK_VALORVARIABLE('IDFDEPFACTURACION'), 20)
		Select @DATO=dbo.FNK_VALORVARIABLE('IDMONEDABASE');

        -- PRINT 'INGRESE' 
        If @PROC='CE'
        Begin
			Select @IDAUT=IDAUT From dbo.AUT With (NoLock) Where NOAUT= @NOAUT
            If @CETIPOHOSP='CEHOSP'
            Begin
				set @FACTURADA = 1; -- 2020.01.14 Ya no se facturan las AUT que se emitieron desde HOSP.
				/* 2020.01.14
                Select @IDAFILIADO=a.IDAFILIADO, @DESCUENTO=a.DESCUENTO, @TIPODTO=a.TIPODTO, @CCOSTO=a.CCOSTO, 
					@CA=a.IMPUTABLE_A, @SOAT=a.SOAT, @CNSHACTRAN=a.CNSHACTRAN, @AFIRCID=a.AFIRCID, @KCNTID=a.KCNTID, @RAZONSOCIAL=t.RAZONSOCIAL,
					@TIPOCONTRATO=a.TIPOCONTRATO, @TIPOSISTEMA=a.TIPOSISTEMA, @NUMCONTRATO=Coalesce(b.NUMCONTRATO, ''), @TTEC=a.TIPOTTEC,
					@EC = T.ENVIODICAJA, @DV = T.DIASVTO
                From dbo.AUT a With (NoLock)
                     Left Join dbo.TER t With (NoLock) On T.IDTERCERO=a.IDCONTRATANTE
					 join KCNT b on a.KCNTID=b.KCNTID
                Where a.IDAUT=@IDAUT;

                Select Distinct @IDTERCERO=AUTD.IDTERCEROCA, @IDTERCERO1=AUTD.IDTERCEROCA
                From dbo.AUTD With (NoLock)
					Join dbo.AUT With (NoLock) On AUTD.IDAUT=AUT.IDAUT And AUT.IDAUT=@IDAUT
                Where  AUTD.IDPLAN=@IDPLANPAR;
                Select @IDPLAN=@IDPLANPAR;
                Select @FACTURADA=0;
				*/
            End
            Else
            Begin
                Select @FACTURADA=a.FACTURADA, @IDTERCERO=a.IDCONTRATANTE, @IDPLAN=a.IDPLAN, @IDAFILIADO=a.IDAFILIADO, 
					@DESCUENTO=a.DESCUENTO, @TIPODTO=a.TIPODTO, @CCOSTO=a.CCOSTO, @IDTERCERO1=a.IDCONTRATANTE, @CA=a.COBRARA, @SOAT=A.SOAT, 
					@CNSHACTRAN=A.CNSHACTRAN, @AFIRCID=A.AFIRCID, @EC = T.ENVIODICAJA, @DV = T.DIASVTO, @KCNTID=a.KCNTID, @RAZONSOCIAL=t.RAZONSOCIAL,
					@TIPOCONTRATO=a.TIPOCONTRATO, @TIPOSISTEMA=a.TIPOSISTEMA, @NUMCONTRATO=Coalesce(b.NUMCONTRATO, ''), @TTEC=A.TIPOTTEC
                From dbo.AUT a With (NoLock)
                     Left Join dbo.TER t With (NoLock) On t.IDTERCERO=a.IDCONTRATANTE
					 join KCNT b on a.KCNTID=b.KCNTID
                Where a.IDAUT=@IDAUT;
            End;
        End;
        Else
        Begin
		  -- PRINT 'CITAS'			
			SELECT  @FACTURADA = a.FACTURADA, @IDTERCERO = a.IDCONTRATANTE, @IDPLAN = a.IDPLAN, @IDAFILIADO = a.IDAFILIADO, 
				@DESCUENTO = a.DESCUENTO, @TIPODTO = a.TIPODTO, @CCOSTO=a.CCOSTO, @IDTERCERO1 = a.IDCONTRATANTE, @CA=a.COBRARA, @SOAT = a.SOAT,
					@CNSHACTRAN = a.CNSHACTRAN, @AFIRCID=a.AFIRCID, @EC = T.ENVIODICAJA, @DV = T.DIASVTO, @KCNTID=a.KCNTID, @RAZONSOCIAL=t.RAZONSOCIAL,
					@TIPOCONTRATO=a.TIPOCONTRATO, @TIPOSISTEMA = a.TIPOSISTEMA,  @NUMCONTRATO=coalesce(b.NUMCONTRATO,''),  @TTEC = A.TIPOTTEC 
			FROM dbo.CIT a With (NoLock) 
				LEFT JOIN dbo.TER t With (NoLock) ON t.IDTERCERO = a.IDCONTRATANTE
				join KCNT b on a.KCNTID=b.KCNTID
			WHERE a.CONSECUTIVO = @NOAUT
        End;

        If @FACTURADA=1
        Begin
            -- PRINT 'ME DEVUELVO POR QUE YA ESTA FACTURADA'
			If @PROC='CE'
            Begin
                Update dbo.AUT
                Set MARCAFAC=0
                From dbo.AUTD With (NoLock) 
                Where AUT.IDAUT=@IDAUT 

            End;
            Else
            Begin
                Update dbo.CIT
                Set CIT.MARCAFAC=0
                Where CONSECUTIVO=@NOAUT;
            End;
			If (@@TRANCOUNT>0) 
				Commit;
			Raiserror('La %s No. %s ya se encuentra Facturada.',16,1,@PROC,@NOAUT);
        End;

		Set @NODESCUENTACOPAGO = 0;
        
		If @PROC='CI'
        Begin
            Select @CA='Administradora';
        -- PRINT 'CA CITAS '+@CA   
        End;

        If @CA='Administradora'
        Begin
            If @DV Is Null
                Select @DV=30;
            If @DV=0
                Select @DV=30;
            Select @TV='Credito';
            Select @EC=ENVIODICAJA From dbo.TER With (NoLock) Where IDTERCERO=@IDTERCERO;
            If @EC Is Null
            Begin
                Select @EC=0;
            End;
            -- PRINT 'envio directo caja = '+str(@ec)     
            --SELECT @IDTERPART = DATO FROM USVGS WHERE IDVARIABLE = 'IDCJTERCEROEXTERNO'
            If @IDTERCERO1=@IDTERPART
            Begin
                Select @TV='Contado';
            End;
        End;
        Else 
		If @CA='Afiliado'
        Begin
            If @DV Is Null
                Select @DV=30;
            If @DV=0
                Select @DV=30;
            Select @EC=ENVIODICAJA From dbo.TER With (NoLock) Where IDTERCERO=@IDTERCERO1;
            If @EC Is Null
                Select @EC=0;
            If @EC=1
                Select @TV='Contado';
            Else
                Select @TV='Credito';
        End;

        Select @IDTERCEROF=b.IDTERCEROF From dbo.fnc_IDTERCERO_FTR(@IDTERCERO1, @CA, @IDAFILIADO, @AFIRCID) b;

        -- PRINT 'TERCERO F = '+@IDTERCEROF
        
        Create Table #TTER (IDTERCERO Varchar(20), COBRARA Varchar(1));

        If @PROC='CE'
        Begin
            If @CETIPOHOSP='CEHOSP'
            Begin
                --DECLARE CUR_FTR CURSOR FOR
                Insert Into #TTER Select @IDTERCEROF, @CA;
            End;
            Else
            Begin
                --DECLARE CUR_FTR CURSOR FOR
                Insert Into #TTER
                Select Distinct Case When TER.IDTERCERO Is Null Then @IDTERCEROF Else AUTD.IDTERCEROCA End, 
					Case When TER.IDTERCERO Is Null Then @CA Else AUTD.COBRARA End
                From dbo.AUT With (NoLock)
                     Inner Join dbo.AUTD With (NoLock) On AUTD.IDAUT=AUT.IDAUT
                     Left Join dbo.TER With (NoLock) On AUTD.IDTERCEROCA=TER.IDTERCERO
                Where AUT.IDAUT=@IDAUT And (AUT.FACTURADA=0 Or AUT.FACTURADA Is Null Or AUT.FACTURADA=2) 
					And (AUTD.FACTURADA=0 Or AUTD.FACTURADA Is Null) 
					And (TER.IDTERCERO= (Case When @IDTERCEROCA1='' Then TER.IDTERCERO Else @IDTERCEROCA1 End) 
							Or (TER.IDTERCERO Is Null And @IDTERCEROF=@IDTERCEROCA1 And @IDTERCEROCA1<>'') Or (TER.IDTERCERO Is Null And @IDTERCEROCA1=''));
            End;
        End;
        Else If @PROC='CI'
        Begin
            --DECLARE CUR_FTR CURSOR FOR
            Insert Into #TTER
            Select Case When TER.IDTERCERO Is Null Then @IDTERCEROF Else CIT.IDTERCEROCA End, Case When TER.IDTERCERO Is Null Then @CA Else CIT.COBRARA End
            From dbo.CIT With (NoLock)
                 Left Join dbo.TER With (NoLock) On CIT.IDTERCEROCA=TER.IDTERCERO
            Where CIT.CONSECUTIVO=@NOAUT And (CIT.FACTURADA=0 Or CIT.FACTURADA Is Null) 
					And (TER.IDTERCERO= (Case When @IDTERCEROCA1='' Then TER.IDTERCERO Else @IDTERCEROCA1 End) 
						Or (TER.IDTERCERO Is Null And @IDTERCEROF=@IDTERCEROCA1 And @IDTERCEROCA1<>'') Or (TER.IDTERCERO Is Null And @IDTERCEROCA1=''));
        End;

        Insert Into @TERCA (IDTERCERO)
        Select Distinct b.IDTERCEROF
        From #TTER a
             Cross Apply dbo.fnc_IDTERCERO_FTR(a.IDTERCERO, a.COBRARA, @IDAFILIADO, @AFIRCID) b;

        -- LSaez.11.mar.2019: FACTURARAIDTERPART: Control para facturar a tercero Particular dbo.fnk_ValorVariable('IDTERPART')
        Select @ERROR_FCNS=ERROR, @MSJERROR_FCNS=MSJERROR From dbo.fnc_FTR_FacturarIDTERPART(@TERCA);
        If @ERROR_FCNS=1
        Begin
            Raiserror(@MSJERROR_FCNS, 16, 1);
        End;

        -- LSaez.22.mar.2019: Control para facturar a Menores de Edad
        Select @ERROR_FCNS=ERROR, @MSJERROR_FCNS=MSJERROR From dbo.fnc_AFI_MenoresEdad(18, @TERCA);
        If @ERROR_FCNS=1
        Begin
            Raiserror(@MSJERROR_FCNS, 16, 1);
        End;

        Declare CUR_FTR Cursor Static For
        Select Distinct IDTERCERO, COBRARA From #TTER;
        Open CUR_FTR;
        Fetch Next From CUR_FTR
        Into @IDTERCEROCA, @CA;
        While @@FETCH_STATUS=0
        Begin
            -- LSaez.22.mar.2019 Busca Tercero para la Factura 
            Select @IDTERCEROF=IDTERCEROF, @IDTERCERO_RC=IDTERCERO_RC
            From dbo.fnc_IDTERCERO_FTR(@IDTERCEROCA, @CA, @IDAFILIADO, @AFIRCID) a;
            If Coalesce(@IDTERCERO_RC, '')<>''
            Begin
                -- Creación del Responsable como Tercero
                Exec dbo.spc_TER_InsertFromAsistencial 'AFIRC', @AFIRCID;
            End;

            -- Se Crea tabla temporal con Identity...
            -- La tabla se destruye y crea nuevamente en el bucle para que el identity se resetee en 0	 
            Create Table #FTRD1 (
                IDTRANSACCION  Varchar(6),
                NUMDOCUMENTO   Varchar(16),
                CNSFTR         Varchar(40),
                N_CUOTA        SmallInt Identity,
                FECHA          DateTime,
                DB_CR          Varchar(2),
                AREAPRESTACION Varchar(20),
                UBICACION      Varchar(16),
                VR_TOTAL       Float,
                IMPUTACION     Varchar(16),
                CCOSTO         Varchar(6),
                PREFIJO        Varchar(6),
                ANEXO          Varchar(1024),
                REFERENCIA     Varchar(40),
                IDCIRUGIA      Varchar(20),
                CANTIDAD       SmallInt,
                VALOR          Decimal(14, 2),
                VLR_SERVICI    Decimal(14, 2),
                VLR_COPAGOS    Decimal(14, 2),
                VLR_PAGCOMP    Decimal(14, 2), 
				VALORMODERADORA Decimal(14, 2),
				DESCUENTO		Decimal(14, 2),
                IDPROVEEDOR    Varchar(20),
                NOADMISION     Varchar(16),
                NOPRESTACION   Varchar(16),
                NOITEM         Int,
                AREAFUNCONT    Varchar(20),
                N_FACTURA      Varchar(16),
                SUBCCOSTO      Varchar(4),
                PCOSTO         Decimal(14, 2),
                FECHAPREST     DateTime,
				NOAUTORIZACION varchar(20)
            ); 
			
 			IF @PROC = 'CE'
			BEGIN      
				IF @CETIPOHOSP = 'CEHOSP' 
				BEGIN					
					INSERT INTO #FTRD1(IDTRANSACCION,NUMDOCUMENTO,CNSFTR, FECHA, DB_CR, AREAPRESTACION, UBICACION, VR_TOTAL,
							IMPUTACION, CCOSTO, PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD,
							VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, VALORMODERADORA, IDPROVEEDOR, NOADMISION,
							NOPRESTACION, NOITEM, AREAFUNCONT, N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST, NOAUTORIZACION)
					SELECT @FTR_IDTRANSACCION, @CNSFTR, @CNSFTR, GETDATE(), 'DB', AUT.IDAREA, NULL, VR_TOTAL=0, 
							NULL, CASE WHEN @DATOCCOSTO = 'SER:CCOSTO' THEN AUTD.CCOSTO ELSE AUT.CCOSTO END, 
							AUT.PREFIJO, SER.DESCSERVICIO, AUTD.IDSERVICIO, NULL, AUTD.CANTIDAD, AUTD.VALOR, 
							VLR_SERVICI=AUTD.CANTIDAD*AUTD.VALOR, VLR_COPAGOS=AUTD.VALORCOPAGO, VLR_PAGCOMP=0, VALORMODERADORA=0, 
							AUT.IDPROVEEDOR, @NOAUT, @NOAUT, AUTD.NO_ITEM, NULL, @N_FACTURA, AUT.SUBCCOSTO, AUTD.PCOSTO, AUT.FECHA,
							NOAUTORIZACION =	case when coalesce(AUTD.NOAUTORIZEXT,'')<>'' then AUTD.NOAUTORIZEXT else coalesce(AUT.NUMAUTORIZA,'') end							
					FROM   AUT INNER JOIN 
						AUTD ON AUTD.IDAUT = AUT.IDAUT INNER JOIN 
						SER ON SER.IDSERVICIO = AUTD.IDSERVICIO LEFT JOIN
						TER ON TER.IDTERCERO = AUTD.IDTERCEROCA
					WHERE  AUT.NOAUT = @NOAUT
						AND SER.PREFIJO       <> @PRE1
						AND SER.PREFIJO       <> @PRE2
						AND SER.PREFIJO       <> @PRE3
						AND SER.PREFIJO       <> @PRE4
						AND SER.PREFIJO       <> @PRE5                 
						AND (AUTD.FACTURADA=0 OR AUTD.FACTURADA IS NULL OR AUTD.FACTURADA=2)
						AND (TER.IDTERCERO = @IDTERCEROCA OR (TER.IDTERCERO IS NULL AND @IDTERCEROF=@IDTERCEROCA)) 
						AND AUTD.IDPLAN = @IDPLANPAR
				END
				ELSE
				BEGIN
					INSERT INTO #FTRD1(IDTRANSACCION,NUMDOCUMENTO,CNSFTR, FECHA, DB_CR, AREAPRESTACION, UBICACION, VR_TOTAL,
							IMPUTACION, CCOSTO, PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD,
							VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, VALORMODERADORA, IDPROVEEDOR, NOADMISION,
							NOPRESTACION, NOITEM, AREAFUNCONT, N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST, NOAUTORIZACION)
					SELECT @FTR_IDTRANSACCION, @CNSFTR, @CNSFTR, GETDATE(), 'DB', AUT.IDAREA, NULL, VR_TOTAL=0, 
							NULL, CASE WHEN @DATOCCOSTO = 'SER:CCOSTO' THEN AUTD.CCOSTO ELSE AUT.CCOSTO END, 
							AUT.PREFIJO, SER.DESCSERVICIO, AUTD.IDSERVICIO, NULL, AUTD.CANTIDAD, AUTD.VALOR, 
							VLR_SERVICI=AUTD.CANTIDAD*AUTD.VALOR, VLR_COPAGOS=AUTD.VALORCOPAGO, VLR_PAGCOMP=0, VALORMODERADORA=0, 
							AUT.IDPROVEEDOR, @NOAUT, @NOAUT, AUTD.NO_ITEM, NULL, @N_FACTURA, AUT.SUBCCOSTO, AUTD.PCOSTO,AUT.FECHA,
							NOAUTORIZACION =	case when coalesce(AUTD.NOAUTORIZEXT,'')<>'' then AUTD.NOAUTORIZEXT else coalesce(AUT.NUMAUTORIZA,'') end
					FROM   AUT INNER JOIN 
						AUTD ON AUTD.IDAUT = AUT.IDAUT INNER JOIN 
						SER ON SER.IDSERVICIO = AUTD.IDSERVICIO LEFT JOIN
						TER ON TER.IDTERCERO = AUTD.IDTERCEROCA
					WHERE  AUT.NOAUT = @NOAUT
						AND SER.PREFIJO       <> @PRE1
						AND SER.PREFIJO       <> @PRE2
						AND SER.PREFIJO       <> @PRE3
						AND SER.PREFIJO       <> @PRE4
						AND SER.PREFIJO       <> @PRE5                 
						AND (AUTD.FACTURADA=0 OR AUTD.FACTURADA IS NULL OR AUTD.FACTURADA=2)
						AND (TER.IDTERCERO = @IDTERCEROCA OR (TER.IDTERCERO IS NULL AND @IDTERCEROF=@IDTERCEROCA)) 
				END
			END
			ELSE
			BEGIN
				INSERT INTO #FTRD1(IDTRANSACCION,NUMDOCUMENTO,CNSFTR, FECHA, DB_CR, AREAPRESTACION, UBICACION, VR_TOTAL,
						IMPUTACION, CCOSTO, PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD,
						VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, VALORMODERADORA, IDPROVEEDOR, NOADMISION,
						NOPRESTACION, NOITEM, AREAFUNCONT, N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST,NOAUTORIZACION)
				SELECT @FTR_IDTRANSACCION, @CNSFTR, @CNSFTR, GETDATE(), 'DB', CIT.IDAREA, NULL, VR_TOTAL=0, 
					NULL, CIT.CCOSTO, SER.PREFIJO, SER.DESCSERVICIO, CIT.IDSERVICIO, NULL, CANTIDAD=1, VALOR=CIT.VALORTOTAL, 
					VLR_SERVICI=CIT.VALORTOTAL, VLR_COPAGOS=CIT.VALORCOPAGO, VLR_PAGCOMP=0, VALORMODERADORA=CIT.VALORMODERADORA, CIT.IDMEDICO, @NOAUT, @NOAUT, 1, 
					NULL, @N_FACTURA, CIT.SUBCCOSTO, CIT.VALORTOTALCOS, CIT.FECHA, CIT.NOAUTORIZACION 
				FROM   CIT INNER JOIN 
					SER ON SER.IDSERVICIO = CIT.IDSERVICIO LEFT JOIN
					TER ON TER.IDTERCERO = CIT.IDTERCEROCA
				WHERE  CIT.CONSECUTIVO   = @NOAUT
				AND    SER.PREFIJO       <> @PRE1
				AND    SER.PREFIJO       <> @PRE2
				AND    SER.PREFIJO       <> @PRE3
				AND    SER.PREFIJO       <> @PRE4
				AND    SER.PREFIJO       <> @PRE5                 
				AND    (CIT.FACTURADA=0 OR CIT.FACTURADA IS NULL)
				AND    (TER.IDTERCERO  = @IDTERCEROCA OR (TER.IDTERCERO IS NULL AND @IDTERCEROF=@IDTERCEROCA)) 
			END

            Select @OK=Count(*) From #FTRD1 Where VLR_SERVICI>0; -- Solo servicios con valor
            If @OK>0
            Begin
                -- 21.dic.2018.LSaez: Generación de No.Factura controlado por la tabla FCNS
                -- Toma Area de #FTRD1
                Select Top 1 @IDAREA=AREAPRESTACION From #FTRD1;
                -- Se agregaro el parámetros @IDAREA_ALTA a SPC_GENNUMEROFACTURA_FCNS, este SP no usa RPDX
				insert into @Tabla_N_FACTURA (N_FACTURA, FCNSID, ESTADO, ERRORMSG, FCNSCNS)
				EXEC dbo.SPC_GENNUMEROFACTURA_FCNS @COMPANIA, @IDSEDE, @IDAREA

				select @N_FACTURA=null, @ERROR_FCNS=null, @MSJERROR_FCNS=null, @FCNSID=null;

				select @N_FACTURA=N_FACTURA, @ERROR_FCNS=ESTADO, @MSJERROR_FCNS=ERRORMSG, @FCNSID=FCNSID, @FCNSCNS=FCNSCNS  
				from @Tabla_N_FACTURA

                -- PRINT ' N_FACTURA = '+ coalesce(@N_FACTURA,'null')
                If @ERROR_FCNS='OK'
                Begin
                    Exec SPK_GENCONSECUTIVO @COMPANIA, @IDSEDE, '@CNSFTR', @CNSFTR Output;
                    Select @CNSFTR=@IDSEDE+Replace(Space(8-Len(@CNSFTR))+LTrim(RTrim(@CNSFTR)), Space(1), 0);

					set @FTRS += 1;
					Set @N_FACTURAS=Coalesce(@N_FACTURAS+', '+@N_FACTURA, @N_FACTURA);

                    -- PRINT 'CNSFCT ='+@CNSFTR

                    -- LSaez.22.mar.2018 Si se factura a nombre del Afiliado, Crea entonces a este como Tercero
                    -- esto si @IDTERCEROF=IDAFILIADO y el Tercero no existe en la tabla TER
                    -- en el caso de Particulares, @IDTERCEROF ya vendría a este punto creado en TER
                    Exec dbo.spc_TER_InsertFromAsistencial 'AFI', @IDTERCEROF;

					select @EFACTURA=EFACTURA, @PREFIJOFTR=PREFIJO from FCNS where FCNSID=@FCNSID;

					IF @DESCUENTO IS NULL
						SELECT @DESCUENTO = 0
          
					IF @DESCUENTO > 0
					BEGIN
						IF @TIPODTO = 'P'
							SELECT @VRDTO = round(@VRTOTAL * (@DESCUENTO/100),0)
						ELSE 
							SELECT @VRDTO = round(@DESCUENTO,0) 
					END           
					ELSE
						SELECT @VRDTO = 0                						 
					
					UPDATE #FTRD1 SET 
						CANTIDAD    = CASE WHEN coalesce(CANTIDAD,0)=0 THEN 1 ELSE CANTIDAD END,
						VALOR       = coalesce(VALOR,0),
						VLR_SERVICI = round(coalesce(VALOR,0) * CASE WHEN coalesce(CANTIDAD,0)=0 THEN 1 ELSE CANTIDAD END,0),
						VLR_COPAGOS = round(coalesce(VLR_COPAGOS,0),0), -- Se debe ditribuir el valor de AUT.VALORCOPAGO o CIT.VALORCOPAGO y depende de @NODESCUENTACOPAGO
						VLR_PAGCOMP = round(coalesce(VLR_PAGCOMP,0),0), -- No aplica en CIT
						VALORMODERADORA = round(coalesce(VALORMODERADORA,0),0), -- Solo para CIT
						DESCUENTO   = 0, -- Se debe ditribuir el valor de AUT.DESCUENTO
						VR_TOTAL    = 0

					SELECT @VRSERV = SUM(VLR_SERVICI) FROM #FTRD1 
					
					-- Cuando hay Descuento, este debe distribuirse proporcionalmente en FTRD
					UPDATE #FTRD1 SET DESCUENTO = round(case when @VRDTO=0 then 0 else (VLR_SERVICI*@VRDTO)/@VRSERV end,0)

					if (select sum(DESCUENTO) from #FTRD1)<>@VRDTO
					begin
						-- Ajuste del descuento por +/- decimales, se aplica al último item
						with 
							x as (select top 1 N_CUOTA from #FTRD1 order by N_CUOTA desc),
							t as (select TotalError=sum(DESCUENTO) from #FTRD1)
						update #FTRD1 set DESCUENTO = DESCUENTO + (@VRDTO - t.TotalError)
						from #FTRD1 a join x on a.N_CUOTA=x.N_CUOTA
							cross apply t
					end

					if @PROC='CI' and @NODESCUENTACOPAGO=0 
					begin
						SELECT @VRCOPA = coalesce(VALORCOPAGO,0) FROM dbo.CIT with (nolock) WHERE CONSECUTIVO = @NOAUT;
						UPDATE #FTRD1 SET VLR_COPAGOS = @VRCOPA;
					end
					else
					if @PROC= 'CE' and @NODESCUENTACOPAGO=0 
					begin
						SELECT @VRCOPA = coalesce(VALORCOPAGO,0) FROM dbo.AUT with (nolock) WHERE NOAUT = @NOAUT
						if @VRCOPA>0
						begin
							UPDATE #FTRD1 SET VLR_COPAGOS = (VLR_SERVICI*@VRCOPA)/@VRSERV;
							if (select sum(VLR_COPAGOS) from #FTRD1)<>@VRCOPA
							begin
								-- Ajuste del copago por +/- decimales, se aplica al último item
								with 
									x as (select top 1 N_CUOTA from #FTRD1 order by N_CUOTA desc),
									t as (select TotalError=sum(VLR_COPAGOS) from #FTRD1)
								update #FTRD1 set VLR_COPAGOS = VLR_COPAGOS + (@VRCOPA - t.TotalError)
								from #FTRD1 a join x on a.N_CUOTA=x.N_CUOTA
									cross apply t
							end
						end						
					end
					
					UPDATE #FTRD1 SET VR_TOTAL = VLR_SERVICI - VLR_COPAGOS - VLR_PAGCOMP - VALORMODERADORA - DESCUENTO

					-- @VRABONO No se está tomando de ninguna tabla o proceso
					set @VRABONO=coalesce(@VRABONO,0);     

					SELECT @VRTOTAL = SUM(VR_TOTAL), @VRSERV = SUM(VLR_SERVICI), @VRCOPA = SUM(VLR_COPAGOS), @VRPACO = SUM(VLR_PAGCOMP), 
						@VRMODERA = sum(VALORMODERADORA)
					FROM #FTRD1
               
					IF @VRTOTAL < 0
						SET @VRTOTAL = 0

					INSERT INTO FTR(IDTRANSACCION,CONCEPTO,NUMDOCUMENTO,FECHADOCUMENTO,CNSFCT, COMPANIA, 
						CLASE, IDTERCERO, N_FACTURA, F_FACTURA, F_VENCE,
						VR_TOTAL, COBRADOR, VENDEDOR, MONEDA, OCOMPRA, ESTADO, F_CANCELADO,
						IDAFILIADO, EMPLEADO, NOREFERENCIA, PROCEDENCIA, TIPOFAC, OBSERVACION,
						TIPOVENTA, VALORCOPAGO, DESCUENTO, VALORPCOMP, VALORMODERADORA, CREDITO, INDCARTERA,
						INDCXC, MARCACONT, CONTABILIZADA, NROCOMPROBANTE, MARCA, INDASIGCXC,
						IMPRESO, VALORSERVICIOS, CLASEANULACION, CNSLOG, USUARIOFACTURA, FECHAFAC,
						MIVA, PIVA, VR_ABONOS, IDPLAN, FECHAPASOCXC, TIPOFIN, CNSFMAS, IDAREA_ALTA,
						CCOSTO_ALTA, IDDEP, TIPOTTEC, CUENTACXC, PROCESO, VALOR_TRM, 
						RAZONSOCIAL, TIPOCONTRATO, NUMCONTRATO, TIPOSISTEMA, KCNTID,
						FCNSID, EFACTURA, PREFIJOFTR, PORENVIAR, ERROR, ERRORMSG, IMPUTABLE, FCNSCNS, IDSEDE, IDT)
					SELECT @FTR_IDTRANSACCION,@FTR_CONCEPTO,@CNSFTR,DBO.FNK_FECHA_SIN_MLS(GETDATE()),@CNSFTR,
						@COMPANIA, 'C', @IDTERCEROF, @N_FACTURA, dbo.FNK_FECHA_SIN_HORA(GETDATE()), 
						dbo.FNK_FECHA_SIN_HORA(GETDATE()+@DV), VR_TOTAL = @VRTOTAL, NULL, NULL, LEFT(@DATO,2), NULL, 'P', NULL, 
						@IDAFILIADO, @USUARIO, @NOAUT, @PROC, 'I', '', @TV, VALORCOPAGO = @VRCOPA, DESCUENTO = @VRDTO,  
						VALORPCOMP = @VRPACO, VALORMODERADORA=@VRMODERA, 0, 0, 0, 0, 0, NULL, 0, 0, 0, VALORSERVICIOS = @VRSERV, 
						NULL, NULL, @USUARIO, GETDATE(), 0, 0, VR_ABONOS = @VRABONO, 
						@IDPLAN, NULL, 'C', NULL, @IDAREA, @CCOSTO, @DATO3, @TTEC, @CUENTACXC, @Proceso, VALOR_TRM=1, 
						@RAZONSOCIAL, @TIPOCONTRATO, @NUMCONTRATO, @TIPOSISTEMA, @KCNTID,
						@FCNSID, @EFACTURA, @PREFIJOFTR, PORENVIAR=0, ERROR=0, ERRORMSG='', IMPUTABLE=0, @FCNSCNS, @IDSEDE, @IDT;  
						
					INSERT INTO FTRD(IDTRANSACCION, NUMDOCUMENTO, CNSFTR, N_CUOTA, FECHA, DB_CR, AREAPRESTACION, UBICACION, VR_TOTAL,
						IMPUTACION, CCOSTO, PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD,
						VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, VALORMODERADORA, DESCUENTO, IDPROVEEDOR, NOADMISION,
						NOPRESTACION, NOITEM, AREAFUNCONT, N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST, PROCESO, NOAUTORIZACION)
					SELECT @FTR_IDTRANSACCION, @CNSFTR, @CNSFTR, N_CUOTA, FECHA, DB_CR, AREAPRESTACION, UBICACION, VR_TOTAL,
						IMPUTACION, CCOSTO, PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD,
						VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, VALORMODERADORA, DESCUENTO, IDPROVEEDOR, NOADMISION,
						NOPRESTACION, NOITEM, AREAFUNCONT, @N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST, @Proceso, NOAUTORIZACION  
					From #FTRD1;
                                                            
					If @EC<>1
                        Exec dbo.SPK_FAC_IMPDEDUC @NIT, @CNSFTR, @N_FACTURA, @VRSERV;
                    
					If @PROC='CE'
                    Begin
                        If @CETIPOHOSP='CEHOSP'
                        Begin
                            Update dbo.AUTD
                            Set N_FACTURA=@N_FACTURA, FACTURADA=1, CNSFCT=@CNSFTR
                            From dbo.AUTD With (NoLock)
                                 Inner Join dbo.AUT With (NoLock) On AUTD.IDAUT=AUT.IDAUT
                                 Inner Join dbo.SER With (NoLock) On SER.IDSERVICIO=AUTD.IDSERVICIO
                                 Left Join dbo.TER With (NoLock) On TER.IDTERCERO=AUTD.IDTERCEROCA
                            Where AUT.IDAUT=@IDAUT And SER.PREFIJO<>@PRE1 And SER.PREFIJO<>@PRE2 And SER.PREFIJO<>@PRE3 And SER.PREFIJO<>@PRE4 And 
								SER.PREFIJO<>@PRE5 And (AUTD.FACTURADA=0 Or AUTD.FACTURADA Is Null Or AUTD.FACTURADA=2) And                                                                                                                                                           
                                                                                    
								(TER.IDTERCERO=@IDTERCEROCA Or (TER.IDTERCERO Is Null And @IDTERCEROF=@IDTERCEROCA)) And AUTD.IDPLAN=@IDPLANPAR;
                        End;
                        Else
                        Begin
                            Update dbo.AUTD
                            Set N_FACTURA=@N_FACTURA, FACTURADA=1, CNSFCT=@CNSFTR
                            From dbo.AUTD With (NoLock) 
                                 Inner Join dbo.AUT With (NoLock) On AUTD.IDAUT=AUT.IDAUT
                                 Inner Join dbo.SER With (NoLock) On SER.IDSERVICIO=AUTD.IDSERVICIO
                                 Left Join dbo.TER With (NoLock) On TER.IDTERCERO=AUTD.IDTERCEROCA
                            Where AUT.IDAUT=@IDAUT And SER.PREFIJO<>@PRE1 And SER.PREFIJO<>@PRE2 And SER.PREFIJO<>@PRE3 And SER.PREFIJO<>@PRE4 And 
								SER.PREFIJO<>@PRE5 And (AUTD.FACTURADA=0 Or AUTD.FACTURADA Is Null Or AUTD.FACTURADA=2) And
								(TER.IDTERCERO=@IDTERCEROCA Or (TER.IDTERCERO Is Null And @IDTERCEROF=@IDTERCEROCA));
                        End;

						insert into FTROFR (CNSFTR,N_FACTURA,VALORTOTAL)
						select distinct CNSFTR=@CNSFTR, a.N_FACTURA, a.VR_TOTAL
						from AUT d 
							join FTR a with(nolock) on a.NOREFERENCIA=d.IDAUT and a.TIPOFAC in ('7','8','9') and a.ORIGENINGASIS='CE' and a.GENERADA=1 and a.ESTADO='P'  
								and not exists (select N_FACTURA from FTROFR o with(nolock) where o.N_FACTURA=a.N_FACTURA)
						Where d.IDAUT=@IDAUT;
                    End
                    Else
                    Begin
                        Update dbo.CIT
                        Set CIT.FACTURADA=1, CIT.N_FACTURA=@N_FACTURA, CIT.CNSFCT=@CNSFTR, CIT.VFACTURAS=0, CIT.MARCAFAC=0
                        Where CONSECUTIVO=@NOAUT;

						insert into FTROFR (CNSFTR,N_FACTURA,VALORTOTAL)
						select distinct CNSFTR=@CNSFTR, a.N_FACTURA, a.VR_TOTAL
						from CIT d 
							join FTR a with(nolock) on a.NOREFERENCIA=d.CONSECUTIVO and a.TIPOFAC in ('7','8','9') and a.ORIGENINGASIS='CIT' and a.GENERADA=1 and a.ESTADO='P'  
								and not exists (select N_FACTURA from FTROFR o with(nolock) where o.N_FACTURA=a.N_FACTURA)
						Where d.CONSECUTIVO=@NOAUT;
                    End; 

                    If @SOAT=1
                    Begin
                        If @PROC='CE'
                        Begin
                            Update dbo.HACTRAND
                            Set N_FCT_ASEG=@N_FACTURA
                            Where PROCEDENCIA='CE' And CNSHACTRAN=@CNSHACTRAN And NOREFERENCIA=@NOAUT;
                        End;
                        Else
                        Begin
                            Update dbo.HACTRAND
                            Set N_FCT_ASEG=@N_FACTURA
                            Where PROCEDENCIA='CI' And CNSHACTRAN=@CNSHACTRAN And NOREFERENCIA=@NOAUT;
                        End;
                    End;
                 
					If @PROC='CE'
                    Begin
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
								where IDAUT=@IDAUT 
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

                    End;
                End;
                Else
                Begin
                    -- Error en Generacion de N_FACTURA
                    Set @MSJERROR_FCNS=Coalesce(@MSJERROR_FCNS, 'Error en Generacion de N_FACTURA, la función no devolvió registros.');
                    Raiserror(@MSJERROR_FCNS, 16, 1);
                End;
            End;
            Else
            Begin
                -- Error en Generacion de N_FACTURA
                Set @MSJERROR_FCNS='No existen servicios con valores mayor que cero para Facturar.';
                Raiserror(@MSJERROR_FCNS, 16, 1);
            End;

            Drop Table #FTRD1;

			If @PROC='CE'
				Insert into @FTR_Result (TipoDoc,Documento,N_Factura,Error,Msg_Error) values (@PROC,@IDAUT,@N_FACTURA,0,'Generada.');
			Else
				Insert into @FTR_Result (TipoDoc,Documento,N_Factura,Error,Msg_Error) values (@PROC,@NOAUT,@N_FACTURA,0,'Generada.');

            Fetch Next From CUR_FTR
            Into @IDTERCEROCA, @CA;
        End;
        Deallocate CUR_FTR;
        Drop Table #TTER;

		-- Guarda resultados de la facturación
		insert into FTR_Log (IDT,Fecha,TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber,ErrorSeverity,ErrorState,Origen,Usuario,PC)
		select @IDT,getdate(),TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber=null,ErrorSeverity=null,ErrorState=null,Origen=@Proceso,Usuario=@USUARIO,PC=@SYS_COMPUTERNAME 
		from @FTR_Result;
        
		If (@@TRANCOUNT>0) 
			Commit;

    End Try
    Begin Catch
        If Cursor_Status('global', 'CUR_FTR')>=-1
        Begin
            Deallocate CUR_FTR;
        End;
		Select @ErrorMessage=N'Error al ejecutar '+@Proceso+':'+Char(13)+Char(10)+Coalesce(Error_Message(), '(desconocido)'), @ErrorSeverity=Error_Severity(), @ErrorState=Error_State();

        If @@TRANCOUNT>0 
            Rollback Transaction;		

		-- Guarda resultados del error de facturación
		insert into FTR_Log (IDT,Fecha,TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber,ErrorSeverity,ErrorState,Origen,Usuario,PC)
		select @IDT,getdate(),@PROC,@NOAUT,'',Error=1,Msg_Error=Error_Message(),Error_Number(),Error_Severity(),Error_State(),Origen=@Proceso,Usuario=@USUARIO,PC=@SYS_COMPUTERNAME 
		
        -- Raiserror(@ErrorMessage, @ErrorSeverity, @ErrorState);
    End Catch;
End;
go