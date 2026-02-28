import 'package:flutter/material.dart';
import '../../constants.dart';

enum OrderProcessStatus {
  ordered,          // default
  awbGenerated,
  pickupRequested,
  pickedUp,
  inTransit,
  outForDelivery,
  delivered,
  failed,
  cancelled,
  rto,
  rtoDelivered,
  error,
  pending,
}

extension OrderProcessStatusExtension on OrderProcessStatus {
  String get label {
    switch (this) {
      case OrderProcessStatus.ordered: return "Ordered";
      case OrderProcessStatus.awbGenerated: return "AWB Generated";
      case OrderProcessStatus.pickupRequested: return "Pickup Requested";
      case OrderProcessStatus.pickedUp: return "Picked Up";
      case OrderProcessStatus.inTransit: return "In Transit";
      case OrderProcessStatus.outForDelivery: return "Out for Delivery";
      case OrderProcessStatus.delivered: return "Delivered";
      case OrderProcessStatus.failed: return "Failed";
      case OrderProcessStatus.cancelled: return "Cancelled";
      case OrderProcessStatus.rto: return "Issued";
      case OrderProcessStatus.rtoDelivered: return "Processed";
      case OrderProcessStatus.pending: return "Pending";
      default: return "Unknown";
    }
  }

  Color get color {
    switch (this) {
      case OrderProcessStatus.failed:
      case OrderProcessStatus.cancelled:
      case OrderProcessStatus.error:
        return Colors.red;
      case OrderProcessStatus.rto:
      case OrderProcessStatus.rtoDelivered:
        return Colors.orange;
      case OrderProcessStatus.delivered:
        return successColor;
      case OrderProcessStatus.ordered:
      case OrderProcessStatus.pending:
        return Colors.blue;
      default:
        return Colors.blue;
    }
  }

  IconData get icon {
    switch (this) {
      case OrderProcessStatus.failed:
      case OrderProcessStatus.cancelled:
      case OrderProcessStatus.error:
        return Icons.close;
      case OrderProcessStatus.rto:
      case OrderProcessStatus.rtoDelivered:
        return Icons.autorenew;
      case OrderProcessStatus.delivered:
        return Icons.check;
      default:
        return Icons.access_time;
    }
  }
}

class OrderStatusBadge extends StatelessWidget {
  final OrderProcessStatus status;
  const OrderStatusBadge({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(defaultBorderRadious),
        border: Border.all(color: status.color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 4),
          Text(
            status.label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: status.color,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}

class OrderProgress extends StatelessWidget {
  const OrderProgress({
    super.key,
    required this.orderStatus,
    this.isCanceled = false,
    this.isReturned = false,
    this.isRefundInitiated = false,
    this.isRefundCompleted = false,
    this.isExchanged = false,
    this.isExchangeInitiated = false,
    this.isExchangeCompleted = false,
  });

  final OrderProcessStatus orderStatus;
  final bool isCanceled;
  final bool isReturned;
  final bool isRefundInitiated;
  final bool isRefundCompleted;
  final bool isExchanged;
  final bool isExchangeInitiated;
  final bool isExchangeCompleted;

  bool _isFailureState(OrderProcessStatus s) {
    return s == OrderProcessStatus.failed ||
        s == OrderProcessStatus.cancelled ||
        s == OrderProcessStatus.rto ||
        s == OrderProcessStatus.rtoDelivered;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _step("Ordered", stepStatus: OrderProcessStatus.ordered, isCompleted: true),
        _step("AWB", stepStatus: OrderProcessStatus.awbGenerated),
        _step("Pickup", stepStatus: OrderProcessStatus.pickupRequested),
        _step("In Transit", stepStatus: OrderProcessStatus.inTransit),
        _step("Delivered", stepStatus: OrderProcessStatus.delivered, isLast: true),
      ],
    );
  }

  Widget _step(String title, {OrderProcessStatus? stepStatus, bool isCompleted = false, bool isLast = false}) {
    bool isStepCompleted(OrderProcessStatus step, OrderProcessStatus current) {
      const flow = [
        OrderProcessStatus.ordered,
        OrderProcessStatus.awbGenerated,
        OrderProcessStatus.pickupRequested,
        OrderProcessStatus.inTransit,
        OrderProcessStatus.delivered,
      ];
      final stepIndex = flow.indexOf(step);
      final currentIndex = flow.indexOf(current);
      if (stepIndex == -1 || currentIndex == -1) return false;
      return stepIndex <= currentIndex;
    }

    final completed = isCompleted || (stepStatus != null && !_isFailureState(orderStatus) && isStepCompleted(stepStatus, orderStatus));

    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(child: Container(height: 2, color: completed ? successColor : blackColor20)),
              _statusWidget(completed: completed, isCurrent: stepStatus == orderStatus, stepStatus: stepStatus),
              Expanded(child: Container(height: 2, color: isLast ? Colors.transparent : (completed ? successColor : blackColor20))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusWidget({required bool completed, required bool isCurrent, OrderProcessStatus? stepStatus}) {
    Color bgColor = blackColor20;
    IconData? icon;
    Color iconColor = Colors.white;

    if (isCurrent || completed) {
      bgColor = stepStatus?.color ?? successColor;
      icon = stepStatus?.icon ?? Icons.check;
    }

    return CircleAvatar(
      radius: 10,
      backgroundColor: bgColor,
      child: icon != null ? Icon(icon, size: 12, color: iconColor) : null,
    );
  }
}
