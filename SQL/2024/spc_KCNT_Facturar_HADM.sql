

declare 
	@CNSFMAS varchar(20) = '...', -- remplazar los ... con el dato correcto
	@USUARIO varchar(12) = '...', -- remplazar los ... con el dato correcto
	@IDT bigint;

-- Generar nueva ID trnassación
select @IDT = dbo.fnc_GenFechaNumerica(getdate());

-- Actualzar FMAS con el IDT generado   
update FMAS set IDT=@IDT where CNSFMAS=@CNSFMAS;

-- Ejecuta SP que genera la facturación
exec dbo.spc_KCNT_Facturar_HADM @COMPANIA, @CNSFMAS, 'MASIVA', @USUARIO, @IDT;

-- Ver resultado de la facturacion: Se debe mostrar al usurio éste resultado. 
-- Tener en cuenta el campo Error (>0: hubo errores), Msj_Error: Es el error o mensaje
select * from FTR_Log where IDT=@IDT;


drop Procedure if exists dbo.spc_KCNT_Facturar_HADM
go
-- 26.nov.2024: Relacionar facturas de Copagos en FTROFR
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
				AREAPRESTACION=a.IDAREA, AREAFUNCONT=a.IDAREA, UBICACION=Null, VR_TOTAL=(a.VALOR+coalesce(a.VIVA,0)) * a.CANTIDAD, IMPUTACION=0, CCOSTO=a.CCOSTO, 
				PREFIJO=a.PREFIJO, ANEXO=a.DESCSERVICIO, REFERENCIA=a.IDSERVICIO, IDCIRUGIA=Null, CANTIDAD=a.CANTIDAD, VALOR=a.VALOR, 
				VLR_SERVICI=a.VALOR * a.CANTIDAD, /*Case When @VLRCOPAGOMANUAL>0.00 Then 0.00 Else */a.VALORCOPAGO /*End*/ VLR_COPAGOS, 
				VLR_PAGCOMP=a.VALORPCOMP, a.DESCUENTO, NOADMISION=a.NOADMISION, NOPRESTACION=a.NOPRESTACION, NOITEM=a.NOITEM, N_FACTURA=@N_FACTURA, 
				SUBCCOSTO=Null, a.PCOSTO, FECHAPREST=a.FECHA, VLRNOTADB=0, VLRNOTACR=0, TIPO=Null, IDIMPUESTO=Null, IDCLASE=Null, ITEM=Null, 
				VLRIMPUESTO=0, PIVA=coalesce(a.PIVA,0), VIVA=coalesce(a.VIVA,0)*a.CANTIDAD, TIPOCONTRATOARS=Null, ARSTIPOCONTRATO=Null, ANO=Null, MES=Null, NAFILIADOS=Null, IDPLAN=Null, 
				IDTRANSACCION='FTR', NUMDOCUMENTO=@CNSFTR, VLR_PCOSTO=a.PCOSTO*a.CANTIDAD, a.VALORMODERADORA, IDCUM=a.IDCUM, NOINVIMA=a.NOINVIMA, 
				IDTARIFA=a.IDTARIFA, a.IDSERVICIOREL, KNEGID=a.KNEGID, a.KCNTID, @Proceso, NOAUTORIZACION
            From #Datos a; 

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
End;
go

drop FUNCTION if exists dbo.fnc_HCAD_Print
go
CREATE FUNCTION dbo.fnc_HCAD_Print(@CONSECUTIVO varchar(20))    
RETURNS varchar(max)    
AS    
BEGIN    
  DECLARE    
    @PltComp varchar(max) = '{"seq":"","field":"","label":"","value":"","type":""}',    
    @data varchar(max) = '{}';    
    
  SELECT @data = '[' + STRING_AGG(comp.Componente, ',') WITHIN GROUP (ORDER BY a.SECUENCIA) + ']'    
  FROM HCAD a WITH (NOLOCK)
	left join MPLD mld on mld.CLASEPLANTILLA=a.CLASEPLANTILLA and mld.CAMPO=a.CAMPO
	OUTER APPLY (    
		SELECT    
		  dvMulticheck = CAST('{' + STRING_AGG(dvMulticheck, ',') + '}' AS varchar(max))    
		FROM HCADL l WITH (NOLOCK)    
		CROSS APPLY (SELECT dvMulticheck = '"' + l.VALORLISTA + '":' + CASE l.CHECKM WHEN 1 THEN 'true' ELSE 'false' END) dvmc    
		WHERE l.CONSECUTIVO = a.CONSECUTIVO AND l.SECUENCIA = a.SECUENCIA    
	  ) omc    
	OUTER APPLY (    
		SELECT DESCRIPCION = COALESCE(l.DESCRIPCION, '')    
		FROM HCADL l WITH (NOLOCK)    
		WHERE a.TIPOCAMPO = 'Lista' AND a.CONSECUTIVO = l.CONSECUTIVO AND a.SECUENCIA = l.SECUENCIA AND l.CHECKM = 1    
	  ) l    
	OUTER APPLY (    
		SELECT [defaultValue] = CASE a.TIPOCAMPO    
		  WHEN 'Alfanumerico' THEN a.ALFANUMERICO    
		  WHEN 'Fecha' THEN CONVERT(varchar(max), a.FECHA, 3)    
		  WHEN 'FechaHora' THEN CONVERT(varchar(max), a.FECHA, 121)     
		  WHEN 'Memo' THEN STRING_ESCAPE(a.MEMO, 'json')    
		  WHEN 'Descripcion' THEN STRING_ESCAPE(a.MEMO, 'json')    
		  WHEN 'MultiCheck' THEN omc.dvMulticheck    
		  WHEN 'Lista' THEN COALESCE(l.DESCRIPCION, '')    
		  WHEN 'HC' THEN STRING_ESCAPE(a.MEMO, 'json')    
		END    
	  ) kdv    
	CROSS APPLY (    
		SELECT Componente = JSON_MODIFY(    
		  JSON_MODIFY(    
			JSON_MODIFY(    
			  JSON_MODIFY(    
				JSON_MODIFY(@PltComp,    
				  '$.seq', a.SECUENCIA),    
				'$.field', a.CAMPO), -- Cambio la referencia a la tabla MPLD por la tabla HCAD    
			  '$.label', mld.DESCCAMPO /*a.DESCCAMPO*/),    
			'$.value', CASE WHEN ISJSON(kdv.[defaultValue]) = 0 THEN '"' + kdv.[defaultValue] + '"' ELSE JSON_QUERY(kdv.[defaultValue]) END),    
		  '$.type', a.TIPOCAMPO)    
		) comp	
  WHERE a.CONSECUTIVO = @CONSECUTIVO;    
    
  SET @data = COALESCE(@data, '{}');    
  RETURN @data;    
END;    
go

