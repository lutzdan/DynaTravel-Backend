// lib/word2vec_trainer.dart
//
// Entrenamiento Word2Vec simplificado (skip-gram con ventana de contexto)
// enfocado en turismo para La Paz, BCS.
//
// USO:
//   final model = Word2VecTrainer.trainModel();
//   Word2VecTrainer.saveModel(model, 'assets/word2vec_tourism.json');

import 'dart:math';
import 'dart:convert';
import 'dart:io';

// ---------------------------------------------------------------------------
// Corpus turístico curado para La Paz, BCS
// Cada lista es una "oración" semántica: palabras que aparecen juntas
// capturan relaciones de contexto que Word2Vec aprende.
// ---------------------------------------------------------------------------
const List<List<String>> _tourismCorpus = [
  // --- Playa y mar ---
  ['playa', 'mar', 'arena', 'sol', 'olas', 'costa', 'litoral', 'orilla'],
  [
    'playa',
    'snorkel',
    'buceo',
    'arrecife',
    'peces',
    'coral',
    'aletas',
    'visor',
  ],
  ['playa', 'natacion', 'nado', 'agua', 'chapotear', 'baño', 'refrescarse'],
  [
    'mar',
    'agua',
    'profundidad',
    'transparencia',
    'azul',
    'turquesa',
    'cristalino',
  ],
  ['kayak', 'remo', 'canoa', 'paddle', 'sup', 'aventura', 'mar', 'playa'],
  [
    'lobos_marinos',
    'fauna',
    'marina',
    'avistamiento',
    'snorkel',
    'isla',
    'espiritu_santo',
  ],
  ['isla', 'espiritu_santo', 'bahia', 'lapaz', 'tour', 'lancha', 'excursion'],
  ['ballena', 'avistamiento', 'mar', 'temporada', 'naturaleza', 'tour', 'baja'],
  [
    'tiburon_ballena',
    'snorkel',
    'buceo',
    'gigante',
    'pacifico',
    'baja',
    'aventura',
  ],
  ['pez_vela', 'pesca', 'mar', 'lapaz', 'deportiva', 'baja', 'charter'],

  // --- Ecoturismo y naturaleza ---
  [
    'naturaleza',
    'fauna',
    'flora',
    'ecosistema',
    'reserva',
    'biosfera',
    'conservacion',
  ],
  [
    'ecoturismo',
    'senderismo',
    'trail',
    'montaña',
    'cerro',
    'naturaleza',
    'aventura',
  ],
  ['desierto', 'baja', 'cactus', 'cardon', 'paisaje', 'aridez', 'naturaleza'],
  [
    'manglares',
    'aves',
    'observacion',
    'naturaleza',
    'ecosistema',
    'costa',
    'lagunas',
  ],
  [
    'birdwatching',
    'aves',
    'observacion',
    'naturaleza',
    'pajaros',
    'binoculares',
  ],
  [
    'reserva',
    'biosfera',
    'vizcaino',
    'protegida',
    'naturaleza',
    'fauna',
    'bcs',
  ],
  [
    'estero',
    'laguna',
    'manglares',
    'pesca',
    'naturaleza',
    'ecosistema',
    'tranquilidad',
  ],
  [
    'cañon',
    'senderismo',
    'aventura',
    'escalada',
    'naturaleza',
    'trail',
    'montaña',
  ],
  [
    'camping',
    'fogata',
    'naturaleza',
    'estrellas',
    'noche',
    'aventura',
    'tienda',
  ],
  [
    'fotografia',
    'naturaleza',
    'paisaje',
    'fauna',
    'amanecer',
    'atardecer',
    'arte',
  ],

  // --- Gastronomía ---
  ['restaurante', 'comida', 'gastronomia', 'sabor', 'menu', 'chef', 'cocina'],
  [
    'mariscos',
    'pescado',
    'ceviche',
    'taco',
    'camarones',
    'ostiones',
    'mar',
    'fresco',
  ],
  ['mariscos', 'gastronomia', 'lapaz', 'bcs', 'fresco', 'local', 'tradicional'],
  ['taco', 'comida', 'local', 'tradicional', 'mexicana', 'mercado', 'puesto'],
  ['ceviche', 'mariscos', 'limon', 'fresco', 'mar', 'chile', 'restaurante'],
  [
    'mercado',
    'local',
    'comida',
    'fresco',
    'tradicional',
    'gastronomia',
    'productos',
  ],
  [
    'cocina',
    'baja',
    'fusion',
    'vino',
    'baja_med',
    'chef',
    'restaurante',
    'gourmet',
  ],
  [
    'pulpo',
    'mariscos',
    'preparacion',
    'restaurante',
    'mar',
    'especial',
    'plato',
  ],
  ['cerveza', 'artesanal', 'bar', 'noche', 'social', 'lapaz', 'malecon'],
  ['smoothie', 'fruta', 'tropical', 'desayuno', 'saludable', 'cafe', 'mañana'],
  ['cafe', 'desayuno', 'pan', 'panaderia', 'mañana', 'tranquilo', 'local'],
  ['palapa', 'mariscos', 'playa', 'sol', 'cerveza', 'relajacion', 'mar'],

  // --- Cultura e historia ---
  [
    'museo',
    'historia',
    'arte',
    'cultura',
    'exposicion',
    'aprendizaje',
    'visita',
  ],
  [
    'museo',
    'ballena',
    'lapaz',
    'ciencias',
    'marino',
    'educacion',
    'naturaleza',
  ],
  [
    'catedral',
    'iglesia',
    'historia',
    'colonial',
    'arquitectura',
    'centro',
    'lapaz',
  ],
  ['malecon', 'lapaz', 'paseo', 'vista', 'mar', 'atardecer', 'bulevar'],
  [
    'arte',
    'galeria',
    'exposicion',
    'local',
    'artesania',
    'cultura',
    'creacion',
  ],
  [
    'artesania',
    'souvenir',
    'local',
    'compras',
    'mercado',
    'cultura',
    'tradicion',
  ],
  [
    'centro_historico',
    'lapaz',
    'historia',
    'arquitectura',
    'colonial',
    'calles',
    'tour',
  ],
  [
    'mision',
    'historia',
    'jesuitas',
    'baja',
    'colonial',
    'cultura',
    'patrimonio',
  ],
  ['carnaval', 'fiesta', 'lapaz', 'tradicion', 'musica', 'baile', 'comunidad'],

  // --- Aventura y deportes ---
  [
    'aventura',
    'adrenalina',
    'riesgo',
    'emocion',
    'deporte',
    'extremo',
    'activo',
  ],
  ['paracaidas', 'skydiving', 'vuelo', 'aventura', 'extremo', 'baja', 'cielo'],
  [
    'motocross',
    'todo_terreno',
    'aventura',
    'baja',
    'desierto',
    'rally',
    'off_road',
  ],
  [
    'ciclismo',
    'bicicleta',
    'trail',
    'deporte',
    'naturaleza',
    'recorrido',
    'activo',
  ],
  ['surf', 'olas', 'tabla', 'playa', 'deporte', 'pacifico', 'baja'],
  [
    'pesca',
    'deportiva',
    'mar',
    'lapaz',
    'charter',
    'barra',
    'marlín',
    'dorado',
  ],
  [
    'yoga',
    'meditacion',
    'playa',
    'amanecer',
    'bienestar',
    'salud',
    'tranquilidad',
  ],
  [
    'trekking',
    'senderismo',
    'mochila',
    'montaña',
    'aventura',
    'naturaleza',
    'trail',
  ],

  // --- Alojamiento y servicios ---
  [
    'hotel',
    'hospedaje',
    'descanso',
    'comodidad',
    'servicio',
    'habitacion',
    'resort',
  ],
  [
    'hostal',
    'mochilero',
    'economico',
    'social',
    'viajero',
    'comunidad',
    'aventura',
  ],
  ['resort', 'lujo', 'spa', 'piscina', 'playa', 'todo_incluido', 'descanso'],
  ['airbnb', 'casa', 'local', 'experiencia', 'comoda', 'hospedaje', 'barrio'],

  // --- Tiempo libre y relajación ---
  [
    'relajacion',
    'descanso',
    'tranquilidad',
    'paz',
    'silencio',
    'naturaleza',
    'zen',
  ],
  [
    'atardecer',
    'malecon',
    'lapaz',
    'cielo',
    'naranja',
    'romantico',
    'vista',
    'mar',
  ],
  [
    'amanecer',
    'playa',
    'silencio',
    'naturaleza',
    'fotografia',
    'mañana',
    'paz',
  ],
  ['familia', 'niños', 'seguro', 'diversion', 'actividades', 'playa', 'comodo'],
  ['romantico', 'pareja', 'atardecer', 'cena', 'playa', 'privado', 'especial'],
  ['social', 'grupo', 'amigos', 'fiesta', 'bar', 'noche', 'malecon'],
  ['solo', 'viajero', 'libertad', 'descubrimiento', 'aventura', 'mochilero'],
  ['lujo', 'exclusivo', 'premium', 'resort', 'yacht', 'privado', 'experiencia'],

  // --- Tipos de Google Places mapeados a contexto turístico ---
  ['beach', 'playa', 'natural_feature', 'costa', 'mar', 'litoral'],
  ['restaurant', 'restaurante', 'comida', 'gastronomia', 'food', 'menu'],
  [
    'tourist_attraction',
    'atraccion',
    'visita',
    'turismo',
    'punto_interes',
    'tour',
  ],
  [
    'natural_feature',
    'naturaleza',
    'paisaje',
    'ecosistema',
    'reserva',
    'fauna',
  ],
  ['museum', 'museo', 'historia', 'cultura', 'arte', 'exposicion'],
  ['park', 'parque', 'naturaleza', 'area_verde', 'descanso', 'recreacion'],
  ['lodging', 'hospedaje', 'hotel', 'alojamiento', 'descanso', 'habitacion'],
  ['food', 'comida', 'gastronomia', 'restaurante', 'mercado', 'alimento'],
  ['travel_agency', 'agencia', 'tour', 'excursion', 'paquete', 'viaje'],
  ['spa', 'bienestar', 'masaje', 'relajacion', 'lujo', 'salud', 'tratamiento'],
  ['bar', 'bebida', 'noche', 'social', 'cerveza', 'malecon', 'lapaz'],
  ['cafe', 'cafe', 'desayuno', 'tranquilo', 'trabajo', 'lectura', 'mañana'],
  ['aquarium', 'fauna', 'marina', 'educacion', 'naturaleza', 'peces', 'museo'],
  [
    'campground',
    'camping',
    'naturaleza',
    'aventura',
    'estrellas',
    'tienda',
    'fogata',
  ],
  ['marina', 'yate', 'lancha', 'mar', 'nautica', 'paseo', 'lapaz'],
];

