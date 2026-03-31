enum CalendarType {
  life,
  year,
  goal;

  String get label {
    switch (this) {
      case CalendarType.life:
        return 'Life Calendar';
      case CalendarType.year:
        return 'Year Calendar';
      case CalendarType.goal:
        return 'Goal Calendar';
    }
  }

  String get key {
    switch (this) {
      case CalendarType.life:
        return 'life';
      case CalendarType.year:
        return 'year';
      case CalendarType.goal:
        return 'goal';
    }
  }

  static CalendarType fromKey(String key) {
    switch (key) {
      case 'life':
        return CalendarType.life;
      case 'year':
        return CalendarType.year;
      case 'goal':
        return CalendarType.goal;
      default:
        return CalendarType.life;
    }
  }
}