drop TRIGGER if exists [dbo].[TA_FTRD]
go
CREATE TRIGGER [dbo].[TA_FTRD]  
ON [dbo].[FTRD] AFTER        
INSERT,UPDATE   
AS   
 BEGIN --1  
	--print 'TA_FTRD';  
	-- VERIFICO SI EL TRIGER ESTA HABILITADO  
	IF (UPDATE(REFERENCIA) OR UPDATE(CANTIDAD) OR UPDATE(PCOSTO)) AND DBO.FNK_VALORVARIABLE('HABTRGFCJ')='1'  
	begin  
		UPDATE FTRD set FTRD.VLR_PCOSTO  = FTRD.CANTIDAD * FTRD.PCOSTO  
		from inserted inner join FTRD on FTRD.CNSFTR  = inserted.CNSFTR  
			AND FTRD.N_CUOTA = INSERTED.N_CUOTA  
	end  
  
	-- add by LSaez: 18.04.2015  
	-- Agrega Código CUM y ACT al final del anexo de FTRD, teniendo en cuenta que el Servicio debe ser NOPOS y el PLAN y Variable lo permitan  
	if update(REFERENCIA) and dbo.fnk_ValorVariable('FTR_ADDCUMANEXO')='SI'  
	begin  
		--update FTRD set ANEXO=b.DescServicio+case when coalesce(b.TIPOMED,'0')='2' and coalesce(f.NOTIFICAR_CUMACT,0)=1  then ' (CUM:'+coalesce(b.IDCUM,'?')+')' else '' end  
		update FTRD set ANEXO=left(b.DescServicio,30)+' (CUM:'+coalesce(b.IDCUM,'?')+')'  
		from inserted a   
			left join ser b on a.REFERENCIA=b.IDSERVICIO  
			left join iart c on b.IDARTICULO=c.IDARTICULO  
			join FTRD d on a.CNSFTR=d.CNSFTR and a.N_CUOTA=d.N_CUOTA  
			left join FTR e on d.CNSFTR=e.CNSFCT  
			left join PPT f on e.IDTERCERO=f.IDTERCERO and e.IDPLAN=f.IDPLAN  
		where coalesce(b.TIPOMED,'0')='2' and coalesce(f.NOTIFICAR_CUMACT,0)=1   
	end   

	-- LSaez: 20231222, actualiza IDCIRUGIA cuando la procedencia es de SALUD
	update FTRD set IDCIRUGIA=d.IDCIRUGIA, ORIGEN='HPRED', PRESTACIONID=d.HPREDID
	from inserted b
		join FTRD a with(nolock) on a.CNSFTR=b.CNSFTR and a.N_CUOTA=b.N_CUOTA
		join FTR f with(nolock) on a.CNSFTR=f.CNSFCT and f.PROCEDENCIA='SALUD'
		join HPRE c with(nolock) on b.NOPRESTACION=c.NOPRESTACION and c.CIRUGIA='Si'
		join HPRED d with(nolock) on c.NOPRESTACION=d.NOPRESTACION and a.NOITEM=d.NOITEM;

	-- LSaez: 20241205, actualiza ORIGEN,PRESTACIONID cuando la procedencia es de Admisiones sin Cirugía
	update FTRD set ORIGEN='HPRED', PRESTACIONID=d.HPREDID
	from inserted b
		join FTRD a with(nolock) on a.CNSFTR=b.CNSFTR and a.N_CUOTA=b.N_CUOTA
		join FTR f with(nolock) on a.CNSFTR=f.CNSFCT and f.PROCEDENCIA='SALUD'
		join HPRE c with(nolock) on b.NOPRESTACION=c.NOPRESTACION and coalesce(c.CIRUGIA,'No')<>'Si'
		join HPRED d with(nolock) on c.NOPRESTACION=d.NOPRESTACION and a.NOITEM=d.NOITEM;

	-- LSaez: 20241205, actualiza ORIGEN,PRESTACIONID cuando la procedencia es de Citas sin Cirugía
	update FTRD set ORIGEN='CIT', PRESTACIONID=d.CITID
	from inserted b
		join FTRD a with(nolock) on a.CNSFTR=b.CNSFTR and a.N_CUOTA=b.N_CUOTA
		join FTR f with(nolock) on a.CNSFTR=f.CNSFCT and f.PROCEDENCIA='CI'
		join CIT d with(nolock) on b.NOADMISION=d.CONSECUTIVO;

	-- LSaez: 20241205, actualiza ORIGEN,PRESTACIONID cuando la procedencia es de Autorizaciones sin Cirugía
	update FTRD set ORIGEN='AUTD', PRESTACIONID=d.AUTDID
	from inserted b
		join FTRD a with(nolock) on a.CNSFTR=b.CNSFTR and a.N_CUOTA=b.N_CUOTA
		join FTR f with(nolock) on a.CNSFTR=f.CNSFCT and f.PROCEDENCIA='CE'
		join AUTD d with(nolock) on b.NOADMISION=d.IDAUT and a.NOITEM=d.NO_ITEM;

 END --1         
go

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
	-- Signación DIAN
	update FTR set OBS_SIGNACION=@OBS_SIGNACION where CNSFCT=@CNSFCT;
go

