import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F4_231A290134',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0468D7)),
      ),
      // Màn hình đầu tiên của app (tương đương Activity có intent-filter LAUNCHER)
      home: const ContactListPage(),
      // Named routes: khai báo sẵn "địa chỉ" của các màn hình dùng lại nhiều nơi
      routes: {AboutPage.routeName: (context) => const AboutPage()},
    );
  }
}

/// Model dữ liệu. Dùng `final` + copyWith để đối tượng bất biến (immutable),
/// tránh việc màn hình con lỡ sửa trực tiếp dữ liệu của màn hình cha.
class Contact {
  final String hoTen;
  final String dienThoai;
  final String email;

  const Contact({required this.hoTen, required this.dienThoai, this.email = ''});

  Contact copyWith({String? hoTen, String? dienThoai, String? email}) => Contact(
        hoTen: hoTen ?? this.hoTen,
        dienThoai: dienThoai ?? this.dienThoai,
        email: email ?? this.email,
      );
}

/// Kết quả mà màn hình Chi tiết trả về cho màn hình Danh sách.
enum DetailAction { updated, deleted }

class DetailResult {
  final DetailAction action;
  final Contact? contact; // null khi action = deleted
  const DetailResult(this.action, [this.contact]);
}

// ===================================================================
// MÀN HÌNH 1 – DANH SÁCH
// ===================================================================
class ContactListPage extends StatefulWidget {
  const ContactListPage({super.key});

  @override
  State<ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  final List<Contact> _danhBa = [
    const Contact(hoTen: 'Nguyễn Văn A', dienThoai: '0901234567', email: 'a@vhu.edu.vn'),
    const Contact(hoTen: 'Trần Thị B', dienThoai: '0912345678', email: 'b@vhu.edu.vn'),
    const Contact(hoTen: 'Lê Văn C', dienThoai: '0987654321'),
  ];

  /// Mở màn hình chi tiết và CHỜ kết quả trả về.
  /// `await` ở đây tương đương registerForActivityResult bên Android.
  Future<void> _moChiTiet(int viTri) async {
    final result = await Navigator.push<DetailResult>(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailPage(contact: _danhBa[viTri]),
      ),
    );

    if (result == null) return; // người dùng bấm Back, không có kết quả
    if (!mounted) return; // widget đã bị gỡ trong lúc chờ → dừng lại

    setState(() {
      if (result.action == DetailAction.deleted) {
        _danhBa.removeAt(viTri);
      } else if (result.contact != null) {
        _danhBa[viTri] = result.contact!;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.action == DetailAction.deleted ? 'Đã xóa' : 'Đã cập nhật'),
      ),
    );
  }

  Future<void> _themMoi() async {
    final moi = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(builder: (context) => const ContactEditPage()),
    );
    if (moi == null || !mounted) return;
    setState(() => _danhBa.add(moi));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh bạ mini'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            // pushNamed: đi tới route đã khai báo sẵn, không cần nhắc tên class
            onPressed: () => Navigator.pushNamed(context, AboutPage.routeName),
          ),
        ],
      ),
      body: _danhBa.isEmpty
          ? const Center(child: Text('Danh bạ trống'))
          : ListView(
              // Lab F5 sẽ thay bằng ListView.builder cho danh sách dài
              children: [
                for (int i = 0; i < _danhBa.length; i++)
                  ListTile(
                    leading: CircleAvatar(child: Text(_danhBa[i].hoTen[0])),
                    title: Text(_danhBa[i].hoTen),
                    subtitle: Text(_danhBa[i].dienThoai),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _moChiTiet(i),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _themMoi,
        child: const Icon(Icons.add),
      ),
    );
  }
}

// ===================================================================
// MÀN HÌNH 2 – CHI TIẾT
// ===================================================================
class ContactDetailPage extends StatelessWidget {
  /// Truyền dữ liệu sang màn hình con bằng tham số của constructor —
  /// gọn và an toàn kiểu hơn hẳn Intent.putExtra bên Android.
  final Contact contact;

  const ContactDetailPage({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar tự thêm nút Back vì màn hình này nằm trên ngăn xếp
      appBar: AppBar(title: Text(contact.hoTen)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _dong(Icons.person, 'Họ tên', contact.hoTen),
            _dong(Icons.phone, 'Điện thoại', contact.dienThoai),
            _dong(Icons.email, 'Email', contact.email.isEmpty ? '(chưa có)' : contact.email),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Sửa'),
              onPressed: () async {
                final sua = await Navigator.push<Contact>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ContactEditPage(banDau: contact),
                  ),
                );
                if (sua == null || !context.mounted) return;
                // pop kèm dữ liệu: trả kết quả ngược về màn hình Danh sách
                Navigator.pop(context, DetailResult(DetailAction.updated, sua));
              },
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline),
              label: const Text('Xóa'),
              onPressed: () =>
                  Navigator.pop(context, const DetailResult(DetailAction.deleted)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dong(IconData icon, String nhan, String giaTri) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(icon),
        title: Text(nhan, style: const TextStyle(fontSize: 13, color: Colors.grey)),
        subtitle: Text(giaTri, style: const TextStyle(fontSize: 17, color: Colors.black87)),
      );
}

// ===================================================================
// MÀN HÌNH 3 – THÊM / SỬA
// ===================================================================
class ContactEditPage extends StatefulWidget {
  /// null = thêm mới, khác null = sửa
  final Contact? banDau;

  const ContactEditPage({super.key, this.banDau});

  @override
  State<ContactEditPage> createState() => _ContactEditPageState();
}

class _ContactEditPageState extends State<ContactEditPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _ten;
  late final TextEditingController _sdt;
  late final TextEditingController _email;
  bool _daSua = false;

  @override
  void initState() {
    super.initState();
    _ten = TextEditingController(text: widget.banDau?.hoTen ?? '');
    _sdt = TextEditingController(text: widget.banDau?.dienThoai ?? '');
    _email = TextEditingController(text: widget.banDau?.email ?? '');
  }

  @override
  void dispose() {
    _ten.dispose();
    _sdt.dispose();
    _email.dispose();
    super.dispose();
  }

  void _luu() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      Contact(
        hoTen: _ten.text.trim(),
        dienThoai: _sdt.text.trim(),
        email: _email.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // PopScope chặn thao tác Back khi còn thay đổi chưa lưu.
    // (Flutter 3.12 trở về trước dùng WillPopScope — đã ngừng hỗ trợ.)
    return PopScope(
      canPop: !_daSua,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final thoat = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Bỏ thay đổi?'),
            content: const Text('Dữ liệu bạn vừa nhập sẽ không được lưu.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ở lại'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Thoát'),
              ),
            ],
          ),
        );
        if (thoat == true && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.banDau == null ? 'Thêm liên hệ' : 'Sửa liên hệ'),
        ),
        body: Form(
          key: _formKey,
          onChanged: () => setState(() => _daSua = true),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _ten,
                decoration: const InputDecoration(
                  labelText: 'Họ và tên',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Không được để trống' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _sdt,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Số điện thoại',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().length < 9)
                    ? 'Số điện thoại không hợp lệ'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (không bắt buộc)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(onPressed: _luu, child: const Text('Lưu')),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================================================================
// MÀN HÌNH PHỤ – dùng named route
// ===================================================================
class AboutPage extends StatelessWidget {
  static const routeName = '/about';

  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giới thiệu')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Lab F4 – Điều hướng đa màn hình\nNguyễn Việt Quang – 231A290134',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
