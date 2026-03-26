import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:upi_pay/upi_pay.dart';
import 'package:unibus/screens/paymentprocessingpage.dart';

class UpiAppsPage extends StatefulWidget {
  final String stop;
  final String duration;
  final int amount;

  const UpiAppsPage({
    super.key,
    required this.stop,
    required this.duration,
    required this.amount,
  });

  @override
  State<UpiAppsPage> createState() => _UpiAppsPageState();
}

class _UpiAppsPageState extends State<UpiAppsPage> {
  final UpiPay _upiPay = UpiPay();
  List<ApplicationMeta>? _appsList;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await Future.delayed(Duration.zero);
      final apps = await _upiPay.getInstalledUpiApplications(
        statusType: UpiApplicationDiscoveryAppStatusType.all,
      );
      if (mounted) {
        setState(() {
          _appsList = apps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pay via UPI',
          style: GoogleFonts.righteous(color: Colors.black, fontSize: 22),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF7FC014)),
      );
    }

    if (_error != null) {
      return _buildErrorState();
    }

    if (_appsList == null || _appsList!.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            'Choose a UPI app to pay',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: Color(0xFF7FC014),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  '${widget.stop} · ${widget.duration}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.black87,
                  ),
                ),
                const Spacer(),
                Text(
                  '\u20B9${widget.amount}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF7FC014),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _appsList!.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final app = _appsList![index];
              return _AppTile(
                app: app,
                amount: widget.amount,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PaymentProcessingPage(
                        app: app,
                        stop: widget.stop,
                        duration: widget.duration,
                        amount: widget.amount,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No UPI apps found',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please install a UPI app like\nGPay, PhonePe, or Paytm',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadApps,
            child: const Text(
              'Retry',
              style: TextStyle(color: Color(0xFF7FC014)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text(
            'Could not load UPI apps',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _loadApps,
            child: const Text(
              'Retry',
              style: TextStyle(color: Color(0xFF7FC014)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final ApplicationMeta app;
  final VoidCallback onTap;
  final int amount;

  const _AppTile({
    required this.app,
    required this.onTap,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      leading: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child:
              app.iconImage(48) ??
              const Icon(
                Icons.account_balance_wallet,
                color: Color(0xFF7FC014),
              ),
        ),
      ),
      title: Text(
        _formatAppName(app.upiApplication.toString().split('.').last),
        style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'Tap to pay \u20B9$amount',
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey.shade500),
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF7FC014),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Pay',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
      onTap: onTap,
    );
  }

  String _formatAppName(String raw) {
    final result = raw.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (m) => ' ${m.group(0)}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }
}
