import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../hydration/domain/models.dart';
import '../../account/account_panel.dart';
import '../../pets/domain/pet.dart';
import 'legal_page.dart';
import '../water_suggestion.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.preferences,
    required this.onSave,
    required this.onNotifications,
    required this.notificationsSupported,
    this.notificationError,
    this.onboarding = false,
  });
  final Preferences preferences;
  final Future<void> Function(Preferences) onSave;
  final Future<void> Function(bool) onNotifications;
  final bool notificationsSupported, onboarding;
  final String? notificationError;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final form = GlobalKey<FormState>();
  late final TextEditingController goal, age, weight, height;
  late String sex, pet;
  late int start, end;
  bool saving = false;
  bool dirty = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final p = widget.preferences;
    goal = TextEditingController(text: '${p.goal}');
    age = TextEditingController(text: '${p.age}');
    weight = TextEditingController(text: '${p.weight}');
    height = TextEditingController(text: '${p.height}');
    start = p.startMinute;
    end = p.endMinute;
    sex = p.sex;
    pet = p.pet;
  }

  @override
  void dispose() {
    goal.dispose();
    age.dispose();
    weight.dispose();
    height.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (dirty || saving) return;
    final p = widget.preferences;
    goal.text = '${p.goal}';
    age.text = '${p.age}';
    weight.text = '${p.weight}';
    height.text = '${p.height}';
    start = p.startMinute;
    end = p.endMinute;
    sex = p.sex;
    pet = p.pet;
  }

  Future<void> pickTime(bool beginning) async {
    final minute = beginning ? start : end;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minute ~/ 60, minute: minute % 60),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time != null && mounted) {
      setState(() {
        if (beginning) {
          start = time.hour * 60 + time.minute;
        } else {
          end = time.hour * 60 + time.minute;
        }
      });
    }
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final p = widget.preferences.copyWith(
        goal: int.parse(goal.text),
        age: int.parse(age.text),
        weight: double.parse(weight.text.replaceAll(',', '.')),
        height: double.parse(height.text.replaceAll(',', '.')),
        startMinute: start,
        endMinute: end,
        sex: sex,
        pet: pet,
        onboarded: true,
      );
      p.validate();
      await widget.onSave(p);
    } catch (e) {
      if (mounted) {
        setState(
          () => error = e is FormatException
              ? e.message
              : 'Không lưu được. Hãy thử lại.',
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget suggestionCard() {
    final value = suggestedWater(
      age: int.tryParse(age.text.trim()),
      weight: double.tryParse(weight.text.trim().replaceAll(',', '.')),
      height: double.tryParse(height.text.trim().replaceAll(',', '.')),
    );
    return Container(
      key: const Key('water-suggestion'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: IslandColors.soft,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gợi ý mục tiêu mỗi ngày',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            value == null ? 'Chưa đủ điều kiện tính gợi ý' : '$value ml / ngày',
            key: const Key('suggested-water-value'),
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            value == null
                ? 'Nhập tuổi 18–100, cân nặng 38–102 kg và chiều cao 100–230 cm hợp lệ. Ngoài phạm vi bảng, hãy tự nhập mục tiêu.'
                : 'Ước tính lượng đồ uống theo cân nặng, nội suy bảng NHS và làm tròn 50 ml. Bao gồm nước lọc và đồ uống khác; không gồm nước trong thức ăn.',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Giới tính và chiều cao không điều chỉnh kết quả trong phương pháp này; tuổi giới hạn phạm vi người lớn. Không thay thế chỉ định riêng khi có bệnh, mang thai hoặc cho con bú.',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          FilledButton.tonal(
            key: const Key('apply-water-suggestion'),
            onPressed: value == null || saving
                ? null
                : () => setState(() {
                    goal.text = '$value';
                    dirty = true;
                  }),
            child: const Text('Dùng mục tiêu này'),
          ),
          TextButton(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Nguồn gợi ý'),
                content: const SingleChildScrollView(
                  child: SelectableText(
                    'Gloucestershire Hospitals NHS Foundation Trust — Fluid and caffeine intake for bladder and bowel health, bảng lượng đồ uống theo cân nặng.\n\nhttps://www.gloshospitals.nhs.uk/your-visit/patient-information-leaflets/fluid-and-caffeine-intake-bladder-and-bowel-health-ghpi0533/\n\nApp nội suy giữa các hàng, làm tròn tới 50 ml; đây là cách áp dụng của app, không phải công thức cá nhân hóa được NHS chứng nhận. Điều kiện thời tiết, vận động và sức khỏe có thể thay đổi nhu cầu. Nếu được yêu cầu hạn chế dịch, hãy dùng mục tiêu của bác sĩ.',
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ],
              ),
            ),
            child: const Text('Nguồn và cách tính'),
          ),
        ],
      ),
    );
  }

  Widget numberField(
    String label,
    TextEditingController controller,
    double min,
    double max, {
    bool integer = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: TextInputType.numberWithOptions(decimal: !integer),
    style: const TextStyle(fontSize: 16),
    decoration: InputDecoration(labelText: label),
    onChanged: (_) => setState(() => dirty = true),
    validator: (value) {
      final n = double.tryParse((value ?? '').replaceAll(',', '.'));
      if (n == null ||
          !n.isFinite ||
          n < min ||
          n > max ||
          (integer && n != n.roundToDouble())) {
        return '$min–$max';
      }
      return null;
    },
  );
  @override
  Widget build(BuildContext context) => Form(
    key: form,
    onChanged: () => dirty = true,
    child: ListView(
      key: PageStorageKey(
        widget.onboarding ? 'onboarding-scroll' : 'profile-scroll',
      ),
      padding: const EdgeInsets.all(22),
      children: [
        Text(
          widget.onboarding ? 'Chào mừng đến đảo nhỏ' : 'Góc của bạn',
          style: const TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 6),
        Text(
          widget.onboarding
              ? 'Chăm mình, nuôi niềm vui.'
              : 'Chăm mình theo cách riêng.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: IslandColors.soft,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Text(
            'Mỗi ngụm nhỏ đều được lưu trên máy. Quản lý đăng nhập và đồng bộ ở phần Tài khoản & dữ liệu bên dưới.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(height: 22),
        const Text(
          'Mục tiêu mỗi ngày',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        numberField('Lượng nước · ml', goal, 500, 5000, integer: true),
        const SizedBox(height: 8),
        const Text(
          'Nhập theo bước 50 ml hoặc dùng gợi ý bên dưới. Mục tiêu chỉ đổi sau khi bạn lưu.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 18),
        const Text(
          'Khoảng thời gian nhắc',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => pickTime(true),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Từ ${clockLabel(start)}'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton(
                onPressed: () => pickTime(false),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text('Đến ${clockLabel(end)}'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Text(
          'Bạn đồng hành',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          key: ValueKey('pet-$pet'),
          initialValue: pet,
          decoration: const InputDecoration(labelText: 'Chọn thú nuôi'),
          items: [
            for (final id in ['cat', 'dog', 'fish'])
              DropdownMenuItem(value: id, child: Text(petName(id))),
          ],
          onChanged: (value) => setState(() {
            pet = value!;
            dirty = true;
          }),
        ),
        const SizedBox(height: 8),
        const Text(
          'Ba bạn cùng lớn lên theo lịch sử uống nước. Lv. 3: đang lớn; Lv. 6: trưởng thành. Đổi bạn vẫn giữ tiến độ.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 20),
        const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: sex,
          decoration: const InputDecoration(labelText: 'Giới tính'),
          items: const [
            DropdownMenuItem(
              value: 'unspecified',
              child: Text('Không chia sẻ'),
            ),
            DropdownMenuItem(value: 'female', child: Text('Nữ')),
            DropdownMenuItem(value: 'male', child: Text('Nam')),
          ],
          onChanged: (value) => setState(() => sex = value!),
        ),
        const SizedBox(height: 14),
        numberField('Tuổi', age, 18, 100, integer: true),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: numberField('Cân nặng · kg', weight, 30, 250)),
            const SizedBox(width: 12),
            Expanded(child: numberField('Chiều cao · cm', height, 100, 230)),
          ],
        ),
        const SizedBox(height: 12),
        suggestionCard(),
        if (error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(error!, style: const TextStyle(color: Colors.red)),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: saving ? null : save,
          child: Text(
            saving
                ? 'Đang lưu…'
                : widget.onboarding
                ? 'Bắt đầu cùng ${petName(pet)}'
                : 'Lưu mục tiêu',
          ),
        ),
        if (!widget.onboarding) ...[
          const SizedBox(height: 22),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nhắc uống nước'),
            subtitle: Text(
              widget.notificationsSupported
                  ? 'Nhắc trên điện thoại, kể cả khi app đóng.'
                  : 'Bản web dùng để xem thử; nhắc nền dành cho Android/iOS.',
              style: const TextStyle(fontSize: 14),
            ),
            value: widget.preferences.notifications,
            onChanged: widget.notificationsSupported
                ? (value) async {
                    try {
                      await widget.onNotifications(value);
                    } catch (_) {
                      if (mounted) {
                        setState(
                          () => error =
                              'Không thay đổi được quyền nhắc. Hãy thử lại.',
                        );
                      }
                    }
                  }
                : null,
          ),
          if (widget.notificationError != null)
            Text(
              widget.notificationError!,
              style: const TextStyle(fontSize: 14, color: Colors.deepOrange),
            ),
          const SizedBox(height: 18),
          const AccountPanel(),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => showLicensePage(
              context: context,
              applicationName: 'Little Island',
            ),
            child: const Text('Giấy phép nguồn mở'),
          ),
        ],
        if (widget.onboarding) const AccountPanel(),
        const SizedBox(height: 18),
        TextButton(
          onPressed: () => LegalPage.open(context, 'Quyền riêng tư', 'privacy'),
          child: const Text('Quyền riêng tư'),
        ),
        TextButton(
          onPressed: () =>
              LegalPage.open(context, 'Điều khoản sử dụng', 'terms'),
          child: const Text('Điều khoản sử dụng'),
        ),
        TextButton(
          onPressed: () =>
              LegalPage.open(context, 'Thông tin xóa dữ liệu', 'deletion'),
          child: const Text('Thông tin xóa dữ liệu'),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}
