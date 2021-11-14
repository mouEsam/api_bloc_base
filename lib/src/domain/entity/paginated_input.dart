import 'package:api_bloc_base/src/presentation/bloc/worker/pagination_mixin.dart';

class SimplePaginatedInput extends PaginatedInput {
  SimplePaginatedInput(input, String? nextUrl, int currentPage)
      : super(input, nextUrl, currentPage);
}
