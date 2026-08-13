import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import 'app_routes.dart';

class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authenticated = Get.isRegistered<AuthController>() &&
        Get.find<AuthController>().isAuthenticated;
    return authenticated ? null : const RouteSettings(name: AppRoutes.login);
  }
}
