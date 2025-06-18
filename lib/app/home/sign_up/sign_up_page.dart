import 'package:flutter/material.dart';
import 'package:flutter_steps_tracker/app/home/sign_up/utils/auth_utils.dart';
import 'package:flutter_steps_tracker/app/home/sign_up/widgets/password_text_field.dart';
import 'package:flutter_steps_tracker/utils/colors.dart';
import 'package:flutter_steps_tracker/utils/show_snack_bar.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({Key? key}) : super(key: key);

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final emailExists = await AuthUtils.checkEmailExists(_emailController.text);
      if (emailExists) {
        if (mounted) {
          showSnackBar(context, 'Пользователь с таким email уже существует');
        }
        return;
      }

      await AuthUtils.registerUser(
        email: _emailController.text,
        password: _passwordController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        nickname: _nicknameController.text,
      );

      if (mounted) {
        showSnackBar(context, 'Регистрация успешна!');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showSnackBar(context, 'Произошла ошибка: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
        backgroundColor: darkGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: AuthUtils.validateEmail,
              ),
              const SizedBox(height: 16),
              PasswordTextField(
                controller: _passwordController,
                labelText: 'Пароль',
                validator: AuthUtils.validatePassword,
              ),
              const SizedBox(height: 16),
              PasswordTextField(
                controller: _confirmPasswordController,
                labelText: 'Подтвердите пароль',
                validator: (value) => AuthUtils.validateConfirmPassword(
                  value,
                  _passwordController.text,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'Имя',
                  border: OutlineInputBorder(),
                ),
                validator: AuthUtils.validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Фамилия',
                  border: OutlineInputBorder(),
                ),
                validator: AuthUtils.validateName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Никнейм',
                  border: OutlineInputBorder(),
                ),
                validator: AuthUtils.validateNickname,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSignUp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: darkGrey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Зарегистрироваться',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
