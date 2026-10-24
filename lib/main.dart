import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

/// NC3: toàn bộ tên route đặt ở MỘT chỗ để không gõ sai chuỗi ở nhiều nơi.
class AppRoutes {
  static const danhSach = '/';
  static const chiTiet = '/chi-tiet';
  static const sua = '/sua';
  static const timKiem = '/tim-kiem';
  static const gioiThieu = '/gioi-thieu';
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /// NC3: onGenerateRoute nhận RouteSettings (tên route + arguments) rồi tạo màn hình.
  /// LƯU Ý: MaterialPageRoute phải khai báo ĐÚNG kiểu kết quả (<DetailResult>, <Contact>...).
  /// Nếu để mặc định (dynamic), pushNamed<DetailResult> sẽ báo lỗi ép kiểu lúc chạy.
  Route<dynamic>? _taoRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.danhSach:
        return MaterialPageRoute<Object?>(
          builder: (context) => const ContactListPage(),
          settings: settings,
        );
      case AppRoutes.chiTiet:
        final contact = settings.arguments as Contact;
        return MaterialPageRoute<DetailResult>(
          builder: (context) => ContactDetailPage(contact: contact),
          settings: settings,
        );
      case AppRoutes.sua:
        final banDau = settings.arguments as Contact?; // không có arguments = thêm mới
        return MaterialPageRoute<Contact>(
          builder: (context) => ContactEditPage(banDau: banDau),
          settings: settings,
        );
      case AppRoutes.timKiem:
        final danhBa = settings.arguments as List<Contact>;
        return MaterialPageRoute<Contact>(
          builder: (context) => ContactSearchPage(danhBa: danhBa),
          settings: settings,
        );
      case AppRoutes.gioiThieu:
        return MaterialPageRoute<Object?>(
          builder: (context) => const AboutPage(),
          settings: settings,
        );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'F4_231A290134',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0468D7)),
      ),
      initialRoute: AppRoutes.danhSach,
      onGenerateRoute: _taoRoute,
      // Tên route không tồn tại → hiện trang báo lỗi thay vì crash
      onUnknownRoute: (settings) => MaterialPageRoute<Object?>(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Lỗi điều hướng')),
          body: Center(child: Text('Không tìm thấy màn hình "${settings.name}"')),
        ),
      ),
    );
  }
}

