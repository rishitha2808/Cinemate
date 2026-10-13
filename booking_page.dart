

import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';



class BookingPage extends StatefulWidget {

  final Map<String, dynamic> movie;

  final String showtime;

  final String studentName;

  final String registerNumber;



  const BookingPage({

    super.key,

    required this.movie,

    required this.showtime,

    required this.studentName,

    required this.registerNumber,

  });



  @override

  State<BookingPage> createState() => _BookingPageState();

}



class _BookingPageState extends State<BookingPage> {

  static const gold = Color(0xFFE8C66A);

  static const dark = Color(0xFF101010);

  static const cardColor = Color(0xFF202020);



  List<String> selectedSeats = [];

  List<String> bookedSeats = [];

  bool loading = true;



  String get movieId => widget.movie['id'].toString();



  String get seatStorageKey =>

      'booked_${movieId}_${widget.showtime}';



  double get ticketPrice {

    final value = widget.movie['price'];

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 150;

  }



  @override

  void initState() {

    super.initState();

    loadSeats();

  }



  Future<void> loadSeats() async {

    final prefs = await SharedPreferences.getInstance();

    final savedSeats = prefs.getStringList(seatStorageKey) ?? [];



    if (!mounted) return;



    setState(() {

      bookedSeats = savedSeats;

      loading = false;

    });

  }



  void toggleSeat(String seat) {

    if (bookedSeats.contains(seat)) return;



    setState(() {

      if (selectedSeats.contains(seat)) {

        selectedSeats.remove(seat);

      } else {

        selectedSeats.add(seat);

      }

    });

  }



  void continueBooking() {

    if (selectedSeats.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(

          content: Text('Please select at least one seat.'),

        ),

      );

      return;

    }