drop Trigger if exists dbo.trc_FTR_U
go
Create Trigger dbo.trc_FTR_U  
on dbo.FTR for Update  
as
begin
	set xact_abort off;	-- Para poder manipular eventos de error(catch) en triggers que afecten transacciones encadenadas. si no se usa SQL generara el error 
						-- 3998: Se ha detectado una transacción no confirmable al final del lote. Se ha revertido la transacción.
	set nocount on;
	if @@ROWCOUNT>1
	begin
		raiserror('No puede procesar mas de una Factura en una sola instrucción.',16,1);
		rollback;
		return;			
	end
	
	declare 
		@TranCounter int, @N_FACTURA_COPAGOS varchar(20), @PROCEDENCIA varchar(20), @IDT varchar(20);
            
	set @TranCounter = @@TRANCOUNT; -- Guarda el # de transacciones activas     
	
	begin try        
        
		if @TranCounter > 0          
			save transaction SaveTranc_trc_FTR_U;  -- ya existe una transaccion activa   
 
		if update (ORIGENINGASIS)
		begin
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
				raiserror('Factura Existente: Para éste documento existe la Factura No. %s sin relacionar a una factura de EPS',16,1,@N_FACTURA_COPAGOS);
			end
		end

		 -- Obtiene el consecutivo de factura numérico  
		if update(N_FACTURA)  
		Begin  
			With x As (  
				SELECT CNSFCT, Val=Substring(N_FACTURA, PATINDEX('%[0-9]%', N_FACTURA), LEN(N_FACTURA))    
				From Inserted Where FCNSCNS Is null  
			)  
			Update dbo.FTR Set FCNSCNS = Left(x.Val,PATINDEX('%[^0-9]%', x.Val+'a')-1)  
			From dbo.FTR a   
				Join x On a.CNSFCT=x.CNSFCT
			where a.FCNSID>0

			-- Solo para la UT de IMAT SAS - Oncomedica
			if db_name()='Clintos8_UT'
			begin
				update Agilis.dbo.FTR set N_FACTURA_FTRUT=a.N_FACTURA
				from inserted a
					join FTRUT b with (nolock) on a.CNSFCT=b.CNSFCT
					join Agilis.dbo.FTR c with (nolock) on b.N_FACTURA=c.N_FACTURA
				where b.BDEXT='Agilis'

				update Clintos8.dbo.FTR set N_FACTURA_FTRUT=a.N_FACTURA
				from inserted a
					join FTRUT b with (nolock) on a.CNSFCT=b.CNSFCT
					join Clintos8.dbo.FTR c with (nolock) on b.N_FACTURA=c.N_FACTURA
				where b.BDEXT='Clintos8'

				update Oncomedica8.dbo.FTR set N_FACTURA_FTRUT=a.N_FACTURA
				from inserted a
					join FTRUT b with (nolock) on a.CNSFCT=b.CNSFCT
					join Oncomedica8.dbo.FTR c with (nolock) on b.N_FACTURA=c.N_FACTURA
				where b.BDEXT='Oncomedica8'
			end	
		end

		-- Distribución de facturas copagos en las prestaciones
		declare 
			@FTR_GENERADA table (
				CNSFCT varchar(40), N_FACTURA varchar(20), NOADMISION varchar(20), IDT varchar(20), 
				TIPOFAC varchar(1), COPAGOS decimal(14,2), ORIGENINGASIS varchar(20), ESTADO varchar(1)
			); 
		declare @TOTALEXCEDENTE decimal(14,2), @string varchar(128), @ESTADO varchar(1);

		drop table if exists #ftrofr;
		drop table if exists #Datos_I;
		
		-- Asignar Estado Generada
		update FTR set GENERADA=1 
		output inserted.CNSFCT, inserted.N_FACTURA, inserted.NOREFERENCIA, inserted.IDT, inserted.TIPOFAC, inserted.VR_TOTAL, inserted.ORIGENINGASIS, inserted.ESTADO 
		into @FTR_GENERADA(CNSFCT,N_FACTURA,NOADMISION,IDT,TIPOFAC,COPAGOS,ORIGENINGASIS,ESTADO) -- Faturas Generadas
		from inserted a
			join FTR b on a.CNSFCT=b.CNSFCT
		where a.FCNSID>0 and a.FCNSCNS>0; 	
	
		if (select count(*) from @FTR_GENERADA)>0
		begin			
			select @PROCEDENCIA=ORIGENINGASIS, @N_FACTURA_COPAGOS=N_FACTURA, @ESTADO=ESTADO, @IDT = IDT from @FTR_GENERADA;
			
			if @ESTADO='A'
			begin
				if (select count(*) from vwc_Facturable a with(nolock) where a.N_FACTURACOPAGO=@N_FACTURA_COPAGOS
					-- and a.FACTURABLE=1 and coalesce(a.CLASENOPROC,'')<>'NP'
				) > 0
					raiserror('ERROR: debe desvincular primero ésta factura de servicios relacionados por Copagos.',16,1);
			end

			-- select @ESTADO,@IDT

			if @ESTADO='P'
			begin
				if @IDT like '_789' -- desde el formulario FormaFTR_Financ de Clarion se llena FTR:IDT cuando se está insertando ej. 7789, 8789, 9789
				begin
					-- Indica que se está facturando todos los ITEMS del documento (cuando no es facturación por items)
					-- Se marcan el IDT tanto FTR como los items del documento origen que no estén facturados en copagos, ni en facturas 
					update @FTR_GENERADA set IDT = dbo.fnc_GenFechaNumerica(getdate());
					update FTR set IDT = f.IDT from @FTR_GENERADA f where f.CNSFCT=FTR.CNSFCT;
				
					if @PROCEDENCIA='SALUD'
					begin
						-- obligado a usar vwc_Facturable_HADM_Todas para incluir admisiones con alta medica y no admin. No usar vwc_Facturable
						update vwc_Facturable_HADM_Todas set IDT=f.IDT 
						from vwc_Facturable_HADM_Todas a
							join @FTR_GENERADA f on f.NOADMISION=a.NOADMISION 
						where coalesce(a.N_FACTURACOPAGO,'')='' and a.FACTURABLE=1 and coalesce(a.CLASENOPROC,'')<>'NP';
					end
					else
					if @PROCEDENCIA='CIT'
					begin
						update CIT set IDT=f.IDT 
						from CIT a
							join @FTR_GENERADA f on f.NOADMISION=a.CONSECUTIVO
						where a.FACTURADA=0 and coalesce(a.N_FACTURACOPAGO,'')='';
					end
					else
					if @PROCEDENCIA='CE'
					begin
						update AUTD set IDT=f.IDT 
						from AUTD a
							join @FTR_GENERADA f on f.NOADMISION=a.IDAUT
						where a.FACTURADA=0 and coalesce(a.N_FACTURACOPAGO,'')='';
					end
				end
				
				-- drop table #Datos_I
				select ORIGEN,IDTERCEROCA,COBRARA,IDSERVICIOADM,IDSEDE,NOADMISION,FECHAALTA,IDAREA_ALTA,CCOSTO_ALTA,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,IDAFILIADO,NOPRESTACION,
					IDAUT,CNSCIT,FECHA,NOITEM,PREFIJO,IDSERVICIO,DESCSERVICIO,CANTIDAD,VALOR,VLR_SERVICI,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,PCOSTO,FACTURADA,
					N_FACTURA,IDPROVEEDOR,IDAREA,CCOSTO,IDCUM,NOINVIMA,KCNTRID,NUMCONTRATO,KNEGID,IDTARIFA,KCNTID,IDSERVICIOREL,AFIRCID,CNSFACT,MARCAFAC,CNSFCT,VFACTURAS,
					NOCOBRABLE,CLASEING,CAPITA,IDT,HPREDID,NOAUTORIZACION,CERRADA,N_FACTURACOPAGO, 
					VALOREXCEDENTE=cast(0 as decimal(14,2)), TIPOFAC = cast(null as varchar(1))
				into #Datos_I
				from vwc_Facturable_HADM where 1=2
				union all 
				select ORIGEN,IDTERCEROCA,COBRARA,IDSERVICIOADM,IDSEDE,NOADMISION,FECHAALTA,IDAREA_ALTA,CCOSTO_ALTA,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,IDAFILIADO,NOPRESTACION,
					IDAUT,CNSCIT,FECHA,NOITEM,PREFIJO,IDSERVICIO,DESCSERVICIO,CANTIDAD,VALOR=VLR_SERVICI,VLR_SERVICI,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,PCOSTO,FACTURADA,
					N_FACTURA,IDPROVEEDOR,IDAREA,CCOSTO,IDCUM,NOINVIMA,KCNTRID,NUMCONTRATO,KNEGID,IDTARIFA,KCNTID,IDSERVICIOREL,AFIRCID,CNSFACT,MARCAFAC,CNSFCT,VFACTURAS,
					NOCOBRABLE,CLASEING,CAPITA,IDT,HPREDID,NOAUTORIZACION,CERRADA,N_FACTURACOPAGO,
					VALOREXCEDENTE=cast(0 as decimal(14,2)), TIPOFAC = cast(null as varchar(1)) 
				from vwc_Facturable_CIT where 1=2
				union all 
				select ORIGEN,IDTERCEROCA,COBRARA,IDSERVICIOADM,IDSEDE,NOADMISION,FECHAALTA,IDAREA_ALTA,CCOSTO_ALTA,TIPOCONTRATO,TIPOTTEC,TIPOSISTEMA,IDAFILIADO,NOPRESTACION,
					IDAUT,CNSCIT,FECHA,NOITEM,PREFIJO,IDSERVICIO,DESCSERVICIO,CANTIDAD,VALOR,VLR_SERVICI,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,PCOSTO,FACTURADA,
					N_FACTURA,IDPROVEEDOR,IDAREA,CCOSTO,IDCUM,NOINVIMA,KCNTRID,NUMCONTRATO,KNEGID,IDTARIFA,KCNTID,IDSERVICIOREL,AFIRCID,CNSFACT,MARCAFAC,CNSFCT,VFACTURAS,
					NOCOBRABLE,CLASEING,CAPITA,IDT,HPREDID,NOAUTORIZACION,CERRADA,N_FACTURACOPAGO, 
					VALOREXCEDENTE=cast(0 as decimal(14,2)), TIPOFAC = cast(null as varchar(1)) 
				from vwc_Facturable_AUT where 1=2;

				--exec tempdb.sys.sp_help #Datos_I;
				--print @PROCEDENCIA;

				if @PROCEDENCIA='SALUD'
				begin
					-- obligado a usar vwc_Facturable_HADM_Todas para incluir admisiones con alta medica y no admin. No usar vwc_Facturable
					-- Items marcados en proceso previo con IDT por documento 
					insert into #Datos_I
					select a.ORIGEN,a.IDTERCEROCA,a.COBRARA,a.IDSERVICIOADM,a.IDSEDE,a.NOADMISION,a.FECHAALTA,a.IDAREA_ALTA,a.CCOSTO_ALTA,a.TIPOCONTRATO,a.TIPOTTEC,a.TIPOSISTEMA,a.IDAFILIADO,a.NOPRESTACION,
						a.IDAUT,a.CNSCIT,a.FECHA,a.NOITEM,a.PREFIJO,a.IDSERVICIO,a.DESCSERVICIO,a.CANTIDAD,a.VALOR,a.VLR_SERVICI,a.VALORCOPAGO,a.VALORPCOMP,a.VALORMODERADORA,a.DESCUENTO,a.PCOSTO,a.FACTURADA,
						a.N_FACTURA,a.IDPROVEEDOR,a.IDAREA,a.CCOSTO,a.IDCUM,a.NOINVIMA,a.KCNTRID,a.NUMCONTRATO,a.KNEGID,a.IDTARIFA,a.KCNTID,a.IDSERVICIOREL,a.AFIRCID,a.CNSFACT,MARCAFAC=a.MARCA,a.CNSFCT,a.VFACTURAS,
						a.NOCOBRABLE,a.CLASEING,a.CAPITA,a.IDT,a.HPREDID,a.NOAUTORIZACION,a.CERRADA,a.N_FACTURACOPAGO, 
						VALOREXCEDENTE=cast(0 as decimal(14,2)), f.TIPOFAC 
					from @FTR_GENERADA f
						-- obligado a usar vwc_Facturable_HADM_Todas para incluir admisiones con alta medica y no admin. No usar vwc_Facturable
						join dbo.vwc_Facturable_HADM_Todas a on a.NOADMISION=f.NOADMISION and a.IDT=f.IDT
					where f.TIPOFAC in ('7','8','9') and a.FACTURABLE=1 and coalesce(a.CLASENOPROC,'')<>'NP';
				end
				else
				if @PROCEDENCIA='CIT'  
				begin  
					--print @PROCEDENCIA;  
					--select * from @FTR_GENERADA;  
					-- Items marcados en proceso previo con IDT por documento  
					insert into #Datos_I  
					select a.ORIGEN,a.IDTERCEROCA,a.COBRARA,a.IDSERVICIOADM,a.IDSEDE,a.NOADMISION,a.FECHAALTA,a.IDAREA_ALTA,a.CCOSTO_ALTA,a.TIPOCONTRATO,a.TIPOTTEC,a.TIPOSISTEMA,a.IDAFILIADO,a.NOPRESTACION,  
						a.IDAUT,a.CNSCIT,a.FECHA,a.NOITEM,a.PREFIJO,a.IDSERVICIO,a.DESCSERVICIO,a.CANTIDAD,a.VALORTOTAL,a.VLR_SERVICI,a.VALORCOPAGO,a.VALORPCOMP,a.VALORMODERADORA,a.DESCUENTO,a.PCOSTO,a.FACTURADA,  
						a.N_FACTURA,a.IDPROVEEDOR,a.IDAREA,a.CCOSTO,a.IDCUM,a.NOINVIMA,a.KCNTRID,a.NUMCONTRATO,a.KNEGID,a.IDTARIFA,a.KCNTID,a.IDSERVICIOREL,a.AFIRCID,a.CNSFACT,MARCAFAC=a.MARCAFAC,a.CNSFCT,a.VFACTURAS,  
						a.NOCOBRABLE,a.CLASEING,a.CAPITA,a.IDT,a.HPREDID,a.NOAUTORIZACION,a.CERRADA,a.N_FACTURACOPAGO, 
						VALOREXCEDENTE=cast(0 as decimal(14,2)), f.TIPOFAC   
					from @FTR_GENERADA f  
						-- obligado a usar vwc_Facturable_CIT   
						join dbo.vwc_Facturable_CIT a on a.CNSCIT=f.NOADMISION and a.IDT=f.IDT;  
				end  
				else  
				if @PROCEDENCIA='CE'   
				begin  
					-- Items marcados en proceso previo con IDT por documento   
					insert into #Datos_I  
					select a.ORIGEN,a.IDTERCEROCA,a.COBRARA,a.IDSERVICIOADM,a.IDSEDE,a.NOADMISION,a.FECHAALTA,a.IDAREA_ALTA,a.CCOSTO_ALTA,a.TIPOCONTRATO,a.TIPOTTEC,a.TIPOSISTEMA,a.IDAFILIADO,a.NOPRESTACION,  
						a.IDAUT,a.CNSCIT,a.FECHA,a.NOITEM,a.PREFIJO,a.IDSERVICIO,a.DESCSERVICIO,a.CANTIDAD,a.VALOR,a.VLR_SERVICI,a.VALORCOPAGO,a.VALORPCOMP,a.VALORMODERADORA,a.DESCUENTO,a.PCOSTO,a.FACTURADA,  
						a.N_FACTURA,a.IDPROVEEDOR,a.IDAREA,a.CCOSTO,a.IDCUM,a.NOINVIMA,a.KCNTRID,a.NUMCONTRATO,a.KNEGID,a.IDTARIFA,a.KCNTID,a.IDSERVICIOREL,a.AFIRCID,a.CNSFACT,MARCAFAC=a.MARCAFAC,a.CNSFCT,a.VFACTURAS,  
						a.NOCOBRABLE,a.CLASEING,a.CAPITA,a.IDT,a.HPREDID,a.NOAUTORIZACION,a.CERRADA,a.N_FACTURACOPAGO, 
					VALOREXCEDENTE=cast(0 as decimal(14,2)), f.TIPOFAC   
					from @FTR_GENERADA f  
						-- obligado a usar vwc_Facturable_AUT  
						join dbo.vwc_Facturable_AUT a on a.IDAUT=f.NOADMISION and a.IDT=f.IDT;  
				end

				if (select count(*) from #Datos_I ) > 0
				begin
					--select * from #Datos_I;
					-- Totales de la Factura
					with 
					a as (
						-- Total acumulado por Admisiones que tienen copagos facturados, agrupadas (7:Copago, 8:moderadora, 9:Pago Comp.)
						select a.TIPOFAC, TOTALPRESTACION=sum(TOTALPRESTACION)
						from (
							select TIPOFAC = case when a.ORIGEN='HADM' and a.TIPOFAC='8' then '7' else a.TIPOFAC end, TOTALPRESTACION=coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0)
							from #Datos_I a
						) a
						group by a.TIPOFAC
					)
					select a.TIPOFAC, a.TOTALPRESTACION, f.COPAGOS
					into #ftrofr
					from @FTR_GENERADA f cross join a;

					select @TOTALEXCEDENTE=TOTALPRESTACION-COPAGOS from #ftrofr;

					if @TOTALEXCEDENTE<0
					begin
						set @string = format(@TOTALEXCEDENTE,'C2', 'es-CO')
						raiserror('El Valor de la Factura de Copagos no puede superar el total de los Servicios prestados (%s)',16,1,@string);
					end

					-- Actualizacion del copago tomado de la factura relacionada al documento 
					Update #Datos_I 
					Set VALORCOPAGO = (coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0) * f.COPAGOS) / f.TOTALPRESTACION*1.00
					from #Datos_I a
						cross join #ftrofr f 
					where f.TIPOFAC='7';
					-- Actualizacion de cuota moderadora tomado de la factura relacionada al documento					
					Update #Datos_I 
					Set VALORMODERADORA = (coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0) * f.COPAGOS) / f.TOTALPRESTACION*1.00
					from #Datos_I a
						cross join #ftrofr f 
					where f.TIPOFAC='8';
					-- Actualizacion del pago compartido tomado de la factura relacionada al documento 					
					Update #Datos_I 
					Set VALORPCOMP = (coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0) * f.COPAGOS) / f.TOTALPRESTACION*1.00
					from #Datos_I a
						cross join #ftrofr f 
					where f.TIPOFAC='9';

					-- Ajuste por decimales segun el tipo de copagos, el ajuste se aplica a un solo item x admision y tipo copago
					with v as (
						select HPREDID = max(a.HPREDID),
							AJUSTE = f.COPAGOS - sum(case f.TIPOFAC when '7' then a.VALORCOPAGO when '8' then a.VALORMODERADORA when '9' then a.VALORPCOMP end)					
						from #Datos_I a
							cross join #ftrofr f 
						group by f.COPAGOS
					)
					update #Datos_I set 
						VALORCOPAGO = VALORCOPAGO + iif(f.TIPOFAC='7',v.AJUSTE,0),
						VALORMODERADORA = VALORMODERADORA + iif(f.TIPOFAC='8',v.AJUSTE,0),
						VALORPCOMP = VALORPCOMP + iif(f.TIPOFAC='9',v.AJUSTE,0)
					from #Datos_I a
						join v on v.HPREDID = a.HPREDID
						cross join #ftrofr f;

					if @PROCEDENCIA='SALUD'
					begin
						-- Procedencia Salud: HADM

						-- Recalculos en HPRED del valor total luego de los copagos
						update HPRED 
						set N_FACTURACOPAGO=@N_FACTURA_COPAGOS, VALORCOPAGO=coalesce(b.VALORCOPAGO,0), VALORPCOMP=coalesce(b.VALORPCOMP,0),
							VALOREXCEDENTE = (coalesce(b.VALOR,0)*coalesce(b.CANTIDAD,0))-coalesce(b.VALORCOPAGO,0)-coalesce(b.VALORPCOMP,0), TIPOCOPAGO=b.TIPOFAC
						from dbo.HPRED a
							join #Datos_I b on b.ORIGEN='HADM' and a.HPREDID=b.HPREDID; 
				
						update HPRE set VALORCOPAGO=b.VALORCOPAGO, VALORPCOMP=b.VALORPCOMP, VALOREXEDENTE=b.VALOREXCEDENTE
						from @FTR_GENERADA i 
							join HPRE a on a.NOADMISION = i.NOADMISION
							cross apply (
								select VALORCOPAGO=sum(VALORCOPAGO), VALORPCOMP=sum(VALORPCOMP), VALOREXCEDENTE=sum(VALOREXCEDENTE) 
								from HPRED b with(nolock) where b.NOPRESTACION=a.NOPRESTACION
							) b

						update HADM set COPAGOVALOR = coalesce(b.VR_TOTAL,0), MODOCOPAGO='Propio', TIPOCOPAGO=b.TIPOFAC 
						from @FTR_GENERADA i 
							join HADM a on a.NOADMISION=i.NOADMISION
							outer apply ( 
								-- Suma de todas las facturas de Copagos de la Admisión
								select VR_TOTAL=sum(b.VR_TOTAL), TIPOFAC=min(b.TIPOFAC) 
								from FTR b with(nolock) where b.NOREFERENCIA=a.NOADMISION and b.GENERADA=1 and b.ESTADO='P' and b.ORIGENINGASIS=@PROCEDENCIA
							) b
					end 
					else
					if @PROCEDENCIA = 'CIT'
					begin        
						update CIT set N_FACTURACOPAGO=@N_FACTURA_COPAGOS, VALORCOPAGO = coalesce(b.VALORCOPAGO,0), VALORMODERADORA = coalesce(b.VALORMODERADORA,0), 
							VALOREXEDENTE = a.VALORTOTAL - coalesce(b.VALORCOPAGO,0) - coalesce(b.VALORMODERADORA,0), TIPOCOPAGO=b.TIPOFAC
						from CIT a
							join #Datos_I b on b.ORIGEN='CIT' and b.HPREDID=a.CITID; 
					end
					else
					if @PROCEDENCIA = 'CE' 
					begin
						update AUTD set N_FACTURACOPAGO=@N_FACTURA_COPAGOS, VALORCOPAGO = coalesce(b.VALORCOPAGO,0),VALOREXCEDENTE = (coalesce(a.VALOR,0)*coalesce(a.CANTIDAD,0))-coalesce(b.VALORCOPAGO,0), 
							TIPOCOPAGO = b.TIPOFAC
						from dbo.AUTD a
							join #Datos_I b on b.ORIGEN='AUT' and b.HPREDID=a.AUTDID; 
				
						update AUT set VALORCOPAGO = b.VALORCOPAGO, VALOREXEDENTE = b.VALOREXCEDENTE
						from  @FTR_GENERADA i 
							join AUT a on a.IDAUT=i.NOADMISION
							cross apply (
								select VALORCOPAGO=sum(VALORCOPAGO), VALOREXCEDENTE=sum(VALOREXCEDENTE) 
								from AUTD b with(nolock) where b.IDAUT=a.IDAUT
							) b
					end
				end
			end
		end
		
		-- Anulación de Facturas en HADMF
		if update (ESTADO)
		begin
			update FTR set USUARIOANULA=u.USUARIO, FECHAANULA=dbo.fnk_fecha_sin_mls(getdate())
			from FTR a 
				join inserted b on a.CNSFCT=b.CNSFCT and b.ESTADO='A'
				outer apply dbo.fnc_getSession(@@SPID) u

			update HADMF set ESTADO='A'
			from HADMF a join inserted b on a.N_FACTURA=b.N_FACTURA and b.ESTADO='A'
		end
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
       
		select     
			@ErrorMessage = coalesce(ERROR_MESSAGE(),'desconocido'),    
			@ErrorSeverity = ERROR_SEVERITY(),    
			@ErrorState = ERROR_STATE();  
      
		if @TranCounter = 0  -- En un trigger en valor mínimo es 1, cuando hay cero o una transacción abierta.
			rollback transaction;	-- en triggers nunca entra por acá
		else 
		begin
			-- ************ ADVERTENCIA con XACT_ABORT OFF ****************
			rollback transaction SaveTranc_trc_FTR_U; 
			-- SET XACT_ABORT OFF: Tenga en cuenta cuando esté presente en el trigger, 
			--	modo OFF es requerido para poder manipular eventos de error(catch) en triggers que afecten transacciones encadenadas. si no se usa SQL generara el error
			--				3998: Se ha detectado una transacción no confirmable al final del lote. Se ha revertido la transacción.
			--
			-- 1. Cuidado, el rollback aquí presente, que es de la transacción guardada NO revierte cambios.
			-- 2. Ei el triggers se desencadenó dentro de un try catch sin una transacción previa, el catch revierte los cambios (rollback automático).
			-- 3. Si antes de desencadenar el trigger existe al menos una transacción abierta, el commit o rollback de esa transación serán los que afecten lo sucedido. 
			-- Ej. si al eliminar un registro de esta tabla usted no usa try catch o no inicia transacción, en caso de error la transacción quedará confirmada (commit).	   
		end
		raiserror(@ErrorMessage,16,1);  		
	end catch
