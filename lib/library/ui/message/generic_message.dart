import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';

import '../../api/data_api.dart';
import '../../api/sharedprefs.dart';
import '../../data/org_message.dart';
import '../../functions.dart';
import '../../data/project.dart';
import '../../data/user.dart';
class GenericMessage extends StatefulWidget {
  final Project? project;
  final User user;

  const GenericMessage({super.key,
    this.project,
    required this.user,
  });

  @override
  GenericMessageState createState() => GenericMessageState();
}

class GenericMessageState extends State<GenericMessage> {
  String frequency = MONITOR_TWICE_A_DAY;
  bool isBusy = false;
  var _key = GlobalKey<ScaffoldState>();
  void _onRadioButtonSelected(String selected) {
    pp('MessageMobile :  🥦 🥦 🥦 _onRadioButtonSelected: 🍊 $selected 🍊');
    setState(() {
      frequency = selected;
    });
  }

  void _sendMessage() async {
    // if (frequency == null) {
    //   AppSnackbar.showErrorSnackbar(
    //       scaffoldKey: widget.key!, message: 'Please select frequency');
    //   return;
    // }

    setState(() {
      isBusy = true;
    });
    var admin = await Prefs.getUser();
    if (admin != null && admin.userId != widget.user.userId) {
      var msg = OrgMessage(
          name: widget.user.name,
          adminId: admin.userId,
          adminName: admin.name,
          projectName: widget.project == null? null: widget.project!.name,
          frequency: frequency,
          message: message,
          userId: widget.user.userId,
          created: DateTime.now().toUtc().toIso8601String(),
          projectId: widget.project == null? null: widget.project!.projectId,
          organizationId: widget.project == null? null: widget.project!.organizationId, orgMessageId: Uuid().v4());
      try {
        var res = await DataAPI.sendMessage(msg);
        pp('GenericMessage:  🏓  🏓  🏓 Response from server:  🏓 ${res.toJson()}  🏓');
      } catch (e) {
        // AppSnackbar.showErrorSnackbar(
        //     scaffoldKey: widget.key, message: 'Message Send failed : $e');
      }
      setState(() {
        isBusy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.app_registration,
              color: Theme.of(context).primaryColor,
            ),
            title: AnimatedContainer(
              duration: Duration(milliseconds: 1000),
              child: Text(
                '${widget.project == null ? '' : widget.project!.name}',
                style: Styles.blackBoldSmall,
              ),
            ),
          ),
          SizedBox(
            height: 2,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              minLines: 2,
              maxLines: 6,
              decoration: InputDecoration(
                icon: Icon(Icons.message),
                hintText: 'Enter message',
              ),
              onChanged: _onMessageChanged,
            ),
          ),
          SizedBox(
            height: 4,
          ),
          isBusy
              ? Container(
                  height: 24,
                  width: 24,
                  child: Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 4,
                      backgroundColor: Colors.pink[200],
                    ),
                  ),
                )
              : widget.project == null
                  ? Container()
                  : ElevatedButton(

                      child: Text(
                        'Send Message',
                        style: Styles.whiteSmall,
                      ),
                      onPressed: _sendMessage),
          SizedBox(
            height: 12,
          )
        ],
      ),
    );
  }

  String? message;
  void _onMessageChanged(String value) {
    setState(() {
      message = value;
    });
  }
}
