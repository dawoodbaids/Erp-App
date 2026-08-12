import 'package:get/get.dart';

class ShellController extends GetxController {
  final _tabIndex = 0.obs;

  int get tabIndex => _tabIndex.value;

  void setTab(int index) => _tabIndex.value = index;

  void goToInvoices() => _tabIndex.value = 1;

  void goToProducts() => _tabIndex.value = 2;

  void goToCustomers() => _tabIndex.value = 3;

  void goToSettings() => _tabIndex.value = 4;
}