    Navigator.push(

      context,

      MaterialPageRoute(

        builder: (_) => BookingReviewPage(

          movie: widget.movie,

          showtime: widget.showtime,

          studentName: widget.studentName,

          registerNumber: widget.registerNumber,

          seats: List<String>.from(selectedSeats),

        ),

      ),

    );

  }



  @override

  Widget build(BuildContext context) {

    final rows = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H'];



    return Scaffold(

      backgroundColor: dark,

      appBar: AppBar(

        backgroundColor: dark,

        foregroundColor: gold,

        title: const Text('SELECT YOUR SEATS'),

      ),

      body: loading

          ? const Center(

              child: CircularProgressIndicator(color: gold),

            )

          : SafeArea(

              child: ListView(

                padding: const EdgeInsets.all(16),

                children: [

                  Text(

                    widget.movie['title']?.toString() ??

                        'Movie',

                    textAlign: TextAlign.center,

                    style: const TextStyle(

                      color: gold,

                      fontSize: 23,

                      fontWeight: FontWeight.bold,

                    ),

                  ),

                  const SizedBox(height: 6),

                  Text(

                    'Show: ${widget.showtime}',

                    textAlign: TextAlign.center,

                    style: const TextStyle(

                      color: Colors.white70,

                    ),

                  ),

                  const SizedBox(height: 25),



                  Container(

                    padding: const EdgeInsets.all(12),

                    decoration: BoxDecoration(

                      color: cardColor,

                      borderRadius: BorderRadius.circular(12),

                    ),

                    child: Column(

                      children: [

                        const Text(

                          'SCREEN',

                          style: TextStyle(

                            color: gold,

                            letterSpacing: 5,

                            fontWeight: FontWeight.bold,

                          ),

                        ),

                        const SizedBox(height: 8),

                        Container(

                          height: 4,

                          width: double.infinity,

                          decoration: BoxDecoration(

                            color: gold,

                            borderRadius: BorderRadius.circular(10),

                          ),

                        ),

                      ],

                    ),

                  ),



                  const SizedBox(height: 24),



                  Row(

                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,

                    children: [

                      legend(Colors.white, 'Available'),

                      legend(gold, 'Selected'),

                      legend(Colors.green, 'Booked'),

                    ],

                  ),



                  const SizedBox(height: 24),



                  for (final row in rows)

                    Padding(

                      padding: const EdgeInsets.only(bottom: 10),

                      child: Row(

                        mainAxisAlignment: MainAxisAlignment.center,

                        children: [

                          SizedBox(

                            width: 22,

                            child: Text(

                              row,

                              style: const TextStyle(

                                color: gold,

                                fontWeight: FontWeight.bold,

                              ),

                            ),

                          ),

                          const SizedBox(width: 4),

                          for (int number = 1;

                              number <= 8;

                              number++)

                            seatButton('$row$number'),

                        ],

                      ),

                    ),



                  const SizedBox(height: 24),



                  Container(

                    padding: const EdgeInsets.all(16),

                    decoration: BoxDecoration(

                      color: cardColor,

                      borderRadius: BorderRadius.circular(12),

                    ),

                    child: Column(

                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [

                        Text(

                          'Selected Seats: ${selectedSeats.isEmpty ? 'None' : selectedSeats.join(', ')}',

                          style: const TextStyle(

                            color: Colors.white,

                          ),

                        ),

                        const SizedBox(height: 10),

                        Text(

                          'Tickets: ${selectedSeats.length}',

                          style: const TextStyle(

                            color: Colors.white70,

                          ),

                        ),

                        const SizedBox(height: 8),

                        Text(

                          'Total: ₹${(ticketPrice * selectedSeats.length).toStringAsFixed(0)}',

                          style: const TextStyle(

                            color: gold,

                            fontSize: 20,

                            fontWeight: FontWeight.bold,

                          ),

                        ),

                      ],

                    ),

                  ),



                  const SizedBox(height: 20),



                  ElevatedButton(

                    onPressed: continueBooking,

                    style: ElevatedButton.styleFrom(

                      backgroundColor: gold,

                      foregroundColor: Colors.black,

                      padding: const EdgeInsets.symmetric(

                        vertical: 15,

                      ),

                    ),

                    child: const Text(

                      'CONTINUE',

                      style: TextStyle(

                        fontWeight: FontWeight.bold,

                      ),

                    ),

                  ),

                ],

              ),

            ),

    );

  }



  Widget seatButton(String seat) {

    final isBooked = bookedSeats.contains(seat);

    final isSelected = selectedSeats.contains(seat);



    final Color seatColor = isBooked

        ? Colors.green

        : isSelected

            ? gold

            : Colors.white;



    return Padding(

      padding: const EdgeInsets.all(3),

      child: InkWell(

        onTap: isBooked ? null : () => toggleSeat(seat),

        borderRadius: BorderRadius.circular(5),

        child: Container(

          width: 29,

          height: 29,

          alignment: Alignment.center,

          decoration: BoxDecoration(

            color: seatColor,

            borderRadius: BorderRadius.circular(5),

          ),

          child: Text(

            seat.substring(1),

            style: const TextStyle(

              color: Colors.black,

              fontSize: 11,

              fontWeight: FontWeight.bold,

            ),

          ),

        ),

      ),

    );

  }



  Widget legend(Color color, String label) {

    return Row(

      children: [

        Container(

          width: 14,

          height: 14,

          decoration: BoxDecoration(

            color: color,

            borderRadius: BorderRadius.circular(3),

          ),

        ),

        const SizedBox(width: 5),

        Text(

          label,

          style: const TextStyle(

            color: Colors.white70,

            fontSize: 12,

          ),

        ),

      ],

    );

  }

}



class BookingReviewPage extends StatelessWidget {

  final Map<String, dynamic> movie;

  final String showtime;

  final String studentName;

  final String registerNumber;

  final List<String> seats;



  const BookingReviewPage({

    super.key,

    required this.movie,

    required this.showtime,

    required this.studentName,

    required this.registerNumber,

    required this.seats,

  });



  static const gold = Color(0xFFE8C66A);

  static const dark = Color(0xFF101010);

  static const cardColor = Color(0xFF202020);



  double get ticketPrice {

    final value = movie['price'];

    if (value is num) return value.toDouble();

    return double.tryParse(value.toString()) ?? 150;

  }



  @override

  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: dark,

      appBar: AppBar(

        backgroundColor: dark,

        foregroundColor: gold,

        title: const Text('REVIEW BOOKING'),

      ),