end
go

drop procedure if exists spc_FTR_DesvincularItemsCopagos 
go
create procedure spc_FTR_DesvincularItemsCopagos 
	@N_FACTURACOPAGO varchar(20),
	@NOADMISION varchar(20),
	@PROCEDENCIA varchar(20)
as
begin
	set nocount on;

	if coalesce(@N_FACTURACOPAGO,'')=''
		return;

	declare 
		@TranCounter int;
	-- Control de Transacciones  
	set @TranCounter = @@TRANCOUNT; -- Guarda el # de transacciones activas       
	
	begin try 

		if @TranCounter > 0    
			save transaction SaveTranc;
		else    
			begin transaction;  -- Nueva transaccion 

		if @PROCEDENCIA = 'SALUD'
		begin
			-- obligado a usar vwc_Facturable_HADM_Todas para incluir admisiones con alta medica y no admin. No usar vwc_Facturable
			if (select count(*) from vwc_Facturable_HADM_Todas with(nolock) where N_FACTURACOPAGO=@N_FACTURACOPAGO and FACTURADA=1)>0
			begin
				raiserror('ERROR: Esta factura ya se esncuentra relacionada a servcios facturados a la aseguradora',16,1);
			end

			update HPRED set VALORCOPAGO=0, VALORPCOMP=0, VALOREXCEDENTE=CANTIDAD*VALOR, N_FACTURACOPAGO=null where N_FACTURACOPAGO=@N_FACTURACOPAGO;
			
			update HPRE set VALORCOPAGO=b.VALORCOPAGO, VALORPCOMP=b.VALORPCOMP, VALOREXEDENTE=b.VALOREXCEDENTE
			from HPRE a
				cross apply (
					select VALORCOPAGO=sum(VALORCOPAGO), VALORPCOMP=sum(VALORPCOMP), VALOREXCEDENTE=sum(VALOREXCEDENTE) 
					from HPRED b with(nolock) where b.NOPRESTACION=a.NOPRESTACION
				) b
			where a.NOADMISION=@NOADMISION;

			update HADM set COPAGOVALOR=b.VALORCOPAGO
			from HADM a
				cross apply (
					select VALORCOPAGO=sum(VALORCOPAGO)
					from HPRE b with(nolock) where b.NOADMISION=a.NOADMISION
				) b
			where a.NOADMISION=@NOADMISION;

		end
		else
		if @PROCEDENCIA = 'CIT'
		begin
			-- obligado a usar vwc_Facturable_HADM_Todas para incluir admisiones con alta medica y no admin. No usar vwc_Facturable
			if (select count(*) from vwc_Facturable with(nolock) where N_FACTURACOPAGO=@N_FACTURACOPAGO and FACTURADA=1)>0
			begin
				raiserror('ERROR: Esta factura ya se esncuentra relacionada a servcios facturados a la aseguradora',16,1);
			end
			
			update CIT set VALORCOPAGO=0, VALORMODERADORA=0, VALOREXEDENTE=VALORTOTAL, N_FACTURACOPAGO=null where N_FACTURACOPAGO=@N_FACTURACOPAGO;
		end
		else
		if @PROCEDENCIA = 'CE'
		begin
			-- obligado a usar vwc_Facturable_HADM_Todas para incluir admisiones con alta medica y no admin. No usar vwc_Facturable
			if (select count(*) from vwc_Facturable with(nolock) where N_FACTURACOPAGO=@N_FACTURACOPAGO and FACTURADA=1)>0
			begin
				raiserror('ERROR: Esta factura ya se esncuentra relacionada a servcios facturados a la aseguradora',16,1);
			end

			update AUTD set VALORCOPAGO=0, VALOREXCEDENTE=CANTIDAD*VALOR, N_FACTURACOPAGO=null where N_FACTURACOPAGO=@N_FACTURACOPAGO;
			update AUT set VALORCOPAGO=b.VALORCOPAGO, VALOREXEDENTE=b.VALOREXCEDENTE
			from AUT a
				cross apply (
					select VALORCOPAGO=sum(VALORCOPAGO), VALOREXCEDENTE=sum(VALOREXCEDENTE) 
					from AUTD b with(nolock) where b.IDAUT=a.IDAUT
				) b
			where a.IDAUT=@NOADMISION;
		end

  		if @TranCounter = 0  -- Solo cuando la transaccion inició con este SP.  
		   commit transaction; 
	end try
	begin catch	
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;  						
		select   
			@ErrorMessage = coalesce(ERROR_MESSAGE(),'desconocido'),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE();

		if @TranCounter = 0  -- Solo cuando la transaccion inició con este SP.
			rollback transaction;  
		else  
			rollback transaction SaveTranc;
		raiserror(@ErrorMessage,@ErrorSeverity,@ErrorState);
	end catch      
