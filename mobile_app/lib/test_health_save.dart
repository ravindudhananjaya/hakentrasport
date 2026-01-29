import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'models/employee.dart';

/// Simple test screen to verify Firebase health data save
class TestHealthSaveScreen extends StatelessWidget {
  const TestHealthSaveScreen({super.key});

  Future<void> _runTest(BuildContext context) async {
    print('\n\n=== STARTING FIREBASE HEALTH DATA TEST ===\n');

    try {
      // Step 1: Create test health data
      print('Step 1: Creating test health data...');
      final testHealthData = HealthCheckData(
        healthCondition: 'Good',
        temperature: 36.5,
        timestamp: DateTime.now().toIso8601String(),
      );
      print('✓ Created: $testHealthData');
      print('  JSON: ${testHealthData.toJson()}');

      // Step 2: Get first employee from Firebase
      print('\nStep 2: Fetching employee from Firebase...');
      final snapshot = await FirebaseFirestore.instance
          .collection('employees')
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        print('❌ ERROR: No employees found in Firebase');
        return;
      }

      final doc = snapshot.docs.first;
      final employeeData = doc.data();
      print('✓ Found employee: ${employeeData['name']}');
      print('  ID: ${doc.id}');

      // Step 3: Create employee object
      print('\nStep 3: Creating employee object...');
      final employee = Employee.fromJson(employeeData);
      print('✓ Employee loaded');
      print('  Current health checks: ${employee.weeklyHealthChecks}');

      // Step 4: Update health checks
      print('\nStep 4: Updating health checks...');
      final newHealthChecks = List<HealthCheckData?>.filled(5, null);
      newHealthChecks[0] = testHealthData;
      print('✓ New health checks created');
      print('  Week 0: ${newHealthChecks[0]}');

      // Step 5: Create updated employee
      print('\nStep 5: Creating updated employee...');
      final updatedEmployee = employee.copyWith(
        weeklyHealthChecks: newHealthChecks,
        lastUpdated: DateTime.now().toIso8601String(),
      );
      print('✓ Updated employee created');

      // Step 6: Convert to JSON
      print('\nStep 6: Converting to JSON...');
      final jsonData = updatedEmployee.toJson();
      print('✓ JSON created');
      print('  weeklyHealthChecks in JSON: ${jsonData['weeklyHealthChecks']}');

      // Step 7: Save to Firebase
      print('\nStep 7: Saving to Firebase...');
      await FirebaseFirestore.instance
          .collection('employees')
          .doc(doc.id)
          .set(jsonData, SetOptions(merge: true));
      print('✓ Saved to Firebase');

      // Step 8: Verify by reading back
      print('\nStep 8: Reading back from Firebase...');
      final verifyDoc = await FirebaseFirestore.instance
          .collection('employees')
          .doc(doc.id)
          .get();

      final verifyData = verifyDoc.data();
      print('✓ Read back from Firebase');
      print('  weeklyHealthChecks: ${verifyData?['weeklyHealthChecks']}');

      if (verifyData?['weeklyHealthChecks'] != null) {
        print('\n✅ SUCCESS! Health data is in Firebase!');
      } else {
        print('\n❌ FAILED! Health data not in Firebase!');
      }

      print('\n=== TEST COMPLETE ===\n\n');

      // Show result to user
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verifyData?['weeklyHealthChecks'] != null
                  ? '✅ Test PASSED! Check console for details.'
                  : '❌ Test FAILED! Check console for details.',
            ),
            backgroundColor: verifyData?['weeklyHealthChecks'] != null
                ? Colors.green
                : Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('\n❌ ERROR during test:');
      print(e);
      print(stackTrace);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Test ERROR: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Health Data Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.science, size: 100, color: Colors.blue),
            const SizedBox(height: 32),
            const Text(
              'Firebase Health Data Test',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                'This will test if health check data can be saved to Firebase.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _runTest(context),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Test'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Check console for detailed output',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
