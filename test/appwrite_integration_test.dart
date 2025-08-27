import 'package:flutter_test/flutter_test.dart';
import 'package:appwrite/appwrite.dart';
import 'package:photo_uploader/app/core/values/environment.dart';

void main() {
  group('Appwrite Integration Tests', () {
    late Client client;
    late Account account;
    late Databases databases;
    
    // Test user credentials
    const testEmail = 'test@example.com';
    const testPassword = 'TestPassword123!';
    const testFullName = 'Test User';
    
    setUp(() {
      // Initialize Flutter binding for tests
      TestWidgetsFlutterBinding.ensureInitialized();
      
      client = Client();
      client
          .setEndpoint(Environment.appwritePublicEndpoint)
          .setProject(Environment.appwriteProjectId)
          .setSelfSigned(status: true);
      
      account = Account(client);
      databases = Databases(client);
    });
    
    test('Client can be initialized', () {
      expect(client, isNotNull);
      expect(account, isNotNull);
      expect(databases, isNotNull);
    });
    
    // Note: These tests require a real Appwrite instance to be running
    // and the database/collections to be set up properly
    
    /*
    test('Can create user account', () async {
      try {
        final user = await account.create(
          userId: ID.unique(),
          email: testEmail,
          password: testPassword,
          name: testFullName,
        );
        expect(user.email, equals(testEmail));
        expect(user.name, equals(testFullName));
      } catch (e) {
        // Handle existing user case
        expect(e, isNotNull);
      }
    });
    
    test('Can sign in user', () async {
      final session = await account.createEmailPasswordSession(
        email: testEmail,
        password: testPassword,
      );
      expect(session.userId, isNotNull);
    });
    
    test('Can get user data', () async {
      final user = await account.get();
      expect(user.email, equals(testEmail));
    });
    
    test('Can sign out user', () async {
      await account.deleteSession(sessionId: 'current');
      // After signing out, getting user data should fail
      try {
        await account.get();
        fail('Should have thrown an exception');
      } on AppwriteException catch (e) {
        expect(e.code, equals(401));
      }
    });
    */
  });
}