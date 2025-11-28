# Billing_App

<!-- import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mera App',
      theme: lightTheme, 
      darkTheme: darkTheme,
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Light Theme define karo
ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.white,
  appBarTheme: AppBarTheme(backgroundColor: Colors.blue, foregroundColor: Colors.white),
  inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(), filled: true, fillColor: Colors.grey[50]),
);

// Dark Theme define karo
ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primarySwatch: Colors.blue,
  scaffoldBackgroundColor: Colors.grey[900],
  appBarTheme: AppBarTheme(backgroundColor: Colors.grey[800], foregroundColor: Colors.white),
  inputDecorationTheme: InputDecorationTheme(border: OutlineInputBorder(), filled: true, fillColor: Colors.grey[800]),
);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 2), () {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apps, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              'Mera App',
              style: TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login'),
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: () {
              // Dark/light theme toggle karega
              final themeMode = Theme.of(context).brightness == Brightness.dark ? ThemeMode.light : ThemeMode.dark;

              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Theme Change'),
                  content: Text(
                    'Is app ko properly theme change karne ke liye state management chahiye. Abhi bas demo dikha raha hoon.',
                  ),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
            ),
            SizedBox(height: 20),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  print('Login button press hua');
                },
                child: Text('LOGIN', style: TextStyle(fontSize: 18)),
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SignupScreen()));
              },
              child: Text('Signup karna hai? Yahan click karo'),
            ),
          ],
        ),
      ),
    );
  }
}

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Signup'),
        actions: [
          IconButton(
            icon: Icon(Icons.brightness_6),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Theme Change'),
                  content: Text('Theme change functionality demo.'),
                  actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text('OK'))],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
            ),
            SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
            ),
            SizedBox(height: 20),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock)),
            ),
            SizedBox(height: 20),
            TextField(
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm Password', prefixIcon: Icon(Icons.lock)),
            ),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () {
                  print('Signup button press hua');
                },
                child: Text('SIGNUP', style: TextStyle(fontSize: 18)),
              ),
            ),
            SizedBox(height: 20),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Already account hai? Login karo'),
            ),
          ],
        ),
      ),
    );
  }
} -->