import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart'; // ✅ WhatsApp ke liye
// ✅ JSON encoding ke liye
import 'package:pdf/pdf.dart'; // ✅ PDF
import 'package:pdf/widgets.dart' as pw; // ✅ PDF Widgets
import 'package:printing/printing.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('authBox');
  await Hive.openBox('settingsBox');
  await Hive.openBox('clientsBox');

  // Default admin account create karenge
  await _createDefaultAdmin();

  runApp(const MyApp());
}

// Default admin account creation
Future<void> _createDefaultAdmin() async {
  final authBox = Hive.box('authBox');
  if (authBox.get('token', defaultValue: '').isEmpty) {
    await authBox.put('token', 'default_admin_token');
    await authBox.put('userRole', 'admin');
    await authBox.put('userName', 'admin');
    await authBox.put('email', 'admin@billingapp.com');
  }
}

// ==================== GETX CONTROLLERS ====================

class AuthController extends GetxController {
  final RxBool isLoading = false.obs;
  final RxString token = ''.obs;
  final RxString userRole = 'user'.obs;
  final RxString userName = ''.obs;
  final RxString email = ''.obs;

  @override
  void onInit() {
    super.onInit();
    checkAutoLogin();
  }

  bool get isLoggedIn => token.value.isNotEmpty;
  bool get isAdmin => userRole.value == 'admin';
  bool get isSubAdmin => userRole.value == 'subadmin';

  Future<void> checkAutoLogin() async {
    isLoading.value = true;

    // Hive se data load karenge
    final authBox = Hive.box('authBox');
    token.value = authBox.get('token', defaultValue: '');
    userRole.value = authBox.get('userRole', defaultValue: 'user');
    userName.value = authBox.get('userName', defaultValue: '');
    email.value = authBox.get('email', defaultValue: '');

    // 2 second wait karenge splash screen ke liye
    await Future.delayed(const Duration(seconds: 2));

    isLoading.value = false;

    // ✅ YEH LINE CHANGE KAREN - Get.offAllNamed ki jagah Get.offAll use karen
    if (isLoggedIn) {
      Get.offAll(() => const ClientSelectionScreen());
    } else {
      Get.offAll(() => LoginScreen());
    }
  }

  Future<bool> login(String email, String password) async {
    isLoading.value = true;

    await Future.delayed(const Duration(seconds: 1));

    bool isValidUser = _checkUserCredentials(email, password);

    if (isValidUser) {
      final authBox = Hive.box('authBox');
      token.value = 'user_token_${DateTime.now().millisecondsSinceEpoch}';
      userRole.value = _getUserRole(email);
      userName.value = _getUserName(email);
      this.email.value = email;

      await authBox.put('token', token.value);
      await authBox.put('userRole', userRole.value);
      await authBox.put('userName', userName.value);
      await authBox.put('email', email);

      isLoading.value = false;
      return true;
    }

    isLoading.value = false;
    return false;
  }

  bool _checkUserCredentials(String email, String password) {
    final users = {
      'admin@billingapp.com': 'admin123',
      'subadmin@billingapp.com': 'subadmin123',
      'user1@billingapp.com': 'user123',
      'user2@billingapp.com': 'user123',
    };
    return users[email] == password;
  }

  String _getUserRole(String email) {
    final roles = {
      'admin@billingapp.com': 'admin',
      'subadmin@billingapp.com': 'subadmin',
      'user1@billingapp.com': 'user',
      'user2@billingapp.com': 'user',
    };
    return roles[email] ?? 'user';
  }

  String _getUserName(String email) {
    final names = {
      'admin@billingapp.com': 'Admin User',
      'subadmin@billingapp.com': 'Sub Admin',
      'user1@billingapp.com': 'Sales Person 1',
      'user2@billingapp.com': 'Sales Person 2',
    };
    return names[email] ?? 'User';
  }

  Future<void> logout() async {
    final authBox = Hive.box('authBox');
    await authBox.clear();

    token.value = '';
    userRole.value = 'user';
    userName.value = '';
    email.value = '';

    Get.offAll(() => LoginScreen());
  }
}

class ThemeController extends GetxController {
  final RxBool isDarkMode = false.obs;
  final RxString currentClient = 'default'.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  void loadSettings() {
    final settingsBox = Hive.box('settingsBox');
    isDarkMode.value = settingsBox.get('isDarkMode', defaultValue: false);
    currentClient.value = settingsBox.get('currentClient', defaultValue: 'default');
  }

  void toggleTheme(bool value) {
    isDarkMode.value = value;
    final settingsBox = Hive.box('settingsBox');
    settingsBox.put('isDarkMode', value);
  }

  void changeClient(String clientId) {
    currentClient.value = clientId;
    final settingsBox = Hive.box('settingsBox');
    settingsBox.put('currentClient', clientId);
  }
}

class ClientController extends GetxController {
  final RxList<Client> clients = <Client>[].obs;
  final RxString currentClientId = 'default'.obs;

  @override
  void onInit() {
    super.onInit();
    loadClients();
    loadCurrentClient();
  }

  void loadCurrentClient() {
    final clientsBox = Hive.box('clientsBox');
    currentClientId.value = clientsBox.get('currentClient', defaultValue: 'default');
  }

  void loadClients() {
    final clientsBox = Hive.box('clientsBox');
    final clientsData = clientsBox.get('clientsList', defaultValue: []);

    if (clientsData.isEmpty) {
      createDefaultClients();
    } else {
      clients.value = _parseClientsFromList(clientsData);
    }
  }

  void createDefaultClients() {
    clients.value = [
      Client(
        id: 'default',
        name: 'Default Client',
        primaryColor: {'r': 33, 'g': 150, 'b': 243},
        shopList: _getDefaultShops(),
        itemList: _getDefaultItems(),
      ),
      Client(
        id: 'client1',
        name: 'Client 1 - SuperMart',
        primaryColor: {'r': 76, 'g': 175, 'b': 80},
        shopList: _getClient1Shops(),
        itemList: _getClient1Items(),
      ),
      Client(
        id: 'client2',
        name: 'Client 2 - MegaStore',
        primaryColor: {'r': 156, 'g': 39, 'b': 176},
        shopList: _getClient2Shops(),
        itemList: _getClient2Items(),
      ),
    ];
    saveClients();
  }

