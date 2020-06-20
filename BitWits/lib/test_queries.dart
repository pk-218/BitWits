import 'package:flutter/material.dart';
import 'dart:core';
import 'package:cloud_firestore/cloud_firestore.dart';

class Test extends StatefulWidget {
  static String id = "test";

  @override
  _TestState createState() => _TestState();
}

class _TestState extends State<Test> {
  bool isValid = false;

  @override
  void initState() {
    super.initState();

    // writeQuery();
    _writeQuery();
  }

  // Future<void> getDetails() async {
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   setState(() {
  //     code = prefs.getString("sql@gmail.com");
  //     year = code.substring(5, 6);
  //     if (year == "1")
  //       batch = code.substring(1, 2);
  //     else {
  //       Map reversed = Info.getBranch().map((k, v) => MapEntry(v, k));
  //       String b = code.substring(0, 2);
  //       branch = reversed[b];
  //     }
  //   });
  // }

  _writeQuery() {
    //write your  queries
    Firestore.instance.collection('Classrooms').snapshots().listen((snapshot) {
      snapshot.documents.forEach((doc) {
        if('es148286' == doc.documentID){
          setState(() {
            isValid = true;
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(child: Text(isValid.toString()),
    ));
  }
}
