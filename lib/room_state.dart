import 'package:dyte_core/dyte_core.dart';
import 'package:flutter/material.dart';
import 'package:bishop/bishop.dart' as bishop;
// import 'package:flutter_stateless_chessboard/flutter_stateless_chessboard.dart';
import 'package:get/instance_manager.dart';
import 'package:get/route_manager.dart';
import 'package:get/state_manager.dart';
import 'package:square_bishop/square_bishop.dart';
import 'package:squares/squares.dart';

class RoomStateNotifier extends GetxController
    implements
        DyteMeetingRoomEventsListener,
        DyteParticipantEventsListener,
        DyteChatEventsListener {
  // DyteMobileClient is manager to interact with dyte server.
  final Rx<DyteMobileClient> dyteClient = DyteMobileClient().obs;
  // Remote peer will hold the remote peer information like name, video, audio so on.
  Rxn<DyteMeetingParticipant> remotePeer = Rxn<DyteMeetingParticipant>();
  // isAudioOn is used to get and set local user audio status
  Rx<bool> isAudioOn = false.obs;
  // isVideoOn is used to get and set local user video status
  Rx<bool> isVideoOn = true.obs;
  // Room Join status
  Rx<bool> roomJoin = false.obs;
  // chess game fen
  Rx<String> fen = "".obs;
  // Local User Colour.
  Rx<int> playerColor = Squares.white.obs;
  // Bishop is used for validating chess moves.
  Rx<bishop.Game> game = bishop.Game(variant: bishop.Variant.standard()).obs;
  // ChessBoard state
  late Rx<SquaresState> state;
  // Username is used to assign value in room.
  Rx<String> username = "".obs;
  // Is local user turn
  Rx<bool> localUserTurn = false.obs;
  // Dyte Room Id
  Rx<String> roomId = "".obs;

  RoomStateNotifier(String name,String token,String meetingId) {
    state = game.value.squaresState(playerColor.value).obs;
    username.value = name;
    roomId.value = meetingId; 
    dyteClient.value.addMeetingRoomEventsListener(this);
    dyteClient.value.addParticipantEventsListener(this);
    dyteClient.value.addChatEventsListener(this);
    token = "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJvcmdJZCI6ImNiODliMzFkLTU0ZmEtNDE1YS1iZTFlLTk3NzA0Njc1M2Q0MyIsIm1lZXRpbmdJZCI6ImJiYjEyYjI5LTM5MDYtNDIzZC05NDNlLTg0MTdjMjAxYTMyMSIsInBhcnRpY2lwYW50SWQiOiJhYWE2NDQ4OC01ZmU5LTQzZTgtODBhOS02YmQ0OTZmMmRkZmYiLCJwcmVzZXRJZCI6ImM4YjU2YjczLWMxNTItNDZlYS1hMDY0LWQxZjAzOGRkYjI2NiIsImlhdCI6MTY5Mjg2NTQxNCwiZXhwIjoxNzAxNTA1NDE0fQ.L9usZyCqeQWFWJJ05Qrpkbv4aAVoAZ5-l6BKhpTebadzTmtfnCymq9qAPxsVYcuGNi_lbZPkAeWDkjuM5Ddz9vqdgKpFpw3GAQEYLkSHYW8E3z2GpRV8kJ5GlZLndUuv84dNHL6q_JXJyYQQnmtA3EDO4P9suIyHApHDPxLW6km4QpezTXSMCuqI-wvrs6BiY3UkMKiAnKl7jopiLhzZuhc2VB48GriDVmtLISuHpYdo3LXfzfxGFdR-TYle4b6Jmn33TUNbCdxS2w-SWEeqTurQ86Zqm_cLYo5BLRjuDknPY9kqSaJubG5ODqMoT-2y3nCFOyy_09h_ltWROj8vvw";
    final meetingInfo = DyteMeetingInfoV2(
        authToken:token,
        enableAudio: false,
        enableVideo: true);
    dyteClient.value.init(meetingInfo);
  }

  sendMessage(String message) {
    dyteClient.value.chat.sendTextMessage(message);
  }

  toggleVideo() {
    if (isVideoOn.value) {
      dyteClient.value.localUser.disableVideo();
    } else {
      dyteClient.value.localUser.enableVideo();
    }
    isVideoOn.toggle();
  }

  toggleAudio() {
    if (isAudioOn.value) {
      dyteClient.value.localUser.disableAudio();
    } else {
      dyteClient.value.localUser.enableAudio();
    }
    isAudioOn.toggle();
  }

  @override
  void onMeetingInitCompleted() {
    dyteClient.value.localUser.setDisplayName(username.value);
    dyteClient.value.joinRoom();
  }

  @override
  void onMeetingRoomJoinCompleted() {
    roomJoin.value = true;
  }

  @override
  void onMeetingRoomLeaveCompleted() {
    roomJoin.value = false;
    dyteClient.value.removeMeetingRoomEventsListener(this);
    dyteClient.value.removeParticipantEventsListener(this);
    dyteClient.value.removeChatEventsListener(this);
    Get.back();
    Get.delete<RoomStateNotifier>();
  }

  @override
  void onParticipantJoin(DyteJoinedMeetingParticipant participant) {
    if (participant.userId != dyteClient.value.localUser.userId) {
      remotePeer.value = participant;
      assignColour();
    }
  }

  @override
  void onParticipantLeave(DyteJoinedMeetingParticipant participant) {
    if (participant.userId != dyteClient.value.localUser.userId &&
        remotePeer.value != null) {
      remotePeer.value = null;
      Get.defaultDialog(
          barrierDismissible: false,
          onWillPop: () async {
            return false;
          },
          title: "Opponent Left this game.",
          textConfirm: "Leave",
          middleText: "",
          confirmTextColor: Colors.white,
          onConfirm: () {
            dyteClient.value.leaveRoom();
            Get.back();
          });
    }
  }

  @override
  void onNewChatMessage(DyteChatMessage message) {
    if (message.userId == dyteClient.value.localUser.userId) {
      return;
    }
    DyteTextMessage textMessage = message as DyteTextMessage;
    final fen = textMessage.message;
    game.value.loadFen(fen);
    state.value = game.value.squaresState(playerColor.value);
    if (game.value.checkmate) {
      Get.defaultDialog(
          barrierDismissible: false,
          title: "You lose the game",
          textConfirm: "Leave",
          middleText: "",
          confirmTextColor: Colors.white,
          onConfirm: () {
            dyteClient.value.leaveRoom();
            Get.back();
          });
    }
    localUserTurn.value = true;
  }

  @override
  void onMeetingInitFailed(Exception exception) {
    print("onMeetingInitFailed $exception");
  }

  @override
  void onMeetingInitStarted() {
    // TODO: implement onMeetingInitStarted
  }

  @override
  void onMeetingRoomDisconnected() {
    // TODO: implement onMeetingRoomDisconnected
  }

  @override
  void onMeetingRoomJoinFailed(Exception exception) {
    print("onMeetingRoomJoinFailed $exception");
  }

  @override
  void onMeetingRoomJoinStarted() {
    print("onMeetingRoomJoinStarted");
  }

  @override
  void onMeetingRoomLeaveStarted() {
    // TODO: implement onMeetingRoomLeaveCompleted
  }

  @override
  void onActiveParticipantsChanged(List<DyteJoinedMeetingParticipant> active) {
    // TODO: implement onActiveParticipantsChanged
  }

  @override
  void onActiveSpeakerChanged(DyteJoinedMeetingParticipant participant) {
    // TODO: implement onActiveSpeakerChanged
  }

  @override
  void onAudioUpdate(
      bool audioEnabled, DyteJoinedMeetingParticipant participant) {
    // TODO: implement onAudioUpdate
  }

  @override
  void onNoActiveSpeaker() {
    // TODO: implement onNoActiveSpeaker
  }

  @override
  void onParticipantPinned(DyteJoinedMeetingParticipant participant) {
    // TODO: implement onParticipantPinned
  }

  @override
  void onParticipantUnpinned(DyteJoinedMeetingParticipant participant) {
    // TODO: implement onParticipantUnpinned
  }

  @override
  void onScreenShareEnded(DyteScreenShareMeetingParticipant participant) {
    // TODO: implement onScreenShareEnded
  }

  @override
  void onScreenShareStarted(DyteScreenShareMeetingParticipant participant) {
    // TODO: implement onScreenShareStarted
  }

  @override
  void onScreenSharesUpdated() {
    // TODO: implement onScreenSharesUpdated
  }

  @override
  void onUpdate(DyteRoomParticipants participants) {}

  @override
  void onVideoUpdate(
      bool videoEnabled, DyteJoinedMeetingParticipant participant) {
    // TODO: implement onVideoUpdate
  }

  @override
  void onChatUpdates(List<DyteChatMessage> messages) {
    // TODO: implement onChatUpdates
  }

  @override
  void onDisconnectedFromMeetingRoom(String reason) {
    // TODO: implement onDisconnectedFromMeetingRoom
  }

  @override
  void onMeetingRoomConnectionError(String errorMessage) {
    // TODO: implement onMeetingRoomConnectionError
  }

  @override
  void onMeetingRoomReconnectionFailed() {
    // TODO: implement onMeetingRoomReconnectionFailed
  }

  @override
  void onReconnectedToMeetingRoom() {
    // TODO: implement onReconnectedToMeetingRoom
  }

  @override
  void onReconnectingToMeetingRoom() {
    // TODO: implement onReconnectingToMeetingRoom
  }

  onUserMove(Move move) {
    if (game.value.makeSquaresMove(move)) {  
      state.value = game.value.squaresState(playerColor.value);    
      sendMessage(game.value.fen);
      localUserTurn.value = false;
    }else{
      Get.snackbar("Invalid move","",snackPosition: SnackPosition.BOTTOM);
    }
    if (game.value.checkmate) {
      Get.defaultDialog(
          barrierDismissible: false,
          title: "You won the game",
          textConfirm: "Leave",
          middleText: "",
          confirmTextColor: Colors.white,
          onConfirm: () {
            dyteClient.value.leaveRoom();
            Get.back();
          });
    }
  }


  assignColour() {
    List<String> peer = [
      dyteClient.value.localUser.userId,
      remotePeer.value!.userId
    ];
    peer.sort();
    if (peer.indexOf(dyteClient.value.localUser.userId) == 0) {
      playerColor.value = Squares.white;
      state.value = game.value.squaresState(playerColor.value);
      localUserTurn.value = true;
    } else {
      playerColor.value = Squares.black;
      localUserTurn.value = false;
    }
  }
}
