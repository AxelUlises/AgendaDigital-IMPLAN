import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:agenda_digital/serviciosremotos.dart';

class eventoIndividual extends StatefulWidget {
  final String descripcion;
  final String tipoEvento;
  final String id;
  final String propietario;
  final bool isMine;
  eventoIndividual({required this.descripcion, required this.tipoEvento, required this.id, required this.propietario, required this.isMine});

  @override
  State<eventoIndividual> createState() => _eventoIndividualState();
}

class _eventoIndividualState extends State<eventoIndividual> {
  String archivoRemoto = "";
  String estatusEvento = "";

  void setStatus() async {
    bool? estado = await DB.obtenerEstado(widget.id);

    setState(() {
      if(estado==true){
        estatusEvento = "CERRAR EVENTO";
      }else{
        estatusEvento = "ABRIR EVENTO";
      }
    });

  }

  void initState() {
    setStatus();
    super.initState();
  }
  @override

  Widget build(BuildContext context) {

    print("El evento es mio: ${widget.isMine}");
    return Scaffold(
      appBar: AppBar(
        title: Text("EVENTO"),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30),
            Center(
              child: Text(
                "ÁLBUM EVENTO",
                style: TextStyle(color: Colors.red, fontSize: 40, fontFamily: 'BebasNeue'),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.only(left: 30.0),
              child: Text("TIPO DE EVENTO: ${widget.tipoEvento}"),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 30.0),
              child: Text("PROPIEDAD DE:    ${widget.propietario}"),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 30.0),
              child: Text("DESCRIPCIÓN:      ${widget.descripcion}"),
            ),
            SizedBox(height: 10),

            // AQUÍ VAN LAS FOTOS
            Container(
              height: 450,
              child: FutureBuilder(
                future: CR.mostrarTodos(widget.id),
                builder: (context, listaRegreso) {
                  if (listaRegreso.hasData) {
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                      ),
                      itemCount: listaRegreso.data?.items.length,
                      itemBuilder: (context, indice) {
                        final nombreImagen = listaRegreso.data!.items[indice].name;

                        return Padding(
                          padding: EdgeInsets.all(10),
                          child: FutureBuilder(
                            future: CR.obtenerURLimagen(widget.id, nombreImagen),
                            builder: (context, URL) {
                              if (URL.hasData) {
                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        // Almacenar el contexto en una variable local
                                        BuildContext dialogContext = context;

                                        return Dialog(
                                          child: Stack(
                                            children: [
                                              Image.network(URL.data!, fit: BoxFit.contain),
                                              Positioned(
                                                top: 10,
                                                right: 10,
                                                child: Opacity(
                                                  opacity: widget.isMine ? 1.0 : 0.0,
                                                  child: IgnorePointer(
                                                    ignoring: !widget.isMine,
                                                    child: IconButton(
                                                      icon: Icon(Icons.delete, color: Colors.white),
                                                      onPressed: () {
                                                        // BORRAR FOTO
                                                        CR.eliminarImagen(widget.id, nombreImagen).then((value) {
                                                          ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text("IMAGEN ELIMINADA.")));
                                                          setState(() {});

                                                          // Usar la variable dialogContext en lugar de context
                                                          Navigator.of(dialogContext).pop();
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  },

                                  child: Container(
                                    child: Image.network(URL.data!, fit: BoxFit.cover),
                                  ),
                                );
                              } else if (URL.hasError) {
                                return Text('Error loading image');
                              } else {
                                return CircularProgressIndicator();
                              }
                            },
                          ),
                        );
                      },
                    );
                  } else if (listaRegreso.hasError) {
                    // Return an error widget if there is an error
                    return Text('Error loading data');
                  } else {
                    // Return a loading indicator while the future is still in progress
                    return CircularProgressIndicator();
                  }
                },
              ),
            ),
            Center(
              child: Opacity(
                  opacity: widget.isMine ? 1.0 : 0.0, // Si isMine es true, la opacidad es 1.0 (totalmente visible), de lo contrario, 0.0 (totalmente transparente)
                  child: IgnorePointer(
                    ignoring: !widget.isMine,
                    child: ElevatedButton(
                      onPressed: () {
                        DB.cambiarEstado(widget.id).then((value) {
                          setState(() async {
                            bool? estado = await DB.obtenerEstado(widget.id);

                            if (estado == true) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("EVENTO ABIERTO")));
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("EVENTO CERRADO")));
                            }

                            setStatus();
                          });
                        });
                      },
                      child: Text(estatusEvento),
                    ),

                  )
              ),
            )

          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async{
          final archivoAEnviar = await FilePicker.platform.pickFiles(
              allowMultiple: false,
              type: FileType.custom,
              allowedExtensions: ['png','jpg','jpeg']
          );

          if(archivoAEnviar==null){
            setState(() {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("ERROR! No se seleccionó ARCHIVO")));
            });
            return;
          }

          var path = archivoAEnviar.files.single.path!!;
          var nombre = archivoAEnviar.files.single.name!!;
          var nombreCarpeta = widget.id;

          CR.subirArchivo(path, nombre, nombreCarpeta).then((value) {
            setState(() {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("SUBIENDO ARCHIVO")));
            });
          });

        },
        child: Icon(Icons.add),
      ),
    );

  }
}

