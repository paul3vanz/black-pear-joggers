import '../data/standards_dtos.dart';

/// Display name of a gender key: `Men` / `Women`.
String genderLabel(String gender) => gender == 'female' ? 'Women' : 'Men';

/// The sentence form used in "Showing V50 women".
String genderNoun(String gender) => gender == 'female' ? 'women' : 'men';

/// The gender + category the screen opens on: the caller's own (`mine`) when
/// the table has it, else Men SEN (or the first category the table has).
MyCategory defaultSelection(StandardsData data) {
  final mine = data.mine;
  if (mine != null && data.categoriesFor(mine.gender).contains(mine.category)) {
    return mine;
  }
  return _firstOrSen(data, 'male');
}

MyCategory _firstOrSen(StandardsData data, String gender) {
  final list = data.categoriesFor(gender);
  if (list.isNotEmpty) {
    return MyCategory(
      gender: gender,
      category: list.contains('SEN') ? 'SEN' : list.first,
    );
  }
  // This gender has no rows at all: use the other one if it has any.
  final other = gender == 'male' ? 'female' : 'male';
  final otherList = data.categoriesFor(other);
  if (otherList.isNotEmpty) {
    return MyCategory(
      gender: other,
      category: otherList.contains('SEN') ? 'SEN' : otherList.first,
    );
  }
  return MyCategory(gender: gender, category: 'SEN');
}

/// What to show after the gender control is set to [gender]: the caller's own
/// category when it is of that gender, else the category already open if that
/// gender has it too, else SEN.
MyCategory selectionAfterGender(
  StandardsData data,
  MyCategory current,
  String gender,
) {
  final mine = data.mine;
  if (mine != null &&
      mine.gender == gender &&
      data.categoriesFor(gender).contains(mine.category)) {
    return mine;
  }
  if (data.categoriesFor(gender).contains(current.category)) {
    return MyCategory(gender: gender, category: current.category);
  }
  return _firstOrSen(data, gender);
}
