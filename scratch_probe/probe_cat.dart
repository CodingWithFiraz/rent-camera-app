// Scratch probe: bentuk constructor mana yang memicu pesan
// "A value of type 'Null' can't be assigned to a parameter of type 'String'
// in a const constructor." pada pemanggilan const.
class CatImpl {
  const CatImpl({required this.id, required this.name, this.description});

  final String id;
  final String name;
  final String description;
}

const List<CatImpl> withConstOmitted =
    <CatImpl>[CatImpl(id: 'kamera', name: 'Kamera')];

final List<CatImpl> withoutConstOmitted =
    <CatImpl>[CatImpl(id: 'kamera', name: 'Kamera')];

const List<CatImpl> withConstExplicit =
    <CatImpl>[CatImpl(id: 'kamera', name: 'Kamera', description: '')];
