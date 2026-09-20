typedef JsonMap = Map<String, dynamic>;

final class ApiResponse<T> {
  const ApiResponse({
    required this.status,
    required this.message,
    required this.data,
    this.meta,
  });
  final int status;
  final String message;
  final T data;
  final JsonMap? meta;
  factory ApiResponse.fromJson(JsonMap json, T Function(Object?) decode) =>
      ApiResponse(
        status: (json['status'] as num?)?.toInt() ?? 0,
        message: (json['mensagem'] ?? json['message'] ?? '').toString(),
        data: decode(json['data']),
        meta: json['meta'] is Map
            ? Map<String, dynamic>.from(json['meta'] as Map)
            : null,
      );
}
