// GETX VERSION - Complete GetX app yahan ayega
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class GetXScreen extends StatelessWidget {
  const GetXScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Billing App - GETX',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: const GetXSplashScreen(),
      getPages: [
        GetPage(name: '/splash', page: () => const GetXSplashScreen()),
        GetPage(name: '/login', page: () => GetXLoginScreen()),
        GetPage(name: '/signup', page: () => const GetXSignupScreen()),
        GetPage(name: '/clientSelection', page: () => const GetXClientSelectionScreen()),
        GetPage(name: '/dashboard', page: () => const GetXDashboardScreen()),
      ],
      debugShowCheckedModeBanner: false,
      initialBinding: BindingsBuilder(() {
        Get.lazyPut<AuthController>(() => AuthController());
        Get.lazyPut<ThemeController>(() => ThemeController());
        Get.lazyPut<ClientController>(() => ClientController());
      }),
    );
  }
}

// ==================== GETX CODE YAHAN AYEGA ====================

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
    
    final authBox = Hive.box('authBox');
    token.value = authBox.get('token', defaultValue: '');
    userRole.value = authBox.get('userRole', defaultValue: 'user');
    userName.value = authBox.get('userName', defaultValue: '');
    email.value = authBox.get('email', defaultValue: '');
    
    isLoading.value = false;
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

  Future<bool> signup(String name, String email, String password, String role) async {
    isLoading.value = true;
    await Future.delayed(const Duration(seconds: 1));
    isLoading.value = false;
    return true;
  }

  Future<void> logout() async {
    final authBox = Hive.box('authBox');
    await authBox.clear();
    
    token.value = '';
    userRole.value = 'user';
    userName.value = '';
    email.value = '';
    
    Get.offAllNamed('/login');
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
      Item(id: '3', name: 'Tea', category: 'Beverages', price: 450, tradePrice: 400, unit: 'pack'),
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
      Item(id: '3', name: 'Eggs', category: 'Dairy', price: 200, tradePrice: 180, unit: 'dozen'),
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
      Item(id: '3', name: 'Shoes', category: 'Footwear', price: 3000, tradePrice: 2500, unit: 'pair'),
    ];
  }
  
  void switchClient(String clientId) {
    currentClientId.value = clientId;
    final clientsBox = Hive.box('clientsBox');
    clientsBox.put('currentClient', clientId);
  }

  Client getCurrentClient() {
    return clients.firstWhere(
      (client) => client.id == currentClientId.value,
      orElse: () => clients.first,
    );
  }
}

// Data Models (Same as Provider)
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

  factory Client.fromMap(Map<String, dynamic> map) {
    final primaryColorMap = map['primaryColor'] as Map<dynamic, dynamic>;
    final primaryColor = <String, int>{};
    primaryColorMap.forEach((key, value) {
      primaryColor[key.toString()] = value as int;
    });

    final shopListData = map['shopList'] as List<dynamic>;
    final shopList = shopListData.map<Shop>((shopData) {
      return Shop.fromMap(Map<String, dynamic>.from(shopData as Map<dynamic, dynamic>));
    }).toList();

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

  Shop({
    required this.id,
    required this.name,
    required this.address,
    required this.phone,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'status': status,
    };
  }

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
    return {
      'id': id,
      'name': name,
      'category': category,
      'price': price,
      'tradePrice': tradePrice,
      'unit': unit,
    };
  }

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

// GetX Screens
class GetXSplashScreen extends StatelessWidget {
  const GetXSplashScreen({super.key});

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
              'BILLING APP - GETX',
              style: TextStyle(
                fontSize: 24,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Obx(() {
              final authController = Get.find<AuthController>();
              return authController.isLoading.value
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const SizedBox();
            }),
          ],
        ),
      ),
    );
  }
}

class GetXLoginScreen extends StatelessWidget {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  GetXLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Login - GETX'),
        backgroundColor: Colors.blue.shade700,
      ),
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
            Obx(() {
              return SizedBox(
                width: double.infinity,
                height: 50,
                child: authController.isLoading.value
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: () async {
                          final success = await authController.login(
                            emailController.text,
                            passwordController.text,
                          );
                          
                          if (success) {
                            Get.offAllNamed('/clientSelection');
                          } else {
                            Get.snackbar(
                              'Error',
                              'Login failed! Check your credentials',
                              backgroundColor: Colors.red,
                              colorText: Colors.white,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                        ),
                        child: const Text('LOGIN', style: TextStyle(fontSize: 16)),
                      ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class GetXSignupScreen extends StatelessWidget {
  const GetXSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Signup - GETX'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: const Center(
        child: Text('GetX Signup Screen'),
      ),
    );
  }
}

class GetXClientSelectionScreen extends StatelessWidget {
  const GetXClientSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Selection - GETX'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: const Center(
        child: Text('GetX Client Selection Screen'),
      ),
    );
  }
}

class GetXDashboardScreen extends StatelessWidget {
  const GetXDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard - GETX'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: const Center(
        child: Text('GetX Dashboard Screen'),
      ),
    );
  }
}

