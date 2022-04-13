import 'package:intl/intl.dart';

abstract class TranslatableString {
  final String pattern;
  final List<String>? args;
  final List<TranslatableString>? translatableArgs;

  const TranslatableString(this.pattern, this.args, this.translatableArgs);
}

class TranslatableText extends TranslatableString {
  final Map<String, String>? namedArgs;
  final Map<String, TranslatableText>? translatableNamedArgs;

  const TranslatableText(String pattern,
      {List<String>? args,
      this.namedArgs,
      List<TranslatableString>? translatableArgs,
      this.translatableNamedArgs})
      : super(pattern, args, translatableArgs);
}

class TranslatableNumber extends TranslatableString {
  final NumberFormat? format;
  final num? number;

  const TranslatableNumber(String pattern, this.number,
      {List<String>? args,
      this.format,
      List<TranslatableText>? translatableArgs})
      : super(pattern, args, translatableArgs);
}
