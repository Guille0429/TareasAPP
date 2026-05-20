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
import 'package:google_sign_in/google_sign_in.dart';

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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() =>
      _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TextEditingController nombreController =
  TextEditingController();

  TextEditingController telefonoController =
  TextEditingController();

  Future<Map<String, dynamic>?> obtenerDatosUsuario() async {

    User? user = auth.currentUser;

    if (user == null) return null;

    DocumentSnapshot doc = await firestore
        .collection('usuarios')
        .doc(user.uid)
        .get();

    return doc.data() as Map<String, dynamic>?;

  }

  Future<void> editarPerfil(BuildContext context) async {

    User? user = auth.currentUser;

    if (user == null) return;

    await firestore
        .collection('usuarios')
        .doc(user.uid)
        .update({

      'nombre': nombreController.text.trim(),
      'telefono': telefonoController.text.trim(),

    });

    if (context.mounted) {

      Navigator.pop(context);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Perfil actualizado"),
        ),
      );

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Mi Perfil"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),

      body: FutureBuilder<Map<String, dynamic>?>(

        future: obtenerDatosUsuario(),

        builder: (context, snapshot) {

          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child: CircularProgressIndicator(),
            );

          }

          if (!snapshot.hasData || snapshot.data == null) {

            return const Center(
              child: Text("No hay datos"),
            );

          }

          final data = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(25),

            child: Column(

              children: [

                const SizedBox(height: 20),

                CircleAvatar(
                  radius: 55,
                  backgroundColor: Colors.deepPurple,

                  child: Text(

                    data['nombre'][0].toUpperCase(),

                    style: const TextStyle(
                      fontSize: 40,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                Card(

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: ListTile(

                    leading: const Icon(Icons.person),

                    title: const Text("Nombre"),

                    subtitle: Text(data['nombre'] ?? ''),

                  ),
                ),

                const SizedBox(height: 15),

                Card(

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: ListTile(

                    leading: const Icon(Icons.email),

                    title: const Text("Correo"),

                    subtitle: Text(data['email'] ?? ''),

                  ),
                ),

                const SizedBox(height: 15),

                Card(

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),

                  child: ListTile(

                    leading: const Icon(Icons.phone),

                    title: const Text("Teléfono"),

                    subtitle: Text(data['telefono'] ?? ''),

                  ),
                ),

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton.icon(

                    onPressed: () {

                      nombreController.text =
                          data['nombre'] ?? '';

                      telefonoController.text =
                          data['telefono'] ?? '';

                      showModalBottomSheet(

                        context: context,

                        isScrollControlled: true,

                        shape: const RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.vertical(
                            top: Radius.circular(25),
                          ),
                        ),

                        builder: (context) {

                          return Padding(

                            padding: EdgeInsets.only(

                              left: 20,
                              right: 20,
                              top: 25,

                              bottom:
                              MediaQuery.of(context)
                                  .viewInsets
                                  .bottom + 20,

                            ),

                            child: Column(

                              mainAxisSize: MainAxisSize.min,

                              children: [

                                const Text(
                                  "Editar Perfil",
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 25),

                                TextField(

                                  controller: nombreController,

                                  decoration: InputDecoration(

                                    labelText: "Nombre",

                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(15),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                TextField(

                                  controller:
                                  telefonoController,

                                  keyboardType:
                                  TextInputType.phone,

                                  decoration: InputDecoration(

                                    labelText: "Teléfono",

                                    border: OutlineInputBorder(
                                      borderRadius:
                                      BorderRadius.circular(15),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 25),

                                SizedBox(

                                  width: double.infinity,
                                  height: 55,

                                  child: ElevatedButton(

                                    onPressed: () =>
                                        editarPerfil(context),

                                    style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor:
                                      Colors.deepPurple,
                                      foregroundColor:
                                      Colors.white,
                                    ),

                                    child: const Text(
                                      "Guardar cambios",
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          );

                        },
                      );

                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),

                    icon: const Icon(Icons.edit),

                    label: const Text(
                      "Editar perfil",
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: ElevatedButton.icon(

                    onPressed: () async {

                      await auth.signOut();

                      if (context.mounted) {

                        Navigator.pushAndRemoveUntil(

                          context,

                          MaterialPageRoute(
                            builder: (_) =>
                            const LoginScreen(),
                          ),

                              (route) => false,

                        );

                      }

                    },

                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),

                    icon: const Icon(Icons.logout),

                    label: const Text(
                      "Cerrar sesión",
                    ),
                  ),
                ),

              ],
            ),
          );

        },
      ),
    );
  }
}

class _TaskScreenState extends State<TaskScreen> {
  List<Map<String, dynamic>> tareas = [];
  TextEditingController controller = TextEditingController();
  String prioridadSeleccionada = 'Media';

  DateTime? fechaSeleccionada;
  TimeOfDay? horaSeleccionada;

  bool mostrarSoloDestacadas = false;

  String busqueda = '';

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

    DocumentReference doc = await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('tareas')
        .add(tarea);

    tarea['id'] = doc.id;

  }

  Future<void> cargarTareasFirebase() async {

    User? user = auth.currentUser;

    if (user == null) return;

    final snapshot = await firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('tareas')
        .get();

    List<Map<String, dynamic>> tareasFirebase = snapshot.docs.map((doc) {

      Map<String, dynamic> data = doc.data();

      data['id'] = doc.id;

      return data;

    }).toList();

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

  Future<void> toggleDestacada(int index) async {

    setState(() {
      tareas[index]['destacada'] =
      !(tareas[index]['destacada'] ?? false);
    });

    guardarTareas();

    User? user = auth.currentUser;

    if (user != null && tareas[index]['id'] != null) {

      await firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('tareas')
          .doc(tareas[index]['id'])
          .update({

        'destacada': tareas[index]['destacada'],

      });

    }

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
                    onPressed: () async {
                      setState(() {
                        tareas[index]['texto'] = controller.text;
                        tareas[index]['prioridad'] = prioridadSeleccionada;
                      });
                      guardarTareas();
                      User? user = auth.currentUser;

                      if (user != null &&
                          tareas[index]['id'] != null) {

                        await firestore
                            .collection('usuarios')
                            .doc(user.uid)
                            .collection('tareas')
                            .doc(tareas[index]['id'])
                            .update({

                          'texto': controller.text,
                          'prioridad': prioridadSeleccionada,

                        });

                      }
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
              onPressed: () async {

                User? user = auth.currentUser;

                if (user != null && tareas[index]['id'] != null) {

                  await firestore
                      .collection('usuarios')
                      .doc(user.uid)
                      .collection('tareas')
                      .doc(tareas[index]['id'])
                      .delete();

                }

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

  Future<void> toggleTarea(int index, bool value) async {

    setState(() {
      tareas[index]['completado'] = value;
    });

    guardarTareas();

    User? user = auth.currentUser;

    if (user != null && tareas[index]['id'] != null) {

      await firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('tareas')
          .doc(tareas[index]['id'])
          .update({

        'completado': value,

      });

    }

  }

  @override
  Widget build(BuildContext context) {
    final tareasPendientes = tareas.where((t) {

      if (t['completado'] == true) return false;

      if (mostrarSoloDestacadas &&
          t['destacada'] != true) {
        return false;
      }

      if (busqueda.isNotEmpty &&
          !t['texto']
              .toString()
              .toLowerCase()
              .contains(busqueda.toLowerCase())) {
        return false;
      }

      return true;

    }).toList();

    final tareasCompletadas = tareas.where((t) => t['completado'] == true).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      floatingActionButton: FloatingActionButton.extended(

        onPressed: mostrarModalNuevaTarea,

        backgroundColor: Colors.deepPurple,

        elevation: 8,

        shape: RoundedRectangleBorder(
          borderRadius: BorderRadiusGeometry.circular(18),
        ),
        icon: const Icon(Icons.add, color: Colors.white),

        label: const Text(
          "Nueva tarea",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),

      ),

      //AppBAR
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "TaskBy Notes",
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),

            SizedBox(height: 4),

            Text(
              "Organiza tu día",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

          ],
        ),

        actions: [

          PopupMenuButton<String>(

            offset: const Offset(0, 50),

            onSelected: (value) async {

              if (value == 'perfil') {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );

              }

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
                value: 'perfil',

                child: Row(
                  children: [

                    Icon(Icons.person),

                    SizedBox(width: 10),

                    Text('Mi perfil'),

                  ],
                ),
              ),

              PopupMenuItem(
                enabled: false,

                child: Text(
                  auth.currentUser?.email ?? "Invitado",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const PopupMenuDivider(),

              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [

                    Icon(Icons.logout, color: Colors.red),

                    SizedBox(width: 10),

                    Text('Cerrar sesión'),

                  ],
                ),
              ),

            ],

            child: Padding(
              padding: const EdgeInsets.only(right: 15),

              child: CircleAvatar(
                radius: 22,
                backgroundColor: Colors.deepPurple,

                child: Text(

                  auth.currentUser != null
                   ? auth.currentUser!.email![0].toUpperCase()
                   : "I",

                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        ],
      ),



      body: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(12),

            child: TextField(

              onChanged: (value) {

                setState(() {
                  busqueda = value;
                });

              },

              decoration: InputDecoration(

                hintText: "Buscar tareas...",

                prefixIcon: const Icon(Icons.search),

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
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
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),

                  child: ListTile(

                    contentPadding: const EdgeInsets.all(18),

                    onLongPress: () => editarTarea(tareas.indexOf(t)),

                    title: Text(
                      t['texto'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 10),

                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),

                            decoration: BoxDecoration(
                              color: t['prioridad'] == 'Alta'
                                  ? Colors.red.shade100
                                  : t['prioridad'] == 'Media'
                                  ? Colors.orange.shade100
                                  : Colors.green.shade100,

                              borderRadius: BorderRadius.circular(20),
                            ),

                            child: Text(
                              t['prioridad'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,

                                color: t['prioridad'] == 'Alta'
                                    ? Colors.red
                                    : t['prioridad'] == 'Media'
                                    ? Colors.orange
                                    : Colors.green,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            "📅 ${t['fecha']}   ⏰ ${t['hora']}",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),

                        ],
                      ),
                    ),

                    leading: Checkbox(
                      value: t['completado'],
                      onChanged: (value) =>
                          toggleTarea(tareas.indexOf(t), value!),
                    ),

                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,

                      children: [

                        IconButton(
                          icon: Icon(
                            t['destacada'] == true
                                ? Icons.star
                                : Icons.star_border,
                            color: Colors.amber,
                          ),
                          onPressed: () =>
                              toggleDestacada(tareas.indexOf(t)),
                        ),

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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  TextEditingController nombreController =
  TextEditingController();

  TextEditingController telefonoController =
  TextEditingController();

  TextEditingController emailController =
  TextEditingController();

  TextEditingController passwordController =
  TextEditingController();

  TextEditingController confirmarController =
  TextEditingController();

  Future<void> registrarUsuario() async {

    if (passwordController.text !=
        confirmarController.text) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Las contraseñas no coinciden"),
        ),
      );

      return;
    }

    try {

      UserCredential userCredential =
      await auth.createUserWithEmailAndPassword(

        email: emailController.text.trim(),

        password: passwordController.text.trim(),
      );

      await firestore
          .collection('usuarios')
          .doc(userCredential.user!.uid)
          .set({

        'nombre': nombreController.text.trim(),
        'telefono': telefonoController.text.trim(),
        'email': emailController.text.trim(),

      });

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Cuenta creada correctamente"),
          ),
        );

        Navigator.pop(context);

      }

    } on FirebaseAuthException catch (e) {

      String mensaje = "Error al registrar";

      if (e.code == 'email-already-in-use') {
        mensaje = "Ese correo ya está registrado";
      }

      else if (e.code == 'weak-password') {
        mensaje = "La contraseña debe tener mínimo 6 caracteres";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );

    }

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(25),

        child: Column(

          children: [

            const SizedBox(height: 20),

            const Text(
              "Crear Cuenta",
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 35),

            TextField(
              controller: nombreController,

              decoration: InputDecoration(
                hintText: "Nombre completo",

                prefixIcon:
                const Icon(Icons.person_outline),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: telefonoController,

              keyboardType: TextInputType.phone,

              decoration: InputDecoration(
                hintText: "Número de teléfono",

                prefixIcon:
                const Icon(Icons.phone_outlined),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: emailController,

              decoration: InputDecoration(
                hintText: "Correo electrónico",

                prefixIcon:
                const Icon(Icons.email_outlined),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: passwordController,

              obscureText: true,

              decoration: InputDecoration(
                hintText: "Contraseña",

                prefixIcon:
                const Icon(Icons.lock_outline),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 18),

            TextField(
              controller: confirmarController,

              obscureText: true,

              decoration: InputDecoration(
                hintText: "Confirmar contraseña",

                prefixIcon:
                const Icon(Icons.lock_outline),

                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 58,

              child: ElevatedButton(

                onPressed: registrarUsuario,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,

                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(18),
                  ),
                ),

                child: const Text(
                  "Crear cuenta",

                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}

class _LoginScreenState extends State<LoginScreen> {

  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
    try {
      await auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TaskScreen(),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String mensaje = "Error al iniciar sesión";

      if (e.code == 'user-not-found') {
        mensaje = "No existe una cuenta con ese correo";
      }

      else if (e.code == 'wrong-password') {
        mensaje = "Contraseña incorrecta";
      }

      else if (e.code == 'invalid-email') {
        mensaje = "Correo inválido";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );

      print(e.code);
      print(e.message);
    }
  }

  Future<void> recuperarPassword() async {

    if (emailController.text.trim().isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Escribe tu correo"),
        ),
      );

      return;
    }

    try {

      await auth.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Correo de recuperación enviado",
          ),
        ),
      );

    } on FirebaseAuthException catch (e) {

      String mensaje = "Error al enviar correo";

      if (e.code == 'user-not-found') {
        mensaje = "No existe una cuenta con ese correo";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(mensaje)),
      );

    }

  }

  Future<void> loginGoogle() async {

    try {

      final GoogleSignInAccount? googleUser =
      await GoogleSignIn().signIn();

      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await auth.signInWithCredential(credential);

      if (context.mounted) {

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const TaskScreen(),
          ),
        );

      }

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error Google: $e"),
        ),
      );

    }

  }

  void entrarComoInvitado() {

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const TaskScreen(),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(25),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [

              Container(
                width: 140,
                height: 140,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(35),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.deepPurple.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),

                child: ClipRRect(
                  borderRadius: BorderRadius.circular(35),

                  child: Image.asset(
                    'assets/icon/Icon.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                "TaskBy Notes",
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                "Organiza tu vida de manera inteligente",
                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 50),

              TextField(

                controller: emailController,

                decoration: InputDecoration(

                  hintText: "Correo electrónico",

                  prefixIcon: const Icon(Icons.email_outlined),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),


              const SizedBox(height: 18),

              TextField(

                controller: passwordController,

                obscureText: true,

                decoration: InputDecoration(

                  hintText: "Contraseña",

                  prefixIcon: const Icon(Icons.lock_outline),

                  filled: true,
                  fillColor: Colors.white,

                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton(

                  onPressed: login,

                  style: ElevatedButton.styleFrom(

                    backgroundColor: Colors.deepPurple,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  child: const Text(
                    "Iniciar sesión",
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              TextButton(

                onPressed: () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterScreen(),
                    ),
                  );

                },

                child: const Text(

                  "Crear cuenta",

                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
              ),

              TextButton(

                onPressed: recuperarPassword,

                child: const Text(

                  "¿Olvidaste tu contraseña?",

                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              const Row(
                children: [

                  Expanded(child: Divider()),

                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      "o continuar con",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),

                  Expanded(child: Divider()),

                ],
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton.icon(

                  onPressed: loginGoogle,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,

                    elevation: 3,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  icon: const Icon(Icons.g_mobiledata, size: 32),

                  label: const Text(
                    "Continuar con Google",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 58,

                child: ElevatedButton.icon(

                  onPressed: entrarComoInvitado,

                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),

                  icon: const Icon(Icons.person_outline),

                  label: const Text(
                    "Entrar como invitado",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),



            ],
          ),
        ),
      ),
    );
  }
}