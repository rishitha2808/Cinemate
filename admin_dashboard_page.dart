
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/movie_service.dart';
import 'admin_reports_page.dart';
import 'login_page.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() =>
      _AdminDashboardPageState();
}

class _AdminDashboardPageState
    extends State<AdminDashboardPage> {
  static const gold = Color(0xFFE8C66A);
  static const dark = Color(0xFF101010);
  static const cardColor = Color(0xFF202020);
  static const bookingKey = 'cinemate_bookings';

  List<Map<String, dynamic>> movies = [];
  List<Map<String, dynamic>> bookings = [];
  bool loading = true;
  String searchText = '';

  final titleController =
      TextEditingController(text: 'Paradise');
  final posterController = TextEditingController();
  final timingsController = TextEditingController(
    text: '10:00 AM, 1:00 PM, 6:00 PM',
  );
  final priceController = TextEditingController(text: '150');
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadDashboard();
  }

  Future<void> loadDashboard() async {
    if (mounted) setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final movieData = await MovieService.getMovies();
      final data = prefs.getString(bookingKey);

      List<Map<String, dynamic>> savedBookings = [];

      if (data != null && data.isNotEmpty) {
        final decoded = jsonDecode(data);

        if (decoded is List) {
          savedBookings = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      if (!mounted) return;

      setState(() {
        movies = movieData;
        bookings = savedBookings;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);
      showMessage('Could not load dashboard: $e');
    }
  }

  Future<void> addMovie() async {
    final title = titleController.text.trim();
    final poster = posterController.text.trim();
    final timings = timingsController.text
        .split(',')
        .map((time) => time.trim())
        .where((time) => time.isNotEmpty)
        .toList();
    final price = double.tryParse(priceController.text.trim());

    if (title.isEmpty || timings.isEmpty ||
        price == null || price <= 0) {
      showMessage(
        'Enter a movie name, valid timings and ticket price.',
      );
      return;
    }

    final movie = <String, dynamic>{
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'title': title,
      'poster': poster,
      'timings': timings,
      'price': price,
    };

    try {
      final updated = List<Map<String, dynamic>>.from(movies)
        ..add(movie);

      await MovieService.saveMovies(updated);

      if (!mounted) return;

      setState(() => movies = updated);
      titleController.clear();
      posterController.clear();
      timingsController.text = '10:00 AM, 1:00 PM, 6:00 PM';
      priceController.text = '150';

      showMessage('Movie added successfully.');
    } catch (e) {
      showMessage('Could not add movie: $e');
    }
  }

  Future<void> deleteMovie(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Delete Movie?',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Delete ${movies[index]['title']}?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final updated = List<Map<String, dynamic>>.from(movies)
        ..removeAt(index);

      await MovieService.saveMovies(updated);

      if (!mounted) return;

      setState(() => movies = updated);
      showMessage('Movie deleted.');
    } catch (e) {
      showMessage('Could not delete movie: $e');
    }
  }

  Future<void> cancelBooking(
    Map<String, dynamic> booking,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: const Text(
          'Cancel Booking?',
          style: TextStyle(color: gold),
        ),
        content: Text(
          'Cancel booking for ${booking['studentName']}?\n\n'
          'Movie: ${booking['movieTitle']}\n'
          'Show: ${booking['showtime']}\n'
          'Seats: ${booking['seats']}',
          style: const TextStyle(
            color: Colors.white70,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Booking'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel Booking'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final bookingId = booking['bookingId']?.toString() ?? '';
      final movieId = booking['movieId']?.toString() ?? '';
      final showtime = booking['showtime']?.toString() ?? '';

      if (movieId.isEmpty || showtime.isEmpty) {
        showMessage(
          'This booking has no movie ID. '
          'Cannot safely release seats.',
        );
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final key = 'booked_${movieId}_$showtime';
      final bookedSeats = prefs.getStringList(key) ?? [];

      final dynamic value = booking['seats'];
      final seats = value is List
          ? value.map((seat) => seat.toString()).toList()
          : <String>[];

      bookedSeats.removeWhere((seat) => seats.contains(seat));
      await prefs.setStringList(key, bookedSeats);

      final updated = List<Map<String, dynamic>>.from(bookings);
      final index = updated.indexWhere(
        (item) =>
            item['bookingId']?.toString() == bookingId,
      );

      if (index == -1) {
        showMessage('Booking not found. Please refresh.');
        await loadDashboard();
        return;
      }

      updated.removeAt(index);

      await prefs.setString(bookingKey, jsonEncode(updated));

      if (!mounted) return;

      setState(() => bookings = updated);
      showMessage('Booking cancelled and seats released.');
    } catch (e) {
      showMessage('Could not cancel booking: $e');
      await loadDashboard();
    }
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  List<Map<String, dynamic>> get filteredBookings {
    if (searchText.trim().isEmpty) return bookings;

    final query = searchText.toLowerCase().trim();

    return bookings.where((booking) {
      return [
        booking['studentName'],
        booking['registerNumber'],
        booking['bookingId'],
        booking['movieTitle'],
      ].any(
        (value) => (value ?? '')
            .toString()
            .toLowerCase()
            .contains(query),
      );
    }).toList();
  }

  int get totalTickets => bookings.fold<int>(
        0,
        (total, booking) =>
            total +
            ((booking['ticketCount'] as num?)?.toInt() ?? 0),
      );

  double get totalAmount => bookings.fold<double>(
        0,
        (total, booking) =>
            total +
            ((booking['total'] as num?)?.toDouble() ?? 0),
      );

  String formatBookingDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Not available';
    }

    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return 'Not available';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/${date.year}, $hour:$minute $period';
  }

  @override
  void dispose() {
    titleController.dispose();
    posterController.dispose();
    timingsController.dispose();
    priceController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        foregroundColor: gold,
        title: const Text(
          'CINEMATE ADMIN',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Booking reports',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminReportsPage(),
                ),
              );

              if (mounted) loadDashboard();
            },
            icon: const Icon(Icons.analytics_outlined),
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: loadDashboard,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Logout',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: gold),
            )
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: RefreshIndicator(
                  color: gold,
                  onRefresh: loadDashboard,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'Dashboard Overview',
                        style: TextStyle(
                          color: gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      LayoutBuilder(
                        builder: (context, constraints) {
                          final columns =
                              constraints.maxWidth < 500 ? 1 : 3;

                          return GridView.count(
                            crossAxisCount: columns,
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio:
                                columns == 1 ? 3 : 1.25,
                            children: [
                              summaryCard(
                                'Confirmed Bookings',
                                bookings.length.toString(),
                                Icons.confirmation_number,
                              ),
                              summaryCard(
                                'Tickets Booked',
                                totalTickets.toString(),
                                Icons.event_seat,
                              ),
                              summaryCard(
                                'Booking Amount',
                                '₹${totalAmount.toStringAsFixed(0)}',
                                Icons.currency_rupee,
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 28),

                      const Text(
                        'Movie Management',
                        style: TextStyle(
                          color: gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            movieField(
                              'Movie Name',
                              titleController,
                              Icons.movie,
                            ),
                            const SizedBox(height: 12),
                            movieField(
                              'Poster Image URL',
                              posterController,
                              Icons.image,
                            ),
                            const SizedBox(height: 12),
                            movieField(
                              'Show Timings (comma separated)',
                              timingsController,
                              Icons.schedule,
                            ),
                            const SizedBox(height: 12),
                            movieField(
                              'Ticket Price',
                              priceController,
                              Icons.currency_rupee,
                              keyboardType: TextInputType.number,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: addMovie,
                                icon: const Icon(Icons.add),
                                label: const Text('ADD MOVIE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gold,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      if (movies.isEmpty)
                        emptyMessage('No movies added yet.')
                      else
                        ...List.generate(movies.length, (index) {
                          final movie = movies[index];
                          final timingValue = movie['timings'];
                          final timingText = timingValue is List
                              ? timingValue.join(', ')
                              : (timingValue ?? '').toString();

                          return Card(
                            color: cardColor,
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: gold,
                                child: Icon(
                                  Icons.movie,
                                  color: Colors.black,
                                ),
                              ),
                              title: Text(
                                movie['title']?.toString() ?? 'Movie',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                '$timingText\n'
                                'Ticket Price: ₹${movie['price'] ?? 0}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),
                              isThreeLine: true,
                              trailing: IconButton(
                                onPressed: () => deleteMovie(index),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 28),

                      const Text(
                        'Student Bookings',
                        style: TextStyle(
                          color: gold,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        'Total booking records: ${bookings.length}',
                        style: const TextStyle(
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 14),

                      TextField(
                        controller: searchController,
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() => searchText = value);
                        },
                        decoration: InputDecoration(
                          hintText:
                              'Search student, register number, movie...',
                          hintStyle: const TextStyle(
                            color: Colors.white54,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: gold,
                          ),
                          suffixIcon: searchText.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    searchController.clear();
                                    setState(() => searchText = '');
                                  },
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.white70,
                                  ),
                                )
                              : null,
                          filled: true,
                          fillColor: cardColor,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      if (filteredBookings.isEmpty)
                        emptyMessage(
                          bookings.isEmpty
                              ? 'No bookings found yet.'
                              : 'No bookings match your search.',
                        )
                      else
                        ...filteredBookings.map(bookingCard),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget summaryCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: gold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget bookingCard(Map<String, dynamic> booking) {
    final seats = booking['seats'];
    final seatText = seats is List
        ? seats.join(', ')
        : (seats ?? 'N/A').toString();

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        iconColor: gold,
        collapsedIconColor: gold,
        leading: const CircleAvatar(
          backgroundColor: gold,
          child: Icon(Icons.person, color: Colors.black),
        ),
        title: Text(
          booking['studentName']?.toString() ?? 'Unknown Student',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${booking['movieTitle'] ?? 'Movie'} • '
          'ID: ${booking['bookingId'] ?? 'N/A'}',
          style: const TextStyle(color: Colors.white70),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          bookingRow(
            'Booking ID',
            booking['bookingId']?.toString() ?? 'N/A',
          ),
          bookingRow(
            'Student Name',
            booking['studentName']?.toString() ?? 'N/A',
          ),
          bookingRow(
            'Register Number',
            booking['registerNumber']?.toString() ?? 'N/A',
          ),
          bookingRow(
            'Movie',
            booking['movieTitle']?.toString() ?? 'N/A',
          ),
          bookingRow(
            'Show Timing',
            booking['showtime']?.toString() ?? 'N/A',
          ),
          bookingRow(
            'Tickets',
            booking['ticketCount']?.toString() ?? '0',
          ),
          bookingRow('Seats', seatText),
          bookingRow(
            'Payment Method',
            booking['paymentMethod']?.toString() ?? 'N/A',
          ),
          bookingRow(
            'Total Amount',
            '₹${booking['total'] ?? 0}',
          ),
          bookingRow(
            'Booking Date',
            formatBookingDate(booking['createdAt']?.toString()),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => cancelBooking(booking),
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('CANCEL BOOKING'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bookingRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget movieField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: gold),
        filled: true,
        fillColor: dark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: gold),
        ),
      ),
    );
  }

  Widget emptyMessage(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.inbox_outlined,
            color: gold,
            size: 38,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}