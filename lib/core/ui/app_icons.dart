import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Цвета категорий — используются везде в приложении
class CategoryColors {
  static const cleaning = Color(0xFF4FC3F7);
  static const cooking = Color(0xFFFFB74D);
  static const events = Color(0xFFBA68C8);
  static const pets = Color(0xFFFFCA28);
  static const health = Color(0xFFEF5350);
  static const study = Color(0xFF66BB6A);
  static const other = Color(0xFF90A4AE);
  static const note = Color(0xFF64B5F6);
  static const ideas = Color(0xFFFFF176);
  static const purchases = Color(0xFF80CBC4);
  static const important = Color(0xFFFF7043);
  static const cafe = Color(0xFFA1887F);
  static const travel = Color(0xFF4DB6AC);
  static const kino = Color(0xFF7986CB);
  static const entertainment = Color(0xFFF06292);
  static const gifts = Color(0xFFFFB300);
  static const analytics = Color(0xFF6C5CE7);
  static const friends = Color(0xFF34D399);
  static const farm = Color(0xFFB39DDB);
  static const family = Color(0xFFFFB74D);

  static Color forId(String id) {
    switch (id) {
      case 'cleaning':
        return cleaning;
      case 'cooking':
        return cooking;
      case 'events':
        return events;
      case 'pets':
        return pets;
      case 'health':
        return health;
      case 'study':
        return study;
      case 'note':
        return note;
      case 'ideas':
        return ideas;
      case 'purchases':
        return purchases;
      case 'important':
        return important;
      case 'cafe':
        return cafe;
      case 'travel':
        return travel;
      case 'kino':
        return kino;
      case 'entertainment':
        return entertainment;
      case 'gifts':
        return gifts;
      default:
        return other;
    }
  }
}

class AppIcons {
  static Widget home({double size = 30, Color color = Colors.white}) =>
      _svg('home.svg', size, color);
  static Widget calendar({double size = 30, Color color = Colors.white}) =>
      _svg('calendar.svg', size, color);
  static Widget notes({double size = 30, Color color = Colors.white}) =>
      _svg('notes.svg', size, color);
  static Widget lists({double size = 30, Color color = Colors.white}) =>
      _svg('lists.svg', size, color);
  static Widget arrow({double size = 30, Color color = Colors.white}) =>
      _svg('arrow.svg', size, color);
  static Widget notificationsPassive({
    double size = 24,
    Color color = Colors.white,
  }) => _svg('notifications_passive.svg', size, color);
  static Widget notificationsActive({
    double size = 24,
    Color color = Colors.white,
  }) => _svg('notifications _active.svg', size, color);

  static Widget cleaning({double size = 26, Color? color}) => _svg(
    'cleaning.svg',
    size,
    color ?? const Color.fromARGB(255, 131, 211, 248),
  );
  static Widget cooking({double size = 26, Color? color}) =>
      _svg('cooking.svg', size, color ?? CategoryColors.cooking);
  static Widget events({double size = 26, Color? color}) => _svg(
    'events.svg',
    size,
    color ?? const Color.fromARGB(255, 207, 132, 167),
  );
  static Widget pets({double size = 26, Color? color}) =>
      _svg('pets.svg', size, color ?? const Color.fromARGB(255, 238, 217, 155));
  static Widget health({double size = 26, Color? color}) => _svg(
    'health.svg',
    size,
    color ?? const Color.fromARGB(255, 243, 107, 104),
  );
  static Widget study({double size = 26, Color? color}) => _svg(
    'other.svg',
    size,
    color ?? const Color.fromARGB(255, 151, 232, 235),
  );
  static Widget other({double size = 26, Color? color}) =>
      _svg('other.svg', size, color ?? CategoryColors.other);

  static Widget note({double size = 24, Color? color}) =>
      _svg('note.svg', size, color ?? const Color.fromARGB(255, 182, 216, 245));
  static Widget ideas({double size = 24, Color? color}) => _svg(
    'ideas.svg',
    size,
    color ?? const Color.fromARGB(255, 255, 250, 201),
  );
  static Widget purchases({double size = 24, Color? color}) => _svg(
    'purchases.svg',
    size,
    color ?? const Color.fromARGB(255, 209, 255, 250),
  );
  static Widget important({double size = 24, Color? color}) => _svg(
    'Important.svg',
    size,
    color ?? const Color.fromARGB(255, 255, 215, 202),
  );

