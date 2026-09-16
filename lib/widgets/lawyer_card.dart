import 'package:flutter/material.dart';
import 'package:avukatbul/models/lawyer_model.dart';
import 'package:avukatbul/widgets/rating_bar.dart';
import 'package:cached_network_image/cached_network_image.dart';

class LawyerCard extends StatelessWidget {
  final LawyerModel lawyer;
  final VoidCallback onTap;
  
  const LawyerCard({
    Key? key,
    required this.lawyer,
    required this.onTap,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profil fotoğrafı
              _buildProfileImage(context),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lawyer.name.isNotEmpty ? lawyer.name : 'İsimsiz Avukat',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 4),
                        Text(
                          lawyer.city,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        RatingBar(
                          rating: lawyer.averageRating,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          '(${lawyer.averageRating.toStringAsFixed(1)})',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      lawyer.bio.isEmpty
                        ? 'Avukat henüz bir biyografi eklememiş.'
                        : lawyer.bio.length > 100
                          ? '${lawyer.bio.substring(0, 100)}...'
                          : lawyer.bio,
                      style: TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildProfileImage(BuildContext context) {
    if (lawyer.profileImageUrl != null && lawyer.profileImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: CachedNetworkImage(
          imageUrl: lawyer.profileImageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          placeholder: (context, url) => CircularProgressIndicator(),
          errorWidget: (context, url, error) => _buildDefaultAvatar(context),
        ),
      );
    } else {
      return _buildDefaultAvatar(context);
    }
  }
  
  Widget _buildDefaultAvatar(BuildContext context) {
    return CircleAvatar(
      radius: 30,
      backgroundColor: Theme.of(context).primaryColor,
      child: Text(
        lawyer.name.isNotEmpty ? lawyer.name.substring(0, 1).toUpperCase() : '?',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
