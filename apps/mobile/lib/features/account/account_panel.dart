import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../app/providers.dart';
import '../../core/backend/backend_config.dart';

class AccountPanel extends ConsumerStatefulWidget {
  const AccountPanel({super.key});
  @override
  ConsumerState<AccountPanel> createState() => _AccountPanelState();
}

class _AccountPanelState extends ConsumerState<AccountPanel> {
  bool merging = false;
  String? mergeMessage;
  Future<bool> confirm(String title, String message, String action) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;
  Future<void> merge() async {
    if (!await confirm(
          'Nhập lịch sử trên máy?',
          'Thêm lịch sử khách vào tài khoản đang đăng nhập. Lần uống trùng ID được bỏ qua; dữ liệu đã xóa trên tài khoản không được khôi phục. Dữ liệu khách này chỉ nhập vào một tài khoản.',
          'Nhập dữ liệu',
        ) ||
        !mounted) {
      return;
    }
    final engine = ref.read(syncProvider),
        guest = ref.read(guestRepositoryProvider);
    setState(() {
      merging = true;
      mergeMessage = null;
    });
    try {
      await engine.importGuest(guest);
      if (mounted) {
        setState(
          () => mergeMessage = engine.error == null
              ? 'Đã nhập và đồng bộ lịch sử khách.'
              : 'Đã nhập vào máy. Đang chờ đồng bộ lên server.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => mergeMessage = 'Chưa nhập được. Cần kết nối server; lịch sử khách có thể đã được nhập vào tài khoản khác.',
        );
      }
    } finally {
      if (mounted) setState(() => merging = false);
    }
  }

  Future<void> localLogin() async {
    final email = TextEditingController(), password = TextEditingController();
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tài khoản thử local'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Chỉ dùng tài khoản kiểm thử đã tạo trên Supabase local.',
            ),
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email thử'),
            ),
            TextField(
              controller: password,
              obscureText: true,
              enableSuggestions: false,
              autocorrect: false,
              decoration: const InputDecoration(labelText: 'Mật khẩu thử'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng nhập'),
          ),
        ],
      ),
    );
    if (approved == true && mounted) {
      await ref
          .read(accountProvider)
          .localLogin(email.text.trim(), password.text);
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
    email.dispose();
    password.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountProvider), sync = ref.watch(syncProvider);
    final user = account.user;
    final identities =
        user?.identities?.map((i) => i.provider).toSet() ?? <String>{};
    final disabled = account.busy || merging || sync.busy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Tài khoản & dữ liệu',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Text(
          user == null
              ? 'Đang dùng trên máy này. Đăng nhập để lưu lịch sử và khôi phục trên điện thoại khác.'
              : 'Đã đăng nhập · ${user.email ?? 'Tài khoản của bạn'}',
          style: const TextStyle(fontSize: 14),
        ),
        if (!BackendConfig.configured)
          const Text(
            'Chưa cấu hình kết nối server cho bản app này.',
            style: TextStyle(fontSize: 14),
          ),
        if (account.initializationError != null)
          Text(account.initializationError!),
        if (user != null) ...[
          const SizedBox(height: 8),
          Text(
            sync.busy
                ? 'Đang đồng bộ…'
                : '${sync.pending} thay đổi chờ gửi · ${sync.lastSync == null ? 'Chưa đồng bộ' : 'Lần cuối ${DateFormat('dd/MM HH:mm').format(sync.lastSync!.toLocal())}'}',
            style: const TextStyle(fontSize: 14),
          ),
          if (sync.error != null)
            Text(
              sync.error!,
              style: const TextStyle(color: Colors.deepOrange, fontSize: 14),
            ),
          if (sync.conflicts > 0)
            Text(
              '${sync.conflicts} xung đột đã dùng dữ liệu mới nhất trên server. Kiểm tra lại lịch sử/mục tiêu.',
              style: const TextStyle(color: Colors.deepOrange, fontSize: 14),
            ),
          TextButton(
            onPressed: disabled ? null : sync.sync,
            child: const Text('Đồng bộ ngay'),
          ),
        ],
        for (final entry in {
          OAuthProvider.google: 'Google',
          OAuthProvider.apple: 'Apple',
          OAuthProvider.facebook: 'Facebook',
        }.entries)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton(
              onPressed:
                  disabled ||
                      identities.contains(entry.key.name) ||
                      !BackendConfig.providerEnabled(entry.key.name) ||
                      account.client == null
                  ? null
                  : () => account.oauth(entry.key, link: user != null),
              child: Text(
                identities.contains(entry.key.name)
                    ? '${entry.value} · Đã liên kết'
                    : !BackendConfig.providerEnabled(entry.key.name)
                    ? '${entry.value} · Chờ cấu hình'
                    : '${user == null ? 'Tiếp tục với' : 'Liên kết'} ${entry.value}',
              ),
            ),
          ),
        if (account.error != null)
          Text(
            account.error!,
            style: const TextStyle(color: Colors.deepOrange, fontSize: 14),
          ),
        if (user == null && BackendConfig.localAuth && account.client != null)
          TextButton(
            onPressed: disabled ? null : localLogin,
            child: const Text('Đăng nhập tài khoản thử local'),
          ),
        if (user != null) ...[
          TextButton(
            onPressed: disabled ? null : merge,
            child: Text(merging ? 'Đang nhập…' : 'Nhập lịch sử khách trên máy'),
          ),
          if (mergeMessage != null)
            Text(mergeMessage!, style: const TextStyle(fontSize: 14)),
          TextButton(
            onPressed: disabled
                ? null
                : () async {
                    if (!await confirm(
                          'Đăng xuất trên máy này?',
                          '${sync.pending > 0 ? 'Còn ${sync.pending} thay đổi chưa gửi. ' : ''}Dữ liệu tài khoản được giữ riêng trên máy và tiếp tục gửi khi bạn đăng nhập lại đúng tài khoản. Bạn sẽ quay về chế độ khách.',
                          'Đăng xuất',
                        ) ||
                        !mounted) {
                      return;
                    }
                    await ref.read(accountProvider).signOut();
                  },
            child: const Text('Đăng xuất'),
          ),
        ],
      ],
    );
  }
}
