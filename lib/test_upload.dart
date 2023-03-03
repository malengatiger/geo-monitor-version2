import 'package:flutter/material.dart';

class TestUpload extends StatelessWidget {
  const TestUpload({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var url = 'https://storage.googleapis.com/thermal-effort-366015.appspot.com/photo_1677825352518.jpg?GoogleAccessId=firebase-adminsdk-8y4e9@thermal-effort-366015.iam.gserviceaccount.com&Expires=3405825356&Signature=k1ShVftuxoWo7k8DfaYQxL%2FS%2BjPla6IA6A%2BzlURbFJE4%2B%2BwPQZSj49wfkNSGm7gQ5ULTQOdoI3RRpOzAN7%2F9w0Yug89Slb%2B5ZFauvGvx5NnZ3ANKkhLPcENURDcAzhDnDLkjH0ldzRM2i3VI2thNrtQ67Xo%2BqTYm7ur9Dchpl1oXvjq%2F26PjyitLfPo58DzsoSKoxGTzIBSwV0fp4zvIAT370YNmxWgizUQ%2FcvKKajNuepPcHDXcQpPCbcmjs%2FvYL2T5wmqzvWZ9NIwPlvoONuRa%2F2VfIorz1BfI3I3TasPoBSUrpPhgT1VGHiuAnQeNlyIH8%2F6eEHu0JzP8%2FQqXkA%3D%3D';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cloud Storage HTTP Upload'),
      ),
      body: SizedBox(width: 600, child: Image.network(url),),
    );
  }
}