end
go

CREATE PROCEDURE DBO.spc_FTR_GENERAR_FACTURA  
   @CNSFCT VARCHAR(40)  
AS  
begin
	declare 
		@Tabla_N_FACTURA table (N_FACTURA varchar(20), FCNSID bigint, ESTADO varchar(20), ERRORMSG varchar(max), FCNSCNS bigint);
	declare 
		@COMPANIA VARCHAR(2), @IDSEDE VARCHAR(5), @IDAREA VARCHAR(20), @EFACTURA smallint,
		@N_FACTURA VARCHAR(20), @FCNSID smallint, @ESTADO varchar(12), @ERRORMSG varchar(max), @PREFIJOFTR varchar(10), 
		@FCNSCNS bigint, @CNSFACTURA varchar(20), @GENERADA smallint, @DVENCE smallint, @F_FACTURA datetime;

	begin try
		begin transaction;
		select @COMPANIA=COMPANIA, @IDSEDE=IDSEDE, @IDAREA=IDAREA_FTR, @CNSFACTURA=N_FACTURA, @GENERADA=GENERADA,
			@DVENCE=datediff(day,F_FACTURA,F_VENCE)
		from FTR with(nolock) where CNSFCT=@CNSFCT

		if @@ROWCOUNT=0
		begin
			raiserror ('No se encontró el Documento con Consecutivo No. %s.',16,1,@CNSFCT);
		end

		if @GENERADA=1
		begin
			raiserror ('Otra sesión ha generada la Factura No. %s. para este registro.',16,1,@CNSFACTURA);
		end

		insert into @Tabla_N_FACTURA (N_FACTURA, FCNSID, ESTADO, ERRORMSG, FCNSCNS)
		EXEC dbo.SPC_GENNUMEROFACTURA_FCNS @COMPANIA, @IDSEDE, @IDAREA

		select @N_FACTURA=a.N_FACTURA, @FCNSID=a.FCNSID, @ESTADO=a.ESTADO, @ERRORMSG=a.ERRORMSG, 
			@FCNSCNS=a.FCNSCNS,	@EFACTURA=b.EFACTURA, @PREFIJOFTR=b.PREFIJO
		from @Tabla_N_FACTURA a
			join dbo.FCNS b with(NoLock) on a.FCNSID=b.FCNSID

		if @ESTADO='OK'
		begin
			select @F_FACTURA = cast(cast(getdate() as date) as datetime), @DVENCE=coalesce(@DVENCE,0);
			update FTR set N_FACTURA=@N_FACTURA, EFACTURA=@EFACTURA, PREFIJOFTR = @PREFIJOFTR,
				FCNSID=@FCNSID, FCNSCNS = @FCNSCNS, CUFE = '', PORENVIAR = 0, ERROR = 0, ERRORMSG = '', 
				IMPUTABLE = 0, GENERADA = 1, FECHAFAC=dbo.fnk_fecha_sin_mls(getdate()),
				F_FACTURA=@F_FACTURA, F_VENCE=@F_FACTURA + @DVENCE
			where CNSFCT=@CNSFCT

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

 
drop Trigger if exists [dbo].[tra_HPRED_U] 
go
Create Trigger [dbo].[tra_HPRED_U]  
on [dbo].[HPRED] for update  
as  
begin
	set xact_abort off;	-- Para poder manipular eventos de error(catch) en triggers que afecten transacciones encadenadas. si no se usa SQL generara el error 
						-- 3998: Se ha detectado una transacción no confirmable al final del lote. Se ha revertido la transacción.
	set nocount on;

	declare @TranCounter int;

	set @TranCounter = @@TRANCOUNT; -- Guarda el # de transacciones activas     
	
	begin try        
        
		if @TranCounter > 0          
			save transaction SaveTranc_tra_HPRED_U;  -- ya existe una transaccion activa   

		if not update (FACTURADA) and (select count(*) from deleted where FACTURADA=1)>0
			and not update(VALORCOPAGO) and not update(VALORPCOMP) and not update(VALOREXCEDENTE)
		begin
			raiserror('ERROR: Las prestaciones que intenta modificar se encuentran facturadas.',16,1)
			rollback
		end

		if update(IDCIRUGIA)
		begin
			update HPRED set IDCIRUGIA=null from inserted where hpred.HPREDID=inserted.HPREDID and hpred.IDCIRUGIA='' 
		end

		-- Valida que no se modifique el copago cuando ya se encuentra liquidado en los items de HPRED
		if update(VALORCOPAGO) or update(VALORPCOMP)
		begin
			if (select count(*) from inserted  where FACTURADA=1) > 0
			begin
				raiserror('No es posible liquidar copagos en las prestaciones porque tiene Items facturados.',16,1)
			end
		end
	end try
	begin catch
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;
       
		select     
			@ErrorMessage = coalesce(ERROR_MESSAGE(),'desconocido'),    
			@ErrorSeverity = ERROR_SEVERITY(),    
			@ErrorState = ERROR_STATE();  
      
		if @TranCounter = 0  -- En un trigger en valor mínimo es 1, cuando hay cero o una transacción abierta.
			rollback transaction;	-- en triggers nunca entra por acá
		else 
		begin
			-- ************ ADVERTENCIA con XACT_ABORT OFF ****************
			rollback transaction SaveTranc_tra_HPRED_U; 
			-- SET XACT_ABORT OFF: Tenga en cuenta cuando esté presente en el trigger, 
			--	modo OFF es requerido para poder manipular eventos de error(catch) en triggers que afecten transacciones encadenadas. si no se usa SQL generara el error
			--				3998: Se ha detectado una transacción no confirmable al final del lote. Se ha revertido la transacción.
			--
			-- 1. Cuidado, el rollback aquí presente, que es de la transacción guardada NO revierte cambios.
			-- 2. Ei el triggers se desencadenó dentro de un try catch sin una transacción previa, el catch revierte los cambios (rollback automático).
			-- 3. Si antes de desencadenar el trigger existe al menos una transacción abierta, el commit o rollback de esa transación serán los que afecten lo sucedido. 
			-- Ej. si al eliminar un registro de esta tabla usted no usa try catch o no inicia transacción, en caso de error la transacción quedará confirmada (commit).	   
		end
		raiserror(@ErrorMessage,16,1);  		
	end catch
