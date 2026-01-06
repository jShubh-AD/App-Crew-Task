import 'package:appcrew_task/notes.dart';
import 'package:appcrew_task/utils/validators.dart';
import 'package:appcrew_task/widgets/custom_button.dart';
import 'package:appcrew_task/widgets/custom_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Auth extends StatefulWidget {
  const Auth({super.key});

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool isLogin = true;
  bool loading = false;

  final _formKey = GlobalKey<FormState>();

  Future<void> _submit() async {
    if(!_formKey.currentState!.validate()) return;
    setState(() => loading = true);
    try {
      UserCredential res;

      if (isLogin) {
        res =  await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );

      } else {
        res = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passCtrl.text.trim(),
        );
      }

      if (res.user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Notes()),
        );
      }

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Auth error')));
    } finally {
      if(mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose(){
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 8,
        title: Text(
          isLogin ? 'Welcome Back, I missed you.' : "Let's start new journey",
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  textAlign: TextAlign.center,
                  isLogin ? 'Login' : "Sign up",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700
                  ),
                ),
                SizedBox(height: 16,),
                AppTextField(
                  controller: _emailCtrl,
                  validator: ValidationHelper.emailValidator,
                  hintText: "johndoe@123gmail.com",
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _passCtrl,
                  obscureText: true,
                  validator: ValidationHelper.passwordValidator,
                  hintText: "Enter a strong",
                ),
                const SizedBox(height: 24),
                AppButton(
                  loading: loading,
                  text: isLogin ? "Login" : "Sign up",
                  onPressed: _submit,
                ),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(
                    isLogin
                        ? "Don't have an account? Sign up"
                        : "Already have an account? Login",
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
