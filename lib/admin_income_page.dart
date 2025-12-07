import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:io_mom/booking.dart';
import 'package:io_mom/package.dart';
import 'confinement_center.dart';
import 'database.dart';
import 'transaction.dart';
import 'package:pay/pay.dart';

class AdminIncomePage extends StatefulWidget {
  const AdminIncomePage({super.key});

  @override
  State<AdminIncomePage> createState() => _AdminIncomePageState();
}

class _AdminIncomePageState extends State<AdminIncomePage> {
  final dbService = DatabaseService();
  List<Booking> bookings = [];
  Map<String, Package> packagesCache = {};
  Map<String, ConfinementCenter> centersCache = {};
  bool isLoading = true;
  String selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    fetchAllBookings();
  }

  Future<void> fetchAllBookings() async {
    try {
      print("📊 Fetching all bookings...");
      final allBookings = await dbService.getAllBooking();

      print("📦 Bookings fetched: ${allBookings?.length ?? 0}");

      if (allBookings == null || allBookings.isEmpty) {
        print("⚠️ No bookings found in database");
        setState(() {
          bookings = [];
          isLoading = false;
        });
        return;
      }

      Set<String> packageIDs = allBookings.map((b) => b.PackageID).toSet();
      Set<String> centerIDs = {};

      for (String packageID in packageIDs) {
        if (!packagesCache.containsKey(packageID)) {
          print("📦 Fetching package: $packageID");
          final package = await dbService.getPackageByPackageID(packageID);
          if (package != null) {
            packagesCache[packageID] = package;
            centerIDs.add(package.CenterID);
            print("✅ Package found: ${package.packageName}");
          } else {
            print("⚠️ Package not found: $packageID");
          }
        } else {
          centerIDs.add(packagesCache[packageID]!.CenterID);
        }
      }

      for (String centerID in centerIDs) {
        if (!centersCache.containsKey(centerID)) {
          print("🏢 Fetching center: $centerID");
          final center = await dbService.getConfinementByCenterID(centerID);
          if (center != null) {
            centersCache[centerID] = center;
            print("✅ Center found: ${center.CenterName}");
          } else {
            print("⚠️ Center not found: $centerID");
          }
        }
      }

      print("✅ Total bookings loaded: ${allBookings.length}");

      setState(() {
        bookings = allBookings;
        isLoading = false;
      });

      await checkAndAutoRelease();
    } catch (e) {
      print("❌ Error fetching bookings: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> checkAndAutoRelease() async {
    for (var booking in bookings) {
      if (shouldAutoRelease(booking)) {
        await _releasePayment(booking, autoRelease: true);
      }
    }
  }

  List<Booking> get filteredBookings {
    if (selectedFilter == 'All') return bookings;

    String statusCode = selectedFilter;
    if (selectedFilter == 'Paid') statusCode = 'P';
    if (selectedFilter == 'Released') statusCode = 'R';

    return bookings.where((b) => b.paymentStatus == statusCode).toList();
  }

  double calculatePlatformTax(double payAmount) {
    return payAmount - (payAmount / 1.06);
  }

  double calculateCenterAmount(double payAmount) {
    return payAmount / 1.06;
  }

  double get totalPlatformIncome {
    return bookings
        .where((b) => b.paymentStatus == 'P' || b.paymentStatus == 'R')
        .fold(0.0, (sum, b) => sum + calculatePlatformTax(b.payAmount));
  }

  bool shouldAutoRelease(Booking booking) {
    final daysSinceBooking = DateTime.now().difference(booking.bookingDate).inDays;
    return daysSinceBooking >= 5 && booking.paymentStatus == 'P';
  }

  String _getStatusDisplay(String statusCode) {
    switch (statusCode) {
      case 'P':
        return 'Paid';
      case 'R':
        return 'Released';
      default:
        return statusCode;
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "$label copied to clipboard",
          style: GoogleFonts.poppins(),
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Income Management",
          style: GoogleFonts.poppins(
            color: Colors.black,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.pinkAccent),
      )
          : bookings.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              "No Bookings Found",
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Check your database or wait for bookings",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => isLoading = true);
                fetchAllBookings();
              },
              icon: const Icon(Icons.refresh),
              label: Text(
                "Refresh",
                style: GoogleFonts.poppins(),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      )
          : Column(
        children: [
          _buildPlatformIncomeCard(),
          _buildFilterChips(),
          Expanded(
            child: filteredBookings.isEmpty
                ? Center(
              child: Text(
                "No bookings found for this filter.",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredBookings.length,
              itemBuilder: (context, index) {
                final booking = filteredBookings[index];
                final package = packagesCache[booking.PackageID] ?? Package.empty();
                final center = centersCache[package.CenterID];

                if (center == null) {
                  return const SizedBox.shrink();
                }

                return _buildBookingCard(booking, package, center);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformIncomeCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.pinkAccent, Colors.pink[300]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Platform Income (6% Tax)",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "RM ${totalPlatformIncome.toStringAsFixed(2)}",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Paid', 'Released'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
                selectedColor: Colors.pinkAccent,
                labelStyle: GoogleFonts.poppins(
                  color: isSelected ? Colors.white : Colors.black,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBookingCard(
      Booking booking, Package package, ConfinementCenter center) {
    final formatter = DateFormat('dd MMM yyyy');
    final checkOut = booking.checkInDate.add(Duration(days: package.duration));
    final platformTax = calculatePlatformTax(booking.payAmount);
    final centerAmount = calculateCenterAmount(booking.payAmount);
    final daysSinceBooking = DateTime.now().difference(booking.bookingDate).inDays;
    final daysUntilAutoRelease = 5 - daysSinceBooking;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    center.CenterName,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.pinkAccent,
                    ),
                  ),
                ),
                _buildStatusChip(booking.paymentStatus),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              package.packageName,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const Divider(height: 20),
            _infoRow("Booking ID", booking.BookingID),
            _infoRow("User ID", booking.userID),
            _infoRow("Check-In", formatter.format(booking.checkInDate)),
            _infoRow("Check-Out", formatter.format(checkOut)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _infoRow("Total Paid", "RM ${booking.payAmount.toStringAsFixed(2)}"),
                  _infoRow("Platform Tax (6%)", "RM ${platformTax.toStringAsFixed(2)}"),
                  const Divider(),
                  _infoRow(
                    "Transfer to Center",
                    "RM ${centerAmount.toStringAsFixed(2)}",
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (booking.paymentStatus == 'P' && daysUntilAutoRelease > 0)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.orange[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Auto-release in $daysUntilAutoRelease day${daysUntilAutoRelease > 1 ? 's' : ''}",
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "Booked on ${formatter.format(booking.bookingDate)}",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                if (booking.paymentStatus == 'P')
                  ElevatedButton.icon(
                    onPressed: () => _showReleaseDialog(booking, center, centerAmount),
                    icon: const Icon(Icons.send, size: 18),
                    label: Text(
                      "Release",
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                else if (booking.paymentStatus == 'R')
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green[700]),
                        const SizedBox(width: 6),
                        Text(
                          "Released",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.green[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String statusCode) {
    String displayStatus = _getStatusDisplay(statusCode);
    Color color;

    switch (statusCode) {
      case 'P':
        color = Colors.blue;
        break;
      case 'R':
        color = Colors.green;
        break;
      case 'Pending':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        displayStatus,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              "$title:",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                color: Colors.black,
                fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showReleaseDialog(Booking booking, ConfinementCenter center, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.account_balance, color: Colors.green[700], size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Release Payment",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Transfer payment to confinement center:",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    _dialogInfoRow("Center Name", center.CenterName),
                    const Divider(height: 16),
                    _dialogInfoRowWithCopy("Bank", center.bankName),
                    _dialogInfoRowWithCopy("Account Name", center.accountName),
                    _dialogInfoRowWithCopy("Account No", center.accountNo),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green[50]!, Colors.green[100]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Transfer Amount",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "RM ${amount.toStringAsFixed(2)}",
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(Icons.copy, color: Colors.green[700]),
                      onPressed: () => _copyToClipboard(
                        amount.toStringAsFixed(2),
                        "Amount",
                      ),
                      tooltip: "Copy amount",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Review the bank details and proceed to the next step to complete the payment.",
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.blue[800],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _confirmReleaseDialog(booking, center, amount);
            },
            icon: const Icon(Icons.arrow_forward, size: 18),
            label: Text(
              "Proceed to Payment",
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleGooglePaySuccess(Booking booking) async {
    try {
      print("💳 Google Pay payment successful for booking: ${booking.BookingID}");

      final updatedBooking = Booking(
        BookingID: booking.BookingID,
        bookingDate: booking.bookingDate,
        checkInDate: booking.checkInDate,
        payAmount: booking.payAmount,
        paymentStatus: 'R',
        userID: booking.userID,
        PackageID: booking.PackageID,
        checkOutStatus: booking.checkOutStatus,
      );

      await dbService.editBooking(updatedBooking);
      print("✅ Booking status updated to 'R'");

      var tid = await dbService.generateTransactionID();
      final centerAmount = calculateCenterAmount(booking.payAmount);

      final transaction = Transactions(
        TransactionID: tid,
        transactionDate: DateTime.now(),
        amount: centerAmount,
        status: 'P',
        BookingID: booking.BookingID,
      );

      await dbService.insertTransaction(transaction);
      print("✅ Transaction created: ${transaction.TransactionID}");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Payment Released via Google Pay!",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      "RM ${centerAmount.toStringAsFixed(2)} transferred successfully",
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );

      await fetchAllBookings();

    } catch (e) {
      print("❌ Error processing Google Pay payment: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Failed to process payment: $e",
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmReleaseDialog(Booking booking, ConfinementCenter center, double amount) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.payment, color: Colors.green[700], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Complete Payment",
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Transfer RM ${amount.toStringAsFixed(2)} to ${center.CenterName}",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Google Pay Button - THIS IS WHERE IT SHOULD BE
              GooglePayButton(
                paymentConfiguration: PaymentConfiguration.fromJsonString(
                    '''
                {
                  "provider": "google_pay",
                  "data": {
                    "environment": "TEST",
                    "apiVersion": 2,
                    "apiVersionMinor": 0,
                    "allowedPaymentMethods": [
                      {
                        "type": "CARD",
                        "parameters": {
                          "allowedAuthMethods": ["PAN_ONLY", "CRYPTOGRAM_3DS"],
                          "allowedCardNetworks": ["AMEX", "DISCOVER", "INTERAC", "JCB", "MASTERCARD", "VISA"]
                        },
                        "tokenizationSpecification": {
                          "type": "PAYMENT_GATEWAY",
                          "parameters": {
                            "gateway": "example",
                            "gatewayMerchantId": "exampleGatewayMerchantId"
                          }
                        }
                      }
                    ],
                    "merchantInfo": {
                      "merchantId": "BCR2DN4T27RXXVQ7",
                      "merchantName": "Io Mom"
                    },
                    "transactionInfo": {
                      "countryCode": "MY",
                      "currencyCode": "MYR"
                    }
                  }
                }
                '''
                ),
                paymentItems: [
                  PaymentItem(
                    label: 'Transfer to ${center.CenterName}',
                    amount: amount.toStringAsFixed(2),
                    status: PaymentItemStatus.final_price,
                  ),
                ],
                width: double.infinity,
                height: 50,
                type: GooglePayButtonType.pay,
                onPaymentResult: (result) {
                  print("💳 Payment result: $result");
                  Navigator.pop(context);
                  _handleGooglePaySuccess(booking);
                },
                onError: (error) {
                  print("❌ Google Pay Error: $error");
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Google Pay Error: $error",
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                loadingIndicator: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: GoogleFonts.poppins(color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$title:",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogInfoRowWithCopy(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$title:",
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                color: Colors.black,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.copy, size: 16, color: Colors.grey[600]),
            onPressed: () => _copyToClipboard(value, title),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: "Copy $title",
          ),
        ],
      ),
    );
  }

  Future<void> _releasePayment(Booking booking, {bool autoRelease = false}) async {
    try {
      final centerAmount = calculateCenterAmount(booking.payAmount);

      final updatedBooking = Booking(
        BookingID: booking.BookingID,
        bookingDate: booking.bookingDate,
        checkInDate: booking.checkInDate,
        payAmount: booking.payAmount,
        paymentStatus: 'R',
        userID: booking.userID,
        PackageID: booking.PackageID,
        checkOutStatus: booking.checkOutStatus,
      );

      await dbService.editBooking(updatedBooking);
      var tid = await dbService.generateTransactionID();

      final transaction = Transactions(
        TransactionID: tid,
        transactionDate: DateTime.now(),
        amount: centerAmount,
        status: 'P',
        BookingID: booking.BookingID,
      );

      await dbService.insertTransaction(transaction);

      print("✅ Transaction created: ${transaction.TransactionID} - RM ${centerAmount.toStringAsFixed(2)}");

      if (!autoRelease) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Payment Released Successfully!",
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "RM ${centerAmount.toStringAsFixed(2)} marked as transferred",
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      await fetchAllBookings();
    } catch (e) {
      print("❌ Error releasing payment: $e");
      if (!autoRelease) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Failed to release payment: $e",
                    style: GoogleFonts.poppins(),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}