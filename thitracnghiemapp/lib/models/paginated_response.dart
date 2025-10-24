class PaginatedResponse<T> {
  final int total;
  final List<T> items;
  final int page;
  final int pageSize;

  const PaginatedResponse({
    required this.total,
    required this.items,
    required this.page,
    required this.pageSize,
  });

  bool get isLastPage => page * pageSize >= total;

  PaginatedResponse<T> copyWith({
    int? total,
    List<T>? items,
    int? page,
    int? pageSize,
  }) => PaginatedResponse(
    total: total ?? this.total,
    items: items ?? this.items,
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
  );
}
