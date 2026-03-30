/*
-- ----------------------------------------------------------------------------
Estructura json
usuario 
	[serviciosTecnologias]
		[consultas]
		[procedimientos]
		[urgencias]
		[hospitalizaciones]
		[recienNacidos]
		[otrosServicios]
		[medicamentos]

where R2SECCION = 1 --consultas
where R2SECCION = 2 --medicamentos
where R2SECCION = 3 --procedimientos
where R2SECCION = 4 --urgencias
where R2SECCION = 5 --hospitalizaciones
where R2SECCION = 6 --recienNacidos
where R2SECCION = 7 --otrosServicios

select top 10 * from R2SISPRO

Selects de cada sección
-- ----------------------------------------------------------------------------
*/

-- ----------------------------------------------------------------------------
--	usuarios
-- ----------------------------------------------------------------------------

select TOP 10 
TIPO_DOC TipoDocumentoldentificacion,
DOCIDAFILIADO NumDocumentoldentificacion,
TIPOAFILIADO tipoUsuario,
FNACIMIENTO fechaNacimiento,
left(SEXO,1) codSexo,
AFI.IDPAISRES codPaisResidencia,
DEP.DPTO codMunicipioResidencia,
AFI.ZONA codZonaTerritorialResidencia,
AFI.INCAPACIDADLABORAL incapacidad,
1 consecutivo, --n�mero consecutivo que identifique el registro de 1 a 7 d�gitos (rowcount)
AFI.IDPAISORI codPaisOrigen
from AFI
join CIU ON CIU.CIUDAD = AFI.CIUDAD
LEFT join CIU C2 ON C2.CIUDAD = AFI.CIUDAD
LEFT JOIN DEP ON DEP.DPTO = CIU.DPTO
LEFT JOIN DEP D2 ON D2.DPTO = C2.DPTO
go

-- ----------------------------------------------------------------------------
--	consultas
-- ----------------------------------------------------------------------------
select TOP 10 'Consultas',
'' codPrestador,
CIT.FECHA fechalnicioAtencion,
CIT.NOAUTORIZACION numAutorizacion,
SER.IDSERVICIOCUPS codConsulta,
AFU.R2AMBITO modalidadGrupoServicioTecSal,
AFU.R2CODGRUPOSER grupoServicios,
SER.IDSERVICIOCUPS codServicio,
CIT.FINCONSULTA finalidadTecnologiaSalud,
CIT.IDCAUSAEXT causaMotivoAtencion,
HCA.IDDX codDiagnosticoPrincipal,
HCA.DX1 codDiagnosticoRelacionado1,
HCA.DX2 codDiagnosticoRelacionado2,
HCA.DX3 codDiagnosticoRelacionado3,
HCA.TIPODX tipoDiagnosticoPrincipal,
AFI.TIPO_DOC tipoDocumentoldentificacion,
AFI.DOCIDAFILIADO numDocumentoldentificacion,
CIT.VALORTOTAL vrServicio,
CIT.TIPOCOPAGO tipoPagoModerador,
CIT.VALORCOPAGO valorPagoModerador,
CIT.N_FACTURACOPAGO numFEVPagoModerador,
1 consecutivo --n�mero consecutivo que identifique el registro de 1 a 7 d�gitos (rowcount)
from CIT
JOIN AFI ON AFI.IDAFILIADO = CIT.IDAFILIADO
JOIN SER ON SER.IDSERVICIO = CIT.IDSERVICIO
LEFT JOIN HCA ON HCA.CNSCITA = CIT.CONSECUTIVO
LEFT JOIN AFU ON AFU.IDAREA = CIT.IDAREA
where SER.R2SECCION = 1 --consultas


-- ----------------------------------------------------------------------------
--	procedimientos
-- ----------------------------------------------------------------------------

SELECT TOP 10
'procedimientos' seccion,
'' codPrestador,
HPRE.FECHA fechalnicioAtencion,
HPRED.CODMIPRES idMIPRES,
HPRED.NOAUTORIZACION numAutorizacion,
SER.IDSERVICIOCUPS codProcedimiento,
HADM.VIAINGRESO viaIngresoServicioSalud,
AFU.R2MODATENCION modalidadGrupoServicioTecSal,
AFU.R2CODGRUPOSER grupoServicios,
SER.R2CODSERVICIO codServicio,
HCA.FINALIDAD finalidadTecnologiaSalud,
AFI.TIPO_DOC tipoDocumentoIdentificacion,
AFI.DOCIDAFILIADO numDocumentoIdentificacion,
HCA.IDDX codDiagnosticoPrincipal,
HCA.DX1 codDiagnosticoRelacionado,
HADM.COMPLICACION codComplicacion,
cast(ROUND (HPRED.VALOR ,0,1) as int) vrServicio,
HPRE.TIPOCOPAGO tipoPagoModerador,
cast(ROUND (HPRED.VALORCOPAGO ,0,1) as int) valorPagoModerador,
HPRE.N_FACTURACOP numFEVPagoModerador,
1 consecutivo --n�mero consecutivo que identifique el registro de 1 a 7 d�gitos (rowcount)
from HPRED
JOIN HPRE ON HPRE.NOPRESTACION = HPRED.NOPRESTACION
JOIN HADM ON HADM.NOADMISION = HPRE.NOADMISION
JOIN AFI ON AFI.IDAFILIADO = HADM.IDAFILIADO
JOIN SER ON SER.IDSERVICIO = HPRED.IDSERVICIO
LEFT JOIN HCA ON HCA.NOADMISION = HADM.NOADMISION
LEFT JOIN AFU ON AFU.IDAREA = HPRE.IDAREA
where SER.R2SECCION = 3 --procedimientos




