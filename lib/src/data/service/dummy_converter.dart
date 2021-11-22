import 'package:api_bloc_base/api_bloc_base.dart';

import 'converter.dart';

class DummyConverter extends BaseResponseConverter<BaseApiResponse, dynamic> {
  const DummyConverter() : super();

  convert(model) {
    throw UnimplementedError();
  }

  @override
  get converters => throw UnimplementedError();
}
