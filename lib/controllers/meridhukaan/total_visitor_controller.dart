import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mcsofttech/controllers/cart/cart_controller.dart';
import 'package:mcsofttech/data/network/apiservices/cart_api_services.dart';
import 'package:provider/provider.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../data/network/apiservices/meridukaan_api_services.dart';
import '../../data/preferences/AppPreferences.dart';
import '../../models/meridukaan/userdashboard/Equiry.dart';
import '../../notifire/cart_notifire.dart';
import '../../ui/module/home/home.dart';
import '../../utils/common_util.dart';
import '../base_getx_controller.dart';

class TotalVisitorController extends BaseController {
  final apiServices = Get.put(MeriDukaanApiServices());
  final cartApiServices = Get.put(CartApiServices());
  final appPreferences = Get.find<AppPreferences>();
  final cartController = Get.find<CartController>();
  RxList<Equiry> get equiryList => cartController.cartList;
  final isLoader = false.obs;
  get totalPrice => cartController.totalValue;

  void callUserDashboardCardCall(String dataType) async {
    // isLoader.value = true;

    // final response = await apiServices.totalVisitor(
    //     userId: appPreferences.userId, dataType: dataType);
    // isLoader.value = false;
    // if (response == null) Common.showToast("Server Error!");
    // if (response != null && response.status == 200) {
    //   // equiryList = response.equiryList;
    //   totalPrice.value = 0;
    //   totalPrice.value = response.totalPrice;
    // }
  }

  Future<void> createOrderId(amount, List<Map<String, dynamic>> items) async {
    showLoader();
    final response = await cartApiServices.createOrderApi(orderItems: items);
    //   cartController.cartList.map((element) {
    // return {"productId": element.product_id, "quantity": element.qunatity};
    // }).toList());
    hideLoader();
    if (response == null) return;
    if (response.statusCode == 200) {
      debugPrint("sonu${response.data} ::${amount * 100}");
      buyNow(response.data?.orderUuid ?? "", amount * 100);
    } else {
      Common.showToast(response.message ?? "");
    }
  }

  Future<void> createOrderIdForBook(amount) async {
    showLoader();
    final response = await apiServices.orderCreate(paidAmount: amount);
    hideLoader();
    if (response == null) return;
    if (response.status == 200) {
      debugPrint("sonu${response.data} ::${amount * 100}");
      buyNow(response.data, amount * 100);
    } else {
      Common.showToast(response.message);
    }
  }

  void buyNow(String orderId, int amount) {
    Razorpay razorpay = Razorpay();
    var options = {
      'key': 'rzp_live_MmKm1tIl8HM05R',
      'amount': amount,
      'name': 'F2DF.',
      'description': '',
      'orderId': orderId,
      'retry': {'enabled': true, 'max_count': 1},
      'send_sms_hash': true,
      'prefill': {
        'contact': appPreferences.mobile,
        'email': appPreferences.email
      },
      'external': {}
    };
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentErrorResponse);
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccessResponse);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWalletSelected);
    razorpay.open(options);
  }

  void handlePaymentErrorResponse(PaymentFailureResponse response) {
    saveTransaction(0, response.code ?? 0, response.error.toString(),
        response.message ?? "", "", totalPrice.value, "", "", false);
    showAlertDialog(Get.context!, "Payment Failed",
        "Code: ${response.code}\nDescription: ${response.message}\nMetadata:${response.error.toString()}");
  }

  void handlePaymentSuccessResponse(PaymentSuccessResponse response) {
    saveTransaction(0, 0, "", "", response.orderId ?? "", totalPrice.value,
        response.paymentId ?? "", response.signature ?? "", false);
    // Provider.of<CartNotifier>(Get.context!, listen: false).clearCart();
  }

  void handleExternalWalletSelected(ExternalWalletResponse response) {
    Home.start(0);
    showAlertDialog(
        Get.context!, "External Wallet Selected", "${response.walletName}");
  }

  void showAlertDialog(BuildContext context, String title, String message) {
    // set up the buttons
    Widget continueButton = ElevatedButton(
      child: const Text("Continue"),
      onPressed: () {
        Get.back();
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void saveTransaction(
      int cartId,
      int code,
      String error,
      String message,
      String orderId,
      int paidAmount,
      String paymentId,
      String signature,
      status) async {
    final response = await apiServices.saveTransaction(
      cartId: cartId,
      code: code,
      error: error,
      message: message,
      orderId: orderId,
      paidAmount: paidAmount,
      paymentId: paymentId,
      signature: signature,
      status: status,
      userId: appPreferences.userId,
    );
    if (response == null) return;
    if (response.status == 200) {
      //Common.showToast(response.message);
    }
  }
}