-- ----------------------------------------------------------------------------
--	urgencias
-- ----------------------------------------------------------------------------
SELECT TOP 10
'urgencias' seccion,
'' codPrestador,
HADM.FECHA  fechaInicioAtencion,
HADM.CAUSAEXTERNA causaMotivoAtencion,
HADM.DXINGRESO codDiagnosticoPrincipal,
HADM.DXEGRESO codDiagnosticoPrincipalE,
HADM.DXSALIDA1 codDiagnosticoPrincipalE1,
HADM.DXSALIDA2 codDiagnosticoPrincipalE2,
HADM.DXSALIDA3 codDiagnosticoPrincipalE3,
HADM.DESTINO condicionDestinoUsuarioEgreso,
HADM.CAUSABMUERTE codDiagnosticoCausaMuerte,
HADM.FECHAALTA fechaEgreso,
1 consecutivo --n�mero consecutivo que identifique el registro de 1 a 7 d�gitos (rowcount)
from 
HADM
JOIN AFI ON AFI.IDAFILIADO = HADM.IDAFILIADO
JOIN HTAD ON HTAD.TIPOADM = HADM.TIPOADM
LEFT JOIN AFU ON AFU.IDAREA = HADM.IDAREA_ALTA
WHERE HADM.CLASEING = 'A' AND COALESCE(HADM.CLASENOPROC,'NP') <> 'NP' AND HTAD.RIPS_AH_AU = 1 AND
HADM.IDAREAINGRESO = dbo.FNK_VALORVARIABLE('IDAREAURGENCIA') and DATEDIFF(HOUR,HADM.FECHA,HADM.FECHASALIDA) <= 8

-- ----------------------------------------------------------------------------
--	hospitalizaciones
-- ----------------------------------------------------------------------------
SELECT TOP 10
'hospitalizaciones' seccion,
'' codPrestador,
HADM.VIAINGRESO viaIngresoServicioSalud,
HADM.FECHA fechaInicioAtencion,
HADM.NOAUTORIZACION numAutorizacion,
HADM.CAUSAEXTERNA causaMotivoAtencion,
HADM.DXINGRESO codDiagnosticoPrincipal,
HADM.DXEGRESO codDiagnosticoPrincipalE,
HADM.DXSALIDA1 codDiagnosticoPrincipalE1,
HADM.DXSALIDA2 codDiagnosticoPrincipalE2,
HADM.DXSALIDA3 codDiagnosticoPrincipalE3,
HADM.COMPLICACION codComplicacion,
HADM.DESTINO CondicionyDestinoUsuarioEgreso,
HADM.CAUSABMUERTE codDiagnosticoCausaMuerte,
HADM.FECHASALIDA fechaEgreso,
1 consecutivo --n�mero consecutivo que identifique el registro de 1 a 7 d�gitos (rowcount)
from 
HADM
JOIN AFI ON AFI.IDAFILIADO = HADM.IDAFILIADO
JOIN HTAD ON HTAD.TIPOADM = HADM.TIPOADM
LEFT JOIN AFU ON AFU.IDAREA = HADM.IDAREA_ALTA
WHERE HADM.CLASEING = 'A' AND COALESCE(HADM.CLASENOPROC,'NP') <> 'NP' AND HTAD.RIPS_AH_AU = 1


-- ----------------------------------------------------------------------------
--	recienNacidos
-- ----------------------------------------------------------------------------
SELECT TOP 10
'recienNacidos' seccion,
'' codPrestador,
AFI.TIPO_DOC TipoDocumentoldentificacion,
AFI.DOCIDAFILIADO NumDocumentoldentificacion,
AFI.FNACIMIENTO fechaNacimiento,
HADM.EDADGEST edadGestacional,
1 numConsultasCPrenatal,
LEFT(AFI.SEXO,1) codSexoBiologico,
HADM.PESONACER peso,
HADM.DXEGRESO codDiagnosticoPrincipal,
HADM.DESTINO condicionDestinoUsuarioEgreso,
HADM.CAUSABMUERTE codDiagnosficoCausaMuerte,
IIF(HADM.CAUSABMUERTE IS NOT NULL,HADM.FECHAMUERTE,HADM.FECHAALTA) fechaEgreso,
1 consecutivo
from 
HADM
JOIN AFI ON AFI.IDAFILIADO = HADM.IDAFILIADO
WHERE HADM.CLASEING = 'A' AND COALESCE(HADM.CLASENOPROC,'NP') <> 'NP' AND AFI.NACIMIENTO = 1
GO

