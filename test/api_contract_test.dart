import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

void main() {
  test('OpenAPI descreve as operações usadas pela sincronização', () async {
    final spec = loadYaml(await File('openapi.yaml').readAsString()) as YamlMap;
    final paths = spec['paths'] as YamlMap;

    expect(paths['/remessas/minhas'], isA<YamlMap>());
    expect((paths['/remessas/minhas'] as YamlMap)['get'], isA<YamlMap>());
    expect(paths['/remessas/{id}/status'], isA<YamlMap>());
    expect(paths['/remessas/{id}/aceitar'], isA<YamlMap>());
    expect(paths['/localizacao'], isA<YamlMap>());

    final localizacao = (paths['/localizacao'] as YamlMap)['post'] as YamlMap;
    final responses = localizacao['responses'] as YamlMap;
    expect(responses['429'], isA<YamlMap>());
    expect(
      (((responses['429'] as YamlMap)['headers'] as YamlMap)['Retry-After']),
      isA<YamlMap>(),
    );
  });
}
