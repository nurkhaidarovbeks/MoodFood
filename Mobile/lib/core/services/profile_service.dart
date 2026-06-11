import 'package:dio/dio.dart';
import '../api/api_client.dart';
import '../constants/api_constants.dart';
import '../models/profile_model.dart';

class ProfileService {
  final _client = ApiClient.instance;
  Dio get _dio => _client.dio;

  Future<ProfileModel?> getProfile() async {
    try {
      final res = await _dio.get(ApiConstants.profile);
      if (res.data == null) return null;
      return ProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw _client.handleError(e);
    }
  }

  Future<ProfileModel> upsertProfile(ProfileModel profile) async {
    try {
      final res = await _dio.put(
        ApiConstants.profile,
        data: profile.toJson(),
      );
      return ProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }

  Future<ProfileModel> patchProfile(Map<String, dynamic> updates) async {
    try {
      final res = await _dio.patch(ApiConstants.profile, data: updates);
      return ProfileModel.fromJson(res.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.handleError(e);
    }
  }
}
