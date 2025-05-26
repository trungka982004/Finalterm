import 'package:flutter/material.dart';

class LabelManagementPage extends StatefulWidget {
  const LabelManagementPage({super.key});

  @override
  State<LabelManagementPage> createState() => _LabelManagementPageState();
}

class _LabelManagementPageState extends State<LabelManagementPage> {
  final List<Map<String, dynamic>> _labels = [
    {
      'name': 'Important',
      'color': Colors.red,
      'emailCount': 12,
      'emails': [
        {'subject': 'Urgent: Project Deadline', 'sender': 'John Doe', 'time': '10:30 AM'},
        {'subject': 'Important Meeting Notes', 'sender': 'Alice Smith', 'time': 'Yesterday'},
      ]
    },
    {
      'name': 'Work',
      'color': Colors.blue,
      'emailCount': 25,
      'emails': [
        {'subject': 'Weekly Report', 'sender': 'Manager', 'time': '9:15 AM'},
        {'subject': 'Team Meeting', 'sender': 'HR', 'time': 'Yesterday'},
      ]
    },
    {
      'name': 'Personal',
      'color': Colors.green,
      'emailCount': 8,
      'emails': [
        {'subject': 'Family Gathering', 'sender': 'Mom', 'time': '2:00 PM'},
        {'subject': 'Birthday Party', 'sender': 'Friend', 'time': 'Yesterday'},
      ]
    },
    {
      'name': 'Projects',
      'color': Colors.orange,
      'emailCount': 15,
      'emails': [
        {'subject': 'Project Update', 'sender': 'Team Lead', 'time': '11:45 AM'},
        {'subject': 'New Task Assigned', 'sender': 'Project Manager', 'time': 'Yesterday'},
      ]
    },
  ];

  final List<Color> _availableColors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Labels'),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.blue),
            onPressed: () => _showAddEditLabelDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search labels',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          // Labels List
          Expanded(
            child: ListView.builder(
              itemCount: _labels.length,
              itemBuilder: (context, index) {
                final label = _labels[index];
                return Dismissible(
                  key: Key(label['name']),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    setState(() {
                      _labels.removeAt(index);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('${label['name']} deleted')),
                    );
                  },
                  child: InkWell(
                    onTap: () => _showEmailsDialog(label),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: label['color'],
                        child: Text(
                          label['name'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      title: Text(label['name']),
                      subtitle: Text('${label['emailCount']} emails'),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showAddEditLabelDialog(label: label),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditLabelDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showEmailsDialog(Map<String, dynamic> label) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: label['color'],
                        child: Text(
                          label['name'][0].toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        label['name'],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: label['emails'].length,
                  itemBuilder: (context, index) {
                    final email = label['emails'][index];
                    return ListTile(
                      title: Text(
                        email['subject'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(email['sender']),
                      trailing: Text(
                        email['time'],
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      onTap: () {
                        // TODO: Implement email opening logic
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddEditLabelDialog({Map<String, dynamic>? label}) {
    final TextEditingController nameController = TextEditingController(
      text: label?['name'] ?? '',
    );
    Color selectedColor = label?['color'] ?? Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(label == null ? 'Add New Label' : 'Edit Label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Label Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Select Color:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _availableColors.map((color) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selectedColor == color
                              ? Colors.black
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  if (label == null) {
                    // Add new label
                    setState(() {
                      _labels.add({
                        'name': nameController.text,
                        'color': selectedColor,
                        'emailCount': 0,
                        'emails': [],
                      });
                    });
                  } else {
                    // Update existing label
                    final index = _labels.indexOf(label);
                    setState(() {
                      _labels[index] = {
                        ...label,
                        'name': nameController.text,
                        'color': selectedColor,
                      };
                    });
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
} 