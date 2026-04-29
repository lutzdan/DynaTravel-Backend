// bin/train.dart
//
// Script de entrenamiento Word2Vec para DynaTravel La Paz BCS.
//
// EJECUCIÓN (una sola vez, desde la raíz del proyecto):
//   dart run bin/train.dart
//
// SALIDA:
//   assets/word2vec_tourism.json   ← copiar al proyecto Flutter en assets/
//
// DESPUÉS DE EJECUTAR:
//   1. Copia assets/word2vec_tourism.json al proyecto Flutter
//   2. Agrega la ruta en pubspec.yaml del proyecto Flutter:
//        flutter:
//          assets:
//            - assets/word2vec_tourism.json

import 'dart:io';
import '../lib/word2vec_trainer.dart';

void main() async {
  print('');
  print('╔══════════════════════════════════════════════════╗');
  print('║   DynaTravel — Entrenamiento Word2Vec Turismo    ║');
  print('║   La Paz, Baja California Sur                    ║');
  print('╚══════════════════════════════════════════════════╝');
  print('');

  final stopwatch = Stopwatch()..start();

  // ── 1. Entrenamiento ──────────────────────────────────────────────────────
  print('[ 1/3 ] Entrenando modelo...');
  print('');

  final model = Word2VecTrainer.trainModel(
    onProgress: (epoch, total, lr) {
      // Callback opcional para progreso detallado
    },
  );

  print('');
  print('[ 2/3 ] Guardando modelo...');

  final outputPath = 'assets/word2vec_tourism.json';
  Word2VecTrainer.saveModel(model, outputPath);

  // ── 2. Verificación de similitudes ───────────────────────────────────────
  print('');
  print('[ 3/3 ] Verificando similitudes del modelo...');
  print('');

  final testWords = ['playa', 'gastronomia', 'ecoturismo', 'aventura', 'buceo'];

  for (final word in testWords) {
    if (!model.contains(word)) {
      print('  "$word" no está en el vocabulario');
      continue;
    }
    final similar = model.findSimilar(word, topN: 5);
    print('  Similares a "$word":');
    for (final entry in similar.entries) {
      final bar = _bar(entry.value, width: 20);
      print(
        '    ${entry.key.padRight(20)} $bar  ${entry.value.toStringAsFixed(3)}',
      );
    }
    print('');
  }

  // ── 3. Prueba de expansión de tags de usuario ─────────────────────────────
  print('  Prueba de expansión de tags de usuario:');
  final userTags = ['playa', 'snorkel', 'naturaleza'];
  final expanded = model.expandTags(userTags, topNPerTag: 3, threshold: 0.5);
  print('  Input:    ${userTags.join(', ')}');
  print('  Expanded: ${expanded.join(', ')}');
  print('');

  // ── 4. Prueba de similitud directa ────────────────────────────────────────
  print('  Prueba de similitud directa (pares semánticos):');
  final pairs = [
    ('playa', 'mar'),
    ('snorkel', 'buceo'),
    ('mariscos', 'gastronomia'),
    ('museo', 'cultura'),
    ('aventura', 'ecoturismo'),
    ('playa', 'museo'), // Baja similitud esperada
  ];

  for (final (a, b) in pairs) {
    final sim = Word2VecModel.cosineSimilarity(
      model.getVector(a),
      model.getVector(b),
    );
    final bar = _bar(sim, width: 20);
    print('  "$a" ↔ "$b": $bar  ${sim.toStringAsFixed(3)}');
  }

  stopwatch.stop();
  final elapsed = stopwatch.elapsed;

  print('');
  print('╔══════════════════════════════════════════════════╗');
  print('║  ✓ Entrenamiento completado                      ║');
  print(
    '║  Vocabulario: ${model.wordVectors.length.toString().padRight(5)} palabras                    ║',
  );
  print(
    '║  Dimensiones: ${model.dimensions.toString().padRight(5)}                           ║',
  );
  print('║  Tiempo:      ${elapsed.inSeconds}s                              ║');
  print('╚══════════════════════════════════════════════════╝');
  print('');
  print('  Modelo guardado en: $outputPath');
  print('');
  print('  Próximos pasos:');
  print('  1. Copia "$outputPath" a tu proyecto Flutter');
  print('  2. Decláralo en pubspec.yaml bajo flutter > assets:');
  print('       - assets/word2vec_tourism.json');
  print('  3. Úsalo con AdvancedWord2Vec en recommendation_service.dart');
  print('');

  exit(0);
}

// Barra de progreso ASCII para visualizar scores en terminal
String _bar(double value, {int width = 20}) {
  final filled = (value.clamp(0.0, 1.0) * width).round();
  final empty = width - filled;
  return '[${('█' * filled).padRight(filled)}${'░' * empty}]';
}
