import 'package:flutter/material.dart';
import '../models/meeting_model.dart';
import '../services/firestore_service.dart';
import '../services/zoom_service.dart';

class MeetingProvider extends ChangeNotifier {
  final FirestoreService _firestore = FirestoreService();
  final ZoomService _zoom = ZoomService();

  List<Map<String, dynamic>> _upcomingMeetings = [];
  List<Map<String, dynamic>> _completedMeetings = [];
  List<Map<String, dynamic>> _cancelledMeetings = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Map<String, dynamic>> get upcomingMeetings => _upcomingMeetings;
  List<Map<String, dynamic>> get completedMeetings => _completedMeetings;
  List<Map<String, dynamic>> get cancelledMeetings => _cancelledMeetings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get upcomingCount => _upcomingMeetings.length;

  // ==================== LOAD MEETINGS ====================

  Future<void> loadUpcomingMeetings(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _upcomingMeetings = await _firestore.getUpcomingMeetings(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCompletedMeetings(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _completedMeetings = await _firestore.getCompletedMeetings(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadCancelledMeetings(String userId) async {
    _setLoading(true);
    _error = null;
    try {
      _cancelledMeetings = await _firestore.getCancelledMeetings(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  // ==================== SCHEDULE MEETING ====================

  /// Schedule a new meeting — calls Zoom + saves to Firestore
  /// Returns meetingId on success, null on failure
  Future<String?> scheduleMeeting({
    required String requestId,
    required String teacherId,
    required String learnerId,
    required String skillId,
    required String skillName,
    required DateTime meetingDate,
    required String startTime,
    required String endTime,
    required int durationMinutes,
  }) async {
    _error = null;
    try {
      print('📅 Scheduling meeting...');

      // ✅ DUPLICATE CHECK: Does a meeting already exist for this request?
      final existing = await _firestore.getMeetingByRequestId(requestId);
      if (existing != null) {
        print('⚠️ Meeting already exists: ${existing['id']}');
        _error = 'A meeting is already scheduled for this request';
        return null;
      }

      print('📅 No existing meeting — proceeding');

      // Parse startTime into DateTime
      final parts = startTime.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dateTime = DateTime(
        meetingDate.year,
        meetingDate.month,
        meetingDate.day,
        hour,
        minute,
      );

      // Create Zoom meeting
      final topic = '$skillName Session';
      print('📡 Calling Zoom API...');

      final zoomResult = await _zoom.createMeeting(
        topic: topic,
        startTime: dateTime,
        durationMinutes: durationMinutes,
      );

      print('✅ Zoom meeting created: ${zoomResult['id']}');

      // Save to Firestore
      final meetingId = 'meet_${DateTime.now().millisecondsSinceEpoch}';

      final meeting = MeetingModel(
        id: meetingId,
        requestId: requestId,
        teacherId: teacherId,
        learnerId: learnerId,
        skillId: skillId,
        skillName: skillName,
        meetingDate: meetingDate,
        startTime: startTime,
        endTime: endTime,
        zoomMeetingId: zoomResult['id'] ?? '',
        zoomJoinUrl: zoomResult['join_url'] ?? '',
        zoomStartUrl: zoomResult['start_url'] ?? '',
        status: 'scheduled',
        topic: topic,
        createdAt: DateTime.now(),
      );

      await _firestore.createMeeting(meeting);
      print('✅ Meeting saved to Firestore: $meetingId');

      return meetingId;
    } catch (e) {
      print('❌ Schedule meeting error: $e');
      _error = e.toString();
      return null;
    }
  }

  // ==================== CANCEL MEETING ====================

  /// Cancel a meeting + delete Zoom meeting
  Future<bool> cancelMeeting(String meetingId) async {
    _error = null;
    try {
      // Get meeting to find Zoom ID
      final meeting = await _firestore.getMeetingById(meetingId);
      if (meeting == null) {
        _error = 'Meeting not found';
        return false;
      }

      // Delete Zoom meeting (best effort)
      final zoomId = meeting['zoom_meeting_id'] as String? ?? '';
      if (zoomId.isNotEmpty) {
        try {
          await _zoom.deleteMeeting(zoomId);
        } catch (e) {
          print('⚠️ Zoom delete failed (continuing): $e');
        }
      }

      // Update Firestore status
      await _firestore.updateMeetingStatus(
        meetingId: meetingId,
        status: 'cancelled',
      );

      print('✅ Meeting cancelled: $meetingId');
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ==================== COMPLETE MEETING ====================

  /// Mark a meeting as completed
  Future<bool> completeMeeting(String meetingId) async {
    _error = null;
    try {
      await _firestore.updateMeetingStatus(
        meetingId: meetingId,
        status: 'completed',
      );
      print('✅ Meeting marked complete: $meetingId');
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  // ==================== HELPERS ====================

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}