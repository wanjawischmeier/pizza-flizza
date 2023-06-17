import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;

class PaypalServices {
  String domain = "https://api.sandbox.paypal.com"; // for sandbox mode
//  String domain = "https://api.paypal.com"; // for production mode

  // change clientId and secret with your own, provided by paypal
  String clientId =
      'ASzjeAgZEhqu2UBjUGD3fnls-IGUmxl6YvwBmvbR8OcyC7KwO5JHRXEJTT6DL3jJT2GRIAUqe5_4TDKP';
  String secret =
      'EKGOohYBQE1UUw7UWFhwZcFtZdhDc2HiEiWE4JdXWrv3Xc-VNSH-eQi5G1E48b3E28z22k9RjLMNcFbr';

  // for getting the access token from Paypal
  Future<String?> getAccessToken() async {
    try {
      String basicAuth =
          'Basic ${base64Encode(utf8.encode('$clientId:$secret'))}';

      var response = await http.post(
        Uri.parse('$domain/v1/oauth2/token?grant_type=client_credentials'),
        headers: {
          'Authorization': basicAuth,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        return body["access_token"];
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, String>?> sendMoney(
      String recipientEmail, double amount) async {
    String? accessToken = await getAccessToken();

    try {
      var response = await http.post(
        Uri.parse('$domain/v1/payments/payouts'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'sender_batch_header': {
            'email_subject': 'Payment from PayPal',
          },
          'items': [
            {
              'recipient_type': 'EMAIL',
              'amount': {
                'value': amount.toString(),
                'currency': 'USD',
              },
              'receiver': recipientEmail,
            },
          ],
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        if (body["links"] != null && body["links"].length > 0) {
          List links = body["links"];

          String executeUrl = "";
          String approvalUrl = "";
          final item = links.firstWhere((o) => o["rel"] == "approval_url",
              orElse: () => null);
          if (item != null) {
            approvalUrl = item["href"];
          }
          final item1 = links.firstWhere((o) => o["rel"] == "execute",
              orElse: () => null);
          if (item1 != null) {
            executeUrl = item1["href"];
          }
          return {"executeUrl": executeUrl, "approvalUrl": approvalUrl};
        }
        return null;
      } else {
        throw Exception(body["message"]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, String>> createPayPalOrder(
      double amount, String recipientEmail) async {
    String? accessToken = await getAccessToken();

    final response = await http.post(
      Uri.parse('$domain/v2/checkout/orders'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'intent': 'CAPTURE',
        "authorizations": [
          {
            "seller_protection": {
              "status": "NOT_ELIGIBLE",
            },
          }
        ],
        'purchase_units': [
          {
            'items': [
              {
                'name': 'Product 1',
                'unit_amount': {
                  'currency_code': 'EUR',
                  'value': '2.00',
                },
                'quantity': '1',
              },
              {
                'name': 'Product 2',
                'unit_amount': {
                  'currency_code': 'EUR',
                  'value': '1.00',
                },
                'quantity': '2',
              },
            ],
            'amount': {
              'currency_code': 'EUR',
              'value': '4.00',
              'breakdown': {
                'item_total': {
                  'currency_code': 'EUR',
                  'value': '4.00',
                },
              },
            },
            'payee': {
              'email_address': recipientEmail,
            },
          },
        ],
        'application_context': {
          "user_action": "PAY_NOW",
          'shipping_preference': 'NO_SHIPPING',
          "return_url": "https://pizzaflizza.com/return",
          "cancel_url": "https://pizzaflizza.com/cancel",
        },
      }),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      return {
        'id': responseData['id'],
        'approve': responseData['links'][1]['href'],
      }; // Return the payment URL
    } else {
      throw Exception(
          'Failed to create PayPal order. Status Code: ${response.statusCode}');
    }
  }

  Future<void> capturePayPalPayment(String orderId) async {
    String? accessToken = await getAccessToken();

    final response = await http.post(
      Uri.parse('$domain/v2/checkout/orders/$orderId/capture'),
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 201) {
      // Payment captured successfully
      print('Payment captured successfully');
    } else {
      throw Exception(
          'Failed to capture PayPal payment. Status Code: ${response.statusCode}');
    }
  }

  // for creating the payment request with Paypal
  Future<Map<String, String>?> createPaypalPayment(
      transactions, accessToken) async {
    try {
      var response = await http.post(Uri.parse('$domain/v1/payments/payment'),
          body: jsonEncode(transactions),
          headers: {
            "content-type": "application/json",
            'Authorization': 'Bearer $accessToken'
          });

      final body = jsonDecode(response.body);
      if (response.statusCode == 201) {
        if (body["links"] != null && body["links"].length > 0) {
          List links = body["links"];

          String executeUrl = "";
          String approvalUrl = "";
          final item = links.firstWhere((o) => o["rel"] == "approval_url",
              orElse: () => null);
          if (item != null) {
            approvalUrl = item["href"];
          }
          final item1 = links.firstWhere((o) => o["rel"] == "execute",
              orElse: () => null);
          if (item1 != null) {
            executeUrl = item1["href"];
          }
          return {"executeUrl": executeUrl, "approvalUrl": approvalUrl};
        }
        return null;
      } else {
        throw Exception(body["message"]);
      }
    } catch (e) {
      rethrow;
    }
  }

  // for executing the payment transaction
  Future<String?> executePayment(url, payerId, accessToken) async {
    try {
      var response = await http.post(url,
          body: jsonEncode({"payer_id": payerId}),
          headers: {
            "content-type": "application/json",
            'Authorization': 'Bearer $accessToken'
          });

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return body["id"];
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
}
