import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_invoice_view_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/calendar_service.dart';
import '../views/calendar.dart';
import '../views/date_manager.dart';
import '../views/add_invoice.dart';
import '../views/admin_more.dart';
import '../views/bookings.dart';
import '../views/admin_profile_screen.dart';
import '../views/admin_settings_screen.dart';
import '../views/invoice_list_screen.dart';
import '../views/portfolio_content.dart';
import '../views/service_list_view.dart';
import '../views/clients.dart';
import '../views/portfolio_gallery.dart';
import '../views/admin_dashboard.dart';
import '../views/admin_notifications_screen.dart';

class RouteManager {
  static const calendar = '/calendar',
      bookings = '/bookings',
      profile = '/admin-profile',
      notifications = '/notifications',
      more = '/more',
      portfolioContent = '/portfolio-content',
      clients = '/clients',
      portfolioGallery = '/portfolio-gallery',
      invoices = '/invoices',
      services = '/services',
      addInvoice = '/add-invoice',
      dateManager = '/date-availability';
  // Register only on the authenticated nested Navigator, never publicly.
  static Route<dynamic> getRoute(
    RouteSettings settings, {
    SupabaseClient? client,
  }) {
    final WidgetBuilder builder = switch (settings.name) {
      '/' => (_) => AdminDashboard(),
      calendar => (_) => CalendarScreen(
        service: CalendarService(supabase: client),
      ),
      bookings => (_) => const BookingsScreen(),
      profile => (_) => AdminProfileScreen(),
      notifications => (_) => const AdminNotificationsScreen(),
      more => (_) => const AdminMoreScreen(),
      portfolioContent => (_) => const PortfolioContentScreen(),
      clients => (_) => const ClientsView(),
      portfolioGallery => (_) => const PortfolioGalleryScreen(),
      invoices => (_) => InvoiceListScreen(),
      '/settings' => (_) => AdminSettingsScreen(),
      services => (_) => const ServiceList(),
      addInvoice => (context) => AddInvoiceScreen(
        viewModel: context.read<AddInvoiceViewModel>(),
        initialBookingId: settings.arguments is String
            ? settings.arguments as String
            : null,
      ),
      dateManager =>
        (_) => settings.arguments is DateTime
            ? DateManagerScreen(
                service: CalendarService(supabase: client),
                date: settings.arguments as DateTime,
              )
            : const Scaffold(
                body: Center(child: Text('Choose a date from the calendar.')),
              ),
      _ => (_) => Scaffold(
        appBar: AppBar(title: const Text('Page not found')),
        body: const Center(child: Text('This page is not available.')),
      ),
    };
    return MaterialPageRoute(settings: settings, builder: builder);
  }
}
