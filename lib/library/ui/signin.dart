import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as dot;
import 'package:google_fonts/google_fonts.dart';

import '../auth/app_auth.dart';
import '../functions.dart';

class SignIn extends StatefulWidget {

  const SignIn( {super.key});

  @override
  SignInState createState() => SignInState();
}

class SignInState extends State<SignIn> {
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  bool isBusy = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _key,
      appBar: AppBar(
        title: Text(
          'Digital Monitor Platform',
          style: Styles.whiteSmall,
        ),
        // backgroundColor: Colors.brown[400],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Column(
            children: [
              Text('Signing In ...', style: Styles.whiteBoldMedium),
              const SizedBox(
                height: 24,
              )
            ],
          ),
        ),
      ),
      // backgroundColor: Colors.brown[100],
      body: isBusy
          ? Center(
              child: SizedBox(
                height: 60,
                width: 60,
                child: CircularProgressIndicator(
                  strokeWidth: 24,
                  backgroundColor: Colors.teal[800],
                ),
              ),
            )
          : ListView(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24.0)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        children: <Widget>[
                          const SizedBox(
                            height: 40,
                          ),
                          Text(
                            'Sign in',
                            style: GoogleFonts.lato(
                              textStyle: Theme.of(context).textTheme.bodyLarge,
                              fontWeight: FontWeight.w900, fontSize: 24),
                          ),
                          const SizedBox(
                            height: 40,
                          ),
                          TextField(
                            onChanged: _onEmailChanged,
                            keyboardType: TextInputType.emailAddress,
                            controller: emailCntr,
                            decoration: const InputDecoration(
                              hintText: 'Enter email address',
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                          TextField(
                            onChanged: _onPasswordChanged,
                            keyboardType: TextInputType.text,
                            obscureText: true,
                            controller: pswdCntr,
                            decoration: const InputDecoration(
                              hintText: 'Enter password',
                            ),
                          ),
                          const SizedBox(
                            height: 60,
                          ),
                          ElevatedButton(
                            onPressed: _signIn,
                            // color: Colors.pink[700],
                            // elevation: 8,
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Text(
                                'Submit',
                                style: GoogleFonts.lato(
                                  textStyle: Theme.of(context).textTheme.bodyLarge,
                                  fontWeight: FontWeight.normal,),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 60,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  TextEditingController emailCntr = TextEditingController();
  TextEditingController pswdCntr = TextEditingController();

  @override
  initState() {
    super.initState();
    _checkStatus();
  }

  //user: ORG_ADMINISTRATOR 🍎  org.qaf@monitor.com 🔵  Nicole Seleka
  //user: FIELD_MONITOR 🍎  monitor.zyp@monitor.com 🔵  Mmaphefo De sousa
  //user: EXECUTIVE 🍎  exec.uat@monitor.com 🔵  Andre Motau

  //user: ORG_ADMINISTRATOR 🍎  org.kis@monitor.com 🔵  Lesley Makhubo
  //user: FIELD_MONITOR 🍎  monitor.ffg@monitor.com 🔵  Vusi Mavuso
  //user: EXECUTIVE 🍎  exec.wub@monitor.com 🔵  David Maepa
  void _checkStatus() async {
    var status = dot.dotenv.env['CURRENT_STATUS'];
    pp('🥦🥦 Checking status ..... 🥦🥦 status: $status 🌸 🌸 🌸');
    // if (status == 'dev') {
    //   pswdCntr.text = 'pass123';
    //   switch (widget.type) {
    //     case UserType.fieldMonitor:
    //       emailCntr.text = 'monitor.ffg@monitor.com';
    //       break;
    //     case UserType.orgExecutive:
    //       emailCntr.text = 'exec.wub@monitor.com';
    //       break;
    //     case UserType.orgAdministrator:
    //       emailCntr.text = 'org.kis@monitor.com';
    //       break;
    //     default:
    //       emailCntr.text = 'org.kis@monitor.com';
    //       break;
    //
    //       break;
    //   }
    // }


    setState(() {});
  }

  String email = '', password = '';
  void _onEmailChanged(String value) {
    email = value;
    pp(email);
  }

  void _signIn() async {
    email = emailCntr.text;
    password = pswdCntr.text;
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Credentials missing or invalid')));
      return;
    }
    setState(() {
      isBusy = true;
    });
    try {
      var user = await AppAuth.signIn(email: email, password: password,);
      if (!mounted) return;
      Navigator.pop(context, user);
      //do I want to gp to dashboard??
    } catch (e) {
      setState(() {
        isBusy = false;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Sign in failed: $e')));
    }
  }

  void _onPasswordChanged(String value) {
    password = value;
    pp(password);
  }
}
