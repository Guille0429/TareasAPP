import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

final FirebaseAuth auth = FirebaseAuth.instance;

final FirebaseFirestore firestore = FirebaseFirestore.instance;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //FIREBASE
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // INICIALIZAR TIMEZONES
  tz.initializeTimeZones();

  // CONFIGURACIÓN DE INICIALIZACIÓN ANDROID
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
  );

  // SOLICITAR PERMISOS EXPLÍCITOS (Android 13+)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: auth.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return const TaskScreen();
          }
          return const LoginScreen();
        },
      ),
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

  DateTime? fechaSeleccionada;
  TimeOfDay? horaSeleccionada;

  bool mostrarSoloDestacadas = false;

  @override
  void initState() {
    super.initState();

    if (auth.currentUser != null) {
      cargarTareasFirebase();
    } else {
      cargarTareas();
    }
  }

  Future<void> guardarTareaFirebase(Map<String, dynamic> tarea) async {

    User? user = auth.currentUser;

    if (user == null) return;

    await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('tareas')
        .add(tarea);

  }

  Future<void> cargarTareasFirebase() async {

    User? user = auth.currentUser;

    if (user == null) return;

    final snapshot = await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('tareas')
        .get();

    List<Map<String, dynamic>> tareasFirebase = snapshot.docs
        .map((doc) => doc.data())
        .toList();

    setState(() {
      tareas = tareasFirebase;
    });

  }


  // --- FUNCIONES ---

  Future<void> seleccionarFecha() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        fechaSeleccionada = picked;
      });
    }
  }

  Future<void> seleccionarHora() async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        horaSeleccionada = picked;
      });
    }
  }

  Future<void> programarNotificacion(int id, String titulo, DateTime fechaHora) async {
    if (fechaHora.isBefore(DateTime.now())) return;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      'Recordatorio de tarea',
      titulo,
      tz.TZDateTime.from(fechaHora, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tareas_channel_01',
          'Recordatorios',
          channelDescription: 'Notificaciones de tareas',
          importance: Importance.max, // Máxima importancia para banner
          priority: Priority.high,    // Prioridad alta para sonido
          playSound: true,
          enableVibration: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
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

  void toggleDestacada(int index) {
    setState(() {
      tareas[index]['destacada'] = !(tareas[index]['destacada'] ?? false);
    });
    guardarTareas();
  }

  void mostrarModalNuevaTarea() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Nueva tarea",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: "Escribe una tarea",
                    filled: true,
                    fillColor: Colors.grey[200],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: prioridadSeleccionada,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: ['Alta', 'Media', 'Baja'].map((String value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) => setState(() => prioridadSeleccionada = value!),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: seleccionarFecha,
                        child: Text(fechaSeleccionada == null
                            ? "Fecha"
                            : "${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: seleccionarHora,
                        child: Text(horaSeleccionada == null
                            ? "Hora"
                            : horaSeleccionada!.format(context)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      agregarTarea();
                      Navigator.pop(context);
                    },
                    child: const Text("Guardar Tarea"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void editarTarea(int index) {
    controller.text = tareas[index]['texto'];
    prioridadSeleccionada = tareas[index]['prioridad'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Editar tarea",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                      hintText: "Editar tarea",
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none)),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: prioridadSeleccionada,
                  items: ['Alta', 'Media', 'Baja'].map((String value) {
                    return DropdownMenuItem(value: value, child: Text(value));
                  }).toList(),
                  onChanged: (value) => setState(() => prioridadSeleccionada = value!),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        tareas[index]['texto'] = controller.text;
                        tareas[index]['prioridad'] = prioridadSeleccionada;
                      });
                      guardarTareas();
                      controller.clear();
                      Navigator.pop(context);
                    },
                    child: const Text("Guardar Cambios"),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void agregarTarea() {
    if (controller.text.isNotEmpty) {
      String textoTarea = controller.text;
      int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      if (fechaSeleccionada != null && horaSeleccionada != null) {
        final fechaHora = DateTime(
          fechaSeleccionada!.year,
          fechaSeleccionada!.month,
          fechaSeleccionada!.day,
          horaSeleccionada!.hour,
          horaSeleccionada!.minute,
        );

        programarNotificacion(notificationId, textoTarea, fechaHora);
      }

      Map<String, dynamic> nuevaTarea = {
        'texto': textoTarea,
        'completado': false,
        'destacada': false,
        'prioridad': prioridadSeleccionada,
        'fecha': fechaSeleccionada != null
            ? "${fechaSeleccionada!.day}/${fechaSeleccionada!.month}/${fechaSeleccionada!.year}"
            : "Sin fecha",
        'hora': horaSeleccionada != null
            ? horaSeleccionada!.format(context)
            : "Sin hora",
      };

      setState(() {
        tareas.add(nuevaTarea);

        controller.clear();
        fechaSeleccionada = null;
        horaSeleccionada = null;
      });

      guardarTareas();
      guardarTareaFirebase(nuevaTarea);
    }
  }

  void eliminarTarea(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Eliminar tarea"),
          content: const Text("Estás seguro de borrar esta tarea"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancelar")),
            ElevatedButton(
              onPressed: () {
                setState(() => tareas.removeAt(index));
                guardarTareas();
                Navigator.pop(context);
              },
              child: const Text("Eliminar"),
            ),
          ],
        );
      },
    );
  }

  void toggleTarea(int index, bool value) {
    setState(() => tareas[index]['completado'] = value);
    guardarTareas();
  }

  @override
  Widget build(BuildContext context) {
    final tareasPendientes = tareas.where((t) {
      if (t['completado'] == true) return false;
      if (mostrarSoloDestacadas && t['destacada'] != true) return false;
      return true;
    }).toList();

    final tareasCompletadas = tareas.where((t) => t['completado'] == true).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      floatingActionButton: FloatingActionButton(
        onPressed: mostrarModalNuevaTarea,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text("Mis Tareas"),
        centerTitle: true,
        elevation: 0,

        actions: [

          PopupMenuButton<String>(

            onSelected: (value) async {

              if (value == 'logout') {

                await auth.signOut();

                if (context.mounted) {

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );

                }

              }

            },

            itemBuilder: (context) => [

              const PopupMenuItem(
                value: 'account',
                child: Text('Mi cuenta'),
              ),

              const PopupMenuItem(
                value: 'logout',
                child: Text('Cerrar sesión'),
              ),

            ],

            child: const Padding(
              padding: EdgeInsets.only(right: 15),
              child: CircleAvatar(
                child: Icon(Icons.person),
              ),
            ),

          ),

        ],
      ),

      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Pendientes",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text("Todas"),
                  selected: !mostrarSoloDestacadas,
                  onSelected: (value) => setState(() => mostrarSoloDestacadas = false),
                ),

                const SizedBox(width: 10),

                ChoiceChip(
                  label: const Text("⭐ Destacadas"),
                  selected: mostrarSoloDestacadas,
                  onSelected: (value) {
                    setState(() {
                      mostrarSoloDestacadas = value;
                    });
                  },
                ),

              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tareasPendientes.length,
              itemBuilder: (context, index) {
                final t = tareasPendientes[index];
                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  child: ListTile(
                    onLongPress: () => editarTarea(tareas.indexOf(t)),
                    title: Text(
                      t['texto'],
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        decoration: t['completado'] ? TextDecoration.lineThrough : TextDecoration.none,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t['prioridad'] ?? 'Media',
                          style: TextStyle(
                            color: t['prioridad'] == 'Alta'
                                ? Colors.red
                                : t['prioridad'] == 'Media'
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                        Text("📅 ${t['fecha']}   ⏰ ${t['hora']}",
                            style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                    leading: Checkbox(
                        value: t['completado'],
                        onChanged: (value) => toggleTarea(tareas.indexOf(t), value!)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: Icon(
                                t['destacada'] == true ? Icons.star : Icons.star_border,
                                color: Colors.amber),
                            onPressed: () => toggleDestacada(tareas.indexOf(t))),
                        IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => eliminarTarea(tareas.indexOf(t))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("Completadas",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tareasCompletadas.length,
              itemBuilder: (context, index) {
                final tc = tareasCompletadas[index];
                return Card(
                  color: Colors.grey[300],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: ListTile(
                    title: Text(tc['texto'],
                        style: const TextStyle(decoration: TextDecoration.lineThrough, color: Colors.black54)),
                    subtitle: Text("📅 ${tc['fecha']}  ⏰ ${tc['hora']}",
                        style: const TextStyle(fontSize: 12)),
                    leading: Checkbox(value: true, onChanged: (value) => toggleTarea(tareas.indexOf(tc), false)),
                    trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => eliminarTarea(tareas.indexOf(tc))),
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> login() async {

    await auth.signInWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
  }

  Future<void> registrar() async {

    await auth.createUserWithEmailAndPassword(
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Correo',
              ),
            ),

            const SizedBox(height: 20),

            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Contraseña',
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: login,
              child: const Text("Iniciar Sesión"),
            ),

            ElevatedButton(
              onPressed: registrar,
              child: const Text("Crear Cuenta"),
            ),

            const SizedBox(height: 10),

            ElevatedButton(
                onPressed: () {

                  Navigator.pushReplacement(
                      context,
                    MaterialPageRoute(
                        builder: (_) => const TaskScreen(),
                    ),
                  );
                },

              child: const Text("Continuar como invitado"),

               ),

          ],
        ),
      ),
    );
  }
}