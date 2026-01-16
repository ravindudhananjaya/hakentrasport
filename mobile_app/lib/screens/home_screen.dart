
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

    void verifyAdminPassword(VoidCallback onSuccess) {
       final passwordController = TextEditingController();
       showDialog(
         context: context,
         builder: (ctx) => AlertDialog(
           title: const Text("Enter Admin Password"),
           content: TextField(
             controller: passwordController,
             obscureText: true,
             autofocus: true,
             decoration: const InputDecoration(
               hintText: "Password",
               border: OutlineInputBorder(),
             ),
           ),
           actions: [
             TextButton(
               onPressed: () => Navigator.pop(ctx),
               child: const Text("Cancel"),
             ),
             ElevatedButton(
               onPressed: () {
                 if (passwordController.text == "1234") {
                   Navigator.pop(ctx);
                   onSuccess();
                 } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text("Incorrect Password!"), backgroundColor: Colors.red),
                   );
                 }
               },
               child: const Text("Login"),
             ),
           ],
         ),
       );
    }

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

          ],
        ),
        actions: [
          _ModeToggleButton(
            label: 'Driver',
            icon: LucideIcons.bus,
            isActive: appState.viewMode == AppViewMode.USER,
            onTap: () => appState.setViewMode(AppViewMode.USER),
          ),
          const SizedBox(width: 8),
          _ModeToggleButton(
            label: 'Admin',
            icon: LucideIcons.shield,
            isActive: appState.viewMode == AppViewMode.ADMIN,
            onTap: () {
                 if (appState.viewMode == AppViewMode.ADMIN) return;
                 verifyAdminPassword(() {
                    appState.setViewMode(AppViewMode.ADMIN);
                 });
            },
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
                 Expanded(
                   child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          Text(
                              isAdmin ? 'Transport Management' : 'Driver Attendance',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A), // Slate 900
                              ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                              isAdmin 
                                ? 'Manage roster, view statistics, and optimize routes.'
                                : 'Mark passenger attendance and pickup status.',
                               maxLines: 2,
                               overflow: TextOverflow.ellipsis,
                               style: const TextStyle(
                                 color: Color(0xFF64748B), // Slate 500
                                 fontSize: 13,
                               ), 
                          ),
                      ],
                   ),
                 ),

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
