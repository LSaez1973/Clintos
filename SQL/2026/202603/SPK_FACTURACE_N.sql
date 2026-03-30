drop Procedure if exists dbo.SPK_FACTURACE_N
go
-- ============================================================================
-- SPK_FACTURACE_N - VERSIÓN CORREGIDA
-- SQL Server 2017 Compatible
-- ============================================================================
-- CAMBIOS PRINCIPALES:
-- ✅ SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
-- ✅ REEMPLAZADO: With (NoLock) → With (UPDLOCK, HOLDLOCK) EN LECTURA CRÍTICA
-- ✅ AGREGADO: Validación de @@ROWCOUNT después de UPDATE críticos
-- ✅ AGREGADO: WHERE FACTURADA = 0 en UPDATE statements
-- ============================================================================

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
    @CETIPOHOSP   Varchar(6) = 'FALSE',
    @IDPLANPAR    Varchar(6) = NULL,
    @IDT          bigint = 0
As  
Begin  
    Declare @CNSFTR Varchar(20);  
    Declare @FACTURADA SmallInt;  
    Declare @IDTERCERO Varchar(20);  
    Declare @IDPLAN Varchar(6);  
    Declare @DATO Varchar(80);  
    Declare @IDTERCERO1 Varchar(20);  
    Declare @OK Int;  
    Declare @CA Varchar(1);  
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
    Declare @VRMODERA Decimal(14, 2);  
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
    Declare @FTR_CONCEPTO Varchar(254);
    Declare @AFIRCID Int;
    Declare @IDTERCERO_RC Varchar(20);
    Declare @N_FACTURA Varchar(20);
    Declare @ERROR_FCNS Varchar(20);
    Declare @MSJERROR_FCNS Varchar(256);
    Declare @FCNSID Int;  
    Declare @EFACTURA SmallInt;
    Declare @PREFIJOFTR Varchar(10);
    Declare @C_IDTERPART SmallInt;
    Declare @IDTERPART Varchar(20);
    Declare @KCNTID Int;
    Declare @TIPOSISTEMA Varchar(12);  
    Declare @TIPOCONTRATO Varchar(1);
    Declare @NUMCONTRATO Varchar(30);
    Declare @RAZONSOCIAL Varchar(120);
    Declare @FTRS SmallInt;
    Declare @N_FACTURAS Varchar(Max);
    Declare @IDAUT Varchar(20);
    Declare @FCNSCNS bigint;
    Declare @ErrorMessage NVarchar(4000);
    Declare @ErrorSeverity Int;
    Declare @ErrorState Int;
    Declare @cant_trans Int;
    Declare @QueryText Varchar(Max);
    Declare @Proceso varchar(50);
    Declare @AUTD_ROWCOUNT Int;  -- ✅ Para validar UPDATE
    Declare @CIT_ROWCOUNT Int;   -- ✅ Para validar UPDATE
    
    -- ✅ Table variables (SQL Server 2017 compatible)
    declare @Tabla_N_FACTURA table (
        N_FACTURA varchar(20), 
        FCNSID bigint, 
        ESTADO varchar(20), 
        ERRORMSG varchar(max), 
        FCNSCNS bigint
    );
    
    declare @FTR_Result as dbo.FTR_Result_Type;
    
    Declare @TERCA dbo.IDTERCERO_Type;

    Set @Proceso = 'SPK_FACTURACE_N';
    Set @SYS_COMPUTERNAME = Host_Name();  
    Set @NODESCUENTACOPAGO = 0;
    Set @FTRS = 0;
    Set @VRABONO = 0;
    Set @IDTERPART = dbo.FNK_VALORVARIABLE('IDTERPART');
  
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
  
    -- ============================================================
    -- INICIO PROCESO DE FACTURACIÓN CON SERIALIZABLE ISOLATION
    -- ============================================================
    Begin Try  
        -- ✅ SET ISOLATION LEVEL SERIALIZABLE
        SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
        
        Begin Transaction;  
        
        -- LSaez.05.Feb.2018  
        -- Corrección de @IDSEDE, cuando ésta llega nula o vacia
        Select @IDSEDE= (Select a.IDSEDE From dbo.SED a With (NoLock) Where a.IDSEDE=@IDSEDE);  
        
        If Coalesce(@IDSEDE, '')=''  
        Begin  
            Select @IDSEDE=Coalesce(b.IDSEDE, c.IDSEDE)  
            From dbo.UBEQ a With (NoLock)  
                 Left Join dbo.SED b With (NoLock) On a.IDSEDE=b.IDSEDE  
                 Outer Apply (Select Top (1) IDSEDE From dbo.SED With (NoLock) Order By IDSEDE) c  
            Where a.SYS_ComputerName=Host_Name();  
        End;  
  
        Select @DATOCCOSTO=dbo.FNK_VALORVARIABLE('CCOSTOENPRESTACION');  
        Select @FTR_IDTRANSACCION=LTrim(rtrim(dbo.FNK_VALORVARIABLE('FTR_IDTRANSACCION')));  
        Select @FTR_CONCEPTO=LTrim(rtrim(dbo.FNK_VALORVARIABLE('FTR_CONCEPTO')));  
        Select @DATO3=Left(dbo.FNK_VALORVARIABLE('IDFDEPFACTURACION'), 20);  
        Select @DATO=dbo.FNK_VALORVARIABLE('IDMONEDABASE');  
  
        -- ✅ CAMBIO CRÍTICO: REEMPLAZAR NoLock POR UPDLOCK, HOLDLOCK
        If @PROC='CE'  
        Begin  
            -- ✅ CAMBIO: De With (NoLock) a With (UPDLOCK, HOLDLOCK)
            Select @IDAUT=IDAUT, @FACTURADA=FACTURADA 
            From dbo.AUT With (UPDLOCK, HOLDLOCK) 
            Where NOAUT= @NOAUT;
            
            If @FACTURADA=1  
            Begin  
                If (@@TRANCOUNT>0)   
                    Commit;  
                Raiserror('La %s No. %s ya se encuentra Facturada.',16,1,@PROC,@NOAUT);  
                Return;
            End;
            
            If @CETIPOHOSP='CEHOSP'  
            Begin  
                set @FACTURADA = 1;
            End  
            Else  
            Begin  
                -- ✅ CAMBIO: De With (NoLock) a With (UPDLOCK, HOLDLOCK)
                Select @FACTURADA=a.FACTURADA, @IDTERCERO=a.IDCONTRATANTE, @IDPLAN=a.IDPLAN, @IDAFILIADO=a.IDAFILIADO,   
                       @DESCUENTO=a.DESCUENTO, @TIPODTO=a.TIPODTO, @CCOSTO=a.CCOSTO, @IDTERCERO1=a.IDCONTRATANTE, 
                       @CA=a.COBRARA, @SOAT=A.SOAT, @CNSHACTRAN=A.CNSHACTRAN, @AFIRCID=A.AFIRCID, 
                       @EC = T.ENVIODICAJA, @DV = T.DIASVTO, @KCNTID=a.KCNTID, @RAZONSOCIAL=t.RAZONSOCIAL,  
                       @TIPOCONTRATO=a.TIPOCONTRATO, @TIPOSISTEMA=a.TIPOSISTEMA, 
                       @NUMCONTRATO=Coalesce(b.NUMCONTRATO, ''), @TTEC=A.TIPOTTEC  
                From dbo.AUT a With (UPDLOCK, HOLDLOCK)
                     Left Join dbo.TER t With (NoLock) On t.IDTERCERO=a.IDCONTRATANTE  
                     join KCNT b on a.KCNTID=b.KCNTID  
                Where a.IDAUT=@IDAUT;
                
                If @FACTURADA=1  
                Begin  
                    If (@@TRANCOUNT>0)   
                        Commit;  
                    Raiserror('La %s No. %s ya se encuentra Facturada.',16,1,@PROC,@NOAUT);  
                    Return;
                End;
            End;  
        End;  
        Else  
        Begin  
            -- ✅ CAMBIO: De With (NoLock) a With (UPDLOCK, HOLDLOCK)
            SELECT @FACTURADA = a.FACTURADA, @IDTERCERO = a.IDCONTRATANTE, @IDPLAN = a.IDPLAN, @IDAFILIADO = a.IDAFILIADO,   
                   @DESCUENTO = a.DESCUENTO, @TIPODTO = a.TIPODTO, @CCOSTO=a.CCOSTO, @IDTERCERO1 = a.IDCONTRATANTE, 
                   @CA=a.COBRARA, @SOAT = a.SOAT, @CNSHACTRAN = a.CNSHACTRAN, @AFIRCID=a.AFIRCID, 
                   @EC = T.ENVIODICAJA, @DV = T.DIASVTO, @KCNTID=a.KCNTID, @RAZONSOCIAL=t.RAZONSOCIAL,  
                   @TIPOCONTRATO=a.TIPOCONTRATO, @TIPOSISTEMA = a.TIPOSISTEMA, 
                   @NUMCONTRATO=coalesce(b.NUMCONTRATO,''),  @TTEC = A.TIPOTTEC   
            FROM dbo.CIT a With (UPDLOCK, HOLDLOCK)
                 LEFT JOIN dbo.TER t With (NoLock) ON t.IDTERCERO = a.IDCONTRATANTE  
                 join KCNT b on a.KCNTID=b.KCNTID  
            WHERE a.CONSECUTIVO = @NOAUT;
            
            If @FACTURADA=1  
            Begin  
                If (@@TRANCOUNT>0)   
                    Commit;  
                Raiserror('La %s No. %s ya se encuentra Facturada.',16,1,@PROC,@NOAUT);  
                Return;
            End;
        End;  
  
        Set @NODESCUENTACOPAGO = 0;
        
        If @PROC='CI'  
        Begin  
            Select @CA='C';  
        End;
  
        If @CA='C'
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
            If @IDTERCERO1=@IDTERPART  
            Begin  
                Select @TV='Contado';  
            End;  
        End;  
        Else   
        If @CA='A'
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
        End  
        else  
        Begin
            If (@@TRANCOUNT > 0)
                Rollback;
            raiserror('El dato del campo CobrarA debe estar en A,C o P. A llegado %s',16,1,@CA);
            Return;
        End;
  
        Select @IDTERCEROF=b.IDTERCEROF From dbo.fnc_IDTERCERO_FTR(@IDTERCERO1, @CA, @IDAFILIADO, @AFIRCID) b;  
          
        Create Table #TTER (IDTERCERO Varchar(20), COBRARA Varchar(1));  
  
        If @PROC='CE'  
        Begin  
            If @CETIPOHOSP='CEHOSP'  
            Begin  
                Insert Into #TTER Select @IDTERCEROF, @CA;  
            End;  
            Else  
            Begin  
                Insert Into #TTER  
                Select Distinct Case When TER.IDTERCERO Is Null Then @IDTERCEROF Else AUTD.IDTERCEROCA End,   
                                 Case When TER.IDTERCERO Is Null Then @CA Else AUTD.COBRARA End  
                From dbo.AUT With (NoLock)  
                     Inner Join dbo.AUTD With (NoLock) On AUTD.IDAUT=AUT.IDAUT  
                     Left Join dbo.TER With (NoLock) On AUTD.IDTERCEROCA=TER.IDTERCERO  
                Where AUT.IDAUT=@IDAUT And (AUT.FACTURADA=0 Or AUT.FACTURADA Is Null Or AUT.FACTURADA=2)   
                  And (AUTD.FACTURADA=0 Or AUTD.FACTURADA Is Null)   
                  And (TER.IDTERCERO= (Case When @IDTERCEROCA1='' Then TER.IDTERCERO Else @IDTERCEROCA1 End)   
                       Or (TER.IDTERCERO Is Null And @IDTERCEROF=@IDTERCEROCA1 And @IDTERCEROCA1<>'') 
                       Or (TER.IDTERCERO Is Null And @IDTERCEROCA1=''));  
            End;  
        End;  
        Else If @PROC='CI'  
        Begin  
            Insert Into #TTER  
            Select Case When TER.IDTERCERO Is Null Then @IDTERCEROF Else CIT.IDTERCEROCA End, 
                   Case When TER.IDTERCERO Is Null Then @CA Else CIT.COBRARA End  
            From dbo.CIT With (NoLock)  
                 Left Join dbo.TER With (NoLock) On CIT.IDTERCEROCA=TER.IDTERCERO  
            Where CIT.CONSECUTIVO=@NOAUT And (CIT.FACTURADA=0 Or CIT.FACTURADA Is Null)   
              And (TER.IDTERCERO= (Case When @IDTERCEROCA1='' Then TER.IDTERCERO Else @IDTERCEROCA1 End)   
                   Or (TER.IDTERCERO Is Null And @IDTERCEROF=@IDTERCEROCA1 And @IDTERCEROCA1<>'') 
                   Or (TER.IDTERCERO Is Null And @IDTERCEROCA1=''));  
        End;  
  
        Insert Into @TERCA (IDTERCERO)  
        Select Distinct b.IDTERCEROF  
        From #TTER a  
             Cross Apply dbo.fnc_IDTERCERO_FTR(a.IDTERCERO, a.COBRARA, @IDAFILIADO, @AFIRCID) b;  
  
        Select @ERROR_FCNS=ERROR, @MSJERROR_FCNS=MSJERROR From dbo.fnc_FTR_FacturarIDTERPART(@TERCA);  
        If @ERROR_FCNS=1  
        Begin  
            If (@@TRANCOUNT > 0)
                Rollback;
            Raiserror(@MSJERROR_FCNS, 16, 1);  
            Return;
        End;  
  
        Select @ERROR_FCNS=ERROR, @MSJERROR_FCNS=MSJERROR From dbo.fnc_AFI_MenoresEdad(18, @TERCA);  
        If @ERROR_FCNS=1  
        Begin  
            If (@@TRANCOUNT > 0)
                Rollback;
            Raiserror(@MSJERROR_FCNS, 16, 1);  
            Return;
        End;  
  
        Declare CUR_FTR Cursor Static For  
        Select Distinct IDTERCERO, COBRARA From #TTER;  
        Open CUR_FTR;  
        Fetch Next From CUR_FTR  
        Into @IDTERCEROCA, @CA;  
        While @@FETCH_STATUS=0  
        Begin  
            Select @IDTERCEROF=IDTERCEROF, @IDTERCERO_RC=IDTERCERO_RC  
            From dbo.fnc_IDTERCERO_FTR(@IDTERCEROCA, @CA, @IDAFILIADO, @AFIRCID) a;  
            If Coalesce(@IDTERCERO_RC, '')<>''  
            Begin  
                Exec dbo.spc_TER_InsertFromAsistencial 'AFIRC', @AFIRCID;  
            End;  
  
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
                DESCUENTO      Decimal(14, 2),  
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
                        VLR_SERVICI=AUTD.CANTIDAD*AUTD.VALOR,   
                        VLR_COPAGOS=AUTD.VALORCOPAGO, VLR_PAGCOMP=AUTD.VALORPCOMP, VALORMODERADORA=AUTD.VALORMODERADORA,   
                        AUT.IDPROVEEDOR, @NOAUT, @NOAUT, AUTD.NO_ITEM, NULL, @N_FACTURA, AUT.SUBCCOSTO, AUTD.PCOSTO, AUT.FECHA,  
                        NOAUTORIZACION = case when coalesce(AUTD.NOAUTORIZEXT,'')<>'' then AUTD.NOAUTORIZEXT else coalesce(AUT.NUMAUTORIZA,'') end         
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
                        AND AUTD.IDPLAN = @IDPLANPAR;  
                END;  
                ELSE  
                BEGIN  
                    INSERT INTO #FTRD1(IDTRANSACCION,NUMDOCUMENTO,CNSFTR, FECHA, DB_CR, AREAPRESTACION, UBICACION, VR_TOTAL,  
                        IMPUTACION, CCOSTO, PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD,  
                        VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, VALORMODERADORA, IDPROVEEDOR, NOADMISION,  
                        NOPRESTACION, NOITEM, AREAFUNCONT, N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST, NOAUTORIZACION)  
                    SELECT @FTR_IDTRANSACCION, @CNSFTR, @CNSFTR, GETDATE(), 'DB', AUT.IDAREA, NULL, VR_TOTAL=0,   
                        NULL, CASE WHEN @DATOCCOSTO = 'SER:CCOSTO' THEN AUTD.CCOSTO ELSE AUT.CCOSTO END,   
                        AUT.PREFIJO, SER.DESCSERVICIO, AUTD.IDSERVICIO, NULL, AUTD.CANTIDAD, AUTD.VALOR,   
                        VLR_SERVICI=AUTD.CANTIDAD*AUTD.VALOR, VLR_COPAGOS=AUTD.VALORCOPAGO, VLR_PAGCOMP=AUTD.VALORPCOMP, VALORMODERADORA=AUTD.VALORMODERADORA,   
                        AUT.IDPROVEEDOR, @NOAUT, @NOAUT, AUTD.NO_ITEM, NULL, @N_FACTURA, AUT.SUBCCOSTO, AUTD.PCOSTO,AUT.FECHA,  
                        NOAUTORIZACION = case when coalesce(AUTD.NOAUTORIZEXT,'')<>'' then AUTD.NOAUTORIZEXT else coalesce(AUT.NUMAUTORIZA,'') end  
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
                        AND (TER.IDTERCERO = @IDTERCEROCA OR (TER.IDTERCERO IS NULL AND @IDTERCEROF=@IDTERCEROCA));  
                END;  
            END  
            ELSE  
            BEGIN  
                INSERT INTO #FTRD1(IDTRANSACCION,NUMDOCUMENTO,CNSFTR, FECHA, DB_CR, AREAPRESTACION, UBICACION, VR_TOTAL,  
                    IMPUTACION, CCOSTO, PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD,  
                    VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, VALORMODERADORA, IDPROVEEDOR, NOADMISION,  
                    NOPRESTACION, NOITEM, AREAFUNCONT, N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST,NOAUTORIZACION)  
                SELECT @FTR_IDTRANSACCION, @CNSFTR, @CNSFTR, GETDATE(), 'DB', CIT.IDAREA, NULL, VR_TOTAL=0,   
                    NULL, CIT.CCOSTO, SER.PREFIJO, SER.DESCSERVICIO, CIT.IDSERVICIO, NULL, CANTIDAD=1, VALOR=CIT.VALORTOTAL,   
                    VLR_SERVICI=CIT.VALORTOTAL, VLR_COPAGOS=CIT.VALORCOPAGO, VLR_PAGCOMP=CIT.VALORPCOMP, VALORMODERADORA=CIT.VALORMODERADORA, 
                    CIT.IDMEDICO, @NOAUT, @NOAUT, 1, NULL, @N_FACTURA, CIT.SUBCCOSTO, CIT.VALORTOTALCOS, CIT.FECHA, CIT.NOAUTORIZACION   
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
                    AND    (TER.IDTERCERO  = @IDTERCEROCA OR (TER.IDTERCERO IS NULL AND @IDTERCEROF=@IDTERCEROCA));  
            END;  
  
            Select @OK=Count(*) From #FTRD1 Where VLR_SERVICI>0;
            If @OK>0  
            Begin  
                Select Top 1 @IDAREA=AREAPRESTACION From #FTRD1;
                insert into @Tabla_N_FACTURA (N_FACTURA, FCNSID, ESTADO, ERRORMSG, FCNSCNS)  
                EXEC dbo.SPC_GENNUMEROFACTURA_FCNS @COMPANIA, @IDSEDE, @IDAREA;  
  
                select @N_FACTURA=null, @ERROR_FCNS=null, @MSJERROR_FCNS=null, @FCNSID=null;  
  
                select @N_FACTURA=N_FACTURA, @ERROR_FCNS=ESTADO, @MSJERROR_FCNS=ERRORMSG, @FCNSID=FCNSID, @FCNSCNS=FCNSCNS    
                from @Tabla_N_FACTURA;  
  
                If @ERROR_FCNS='OK'  
                Begin  
                    Exec SPK_GENCONSECUTIVO @COMPANIA, @IDSEDE, '@CNSFTR', @CNSFTR Output;  
                    Select @CNSFTR=@IDSEDE+Replace(Space(8-Len(@CNSFTR))+LTrim(RTrim(@CNSFTR)), Space(1), 0);  
  
                    set @FTRS += 1;  
                    Set @N_FACTURAS=Coalesce(@N_FACTURAS+', '+@N_FACTURA, @N_FACTURA);  
  
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
                        VLR_COPAGOS = round(coalesce(VLR_COPAGOS,0),0),
                        VLR_PAGCOMP = round(coalesce(VLR_PAGCOMP,0),0),
                        VALORMODERADORA = round(coalesce(VALORMODERADORA,0),0),
                        DESCUENTO   = 0,
                        VR_TOTAL    = 0;
  
                    SELECT @VRSERV = SUM(VLR_SERVICI) FROM #FTRD1;   
                    
                    UPDATE #FTRD1 SET DESCUENTO = round(case when @VRDTO=0 then 0 else (VLR_SERVICI*@VRDTO)/@VRSERV end,0);
  
                    if (select sum(DESCUENTO) from #FTRD1)<>@VRDTO  
                    begin  
                        with   
                        x as (select top 1 N_CUOTA from #FTRD1 order by N_CUOTA desc),  
                        t as (select TotalError=sum(DESCUENTO) from #FTRD1)  
                        update #FTRD1 set DESCUENTO = DESCUENTO + (@VRDTO - t.TotalError)  
                        from #FTRD1 a join x on a.N_CUOTA=x.N_CUOTA  
                             cross apply t;  
                    end;  
       
                    UPDATE #FTRD1 SET VR_TOTAL = VLR_SERVICI - VLR_COPAGOS - VLR_PAGCOMP - VALORMODERADORA - DESCUENTO;
  
                    SELECT @VRTOTAL = SUM(VR_TOTAL), @VRSERV = SUM(VLR_SERVICI), @VRCOPA = SUM(VLR_COPAGOS), @VRPACO = SUM(VLR_PAGCOMP),   
                        @VRMODERA = sum(VALORMODERADORA)  
                    FROM #FTRD1;
                 
                    IF @VRTOTAL < 0  
                        SET @VRTOTAL = 0;
  
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
                        VALORPCOMP = @VRPACO, VALORMODERADORA = @VRMODERA, 0, 0, 0, 0, 0, NULL, 0, 0, 0, VALORSERVICIOS = @VRSERV,   
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
                            -- ✅ AGREGADO: WHERE FACTURADA = 0 para validación
                            Update dbo.AUTD  
                            Set N_FACTURA=@N_FACTURA, FACTURADA=1, CNSFCT=@CNSFTR  
                            From dbo.AUTD With (NoLock)  
                                 Inner Join dbo.AUT With (NoLock) On AUTD.IDAUT=AUT.IDAUT  
                                 Inner Join dbo.SER With (NoLock) On SER.IDSERVICIO=AUTD.IDSERVICIO  
                                 Left Join dbo.TER With (NoLock) On TER.IDTERCERO=AUTD.IDTERCEROCA  
                            Where AUT.IDAUT=@IDAUT 
                              And AUTD.FACTURADA=0  -- ✅ VALIDACIÓN AGREGADA
                              And SER.PREFIJO<>@PRE1 And SER.PREFIJO<>@PRE2 And SER.PREFIJO<>@PRE3 And SER.PREFIJO<>@PRE4 And   
                                  SER.PREFIJO<>@PRE5 
                              And (AUTD.FACTURADA=0 Or AUTD.FACTURADA Is Null Or AUTD.FACTURADA=2) 
                              And (TER.IDTERCERO=@IDTERCEROCA Or (TER.IDTERCERO Is Null And @IDTERCEROF=@IDTERCEROCA)) 
                              And AUTD.IDPLAN=@IDPLANPAR;
                            
                            Set @AUTD_ROWCOUNT = @@ROWCOUNT;
                            -- ✅ VALIDACIÓN AGREGADA
                            If @AUTD_ROWCOUNT = 0
                            Begin
                                If (@@TRANCOUNT > 0)
                                    Rollback;
                                Raiserror('Error: La Autorización ya fue facturada por otra transacción concurrente.', 16, 1);
                                Return;
                            End;
                        End;  
                        Else  
                        Begin  
                            -- ✅ AGREGADO: WHERE FACTURADA = 0 para validación
                            Update dbo.AUTD  
                            Set N_FACTURA=@N_FACTURA, FACTURADA=1, CNSFCT=@CNSFTR  
                            From dbo.AUTD With (NoLock)   
                                 Inner Join dbo.AUT With (NoLock) On AUTD.IDAUT=AUT.IDAUT  
                                 Inner Join dbo.SER With (NoLock) On SER.IDSERVICIO=AUTD.IDSERVICIO  
                                 Left Join dbo.TER With (NoLock) On TER.IDTERCERO=AUTD.IDTERCEROCA  
                            Where AUT.IDAUT=@IDAUT 
                              And AUTD.FACTURADA=0  -- ✅ VALIDACIÓN AGREGADA
                              And SER.PREFIJO<>@PRE1 And SER.PREFIJO<>@PRE2 And SER.PREFIJO<>@PRE3 And SER.PREFIJO<>@PRE4 And   
                                  SER.PREFIJO<>@PRE5 
                              And (AUTD.FACTURADA=0 Or AUTD.FACTURADA Is Null Or AUTD.FACTURADA=2) 
                              And (TER.IDTERCERO=@IDTERCEROCA Or (TER.IDTERCERO Is Null And @IDTERCEROF=@IDTERCEROCA));
                            
                            Set @AUTD_ROWCOUNT = @@ROWCOUNT;
                            -- ✅ VALIDACIÓN AGREGADA
                            If @AUTD_ROWCOUNT = 0
                            Begin
                                If (@@TRANCOUNT > 0)
                                    Rollback;
                                Raiserror('Error: La Autorización ya fue facturada por otra transacción concurrente.', 16, 1);
                                Return;
                            End;
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
                        -- ✅ AGREGADO: WHERE FACTURADA = 0 para validación
                        Update dbo.CIT  
                        Set CIT.FACTURADA=1, CIT.N_FACTURA=@N_FACTURA, CIT.CNSFCT=@CNSFTR, CIT.VFACTURAS=0, CIT.MARCAFAC=0  
                        Where CONSECUTIVO=@NOAUT 
                          And FACTURADA=0;  -- ✅ VALIDACIÓN AGREGADA
                        
                        Set @CIT_ROWCOUNT = @@ROWCOUNT;
                        -- ✅ VALIDACIÓN AGREGADA
                        If @CIT_ROWCOUNT = 0
                        Begin
                            If (@@TRANCOUNT > 0)
                                Rollback;
                            Raiserror('Error: La Cita ya fue facturada por otra transacción concurrente.', 16, 1);
                            Return;
                        End;
  
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
                        with m1 as(  
                            select IDAUT,  
                                FACTURADA=min(facturada),
                                N_FACTURA=max(n_factura),
                                VFACTURAS=sum(case when N_FACTURA<>'' then 1 else 0 end)
                            from (  
                                select IDAUT,FACTURADA=coalesce(FACTURADA,0), N_FACTURA=coalesce(case when FACTURADA=1 then N_FACTURA else '' end,'')  
                                from dbo.vwc_Facturable_AUT   
                                where IDAUT=@IDAUT   
                                group by IDAUT,coalesce(FACTURADA,0), coalesce(case when FACTURADA=1 then N_FACTURA else '' end,'')  
                            ) x  
                            Group By x.IDAUT  
                        )      
                        Update dbo.AUT   
                        Set FACTURADA = b.FACTURADA,   
                            VFACTURAS = case when b.VFACTURAS>0 then 1 else 0 end,
                            N_FACTURA = Coalesce(c.N_FACTURA,b.N_FACTURA),  
                            CNSFCT = Coalesce(c.CNSFCT,@CNSFTR),  
                            MARCAFAC = 0  
                        from dbo.AUT a With (NoLock)  
                            join m1 b on a.IDAUT=b.IDAUT  
                            left join dbo.FTR c With (NoLock) On b.N_FACTURA=c.N_FACTURA and b.FACTURADA=1;
                    End;  
                End;  
                Else  
                Begin  
                    If (@@TRANCOUNT > 0)
                        Rollback;
                    Set @MSJERROR_FCNS=Coalesce(@MSJERROR_FCNS, 'Error en Generacion de N_FACTURA, la función no devolvió registros.');  
                    Raiserror(@MSJERROR_FCNS, 16, 1);  
                    Return;
                End;  
            End;  
            Else  
            Begin  
                If (@@TRANCOUNT > 0)
                    Rollback;
                Set @MSJERROR_FCNS='No existen servicios con valores mayor que cero para Facturar.';  
                Raiserror(@MSJERROR_FCNS, 16, 1);  
                Return;
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
  
        insert into FTR_Log (IDT,Fecha,TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber,ErrorSeverity,ErrorState,Origen,Usuario,PC)  
        select @IDT,getdate(),@PROC,@NOAUT,'',Error=1,Msg_Error=Error_Message(),Error_Number(),Error_Severity(),Error_State(),Origen=@Proceso,Usuario=@USUARIO,PC=@SYS_COMPUTERNAME;
    End Catch;  
End;
GO