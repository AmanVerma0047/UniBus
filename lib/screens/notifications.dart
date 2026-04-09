import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  static const Map<String, Map<String, dynamic>> _typeConfig = {
    'fees notice': {
      'icon': Icons.account_balance_wallet_rounded,
      'bg': Color(0xFFFAEEDA),
      'color': Color(0xFFBA7517),
      'label': 'Fees',
    },
    'off notice': {
      'icon': Icons.event_busy_rounded,
      'bg': Color(0xFFFCEBEB),
      'color': Color(0xFFA32D2D),
      'label': 'Off Day',
    },
    'schedule notice': {
      'icon': Icons.schedule_rounded,
      'bg': Color(0xFFE6F1FB),
      'color': Color(0xFF185FA5),
      'label': 'Schedule',
    },
  };

  static Map<String, dynamic> _fallbackConfig(String docId) => {
        'icon': Icons.notifications_rounded,
        'bg': const Color(0xFFF1EFE8),
        'color': Colors.black54,
        'label': docId,
      };

  static String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final now = DateTime.now();
    final dt = ts.toDate().toLocal();
    final diff = now.difference(dt);

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final fullDate =
        '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    final time = '$h:$m $period';

    String relative = '';
    if (diff.inSeconds < 60) {
      relative = 'Just now';
    } else if (diff.inMinutes < 60) {
      relative = '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      relative = '${diff.inHours}h ago';
    } else if (diff.inDays == 1) {
      relative = 'Yesterday';
    } else if (diff.inDays < 7) {
      relative = '${diff.inDays}d ago';
    }

    return relative.isNotEmpty
        ? '$fullDate · $time ($relative)'
        : '$fullDate · $time';
  }

  // Sort docs by createdAt descending — newest first
  static List<QueryDocumentSnapshot> _sortedDocs(
      List<QueryDocumentSnapshot> docs) {
    final sorted = [...docs];
    sorted.sort((a, b) {
      final aTs = (a.data() as Map<String, dynamic>)['createdAt']
          as Timestamp?;
      final bTs = (b.data() as Map<String, dynamic>)['createdAt']
          as Timestamp?;
      if (aTs == null && bTs == null) return 0;
      if (aTs == null) return 1;  // no timestamp → bottom
      if (bTs == null) return -1;
      return bTs.compareTo(aTs); // newest first
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F5),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('notifications')
              .snapshots(),
          builder: (context, snapshot) {
            final isLoading =
                snapshot.connectionState == ConnectionState.waiting;
            final docs = snapshot.data?.docs ?? [];
            final sorted = _sortedDocs(docs);

            return CustomScrollView(
              slivers: [
                // ── Header ────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius:
                                    BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_rounded,
                                color: Color(0xFF7FC014),
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text('Notifications',
                                    style:
                                        GoogleFonts.spaceGrotesk(
                                            fontSize: 22,
                                            fontWeight:
                                                FontWeight.w700,
                                            color: Colors.black)),
                                Text('Latest updates from campus',
                                    style:
                                        GoogleFonts.spaceGrotesk(
                                            fontSize: 12,
                                            color:
                                                Colors.black38)),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Count pill
                        if (!isLoading && sorted.isNotEmpty)
                          Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius:
                                      BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '${sorted.length} update${sorted.length == 1 ? '' : 's'}',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text('sorted by newest first',
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      color: Colors.black38)),
                            ],
                          ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),

                // ── Loading ────────────────────────
                if (isLoading)
                  const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF7FC014)),
                    ),
                  )

                // ── Error ──────────────────────────
                else if (snapshot.hasError)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              size: 48,
                              color: Colors.grey.shade300),
                          const SizedBox(height: 12),
                          Text('Something went wrong.',
                              style: GoogleFonts.spaceGrotesk(
                                  color: Colors.black38)),
                        ],
                      ),
                    ),
                  )

                // ── Empty ──────────────────────────
                else if (sorted.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1EFE8),
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: Icon(
                              Icons.notifications_off_rounded,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text('No notifications yet.',
                              style: GoogleFonts.spaceGrotesk(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black54)),
                          const SizedBox(height: 4),
                          Text(
                            'Check back later for updates\nfrom the bus manager.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                color: Colors.black38,
                                height: 1.5),
                          ),
                        ],
                      ),
                    ),
                  )

                // ── List ───────────────────────────
                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) {
                          final doc = sorted[i];
                          final data =
                              doc.data() as Map<String, dynamic>;
                          final cfg = _typeConfig[doc.id] ??
                              _fallbackConfig(doc.id);
                          final ts =
                              data['createdAt'] as Timestamp?;

                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: 10),
                            child: _NotificationCard(
                              icon: cfg['icon'] as IconData,
                              iconBg: cfg['bg'] as Color,
                              iconColor: cfg['color'] as Color,
                              label: cfg['label'] as String,
                              title: data['title'] ?? '—',
                              message: data['message'] ?? '—',
                              timestamp: _formatTimestamp(ts),
                              isNewest: i == 0,
                            ),
                          );
                        },
                        childCount: sorted.length,
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Notification card ─────────────────────────────────
class _NotificationCard extends StatefulWidget {
  final IconData icon;
  final Color iconBg, iconColor;
  final String label, title, message, timestamp;
  final bool isNewest;