  List<Client> _parseClientsFromList(List<dynamic> clientsData) {
    return clientsData.map<Client>((data) {
      final clientMap = Map<String, dynamic>.from(data as Map<dynamic, dynamic>);
      return Client.fromMap(clientMap);
    }).toList();
  }

  void saveClients() {
    final clientsBox = Hive.box('clientsBox');
    clientsBox.put('clientsList', clients.map((c) => c.toMap()).toList());
  }

  List<Shop> _getDefaultShops() {
    return [
      Shop(id: '1', name: 'Main Store', address: '123 Main St', phone: '0300-1234567', status: 'open'),
      Shop(id: '2', name: 'Branch 1', address: '456 Branch Rd', phone: '0300-7654321', status: 'open'),
    ];
  }

  List<Item> _getDefaultItems() {
    return [
      Item(id: '1', name: 'Sugar', category: 'Grocery', price: 120, tradePrice: 110, unit: 'kg'),
      Item(id: '2', name: 'Rice', category: 'Grocery', price: 180, tradePrice: 160, unit: 'kg'),
    ];
  }

  List<Shop> _getClient1Shops() {
    return [
      Shop(id: '1', name: 'SuperMart Main', address: 'SuperMart Plaza', phone: '0300-1111111', status: 'open'),
      Shop(id: '2', name: 'SuperMart North', address: 'North City Mall', phone: '0300-2222222', status: 'open'),
    ];
  }

  List<Item> _getClient1Items() {
    return [
      Item(id: '1', name: 'Bread', category: 'Bakery', price: 80, tradePrice: 70, unit: 'pack'),
      Item(id: '2', name: 'Milk', category: 'Dairy', price: 120, tradePrice: 100, unit: 'liter'),
    ];
  }

  List<Shop> _getClient2Shops() {
    return [
      Shop(id: '1', name: 'MegaStore Central', address: 'Central Plaza', phone: '0300-3333333', status: 'open'),
      Shop(id: '2', name: 'MegaStore West', address: 'West Point', phone: '0300-4444444', status: 'open'),
    ];
  }

  List<Item> _getClient2Items() {
    return [
      Item(id: '1', name: 'Shirt', category: 'Clothing', price: 1500, tradePrice: 1200, unit: 'piece'),
      Item(id: '2', name: 'Pants', category: 'Clothing', price: 2000, tradePrice: 1800, unit: 'piece'),
    ];
  }

  void switchClient(String clientId) {
    currentClientId.value = clientId;
    final clientsBox = Hive.box('clientsBox');
    clientsBox.put('currentClient', clientId);
  }

  Client getCurrentClient() {
    return clients.firstWhere((client) => client.id == currentClientId.value, orElse: () => clients.first);
  }
}

class ShopController extends GetxController {
  final RxList<ShopOrder> shopOrders = <ShopOrder>[].obs;
  final RxList<DaySchedule> daySchedules = <DaySchedule>[].obs;
  final RxString selectedDay = 'Monday'.obs;

  @override
  void onInit() {
    super.onInit();
    // Default day schedules create karenge
    _createDefaultSchedules();
  }

  void _createDefaultSchedules() {
    daySchedules.value = [
      DaySchedule(day: 'Monday', shopIds: ['1', '2']),
      DaySchedule(day: 'Tuesday', shopIds: ['1', '2', '3']),
      DaySchedule(day: 'Wednesday', shopIds: ['1', '3']),
      DaySchedule(day: 'Thursday', shopIds: ['2', '3']),
      DaySchedule(day: 'Friday', shopIds: ['1', '2', '3']),
      DaySchedule(day: 'Saturday', shopIds: ['1']),
      DaySchedule(day: 'Sunday', shopIds: []), // Sunday off
    ];
  }

  // Selected day ke hisab se shop list get karega
  List<Shop> getShopsForSelectedDay() {
    final schedule = daySchedules.firstWhere(
      (schedule) => schedule.day == selectedDay.value,
      orElse: () => DaySchedule(day: selectedDay.value, shopIds: []),
    );

    final clientController = Get.find<ClientController>();
    final currentClient = clientController.getCurrentClient();

    return currentClient.shopList.where((shop) => schedule.shopIds.contains(shop.id)).toList();
  }

  // Shop status update karega
  void updateShopStatus(String shopId, String status) {
    final existingIndex = shopOrders.indexWhere((order) => order.shopId == shopId);

    if (existingIndex != -1) {
      shopOrders[existingIndex].status = status;
      shopOrders[existingIndex].updatedAt = DateTime.now();
    } else {
      shopOrders.add(
        ShopOrder(shopId: shopId, status: status, items: [], createdAt: DateTime.now(), updatedAt: DateTime.now()),
      );
    }
  }

  // Day schedule update karega
  void updateDaySchedule(String day, List<String> shopIds) {
    final index = daySchedules.indexWhere((schedule) => schedule.day == day);
    if (index != -1) {
      daySchedules[index] = DaySchedule(day: day, shopIds: shopIds);
    } else {
      daySchedules.add(DaySchedule(day: day, shopIds: shopIds));
    }
  }

  // Current day ke liye shop order get karega
  ShopOrder getShopOrder(String shopId) {
    return shopOrders.firstWhere(
      (order) => order.shopId == shopId,
      orElse: () =>
          ShopOrder(shopId: shopId, status: 'pending', items: [], createdAt: DateTime.now(), updatedAt: DateTime.now()),
    );
  }
}

class OrderController extends GetxController {
  final RxList<OrderItem> cartItems = <OrderItem>[].obs;
  final RxList<Invoice> invoices = <Invoice>[].obs;
  final RxString selectedCategory = 'All'.obs;
  final RxString searchQuery = ''.obs;
  final RxString selectedShopId = ''.obs;
  final RxString selectedShopName = ''.obs;

  

  double get cartTotal {
    return cartItems.fold(0, (total, item) => total + (item.item.tradePrice * item.quantity));
  }