end
go

drop Trigger if exists dbo.trc_HADM_U
go
Create Trigger dbo.trc_HADM_U
on dbo.HADM for Update
as
begin
	if update (KCNTID) or update (FECHA) or update (IDAREAINGRESO) or update (DXINGRESO) or update (IDTERCERO)
		or update (TIPOCONTRATO) or update (TIPOTTEC) or update (TIPOSISTEMA)
	begin
		update dbo.HADMV set FECHAINI=b.FECHA,IDTERCERO=b.IDTERCERO,KCNTID=b.KCNTID,IDAREA=b.IDAREAINGRESO,IDDX=b.DXINGRESO,
			TIPOCONTRATO=b.TIPOCONTRATO,TIPOTTEC=b.TIPOTTEC,TIPOSISTEMA=b.TIPOSISTEMA,USUARIO=b.USUARIO,FECHAREG=dbo.fnk_fecha_sin_mls(getdate()),
			SYS_COMPUTERNAME=host_name() 
		from dbo.HADMV a join inserted b on a.NOADMISION=B.NOADMISION AND a.TIPOREG=1
	end

	if update(FACTURADA) or update(N_FACTURA)
	begin
		update CIT set FACTURADA=b.FACTURADA, N_FACTURA=b.N_FACTURA
		from CIT a join inserted b on a.NOADMISION=b.NOADMISION 
			and a.PROCEDENCIA='AA' and b.CLASEING='M'
	end

	-- Valida que no se modifique el copago cuando ya se encuentra liquidado en los items de HPRED
	/*
	if update(COPAGOVALOR)
	begin
		if (
			select count(*)
			from dbo.vwc_Facturable_HADM_Todas a with (nolock)
				join inserted b on a.NOADMISION=b.NOADMISION
			where a.VALORCOPAGO>0 or a.FACTURADA=1
			) > 0
		begin
			raiserror('Ya no es posible fijar valor de copago en la admisión porque los items se encuentran con copagos liquidados o items facturados.',16,1)
		end
	end
	*/
