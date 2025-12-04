import 'package:flutter/material.dart';
import 'program_dashboard_screen.dart';
import '../widgets/app_logo.dart';
import 'package:ndu_project/widgets/kaz_ai_chat_bubble.dart';
import 'portfolio_dashboard_screen.dart';
import 'project_dashboard_screen.dart';

class ManagementLevelScreen extends StatefulWidget {
  const ManagementLevelScreen({super.key});

  @override
  State<ManagementLevelScreen> createState() => _ManagementLevelScreenState();
}

class _ManagementLevelScreenState extends State<ManagementLevelScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: _buildMainContent(context),
          ),
          const KazAiChatBubble(),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const SizedBox(height: 80),
          AppLogo(
            height: 240,
          ),
          const SizedBox(height: 32),
          // Title
          const Text(
            'Choose Your Management Level',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          // Subtitle
          Text(
            'Select the scope of work you want to manage:',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 80),
          // Management Level Cards
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildManagementCardWithImage(
                imageUrl: 'assets/images/project-management.png',
                title: 'Project',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProjectDashboardScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 60),
              _buildManagementCardWithImage(
                imageUrl: 'assets/images/monitoring.png',
                title: 'Program',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProgramDashboardScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 60),
              _buildManagementCardWithImage(
                imageUrl: 'assets/images/professional-portfolio.png',
                title: 'Portfolio',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PortfolioDashboardScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManagementCardWithImage({
    required String imageUrl,
    required String title,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image area with consistent aspect ratio and high-quality scaling
            LayoutBuilder(
              builder: (context, constraints) {
                final dpr = MediaQuery.devicePixelRatioOf(context);
                final targetLogicalWidth = 120.0; // visible logical px we aim for
                final cacheWidth = (targetLogicalWidth * dpr).round();

                Widget imageChild;
                if (imageUrl.toLowerCase().startsWith('http')) {
                  imageChild = Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) {
                      return _imageFallback();
                    },
                  );
                } else {
                  imageChild = Image.asset(
                    imageUrl,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    cacheWidth: cacheWidth,
                    errorBuilder: (context, error, stackTrace) {
                      return _imageFallback();
                    },
                  );
                }

                return Container(
                  width: targetLogicalWidth,
                  height: 96,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: RepaintBoundary(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: imageChild,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 40,
        color: Colors.grey,
      ),
    );
  }
}