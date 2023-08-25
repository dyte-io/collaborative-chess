import 'dart:math';

import 'package:chess_video_call/room_state.dart';
import 'package:dyte_core/dyte_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:get/state_manager.dart';
import 'package:squares/squares.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final RoomStateNotifier roomStateNotifier = Get.find();
    return WillPopScope(
      onWillPop: () async {
        if(roomStateNotifier.roomJoin.value){
          return true;
        }
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.blueGrey,
        body: Column(children: [
          Obx(
            () => Expanded(
              child: roomStateNotifier.remotePeer.value == null
                  // Room Id
                  ? SizedBox(
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Room Id: ${roomStateNotifier.roomId.value.split("-")[0]}...",
                            ),
                            IconButton(
                                onPressed: () async {
                                  //`Clipboard.setData` copy string to clipboard
                                  await Clipboard.setData(ClipboardData(
                                      text: roomStateNotifier.roomId.value));
                                },
                                icon: const Icon(Icons.copy)),
                          ],
                        ),
                      ),
                    )
                  // Remote user video tile and name
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 100,
                          width: 100,
                          margin: const EdgeInsets.only(left: 10),
                          decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: [
                        if (!roomStateNotifier.localUserTurn.value) ...[
                          const BoxShadow(
                            color: Colors.red,
                            spreadRadius: 4,
                            blurRadius: 10,
                          ),
                          const BoxShadow(
                            color: Colors.red,
                            spreadRadius: -4,
                            blurRadius: 5,
                          )
                        ]
                      ],
                    ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(17),
                            // Remote Peer video Tile
                            // child: VideoView(
                            //   meetingParticipant:
                            //       roomStateNotifier.remotePeer.value,
                            // ),
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        // Remote Peer Name
                        // Text(
                        //   roomStateNotifier.remotePeer.value!.name,
                        //   style: const TextStyle(
                        //       color: Colors.black, fontWeight: FontWeight.bold),
                        // ),
                        const Spacer()
                      ],
                    ),
            ),
          ),
          Flexible(
            flex: 2,
            child: LayoutBuilder(builder: (context, boxConstraints) {
              double size = min(boxConstraints.biggest.height,
                      boxConstraints.biggest.width) -
                  10;
              return Stack(children: [
                Obx(
                  () => BoardController(
                    state: roomStateNotifier.state.value.board,
                    playState: roomStateNotifier.state.value.state,
                    pieceSet: PieceSet.merida(),
                    moves: roomStateNotifier.localUserTurn.value
                        ? roomStateNotifier.state.value.moves
                        : [],
                    onMove: roomStateNotifier.onUserMove,
                    markerTheme: MarkerTheme(
                      empty: MarkerTheme.dot,
                      piece: MarkerTheme.corners(),
                    ),
                    promotionBehaviour: PromotionBehaviour.autoPremove,
                  ),
                ),
                Obx(
                  () => SizedBox(
                    child: roomStateNotifier.remotePeer.value != null
                        ? const SizedBox()
                        : SizedBox(
                            width: size,
                            height: size,
                            child: const Center(
                              child: Text(
                                "Waiting player to join",
                                textAlign: TextAlign.center,
                                maxLines: 3,
                                style: TextStyle(
                                    fontSize: 25, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                  ),
                )
              ]);
            }),
          ),
          // Local user video tile and name
          Expanded(
            child: Row(
              children: [
                const Spacer(),
                Obx(
                  () => Text(
                    roomStateNotifier.roomJoin.value == false
                        ? ""
                        : roomStateNotifier.username.value,
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Obx(
                  () => Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(17),
                      boxShadow: [
                        if (roomStateNotifier.localUserTurn.value) ...[
                          const BoxShadow(
                            color: Colors.red,
                            spreadRadius: 4,
                            blurRadius: 10,
                          ),
                          const BoxShadow(
                            color: Colors.red,
                            spreadRadius: -4,
                            blurRadius: 5,
                          )
                        ]
                      ],
                    ),
                    margin: const EdgeInsets.only(right: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(17),
                      // Dyte Meeting Video View of local peer
                      // child: roomStateNotifier.roomJoin.value == false
                      //     ? const SizedBox()
                      //     : const VideoView(
                      //         isSelfParticipant: true,
                      //       ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                  onPressed: () {
                    roomStateNotifier.toggleVideo();
                  },
                  icon: Obx(
                    () => Icon(
                        roomStateNotifier.isVideoOn.value
                            ? Icons.videocam
                            : Icons.videocam_off_rounded,
                        color: roomStateNotifier.isVideoOn.value
                            ? Colors.black
                            : Colors.red),
                  )),
              IconButton(
                  onPressed: () {
                    roomStateNotifier.toggleAudio();
                  },
                  icon: Obx(
                    () => Icon(
                        roomStateNotifier.isAudioOn.value
                            ? Icons.mic
                            : Icons.mic_off_rounded,
                        color: roomStateNotifier.isAudioOn.value
                            ? Colors.black
                            : Colors.red),
                  )),
              GestureDetector(
                onTap: () {
                  Get.defaultDialog(
                    title: "Want to leave?",
                    onConfirm: () {
                      roomStateNotifier.dyteClient.value.leaveRoom();
                      Get.back();
                    },
                    middleText: "",
                    confirmTextColor: Colors.white,
                    textCancel: "Cancel",
                    textConfirm: "Leave",
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                  child: const Icon(
                    Icons.call_end,
                    color: Colors.white,
                  ),
                ),
              )
            ],
          ),
        ]),
      ),
    );
  }
}
