import 'package:flutter/material.dart';
import 'package:flutter_credit_card/credit_card_model.dart';
import 'package:flutter_credit_card/credit_card_widget.dart';

import '../../data/user.dart';
import '../../functions.dart';


class CreditCardHandlerMobile extends StatefulWidget {
  final User user;

  const CreditCardHandlerMobile({Key? key, required this.user}) : super(key: key);
  @override
  CreditCardHandlerMobileState createState() =>
      CreditCardHandlerMobileState();
}

class CreditCardHandlerMobileState extends State<CreditCardHandlerMobile>
    with SingleTickerProviderStateMixin
     {
  late AnimationController _controller;
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  var _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
    cardHolderName = widget.user.name!;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        key: _key,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          title: Text(
            'Service Subscription',
            style: Styles.whiteSmall,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(20),
            child: Column(
              children: [
                Text(
                  '${widget.user.organizationName}',
                  style: Styles.whiteSmall,
                ),
                const SizedBox(
                  height: 8,
                )
              ],
            ),
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                CreditCardWidget(
                    cardNumber: cardNumber,
                    expiryDate: expiryDate,
                    cardHolderName: cardHolderName,
                    cvvCode: cvvCode,
                    textStyle: Styles.whiteSmall,
                    cardBgColor: Theme.of(context).primaryColor,
                    showBackView: isCvvFocused, onCreditCardWidgetChange: (creditCardBrand ) {
                      pp('onCreditCardWidgetChange FIRED!! ${creditCardBrand.toString()}');
                },),
                // Expanded(
                //   child: SingleChildScrollView(
                //     child: CreditCardForm(
                //         key: _formKey, onCreditCardModelChange: _onChange),
                //   ),
                // ),
              ],
            ),
            showSubmit
                ? Positioned(
                    right: 12,
                    bottom: 12,
                    child: Container(
                      child: Card(
                        elevation: 8,
                        child: ElevatedButton(
                          child: Padding(
                            padding: const EdgeInsets.only(
                                left: 32, right: 32, top: 12, bottom: 12),
                            child: Text(
                              'Submit Card',
                              style: Styles.whiteSmall,
                            ),
                          ),
                          onPressed: _submit,
                        ),
                      ),
                    ),
                  )
                : Container(),
          ],
        ),
      ),
    );
  }

  var _formKey = GlobalKey<FormState>();
  bool showSubmit = false;
  void _onChange(CreditCardModel creditCardModel) {
    pp('😡 😡 😡 Credit Card Details changed '
        'cardHolderName: ${creditCardModel.cardHolderName} 💙 cardNumber: ${creditCardModel.cardNumber} '
        ' 💙 expiryDate: ${creditCardModel.expiryDate} 💙 cvv: ${creditCardModel.cvvCode}');
    int cnt = 0;
    if (creditCardModel.cardNumber.isNotEmpty) {
      cnt++;
    }
    if (creditCardModel.cardHolderName.isNotEmpty) {
      cnt++;
    }
    if (creditCardModel.cvvCode.isNotEmpty) {
      cnt++;
    }
    if (creditCardModel.expiryDate.isNotEmpty) {
      cnt++;
    }
    if (cnt == 4) {
      showSubmit = true;
    } else {
      showSubmit = false;
    }

    setState(() {
      cardNumber = creditCardModel.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
  }

  void _submit() {
    pp('😡 😡 😡 Credit Card about to be submitted here 💙 💙 💙 💙 💙');
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment made')));
  }

  @override
  onActionPressed(int action) {
    Navigator.pop(context);
  }
}
