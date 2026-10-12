import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'club_config.g.dart';

/// Everything that makes the app "Black Pear Joggers" rather than another club.
/// White-label builds later supply their own instance (see architecture.md).
class ClubConfig {
  const ClubConfig({
    required this.name,
    required this.shortName,
    required this.website,
    required this.joinUrl,
    required this.contactUrl,
    required this.privacyPolicyUrl,
    required this.logoAsset,
    required this.primary,
    required this.seed,
  });

  final String name;
  final String shortName;
  final Uri website;
  final Uri joinUrl;
  final Uri contactUrl;
  final Uri privacyPolicyUrl;
  final String logoAsset;

  /// Brand orange (Tailwind `primary.DEFAULT` on the website).
  final Color primary;

  /// Seed colour for the Material 3 colour scheme.
  final Color seed;

  static final bpj = ClubConfig(
    name: 'Black Pear Joggers',
    shortName: 'BPJ',
    website: Uri.parse('https://bpj.org.uk'),
    joinUrl: Uri.parse('https://bpj.org.uk/membership'),
    contactUrl: Uri.parse('https://bpj.org.uk/contact?reason=website'),
    privacyPolicyUrl: Uri.parse('https://bpj.org.uk/privacy-policy'),
    logoAsset: 'assets/images/logo.png',
    primary: const Color(0xFFF89829),
    seed: const Color(0xFFF89829),
  );
}

/// The club this build is for. Override in tests; later, white-label flavors return
/// their own [ClubConfig].
@Riverpod(keepAlive: true)
ClubConfig clubConfig(Ref ref) => ClubConfig.bpj;
