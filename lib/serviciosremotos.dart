import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

var baseremota = FirebaseFirestore.instance;
var carpetaRemota = FirebaseStorage.instance;

class DB{
  static Future<String> creaEvento(Map<String, dynamic> evento) async {
    DocumentReference eventoRef = await baseremota.collection("eventos").add(evento);
    return eventoRef.id;
  }

  static Future<void> eliminarEvento(String id) async {
    await baseremota.collection("eventos").doc(id).delete();
  }

  static Future<void> eliminarInvitado(String idEvento, String idInvitado) async {
    try {
      // Obtener una referencia al documento del evento
      DocumentReference eventoRef = FirebaseFirestore.instance.collection('eventos').doc(idEvento);

      // Obtener el documento actual
      DocumentSnapshot eventoSnapshot = await eventoRef.get();

      if (eventoSnapshot.exists) {
        // Obtener los datos actuales del evento
        Map<String, dynamic> datosEvento = eventoSnapshot.data() as Map<String, dynamic>;

        // Obtener la lista de invitados
        List<dynamic> invitados = datosEvento['invitados'] ?? [];

        // Eliminar el idInvitado de la lista de invitados
        invitados.remove(idInvitado);

        // Actualizar el campo 'invitados' en Firestore
        await eventoRef.update({'invitados': invitados});

        print('Invitado eliminado correctamente.');
      } else {
        print('El evento con ID $idEvento no existe.');
      }
    } catch (error) {
      print('Error al eliminar el invitado: $error');
    }
  }

  static Future<String> creaUsuario(Map<String, dynamic> usuario) async {
    DocumentReference eventoRef = await baseremota.collection("usuarios").add(usuario);
    return eventoRef.id;
  }

  static Future<List<String>> recuperarDatos(String uid) async {
    var query = await baseremota.collection("usuarios").where('idUsuario', isEqualTo: uid).get();
    List<String> temporal = List.filled(2, ''); // Inicializa la lista con dos elementos vacíos.

    query.docs.forEach((element) {
      Map<String, dynamic> mapa = element.data();
      temporal[0] = mapa['nombre'];
      temporal[1] = mapa['nickname'];
    });

    return temporal;
  }

  static Future<void> actualizarDatosUsuario(String uid, String nuevoNombre, String nuevoNickname) async {
    try {
      var query = await baseremota.collection("usuarios").where('idUsuario', isEqualTo: uid).get();
      if (query.docs.isNotEmpty) {
        // Obtener el ID del primer documento que cumple con la consulta
        var idDocumento = query.docs.first.id;
        await baseremota.collection("usuarios").doc(idDocumento).update({
          'nombre': nuevoNombre,
          'nickname': nuevoNickname,
        });
        print("No hay al encontrar el documento del usuario $uid");
      } else {
        print("Error al encontrar el documento del usuario $uid");
        return null;
      }
    } catch (e) {
      print("Error al obtener el ID del documento: $e");
      return null;
    }
  }

  static Future<List> misEventos(String uid) async{
    List temp = [];
    var query = await baseremota.collection("eventos").where('propietario', isEqualTo: uid).get();

    query.docs.forEach((element) {
      Map<String, dynamic> dato = element.data();
      dato.addAll({
        'id': element.id
      });

      temp.add(dato);
    });

    return temp;
  }

  static Future<List> misInvitaciones(String uid) async{
    List temp = [];
    var query = await baseremota.collection("eventos").where('invitados', arrayContains: uid).where('estatus', isEqualTo: true).get();

    query.docs.forEach((element) {
      Map<String, dynamic> dato = element.data();
      dato.addAll({
        'id': element.id
      });

      temp.add(dato);
    });

    return temp;
  }

  static Future<List> buscarInvitacion(String idinvitacion) async {
    List temp = [];

    try {
      var documento = await baseremota.collection("eventos").doc(idinvitacion).get();

      if (documento.exists) {
        // El documento existe, puedes acceder a sus datos
        var datos = documento.data();
        print("Datos del documento con ID $idinvitacion: $datos");

        temp.add(documento.data());
        print(temp);
      } else {
        // El documento no existe
        print("No se encontró ningún documento con el ID $idinvitacion");
      }


    } catch (e) {
      // Manejar el error según sea necesario
      print("Error al obtener el documento: $e");
    }

    return temp;

  }