// ---------------------------------------------------------------------------
// Modelo Word2Vec (Skip-gram simplificado con descenso de gradiente)
// ---------------------------------------------------------------------------
class Word2VecModel {
  final Map<String, List<double>> wordVectors;
  final int dimensions;

  Word2VecModel({required this.wordVectors, required this.dimensions});

  // Similitud coseno entre dos vectores
  static double cosineSimilarity(List<double> a, List<double> b) {
    double dot = 0.0, normA = 0.0, normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (sqrt(normA) * sqrt(normB));
  }

  // Obtener vector de una palabra (o vector cero si no existe)
  List<double> getVector(String word) {
    return wordVectors[word.toLowerCase()] ?? List.filled(dimensions, 0.0);
  }

  bool contains(String word) => wordVectors.containsKey(word.toLowerCase());

  // Palabras más similares a la dada
  Map<String, double> findSimilar(String word, {int topN = 8}) {
    final vec = getVector(word);
    if (vec.every((v) => v == 0.0)) return {};

    final scores = <String, double>{};
    for (final entry in wordVectors.entries) {
      if (entry.key == word) continue;
      scores[entry.key] = cosineSimilarity(vec, entry.value);
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sorted.take(topN));
  }

  // Expandir un conjunto de tags con palabras similares
  List<String> expandTags(
    List<String> tags, {
    int topNPerTag = 3,
    double threshold = 0.55,
  }) {
    final expanded = <String>{...tags};
    for (final tag in tags) {
      final similar = findSimilar(tag, topN: topNPerTag + 5);
      for (final entry in similar.entries) {
        if (entry.value >= threshold) {
          expanded.add(entry.key);
          if (expanded.length - tags.length >= topNPerTag * tags.length) break;
        }
      }
    }
    return expanded.toList();
  }

