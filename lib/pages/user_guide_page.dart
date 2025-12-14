import 'package:flutter/material.dart';
import 'package:g/utils/responsive_helper.dart';

class UserGuidePage extends StatefulWidget {
  const UserGuidePage({super.key});

  @override
  State<UserGuidePage> createState() => _UserGuidePageState();
}

class _UserGuidePageState extends State<UserGuidePage> {
  bool _isTagalog = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isTagalog ? 'Gabay sa Paggamit' : 'User Guide',
          style: TextStyle(
            fontSize: ResponsiveHelper.fontSize(context, mobile: 20),
          ),
        ),
        backgroundColor: Colors.blue,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ToggleButtons(
                  borderRadius: BorderRadius.circular(20),
                  selectedColor: Colors.white,
                  fillColor: Colors.blue.shade700,
                  color: Colors.white70,
                  constraints: const BoxConstraints(
                    minHeight: 32,
                    minWidth: 50,
                  ),
                  isSelected: [!_isTagalog, _isTagalog],
                  onPressed: (index) {
                    setState(() {
                      _isTagalog = index == 1;
                    });
                  },
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('EN',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Text('TL',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(ResponsiveHelper.horizontalPadding(context)),
        children: [
          _buildWelcomeSection(),
          const SizedBox(height: 24),
          _buildDashboardSection(),
          const SizedBox(height: 24),
          _buildScanningSection(),
          const SizedBox(height: 24),
          _buildAIChatSection(),
          const SizedBox(height: 24),
          _buildManualEntrySection(),
          const SizedBox(height: 24),
          _buildTransactionRulesSection(),
          const SizedBox(height: 24),
          _buildTipsSection(),
          const SizedBox(height: 24),
          _buildFAQSection(),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue, size: 28),
                const SizedBox(width: 12),
                Text(
                  _isTagalog
                      ? 'Maligayang Pagdating sa CASH'
                      : 'Welcome to CASH',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _isTagalog
                  ? 'Subaybayan ang iyong mga money transfer gamit ang receipt scanning at AI assistance.'
                  : 'Track your money transfers easily with receipt scanning and AI assistance.',
              style: const TextStyle(fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.dashboard, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                Text(
                  _isTagalog
                      ? 'Pangkalahatang Tanawin ng Dashboard'
                      : 'Dashboard Overview',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoItem(
              '💰 ${_isTagalog ? 'Kabuuang Cash In' : 'Total Cash In'}',
              _isTagalog
                  ? 'Lahat ng perang natanggap mo'
                  : 'All money you received',
            ),
            _buildInfoItem(
              '💸 ${_isTagalog ? 'Kabuuang Cash Out' : 'Total Cash Out'}',
              _isTagalog
                  ? 'Lahat ng perang ipinadala mo'
                  : 'All money you sent',
            ),
            _buildInfoItem(
              '💵 ${_isTagalog ? 'Available na Pondo' : 'Available Funds'}',
              _isTagalog
                  ? 'Iyong kasalukuyang balanse (Cash In - Cash Out)'
                  : 'Your current balance (Cash In - Cash Out)',
            ),
            _buildInfoItem(
              '📊 ${_isTagalog ? 'Kabuuang Bayad' : 'Total Fees'}',
              _isTagalog
                  ? 'Lahat ng bayad sa transaksyon'
                  : 'All transaction fees paid',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.camera_alt, color: Colors.orange, size: 24),
                const SizedBox(width: 12),
                Text(
                  _isTagalog ? 'Pag-scan ng mga Resibo' : 'Scanning Receipts',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildStepItem(
              '1',
              _isTagalog ? 'Kumuha ng Larawan' : 'Take a Photo',
              _isTagalog
                  ? 'I-tap ang "Scan Receipt" at kunan ng malinaw ang resibo'
                  : 'Tap "Scan Receipt" and capture your receipt clearly',
            ),
            _buildStepItem(
              '2',
              _isTagalog ? 'AI ay Kukuha ng Data' : 'AI Extracts Data',
              _isTagalog
                  ? 'Awtomatikong babasahin ng app ang halaga, reference, petsa, atbp.'
                  : 'App automatically reads amount, reference, date, etc.',
            ),
            _buildStepItem(
              '3',
              _isTagalog ? 'Suriin at I-edit' : 'Review & Edit',
              _isTagalog
                  ? 'Tignan ang mga detalye at itama ang mali'
                  : 'Check the details and fix any errors',
            ),
            _buildStepItem(
              '4',
              _isTagalog ? 'I-save ang Transaksyon' : 'Save Transaction',
              _isTagalog
                  ? 'I-tap ang save para idagdag sa records'
                  : 'Tap save to add it to your records',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.blue, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _isTagalog ? 'Mga Tip sa Pag-scan:' : 'Scanning Tips:',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(_isTagalog
                      ? '• Gumamit ng magandang ilaw'
                      : '• Use good lighting'),
                  Text(_isTagalog
                      ? '• Panatilihing steady ang camera'
                      : '• Keep camera steady'),
                  Text(_isTagalog
                      ? '• Kunan ang buong resibo'
                      : '• Capture entire receipt'),
                  Text(_isTagalog
                      ? '• Iwasan ang anino at silawan'
                      : '• Avoid shadows and glare'),
                  Text(_isTagalog
                      ? '• Gumagana sa GCash, banks, PayMaya'
                      : '• Works with GCash, banks, PayMaya'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIChatSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat_bubble, color: Colors.purple, size: 24),
                const SizedBox(width: 12),
                Text(
                  _isTagalog ? 'AI Chat Assistant' : 'AI Chat Assistant',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _isTagalog ? 'Magagawa ng AI:' : 'What AI Can Do:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoItem(
              _isTagalog ? '📸 Mag-scan sa Chat' : '📸 Scan via Chat',
              _isTagalog
                  ? 'Magpadala ng larawan ng resibo sa chat'
                  : 'Send receipt images directly in chat',
            ),
            _buildInfoItem(
              _isTagalog ? '❓ Sumagot ng Tanong' : '❓ Answer Questions',
              _isTagalog
                  ? '"Magkano ang nagastos ko?" "Ipakita ang balanse"'
                  : '"How much did I spend?" "Show my balance"',
            ),
            _buildInfoItem(
              _isTagalog ? '➕ Magdagdag ng Transaksyon' : '➕ Add Transactions',
              _isTagalog
                  ? 'Maaaring mag-save ng bagong transaksyon ang AI'
                  : 'AI can save new transactions for you',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isTagalog
                          ? 'Hindi maaaring i-edit ng AI ang mga naka-save na transaksyon. Permanente ang mga transaksyon.'
                          : 'AI cannot edit existing transactions. Transactions are permanent once saved.',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManualEntrySection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Colors.teal, size: 24),
                const SizedBox(width: 12),
                Text(
                  _isTagalog ? 'Manwal na Pagpasok' : 'Manual Entry',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              _isTagalog ? 'Kailan Gamitin:' : 'When to Use:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            Text(_isTagalog
                ? '• Walang available na resibo'
                : '• No receipt available'),
            Text(_isTagalog
                ? '• Masamang kalidad ng scan'
                : '• Poor scan quality'),
            Text(_isTagalog
                ? '• Custom na transaksyon'
                : '• Custom transaction entry'),
            const SizedBox(height: 16),
            Text(
              _isTagalog ? 'Kinakailangang Detalye:' : 'Required Fields:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 8),
            _buildInfoItem(_isTagalog ? '✅ Halaga' : '✅ Amount',
                _isTagalog ? 'Dapat higit sa 0' : 'Must be greater than 0'),
            _buildInfoItem(
                _isTagalog ? '✅ Reference Number' : '✅ Reference Number',
                _isTagalog
                    ? 'Dapat unique (8-20 characters)'
                    : 'Must be unique (8-20 characters)'),
            _buildInfoItem(
                _isTagalog ? '✅ Uri ng Transaksyon' : '✅ Transaction Type',
                _isTagalog ? 'Cash In o Cash Out' : 'Cash In or Cash Out'),
            _buildInfoItem(_isTagalog ? '📅 Petsa' : '📅 Date',
                _isTagalog ? 'Petsa ng transaksyon' : 'Transaction date'),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionRulesSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.rule, color: Colors.indigo, size: 24),
                const SizedBox(width: 12),
                Text(
                  _isTagalog
                      ? 'Mga Patakaran sa Transaksyon'
                      : 'Transaction Rules',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildRuleItem(
              '✅',
              _isTagalog
                  ? 'Ang reference number ay dapat UNIQUE'
                  : 'Reference numbers must be UNIQUE',
              Colors.green,
            ),
            _buildRuleItem(
              '❌',
              _isTagalog
                  ? 'HINDI maaaring i-edit ang transaksyon pagkatapos i-save'
                  : 'Transactions CANNOT be edited after saving',
              Colors.red,
            ),
            _buildRuleItem(
              '✅',
              _isTagalog
                  ? 'MAAARI mong burahin ang maling transaksyon'
                  : 'You CAN delete incorrect transactions',
              Colors.green,
            ),
            _buildRuleItem(
              '⚠️',
              _isTagalog
                  ? 'Laging suriin ang scanned data bago i-save'
                  : 'Always review scanned data before saving',
              Colors.orange,
            ),
            _buildRuleItem(
              '✅',
              _isTagalog
                  ? 'Ang duplicate reference ay tatanggihan'
                  : 'Duplicate references will be rejected',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.amber, size: 24),
                const SizedBox(width: 12),
                Text(
                  _isTagalog ? 'Mga Mabuting Gawain' : 'Best Practices',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTipItem(
                '📸',
                _isTagalog
                    ? 'I-scan ang resibo kaagad pagkatapos ng transaksyon'
                    : 'Scan receipts immediately after transactions'),
            _buildTipItem(
                '✔️',
                _isTagalog
                    ? 'Laging i-verify ang data na kinuha ng AI'
                    : 'Always verify AI-extracted data'),
            _buildTipItem(
                '🔢',
                _isTagalog
                    ? 'Gumamit ng unique na reference numbers'
                    : 'Use unique reference numbers'),
            _buildTipItem(
                '📝',
                _isTagalog
                    ? 'Magdagdag ng notes para sa maayos na organisasyon'
                    : 'Add notes for better organization'),
            _buildTipItem(
                '🔒',
                _isTagalog
                    ? 'Mag-logout kapag gumagamit ng shared devices'
                    : 'Logout when using shared devices'),
            _buildTipItem(
                '📊',
                _isTagalog
                    ? 'Regular na suriin ang dashboard'
                    : 'Review dashboard regularly'),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.help, color: Colors.deepOrange, size: 24),
                const SizedBox(width: 12),
                Text(
                  _isTagalog
                      ? 'Mga Madalas Itanong'
                      : 'Frequently Asked Questions',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              _isTagalog
                  ? 'Maaari ko bang i-edit ang transaksyon?'
                  : 'Can I edit a transaction?',
              _isTagalog
                  ? 'Hindi. Ang mga transaksyon ay permanente para sa katumpakan. Burahin at gumawa ng bago kung kailangan.'
                  : 'No. Transactions are permanent to ensure accuracy. Delete and create a new one if needed.',
            ),
            _buildFAQItem(
              _isTagalog
                  ? 'Paano kung duplicate ang reference?'
                  : 'What if reference is duplicate?',
              _isTagalog
                  ? 'Babala ka ng app at hindi makakapag-save. Bawat reference ay dapat unique.'
                  : 'The app will warn you and prevent saving. Each reference must be unique.',
            ),
            _buildFAQItem(
              _isTagalog
                  ? 'Gumagana ba ang OCR sa lahat ng resibo?'
                  : 'Does OCR work on all receipts?',
              _isTagalog
                  ? 'Oo! Sinusuportahan na ng app ang iba\'t ibang format ng resibo (GCash, banks, PayMaya, atbp.).'
                  : 'Yes! The app now supports various receipt formats (GCash, banks, PayMaya, etc.).',
            ),
            _buildFAQItem(
              _isTagalog
                  ? 'Ano ang Available Funds?'
                  : 'What is Available Funds?',
              _isTagalog
                  ? 'Ang iyong kasalukuyang balanse: Kabuuang Cash In minus Kabuuang Cash Out (walang bayad).'
                  : 'Your current balance: Total Cash In minus Total Cash Out (fees excluded).',
            ),
            _buildFAQItem(
              _isTagalog
                  ? 'Paano ko buburahin ang transaksyon?'
                  : 'How do I delete a transaction?',
              _isTagalog
                  ? 'I-tap ang transaksyon sa history at piliin ang delete option.'
                  : 'Tap the transaction in history and select delete option.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: TextStyle(fontSize: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Q: $question',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'A: $answer',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
