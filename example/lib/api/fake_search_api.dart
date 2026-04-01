import 'dart:math';

import 'package:search_plus/search_plus.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.username,
    required this.avatarUrl,
    this.bio = '',
    this.followers = 0,
    this.isVerified = false,
  });

  final String id;
  final String name;
  final String username;
  final String avatarUrl;
  final String bio;
  final int followers;
  final bool isVerified;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.imageUrl = '',
    this.rating = 0.0,
  });

  final String id;
  final String name;
  final String category;
  final double price;
  final String imageUrl;
  final double rating;
}

class Article {
  const Article({
    required this.id,
    required this.title,
    required this.excerpt,
    required this.author,
    this.imageUrl = '',
    this.readTime = 5,
  });

  final String id;
  final String title;
  final String excerpt;
  final String author;
  final String imageUrl;
  final int readTime;
}

// ---------------------------------------------------------------------------
// Sample datasets
// ---------------------------------------------------------------------------

const List<AppUser> sampleUsers = [
  AppUser(
    id: 'u1',
    name: 'Sarah Chen',
    username: '@sarahchen',
    avatarUrl: 'https://i.pravatar.cc/150?u=sarah',
    bio: 'Senior Flutter Developer · Open-source enthusiast',
    followers: 12400,
    isVerified: true,
  ),
  AppUser(
    id: 'u2',
    name: 'James Wilson',
    username: '@jwilson',
    avatarUrl: 'https://i.pravatar.cc/150?u=james',
    bio: 'Mobile architect at TechCorp',
    followers: 8700,
    isVerified: true,
  ),
  AppUser(
    id: 'u3',
    name: 'Maria Garcia',
    username: '@mariadev',
    avatarUrl: 'https://i.pravatar.cc/150?u=maria',
    bio: 'UI/UX designer & developer',
    followers: 5200,
  ),
  AppUser(
    id: 'u4',
    name: 'Alex Kumar',
    username: '@alexk',
    avatarUrl: 'https://i.pravatar.cc/150?u=alex',
    bio: 'Full-stack developer · Building cool stuff',
    followers: 3100,
  ),
  AppUser(
    id: 'u5',
    name: 'Emily Thompson',
    username: '@emilyt',
    avatarUrl: 'https://i.pravatar.cc/150?u=emily',
    bio: 'Product designer at DesignStudio',
    followers: 6800,
    isVerified: true,
  ),
  AppUser(
    id: 'u6',
    name: 'Omar Hassan',
    username: '@omarh',
    avatarUrl: 'https://i.pravatar.cc/150?u=omar',
    bio: 'Backend engineer · Dart lover',
    followers: 2900,
  ),
  AppUser(
    id: 'u7',
    name: 'Sakura Tanaka',
    username: '@sakura_t',
    avatarUrl: 'https://i.pravatar.cc/150?u=sakura',
    bio: 'Cross-platform mobile dev',
    followers: 4500,
    isVerified: true,
  ),
  AppUser(
    id: 'u8',
    name: 'Daniel Brown',
    username: '@danbrown',
    avatarUrl: 'https://i.pravatar.cc/150?u=daniel',
    bio: 'Tech lead · Flutter GDE',
    followers: 15600,
    isVerified: true,
  ),
  AppUser(
    id: 'u9',
    name: 'Lina Svensson',
    username: '@linasv',
    avatarUrl: 'https://i.pravatar.cc/150?u=lina',
    bio: 'Developer advocate',
    followers: 9300,
  ),
  AppUser(
    id: 'u10',
    name: 'Marco Rossi',
    username: '@marcodev',
    avatarUrl: 'https://i.pravatar.cc/150?u=marco',
    bio: 'iOS & Flutter specialist',
    followers: 7100,
  ),
];

