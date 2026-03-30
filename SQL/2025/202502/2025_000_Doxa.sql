-- *************** OJO cambios tablas DOXA *************************************
use Dxzf
use DxContable
go

-- Artículos Medicamentos  (CRUD)

ALTER TABLE IART ADD CODIUM VARCHAR(20) NULL; -- TablaReferencia_IUM__1.csv
go
-- ALTER TABLE IART ADD CODCUM VARCHAR(20) NULL;
go
ALTER TABLE IART ADD CODINVIMA VARCHAR(20) NULL;
go
ALTER TABLE IART ADD CODUPR VARCHAR(20) NULL -- TablaReferencia_UPR__1.csv
go
ALTER TABLE IART ADD CODR2CCN VARCHAR(5) NULL -- TablaReferencia_UPR__1.csv
go
ALTER TABLE IART ADD CODR2UNI VARCHAR(5) NULL -- TablaReferencia_UPR__1.csv
go
ALTER TABLE IART ADD CODR2FFA VARCHAR(10) NULL -- TablaReferencia_UPR__1.csv
go
-- 17.JUN.2024 FDIAZP ES
ALTER TABLE IGEN ADD CODDCI VARCHAR(20) NULL; -- TablaReferencia_DCI__1.csv
GO
-- *****************************************************************************
