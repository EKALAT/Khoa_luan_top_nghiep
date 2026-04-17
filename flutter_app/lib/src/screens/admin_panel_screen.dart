import 'package:flutter/material.dart';

import '../widgets/section_card.dart';
import 'admin_attendance_screen.dart';
import 'admin_monthly_attendance_screen.dart';
import 'admin_users_screen.dart';

class AdminPanelScreen extends StatelessWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0F766E), Color(0xFF115E59)],
                      ),
                      borderRadius: BorderRadius.circular(34),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x26115E59),
                          blurRadius: 22,
                          offset: Offset(0, 14),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trung tam quan tri',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Theo doi tinh hinh cham cong trong ngay va quan ly tai khoan nhan vien trong cung mot khu vuc dieu hanh.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withValues(alpha: 0.82),
                                height: 1.45,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    title: 'Che do quan tri',
                    subtitle:
                        'Chuyen nhanh giua cham cong theo ngay, bang cong thang va quan ly tai khoan.',
                    child: const TabBar(
                      tabs: [
                        Tab(text: 'Trong ngay'),
                        Tab(text: 'Bang cong'),
                        Tab(text: 'Tai khoan'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Expanded(
              child: TabBarView(
                children: [
                  AdminAttendanceScreen(embedded: true),
                  AdminMonthlyAttendanceScreen(embedded: true),
                  AdminUsersScreen(embedded: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
