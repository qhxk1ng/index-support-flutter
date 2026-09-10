import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/navigation/app_navigator.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../customer/presentation/bloc/customer_bloc.dart';
import '../../../customer/presentation/pages/customer_dashboard_page.dart';
import '../../../installer/presentation/pages/installer_home_page.dart';
import '../../../field_personnel/presentation/pages/field_personnel_home_page.dart';
import '../../../sales_personnel/presentation/bloc/sales_personnel_bloc.dart';
import '../../../sales_personnel/presentation/pages/sales_personnel_dashboard_page.dart';
import '../../../admin/presentation/pages/admin_dashboard_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthUnauthenticated,
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          AppNavigator.navigateToLogin();
        }
      },
      buildWhen: (previous, current) {
        if (previous is! AuthAuthenticated && current is AuthAuthenticated) return true;
        if (previous is AuthAuthenticated && current is AuthAuthenticated) {
          // Rebuild dashboard only if activeRole or user ID actually changed
          return previous.user.activeRole != current.user.activeRole ||
                 previous.user.id != current.user.id;
        }
        return false;
      },
      builder: (context, state) {
        if (state is AuthAuthenticated) {
          final activeRole = state.user.activeRole;
          
          switch (activeRole) {
            case UserRole.admin:
              return const AdminDashboardPage();
            case UserRole.customer:
              return BlocProvider(
                create: (_) => sl<CustomerBloc>(),
                child: const CustomerDashboardPage(),
              );
            case UserRole.installer:
              return const InstallerHomePage();
            case UserRole.fieldPersonnel:
              return const FieldPersonnelHomePage();
            case UserRole.salesPersonnel:
              return BlocProvider(
                create: (_) => sl<SalesPersonnelBloc>(),
                child: const SalesPersonnelDashboardPage(),
              );
            default:
              return const _InvalidRoleScreen();
          }
        }
        
        if (state is AuthUnauthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            AppNavigator.navigateToLogin();
          });
        }

        return const Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}

class _InvalidRoleScreen extends StatelessWidget {
  const _InvalidRoleScreen();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Error'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            const Text(
              'Invalid user role',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                context.read<AuthBloc>().add(LogoutEvent());
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
