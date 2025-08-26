import 'package:flutter/material.dart';
import '../../data/models/user_model.dart';

/// User avatar widget with fallback to initials
class UserAvatar extends StatelessWidget {
  final UserModel user;
  final double radius;
  final VoidCallback? onTap;

  const UserAvatar({
    super.key,
    required this.user,
    this.radius = 20,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: NetworkImage(user.photoUrl!),
        onBackgroundImageError: (exception, stackTrace) {
          // Fallback to initials if image fails to load
        },
        child: user.photoUrl!.isEmpty ? Text(
          user.initials,
          style: TextStyle(
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ) : null,
      );
    } else {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: Text(
          user.initials,
          style: TextStyle(
            fontSize: radius * 0.6,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      );
    }

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: avatar,
      );
    }

    return avatar;
  }
}