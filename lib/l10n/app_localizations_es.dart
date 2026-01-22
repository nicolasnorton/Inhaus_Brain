// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get nodeStart => 'Inicio';

  @override
  String get nodeEnd => 'Fin';

  @override
  String get nodeFunction => 'Función';

  @override
  String get nodeParallel => 'Paralelo';

  @override
  String get nodeCondition => 'Condición';

  @override
  String get moduleClient => 'Cliente';

  @override
  String get moduleCampaign => 'Campaña';

  @override
  String get mockAIModels => 'Simular Modelos IA';

  @override
  String get mockAIModelsSubtitle => 'Usar respuestas simuladas para pruebas';

  @override
  String aiMockMode(Object status) {
    return 'Modo Simulación IA: $status';
  }

  @override
  String get loading => 'Loading...';

  @override
  String get connectedAccounts => 'Cuentas Conectadas';

  @override
  String get connected => 'Conectado';

  @override
  String get notConnected => 'No Conectado';

  @override
  String get disconnect => 'Desconectar';

  @override
  String accountDisconnected(Object account) {
    return 'Desconectado de $account';
  }

  @override
  String get connect => 'Conectar';

  @override
  String accountConnected(Object account) {
    return 'Conectado a $account';
  }

  @override
  String get nameHint => 'Ingresa tu nombre';

  @override
  String get nameEmptyError => 'El nombre no puede estar vacío';

  @override
  String get emailLabel => 'Correo electrónico';

  @override
  String get emailHint => 'Ingresa tu correo';

  @override
  String get emailInvalidError => 'Por favor ingresa un correo válido';

  @override
  String get emailChangeWarning =>
      'Nota: Cambiar el correo puede requerir voverificación';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get profileUpdated => 'Perfil actualizado exitosamente';

  @override
  String get displayLanguage => 'Idioma de visualización';

  @override
  String languageUpdated(Object language) {
    return 'Idioma cambiado a $language';
  }

  @override
  String get emailNotifications => 'Notificaciones por correo';

  @override
  String get emailNotificationsSubtitle =>
      'Recibir actualizaciones y alertas por correo';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get darkModeSubtitle => 'Usar tema oscuro para la aplicación';

  @override
  String get developerSettings => 'Ajustes de Desarrollador';

  @override
  String get settingsTitle => 'Ajustes Personales';

  @override
  String get settingsSubtitle => 'Gestiona tu perfil y preferencias';

  @override
  String get tabProfile => 'Perfil';

  @override
  String get tabPreferences => 'Preferencias';

  @override
  String get tabSecurity => 'Seguridad';

  @override
  String get profilePicture => 'Foto de Perfil';

  @override
  String get uploadNewPicture => 'Subir Nueva Foto';

  @override
  String get uploadComingSoon => 'Función de subida próximamente';

  @override
  String get navDashboard => 'Tablero';

  @override
  String get navClients => 'Clientes';

  @override
  String get navCampaigns => 'Campañas';

  @override
  String get navAnalytics => 'Analítica';

  @override
  String get navWorkflows => 'Flujos de trabajo';

  @override
  String get navPublish => 'Publicar';

  @override
  String get navKnowledge => 'Conocimiento';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get navDebug => 'Depuración';

  @override
  String welcomeBack(String name) {
    return 'Bienvenido de nuevo, $name';
  }

  @override
  String get readyForCampaign =>
      'Inhaus Brain está listo para tu próxima campaña.';

  @override
  String get quickAccess => 'Acceso Rápido';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String loggedInAs(String role) {
    return 'Sesión iniciada como $role';
  }

  @override
  String get campaignsTitle => 'Campañas';

  @override
  String get creativeStudio => 'Estudio Creativo';

  @override
  String get newCampaign => 'Nueva Campaña';

  @override
  String get noActiveCampaigns => 'No hay campañas activas';

  @override
  String get createNewCampaign => 'Crear nueva campaña';

  @override
  String get noClient => 'Sin cliente';

  @override
  String createdOn(String date) {
    return 'Creado: $date';
  }

  @override
  String get statusResearching => 'Investigando';

  @override
  String get statusDesigning => 'Diseñando';

  @override
  String get statusInProduction => 'En producción';

  @override
  String get statusPublished => 'Publicada';

  @override
  String get researchWorkshop => 'Taller de Investigación';

  @override
  String get campaignBrief => 'Resumen de Campaña';

  @override
  String get tellAgentGoals => 'Dile al Agente IA lo que quieres lograr.';

  @override
  String get campaignTitle => 'Título de la Campaña';

  @override
  String get campaignTitleHint => 'p.ej. Colección de Verano 2026';

  @override
  String get clientNameLabel => 'Nombre del Cliente';

  @override
  String get clientNameHint => 'p.ej. Acme Corp';

  @override
  String get detailedBrief => 'Resumen Detallado';

  @override
  String get detailedBriefHint =>
      'Describe objetivos, público objetivo y mensajes clave...';

  @override
  String get requiredField => 'Requerido';

  @override
  String get startResearchChat => 'Iniciar Chat de Investigación';

  @override
  String get confirmStrategyCreate => 'Confirmar Estrategia y Crear Campaña';

  @override
  String startNewCampaignMsg(String title, String description) {
    return 'Quiero empezar una nueva campaña: $title. Resumen: $description';
  }

  @override
  String get agentResearchInsights =>
      'Perspectivas de Investigación del Agente';

  @override
  String get reviewApproveInsights =>
      'Revisa y aprueba las perspectivas recopiladas por el Agente de Investigación.';

  @override
  String get proceedToDesignPlan => 'Proceder al Plan de Diseño';

  @override
  String get campaignStrategyBrief => 'Resumen de la Estrategia de Campaña';

  @override
  String get clientLabel => 'Cliente:';

  @override
  String get approve => 'Aprobar';

  @override
  String get designPhaseActive => 'Fase de Diseño Activa';

  @override
  String get creativeProposedDirections =>
      'El Agente Creativo ha propuesto direcciones visuales para esta campaña.';

  @override
  String get openCreativeStudio => 'Abrir Estudio Creativo';

  @override
  String get notAvailable => 'N/D';

  @override
  String get proposeNewConcept => 'Proponer Nuevo Concepto';

  @override
  String get noCreativeConceptsYet => 'Aún no hay conceptos creativos.';

  @override
  String get completeResearchApprovalMsg =>
      'Completa la aprobación de investigación de una campaña para activar al Agente de Diseño.';

  @override
  String get designFeedback => 'COMENTARIOS DE DISEÑO';

  @override
  String campaignIdLabel(String id) {
    return 'ID de Campaña: $id';
  }

  @override
  String get copyProposition => 'Propuesta de Copia';

  @override
  String get visualStrategyPrompt => 'Prompt de Estrategia Visual';

  @override
  String get finalProductionAssets => 'Activos de Producción Final';

  @override
  String get generateHighTierAssets => 'Generar Activos de Alto Nivel';

  @override
  String get finalHighFidelityCopy =>
      'Copia Final de Alta Fidelidad (Vertex AI)';

  @override
  String get finalVisualMock => 'Maqueta Visual Final (Imagen-3)';

  @override
  String get conceptApprovedReadyProduction =>
      'Concepto aprobado. Listo para producción de alta fidelidad.';

  @override
  String get styleBoards => 'Tableros de Estilo';

  @override
  String suggestedCount(int count) {
    return '$count Sugeridos';
  }

  @override
  String get clientModule => 'MÓDULO DE CLIENTES';

  @override
  String get portfolioManagement => 'Gestión de Portafolio';

  @override
  String get addClient => 'Añadir Cliente';

  @override
  String get noClientsConfigured => 'Aún no hay clientes configurados.';

  @override
  String get approved => 'Aprobado';

  @override
  String get approveInsight => 'Aprobar Insight';

  @override
  String get designConcept => 'CONCEPTO DE DISEÑO';

  @override
  String get campaignsCountLabel => 'CAMPAÑAS';

  @override
  String get manageClient => 'Gestionar Cliente';

  @override
  String get addNewClient => 'Añadir Nuevo Cliente';

  @override
  String get industryLabel => 'Industria';

  @override
  String get contactEmail => 'Correo de Contacto';

  @override
  String get cancel => 'Cancelar';

  @override
  String get primaryContactEmail => 'Correo de Contacto Principal';

  @override
  String get createClient => 'Crear Cliente';

  @override
  String get clientNotFound => 'Cliente No Encontrado';

  @override
  String get clientNotFoundMsg => 'No se pudo encontrar el cliente solicitado.';

  @override
  String get tabOverview => 'Resumen';

  @override
  String get tabContacts => 'Contactos';

  @override
  String get tabProjects => 'Proyectos';

  @override
  String get tabTasks => 'Tareas';

  @override
  String get tabIntegrations => 'Integraciones';

  @override
  String get tabUCP => 'Comercio UCP';

  @override
  String get tabReports => 'Reportes';

  @override
  String get noDescriptionAvailable => 'No hay descripción disponible.';

  @override
  String get industryLabelShort => 'Industria';

  @override
  String get sizeLabel => 'Tamaño';

  @override
  String get primaryContactLabel => 'Contacto Principal';

  @override
  String get performanceSummary => 'Resumen de Rendimiento';

  @override
  String get activeCampaigns => 'Campañas Activas';

  @override
  String get totalProjects => 'Proyectos Totales';

  @override
  String get clientContacts => 'Contactos del Cliente';

  @override
  String get addContact => 'Añadir Contacto';

  @override
  String get noContactsAdded => 'Aún no se han añadido contactos.';

  @override
  String get clientProjects => 'Proyectos del Cliente';

  @override
  String get newProject => 'Nuevo Proyecto';

  @override
  String get activeTasksLabel => 'Tareas Activas';

  @override
  String get newTask => 'Nueva Tarea';

  @override
  String get connectThirdPartyTools => 'Conectar Herramientas de Terceros';

  @override
  String get authorizeInhausBrainMsg =>
      'Autoriza a Inhaus Brain a acceder a los datos de estas plataformas.';

  @override
  String get ucpTitle => 'Protocolo de Comercio Universal (UCP)';

  @override
  String get ucpSubTitle => 'Integración fluida de comercio agéntico.';

  @override
  String get ucpStatusActive => 'Estado de UCP: Activo';

  @override
  String get discoveryServiceOnline => 'Servicio de Descubrimiento: En línea';

  @override
  String get discoverBusinesses => 'Descubrir Negocios';

  @override
  String get connectedCommerceAgents => 'Agentes de Comercio Conectados';

  @override
  String get addProject => 'Añadir Proyecto';

  @override
  String get projectName => 'Nombre del Proyecto';

  @override
  String get descriptionLabel => 'Descripción';

  @override
  String get createLabel => 'Crear';

  @override
  String get addTask => 'Añadir Tarea';

  @override
  String get taskTitle => 'Título de la Tarea';

  @override
  String get firstName => 'Nombre';

  @override
  String get lastName => 'Apellido';

  @override
  String get roleLabel => 'Rol';

  @override
  String get addLabel => 'Añadir';

  @override
  String get statusPlanning => 'Planificación';

  @override
  String get statusInProgress => 'En Progreso';

  @override
  String get statusCompleted => 'Completado';

  @override
  String get statusArchived => 'Archivado';

  @override
  String get statusTodo => 'Pendiente';

  @override
  String get statusDone => 'Hecho';

  @override
  String get projectNotFound => 'Proyecto No Encontrado';

  @override
  String get projectNotFoundMsg => 'No se pudo encontrar el proyecto.';

  @override
  String get switchToListView => 'Cambiar a vista de lista';

  @override
  String get switchToBoardView => 'Cambiar a vista de tablero';

  @override
  String get editTask => 'Editar Tarea';

  @override
  String get deleteLabel => 'Eliminar';

  @override
  String get saveLabel => 'Guardar';

  @override
  String get priorityLow => 'Baja';

  @override
  String get priorityMedium => 'Media';

  @override
  String get priorityHigh => 'Alta';

  @override
  String get priorityUrgent => 'Urgente';

  @override
  String get operationsCenter => 'Centro de Operaciones';

  @override
  String get secGeneral => 'General';

  @override
  String get secAgentBrain => 'Cerebro del Agente';

  @override
  String get secAIModels => 'Modelos de IA';

  @override
  String get secConnectors => 'Conectores';

  @override
  String get profileAccount => 'PERFIL Y CUENTA';

  @override
  String get profileAccountSub => 'Gestiona tu identidad y niveles de acceso.';

  @override
  String get agentBrainTitle => 'CEREBRO DEL AGENTE (PROMPTS MAESTROS)';

  @override
  String get agentBrainSub =>
      'Configura el comportamiento, la personalidad y los flujos de trabajo de tu fuerza laboral.';

  @override
  String get agentStudioTitle => 'Estudio del Agente';

  @override
  String get agentStudioSub =>
      'Accede al panel de configuración avanzada para ajustar los Prompts del Sistema, gestionar las conexiones de Pipelines y configurar herramientas para los agentes de Campaña y Creatividad.';

  @override
  String get launchAgentStudio => 'Lanzar Estudio del Agente';

  @override
  String get aiModelVaultTitle => 'VÓLVEDA DE MODELOS DE IA';

  @override
  String get aiModelVaultSub =>
      'Almacena de forma segura las claves API de proveedores externos. Las claves nunca salen de tu dispositivo.';

  @override
  String get saveKeysLabel => 'Guardar Claves';

  @override
  String get toolConnectorsTitle => 'CONECTORES DE HERRAMIENTAS';

  @override
  String get toolConnectorsSub =>
      'Integra servicios de terceros en tu flujo de trabajo.';

  @override
  String get teamAccessRoles => 'ACCESO Y ROLES DEL EQUIPO';

  @override
  String get systemRole => 'Rol del Sistema';

  @override
  String get assignedClients => 'Clientes Asignados';

  @override
  String get saveAccessLevels => 'Guardar Niveles de Acceso';

  @override
  String get keysSavedMsg => 'Claves guardadas de forma segura en la Bóveda.';

  @override
  String get promptsUpdatedMsg => 'Prompts Maestros actualizados.';

  @override
  String get profileUpdatedMsg => 'Perfil actualizado con éxito.';

  @override
  String get pleaseLoginManage =>
      'Por favor, inicia sesión para gestionar la configuración.';

  @override
  String get enterAgentInstructions =>
      'Ingresa las instrucciones del agente...';

  @override
  String get enterApiKey => 'Ingresa la clave API...';

  @override
  String get unnamedUser => 'Usuario sin nombre';

  @override
  String get noClientsFound => 'No se encontraron clientes.';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get workspaceInfrastructure =>
      'Infraestructura del Espacio de Trabajo';

  @override
  String get modelProviders => 'Proveedores de Modelos';

  @override
  String get modelProvidersSub =>
      'Configura las claves de LLM y generación de imágenes';

  @override
  String get pluginsTools => 'Complementos y Herramientas';

  @override
  String get pluginsToolsSub =>
      'Conecta herramientas externas y servidores MCP';

  @override
  String get manageApps => 'Gestionar Aplicaciones';

  @override
  String get manageAppsSub => 'Despliega y organiza tus micro-aplicaciones';

  @override
  String get analyticsMonitor => 'Analítica y Monitoreo';

  @override
  String get tabBusinessAnalytics => 'Analítica de Negocios';

  @override
  String get tabSystemMonitor => 'Monitor del Sistema';

  @override
  String get campaignPerformance => 'Rendimiento de la Campaña';

  @override
  String get conversionOverTime => 'Conversión a lo largo del tiempo';

  @override
  String get historicalDataAggregated => 'Datos históricos siendo agregados...';

  @override
  String get statROI => 'ROI';

  @override
  String get statConversion => 'Conversión';

  @override
  String get statCPA => 'CPA';

  @override
  String get monitorDashboard => 'Tablero de Monitoreo';

  @override
  String get statStatistics => 'Estadísticas';

  @override
  String get quickLogs => 'Logs Rápidos';

  @override
  String get viewAllLogs => 'Ver todos los logs';

  @override
  String get last7Days => 'Últimos 7 días';

  @override
  String get totalMessages => 'Total de Mensajes';

  @override
  String get activeUsers => 'Usuarios Activos';

  @override
  String get avgInteractions => 'Promedio de Interacciones';

  @override
  String get tokenUsage => 'Uso de Tokens';

  @override
  String get tracingAppPerformance => 'Rastreo de rendimiento de la aplicación';

  @override
  String get tracingIntegration => 'Integración de Rastreo';

  @override
  String get connectExternalTracingMsg =>
      'Conecta proveedores de rastreo externos para monitorear el rendimiento del agente.';

  @override
  String connectedToMsg(String name) {
    return 'Conectado a $name (Simulación)';
  }

  @override
  String get statConvVolume => 'Volumen de conversación';

  @override
  String get statMeaningfulExchange => '>1 intercambio significativo';

  @override
  String get statEngagementDepth => 'Profundidad de compromiso';

  @override
  String get statResourceConsumption => 'Consumo de recursos';

  @override
  String get knowledgeModule => 'CONOCIMIENTO';

  @override
  String get createKnowledge => 'Crear Conocimiento';

  @override
  String get quickCreate => 'Creación Rápida';

  @override
  String get knowledgePipeline => 'Pipeline de Conocimiento';

  @override
  String get authorizeDataSource => 'Autorizar Fuente de Datos';

  @override
  String get connectToExternal => 'Conectar a Externo';

  @override
  String get externalBase => 'Base Externa';

  @override
  String get apiReference => 'Referencia de API';

  @override
  String get manageKnowledge => 'Gestionar Conocimiento';

  @override
  String get contentLabel => 'Contenido';

  @override
  String get metadataLabel => 'Metadatos';

  @override
  String get testRetrieval => 'Probar Recuperación';

  @override
  String get integrateApps => 'Integrar en Aplicaciones';

  @override
  String get backLabel => 'Atrás';

  @override
  String get kbDocuments => 'Documentos';

  @override
  String get kbRetrievalTest => 'Prueba de Recuperación';

  @override
  String get knowledgeUsage => 'USO';

  @override
  String get kbCloud => 'NUBE';

  @override
  String kbUsedMsg(String used, String total) {
    return '$used / $total usados';
  }

  @override
  String get welcomeBackAuth => 'BIENVENIDO DE NUEVO';

  @override
  String get createAccountAuth => 'CREAR CUENTA';

  @override
  String get signInAccessConsole =>
      'Inicia sesión para acceder a la consola agéntica';

  @override
  String get joinEcosystem => 'Únete al ecosistema INHAUS';

  @override
  String get fullNameLabel => 'Nombre Completo';

  @override
  String get emailAddressLabel => 'Correo Electrónico';

  @override
  String get passwordLabel => 'Contraseña';

  @override
  String get signInLabel => 'INICIAR SESIÓN';

  @override
  String get registerLabel => 'REGISTRARSE';

  @override
  String get newAccountLabel => 'NUEVA CUENTA';

  @override
  String get existingUserLogin => '¿YA TIENES CUENTA? INICIA SESIÓN';

  @override
  String get googleLogin => 'INICIO CON GOOGLE';

  @override
  String get orLabel => 'O';

  @override
  String get basicInfo => 'INFORMACIÓN BÁSICA';

  @override
  String get knowledgeNameLabel => 'Nombre del conocimiento';

  @override
  String get enableHybridSearch => 'Activar búsqueda híbrida';

  @override
  String get metadataConfig => 'CONFIGURACIÓN DE METADATOS';

  @override
  String get autoExtractAuthor => 'Extraer autor automáticamente';

  @override
  String get autoExtractDate => 'Extraer fecha de publicación automáticamente';

  @override
  String get indexTablesAsText => 'Indexar tablas como texto';

  @override
  String get dangerZone => 'ZONA DE PELIGRO';

  @override
  String get deleteKnowledgeBase => 'Eliminar base de conocimientos';

  @override
  String get deleteKnowledgeBaseSub =>
      'Elimina permanentemente esta base de conocimientos y todos sus datos asociados.';

  @override
  String get knowledgeSettings => 'Configuración de Conocimiento';

  @override
  String get knowledgeSettingsSub =>
      'Administra la configuración, indexación y ajustes de recuperación de tu base de conocimientos.';

  @override
  String get statusActive => 'Activo';

  @override
  String get statusError => 'Error';

  @override
  String get externalKnowledgeTitle =>
      'Conectar a base de conocimiento externa';

  @override
  String get externalKnowledgeSub =>
      'Integra bases de conocimiento externas a través de servicios API o plugins oficiales.';

  @override
  String get apiConnections => 'Conexiones API';

  @override
  String get pluginMarketplace => 'Marketplace de Plugins';

  @override
  String get apiConnectionsSub =>
      'Configura endpoints API personalizados para conectar con tus bases de conocimiento propias o de terceros.';

  @override
  String get addApiConnection => 'Añadir conexión API';

  @override
  String get noConnectionsConfigured => 'No hay conexiones configuradas';

  @override
  String get addFirstConnection => 'Añade tu primera conexión';

  @override
  String get retrievalSandbox => 'Sandbox de recuperación';

  @override
  String get retrievalSandboxSub =>
      'Prueba tus ajustes de recuperación y visualiza los fragmentos brutos devueltos por la API.';

  @override
  String get selectConnection => 'Seleccionar conexión';

  @override
  String get chooseConnectionHint => 'Elige una conexión';

  @override
  String get queryLabel => 'Consulta';

  @override
  String get searchQueryHint => 'Introduce tu consulta de búsqueda...';

  @override
  String get searchLabel => 'Buscar';

  @override
  String get retrievalResults => 'Resultados de recuperación';

  @override
  String scoreLabel(String score) {
    return 'Puntuación: $score';
  }

  @override
  String lastSyncLabel(String time) {
    return 'Última sincronización: $time';
  }

  @override
  String get testingStatus => 'Probando...';

  @override
  String get disconnectedStatus => 'Desconectado';

  @override
  String get connectionSuccessful => '¡Conexión exitosa!';

  @override
  String get connectionFailed => 'La conexión falló. Revisa tus ajustes.';

  @override
  String get installedLabel => 'INSTALADO';

  @override
  String get configureLabel => 'Configurar';

  @override
  String get installLabel => 'Instalar';

  @override
  String get connectionNameLabel => 'Nombre de la conexión';

  @override
  String get connectionNameHint => 'ej. Mi Vector Store Personalizado';

  @override
  String get apiEndpointLabel => 'Endpoint de la API';

  @override
  String get knowledgeIdOptional => 'ID de conocimiento (Opcional)';

  @override
  String get internalRefId => 'ID de referencia interna';

  @override
  String get apiKeyLabel => 'Clave API';

  @override
  String get apiRequirements => 'Requisitos de la API';

  @override
  String get apiRequirementsSub =>
      'Tu API debe aceptar peticiones POST con un parámetro de consulta y devolver resultados en formato JSON con contenido de texto.';

  @override
  String get testSave => 'Probar y Guardar';

  @override
  String configurePlugin(String plugin) {
    return 'Configurar $plugin';
  }

  @override
  String apiKeyOptionalHint(String label) {
    return 'Opcional: Especifica un $label';
  }

  @override
  String get needApiKey => '¿Necesitas una clave API?';

  @override
  String visitPluginHub(String url) {
    return 'Visita $url para crear una';
  }

  @override
  String get saveConfiguration => 'Guardar configuración';

  @override
  String get justNow => 'Justo ahora';

  @override
  String minutesAgo(int count) {
    return 'hace ${count}m';
  }

  @override
  String hoursAgo(int count) {
    return 'hace ${count}h';
  }

  @override
  String daysAgo(int count) {
    return 'hace ${count}d';
  }

  @override
  String get dataSourceStep => 'FUENTE DE DATOS';

  @override
  String get processingStep => 'PROCESAMIENTO DE DOCUMENTOS';

  @override
  String get executeFinishStep => 'EJECUTAR Y FINALIZAR';

  @override
  String get selectDataSource => 'Seleccionar fuente de datos';

  @override
  String get dataSourceChangeWarning =>
      'Una vez creada una base de conocimientos, su fuente de datos no se puede cambiar más tarde.';

  @override
  String get importFromFile => 'Importar desde archivo';

  @override
  String get syncFromNotion => 'Sincronizar desde Notion';

  @override
  String get syncFromWebsite => 'Sincronizar desde sitio web';

  @override
  String get chunkSettings => 'Ajustes de fragmentación';

  @override
  String get chunkSettingsSub =>
      'Configura cómo se segmentarán y limpiarán tus datos antes de la indexación.';

  @override
  String get chunkingMode => 'MODO DE FRAGMENTACIÓN';

  @override
  String get automatic => 'Automático';

  @override
  String get custom => 'Personalizado';

  @override
  String get chunkingRules => 'REGLAS DE FRAGMENTACIÓN';

  @override
  String get separator => 'Separador';

  @override
  String get maxChunkLength => 'Longitud máxima del fragmento';

  @override
  String get chunkOverlap => 'Superposición de fragmentos';

  @override
  String get cleaningRules => 'REGLAS DE LIMPIEZA';

  @override
  String get cleanSpacesRule =>
      'Reemplazar espacios, saltos de línea y tabulaciones consecutivos';

  @override
  String get cleanUrlsRule =>
      'Eliminar todas las URL y direcciones de correo electrónico';

  @override
  String get chunksPreview => 'VISTA PREVIA DE FRAGMENTOS';

  @override
  String chunksIdentified(int count) {
    return '$count fragmentos identificados';
  }

  @override
  String get indexRetrievalTitle => 'Indexación y recuperación';

  @override
  String get indexRetrievalSub =>
      'Define cómo se indexará y recuperará tu conocimiento para la mejor precisión.';

  @override
  String get indexMethod => 'MÉTODO DE INDEXACIÓN';

  @override
  String get highQuality => 'Alta calidad';

  @override
  String get highQualitySub =>
      'Modelo de embedding y soporte de búsqueda híbrida.';

  @override
  String get economical => 'Económico';

  @override
  String get economicalSub => 'Sin consumo de tokens, solo palabras clave.';

  @override
  String get embeddingModel => 'MODELO DE EMBEDDING';

  @override
  String get retrievalSettings => 'AJUSTES DE RECUPERACIÓN';

  @override
  String get rerankSettings => 'AJUSTES DE RE-RANKING';

  @override
  String get rerankModel => 'Modelo de Re-ranking';

  @override
  String get topK => 'Top K';

  @override
  String get scoreThreshold => 'Umbral de puntuación';

  @override
  String get finishLabel => 'Finalizar';

  @override
  String get nextLabel => 'Siguiente';

  @override
  String get knowledgeBases => 'BASES DE CONOCIMIENTO';

  @override
  String get noKnowledgeBases => 'No hay bases de conocimiento';

  @override
  String get createDatasetMsg =>
      'Crea un nuevo conjunto de datos para empezar.';

  @override
  String get documentsLabel => 'DOCUMENTOS';

  @override
  String get noDocuments => 'No hay documentos';

  @override
  String get uploadFilesMsg =>
      'Sube archivos o añade texto a esta base de conocimientos.';

  @override
  String itemsSelected(int count) {
    return '$count elementos seleccionados';
  }

  @override
  String get deleteDocuments => 'Eliminar documentos';

  @override
  String deleteDocumentsConfirm(int count) {
    return '¿Estás seguro de que quieres eliminar $count documentos?';
  }

  @override
  String get documentsDeleted => 'Documentos eliminados';

  @override
  String get pasteUrlHint => 'Pegar URL...';

  @override
  String get addLinkLabel => 'Añadir enlace';

  @override
  String get uploadLabel => 'Subir';

  @override
  String get imageLabel => 'Imagen';

  @override
  String get driveLabel => 'Drive';

  @override
  String get googleDriveIntegration => 'Integración con Google Drive';

  @override
  String get driveIntegrationComingSoon =>
      'La integración directa con Google Drive estará disponible pronto. Por ahora, descarga tus archivos y súbelos manualmente.';

  @override
  String get gotIt => 'Entendido';

  @override
  String kbStats(int docCount, int wordCount) {
    return '$docCount Documentos • $wordCount Palabras';
  }

  @override
  String tokensWords(int tokens, int wordCount) {
    return '$tokens Tokens • $wordCount Palabras';
  }

  @override
  String get analyzeVisionAgent => 'Analizar con Agente de Visión';

  @override
  String analyzeVisualAsset(String title) {
    return 'Analizar este activo visual: $title';
  }
}