-- ----------------------------------------------------------------------------
--	medicamentos VERIFICAR! pues con el cambio de inventarios hay que tener en 
-- 	cuenta las entregas x Doxa
-- ----------------------------------------------------------------------------

SELECT TOP 10
'medicamentos' seccion,
'' codPrestador,
HPRED.NOAUTORIZACION numAutorizacion,
HPRED.CODMIPRES idMIPRES,
HPRE.FECHA fechaDispensAdmon,
HCA.IDDX codDiagnosticoPrincipal,
HCA.DX1 codDiagnosticoRelacionado,
SER.R2TIPOMEDPOS tipoMedicamento,
iif(IART.CODIUM is not null,IART.CODIUM,IART.CODCUM) codTecnologiaSalud, -- colocar IART.CODIUM sino se tiene IART.CODCUM
IGEN.CODDCI nomTecnologiaSalud, --solo para preparaci�n magistral se toma descripci�n del IART.IDDCI
IART.CODR2CCN concentracionMedicamento,
IART.CODR2UNI unidadMedida,
IART.CODR2FFA formaFarmaceutica,
IART.CODUPR unidadMinDispensa,
cast(HPRED.CANTIDAD as int) cantidadMedicamento,
1 diasTratamiento, --n�mero de d�as redondeado al entero m�s alto *****************
TER.TIPO_ID tipoDocumentoldentificacion, -- Tipo documento del Medico en la tabla de terceros
TER.NIT numDocumentoldentificacion, -- n�mero documento del Medico en la tabla de terceros
CAST(HPRED.VALOR AS INT) vrUnitMedicamento, -- Valor unitario x unidad m�nima de dispensaci�n UPR si es x evento en las dem�s reportar 0
CAST(HPRED.CANTIDAD * HPRED.VALOR AS INT) vrServicio,-- Valor total medicamento dispensado si es x evento en las dem�s reportar 0
HPRE.TIPOCOPAGO tipoPagoModerador,
HPRED.VALORCOPAGO valorPagoModerador,
HPRE.N_FACTURACOP numFEVPagoModerador,
1 consecutivo
from HPRED
JOIN HPRE ON HPRE.NOPRESTACION = HPRED.NOPRESTACION
JOIN HADM ON HADM.NOADMISION = HPRE.NOADMISION
JOIN MED ON MED.IDMEDICO = HPRE.IDMEDICO
JOIN SER ON SER.IDSERVICIO = HPRED.IDSERVICIO
LEFT JOIN IART ON IART.IDARTICULO = SER.IDARTICULO
LEFT JOIN IGEN ON IGEN.IDGENERICO = IART.IDGENERICO
LEFT JOIN TER ON TER.IDTERCERO = MED.IDTERCERO
left join HCA ON HCA.NOADMISION = HPRE.NOADMISION
where R2SECCION = 2 --medicamentos

-- ----------------------------------------------------------------------------
--	otrosServicios
-- ----------------------------------------------------------------------------

SELECT TOP 10
'otrosServicios' seccion,
'' codPrestador,
HPRED.NOAUTORIZACION numAutorizacion,
HPRED.CODMIPRES idMIPRES,
HPRE.FECHA fechaSuministroTecnologia,
SER.R2OTROSSER tipoOS,
SER.IDSERVICIOCUPS codTecnologiaSalud,
DESCSERVICIOCUPS nomTecnologiaSalud,
cast(ROUND (HPRED.CANTIDAD ,0,1) as int) cantidadOS,
TER.TIPO_ID tipoDocumentoldentificacion, -- Tipo documento del Medico en la tabla de terceros
TER.NIT numDocumentoldentificacion, -- n�mero documento del Medico en la tabla de terceros
CAST(HPRED.VALOR AS INT) vrUnitOS,
CAST(HPRED.CANTIDAD * HPRED.VALOR AS INT) vrServicio,
HPRE.TIPOCOPAGO tipoPagoModerador,
HPRED.VALORCOPAGO valorPagoModerador,
HPRE.N_FACTURACOP numFEVPagoModerador,
1 consecutivo --n�mero consecutivo que identifique el registro de 1 a 7 d�gitos (rowcount)
from HPRED
JOIN HPRE ON HPRE.NOPRESTACION = HPRED.NOPRESTACION
JOIN HADM ON HADM.NOADMISION = HPRE.NOADMISION
JOIN MED ON MED.IDMEDICO = HPRE.IDMEDICO
LEFT JOIN TER ON TER.IDTERCERO = MED.IDTERCERO
left join HCA ON HCA.NOADMISION = HPRE.NOADMISION
JOIN SER ON SER.IDSERVICIO = HPRED.IDSERVICIO
where SER.R2SECCION = 7 --otrosServicios