  // Serializar a JSON
  Map<String, dynamic> toJson() => {
    'dimensions': dimensions,
    'vocabulary_size': wordVectors.length,
    'vectors': wordVectors.map((k, v) => MapEntry(k, v)),
  };
}

// ---------------------------------------------------------------------------
// Entrenador Word2Vec (Skip-gram)
// ---------------------------------------------------------------------------
class Word2VecTrainer {
  static const int _dimensions = 100;
  static const int _windowSize = 3;
  static const int _epochs = 200;
  static const double _learningRate = 0.025;
  static const double _minLearningRate = 0.0001;
  static const int _negativeSamples = 5;

  // Construir vocabulario
  static Map<String, int> _buildVocabulary(List<List<String>> corpus) {
    final freq = <String, int>{};
    for (final sentence in corpus) {
      for (final word in sentence) {
        freq[word] = (freq[word] ?? 0) + 1;
      }
    }
    // Solo palabras con frecuencia >= 1
    final vocab = <String, int>{};
    int idx = 0;
    for (final entry in freq.entries) {
      if (entry.value >= 1) {
        vocab[entry.key] = idx++;
      }
    }
    return vocab;
  }

  // Inicializar vectores aleatoriamente
  static Map<String, List<double>> _initVectors(
    Map<String, int> vocab,
    Random rng,
  ) {
    final vectors = <String, List<double>>{};
    for (final word in vocab.keys) {
      vectors[word] = List.generate(
        _dimensions,
        (_) => (rng.nextDouble() - 0.5) / _dimensions,
      );
    }
    return vectors;
  }

