import 'dart:io';

import 'package:equatable/equatable.dart';
import 'package:http_parser/http_parser.dart';

class UploadFile extends Equatable {
  final String? fileName;
  final File file;
  final MediaType? contentType;

  const UploadFile(
    this.file,
    this.fileName, [
    this.contentType,
  ]);

  @override
  get props => [
        this.fileName,
        this.file,
        this.contentType,
      ];
}
