import 'package:flutter/cupertino.dart';

import '../../../../common/config.dart';
import '../../../../common/constants.dart';
import '../../../../common/extensions/extensions.dart';
import '../../../../models/entities/index.dart';
import '../../../../models/payment_method_model.dart';
import '../../../../services/index.dart';

enum BookingPaymentModelState { loading, loaded, paymentProcessing }

class BookingPaymentModel extends ChangeNotifier {
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final phoneNumberController = TextEditingController();
  final emailController = TextEditingController();
  final stateController = TextEditingController();
  final cityController = TextEditingController();
  final address1 = TextEditingController();
  final address2 = TextEditingController();
  final zipCodeController = TextEditingController();

  final _services = Services();

  List<PaymentMethod> lstPaymentMethod = [];
  User? user;
  ListingBooking? booking;
  int index = 0;
  var state = BookingPaymentModelState.loading;
  String? langCode;

  BookingPaymentModel({this.user, this.booking, required this.langCode}) {
    _setTextController();
    _getPaymentMethod(langCode);
  }

  void _updateState(state) {
    this.state = state;
    notifyListeners();
  }

  Future<void> _getPaymentMethod(String? langCode) async {
    _updateState(BookingPaymentModelState.loading);
    var list = await _services.api.getPaymentMethods(token: user!.cookie)!;
    for (var element in list) {
      if (kPaypalConfig.isNotEmpty &&
          kPaypalConfig.getValueList('paymentMethodIds').contains(element.id) &&
          kPaypalConfig['enabled'] == true) {
        lstPaymentMethod.add(element);
      }
      if (kRazorpayConfig.isNotEmpty &&
          kRazorpayConfig
              .getValueList('paymentMethodIds')
              .contains(element.id) &&
          kRazorpayConfig['enabled'] == true) {
        lstPaymentMethod.add(element);
      }
      if (kTapConfig.isNotEmpty &&
          kTapConfig.getValueList('paymentMethodIds').contains(element.id) &&
          kTapConfig['enabled'] == true) {
        lstPaymentMethod.add(element);
      }
      if (kStripeConfig.isNotEmpty &&
          kStripeConfig.getValueList('paymentMethodIds').contains(element.id) &&
          kStripeConfig['enabled'] == true) {
        lstPaymentMethod.add(element);

        final shouldShowApplePay = isIos &&
            kStripeConfig['enabled'] == true &&
            kStripeConfig['enableApplePay'] == true;

        if (shouldShowApplePay) {
          lstPaymentMethod.add(PaymentMethod(
            id: kStripeApplePayMethod,
            title: 'Apple Pay',
            enabled: true,
          ));
        }

        final shouldShowGooglePay = isAndroid &&
            kStripeConfig['enabled'] == true &&
            kStripeConfig['enableGooglePay'] == true;
        if (shouldShowGooglePay) {
          lstPaymentMethod.add(
            PaymentMethod(
              id: kStripeGooglePayMethod,
              title: 'Google Pay',
              enabled: true,
            ),
          );
        }
      }
      if (kMyFatoorahConfig.isNotEmpty &&
          kMyFatoorahConfig
              .getValueList('paymentMethodIds')
              .contains(element.id) &&
          kMyFatoorahConfig['enabled'] == true) {
        lstPaymentMethod.add(element);
      }
      if (kThaiPromptPayConfig.isNotEmpty &&
          kThaiPromptPayConfig
              .getValueList('paymentMethodIds')
              .contains(element.id) &&
          kThaiPromptPayConfig['enabled'] == true) {
        lstPaymentMethod.add(element);
      }

      if (kBankTransferConfig
          .getValueList('paymentMethodIds')
          .contains(element.id)) {
        lstPaymentMethod.add(element);
      }

      if (kCashOnDeliveryConfig
          .getValueList('paymentMethodIds')
          .contains(element.id)) {
        lstPaymentMethod.add(element);
      }
    }
    _updateState(BookingPaymentModelState.loaded);
  }

  void updatePaymentMethodIndex(index) {
    this.index = index;
    _updateState(BookingPaymentModelState.loaded);
  }

  void _setTextController() {
    firstNameController.text = user!.firstName ?? '';
    lastNameController.text = user!.lastName ?? '';
    phoneNumberController.text = user!.billing?.phone ?? '';
    emailController.text = user!.email ?? '';
    stateController.text = user!.billing?.state ?? '';
    cityController.text = user!.billing?.city ?? '';
    address1.text = user!.billing?.address1 ?? '';
    address2.text = user!.billing?.address2 ?? '';
    zipCodeController.text = user!.billing?.postCode ?? '';
  }

  Future<Order?> updateBookingStatus(bool isPaid) async {
    _updateState(BookingPaymentModelState.paymentProcessing);
    final order = await _services.api.updateOrder(booking!.orderId,
        status: isPaid ? 'processing' : 'pending', token: null);
    _updateState(BookingPaymentModelState.loaded);
    return order;
  }
}
