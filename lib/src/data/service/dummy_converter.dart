import '../_index.dart';

class DummyConverter extends BaseResponseConverter<BaseApiResponse, dynamic> {
  const DummyConverter() : super();

  convert(model) {
    throw UnimplementedError();
  }

  @override
  get converters => throw UnimplementedError();
}