  // ✅ Missing methods add karein
  void increaseQuantity(String itemId) {
    final index = cartItems.indexWhere((item) => item.item.id == itemId);
    if (index != -1) {
      cartItems[index].quantity += 1;
    }
  }

  void decreaseQuantity(String itemId) {
    final index = cartItems.indexWhere((item) => item.item.id == itemId);
    if (index != -1) {
      if (cartItems[index].quantity > 1) {
        cartItems[index].quantity -= 1;
      } else {
        cartItems.removeAt(index);
      }
    }
  }

  // Category change karega
  void setCategory(String category) {
    selectedCategory.value = category;
  }

  // Search query set karega
  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  // Selected shop set karega
  void setSelectedShop(String shopId, String shopName) {
    selectedShopId.value = shopId;
    selectedShopName.value = shopName;
    clearCart(); // New shop select karne par cart clear ho jayega
  }

  // Cart mein item add karega
  void addToCart(Item item, int quantity) {
    final existingIndex = cartItems.indexWhere((cartItem) => cartItem.item.id == item.id);

    if (existingIndex != -1) {
      cartItems[existingIndex].quantity += quantity;
    } else {
      cartItems.add(OrderItem(item: item, quantity: quantity));
    }
  }

  // Cart se item remove karega
  void removeFromCart(String itemId) {
    cartItems.removeWhere((item) => item.item.id == itemId);
  }

  // Quantity update karega
  void updateQuantity(String itemId, int quantity) {
    final index = cartItems.indexWhere((item) => item.item.id == itemId);
    if (index != -1) {
      cartItems[index].quantity = quantity;
      if (cartItems[index].quantity <= 0) {
        cartItems.removeAt(index);
      }
    }
  }

  // Cart clear karega
  void clearCart() {
    cartItems.clear();
  }

  // ✅ COMPLETE Invoice generate method
  void generateInvoice() {
    if (selectedShopId.value.isEmpty) {
      Get.snackbar('Error', 'Please select a shop first!', backgroundColor: Colors.red);
      return;
    }

    try {
      final invoice = Invoice(
        id: 'INV-${DateTime.now().millisecondsSinceEpoch}',
        shopId: selectedShopId.value,
        shopName: selectedShopName.value,
        items: List.from(cartItems), // ✅ Copy create karein
        totalAmount: cartTotal,
        date: DateTime.now(),
        status: 'completed',
      );

      invoices.add(invoice);
      
      // ✅ Debug ke liye print karein
      print('=== INVOICE GENERATED ===');
      print('Invoice ID: ${invoice.id}');
      print('Shop: ${invoice.shopName}');
      print('Total Amount: ₹${invoice.totalAmount}');
      print('Items: ${invoice.items.length}');
      print('Total invoices now: ${invoices.length}');

      // Shop order update karenge
      final shopController = Get.find<ShopController>();
      shopController.updateShopStatus(selectedShopId.value, 'ordered');

      // Cart clear karein
      clearCart();

      // Success notification
      Get.snackbar(
        'Success ✅', 
        'Order saved successfully!\nInvoice: ${invoice.id}',
        backgroundColor: Colors.green, 
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
      );

      // ✅ Notification service call karein
      NotificationService.showOrderNotification(invoice.shopName, invoice.totalAmount);

      // ✅ Force UI update
      update();

    } catch (e) {
      print('Error generating invoice: $e');
      Get.snackbar('Error', 'Failed to generate invoice: $e', backgroundColor: Colors.red);
    }
  }

  // Filtered items get karega
  List<Item> getFilteredItems(List<Item> allItems) {
    var filtered = allItems;

    // Category filter
    if (selectedCategory.value != 'All') {
      filtered = filtered.where((item) => item.category == selectedCategory.value).toList();
    }

    // Search filter
    if (searchQuery.value.isNotEmpty) {
      filtered = filtered
          .where(
            (item) =>
                item.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
                item.category.toLowerCase().contains(searchQuery.value.toLowerCase()),
          )
          .toList();
    }

    return filtered;
  }

  // ✅ Getter add karein reports ke liye
  List<Invoice> get allInvoices => invoices.toList();
  
  double get totalRevenue {
    return invoices.fold(0.0, (sum, invoice) => sum + invoice.totalAmount);
  }
  
  int get totalOrders => invoices.length;

  // ✅ Today's orders count
  int get todaysOrders {
    final today = DateTime.now();
    return invoices.where((invoice) => 
      invoice.date.year == today.year &&
      invoice.date.month == today.month &&
      invoice.date.day == today.day
    ).length;
  }
}

// ==================== DATA MODELS ====================

class Client {
  final String id;
  final String name;
  final Map<String, int> primaryColor;
  final List<Shop> shopList;
  final List<Item> itemList;

  Client({
    required this.id,
    required this.name,
    required this.primaryColor,
    required this.shopList,
    required this.itemList,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'primaryColor': primaryColor,
      'shopList': shopList.map((shop) => shop.toMap()).toList(),
      'itemList': itemList.map((item) => item.toMap()).toList(),
    };
  }

  // ✅ YEH fromMap FACTORY CONSTRUCTOR ADD KAREN
  factory Client.fromMap(Map<String, dynamic> map) {
    // Safely convert primaryColor
    final primaryColorMap = map['primaryColor'] as Map<dynamic, dynamic>;
    final primaryColor = <String, int>{};
    primaryColorMap.forEach((key, value) {
      primaryColor[key.toString()] = value as int;
    });

    // Safely convert shopList
    final shopListData = map['shopList'] as List<dynamic>;
    final shopList = shopListData.map<Shop>((shopData) {
      return Shop.fromMap(Map<String, dynamic>.from(shopData as Map<dynamic, dynamic>));
    }).toList();

    // Safely convert itemList
    final itemListData = map['itemList'] as List<dynamic>;
    final itemList = itemListData.map<Item>((itemData) {
      return Item.fromMap(Map<String, dynamic>.from(itemData as Map<dynamic, dynamic>));
    }).toList();

    return Client(
      id: map['id'] as String,
      name: map['name'] as String,
      primaryColor: primaryColor,
      shopList: shopList,
      itemList: itemList,
    );
  }
}

