import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TaskScreen(),
    );
  }
}

class TaskScreen extends StatefulWidget {
  const TaskScreen({super.key});

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  List<Map<String, dynamic>> tareas = [];
  TextEditingController controller = TextEditingController();
   String prioridadSeleccionada = 'Media';
  @override
  void initState() {
    super.initState();
    cargarTareas();
  }

  Future<void> guardarTareas() async {
    final prefs = await SharedPreferences.getInstance();
    String data = jsonEncode(tareas);
    prefs.setString('tareas', data);
  }

  Future<void> cargarTareas() async {
    final prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('tareas');

    if (data != null) {
      setState(() {
        tareas = List<Map<String, dynamic>>.from(jsonDecode(data));
      });
    }
  }

  void agregarTarea() {
    if (controller.text.isNotEmpty) {
      setState(() {
        tareas.add({
          'texto': controller.text,
          'completado': false,
          'prioridad': prioridadSeleccionada,
        });
        controller.clear();
      });
      guardarTareas();
    }
  }

  void eliminarTarea(int index) {
    setState(() {
      tareas.removeAt(index);
    });
    guardarTareas();
  }

  void toggleTarea(int index, bool value) {
    setState(() {
      tareas[index]['completado'] = value;
    });
    guardarTareas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
          onPressed: agregarTarea,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text("Mis Tareas"),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
                children: [
                  Expanded(
                   child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: "Escribe una tarea",
                      filled: true,
                      fillColor: Colors.white,
                        border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                        borderSide:
                        BorderSide.none,
                    ),
                  ),
                ),
             ),

                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: agregarTarea,
                  child: const Text("Agregar"),
                )
              ],
            ),
          ),

          DropdownButton<String>(
            value: prioridadSeleccionada,
            items: ['Alta', 'Media', 'Baja'].map((String value) {
              return DropdownMenuItem(
                value: value,
                child: Text(value),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                prioridadSeleccionada = value!;
              });
            },
          ),

          Expanded(
            child: ListView.builder(
              itemCount: tareas.length,
              itemBuilder: (context, index) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)
                  ),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 6),
                  child: ListTile(
                    title: Text(
                      tareas[index]['texto'],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        decoration: tareas[index]['completado']
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    subtitle: Text(
                      tareas[index]['prioridad'] ?? 'Media', // Evita el error Null del pantallazo rojo
                      style: TextStyle(
                        color: (tareas[index]['prioridad'] ?? 'Media') == 'Alta'
                            ? Colors.red
                            : (tareas[index]['prioridad'] ?? 'Media') == 'Media'
                            ? Colors.orange
                            : Colors.green,
                      ),
                    ),
                    leading: Checkbox(

                      value: tareas[index]['completado'],
                      onChanged: (value) =>
                          toggleTarea(index, value!),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red,),
                      onPressed: () => eliminarTarea(index),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}