end
go


drop VIEW [dbo].[VWK_TEADCON]
go
CREATE VIEW [dbo].[VWK_TEADCON]    
AS     
	SELECT a.NOADMISION, a.IDTERCEROCA, a.IDAFILIADO, b.RAZONSOCIAL, CERRADA=1, CAPITADO=a.CAPITA, FACTURABLE=1,     
		a.FACTURADA, a.TIPOTTEC,ERRORPRESTACIONES='', KCNTID=coalesce(a.KCNTID,0), a.NUMCONTRATO, a.TIPOCONTRATO, a.TIPOSISTEMA, N_FACTURA=coalesce(a.N_FACTURA,''),  
		VALORSERVICIOS=sum(a.VALOR),VALORCOPAGO=sum(a.VALORCOPAGO),VALORPCOMP=sum(a.VALORPCOMP),VALORMODERADORA=sum(a.VALORMODERADORA),DESCUENTO=sum(a.DESCUENTO),  
		VALORTOTAL=sum(a.VALOR-a.VALORCOPAGO-a.VALORPCOMP-a.VALORMODERADORA-a.DESCUENTO), N_FACTURACOPAGO = max(a.N_FACTURACOPAGO) 
	from dbo.vwc_Facturable_HADM_Todas a  
		left join TER b with (nolock) on a.IDTERCEROCA=b.IDTERCERO  
	WHERE a.CLASEING IN ('A','M')   
	group by a.NOADMISION, a.IDTERCEROCA, a.IDAFILIADO, b.RAZONSOCIAL, a.CAPITA,     
		a.FACTURADA, a.TIPOTTEC, a.KCNTID, a.NUMCONTRATO, a.TIPOCONTRATO, a.TIPOSISTEMA, coalesce(a.N_FACTURA,'')   
go

drop VIEW [dbo].[VWK_TEADSIN]  
go
CREATE VIEW [dbo].[VWK_TEADSIN]  
AS  
SELECT a.NOADMISION, a.IDTERCERO AS IDTERCEROCA, a.IDAFILIADO, b.RAZONSOCIAL, a.CERRADA,0 CAPITADO,a.FACTURABLE, 
	FACTURADA=0, a.TIPOTTEC, ERRORPRESTACIONES='Prestaciones sin Itemes', KCNTID=coalesce(a.KCNTID,0), c.NUMCONTRATO, a.TIPOCONTRATO, a.TIPOSISTEMA, a.N_FACTURA,
	VALORSERVICIOS=0, VALORCOPAGO=0, VALORPCOMP=0, VALORMODERADORA=0, DESCUENTO=0, VALORTOTAL=0, N_FACTURACOPAGO=cast(null as varchar(16))
