import 'package:flutter/material.dart';
import 'package:photography_flutter_application/viewmodels/admin_profile_viewmodel.dart';
import 'package:photography_flutter_application/views/admin_profile_screen.dart';
import 'package:provider/provider.dart';
import '/views/portfolio_content.dart';
import '/viewmodels/portfolio_view_model.dart';

class Routes {
  static const String portfolioContent = '/portfolio-content';
  static const String adminProfile = '/adminProfile';
  static const String adminSettings = '/adminSettings';
  static const String invoiceList = '/invoiceScreen';
}

class RouteManager {
  static Route<dynamic> getRoute(RouteSettings settings) {
    switch (settings.name) {
      case Routes.portfolioContent:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => PortfolioViewModel(),
            child: const PortfolioContentScreen(),
          ),
        );
        case Routes.adminProfile:
        return MaterialPageRoute(
          builder: (_) => ChangeNotifierProvider(
            create: (_) => AdminProfileViewModel(),
            child: AdminProfileScreen(),
          ),
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route Not Found')),
          ),
        );
    }
  }
}
