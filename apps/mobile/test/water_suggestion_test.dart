import 'package:flutter_test/flutter_test.dart';
import 'package:little_island/features/profile/water_suggestion.dart';

void main() {
  test('published table values and interpolation round to 50 ml', () {
    expect(suggestedWater(age: 26, weight: 70, height: 165), 2200);
    expect(suggestedWater(age: 26, weight: 60, height: 165), 1850);
    expect(suggestedWater(age: 26, weight: 38, height: 165), 1200);
    expect(suggestedWater(age: 26, weight: 102, height: 165), 3150);
  });
  test('does not extrapolate or accept invalid profile values', () {
    for (final weight in [null, double.nan, double.infinity, 37.9, 102.1]) {
      expect(suggestedWater(age: 26, weight: weight, height: 165), isNull);
    }
    for (final age in [null, 17, 101]) {
      expect(suggestedWater(age: age, weight: 60, height: 165), isNull);
    }
    expect(suggestedWater(age: 26, weight: 60, height: double.nan), isNull);
    expect(suggestedWater(age: 26, weight: 60, height: null), isNull);
  });
}