const List<Product> sampleProducts = [
  Product(
    id: 'p1',
    name: 'Wireless Noise-Canceling Headphones',
    category: 'Audio',
    price: 299.99,
    rating: 4.8,
  ),
  Product(
    id: 'p2',
    name: 'Ultra-Slim Laptop Stand',
    category: 'Accessories',
    price: 49.99,
    rating: 4.5,
  ),
  Product(
    id: 'p3',
    name: 'Mechanical Keyboard RGB',
    category: 'Peripherals',
    price: 159.99,
    rating: 4.7,
  ),
  Product(
    id: 'p4',
    name: 'USB-C Hub 7-in-1',
    category: 'Accessories',
    price: 39.99,
    rating: 4.3,
  ),
  Product(
    id: 'p5',
    name: 'Ergonomic Mouse Pro',
    category: 'Peripherals',
    price: 79.99,
    rating: 4.6,
  ),
  Product(
    id: 'p6',
    name: '4K Webcam Ultra',
    category: 'Video',
    price: 129.99,
    rating: 4.4,
  ),
  Product(
    id: 'p7',
    name: 'Portable SSD 2TB',
    category: 'Storage',
    price: 189.99,
    rating: 4.9,
  ),
  Product(
    id: 'p8',
    name: 'Smart Desk Lamp',
    category: 'Lighting',
    price: 59.99,
    rating: 4.2,
  ),
  Product(
    id: 'p9',
    name: 'Wireless Charging Pad',
    category: 'Accessories',
    price: 29.99,
    rating: 4.1,
  ),
  Product(
    id: 'p10',
    name: 'Studio Monitor Speakers',
    category: 'Audio',
    price: 449.99,
    rating: 4.8,
  ),
  Product(
    id: 'p11',
    name: 'Curved Ultrawide Monitor',
    category: 'Displays',
    price: 699.99,
    rating: 4.7,
  ),
  Product(
    id: 'p12',
    name: 'Bluetooth Trackpad',
    category: 'Peripherals',
    price: 89.99,
    rating: 4.4,
  ),
];

const List<Article> sampleArticles = [
  Article(
    id: 'a1',
    title: 'Building Scalable Flutter Apps with Clean Architecture',
    excerpt:
        'Learn how to structure large Flutter projects using clean architecture principles and dependency injection.',
    author: 'Sarah Chen',
    readTime: 8,
  ),
  Article(
    id: 'a2',
    title: 'Advanced State Management Patterns in Dart',
    excerpt:
        'A deep dive into reactive patterns, streams, and the ChangeNotifier approach for complex UIs.',
    author: 'James Wilson',
    readTime: 12,
  ),
  Article(
    id: 'a3',
    title: 'Mastering Custom Animations in Flutter',
    excerpt:
        'From implicit animations to custom painters — everything you need for buttery-smooth UX.',
    author: 'Maria Garcia',
    readTime: 10,
  ),
  Article(
    id: 'a4',
    title: 'Responsive Design Strategies for Multi-Platform Flutter',
    excerpt:
        'How to build layouts that look great on phones, tablets, desktops, and the web.',
    author: 'Alex Kumar',
    readTime: 7,
  ),
  Article(
    id: 'a5',
    title: 'Testing Flutter Apps: A Comprehensive Guide',
    excerpt:
        'Unit tests, widget tests, integration tests, and golden tests explained.',
    author: 'Emily Thompson',
    readTime: 15,
  ),
  Article(
    id: 'a6',
    title: 'Dart 3 Features Every Developer Should Know',
    excerpt:
        'Records, patterns, sealed classes, and the latest Dart 3 features for better code.',
    author: 'Omar Hassan',
    readTime: 6,
  ),
  Article(
    id: 'a7',
    title: 'Performance Optimization Tips for Flutter',
    excerpt:
        'Reduce jank, optimize builds, and profile your app like a pro.',
    author: 'Sakura Tanaka',
    readTime: 9,
  ),
  Article(
    id: 'a8',
    title: 'Building a Design System with Flutter',
    excerpt:
        'Create reusable tokens, components, and themes for consistent UIs across your organization.',
    author: 'Daniel Brown',
    readTime: 11,
  ),
];

// ---------------------------------------------------------------------------
// Trending & Suggestions
// ---------------------------------------------------------------------------

const List<String> trendingSearches = [
  'Flutter 4.0',
  'AI widgets',
  'Material 3',
  'Dart macros',
  'Adaptive layouts',
  'Riverpod 3',
  'Firebase ML',
  'Shorebird',
];

