import 'package:bpj/features/messages/data/message_dtos.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMember', () {
    test('reads the members endpoint item', () {
      final m = ChatMember.fromJson({
        'memberId': 'm1',
        'name': 'Sam B.',
        'role': 'leader',
      });
      expect(m.name, 'Sam B.');
      expect(m.roleLabel, 'Leader');
    });

    test('an ordinary member has no role tag, a missing name is "Member"', () {
      final m = ChatMember.fromJson({'memberId': 'm2', 'role': 'member'});
      expect(m.name, 'Member');
      expect(m.roleLabel, isEmpty);
    });

    test('coordinator and committee are tagged', () {
      expect(
        const ChatMember(
          memberId: 'a',
          name: 'A',
          role: 'coordinator',
        ).roleLabel,
        'Coordinator',
      );
      expect(
        const ChatMember(memberId: 'b', name: 'B', role: 'committee').roleLabel,
        'Committee',
      );
    });

    test('admin has its own tag', () {
      expect(
        const ChatMember(memberId: 'c', name: 'C', role: 'admin').roleLabel,
        'Admin',
      );
    });
  });
}
