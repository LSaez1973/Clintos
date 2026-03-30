objetivo:
Crear un sp que clone FTR/FTRD recibiendo como parametro el campo @COMPANIA, @IDSEDE, @N_FACTURA
reglas de negocio:
- El numero de factura resultante será el original concatenando al final el caracter '_C'
- El campo ESTADO de la factura será 'X' que indica que pertenece a un proceso especial en tramite
- El FTR.CNSFCT (primarykey) será llenado con @CNSFCT quien será determinada con:
            Exec SPK_GENCONSECUTIVO @COMPANIA, @IDSEDE, '@CNSFTR', @CNSFCT Output;  
            Select @CNSFCT=@IDSEDE+Replace(Space(8-Len(@CNSFCT))+LTrim(RTrim(@CNSFCT)), Space(1), 0);  
- FTR.CNSFTR se llena con @CNSFCT
- Tener en cuenta los valores default en Campos de FTR/FTRD quemados que inserta el spc_KCNT_Facturar_HADM que es quien generó la factura original
- Generar un segundo SP que genere el proceso de asignar el campo N_FACTURA a la factura clonada segun como se hace en el spc_KCNT_Facturar_HADM, 
	esto con el fin de actualizar ese campo y los relacionados con el numero de factura que vienen de la tabla FCNS, 
	el SP debe pedir de parametro el numero de factura original + '_C'

sp_help FTR
CNSFCT	varchar	no	40	     
COMPANIA	varchar	no	2	     
CLASE	varchar	no	1	     
IDTERCERO	varchar	no	20	     
N_FACTURA	varchar	no	16	     
F_FACTURA	datetime	no	8	     
F_VENCE	datetime	no	8	     
VR_TOTAL	float	no	8	53   
COBRADOR	varchar	no	20	     
VENDEDOR	varchar	no	20	     
MONEDA	varchar	no	3	     
OCOMPRA	varchar	no	16	     
ESTADO	varchar	no	1	     
F_CANCELADO	datetime	no	8	     
IDAFILIADO	varchar	no	20	     
EMPLEADO	varchar	no	20	     
NOREFERENCIA	varchar	no	16	     
PROCEDENCIA	varchar	no	10	     
TIPOFAC	varchar	no	1	     
OBSERVACION	varchar	no	2048	     
TIPOVENTA	varchar	no	7	     
TIPOCOPAGO	varchar	no	20	     
VALORCOPAGO	decimal	no	9	14   
DESCUENTO	decimal	no	9	14   
VALORPCOMP	decimal	no	9	14   
CREDITO	decimal	no	9	14   
INDCARTERA	smallint	no	2	5    
INDCXC	smallint	no	2	5    
MARCA	smallint	no	2	5    
INDASIGCXC	smallint	no	2	5    
MARCACONT	smallint	no	2	5    
CONTABILIZADA	smallint	no	2	5    
NROCOMPROBANTE	varchar	no	20	     
IMPRESO	smallint	no	2	5    
VALORSERVICIOS	decimal	no	9	14   
CLASEANULACION	varchar	no	1	     
CNSLOG	varchar	no	20	     
USUARIOFACTURA	varchar	no	12	     
FECHAFAC	datetime	no	8	     
MIVA	smallint	no	2	5    
PIVA	decimal	no	9	14   
VIVA	decimal	no	9	14   
VR_ABONOS	decimal	no	9	14   
IDPLAN	varchar	no	6	     
FECHAPASOCXC	datetime	no	8	     
TIPOFIN	varchar	no	1	     
CNSFMAS	varchar	no	20	     
IDAREA_ALTA	varchar	no	20	     
CCOSTO_ALTA	varchar	no	6	     
IDDEP	varchar	no	20	     
VLRNOTADB	decimal	no	9	14   
VLRNOTACR	decimal	no	9	14   
TIPOTTEC	varchar	no	10	     
RAZONANULACION	varchar	no	255	     
CUENTACXC	varchar	no	16	     
IDAREA_FTR	varchar	no	20	     
CCOSTO_FTR	varchar	no	20	     
INDASIGENT	smallint	no	2	5    
PLANDEPAGO	smallint	no	2	5    
CUOTAS	smallint	no	2	5    
FECHA_PP	datetime	no	8	     
PERIODODIAS	smallint	no	2	5    
BANCO	varchar	no	3	     
TIPO_CUENTA	varchar	no	2	     
CTA_BCO	varchar	no	15	     
TIPOANULACION	varchar	no	2	     
CODUNG	varchar	no	5	     
CODPRG	varchar	no	20	     
CAPITADA	smallint	no	2	5    
CP_CONVENIO	varchar	no	20	     
CP_MODALIDAD	varchar	no	80	     
CP_MES	varchar	no	20	     
CP_VLR_SERVICIOS	decimal	no	9	14   
CP_VLR_COPAGOS	decimal	no	9	14   
IDTRANSACCION	varchar	no	6	     
NUMDOCUMENTO	varchar	no	16	     
RAZONSOCIAL	varchar	no	120	     
CONCEPTO	varchar	no	254	     
CONTABILIZADO	smallint	no	2	5    
FECHADOCUMENTO	datetime	no	8	     
IDSEDE	varchar	no	5	     
VALORMODERADORA	decimal	no	9	14   
TIPOCONTRATO	varchar	no	1	     
KCNTID	int	no	4	10   
NOCONTRATO	varchar	no	30	     
NUMCONTRATO	varchar	no	30	     
TIPOSISTEMA	varchar	no	12	     
KCNTRID	int	no	4	10   
FECHAINI	datetime	no	8	     
FECHAFIN	datetime	no	8	     
KCNTFCSGID	int	no	4	10   
FCNSID	smallint	no	2	5    
CUFE	varchar	no	100	     
EFACTURA	smallint	no	2	5    
PORENVIAR	smallint	no	2	5    
ERROR	smallint	no	2	5    
ERRORMSG	varchar	no	512	     
IMPUTABLE	smallint	no	2	5    
PREFIJOFTR	varchar	no	10	     
VALOR_TRM	decimal	no	13	22   
MARCA_CNSCXC	varchar	no	20	     
MARCA_USUARIO	varchar	no	12	     
PROCESO	varchar	no	50	     
FCNSCNS	bigint	no	8	19   
QR	varchar	no	-1	     
FECHAVALIDACION	datetime	no	8	     
FECHAEGRESO	datetime	no	8	     
DXEGRESO	varchar	no	10	     
IDADMINISTRADORA_AFI	varchar	no	20	     
NOAUTORIZACION	varchar	no	30	     
EN_FTRUT	smallint	no	2	5    
N_FACTURA_FTRUT	varchar	no	16	     
GENERADA	smallint	no	2	5    
IDT	bigint	no	8	19   
JSDIAN_AFI	varchar	no	-1	     
MODALIDADCNT	varchar	no	10	     
COBERTURAPLAN	varchar	no	10	     
TIPOUSUARIO	varchar	no	10	     
ESVALIDODIAN	varchar	no	5	     
OBS_SIGNACION	varchar	no	1024	     
NOMIPRES	varchar	no	20	     
IDSUMINISTROMIPRES	varchar	no	20	     
USUARIOANULA	varchar	no	12	     
FECHAANULA	datetime	no	8	     
ORIGENINGASIS	varchar	no	20	    

