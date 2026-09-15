enum CentralWriteDisposition { completed, queued }

class CentralResilientWriteResult<T> {
  const CentralResilientWriteResult.completed(this.value)
    : disposition = CentralWriteDisposition.completed,
      queueId = null;

  const CentralResilientWriteResult.queued(this.queueId)
    : disposition = CentralWriteDisposition.queued,
      value = null;

  final CentralWriteDisposition disposition;
  final T? value;
  final String? queueId;

  bool get completed => disposition == CentralWriteDisposition.completed;
  bool get queued => disposition == CentralWriteDisposition.queued;
}
