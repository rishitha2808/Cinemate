
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/movie_service.dart';
import 'booking_page.dart';
import 'booking_history_page.dart';

class HomePage extends StatefulWidget {
  final String studentName;
  final String registerNumber;

  const HomePage({
    super.key,
    required this.studentName,
    required this.registerNumber,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const Color gold = Color(0xFFD4AF37);
  static const Color dark = Color(0xFF090909);
  static const Color cardColor = Color(0xFF171717);
  static const Color muted = Color(0xFFAAAAAA);

  List<Map<String, dynamic>> movies = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadMovies();
  }

  Future<void> loadMovies() async {
    if (mounted) {
      setState(() => loading = true);
    }

    try {
      final result = await MovieService.getMovies();

      if (!mounted) return;

      setState(() {
        movies = result
            .map((movie) => Map<String, dynamic>.from(movie))
            .toList();
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to load movies. Please try again.'),
        ),
      );
    }
  }

  List<String> getTimings(Map<String, dynamic> movie) {
    final value = movie['timings'];

    if (value is List) {
      return value
          .map((time) => time.toString().trim())
          .where((time) => time.isNotEmpty)
          .toList();
    }

    if (value is String) {
      return value
          .split(',')
          .map((time) => time.trim())
          .where((time) => time.isNotEmpty)
          .toList();
    }

    return [];
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('studentName');
    await prefs.remove('studentEmail');
    await prefs.remove('registerNumber');
    await prefs.remove('studentMobile');

    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      '/',
      (route) => false,
    );
  }

  void selectShowtime(Map<String, dynamic> movie) {
    final timings = getTimings(movie);

    if (timings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No showtimes are available for this movie.'),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'CHOOSE YOUR SHOW',
                style: TextStyle(
                  color: gold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                (movie['title'] ?? 'Movie').toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Select a showtime to continue booking.',
                style: TextStyle(
                  color: muted,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: timings.map((time) {
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: gold,
                      side: const BorderSide(color: gold),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 13,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookingPage(
                            movie: movie,
                            showtime: time,
                            studentName: widget.studentName,
                            registerNumber: widget.registerNumber,
                          ),
                        ),
                      );
                    },
                    child: Text(
                      time,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget posterImage(String poster, {double height = 210}) {
    if (poster.isEmpty) {
      return Container(
        height: height,
        color: const Color(0xFF242424),
        child: const Center(
          child: Icon(
            Icons.movie_creation_outlined,
            color: gold,
            size: 58,
          ),
        ),
      );
    }

    return Image.network(
      poster,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          height: height,
          color: const Color(0xFF242424),
          child: const Center(
            child: Icon(
              Icons.movie_creation_outlined,
              color: gold,
              size: 58,
            ),
          ),
        );
      },
    );
  }

  Widget movieCard(Map<String, dynamic> movie, int index) {
    final poster = (movie['poster'] ?? '').toString();
    final title = (movie['title'] ?? 'Untitled Movie').toString();
    final price = movie['price'] ?? 0;
    final timings = getTimings(movie);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: gold.withOpacity(0.24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 205,
                width: double.infinity,
                child: posterImage(
                  poster,
                  height: 205,
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.02),
                        Colors.black.withOpacity(0.78),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 15,
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 13,
                left: 13,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: gold.withOpacity(0.7),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.stars_rounded,
                        color: gold,
                        size: 14,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'NOW SHOWING',
                        style: TextStyle(
                          color: gold,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.confirmation_number_outlined,
                      color: gold,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Text(
                      '₹$price',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      ' / ticket',
                      style: TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.access_time_rounded,
                      color: muted,
                      size: 15,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${timings.length} shows',
                      style: const TextStyle(
                        color: muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'SHOWTIMES',
                  style: TextStyle(
                    color: gold,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.8,
                  ),
                ),
                const SizedBox(height: 9),
                if (timings.isEmpty)
                  const Text(
                    'No showtimes added yet',
                    style: TextStyle(
                      color: muted,
                      fontSize: 13,
                    ),
                  )
                else
                  Wrap(
                    spacing: 7,
                    runSpacing: 7,
                    children: timings.take(4).map((time) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: gold.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: gold.withOpacity(0.35),
                          ),
                        ),
                        child: Text(
                          time,
                          style: const TextStyle(
                            color: gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 17),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () => selectShowtime(movie),
                    icon: const Icon(
                      Icons.event_seat_rounded,
                      size: 19,
                    ),
                    label: const Text(
                      'BOOK TICKETS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gold,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        foregroundColor: gold,
        elevation: 0,
        titleSpacing: 20,
        title: const Row(
          children: [
            Icon(
              Icons.local_movies_rounded,
              size: 25,
            ),
            SizedBox(width: 9),
            Text(
              'CINEMATE',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.2,
                fontSize: 19,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'My Bookings',
            icon: const Icon(Icons.confirmation_number_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookingHistoryPage(
                    registerNumber: widget.registerNumber,
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Refresh movies',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: loadMovies,
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded),
            onPressed: logout,
          ),
          const SizedBox(width: 5),
        ],
      ),
      body: RefreshIndicator(
        color: gold,
        backgroundColor: cardColor,
        onRefresh: loadMovies,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 850),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
              children: [
                Container(
                  padding: const EdgeInsets.all(19),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF292316),
                        Color(0xFF17140D),
                        Color(0xFF171717),
                      ],
                    ),
                    border: Border.all(
                      color: gold.withOpacity(0.42),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: gold.withOpacity(0.13),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: gold,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'WELCOME BACK',
                              style: TextStyle(
                                color: gold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 2,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              widget.studentName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.registerNumber,
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 13),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.07),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: gold,
                        size: 23,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TODAY AT YOUR MINIPLEX',
                              style: TextStyle(
                                color: gold,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              today,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 27),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'YOUR NEXT',
                            style: TextStyle(
                              color: muted,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'MOVIE EXPERIENCE',
                            style: TextStyle(
                              color: gold,
                              fontSize: 21,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.7,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.local_activity_outlined,
                      color: gold,
                      size: 25,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose a movie, pick your seats, and enjoy the show.',
                  style: TextStyle(
                    color: muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 17),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(45),
                    child: Center(
                      child: CircularProgressIndicator(color: gold),
                    ),
                  )
                else if (movies.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: gold.withOpacity(0.2),
                      ),
                    ),
                    child: const Column(
                      children: [
                        Icon(
                          Icons.movie_filter_outlined,
                          color: gold,
                          size: 58,
                        ),
                        SizedBox(height: 14),
                        Text(
                          'No movies available',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 7),
                        Text(
                          'Please check again later or refresh the movie list.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: muted,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...movies.asMap().entries.map(
                        (entry) => movieCard(entry.value, entry.key),
                      ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'MADE FOR YOUR MOVIE MOMENTS',
                    style: TextStyle(
                      color: Color(0xFF68604A),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
