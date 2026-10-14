import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';

class TaskScreen extends StatelessWidget {
  const TaskScreen({super.key});
  void _form(BuildContext context, [Task? item]) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => TaskForm(item: item)),
    );
  }

  Future<void> _delete(BuildContext context, Task item) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ลบ ${item.title} หรือไม่'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ'),
          ),
        ],
      ),
    );
    if (yes != true || !context.mounted) return;
    final p = context.read<TaskProvider>();
    final ok = await p.delete(item.id!);
    if (!context.mounted || ok) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(p.error ?? 'ลบไม่สำเร็จ')));
  }

  @override
  Widget build(BuildContext context) => Consumer<TaskProvider>(
    builder: (context, p, _) => Scaffold(
      appBar: AppBar(
        title: const Text('งานที่ต้องทำ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: p.busy
                ? null
                : () {
                    p.load();
                  },
          ),
        ],
      ),
      body: Column(
        children: [
          if (p.busy) const LinearProgressIndicator(),
          if (p.error != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(p.error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: p.items.isEmpty
                ? Center(
                    child: Text(
                      p.busy ? 'กำลังโหลด' : 'ยังไม่มีข้อมูล กด + เพื่อเพิ่ม',
                    ),
                  )
                : ListView.builder(
                    itemCount: p.items.length,
                    itemBuilder: (context, i) {
                      final item = p.items[i];
                      return ListTile(
                        title: Text(item.title),
                        subtitle: Text(
                          item.dueDate.toIso8601String().split('T').first +
                              (item.isDone ? ' เสร็จแล้ว' : ' ยังไม่เสร็จ'),
                        ),
                        onTap: p.busy
                            ? null
                            : () {
                                _form(context, item);
                              },
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: p.busy
                              ? null
                              : () {
                                  _delete(context, item);
                                },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: p.busy
            ? null
            : () {
                _form(context);
              },
        child: const Icon(Icons.add),
      ),
    ),
  );
}

class TaskForm extends StatefulWidget {
  final Task? item;
  const TaskForm({super.key, this.item});
  @override
  State<TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<TaskForm> {
  final _key = GlobalKey<FormState>();
  bool _saving = false;
  late final TextEditingController _title;
  late DateTime _date;
  late bool _done;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.item?.title ?? '');
    _date = widget.item?.dueDate ?? DateTime.now();
    _done = widget.item?.isDone ?? false;
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(_date.year < 1900 ? _date.year : 1900),
      lastDate: DateTime(_date.year > 2200 ? _date.year : 2200, 12, 31),
    );
    if (value != null && mounted) setState(() => _date = value);
  }

  Future<void> _save() async {
    if (_saving || !_key.currentState!.validate()) return;
    setState(() => _saving = true);
    final p = context.read<TaskProvider>();
    final ok = await p.save(
      Task(
        id: widget.item?.id,
        title: _title.text.trim(),
        dueDate: DateTime(_date.year, _date.month, _date.day),
        isDone: _done,
      ),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(p.error ?? 'บันทึกไม่สำเร็จ')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.item == null ? 'เพิ่มงานที่ต้องทำ' : 'แก้ไขงานที่ต้องทำ',
      ),
    ),
    body: AbsorbPointer(
      absorbing: _saving,
      child: Form(
        key: _key,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'ชื่องาน'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'กรุณากรอกชื่องาน' : null,
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('วันครบกำหนด'),
              subtitle: Text(_date.toIso8601String().split('T').first),
              trailing: const Icon(Icons.calendar_month),
              onTap: _pickDate,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('เสร็จแล้ว'),
              value: _done,
              onChanged: (v) => setState(() => _done = v),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'กำลังบันทึก' : 'บันทึก'),
            ),
          ],
        ),
      ),
    ),
  );
}
