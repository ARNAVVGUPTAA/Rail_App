import 'package:flutter/material.dart';

// A simple class to hold our task data
class Task {
  String title;
  bool isDone;

  Task({required this.title, this.isDone = false});
}

class MaintenanceChecklistPage extends StatefulWidget {
  const MaintenanceChecklistPage({super.key});

  @override
  State<MaintenanceChecklistPage> createState() =>
      _MaintenanceChecklistPageState();
}

class _MaintenanceChecklistPageState extends State<MaintenanceChecklistPage> {
  // Controller for the text input field
  final TextEditingController _taskController = TextEditingController();

  // The list of tasks, pre-filled with some defaults
  final List<Task> _tasks = [
    Task(title: 'Check cable insulation'),
    Task(title: 'Verify signal lamp'),
    Task(title: 'Check joint pit marker'),
    Task(title: 'Record megger reading'),
  ];

  // This function adds a new task to the list
  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(Task(title: _taskController.text));
        _taskController.clear(); // Clear the text field after adding
        FocusScope.of(context).unfocus(); // Dismiss the keyboard
      });
    }
  }

  @override
  void dispose() {
    _taskController.dispose(); // Clean up the controller
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Themed AppBar to match the rest of the app
      appBar: AppBar(
        title: const Text(
          'Maintenance Tasks',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF2C3E50), // Dark blue-gray color
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(
          bottom: 80,
        ), // Prevents overlap with bottom bar
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          // A styled CheckboxListTile
          return CheckboxListTile(
            title: Text(
              task.title,
              style: TextStyle(
                // Strikethrough text when the task is done
                decoration: task.isDone ? TextDecoration.lineThrough : null,
                color: task.isDone ? Colors.grey : Colors.black87,
              ),
            ),
            value: task.isDone,
            onChanged: (bool? newValue) {
              setState(() {
                task.isDone = newValue ?? false;
              });
            },
            activeColor: Colors.redAccent, // Themed accent color
            controlAffinity: ListTileControlAffinity.leading,
          );
        },
      ),
      // Themed bottom navigation bar for adding new tasks
      bottomNavigationBar: Padding(
        // Adjusts padding to avoid the keyboard
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: InputDecoration(
                    hintText: 'Enter new task...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Colors.redAccent,
                        width: 2,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Themed "Add" button
              IconButton(
                icon: const Icon(Icons.add_circle, size: 40),
                onPressed: _addTask,
                color: Colors.redAccent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