class Shop {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String status;

  Shop({required this.id, required this.name, required this.address, required this.phone, required this.status});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'address': address, 'phone': phone, 'status': status};
  }

  // ✅ fromMap factory constructor
  factory Shop.fromMap(Map<String, dynamic> map) {
    return Shop(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      phone: map['phone'] as String,
      status: map['status'] as String,
    );
  }
}

class Item {
  final String id;
  final String name;
  final String category;
  final double price;
  final double tradePrice;
  final String unit;

  Item({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.tradePrice,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'category': category, 'price': price, 'tradePrice': tradePrice, 'unit': unit};
  }

  // ✅ fromMap factory constructor
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as String,
      name: map['name'] as String,
      category: map['category'] as String,
      price: (map['price'] as num).toDouble(),
      tradePrice: (map['tradePrice'] as num).toDouble(),
      unit: map['unit'] as String,
    );
  }
}

class ShopOrder {
  String shopId;
  String status; // pending, ordered, closed, refused, no-order
  List<OrderItem> items;
  DateTime createdAt;
  DateTime updatedAt;

  ShopOrder({
    required this.shopId,
    required this.status,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });
}

class OrderItem {
  Item item;
  int quantity;

  OrderItem({required this.item, required this.quantity});

  double get totalPrice => item.tradePrice * quantity;

  // ✅ toMap method add karein
  Map<String, dynamic> toMap() {
    return {
      'item': item.toMap(),
      'quantity': quantity,
    };
  }
}

class Invoice {
  String id;
  String shopId;
  String shopName;
  List<OrderItem> items;
  double totalAmount;
  DateTime date;
  String status;

  Invoice({
    required this.id,
    required this.shopId,
    required this.shopName,
    required this.items,
    required this.totalAmount,
    required this.date,
    required this.status,
  });

  // ✅ toMap method add karein
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'shopId': shopId,
      'shopName': shopName,
      'items': items.map((item) => {
        'item': item.item.toMap(),
        'quantity': item.quantity,
      }).toList(),
      'totalAmount': totalAmount,
      'date': date.toIso8601String(),
      'status': status,
    };
  }
}
class DaySchedule {
  String day;
  List<String> shopIds;

  DaySchedule({required this.day, required this.shopIds});
}

