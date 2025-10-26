// lib/performance/benchmark.dart

import 'dart:math';
import 'package:flutter/foundation.dart';
import '../sqlite/database_helper.dart';
import '../sqlite/models.dart';
import '../drift/database.dart';
import 'package:drift/drift.dart' as drift;

class PerformanceBenchmark {
  final DatabaseHelper sqliteDb;
  final AppDatabase driftDb;

  PerformanceBenchmark({
    required this.sqliteDb,
    required this.driftDb,
  });

  // ========== GENERATE TEST DATA ==========

  List<SQLiteProduct> generateSQLiteProducts(int count, int categoryId) {
    final random = Random();
    return List.generate(count, (index) {
      return SQLiteProduct(
        name: 'Product $index',
        price: random.nextDouble() * 1000,
        categoryId: categoryId,
        stock: random.nextInt(100),
      );
    });
  }

  List<ProductsCompanion> generateDriftProducts(int count, int categoryId) {
    final random = Random();
    return List.generate(count, (index) {
      return ProductsCompanion.insert(
        name: 'Product $index',
        price: random.nextDouble() * 1000,
        categoryId: categoryId,
        stock: drift.Value(random.nextInt(100)),
      );
    });
  }

  // ========== BENCHMARK FUNCTIONS ==========

  Future<BenchmarkResult> benchmarkSQLiteInsert(int count) async {
    final products = generateSQLiteProducts(count, 1);

    final stopwatch = Stopwatch()..start();
    await sqliteDb.batchInsertProducts(products);
    stopwatch.stop();

    return BenchmarkResult(
      operation: 'SQLite Batch Insert',
      count: count,
      duration: stopwatch.elapsedMilliseconds,
    );
  }

  Future<BenchmarkResult> benchmarkDriftInsert(int count) async {
    final products = generateDriftProducts(count, 1);

    final stopwatch = Stopwatch()..start();
    await driftDb.batchInsertProducts(products);
    stopwatch.stop();

    return BenchmarkResult(
      operation: 'Drift Batch Insert',
      count: count,
      duration: stopwatch.elapsedMilliseconds,
    );
  }

  Future<BenchmarkResult> benchmarkSQLiteQuery() async {
    final stopwatch = Stopwatch()..start();
    final products = await sqliteDb.readAllProducts();
    stopwatch.stop();

    return BenchmarkResult(
      operation: 'SQLite Query All',
      count: products.length,
      duration: stopwatch.elapsedMilliseconds,
    );
  }

  Future<BenchmarkResult> benchmarkDriftQuery() async {
    final stopwatch = Stopwatch()..start();
    final products = await driftDb.getAllProducts();
    stopwatch.stop();

    return BenchmarkResult(
      operation: 'Drift Query All',
      count: products.length,
      duration: stopwatch.elapsedMilliseconds,
    );
  }

  Future<BenchmarkResult> benchmarkSQLiteJoin() async {
    final stopwatch = Stopwatch()..start();
    final results = await sqliteDb.getProductsWithCategory();
    stopwatch.stop();

    return BenchmarkResult(
      operation: 'SQLite JOIN Query',
      count: results.length,
      duration: stopwatch.elapsedMilliseconds,
    );
  }

  Future<BenchmarkResult> benchmarkDriftJoin() async {
    final stopwatch = Stopwatch()..start();
    final results = await driftDb.getProductsWithCategory();
    stopwatch.stop();

    return BenchmarkResult(
      operation: 'Drift JOIN Query',
      count: results.length,
      duration: stopwatch.elapsedMilliseconds,
    );
  }

  Future<BenchmarkResult> benchmarkSQLiteSearch(String query) async {
    final stopwatch = Stopwatch()..start();
    final results = await sqliteDb.searchProducts(query);
    stopwatch.stop();

    return BenchmarkResult(
      operation: 'SQLite Search',
      count: results.length,
      duration: stopwatch.elapsedMilliseconds,
    );
  }

  Future<BenchmarkResult> benchmarkDriftSearch(String query) async {
    final stopwatch = Stopwatch()..start();
    final results = await driftDb.searchProducts(query);
    stopwatch.stop();

    return BenchmarkResult(
      operation: 'Drift Search',
      count: results.length,
      duration: stopwatch.elapsedMilliseconds,
    );
  }

