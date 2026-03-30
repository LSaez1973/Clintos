
IF SCHEMA_ID('cweb') IS NULL 
	EXECUTE('CREATE SCHEMA [cweb];');
GO

CREATE  TABLE cweb.USLAN ( 
	CODLAN               varchar(20)      NOT NULL,
	NOMBRE               varchar(60)      NULL,
	IDPAIS               varchar(5)      NULL,
	CODLANISO2           varchar(20)      NULL,
	CONSTRAINT pk_USLAN PRIMARY KEY  CLUSTERED ( CODLAN  asc ) 
 );
GO

CREATE  TABLE cweb.USMOD ( 
	CODMOD               varchar(20)      NOT NULL,
	NOMBRE               varchar(60)      NULL,
	PREFIJO              varchar(6)      NULL,
	CONSTRAINT pk_USMOD PRIMARY KEY  CLUSTERED ( CODMOD  asc ) 
 );
GO

CREATE  TABLE cweb.USMSG ( 
	USMSGID              int    IDENTITY  NOT NULL,
	CODMOD               varchar(20)      NOT NULL,
	CODMSG               int      NOT NULL,
	CODLAN               varchar(20)      NOT NULL,
	MENSAJE              varchar(512)      NOT NULL,
	TEXTOAYUDA           varchar(max)      NULL,
	SEVERITY             varchar(1)      NOT NULL,
	CONSTRAINT pk_USMSG PRIMARY KEY  CLUSTERED ( USMSGID  asc ) 
 );
GO

CREATE UNIQUE  NONCLUSTERED INDEX idx_USMSG_CODMOD_CODMSG_CODLAN ON cweb.USMSG ( CODMOD  asc, CODMSG  asc, CODLAN  asc );
GO

CREATE  TABLE cweb.USMSGL ( 
	USMSGLID             int    IDENTITY  NOT NULL,
	USMSGID              int      NOT NULL,
	CODLAN               varchar(20)      NOT NULL,
	MENSAJE              varchar(512)      NOT NULL,
	TEXTOAYUDA           varchar(max)      NULL,
	CONSTRAINT pk_USMSGL PRIMARY KEY  CLUSTERED ( USMSGLID  asc ) 
 );
GO

CREATE UNIQUE  NONCLUSTERED INDEX idx_USMSGL_USMSGLID_CODLAN ON cweb.USMSGL ( USMSGLID  asc, CODLAN );
GO

ALTER TABLE cweb.USMSG ADD CONSTRAINT fk_USMSG_USMOD FOREIGN KEY ( CODMOD ) REFERENCES cweb.USMOD( CODMOD ) ON UPDATE CASCADE;
GO

ALTER TABLE cweb.USMSG ADD CONSTRAINT fk_USMSG_USLAN FOREIGN KEY ( CODLAN ) REFERENCES cweb.USLAN( CODLAN ) ON UPDATE CASCADE;
GO

ALTER TABLE cweb.USMSGL ADD CONSTRAINT fk_USMSGL_USMSG FOREIGN KEY ( USMSGID ) REFERENCES cweb.USMSG( USMSGID ) ON UPDATE CASCADE;
GO

ALTER TABLE cweb.USMSGL ADD CONSTRAINT fk_USMSGL_USLAN FOREIGN KEY ( CODLAN ) REFERENCES cweb.USLAN( CODLAN );
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Lenguajes con códgos internacionales' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USLAN';;
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Código ISO1' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USLAN', @level2type=N'COLUMN',@level2name=N'CODLAN';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Nombre' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USLAN', @level2type=N'COLUMN',@level2name=N'NOMBRE';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Códido del ID del páis referenciado a la tabla PAIS' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USLAN', @level2type=N'COLUMN',@level2name=N'IDPAIS';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Código ISO 2/3 del lenguaje' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USLAN', @level2type=N'COLUMN',@level2name=N'CODLANISO2';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Tabla de módulos' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMOD';;
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Código del modulo (pkey)' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMOD', @level2type=N'COLUMN',@level2name=N'CODMOD';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Nombre' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMOD', @level2type=N'COLUMN',@level2name=N'NOMBRE';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Prefijo para uso alternativo' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMOD', @level2type=N'COLUMN',@level2name=N'PREFIJO';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Mensajes de aplicación' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSG';;
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'ID del mensaje (pkey)' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSG', @level2type=N'COLUMN',@level2name=N'USMSGID';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Código del módulo' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSG', @level2type=N'COLUMN',@level2name=N'CODMOD';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Consecutivo del mensaje' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSG', @level2type=N'COLUMN',@level2name=N'CODMSG';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Código del lenguaje usado' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSG', @level2type=N'COLUMN',@level2name=N'CODLAN';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Mensaje, tendrian un comodin {{IDAFILIADO}}' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSG', @level2type=N'COLUMN',@level2name=N'MENSAJE';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Texto extendido' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSG', @level2type=N'COLUMN',@level2name=N'TEXTOAYUDA';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Severidad:  T: Toast, I: Informacion, W:Warning, E:Error, S:Stop' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSG', @level2type=N'COLUMN',@level2name=N'SEVERITY';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Mensaje en otros idiomas' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSGL';;
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'ID del registro (pkey)' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSGL', @level2type=N'COLUMN',@level2name=N'USMSGLID';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'ID Mensaje' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSGL', @level2type=N'COLUMN',@level2name=N'USMSGID';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Código del lenguaje' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSGL', @level2type=N'COLUMN',@level2name=N'CODLAN';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Mensaje' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSGL', @level2type=N'COLUMN',@level2name=N'MENSAJE';
GO

execute sys.sp_addextendedproperty  @name=N'MS_Description', @value=N'Texto extendido' , @level0type=N'SCHEMA',@level0name=N'cweb', @level1type=N'TABLE',@level1name=N'USMSGL', @level2type=N'COLUMN',@level2name=N'TEXTOAYUDA';
GO


-- El código del lenguaje será ISO1 ej. es, us
-- Los Códigos de los mensajes serán un consecutivo numérico que será formateado al momento de su presentación 
-- Los mensajes tendrán el formato PREFIJO_SEVERITY_CODMSG_CODLAN El. mensaje de warning 444 desde el modulo Consulta externa: CE_W_0444_ES

-- Dentro de cada comodin irá una variable que será remplzada en un parámetros de 
-- tipo JSON donde cada key hace referencia a la misma {"var1":"dato1", "var2":"dato2"}

/*
-- ============================================================================
    Observaciones
-- ============================================================================

1. Estandarización de códigos
Usar esquema consistente para los códigos de error, como prefijos por módulo o tipo (Ej. ADMN_001, LAB_404, AUTH_501). 
Esto ayuda en depuración y categorización sin ambigüedades.

2. Usar comodines en el mensaje de error, EJ. PACIENTE {{IDAFILIADO-NOMPACIENTE}} NO ENCONTRADO
Esto permirte reutilizar mensajes y personalizarlos desde backend o frontend.

3. Uso de código de lenguaje para uso futuro al tener la APP en múltiples idiomas

*/
