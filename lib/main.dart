import 'package:flutter/material.dart';

void main() => runApp(const CalculatorApp());

class CalculatorApp extends StatelessWidget {
  const CalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
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

  void _onButtonPressed(String value) {
    setState(() {
      if (value == 'AC') {
        expression = '';
        result = '0';
      } else if (value == '=') {
        // Здесь будет логика вычислений
        try {
          // Пример: просто выводим выражение как результат
          result = expression;
        } catch (e) {
          result = 'Ошибка';
        }
      } else {
        expression += value;
      }
    });
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
        onTap: () => _onButtonPressed(text),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final buttons = [
      ['AC', '±', '%', '/'],
      ['7', '8', '9', '×'],
      ['4', '5', '6', '-'],
      ['1', '2', '3', '+'],
      ['0', '.', '='],
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Дисплей
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
            // Кнопки
            Expanded(
              flex: 5,
              child: Column(
                children: buttons.map((row) {
                  return Expanded(
                    child: Row(
                      children: row.map((btn) {
                        final isOperator = [
                          '/',
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
    );
  }
}
