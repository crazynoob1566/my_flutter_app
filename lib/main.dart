import 'package:flutter/material.dart';
import 'package:math_expressions/math_expressions.dart';
import 'photo_safe_screen.dart';

void main() => runApp(const SecretCalculatorApp());

class SecretCalculatorApp extends StatelessWidget {
  const SecretCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Secret Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
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
  String input = '';
  String result = '';
  final String secretCode = '55555';

  String _normalize(String expr) {
    return expr.replaceAll('×', '*').replaceAll('÷', '/');
  }

  String _evaluate(String expr) {
    try {
      if (expr.isEmpty) return '';
      final parsed = Parser().parse(_normalize(expr));
      final value = parsed.evaluate(EvaluationType.REAL, ContextModel());
      final isInt = (value - value.roundToDouble()).abs() < 1e-9;
      return isInt ? value.toInt().toString() : value.toString();
    } catch (_) {
      return 'Ошибка';
    }
  }

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'AC') {
        input = '';
        result = '';
        return;
      }
      if (value == 'DEL') {
        if (input.isNotEmpty) input = input.substring(0, input.length - 1);
        return;
      }
      if (value == '=') {
        result = _evaluate(input);
        return;
      }

      // защита от двух операторов подряд
      final ops = ['+', '-', '×', '÷'];
      if (ops.contains(value)) {
        if (input.isEmpty) return;
        if (ops.contains(input.characters.last)) {
          input = input.substring(0, input.length - 1) + value;
          return;
        }
      }

      input += value;

      if (input.endsWith(secretCode)) {
        input = '';
        result = '';
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PhotoSafeScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      '7', '8', '9', 'DEL',
      '4', '5', '6', '×',
      '1', '2', '3', '÷',
      '0', '.', '=', 'AC',
      '+', '-', // вынесем вниз, можно переставить как удобно
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Calculator')),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.bottomRight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(input, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 8),
                  Text(
                    result,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          GridView.builder(
            padding: const EdgeInsets.all(8),
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              childAspectRatio: 1.15,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: buttons.length,
            itemBuilder: (context, index) {
              final label = buttons[index];
              final isOp = [
                '+',
                '-',
                '×',
                '÷',
                '=',
                'AC',
                'DEL',
              ].contains(label);
              return ElevatedButton(
                onPressed: () => _onButtonPressed(label),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOp ? Colors.teal : Colors.teal.shade50,
                  foregroundColor: isOp ? Colors.white : Colors.black,
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SecretScreen extends StatelessWidget {
  const SecretScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Secret Area')),
      body: const Center(
        child: Text(
          '🔒 Секретный раздел (сюда добавим биометрию)',
          style: TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
