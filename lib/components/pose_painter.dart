import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:vector_math/vector_math.dart' as vector;
import 'dart:math';
import 'dart:core';
import 'coordinate_translator.dart';
import 'package:healthcare/models/action_info_post.dart';
import 'package:healthcare/services/remote_service_action_info.dart';
import 'package:healthcare/services/remote_service_video_set.dart';

int cnt = 0;
int prv = -1, cur = -1;
double prv_Time = 0, cur_Time = 0;
double stepCurTime = 0, stepPrvTime = 0;

PostDetail? posts;
bool flag = false;

// void getData() async {
//   posts = await RemoteService_detail().getPostsdetail(ID);
//   start_angle = int.parse(posts?.result.data.stage1[0].angle1 ?? '');
//   end_angle = int.parse(posts?.result.data.stage1[0].angle2 ?? '');
//   varience = int.parse(posts?.result.data.stage1[0].variance ?? '');
//   fail_time = int.parse(posts?.result.data.stage1[0].failTime ?? '');
//   angleGt = int.parse(posts?.result.data.stage1[0].angleGt ?? '');
//   notif_test13 = posts?.result.data.stage1[0].angleGtMsg ?? '';
//   if (posts != null) {
//     code = posts?.code;
//     message = posts?.msg;
//     print("|||||||||||||||||||||||||||||API|||||||||||||||||||||||||||||");
//     print(message);
//     print(notif_test13);
//   } else {
//     print('~~~~~~~~~~~~~~~~~~~~~~~~~~~~~API request failed');
//   }
// }

class PosePainter extends CustomPainter {
  PosePainter(this.poses, this.absoluteImageSize, this.rotation);

  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  //Calcuate angle of 3 joint points
  double calculateAngle(Offset p1, Offset p2, Offset p3) {
    final vector.Vector2 v1 = vector.Vector2(p1.dx - p2.dx, p1.dy - p2.dy);
    final vector.Vector2 v2 = vector.Vector2(p3.dx - p2.dx, p3.dy - p2.dy);
    final double dotProduct = v1.dot(v2);
    final double cosAngle = dotProduct / (v1.length * v2.length);
    final double angle = acos(cosAngle);
    double degrees = angle * 180 / pi; // Convert to degrees
    if (degrees > 180.0) degrees = 360 - degrees;
    return degrees;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // print("~~~~~~~~~~~~~~~~#Painter:Video_Start_End_Time#~~~~~~~~~~~~~~");
    // print(video_start_Time);
    // print(video_end_Time);

    //progress_bar
    double progress_percent;

    final Paint backgroundPaint = Paint()
      ..color = Colors.grey
      ..style = PaintingStyle.fill;

    final Paint progressPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    double left = 30;
    double top = 1.0 * ((size.height / 3).toInt());
    double right = left + 10;
    double bottom = 2 * top;
    // // Draw the background bar
    // Define the border radius for the rounded corners
    final borderRadius = BorderRadius.circular(10.0);

    // Create a rounded rectangle from the provided rect and border radius
    final roundedRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(left, top, right, bottom),
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomLeft: borderRadius.bottomLeft,
      bottomRight: borderRadius.bottomRight,
    );

    canvas.drawRRect(roundedRect, backgroundPaint);

    // // Draw the progress bar based on the given percent
    // canvas.drawRect(
    //   Rect.fromLTRB(
    //       left, bottom, right, bottom - (bottom - top) * progress_percent),
    //   progressPaint,
    // );

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.yellow;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.green;

    final whitePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.white;

    //Angle of joint
    double angleShow(joint1, joint2, joint3) {
      return calculateAngle(
        Offset(translateX(joint1.x, rotation, size, absoluteImageSize),
            translateY(joint1.y, rotation, size, absoluteImageSize)),
        Offset(translateX(joint2.x, rotation, size, absoluteImageSize),
            translateY(joint2.y, rotation, size, absoluteImageSize)),
        Offset(translateX(joint3.x, rotation, size, absoluteImageSize),
            translateY(joint3.y, rotation, size, absoluteImageSize)),
      );
    }

