/// Interpolates the published NHS Gloucestershire drinking-fluid table.
/// This is an approximate drinks target, not total water including food.
int? suggestedWater({
  required int? age,
  required double? weight,
  required double? height,
}) {
  if (age == null ||
      age < 18 ||
      age > 100 ||
      weight == null ||
      !weight.isFinite ||
      weight < 38 ||
      weight > 102 ||
      height == null ||
      !height.isFinite ||
      height < 100 ||
      height > 230) {
    return null;
  }
  const kg = [
    38.0,
    45.0,
    51.0,
    57.0,
    64.0,
    70.0,
    76.0,
    83.0,
    89.0,
    95.0,
    102.0,
  ];
  const ml = [
    1190.0,
    1275.0,
    1446.0,
    1786.0,
    1981.0,
    2179.0,
    2377.0,
    2575.0,
    2773.0,
    2971.0,
    3136.0,
  ];
  for (var i = 1; i < kg.length; i++) {
    if (weight <= kg[i]) {
      final value =
          ml[i - 1] +
          (ml[i] - ml[i - 1]) * (weight - kg[i - 1]) / (kg[i] - kg[i - 1]);
      return (value / 50).round() * 50;
    }
  }
  return null;
}
