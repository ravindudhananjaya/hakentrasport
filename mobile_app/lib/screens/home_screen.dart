
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/app_state.dart';
import 'user_check_in.dart';
import 'admin_panel.dart';
import '../widgets/stats_overview.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text(
                  'TS',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Transport Scheduler',
              style: TextStyle(
                color: Color(0xFF1E293B), // Slate 800
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        actions: [
          _ModeToggleButton(
            label: 'Driver Mode',
            icon: LucideIcons.bus,
            isActive: appState.viewMode == AppViewMode.USER,
            onTap: () => appState.setViewMode(AppViewMode.USER),
          ),
          const SizedBox(width: 8),
          _ModeToggleButton(
            label: 'Admin',
            icon: LucideIcons.shield,
            isActive: appState.viewMode == AppViewMode.ADMIN,
            onTap: () => appState.setViewMode(AppViewMode.ADMIN),
          ),
          const SizedBox(width: 16),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(color: Colors.grey[200], height: 1.0),
        ),
      ),
      body: appState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    _HeaderSection(appState: appState),
                    const SizedBox(height: 24),
                    StatsOverview(employees: appState.employees),
                    const SizedBox(height: 24),
                    appState.viewMode == AppViewMode.ADMIN
                        ? const AdminPanel()
                        : const UserCheckIn(),
                ],
              ),
            ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
    final AppState appState;
    const _HeaderSection({required this.appState});

    @override
    Widget build(BuildContext context) {
         final isAdmin = appState.viewMode == AppViewMode.ADMIN;
         
         return Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             crossAxisAlignment: CrossAxisAlignment.end,
             children: [
                 Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text(
                            isAdmin ? 'Transport Management' : 'Driver Attendance',
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A), // Slate 900
                            ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                            isAdmin 
                              ? 'Manage roster, view statistics, and optimize routes.'
                              : 'Mark passenger attendance and pickup status.',
                             style: const TextStyle(color: Color(0xFF64748B)), // Slate 500
                        ),
                    ],
                 ),
                 if (isAdmin)
                    TextButton.icon(
                        onPressed: () {
                           showDialog(context: context, builder: (ctx) => AlertDialog(
                               title: const Text("Reset Data?"),
                               content: const Text("This cannot be undone."),
                               actions: [
                                   TextButton(onPressed: ()=>Navigator.pop(ctx), child: const Text("Cancel")),
                                   TextButton(
                                       onPressed: () {
                                           appState.resetData();
                                           Navigator.pop(ctx);
                                       }, 
                                       child: const Text("Reset", style: TextStyle(color: Colors.red))
                                   )
                               ]
                           ));
                        },
                        icon: const Icon(LucideIcons.refreshCw, size: 14, color: Colors.grey),
                        label: const Text("Reset Data", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    )
             ],
         );
    }
}

class _ModeToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ModeToggleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: isActive ? (label == 'Admin' ? Theme.of(context).primaryColor : const Color(0xFF1E293B)) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
                children: [
                    Icon(icon, size: 16, color: isActive ? Colors.white : const Color(0xFF475569)),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(
                        fontSize: 13, 
                        fontWeight: FontWeight.w500,
                        color: isActive ? Colors.white : const Color(0xFF475569)
                    ))
                ],
            ),
        ),
    );
  }
}