  // Función sigmoide
  static double _sigmoid(double x) {
    if (x > 6) return 1.0;
    if (x < -6) return 0.0;
    return 1.0 / (1.0 + exp(-x));
  }

  // Producto punto
  static double _dot(List<double> a, List<double> b) {
    double s = 0.0;
    for (int i = 0; i < a.length; i++) s += a[i] * b[i];
    return s;
  }

  // Actualizar vectores (un paso skip-gram con negative sampling)
  static void _updateVectors(
    List<double> centerVec,
    List<double> contextVec,
    bool isPositive,
    double lr,
  ) {
    final label = isPositive ? 1.0 : 0.0;
    final score = _sigmoid(_dot(centerVec, contextVec));
    final error = (label - score) * lr;

    // Gradiente
    for (int i = 0; i < centerVec.length; i++) {
      final grad = error * contextVec[i];
      contextVec[i] += error * centerVec[i];
      centerVec[i] += grad;
    }
  }

  /// Entrenar el modelo Word2Vec con el corpus turístico.
  static Word2VecModel trainModel({
    List<List<String>>? corpus,
    void Function(int epoch, int total, double lr)? onProgress,
  }) {
    final trainingCorpus = corpus ?? _tourismCorpus;
    final rng = Random(42); // Seed fija para reproducibilidad

    print('  Construyendo vocabulario...');
    final vocab = _buildVocabulary(trainingCorpus);
    print('  Vocabulario: ${vocab.length} palabras');

    print('  Inicializando vectores (dim=$_dimensions)...');
    final vectors = _initVectors(vocab, rng);
    final wordList = vocab.keys.toList();

    print('  Iniciando entrenamiento (${_epochs} épocas)...');

    for (int epoch = 0; epoch < _epochs; epoch++) {
      // Learning rate con decay lineal
      final lr = max(_minLearningRate, _learningRate * (1.0 - epoch / _epochs));

      // Barajar corpus
      final shuffled = [...trainingCorpus]..shuffle(rng);

      for (final sentence in shuffled) {
        final words = sentence.where((w) => vocab.containsKey(w)).toList();
        if (words.length < 2) continue;

        for (int i = 0; i < words.length; i++) {
          final center = words[i];
          final centerVec = vectors[center]!;

          // Ventana de contexto
          final start = max(0, i - _windowSize);
          final end = min(words.length - 1, i + _windowSize);

          for (int j = start; j <= end; j++) {
            if (j == i) continue;
            final context = words[j];
            final contextVec = vectors[context]!;

            // Par positivo
            _updateVectors(centerVec, contextVec, true, lr);

            // Negative sampling
            for (int n = 0; n < _negativeSamples; n++) {
              final negWord = wordList[rng.nextInt(wordList.length)];
              if (negWord == center || negWord == context) continue;
              _updateVectors(centerVec, vectors[negWord]!, false, lr);
            }
          }
        }
      }

      // Reportar progreso cada 25 épocas
      if ((epoch + 1) % 25 == 0 || epoch == 0) {
        final pct = ((epoch + 1) / _epochs * 100).toStringAsFixed(0);
        print(
          '  Época ${epoch + 1}/$_epochs ($pct%) — lr=${lr.toStringAsFixed(4)}',
        );
        onProgress?.call(epoch + 1, _epochs, lr);
      }
    }

    // Normalizar vectores (L2) para que cosine similarity sea más estable
    for (final vec in vectors.values) {
      double norm = 0.0;
      for (final v in vec) norm += v * v;
      norm = sqrt(norm);
      if (norm > 0) {
        for (int i = 0; i < vec.length; i++) vec[i] /= norm;
      }
    }

    return Word2VecModel(wordVectors: vectors, dimensions: _dimensions);
  }

