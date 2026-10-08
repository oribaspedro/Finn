import 'package:flutter/material.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// Contas bancárias centralizadas no Finn
// ---------------------------------------------------------------------------

const String kSantander = 'Banco Santander';
const String kBB = 'Banco do Brasil';
const String kCaixa = 'Caixa Econômica';
const String kSerasa = 'Serasa';

class BankAccount {
  final String name;
  final Color color;
  final double balance;
  const BankAccount(this.name, this.color, this.balance);

  BankAccount copyWith({double? balance}) =>
      BankAccount(name, color, balance ?? this.balance);
}

/// Saldo de cada conta (soma inicial: R$ 21.982,19). Muda a cada pagamento.
final ValueNotifier<List<BankAccount>> accounts =
    ValueNotifier<List<BankAccount>>(const [
  BankAccount(kSantander, FinnTheme.red, 8935.76),
  BankAccount(kBB, FinnTheme.yellow, 4858.00),
  BankAccount(kCaixa, FinnTheme.blue, 4462.38),
  BankAccount(kSerasa, FinnTheme.pink, 3726.05),
]);

/// Saldo total unificado (soma de todas as contas).
double get totalBalance =>
    accounts.value.fold<double>(0, (s, a) => s + a.balance);

BankAccount accountByName(String name) => accounts.value
    .firstWhere((a) => a.name == name, orElse: () => accounts.value.first);

double _r2(double v) => (v * 100).round() / 100;

/// Valor movimentado em um banco específico (parte de um pagamento/recebimento).
class BankFlow {
  final String bank;
  final double amount; // sempre positivo
  const BankFlow(this.bank, this.amount);

  Color get color => accountByName(bank).color;
}

/// Desconta dos saldos o que saiu de cada banco.
void applyDebits(List<BankFlow> flows) {
  accounts.value = [
    for (final a in accounts.value)
      a.copyWith(
        balance: _r2(a.balance -
            flows.where((f) => f.bank == a.name).fold<double>(0, (s, f) => s + f.amount)),
      ),
  ];
}

/// Soma ao saldo o que entrou em um banco.
void applyCredit(BankFlow flow) {
  accounts.value = [
    for (final a in accounts.value)
      a.name == flow.bank ? a.copyWith(balance: _r2(a.balance + flow.amount)) : a,
  ];
}

// ---------------------------------------------------------------------------
// Cartões
// ---------------------------------------------------------------------------

class CardData {
  final Color color;
  final String bank;
  final String brand; // bandeira
  final String last4;
  final String holder;
  final String expiry; // MM/AA
  final double availableLimit;
  final double invoice; // fatura atual

  const CardData({
    required this.color,
    required this.bank,
    required this.brand,
    required this.last4,
    required this.holder,
    required this.expiry,
    required this.availableLimit,
    required this.invoice,
  });

  String get maskedNumber => '••••  ••••  ••••  $last4';
}

/// Ordem dos cartões: do fundo (primeiro) para a frente (último).
const List<CardData> cards = [
  CardData(
    color: FinnTheme.red,
    bank: 'Santander',
    brand: 'Mastercard',
    last4: '4821',
    holder: 'LUCAS M SILVA',
    expiry: '09/29',
    availableLimit: 10156.73,
    invoice: 1843.27,
  ),
  CardData(
    color: FinnTheme.yellow,
    bank: 'Banco do Brasil',
    brand: 'Visa',
    last4: '7390',
    holder: 'LUCAS M SILVA',
    expiry: '03/28',
    availableLimit: 7037.60,
    invoice: 962.40,
  ),
  CardData(
    color: FinnTheme.blue,
    bank: 'Caixa',
    brand: 'Elo',
    last4: '1156',
    holder: 'LUCAS M SILVA',
    expiry: '11/27',
    availableLimit: 3480.00,
    invoice: 1520.00,
  ),
  CardData(
    color: FinnTheme.pink,
    bank: 'Serasa Card',
    brand: 'Mastercard',
    last4: '9034',
    holder: 'LUCAS M SILVA',
    expiry: '06/30',
    availableLimit: 2215.50,
    invoice: 284.50,
  ),
];

// ---------------------------------------------------------------------------
// Extrato
// ---------------------------------------------------------------------------

class Transaction {
  final String title;
  final String subtitle;
  final double amount; // positivo = entrada, negativo = saída
  final DateTime date;
  final IconData icon;

  /// Entrada: em qual banco entrou. Saída: de quais bancos saiu (e quanto).
  final List<BankFlow> flows;

  const Transaction({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    required this.icon,
    required this.flows,
  });

  bool get isIncome => amount > 0;

  String get flowSummary {
    final names = flows.map((f) => f.bank).join(', ');
    return isIncome ? 'Entrou em $names' : 'Saiu de $names';
  }
}

