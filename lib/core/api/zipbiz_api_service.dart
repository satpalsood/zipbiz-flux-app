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
    if (user != null && user.id != null) {
      headers['X-User-ID'] = user.id.toString();
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
  Future<List<Map<String, dynamic>>> getSlotAvailability(int listingId, String date, {int? interval}) async {
    var endpoint = '$_baseUrl/booking/availability?listing_id=$listingId&date=$date';
    if (interval != null && interval > 0) {
      endpoint += '&interval=$interval';
    }
    final url = Uri.parse(endpoint);
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

  /// Customer: Get customer bookings (bookings made by user as a customer)
  Future<List<dynamic>> getCustomerBookings({
    required User user,
    String status = 'all',
  }) async {
    final url = Uri.parse('$_baseUrl/customer/bookings?status=$status');
    final response = await http.get(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List?) ?? [];
    } else {
      throw Exception(data['message'] ?? 'Failed to load bookings');
    }
  }

  /// Vendor: Get all listings created by vendor
  Future<List<dynamic>> getVendorListings({
    required User user,
    int page = 1,
    int perPage = 20,
    String status = 'any',
  }) async {
    final url = Uri.parse('$_baseUrl/vendor/listings?page=$page&per_page=$perPage&status=$status');
    final response = await http.get(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List?) ?? [];
    } else {
      throw Exception(data['message'] ?? 'Failed to load vendor listings');
    }
  }

  /// Vendor: Create new listing
  Future<Map<String, dynamic>> createVendorListing({
    required User user,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse('$_baseUrl/vendor/listing/create');
    final response = await http.post(url, headers: _getHeaders(user), body: jsonEncode(data));
    final res = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300 && res['success'] == true) {
      return (res['data'] as Map<String, dynamic>?) ?? {};
    } else {
      throw Exception(res['message'] ?? 'Failed to create listing');
    }
  }

  /// Vendor: Update listing
  Future<Map<String, dynamic>> updateVendorListing({
    required User user,
    required int id,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse('$_baseUrl/vendor/listing/$id/update');
    final response = await http.post(url, headers: _getHeaders(user), body: jsonEncode(data));
    final res = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300 && res['success'] == true) {
      return (res['data'] as Map<String, dynamic>?) ?? {};
    } else {
      throw Exception(res['message'] ?? 'Failed to update listing');
    }
  }

  /// Vendor: Delete listing
  Future<bool> deleteVendorListing({
    required User user,
    required int id,
  }) async {
    final url = Uri.parse('$_baseUrl/vendor/listing/$id/delete');
    final response = await http.post(url, headers: _getHeaders(user));
    final res = jsonDecode(response.body);
    return response.statusCode == 200 && res['success'] == true;
  }

  /// Vendor: Get Wallet stats and payout history
  Future<Map<String, dynamic>> getVendorWallet(User user) async {
    final url = Uri.parse('$_baseUrl/vendor/wallet');
    final response = await http.get(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as Map<String, dynamic>?) ?? {};
    } else {
      throw Exception(data['message'] ?? 'Failed to load wallet');
    }
  }

  /// Vendor: Request withdrawal
  Future<Map<String, dynamic>> requestVendorWithdrawal({
    required User user,
    required double amount,
    required String method,
    required Map<String, dynamic> details,
  }) async {
    final url = Uri.parse('$_baseUrl/vendor/wallet/withdraw');
    final body = jsonEncode({
      'amount': amount,
      'method': method,
      'details': details,
    });
    final response = await http.post(url, headers: _getHeaders(user), body: body);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as Map<String, dynamic>?) ?? {};
    } else {
      throw Exception(data['message'] ?? 'Failed to submit withdrawal request');
    }
  }

  /// Vendor: Reviews
  Future<List<dynamic>> getVendorReviews(User user) async {
    final url = Uri.parse('$_baseUrl/vendor/reviews');
    final response = await http.get(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List?) ?? [];
    } else {
      throw Exception(data['message'] ?? 'Failed to load reviews');
    }
  }

  /// Vendor: Bookmarks
  Future<Map<String, dynamic>> getVendorBookmarks(User user) async {
    final url = Uri.parse('$_baseUrl/vendor/bookmarks');
    final response = await http.get(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as Map<String, dynamic>?) ?? {};
    } else {
      throw Exception(data['message'] ?? 'Failed to load bookmarks');
    }
  }

  /// Vendor: Coupons
  Future<List<dynamic>> getVendorCoupons(User user) async {
    final url = Uri.parse('$_baseUrl/vendor/coupons');
    final response = await http.get(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List?) ?? [];
    } else {
      throw Exception(data['message'] ?? 'Failed to load coupons');
    }
  }

  /// Vendor: Create Coupon
  Future<Map<String, dynamic>> createVendorCoupon({
    required User user,
    required Map<String, dynamic> data,
  }) async {
    final url = Uri.parse('$_baseUrl/vendor/coupons/create');
    final response = await http.post(url, headers: _getHeaders(user), body: jsonEncode(data));
    final res = jsonDecode(response.body);

    if (response.statusCode == 200 && res['success'] == true) {
      return (res['data'] as Map<String, dynamic>?) ?? {};
    } else {
      throw Exception(res['message'] ?? 'Failed to create coupon');
    }
  }

  /// Messages: Get conversations list
  Future<List<dynamic>> getConversations(User user) async {
    final url = Uri.parse('$_baseUrl/messages/conversations');
    final response = await http.get(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as List?) ?? [];
    } else {
      throw Exception(data['message'] ?? 'Failed to load conversations');
    }
  }

  /// Messages: Get message thread with partner
  Future<Map<String, dynamic>> getMessageThread({
    required User user,
    required int recipientId,
  }) async {
    final url = Uri.parse('$_baseUrl/messages/$recipientId');
    final response = await http.get(url, headers: _getHeaders(user));
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as Map<String, dynamic>?) ?? {};
    } else {
      throw Exception(data['message'] ?? 'Failed to load message thread');
    }
  }

  /// Messages: Send message
  Future<Map<String, dynamic>> sendMessage({
    required User user,
    required int recipientId,
    required String message,
    int listingId = 0,
  }) async {
    final url = Uri.parse('$_baseUrl/messages/send');
    final body = jsonEncode({
      'recipient_id': recipientId,
      'message': message,
      'listing_id': listingId,
    });
    final response = await http.post(url, headers: _getHeaders(user), body: body);
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as Map<String, dynamic>?) ?? {};
    } else {
      throw Exception(data['message'] ?? 'Failed to send message');
    }
  }

  /// Check if customer has an approved/confirmed booking with vendor or for a listing
  Future<bool> hasConfirmedBooking({
    required User user,
    int? vendorId,
    int? listingId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (vendorId != null && vendorId > 0) {
        queryParams['vendor_id'] = vendorId.toString();
      }
      if (listingId != null && listingId > 0) {
        queryParams['listing_id'] = listingId.toString();
      }
      final uri = Uri.parse('$_baseUrl/customer/has-confirmed-booking')
          .replace(queryParameters: queryParams);
      final response = await http.get(uri, headers: _getHeaders(user));
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return data['data']?['has_confirmed'] == true;
      }
    } catch (_) {}
    return false;
  }

  /// Get vendor configuration (listing types, commission, moderation)
  Future<Map<String, dynamic>> getVendorConfig(User user) async {
    try {
      final url = Uri.parse('$_baseUrl/vendor/config');
      final response = await http.get(url, headers: _getHeaders(user));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return (data['data'] as Map<String, dynamic>?) ?? {};
      }
    } catch (_) {}
    return {
      'listing_types': [
        {'id': 'service', 'name': 'Service'},
        {'id': 'rent', 'name': 'Rent'},
      ],
      'commission_rate': 15.0,
      'approval_status': 'pending',
    };
  }

  /// Upload media to WordPress Media Library
  Future<Map<String, dynamic>> uploadMedia({
    required User user,
    String? base64Data,
    String? fileName,
  }) async {
    final url = Uri.parse('$_baseUrl/media/upload');
    final body = jsonEncode({
      if (base64Data != null) 'base64_data': base64Data,
      if (fileName != null) 'file_name': fileName,
    });
    final response = await http.post(url, headers: _getHeaders(user), body: body);
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
      return (data['data'] as Map<String, dynamic>?) ?? {};
    } else {
      throw Exception(data['message'] ?? 'Failed to upload media');
    }
  }

  /// Get vendor packages & status
  Future<Map<String, dynamic>> getVendorPackages(User user) async {
    try {
      final url = Uri.parse('$_baseUrl/vendor/packages');
      final response = await http.get(url, headers: _getHeaders(user));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return (data['data'] as Map<String, dynamic>?) ?? {};
      }
    } catch (_) {}
    return {
      'packages': [],
      'user_packages': [],
      'can_add_listing': true,
      'current_listings': 0,
    };
  }

  /// Select free Silver package
  Future<Map<String, dynamic>> selectFreeVendorPackage(User user, int productId) async {
    final url = Uri.parse('$_baseUrl/vendor/packages/select-free');
    final body = jsonEncode({'product_id': productId});
    final response = await http.post(url, headers: _getHeaders(user), body: body);
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300 && data['success'] == true) {
      return (data['data'] as Map<String, dynamic>?) ?? {};
    } else {
      throw Exception(data['message'] ?? 'Failed to activate free package');
    }
  }

  /// Get dynamic listing form fields and taxonomies
  Future<Map<String, dynamic>> getListingFormFields(User user, {String type = 'service'}) async {
    try {
      final url = Uri.parse('$_baseUrl/vendor/listing-form-fields?type=$type');
      final response = await http.get(url, headers: _getHeaders(user));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return (data['data'] as Map<String, dynamic>?) ?? {};
      }
    } catch (_) {}
    return {'fields': {}, 'categories': [], 'regions': []};
  }
}
