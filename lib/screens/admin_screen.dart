import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/device.dart';
import '../models/maintenance_log.dart';
import '../providers/auth_provider.dart';

class AdminScreen extends StatefulWidget {
  // Yeni Hali
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Yeni Kullanıcı Form Durumu
  final _userFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = 'personnel';
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleCreateUser(AuthProvider authProvider) async {
    if (_userFormKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      final success = await authProvider.registerNewUser(
        email: _emailController.text,
        password: _passwordController.text,
        role: _selectedRole,
      );

      if (mounted) {
        if (success) {
          _emailController.clear();
          _passwordController.clear();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('User successfully created!'),
              backgroundColor: const Color(0xFF10B981), // Zümrüt
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'Failed to create user.'),
              backgroundColor: const Color(0xFFEF4444), // Kırmızı
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final firebaseService = authProvider.service;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text(
          'ADMIN DASHBOARD',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFEF4444)),
            tooltip: 'Sign Out',
            onPressed: () => authProvider.logout(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF818CF8),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: const Color(0xFF94A3B8),
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Logs'),
            Tab(icon: Icon(Icons.devices_other), text: 'Inventory'),
            Tab(icon: Icon(Icons.person_add_alt_1_outlined), text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Sekme 1: Bakım Günlükleri
          _buildLogsTab(firebaseService),
          // Sekme 2: Cihaz Envanteri
          _buildInventoryTab(firebaseService),
          // Sekme 3: Kullanıcı Oluştur
          _buildCreateUserTab(authProvider),
        ],
      ),
    );
  }

  // --- SEKME 1: BAKIM GÜNLÜKLERİ ---
  Widget _buildLogsTab(dynamic service) {
    return StreamBuilder<List<MaintenanceLog>>(
      stream: service.streamMaintenanceLogs(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading logs: ${snapshot.error}',
              style: const TextStyle(color: Colors.white70),
            ),
          );
        }

        final logs = snapshot.data ?? [];
        if (logs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.feed_outlined,
                  size: 64,
                  color: const Color(0xFF475569).withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No maintenance reports received yet.',
                  style: TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Log reports will appear here in real-time.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            final log = logs[index];
            final formattedTime = DateFormat(
              'dd MMM yyyy, HH:mm',
            ).format(log.timestamp);

            Color statusColor;
            IconData statusIcon;
            if (log.status == 'Working') {
              statusColor = const Color(0xFF10B981); // Zümrüt
              statusIcon = Icons.check_circle_outline;
            } else if (log.status == 'Faulty') {
              statusColor = const Color(0xFFEF4444); // Kırmızı/Mercan
              statusIcon = Icons.error_outline;
            } else {
              statusColor = const Color(0xFFF59E0B); // Kehribar
              statusIcon = Icons.help_outline;
            }

            return Card(
              color: const Color(0xFF1E293B),
              margin: const EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: const Color(0xFF334155).withValues(alpha: 0.5),
                ),
              ),
              child: ExpansionTile(
                iconColor: const Color(0xFF818CF8),
                collapsedIconColor: const Color(0xFF94A3B8),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 4),
                          Text(
                            log.status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        log.deviceName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'SN: ${log.deviceSerialNumber} • $formattedTime',
                    style: TextStyle(
                      color: const Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Color(0xFF334155)),
                          const SizedBox(height: 8),
                          _buildDetailRow('Reported By', log.reportedBy),
                          const SizedBox(height: 10),
                          _buildDetailRow(
                            'Notes',
                            log.notes.isEmpty ? 'No notes provided' : log.notes,
                          ),
                          if (log.photoUrl != null &&
                              log.photoUrl!.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            const Text(
                              'Captured Image:',
                              style: TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () =>
                                  _showFullImageDialog(context, log.photoUrl!),
                              child: Container(
                                height: 160,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFF475569),
                                  ),
                                  image: DecorationImage(
                                    image: NetworkImage(log.photoUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                child: Stack(
                                  children: [
                                    Positioned(
                                      bottom: 8,
                                      right: 8,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(
                                            alpha: 0.6,
                                          ),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.fullscreen_rounded,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF6366F1),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
      ],
    );
  }

  void _showFullImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(url),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  // --- SEKME 2: ENVANTER ---
  Widget _buildInventoryTab(dynamic service) {
    return StreamBuilder<List<Device>>(
      stream: service.streamInventory(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
            ),
          );
        }

        final devices = snapshot.data ?? [];
        if (devices.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: const Color(0xFF475569).withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Inventory is currently empty.',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Seed standard testing hardware (HMI, LED, Panel, LCD) automatically.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await service.seedInitialInventory();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.cloud_upload_outlined,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Seed Inventory',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Metrik hesaplamaları
        int healthyCount = devices.where((d) => d.status == 'Working').length;
        int faultyCount = devices.where((d) => d.status == 'Faulty').length;
        int missingCount = devices.where((d) => d.status == 'Missing').length;

        return Column(
          children: [
            // Durum çubuğu genel bakış
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  _buildMetricCard(
                    'WORKING',
                    healthyCount,
                    const Color(0xFF10B981),
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    'FAULTY',
                    faultyCount,
                    const Color(0xFFEF4444),
                  ),
                  const SizedBox(width: 10),
                  _buildMetricCard(
                    'MISSING',
                    missingCount,
                    const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF334155)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final dev = devices[index];

                  Color statusColor;
                  if (dev.status == 'Working') {
                    statusColor = const Color(0xFF10B981);
                  } else if (dev.status == 'Faulty') {
                    statusColor = const Color(0xFFEF4444);
                  } else {
                    statusColor = const Color(0xFFF59E0B);
                  }

                  IconData typeIcon;
                  switch (dev.type.toUpperCase()) {
                    case 'HMI':
                      typeIcon = Icons.tablet_android_outlined;
                      break;
                    case 'LED':
                      typeIcon = Icons.lightbulb_outline;
                      break;
                    case 'PANEL':
                      typeIcon = Icons.developer_board;
                      break;
                    case 'LCD':
                      typeIcon = Icons.monitor_outlined;
                      break;
                    default:
                      typeIcon = Icons.settings_input_component_outlined;
                  }

                  return Card(
                    color: const Color(0xFF1E293B),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: const Color(0xFF334155).withValues(alpha: 0.5),
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF334155).withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          typeIcon,
                          color: const Color(0xFF818CF8),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        dev.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'SN: ${dev.serialNumber} • ${dev.type.toUpperCase()}',
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Text(
                          dev.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(String title, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                color: const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SEKME 3: KULLANICI OLUŞTUR ---
  Widget _buildCreateUserTab(AuthProvider authProvider) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Hero(
          tag: 'adminCard',
          child: Card(
            elevation: 12,
            color: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: const Color(0xFF334155).withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 32.0,
              ),
              child: Form(
                key: _userFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Center(
                      child: Icon(
                        Icons.person_add_alt_1_outlined,
                        size: 48,
                        color: Color(0xFF818CF8),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Center(
                      child: Text(
                        'ADD NEW SYSTEM USER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Register a new Admin or Field Staff account',
                        style: TextStyle(
                          color: const Color(0xFF94A3B8).withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    // E-posta
                    TextFormField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'User Email',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          color: Color(0xFF818CF8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF475569),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF818CF8),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(
                          0xFF0F172A,
                        ).withValues(alpha: 0.3),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter user email';
                        }
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Şifre
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
                        prefixIcon: const Icon(
                          Icons.lock_outlined,
                          color: Color(0xFF818CF8),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: const Color(0xFF94A3B8),
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF475569),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF818CF8),
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: const Color(
                          0xFF0F172A,
                        ).withValues(alpha: 0.3),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    // Rol
                    const Text(
                      'ASSIGN ROLE',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRole = 'personnel';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'personnel'
                                    ? const Color(
                                        0xFF818CF8,
                                      ).withValues(alpha: 0.15)
                                    : const Color(
                                        0xFF0F172A,
                                      ).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedRole == 'personnel'
                                      ? const Color(0xFF818CF8)
                                      : const Color(0xFF475569),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.engineering_outlined,
                                    color: _selectedRole == 'personnel'
                                        ? const Color(0xFF818CF8)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Field Personnel',
                                    style: TextStyle(
                                      color: _selectedRole == 'personnel'
                                          ? Colors.white
                                          : const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedRole = 'admin';
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedRole == 'admin'
                                    ? const Color(
                                        0xFF818CF8,
                                      ).withValues(alpha: 0.15)
                                    : const Color(
                                        0xFF0F172A,
                                      ).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _selectedRole == 'admin'
                                      ? const Color(0xFF818CF8)
                                      : const Color(0xFF475569),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.admin_panel_settings_outlined,
                                    color: _selectedRole == 'admin'
                                        ? const Color(0xFF818CF8)
                                        : const Color(0xFF94A3B8),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Administrator',
                                    style: TextStyle(
                                      color: _selectedRole == 'admin'
                                          ? Colors.white
                                          : const Color(0xFF94A3B8),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Gönder
                    authProvider.isLoading
                        ? const Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFF818CF8),
                              ),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () => _handleCreateUser(authProvider),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF818CF8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'REGISTER USER',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
