
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingHistoryPage extends StatefulWidget {
  final String registerNumber;

  const BookingHistoryPage({
    super.key,
    required this.registerNumber,
  });

  @override
  State<BookingHistoryPage> createState() =>
      _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  static const Color gold = Color(0xFFD4AF37);
  static const Color dark = Color(0xFF101010);
  static const Color cardColor = Color(0xFF1D1D1D);

  List<Map<String, dynamic>> bookings = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadBookings();
  }

  Future<void> loadBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('cinemate_bookings');

    List<Map<String, dynamic>> result = [];

    if (savedData != null) {
      try {
        final decoded = jsonDecode(savedData);

        if (decoded is List) {
          result = decoded
              .whereType<Map>()
              .map((item) => Map<String, dynamic>.from(item))
              .where((booking) =>
                  (booking['registerNumber'] ?? '')
                      .toString()
                      .toLowerCase() ==
                  widget.registerNumber.toLowerCase())
              .toList();
        }
      } catch (_) {
        result = [];
      }
    }

    result.sort((a, b) {
      final dateA = DateTime.tryParse(
            (a['createdAt'] ?? '').toString(),
          ) ??
          DateTime(2000);

      final dateB = DateTime.tryParse(
            (b['createdAt'] ?? '').toString(),
          ) ??
          DateTime(2000);

      return dateB.compareTo(dateA);
    });

    if (!mounted) return;

    setState(() {
      bookings = result;
      loading = false;
    });
  }

  String formatDate(dynamic value) {
    final date = DateTime.tryParse((value ?? '').toString());

    if (date == null) return 'Date unavailable';

    final local = date.toLocal();

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year}';
  }

  String formatTime(dynamic value) {
    final date = DateTime.tryParse((value ?? '').toString());

    if (date == null) return '';

    final local = date.toLocal();

    return '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  String seatText(dynamic seats) {
    if (seats is List) {
      return seats.join(', ');
    }

    return (seats ?? 'Not available').toString();
  }

  void showTicket(Map<String, dynamic> booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Center(
                    child: Icon(
                      Icons.confirmation_number,
                      color: gold,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Center(
                    child: Text(
                      'CINEMATE TICKET',
                      style: TextStyle(
                        color: gold,
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      (booking['movieTitle'] ?? 'Movie').toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(color: gold, height: 30),
                  ticketRow('Student', booking['studentName']),
                  ticketRow(
                    'Register Number',
                    booking['registerNumber'],
                  ),
                  ticketRow('Booking ID', booking['bookingId']),
                  ticketRow('Showtime', booking['showtime']),
                  ticketRow('Seats', seatText(booking['seats'])),
                  ticketRow('Tickets', booking['ticketCount']),
                  ticketRow(
                    'Payment',
                    booking['paymentMethod'],
                  ),
                  ticketRow(
                    'Amount',
                    '₹${booking['total'] ?? 0}',
                  ),
                  ticketRow(
                    'Booking Date',
                    formatDate(booking['createdAt']),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gold,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.all(14),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'CLOSE TICKET',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget ticketRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white60),
            ),
          ),
          Expanded(
            child: Text(
              (value ?? 'Not available').toString(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget bookingCard(Map<String, dynamic> booking) {
    final createdAt = booking['createdAt'];

    return Card(
      color: cardColor,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: gold.withValues(alpha: 0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => showTicket(booking),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    backgroundColor: Color(0xFF352D16),
                    child: Icon(
                      Icons.movie,
                      color: gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      (booking['movieTitle'] ?? 'Movie').toString(),
                      style: const TextStyle(
                        color: gold,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Colors.white54,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              detailRow(
                Icons.calendar_today,
                formatDate(createdAt),
              ),
              detailRow(
                Icons.access_time,
                (booking['showtime'] ?? 'Not available').toString(),
              ),
              detailRow(
                Icons.event_seat,
                'Seats: ${seatText(booking['seats'])}',
              ),
              const Divider(color: Colors.white12, height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${booking['ticketCount'] ?? 0} ticket(s)',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  Text(
                    '₹${booking['total'] ?? 0}',
                    style: const TextStyle(
                      color: gold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Tap to view ticket details',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget detailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 17, color: gold),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        foregroundColor: gold,
        title: const Text(
          'MY BOOKINGS',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh bookings',
            onPressed: () {
              setState(() {
                loading = true;
              });
              loadBookings();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: gold),
            )
          : bookings.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.confirmation_number_outlined,
                          color: gold,
                          size: 75,
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'No bookings yet',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your movie tickets will appear here after you complete a booking.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white60,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: loadBookings,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: gold,
                            side: const BorderSide(color: gold),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  color: gold,
                  backgroundColor: cardColor,
                  onRefresh: loadBookings,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        '${bookings.length} booking(s) found',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...bookings.map(bookingCard),
                    ],
                  ),
                ),
    );
  }
}
