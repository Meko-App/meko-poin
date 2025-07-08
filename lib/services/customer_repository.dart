import '../models/customer.dart';
import 'database_helper.dart';

class CustomerRepository {
  final DatabaseHelper dbHelper;

  CustomerRepository(this.dbHelper);

  Future<int> insertCustomer(Customer customer) async {
    final db = await dbHelper.database;
    return await db.insert('Data_Customer', customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final db = await dbHelper.database;
    final result = await db.query('Data_Customer');
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Customer',
      where: 'id = ?',
      whereArgs: [id],
    );
    return result.isNotEmpty ? Customer.fromMap(result.first) : null;
  }

  Future<int> updateCustomer(Customer customer) async {
    final db = await dbHelper.database;
    return await db.update(
      'Data_Customer',
      customer.toMap(),
      where: 'id = ?',
      whereArgs: [customer.id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await dbHelper.database;
    return await db.delete(
      'Data_Customer',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Customer>> searchCustomers(String query) async {
    final db = await dbHelper.database;
    final result = await db.query(
      'Data_Customer',
      where: 'name LIKE ? OR phone LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
    );
    return result.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> findCustomerByPhone(String phone) async {
    final db = await DatabaseHelper.instance.database;
    final results = await db.query(
      'Data_Customer',
      where: 'phone = ?',
      whereArgs: [phone],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return Customer.fromMap(results.first);
    }
    return null;
  }
}