/// Model dữ liệu bất biến (immutable): muốn sửa thì tạo bản mới bằng copyWith.
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

  void _thongBao(String noiDung) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(noiDung)));
  }

  /// SĐT là khóa của Hero (NC2) nên không được trùng, nếu không Flutter báo lỗi
  /// "multiple heroes that share the same tag".
  bool _trungSdt(String sdt, {int? boQuaViTri}) {
    for (int i = 0; i < _danhBa.length; i++) {
      if (i != boQuaViTri && _danhBa[i].dienThoai == sdt) return true;
    }
    return false;
  }

  /// Mở màn hình chi tiết bằng pushNamed (NC3) và CHỜ kết quả trả về.
  Future<void> _moChiTiet(int viTri) async {
    final result = await Navigator.pushNamed<DetailResult>(
      context,
      AppRoutes.chiTiet,
      arguments: _danhBa[viTri], // truyền tham số bằng arguments
    );

    if (result == null) return; // người dùng bấm Back, không có kết quả
    if (!mounted) return; // widget đã bị gỡ trong lúc chờ → dừng lại

    final sua = result.contact;
    if (result.action == DetailAction.updated &&
        sua != null &&
        _trungSdt(sua.dienThoai, boQuaViTri: viTri)) {
      _thongBao('Số điện thoại này đã có trong danh bạ, thay đổi không được lưu');
      return;
    }

    setState(() {
      if (result.action == DetailAction.deleted) {
        _danhBa.removeAt(viTri);
      } else if (sua != null) {
        _danhBa[viTri] = sua;
      }
    });

    _thongBao(result.action == DetailAction.deleted ? 'Đã xóa' : 'Đã cập nhật');
  }

  Future<void> _themMoi() async {
    final moi = await Navigator.pushNamed<Contact>(context, AppRoutes.sua);
    if (moi == null || !mounted) return;
    if (_trungSdt(moi.dienThoai)) {
      _thongBao('Số điện thoại này đã có trong danh bạ');
      return;
    }
    setState(() => _danhBa.add(moi));
  }

  /// NC1: mở màn hình Tìm kiếm, nhận về liên hệ được chọn rồi mở chi tiết của nó.
  Future<void> _timKiem() async {
    final chon = await Navigator.pushNamed<Contact>(
      context,
      AppRoutes.timKiem,
      arguments: List<Contact>.unmodifiable(_danhBa),
    );
    if (chon == null || !mounted) return;
    final viTri = _danhBa.indexOf(chon);
    if (viTri >= 0) await _moChiTiet(viTri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh bạ mini'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _timKiem, // NC1
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.pushNamed(context, AppRoutes.gioiThieu),
          ),
        ],
      ),
      body: _danhBa.isEmpty
          ? const Center(child: Text('Danh bạ trống'))
          : ListView(
              children: [
                for (int i = 0; i < _danhBa.length; i++)
                  ListTile(
                    // NC2: Hero – avatar "bay" sang màn hình Chi tiết
                    leading: Hero(
                      tag: 'avatar-${_danhBa[i].dienThoai}',
                      child: CircleAvatar(child: Text(_danhBa[i].hoTen[0])),
                    ),
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
  /// Dữ liệu nhận từ settings.arguments qua onGenerateRoute rồi truyền vào constructor.
  final Contact contact;

  const ContactDetailPage({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(contact.hoTen)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // NC2: cùng tag với avatar ở màn hình Danh sách
            Center(
              child: Hero(
                tag: 'avatar-${contact.dienThoai}',
                child: CircleAvatar(
                  radius: 44,
                  child: Text(contact.hoTen[0], style: const TextStyle(fontSize: 36)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _dong(Icons.person, 'Họ tên', contact.hoTen),
            _dong(Icons.phone, 'Điện thoại', contact.dienThoai),
            _dong(Icons.email, 'Email', contact.email.isEmpty ? '(chưa có)' : contact.email),
            const Spacer(),
            FilledButton.icon(
              icon: const Icon(Icons.edit),
              label: const Text('Sửa'),
              onPressed: () async {
                final sua = await Navigator.pushNamed<Contact>(
                  context,
                  AppRoutes.sua,
                  arguments: contact,
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
// NC1 – MÀN HÌNH TÌM KIẾM: trả về liên hệ được chọn
// ===================================================================
class ContactSearchPage extends StatefulWidget {
  final List<Contact> danhBa;

  const ContactSearchPage({super.key, required this.danhBa});

  @override
  State<ContactSearchPage> createState() => _ContactSearchPageState();
}

class _ContactSearchPageState extends State<ContactSearchPage> {
  final _tuKhoa = TextEditingController();

  @override
  void dispose() {
    _tuKhoa.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = _tuKhoa.text.trim().toLowerCase();
    final ketQua = widget.danhBa
        .where((c) => c.hoTen.toLowerCase().contains(k) || c.dienThoai.contains(k))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Tìm liên hệ')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _tuKhoa,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nhập tên hoặc số điện thoại',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),
          Expanded(
            child: ketQua.isEmpty
                ? const Center(child: Text('Không tìm thấy liên hệ nào'))
                : ListView(
                    children: [
                      for (final c in ketQua)
                        ListTile(
                          leading: CircleAvatar(child: Text(c.hoTen[0])),
                          title: Text(c.hoTen),
                          subtitle: Text(c.dienThoai),
                          // pop kèm liên hệ được chọn → trả về màn hình Danh sách
                          onTap: () => Navigator.pop(context, c),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

// ===================================================================
// MÀN HÌNH PHỤ – dùng named route
// ===================================================================
class AboutPage extends StatelessWidget {
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
