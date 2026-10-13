
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() =>
      _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  static const gold = Color(0xFFE8C66A);
  static const dark = Color(0xFF101010);
  static const cardColor = Color(0xFF202020);
  static const bookingKey = 'cinemate_bookings';

  List<Map<String, dynamic>> bookings = [];
  DateTime selectedDate = DateTime.now();
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadReports();
  }

  Future<void> loadReports() async {
    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(bookingKey);

      List<Map<String, dynamic>> saved = [];

      if (data != null && data.isNotEmpty) {
        final decoded = jsonDecode(data);

        if (decoded is List) {
          saved = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList();
        }
      }

      if (!mounted) return;

      setState(() {
        bookings = saved;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load reports: $e'),
        ),
      );
    }
  }

  DateTime? bookingDate(Map<String, dynamic> booking) {
    final value = booking['createdAt']?.toString();

    if (value == null || value.isEmpty) return null;

    return DateTime.tryParse(value)?.toLocal();
  }

  bool isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  List<Map<String, dynamic>> get dailyBookings {
    return bookings.where((booking) {
      final date = bookingDate(booking);

      return date != null && isSameDay(date, selectedDate);
    }).toList();
  }

  int get dailyTickets {
    return dailyBookings.fold<int>(
      0,
      (total, booking) =>
          total +
          ((booking['ticketCount'] as num?)?.toInt() ?? 0),
    );
  }

  double get dailyCollection {
    return dailyBookings.fold<double>(
      0,
      (total, booking) =>
          total +
          ((booking['total'] as num?)?.toDouble() ?? 0),
    );
  }

  int get allTimeTickets {
    return bookings.fold<int>(
      0,
      (total, booking) =>
          total +
          ((booking['ticketCount'] as num?)?.toInt() ?? 0),
    );
  }

  double get allTimeCollection {
    return bookings.fold<double>(
      0,
      (total, booking) =>
          total +
          ((booking['total'] as num?)?.toDouble() ?? 0),
    );
  }

  Future<void> chooseDate() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: gold,
              onPrimary: Colors.black,
              surface: cardColor,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (chosen != null && mounted) {
      setState(() {
        selectedDate = chosen;
      });
    }
  }

  String formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  String formatTime(DateTime? date) {
    if (date == null) return 'Time unavailable';

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        foregroundColor: gold,
        title: const Text(
          'BOOKING REPORTS',
          style: TextStyle(
            color: gold,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            onPressed: loadReports,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: gold),
            )
          : RefreshIndicator(
              color: gold,
              onRefresh: loadReports,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text(
                    'Daily Report',
                    style: TextStyle(
                      color: gold,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 14),

                  InkWell(
                    onTap: chooseDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: gold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_month,
                            color: gold,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Selected date: ${formatDate(selectedDate)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.edit_calendar,
                            color: gold,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columns =
                          constraints.maxWidth < 480 ? 1 : 2;

                      return GridView.count(
                        crossAxisCount: columns,
                        shrinkWrap: true,
                        physics:
                            const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio:
                            columns == 1 ? 3.0 : 1.45,
                        children: [
                          reportCard(
                            'Bookings',
                            dailyBookings.length.toString(),
                            Icons.confirmation_number,
                          ),
                          reportCard(
                            'Tickets Sold',
                            dailyTickets.toString(),
                            Icons.local_activity,
                          ),
                          reportCard(
                            'Daily Collection',
                            '₹${dailyCollection.toStringAsFixed(2)}',
                            Icons.currency_rupee,
                          ),
                          reportCard(
                            'All-Time Bookings',
                            bookings.length.toString(),
                            Icons.analytics,
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    'Overall Summary',
                    style: TextStyle(
                      color: gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        summaryRow(
                          'Total Active Bookings',
                          bookings.length.toString(),
                        ),
                        summaryRow(
                          'Total Tickets',
                          allTimeTickets.toString(),
                        ),
                        summaryRow(
                          'Total Booking Amount',
                          '₹${allTimeCollection.toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  Text(
                    'Bookings on ${formatDate(selectedDate)}',
                    style: const TextStyle(
                      color: gold,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (dailyBookings.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.inbox_outlined,
                            color: gold,
                            size: 42,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No bookings found for this date.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ...dailyBookings.map((booking) {
                      final date = bookingDate(booking);
                      final seats = booking['seats'];

                      final seatText = seats is List
                          ? seats.join(', ')
                          : (seats ?? 'N/A').toString();

                      return Card(
                        color: cardColor,
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking['studentName']?.toString() ??
                                    'Unknown Student',
                                style: const TextStyle(
                                  color: gold,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              summaryRow(
                                'Movie',
                                booking['movieTitle']?.toString() ??
                                    'N/A',
                              ),
                              summaryRow(
                                'Register Number',
                                booking['registerNumber']?.toString() ??
                                    'N/A',
                              ),
                              summaryRow(
                                'Showtime',
                                booking['showtime']?.toString() ??
                                    'N/A',
                              ),
                              summaryRow('Seats', seatText),
                              summaryRow(
                                'Tickets',
                                booking['ticketCount']?.toString() ??
                                    '0',
                              ),
                              summaryRow(
                                'Amount',
                                '₹${booking['total'] ?? 0}',
                              ),
                              summaryRow(
                                'Booked At',
                                formatTime(date),
                              ),
                              summaryRow(
                                'Booking ID',
                                booking['bookingId']?.toString() ??
                                    'N/A',
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget reportCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: gold.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: gold, size: 30),
          const SizedBox(width: 12),
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
                const SizedBox(height: 7),
                Text(
                  value,
                  style: const TextStyle(
                    color: gold,
                    fontSize: 21,
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

  Widget summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
