// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Inhaus Brain';

  @override
  String get settingsTitle => 'Configuración Personal';

  @override
  String get settingsSubtitle =>
      'Gestiona tu perfil y preferencias en todos tus espacios de trabajo';

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
  String get uploadComingSoon =>
      'La carga de avatares estará disponible pronto';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get nameHint => 'Introduce tu nombre';

  @override
  String get nameEmptyError => 'El nombre no puede estar vacío';

  @override
  String get emailLabel => 'Dirección de Correo';

  @override
  String get emailHint => 'Introduce tu correo';

  @override
  String get emailInvalidError => 'Correo inválido';

  @override
  String get emailChangeWarning =>
      'Cambiar tu correo afecta a todos los espacios de trabajo';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get profileUpdated => 'Perfil actualizado correctamente';

  @override
  String get displayLanguage => 'Idioma de Visualización';

  @override
  String languageUpdated(String language) {
    return 'Idioma actualizado a $language';
  }

  @override
  String get emailNotifications => 'Notificaciones por Correo';

  @override
  String get emailNotificationsSubtitle =>
      'Recibe actualizaciones y alertas por correo';

  @override
  String get darkMode => 'Modo Oscuro';

  @override
  String get darkModeSubtitle => 'Usa un tema oscuro de alto contraste';

  @override
  String get developerSettings => 'Opciones de Desarrollador';

  @override
  String get mockAIModels => 'Simular Modelos de IA';

  @override
  String get mockAIModelsSubtitle =>
      'Forzar que toda la IA generativa use simulaciones locales para pruebas';

  @override
  String aiMockMode(String status) {
    return 'Modo Simulación IA: $status';
  }

  @override
  String get connectedAccounts => 'Cuentas Conectadas';

  @override
  String get connected => 'Conectado';

  @override
  String get notConnected => 'No conectado';

  @override
  String get disconnect => 'Desconectar';

  @override
  String get connect => 'Conectar';

  @override
  String accountDisconnected(String account) {
    return '$account desconectado';
  }

  @override
  String accountConnected(String account) {
    return '$account conectado';
  }
}
