import 'package:cloud_firestore/cloud_firestore.dart';
class MeetingModel {
  final String id;
  final String requestId;
  final String teacherId;
  final String learnerId;
  final String skillId;
  final DateTime meetingDate;
  final String startTime;
  final String endTime;
  final String zoomMeetingId;
  final String zoomJoinUrl;
  final String status; // 'scheduled', 'completed', 'cancelled'
  final DateTime createdAt;

  MeetingModel({
    required this.id,
    required this.requestId,
    required this.teacherId,
    required this.learnerId,
    required this.skillId,
    required this.meetingDate,
    required this.startTime,
    required this.endTime,
    required this.zoomMeetingId,
    required this.zoomJoinUrl,
    required this.status,
    required this.createdAt,
  });

  factory MeetingModel.fromFirestore(Map<String, dynamic> data, String id) {
    return MeetingModel(
      id: id,
      requestId: data['request_id'] ?? '',
      teacherId: data['teacher_id'] ?? '',
      learnerId: data['learner_id'] ?? '',
      skillId: data['skill_id'] ?? '',
      meetingDate: (data['meeting_date'] as Timestamp).toDate(),
      startTime: data['start_time'] ?? '',
      endTime: data['end_time'] ?? '',
      zoomMeetingId: data['zoom_meeting_id'] ?? '',
      zoomJoinUrl: data['zoom_join_url'] ?? '',
      status: data['status'] ?? 'scheduled',
      createdAt: (data['created_at'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'request_id': requestId,
      'teacher_id': teacherId,
      'learner_id': learnerId,
      'skill_id': skillId,
      'meeting_date': Timestamp.fromDate(meetingDate),
      'start_time': startTime,
      'end_time': endTime,
      'zoom_meeting_id': zoomMeetingId,
      'zoom_join_url': zoomJoinUrl,
      'status': status,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }
}