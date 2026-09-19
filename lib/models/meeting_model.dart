import 'package:cloud_firestore/cloud_firestore.dart';

class MeetingModel {
  final String id;
  final String requestId;      // Links back to learning_request
  final String teacherId;      // Who teaches
  final String learnerId;      // Who learns
  final String skillId;        // Skill being taught
  final String skillName;      // Cached for quick display
  final DateTime meetingDate;  // Date of meeting
  final String startTime;      // "14:30"
  final String endTime;        // "15:00"
  final String zoomMeetingId;  // Zoom meeting ID
  final String zoomJoinUrl;    // For learners (and teacher too)
  final String zoomStartUrl;   // Only for teacher (host)
  final String status;         // scheduled | completed | cancelled
  final String topic;          // Meeting topic
  final DateTime createdAt;
  final DateTime? cancelledAt;
  final DateTime? completedAt;

  MeetingModel({
    required this.id,
    required this.requestId,
    required this.teacherId,
    required this.learnerId,
    required this.skillId,
    required this.skillName,
    required this.meetingDate,
    required this.startTime,
    required this.endTime,
    required this.zoomMeetingId,
    required this.zoomJoinUrl,
    required this.zoomStartUrl,
    required this.status,
    required this.topic,
    required this.createdAt,
    this.cancelledAt,
    this.completedAt,
  });

  factory MeetingModel.fromFirestore(
      Map<String, dynamic> data, String id) {
    return MeetingModel(
      id: id,
      requestId: data['request_id'] ?? '',
      teacherId: data['teacher_id'] ?? '',
      learnerId: data['learner_id'] ?? '',
      skillId: data['skill_id'] ?? '',
      skillName: data['skill_name'] ?? '',
      meetingDate: (data['meeting_date'] as Timestamp).toDate(),
      startTime: data['start_time'] ?? '',
      endTime: data['end_time'] ?? '',
      zoomMeetingId: data['zoom_meeting_id'] ?? '',
      zoomJoinUrl: data['zoom_join_url'] ?? '',
      zoomStartUrl: data['zoom_start_url'] ?? '',
      status: data['status'] ?? 'scheduled',
      topic: data['topic'] ?? '',
      createdAt: (data['created_at'] as Timestamp).toDate(),
      cancelledAt: data['cancelled_at'] != null
          ? (data['cancelled_at'] as Timestamp).toDate()
          : null,
      completedAt: data['completed_at'] != null
          ? (data['completed_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'request_id': requestId,
      'teacher_id': teacherId,
      'learner_id': learnerId,
      'skill_id': skillId,
      'skill_name': skillName,
      'meeting_date': Timestamp.fromDate(meetingDate),
      'start_time': startTime,
      'end_time': endTime,
      'zoom_meeting_id': zoomMeetingId,
      'zoom_join_url': zoomJoinUrl,
      'zoom_start_url': zoomStartUrl,
      'status': status,
      'topic': topic,
      'created_at': Timestamp.fromDate(createdAt),
      'cancelled_at':
      cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'completed_at':
      completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  MeetingModel copyWith({
    String? id,
    String? requestId,
    String? teacherId,
    String? learnerId,
    String? skillId,
    String? skillName,
    DateTime? meetingDate,
    String? startTime,
    String? endTime,
    String? zoomMeetingId,
    String? zoomJoinUrl,
    String? zoomStartUrl,
    String? status,
    String? topic,
    DateTime? createdAt,
    DateTime? cancelledAt,
    DateTime? completedAt,
  }) {
    return MeetingModel(
      id: id ?? this.id,
      requestId: requestId ?? this.requestId,
      teacherId: teacherId ?? this.teacherId,
      learnerId: learnerId ?? this.learnerId,
      skillId: skillId ?? this.skillId,
      skillName: skillName ?? this.skillName,
      meetingDate: meetingDate ?? this.meetingDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      zoomMeetingId: zoomMeetingId ?? this.zoomMeetingId,
      zoomJoinUrl: zoomJoinUrl ?? this.zoomJoinUrl,
      zoomStartUrl: zoomStartUrl ?? this.zoomStartUrl,
      status: status ?? this.status,
      topic: topic ?? this.topic,
      createdAt: createdAt ?? this.createdAt,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}