  Future<BenchmarkResult> benchmarkSQLiteAggregate() async {
    final stopwatch = Stopwatch()..start();
    await sqliteDb.getStockByCategory();
    stopwatch.stop();

    return BenchmarkResult(
      operation: 'SQLite Aggregate',
      count: 0,
      duration: stopwatch.elapsedMilliseconds,
    );
  }

  Future<BenchmarkResult> benchmarkDriftAggregate() async {
    final stopwatch = Stopwatch()..start();
    await driftDb.getStockByCategory();
    stopwatch.stop();

    return BenchmarkResult(
      operation: 'Drift Aggregate',
      count: 0,
      duration: stopwatch.elapsedMilliseconds,
    );
  }

  // ========== RUN ALL BENCHMARKS ==========

  Future<List<BenchmarkResult>> runAllBenchmarks() async {
    final results = <BenchmarkResult>[];

    debugPrint('🚀 Starting Performance Benchmarks...\n');

    try {
      debugPrint('📊 Testing INSERT performance...');
      results.add(await benchmarkSQLiteInsert(1000));
      results.add(await benchmarkDriftInsert(1000));

      debugPrint('📊 Testing QUERY performance...');
      results.add(await benchmarkSQLiteQuery());
      results.add(await benchmarkDriftQuery());

      debugPrint('📊 Testing JOIN performance...');
      results.add(await benchmarkSQLiteJoin());
      results.add(await benchmarkDriftJoin());

      debugPrint('📊 Testing SEARCH performance...');
      results.add(await benchmarkSQLiteSearch('Product'));
      results.add(await benchmarkDriftSearch('Product'));

      debugPrint('📊 Testing AGGREGATE performance...');
      results.add(await benchmarkSQLiteAggregate());
      results.add(await benchmarkDriftAggregate());

      debugPrint('\n✅ Benchmarks completed!');
    } catch (e) {
      debugPrint('❌ Benchmark error: $e');
    }

    return results;
  }

  void printResults(List<BenchmarkResult> results) {
    if (results.isEmpty) return;

    final separator = '=' * 60;
    debugPrint('\n$separator');
    debugPrint('PERFORMANCE BENCHMARK RESULTS');
    debugPrint(separator);

    for (var result in results) {
      final opName = result.operation.padRight(25);
      final count = result.count.toString().padLeft(5);
      debugPrint('$opName | Count: $count | Time: ${result.duration}ms');
    }

    debugPrint(separator);

    final sqliteResults = results.where((r) => r.operation.startsWith('SQLite')).toList();
    final driftResults = results.where((r) => r.operation.startsWith('Drift')).toList();

    if (sqliteResults.isEmpty || driftResults.isEmpty) return;

    final sqliteAvg = sqliteResults.map((r) => r.duration).reduce((a, b) => a + b) / sqliteResults.length;
    final driftAvg = driftResults.map((r) => r.duration).reduce((a, b) => a + b) / driftResults.length;

    debugPrint('\n📈 SUMMARY:');
    debugPrint('  SQLite Average: ${sqliteAvg.toStringAsFixed(2)}ms');
    debugPrint('  Drift Average: ${driftAvg.toStringAsFixed(2)}ms');

    if (sqliteAvg < driftAvg) {
      final diff = ((driftAvg - sqliteAvg) / sqliteAvg * 100).toStringAsFixed(1);
      debugPrint('  ✓ SQLite is $diff% faster on average');
    } else {
      final diff = ((sqliteAvg - driftAvg) / driftAvg * 100).toStringAsFixed(1);
      debugPrint('  ✓ Drift is $diff% faster on average');
    }
    debugPrint('$separator\n');
  }
}

class BenchmarkResult {
  final String operation;
  final int count;
  final int duration;

  BenchmarkResult({
    required this.operation,
    required this.count,
    required this.duration,
  });

  Map<String, dynamic> toJson() => {
    'operation': operation,
    'count': count,
    'duration_ms': duration,
  };
}