import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:couple_app/features/auth/presentation/login_screen.dart';
import 'package:couple_app/features/auth/presentation/splash_screen.dart';
import 'package:couple_app/features/auth/presentation/welcome_screen.dart';
import 'package:couple_app/features/auth/presentation/onboarding_screen.dart';
import 'package:couple_app/features/auth/providers/auth_provider.dart';
import 'package:couple_app/features/auth/providers/profile_provider.dart';
import 'package:couple_app/features/home/home_screen.dart';
import 'package:couple_app/features/tasks/presentation/calendar_screen.dart';
import 'package:couple_app/features/notes/presentation/notes_screen.dart';
import 'package:couple_app/features/partner/presentation/partner_screen.dart';
import 'package:couple_app/features/partner/presentation/wish_detail_screen.dart';
import 'package:couple_app/features/tasks/presentation/new_task_screen.dart';
import 'package:couple_app/features/tasks/presentation/task_detail_screen.dart';
import 'package:couple_app/features/auth/presentation/profile_setup_screen.dart';
import 'package:couple_app/features/tasks/presentation/search_screen.dart';
import 'package:couple_app/features/tasks/presentation/category_tasks_screen.dart';
import 'package:couple_app/features/tasks/data/task_model.dart';
import 'package:couple_app/features/home/pet_farm_screen.dart';
import 'package:couple_app/features/stats/presentation/stats_screen.dart';
import 'package:couple_app/features/friends/presentation/friends_screen.dart';
import 'package:couple_app/shared/widgets/app_scaffold.dart';
import 'package:couple_app/features/family/presentation/family_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final profile = ref.watch(profileProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,

    redirect: (context, state) {
      if (authState.isLoading) return null;

      final bool isLoggedIn = authState.value != null;
      final bool isNameEmpty = profile.name.trim().isEmpty;

      final isSplash = state.matchedLocation == '/splash';
      final isLogin = state.matchedLocation == '/login';
      final isWelcome = state.matchedLocation == '/welcome';
      final isProfileSetup = state.matchedLocation == '/profile';
      final isOnboarding = state.matchedLocation == '/onboarding';

      if (!isLoggedIn) {
        if (isSplash || isLogin || isWelcome || isOnboarding) return null;
        return '/welcome';
      }

      if (isLoggedIn && isNameEmpty) {
        if (isProfileSetup) return null;
        return '/profile';
      }

      if (isLoggedIn && !isNameEmpty) {
        if (isSplash || isLogin || isWelcome || isOnboarding) return '/';
      }

      return null;
    },

    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          onFinished: () async {
            final prefs = await SharedPreferences.getInstance();
            final seen = prefs.getBool('onboarding_seen') ?? false;
            if (!seen) {
              await prefs.setBool('onboarding_seen', true);
              if (context.mounted) context.go('/onboarding');
            } else {
              if (context.mounted) context.go('/welcome');
            }
          },
        ),
      ),

      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),

      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) => AppScaffold(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/calendar',
            builder: (context, state) => const CalendarScreen(),
          ),
          GoRoute(
            path: '/notes',
            builder: (context, state) => const NotesScreen(),
          ),
          GoRoute(
            path: '/partner',
            builder: (context, state) => const PartnerScreen(),
          ),
          GoRoute(
            path: '/family',
            builder: (context, state) => const FamilyScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileSetupScreen(),
          ),
        ],
      ),

      // ← FIX: категория передаётся через extra если пользовательская
      GoRoute(
        path: '/category/:id',
        name: 'categoryTasks',
        builder: (context, state) {
          // Сначала пробуем extra — для пользовательских категорий
          if (state.extra is TaskCategory) {
            return CategoryTasksScreen(category: state.extra as TaskCategory);
          }
          // Фолбэк для стандартных категорий
          final id = state.pathParameters['id']!;
          const defaults = [
            TaskCategory(id: 'cleaning', name: 'Уборка', emoji: '🧹'),
            TaskCategory(id: 'cooking', name: 'Готовка', emoji: '🍳'),
            TaskCategory(id: 'events', name: 'Мероприятия', emoji: '🎭'),
            TaskCategory(id: 'pets', name: 'Питомцы', emoji: '🐱'),
            TaskCategory(id: 'health', name: 'Здоровье', emoji: '🫀'),
          ];
          final category = defaults.firstWhere(
            (c) => c.id == id,
            orElse: () => defaults.first,
          );
          return CategoryTasksScreen(category: category);
        },
      ),

      GoRoute(
        path: '/tasks/new',
        builder: (context, state) {
          final extra = state.extra;
          Task? editTask;
          TaskCategory? initialCategory;
          DateTime? initialDate;
          if (extra is Task) {
            editTask = extra;
          } else if (extra is TaskCategory) {
            initialCategory = extra;
          } else if (extra is DateTime) {
            initialDate = extra;
          }
          return NewTaskScreen(
            editTask: editTask,
            initialCategory: initialCategory,
            initialDate: initialDate,
          );
        },
      ),

      GoRoute(
        path: '/tasks/:id',
        builder: (context, state) =>
            TaskDetailScreen(taskId: state.pathParameters['id']!),
      ),

      GoRoute(
        path: '/partner/:collectionId',
        builder: (context, state) {
          final id = state.pathParameters['collectionId']!;
          final collection = _getCollection(id);
          return WishlistScreen(collection: collection);
        },
      ),

      GoRoute(
        path: '/notes/create',
        builder: (context, state) {
          final extra = state.extra;
          NoteType type = NoteType.note;
          if (extra is NoteType) type = extra;
          return NoteDetailScreen(initialType: type);
        },
      ),

      GoRoute(
        path: '/notes/:id',
        builder: (context, state) {
          final extra = state.extra;
          if (extra is NoteItem) {
            return NoteDetailScreen(note: extra, initialType: extra.type);
          }
          // Fallback - пустой экран создания
          return NoteDetailScreen(initialType: NoteType.note);
        },
      ),

      GoRoute(
        path: '/pet-farm',
        builder: (context, state) => const PetFarmScreen(),
      ),

      GoRoute(
        path: '/search',
        builder: (context, state) => const SearchScreen(),
      ),

      GoRoute(path: '/stats', builder: (context, state) => const StatsScreen()),

      GoRoute(
        path: '/friends',
        builder: (context, state) => const FriendsScreen(),
      ),
    ],
  );
});

Collection _getCollection(String id) {
  const collections = [
    Collection(
      id: 'gifts',
      name: 'Сундук желаний',
      description: 'Идеи для подарков: от мелочей до заветных желаний.',
    ),
    Collection(
      id: 'travel',
      name: 'Атлас мечтаний',
      description: 'Карта будущих путешествий, городов и маршрутов.',
    ),
    Collection(
      id: 'kino',
      name: 'Плед и попкорн',
      description: 'Кино, сериалы и мультфильмы для наших вечеров.',
    ),
    Collection(
      id: 'entertainment',
      name: 'Тихая гавань',
      description: 'Идеи для совместного отдыха и уютных вечеров.',
    ),
    Collection(
      id: 'cafe',
      name: 'Вкусные истории',
      description: 'Любимые кафе, рестораны и новые места.',
    ),
  ];
  return collections.firstWhere(
    (c) => c.id == id,
    orElse: () => collections.first,
  );
}
