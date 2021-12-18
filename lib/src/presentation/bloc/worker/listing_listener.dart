import 'dart:async';

import 'package:api_bloc_base/src/presentation/bloc/provider/_index.dart';
import 'package:api_bloc_base/src/presentation/bloc/provider/provider.dart';
import 'package:api_bloc_base/src/presentation/bloc/worker/listing_mixin.dart';

import 'provider_listener.dart';

abstract class ListingListener<Input, Output, Filtering extends FilterType>
    extends ProviderListener<Input, Output>
    with ListingMixin<Input, Output, Filtering> {
  final int searchDelayMillis;

  ListingListener(
      List<Stream<ProviderState>> sources, ProviderMixin<Input> provider,
      {this.searchDelayMillis = 1000, Output? currentData})
      : super(sources, provider, currentData: currentData);
}
