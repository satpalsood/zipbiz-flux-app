import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../common/constants.dart';
import '../../models/entities/user.dart';
import '../../services/service_config.dart';

class ZipBizApiService {
  static final ZipBizApiService _instance = ZipBizApiService._internal();
  factory ZipBizApiService() => _instance;
  ZipBizApiService._internal();

  String get _baseUrl => '${ServerConfig().url}/wp-json/zipbiz/v1';

  Map<String, String> _getHeaders(User? user) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (user != null && (user.cookie?.isNotEmpty ?? false)) {
      headers['User-Cookie'] = user.cookie!;
    }
    return headers;
  }

  /// Create booking with server-side pricing and race-condition validation
  Future<Map<String, dynamic>> createBooking({
    required User user,
    required int listingId,
    required String date,
    required String timeSlot,
    required List<dynamic> services,
    required Map<String, dynamic> address,
    String notes = '',
    String paymentMethod = 'cod',
  }) async {
    final url = Uri.parse('$_baseUrl/booking/create');
    final body = jsonEncode({
      'listing_id': listingId,
      'date': date,
      'time_slot': timeSlot,
      'services': services,
      'address': address,
      'notes': notes,
      'payment_method': paymentMethod,
    });

    final response = await http.post(url, headers: _getHeaders(user), body: body);
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
      return data['data'] ?? {};
    } else {
      throw Exception(data['message'] ?? 'Failed to create booking');
    }
  }

  /// Get single booking details
  Future<Map<String, dynamic>> getBookingDetail(int bookingId, User user) async {
    final url = Uri.parse('$_baseUrl/booking/$bookingId');
    final response = await http.get(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? {};
    } else {
      throw Exception(data['message'] ?? 'Failed to load booking');
    }
  }

  /// Get slot availability for a listing on a specific date
  Future<List<Map<String, dynamic>>> getSlotAvailability(int listingId, String date) async {
    final url = Uri.parse('$_baseUrl/booking/availability?listing_id=$listingId&date=$date');
    final response = await http.get(url, headers: {'Accept': 'application/json'});
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final slots = data['data']?['slots'] as List? ?? [];
      return slots.map((s) => Map<String, dynamic>.from(s)).toList();
    }
    return [];
  }

  /// Cancel booking
  Future<bool> cancelBooking(int bookingId, User user) async {
    final url = Uri.parse('$_baseUrl/booking/$bookingId/cancel');
    final response = await http.post(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);
    return response.statusCode == 200 && data['success'] == true;
  }

  /// Create Razorpay order server-side
  Future<Map<String, dynamic>> createRazorpayOrder(int bookingId, User user) async {
    final url = Uri.parse('$_baseUrl/payment/create-order');
    final body = jsonEncode({'booking_id': bookingId});

    final response = await http.post(url, headers: _getHeaders(user), body: body);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? {};
    } else {
      throw Exception(data['message'] ?? 'Failed to initialize payment');
    }
  }

  /// Cryptographic Razorpay signature verification
  Future<Map<String, dynamic>> verifyRazorpayPayment({
    required User user,
    required int bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    final url = Uri.parse('$_baseUrl/payment/verify');
    final body = jsonEncode({
      'booking_id': bookingId,
      'razorpay_order_id': razorpayOrderId,
      'razorpay_payment_id': razorpayPaymentId,
      'razorpay_signature': razorpaySignature,
    });

    final response = await http.post(url, headers: _getHeaders(user), body: body);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? {};
    } else {
      throw Exception(data['message'] ?? 'Payment verification failed');
    }
  }

  /// Vendor: Get KPI stats
  Future<Map<String, dynamic>> getVendorDashboard(User user) async {
    final url = Uri.parse('$_baseUrl/vendor/dashboard');
    final response = await http.get(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? {};
    } else {
      throw Exception(data['message'] ?? 'Failed to load vendor dashboard');
    }
  }

  /// Vendor: Get bookings list
  Future<Map<String, dynamic>> getVendorBookings({
    required User user,
    String status = 'all',
    int page = 1,
    int perPage = 20,
  }) async {
    final url = Uri.parse('$_baseUrl/vendor/bookings?status=$status&page=$page&per_page=$perPage');
    final response = await http.get(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? {'items': [], 'total': 0};
    } else {
      throw Exception(data['message'] ?? 'Failed to load vendor bookings');
    }
  }

  /// Vendor: Action on booking (accept, reject, start, complete)
  Future<bool> updateVendorBookingStatus({
    required User user,
    required int bookingId,
    required String action, // 'accept', 'reject', 'start', 'complete'
  }) async {
    final url = Uri.parse('$_baseUrl/vendor/bookings/$bookingId/$action');
    final response = await http.post(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);
    return response.statusCode == 200 && data['success'] == true;
  }

  /// Vendor: Get earnings report
  Future<Map<String, dynamic>> getVendorEarnings(User user) async {
    final url = Uri.parse('$_baseUrl/vendor/earnings');
    final response = await http.get(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? {};
    } else {
      throw Exception(data['message'] ?? 'Failed to load earnings');
    }
  }

  /// Register device token for FCM
  Future<bool> registerDeviceToken(String token, User user, {String platform = 'android'}) async {
    final url = Uri.parse('$_baseUrl/device-token');
    final body = jsonEncode({
      'token': token,
      'platform': platform,
      'app_version': '1.0.0',
    });
    final response = await http.post(url, headers: _getHeaders(user), body: body);
    final data = jsonDecode(response.body);
    return response.statusCode == 200 && data['success'] == true;
  }
}