FROM HADM a with (nolock)  
	INNER JOIN TER b with (nolock) ON b.IDTERCERO = a.IDTERCERO
	left join KCNT c with (nolock) ON a.KCNTID = c.KCNTID
WHERE a.CLASEING IN ('A','M') AND 
	(SELECT COUNT(*) 
	FROM HPRED with (nolock)
		join HPRE with (nolock) on HPRE.NOPRESTACION = HPRED.NOPRESTACION AND HPRE.NOADMISION = a.NOADMISION
	) = 0     
go

drop VIEW [dbo].[VWK_TERXHADM]  
go
CREATE VIEW [dbo].[VWK_TERXHADM]  
AS  
	SELECT NOADMISION, IDTERCEROCA, IDAFILIADO, RAZONSOCIAL, CERRADA, CAPITADO, FACTURABLE, FACTURADA, TIPOTTEC, ERRORPRESTACIONES,
		KCNTID,NUMCONTRATO,TIPOCONTRATO,TIPOSISTEMA,N_FACTURA,VALORSERVICIOS,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,VALORTOTAL,N_FACTURACOPAGO
	FROM VWK_TEADCON  
	UNION ALL  
	SELECT NOADMISION, IDTERCEROCA, IDAFILIADO, RAZONSOCIAL, CERRADA, CAPITADO, FACTURABLE, FACTURADA, TIPOTTEC, ERRORPRESTACIONES,
		KCNTID,NUMCONTRATO,TIPOCONTRATO,TIPOSISTEMA,N_FACTURA,VALORSERVICIOS,VALORCOPAGO,VALORPCOMP,VALORMODERADORA,DESCUENTO,VALORTOTAL,N_FACTURACOPAGO  
	FROM VWK_TEADSIN  
 
go


drop PROCEDURE if exists DBO.fnc_DistribuirCopago_xITEMS
go

drop PROCEDURE DBO.fnc_DistribuirCopago_xITEMS
go
/*
CREATE PROCEDURE DBO.fnc_DistribuirCopago_xITEMS
	@IDT varchar(20), 
	@VALORCOPAGO decimal(14,0) 
as
begin
	declare 
		@NOADMISION varchar(20), @NOPRESTACION varchar(20), @NOITEM smallint, @CIRUGIA varchar(2),
		@Total Decimal(14,0), @Ajuste decimal(14,0), @HPREDID bigint,
		@TranCounter int;

	-- Control de Transacciones  
	set @TranCounter = @@TRANCOUNT; -- Guarda el # de transacciones activas       
	
	begin try 

		if @TranCounter > 0    
			save transaction SaveTranc;
		else    
			begin transaction;  -- Nueva transaccion 

		select @Total=sum(coalesce(CANTIDAD,0)*coalesce(VALOR,0)) from HPRED with(nolock) 
		where IDT=@IDT and coalesce(FACTURADA,0)=0 and coalesce(FACTURABLE,0)=1 and coalesce(NOCOBRABLE,0)=0

		if @Total>0
		begin
			update HPRED set VALORCOPAGO = Round( (coalesce(CANTIDAD,0)*coalesce(VALOR,0)*@VALORCOPAGO)/@Total,0) 
			where IDT=@IDT and coalesce(FACTURADA,0)=0 and coalesce(FACTURABLE,0)=1 and coalesce(NOCOBRABLE,0)=0   

			select @Ajuste=@VALORCOPAGO-sum(coalesce(VALORCOPAGO,0)) from HPRED with(nolock) 
			where IDT=@IDT and coalesce(FACTURADA,0)=0 and coalesce(FACTURABLE,0)=1 and coalesce(NOCOBRABLE,0)=0
			if @Ajuste<>0
			begin
				select @HPREDID=max(a.HPREDID) from HPRED a with(nolock) 
				where IDT=@IDT and coalesce(FACTURADA,0)=0 and coalesce(FACTURABLE,0)=1 and coalesce(NOCOBRABLE,0)=0  
				update HPRED set VALORCOPAGO = coalesce(VALORCOPAGO,0) + @Ajuste where HPREDID=@HPREDID
			end

			update HPRED set VALOREXCEDENTE = (coalesce(VALOR,0)*coalesce(CANTIDAD,0))-coalesce(VALORCOPAGO,0)-coalesce(VALORPCOMP,0)
			where IDT=@IDT and coalesce(FACTURADA,0)=0 and coalesce(FACTURABLE,0)=1 and coalesce(NOCOBRABLE,0)=0;


			select top 1 @NOADMISION=NOADMISION from vwc_Facturable with(nolock) where IDT=@IDT;

			update HPRE set VALORCOPAGO=b.VALORCOPAGO, VALORPCOMP=b.VALORPCOMP, VALOREXEDENTE=b.VALOREXCEDENTE
			from HPRE a
				cross apply (
					select VALORCOPAGO=sum(VALORCOPAGO), VALORPCOMP=sum(VALORPCOMP), VALOREXCEDENTE=sum(VALOREXCEDENTE) 
					from HPRED b with(nolock) where b.NOPRESTACION=a.NOPRESTACION
				) b
			where a.NOADMISION=@NOADMISION;

			update HADM set COPAGOVALOR=b.VALORCOPAGO
			from HADM a
				cross apply (
					select VALORCOPAGO=sum(VALORCOPAGO)
					from HPRE b with(nolock) where b.NOADMISION=a.NOADMISION
				) b
			where a.NOADMISION=@NOADMISION;

			/*
			declare c1x cursor static for   
			select b.NOADMISION, a.NOPRESTACION, a.NOITEM, b.CIRUGIA 
			from HPRED a with(nolock) join HPRE b with(nolock) on a.NOPRESTACION=b.NOPRESTACION 
			where a.IDT=@IDT and a.FACTURADA=0
			open c1x
			fetch next from c1x into @NOADMISION, @NOPRESTACION, @NOITEM, @CIRUGIA 
			while @@FETCH_STATUS=0
			begin
				if @CIRUGIA = 'SI'
					EXEC dbo.SPK_COPAGOQX @NOADMISION, @NOPRESTACION, @NOITEM, 1
				else
					EXEC dbo.SPK_COPAGOQX @NOADMISION, @NOPRESTACION, @NOITEM, 0    	
				fetch next from c1x into @NOADMISION, @NOPRESTACION, @NOITEM, @CIRUGIA 
			end
			deallocate c1x
			*/
		end

  		if @TranCounter = 0  -- Solo cuando la transaccion inició con este SP.  
		   commit transaction; 
	end try
	begin catch	
		declare @ErrorMessage nvarchar(4000), @ErrorSeverity int, @ErrorState int;  						
		select   
			@ErrorMessage = coalesce(ERROR_MESSAGE(),'desconocido'),  
			@ErrorSeverity = ERROR_SEVERITY(),  
			@ErrorState = ERROR_STATE();

		if @TranCounter = 0  -- Solo cuando la transaccion inició con este SP.
			rollback transaction;  
		else  
			rollback transaction SaveTranc;
		raiserror(@ErrorMessage,@ErrorSeverity,@ErrorState);
	end catch      
end
go
*/


drop Trigger if exists trs_USPROH_EXTAPP_instead_of_iu;
go
/*
-- Desvio de los datos
Create Trigger trs_USPROH_EXTAPP_instead_of_iu  
on dbo.USPROH instead of insert,update  
as
	return;
go
*/
