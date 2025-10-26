// lib/screens/benchmark_screen.dart

import 'package:flutter/material.dart';
import '../performance/benchmark.dart';
import '../sqlite/database_helper.dart';
import '../drift/database.dart';

class BenchmarkScreen extends StatefulWidget {
  const BenchmarkScreen({super.key});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  final DatabaseHelper _sqliteDb = DatabaseHelper.instance;
  final AppDatabase _driftDb = AppDatabase();
  late PerformanceBenchmark _benchmark;

  List<BenchmarkResult> _results = [];
  bool _isRunning = false;
  String _currentTest = '';

  @override
  void initState() {
    super.initState();
    _benchmark = PerformanceBenchmark(
      sqliteDb: _sqliteDb,
      driftDb: _driftDb,
    );
  }

  @override
  void dispose() {
    _driftDb.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Benchmark'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          _buildHeader(),
          if (_isRunning) _buildProgressIndicator(),
          Expanded(
            child: _results.isEmpty
                ? _buildEmptyState()
                : _buildResultsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isRunning ? null : _runBenchmarks,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Run Benchmarks'),
        backgroundColor: _isRunning ? Colors.grey : Colors.green,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.green[50],
      child: Column(
        children: [
          const Text(
            '⚡ Performance Test',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Compare SQLite vs Drift on various operations',
            style: TextStyle(color: Colors.grey),
          ),
          if (_results.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildSummary(),
          ],
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final sqliteResults = _results.where((r) => r.operation.startsWith('SQLite')).toList();
    final driftResults = _results.where((r) => r.operation.startsWith('Drift')).toList();

    if (sqliteResults.isEmpty || driftResults.isEmpty) return const SizedBox.shrink();

    final sqliteAvg = sqliteResults.map((r) => r.duration).reduce((a, b) => a + b) / sqliteResults.length;
    final driftAvg = driftResults.map((r) => r.duration).reduce((a, b) => a + b) / driftResults.length;

    final faster = sqliteAvg < driftAvg ? 'SQLite' : 'Drift';
    final diff = sqliteAvg < driftAvg
        ? ((driftAvg - sqliteAvg) / sqliteAvg * 100).toStringAsFixed(1)
        : ((sqliteAvg - driftAvg) / driftAvg * 100).toStringAsFixed(1);

    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildAvgChip('SQLite', sqliteAvg, Colors.blue),
                _buildAvgChip('Drift', driftAvg, Colors.orange),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '🏆 $faster is $diff% faster on average',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvgChip(String label, double avg, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        Chip(
          label: Text('${avg.toStringAsFixed(1)}ms'),
          backgroundColor: color.withOpacity(0.2),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Text(_currentTest, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No benchmark results yet',
            style: TextStyle(fontSize: 20, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap the button below to run tests',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final result = _results[index];
        final isSQLite = result.operation.startsWith('SQLite');

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isSQLite ? Colors.blue : Colors.orange,
              child: Icon(
                isSQLite ? Icons.list : Icons.star,
                color: Colors.white,
              ),
            ),
            title: Text(
              result.operation,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: result.count > 0
                ? Text('${result.count} items')
                : null,
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getSpeedColor(result.duration),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${result.duration}ms',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getSpeedColor(int duration) {
    if (duration < 100) return Colors.green;
    if (duration < 500) return Colors.orange;
    return Colors.red;
  }

  Future<void> _runBenchmarks() async {
    setState(() {
      _isRunning = true;
      _results = [];
      _currentTest = 'Starting benchmarks...';
    });

    try {
      // 1. INSERT Test
      setState(() => _currentTest = 'Testing INSERT performance (1000 items)...');
      await Future.delayed(const Duration(milliseconds: 500));
      _results.add(await _benchmark.benchmarkSQLiteInsert(1000));
      setState(() {});

      _results.add(await _benchmark.benchmarkDriftInsert(1000));
      setState(() {});

      // 2. QUERY Test
      setState(() => _currentTest = 'Testing QUERY performance...');
      await Future.delayed(const Duration(milliseconds: 500));
      _results.add(await _benchmark.benchmarkSQLiteQuery());
      setState(() {});

      _results.add(await _benchmark.benchmarkDriftQuery());
      setState(() {});

      // 3. JOIN Test
      setState(() => _currentTest = 'Testing JOIN performance...');
      await Future.delayed(const Duration(milliseconds: 500));
      _results.add(await _benchmark.benchmarkSQLiteJoin());
      setState(() {});

      _results.add(await _benchmark.benchmarkDriftJoin());
      setState(() {});

      // 4. SEARCH Test
      setState(() => _currentTest = 'Testing SEARCH performance...');
      await Future.delayed(const Duration(milliseconds: 500));
      _results.add(await _benchmark.benchmarkSQLiteSearch('Product'));
      setState(() {});

      _results.add(await _benchmark.benchmarkDriftSearch('Product'));
      setState(() {});

      // 5. AGGREGATE Test
      setState(() => _currentTest = 'Testing AGGREGATE performance...');
      await Future.delayed(const Duration(milliseconds: 500));
      _results.add(await _benchmark.benchmarkSQLiteAggregate());
      setState(() {});

      _results.add(await _benchmark.benchmarkDriftAggregate());
      setState(() {});

      setState(() => _currentTest = 'Benchmarks completed!');
      await Future.delayed(const Duration(seconds: 1));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Benchmarks completed successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Print results to console
      _benchmark.printResults(_results);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isRunning = false;
        _currentTest = '';
      });
    }
  }
}