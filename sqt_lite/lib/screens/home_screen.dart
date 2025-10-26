// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'sqlite_screen.dart';
import 'drift_screen.dart';
import 'benchmark_screen.dart';
import '../sqlite/database_helper.dart';
import '../drift/database.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SQLite vs Drift Comparison'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.storage, size: 100, color: Colors.deepPurple),
              const SizedBox(height: 32),
              const Text(
                'Database Comparison Demo',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text(
                'Compare SQLite and Drift ORMs',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 48),
              _buildOptionCard(
                context,
                'SQLite (Raw)',
                'Traditional sqflite package',
                Icons.list,
                Colors.blue,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SQLiteScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                context,
                'Drift (ORM)',
                'Type-safe database with reactive queries',
                Icons.star,
                Colors.orange,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DriftScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildOptionCard(
                context,
                'Performance Test',
                'Benchmark SQLite vs Drift',
                Icons.assessment,
                Colors.green,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BenchmarkScreen(),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _buildInfoCard(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context,
      String title,
      String subtitle,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return Card(
      elevation: 4,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: _getDatabasePaths(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        return Card(
          color: Colors.grey[100],
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '📁 Database Locations:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'SQLite: ${snapshot.data!['sqlite']}',
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  'Drift: ${snapshot.data!['drift']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, String>> _getDatabasePaths() async {
    final sqlitePath = await DatabaseHelper.instance.getDatabasePath();
    return {
      'sqlite': sqlitePath,
      'drift': 'products_drift.sqlite',
    };
  }
}