import '../core/network/api_client.dart';
import '../core/network/api_config.dart';
import '../models/customer.dart';

class CustomerService {
  Future<List<Customer>> getCustomers() async {
    final data = await ApiClient.getData(ApiConfig.customersPath);
    return (data as List)
        .map((e) => Customer.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Customer> createCustomer(Customer draft) async {
    final data = await ApiClient.postData(
      ApiConfig.customersPath,
      data: draft.toCreateRequest(),
    );
    return Customer.fromJson(data as Map<String, dynamic>);
  }
}
