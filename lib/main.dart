import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'photo_safe_screen.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const CalculatorScreen(),
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String expression = '';
  String result = '0';
  String secretCode = '12345';
  String? _pressedButton;

  @override
  void initState() {
    super.initState();
    _loadSecretCode();
  }

  Future<void> _loadSecretCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      secretCode = prefs.getString('secret_code') ?? '12345';
    });
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'AC') {
        expression = '';
        result = '0';
      } else if (value == '=') {
        if (expression == secretCode) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PhotoSafeScreen()),
          );
          expression = '';
          result = '0';
        } else {
          _calculateResult();
        }
      } else {
        expression += value;
      }
    });
  }

  void _calculateResult() {
    try {
      Parser p = Parser();
      Expression exp = p.parse(
        expression.replaceAll('×', '*').replaceAll('÷', '/'),
      );
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);
      result = eval.toString();
    } catch (e) {
      result = 'Ошибка';
    }
  }

  Widget _buildButton(
    String text, {
    Color? color,
    Color? textColor,
    double fontSize = 24,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressedButton = text),
        onTapUp: (_) {
          setState(() => _pressedButton = null);
          _onButtonPressed(text);
        },
        onTapCancel: () => setState(() => _pressedButton = null),
        child: AnimatedScale(
          scale: _pressedButton == text ? 0.9 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color ?? Colors.grey[850],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  color: textColor ?? Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['AC', '±', '%', '÷'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Калькулятор'),
        backgroundColor: Colors.black.withOpacity(0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadSecretCode();
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  alignment: Alignment.bottomRight,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        expression,
                        style: const TextStyle(
                          fontSize: 28,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        result,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Column(
                  children: buttons.map((row) {
                    return Expanded(
                      child: Row(
                        children: row.map((btn) {
                          final isOperator = [
                            '÷',
                            '×',
                            '-',
                            '+',
                            '=',
                          ].contains(btn);
                          final isSpecial = ['AC', '±', '%'].contains(btn);
                          return _buildButton(
                            btn,
                            flex: btn == '0' ? 2 : 1,
                            color: isOperator
                                ? Colors.orange
                                : isSpecial
                                ? Colors.grey[700]
                                : Colors.grey[850],
                            textColor: Colors.white,
                          );
                        }).toList(),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _oldCodeController = TextEditingController();
  final TextEditingController _newCodeController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  String? _errorText;
  String _currentCode = '12345';

  @override
  void initState() {
    super.initState();
    _loadCurrentCode();
  }

  Future<void> _loadCurrentCode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentCode = prefs.getString('secret_code') ?? '12345';
    });
  }

  Future<void> _saveCode() async {
    final oldCode = _oldCodeController.text.trim();
    final newCode = _newCodeController.text.trim();
    final confirm = _confirmController.text.trim();

    if (oldCode.isEmpty || newCode.isEmpty || confirm.isEmpty) {
      setState(() {
        _errorText = 'Все поля должны быть заполнены';
      });
      return;
    }

    if (oldCode != _currentCode) {
      setState(() {
        _errorText = 'Старый код введён неверно';
      });
      return;
    }

    if (newCode != confirm) {
      setState(() {
        _errorText = 'Новый код и подтверждение не совпадают';
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('secret_code', newCode);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Настройки'),
        backgroundColor: Colors.black.withOpacity(0.3),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Введите старый код:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _oldCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Текущий код',
              ),
            ),
            const SizedBox(height: 20),
            const Text('Введите новый код:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            TextField(
              controller: _newCodeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Новый код',
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Подтвердите новый код:',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Повторите новый код',
              ),
            ),
            if (_errorText != null) ...[
              const SizedBox(height: 10),
              Text(_errorText!, style: const TextStyle(color: Colors.red)),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveCode,
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }
}