List<Transaction> _seedTransactions() {
  final now = DateTime.now();
  DateTime d(int daysAgo, int h, int m) =>
      DateTime(now.year, now.month, now.day - daysAgo, h, m);

  return [
    Transaction(title: 'Mercado Bom Preço', subtitle: 'Compra no débito', amount: -187.45, date: d(0, 18, 12), icon: Icons.shopping_cart_outlined, flows: const [BankFlow(kSantander, 187.45)]),
    Transaction(title: 'Pix recebido de Ana Souza', subtitle: 'Pix recebido', amount: 120.00, date: d(0, 9, 41), icon: Icons.south_west, flows: const [BankFlow(kBB, 120.00)]),
    Transaction(title: 'Uber', subtitle: 'Compra no crédito', amount: -23.90, date: d(1, 22, 5), icon: Icons.directions_car_outlined, flows: const [BankFlow(kCaixa, 23.90)]),
    Transaction(title: 'Pix para Carlos Lima', subtitle: 'Pix enviado', amount: -60.00, date: d(1, 13, 30), icon: Icons.north_east, flows: const [BankFlow(kSantander, 40.00), BankFlow(kCaixa, 20.00)]),
    Transaction(title: 'Pix para Imobiliária Central', subtitle: 'Pix enviado', amount: -2300.00, date: d(2, 15, 10), icon: Icons.north_east, flows: const [BankFlow(kSantander, 1200.00), BankFlow(kBB, 600.00), BankFlow(kCaixa, 500.00)]),
    Transaction(title: 'Restaurante Sabor & Cia', subtitle: 'Compra no crédito', amount: -74.80, date: d(2, 12, 48), icon: Icons.restaurant_outlined, flows: const [BankFlow(kBB, 74.80)]),
    Transaction(title: 'Salário', subtitle: 'Depósito', amount: 4850.00, date: d(3, 8, 0), icon: Icons.account_balance_wallet_outlined, flows: const [BankFlow(kSantander, 4850.00)]),
    Transaction(title: 'Conta de luz', subtitle: 'Pagamento de boleto', amount: -212.37, date: d(4, 10, 20), icon: Icons.bolt_outlined, flows: const [BankFlow(kBB, 150.00), BankFlow(kSerasa, 62.37)]),
    Transaction(title: 'Streaming', subtitle: 'Compra no crédito', amount: -39.90, date: d(5, 6, 0), icon: Icons.movie_outlined, flows: const [BankFlow(kCaixa, 39.90)]),
    Transaction(title: 'Pix recebido de João Pereira', subtitle: 'Pix recebido', amount: 250.00, date: d(6, 16, 22), icon: Icons.south_west, flows: const [BankFlow(kCaixa, 250.00)]),
    Transaction(title: 'Farmácia Vida', subtitle: 'Compra no débito', amount: -58.60, date: d(8, 17, 45), icon: Icons.local_pharmacy_outlined, flows: const [BankFlow(kSerasa, 58.60)]),
    Transaction(title: 'Transferência recebida', subtitle: 'TED', amount: 900.00, date: d(11, 11, 3), icon: Icons.swap_horiz, flows: const [BankFlow(kSantander, 900.00)]),
    Transaction(title: 'Academia', subtitle: 'Débito automático', amount: -109.90, date: d(14, 7, 0), icon: Icons.fitness_center_outlined, flows: const [BankFlow(kBB, 109.90)]),
    Transaction(title: 'Internet', subtitle: 'Pagamento de boleto', amount: -99.90, date: d(18, 9, 15), icon: Icons.wifi, flows: const [BankFlow(kSerasa, 99.90)]),
    Transaction(title: 'Pix para Maria Oliveira', subtitle: 'Pix enviado', amount: -35.00, date: d(21, 20, 10), icon: Icons.north_east, flows: const [BankFlow(kSantander, 35.00)]),
  ];
}

final ValueNotifier<List<Transaction>> transactions =
    ValueNotifier<List<Transaction>>(_seedTransactions());

void addTransactions(List<Transaction> items) {
  transactions.value = [...items, ...transactions.value];
}

// ---------------------------------------------------------------------------
// Pix
// ---------------------------------------------------------------------------

class PixKey {
  final String type; // CPF, E-mail, Celular, Aleatória
  final String value;
  final String bank; // banco onde os Pix recebidos por esta chave entram
  const PixKey(this.type, this.value, this.bank);
}

final ValueNotifier<List<PixKey>> pixKeys = ValueNotifier<List<PixKey>>([
  const PixKey('CPF', '123.456.789-09', kSantander),
  const PixKey('E-mail', 'lucas.silva@email.com', kBB),
  const PixKey('Celular', '(41) 99876-5432', kCaixa),
]);

class PixContact {
  final String name;
  final String key;
  final Color color;
  const PixContact(this.name, this.key, this.color);

  String get initials {
    final parts = name.trim().split(' ');
    return (parts.first[0] + (parts.length > 1 ? parts.last[0] : '')).toUpperCase();
  }
}

const List<PixContact> frequentContacts = [
  PixContact('Ana Souza', 'ana.souza@email.com', FinnTheme.pink),
  PixContact('Carlos Lima', '(41) 98811-2233', FinnTheme.blue),
  PixContact('Maria Oliveira', '987.654.321-00', FinnTheme.red),
  PixContact('João Pereira', 'joao.pereira@email.com', FinnTheme.secondaryBlue),
];
