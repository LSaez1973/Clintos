drop Procedure [spc_KCNT_Facturar_HADM_CAP_1]
go
-- 26.nov.2024: Relacionar facturas de Copagos en FTROFR
CREATE Procedure [spc_KCNT_Facturar_HADM_CAP_1]
    @COMPANIA Varchar(2), 
	@KCNTFCID Int, 
	@USUARIO Varchar(12), 
	@IDSEDE varchar(5), 
	@IDT bigint=0 -- ID Transacción
As
Begin
	Declare @FTRD Table (
		CNSFTR varchar(40) NULL,
		N_CUOTA smallint NULL,
		FECHA datetime NULL,
		DB_CR varchar(2) NULL,
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
		PROCESO varchar(50) Null,
		NOAUTORIZACION varchar(20)
	);
	declare @Tabla_N_FACTURA table (N_FACTURA varchar(20) null, FCNSID bigint null, ESTADO varchar(20) null, ERRORMSG varchar(max) null, FCNSCNS bigint);
	Declare
		@CNSFTR Varchar(20),
		@IDTERCERO Varchar(20),
		@KCNTID Int,
		@idAdministrdoraAfi Varchar(20),
		@N_FACTURA Varchar(20),
		@N_FACTURA2 Varchar(20),
		@ESTADOFAC Varchar(12),
		@NUMCONTRATO Varchar(20),
		@ANO Int,
		@MES Int,
		@DESCSERVICIOS Varchar(1024),
		@NAFILIADOS Int,
		@CIUDAD Varchar(45),
		@NOADMISION Varchar(20)=RTrim(LTrim(Cast(@KCNTFCID As Varchar(20)))),
		@SYS_COMPUTERNAME Varchar(254) = Host_Name(),
		@IDMONEDABASE Varchar(3),
		@IDAREA_ALTA  VARCHAR(20),
		@ERROR_FCNS varchar(20), 
		@MSJERROR_FCNS varchar(256), 
		@FCNSID Int,
		@EFACTURA smallint, 
		@PREFIJOFTR varchar(10),
		@VRSERV        DECIMAL(14,2),
		@EC SmallInt,
		@IDDEP Varchar(20), 
		@TIPOCONT Varchar(1),
		@Modo Varchar(20),
		@FCNSCNS bigint, 
		@cinf varbinary(128),
		@ErrorMessage NVarchar(4000), @ErrorSeverity Int, @ErrorState Int, @cant_trans Int, @Proceso Varchar(50)='spc_KCNT_Facturar_HADM_CAP_1';
	--
	declare @FTR_Result as dbo.FTR_Result_Type;
	Declare @Totales Table (
		VLRFACTURA      Decimal(22, 2) null,
		VLR_SERVICI     Decimal(22, 2) null,
		VALORCOPAGO     Decimal(22, 2) null,
		VALORPCOMP      Decimal(22, 2) null,
		VALORMODERADORA Decimal(22, 2) null,
		VLRDESCUENTO    Decimal(22, 2) null,
		VLRTOTAL        Decimal(22, 2) null
	);

	declare @Datos table (NOADMISION varchar(20), ORIGENINGASIS varchar(20));

	if coalesce(@IDT,0)=0
		set @IDT = dbo.fnc_GenFechaNumerica(getdate());

	-- @IDSEDE: tener en cuenta que NO viene en parametros ni se optiene de tablas
    -- LSaez.05.Feb.2018
    -- Corrección de @IDSEDE, cuando ésta llega nula o vacia, estaba generando consecutivo de Factura sin sedes 
    -- 1. Verifica que IDSEDE que viene en el parámetro exista
    Select @IDSEDE = (Select Top (1) a.IDSEDE From dbo.SED a With (NoLock) Where a.IDSEDE=@IDSEDE Order By a.IDSEDE);
    -- 2. Sino existe la sede suministrada; toma la del Equipo Facturador o la primera sede de la tabla SED
    If Coalesce(@IDSEDE, '')=''
    Begin
        Select @IDSEDE=Coalesce(b.IDSEDE, c.IDSEDE)
        From dbo.UBEQ a With (NoLock)
                Left Join dbo.SED b With (NoLock) On a.IDSEDE=b.IDSEDE
                Outer Apply
            (Select Top (1) IDSEDE From dbo.SED With (NoLock) Order By IDSEDE) c
        Where a.SYS_ComputerName=@SYS_COMPUTERNAME;
    End;

	-- Areal de Alta (PC desde donde se factura)
	Select @IDAREA_ALTA=a.IDAREA From dbo.UBEQ a With (NoLock) Where a.SYS_ComputerName=@SYS_COMPUTERNAME;

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
        Exec dbo.SPC_ADD_SP_ERROR @Proceso, @ErrorMessage, @NOADMISION, @IDSEDE, @USUARIO, @SYS_COMPUTERNAME, null;
        Raiserror(@ErrorMessage, @ErrorSeverity, @ErrorState);
		return;
    End Catch;

    Begin Try
        Begin Transaction;

		Select @IDTERCERO=f.IDTERCERO, @KCNTID=a.KCNTID, @ESTADOFAC=Coalesce(b.ESTADO, ''), @N_FACTURA2=Coalesce(a.N_FACTURA, ''), 
			@N_FACTURA=Coalesce(b.N_FACTURA, ''), @NUMCONTRATO=Coalesce(f.NUMCONTRATO, '?'), @ANO=a.ANO, @MES=a.MES, 
			@NAFILIADOS=Coalesce(f.NAFILIADOS, 0), @CIUDAD=Coalesce(e.NOMBRE, 'CIUDAD?'),
			@CNSFTR=b.CNSFCT, @TIPOCONT=f.TIPOCONTRATO
		From dbo.KCNTFC a With (NoLock)
			 Left Join dbo.FTR b With (NoLock) On a.N_FACTURA=b.N_FACTURA
			 Join dbo.KCNT f With (NoLock) On a.KCNTID=f.KCNTID
			 Left Join dbo.TER d With (NoLock) On f.IDTERCERO=d.IDTERCERO
			 Left Join dbo.CIU e With (NoLock) On d.CIUDAD=e.CIUDAD
		Where a.KCNTFCID=@KCNTFCID;

		/*UPDATE KCNTFC SET ESTADO='*' where KCNTFCID=@KCNTFCID;*/
		If @N_FACTURA2<>'' And @N_FACTURA=''
		Begin
			Raiserror('La Factura No.%s NO existe en Facturas.', 16, 1, @N_FACTURA2); -- error()=90 en clarion  
		End;
		If @ESTADOFAC='A'
		Begin
			Raiserror('La Factura No.%s se encuentra Anulada y no puede ser utilizada para Facturar.', 16, 1, @N_FACTURA); -- error()=90 en clarion  
		End;
 
		If  (Select sum(VALOR*CANTIDAD) From dbo.KCNTFCD a With (nolock) Where KCNTFCID=@KCNTFCID) = 0
        Begin
            Raiserror('No se encontraron servicios por Facturar entre el periodo seleccionado.', 16, 1, @NUMCONTRATO); -- error()=90 en clarion  
        End;

		-- De aquí en adelante se supone que hay servicios que facturar
		
		-- Tomamos el dato IDADMINISTRADORA_AFI de la tabla KCNT
		select @idAdministrdoraAfi = kcnt.idadministradora_afi from kcnt where kcnt.kcntid=@KCNTID;

		Select 
			@IDDEP = dbo.FNK_VALORVARIABLE('IDFDEPFACTURACION'),
			@IDMONEDABASE = Left(dbo.FNK_VALORVARIABLE('IDMONEDABASE'),3);

        -- Calculo de Totales  
        With mem1 As (
            Select VLRFACTURA=Coalesce(a.VLRFACTURA,0), VLR_SERVICI=Sum(Coalesce(b.VLR_SERVICI,0)), VALORCOPAGO=Sum(Coalesce(b.VALORCOPAGO,0)), 
				VALORPCOMP=Sum(Coalesce(b.VALORPCOMP,0)), VALORMODERADORA=Sum(Coalesce(b.VALORMODERADORA,0)), VLRDESCUENTO=Coalesce(a.VLRDESCUENTO, 0), 
				VLRTOTAL=Coalesce(a.VLRFACTURA,0)-Sum(Coalesce(b.VALORCOPAGO,0)-Coalesce(b.VALORPCOMP,0)-Coalesce(b.VALORMODERADORA,0))-Coalesce(a.VLRDESCUENTO, 0)
            From dbo.KCNTFC a With (NoLock) 
                 Left Join dbo.vwc_Facturable b On b.KCNTID=a.KCNTID
					And b.IDTERCEROCA=@IDTERCERO And b.TIPOCONTRATO=@TIPOCONT 
					And (Coalesce(b.FACTURADA, 0)=0 Or (b.FACTURADA=1 And b.N_FACTURA=@N_FACTURA And @N_FACTURA<>'')) 
					And b.FECHAALTA Between a.FECHAINI And a.FECHAFIN
            Where a.KCNTFCID=@KCNTFCID 
            Group By Coalesce(a.VLRFACTURA,0), Coalesce(a.VLRDESCUENTO, 0)
        )
        Insert Into @Totales 
		Select * From mem1;

		Select @VRSERV = Sum(VLR_SERVICI) From @Totales;

		-- Detalles de la factura
        Insert Into @FTRD (CNSFTR, N_CUOTA, FECHA, DB_CR, AREAPRESTACION, AREAFUNCONT, UBICACION, VR_TOTAL, IMPUTACION, CCOSTO, PREFIJO, ANEXO, 
			REFERENCIA, IDCIRUGIA, CANTIDAD, VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, NOADMISION, NOPRESTACION, NOITEM, N_FACTURA, SUBCCOSTO, 
			PCOSTO, FECHAPREST, VLRNOTADB, VLRNOTACR, TIPO, IDIMPUESTO, IDCLASE, ITEM, VLRIMPUESTO, PIVA, VIVA, TIPOCONTRATOARS, ARSTIPOCONTRATO, 
			ANO, MES, NAFILIADOS, IDPLAN, IDTRANSACCION, NUMDOCUMENTO, VLR_PCOSTO, VALORMODERADORA, IDCUM, NOINVIMA, IDTARIFA, KNEGID, NUMCONTRATO, 
			TIPOCONTRATO, VLR_UPC, VLR_UPCNETA_M8P, VLRP_CAPITADO, KCNTRID, PROCESO, NOAUTORIZACION)
		Select CNSFTR=null, N_CUOTA=Row_Number() Over (Order By d.KCNTFCDID), FECHA=dbo.FNK_FECHA_SIN_MLS(GetDate()), DB_CR='DB', 
			AREAPRESTACION=@IDAREA_ALTA, AREAFUNCONT=@IDAREA_ALTA, UBICACION=Null, VR_TOTAL=d.CANTIDAD*d.VALOR, IMPUTACION=0, CCOSTO=s.CCOSTO, PREFIJO=s.PREFIJO, 
			ANEXO=concat(s.DESCSERVICIO,Case When Coalesce(d.ANEXO,'')='' Then '' else '-'+d.ANEXO end), 
			REFERENCIA=d.IDSERVICIO, IDCIRUGIA=Null, CANTIDAD=d.CANTIDAD, VALOR=d.VALOR, VLR_SERVICI=d.CANTIDAD*d.VALOR, VLR_COPAGOS=0, 
			VLR_PAGCOMP=0, NOADMISION=Null, NOPRESTACION=Null, NOITEM=Null, N_FACTURA=@N_FACTURA, SUBCCOSTO=Null, PCOSTO=0, FECHAPREST=Null, 
			VLRNOTADB=0, VLRNOTACR=0, TIPO=Null, IDIMPUESTO=Null, IDCLASE=Null, ITEM=Null, VLRIMPUESTO=0, PIVA=0, VIVA=0, TIPOCONTRATOARS=Null, 
			ARSTIPOCONTRATO=Null, ANO=@ANO, MES=@MES, NAFILIADOS=c.NAFILIADOS, IDPLAN=Null, IDTRANSACCION='FTR', NUMDOCUMENTO=null, VLR_PCOSTO=0, 
			VALORMODERADORA=0, IDCUM=Null, NOINVIMA=Null, IDTARIFA=Null, KNEGID=Null, NUMCONTRATO=@NUMCONTRATO, TIPOCONTRATO=@TIPOCONT, 
			VLR_UPC=c.VLR_UPC, VLR_UPCNETA_M8P=c.VLR_UPCNETA_M8P, VLRP_CAPITADO=c.VLRP_CAPITADO, KCNTRID=0, @Proceso, NOAUTORIZACION=''
        From dbo.KCNTFC a With (NoLock) 
			Join dbo.KCNT c With (NoLock) On a.KCNTID=c.KCNTID
			join dbo.KCNTFCD d With (NoLock) on a.KCNTFCID=d.KCNTFCID  
			join dbo.SER s With (NoLock) on s.IDSERVICIO=d.IDSERVICIO  
        Where a.KCNTFCID=@KCNTFCID 
			And d.CANTIDAD>0 -- Se supone que d.CANTIDAD=0 es informativo para la impresion de la factura, no debería ir a FTRD
			
        -- Calculo de Descripcion de Servicios  
        Select @DESCSERVICIOS=Coalesce(@DESCSERVICIOS+', '+LTrim(RTrim(DESCSERVICIO)), LTrim(RTrim(DESCSERVICIO)))
        From
            (Select Distinct DESCSERVICIO=Upper(d.DESCSERVICIO)
             From dbo.vwc_KNEG_MAES a With (NoLock)
                  Join dbo.KNEG b With (NoLock) On a.KNEGID=b.KNEGID
                  Join dbo.KCNTFC c With (NoLock) On b.KCNTID=c.KCNTID
                  Join dbo.MAES d With (NoLock) On a.IDSERVICIOADM=d.IDSERVICIOADM
             Where c.KCNTFCID=@KCNTFCID) a;
        Set @DESCSERVICIOS='POR CONCEPTO DE PRESTACION DE: '+Coalesce(@DESCSERVICIOS+'.', '')+' A LOS '+LTrim(Str(@NAFILIADOS))
			+' AFILIADOS DEL AREA DE INFLUENCIA DEL MUNICIPIO DE '+@CIUDAD;

        If @N_FACTURA=''
        Begin
            -- Nueva Factura  
			-- 21.dic.2018.LSaez: Generación de No.Factura controlado por la tabla FCNS, 
			-- Se agregaro el parámetros @IDAREA_ALTA a SPC_GENNUMEROFACTURA_FCNS, este SP no usa RPDX
			insert into @Tabla_N_FACTURA (N_FACTURA, FCNSID, ESTADO, ERRORMSG, FCNSCNS)
			EXEC dbo.SPC_GENNUMEROFACTURA_FCNS @COMPANIA, @IDSEDE, @IDAREA_ALTA

			select @N_FACTURA=null, @ERROR_FCNS=null, @MSJERROR_FCNS=null, @FCNSID=null;

			--select @N_FACTURA=N_FACTURA, @ERROR_FCNS=ESTADO, @MSJERROR_FCNS=ERRORMSG, @FCNSID=FCNSID 
			--from @Tabla_N_FACTURA

			select @N_FACTURA=a.N_FACTURA, @ERROR_FCNS=a.ESTADO, @MSJERROR_FCNS=a.ERRORMSG, @FCNSID=a.FCNSID, @FCNSCNS=a.FCNSCNS,
				@EFACTURA=b.EFACTURA, @PREFIJOFTR=b.PREFIJO
			from @Tabla_N_FACTURA a
				join dbo.FCNS b with(NoLock) on a.FCNSID=b.FCNSID

			-- PRINT ' N_FACTURA = '+ coalesce(@N_FACTURA,'null')

			if @ERROR_FCNS = 'OK'
			begin	      
				EXEC SPK_GENCONSECUTIVO @COMPANIA, @IDSEDE, '@CNSFTR',  @CNSFTR OUTPUT  
				SELECT @CNSFTR = @IDSEDE + REPLACE(SPACE(8 - LEN(@CNSFTR))+LTRIM(RTRIM(@CNSFTR)),SPACE(1),0)
   
				Select @EC = ENVIODICAJA FROM dbo.TER with(NoLock) Where IDTERCERO = @IDTERCERO;               	
  
				With mem1 As (
					Select CNSFCT=@CNSFTR, COMPANIA=@COMPANIA, CLASE='C', IDTERCERO=@IDTERCERO, N_FACTURA=@N_FACTURA, 
						F_FACTURA=dbo.FNK_FECHA_SIN_HORA(GetDate()), F_VENCE=dbo.FNK_FECHA_SIN_HORA(GetDate()+30), 
						VR_TOTAL=t.VLRTOTAL, COBRADOR=Null, VENDEDOR=Null, MONEDA=@IDMONEDABASE, VALOR_TRM=1, 
						OCOMPRA=Null, ESTADO='P', F_CANCELADO=Null, IDAFILIADO=Null, EMPLEADO=@USUARIO, NOREFERENCIA=Null, 
						PROCEDENCIA = 
							case when coalesce(a.FACTURA_UT,1)=1 then 
								case b.TIPOCONTRATO when 'C' then 'UT_CAPITA' when 'P' then 'UT_PGP' end
							else 'CAPITA' end, 
						TIPOFAC='I', OBSERVACION=@DESCSERVICIOS, TIPOVENTA='Credito', TIPOCOPAGO=Null, VALORCOPAGO=t.VALORCOPAGO, DESCUENTO=t.VLRDESCUENTO, 
						VALORPCOMP=t.VALORPCOMP, CREDITO=0, INDCARTERA=0, INDCXC=0, MARCA=0, INDASIGCXC=0, MARCACONT=0, CONTABILIZADA=0, 
						NROCOMPROBANTE=Null, IMPRESO=0, VALORSERVICIOS=t.VLRFACTURA, CLASEANULACION=Null, CNSLOG=Null, USUARIOFACTURA=@USUARIO, 
						FECHAFAC=dbo.FNK_FECHA_SIN_MLS(GetDate()), MIVA=0, PIVA=0, VIVA=0, VR_ABONOS=0, IDPLAN=Null, FECHAPASOCXC=Null, 
						TIPOFIN = case when coalesce(a.FACTURA_UT,1)=1 then 'U' else 'C' end, CNSFMAS=Null, IDAREA_ALTA=@IDAREA_ALTA, CCOSTO_ALTA=Null, 
						IDDEP=@IDDEP, VLRNOTADB=0, VLRNOTACR=0, TIPOTTEC=b.TIPOTTEC, RAZONANULACION=Null, CUENTACXC=Null, IDAREA_FTR=Null, CCOSTO_FTR=Null, 
						INDASIGENT=Null, PLANDEPAGO=Null, CUOTAS=Null, FECHA_PP=Null, PERIODODIAS=Null, BANCO=Null, TIPO_CUENTA=Null, CTA_BCO=Null, 
						TIPOANULACION=Null, CODUNG=Null, CODPRG=Null, CAPITADA=1, CP_CONVENIO=Null, CP_MODALIDAD=Null, CP_MES=a.MES, CP_VLR_SERVICIOS=t.VLR_SERVICI, 
						CP_VLR_COPAGOS=t.VALORCOPAGO, IDTRANSACCION='FTR', NUMDOCUMENTO=@CNSFTR, RAZONSOCIAL=b.RAZONSOCIAL, CONCEPTO='Factura De Venta', 
						CONTABILIZADO=0, FECHADOCUMENTO=Null, IDSEDE=@IDSEDE, VALORMODERADORA=t.VALORMODERADORA, TIPOCONTRATO=@TIPOCONT, 
						KCNTID=b.KCNTID ,KCNTRID=0, NOCONTRATO=Coalesce(b.NUMCONTRATO, ''), NUMCONTRATO=Coalesce(b.NUMCONTRATO, ''), c.TIPOSISTEMA, 
						FECHAINI=a.FECHAINI, FECHAFIN=a.FECHAFIN, FCNSCNS=@FCNSCNS, EFACTURA=@EFACTURA, PREFIJOFTR=@PREFIJOFTR, PORENVIAR=0, Error=0, ERRORMSG='', 
						IMPUTABLE=0, FCNSID=@FCNSID, PROCESO=@Proceso
					From dbo.KCNTFC a With (NoLock) 
							Join dbo.KCNT b With (NoLock) On a.KCNTID=b.KCNTID
							Left Join dbo.TTEC c With (NoLock) On b.TIPOTTEC=c.TIPO
							cross Apply @Totales t
					Where a.KCNTFCID=@KCNTFCID
				)
				Insert Into dbo.FTR (CNSFCT, COMPANIA, CLASE, IDTERCERO, N_FACTURA, F_FACTURA, F_VENCE, VR_TOTAL, COBRADOR, VENDEDOR, MONEDA, VALOR_TRM,
					OCOMPRA, ESTADO, F_CANCELADO, IDAFILIADO, EMPLEADO, NOREFERENCIA, PROCEDENCIA, TIPOFAC, OBSERVACION, TIPOVENTA, TIPOCOPAGO, VALORCOPAGO, 
					DESCUENTO, VALORPCOMP, CREDITO, INDCARTERA, INDCXC, MARCA, INDASIGCXC, MARCACONT, CONTABILIZADA, NROCOMPROBANTE, IMPRESO, 
					VALORSERVICIOS, CLASEANULACION, CNSLOG, USUARIOFACTURA, FECHAFAC, MIVA, PIVA, VIVA, VR_ABONOS, IDPLAN, FECHAPASOCXC, TIPOFIN, 
					CNSFMAS, IDAREA_ALTA, CCOSTO_ALTA, IDDEP, VLRNOTADB, VLRNOTACR, TIPOTTEC, RAZONANULACION, CUENTACXC, IDAREA_FTR, CCOSTO_FTR, 
					INDASIGENT, PLANDEPAGO, CUOTAS, FECHA_PP, PERIODODIAS, BANCO, TIPO_CUENTA, CTA_BCO, TIPOANULACION, CODUNG, CODPRG, CAPITADA, 
					CP_CONVENIO, CP_MODALIDAD, CP_MES, CP_VLR_SERVICIOS, CP_VLR_COPAGOS, IDTRANSACCION, NUMDOCUMENTO, RAZONSOCIAL, CONCEPTO, 
					CONTABILIZADO, FECHADOCUMENTO, IDSEDE, VALORMODERADORA, TIPOCONTRATO, KCNTID, KCNTRID, NOCONTRATO, NUMCONTRATO, TIPOSISTEMA, FECHAINI, 
					FECHAFIN, FCNSCNS, EFACTURA, PREFIJOFTR, PORENVIAR, ERROR, ERRORMSG, IMPUTABLE, FCNSID, PROCESO, IDT)
				Select *, @IDT From mem1;
				Set @Modo='Generada.';
				
				-- Actualizamos en campo IDADMINISTRADORA_AFI en la factura generada @N_FACTURA
				if @N_FACTURA <> ''
					update ftr set idadministradora_afi=@idAdministrdoraAfi where n_factura=@N_FACTURA;
			End
			else
			begin
				-- Error en Generacion de N_FACTURA
				set @MSJERROR_FCNS = coalesce(@MSJERROR_FCNS,'Error en Generacion de N_FACTURA, la función no devolvió registros.');
				raiserror(@MSJERROR_FCNS,16,1);
			end
        End;
        Else
        Begin
            -- Factura Existente, se actualizan los datos  
            Update dbo.FTR
            Set VR_TOTAL=t.VLRTOTAL, VALORCOPAGO=t.VALORCOPAGO, DESCUENTO=t.VLRDESCUENTO, VALORPCOMP=t.VALORPCOMP, 
				VALORSERVICIOS=t.VLRFACTURA, CP_MES=@MES, CP_VLR_SERVICIOS=t.VLR_SERVICI, CP_VLR_COPAGOS=t.VALORCOPAGO, VALORMODERADORA=t.VALORMODERADORA, 
				TIPOCONTRATO=@TIPOCONT, KCNTID=@KCNTID, NUMCONTRATO=@NUMCONTRATO, IDTERCERO=@IDTERCERO, OBSERVACION=@DESCSERVICIOS
            From @Totales t
            Where N_FACTURA=@N_FACTURA;

            Delete dbo.FTRD Where N_FACTURA=@N_FACTURA;
			Set @Modo='Actualizada.';
        End;

        -- Detalles de la Factura  

		set @cinf = convert(varbinary(128),'Skip_Trigger_FTRD:trFTRD_AUTOLOG');
		set context_info @cinf

        Insert Into dbo.FTRD (CNSFTR, N_CUOTA, FECHA, DB_CR, AREAPRESTACION, AREAFUNCONT, UBICACION, VR_TOTAL, IMPUTACION, CCOSTO, PREFIJO, ANEXO, 
			REFERENCIA, IDCIRUGIA, CANTIDAD, VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, NOADMISION, NOPRESTACION, NOITEM, N_FACTURA, SUBCCOSTO, 
			PCOSTO, FECHAPREST, VLRNOTADB, VLRNOTACR, TIPO, IDIMPUESTO, IDCLASE, ITEM, VLRIMPUESTO, PIVA, VIVA, TIPOCONTRATOARS, ARSTIPOCONTRATO, 
			ANO, MES, NAFILIADOS, IDPLAN, IDTRANSACCION, NUMDOCUMENTO, VLR_PCOSTO, VALORMODERADORA, IDCUM, NOINVIMA, IDTARIFA, KNEGID, NUMCONTRATO, 
			TIPOCONTRATO, VLR_UPC, VLR_UPCNETA_M8P, VLRP_CAPITADO, KCNTRID, PROCESO, NOAUTORIZACION)
		Select @CNSFTR, N_CUOTA, FECHA, DB_CR, AREAPRESTACION, AREAFUNCONT, UBICACION, VR_TOTAL, IMPUTACION, CCOSTO, PREFIJO, ANEXO, 
			REFERENCIA, IDCIRUGIA, CANTIDAD, VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, NOADMISION, NOPRESTACION, NOITEM, @N_FACTURA, SUBCCOSTO, 
			PCOSTO, FECHAPREST, VLRNOTADB, VLRNOTACR, TIPO, IDIMPUESTO, IDCLASE, ITEM, VLRIMPUESTO, PIVA, VIVA, TIPOCONTRATOARS, ARSTIPOCONTRATO, 
			ANO, MES, NAFILIADOS, IDPLAN, IDTRANSACCION, NUMDOCUMENTO=@CNSFTR, VLR_PCOSTO, VALORMODERADORA, IDCUM, NOINVIMA, IDTARIFA, KNEGID, NUMCONTRATO, 
			TIPOCONTRATO, VLR_UPC, VLR_UPCNETA_M8P, VLRP_CAPITADO, KCNTRID, PROCESO, NOAUTORIZACION
		From @FTRD

		set context_info 0;

		insert into @FTR_Result (TipoDoc,Documento,N_Factura,Error,Msg_Error) values ('CAPITA',@IDTERCERO,@N_FACTURA,0,@Modo);
		
		set @cinf = convert(varbinary(128),'trHPRED_AUTOLOG');
		set context_info @cinf

        -- Actualiza Prestaciones facturadas  
        Update dbo.vwc_Facturable_HADM
        Set FACTURADA=1, N_FACTURA=@N_FACTURA
		output h.NOADMISION, 'SALUD' into @Datos(NOADMISION,ORIGENINGASIS) -- facturadas
        From dbo.vwc_Facturable_HADM a
             Join dbo.KCNTFC b With (NoLock) On a.KCNTID=b.KCNTID
			 join HADM h with(nolock) on h.NOADMISION=a.NOADMISION
        Where b.KCNTFCID=@KCNTFCID And a.IDTERCEROCA=@IDTERCERO And a.TIPOCONTRATO=@TIPOCONT And Coalesce(a.FACTURADA, 0)=0 
			And a.FECHAALTA Between b.FECHAINI And b.FECHAFIN;

        -- Actualiza Ordenes Médicas de la Admisión facturadas  
        Update dbo.vwc_Facturable_HADMOM
        Set FACTURADA=1, N_FACTURA=@N_FACTURA
		output h.NOADMISION, 'SALUD' into @Datos(NOADMISION,ORIGENINGASIS) -- facturadas
        From dbo.vwc_Facturable_HADMOM a
             Join dbo.KCNTFC b With (NoLock) On a.KCNTID=b.KCNTID
			 join HADM h with(nolock) on h.NOADMISION=a.NOADMISION
        Where b.KCNTFCID=@KCNTFCID And a.IDTERCEROCA=@IDTERCERO And a.TIPOCONTRATO=@TIPOCONT And Coalesce(a.FACTURADA, 0)=0 
			And a.FECHAALTA Between b.FECHAINI And b.FECHAFIN;

		set context_info 0;

        -- Actualiza Citas facturadas  
        Update dbo.vwc_Facturable_CIT
        Set FACTURADA=1, N_FACTURA=@N_FACTURA 
		output inserted.NOADMISION, 'CIT' into @Datos(NOADMISION,ORIGENINGASIS) -- facturadas
        From dbo.vwc_Facturable_CIT a
             Join dbo.KCNTFC b With (NoLock) On a.KCNTID=b.KCNTID
        Where b.KCNTFCID=@KCNTFCID And a.IDTERCEROCA=@IDTERCERO And a.TIPOCONTRATO=@TIPOCONT And Coalesce(a.FACTURADA, 0)=0 
			And a.FECHAALTA Between b.FECHAINI And b.FECHAFIN;

        -- Actualiza Ordenes Médicas facturadas
        Update dbo.vwc_Facturable_AUT 
        Set FACTURADA=1, N_FACTURA=@N_FACTURA 
		output h.IDAUT, 'CE' into @Datos(NOADMISION,ORIGENINGASIS) -- facturadas
        From dbo.vwc_Facturable_AUT a
             Join dbo.KCNTFC b With (NoLock) On a.KCNTID=b.KCNTID
			 join AUT h with(nolock) on h.IDAUT=a.NOADMISION
        Where b.KCNTFCID=@KCNTFCID And a.IDTERCEROCA=@IDTERCERO And a.TIPOCONTRATO=@TIPOCONT And Coalesce(a.FACTURADA, 0)=0 
			And a.FECHAALTA Between b.FECHAINI And b.FECHAFIN;

		update AUT set FACTURADA=1, N_FACTURA=@N_FACTURA
		from AUT a 
			join (select distinct IDAUT=NOADMISION from @Datos where ORIGENINGASIS='CE') x on x.IDAUT=a.IDAUT;

		insert into FTROFR (CNSFTR,N_FACTURA,VALORTOTAL)
		select distinct CNSFTR=@CNSFTR, a.N_FACTURA, a.VR_TOTAL
		from @Datos d 
			join FTR a with(nolock) on a.NOREFERENCIA=d.NOADMISION and a.TIPOFAC in ('7','8','9') and a.ORIGENINGASIS=d.ORIGENINGASIS and a.GENERADA=1 and a.ESTADO='P'  
				and not exists (select N_FACTURA from FTROFR o with(nolock) where o.N_FACTURA=a.N_FACTURA);

        -- Si ha generado al menos una factura    
		-- Las admisiones solo estan marcadas como facturadas cuando todas las HPRED.FACTURADA=1
		with 
		m0 as (select distinct NOADMISION from @Datos where ORIGENINGASIS='SALUD'),
		m1 as (
			select NOADMISION,
				FACTURADA=min(FACTURADA), -- Si hay prestaciones sin facturar; FACTURADA será 0. 
				N_FACTURA=max(N_FACTURA), -- Trae el N_FACTURA mayor de las prestaciones facturadas, por que una admision puede terner varias facturas  
				VFACTURAS=sum(case when N_FACTURA<>'' then 1 else 0 end), -- Contador de facturas distintas
				COPAGO=sum(COPAGO) -- Valor total del copago en la admision
			from (
				-- Buscar Facturas distintas para la admisión cuando está facturada
				select b.NOADMISION, FACTURADA=coalesce(a.FACTURADA,0), N_FACTURA=coalesce(case when a.FACTURADA=1 then a.N_FACTURA else '' end,''),
					COPAGO = sum(a.VALORCOPAGO)
				from dbo.HPRE b with (nolock)
					join HPRED a with (nolock) on b.NOPRESTACION=a.NOPRESTACION
					join m0 c on b.NOADMISION = c.NOADMISION
				group by b.NOADMISION, coalesce(a.FACTURADA,0), coalesce(case when a.FACTURADA=1 then a.N_FACTURA else '' end,'')
			) x
			group by NOADMISION
		)    
		Update dbo.HADM set 
			COPAGO = case when b.COPAGO>0 then 1 else 0 end, 
			FACTURADA = b.FACTURADA, 
			FACTURADAPARCIAL = case when b.VFACTURAS>0 and b.FACTURADA=0 then 1 else 0 end,
			VFACTURAS = case when b.VFACTURAS>1 then 1 else 0 end, -- Si hay mas de una factura; entonces es de varias facturas.
			N_FACTURA = @N_FACTURA, 
			CNSFCT = @CNSFTR,
			MARCA=0
		from dbo.HADM a With (NoLock)
			join m1 b on a.NOADMISION=b.NOADMISION;

        -- Actualiza Tabla KCNTFC   
        Update dbo.KCNTFC
        Set N_FACTURA=@N_FACTURA, VLRCOPAGO=t.VALORCOPAGO, VLRPAGOCOMP=t.VALORPCOMP, VLRCUOTAMOD=t.VALORMODERADORA, 
			VLRCOSTO=t.VLR_SERVICI, VLRTOTAL=t.VLRTOTAL, FECHA=dbo.FNK_FECHA_SIN_MLS(GetDate()), ESTADO='F'
        From dbo.KCNTFC a With (NoLock)
             cross Apply @Totales t
        Where a.KCNTFCID=@KCNTFCID;

		IF @EC <> 1
			EXEC dbo.SPK_FAC_IMPDEDUC @IDTERCERO, @CNSFTR, @N_FACTURA, @VRSERV

		-- Guarda resultados de la facturación
		insert into FTR_Log (IDT,Fecha,TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber,ErrorSeverity,ErrorState,Origen,Usuario,PC)
		select @IDT,getdate(),TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber=null,ErrorSeverity=null,ErrorState=null,Origen=@Proceso,Usuario=@USUARIO,PC=@SYS_COMPUTERNAME 
		from @FTR_Result;

		If (@@TRANCOUNT>0) 
			Commit;

        --Raiserror('Se ha %s la Factura Capitada No.%s del Contrato No.%s', 10, 0, @Modo, @N_FACTURA, @NUMCONTRATO); -- error()=0 en clarion   
    End Try
    Begin Catch
        Select @ErrorMessage=N'Error al ejecutar '+@Proceso+':'+Char(13)+Char(10)+Coalesce(Error_Message(), '(desconocido)'), @ErrorSeverity=Error_Severity(), @ErrorState=Error_State();
		
        If (@@TRANCOUNT>0)
            Rollback Transaction;
        --Exec dbo.SPC_ADD_SP_ERROR @Proceso, @ErrorMessage, @NOADMISION, @IDSEDE, @USUARIO, @SYS_COMPUTERNAME, '@QueryText';

		-- Guarda resultados del error de facturación
		insert into FTR_Log (IDT,Fecha,TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber,ErrorSeverity,ErrorState,Origen,Usuario,PC)
		select @IDT,getdate(),'CAPITA',@IDTERCERO,'',Error=1,Msg_Error=Error_Message(),Error_Number(),Error_Severity(),Error_State(),Origen=@Proceso,Usuario=@USUARIO,PC=@SYS_COMPUTERNAME 

        -- Raiserror(@ErrorMessage, @ErrorSeverity, @ErrorState);
    End Catch;
End;
go