      body: Padding(

        padding: const EdgeInsets.all(20),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(

              'Confirm Your Details',

              style: TextStyle(

                color: gold,

                fontSize: 23,

                fontWeight: FontWeight.bold,

              ),

            ),

            const SizedBox(height: 20),

            Expanded(

              child: Container(

                width: double.infinity,

                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(

                  color: cardColor,

                  borderRadius: BorderRadius.circular(16),

                ),

                child: ListView(

                  children: [

                    reviewRow('Student', studentName),

                    reviewRow('Register Number', registerNumber),

                    reviewRow(

                      'Movie',

                      movie['title']?.toString() ?? '',

                    ),

                    reviewRow('Showtime', showtime),

                    reviewRow('Seats', seats.join(', ')),

                    reviewRow('Number of Tickets', '${seats.length}'),

                    reviewRow(

                      'Price per Ticket',

                      '₹${ticketPrice.toStringAsFixed(0)}',

                    ),

                    const Divider(color: Colors.white24),

                    reviewRow(

                      'Total Amount',

                      '₹${(ticketPrice * seats.length).toStringAsFixed(0)}',

                      highlight: true,

                    ),

                  ],

                ),

              ),

            ),

            const SizedBox(height: 16),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                onPressed: () {

                  Navigator.push(

                    context,

                    MaterialPageRoute(

                      builder: (_) => PaymentPage(

                        movie: movie,

                        showtime: showtime,

                        studentName: studentName,

                        registerNumber: registerNumber,

                        seats: seats,

                      ),

                    ),

                  );

                },

                style: ElevatedButton.styleFrom(

                  backgroundColor: gold,

                  foregroundColor: Colors.black,

                  padding: const EdgeInsets.symmetric(vertical: 15),

                ),

                child: const Text(

                  'PROCEED TO PAYMENT',

                  style: TextStyle(fontWeight: FontWeight.bold),

                ),

              ),

            ),

          ],

        ),

      ),

    );

  }



  Widget reviewRow(

    String label,

    String value, {

    bool highlight = false,

  }) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 10),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Expanded(

            child: Text(

              label,

              style: const TextStyle(color: Colors.white70),

            ),

          ),

          const SizedBox(width: 10),

          Expanded(

            child: Text(

              value,

              textAlign: TextAlign.end,

              style: TextStyle(

                color: highlight ? gold : Colors.white,

                fontWeight: FontWeight.bold,

              ),

            ),

          ),

        ],

      ),

    );

  }

}



class PaymentPage extends StatefulWidget {
  final Map<String, dynamic> movie;
  final String showtime;
  final String studentName;
  final String registerNumber;
  final List<String> seats;

