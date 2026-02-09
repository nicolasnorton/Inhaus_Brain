import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_theme.dart';

class LegalDocumentViewer extends StatelessWidget {
  final String title;
  final String content;

  const LegalDocumentViewer({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    // Check if we can pop to determine if we should show a back button or maybe a logo if standalone
    final canPop = GoRouter.of(context).canPop();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null, // If generic web hit, maybe no back button needed, or maybe a home button?
        actions: [
            // If it's a standalone page, maybe a link to home? 
            if (!canPop)
                IconButton(
                    icon: const Icon(Icons.home),
                    onPressed: () => context.go('/'),
                    tooltip: 'Home',
                )
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800), // Max width for reading comfort
          padding: const EdgeInsets.all(24.0),
          child: Markdown(
            data: content,
            styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
              h1: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
              h2: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.secondary,
                  ),
              h3: Theme.of(context).textTheme.titleMedium?.copyWith(
                   fontWeight: FontWeight.w600,
              ),
              p: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: Colors.white70,
                  ),
              listBullet: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.primary,
              ),
              blockSpacing: 16.0,
            ),
            onTapLink: (text, href, title) {
              if (href != null) {
                launchUrl(Uri.parse(href));
              }
            },
            selectable: true,
          ),
        ),
      ),
    );
  }
}
