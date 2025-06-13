import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OTPPage extends StatefulWidget {
  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final TextEditingController _emailController = TextEditingController();
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  bool _isChecking = false;
  bool _emailChecked = false;
  String? _errorMsg;
  bool _isResending = false;
  int _resendCooldown = 0;
  bool _isVerifying = false;
  String? _otpErrorMsg;

  Future<void> _checkEmail() async {
    setState(() {
      _isChecking = true;
      _errorMsg = null;
    });
    final response = await http.post(
      Uri.parse('https://semarnari.sportballnesia.com/api/master/user/check_email'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': _emailController.text.trim()}),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 200 && data['status'] == true) {
      setState(() {
        _emailChecked = true;
        _isChecking = false;
        _startResendCooldown();
      });
    } else {
      setState(() {
        _errorMsg = data['message'] ?? 'Email tidak ditemukan';
        _isChecking = false;
      });
    }
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
      _errorMsg = null;
    });
    // Simulasi resend OTP, ganti dengan API OTP jika ada
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isResending = false;
      _startResendCooldown();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP telah dikirim ulang ke email Anda')),
    );
  }

  Future<void> _verifyOTP() async {
    setState(() {
      _isVerifying = true;
      _otpErrorMsg = null;
    });
    final otp = _otpValue;
    try {
      final response = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/verify_otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'otp': otp}),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        setState(() {
          _isVerifying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP berhasil diverifikasi!')),
        );
        // Navigasi ke halaman new password
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => NewPasswordPage(email: _emailController.text.trim()),
          ),
        );
      } else {
        setState(() {
          _otpErrorMsg = data['message'] ?? 'OTP salah atau sudah kadaluarsa';
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _otpErrorMsg = 'Terjadi kesalahan. Silakan coba lagi.';
        _isVerifying = false;
      });
    }
  }

  void _startResendCooldown() {
    setState(() {
      _resendCooldown = 30;
    });
    Future.doWhile(() async {
      if (_resendCooldown > 0) {
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _resendCooldown--;
        });
        return true;
      }
      return false;
    });
  }

  String get _otpValue =>
      _otpControllers.map((c) => c.text).join();

  @override
  void dispose() {
    for (final c in _otpControllers) {
      c.dispose();
    }
    _emailController.dispose();
    super.dispose();
  }

  Widget _buildOTPFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(6, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.07),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: _otpControllers[i].text.isNotEmpty
                  ? const Color(0xFF152349)
                  : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: Center(
            child: TextField(
              controller: _otpControllers[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2),
              decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (val) {
                if (val.length == 1 && i < 5) {
                  FocusScope.of(context).nextFocus();
                }
                if (val.isEmpty && i > 0) {
                  FocusScope.of(context).previousFocus();
                }
                setState(() {});
              },
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        title: const Text('Lupa Password', style: TextStyle(color: Color(0xFF152349))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF152349)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (!_emailChecked) ...[
                const Text(
                  "Masukkan email akun Anda",
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF152349),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(14),
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF152349)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
                const SizedBox(height: 10),
                if (_errorMsg != null)
                  Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isChecking ? null : _checkEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF152349),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isChecking
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Cek Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ] else ...[
                const Text(
                  'Kode OTP telah dikirim ke email Anda.',
                  style: TextStyle(fontSize: 16, color: Color(0xFF152349), fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                _buildOTPFields(),
                if (_otpErrorMsg != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(_otpErrorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                  ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_otpValue.length == 6 && !_isVerifying)
                        ? _verifyOTP
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF152349),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Verifikasi OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Belum menerima kode? ",
                      style: TextStyle(color: Colors.black87, fontSize: 13),
                    ),
                    TextButton(
                      onPressed: (_resendCooldown == 0 && !_isResending)
                          ? _resendOTP
                          : null,
                      child: _isResending
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _resendCooldown > 0
                                  ? "Kirim ulang ($_resendCooldown)"
                                  : "Kirim ulang",
                              style: TextStyle(
                                color: Color(0xFF152349),
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class NewPasswordPage extends StatefulWidget {
  final String email;
  const NewPasswordPage({Key? key, required this.email}) : super(key: key);

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isSubmitting = false;
  String? _errorMsg;
  String? _successMsg;

  Future<void> _resetPassword() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    setState(() {
      _errorMsg = null;
      _successMsg = null;
    });

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() {
        _errorMsg = "Password tidak boleh kosong";
      });
      return;
    }
    if (newPassword != confirmPassword) {
      setState(() {
        _errorMsg = "Password tidak sama";
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://semarnari.sportballnesia.com/api/master/user/reset_password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.email,
          'password': newPassword,
        }),
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['status'] == true) {
        setState(() {
          _successMsg = "Password berhasil diubah. Silakan login dengan password baru.";
        });
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).popUntil((route) => route.isFirst);
        });
      } else {
        setState(() {
          _errorMsg = data['message'] ?? "Gagal mengubah password";
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = "Terjadi kesalahan. Silakan coba lagi.";
      });
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Baru', style: TextStyle(color: Color(0xFF152349))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF152349)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Masukkan password baru Anda',
                style: TextStyle(fontSize: 18, color: Color(0xFF152349), fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  controller: _newPasswordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password Baru',
                    prefixIcon: const Icon(Icons.lock, color: Color(0xFF152349)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey[700],
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF152349), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Material(
                elevation: 2,
                borderRadius: BorderRadius.circular(14),
                child: TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_isConfirmPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF152349)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                        color: Colors.grey[700],
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Color(0xFF152349), width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (_errorMsg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(_errorMsg!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
              if (_successMsg != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(_successMsg!, style: const TextStyle(color: Colors.green, fontSize: 13)),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF152349),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Simpan Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
