import 'package:agenda_digital/login.dart';
import 'package:agenda_digital/serviciosremotos.dart';
import 'package:agenda_digital/eventoIndividual.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

class inicioApp extends StatefulWidget {
  const inicioApp({super.key});

  @override
  State<inicioApp> createState() => _inicioAppState();
}

class _inicioAppState extends State<inicioApp> {
  String titulo = "Agenda",
      nombre_usuario = "User",
      abreviatura = "U";
  List eventos = [
    "Bautizo",
    "Fiesta de cumpleaños",
    "Boda",
    "XV Años",
    "Primera comunión"
  ];
  String eventoSeleccionado = "";
  String uid = "";
  int _index = 0;
  String msjBuscar = "";

  final descripcion = TextEditingController();
  final fechaInicio = TextEditingController();
  final tipoEvento = TextEditingController();
  final fechaFinal = TextEditingController();
  final numInvitacion = TextEditingController();

  String propietario = "";
  String des = "";
  String fini = "";
  String ffin = "";
  String tevento = "";

  @override
  void setUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      uid = user.uid;
      print("Sesion iniciada con el ID: $uid");
      List<String> datosUsuario = await DB.recuperarDatos(uid);

      setState(() {
        uid = user.uid;
        nombre_usuario = datosUsuario[0];
        abreviatura = datosUsuario[1];
      });
    }
  }

  void initState() {
    setUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:  Text(titulo, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500,),),
        centerTitle: true,
        backgroundColor: Colors.blue,
        shadowColor: Colors.grey,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF3498DB),
                Color.fromARGB(256, 55, 199, 250),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: dinamico(),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white,
                    child: Text(
                      abreviatura,
                      style: TextStyle(fontSize: 20, color: Colors.blue),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Text(
                    nombre_usuario,
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  )
                ],
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF4C60AF),
                    Color.fromARGB(255, 37, 195, 248),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            _item(Icons.event, "MIS EVENTOS", 0),
            _item(Icons.mode_of_travel_outlined, "MIS INVITACIONES", 1),
            _item(Icons.add, "AGREGAR EVENTO", 2),
            _item(Icons.create_new_folder, "CREAR EVENTO", 3),
            _item(Icons.settings, "CONFIGURACIÓN", 4),
            _item(Icons.exit_to_app, "SALIR", 5),
          ],
        ),
      ),
    );
  }

  Widget _item(IconData icono, String texto, int indice) {
    return ListTile(
      onTap: () {
        setState(() {
          _index = indice;
        });
        Navigator.pop(context);
      },
      title: Row(
        children: [
          Expanded(child: Icon(icono)),
          Expanded(
            child: Text(texto),
            flex: 3,
          )
        ],
      ),
    );
  }

  Widget dinamico() {
    if (_index == 1) {
      return invitaciones();
    }
    if (_index == 2) {
      return agregarEvento();
    }
    if (_index == 3) {
      return crearEvento();
    }
    if (_index == 4) {
      return configuracion();
    }
    if (_index == 5) {
      // Navegar a la pantalla de login y reemplazar la actual
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (builder) {
            return login();
          }),
        );
      });
    }
    return misEventos();
  }

  Widget misEventos() {
    return FutureBuilder(
      future: DB.misEventos(uid),
      builder: (context, listaJSON) {
        if (listaJSON.hasData) {
          print("Eventos encontrados: ${listaJSON.data} para el usuario $uid");
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 30),
              Text(
                "MIS EVENTOS",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 40,
                  fontFamily: 'BebasNeue',
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: listaJSON.data?.length,
                  itemBuilder: (context, indice) {
                    return FutureBuilder(
                      future: CR.obtenerPrimeraImagenDeAlbum(
                        '${listaJSON.data?[indice]['id']}',
                      ),
                      builder: (context, snapshot) {
                        String primeraImagen = snapshot.data ?? '';

                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => eventoIndividual(
                                    descripcion: listaJSON.data?[indice]['descripcion'] ?? '',
                                    tipoEvento: listaJSON.data?[indice]['tipoEvento'] ?? '',
                                    propietario: listaJSON.data?[indice]['nombrePropietario'] ?? '',
                                    id: listaJSON.data?[indice]['id'] ?? '',
                                    isMine: listaJSON.data?[indice]['propietario'] == uid,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    topRight: Radius.circular(15),
                                  ),
                                  child: Image.network(
                                    primeraImagen.isNotEmpty
                                        ? primeraImagen
                                        : "https://img.freepik.com/vector-premium/icono-galeria-fotos-vectorial_723554-144.jpg?w=2000",
                                    width: double.infinity,
                                    height: 130,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        listaJSON.data?[indice]['descripcion'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        "${listaJSON.data?[indice]['tipoEvento']}",
                                        style: TextStyle(
                                          fontSize: 16,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          IconButton(
                                              onPressed: (){
                                                Clipboard.setData(
                                                  ClipboardData(
                                                    text: "${listaJSON.data?[indice]['id']}",
                                                  ),
                                                );
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text("Código de invitación copiado al portapapeles."),
                                                  ),
                                                );
                                              },
                                              icon: Icon(Icons.copy, color: Colors.black87,)
                                          ),
                                          SizedBox(width: 20,),
                                          IconButton(
                                              onPressed: (){
                                                showDialog(
                                                  context: context,
                                                  builder: (context) {
                                                    return AlertDialog(
                                                      title: Center(
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(Icons.warning_amber_outlined, color: Colors.red),
                                                            SizedBox(width: 8),
                                                            Text("Comprobar eliminación.", style: TextStyle(color: Colors.red)),
                                                          ],
                                                        ),
                                                      ),
                                                      content: Column(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Text(
                                                            "¿Está seguro de eliminar el evento?",
                                                            style: TextStyle(fontSize: 16),
                                                          ),
                                                          SizedBox(height: 8),
                                                          Text(
                                                            "${listaJSON.data?[indice]['descripcion']}",
                                                            style: TextStyle(fontWeight: FontWeight.bold),
                                                          ),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            DB.eliminarEvento("${listaJSON.data?[indice]['id']}").then((value) {
                                                              setState(() {});
                                                            });
                                                            Navigator.of(context).pop(); // Cerrar el AlertDialog
                                                          },
                                                          child: Text("Aceptar"),
                                                        ),
                                                        TextButton(
                                                          onPressed: () {
                                                            setState(() {
                                                              _index = 0;
                                                            });
                                                            Navigator.of(context).pop(); // Cerrar el AlertDialog
                                                          },
                                                          child: Text("Cancelar"),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                              icon: Icon(Icons.close, color: Colors.red,)
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget formaEventos(IconData icono, String texto, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        primary: Colors.blue,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono),
          SizedBox(height: 10),
          Text(texto),
        ],
      ),
    );
  }

  Widget agregarEvento() {
    return ListView(
      padding: EdgeInsets.all(40),
      children: [
        Center(
          child: Text(
            "AGREGAR EVENTO",
            style: TextStyle(
              fontSize: 25,
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 20),
        TextField(
          controller: numInvitacion,
          decoration: InputDecoration(
            labelText: "NUMERO DE INVITACION:",
            border: OutlineInputBorder(),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            suffixIcon: Icon(Icons.event),
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: () async {
            try {
              List<dynamic> jsonTemporal = await DB.buscarInvitacion(numInvitacion.text);

              setState(() {
                propietario = "Propietario: ${jsonTemporal[0]['nombrePropietario']}";
                des = "Descripcion: ${jsonTemporal[0]['descripcion']}";
                fini = "Fecha Inicio: ${jsonTemporal[0]['fechainicio']}";
                ffin = "Fecha final: ${jsonTemporal[0]['fechafinal']}";
                tevento = "Tipo de evento: ${jsonTemporal[0]['tipoEvento']}";
              });
            } catch (error) {
              print("Error al buscar invitación: $error");
              // Puedes mostrar un mensaje de error al usuario si es necesario
            }
          },
          child: Text("BUSCAR"),
        ),
        SizedBox(height: 20),
        Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${propietario}", style: TextStyle(fontFamily: 'Oswald', fontSize: 17)),
              SizedBox(height: 8.0),
              Text("$des", style: TextStyle(fontFamily: 'Oswald', fontSize: 17)),
              SizedBox(height: 8.0),
              Text("$fini", style: TextStyle(fontFamily: 'Oswald', fontSize: 17)),
              SizedBox(height: 8.0),
              Text("$ffin", style: TextStyle(fontFamily: 'Oswald', fontSize: 17)),
              SizedBox(height: 8.0),
              Text("$tevento", style: TextStyle(fontFamily: 'Oswald', fontSize: 17)),
            ],
          ),
        ),
        ElevatedButton(
          onPressed: ()  {
            try {
              DB.agregarInvitado(numInvitacion.text, uid).then((value) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Evento agregado")));
                setState(() {
                  numInvitacion.text = "";
                  propietario = "";
                  des = "";
                  fini = "";
                  ffin = "";
                  tevento = "";
                  _index = 1;
                });
              });

            } catch (error) {
              print("Error al agregar invitado: $error");
              // Puedes mostrar un mensaje de error al usuario si es necesario
            }
          },
          child: Text("AGREGAR"),
        ),
      ],
    );
  }

  Widget invitaciones() {
    return FutureBuilder(
      future: DB.misInvitaciones(uid),
      builder: (context, listaJSON) {
        if (listaJSON.hasData) {
          print("Invitaciones encontradas: ${listaJSON.data} para el usuario $uid");
          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: 30),
              Text(
                "MIS INVITACIONES",
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 40,
                  fontFamily: 'BebasNeue',
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: listaJSON.data?.length,
                  itemBuilder: (context, indice) {
                    return FutureBuilder(
                      future: CR.obtenerPrimeraImagenDeAlbum(
                        '${listaJSON.data?[indice]['id']}',
                      ),
                      builder: (context, snapshot) {
                        String primeraImagen = snapshot.data ?? '';

                        return Card(
                          elevation: 5,
                          margin: EdgeInsets.all(10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => eventoIndividual(
                                    descripcion: listaJSON.data?[indice]['descripcion'] ?? '',
                                    tipoEvento: listaJSON.data?[indice]['tipoEvento'] ?? '',
                                    propietario: listaJSON.data?[indice]['nombrePropietario'] ?? '',
                                    id: listaJSON.data?[indice]['id'] ?? '',
                                    isMine: listaJSON.data?[indice]['propietario'] == uid,
                                  ),
                                ),
                              );
                            },
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Mostrar la primera imagen si está disponible, de lo contrario, mostrar la imagen genérica
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(15),
                                    topRight: Radius.circular(15),
                                  ),
                                  child: Image.network(
                                    primeraImagen.isNotEmpty
                                        ? primeraImagen
                                        : "https://img.freepik.com/vector-premium/icono-galeria-fotos-vectorial_723554-144.jpg?w=2000",
                                    width: double.infinity,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        listaJSON.data?[indice]['descripcion'],
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "${listaJSON.data?[indice]['tipoEvento']}",
                                            style: TextStyle(
                                              fontSize: 16,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return AlertDialog(
                                                    title: Center(
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.warning_amber_outlined, color: Colors.red),
                                                          SizedBox(width: 8),
                                                          Text("Comprobar eliminación.", style: TextStyle(color: Colors.red)),
                                                        ],
                                                      ),
                                                    ),
                                                    content: Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(
                                                          "¿Está seguro de eliminar el evento?",
                                                          style: TextStyle(fontSize: 16),
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          "${listaJSON.data?[indice]['descripcion']}",
                                                          style: TextStyle(fontWeight: FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          DB.eliminarInvitado("${listaJSON.data?[indice]['id']}", uid).then((value) {
                                                            setState(() {});
                                                          });
                                                          Navigator.of(context).pop();
                                                        },
                                                        child: Text("Aceptar"),
                                                      ),
                                                      TextButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            _index = 0;
                                                          });
                                                          Navigator.of(context).pop();
                                                        },
                                                        child: Text("Cancelar"),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            icon: Icon(Icons.close, color: Colors.red,),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

            ],
          );
        }
        return Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget formaInvitaciones(IconData icono, String texto, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        primary: Colors.blue,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono),
          SizedBox(height: 10),
          Text(texto),
        ],
      ),
    );
  }

  Widget crearEvento() {
    return ListView(
      padding: EdgeInsets.all(40),
      children: [
        Center(
          child: Text(
            "EVENTO NUEVO",
            style: TextStyle(
                fontSize: 25, color: Colors.red, fontWeight: FontWeight.bold),
          ),
        ),
        SizedBox(
          height: 20,
        ),
        TextField(
          controller: descripcion,
          decoration: InputDecoration(
              labelText: "DESCRIPCION:",
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always),
        ),
        SizedBox(
          height: 15,
        ),
        DropdownButtonFormField(
          value: eventos.first,
          items: eventos.map((e) {
            return DropdownMenuItem(
              child: Text(e),
              value: e,
            );
          }).toList(),
          onChanged: (item) {
            setState(() {
              eventoSeleccionado = item.toString();
              tipoEvento.text = eventoSeleccionado;
            });
          },
          decoration: InputDecoration(
              labelText: "TIPO DE EVENTO",
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always),
        ),
        SizedBox(
          height: 15,
        ),
        TextField(
          controller: fechaInicio,
          decoration: InputDecoration(
              labelText: "FECHA INICIO:",
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always),
          textAlign: TextAlign.center,
          readOnly: true,
          onTap: () {
            _selectDate(fechaInicio);
          },
        ),
        SizedBox(
          height: 15,
        ),
        TextField(
          controller: fechaFinal,
          decoration: InputDecoration(
              labelText: "FECHA FINAL:",
              border: OutlineInputBorder(),
              floatingLabelBehavior: FloatingLabelBehavior.always),
          textAlign: TextAlign.center,
          readOnly: true,
          onTap: () {
            _selectDate(fechaFinal);
          },
        ),
        SizedBox(
          height: 15,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            ElevatedButton(
              onPressed: () {
                User? user = FirebaseAuth.instance.currentUser;
                var jsonTemporal = {
                  'propietario': user?.uid.toString(),
                  'nombrePropietario': nombre_usuario,
                  'descripcion': descripcion.text,
                  'tipoEvento': tipoEvento.text,
                  'fechainicio': fechaInicio.text,
                  'fechafinal': fechaFinal.text,
                  'estatus': true,
                  'invitados': [],
                };

                DB.creaEvento(jsonTemporal).then((idEvento) {
                  setState(() {
                    descripcion.text = "";
                    tipoEvento.text = "";
                    fechaInicio.text = "";
                    fechaFinal.text = "";
                  });
                  showDialog(
                    context: context,
                    builder: (context) {
                      return Center(
                        child: AlertDialog(
                          title: Text("EVENTO GENERADO"),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("El ID de tu evento es:"),
                              SizedBox(height: 10),
                              SelectableText(idEvento,
                                  style:
                                  TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: idEvento));
                                setState(() {
                                  _index = 0;
                                });
                                Navigator.of(context).pop(); // Cerrar el AlertDialog
                              },
                              child: Text("Copiar enlace"),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _index = 0;
                                });
                                Navigator.of(context).pop(); // Cerrar el AlertDialog
                              },
                              child: Text("Cerrar"),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                });
              },
              child: Text("Crear"),
            ),
            ElevatedButton(
                onPressed: () {
                  setState(() {
                    _index = 0;
                  });
                },
                child: Text("Cancelar")),
          ],
        )
      ],
    );
  }

  Widget configuracion() {
    return ListView(
      padding: EdgeInsets.all(30),
      children: [
        Text(
          "Configuraciones disponibles:",
          style: TextStyle(fontFamily: 'BebasNeue', fontSize: 30),
        ),
        SizedBox(
          height: 20,
        ),
        TextField(
          onChanged: (value) {
            // Actualizar el nombre de usuario en tiempo real
            nombre_usuario = value;
          },
          decoration: InputDecoration(
              labelText: "Nombre de usuario:", border: OutlineInputBorder()),
        ),
        SizedBox(
          height: 20,
        ),
        TextField(
          onChanged: (value) {
            // Actualizar el nombre de usuario en tiempo real
            abreviatura = value;
          },
          decoration: InputDecoration(
              labelText: "Abreviatura de tu usario:",
              border: OutlineInputBorder()),
        ),
        SizedBox(
          height: 20,
        ),
        ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text("Cambios realizados")));
              setState(() {
                DB.actualizarDatosUsuario(uid, nombre_usuario, abreviatura);
              });
            },
            child: const Text("Cambiar")),
      ],
    );
  }

  Future<void> _selectDate(TextEditingController controlador) async {
    DateTime? _picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));

    if (_picked != null) {
      setState(() {
        controlador.text = _picked.toString().split(" ")[0];
      });
    }
  }
}
