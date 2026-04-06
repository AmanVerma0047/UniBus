import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unibus/screens/login.dart';

class BusManagerScreen extends StatefulWidget {
  const BusManagerScreen({super.key});

  @override
  State<BusManagerScreen> createState() => _BusManagerScreenState();
}

class _BusManagerScreenState extends State<BusManagerScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = [
    'Notifications',
    'Fees',
    'Schedule',
    'Students',
  ];

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text('Logout',
            style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700)),
        content: Text('Are you sure you want to logout?',
            style: GoogleFonts.spaceGrotesk(color: Colors.black54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style:
                    GoogleFonts.spaceGrotesk(color: Colors.black54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Logout',
                style: GoogleFonts.spaceGrotesk(
                    color: Colors.red,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F5),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text('Bus Manager',
            style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.black)),
        actions: [
          GestureDetector(
            onTap: _logout,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEBEB),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.logout_rounded,
                      size: 16, color: Color(0xFFA32D2D)),
                  const SizedBox(width: 6),
                  Text('Logout',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFA32D2D))),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Tab row ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_tabs.length, (i) {
                    final isActive = _selectedTab == i;
                    return Padding(
                      padding: EdgeInsets.only(
                          right: i < _tabs.length - 1 ? 8 : 0),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedTab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 20),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.black
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? Colors.black
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(_tabs[i],
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.black54)),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 16),

            Expanded(
              child: IndexedStack(
                index: _selectedTab,
                children: const [
                  _NotificationsTab(),
                  _FeesTab(),
                  _ScheduleTab(),
                  _StudentsTab(), // ← new
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// STUDENTS TAB
// ═══════════════════════════════════════════════
class _StudentsTab extends StatefulWidget {
  const _StudentsTab();

  @override
  State<_StudentsTab> createState() => _StudentsTabState();
}

class _StudentsTabState extends State<_StudentsTab> {
  String _filter = 'all'; // 'all' | 'active' | 'inactive'
  String _search = '';
  final _searchCtrl = TextEditingController();

  String _formatDate(Timestamp? ts) {
    if (ts == null) return '—';
    final d = ts.toDate().toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Search + filter bar ───────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) =>
                      setState(() => _search = v.trim().toLowerCase()),
                  style: GoogleFonts.spaceGrotesk(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by name or student ID...',
                    hintStyle: GoogleFonts.spaceGrotesk(
                        color: Colors.black26, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: Colors.black38, size: 20),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: Colors.black38),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _search = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Filter chips
              Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    active: _filter == 'all',
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Active',
                    active: _filter == 'active',
                    color: const Color(0xFF3B6D11),
                    activeBg: const Color(0xFFEAF3DE),
                    onTap: () =>
                        setState(() => _filter = 'active'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Inactive',
                    active: _filter == 'inactive',
                    color: const Color(0xFFA32D2D),
                    activeBg: const Color(0xFFFCEBEB),
                    onTap: () =>
                        setState(() => _filter = 'inactive'),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ── Student list ──────────────────────
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF7FC014)));
              }

              var docs = snapshot.data!.docs;

              // Apply status filter
              if (_filter != 'all') {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final status =
                      (data['cardStatus'] ?? 'inactive')
                          .toString()
                          .toLowerCase();
                  return status == _filter;
                }).toList();
              }

              // Apply search
              if (_search.isNotEmpty) {
                docs = docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  final name =
                      (data['name'] ?? '').toString().toLowerCase();
                  final id = d.id.toLowerCase();
                  return name.contains(_search) ||
                      id.contains(_search);
                }).toList();
              }

              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 48,
                          color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      Text('No students found.',
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              color: Colors.black38)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 32),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc = docs[index];
                  final data =
                      doc.data() as Map<String, dynamic>;
                  final studentId = doc.id;
                  final name = data['name'] ?? '—';
                  final cardStatus =
                      (data['cardStatus'] ?? 'inactive')
                          .toString()
                          .toLowerCase();
                  final isActive = cardStatus == 'active';
                  final batch = data['batch'] ?? '';
                  final stop = data['stop'] ?? '—';
                  final validity = data['validity'] ?? '—';
                  final expiryRaw = data['expiryDate'];
                  final expiry = expiryRaw != null
                      ? _formatDate(expiryRaw as Timestamp)
                      : '—';

                  return _StudentCard(
                    studentId: studentId,
                    name: name,
                    batch: batch,
                    stop: stop,
                    validity: validity,
                    expiry: expiry,
                    isActive: isActive,
                    formatDate: _formatDate,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Student card ──────────────────────────────────────
class _StudentCard extends StatefulWidget {
  final String studentId, name, batch, stop, validity, expiry;
  final bool isActive;
  final String Function(Timestamp?) formatDate;

  const _StudentCard({
    required this.studentId,
    required this.name,
    required this.batch,
    required this.stop,
    required this.validity,
    required this.expiry,
    required this.isActive,
    required this.formatDate,
  });

  @override
  State<_StudentCard> createState() => _StudentCardState();
}

class _StudentCardState extends State<_StudentCard> {
  bool _expanded = false;

  // Last transaction fetched lazily
  Map<String, dynamic>? _lastTxn;
  bool _loadingTxn = false;
  bool _txnFetched = false;

  Future<void> _fetchLastTransaction() async {
    if (_txnFetched) return;
    setState(() => _loadingTxn = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .collection('transactions')
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        _lastTxn = snap.docs.first.data();
      }
    } catch (e) {
      debugPrint('Error fetching txn: $e');
    }
    setState(() {
      _loadingTxn = false;
      _txnFetched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: widget.isActive
              ? const Color(0xFF7FC014).withOpacity(0.3)
              : Colors.black.withOpacity(0.07),
        ),
      ),
      child: Column(
        children: [
          // ── Main row ────────────────────────
          GestureDetector(
            onTap: () {
              setState(() => _expanded = !_expanded);
              if (!_txnFetched) _fetchLastTransaction();
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: widget.isActive
                          ? const Color(0xFFEAF3DE)
                          : const Color(0xFFF1EFE8),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      color: widget.isActive
                          ? const Color(0xFF3B6D11)
                          : Colors.black38,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(widget.name,
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(widget.studentId,
                                style: GoogleFonts.dmMono(
                                    fontSize: 11,
                                    color: Colors.black38)),
                            if (widget.batch.isNotEmpty) ...[
                              Text(' · ',
                                  style: GoogleFonts.spaceGrotesk(
                                      color: Colors.black26)),
                              Text(widget.batch,
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      color: Colors.black38)),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: widget.isActive
                              ? const Color(0xFFEAF3DE)
                              : const Color(0xFFFCEBEB),
                          borderRadius:
                              BorderRadius.circular(100),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: widget.isActive
                                    ? const Color(0xFF3B6D11)
                                    : const Color(0xFFA32D2D),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              widget.isActive
                                  ? 'Active'
                                  : 'Inactive',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isActive
                                      ? const Color(0xFF3B6D11)
                                      : const Color(0xFFA32D2D)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        _expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.black26,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded details ─────────────────
          if (_expanded) ...[
            Container(
              height: 0.5,
              color: Colors.black.withOpacity(0.06),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Card info
                  Text('CARD INFO',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black38,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  _DetailRow(
                      icon: Icons.place_rounded,
                      label: 'Stop',
                      value: widget.stop),
                  _DetailRow(
                      icon: Icons.timer_outlined,
                      label: 'Pass Duration',
                      value: widget.validity),
                  _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Expires On',
                      value: widget.expiry),

                  const SizedBox(height: 12),

                  // Last recharge
                  Text('LAST RECHARGE',
                      style: GoogleFonts.spaceGrotesk(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black38,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 8),

                  if (_loadingTxn)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF7FC014)),
                      ),
                    )
                  else if (_lastTxn == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1EFE8),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                              Icons.receipt_long_rounded,
                              size: 16,
                              color: Colors.black38),
                          const SizedBox(width: 8),
                          Text('No recharge history found.',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 12,
                                  color: Colors.black38)),
                        ],
                      ),
                    )
                  else ...[
                    _DetailRow(
                      icon: Icons.place_outlined,
                      label: 'Stop',
                      value: _lastTxn!['stop'] ?? '—',
                    ),
                    _DetailRow(
                      icon: Icons.timer_outlined,
                      label: 'Duration',
                      value: _lastTxn!['duration'] ?? '—',
                    ),
                    _DetailRow(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Amount Paid',
                      value: _lastTxn!['amount'] != null
                          ? '₹${_lastTxn!['amount']}'
                          : '—',
                    ),
                    _DetailRow(
                      icon: Icons.calendar_today_rounded,
                      label: 'Recharged On',
                      value: widget.formatDate(
                          _lastTxn!['timestamp'] as Timestamp?),
                    ),
                    _DetailRow(
                      icon: Icons.event_available_rounded,
                      label: 'New Expiry',
                      value: widget.formatDate(
                          _lastTxn!['newExpiryDate'] as Timestamp?),
                    ),
                    _DetailRow(
                      icon: Icons.tag_rounded,
                      label: 'Txn Ref',
                      value: _lastTxn!['txnRef'] ?? '—',
                      mono: true,
                    ),
                    // Status chip
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: Colors.black38),
                        const SizedBox(width: 6),
                        Text('Status  ',
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 12,
                                color: Colors.black38)),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: (_lastTxn!['status'] ?? '')
                                        .toString()
                                        .toLowerCase() ==
                                    'success'
                                ? const Color(0xFFEAF3DE)
                                : const Color(0xFFFCEBEB),
                            borderRadius:
                                BorderRadius.circular(100),
                          ),
                          child: Text(
                            (_lastTxn!['status'] ?? '—')
                                .toString()
                                .toUpperCase(),
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: (_lastTxn!['status'] ?? '')
                                            .toString()
                                            .toLowerCase() ==
                                        'success'
                                    ? const Color(0xFF3B6D11)
                                    : const Color(0xFFA32D2D)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Detail row ────────────────────────────────────────
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final bool mono;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.mono = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.black38),
          const SizedBox(width: 6),
          Text('$label  ',
              style: GoogleFonts.spaceGrotesk(
                  fontSize: 12, color: Colors.black38)),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: mono
                  ? GoogleFonts.dmMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87)
                  : GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filter chip ───────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final Color color;
  final Color activeBg;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.onTap,
    this.color = Colors.white,
    this.activeBg = Colors.black,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: active ? activeBg : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active
                  ? (activeBg == Colors.black ? Colors.white : color)
                  : Colors.black54),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// NOTIFICATIONS TAB
