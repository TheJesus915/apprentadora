import 'package:flutter/material.dart';
import '../api/auth_service.dart';
import '../models/login_model.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool _obscureText = true;
  final AuthService authService = AuthService();

  void login() async {
    if (!_validateInputs()) return;

    setState(() {
      isLoading = true;
    });

    final credentials = LoginRequest(
      correo: emailController.text,
      password: passwordController.text,
    );

    final response = await authService.login(credentials);

    setState(() {
      isLoading = false;
    });

    if (response.success) {
      Navigator.pushReplacementNamed(
          context, response.necesitaPago ? '/pago-necesario' : '/dashboard');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response.message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  bool _validateInputs() {
    if (emailController.text.isEmpty || !emailController.text.contains('@')) {
      _showError('Por favor ingrese un correo electrónico válido');
      return false;
    }
    if (passwordController.text.isEmpty) {
      _showError('Por favor ingrese su contraseña');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            padding: EdgeInsets.symmetric(horizontal: 24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFFFFFF), // Color de inicio del gradiente (azul)
                  Color(0xFFFFFFFF), // Color de fin del gradiente (blanco)
                ],
              ),
            ),
            child: Column(
              children: [
                SizedBox(height: 60),
                // Logo o Imagen
                Image.asset(
                  'assets/images/logo.png',
                  height: 120,
                  width: 120,
                  fit: BoxFit.contain,
                ),
                SizedBox(height: 40),
                // Título
                Text(
                  'Bienvenido',
                  style: TextStyle(
                    color: Color(0xFF00345E),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Ingresa tus credenciales correctas',
                  style: TextStyle(
                    color: Color(0xFF00345E),
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 40),
                // Campos de entrada
                Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  color: Color(0xFFF5F5F5), // Color personalizado para la Card
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            labelText: 'Correo electrónico',
                            prefixIcon: Icon(Icons.email, color: Color(0xFF00345E),),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Color(0xFF1976D2)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: 20),
                        TextFormField(
                          controller: passwordController,
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                            prefixIcon: Icon(Icons.lock, color: Color(0xFF00345E),),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureText ? Icons.visibility : Icons.visibility_off,
                                color: Color(0xFF00345E),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureText = !_obscureText;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Color(0xFF1976D2)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          obscureText: _obscureText,
                        ),
                        SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF00345E),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 3,
                            ),
                            child: isLoading
                                ? SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}