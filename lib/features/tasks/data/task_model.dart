// ── Модели ───────────────────────────────────────────────────────────

enum RecurrenceType { none, daily, weekly, monthly }

class TaskCategory {
  final String id;
  final String name;
  final String emoji; // Оставлено для обратной совместимости со старыми данными
  final String?
  iconAsset; // НОВОЕ: путь к SVG иконке (например 'categories/broom.svg')
  final String? colorHex; // НОВОЕ: цвет иконки (например '#F16001')

  const TaskCategory({
    required this.id,
    required this.name,
    this.emoji = '📌', // Сделал необязательным с дефолтом
    this.iconAsset,
    this.colorHex,
  });

  // Нужно для сохранения в базу
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'iconAsset': iconAsset,
    'colorHex': colorHex,
  };

  factory TaskCategory.fromMap(Map<String, dynamic> m) => TaskCategory(
    id: m['id'] as String,
    name: m['name'] as String,
    emoji: m['emoji'] as String? ?? '📌',
    iconAsset: m['iconAsset'] as String?,
    colorHex: m['colorHex'] as String?,
  );
}

class Task {
  final String id;
  final String title;
  final TaskCategory category;
  final DateTime? date;
  final String? time; // null = весь день
  final int? reminderMinutes; // null = без напоминания, иначе за N минут
  final String assignedTo;
  final bool isDone;
  final String createdBy;

  // НОВЫЕ ПОЛЯ
  final RecurrenceType recurrenceType;
  final int sortOrder; // Для перетаскивания
  final DateTime? completedDate; // Для стрика

  const Task({
    required this.id,
    required this.title,
    required this.category,
    this.date,
    this.time,
    this.reminderMinutes,
    required this.assignedTo,
    this.isDone = false,
    required this.createdBy,
    this.recurrenceType = RecurrenceType.none, // По умолчанию без повторов
    this.sortOrder = 0, // По умолчанию в конец
    this.completedDate,
  });

  Task copyWith({
    String? id,
    String? title,
    TaskCategory? category,
    DateTime? date,
    String? time,
    int? reminderMinutes,
    bool clearReminder = false,
    String? assignedTo,
    bool? isDone,
    String? createdBy,
    RecurrenceType? recurrenceType,
    int? sortOrder,
    DateTime? completedDate,
  }) => Task(
    id: id ?? this.id,
    title: title ?? this.title,
    category: category ?? this.category,
    date: date ?? this.date,
    time: time ?? this.time,
    reminderMinutes: clearReminder
        ? null
        : (reminderMinutes ?? this.reminderMinutes),
    assignedTo: assignedTo ?? this.assignedTo,
    isDone: isDone ?? this.isDone,
    createdBy: createdBy ?? this.createdBy,
    recurrenceType: recurrenceType ?? this.recurrenceType,
    sortOrder: sortOrder ?? this.sortOrder,
    completedDate: completedDate ?? this.completedDate,
  );

  // Преобразование для сохранения в SharedPreferences/JSON
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'category': category.toMap(),
    'date': date?.toIso8601String(),
    'time': time,
    'reminderMinutes': reminderMinutes,
    'assignedTo': assignedTo,
    'isDone': isDone,
    'createdBy': createdBy,
    'recurrenceType': recurrenceType.index, // Сохраняем число (0, 1, 2, 3)
    'sortOrder': sortOrder,
    'completedDate': completedDate?.toIso8601String(),
  };

  // Чтение из базы. Значения по умолчанию (?? 0) нужны, чтобы не сломались старые задачи
  factory Task.fromMap(Map<String, dynamic> m) {
    return Task(
      id: m['id'] as String,
      title: m['title'] as String,
      category: TaskCategory.fromMap(m['category'] as Map<String, dynamic>),
      date: m['date'] != null ? DateTime.parse(m['date'] as String) : null,
      time: m['time'] as String?,
      reminderMinutes: m['reminderMinutes'] as int?,
      assignedTo: m['assignedTo'] as String? ?? 'Вы',
      isDone: m['isDone'] as bool? ?? false,
      createdBy: m['createdBy'] as String? ?? 'user1',
      // Чтение новых полей с защитой от ошибок старых данных
      recurrenceType: RecurrenceType.values[m['recurrenceType'] as int? ?? 0],
      sortOrder: m['sortOrder'] as int? ?? 0,
      completedDate: m['completedDate'] != null
          ? DateTime.parse(m['completedDate'] as String)
          : null,
    );
  }
}

class TaskCategoryGroup {
  final TaskCategory category;
  final int totalCount;
  final int doneCount;

  const TaskCategoryGroup({
    required this.category,
    required this.totalCount,
    required this.doneCount,
  });

  int get completionPercent =>
      totalCount == 0 ? 0 : ((doneCount / totalCount) * 100).round();
}

class PartnerProgress {
  final int myPercent;
  final int partnerPercent;
  final String partnerName;

  const PartnerProgress({
    required this.myPercent,
    required this.partnerPercent,
    required this.partnerName,
  });
}

class AppUser {
  final String id;
  final String name;
  final String? photoUrl;

  const AppUser({required this.id, required this.name, this.photoUrl});
}
