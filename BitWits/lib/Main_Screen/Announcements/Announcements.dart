import 'package:bitwitsapp/Classroom/unjoined.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bitwitsapp/Utilities/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Announcements extends StatefulWidget {
  @override
  _AnnouncementsState createState() => _AnnouncementsState();
}

class _AnnouncementsState extends State<Announcements> {
  final _auth = FirebaseAuth.instance;
  FirebaseUser currentUser;

  void registeredCurrentUser() async {
    final regUser = await _auth.currentUser();
    currentUser = regUser;
    await Firestore.instance
        .collection("Status")
        .document(currentUser.email)
        .get()
        .then((DocumentSnapshot snapshot) async {
      SharedPreferences preferences = await SharedPreferences.getInstance();
      await preferences.setString(
          currentUser.email + "@", snapshot.data["Current class code"]);
    });
  }

  @override
  void initState() {
    super.initState();

    registeredCurrentUser();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: SharedPreferences.getInstance(),
      builder:
          (BuildContext context, AsyncSnapshot<SharedPreferences> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());
        if (snapshot.data.getString(currentUser.email + "@") == "NA")
          return Unjoined();
        return Scaffold(
          backgroundColor: Colors.white,
          resizeToAvoidBottomInset: false,
          resizeToAvoidBottomPadding: false,
          appBar: AppBar(
            title: Text(
              'Announcements',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 1,
              ),
            ),
            backgroundColor: mainColor,
            actions: [
              IconButton(
                  icon: Icon(
                    Icons.add,
                    size: 30,
                  ),
                  onPressed: () {})
            ],
          ),
        );
      },
    );
  }
}