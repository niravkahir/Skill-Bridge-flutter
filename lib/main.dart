import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'models/user_model.dart';
import 'models/profile_model.dart';
import 'models/skill_model.dart';
import 'models/user_skill_model.dart';
import 'models/learning_request_model.dart';
import 'models/meeting_model.dart';
import 'models/feedback_model.dart';
import 'models/review_model.dart';
import 'models/verification_request_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await testAllModels(); // ← Test all models
  runApp(const MyApp());
}

Future<void> testAllModels() async {
  final db = FirebaseFirestore.instance;

  // 1. Create User
  final user = UserModel(
    id: 'test_user_1',
    email: 'test@student.com',
    role: 'student',
    status: 'active',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  await db.collection('users').doc(user.id).set(user.toFirestore());
  print('✅ User created');

  // 2. Create Profile
  final profile = ProfileModel(
    id: 'profile_1',
    userId: user.id,
    fullName: 'Test Student',
    college: 'MIT',
    semester: 3,
    bio: 'Learning new skills',
    profileImage: '',
    verificationStatus: 'pending',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  await db.collection('profiles').doc(profile.id).set(profile.toFirestore());
  print('✅ Profile created');

  // 3. Create Skill
  final skill = SkillModel(
    id: 'skill_1',
    name: 'Flutter',
    category: 'Programming',
    status: 'active',
  );
  await db.collection('skills').doc(skill.id).set(skill.toFirestore());
  print('✅ Skill created');

  // 4. Create UserSkill
  final userSkill = UserSkillModel(
    id: 'us_1',
    userId: user.id,
    skillId: skill.id,
    type: 'teach',
    skillLevel: SkillLevel.expert,
  );
  await db.collection('user_skills').doc(userSkill.id).set(userSkill.toFirestore());
  print('✅ UserSkill created');

  // 5. Create LearningRequest
  final request = LearningRequestModel(
    id: 'req_1',
    senderId: user.id,
    receiverId: 'other_user',
    skillId: skill.id,
    message: 'Can you teach me Flutter?',
    status: 'pending',
    createdAt: DateTime.now(),
  );
  await db.collection('learning_requests').doc(request.id).set(request.toFirestore());
  print('✅ LearningRequest created');

  // 6. Create Meeting
  final meeting = MeetingModel(
    id: 'meet_1',
    requestId: request.id,
    teacherId: user.id,
    learnerId: 'other_user',
    skillId: skill.id,
    meetingDate: DateTime.now().add(Duration(days: 2)),
    startTime: '10:00',
    endTime: '11:00',
    zoomMeetingId: '123456',
    zoomJoinUrl: 'https://zoom.us/j/123456',
    status: 'scheduled',
    createdAt: DateTime.now(),
  );
  await db.collection('meetings').doc(meeting.id).set(meeting.toFirestore());
  print('✅ Meeting created');

  // 7. Create Feedback
  final feedback = FeedbackModel(
    id: 'fb_1',
    meetingId: meeting.id,
    fromUserId: 'other_user',
    toUserId: user.id,
    rating: 5,
    comment: 'Great teacher!',
    createdAt: DateTime.now(),
  );
  await db.collection('feedbacks').doc(feedback.id).set(feedback.toFirestore());
  print('✅ Feedback created');

  // 8. Create Review
  final review = ReviewModel(
    id: 'rev_1',
    reviewerId: 'other_user',
    reviewedUserId: user.id,
    rating: 5,
    comment: 'Excellent skills!',
    createdAt: DateTime.now(),
  );
  await db.collection('reviews').doc(review.id).set(review.toFirestore());
  print('✅ Review created');

  // 9. Create VerificationRequest
  final verification = VerificationRequestModel(
    id: 'ver_1',
    userId: user.id,
    documentUrl: 'https://storage/student_id.jpg',
    status: 'pending',
    adminComment: '',
    submittedAt: DateTime.now(),
    reviewedAt: null,
  );
  await db.collection('verification_requests').doc(verification.id).set(verification.toFirestore());
  print('✅ VerificationRequest created');

  print('\n🎉 ALL 9 MODELS TESTED SUCCESSFULLY!');
  print('📁 Check your Firebase Console > Firestore Database');


  await db.collection('users').doc('test_user_1').delete();
  await db.collection('profiles').doc('profile_1').delete();
  await db.collection('skills').doc('skill_1').delete();
  await db.collection('user_skills').doc('us_1').delete();
  await db.collection('learning_requests').doc('req_1').delete();
  await db.collection('meetings').doc('meet_1').delete();
  await db.collection('feedbacks').doc('fb_1').delete();
  await db.collection('reviews').doc('rev_1').delete();
  await db.collection('verification_requests').doc('ver_1').delete();

  print('\n🎉 ALL 9 MODELS TESTED AND CLEANED!');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Skill Bridge',
      home: Scaffold(
        appBar: AppBar(title: Text('Skill Bridge - Test Complete')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 80),
              SizedBox(height: 20),
              Text(
                '✅ All 9 Models Created in Firestore!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                'Check Firebase Console → Firestore Database',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}