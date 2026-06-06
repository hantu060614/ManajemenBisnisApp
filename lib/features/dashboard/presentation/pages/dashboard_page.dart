import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../batches/presentation/providers/batch_provider.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsyncValue = ref.watch(dashboardProvider);
    final authState = ref.watch(authProvider);
    final batchesAsync = ref.watch(batchProvider);
    
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final todayStr = DateFormat('EEEE, dd MMMM yyyy', 'id_ID').format(DateTime.now());

    // Determine first active batch category for IoT display
    final activeCategory = batchesAsync.maybeWhen(
      data: (batches) {
        final active = batches.where((b) => b.isActive).toList();
        return active.isNotEmpty ? active.first.animalCategory : 'Perikanan';
      },
      orElse: () => 'Perikanan',
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardProvider);
          ref.invalidate(batchProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Sliver App Bar
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF0F172A),
              title: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white24,
                    backgroundImage: authState.photoUrl != null && (authState.photoUrl!.startsWith('http') || File(authState.photoUrl!).existsSync())
                        ? (authState.photoUrl!.startsWith('http') ? NetworkImage(authState.photoUrl!) : FileImage(File(authState.photoUrl!))) as ImageProvider
                        : null,
                    child: (authState.photoUrl == null || (!authState.photoUrl!.startsWith('http') && !File(authState.photoUrl!).existsSync())) 
                        ? const Icon(Icons.person, size: 20, color: Colors.white) 
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Selamat Datang,",
                          style: TextStyle(fontSize: 10, color: Colors.white70, fontWeight: FontWeight.normal),
                        ),
                        Text(
                          authState.name ?? 'Peternak',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                ),
              ],
            ),

            // Content
            dashboardAsyncValue.when(
              data: (data) {
                final monthlyProfit = data.incomeThisMonth - data.expenseThisMonth;

                return SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Financial Overview Cards (Wallet Style)
                      Transform.translate(
                        offset: const Offset(0, -20),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Kas Tersedia',
                                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          currencyFormatter.format(data.cashflowBalance),
                                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white10,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.blueAccent, size: 24),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white10, height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Kas Masuk (Bulan ini)', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                        const SizedBox(height: 2),
                                        Text(
                                          currencyFormatter.format(data.incomeThisMonth),
                                          style: const TextStyle(color: Colors.greenAccent, fontSize: 13, fontWeight: FontWeight.bold),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(width: 1, height: 30, color: Colors.white10),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Profit Bersih (Bulan ini)', style: TextStyle(color: Colors.white38, fontSize: 11)),
                                        const SizedBox(height: 2),
                                        Text(
                                          currencyFormatter.format(monthlyProfit),
                                          style: TextStyle(
                                            color: monthlyProfit >= 0 ? Colors.blueAccent : Colors.redAccent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (data.activeBatches == 0)
                        Padding(
                          padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 20.0),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Theme.of(context).colorScheme.secondary),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Belum Ada Siklus Aktif',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Tambahkan unit ternak/kolam pertama Anda untuk memulai pencatatan harian.',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    minimumSize: Size.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  onPressed: () => context.push('/batches/add'),
                                  child: const Text('Tambah', style: TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Asisten Aktivitas Hari Ini (Timeline/Checklist)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Asisten Aktivitas Hari Ini 📋',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  todayStr,
                                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.secondary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.08)),
                              ),
                              child: Column(
                                children: [
                                  _buildActivityItem(
                                    context,
                                    title: 'Jadwal Pakan Pagi',
                                    subtitle: '08:00 WIB',
                                    icon: Icons.light_mode_outlined,
                                    iconColor: Colors.amber,
                                    completed: data.feedOut > 0 || DateTime.now().hour >= 10,
                                  ),
                                  const Divider(height: 16),
                                  _buildActivityItem(
                                    context,
                                    title: 'Jadwal Pakan Siang',
                                    subtitle: '12:00 WIB',
                                    icon: Icons.wb_sunny_outlined,
                                    iconColor: Colors.orange,
                                    completed: DateTime.now().hour >= 14,
                                  ),
                                  const Divider(height: 16),
                                  _buildActivityItem(
                                    context,
                                    title: 'Jadwal Pakan Sore',
                                    subtitle: '17:00 WIB',
                                    icon: Icons.dark_mode_outlined,
                                    iconColor: Colors.indigoAccent,
                                    completed: DateTime.now().hour >= 18,
                                  ),
                                  const Divider(height: 16),
                                  _buildActivityItem(
                                    context,
                                    title: 'Vaksinasi / Sanitasi Unit',
                                    subtitle: 'Mingguan / Bulanan',
                                    icon: Icons.vaccines_outlined,
                                    iconColor: Colors.green,
                                    completed: false,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 6 Grid Menus
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Menu Utama',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              crossAxisCount: 3,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.95,
                              children: [
                                _MenuIcon(
                                  icon: Icons.pets_outlined,
                                  label: 'Unit Ternak',
                                  color: Colors.blueAccent,
                                  onTap: () => context.push('/batches'),
                                ),
                                _MenuIcon(
                                  icon: Icons.restaurant_menu_outlined,
                                  label: 'Pakan',
                                  color: Colors.orangeAccent,
                                  onTap: () => context.push('/feed'),
                                ),
                                _MenuIcon(
                                  icon: Icons.health_and_safety_outlined,
                                  label: 'Kesehatan',
                                  color: Colors.redAccent,
                                  onTap: () => context.push('/health'),
                                ),
                                _MenuIcon(
                                  icon: Icons.insights_outlined,
                                  label: 'Produksi',
                                  color: Colors.tealAccent,
                                  onTap: () => context.push('/production'),
                                ),
                                _MenuIcon(
                                  icon: Icons.account_balance_wallet_outlined,
                                  label: 'Keuangan',
                                  color: Colors.greenAccent,
                                  onTap: () => context.push('/cashflow'),
                                ),
                                _MenuIcon(
                                  icon: Icons.analytics_outlined,
                                  label: 'Analisis Bisnis',
                                  color: Colors.purpleAccent,
                                  onTap: () => context.push('/analytics'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // IoT Sensor Sections (Category Adaptive)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  activeCategory == 'Perikanan'
                                      ? 'Sensor Kualitas Air (IoT) 🌊'
                                      : 'Sensor Kondisi Kandang (IoT) 🏠',
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('Beta', style: TextStyle(fontSize: 9, color: Colors.white38)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: Colors.white.withOpacity(0.05)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.withOpacity(0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.sensors, color: Colors.amber, size: 24),
                                      ),
                                      const SizedBox(width: 16),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Menunggu perangkat IoT terhubung',
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.amber),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'ESP32 / MQTT Gateway offline',
                                              style: TextStyle(fontSize: 12, color: Colors.white38),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20),
                                  if (activeCategory == 'Perikanan') ...[
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _WaterIndicator(label: 'pH Air', value: '--', icon: Icons.water_drop_outlined, color: Colors.blue),
                                        _WaterIndicator(label: 'Suhu Air', value: '-- °C', icon: Icons.thermostat_outlined, color: Colors.red),
                                        _WaterIndicator(label: 'Dissolved O2', value: '-- mg/L', icon: Icons.air, color: Colors.teal),
                                        _WaterIndicator(label: 'TDS Air', value: '-- ppm', icon: Icons.blur_on, color: Colors.orange),
                                      ],
                                    ),
                                  ] else ...[
                                    const Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        _WaterIndicator(label: 'Suhu Kandang', value: '-- °C', icon: Icons.thermostat_outlined, color: Colors.red),
                                        _WaterIndicator(label: 'Kelembaban', value: '-- %', icon: Icons.cloud_outlined, color: Colors.blue),
                                        _WaterIndicator(label: 'Sensor Pakan', value: '-- kg', icon: Icons.restaurant_menu, color: Colors.orange),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ));
                },
                loading: () => const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.redAccent, size: 60),
                          const SizedBox(height: 16),
                          const Text(
                            'Gagal Memuat Data',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              ref.invalidate(dashboardProvider);
                              ref.invalidate(batchProvider);
                            },
                            child: const Text('Coba Lagi'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool completed,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  decoration: completed ? TextDecoration.lineThrough : null,
                  color: completed ? Theme.of(context).colorScheme.secondary.withOpacity(0.5) : null,
                ),
              ),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        Icon(
          completed ? Icons.check_circle : Icons.radio_button_unchecked,
          color: completed ? Colors.green : Colors.grey.withOpacity(0.5),
          size: 24,
        ),
      ],
    );
  }
}

class _MenuIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterIndicator extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _WaterIndicator({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.7), size: 20),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
      ],
    );
  }
}
