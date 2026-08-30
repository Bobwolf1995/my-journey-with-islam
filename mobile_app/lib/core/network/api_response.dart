class ApiResponse<T> {
  const ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.statusCode,
    this.errors,
  });

  final bool success;
  final String message;
  final T? data;
  final int? statusCode;
  final dynamic errors;

  factory ApiResponse.success({
    T? data,
    String message = 'تمت العملية بنجاح',
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: true,
      message: message,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.failure({
    String message = 'حدث خطأ غير متوقع',
    int? statusCode,
    dynamic errors,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      statusCode: statusCode,
      errors: errors,
    );
  }

  factory ApiResponse.fromJson(
    Map<String, dynamic> json, {
    T Function(dynamic value)? parser,
  }) {
    final isSuccess = json['success'] == true;
    final rawData = json['data'];

    return ApiResponse<T>(
      success: isSuccess,
      message: json['message']?.toString() ??
          (isSuccess ? 'تمت العملية بنجاح' : 'حدث خطأ غير متوقع'),
      data: parser == null ? rawData as T? : parser(rawData),
      statusCode: _asInt(json['statusCode'] ?? json['status_code']),
      errors: json['errors'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'statusCode': statusCode,
      'errors': errors,
    };
  }

  static int? _asInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value);
    }

    return null;
  }
}
