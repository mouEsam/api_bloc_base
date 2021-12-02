import 'package:api_bloc_base/src/presentation/bloc/worker/pagination_mixin.dart';

class SimplePaginatedInput<E> extends PaginatedInput<E> {
  SimplePaginatedInput(E input, String? nextUrl, int currentPage)
      : super(input, nextUrl, currentPage);
}
