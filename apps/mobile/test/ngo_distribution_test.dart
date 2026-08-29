import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/models_exports.dart';
import 'package:mobile/providers/ngo_distribution_provider.dart';

void main() {
  group('NGO Resource Distribution Domain Model Tests', () {
    test('ResourceDistribution fromJson & toJson works correctly', () {
      final now = DateTime.now();
      final dist = ResourceDistribution(
        id: 'dist-test-1',
        ngoId: 'ngo-99',
        ngoName: 'Test Seva Trust',
        title: 'Free Water Bottles',
        category: DistributionCategory.WATER,
        quantity: 500,
        unit: 'bottles',
        remainingQuantity: 350,
        latitude: 18.5204,
        longitude: 73.8567,
        locationName: 'Alandi Route',
        distributionDate: now,
        startTime: now.subtract(const Duration(minutes: 10)),
        endTime: now.add(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now,
      );

      final json = dist.toJson();
      expect(json['id'], equals('dist-test-1'));
      expect(json['category'], equals('WATER'));
      expect(json['remaining_quantity'], equals(350));

      final parsed = ResourceDistribution.fromJson(json);
      expect(parsed.title, equals('Free Water Bottles'));
      expect(parsed.category, equals(DistributionCategory.WATER));
      expect(parsed.remainingQuantity, equals(350));
    });

    test('computedAvailabilityStatus calculates states based on remaining ratio', () {
      final now = DateTime.now();
      ResourceDistribution createWithRemaining(int rem, int total) {
        return ResourceDistribution(
          id: 'test',
          ngoId: 'ngo',
          ngoName: 'NGO',
          title: 'Test',
          category: DistributionCategory.FOOD,
          quantity: total,
          unit: 'meals',
          remainingQuantity: rem,
          latitude: 18.5,
          longitude: 73.8,
          locationName: 'Site',
          distributionDate: now,
          startTime: now,
          createdAt: now,
          updatedAt: now,
        );
      }

      expect(createWithRemaining(500, 500).computedAvailabilityStatus, equals('AVAILABLE'));
      expect(createWithRemaining(180, 500).computedAvailabilityStatus, equals('LIMITED'));
      expect(createWithRemaining(50, 500).computedAvailabilityStatus, equals('ALMOST_FINISHED'));
      expect(createWithRemaining(0, 500).computedAvailabilityStatus, equals('FINISHED'));
    });

    test('computedDistributionStatus calculates lifecycle states correctly', () {
      final now = DateTime.now();
      final activeDist = ResourceDistribution(
        id: '1',
        ngoId: 'ngo',
        ngoName: 'NGO',
        title: 'Active',
        category: DistributionCategory.FOOD,
        quantity: 100,
        unit: 'meals',
        remainingQuantity: 100,
        latitude: 18.5,
        longitude: 73.8,
        locationName: 'Site',
        distributionDate: now,
        startTime: now.subtract(const Duration(minutes: 15)),
        endTime: now.add(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now,
      );
      expect(activeDist.computedDistributionStatus, equals('ACTIVE'));
      expect(activeDist.isActive, isTrue);

      final cancelledDist = activeDist.copyWith(cancelledAt: now);
      expect(cancelledDist.computedDistributionStatus, equals('CANCELLED'));
      expect(cancelledDist.isActive, isFalse);

      final finishedDist = activeDist.copyWith(remainingQuantity: 0);
      expect(finishedDist.computedDistributionStatus, equals('COMPLETED'));
      expect(finishedDist.isActive, isFalse);
    });
  });

  group('NgoDistributionProvider Logic & Filtering Tests', () {
    test('Provider filters distributions by category correctly', () {
      final provider = NgoDistributionProvider();
      expect(provider.activeDistributions.isNotEmpty, isTrue);

      provider.setCategoryFilter('FOOD');
      final foodItems = provider.filteredDistributions;
      expect(foodItems.every((d) => d.category == DistributionCategory.FOOD), isTrue);

      provider.setCategoryFilter('WATER');
      final waterItems = provider.filteredDistributions;
      expect(waterItems.every((d) => d.category == DistributionCategory.WATER), isTrue);
    });

    test('Provider quantity update updates local state correctly', () async {
      final provider = NgoDistributionProvider();
      final firstId = provider.activeDistributions.first.id;

      await provider.updateQuantity(firstId, 'ngo-001', 50);

      final updated = provider.activeDistributions.firstWhere((d) => d.id == firstId);
      expect(updated.remainingQuantity, equals(50));
    });
  });
}
