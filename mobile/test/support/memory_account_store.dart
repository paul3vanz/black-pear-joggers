import 'package:bpj/core/auth/account.dart';
import 'package:bpj/core/auth/account_store.dart';

/// In-memory keystore with the same observable behaviour as [AccountStore]
/// (accounts, active account, credentials), for tests that run the real
/// `AccountsController`.
class MemoryAccountStore implements AccountStore {
  MemoryAccountStore(List<Account> accounts)
    : accounts = [...accounts],
      active = accounts.isEmpty ? null : accounts.first.sub {
    for (final a in accounts) {
      credentials[a.sub] = StoredCredentials(
        accessToken: 'access-${a.sub}',
        refreshToken: 'refresh-${a.sub}',
        expiresAt: DateTime.utc(2099),
      );
    }
  }

  List<Account> accounts;
  String? active;
  final Map<String, StoredCredentials> credentials = {};

  @override
  Future<List<Account>> readAccounts() async => [...accounts];
  @override
  Future<String?> readActiveSub() async => active;
  @override
  Future<void> writeActiveSub(String? sub) async => active = sub;
  @override
  Future<int?> readActiveClubId(String sub) async => null;
  @override
  Future<StoredCredentials?> readCredentials(String sub) async =>
      credentials[sub];
  @override
  Future<void> removeAccount(String sub) async {
    accounts = accounts.where((a) => a.sub != sub).toList();
    credentials.remove(sub);
    if (active == sub) active = accounts.isEmpty ? null : accounts.first.sub;
  }

  @override
  Object? noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} is not faked');
}
