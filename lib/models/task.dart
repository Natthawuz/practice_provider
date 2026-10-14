class Task {
  final int? id;
  final String title;
  final DateTime dueDate;
  final bool isDone;
  const Task(
      {this.id,
      required this.title,
      required this.dueDate,
      required this.isDone});
  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'dueDate': dueDate.toIso8601String(),
        'isDone': isDone ? 1 : 0,
      };
  factory Task.fromMap(Map<String, Object?> m) => Task(
        id: m['id'] as int?,
        title: m['title'] as String,
        dueDate: DateTime.parse(m['dueDate'] as String),
        isDone: m['isDone'] == 1,
      );
}
