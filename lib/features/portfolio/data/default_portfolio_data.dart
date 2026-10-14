import '../../catalog/domain/price_unit.dart';
import '../domain/creative.dart';
import '../domain/service_rate.dart';

/// Data default rate card dan kreator yang digunakan ketika Firestore
/// belum memiliki dokumen (atau dalam mode luring/tanpa seed admin).
///
/// Nilai diselaraskan dengan `scripts/seed_config.json` dan spesifikasi
/// `docs/BLUEPRINT_APLIKASI.md` §6.6–6.7: empat kelompok layanan dan dua kreator.
abstract final class DefaultPortfolioData {
  static const List<ServiceRate> serviceRates = <ServiceRate>[
    ServiceRate(
      id: 'commercial_social_media_video',
      title: 'Commercial / Social Media Video',
      description:
          'Produksi video komersial dan konten media sosial berkualitas tinggi '
          'untuk branding dan promosi produk.',
      rateLabel: 'Mulai dari',
      startingPrice: 1500000,
      priceUnit: PriceUnit.perSession,
      deliverables: <String>[
        'Konsep & storyboard kreatif',
        'Shooting video Full HD / 4K',
        'Editing, color grading & audio mixing',
        'Format media sosial (Reels/TikTok/YouTube)',
      ],
      sortOrder: 1,
      isActive: true,
    ),
    ServiceRate(
      id: 'video_editing_post_production',
      title: 'Video Editing / Post-production',
      description:
          'Penyuntingan dan pasca-produksi video profesional untuk berbagai '
          'kebutuhan materi visual.',
      rateLabel: 'Mulai dari',
      startingPrice: 500000,
      priceUnit: PriceUnit.perSession,
      deliverables: <String>[
        'Cutting & sequencing footage',
        'Motion graphics & title animation',
        'Color grading & audio sweetening',
        'Export master kualitas tinggi (FHD/4K)',
      ],
      sortOrder: 2,
      isActive: true,
    ),
    ServiceRate(
      id: 'event_project_documentation',
      title: 'Event & Project Documentation',
      description:
          'Dokumentasi menyeluruh untuk event, peluncuran proyek, seminar, '
          'konser, atau gathering.',
      rateLabel: 'Mulai dari',
      startingPrice: 2000000,
      priceUnit: PriceUnit.perSession,
      deliverables: <String>[
        'Liputan foto & video sepanjang acara',
        'Highlight video sinematik (1–3 menit)',
        'Foto dokumentasi terkurasi & diedit',
        'Penyimpanan cloud untuk seluruh file',
      ],
      sortOrder: 3,
      isActive: true,
    ),
    ServiceRate(
      id: 'commercial_portrait_photography',
      title: 'Commercial & Portrait Photography',
      description:
          'Fotografi komersial, foto produk, katalog busana, dan foto profil '
          'profesional / personal portrait.',
      rateLabel: 'Mulai dari',
      startingPrice: 750000,
      priceUnit: PriceUnit.perSession,
      deliverables: <String>[
        'Sesi foto studio atau outdoor',
        'Pencahayaan & lighting setup profesional',
        '15–30 foto resolusi tinggi hasil retouching',
        'File master siap cetak & media digital',
      ],
      sortOrder: 4,
      isActive: true,
    ),
  ];

  static const List<Creative> creatives = <Creative>[
    Creative(
      id: 'ipan_ramadhan',
      name: 'Ipan Ramadhan',
      roleTitle: 'Videographer & Video Editor',
      specialties: <String>[
        'Commercial Video',
        'Video Editing',
        'Color Grading',
        'Motion Graphics',
      ],
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=400&q=80',
      portfolioUrl: 'https://instagram.com/ipanramadhan',
      sortOrder: 1,
      isActive: true,
    ),
    Creative(
      id: 'firas_fadly_a',
      name: 'Firas Fadly A.',
      roleTitle: 'Photographer & Visual Content',
      specialties: <String>[
        'Commercial Photography',
        'Portrait',
        'Event Documentation',
        'Color Retouching',
      ],
      photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=400&q=80',
      portfolioUrl: 'https://instagram.com/firasfadly',
      sortOrder: 2,
      isActive: true,
    ),
  ];
}
