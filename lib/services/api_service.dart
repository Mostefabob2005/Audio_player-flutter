import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class ApiService {
  static const String baseUrl = 'https://quran.yousefheiba.com/en';

  Future<List<Category>> fetchCategories() async {
    final response = await http.get(Uri.parse('$baseUrl/surahs'));
    if (response.statusCode == 200) {
      List data = json.decode(response.body);
      return data.map((json) => Category.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load categories');
    }
  }

  Future<List<Track>> fetchTracksByCategory(int surahId) async {
    final response = await http.get(Uri.parse('$baseUrl/surah/$surahId'));
    if (response.statusCode == 200) {
      Map data = json.decode(response.body);
      List ayahs = data['ayahs'];
      return ayahs.map((json) => Track.fromJson(json, surahId)).toList();
    } else {
      throw Exception('Failed to load tracks');
    }
  }
}