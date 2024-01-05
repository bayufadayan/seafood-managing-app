import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:prak_mobpro/component/my_button.dart';
import 'package:prak_mobpro/component/my_input_field.dart';
import 'package:prak_mobpro/component/toast.dart';
import 'package:prak_mobpro/pages/complete_profile.dart';
import 'package:prak_mobpro/pages/login_page.dart';
import 'package:prak_mobpro/firebase_auth_implementation/firebase_auth_services.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final FirebaseAuthService _auth = FirebaseAuthService();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() async {
    setState(() {
      _isLoading = true;
    });

    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (email == '' || password == '' || confirmPassword == '') {
      showToast("Please fill in the fields");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!_isValidEmail(email)) {
      showToast("Invalid email format");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (!_isValidPassword(password)) {
      showToast("Password is too weak");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      showToast("Passwords do not match");
      setState(() {
        _isLoading = false;
      });
      return;
    }

    User? user = await _auth.signUpWithEmailAndPassword(email, password);
    if (user != null) {
      setState(() {
        _isLoading = true;
      });
      showToast("Account successfully created", bgcolor: Colors.green);
      Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: ((context) => const CompleteProfileAfterRegist())));
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // validasi untuk regist
  bool _isValidEmail(String email) {
    RegExp emailRegex = RegExp(r"^[a-z0-9._%+-]+@[a-z0-9.-]+\.[a-z]{2,3}$");
    return emailRegex.hasMatch(email);
  }

  bool _isValidPassword(String password) {
    return password.length >= 6;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
          child: ListView(
            children: [
              //icon
              SizedBox(
                child: Image.asset(
                  'assets/Logo Gudang.png',
                ),
                height: 100,
                width: 100,
              ),

              //input field

              //email
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Email",
                    style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),

              MyInputField(
                controller: _emailController,
                hintText: "Insert your email",
                obscureText: false,
                icon: const Icon(
                  Icons.email,
                  color: Colors.deepOrange,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              //password
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Password",
                    style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              MyInputField(
                controller: _passwordController,
                hintText: "Insert your password",
                obscureText: true,
                icon: Icon(
                  Icons.password,
                  color: Colors.deepOrange,
                ),
              ),

              const SizedBox(
                height: 10,
              ),
              //retype pasword
              const Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text(
                    "Confirm Password",
                    style: TextStyle(
                        color: Colors.deepOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
              const SizedBox(
                height: 5,
              ),
              MyInputField(
                controller: _confirmPasswordController,
                hintText: "Re-type your password",
                obscureText: true,
                icon: Icon(
                  Icons.password,
                  color: Colors.deepOrange,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              //button login
              MyButton(
                onTap: _signUp,
                // Navigator.of(context).pushReplacement(
                //   MaterialPageRoute(builder: (context) => HomeScreen()),
                // );

                text: 'Register',
                isLoading: _isLoading,
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already Have an Account?",
                    style: TextStyle(color: Colors.deepOrange),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                              builder: ((context) => const LoginPage())));
                    },
                    child: Text(
                      "Login now",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.deepOrange.shade700),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