  static Future agregarInvitado(String id, String uid) async {
    try {
      // Referencia al documento en la colección "eventos"
      var referenciaEvento = await baseremota.collection("eventos").doc(id).get().then((value) {
        if (value.exists) {
          // Verificar si el documento existe antes de acceder a sus datos
          Map<String, dynamic>? mapa = value.data();

          if (mapa != null && mapa.isNotEmpty) {
            List<dynamic> idInvitado = mapa['invitados'] ?? [];
            idInvitado.add(uid);

            baseremota.collection("eventos").doc(id).update({'invitados': idInvitado});
          } else {
            print("El documento está vacío o no contiene datos.");
          }
        } else {
          print("El documento con ID $id no existe.");
        }
      });

      print("Invitado agregado con éxito al evento con ID $id");
    } catch (e) {
      // Manejar el error según sea necesario
      print("Error al agregar invitado: $e");
    }
  }

  static Future cambiarEstado(String id) async {
    try {
      // Referencia al documento en la colección "eventos"
      var referenciaEvento = await baseremota.collection("eventos").doc(id).get();

      if (referenciaEvento.exists) {
        // Verificar si el documento existe antes de acceder a sus datos
        Map<String, dynamic>? mapa = referenciaEvento.data();

        if (mapa != null && mapa.isNotEmpty) {
          // Cambiar el valor del campo "estatus" a false
          var valor = !mapa['estatus'];
          baseremota.collection("eventos").doc(id).update({'estatus': valor});
        } else {
          print("El documento está vacío o no contiene datos.");
        }
      } else {
        print("El documento con ID $id no existe.");
      }

      print("Evento cerrado con éxito. Campo 'estatus' cambiado a false.");
    } catch (e) {
      // Manejar el error según sea necesario
      print("Error al cerrar el evento: $e");
    }
  }

  static Future<bool?> obtenerEstado(String id) async {
    try {
      // Referencia al documento en la colección "eventos"
      var referenciaEvento = await baseremota.collection("eventos").doc(id).get();

      if (referenciaEvento.exists) {
        // Verificar si el documento existe antes de acceder a sus datos
        Map<String, dynamic>? mapa = referenciaEvento.data();

        if (mapa != null && mapa.isNotEmpty && mapa.containsKey('estatus')) {
          // Obtener el valor actual del campo "estatus"
          var estado = mapa['estatus'];
          return estado;
        } else {
          print("El documento está vacío, no contiene datos o no tiene el campo 'estatus'.");
          return null; // Indica que no se pudo obtener el estado
        }
      } else {
        print("El documento con ID $id no existe.");
        return null; // Indica que no se pudo obtener el estado
      }
    } catch (e) {
      // Manejar el error según sea necesario
      print("Error al obtener el estado del evento: $e");
      return null; // Indica que no se pudo obtener el estado
    }
  }
}

class CR{
  static Future subirArchivo(String path, String nombreImagen, String nombreCarpeta) async {
    var file = File(path);

    return await carpetaRemota.ref("$nombreCarpeta/$nombreImagen").putFile(file);
  }

  static Future<ListResult> mostrarTodos( nombreCarpeta) async{
    String carpeta = nombreCarpeta;
    return await carpetaRemota.ref(carpeta).listAll();
  }

  static Future<String> obtenerURLimagen(String nombreCarpeta,String nombre)async{
    return await carpetaRemota.ref("$nombreCarpeta/$nombre").getDownloadURL();
  }

  static Future<void> eliminarImagen(String nombreCarpeta, String nombreImagen) async {
    try {
      // Obtener la referencia del archivo a eliminar
      var referenciaArchivo = carpetaRemota.ref("$nombreCarpeta/$nombreImagen");

      // Eliminar el archivo
      await referenciaArchivo.delete();

      print("Imagen eliminada correctamente.");
    } catch (error) {
      print("Error al eliminar la imagen: $error");
      // Puedes manejar el error de acuerdo a tus necesidades
    }
  }

  static Future<String?> obtenerPrimeraImagenDeAlbum(String nombreCarpeta) async {
    try {
      // Obtén la lista de elementos en la carpeta (imágenes)
      ListResult result = await carpetaRemota.ref(nombreCarpeta).list();

      // Ordena las imágenes por nombre
      result.items.sort((a, b) => a.name.compareTo(b.name));

      // Si hay al menos una imagen, devuelve la URL de la primera
      if (result.items.isNotEmpty) {
        return await result.items.first.getDownloadURL();
      } else {
        // Si no hay imágenes, puedes devolver una URL predeterminada o null
        return null;
      }
    } catch (e) {
      print('Error al obtener la primera imagen del álbum: $e');
      return null;
    }
  }

}








