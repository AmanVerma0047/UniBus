import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BusManagerScreen extends StatefulWidget {
  const BusManagerScreen({super.key});

  @override
  State<BusManagerScreen> createState() => _BusManagerScreenState();
}

class _BusManagerScreenState extends State<BusManagerScreen> {
  int _selectedTab = 0;
  final List<String> _tabs = ['Notifications', 'Fees', 'Schedule'];

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
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Tab row ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: List.generate(_tabs.length, (i) {
                  final isActive = _selectedTab == i;
                  return Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.only(right: i < _tabs.length - 1 ? 8 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTab = i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.black : Colors.white,
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
                    ),
                  );
                }),
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
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF7FC014),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Type selector ──────────────────────
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

          // ── Live preview of existing notifs ────
          _SectionLabel('EXISTING NOTIFICATIONS'),
          const SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('notifications')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
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

  // stopName → TextEditingController
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
      backgroundColor: isError ? Colors.red.shade700 : const Color(0xFF7FC014),
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

        // Default select first bus
        _selectedBus ??= buses.first.id;

        final currentDoc = buses.firstWhere(
          (d) => d.id == _selectedBus,
          orElse: () => buses.first,
        );
        final feesData =
            currentDoc.data() as Map<String, dynamic>;

        // Sync controllers
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
                            color:
                                isActive ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? Colors.black
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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

              // Fees rows
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
                                fontSize: 13,
                                color: Colors.black38),
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

  // For adding new stop
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
      _controllers.clear(); // force re-sync
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
        if (buses.isEmpty) return _EmptyState('No schedule data found.');

        _selectedBus ??= buses.first.id;

        final currentDoc = buses.firstWhere(
          (d) => d.id == _selectedBus,
          orElse: () => buses.first,
        );
        final scheduleData =
            currentDoc.data() as Map<String, dynamic>;

        // Sort stops by time
        final sortedEntries = scheduleData.entries.toList()
          ..sort((a, b) =>
              _parseTime(a.value.toString())
                  .compareTo(_parseTime(b.value.toString())));

        // Sync controllers
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
                            color:
                                isActive ? Colors.black : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isActive
                                  ? Colors.black
                                  : Colors.black.withOpacity(0.08),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
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

              // Stops list
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
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 18, color: Color(0xFFA32D2D)),
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

              // ── Add new stop ────────────────────
              _SectionLabel('ADD NEW STOP'),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _InputBox(
                      controller: _newStopCtrl,
                      hint: 'Stop name',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: _InputBox(
                      controller: _newTimeCtrl,
                      hint: '8:30',
                    ),
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

  int _parseTime(String t) {
    final clean = t.replaceAll(RegExp(r'[APMapm\s]'), '');
    final parts = clean.split(':');
    if (parts.length < 2) return 0;
    int h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    if (t.toUpperCase().contains('PM') && h < 12) h += 12;
    return h * 60 + m;
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