import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../controllers/favorites_controller.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/user_service.dart';

class FavoritesView extends GetView<FavoritesController> {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          "Tanlanganlar",
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: AppTheme.textDark),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (controller.rxFavorites.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 64,
                  color: AppTheme.textLight,
                ),
                SizedBox(height: 16),
                Text(
                  "Sizda tanlangan ustalar yo'q",
                  style: TextStyle(color: AppTheme.textMedium, fontSize: 16),
                ),
              ],
            ),
          ).animate().fadeIn();
        }

        return ListView.builder(
          padding: EdgeInsets.all(20),
          physics: BouncingScrollPhysics(),
          itemCount: controller.rxFavorites.length,
          itemBuilder: (context, index) {
            final barber = controller.rxFavorites[index];
            return _buildFavoriteCard(barber, index);
          },
        );
      }),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> barber, int index) {
    return GestureDetector(
          onTap: () => Get.toNamed('/barber-detail', arguments: barber),
          child: Container(
            margin: EdgeInsets.only(bottom: 16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: CachedNetworkImageProvider(
                        barber['image'] ??
                            'https://i.pravatar.cc/400?u=${barber['id']}',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        barber['name'] ?? 'Usta',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.textDark,
                        ),
                      ),
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star_rounded,
                            size: 14,
                            color: AppTheme.gold,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "${barber['rating'] ?? 5.0}",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textDark,
                            ),
                          ),
                          Text(
                            " (${barber['reviewCount'] ?? 0})",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textLight,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        barber['address'] ?? "Toshkent",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () =>
                      Get.find<UserService>().toggleFavorite(barber['id']),
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_rounded,
                      color: Colors.redAccent,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 100 + (index * 50)))
        .slideX(begin: 0.1);
  }
}
