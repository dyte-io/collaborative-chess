import 'package:dyte_core/dyte_core.dart';
import 'package:flutter/material.dart';
import 'package:bishop/bishop.dart' as bishop;
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
    final meetingInfo = DyteMeetingInfoV2(
        authToken:token,
        enableAudio: false,
        enableVideo: true);
    dyteClient.value.init(meetingInfo);
  }

  // Send message to remote peer
  sendMessage(String message) {
    dyteClient.value.chat.sendTextMessage(message);
  }

// Toggle Video of local peer
  toggleVideo() {
    if (isVideoOn.value) {
      dyteClient.value.localUser.disableVideo();
    } else {
      dyteClient.value.localUser.enableVideo();
    }
    isVideoOn.toggle();
  }

// Toggle Audio of local peer
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
  // TODO: onMeetingInitCompleted code here
  }

  @override
  void onMeetingRoomJoinCompleted() {
    // TODO: onMeetingRoomJoinCompleted code here
  }

  @override
  void onMeetingRoomLeaveCompleted() {
   // TODO: onMeetingRoomLeaveCompleted code here
  }

  @override
  void onParticipantJoin(DyteJoinedMeetingParticipant participant) {
    // TODO: onParticipantJoin code here
  }

  @override
  void onParticipantLeave(DyteJoinedMeetingParticipant participant) {
    // TODO: onParticipantLeave code here
  }

  @override
  void onNewChatMessage(DyteChatMessage message) {
   // TODO: onNewChatMessage code here
  }

  @override
  void onMeetingInitFailed(Exception exception) {
    debugPrint("onMeetingInitFailed $exception");
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
    debugPrint("onMeetingRoomJoinFailed $exception");
  }

  @override
  void onMeetingRoomJoinStarted() {
    debugPrint("onMeetingRoomJoinStarted");
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
