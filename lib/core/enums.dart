import 'dart:ui' show Locale;

/// 领域枚举：存储值统一为 TEXT 枚举名（规格 §5.1）。
/// [storage] 是写入数据库的字符串；[fromStorage] 负责读取映射。
enum InboxStatus {
  pending('pending'),
  clarified('clarified');

  const InboxStatus(this.storage);
  final String storage;
  static InboxStatus fromStorage(String value) =>
      values.firstWhere((e) => e.storage == value);
}

enum TaskStatus {
  nextAction('next_action'),
  waiting('waiting'),
  someday('someday'),
  done('done');

  const TaskStatus(this.storage);
  final String storage;
  static TaskStatus fromStorage(String value) =>
      values.firstWhere((e) => e.storage == value);
}

enum ProjectStatus {
  active('active'),
  done('done'),
  someday('someday');

  const ProjectStatus(this.storage);
  final String storage;
  static ProjectStatus fromStorage(String value) =>
      values.firstWhere((e) => e.storage == value);
}

enum TaskSource {
  text('text'),
  voice('voice'),
  share('share'),
  image('image');

  const TaskSource(this.storage);
  final String storage;
  static TaskSource fromStorage(String value) =>
      values.firstWhere((e) => e.storage == value);
}

enum EnergyLevel {
  low('low'),
  medium('medium'),
  high('high');

  const EnergyLevel(this.storage);
  final String storage;
  static EnergyLevel fromStorage(String value) =>
      values.firstWhere((e) => e.storage == value);
  static EnergyLevel? fromStorageOrNull(String? value) =>
      value == null ? null : values.firstWhere((e) => e.storage == value);
}

enum PriorityLevel {
  low('low'),
  medium('medium'),
  high('high');

  const PriorityLevel(this.storage);
  final String storage;
  static PriorityLevel fromStorage(String value) =>
      values.firstWhere((e) => e.storage == value);
  static PriorityLevel? fromStorageOrNull(String? value) =>
      value == null ? null : values.firstWhere((e) => e.storage == value);
}

/// 语言选择：system=跟随系统（locale 为 null）。
enum LocaleSelection {
  system(null),
  zh(Locale('zh')),
  en(Locale('en'));

  const LocaleSelection(this.locale);
  final Locale? locale;
}
