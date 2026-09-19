import 'package:flutter/material.dart';
import '../models/learning_request_model.dart';
import '../services/firestore_service.dart';

class RequestProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();

  List<Map<String, dynamic>> _incomingRequests = [];
  List<Map<String, dynamic>> _sentRequests = [];
  List<Map<String, dynamic>> _requestHistory = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get incomingRequests => _incomingRequests;
  List<Map<String, dynamic>> get sentRequests => _sentRequests;
  List<Map<String, dynamic>> get requestHistory => _requestHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get incomingCount => _incomingRequests.length;
  int get historyCount => _requestHistory.length;

  // ==================== LOADING ====================

  Future<void> loadIncomingRequests(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _incomingRequests = await _firestore.getIncomingRequests(userId);
      await enrichWithMeetingInfo(_incomingRequests);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSentRequests(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _sentRequests = await _firestore.getSentRequests(userId);
      await enrichWithMeetingInfo(_sentRequests);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRequestHistory(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _requestHistory = await _firestore.getRequestHistory(userId);
      await enrichWithMeetingInfo(_requestHistory);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ==================== ENRICH WITH MEETING ====================

  /// Attach meeting info (id, status, links) to each request
  Future<void> enrichWithMeetingInfo(
      List<Map<String, dynamic>> requests) async {
    try {
      for (var i = 0; i < requests.length; i++) {
        final requestId = requests[i]['id'];
        final meeting = await _firestore.getMeetingByRequestId(requestId);

        if (meeting != null) {
          requests[i]['meeting_id'] = meeting['id'];
          requests[i]['meeting_status'] = meeting['status'];
          requests[i]['meeting_date'] = meeting['meeting_date'];
          requests[i]['meeting_start_time'] = meeting['start_time'];
          requests[i]['meeting_end_time'] = meeting['end_time'];
          requests[i]['zoom_join_url'] = meeting['zoom_join_url'];
          requests[i]['zoom_start_url'] = meeting['zoom_start_url'];
        } else {
          requests[i]['meeting_id'] = null;
          requests[i]['meeting_status'] = null;
        }
      }
    } catch (e) {
      print('⚠️ enrichWithMeetingInfo error: $e');
    }
  }

  // ==================== ACTIONS ====================

  Future<bool> sendRequest({
    required String senderId,
    required String receiverId,
    required String skillId,
    required String message,
    required String preferredTime,
  }) async {
    try {
      final request = LearningRequestModel(
        id: 'req_${DateTime.now().millisecondsSinceEpoch}',
        senderId: senderId,
        receiverId: receiverId,
        skillId: skillId,
        message: message,
        preferredTime: preferredTime,
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestore.sendLearningRequest(request);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> updateStatus(String requestId, String status) async {
    try {
      await _firestore.updateRequestStatus(
        requestId: requestId,
        status: status,
      );
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}