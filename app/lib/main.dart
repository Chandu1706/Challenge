import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

void main() {
  runApp(const BudgetApp());
}

class BudgetApp extends StatelessWidget {
  const BudgetApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  DateTime selectedDate = DateTime.now();
  String get currentDateFormatted =>
      DateFormat('MMMM yyyy').format(selectedDate);

  List<Transaction> transactions = [];
  bool showAllTransactions = false;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/transactions.json');
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      setState(() {
        transactions = (jsonData['transactions'] as List<dynamic>)
            .map((item) => Transaction.fromJson(item))
            .toList();
      });
      // ignore: empty_catches
    } catch (e) {}
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  double calculateTotalSpent() {
    return transactions.fold(
        0.0, (sum, transaction) => sum + transaction.amount);
  }

  double calculateBudget() {
    return transactions.length * 100;
  }

  @override
  Widget build(BuildContext context) {
    double totalSpent = calculateTotalSpent();
    double budget = calculateBudget();
    double remaining = budget - totalSpent;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        elevation: 0,
        toolbarHeight: 80,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: Icon(Icons.menu, color: Colors.white),
        ),
        title: GestureDetector(
          onTap: () => _selectDate(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                currentDateFormatted,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white),
            ],
          ),
        ),
        centerTitle: true,
        actions: const [
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.share, color: Colors.white),
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(Icons.more_vert, color: Colors.white),
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Summary Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      '\$${remaining.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green),
                    ),
                    const SizedBox(height: 4),
                    const Text('Remaining in Budget'),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: totalSpent / budget,
                      color: Colors.green,
                      backgroundColor: Colors.grey.shade300,
                      minHeight: 10,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Spent: \$${totalSpent.toStringAsFixed(2)}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                        Text(
                          'Budget: \$${budget.toStringAsFixed(2)}',
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ...transactions
                                .take(showAllTransactions
                                    ? transactions.length
                                    : 5)
                                .map((transaction) =>
                                    TransactionItem(transaction: transaction)),
                            if (transactions.length > 5)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    showAllTransactions = !showAllTransactions;
                                  });
                                },
                                child: Text(
                                  showAllTransactions
                                      ? "Show Less"
                                      : "Show More",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddTransactionDialog(context);
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Trends',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Accounts',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context) {
    final categoryController = TextEditingController();
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a Transaction'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category'),
              ),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: 'Amount'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                final category = categoryController.text;
                final amount = double.tryParse(amountController.text) ?? 0.0;

                if (category.isNotEmpty && amount > 0) {
                  addTransaction(category, amount);
                }

                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void addTransaction(String category, double amount) {
    setState(() {
      transactions.add(Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        category: category,
        transactionType: "regular",
        amount: amount,
        date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      ));
    });
  }
}

class Transaction {
  final String id;
  final String category;
  final String transactionType;
  final double amount;
  final String date;

  Transaction({
    required this.id,
    required this.category,
    required this.transactionType,
    required this.amount,
    required this.date,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'],
      category: json['category'],
      transactionType: json['transaction_type'],
      amount: json['amount'].toDouble(),
      date: json['date'],
    );
  }
}

class TransactionItem extends StatelessWidget {
  final Transaction transaction;

  const TransactionItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    Color progressColor;
    IconData icon;

    switch (transaction.category) {
      case "Food":
        progressColor = Colors.green;
        icon = Icons.restaurant;
        break;
      case "Shopping":
        progressColor = Colors.blue;
        icon = Icons.shopping_cart;
        break;
      case "Transportation":
        progressColor = Colors.orange;
        icon = Icons.directions_car;
        break;
      case "Housing":
        progressColor = Colors.red;
        icon = Icons.house;
        break;
      case "Education":
        progressColor = Colors.purple;
        icon = Icons.school;
        break;
      case "Shop":
        progressColor = Colors.teal;
        icon = Icons.store;
        break;
      default:
        progressColor = Colors.grey;
        icon = Icons.category;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: progressColor,
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: transaction.amount / 100,
                  color: progressColor,
                  backgroundColor: Colors.grey.shade300,
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${transaction.amount.toStringAsFixed(2)} of \$100',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '\$${(100 - transaction.amount).toStringAsFixed(2)} left',
            style: TextStyle(
              fontSize: 12,
              color: transaction.amount > 100 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
