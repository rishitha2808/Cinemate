
import 'package:cloud_firestore/cloud_firestore.dart';

class MovieService {
  static const String movieKey = 'cinemate_movies';

  static final CollectionReference<Map<String, dynamic>> movieCollection =
      FirebaseFirestore.instance.collection('movies');

  static Future<List<Map<String, dynamic>>> getMovies() async {
    final snapshot = await movieCollection.get();

    return snapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'id': doc.id,
        'title': data['title'] ?? '',
        'poster': data['poster'] ?? '',
        'timings': _getTimings(data['timings'] ?? data['Timings']),
        'price': data['price'] ?? data['Price'] ?? 0,
      };
    }).toList();
  }

  static List<String> _getTimings(dynamic value) {
    if (value is List) {
      return value
          .expand((item) => item.toString().split(','))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return [];
  }

  static Future<void> saveMovies(
      List<Map<String, dynamic>> movies) async {
    final batch = FirebaseFirestore.instance.batch();

    for (final movie in movies) {
      final id = movie['id']?.toString();

      final docRef = id != null && id.isNotEmpty
          ? movieCollection.doc(id)
          : movieCollection.doc();

      batch.set(docRef, {
        'title': movie['title'] ?? '',
        'poster': movie['poster'] ?? '',
        'timings': _getTimings(movie['timings']),
        'price': movie['price'] ?? 0,
      });
    }

    await batch.commit();
  }
}
