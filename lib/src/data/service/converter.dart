import 'package:api_bloc_base/src/data/model/remote/response/base_api_response.dart';
import 'package:api_bloc_base/src/domain/entity/response_entity.dart';
import 'package:collection/collection.dart' show IterableExtension;

abstract class Converter<IN, OUT> {
  const Converter();
  Type get inputType => IN;
  Type get outputType => OUT;
  bool acceptsInput(Type input) => input == inputType;
  bool returnsOutput(Type output) => output == outputType;
  List<Converter> get converters;
  OUT? convert(IN initialData);

  BaseModelConverter<I, O>? getConverter<I, O>() {
    final converter = converters
        .followedBy([this])
        .whereType<BaseModelConverter<I, O>>()
        .firstOrNull;
    return converter;
  }

  X requireConverter<I, X>(I? input) {
    return resolveConverter(input)!;
  }

  X? resolveConverter<I, X>(I? input) {
    if (input == null) return null;
    final converter = getConverter<I, X>();
    return converter?.convert(input);
  }

  List<X> resolveListConverter<X, Y>(List<Y>? input) {
    final converter = getConverter<Y, X>();
    List<X> result = input
            ?.map((item) => converter?.convert(item))
            .whereType<X>()
            .toList() ??
        <X>[];
    return result;
  }

  Map<K, X> resolveMapConverter<K, X, Y>(Map<K, Y>? input) {
    final converter = getConverter<Y, X>();
    final entries = converter?.convertMap<K>(input);
    return Map.from(entries ?? {});
  }

  Map<K, X> resolveKeyedMapConverter<K, X, Y>(
      Map<String, Y>? input, K Function(String key) keyConverter) {
    final converter = getConverter<Y, X>();
    final entries = input
        ?.map((key, value) =>
            MapEntry(keyConverter(key), converter?.convertSingle(value)))
        .entries
        .whereType<MapEntry<K, X>>()
        .toList();
    return Map.fromEntries(entries ?? []);
  }
}

abstract class BaseResponseConverter<T extends BaseApiResponse, X>
    extends Converter<T, X> {
  final String Function(String)? handlePath;

  const BaseResponseConverter([this.handlePath]);

  X convert(T response);

  bool isErrorMessage(BaseApiResponse initialData) {
    return initialData.errors != null ||
        initialData.error != null ||
        initialData.message != null;
  }

  bool isSuccessMessage(BaseApiResponse initialData) {
    return initialData.success == true || initialData.success is String;
  }

  bool hasData(T initialData) {
    return initialData.data != null ||
        (initialData.success == true && !isErrorMessage(initialData)) ||
        (!isSuccessMessage(initialData) && !isErrorMessage(initialData));
  }

  ResponseEntity? response(BaseApiResponse initialData) {
    if (isSuccessMessage(initialData)) {
      return Success(initialData.message ??
          (initialData.success is String ? initialData.success : null));
    } else if (isErrorMessage(initialData)) {
      return Failure(
          initialData.message ?? initialData.error, initialData.errors);
    }
    return null;
  }
}

abstract class BaseModelConverter<Input, Output>
    extends Converter<Input, Output> {
  final bool failIfError;

  const BaseModelConverter([this.failIfError = false]);

  List<Converter> get converters => [];

  Output? convert(Input model);

  Output? convertSingle(Input? initialData) {
    Output? result;
    if (failIfError) {
      result = initialData == null ? null : convert(initialData);
    } else {
      try {
        result = initialData == null ? null : convert(initialData);
      } catch (e, s) {
        print(e);
        print(s);
        result = null;
      }
    }
    return result;
  }

  List<Output> convertList(List<Input?>? initialData) {
    final result = initialData
            ?.map((itemModel) => convertSingle(itemModel))
            .whereType<Output>()
            .toList() ??
        <Output>[];
    return result;
  }

  Map<K, Output> convertMap<K>(Map<K, Input?>? initialData) {
    final entries = initialData?.entries
            .map((entry) => MapEntry(entry.key, convertSingle(entry.value)))
            .whereType<MapEntry<K, Output>>()
            .toList() ??
        <MapEntry<K, Output>>[];
    return Map.fromEntries(entries);
  }
}

mixin ReverseModelConverter<IN, OUT> on BaseModelConverter<IN, OUT> {
  IN? reverseConvert(OUT entity);

  IN? reverseConvertSingle(OUT? initialData) {
    IN? result;
    if (failIfError) {
      result = initialData == null ? null : reverseConvert(initialData);
    } else {
      try {
        result = initialData == null ? null : reverseConvert(initialData);
      } catch (e, s) {
        print(e);
        print(s);
        result = null;
      }
    }
    return result;
  }

  List<IN> reverseConvertList(List<OUT?>? initialData) {
    final result = initialData
            ?.map((itemModel) => reverseConvertSingle(itemModel))
            .whereType<IN>()
            .toList() ??
        <IN>[];
    return result;
  }

  Map<K, IN> reverseConvertMap<K>(Map<K, OUT?>? initialData) {
    final entries = initialData?.entries
            .map((entry) =>
                MapEntry(entry.key, reverseConvertSingle(entry.value)))
            .whereType<MapEntry<K, IN>>()
            .toList() ??
        <MapEntry<K, IN>>[];
    return Map.fromEntries(entries);
  }

  ReverseModelConverter<I, O>? getReverseConverter<O, I>() {
    final converter = converters
        .followedBy([this])
        .whereType<ReverseModelConverter<I, O>>()
        .firstWhereOrNull((element) =>
            element.acceptsInput(inputType) &&
            element.returnsOutput(outputType));
    return converter;
  }

  X requireReverseConverter<I, X>(I? input) {
    return resolveReverseConverter(input)!;
  }

  X? resolveReverseConverter<I, X>(I? input) {
    if (input == null) return null;
    final converter = getReverseConverter<I, X>();
    return converter?.reverseConvert(input);
  }

  List<X> resolveListReverseConverter<X, Y>(List<Y>? input) {
    final converter = getReverseConverter<Y, X>();
    List<X> result = input
            ?.map((item) => converter?.reverseConvert(item))
            .whereType<X>()
            .toList() ??
        <X>[];
    return result;
  }

  Map<K, X> resolveMapReverseConverter<K, X, Y>(Map<K, Y>? input) {
    final converter = getReverseConverter<Y, X>();
    final entries = converter?.reverseConvertMap<K>(input);
    return Map.from(entries ?? {});
  }

  Map<K, X> resolveKeyedMapReverseConverter<K, X, Y>(
      Map<String, Y>? input, K Function(String key) keyConverter) {
    final converter = getReverseConverter<Y, X>();
    final entries = input
        ?.map((key, value) =>
            MapEntry(keyConverter(key), converter?.reverseConvertSingle(value)))
        .entries
        .whereType<MapEntry<K, X>>()
        .toList();
    return Map.fromEntries(entries ?? []);
  }
}