  static Widget cafe({double size = 24, Color? color}) =>
      _svg('cafe.svg', size, color ?? CategoryColors.cafe);
  static Widget travel({double size = 24, Color? color}) =>
      _svg('travel.svg', size, color ?? CategoryColors.travel);
  static Widget kino({double size = 24, Color? color}) =>
      _svg('kino.svg', size, color ?? const Color.fromARGB(255, 184, 193, 236));
  static Widget entertainment({double size = 24, Color? color}) => _svg(
    'entertainment.svg',
    size,
    color ?? const Color.fromARGB(255, 211, 161, 178),
  );
  static Widget gifts({double size = 24, Color? color}) => _svg(
    'gifts.svg',
    size,
    color ?? const Color.fromARGB(255, 236, 224, 196),
  );

  static Widget analytics({double size = 24, Color? color}) => _svg(
    'analytics.svg',
    size,
    color ?? const Color.fromARGB(255, 183, 176, 238),
  );
  static Widget friends({double size = 24, Color? color}) => _svg(
    'friends.svg',
    size,
    color ?? const Color.fromARGB(255, 196, 245, 227),
  );
  static Widget farm({double size = 24, Color? color}) =>
      _svg('farm.svg', size, color ?? const Color.fromARGB(255, 221, 210, 241));
  static Widget family({double size = 24, Color? color}) => _svg(
    'family.svg',
    size,
    color ?? const Color.fromARGB(255, 255, 234, 201),
  );

  static Widget close({double size = 24, Color color = Colors.white}) =>
      _svg('close.svg', size, color);
  static Widget copy({double size = 24, Color color = Colors.white}) =>
      _svg('copy.svg', size, color);
  static Widget fix({
    double size = 24,
    Color color = const Color.fromARGB(255, 255, 255, 255),
  }) => _svg('fix.svg', size, color);
  static Widget hidden({double size = 24, Color color = Colors.white}) =>
      _svg('hidden.svg', size, color);
  static Widget open({double size = 24, Color color = Colors.white}) =>
      _svg('open.svg', size, color);
  static Widget repeat({double size = 24, Color color = Colors.white}) =>
      _svg('repeat.svg', size, color);
  static Widget time({double size = 24, Color color = Colors.white}) =>
      _svg('time.svg', size, color);
  static Widget unpin({double size = 24, Color color = Colors.white}) =>
      _svg('unpin.svg', size, color);
  static Widget allDay({double size = 24, Color color = Colors.white}) =>
      _svg('all_day.svg', size, color);
  static Widget forAll({double size = 24, Color color = Colors.white}) =>
      _svg('for_all.svg', size, color);

  static Widget category(String id, {double size = 24, Color? color}) {
    switch (id) {
      case 'cleaning':
        return cleaning(size: size, color: color);
      case 'cooking':
        return cooking(size: size, color: color);
      case 'events':
        return events(size: size, color: color);
      case 'pets':
        return pets(size: size, color: color);
      case 'health':
        return health(size: size, color: color);
      case 'study':
        return study(size: size, color: color);
      case 'note':
        return note(size: size, color: color);
      case 'ideas':
        return ideas(size: size, color: color);
      case 'purchases':
        return purchases(size: size, color: color);
      case 'important':
        return important(size: size, color: color);
      case 'cafe':
        return cafe(size: size, color: color);
      case 'travel':
        return travel(size: size, color: color);
      case 'kino':
        return kino(size: size, color: color);
      case 'entertainment':
        return entertainment(size: size, color: color);
      case 'gifts':
        return gifts(size: size, color: color);
      default:
        return other(size: size, color: color);
    }
  }

  static Widget custom(
    String name, {
    double size = 24,
    Color color = Colors.white,
  }) => _svg('$name.svg', size, color);

  static Widget _svg(String name, double size, Color color) {
    return SvgPicture.asset(
      'assets/icons/$name',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
