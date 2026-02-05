
import 'package:flutter/material.dart';

enum EmployeeStatus { active, onLeave, terminated }
enum LeadStatus { newLead, contacted, qualified, proposalSent, negotiation, closedWon, closedLost }

class AgencyEmployee {
  final String id;
  final String name;
  final String role;
  final String email;
  final String avatarUrl;
  final EmployeeStatus status;
  final DateTime joinDate;

  AgencyEmployee({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    required this.avatarUrl,
    required this.status,
    required this.joinDate,
  });
}

class SalesLead {
  final String id;
  final String name;
  final String company;
  final String email;
  final String phone;
  final LeadStatus status;
  final double estimatedValue;
  final DateTime lastContacted;
  final String notes;

  SalesLead({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.phone,
    required this.status,
    required this.estimatedValue,
    required this.lastContacted,
    required this.notes,
  });
}

class FinanceMetric {
  final String label;
  final double value;
  final double percentChange;
  final bool isPositiveTrend;
  final IconData icon;
  final Color color;

  FinanceMetric({
    required this.label,
    required this.value,
    required this.percentChange,
    required this.isPositiveTrend,
    required this.icon,
    required this.color,
  });
}

enum ServiceCategory {
  socialMedia,
  webDev,
  branding,
  production,
  other
}

class ServicePackage {
  final String id;
  final String name;
  final ServiceCategory category;
  final double price; // Base price
  final String description;
  final List<String> includes;
  final List<String> excludes;

  ServicePackage({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.description,
    required this.includes,
    this.excludes = const [],
  });

  // Helper to get catalog
  static List<ServicePackage> getCatalog() {
    return [
      // Web
      ServicePackage(
        id: 'web_refresh',
        name: 'Refresh Look & Feel Web',
        category: ServiceCategory.webDev,
        price: 1700.00,
        description: 'Renew digital presence using Ghost.org.',
        includes: ['Redesign Key Sections', 'CMS Ghost Implementation', 'Basic SEO', 'Training'],
      ),
      ServicePackage(
        id: 'web_landing',
        name: 'Landing Page (Webflow)',
        category: ServiceCategory.webDev,
        price: 1000.00,
        description: 'Single page promotional site.',
        includes: ['One-page design', 'Webflow CMS', 'Analytics Setup'],
      ),
       ServicePackage(
        id: 'web_full',
        name: 'Web Profesional (Webflow)',
        category: ServiceCategory.webDev,
        price: 2000.00,
        description: 'Complete corporate website up to 20 pages.',
        includes: ['Home + 20 Pages', 'SEO', 'Creative Gallery'],
      ),
      
      // Social Media
      ServicePackage(
        id: 'smm_entrepreneur',
        name: 'SMM Emprendedor',
        category: ServiceCategory.socialMedia,
        price: 1000.00,
        description: 'For startups. Facebook + Instagram.',
        includes: ['20 Content Pieces', '1 Reel', 'Community Mgmt'],
      ),
      ServicePackage(
        id: 'smm_starter',
        name: 'SMM Starter',
        category: ServiceCategory.socialMedia,
        price: 1500.00,
        description: 'For growing brands. Facebook + Instagram.',
        includes: ['30 Content Pieces', '2 Reels', 'Community Mgmt'],
      ),
      ServicePackage(
        id: 'smm_corporate',
        name: 'SMM Corporativo',
        category: ServiceCategory.socialMedia,
        price: 2000.00,
        description: 'High volume. Facebook + Instagram.',
        includes: ['40 Content Pieces', '3 Reels', 'Community Mgmt'],
      ),
      ServicePackage(
        id: 'smm_tiktok',
        name: 'TikTok Focus',
        category: ServiceCategory.socialMedia,
        price: 900.00,
        description: 'Short-form video focus.',
        includes: ['4 Reels/TikToks', '1 Production Day', 'Editing'],
      ),

      // Branding
      ServicePackage(
        id: 'brand_entrepreneur',
        name: 'Branding Emprendedor',
        category: ServiceCategory.branding,
        price: 1500.00,
        description: 'Essential identity for startups.',
        includes: ['Logo', 'One-pager Manual', 'Basic Stationery'],
      ),
      ServicePackage(
        id: 'brand_corporate',
        name: 'Branding Corporativo',
        category: ServiceCategory.branding,
        price: 8000.00,
        description: 'Complete visual identity system.',
        includes: ['Logo', 'Full Manual (80 pages)', 'Stationery', 'Layouts'],
      ),

      // Production
      ServicePackage(
        id: 'prod_coverage',
        name: 'Event Coverage',
        category: ServiceCategory.production,
        price: 800.00,
        description: 'Documentation of event/activity.',
        includes: ['4 hours shoot', '1 Video (45s)', '20 Photos'],
      ),
      ServicePackage(
        id: 'prod_content_pro',
        name: 'Content Production PRO',
        category: ServiceCategory.production,
        price: 1500.00,
        description: 'High-quality shoot day.',
        includes: ['1 Full Day Shoot', '5 Reels', '25 Photos', '\$100 Props'],
      ),

      // Paid Media (Ads)
      ServicePackage(
        id: 'ads_basic',
        name: 'Pauta Básico (1 Platform)',
        category: ServiceCategory.other,
        price: 400.00,
        description: 'Mgmt fee for 1 platform (e.g., Meta).',
        includes: ['Strategy', 'Execution', 'Reporting', 'Content Creation'],
        excludes: ['Ad Spend (Min \$360)'],
      ),
      ServicePackage(
        id: 'ads_medium',
        name: 'Pauta Medio (2 Platforms)',
        category: ServiceCategory.other,
        price: 750.00,
        description: 'Mgmt fee for 2 platforms.',
        includes: ['Strategy', 'Execution', 'Reporting'],
        excludes: ['Ad Spend'],
      ),
      ServicePackage(
        id: 'ads_premium',
        name: 'Pauta Premium (3 Platforms)',
        category: ServiceCategory.other,
        price: 1600.00,
        description: 'Mgmt for Meta, TikTok, Google.',
        includes: ['Advanced Strategy', 'SEO Ad Copies', 'A/B Testing'],
        excludes: ['Ad Spend (Min \$1200)'],
      ),

      // Corporate
      ServicePackage(
        id: 'corp_linkedin',
        name: 'Gestión LinkedIn',
        category: ServiceCategory.socialMedia,
        price: 1500.00,
        description: 'Personal branding & positioning.',
        includes: ['4 Weekly Articles', 'Strategy', 'Publishing'],
      ),
      ServicePackage(
        id: 'corp_brochure',
        name: 'Corporate Brochure',
        category: ServiceCategory.branding,
        price: 1000.00,
        description: '12-17 page corporate presentation.',
        includes: ['Copywriting', 'Design', 'PDF + PPT Delivery'],
      ),
    ];
  }
}