// ═══════════════════════════════════════════════
class _NotificationsTab extends StatefulWidget {
  const _NotificationsTab();

  @override
  State<_NotificationsTab> createState() => _NotificationsTabState();
}

class _NotificationsTabState extends State<_NotificationsTab> {
  final _titleCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _selectedType = 'fees notice';
  bool _saving = false;

  final List<String> _notifTypes = [
    'fees notice',
    'off notice',
    'schedule notice',
  ];

  final Map<String, Map<String, dynamic>> _typeConfig = {
    'fees notice': {
      'label': 'Fees Notice',
      'icon': Icons.account_balance_wallet_rounded,
      'bg': const Color(0xFFFAEEDA),
      'color': const Color(0xFFBA7517),
    },
    'off notice': {
      'label': 'Off Notice',
      'icon': Icons.event_busy_rounded,
      'bg': const Color(0xFFFCEBEB),
      'color': const Color(0xFFA32D2D),
    },
    'schedule notice': {
      'label': 'Schedule Notice',
      'icon': Icons.schedule_rounded,
      'bg': const Color(0xFFE6F1FB),
      'color': const Color(0xFF185FA5),
    },
  };

  Future<void> _sendNotification() async {
    final title = _titleCtrl.text.trim();
    final message = _messageCtrl.text.trim();
    if (title.isEmpty || message.isEmpty) {
      _showSnack('Please fill in both fields.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('notifications')
          .doc(_selectedType)
          .set({'title': title, 'message': message});
      _titleCtrl.clear();
      _messageCtrl.clear();
      _showSnack('Notification sent successfully!');
    } catch (e) {
      _showSnack('Failed to send. Try again.', isError: true);
    }
    setState(() => _saving = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.spaceGrotesk()),
      backgroundColor:
          isError ? Colors.red.shade700 : const Color(0xFF7FC014),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel('NOTIFICATION TYPE'),
          const SizedBox(height: 10),
          Column(
            children: _notifTypes.map((type) {
              final cfg = _typeConfig[type]!;
              final isActive = _selectedType == type;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = type),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.black : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive
                          ? Colors.black
                          : Colors.black.withOpacity(0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white.withOpacity(0.15)
                              : cfg['bg'] as Color,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(cfg['icon'] as IconData,
                            color: isActive
                                ? Colors.white
                                : cfg['color'] as Color,
                            size: 18),
                      ),
                      const SizedBox(width: 14),
                      Text(cfg['label'] as String,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isActive
                                  ? Colors.white
                                  : Colors.black)),
                      const Spacer(),
                      if (isActive)
                        const Icon(Icons.check_circle_rounded,
                            color: Color(0xFF7FC014), size: 18),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _SectionLabel('TITLE'),
          const SizedBox(height: 8),
          _InputBox(controller: _titleCtrl, hint: 'e.g. Fees Updated!'),
          const SizedBox(height: 14),
          _SectionLabel('MESSAGE'),
          const SizedBox(height: 8),
          _InputBox(
            controller: _messageCtrl,
            hint: 'Write your message here...',
            maxLines: 4,
          ),
          const SizedBox(height: 20),
          _PrimaryButton(
            label: 'Send Notification',
            loading: _saving,
            onTap: _sendNotification,
            icon: Icons.send_rounded,
          ),
          const SizedBox(height: 28),
          _SectionLabel('EXISTING NOTIFICATIONS'),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                    child: CircularProgressIndicator());
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return _EmptyState('No notifications yet.');
              }
              return Column(
                children: docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final cfg = _typeConfig[doc.id] ??
                      {
                        'label': doc.id,
                        'icon': Icons.notifications_rounded,
                        'bg': const Color(0xFFF1EFE8),
                        'color': Colors.black54,
                      };
                  return _NotifCard(
                    type: cfg['label'] as String,
                    icon: cfg['icon'] as IconData,
                    iconBg: cfg['bg'] as Color,
                    iconColor: cfg['color'] as Color,
                    title: data['title'] ?? '—',
                    message: data['message'] ?? '—',
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// FEES TAB
// ═══════════════════════════════════════════════
class _FeesTab extends StatefulWidget {
  const _FeesTab();

  @override
  State<_FeesTab> createState() => _FeesTabState();
}

class _FeesTabState extends State<_FeesTab> {
  String? _selectedBus;
  bool _saving = false;
  final Map<String, TextEditingController> _controllers = {};

  Future<void> _saveFees() async {
    if (_selectedBus == null) return;
    setState(() => _saving = true);
    try {
      final Map<String, String> updated = {};
      _controllers.forEach((stop, ctrl) {
        updated[stop] = ctrl.text.trim();
      });
      await FirebaseFirestore.instance
          .collection('Fees')
          .doc(_selectedBus)
          .update(updated);
      _showSnack('Fees updated successfully!');
    } catch (e) {
      _showSnack('Failed to update fees.', isError: true);
    }
    setState(() => _saving = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.spaceGrotesk()),
      backgroundColor:
          isError ? Colors.red.shade700 : const Color(0xFF7FC014),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance.collection('Fees').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final buses = snapshot.data!.docs;
        if (buses.isEmpty) return _EmptyState('No fees data found.');

        _selectedBus ??= buses.first.id;
        if (!buses.any((d) => d.id == _selectedBus)) {
          _selectedBus = buses.first.id;
          _controllers.clear();
        }

        final currentDoc =
            buses.firstWhere((d) => d.id == _selectedBus);
        final feesData = currentDoc.data() as Map<String, dynamic>;

        for (final entry in feesData.entries) {
          if (!_controllers.containsKey(entry.key)) {
            _controllers[entry.key] =
                TextEditingController(text: entry.value.toString());
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('SELECT BUS'),
              const SizedBox(height: 10),
              Row(
                children: buses.map((bus) {
                  final isActive = _selectedBus == bus.id;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: bus.id != buses.last.id ? 10 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedBus = bus.id;
                          _controllers.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.black
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? Colors.black
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_bus_rounded,
                                  size: 16,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.black38),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(bus.id,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? Colors.white
                                            : Colors.black54)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _SectionLabel('STOP FEES (₹ / MONTH)'),
              const SizedBox(height: 10),
              ...feesData.entries.map((entry) {
                final ctrl = _controllers[entry.key]!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.black.withOpacity(0.07)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(entry.key,
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      SizedBox(
                        width: 90,
                        child: TextField(
                          controller: ctrl,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.right,
                          style: GoogleFonts.dmMono(
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixText: '₹ ',
                            prefixStyle: GoogleFonts.dmMono(
                                fontSize: 13, color: Colors.black38),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
              _PrimaryButton(
                label: 'Save Fees',
                loading: _saving,
                onTap: _saveFees,
                icon: Icons.save_rounded,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// SCHEDULE TAB
// ═══════════════════════════════════════════════
class _ScheduleTab extends StatefulWidget {
  const _ScheduleTab();

  @override
  State<_ScheduleTab> createState() => _ScheduleTabState();
}

class _ScheduleTabState extends State<_ScheduleTab> {
  String? _selectedBus;
  bool _saving = false;
  final Map<String, TextEditingController> _controllers = {};
  final _newStopCtrl = TextEditingController();
  final _newTimeCtrl = TextEditingController();

  Future<void> _saveSchedule() async {
    if (_selectedBus == null) return;
    setState(() => _saving = true);
    try {
      final Map<String, String> updated = {};
      _controllers.forEach((stop, ctrl) {
        updated[stop] = ctrl.text.trim();
      });
      await FirebaseFirestore.instance
          .collection('schedule')
          .doc(_selectedBus)
          .update(updated);
      _showSnack('Schedule updated successfully!');
    } catch (e) {
      _showSnack('Failed to update schedule.', isError: true);
    }
    setState(() => _saving = false);
  }

  Future<void> _addStop(Map<String, dynamic> existing) async {
    final stop = _newStopCtrl.text.trim();
    final time = _newTimeCtrl.text.trim();
    if (stop.isEmpty || time.isEmpty) {
      _showSnack('Enter both stop name and time.', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('schedule')
          .doc(_selectedBus)
          .update({stop: time});
      _newStopCtrl.clear();
      _newTimeCtrl.clear();
      _controllers.clear();
      _showSnack('Stop added!');
    } catch (e) {
      _showSnack('Failed to add stop.', isError: true);
    }
    setState(() => _saving = false);
  }

  Future<void> _deleteStop(String stop) async {
    try {
      await FirebaseFirestore.instance
          .collection('schedule')
          .doc(_selectedBus)
          .update({stop: FieldValue.delete()});
      _controllers.remove(stop);
      _showSnack('Stop removed.');
    } catch (e) {
      _showSnack('Failed to remove stop.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.spaceGrotesk()),
      backgroundColor:
          isError ? Colors.red.shade700 : const Color(0xFF7FC014),
    ));
  }

  int _parseTime(String t) {
    final clean = t.replaceAll(RegExp(r'[APMapm\s]'), '');
    final parts = clean.split(':');
    if (parts.length < 2) return 0;
    int h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    if (t.toUpperCase().contains('PM') && h < 12) h += 12;
    return h * 60 + m;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('schedule')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final buses = snapshot.data!.docs;
        if (buses.isEmpty)
          return _EmptyState('No schedule data found.');

        _selectedBus ??= buses.first.id;
        if (!buses.any((d) => d.id == _selectedBus)) {
          _selectedBus = buses.first.id;
          _controllers.clear();
        }

        final currentDoc =
            buses.firstWhere((d) => d.id == _selectedBus);
        final scheduleData =
            currentDoc.data() as Map<String, dynamic>;

        final sortedEntries = scheduleData.entries.toList()
          ..sort((a, b) => _parseTime(a.value.toString())
              .compareTo(_parseTime(b.value.toString())));

        for (final entry in sortedEntries) {
          if (!_controllers.containsKey(entry.key)) {
            _controllers[entry.key] =
                TextEditingController(text: entry.value.toString());
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel('SELECT BUS'),
              const SizedBox(height: 10),
              Row(
                children: buses.map((bus) {
                  final isActive = _selectedBus == bus.id;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                          right: bus.id != buses.last.id ? 10 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedBus = bus.id;
                          _controllers.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.black
                                : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? Colors.black
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              Icon(Icons.directions_bus_rounded,
                                  size: 16,
                                  color: isActive
                                      ? Colors.white
                                      : Colors.black38),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(bus.id,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isActive
                                            ? Colors.white
                                            : Colors.black54)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              _SectionLabel('STOPS & TIMES'),
              const SizedBox(height: 10),
              ...sortedEntries.map((entry) {
                final ctrl = _controllers[entry.key]!;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.fromLTRB(16, 4, 8, 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.black.withOpacity(0.07)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.radio_button_checked,
                          size: 12, color: Color(0xFF7FC014)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(entry.key,
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ),
                      SizedBox(
                        width: 80,
                        child: TextField(
                          controller: ctrl,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                              border: InputBorder.none),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 18,
                            color: Color(0xFFA32D2D)),
                        onPressed: () => _deleteStop(entry.key),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
              _PrimaryButton(
                label: 'Save Schedule',
                loading: _saving,
                onTap: _saveSchedule,
                icon: Icons.save_rounded,
              ),
              const SizedBox(height: 24),
              _SectionLabel('ADD NEW STOP'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _InputBox(
                        controller: _newStopCtrl,
                        hint: 'Stop name'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _InputBox(
                        controller: _newTimeCtrl, hint: '8:30'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _PrimaryButton(
                label: 'Add Stop',
                loading: false,
                onTap: () => _addStop(scheduleData),
                icon: Icons.add_rounded,
                secondary: true,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: GoogleFonts.spaceGrotesk(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.black38,
            letterSpacing: 1));
  }
}

class _InputBox extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;

  const _InputBox({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: GoogleFonts.spaceGrotesk(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(
              color: Colors.black26, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  final IconData icon;
  final bool secondary;

  const _PrimaryButton({
    required this.label,
    required this.loading,
    required this.onTap,
    required this.icon,
    this.secondary = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: loading ? null : onTap,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
            : Icon(icon, size: 18),
        label: Text(label,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              secondary ? const Color(0xFF3B6D11) : Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 60),
        child: Text(text,
            style: GoogleFonts.spaceGrotesk(
                fontSize: 14, color: Colors.black38)),
      ),
    );
  }
}

class _NotifCard extends StatelessWidget {
  final String type, title, message;
  final IconData icon;
  final Color iconBg, iconColor;

  const _NotifCard({
    required this.type,
    required this.title,
    required this.message,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              fontWeight: FontWeight.w600)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(type,
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: iconColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(message,
                    style: GoogleFonts.spaceGrotesk(
                        fontSize: 12, color: Colors.black45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}