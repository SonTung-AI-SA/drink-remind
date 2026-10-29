String petName(String pet) => switch (pet) {
  'dog' => 'Corgi',
  'fish' => 'Nemo',
  _ => 'Mèo Cam',
};
String petSpecies(String pet) => switch (pet) {
  'dog' => 'Chó',
  'fish' => 'Cá',
  _ => 'Mèo',
};
int growthStage(int level) => level >= 6
    ? 2
    : level >= 3
    ? 1
    : 0;
String growthLabel(int level) =>
    ['Bé nhỏ', 'Đang lớn', 'Trưởng thành'][growthStage(level)];
