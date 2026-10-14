// Scratch probe: default value memakai konstanta yang tidak resolve.
class CatIcon {
  const CatIcon({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.iconKey = CategoryIconKeys.defaultKey,
  });

  final String id;
  final String name;
  final String slug;
  final String description;
  final String iconKey;
}

const List<CatIcon> listIcon = <CatIcon>[
  CatIcon(id: 'kamera', name: 'Kamera', slug: 'kamera'),
];