  /// Guardar el modelo entrenado como JSON.
  static void saveModel(Word2VecModel model, String outputPath) {
    final file = File(outputPath);
    file.parent.createSync(recursive: true);

    final encoder = JsonEncoder.withIndent(
      null,
    ); // Sin indentación para reducir tamaño
    final json = encoder.convert(model.toJson());
    file.writeAsStringSync(json);

    final kb = (file.lengthSync() / 1024).toStringAsFixed(1);
    print('  Archivo guardado: $outputPath ($kb KB)');
  }

  /// Cargar un modelo desde JSON (para usar en la app Flutter).
  static Word2VecModel loadModel(String jsonPath) {
    final file = File(jsonPath);
    if (!file.existsSync()) {
      throw FileSystemException('Modelo no encontrado', jsonPath);
    }

    final raw = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    final dimensions = raw['dimensions'] as int;
    final rawVectors = raw['vectors'] as Map<String, dynamic>;

    final wordVectors = rawVectors.map(
      (k, v) =>
          MapEntry(k, (v as List).map((e) => (e as num).toDouble()).toList()),
    );

    return Word2VecModel(wordVectors: wordVectors, dimensions: dimensions);
  }
}

// ---------------------------------------------------------------------------
// Wrapper de alto nivel para usar en el backend Flutter
// Replica la interfaz que main_training.dart original esperaba.
// ---------------------------------------------------------------------------
class AdvancedWord2Vec {
  late final Word2VecModel _model;

  AdvancedWord2Vec({String modelPath = 'assets/word2vec_tourism.json'}) {
    _model = Word2VecTrainer.loadModel(modelPath);
    print(
      'Modelo cargado: ${_model.wordVectors.length} palabras, dim=${_model.dimensions}',
    );
  }

  /// Palabras más similares a [word].
  Map<String, double> findSimilarTags(String word, {int topN = 8}) {
    return _model.findSimilar(word, topN: topN);
  }

  /// Expandir lista de tags del usuario con contexto semántico.
  List<String> expandUserTags(List<String> tags, {int topNPerTag = 3}) {
    return _model.expandTags(tags, topNPerTag: topNPerTag);
  }

  /// Similitud directa entre dos palabras (0.0 – 1.0).
  double similarity(String wordA, String wordB) {
    return Word2VecModel.cosineSimilarity(
      _model.getVector(wordA),
      _model.getVector(wordB),
    );
  }

  bool containsWord(String word) => _model.contains(word);
}
