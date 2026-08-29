import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../core/utils/app_logger.dart';
import '../models/models_exports.dart';

/// Production-ready Firestore Repository for Real-Time NGO Resource Distributions.
class NgoDistributionRepository {
  final FirebaseFirestore? _firestore;

  NgoDistributionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? (Firebase.apps.isEmpty ? null : FirebaseFirestore.instance);

  CollectionReference<Map<String, dynamic>>? get _collection =>
      _firestore?.collection('resource_deployments');

  /// Realtime stream of all active and published resource distributions.
  Stream<List<ResourceDistribution>> streamActiveDistributions() {
    try {
      if (Firebase.apps.isEmpty || _collection == null) {
        return Stream.value([]);
      }
      return _collection!
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ResourceDistribution.fromJson(data);
        }).toList();
      });
    } catch (e) {
      AppLogger.i('Firestore streamActiveDistributions error: $e');
      return Stream.value([]);
    }
  }

  /// Realtime stream of distributions for a specific NGO account.
  Stream<List<ResourceDistribution>> streamNgoDistributions(String ngoId) {
    try {
      if (Firebase.apps.isEmpty || _collection == null) {
        return Stream.value([]);
      }
      return _collection!
          .where('ngo_id', isEqualTo: ngoId)
          .snapshots()
          .map((snapshot) {
        final list = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return ResourceDistribution.fromJson(data);
        }).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      });
    } catch (e) {
      AppLogger.i('Firestore streamNgoDistributions error: $e');
      return Stream.value([]);
    }
  }

  /// Create a new resource distribution in Cloud Firestore.
  Future<ResourceDistribution> createDistribution(ResourceDistribution distribution) async {
    if (_collection == null) return distribution;
    final docRef = _collection!.doc(distribution.id.isNotEmpty ? distribution.id : null);
    final processed = distribution.copyWith(id: docRef.id);

    try {
      await docRef.set(processed.toJson());

      // If connected to resource_inventory, deduct quantity safely
      if (processed.inventoryItemId != null && processed.inventoryItemId!.isNotEmpty) {
        await _deductInventory(processed.inventoryItemId!, processed.quantity);
      }

      await _logAudit('RESOURCE_CREATED', processed.id, processed.ngoId, {
        'title': processed.title,
        'category': processed.category.name,
        'quantity': processed.quantity,
      });
    } catch (e) {
      AppLogger.i('Warning: Firestore createDistribution notice: $e');
    }

    return processed;
  }

  /// Update an existing resource distribution.
  Future<void> updateDistribution(ResourceDistribution distribution) async {
    if (_collection == null) return;
    try {
      await _collection!.doc(distribution.id).set(
        distribution.toJson(),
        SetOptions(merge: true),
      );

      await _logAudit('RESOURCE_UPDATED', distribution.id, distribution.ngoId, {
        'remaining_quantity': distribution.remainingQuantity,
        'availability_status': distribution.computedAvailabilityStatus,
      });
    } catch (e) {
      AppLogger.i('Warning: Firestore updateDistribution notice: $e');
    }
  }

  /// Realtime quantity update by NGO coordinator.
  Future<void> updateQuantity(String distributionId, String ngoId, int newRemainingQuantity) async {
    if (_collection == null) return;
    final safeQty = newRemainingQuantity < 0 ? 0 : newRemainingQuantity;
    try {
      await _collection!.doc(distributionId).update({
        'remaining_quantity': safeQty,
        'updated_at': DateTime.now().toIso8601String(),
        if (safeQty == 0) 'completed_at': DateTime.now().toIso8601String(),
      });

      await _logAudit('RESOURCE_QUANTITY_UPDATED', distributionId, ngoId, {
        'remaining_quantity': safeQty,
      });
    } catch (e) {
      AppLogger.i('Warning: Firestore updateQuantity notice: $e');
    }
  }

  /// Realtime queue / crowd metrics update by NGO coordinator.
  Future<void> updateQueue(
    String distributionId,
    String ngoId, {
    required int currentQueue,
    required int estWaitMinutes,
  }) async {
    if (_collection == null) return;
    try {
      await _collection!.doc(distributionId).update({
        'current_queue': currentQueue,
        'estimated_queue_minutes': estWaitMinutes,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _logAudit('RESOURCE_QUEUE_UPDATED', distributionId, ngoId, {
        'current_queue': currentQueue,
        'estimated_queue_minutes': estWaitMinutes,
      });
    } catch (e) {
      AppLogger.i('Warning: Firestore updateQueue notice: $e');
    }
  }

  /// Cancel a distribution.
  Future<void> cancelDistribution(String distributionId, String ngoId) async {
    if (_collection == null) return;
    final now = DateTime.now().toIso8601String();
    try {
      await _collection!.doc(distributionId).update({
        'cancelled_at': now,
        'updated_at': now,
      });

      await _logAudit('RESOURCE_CANCELLED', distributionId, ngoId);
    } catch (e) {
      AppLogger.i('Warning: Firestore cancelDistribution notice: $e');
    }
  }

  /// Mark a distribution completed.
  Future<void> completeDistribution(String distributionId, String ngoId) async {
    if (_collection == null) return;
    final now = DateTime.now().toIso8601String();
    try {
      await _collection!.doc(distributionId).update({
        'remaining_quantity': 0,
        'completed_at': now,
        'updated_at': now,
      });

      await _logAudit('RESOURCE_COMPLETED', distributionId, ngoId);
    } catch (e) {
      AppLogger.i('Warning: Firestore completeDistribution notice: $e');
    }
  }

  /// Admin verification toggle.
  Future<void> adminVerifyDistribution(String distributionId, String adminUid, bool isVerified) async {
    if (_collection == null) return;
    try {
      await _collection!.doc(distributionId).update({
        'is_verified': isVerified,
        'updated_at': DateTime.now().toIso8601String(),
      });

      await _logAudit('RESOURCE_VERIFIED', distributionId, adminUid, {'is_verified': isVerified});
    } catch (e) {
      AppLogger.i('Warning: Firestore adminVerifyDistribution notice: $e');
    }
  }

  /// Safely update resource_inventory collection quantity.
  Future<void> _deductInventory(String inventoryItemId, int allocatedQuantity) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final itemRef = firestore.collection('resource_inventory').doc(inventoryItemId);
      final doc = await itemRef.get();
      if (doc.exists && doc.data() != null) {
        final currentRem = doc.data()!['remaining_quantity'] as int? ?? 1000;
        final currentAlloc = doc.data()!['allocated_quantity'] as int? ?? 0;
        final newRem = (currentRem - allocatedQuantity) < 0 ? 0 : (currentRem - allocatedQuantity);
        await itemRef.update({
          'remaining_quantity': newRem,
          'allocated_quantity': currentAlloc + allocatedQuantity,
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      AppLogger.i('Notice: Inventory item deduction update: $e');
    }
  }

  /// Record audit log entry in Firestore audit_logs collection.
  Future<void> _logAudit(String action, String resourceId, String actorUid, [Map<String, dynamic>? metadata]) async {
    final firestore = _firestore;
    if (firestore == null) return;
    try {
      final logId = 'log_${DateTime.now().millisecondsSinceEpoch}';
      await firestore.collection('audit_logs').doc(logId).set({
        'id': logId,
        'action': action,
        'target': 'resource_distributions/$resourceId',
        'actor_uid': actorUid,
        'timestamp': DateTime.now().toIso8601String(),
        'metadata': metadata ?? {},
      });
    } catch (e) {
      AppLogger.i('Audit logger notice: $e');
    }
  }
}
