import 'package:flutter/material.dart';
import 'package:todo_sqlite/database_helper.dart';
import 'package:todo_sqlite/contact.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contact Manager',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      debugShowCheckedModeBanner: false,
      home: const ContactListScreen(),
    );
  }
}

class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final _dbHelper = DatabaseHelper.instance;
  List<Contact> _contacts = [];

  @override
  void initState() {
    super.initState();
    _loadContacts();  // Cargar contactos al iniciar
  }

  Future<void> _loadContacts() async {
    final contacts = await _dbHelper.getContacts();
    setState(() {
      _contacts = contacts.map((map) => Contact.fromMap(map)).toList();
    });
  }

  Future<void> _addOrUpdateContact({Contact? contact}) async {
    final TextEditingController nameController = TextEditingController();

    if (contact != null) {
      nameController.text = contact.name;
    }

    // Mostrar diálogo de agregar o actualizar
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(contact == null ? 'Add Contact' : 'Update Contact'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Enter a name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text;

                if (name.isNotEmpty) {
                  if (contact == null) {
                    // Insertar nuevo contacto
                    await _dbHelper.insertContact(Contact(name: name).toMap());
                  } else {
                    // Actualizar contacto existente
                    contact.name = name;
                    await _dbHelper.updateContact(contact.toMap());
                  }

                  _loadContacts();  // Recargar la lista de contactos después de agregar/actualizar
                  Navigator.of(context).pop();  // Cerrar el diálogo
                }
              },
              child: Text(contact == null ? 'Add' : 'Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteContact(int id) async {
    await _dbHelper.deleteContact(id);
    _loadContacts();  // Recargar la lista después de eliminar
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                _addOrUpdateContact();  // Abrir diálogo para agregar nuevo contacto
              },
              child: const Text('Add New Contact'),
            ),
          ),
          Expanded(
            child: _contacts.isNotEmpty
                ? ListView.builder(
                    itemCount: _contacts.length,
                    itemBuilder: (context, index) {
                      final contact = _contacts[index];
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () {
                                  _addOrUpdateContact(contact: contact);  // Editar contacto
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _deleteContact(contact.id!);  // Eliminar contacto
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text('No contacts available.'),
                  ),
          ),
        ],
      ),
    );
  }
}
