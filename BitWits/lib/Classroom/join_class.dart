import 'package:bitwitsapp/Classroom/Data.dart';
import 'package:bitwitsapp/Intermediate.dart';
import 'package:bitwitsapp/Utilities/UIStyles.dart';
import 'package:flutter/material.dart';
import 'package:bitwitsapp/Utilities/info.dart';
import 'package:bitwitsapp/Utilities/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flushbar/flushbar.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

class JoinClass extends StatefulWidget {
  static String id = "join_class";

  @override
  _JoinClassState createState() => _JoinClassState();
}

class _JoinClassState extends State<JoinClass> {
  final codecon = TextEditingController();
  final rollcon = TextEditingController();
  final _auth = FirebaseAuth.instance;
  FirebaseUser currentUser;
  int y;
  String enteredCode,branch, name;
  bool showSpinner = false;
  bool isValid = false;
  List<String> codes = [];
  @override
  void initState() {
    super.initState();

    registeredCurrentUser();
  }

  void registeredCurrentUser() async {
    final regUser = await _auth.currentUser();
    currentUser = regUser;

    Firestore.instance.collection('Classrooms').snapshots().listen((snapshot) {
      snapshot.documents.forEach((doc) {
        codes.add(doc.documentID);
      });
    });
    print(codes);
  }

  _getYear(){
    try {
      setState(() {
        y = int.parse(enteredCode.substring(5, 6));
      });
    } catch (e) {
      Flushbar(
        messageText: Text(
          'Invalid code',
          style: TextStyle(fontSize: 15, color: Colors.white),
        ),
        icon: errorIcon,
        duration: Duration(seconds: 2),
        backgroundColor: Colors.red,
      )..show(context);
    }
  }

  Future<void> updateStatus() async {
    await Firestore.instance
        .collection("Status")
        .document(currentUser.email)
        .get()
        .then((DocumentSnapshot snapshot) {
      setState(() {
        name = snapshot.data["Name"];
      });
    });
    await Firestore.instance
        .collection("Status")
        .document(currentUser.email)
        .updateData({
          "Current class code": enteredCode,
          "roll number": rollcon.text
        });
    if(y == 1) await Firestore.instance
                  .collection('Status')
                  .document(currentUser.email)
                  .setData({'Branch': branch,},merge: true);

      await Firestore.instance.collection('Classrooms/$enteredCode/Assignments').getDocuments()
      .then((snapshot){
          snapshot.documents.forEach((doc) {
            Firestore.instance.collection('Classrooms/$enteredCode/Assignments/${doc.documentID}/Completion Status')
            .document(rollcon.text).setData({'isDone': false});
          });
        }
      );
  }

  createBranchDialog(BuildContext context) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
                title: BranchText(
                  title: "branch",
                ),
                content: FormField<String>(
                  builder: (FormFieldState<String> state) {
                    return InputDecorator(
                      decoration: textInputDecoration("Branch"),
                      isEmpty: branch == '', //
                      child: DropDown(
                        value: branch,
                        list: Info.branches.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String newValue) {
                          setState(() {
                            FocusScope.of(context).unfocus();
                            branch = newValue;
                            state.didChange(newValue);
                          });
                        },
                      ),
                    );
                  },
                ),
                actions: <Widget>[
                  Cancel(),
                  OK(onPressed: () async {
                    //process
                    setState(() => showSpinner = true);
                    for(int i = 0 ; i < codes.length ; i++){
                      if(enteredCode == codes[i]){
                        await updateStatus();
                        await saveToCF();
                        await Firestore.instance.collection('History').document(currentUser.email)
                              .setData({'class joined on ${DateTime.now()} with roll number and branch': '${codecon.text} , ${rollcon.text} and $branch'},merge: true);
                        setState(() {
                        showSpinner = false;
                          isValid = true;
                        });
                        Navigator.pushNamed(context, Intermediate.id);
                        }
                      }
                      if(isValid == false) {
                      print(isValid);
                      setState(() => showSpinner = false);
                      Flushbar(
                        messageText: Text(
                          "Invalid code",
                        style:
                          TextStyle(fontSize: 15, color: Colors.white),
                        ),
                        icon: errorIcon,
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.red,
                      )..show(context);
                    }
                  })
                ],
              );
        });
  }

  Future<void> saveToCF() async {
    Firestore.instance
        .collection("Classrooms/$enteredCode/Students")
        .document(currentUser.uid)
        .setData({"name": name, "roll number": rollcon.text});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: 40, left: 20, right: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Enter the following to join a class',
                    style: TextStyle(
                      fontSize: 25,
                      color: mainColor,
                      fontWeight: FontWeight.w500,
                    )),
                  SizedBox(height: 40),
                  CodeFields('Roll number', TextInputType.number, rollcon),
                  SizedBox(
                    height: 15,
                  ),
                  CodeFields('Code', TextInputType.text, codecon),
                  SizedBox(height: 20),
                  button(
                    'Join',
                    18,
                    () async {
                      if (rollcon.text.isEmpty || codecon.text.isEmpty)
                        Flushbar(
                          messageText: Text(
                            "Fill in the details",
                            style:
                              TextStyle(fontSize: 15, color: Colors.white),
                          ),
                          icon: errorIcon,
                          duration: Duration(seconds: 2),
                          backgroundColor: Colors.red,
                        )..show(context);
                      else {
                        enteredCode = codecon.text;
                        _getYear();
                        if (y == 1) createBranchDialog(context);
                        else {
                          setState(() => showSpinner = true);
                          for(int i = 0 ; i < codes.length ; i++){
                            if(enteredCode == codes[i]){
                              await updateStatus();
                              await saveToCF();
                              await Firestore.instance.collection('History').document(currentUser.email)
                                    .setData({'class joined on ${DateTime.now()} with roll number': '${codecon.text} and ${rollcon.text}'},merge: true);
                              setState(() {
                                showSpinner = false;
                                isValid = true;
                              });
                              print(codes);
                              Navigator.pushNamed(context, Intermediate.id);
                            }
                          }
                          if(isValid == false) {
                            print(isValid);
                            setState(() => showSpinner = false);
                            Flushbar(
                              messageText: Text(
                              "Invalid code",
                                style:
                                  TextStyle(fontSize: 15, color: Colors.white),
                              ),
                              icon: errorIcon,
                              duration: Duration(seconds: 2),
                              backgroundColor: Colors.red,
                            )..show(context);
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