// ==================== GETX SCREENS ====================

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade700,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FlutterLogo(size: 100),
            const SizedBox(height: 20),
            const Text(
              'BILLING APP',
              style: TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('GetX Version', style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 20),
            Obx(() {
              final authController = Get.find<AuthController>();
              return authController.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Loading...', style: TextStyle(color: Colors.white));
            }),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Login'), backgroundColor: Colors.blue.shade700),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 25),
            Obx(
              () => SizedBox(
                width: double.infinity,
                height: 50,
                child: authController.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () async {
                          final success = await authController.login(emailController.text, passwordController.text);

                          if (success) {
                            Get.offAll(() => const ClientSelectionScreen());
                          } else {
                            Get.snackbar(
                              'Error',
                              'Login failed! Check your credentials',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
                        child: const Text('LOGIN', style: TextStyle(fontSize: 16)),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ClientSelectionScreen extends StatelessWidget {
  const ClientSelectionScreen({super.key});

  Color _getColorFromMap(Map<String, int> colorMap) {
    return Color.fromRGBO(colorMap['r']!, colorMap['g']!, colorMap['b']!, 1);
  }

  @override
  Widget build(BuildContext context) {
    final clientController = Get.find<ClientController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Select Client'), backgroundColor: Colors.blue.shade700),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Choose Your Client', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text('Same code, different clients with their own data'),
            const SizedBox(height: 20),
            Obx(
              () => Expanded(
                child: ListView.builder(
                  itemCount: clientController.clients.length,
                  itemBuilder: (context, index) {
                    final client = clientController.clients[index];
                    final primaryColor = _getColorFromMap(client.primaryColor);

                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: primaryColor,
                          child: Text(
                            client.name[0],
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${client.shopList.length} Shops • ${client.itemList.length} Items'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          clientController.switchClient(client.id);
                          Get.offAll(() => const DashboardScreen());
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final clientController = Get.find<ClientController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          final currentClient = clientController.getCurrentClient();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome, ${authController.userName.value}'),
              Text(
                currentClient.name,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          );
        }),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => authController.logout(),
          ),
        ],
      ),
      body: Obx(() {
        final gridItems = [
          GridItem('Shop List', Icons.store, Colors.blue, '/shopList'),
          GridItem('Billing', Icons.receipt, Colors.green, '/billing'),
          GridItem('Invoices', Icons.description, Colors.orange, '/invoices'),
          GridItem('Reports', Icons.analytics, Colors.purple, '/reports'),
          GridItem('Items', Icons.inventory_2, Colors.teal, '/items'),
          if (authController.isAdmin || authController.isSubAdmin)
            GridItem('Users', Icons.people, Colors.red, '/users'),
          GridItem('Clients', Icons.switch_account, Colors.indigo, '/clientSelection'),
          GridItem('Settings', Icons.settings, Colors.grey, '/settings'),
        ];

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: gridItems.length,
          itemBuilder: (context, index) {
            final item = gridItems[index];
            return Card(
              elevation: 4,
              child: InkWell(
                onTap: () {
                  _handleGridItemTap(item.title, authController);
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 40, color: item.color),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }

  // ✅ Separate method for handling grid item taps
  void _handleGridItemTap(String title, AuthController authController) {
    switch (title) {
      case 'Shop List':
        Get.to(() => const ShopListScreen());
        break;
      case 'Billing':
        Get.to(() => BillingScreen());
        break;
      case 'Invoices':
        Get.to(() => const InvoiceScreen());
        break;
      case 'Reports': // ✅ YEH ADD KAREN
        Get.to(() => const ReportsScreen());
        break;
      case 'Items':
        Get.to(() => const ItemsScreen());
        break;
      case 'Users':
        if (authController.isAdmin || authController.isSubAdmin) {
          Get.to(() => UserManagementScreen());
        }
        break;
      case 'Clients':
        Get.to(() => const ClientSelectionScreen());
        break;
      case 'Settings':
        Get.to(() => const SettingsScreen());
        break;
      default:
        Get.snackbar(
          'Coming Soon',
          '$title screen is under development',
          backgroundColor: Colors.blue,
          colorText: Colors.white,
        );
    }
  }
}
class ItemsScreen extends StatelessWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final clientController = Get.find<ClientController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Items Management'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Obx(() {
        final items = clientController.getCurrentClient().itemList;
        
        return ListView.builder(
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: const Icon(Icons.inventory_2, size: 20),
                ),
                title: Text(item.name),
                subtitle: Text('${item.category} • ₹${item.tradePrice} per ${item.unit}'),
                trailing: Text(
                  '₹${item.price}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class ShopListScreen extends StatelessWidget {
  const ShopListScreen({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'ordered':
        return Colors.green;
      case 'closed':
        return Colors.orange;
      case 'no-order':
        return Colors.grey;
      case 'refused':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'ordered':
        return Icons.check_circle;
      case 'closed':
        return Icons.close;
      case 'no-order':
        return Icons.do_not_disturb;
      case 'refused':
        return Icons.cancel;
      default:
        return Icons.pending;
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopController = Get.find<ShopController>();
    final orderController = Get.find<OrderController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop List'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(icon: const Icon(Icons.calendar_today), onPressed: () => _showDaySelectionDialog(shopController)),
        ],
      ),
      body: Column(
        children: [
          // Day selector
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey.shade100,
            child: Obx(
              () => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Shops for ${shopController.selectedDay.value}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Chip(
                    label: Text('${shopController.getShopsForSelectedDay().length} Shops'),
                    backgroundColor: Colors.blue.shade100,
                  ),
                ],
              ),
            ),
          ),
          // Shop list
          Expanded(
            child: Obx(() {
              final shops = shopController.getShopsForSelectedDay();

              return ListView.builder(
                itemCount: shops.length,
                itemBuilder: (context, index) {
                  final shop = shops[index];
                  final shopOrder = shopController.getShopOrder(shop.id);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    elevation: 4,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(shopOrder.status),
                        child: Icon(_getStatusIcon(shopOrder.status), color: Colors.white),
                      ),
                      title: Text(shop.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(shop.address),
                          Text(shop.phone),
                          const SizedBox(height: 4),
                          Chip(
                            label: Text(
                              shopOrder.status.toUpperCase(),
                              style: const TextStyle(fontSize: 12, color: Colors.white),
                            ),
                            backgroundColor: _getStatusColor(shopOrder.status),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        _showShopOptionsDialog(shop, shopController, orderController);
                      },
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  void _showShopOptionsDialog(Shop shop, ShopController shopController, OrderController orderController) {
    Get.dialog(
      AlertDialog(
        title: Text('${shop.name} - Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOptionButton('Create Bill', Icons.receipt, Colors.blue, () {
              Get.back();
              orderController.setSelectedShop(shop.id, shop.name);
              Get.to(() => BillingScreen());
            }),
            _buildOptionButton('Close Shop', Icons.close, Colors.orange, () {
              shopController.updateShopStatus(shop.id, 'closed');
              Get.back();
              Get.snackbar(
                'Success',
                '${shop.name} marked as closed',
                backgroundColor: Colors.orange,
                colorText: Colors.white,
              );
            }),
            _buildOptionButton('No Order', Icons.do_not_disturb, Colors.grey, () {
              shopController.updateShopStatus(shop.id, 'no-order');
              Get.back();
              Get.snackbar(
                'Success',
                '${shop.name} marked as no order',
                backgroundColor: Colors.grey,
                colorText: Colors.white,
              );
            }),
            _buildOptionButton('Refuse Order', Icons.cancel, Colors.red, () {
              shopController.updateShopStatus(shop.id, 'refused');
              Get.back();
              Get.snackbar(
                'Success',
                '${shop.name} marked as refused',
                backgroundColor: Colors.red,
                colorText: Colors.white,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _showDaySelectionDialog(ShopController shopController) {
    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    Get.dialog(
      AlertDialog(
        title: const Text('Select Day'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: days.map((day) {
            return Obx(
              () => ListTile(
                title: Text(day),
                trailing: day == shopController.selectedDay.value ? const Icon(Icons.check, color: Colors.green) : null,
                onTap: () {
                  shopController.selectedDay.value = day;
                  Get.back();
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class BillingScreen extends StatelessWidget {
  BillingScreen({super.key});

  final TextEditingController searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final orderController = Get.find<OrderController>();
    final clientController = Get.find<ClientController>();

    return Scaffold(
      appBar: AppBar(
        title: Obx(() {
          if (orderController.selectedShopName.value.isEmpty) {
            return const Text('Billing - Select Shop');
          }
          return Text('Billing - ${orderController.selectedShopName.value}');
        }),
        backgroundColor: Colors.blue.shade700,
        // BillingScreen ke AppBar actions mein yeh add karen
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => _showSearchDialog(orderController)),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showAdvancedSearchDialog(orderController, clientController),
          ),
          IconButton(
            icon: Badge(
              label: Obx(() => Text(orderController.cartItems.length.toString())),
              child: const Icon(Icons.shopping_cart),
            ),
            onPressed: () => _showCartDialog(orderController),
          ),
        ],
      ),
      body: Obx(() {
        if (orderController.selectedShopId.value.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.store, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('Please select a shop first', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Go to Shop List and select a shop', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final currentClient = clientController.getCurrentClient();
        final filteredItems = orderController.getFilteredItems(currentClient.itemList);

        return Column(
          children: [
            // Category Chips
            _buildCategoryChips(orderController, clientController),
            // Items Grid
            Expanded(
              child: filteredItems.isEmpty
                  ? const Center(
                      child: Text('No items found', style: TextStyle(fontSize: 18, color: Colors.grey)),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildItemCard(item, orderController);
                      },
                    ),
            ),
            // Cart Summary
            _buildCartSummary(orderController),
          ],
        );
      }),
    );
  }

  Widget _buildCategoryChips(OrderController orderController, ClientController clientController) {
    return Obx(() {
      final currentClient = clientController.getCurrentClient();
      final categories = ['All', ...currentClient.itemList.map((item) => item.category).toSet().toList()];

      return Container(
        padding: const EdgeInsets.all(16),
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: orderController.selectedCategory.value == category,
                onSelected: (selected) {
                  orderController.setCategory(selected ? category : 'All');
                },
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildItemCard(Item item, OrderController orderController) {
  return Obx(() {
    final cartItem = orderController.cartItems.firstWhere(
      (cartItem) => cartItem.item.id == item.id,
      orElse: () => OrderItem(item: item, quantity: 0),
    );

    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => _showItemDialog(item, orderController),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Item Image/Icon
            Container(
              height: 100,
              color: Colors.blue.shade50,
              child: Icon(Icons.inventory_2, size: 40, color: Colors.blue.shade700),
            ),
            // Item Details
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${item.tradePrice}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  Text(
                    item.category,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  // ✅ FIXED Quantity Controls
                  if (cartItem.quantity > 0)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove, size: 18),
                            onPressed: () {
                              orderController.decreaseQuantity(item.id);
                            },
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Text(
                              cartItem.quantity.toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, size: 18),
                            onPressed: () {
                              orderController.increaseQuantity(item.id);
                            },
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      child: ElevatedButton(
                        onPressed: () {
                          orderController.addToCart(item, 1);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 30),
                        ),
                        child: const Text(
                          'Add to Cart',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  });
}

  Widget _buildCartSummary(OrderController orderController) {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${orderController.cartItems.length} Items', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  'Total: ₹${orderController.cartTotal.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: orderController.cartItems.isEmpty ? null : orderController.generateInvoice,
              icon: const Icon(Icons.save),
              label: const Text('Save Order'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

 void _showItemDialog(Item item, OrderController orderController) {
  Get.dialog(
    AlertDialog(
      title: Text(item.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Price'),
            subtitle: Text('₹${item.tradePrice} per ${item.unit}'),
          ),
          ListTile(
            title: const Text('Category'),
            subtitle: Text(item.category),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final cartItem = orderController.cartItems.firstWhere(
              (cartItem) => cartItem.item.id == item.id,
              orElse: () => OrderItem(item: item, quantity: 0),
            );

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ✅ FIXED: Decrease Button
                IconButton(
                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                  iconSize: 30,
                  onPressed: () {
                    if (cartItem.quantity > 0) {
                      orderController.decreaseQuantity(item.id);
                    }
                  },
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    cartItem.quantity.toString(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                // ✅ FIXED: Increase Button
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  iconSize: 30,
                  onPressed: () {
                    orderController.increaseQuantity(item.id);
                  },
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          Text(
            'Total: ₹${(item.tradePrice * (orderController.cartItems.firstWhere(
              (cartItem) => cartItem.item.id == item.id,
              orElse: () => OrderItem(item: item, quantity: 0),
            ).quantity)).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: () {
            if (orderController.cartItems.any((cartItem) => cartItem.item.id == item.id)) {
              // Item already in cart
              Get.back();
            } else {
              // Add item to cart
              orderController.addToCart(item, 1);
              Get.back();
            }
          },
          child: const Text('Add to Cart'),
        ),
      ],
    ),
  );
}

  void _showSearchDialog(OrderController orderController) {
    searchController.text = orderController.searchQuery.value;

    Get.dialog(
      AlertDialog(
        title: const Text('Search Items'),
        content: TextField(
          controller: searchController,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Enter item name...'),
          onChanged: (value) => orderController.setSearchQuery(value),
        ),
        actions: [
          TextButton(
            onPressed: () {
              orderController.setSearchQuery('');
              searchController.clear();
              Get.back();
            },
            child: const Text('Clear'),
          ),
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

 void _showCartDialog(OrderController orderController) {
  Get.bottomSheet(
    Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Cart Items',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Obx(() {
            if (orderController.cartItems.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Cart is empty',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }
            
            return Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: orderController.cartItems.length,
                itemBuilder: (context, index) {
                  final cartItem = orderController.cartItems[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade50,
                      child: const Icon(Icons.inventory_2, size: 20),
                    ),
                    title: Text(cartItem.item.name),
                    subtitle: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove, size: 16),
                          onPressed: () {
                            orderController.decreaseQuantity(cartItem.item.id);
                          },
                        ),
                        Text('${cartItem.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add, size: 16),
                          onPressed: () {
                            orderController.increaseQuantity(cartItem.item.id);
                          },
                        ),
                        Text('× ₹${cartItem.item.tradePrice}'),
                      ],
                    ),
                    trailing: Text('₹${cartItem.totalPrice.toStringAsFixed(2)}'),
                  );
                },
              ),
            );
          }),
          const SizedBox(height: 16),
          // ... rest of cart summary
        ],
      ),
    ),
  );
}

  // Yeh method BillingScreen class ke andar add karen
  void _showAdvancedSearchDialog(OrderController orderController, ClientController clientController) {
    final categories = clientController.getCurrentClient().itemList.map((item) => item.category).toSet().toList();
    final selectedCategory = orderController.selectedCategory; // ✅ RxString directly use karen
    final minPrice = 0.0.obs;
    final maxPrice = 10000.0.obs;

    Get.dialog(
      AlertDialog(
        title: const Text('Advanced Search'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Search by name', prefixIcon: Icon(Icons.search)),
                onChanged: orderController.setSearchQuery,
              ),
              const SizedBox(height: 16),
              Obx(
                () => DropdownButtonFormField<String>(
                  value: selectedCategory.value,
                  items: [
                    'All',
                    ...categories,
                  ].map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                  onChanged: (value) {
                    orderController.setCategory(value!);
                  },
                  decoration: const InputDecoration(labelText: 'Category'),
                ),
              ),
              const SizedBox(height: 16),
              const Text('Price Range:'),
              Obx(
                () => RangeSlider(
                  values: RangeValues(minPrice.value, maxPrice.value),
                  min: 0,
                  max: 10000,
                  divisions: 100,
                  labels: RangeLabels('₹${minPrice.value.toInt()}', '₹${maxPrice.value.toInt()}'),
                  onChanged: (values) {
                    minPrice.value = values.start;
                    maxPrice.value = values.end;
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              orderController.setSearchQuery('');
              orderController.setCategory('All');
              Get.back();
            },
            child: const Text('Reset'),
          ),
          TextButton(onPressed: () => Get.back(), child: const Text('Apply')),
        ],
      ),
    );
  }
}

class GridItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  GridItem(this.title, this.icon, this.color, this.route);
}

// ==================== MAIN GETX APP ====================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Billing App - GETX',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
      initialBinding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController(), fenix: true);
        Get.lazyPut<ClientController>(() => ClientController(), fenix: true);
        Get.lazyPut<ShopController>(() => ShopController(), fenix: true);
        Get.lazyPut<OrderController>(() => OrderController(), fenix: true);
      }),
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderController = Get.find<OrderController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              orderController.update(); // Force refresh
              Get.snackbar('Refreshed', 'Reports updated', backgroundColor: Colors.blue);
            },
          ),
          // ✅ Debug button add karein
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              _showDebugInfo(orderController);
            },
          ),
        ],
      ),
      body: Obx(() {
        final totalInvoices = orderController.invoices.length;
        final totalRevenue = orderController.totalRevenue;
        final averageOrderValue = totalInvoices > 0 ? totalRevenue / totalInvoices : 0;
        final todaysOrders = orderController.todaysOrders;

        return Column(
          children: [
            // Summary Cards
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Orders',
                          totalInvoices.toString(),
                          Icons.receipt,
                          Colors.blue,
                          'All time orders',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          'Total Revenue',
                          '₹${totalRevenue.toStringAsFixed(2)}',
                          Icons.currency_rupee,
                          Colors.green,
                          'Total earnings',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          'Avg Order',
                          '₹${averageOrderValue.toStringAsFixed(2)}',
                          Icons.trending_up,
                          Colors.orange,
                          'Per order average',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          "Today's Orders",
                          todaysOrders.toString(),
                          Icons.today,
                          Colors.purple,
                          'Orders today',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ✅ Invoice List Section
            if (orderController.invoices.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text(
                      'Recent Invoices',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Spacer(),
                    Text(
                      'Total: ',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: orderController.invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = orderController.invoices[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green,
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          '${invoice.shopName}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Invoice: ${invoice.id}'),
                            Text('Date: ${DateFormat('dd/MM/yy').format(invoice.date)}'),
                            Text('Items: ${invoice.items.length}'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '₹${invoice.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${invoice.items.length} items',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              // ✅ Empty State
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'No Reports Yet',
                        style: TextStyle(fontSize: 20, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Create some orders to see reports here',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Get.to(() => const ShopListScreen());
                        },
                        child: const Text('Create Your First Order'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      }),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color, String subtitle) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: const TextStyle(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ Debug info dialog
  void _showDebugInfo(OrderController orderController) {
    Get.dialog(
      AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Invoices: ${orderController.invoices.length}'),
              Text('Total Revenue: ₹${orderController.totalRevenue.toStringAsFixed(2)}'),
              Text("Today's Orders: ${orderController.todaysOrders}"),
              const SizedBox(height: 16),
              const Text('Invoice Details:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...orderController.invoices.map((invoice) => 
                Text('• ${invoice.id} - ${invoice.shopName} - ₹${invoice.totalAmount}')
              ).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class UserManagementScreen extends StatelessWidget {
  UserManagementScreen({super.key});

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final RxString selectedRole = 'user'.obs;

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    // Security check - sirf admin access de sakta hai
    if (!authController.isAdmin) {
      return const Scaffold(body: Center(child: Text('Access Denied - Admin Only')));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('User Management'), backgroundColor: Colors.blue.shade700),
      floatingActionButton: FloatingActionButton(onPressed: () => _showAddUserDialog(), child: const Icon(Icons.add)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Manage Users', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            // Demo users list
            Expanded(
              child: ListView(
                children: [
                  _buildUserCard('Admin User', 'admin@billingapp.com', 'admin'),
                  _buildUserCard('Sub Admin', 'subadmin@billingapp.com', 'subadmin'),
                  _buildUserCard('Sales Person 1', 'user1@billingapp.com', 'user'),
                  _buildUserCard('Sales Person 2', 'user2@billingapp.com', 'user'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserCard(String name, String email, String role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getRoleColor(role),
          child: Text(name[0], style: const TextStyle(color: Colors.white)),
        ),
        title: Text(name),
        subtitle: Text(email),
        trailing: Chip(label: Text(role.toUpperCase()), backgroundColor: _getRoleColor(role).withOpacity(0.2)),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.red;
      case 'subadmin':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _showAddUserDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Add New User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
            ),
            const SizedBox(height: 16),
            Obx(
              () => DropdownButtonFormField<String>(
                value: selectedRole.value,
                items: [
                  'user',
                  'subadmin',
                ].map((role) => DropdownMenuItem(value: role, child: Text(role.toUpperCase()))).toList(),
                onChanged: (value) => selectedRole.value = value!,
                decoration: const InputDecoration(labelText: 'Role'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // Add user logic
              Get.back();
              Get.snackbar(
                'Success',
                'User added successfully',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
              // Clear fields
              nameController.clear();
              emailController.clear();
              passwordController.clear();
            },
            child: const Text('Add User'),
          ),
        ],
      ),
    );
  }
}

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final orderController = Get.find<OrderController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Invoices'), backgroundColor: Colors.blue.shade700),
      body: Obx(() {
        if (orderController.invoices.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.receipt, size: 60, color: Colors.grey),
                SizedBox(height: 16),
                Text('No invoices yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
                SizedBox(height: 8),
                Text('Create bills to see invoices here', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: orderController.invoices.length,
          itemBuilder: (context, index) {
            final invoice = orderController.invoices[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: Colors.green, child: Text(invoice.id.substring(0, 2))),
                title: Text('Invoice: ${invoice.id}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Shop: ${invoice.shopName}'),
                    Text('Amount: ₹${invoice.totalAmount.toStringAsFixed(2)}'),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Get.dialog(
                    AlertDialog(
                      title: Text('Invoice ${invoice.id}'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(title: const Text('Shop Name'), subtitle: Text(invoice.shopName)),
                            ListTile(
                              title: const Text('Total Amount'),
                              subtitle: Text('₹${invoice.totalAmount.toStringAsFixed(2)}'),
                            ),
                            const Divider(),
                            const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                            ...invoice.items
                                .map(
                                  (item) => ListTile(
                                    leading: const Icon(Icons.inventory_2),
                                    title: Text(item.item.name),
                                    subtitle: Text('${item.quantity} x ₹${item.item.tradePrice}'),
                                    trailing: Text('₹${item.totalPrice.toStringAsFixed(2)}'),
                                  ),
                                )
                                .toList(),
                          ],
                        ),
                      ),
                      // InvoiceScreen ke dialog actions mein PDF button add karen
                      actions: [
                        TextButton(onPressed: () => Get.back(), child: const Text('Close')),
                        ElevatedButton(
                          onPressed: () {
                            PDFInvoiceService.generateInvoicePDF(invoice);
                            Get.back();
                          },
                          child: const Text('Generate PDF'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      }),
    );
  }
}

// whatsapp_service.dart - New File

class WhatsAppService {
  static Future<void> shareInvoice(Invoice invoice) async {
    final message =
        '''
*INVOICE ${invoice.id}*

*Shop:* ${invoice.shopName}
*Date:* ${DateFormat('dd/MM/yyyy').format(invoice.date)}
*Total:* ₹${invoice.totalAmount.toStringAsFixed(2)}

*Items:*
${invoice.items.map((item) => '• ${item.item.name} - ${item.quantity} x ₹${item.item.tradePrice} = ₹${item.totalPrice.toStringAsFixed(2)}').join('\n')}

Thank you for your business! 🛍️
    ''';

    final url = "https://wa.me/?text=${Uri.encodeComponent(message)}";

    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch WhatsApp';
    }
  }
}

// backup_service.dart - New File
// backup_service.dart - New File
class BackupService {
  static Future<void> exportData() async {
    final orderController = Get.find<OrderController>();
    final clientController = Get.find<ClientController>();

    final data = {
      'invoices': orderController.invoices.map((invoice) => invoice.toMap()).toList(),
      'clients': clientController.clients.map((client) => client.toMap()).toList(),
      'exportDate': DateTime.now().toIso8601String(),
    };

    // JSON file create karega
    final String encodedData = jsonEncode(data);

    // For now, just show success message
    // Actual file saving logic baad mein add karenge
    Get.snackbar(
      'Backup Created',
      'Data exported successfully\n(File saving feature coming soon)',
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );

    // Debug ke liye data print karen
    print('Exported Data: $encodedData');
  }

  static Future<void> importData() async {
    Get.snackbar('Import Feature', 'Coming in next update', backgroundColor: Colors.blue, colorText: Colors.white);
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings'), backgroundColor: Colors.blue.shade700),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader('Appearance'),
          Obx(
            () => SwitchListTile(
              title: const Text('Dark Mode'),
              value: themeController.isDarkMode.value,
              onChanged: themeController.toggleTheme,
            ),
          ),

          const Divider(),
          _buildSectionHeader('Data Management'),
          ListTile(
            leading: const Icon(Icons.backup),
            title: const Text('Backup Data'),
            subtitle: const Text('Export all data to file'),
            onTap: BackupService.exportData,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Data'),
            subtitle: const Text('Import data from backup'),
            onTap: BackupService.importData,
          ),

          const Divider(),
          _buildSectionHeader('About'),
          ListTile(leading: const Icon(Icons.info), title: const Text('Version'), subtitle: const Text('1.0.0')),
          ListTile(
            leading: const Icon(Icons.help),
            title: const Text('Help & Support'),
            onTap: () {
              Get.snackbar(
                'Help & Support',
                'Contact: support@billingapp.com',
                backgroundColor: Colors.blue,
                colorText: Colors.white,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }
}

// notification_service.dart - New File
class NotificationService {
  static void showOrderNotification(String shopName, double amount) {
    Get.snackbar(
      '🎉 Order Completed!',
      'Bill created for $shopName\nAmount: ₹$amount',
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
      snackPosition: SnackPosition.TOP,
    );
  }

  static void showLowStockAlert(String itemName) {
    Get.snackbar(
      '⚠️ Low Stock Alert',
      '$itemName is running low',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  static void showDailySummary() {
    final orderController = Get.find<OrderController>();
    final todayOrders = orderController.invoices.where((invoice) => invoice.date.day == DateTime.now().day).length;

    if (todayOrders > 0) {
      Get.snackbar(
        '📊 Daily Summary',
        'You completed $todayOrders orders today!',
        backgroundColor: Colors.blue,
        colorText: Colors.white,
      );
    }
  }
}

// pdf_invoice_service.dart - New File Create Karen
// ==================== PDF INVOICE SERVICE ====================

class PDFInvoiceService {
  static Future<void> generateInvoicePDF(Invoice invoice) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('INVOICE', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: ${_formatDate(invoice.date)}', style: pw.TextStyle(fontSize: 12)),
                ],
              ),
              pw.SizedBox(height: 20),

              // Invoice Details
              pw.Text('Invoice No: ${invoice.id}'),
              pw.Text('Shop: ${invoice.shopName}'),
              pw.SizedBox(height: 20),

              // Items Table
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text('Item', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text('Qty', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...invoice.items
                      .map(
                        (item) => pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(8.0), child: pw.Text(item.item.name)),
                            pw.Padding(padding: const pw.EdgeInsets.all(8.0), child: pw.Text(item.quantity.toString())),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Text('₹${item.item.tradePrice}'),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8.0),
                              child: pw.Text('₹${item.totalPrice.toStringAsFixed(2)}'),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ],
              ),
              pw.SizedBox(height: 20),

              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Text(
                    'Total: ₹${invoice.totalAmount.toStringAsFixed(2)}',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // PDF share karega
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'invoice_${invoice.id}.pdf');
  }

  static String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