sp_help FTRD
CNSFTR	varchar	no	40	     	     
IDPROVEEDOR	varchar	no	20	     	     
N_CUOTA	smallint	no	2	5    	0    
FECHA	datetime	no	8	     	     
DB_CR	varchar	no	2	     	     
AREAPRESTACION	varchar	no	20	     	     
AREAFUNCONT	varchar	no	20	     	     
UBICACION	varchar	no	16	     	     
VR_TOTAL	float	no	8	53   	NULL
IMPUTACION	varchar	no	16	     	     
CCOSTO	varchar	no	20	     	     
PREFIJO	varchar	no	6	     	     
ANEXO	varchar	no	1024	     	     
REFERENCIA	varchar	no	40	     	     
IDCIRUGIA	varchar	no	20	     	     
CANTIDAD	decimal	no	9	18   	6    
VALOR	decimal	no	9	14   	2    
VLR_SERVICI	decimal	no	9	14   	2    
VLR_COPAGOS	decimal	no	9	14   	2    
VLR_PAGCOMP	decimal	no	9	14   	2    
NOADMISION	varchar	no	16	     	     
NOPRESTACION	varchar	no	16	     	     
NOITEM	smallint	no	2	5    	0    
N_FACTURA	varchar	no	16	     	     
SUBCCOSTO	varchar	no	4	     	     
PCOSTO	decimal	no	9	14   	2    
FECHAPREST	datetime	no	8	     	     
VLRNOTADB	decimal	no	9	14   	2    
VLRNOTACR	decimal	no	9	14   	2    
TIPO	varchar	no	20	     	     
IDIMPUESTO	varchar	no	10	     	     
IDCLASE	varchar	no	10	     	     
ITEM	smallint	no	2	5    	0    
VLRIMPUESTO	decimal	no	9	14   	2    
PIVA	decimal	no	9	14   	5    
VIVA	decimal	no	9	14   	2    
TIPOCONTRATOARS	varchar	no	8	     	     
ARSTIPOCONTRATO	varchar	no	11	     	     
ANO	varchar	no	4	     	     
MES	varchar	no	2	     	     
NAFILIADOS	int	no	4	10   	0    
IDPLAN	varchar	no	6	     	     
IDTRANSACCION	varchar	no	6	     	     
NUMDOCUMENTO	varchar	no	16	     	     
VLR_PCOSTO	decimal	no	9	14   	2    
VALORMODERADORA	decimal	no	9	14   	2    
IDCUM	varchar	no	20	     	     
NOINVIMA	varchar	no	50	     	     
IDTARIFA	varchar	no	5	     	     
KNEGID	int	no	4	10   	0    
KCNTID	int	no	4	10   	0    
NUMCONTRATO	varchar	no	30	     	     
TIPOCONTRATO	varchar	no	1	     	     
VLR_UPC	decimal	no	13	22   	6    
VLR_UPCNETA_M8P	decimal	no	9	16   	2    
VLRP_CAPITADO	decimal	no	13	22   	6    
KCNTRID	int	no	4	10   	0    
DESCUENTO	decimal	no	9	16   	2    
IDCONCEPTODTO	varchar	no	5	     	     
IDSERVICIOREL	varchar	no	20	     	     
PROCESO	varchar	no	50	     	     
NOAUTORIZACION	varchar	no	20	     	     
CNSFCT_EXT	varchar	no	40	     	     
ORIGEN	varchar	no	20	     	     
PRESTACIONID	int	no	4	10   	0    
FTRDID	int	no	4	10   	0    


-- 02.abr.2025 IVA redondeado a 2 decimales
Create Procedure dbo.spc_KCNT_Facturar_HADM
    @COMPANIA Varchar(2), @NOADMISION Varchar(16), @IDTERCERO Varchar(20), @USUARIO Varchar(12), @IDT bigint = 0, @FACTITEMS smallint=0