  const PaymentPage({
    super.key,
    required this.movie,
    required this.showtime,
    required this.studentName,
    required this.registerNumber,
    required this.seats,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  static const gold = Color(0xFFE8C66A);
  static const dark = Color(0xFF101010);
  static const cardColor = Color(0xFF202020);
  static const bookingKey = 'cinemate_bookings';

  String paymentMethod = 'UPI';
  bool processing = false;

  String get movieId => widget.movie['id'].toString();

  String get seatStorageKey => 'booked_${movieId}_${widget.showtime}';

  double get ticketPrice {
    final value = widget.movie['price'];
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 150;
  }

  double get total => ticketPrice * widget.seats.length;

  Future<List<Map<String, dynamic>>> _readBookings(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(bookingKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Saved booking data is not a list.');
    }

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  bool _bookingAlreadyContainsSeats(
    List<Map<String, dynamic>> bookings,
  ) {
    for (final booking in bookings) {
      if (booking['movieId']?.toString() != movieId ||
          booking['showtime']?.toString() != widget.showtime) {
        continue;
      }

      final rawSeats = booking['seats'];
      if (rawSeats is List &&
          rawSeats.any((seat) => widget.seats.contains(seat.toString()))) {
        return true;
      }
    }
    return false;
  }

  Future<void> confirmPayment() async {
    // Prevent rapid taps from starting more than one booking operation.
    if (processing) return;

    if (widget.seats.isEmpty ||
        widget.seats.toSet().length != widget.seats.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please check your selected seats.')),
      );
      return;
    }

    setState(() => processing = true);

    SharedPreferences? prefs;
    List<String> originalSeatList = [];
    bool seatsWereSaved = false;

    try {
      // This delay represents a demo payment only. No money is transferred.
      await Future.delayed(const Duration(seconds: 1));
      prefs = await SharedPreferences.getInstance();

      // Re-read both stored seats and booking records immediately before saving.
      originalSeatList = prefs.getStringList(seatStorageKey) ?? [];
      final bookings = await _readBookings(prefs);

      final seatListConflict =
          widget.seats.any((seat) => originalSeatList.contains(seat));
      final bookingConflict = _bookingAlreadyContainsSeats(bookings);

      if (seatListConflict || bookingConflict) {
        if (!mounted) return;
        setState(() => processing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'One or more seats are already booked. '
              'Please go back and choose different seats.',
            ),
          ),
        );
        return;
      }

      final now = DateTime.now();
      final bookingId = 'CM${now.microsecondsSinceEpoch}';
      final booking = <String, dynamic>{
        'bookingId': bookingId,
        'movieId': movieId,
        'studentName': widget.studentName,
        'registerNumber': widget.registerNumber,
        'movieTitle': widget.movie['title']?.toString() ?? '',
        'showtime': widget.showtime,
        'ticketCount': widget.seats.length,
        'seats': List<String>.from(widget.seats),
        'paymentMethod': paymentMethod,
        'total': total,
        'status': 'confirmed_demo',
        'createdAt': now.toIso8601String(),
      };

      // Reserve the seats first. If this write fails, do not create a ticket.
      final updatedSeatList = <String>{
        ...originalSeatList,
        ...widget.seats,
      }.toList();

      final seatSaveSucceeded =
          await prefs.setStringList(seatStorageKey, updatedSeatList);
      if (!seatSaveSucceeded) {
        throw Exception('Could not save seat availability.');
      }
      seatsWereSaved = true;

      // Save the booking record after the seat list has been written.
      bookings.add(booking);
      final bookingSaveSucceeded = await prefs.setString(
        bookingKey,
        jsonEncode(bookings),
      );

      if (!bookingSaveSucceeded) {
        // Roll back the seat list if saving the booking record fails.
        final rollbackSucceeded =
            await prefs.setStringList(seatStorageKey, originalSeatList);
        seatsWereSaved = !rollbackSucceeded;
        throw Exception(
          rollbackSucceeded
              ? 'Could not save the booking record.'
              : 'Booking save failed and seat rollback also failed. '
                  'Please ask the demo administrator to check this booking.',
        );
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => TicketPage(booking: booking),
        ),
      );
    } catch (e) {
      // Best-effort rollback if a later operation failed after reserving seats.
      if (prefs != null && seatsWereSaved) {
        try {
          await prefs.setStringList(seatStorageKey, originalSeatList);
        } catch (_) {
          // Keep the original error visible; local storage cannot guarantee
          // transactional rollback if the browser storage itself fails.
        }
      }

      if (!mounted) return;
      setState(() => processing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not confirm booking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: dark,
      appBar: AppBar(
        backgroundColor: dark,
        foregroundColor: gold,
        title: const Text('PAYMENT'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Choose Payment Method',
            style: TextStyle(
              color: gold,
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Total Amount: ₹${total.toStringAsFixed(0)}',
            style: const TextStyle(color: Colors.white, fontSize: 20),
          ),
          const SizedBox(height: 20),
          for (final method in [
            'UPI',
            'Debit/Credit Card',
            'Net Banking',
          ])
            Card(
              color: cardColor,
              child: RadioListTile<String>(
                value: method,
                groupValue: paymentMethod,
                activeColor: gold,
                title: Text(
                  method,
                  style: const TextStyle(color: Colors.white),
                ),
                onChanged: processing
                    ? null
                    : (value) {
                        if (value != null) {
                          setState(() => paymentMethod = value);
                        }
                      },
              ),
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Demo payment only. No real money will be charged.',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: processing ? null : confirmPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: processing
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text(
                    'CONFIRM DEMO PAYMENT',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }
}

class TicketPage extends StatelessWidget {

  final Map<String, dynamic> booking;



  const TicketPage({

    super.key,

    required this.booking,

  });



  static const gold = Color(0xFFE8C66A);

  static const dark = Color(0xFF101010);

  static const cardColor = Color(0xFF202020);



  Future<void> shareTicket(BuildContext context) async {

    final message = '''

CINEMATE - BOOKING CONFIRMATION



Booking ID: ${booking['bookingId']}

Student: ${booking['studentName']}

Register Number: ${booking['registerNumber']}

Movie: ${booking['movieTitle']}

Showtime: ${booking['showtime']}

Seats: ${(booking['seats'] as List).join(', ')}

Tickets: ${booking['ticketCount']}

Payment Method: ${booking['paymentMethod']}

Total: ₹${booking['total']}



Enjoy your movie!

''';



    final uri = Uri.https(

      'wa.me',

      '/',

      {'text': message},

    );



    try {

      final launched = await launchUrl(

        uri,

        mode: LaunchMode.externalApplication,

      );



      if (!launched && context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text('Could not open WhatsApp.'),

          ),

        );

      }

    } catch (e) {

      if (context.mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(

            content: Text('Could not open WhatsApp.'),

          ),

        );

      }

    }

  }



  @override

  Widget build(BuildContext context) {

    final seats = booking['seats'] is List

        ? (booking['seats'] as List).join(', ')

        : booking['seats'].toString();



    return Scaffold(

      backgroundColor: dark,

      appBar: AppBar(

        backgroundColor: dark,

        foregroundColor: gold,

        automaticallyImplyLeading: false,

        title: const Text('YOUR TICKET'),

      ),

      body: ListView(

        padding: const EdgeInsets.all(20),

        children: [

          const Icon(

            Icons.check_circle,

            color: Colors.green,

            size: 75,

          ),

          const SizedBox(height: 12),

          const Text(

            'Booking Confirmed!',

            textAlign: TextAlign.center,

            style: TextStyle(

              color: gold,

              fontSize: 25,

              fontWeight: FontWeight.bold,

            ),

          ),

          const SizedBox(height: 24),



          Container(

            padding: const EdgeInsets.all(20),

            decoration: BoxDecoration(

              color: cardColor,

              borderRadius: BorderRadius.circular(18),

              border: Border.all(color: gold),

            ),

            child: Column(

              children: [

                const Text(

                  'CINEMATE',

                  style: TextStyle(

                    color: gold,

                    fontSize: 24,

                    fontWeight: FontWeight.bold,

                    letterSpacing: 3,

                  ),

                ),

                const Divider(

                  color: gold,

                  height: 30,

                ),

                ticketRow(

                  'Booking ID',

                  booking['bookingId'].toString(),

                ),

                ticketRow(

                  'Student Name',

                  booking['studentName'].toString(),

                ),

                ticketRow(

                  'Register Number',

                  booking['registerNumber'].toString(),

                ),

                ticketRow(

                  'Movie',

                  booking['movieTitle'].toString(),

                ),

                ticketRow(

                  'Showtime',

                  booking['showtime'].toString(),

                ),

                ticketRow('Seats', seats),

                ticketRow(

                  'Tickets',

                  booking['ticketCount'].toString(),

                ),

                ticketRow(

                  'Payment',

                  booking['paymentMethod'].toString(),

                ),

                ticketRow(

                  'Total',

                  '₹${booking['total']}',

                ),

                const Divider(

                  color: gold,

                  height: 30,

                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: jsonEncode({
                      'bookingId': booking['bookingId'],
                      'studentName': booking['studentName'],
                      'registerNumber': booking['registerNumber'],
                      'movieTitle': booking['movieTitle'],
                      'showtime': booking['showtime'],
                      'seats': booking['seats'],
                      'ticketCount': booking['ticketCount'],
                      'status': booking['status'] ?? 'confirmed_demo',
                    }),
                    version: QrVersions.auto,
                    size: 190,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.M,
                  ),
                ),

                const SizedBox(height: 10),

                const Text(
                  'SCAN YOUR DIGITAL TICKET',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: gold,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Show this QR code to the miniplex staff.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 18),

                const Text(

                  'Please arrive before the show begins.',

                  textAlign: TextAlign.center,

                  style: TextStyle(color: Colors.white70),

                ),

              ],

            ),

          ),



          const SizedBox(height: 20),



          ElevatedButton.icon(

            onPressed: () => shareTicket(context),

            icon: const Icon(Icons.share),

            label: const Text('SHARE TICKET ON WHATSAPP'),

            style: ElevatedButton.styleFrom(

              backgroundColor: gold,

              foregroundColor: Colors.black,

              padding: const EdgeInsets.symmetric(vertical: 15),

            ),

          ),



          const SizedBox(height: 10),



          OutlinedButton(

            onPressed: () {

              Navigator.of(context).popUntil(

                (route) => route.isFirst,

              );

            },

            style: OutlinedButton.styleFrom(

              foregroundColor: gold,

              side: const BorderSide(color: gold),

              padding: const EdgeInsets.symmetric(vertical: 15),

            ),

            child: const Text('BACK TO HOME'),

          ),

        ],

      ),

    );

  }



  Widget ticketRow(String label, String value) {

    return Padding(

      padding: const EdgeInsets.symmetric(vertical: 9),

      child: Row(

        crossAxisAlignment: CrossAxisAlignment.start,

        children: [

          Expanded(

            child: Text(

              label,

              style: const TextStyle(color: Colors.white60),

            ),

          ),

          const SizedBox(width: 12),

          Expanded(

            child: Text(

              value,

              textAlign: TextAlign.end,

              style: const TextStyle(

                color: Colors.white,

                fontWeight: FontWeight.bold,

              ),

            ),

          ),

        ],

      ),

    );

  }

}