    //Line between two joints
    void paintLine(joint1, joint2, Paint paintType) {
      canvas.drawLine(
          Offset(translateX(joint1.x, rotation, size, absoluteImageSize),
              translateY(joint1.y, rotation, size, absoluteImageSize)),
          Offset(translateX(joint2.x, rotation, size, absoluteImageSize),
              translateY(joint2.y, rotation, size, absoluteImageSize)),
          paintType);
    }

    DateTime currentTime = DateTime.now();
    cur_Time = currentTime.second + currentTime.millisecond / 1000.0;
    stepCurTime = currentTime.second + currentTime.millisecond / 1000.0;
    if (!flag) {
      flag = true;
      prv_Time = cur_Time;
    }

    void notification_alarm(String str) {
      final notification = TextSpan(
        text: str,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
        ),
      );
      final notificationText = TextPainter(
        text: notification,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      notificationText.layout();

      final notificationPosition = Offset(120 - (notificationText.width * 0.5),
          50 - (notificationText.height * 0.5));
      notificationText.paint(canvas, notificationPosition);
    }

    for (final pose in poses) {
      final PoseLandmark jointNose = pose.landmarks[PoseLandmarkType.nose]!;
      final PoseLandmark jointLeftEyeInner =
          pose.landmarks[PoseLandmarkType.leftEyeInner]!;
      final PoseLandmark jointLeftEye =
          pose.landmarks[PoseLandmarkType.leftEye]!;
      final PoseLandmark jointLeftEyeOuter =
          pose.landmarks[PoseLandmarkType.leftEyeOuter]!;
      final PoseLandmark jointRightEyeInner =
          pose.landmarks[PoseLandmarkType.rightEyeInner]!;
      final PoseLandmark jointRightEye =
          pose.landmarks[PoseLandmarkType.rightEye]!;
      final PoseLandmark jointRightEyeOuter =
          pose.landmarks[PoseLandmarkType.rightEyeOuter]!;
      final PoseLandmark jointLeftEar =
          pose.landmarks[PoseLandmarkType.leftEar]!;
      final PoseLandmark jointRightEar =
          pose.landmarks[PoseLandmarkType.rightEar]!;
      final PoseLandmark jointLeftMouth =
          pose.landmarks[PoseLandmarkType.leftMouth]!;
      final PoseLandmark jointRightMouth =
          pose.landmarks[PoseLandmarkType.rightMouth]!;
      final PoseLandmark jointLeftShoulder =
          pose.landmarks[PoseLandmarkType.leftShoulder]!;
      final PoseLandmark jointRightShoulder =
          pose.landmarks[PoseLandmarkType.rightShoulder]!;
      final PoseLandmark jointLeftElbow =
          pose.landmarks[PoseLandmarkType.leftElbow]!;
      final PoseLandmark jointRightElbow =
          pose.landmarks[PoseLandmarkType.rightElbow]!;
      final PoseLandmark jointLeftWrist =
          pose.landmarks[PoseLandmarkType.leftWrist]!;
      final PoseLandmark jointRightWrist =
          pose.landmarks[PoseLandmarkType.rightWrist]!;
      final PoseLandmark jointLeftPinky =
          pose.landmarks[PoseLandmarkType.leftPinky]!;
      final PoseLandmark jointRightPinky =
          pose.landmarks[PoseLandmarkType.rightPinky]!;
      final PoseLandmark jointLeftIndex =
          pose.landmarks[PoseLandmarkType.leftIndex]!;
      final PoseLandmark jointRightIndex =
          pose.landmarks[PoseLandmarkType.rightIndex]!;
      final PoseLandmark jointLeftThumb =
          pose.landmarks[PoseLandmarkType.leftThumb]!;
      final PoseLandmark jointRightThumb =
          pose.landmarks[PoseLandmarkType.rightThumb]!;
      final PoseLandmark jointLeftHip =
          pose.landmarks[PoseLandmarkType.leftHip]!;
      final PoseLandmark jointRightHip =
          pose.landmarks[PoseLandmarkType.rightHip]!;
      final PoseLandmark jointLeftKnee =
          pose.landmarks[PoseLandmarkType.leftKnee]!;
      final PoseLandmark jointRightKnee =
          pose.landmarks[PoseLandmarkType.rightKnee]!;
      final PoseLandmark jointLeftAnkle =
          pose.landmarks[PoseLandmarkType.leftAnkle]!;
      final PoseLandmark jointRightAnkle =
          pose.landmarks[PoseLandmarkType.rightAnkle]!;
      final PoseLandmark jointLeftHeel =
          pose.landmarks[PoseLandmarkType.leftHeel]!;
      final PoseLandmark jointRightHeel =
          pose.landmarks[PoseLandmarkType.rightHeel]!;
      final PoseLandmark jointLeftFootIndex =
          pose.landmarks[PoseLandmarkType.leftFootIndex]!;
      final PoseLandmark jointRightFootIndex =
          pose.landmarks[PoseLandmarkType.rightFootIndex]!;

      double detect_accuracy = 0.95;
      bool bf = true;
      bf = bf &&
          (jointNose.likelihood >= detect_accuracy) &&
          (jointLeftEyeInner.likelihood >= detect_accuracy) &&
          (jointLeftEye.likelihood >= detect_accuracy) &&
          (jointLeftEyeOuter.likelihood >= detect_accuracy) &&
          (jointRightEyeInner.likelihood >= detect_accuracy) &&
          (jointRightEye.likelihood >= detect_accuracy) &&
          (jointRightEyeOuter.likelihood >= detect_accuracy) &&
          (jointLeftEar.likelihood >= detect_accuracy) &&
          (jointRightEar.likelihood >= detect_accuracy) &&
          (jointLeftMouth.likelihood >= detect_accuracy) &&
          (jointRightMouth.likelihood >= detect_accuracy) &&
          (jointLeftShoulder.likelihood >= detect_accuracy) &&
          (jointRightShoulder.likelihood >= detect_accuracy) &&
          (jointLeftElbow.likelihood >= detect_accuracy) &&
          (jointRightElbow.likelihood >= detect_accuracy) &&
          (jointLeftWrist.likelihood >= detect_accuracy) &&
          (jointRightWrist.likelihood >= detect_accuracy) &&
          (jointLeftPinky.likelihood >= detect_accuracy) &&
          (jointRightPinky.likelihood >= detect_accuracy) &&
          (jointLeftIndex.likelihood >= detect_accuracy) &&
          (jointRightIndex.likelihood >= detect_accuracy) &&
          (jointLeftThumb.likelihood >= detect_accuracy) &&
          (jointRightThumb.likelihood >= detect_accuracy) &&
          (jointLeftHip.likelihood >= detect_accuracy) &&
          (jointRightHip.likelihood >= detect_accuracy) &&
          (jointLeftKnee.likelihood >= detect_accuracy) &&
          (jointRightKnee.likelihood >= detect_accuracy) &&
          (jointLeftAnkle.likelihood >= detect_accuracy) &&
          (jointRightAnkle.likelihood >= detect_accuracy) &&
          (jointLeftHeel.likelihood >= detect_accuracy) &&
          (jointRightHeel.likelihood >= detect_accuracy) &&
          (jointLeftFootIndex.likelihood >= detect_accuracy) &&
          (jointRightFootIndex.likelihood >= detect_accuracy);

      //Notificiation when user's body not fully visible or correct distance
      if (!bf) {
        String str =
            'Please Keep your body fully\nvisible on camera to start or\nKeep distance as 5 to 6 ft!';
        notification_alarm(str);
      } else {
        // Draw joints
        //Draw arms
        paintLine(jointLeftElbow, jointLeftWrist, leftPaint);
        paintLine(jointLeftShoulder, jointLeftElbow, leftPaint);
        paintLine(jointRightShoulder, jointRightElbow, rightPaint);
        paintLine(jointRightElbow, jointRightWrist, rightPaint);
        //Draw hands
        paintLine(jointLeftWrist, jointLeftThumb, leftPaint);
        paintLine(jointLeftWrist, jointLeftIndex, leftPaint);
        paintLine(jointLeftWrist, jointLeftPinky, leftPaint);
        paintLine(jointRightWrist, jointRightThumb, rightPaint);
        paintLine(jointRightWrist, jointRightIndex, rightPaint);
        paintLine(jointRightWrist, jointRightPinky, rightPaint);
        //Draw body
        paintLine(jointLeftShoulder, jointLeftHip, leftPaint);
        paintLine(jointRightShoulder, jointRightHip, rightPaint);
        paintLine(jointLeftShoulder, jointRightShoulder, whitePaint);
        paintLine(jointLeftHip, jointRightHip, whitePaint);
        //Draw legs
        paintLine(jointLeftHip, jointLeftKnee, leftPaint);
        paintLine(jointLeftKnee, jointLeftAnkle, leftPaint);
        paintLine(jointLeftAnkle, jointLeftHeel, leftPaint);
        paintLine(jointLeftHeel, jointLeftFootIndex, leftPaint);
        paintLine(jointLeftAnkle, jointLeftFootIndex, leftPaint);
        paintLine(jointRightHip, jointRightKnee, rightPaint);
        paintLine(jointRightKnee, jointRightAnkle, rightPaint);
        paintLine(jointRightAnkle, jointRightHeel, rightPaint);
        paintLine(jointRightHeel, jointRightFootIndex, rightPaint);
        paintLine(jointRightAnkle, jointRightFootIndex, rightPaint);

        // //Display angle of joints
        // final angleJoints = TextSpan(
        //   text: '${angleShow(jointLeftElbow, jointLeftWrist, jointLeftIndex).toInt()}°(L_Wr)\n' +
        //       '${angleShow(jointRightElbow, jointRightWrist, jointRightIndex).toInt()}°(R_Wr)\n' +
        //       '${angleShow(jointLeftShoulder, jointLeftHip, jointLeftKnee).toInt()}°(L_Hp L_Kn)\n' +
        //       '${angleShow(jointRightShoulder, jointRightHip, jointRightKnee).toInt()}°(R_Hp R_Kn)\n' +
        //       '${angleShow(jointLeftShoulder, jointLeftHip, jointLeftAnkle).toInt()}°(L_Hp L_Ak)\n' +
        //       '${angleShow(jointRightShoulder, jointRightHip, jointRightAnkle).toInt()}°(R_Hp R_Ak)\n' +
        //       '${angleShow(jointLeftAnkle, jointLeftKnee, jointLeftHip).toInt()}°(L_Kn)\n' +
        //       '${angleShow(jointRightAnkle, jointRightKnee, jointRightHip).toInt()}°(R_Kn)\n' +
        //       '${angleShow(jointLeftKnee, jointLeftAnkle, jointLeftFootIndex).toInt()}°(L_Ft)\n' +
        //       '${angleShow(jointRightKnee, jointRightAnkle, jointRightFootIndex).toInt()}°(R_Ft)\n' +
        //       '${angleShow(jointLeftShoulder, jointLeftElbow, jointLeftWrist).toInt()}°(L_Eb)\n' +
        //       '${angleShow(jointRightShoulder, jointRightElbow, jointRightWrist).toInt()}°(R_Eb)\n' +
        //       '${angleShow(jointLeftHip, jointLeftShoulder, jointLeftWrist).toInt()}°(L_Sh L_Wr)\n' +
        //       '${angleShow(jointRightHip, jointRightShoulder, jointRightWrist).toInt()}°(R_Sh R_Wr)\n' +
        //       '${angleShow(jointLeftHip, jointLeftShoulder, jointLeftElbow).toInt()}°(L_Sh L_Eb)\n' +
        //       '${angleShow(jointRightHip, jointRightShoulder, jointRightElbow).toInt()}°(R_Sh R_Eb)\n',
        //   style: TextStyle(
        //     color: Colors.cyanAccent,
        //     fontSize: 18,
        //   ),
        // );

        // final angleJointsText = TextPainter(
        //   text: angleJoints,
        //   textAlign: TextAlign.right,
        //   textDirection: TextDirection.ltr,
        // );

        // angleJointsText.layout();

        // // Draw the text centered around the point (x, y) for instance
        // final angleJointsPosition = Offset(380 - (angleJointsText.width * 0.5),
        //     400 - (angleJointsText.height * 0.5));
        // angleJointsText.paint(canvas, angleJointsPosition);
      }

      //Points of pose
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
            Offset(
              translateX(landmark.x, rotation, size, absoluteImageSize),
              translateY(landmark.y, rotation, size, absoluteImageSize),
            ),
            1,
            paint);
      });

      //Count of repetitions ,only push down/up exercises - test13
      // int leftElbowAngle =
      //     angleShow(jointLeftShoulder, jointLeftElbow, jointLeftWrist).toInt();
      int curAngle =
          angleShow(jointRightShoulder, jointRightElbow, jointRightWrist)
              .toInt();
      if (curAngle > angleGt) {
        notification_alarm(angleGtMsg);
      }
      // print('*********************************************');
      // print(start_angle);
      // print(end_angle);
      if (curAngle >= start_angle - varience &&
          curAngle <= start_angle + varience) {
        cur = -1;
        // notification_alarm('down');
      }
      if (curAngle >= end_angle - varience &&
          curAngle <= end_angle + varience) {
        cur = 1;
        // notification_alarm('up');
      }
      // print('******************current_time is:\n');
      // print(cur_Time);
      if (cur_Time < prv_Time) cur_Time += 60;
      double time_Calcul = cur_Time - prv_Time;
      if (time_Calcul > video_end_Time) notification_alarm('Time Over');
      int ttt = (stepCurTime >= stepPrvTime
              ? (stepCurTime - stepPrvTime)
              : (stepCurTime + 60.0 - stepPrvTime))
          .toInt();

      if (prv == 1 && cur == -1) {
        if (ttt <= fail_time) {
          if (time_Calcul > video_start_Time) cnt++;
          stepPrvTime = stepCurTime;
          // print(
          //     "----------------------------------------$cnt--count changes!!!");
        }
      }
      if (ttt > fail_time) {
        notification_alarm(failMsg);
        if (cur == -1) stepPrvTime = stepCurTime;
      }

      final repetition = TextSpan(
        text: '$cnt\n',
        style: TextStyle(color: Color.fromARGB(255, 5, 1, 255), fontSize: 15),
      );
      final repetitionText = TextPainter(
        text: repetition,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      repetitionText.layout();

      final repetitionPosition = Offset(left + 5 - (repetitionText.width * 0.5),
          top - 5 - (repetitionText.height * 0.5));
      repetitionText.paint(canvas, repetitionPosition);

      prv = cur;

      double calculatePercentage() {
        double res = 0;
        if (start_angle > end_angle) {
          if (curAngle >= start_angle) res = 0;
          if (curAngle <= end_angle) res = 1.0;
          if (curAngle < start_angle && curAngle > end_angle)
            res = (start_angle - curAngle) / (start_angle - end_angle);
        } else {
          if (curAngle <= start_angle) res = 0;
          if (curAngle >= end_angle) res = 1.0;
          if (curAngle > start_angle && curAngle < end_angle)
            res = (curAngle - start_angle) / (end_angle - start_angle);
        }
        // double res = (min(1.0 * angleGt, curAngle) / 10.0).toInt() / 10.0;
        return (res * 10).toInt() / 10.0;
      }

      progress_percent = calculatePercentage();

      // Draw the progress bar based on the given percent
      final rect = Rect.fromLTRB(
        left,
        bottom,
        right,
        bottom - (bottom - top) * progress_percent,
      );

      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: borderRadius.topLeft,
        topRight: borderRadius.topRight,
        bottomLeft: borderRadius.bottomLeft,
        bottomRight: borderRadius.bottomRight,
      );

      canvas.drawRRect(rrect, progressPaint);

      //timer start
      // print(ss);
      final timeElapsed = TextSpan(
        text: '${time_Calcul.toStringAsFixed(1)}',
        // text: '$currentTime',
        style: TextStyle(color: Color.fromARGB(255, 5, 1, 255), fontSize: 15),
      );
      final timeElapsedText = TextPainter(
        text: timeElapsed,
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );

      timeElapsedText.layout();

      final textX = left + 5 - timeElapsedText.width * 0.5;
      final textY = bottom + 10 - timeElapsedText.height * 0.5;

      timeElapsedText.paint(canvas, Offset(textX, textY));

      // // Display Inframelikelihood value of joints
      // final likelihood = TextSpan(
      //   text: 'Nose:${floorWithFixedDecimal(jointNose.likelihood, 4)}\n' +
      //       'LeftEyeIneer:${floorWithFixedDecimal(jointLeftEyeInner.likelihood, 4)}\n' +
      //       'LeftEye:${floorWithFixedDecimal(jointLeftEye.likelihood, 4)}\n' +
      //       'LeftEyeOuter:${floorWithFixedDecimal(jointLeftEyeOuter.likelihood, 4)}\n' +
      //       'RightEyeInner:${floorWithFixedDecimal(jointRightEyeInner.likelihood, 4)}\n' +
      //       'RightEye:${floorWithFixedDecimal(jointRightEye.likelihood, 4)}\n' +
      //       'RightEyeOuter:${floorWithFixedDecimal(jointRightEyeOuter.likelihood, 4)}\n' +
      //       'LeftEar:${floorWithFixedDecimal(jointLeftEar.likelihood, 4)}\n' +
      //       'RightEar:${floorWithFixedDecimal(jointRightEar.likelihood, 4)}\n' +
      //       'LeftMouth:${floorWithFixedDecimal(jointLeftMouth.likelihood, 4)}\n' +
      //       'RightMouth:${floorWithFixedDecimal(jointRightMouth.likelihood, 4)}\n' +
      //       'LeftShoulder:${floorWithFixedDecimal(jointLeftShoulder.likelihood, 4)}\n' +
      //       'RightShoulder:${floorWithFixedDecimal(jointRightShoulder.likelihood, 4)}\n' +
      //       'LeftElbow:${floorWithFixedDecimal(jointLeftElbow.likelihood, 4)}\n' +
      //       'RightElbow:${floorWithFixedDecimal(jointRightElbow.likelihood, 4)}\n' +
      //       'LeftWrist:${floorWithFixedDecimal(jointLeftWrist.likelihood, 4)}\n' +
      //       'RightWrist:${floorWithFixedDecimal(jointRightWrist.likelihood, 4)}\n' +
      //       'LeftPinky:${floorWithFixedDecimal(jointLeftPinky.likelihood, 4)}\n' +
      //       'RightPinky:${floorWithFixedDecimal(jointRightPinky.likelihood, 4)}\n' +
      //       'LeftIndex:${floorWithFixedDecimal(jointLeftIndex.likelihood, 4)}\n' +
      //       'RightIndex:${floorWithFixedDecimal(jointRightIndex.likelihood, 4)}\n' +
      //       'LeftThumb:${floorWithFixedDecimal(jointLeftThumb.likelihood, 4)}\n' +
      //       'RightThumb:${floorWithFixedDecimal(jointRightThumb.likelihood, 4)}\n' +
      //       'LeftHip:${floorWithFixedDecimal(jointLeftHip.likelihood, 4)}\n' +
      //       'LeftRightHip:${floorWithFixedDecimal(jointRightHip.likelihood, 4)}\n' +
      //       'LeftKnee:${floorWithFixedDecimal(jointLeftKnee.likelihood, 4)}\n' +
      //       'RightKnee:${floorWithFixedDecimal(jointRightKnee.likelihood, 4)}\n' +
      //       'LeftAnkle:${floorWithFixedDecimal(jointLeftAnkle.likelihood, 4)}\n' +
      //       'RightAnkle:${floorWithFixedDecimal(jointRightAnkle.likelihood, 4)}\n' +
      //       'LeftHeel:${floorWithFixedDecimal(jointLeftHeel.likelihood, 4)}\n' +
      //       'RightHeel:${floorWithFixedDecimal(jointRightHeel.likelihood, 4)}\n' +
      //       'LeftFootIndex:${floorWithFixedDecimal(jointLeftFootIndex.likelihood, 4)}\n' +
      //       'RightFootIndex:${floorWithFixedDecimal(jointRightFootIndex.likelihood, 4)}\n',
      //   style: TextStyle(
      //     color: Colors.deepOrange,
      //     fontSize: 15,
      //   ),
      // );
      // final likelihoodText = TextPainter(
      //   text: likelihood,
      //   textAlign: TextAlign.center,
      //   textDirection: TextDirection.ltr,
      // );
      // likelihoodText.layout();

      // final likelihoodPosition = Offset(90 - (likelihoodText.width * 0.5),
      //     430 - (likelihoodText.height * 0.5));
      // likelihoodText.paint(canvas, likelihoodPosition);
    }
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.absoluteImageSize != absoluteImageSize ||
        oldDelegate.poses != poses;
  }
}
