import 'dart:io';

import 'package:chess_video_call/game_screen.dart';
import 'package:chess_video_call/room_state.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import './http_request.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const GetMaterialApp(
      debugShowCheckedModeBanner: false,
      home: JoimRoom(),
    );
  }
}

class JoimRoom extends StatefulWidget {
  const JoimRoom({super.key});

  @override
  State<JoimRoom> createState() => _JoimRoomState();
}

class _JoimRoomState extends State<JoimRoom> {
  bool loading = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Text(
              "DYTE ONLINE CHESS",
              textAlign: TextAlign.center,
              style: GoogleFonts.abrilFatface(
                  textStyle: const TextStyle(
                      color: Colors.white, letterSpacing: 3, fontSize: 40)),
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width / 1.5,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(0),
                child: Image.asset(
                  "assets/chess.gif",
                ),
              ),
            ),
            GestureDetector(
                onTap: () async {
                  if (await getPermissions()) {
                    // ignore: use_build_context_synchronously
                    await showDialog(
                        context: context,
                        builder: (context) {
                          TextEditingController nameController =
                              TextEditingController();
                          TextEditingController roomIdController =
                              TextEditingController();
                          return AlertDialog(
                            title: const Text("Enter Details"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: nameController,
                                  decoration: const InputDecoration(
                                      labelText: "Enter Name"),
                                ),
                                TextField(
                                  controller: roomIdController,
                                  decoration: const InputDecoration(
                                      labelText: "Enter Room Id"),
                                ),
                              ],
                            ),
                            actions: [
                              ElevatedButton(
                                  onPressed: () async {
                                    if (nameController.text.trim().isEmpty ||
                                        roomIdController.text.trim().isEmpty) {
                                      Get.snackbar("Enter Name and Room Id",
                                          "Please Enter name and room Id to join the game",
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: Colors.black,
                                          colorText: Colors.white);
                                    } else {
                                      Get.back();
                                      String? token =
                                          await HttpRequest.addParticipant(
                                              nameController.text.trim(),
                                              roomIdController.text.trim());
                                      if (token != null) {
                                        Get.put(RoomStateNotifier(
                                            nameController.text.trim(),
                                            "token",
                                            roomIdController.text.trim()));
                                        Get.to(const GameScreen());
                                      } else {
                                              Get.snackbar( "Error","unable to get token");

                                      }
                                    }
                                  },
                                  child: const Text("JOIN"))
                            ],
                          );
                        });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 45, vertical: 5),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white),
                  child: Text(
                    "JOIN GAME",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.abrilFatface(
                        textStyle: const TextStyle(
                            color: Colors.black,
                            letterSpacing: 3,
                            fontSize: 30)),
                  ),
                )),
            GestureDetector(
                onTap: () async {
                  if (await getPermissions()) {
                    // ignore: use_build_context_synchronously
                    await showDialog(
                        context: context,
                        builder: (context) {
                          TextEditingController controller =
                              TextEditingController();
                          return AlertDialog(
                            title: const Text("Enter Name"),
                            content: TextField(
                              controller: controller,
                            ),
                            actions: [
                              ElevatedButton(
                                  onPressed: () async {
                                    if (controller.text.trim().isEmpty) {
                                      Get.snackbar("Enter Name",
                                          "Please Enter name to join the game",
                                          snackPosition: SnackPosition.BOTTOM,
                                          backgroundColor: Colors.black,
                                          colorText: Colors.white);
                                    } else {
                                      Get.back();
                                      setState(() {
                                        loading = true;
                                      });
                                      String? token;
                                      // Room Creation
                                      String? roomId =
                                          await HttpRequest.createMeeting();
                                      if (roomId != null) {
                                        // Adding Participant
                                        token =
                                            await HttpRequest.addParticipant(
                                                controller.text.trim(), roomId);
                                      }
                                      if (token != null) {
                                        setState(() {
                                          loading = false;
                                        });
                                        Get.put(RoomStateNotifier(
                                            controller.text.trim(),
                                            token,
                                            roomId!));
                                        Get.to(const GameScreen());
                                      } else {
                                             Get.snackbar( "Error","Unable to get token");

                                      }
                                    }
                                  },
                                  child: const Text("JOIN"))
                            ],
                          );
                        });
                  }
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.white),
                  child: Text(
                    "CREATE GAME",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.abrilFatface(
                        textStyle: const TextStyle(
                            color: Colors.black,
                            letterSpacing: 3,
                            fontSize: 30)),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

Future<bool> getPermissions() async {
  if (Platform.isIOS) return true;
  await Permission.camera.request();
  await Permission.microphone.request();

  while ((await Permission.camera.isDenied)) {
    await Permission.camera.request();
  }
  while ((await Permission.microphone.isDenied)) {
    await Permission.microphone.request();
  }

  return true;
}