As
begin
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
		DESCUENTO decimal(16, 2) NULL,
		IDCONCEPTODTO varchar(5) NULL,
		IDSERVICIOREL varchar(20) NULL,
		PROCESO varchar(50) NULL,
		NOAUTORIZACION varchar(20) NULL
	);
	declare @Tabla_N_FACTURA table (N_FACTURA varchar(20), FCNSID bigint, ESTADO varchar(20), ERRORMSG varchar(max), FCNSCNS bigint);
	declare @FTR_Result as dbo.FTR_Result_Type;
	declare @TERCA as IDTERCERO_Type;
	Declare 
		@IDSEDE Varchar(5),
		@CNSFTR Varchar(20),
		@N_FACTURA Varchar(20),
		@IDTERCEROCA Varchar(20),
		@CA varchar(1),
		@TIPOCONTRATO Varchar(1),
		@KCNTID Int,
		@NOCONTRATO Varchar(30),
		@VALORMODERADORA Decimal(18, 2) =0,
		@N_FACTURAS Varchar(max),
		@CERRADA SmallInt,
		@CLASENOPROC Varchar(20),
		@MARCA SmallInt,
		@FTRS SmallInt,
		@VLRCOPAGOMANUAL Decimal(14, 2),
		@SYS_COMPUTERNAME Varchar(254) = Host_Name(),
		@IDAREA_ALTA  VARCHAR(20),
		@ERROR_FCNS varchar(20), 
		@MSJERROR_FCNS varchar(256), 
		@FCNSID Int, 
		@AFIRCID Int,
		@IDMONEDABASE Varchar(3),
		@IDTERCEROF varchar(20),
		@IDTERCERO_RC varchar(20),
		@EFACTURA smallint, 
		@PREFIJOFTR varchar(10),
		@IDAFILIADO Varchar(20),
		@DATOFAC Varchar(20),
		@VRTOTAL       DECIMAL(14,2),
		@VRSERV        DECIMAL(14,2),
		@VRVIVA decimal(14,2),
		@VRCOPA        DECIMAL(14,2),
		@VRPACO        DECIMAL(14,2),
		@VRDTO         DECIMAL(14,2),
		@VRABONO       DECIMAL(14,2),
		@VLRDEVOLUCION DECIMAL(14,2),
		@TOTALFACTURA  Decimal(14,2),
		@NVOCONSEC1 Varchar(20),
		@EC SmallInt, 
		@IDDEP Varchar(20),
		@DV Int,
		@TTEC Varchar(10),
		@TIPOSISTEMA Varchar(12),
		@ErrorMessage NVarchar(4000), @ErrorSeverity Int, @ErrorState Int, @cant_trans Int, @Proceso Varchar(50)='spc_KCNT_Facturar_HADM', 
		@FCNSCNS bigint, @Masivo smallint, @CNSFMAS varchar(20), @errores int, @TIPOFAC varchar(1), @CCOSTO_ALTA varchar(20), 
		@oFMAS smallint, @AGRUPAMIENTO smallint, @VARIOS_TER smallint, @TIPOTTEC varchar(10);
	
	if coalesce(@IDT,0)=0
		set @IDT = dbo.fnc_GenFechaNumerica(getdate());
		
	if @IDTERCERO='MASIVA' 
	begin 
		Begin Try
			Select @IDSEDE=Coalesce(b.IDSEDE, c.IDSEDE)
			From dbo.UBEQ a With (NoLock)
					Left Join dbo.SED b With (NoLock) On a.IDSEDE=b.IDSEDE
					Outer Apply
				(Select Top (1) IDSEDE From dbo.SED With (NoLock) Order By IDSEDE) c
			Where a.SYS_ComputerName=@SYS_COMPUTERNAME;

			set @CNSFMAS = @NOADMISION

			select @IDTERCERO=b.IDTERCERO, @AGRUPAMIENTO=coalesce(a.AGRUPAMIENTO,0), @VARIOS_TER=coalesce(a.VARIOS_TER,1)
			from FMAS a with (nolock) 
				left join TER b with (nolock) on a.IDTERCERO=b.IDTERCERO 
			where a.CNSFMAS=@CNSFMAS

			if @VARIOS_TER=0 and coalesce(@IDTERCERO,'')=''
			begin
				Raiserror('El consecutivo de Facturación masiva (%s) no tiene definido un Tercero válido.', 16, 1, @NOADMISION);
			end
			set @Masivo = 1; 

		End Try
		Begin Catch
			Select @ErrorMessage=N'Error al ejecutar '+@Proceso+':'+Char(13)+Char(10)+Coalesce(Error_Message(), '(desconocido)'), @ErrorSeverity=Error_Severity(), @ErrorState=Error_State();
			Exec dbo.SPC_ADD_SP_ERROR @ORIGEN = @Proceso, @ERROR = @ErrorMessage, @DOCUMENTO = @CNSFMAS, @IDSEDE = @IDSEDE, @USUARIO = @USUARIO, 
				@SYS_COMPUTERNAME = @SYS_COMPUTERNAME, @QUERYTEXT = null;
			Raiserror(@ErrorMessage, @ErrorSeverity, @ErrorState);
			return;
		End Catch;
	end
	else
	begin
		-- Individual
		Select @IDSEDE=Case When Coalesce(IDSEDEALTA, '')='' Then IDSEDE Else IDSEDEALTA End
		From dbo.HADM With (NoLock)
		Where NOADMISION=@NOADMISION;

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
		set @Masivo = 0;
	end
    --Print '0410. @IDSEDE = '+@IDSEDE;	

    -- Genera una Factura por cada Tercero/Contrato (NO FACTURA CAPITACION)
    -- select top 1 @QueryText=Query from dbo.fnDBA_QueryOpenTransaction() where session_id=@@spid;
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
        Exec dbo.SPC_ADD_SP_ERROR @ORIGEN = @Proceso, @ERROR = @ErrorMessage, @DOCUMENTO = @NOADMISION, @IDSEDE = @IDSEDE, @USUARIO = @USUARIO, 
			@SYS_COMPUTERNAME = @SYS_COMPUTERNAME, @QUERYTEXT = null;
        Raiserror(@ErrorMessage, @ErrorSeverity, @ErrorState);
		return;
    End Catch;

    -- Inicio proceso de Facturación
	SELECT 
		@DATOFAC		= dbo.FNK_VALORVARIABLE('FTRIDSERVICIO'),
		@IDDEP			= dbo.FNK_VALORVARIABLE('IDFDEPFACTURACION'),
		@IDMONEDABASE	= Left(dbo.FNK_VALORVARIABLE('IDMONEDABASE'),3);

    Begin Try
        Begin Transaction;
		Set @FTRS=0;
		if @Masivo=0
		begin
			Select @IDAFILIADO=IDAFILIADO, @CERRADA=CERRADA, @CLASENOPROC=Coalesce(CLASENOPROC, ''), @MARCA=MARCA, 
				@VLRCOPAGOMANUAL=Coalesce(COPAGOVALOR, 0), @IDAREA_ALTA=IDAREA_ALTA, @CCOSTO_ALTA=CCOSTO_ALTA
			From dbo.HADM With (NoLock)
			Where NOADMISION=@NOADMISION;
			/*
			Print '0050. @NOADMISION  : '+@NOADMISION;
			Print '0100. @CERRADA   : '+Str(@CERRADA);
			Print '0200. @CLASENOPROC  : '+@CLASENOPROC;
			Print '0300. @MARCA    : '+Str(@MARCA);
			Print '0400. @VLRCOPAGOMANUAL : '+Str(@VLRCOPAGOMANUAL);
			*/
			If @CLASENOPROC='NP'
				Raiserror('La Admisión No.%s es No Procesable y no se puede Facturar.', 16, 1, @NOADMISION);   
			else
			If @MARCA=1
				Raiserror('La Admisión No.%s esta escogida para Una Facturación Masiva Pendiente..', 16, 1, @NOADMISION);   
			else
			If @CERRADA=0 and @FACTITEMS=0
				Raiserror('La Admisión No.%s se encuentra Abierta, debe estar en Alta administrativa para porder Facturar.', 16, 1, @NOADMISION);   
			Else 
			If @CERRADA=2 and @FACTITEMS=0
				Raiserror('La Admisión No.%s se encuentra con Alta Médica, debe estar en Alta Administrativa para porder Facturar.', 16, 1, @NOADMISION);   
			Else 
			If Coalesce(@CERRADA,0)<>1 and @FACTITEMS=0
				Raiserror('La Admisión No.%s se encuentra en estado desconocido, debe estar en Alta Administrativa para porder Facturar.', 16, 1, @NOADMISION);   

			select @TIPOFAC='I', @AGRUPAMIENTO=1

			if @FACTITEMS=1
				Declare c1 Cursor local Static For
				Select distinct @NOADMISION, @IDAFILIADO, a.IDTERCEROCA, a.COBRARA, a.TIPOCONTRATO, NOCONTRATO=Coalesce(a.NUMCONTRATO, ''), 
					a.KCNTID, a.AFIRCID, a.TIPOTTEC
				From dbo.vwc_Facturable_xItems a
				Where a.NOADMISION=@NOADMISION And a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 
					And a.IDTERCEROCA=Case When @IDTERCERO='' Then a.IDTERCEROCA Else @IDTERCERO End
					and a.IDT=@IDT;
			else
				Declare c1 Cursor local Static For
				Select distinct @NOADMISION, @IDAFILIADO, a.IDTERCEROCA, a.COBRARA, a.TIPOCONTRATO, NOCONTRATO=Coalesce(a.NUMCONTRATO, ''), 
					a.KCNTID, a.AFIRCID, a.TIPOTTEC
				From dbo.vwc_Facturable_HADM a
				Where a.NOADMISION=@NOADMISION And a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 
					And a.IDTERCEROCA=Case When @IDTERCERO='' Then a.IDTERCEROCA Else @IDTERCERO End			 
		end
		else
		begin		
			-- Facturacion Masiva
			set @errores = 0
			declare c2 cursor static for
			Select a.NOADMISION, a.IDAFILIADO, a.CERRADA, Coalesce(a.CLASENOPROC, ''), a.MARCA, coalesce(o.oFMAS,0), Coalesce(a.COPAGOVALOR, 0), a.IDAREA_ALTA
            From dbo.HADM a with (nolock)
				join FMASD m on a.NOADMISION=m.NOADMISION and m.CNSFMAS=@CNSFMAS
				outer apply (
					select oFMAS=count(*) 
					from FMAS x with (nolock) 
						join FMASD y with (nolock) on x.CNSFMAS=y.CNSFMAS 
					where x.CNSFMAS<>@CNSFMAS and x.ESTADO='P' and y.NOADMISION=a.NOADMISION 
				) o
            Where a.IDTERCERO=@IDTERCERO -- And Coalesce(a.FACTURADA,0)=0; 
			open c2
			fetch next from c2 into @NOADMISION, @IDAFILIADO, @CERRADA, @CLASENOPROC, @MARCA, @oFMAS, @VLRCOPAGOMANUAL, @IDAREA_ALTA
			while @@FETCH_STATUS=0
			begin
				begin try
					If @CLASENOPROC='NP'
						Raiserror('La Admisión No.%s es No Procesable y no se puede Facturar.', 16, 1, @NOADMISION);
					else
					If @MARCA=0
						Raiserror('La Admisión No.%s ha sido desmarcada para Facturar masivamente.', 16, 1, @NOADMISION);
					else
					If @oFMAS>0
						Raiserror('La Admisión No.%s está pendiente por facturar en %d Procesos Masivos.', 16, 1, @NOADMISION, @oFMAS); 
					else
					If @CERRADA=0
						Raiserror('La Admisión No.%s se encuentra Abierta, debe estar en Alta administrativa para porder Facturar.', 16, 1, @NOADMISION);
					Else 
					If @CERRADA=2
						Raiserror('La Admisión No.%s se encuentra con Alta Médica, debe estar en Alta Administrativa para porder Facturar.', 16, 1, @NOADMISION); 
					Else 
					If Coalesce(@CERRADA,0)<>1
						Raiserror('La Admisión No.%s se encuentra en estado desconocido, debe estar en Alta Administrativa para porder Facturar.', 16, 1, @NOADMISION);  
				end try
				begin catch
					set @errores+=1;
					If (@@TRANCOUNT>0)
						Rollback Transaction;
					insert into FTR_Log (IDT,Fecha,TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber,ErrorSeverity,ErrorState,Origen,Usuario,PC)
					select @IDT,getdate(),'SALUD',@NOADMISION,'',Error=@errores,Msg_Error=Error_Message(),Error_Number(),Error_Severity(),Error_State(),Origen=@Proceso,Usuario=@USUARIO,PC=@SYS_COMPUTERNAME 
				end catch 
				fetch next from c2 into @NOADMISION, @IDAFILIADO, @CERRADA, @CLASENOPROC, @MARCA, @oFMAS, @VLRCOPAGOMANUAL, @IDAREA_ALTA
			end
			deallocate c2
		
			if @errores>0
			begin
				Raiserror('Se encontraron %d errores en la Facturación Masiva No.%s.', 16, 1,@errores, @CNSFMAS);
			end

			select @IDAFILIADO='MASIVA', @AFIRCID=null, @IDAREA_ALTA=null, @CCOSTO_ALTA=null, @NOADMISION='MASIVA', @TIPOFAC='M'; 

			-- Facturación Masiva, depende del valor de FMAS.AGRUPAMIENTO
			-- 0: Todo en Factura Única
			-- 1: Una Factura por Admisión/Contrato
			-- 2: Una Factura por Tercero
			-- 3: Una Factura por Tercero/Régimen
			-- 4: Una Factura por Contrato
			-- 5: Una Factura por Contrato/Régimen

			if @AGRUPAMIENTO=0
				-- 0: Todo en Factura Única
				Declare c1 Cursor Local Static For
				Select 
					case when a.c=1 then a.NOADMISION else @NOADMISION end, 
					case when a.c=1 then a.IDAFILIADO else @IDAFILIADO end, 
					case when a.c=1 then a.IDTERCEROCA else @IDTERCERO end, 
					case when a.c=1 then a.COBRARA else 'C' end, 
					case when a.c=1 then a.TIPOCONTRATO else a.TIPOCONTRATO /*null*/ end, 
					case when a.c=1 then a.NOCONTRATO else a.NOCONTRATO /*''*/ end, 
					case when a.c=1 then a.KCNTID else a.KCNTID /*0*/ end, 
					case when a.c=1 then a.AFIRCID else 0 end, 
					case when a.c=1 then a.TIPOTTEC else a.TIPOTTEC /*''*/ end
				from (
					Select c=count(distinct a.NOADMISION), NOADMISION=max(a.NOADMISION), IDAFILIADO=max(a.IDAFILIADO), IDTERCEROCA=max(a.IDTERCEROCA), 
						COBRARA=max(a.COBRARA), TIPOCONTRATO=max(a.TIPOCONTRATO), NOCONTRATO=max(Coalesce(a.NUMCONTRATO, '')), 
						KCNTID=max(a.KCNTID), AFIRCID=max(a.AFIRCID), TIPOTTEC=max(a.TIPOTTEC)
					From dbo.vwc_Facturable_HADM a
						join FMASD b with (nolock) on a.NOADMISION=b.NOADMISION and b.CNSFMAS=@CNSFMAS
					Where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 
				) a
			else if @AGRUPAMIENTO=1 
				-- 1: Una Factura por Admisión/Contrato
				Declare c1 Cursor Local Static For
				Select distinct a.NOADMISION, a.IDAFILIADO, a.IDTERCEROCA, a.COBRARA, a.TIPOCONTRATO, NOCONTRATO=Coalesce(a.NUMCONTRATO, ''), 
					a.KCNTID, a.AFIRCID, a.TIPOTTEC
				From dbo.vwc_Facturable_HADM a
					join FMASD b with (nolock) on a.NOADMISION=b.NOADMISION and b.CNSFMAS=@CNSFMAS
				Where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 
			else if @AGRUPAMIENTO=2
				-- 2: Una Factura por Tercero
				Declare c1 Cursor Local Static For
				Select 
					case when a.c=1 then a.NOADMISION else @NOADMISION end, 
					case when a.c=1 then a.IDAFILIADO else @IDAFILIADO end, 
					a.IDTERCEROCA, 
					case when a.c=1 then a.COBRARA else 'C' end, 
					case when a.c=1 then a.TIPOCONTRATO else a.TIPOCONTRATO /*null*/ end, 
					case when a.c=1 then a.NOCONTRATO else a.NOCONTRATO /*''*/ end, 
					case when a.c=1 then a.KCNTID else a.KCNTID /*0*/ end, 
					case when a.c=1 then a.AFIRCID else 0 end, 
					case when a.c=1 then a.TIPOTTEC else a.TIPOTTEC /*''*/ end
				from (
					Select c=count(distinct a.NOADMISION), NOADMISION=max(a.NOADMISION), IDAFILIADO=max(a.IDAFILIADO), IDTERCEROCA=(a.IDTERCEROCA), 
						COBRARA=max(a.COBRARA), TIPOCONTRATO=max(a.TIPOCONTRATO), NOCONTRATO=max(Coalesce(a.NUMCONTRATO, '')), 
						KCNTID=max(a.KCNTID), AFIRCID=max(a.AFIRCID), TIPOTTEC=max(a.TIPOTTEC)
					From dbo.vwc_Facturable_HADM a
						join FMASD b with (nolock) on a.NOADMISION=b.NOADMISION and b.CNSFMAS=@CNSFMAS
					Where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 
					group by a.IDTERCEROCA
				) a
			else if @AGRUPAMIENTO=3
				-- 3: Una Factura por Tercero/Régimen
				Declare c1 Cursor Local Static For
				Select 
					case when a.c=1 then a.NOADMISION else @NOADMISION end, 
					case when a.c=1 then a.IDAFILIADO else @IDAFILIADO end, 
					a.IDTERCEROCA, 
					case when a.c=1 then a.COBRARA else 'C' end, 
					case when a.c=1 then a.TIPOCONTRATO else a.TIPOCONTRATO /*null*/ end, 
					case when a.c=1 then a.NOCONTRATO else a.NOCONTRATO /*''*/ end, 
					case when a.c=1 then a.KCNTID else a.KCNTID /*0*/ end, 
					case when a.c=1 then a.AFIRCID else 0 end, 
					a.TIPOTTEC 
				from (
					Select c=count(distinct a.NOADMISION), NOADMISION=max(a.NOADMISION), IDAFILIADO=max(a.IDAFILIADO), IDTERCEROCA=(a.IDTERCEROCA), 
						COBRARA=max(a.COBRARA), TIPOCONTRATO=max(a.TIPOCONTRATO), NOCONTRATO=max(Coalesce(a.NUMCONTRATO, '')), 
						KCNTID=max(a.KCNTID), AFIRCID=max(a.AFIRCID), TIPOTTEC=(a.TIPOTTEC)
					From dbo.vwc_Facturable_HADM a
						join FMASD b with (nolock) on a.NOADMISION=b.NOADMISION and b.CNSFMAS=@CNSFMAS
					Where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 
					group by a.IDTERCEROCA, a.TIPOTTEC
				) a
			else if @AGRUPAMIENTO=4
				-- 4: Una Factura por Contrato
				Declare c1 Cursor Local Static For
				Select 
					case when a.c=1 then a.NOADMISION else @NOADMISION end, 
					case when a.c=1 then a.IDAFILIADO else @IDAFILIADO end, 
					a.IDTERCEROCA, 
					case when a.c=1 then a.COBRARA else 'C' end, 
					case when a.c=1 then a.TIPOCONTRATO else a.TIPOCONTRATO /*null*/ end, 
					a.NOCONTRATO, 
					case when a.c=1 then a.KCNTID else a.KCNTID /*0*/ end, 
					case when a.c=1 then a.AFIRCID else 0 end, 
					case when a.c=1 then a.TIPOTTEC else a.TIPOTTEC /*''*/ end
				from (
					Select c=count(distinct a.NOADMISION), NOADMISION=max(a.NOADMISION), IDAFILIADO=max(a.IDAFILIADO), IDTERCEROCA=(a.IDTERCEROCA), 
						COBRARA=max(a.COBRARA), TIPOCONTRATO=max(a.TIPOCONTRATO), NOCONTRATO=(coalesce(a.NUMCONTRATO, ltrim(str(a.KCNTID)))), 
						KCNTID=max(a.KCNTID), AFIRCID=max(a.AFIRCID), TIPOTTEC=max(a.TIPOTTEC)
					From dbo.vwc_Facturable_HADM a
						join FMASD b with (nolock) on a.NOADMISION=b.NOADMISION and b.CNSFMAS=@CNSFMAS
					Where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 
					group by a.IDTERCEROCA, coalesce(a.NUMCONTRATO, ltrim(str(a.KCNTID)))
				) a
			else if @AGRUPAMIENTO=5
				-- 5: Una Factura por Contrato/Régimen
				/*
				Declare c1 Cursor Static For
				Select distinct NOADMISION='', a.IDTERCEROCA, COBRARA='C', TIPOCONTRATO=null, 
					NOCONTRATO=Coalesce(a.NUMCONTRATO, ltrim(str(a.KCNTID))), KCNTID=0, AFIRCID=0, a.TIPOTTEC
				From dbo.vwc_Facturable_HADM a
					join FMASD b with (nolock) on a.NOADMISION=b.NOADMISION and b.CNSFMAS=@CNSFMAS
				Where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 
				*/
				Declare c1 Cursor Local Static For
				Select 
					case when a.c=1 then a.NOADMISION else @NOADMISION end, 
					case when a.c=1 then a.IDAFILIADO else @IDAFILIADO end, 
					a.IDTERCEROCA, 
					case when a.c=1 then a.COBRARA else 'C' end, 
					case when a.c=1 then a.TIPOCONTRATO else a.TIPOCONTRATO /*null*/ end, 
					a.NOCONTRATO, 
					case when a.c=1 then a.KCNTID else a.KCNTID /*0*/ end, 
					case when a.c=1 then a.AFIRCID else 0 end, 
					a.TIPOTTEC
				from (
					Select c=count(distinct a.NOADMISION), NOADMISION=max(a.NOADMISION), IDAFILIADO=max(a.IDAFILIADO), IDTERCEROCA=(a.IDTERCEROCA), 
						COBRARA=max(a.COBRARA), TIPOCONTRATO=max(a.TIPOCONTRATO), NOCONTRATO=(coalesce(a.NUMCONTRATO, ltrim(str(a.KCNTID)))), 
						KCNTID=max(a.KCNTID), AFIRCID=max(a.AFIRCID), TIPOTTEC=(a.TIPOTTEC)
					From dbo.vwc_Facturable_HADM a
						join FMASD b with (nolock) on a.NOADMISION=b.NOADMISION and b.CNSFMAS=@CNSFMAS
					Where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 
					group by a.IDTERCEROCA, a.TIPOTTEC, coalesce(a.NUMCONTRATO, ltrim(str(a.KCNTID)))
				) a
		end

		-- Crear Tabla Temporal en blanco
		select *,VALOREXCEDENTE=cast(0 as decimal(14,2)) into #Datos from dbo.vwc_Facturable_HADM a where 1=2;
		
		Open c1;

		Fetch Next From c1
		Into @NOADMISION, @IDAFILIADO, @IDTERCEROCA, @CA, @TIPOCONTRATO, @NOCONTRATO, @KCNTID, @AFIRCID, @TIPOTTEC;		
        While @@FETCH_STATUS=0
        Begin
		
            Print '0480. Antes de numerar facturas';
            Print '0485. @IDSEDE = '+Coalesce(@IDSEDE, '** Sede Nulla **');
            Print '0500. @VLRCOPAGOMANUAL : '+Str(@VLRCOPAGOMANUAL);
			Print '0600. @NOADMISION  : '+(@NOADMISION);
			Print '0610. @IDTERCEROCA  : '+(@IDTERCEROCA);
			Print '0620. @TIPOCONTRATO  : '+(@TIPOCONTRATO);
			Print '0630. @CNSFMAS  : '+(@CNSFMAS);
			Print '0640. @AGRUPAMIENTO  : '+ltrim(str(coalesce(@AGRUPAMIENTO,-1)));

			delete #Datos;

			if @AGRUPAMIENTO=0
			begin
				print '@AGRUPAMIENTO=0';
				-- 0: Todo en Factura Única
				insert into #Datos select a.*, VALOREXCEDENTE=0  
				from dbo.vwc_Facturable_HADM a with (nolock) 
					join FMASD b with (nolock) on a.NOADMISION=b.NOADMISION and b.CNSFMAS=@CNSFMAS
				where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0; 
			end
			else if @AGRUPAMIENTO=1
			begin
				-- 1: Una Factura por Admisión/Contrato				
				-- Tambien aplica para cuando la facturación es Individual ()
				if @FACTITEMS=1
					insert into #Datos select a.*, VALOREXCEDENTE=0  
					from dbo.vwc_Facturable_xItems a 
					where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 and a.NOADMISION=@NOADMISION 
						and a.IDTERCEROCA=@IDTERCEROCA and a.COBRARA=@CA and a.TIPOCONTRATO=@TIPOCONTRATO and Coalesce(a.NUMCONTRATO, '')=@NOCONTRATO
						and a.KCNTID=@KCNTID and coalesce(a.AFIRCID,'')=coalesce(@AFIRCID,'') and a.TIPOTTEC=@TIPOTTEC
						and a.IDT=@IDT;
				else 
					insert into #Datos select a.*, VALOREXCEDENTE=0  
					from dbo.vwc_Facturable_HADM a 
					where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 and a.NOADMISION=@NOADMISION 
						and a.IDTERCEROCA=@IDTERCEROCA and a.COBRARA=@CA and a.TIPOCONTRATO=@TIPOCONTRATO and Coalesce(a.NUMCONTRATO, '')=@NOCONTRATO
						and a.KCNTID=@KCNTID and coalesce(a.AFIRCID,'')=coalesce(@AFIRCID,'') and a.TIPOTTEC=@TIPOTTEC
			end
			else if @AGRUPAMIENTO=2
				-- 2: Una Factura por Tercero
				insert into #Datos select a.*, VALOREXCEDENTE=0 
				From dbo.vwc_Facturable_HADM a
					join FMASD b with (nolock) on a.NOADMISION=b.NOADMISION and b.CNSFMAS=@CNSFMAS
				Where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 and a.IDTERCEROCA=@IDTERCEROCA 
			else if @AGRUPAMIENTO=3
				-- 3: Una Factura por Tercero/Régimen
				insert into #Datos select a.*, VALOREXCEDENTE=0 
				From dbo.vwc_Facturable_HADM a
					join FMASD b with (nolock) on a.NOADMISION=b.NOADMISION and b.CNSFMAS=@CNSFMAS
				Where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 and a.IDTERCEROCA=@IDTERCEROCA and a.TIPOTTEC=@TIPOTTEC
			else if @AGRUPAMIENTO=4
				-- 4: Una Factura por Contrato
				insert into #Datos select a.*, VALOREXCEDENTE=0 
				From dbo.vwc_Facturable_HADM a
					join FMASD b with (nolock) on a.NOADMISION=b.NOADMISION and b.CNSFMAS=@CNSFMAS
				Where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 and coalesce(a.NUMCONTRATO,ltrim(str(a.KCNTID)))=@NOCONTRATO
			else if @AGRUPAMIENTO=5
				-- 5: Una Factura por Contrato/Régimen
				insert into #Datos select a.*, VALOREXCEDENTE=0 
				From dbo.vwc_Facturable_HADM a
					join FMASD b with (nolock) on a.NOADMISION=b.NOADMISION and b.CNSFMAS=@CNSFMAS
				Where a.CAPITA=0 And Coalesce(a.FACTURADA, 0)=0 and coalesce(a.NUMCONTRATO,ltrim(str(a.KCNTID)))=@NOCONTRATO and a.TIPOTTEC=@TIPOTTEC
            
			-- Detalles de la nueva Factura  
			Delete @FTRD;
			-- print 'Insert @FTRD';
            Insert Into @FTRD (
				CNSFTR, N_CUOTA, FECHA, DB_CR, AREAPRESTACION, AREAFUNCONT, UBICACION, VR_TOTAL, IMPUTACION, CCOSTO, 
				PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD, VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, DESCUENTO, NOADMISION, 
				NOPRESTACION, NOITEM, N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST, VLRNOTADB, VLRNOTACR, TIPO, IDIMPUESTO, 
				IDCLASE, ITEM, VLRIMPUESTO, PIVA, VIVA, TIPOCONTRATOARS, ARSTIPOCONTRATO, ANO, MES, NAFILIADOS, IDPLAN, 
				IDTRANSACCION, NUMDOCUMENTO, VLR_PCOSTO, VALORMODERADORA, IDCUM, NOINVIMA, IDTARIFA, IDSERVICIOREL, KNEGID, 
				KCNTID, PROCESO, NOAUTORIZACION)
            Select CNSFTR=@CNSFTR, N_CUOTA=Row_Number() Over (Order By a.IDSERVICIO, a.FECHA), FECHA=dbo.FNK_FECHA_SIN_MLS(GetDate()), DB_CR='DB', 
				AREAPRESTACION=a.IDAREA, AREAFUNCONT=a.IDAREA, UBICACION=Null, VR_TOTAL=(a.VALOR+coalesce(i.VIVA,0)) * a.CANTIDAD, IMPUTACION=0, CCOSTO=a.CCOSTO, 
				PREFIJO=a.PREFIJO, ANEXO=a.DESCSERVICIO, REFERENCIA=a.IDSERVICIO, IDCIRUGIA=Null, CANTIDAD=a.CANTIDAD, VALOR=a.VALOR, 
				VLR_SERVICI=a.VALOR * a.CANTIDAD, /*Case When @VLRCOPAGOMANUAL>0.00 Then 0.00 Else */a.VALORCOPAGO /*End*/ VLR_COPAGOS, 
				VLR_PAGCOMP=a.VALORPCOMP, a.DESCUENTO, NOADMISION=a.NOADMISION, NOPRESTACION=a.NOPRESTACION, NOITEM=a.NOITEM, N_FACTURA=@N_FACTURA, 
				SUBCCOSTO=Null, a.PCOSTO, FECHAPREST=a.FECHA, VLRNOTADB=0, VLRNOTACR=0, TIPO=Null, IDIMPUESTO=Null, IDCLASE=Null, ITEM=Null, 
				VLRIMPUESTO=0, PIVA=coalesce(a.PIVA,0), VIVA=coalesce(i.VIVA,0)*a.CANTIDAD, TIPOCONTRATOARS=Null, ARSTIPOCONTRATO=Null, ANO=Null, MES=Null, NAFILIADOS=Null, IDPLAN=Null, 
				IDTRANSACCION='FTR', NUMDOCUMENTO=@CNSFTR, VLR_PCOSTO=a.PCOSTO*a.CANTIDAD, a.VALORMODERADORA, IDCUM=a.IDCUM, NOINVIMA=a.NOINVIMA, 
				IDTARIFA=a.IDTARIFA, a.IDSERVICIOREL, KNEGID=a.KNEGID, a.KCNTID, @Proceso, NOAUTORIZACION
            From #Datos a
				cross apply (select VIVA = round(coalesce(a.VIVA,0),0)) i; 

			If @DATOFAC = 'IDALTERNA'
			Begin
				UPDATE @FTRD Set REFERENCIA = SER.IDALTERNA 
				From dbo.SER with(NoLock)
				WHERE  REFERENCIA = SER.IDSERVICIO AND SER.IDALTERNA IS NOT NULL AND SER.IDALTERNA <> ''
			End

			-- Solo genera factura si por lo menos exista un servicio con valor>0
			if 1=1 -- if (select count(*) from @FTRD where VLR_SERVICI>0)>0
			Begin
				-- LSaez.22.mar.2019 Busca Tercero para la Factura 
				select @IDTERCEROF=IDTERCEROF, @IDTERCERO_RC=IDTERCERO_RC 
				from dbo.fnc_IDTERCERO_FTR(@IDTERCEROCA, @CA, @IDAFILIADO, @AFIRCID) a 

				Insert into @TERCA(IDTERCERO) Values (@IDTERCEROF)

				IF @CA = 'C' 
					SELECT @EC = ENVIODICAJA FROM dbo.TER with(NoLock) Where IDTERCERO = @IDTERCEROCA               
				ELSE
				IF @CA = 'A'
					SELECT @EC = 1
				ELSE
				IF @CA = 'O'               
					SELECT @EC = ENVIODICAJA FROM dbo.TER with(NoLock) Where IDTERCERO = @IDTERCEROF

				-- LSaez.11.mar.2019: FACTURARAIDTERPART: Control para facturar a tercero Particular 
				select @ERROR_FCNS=ERROR, @MSJERROR_FCNS=MSJERROR from dbo.fnc_FTR_FacturarIDTERPART(@TERCA)
				if @ERROR_FCNS=1
				begin
					raiserror(@MSJERROR_FCNS,16,1);
				end

				if coalesce(@IDTERCERO_RC,'')<>'' --and @CA <> 'C'
				begin
					-- Hay un Responsable de cuenta y no se cobra al contratante (administradora), se debe crear el Responsable como Tercero
					exec dbo.spc_TER_InsertFromAsistencial 'AFIRC', @AFIRCID;
				End
				--else
				-- LSaez.22.mar.2018 Si se factura a nombre del Afiliado, Crea entonces a este como Tercero
				-- esto si @IDTERCEROF=IDAFILIADO y el Tercero no existe en la tabla TER
				if @IDTERCEROF=@IDAFILIADO
				begin
					-- LSaez.22.mar.2019: Control para facturar a Menores de Edad
					select @ERROR_FCNS=ERROR, @MSJERROR_FCNS=MSJERROR from dbo.fnc_AFI_MenoresEdad(18,@TERCA)
					if @ERROR_FCNS=1
					begin
						raiserror(@MSJERROR_FCNS,16,1);
					End
					exec dbo.spc_TER_InsertFromAsistencial 'AFI', @IDTERCEROF;
				end

				-- 21.dic.2018.LSaez: Generación de No.Factura controlado por la tabla FCNS, 
				-- Se agregaro el parámetros @IDAREA_ALTA a SPC_GENNUMEROFACTURA_FCNS, este SP no usa RPDX
				insert into @Tabla_N_FACTURA (N_FACTURA, FCNSID, ESTADO, ERRORMSG, FCNSCNS)
				EXEC dbo.SPC_GENNUMEROFACTURA_FCNS @COMPANIA, @IDSEDE, @IDAREA_ALTA

				select @N_FACTURA=null, @ERROR_FCNS=null, @MSJERROR_FCNS=null, @FCNSID=null;

				select @N_FACTURA=a.N_FACTURA, @ERROR_FCNS=a.ESTADO, @MSJERROR_FCNS=a.ERRORMSG, @FCNSID=a.FCNSID, @FCNSCNS=a.FCNSCNS,
					@EFACTURA=b.EFACTURA, @PREFIJOFTR=b.PREFIJO
				from @Tabla_N_FACTURA a
					left join dbo.FCNS b with(NoLock) on a.FCNSID=b.FCNSID				
				/*
				PRINT ' N_FACTURA = '+ coalesce(@N_FACTURA,'null')
				PRINT ' @ERROR_FCNS = '+ coalesce(@ERROR_FCNS,'null')
				PRINT ' @MSJERROR_FCNS = '+ coalesce(@MSJERROR_FCNS,'null')

				select * from @Tabla_N_FACTURA
				*/

				if coalesce(@ERROR_FCNS,'') = 'OK'
				begin	      
					EXEC SPK_GENCONSECUTIVO @COMPANIA, @IDSEDE, '@CNSFTR',  @CNSFTR OUTPUT  
					SELECT @CNSFTR = @IDSEDE + REPLACE(SPACE(8 - LEN(@CNSFTR))+LTRIM(RTRIM(@CNSFTR)),SPACE(1),0)

					update @FTRD set 
						VR_TOTAL = coalesce(VR_TOTAL,0), 
						VLR_SERVICI = coalesce(VLR_SERVICI,0), 
						VLR_COPAGOS = coalesce(VLR_COPAGOS,0),
						VLR_PAGCOMP  = coalesce(VLR_PAGCOMP,0), 
						DESCUENTO = coalesce(DESCUENTO,0),
						VALORMODERADORA = coalesce(VALORMODERADORA,0);
                           
					Select 
						@VRTOTAL = sum(VR_TOTAL), 
						@VRSERV = sum(VLR_SERVICI),
						@VRVIVA = sum(VIVA),
						@VRCOPA = sum(VLR_COPAGOS),
						@VRPACO  = sum(VLR_PAGCOMP), 
						@VRDTO = sum(DESCUENTO),  --Coalesce(SUM(Coalesce(DESCUENTO,0)*Coalesce(CANTIDAD,0)),0)
						@VALORMODERADORA = sum(VALORMODERADORA)
					From @FTRD;
					
					Select 
						@VRTOTAL = round(Coalesce(@VRTOTAL,0),0), 
						@VRSERV = round(Coalesce(@VRSERV,0),0),
						@VRCOPA = round(Coalesce(@VRCOPA,0),0),
						@VRPACO = round(Coalesce(@VRPACO,0),0),
						@VRDTO = round(Coalesce(@VRDTO,0),0),
						@VRVIVA = round(Coalesce(@VRVIVA,0),0),
						@VALORMODERADORA = round(Coalesce(@VALORMODERADORA,0),0);

					-- TAREA: El valor del Abono debe ser distribuido en HPRED para descontarlo adecuadamente
					-- De la forma en que está, podría ser descontado por cada factura de la misma admision
					Select @VRABONO = round(Sum(a.VALOR),0) 
					From dbo.QXDING a with(NoLock)
						join (select distinct NOADMISION from @FTRD) m on a.NOINGRESO = m.NOADMISION 
					Where a.DEVUELTO = 0 

					set @VRABONO = coalesce(@VRABONO,0)
  
  					-- SE MIRA SI EL VALOR ENTRE DESCUENTOS Y ABONOS SOBREPASA EL TOTAL DE LA FACTURA
             
					Set @VLRDEVOLUCION = @VRSERV + @VRVIVA - @VRCOPA - @VALORMODERADORA - @VRPACO - @VRDTO - @VRABONO --OJO             
					Set @TOTALFACTURA  = @VRSERV + @VRVIVA - @VRCOPA - @VALORMODERADORA - @VRPACO - @VRDTO -- OJO QUITE MENOS ABONOS
           
					IF @TOTALFACTURA > 0
						Set @VRTOTAL = @TOTALFACTURA; -- OJO QUITE MENOS ABONOS
					ELSE
					BEGIN
						Set @VRTOTAL = @TOTALFACTURA;    
					End;

					SELECT @DV = a.DIASVENCIMIENTO, @TTEC= a.TIPOTTEC, @TIPOSISTEMA=b.TIPOSISTEMA
					FROM dbo.KCNT a With (NoLock)
						Left Join dbo.TTEC b With (NoLock) On a.TIPOTTEC=b.TIPO
					WHERE a.KCNTID=@KCNTID    
    			
					set @DV = Case When Coalesce(@DV,0) = 0 Then 30 Else @DV End;   

					-- Nueva Factura  
					With mem1 As ( 
						Select CNSFCT=@CNSFTR, COMPANIA=@COMPANIA, CLASE='C', IDTERCERO=b.IDTERCERO, N_FACTURA=@N_FACTURA, 
							F_FACTURA=dbo.FNK_FECHA_SIN_HORA(GetDate()), F_VENCE=dbo.FNK_FECHA_SIN_HORA(GetDate()+@DV), 
							VR_TOTAL = @VRTOTAL, COBRADOR=Null, VENDEDOR=Null, MONEDA=@IDMONEDABASE, VALOR_TRM=1, OCOMPRA=Null, ESTADO='P', F_CANCELADO=Null, 
							IDAFILIADO=@IDAFILIADO, EMPLEADO=@USUARIO, NOREFERENCIA=@NOADMISION, PROCEDENCIA='SALUD', TIPOFAC=@TIPOFAC, 
							OBSERVACION='', TIPOVENTA='Credito', TIPOCOPAGO=Null, VALORCOPAGO=@VRCOPA, DESCUENTO=@VRDTO, VALORPCOMP=@VRPACO, 
							CREDITO=0, INDCARTERA=0, INDCXC=0, MARCA=0, INDASIGCXC=0, MARCACONT=0, CONTABILIZADA=0, NROCOMPROBANTE=Null, IMPRESO=0, 
							VALORSERVICIOS=@VRSERV, CLASEANULACION=Null, CNSLOG=Null, USUARIOFACTURA=@USUARIO, FECHAFAC=dbo.FNK_FECHA_SIN_MLS(GetDate()), 
							MIVA=case when @VRVIVA>0 then 1 else 0 end, PIVA=0, VIVA=@VRVIVA, VR_ABONOS=@VRABONO, IDPLAN=Null, FECHAPASOCXC=Null, TIPOFIN='C', 
							CNSFMAS=Null, IDAREA_ALTA=@IDAREA_ALTA, CCOSTO_ALTA=@CCOSTO_ALTA, IDDEP=@IDDEP, 
							VLRNOTADB=0, VLRNOTACR=0, TIPOTTEC=@TTEC, RAZONANULACION=Null, CUENTACXC=Null, IDAREA_FTR=Null, CCOSTO_FTR=Null, 
							INDASIGENT=Null, PLANDEPAGO=Null, CUOTAS=Null, FECHA_PP=Null, PERIODODIAS=Null, BANCO=Null, TIPO_CUENTA=Null, CTA_BCO=Null, 
							TIPOANULACION=Null, CODUNG=Null, CODPRG=Null, CAPITADA=0, CP_CONVENIO=Null, CP_MODALIDAD=Null, CP_MES=Null, 
							CP_VLR_SERVICIOS=Null, CP_VLR_COPAGOS=Null, IDTRANSACCION='FTR', NUMDOCUMENTO=@CNSFTR, RAZONSOCIAL=b.RAZONSOCIAL, 
							CONCEPTO='Factura De Venta', CONTABILIZADO=0, FECHADOCUMENTO=Null, IDSEDE=@IDSEDE, VALORMODERADORA=@VALORMODERADORA, 
							TIPOCONTRATO=@TIPOCONTRATO, NUMCONTRATO=@NOCONTRATO, TIPOSISTEMA=@TIPOSISTEMA, KCNTID=@KCNTID,
							FCNSID=@FCNSID, FCNSCNS=@FCNSCNS, EFACTURA=@EFACTURA, PREFIJOFTR=@PREFIJOFTR, PORENVIAR=0, Error=0, ERRORMSG='',
							IMPUTABLE=0, PROCESO=@Proceso
						From dbo.TER b With (NoLock) 
						where b.IDTERCERO=@IDTERCEROF						
					)
					Insert Into dbo.FTR (CNSFCT, COMPANIA, CLASE, IDTERCERO, N_FACTURA, F_FACTURA, F_VENCE, VR_TOTAL, COBRADOR, VENDEDOR, MONEDA, VALOR_TRM,
						OCOMPRA, ESTADO, F_CANCELADO, IDAFILIADO, EMPLEADO, NOREFERENCIA, PROCEDENCIA, TIPOFAC, OBSERVACION, TIPOVENTA, TIPOCOPAGO, 
						VALORCOPAGO, DESCUENTO, VALORPCOMP, CREDITO, INDCARTERA, INDCXC, MARCA, INDASIGCXC, MARCACONT, CONTABILIZADA, NROCOMPROBANTE, 
						IMPRESO, VALORSERVICIOS, CLASEANULACION, CNSLOG, USUARIOFACTURA, FECHAFAC, MIVA, PIVA, VIVA, VR_ABONOS, IDPLAN, FECHAPASOCXC, 
						TIPOFIN, CNSFMAS, IDAREA_ALTA, CCOSTO_ALTA, IDDEP, VLRNOTADB, VLRNOTACR, TIPOTTEC, RAZONANULACION, CUENTACXC, IDAREA_FTR, 
						CCOSTO_FTR, INDASIGENT, PLANDEPAGO, CUOTAS, FECHA_PP, PERIODODIAS, BANCO, TIPO_CUENTA, CTA_BCO, TIPOANULACION, CODUNG, CODPRG, 
						CAPITADA, CP_CONVENIO, CP_MODALIDAD, CP_MES, CP_VLR_SERVICIOS, CP_VLR_COPAGOS, IDTRANSACCION, NUMDOCUMENTO, RAZONSOCIAL, CONCEPTO, 
						CONTABILIZADO, FECHADOCUMENTO, IDSEDE, VALORMODERADORA, TIPOCONTRATO, NUMCONTRATO, TIPOSISTEMA, KCNTID,
						FCNSID, FCNSCNS, EFACTURA, PREFIJOFTR, PORENVIAR, ERROR, ERRORMSG, IMPUTABLE, PROCESO, IDT)
					Select *, @IDT From mem1;
					
					Insert Into dbo.FTRD (
						CNSFTR, N_CUOTA, FECHA, DB_CR, AREAPRESTACION, AREAFUNCONT, UBICACION, VR_TOTAL, IMPUTACION, CCOSTO, 
						PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD, VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, NOADMISION, 
						NOPRESTACION, NOITEM, N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST, VLRNOTADB, VLRNOTACR, TIPO, IDIMPUESTO, 
						IDCLASE, ITEM, VLRIMPUESTO, PIVA, VIVA, TIPOCONTRATOARS, ARSTIPOCONTRATO, ANO, MES, NAFILIADOS, IDPLAN, 
						IDTRANSACCION, NUMDOCUMENTO, VLR_PCOSTO, VALORMODERADORA, IDCUM, NOINVIMA, IDTARIFA, IDSERVICIOREL, KNEGID, 
						KCNTID, PROCESO, NOAUTORIZACION, DESCUENTO)
					Select @CNSFTR, N_CUOTA, FECHA, DB_CR, AREAPRESTACION, AREAFUNCONT, UBICACION, VR_TOTAL, IMPUTACION, CCOSTO, 
						PREFIJO, ANEXO, REFERENCIA, IDCIRUGIA, CANTIDAD, VALOR, VLR_SERVICI, VLR_COPAGOS, VLR_PAGCOMP, NOADMISION, 
						NOPRESTACION, NOITEM, @N_FACTURA, SUBCCOSTO, PCOSTO, FECHAPREST, VLRNOTADB, VLRNOTACR, TIPO, IDIMPUESTO, 
						IDCLASE, ITEM, VLRIMPUESTO, PIVA, VIVA, TIPOCONTRATOARS, ARSTIPOCONTRATO, ANO, MES, NAFILIADOS, IDPLAN, 
						IDTRANSACCION, NUMDOCUMENTO, VLR_PCOSTO, VALORMODERADORA, IDCUM, NOINVIMA, IDTARIFA, IDSERVICIOREL, KNEGID, 
						KCNTID, @Proceso, NOAUTORIZACION, DESCUENTO
					From @FTRD;

					insert into FTROFR (CNSFTR,N_FACTURA,VALORTOTAL)
					select distinct CNSFTR=@CNSFTR, a.N_FACTURA, a.VR_TOTAL
					from #Datos d 
						join FTR a with(nolock) on a.NOREFERENCIA=d.NOADMISION and a.TIPOFAC in ('7','8','9') and a.ORIGENINGASIS='SALUD' and a.GENERADA=1 and a.ESTADO='P'  
							and not exists (select N_FACTURA from FTROFR o with(nolock) where o.N_FACTURA=a.N_FACTURA)

					if @NOADMISION='MASIVA' or (@NOADMISION='' and @Masivo=1)
						insert into @FTR_Result (TipoDoc,Documento,N_Factura,Error,Msg_Error) values ('SALUD',@CNSFMAS,@N_FACTURA,0,'Generada.');						
					else
						insert into @FTR_Result (TipoDoc,Documento,N_Factura,Error,Msg_Error) values ('SALUD',@NOADMISION,@N_FACTURA,0,'Generada.');

					-- Actualiza Prestaciones facturadas
					if @FACTITEMS=1
						Update dbo.vwc_Facturable_xItems 
						Set FACTURADA=1, N_FACTURA=@N_FACTURA
						from dbo.vwc_Facturable_xItems a
							join #Datos b on a.HPREDID=b.HPREDID --a.NOADMISION=b.NOADMISION and a.NOPRESTACION=b.NOPRESTACION and a.NOITEM=b.NOITEM;
					else
						Update dbo.vwc_Facturable_HADM 
						Set FACTURADA=1, N_FACTURA=@N_FACTURA
						from dbo.vwc_Facturable_HADM a
							join #Datos b on a.HPREDID=b.HPREDID; --a.NOADMISION=b.NOADMISION and a.NOPRESTACION=b.NOPRESTACION and a.NOITEM=b.NOITEM;

					with 
						m0 as (select distinct NOADMISION from @FTRD),
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
						join m1 b on a.NOADMISION=b.NOADMISION
						-- Si la admision se resuelve como facturada; busca N_FACTURA en FTR (si es de varias facturas, toma el N_FACTURA mayor) 
						--left join dbo.FTR c With (NoLock) On b.N_FACTURA=c.N_FACTURA and b.FACTURADA=1

					declare c3 cursor static for
					select distinct NOADMISION from @FTRD
					open c3
					fetch next from c3 into @NOADMISION 
					while @@FETCH_STATUS=0
					begin	
						-- Inserta en Facturas por Admision  
						Insert Into dbo.HADMF (NOADMISION, N_FACTURA, CNSFCT, ESTADO, N_FACTURAR, ANEXOUNICO, IDTERCERO, IDPLAN, ITEM, DESCRIPCION)
						Select NOADMISION=@NOADMISION, N_FACTURA=@N_FACTURA, CNSFCT=@CNSFTR, ESTADO='P', N_FACTURAR=Null, ANEXOUNICO=0, IDTERCERO=@IDTERCEROF, 
							IDPLAN=Null, ITEM=Null, DESCRIPCION=Null;
						Set @N_FACTURAS=Coalesce(@N_FACTURAS+', '+@N_FACTURA, @N_FACTURA);

						-- PRINT 'llamado a caja del tercero = ' + @IDTERCERO1
						EXEC dbo.SPK_PAGOSCAJA_QX @NOADMISION, @SYS_COMPUTERNAME, @COMPANIA, @IDSEDE, @USUARIO, @IDTERCEROF 

						fetch next from c3 into @NOADMISION;
					end
					deallocate c3;

		         	IF @EC <> 1
						EXEC dbo.SPK_FAC_IMPDEDUC @IDTERCERO, @CNSFTR, @N_FACTURA, @VRSERV

					Set @FTRS += 1;
				End
				else
				begin
					-- Error en Generacion de N_FACTURA
					--PRINT ' @MSJERROR_FCNS* = '+ coalesce(@MSJERROR_FCNS,'null')
					set @MSJERROR_FCNS = coalesce(@MSJERROR_FCNS,'Error en Generacion de N_FACTURA, No hay registros.');
					raiserror(@MSJERROR_FCNS,16,1);
				end
			end
			else
			begin
				-- Error en Generacion de N_FACTURA
				set @MSJERROR_FCNS ='No existen servicios con valores mayor que cero para Facturar.';
				raiserror(@MSJERROR_FCNS,16,1);
			End
			Fetch Next From c1
			Into @NOADMISION, @IDAFILIADO, @IDTERCEROCA, @CA, @TIPOCONTRATO, @NOCONTRATO, @KCNTID, @AFIRCID, @TIPOTTEC;
		End;
		Deallocate c1;

        If @FTRS>0
        Begin;
            -- Si ha generado al menos una factura    

			if @Masivo=1
			begin
				update FMAS set N_FACTURA=@N_FACTURA, F_FACTURA=b.F_FACTURA, F_VENCE=b.F_VENCE, ESTADO='F', FACTURADA=1, VR_TOTAL=@VRTOTAL, IDT=@IDT 
				from FMAS a 
					join FTR b on a.CNSFMAS=@CNSFMAS and b.N_FACTURA=@N_FACTURA

				update FMASD set FACTURADA=1, VR_TOTAL=coalesce(b.VR_TOTAL,0) 
				from FMASD a with (nolock)
					outer apply (select VR_TOTAL=sum(VR_TOTAL) from @FTRD b where a.NOADMISION=b.NOADMISION) b
				where a.CNSFMAS=@CNSFMAS
			end;

			-- Guarda resultados de la facturación
			insert into FTR_Log (IDT,Fecha,TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber,ErrorSeverity,ErrorState,Origen,Usuario,PC)
			select @IDT,getdate(),TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber=null,ErrorSeverity=null,ErrorState=null,Origen=@Proceso,Usuario=@USUARIO,PC=@SYS_COMPUTERNAME 
			from @FTR_Result;

			-- Recalculo del IVA y Valor Total con 2 decimales.
			exec spc_FTR_TOTAL_VIVA @N_FACTURA;

			If (@@TRANCOUNT>0) 
				Commit;
        End;
        Else
        Begin
            Rollback;
            Raiserror('La Admincón No.%s No tiene servicios de tipo Evento pendientes para Facturar', 16, 0, @NOADMISION);   
        End;
    End Try
    Begin Catch
        Select @ErrorMessage=N'Error al ejecutar '+@Proceso+':'+Char(13)+Char(10)+Coalesce(Error_Message(), '(desconocido)'), @ErrorSeverity=Error_Severity(), @ErrorState=Error_State();

        If (@@TRANCOUNT>0)
            Rollback Transaction;

		-- Guarda resultados del error de facturación
		insert into FTR_Log (IDT,Fecha,TipoDoc,Documento,N_Factura,Error,Msg_Error,ErrorNumber,ErrorSeverity,ErrorState,Origen,Usuario,PC)
		select @IDT,getdate(),'SALUD',@NOADMISION,'',Error=1,Msg_Error=Error_Message(),Error_Number(),Error_Severity(),Error_State(),Origen=@Proceso,Usuario=@USUARIO,PC=@SYS_COMPUTERNAME 

        --Exec dbo.SPC_ADD_SP_ERROR @Proceso, @ErrorMessage, @NOADMISION, @IDSEDE, @USUARIO, @SYS_COMPUTERNAME, '@QueryText';
        --Raiserror(@ErrorMessage, @ErrorSeverity, @ErrorState);
    End Catch;
End
go