const List<String> recentSearchesSample = [
  'headphones',
  'keyboard',
  'Sarah Chen',
  'clean architecture',
];

// ---------------------------------------------------------------------------
// FakeSearchApi — simulates network delay & errors
// ---------------------------------------------------------------------------

class FakeSearchApi {
  FakeSearchApi({
    this.minDelay = const Duration(milliseconds: 300),
    this.maxDelay = const Duration(milliseconds: 1200),
    this.errorRate = 0.0,
  });

  final Duration minDelay;
  final Duration maxDelay;
  final double errorRate;

  final _random = Random();

  Future<void> _simulateDelay() async {
    final minMs = minDelay.inMilliseconds;
    final maxMs = maxDelay.inMilliseconds;
    final range = (maxMs > minMs) ? maxMs - minMs : 0;
    final delay = minMs + (range > 0 ? _random.nextInt(range) : 0);
    await Future<void>.delayed(Duration(milliseconds: delay));
  }

  void _maybeThrow() {
    if (errorRate > 0 && _random.nextDouble() < errorRate) {
      throw Exception('Simulated network error — please retry.');
    }
  }

  // -- Users ----------------------------------------------------------------

  Future<List<SearchResult<AppUser>>> searchUsers(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    await _simulateDelay();
    _maybeThrow();

    final q = query.toLowerCase();
    return sampleUsers
        .where(
          (u) =>
              u.name.toLowerCase().contains(q) ||
              u.username.toLowerCase().contains(q) ||
              u.bio.toLowerCase().contains(q),
        )
        .skip(offset)
        .take(limit)
        .map(
          (u) => SearchResult<AppUser>(
            id: u.id,
            title: u.name,
            subtitle: '${u.username} · ${_formatFollowers(u.followers)} followers',
            imageUrl: u.avatarUrl,
            data: u,
            source: SearchResultSource.remote,
            metadata: {
              'verified': u.isVerified,
              'followers': u.followers,
            },
          ),
        )
        .toList();
  }

  // -- Products --------------------------------------------------------------

  Future<List<SearchResult<Product>>> searchProducts(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    await _simulateDelay();
    _maybeThrow();

    final q = query.toLowerCase();
    return sampleProducts
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.category.toLowerCase().contains(q),
        )
        .skip(offset)
        .take(limit)
        .map(
          (p) => SearchResult<Product>(
            id: p.id,
            title: p.name,
            subtitle: '${p.category} · \$${p.price.toStringAsFixed(2)}',
            data: p,
            source: SearchResultSource.remote,
            metadata: {
              'rating': p.rating,
              'category': p.category,
            },
          ),
        )
        .toList();
  }

  // -- Articles --------------------------------------------------------------

  Future<List<SearchResult<Article>>> searchArticles(
    String query, {
    int limit = 20,
    int offset = 0,
  }) async {
    await _simulateDelay();
    _maybeThrow();

    final q = query.toLowerCase();
    return sampleArticles
        .where(
          (a) =>
              a.title.toLowerCase().contains(q) ||
              a.excerpt.toLowerCase().contains(q) ||
              a.author.toLowerCase().contains(q),
        )
        .skip(offset)
        .take(limit)
        .map(
          (a) => SearchResult<Article>(
            id: a.id,
            title: a.title,
            subtitle: 'By ${a.author} · ${a.readTime} min read',
            data: a,
            source: SearchResultSource.remote,
            metadata: {
              'author': a.author,
              'readTime': a.readTime,
            },
          ),
        )
        .toList();
  }

  // -- Suggestions -----------------------------------------------------------

  Future<List<String>> suggestUsers(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final q = query.toLowerCase();
    return sampleUsers
        .where((u) => u.name.toLowerCase().startsWith(q))
        .take(5)
        .map((u) => u.name)
        .toList();
  }

  Future<List<String>> suggestProducts(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final q = query.toLowerCase();
    return sampleProducts
        .where((p) => p.name.toLowerCase().contains(q))
        .take(5)
        .map((p) => p.name)
        .toList();
  }

  static String _formatFollowers(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }
}