  const _NotificationCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isNewest,
  });

  @override
  State<_NotificationCard> createState() =>
      _NotificationCardState();
}

class _NotificationCardState extends State<_NotificationCard> {
  bool _expanded = false;

  String _truncate(String text, int limit) {
    if (text.length <= limit) return text;
    return '${text.substring(0, limit)}...';
  }

  @override
  Widget build(BuildContext context) {
    final isLong = widget.message.length > 80;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expanded
                ? widget.iconColor.withOpacity(0.3)
                : Colors.black.withOpacity(0.07),
            width: _expanded ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Colored top accent ─────────────
            Container(
              height: 3,
              decoration: BoxDecoration(
                color: widget.iconColor.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Icon ──────────────────────
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: widget.iconBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(widget.icon,
                        color: widget.iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),

                  // ── Content ───────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        // Title + badge + newest dot
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // Newest dot
                            if (widget.isNewest) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                    top: 4, right: 6),
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF7FC014),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                widget.title,
                                style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black,
                                    height: 1.3),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: widget.iconBg,
                                borderRadius:
                                    BorderRadius.circular(100),
                              ),
                              child: Text(widget.label,
                                  style:
                                      GoogleFonts.spaceGrotesk(
                                          fontSize: 10,
                                          fontWeight:
                                              FontWeight.w600,
                                          color:
                                              widget.iconColor)),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Message
                        Text(
                          _expanded
                              ? widget.message
                              : _truncate(widget.message, 80),
                          style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              color: Colors.black54,
                              height: 1.55),
                        ),

                        const SizedBox(height: 10),

                        // Timestamp + read more
                        Row(
                          children: [
                            if (widget.timestamp.isNotEmpty) ...[
                              Icon(Icons.access_time_rounded,
                                  size: 11,
                                  color: Colors.black26),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  widget.timestamp,
                                  style: GoogleFonts.spaceGrotesk(
                                      fontSize: 11,
                                      color: Colors.black38),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                            if (isLong) ...[
                              const Spacer(),
                              GestureDetector(
                                onTap: () => setState(
                                    () => _expanded = !_expanded),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _expanded
                                          ? 'Show less'
                                          : 'Read more',
                                      style:
                                          GoogleFonts.spaceGrotesk(
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.w600,
                                              color: widget
                                                  .iconColor),
                                    ),
                                    const SizedBox(width: 2),
                                    Icon(
                                      _expanded
                                          ? Icons
                                              .keyboard_arrow_up_rounded
                                          : Icons
                                              .keyboard_arrow_down_rounded,
                                      size: 14,
                                      color: widget.iconColor,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}