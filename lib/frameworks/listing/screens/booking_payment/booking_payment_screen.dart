import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flux_localization/flux_localization.dart';
import 'package:flux_ui/flux_ui.dart';
import 'package:inspireui/inspireui.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../common/config.dart';
import '../../../../common/extensions/map_extension.dart';
import '../../../../models/app_model.dart';
import '../../../../models/user_model.dart';
import '../../../../modules/native_payment/razorpay/services.dart';
import '../../../../screens/search/widgets/search_empty_result.dart';
import 'booking_payment_method_screen.dart';
import 'booking_payment_model.dart';
import 'payment/paypal/index.dart';
import 'widgets/continue_floating_button.dart';

class BookingPaymentScreen extends StatefulWidget {
  /// Function to refresh the booking history after payment
  final Function? callback;

  const BookingPaymentScreen({super.key, this.callback});

  @override
  State<BookingPaymentScreen> createState() => _BookingPaymentScreenState();
}

class _BookingPaymentScreenState extends State<BookingPaymentScreen>
    with RazorDelegate {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  final _pageController = PageController();
  List<Widget> lstScreen = [];
  int index = 0;

  @override
  void initState() {
    lstScreen.addAll([
      BookingPaymentMethodScreen(),
    ]);
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _updateBooking() async {
    final model = Provider.of<BookingPaymentModel>(context, listen: false);
    await model.updateBookingStatus(true);
    Navigator.pop(context);
    widget.callback!();
  }

  void _makePayment() async {
    final model = Provider.of<BookingPaymentModel>(context, listen: false);
    final paymentMethod = model.lstPaymentMethod[model.index];

    final availablePaypal = kPaypalConfig
            .getValueList('paymentMethodIds')
            .contains(paymentMethod.id) &&
        kPaypalConfig['enabled'] == true;
    if (availablePaypal) {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (context) => PaypalPayment2(
            isExpressCheckout: false,
            booking: model.booking,
            onFinish: (String? payerID, String? token, _) async {
              if (token == null) {
                return;
              } else {
                _updateBooking();
              }
            },
          ),
        ),
      );
      return;
    }

    // if (isNotBlank(kTapConfig['paymentMethodId']) &&
    //     paymentMethod.id!.contains(kTapConfig['paymentMethodId']) &&
    //     kTapConfig['enabled'] == true) {
    //   Navigator.of(context, rootNavigator: true).push(
    //     MaterialPageRoute(
    //         builder: (context) => TapPayment2(
    //               booking: model.booking,
    //               onFinish: (number) async {
    //                 if (number == null) {
    //                   return;
    //                 } else {
    //                   _updateBooking();
    //                 }
    //               },
    //             )),
    //   );
    //   return;
    // }

    final availableRazorpay = kRazorpayConfig
            .getValueList('paymentMethodIds')
            .contains(paymentMethod.id) &&
        kRazorpayConfig['enabled'] == true;
    if (availableRazorpay) {
      final user = Provider.of<UserModel>(context, listen: false).user;
      final razorServices = RazorServices(
        amount: model.booking?.price ?? '0',
        keyId: kRazorpayConfig['keyId'],
        delegate: this,
        userInfo: RazorUserInfo(
          email: user?.email ?? '',
          fullName: user?.fullName,
          phone: user?.billing?.phone ?? '',
        ),
      );
      final appModel = Provider.of<AppModel>(context, listen: false);
      final currencyCode = appModel.currencyCode;
      razorServices.openPayment(currencyCode!);
      return;
    }

    // final availableMyFatoorah = kMyFatoorahConfig['paymentMethodId'] != null &&
    //     (kMyFatoorahConfig['enabled'] ?? false) &&
    //     paymentMethod.id!.contains(kMyFatoorahConfig['paymentMethodId']);
    // if (availableMyFatoorah) {
    //   final user = Provider.of<UserModel>(context, listen: false).user;
    //   final currencyCode =
    //       Provider.of<AppModel>(context, listen: false).currencyCode;
    //   await Navigator.push(
    //     context,
    //     MaterialPageRoute(
    //       builder: (context) => MyFatoorahScreen(
    //         amount: double.parse(model.booking?.price ?? '0'),
    //         currency: currencyCode,
    //         customerAddress: '',
    //         customerName: user?.fullName ?? '',
    //         customerMobile: user?.phoneNumber ?? '',
    //         customerEmail: user?.email ?? '',
    //         orderID: model.booking?.orderId,
    //         onFinish: (String? paymentId) {
    //           if (paymentId != null) {
    //             _updateBooking();
    //           }
    //         },
    //       ),
    //     ),
    //   );

    //   return;
    // }

    // final availableStripe = [
    //       ...(kStripeConfig['paymentMethodIds'] ?? []),
    //       kStripeApplePayMethod,
    //       kStripeGooglePayMethod,
    //     ].contains(paymentMethod.id) &&
    //     kStripeConfig['enabled'] == true;
    // if (availableStripe) {
    // final user = Provider.of<UserModel>(context, listen: false).user;
    // final totalPrice = double.parse(model.booking?.price ?? '0');
    // final appModel = Provider.of<AppModel>(context, listen: false);
    // final currencyCode = appModel.currencyCode!;
    // final smallestUnitRate = appModel.smallestUnitRate ?? 1;
    // final finalPrice =
    //     (totalPrice * smallestUnitRate).round().toStringAsFixed(0);

    // try {
    //   final success = await StripeServicesV2().handlePayment(
    //     context,
    //     orderId: null,
    //     totalPrice: finalPrice,
    //     applePayPrice: totalPrice.toStringAsFixed(2),
    //     useApplePay: paymentMethod.id == kStripeApplePayMethod,
    //     useGooglePay: paymentMethod.id == kStripeGooglePayMethod,
    //     currencyCode: currencyCode,
    //     emailAddress: user?.email ?? '',
    //     name: user?.fullName ?? '',
    //     color: Theme.of(context).primaryColor,
    //     darkMode: Provider.of<AppModel>(context, listen: false).darkTheme,
    //     address: null,
    //     cookie: null,
    //   );

    //   if (!success) {
    //     Tools.showSnackBar(
    //       _scaffoldMessengerKey.currentState,
    //       S.of(context).transactionFailded,
    //     );
    //   } else {
    //     _updateBooking();
    //   }
    // } on StripeException catch (e) {
    //   Tools.showSnackBar(
    //     _scaffoldMessengerKey.currentState,
    //     e.error.localizedMessage ?? S.of(context).transactionFailded,
    //   );
    // } on PlatformException catch (e) {
    //   Tools.showSnackBar(
    //     _scaffoldMessengerKey.currentState,
    //     e.message ?? S.of(context).transactionFailded,
    //   );
    // } catch (e) {
    //   Tools.showSnackBar(
    //     _scaffoldMessengerKey.currentState,
    //     e.toString(),
    //   );
    // }
    // return;
    // }

    if (kCashOnDeliveryConfig
        .getValueList('paymentMethodIds')
        .contains(paymentMethod.id)) {
      _updateBooking();
      return;
    }

    void showCustomBottomSheet({
      required BuildContext context,
      required String description,
      required VoidCallback onPressed,
    }) {
      showModalBottomSheet(
        context: context,
        builder: (sContext) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      S.of(context).cancel,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall!
                          .copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              HtmlWidget(
                description,
                textStyle: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onPressed();
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: Text(
                  S.of(context).ok,
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      );
    }

    if (kBankTransferConfig
        .getValueList('paymentMethodIds')
        .contains(paymentMethod.id)) {
      showCustomBottomSheet(
        context: context,
        description: paymentMethod.description!,
        onPressed: () {
          _updateBooking();
        },
      );
      return;
    }

    final availableThaiPromptPay = kThaiPromptPayConfig
            .getValueList('paymentMethodIds')
            .contains(paymentMethod.id) &&
        kThaiPromptPayConfig['enabled'] == true;
    if (availableThaiPromptPay) {
      showCustomBottomSheet(
        context: context,
        description: paymentMethod.description!,
        onPressed: () {
          _updateBooking();
        },
      );
      return;
    }

    Tools.showSnackBar(_scaffoldMessengerKey.currentState,
        S.of(context).paymentMethodIsNotSupported);
  }

  void nextPage() {
    if (index < lstScreen.length - 1) {
      index++;
      _pageController.animateToPage(index,
          duration: const Duration(milliseconds: 500), curve: Curves.easeIn);
      return;
    }
    _makePayment();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Consumer<BookingPaymentModel>(
      builder: (context, model, _) => Stack(
        fit: StackFit.expand,
        children: [
          ScaffoldMessenger(
            key: _scaffoldMessengerKey,
            child: Scaffold(
              backgroundColor: Theme.of(context).colorScheme.surface,
              appBar: AppBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: Text(S.of(context).paymentMethods),
              ),
              floatingActionButton: ContinueFloatingButton(
                title: S.of(context).continues,
                icon: Icons.arrow_forward_ios,
                onTap: nextPage,
              ),
              floatingActionButtonLocation:
                  FloatingActionButtonLocation.centerDocked,
              body: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: lstScreen,
              ),
            ),
          ),
          if (model.state == BookingPaymentModelState.paymentProcessing)
            Container(
              height: size.height,
              width: size.width,
              color: Colors.grey.withValueOpacity(0.3),
              child: Center(
                child: kLoadingWidget(context),
              ),
            ),
          if (model.state == BookingPaymentModelState.loaded &&
              model.lstPaymentMethod.isEmpty)
            EmptySearch(title: S.of(context).noPaymentMethodsAvailable)
        ],
      ),
    );
  }

  @override
  void handlePaymentFailure(PaymentFailureResponse response) {
    final body = jsonDecode(response.message!);
    if (body['error'] != null &&
        body['error']['reason'] != 'payment_cancelled') {
      Tools.showSnackBar(
        _scaffoldMessengerKey.currentState,
        body['error']['description'],
      );
    }
  }

  @override
  void handlePaymentSuccess(PaymentSuccessResponse response) {
    Tools.showSnackBar(
      _scaffoldMessengerKey.currentState,
      response.paymentId ?? '',
    );
    _updateBooking();
  }
}
