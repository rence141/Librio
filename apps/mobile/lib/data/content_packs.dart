import '../services/content_manager.dart';

/// Curated content packs for Phase 3 Week 14

// Mathematics Pack
final mathemaicsPack = SubjectPack(
  id: 'pack_math_001',
  title: 'Mathematics Fundamentals',
  subject: 'Mathematics',
  description: 'Comprehensive mathematics curriculum covering algebra, geometry, trigonometry, and calculus',
  topics: [
    // Algebra
    ContentTopic(
      id: 'topic_math_001',
      title: 'Linear Equations',
      description: 'Understanding and solving linear equations',
      subject: 'Mathematics',
      difficulty: 1,
      concepts: ['variables', 'coefficients', 'solutions', 'graphing'],
      keywords: ['linear', 'equation', 'slope', 'intercept'],
      createdAt: DateTime.now(),
    ),
    ContentTopic(
      id: 'topic_math_002',
      title: 'Quadratic Equations',
      description: 'Solving quadratic equations using various methods',
      subject: 'Mathematics',
      difficulty: 2,
      concepts: ['quadratic formula', 'factoring', 'completing the square'],
      keywords: ['quadratic', 'parabola', 'roots', 'discriminant'],
      createdAt: DateTime.now(),
    ),
    // Geometry
    ContentTopic(
      id: 'topic_math_003',
      title: 'Triangles and Angles',
      description: 'Properties and theorems related to triangles',
      subject: 'Mathematics',
      difficulty: 2,
      concepts: ['angles', 'sides', 'congruence', 'similarity'],
      keywords: ['triangle', 'angle', 'theorem', 'proof'],
      createdAt: DateTime.now(),
    ),
    ContentTopic(
      id: 'topic_math_004',
      title: 'Circles and Arcs',
      description: 'Understanding circles, arcs, and circular geometry',
      subject: 'Mathematics',
      difficulty: 2,
      concepts: ['radius', 'diameter', 'circumference', 'area'],
      keywords: ['circle', 'arc', 'chord', 'tangent'],
      createdAt: DateTime.now(),
    ),
    // Trigonometry
    ContentTopic(
      id: 'topic_math_005',
      title: 'Trigonometric Functions',
      description: 'Sine, cosine, tangent and other trigonometric functions',
      subject: 'Mathematics',
      difficulty: 3,
      concepts: ['sine', 'cosine', 'tangent', 'unit circle'],
      keywords: ['trigonometry', 'angle', 'ratio', 'function'],
      createdAt: DateTime.now(),
    ),
    // Calculus
    ContentTopic(
      id: 'topic_math_006',
      title: 'Limits and Continuity',
      description: 'Introduction to limits and continuous functions',
      subject: 'Mathematics',
      difficulty: 3,
      concepts: ['limits', 'continuity', 'infinity', 'convergence'],
      keywords: ['limit', 'continuous', 'derivative', 'integral'],
      createdAt: DateTime.now(),
    ),
  ],
  problems: [
    PracticeProblem(
      id: 'prob_math_001',
      topicId: 'topic_math_001',
      question: 'Solve: 2x + 5 = 13',
      options: ['x = 4', 'x = 9', 'x = 3', 'x = 8'],
      correctAnswerIndex: 0,
      explanation: '2x + 5 = 13 → 2x = 8 → x = 4',
      difficulty: 1,
      createdAt: DateTime.now(),
    ),
    PracticeProblem(
      id: 'prob_math_002',
      topicId: 'topic_math_002',
      question: 'Solve: x² - 5x + 6 = 0',
      options: ['x = 2, 3', 'x = 1, 6', 'x = 2, 4', 'x = 3, 4'],
      correctAnswerIndex: 0,
      explanation: 'x² - 5x + 6 = (x - 2)(x - 3) = 0 → x = 2 or x = 3',
      difficulty: 2,
      createdAt: DateTime.now(),
    ),
  ],
  totalTopics: 6,
  totalProblems: 200,
  createdAt: DateTime.now(),
);

// Physics Pack
final physicsPack = SubjectPack(
  id: 'pack_physics_001',
  title: 'Physics Essentials',
  subject: 'Physics',
  description: 'Core physics concepts covering mechanics, thermodynamics, electricity, and waves',
  topics: [
    // Mechanics
    ContentTopic(
      id: 'topic_phys_001',
      title: 'Motion and Forces',
      description: 'Understanding motion, velocity, acceleration, and Newton\'s laws',
      subject: 'Physics',
      difficulty: 2,
      concepts: ['velocity', 'acceleration', 'force', 'Newton\'s laws'],
      keywords: ['motion', 'force', 'mass', 'acceleration'],
      createdAt: DateTime.now(),
    ),
    ContentTopic(
      id: 'topic_phys_002',
      title: 'Energy and Work',
      description: 'Kinetic energy, potential energy, and work-energy theorem',
      subject: 'Physics',
      difficulty: 2,
      concepts: ['kinetic energy', 'potential energy', 'work', 'power'],
      keywords: ['energy', 'work', 'power', 'conservation'],
      createdAt: DateTime.now(),
    ),
    // Thermodynamics
    ContentTopic(
      id: 'topic_phys_003',
      title: 'Heat and Temperature',
      description: 'Temperature, heat transfer, and thermal properties',
      subject: 'Physics',
      difficulty: 2,
      concepts: ['temperature', 'heat', 'thermal energy', 'specific heat'],
      keywords: ['heat', 'temperature', 'thermodynamics', 'transfer'],
      createdAt: DateTime.now(),
    ),
    // Electricity
    ContentTopic(
      id: 'topic_phys_004',
      title: 'Electric Fields and Circuits',
      description: 'Electric fields, circuits, and Ohm\'s law',
      subject: 'Physics',
      difficulty: 3,
      concepts: ['electric field', 'voltage', 'current', 'resistance'],
      keywords: ['electricity', 'circuit', 'voltage', 'current'],
      createdAt: DateTime.now(),
    ),
    // Waves
    ContentTopic(
      id: 'topic_phys_005',
      title: 'Waves and Sound',
      description: 'Wave properties, sound waves, and acoustics',
      subject: 'Physics',
      difficulty: 2,
      concepts: ['wavelength', 'frequency', 'amplitude', 'speed'],
      keywords: ['wave', 'sound', 'frequency', 'wavelength'],
      createdAt: DateTime.now(),
    ),
  ],
  problems: [
    PracticeProblem(
      id: 'prob_phys_001',
      topicId: 'topic_phys_001',
      question: 'A car accelerates from 0 to 60 m/s in 10 seconds. What is the acceleration?',
      options: ['6 m/s²', '10 m/s²', '60 m/s²', '0.6 m/s²'],
      correctAnswerIndex: 0,
      explanation: 'a = Δv/Δt = (60 - 0)/10 = 6 m/s²',
      difficulty: 2,
      createdAt: DateTime.now(),
    ),
  ],
  totalTopics: 5,
  totalProblems: 200,
  createdAt: DateTime.now(),
);

// Biology Pack
final biologyPack = SubjectPack(
  id: 'pack_biology_001',
  title: 'Biology Fundamentals',
  subject: 'Biology',
  description: 'Essential biology covering cell biology, genetics, evolution, and ecology',
  topics: [
    // Cell Biology
    ContentTopic(
      id: 'topic_bio_001',
      title: 'Cell Structure and Function',
      description: 'Understanding cell organelles and their functions',
      subject: 'Biology',
      difficulty: 1,
      concepts: ['nucleus', 'mitochondria', 'chloroplast', 'membrane'],
      keywords: ['cell', 'organelle', 'structure', 'function'],
      createdAt: DateTime.now(),
    ),
    ContentTopic(
      id: 'topic_bio_002',
      title: 'Cell Division',
      description: 'Mitosis, meiosis, and cell reproduction',
      subject: 'Biology',
      difficulty: 2,
      concepts: ['mitosis', 'meiosis', 'chromosomes', 'cytokinesis'],
      keywords: ['cell division', 'mitosis', 'meiosis', 'reproduction'],
      createdAt: DateTime.now(),
    ),
    // Genetics
    ContentTopic(
      id: 'topic_bio_003',
      title: 'DNA and Genetics',
      description: 'DNA structure, genes, and inheritance',
      subject: 'Biology',
      difficulty: 2,
      concepts: ['DNA', 'genes', 'alleles', 'inheritance'],
      keywords: ['DNA', 'genetics', 'gene', 'inheritance'],
      createdAt: DateTime.now(),
    ),
    ContentTopic(
      id: 'topic_bio_004',
      title: 'Evolution',
      description: 'Natural selection and evolutionary theory',
      subject: 'Biology',
      difficulty: 2,
      concepts: ['natural selection', 'adaptation', 'speciation', 'evolution'],
      keywords: ['evolution', 'natural selection', 'adaptation', 'species'],
      createdAt: DateTime.now(),
    ),
    // Ecology
    ContentTopic(
      id: 'topic_bio_005',
      title: 'Ecosystems and Ecology',
      description: 'Ecosystems, food chains, and population dynamics',
      subject: 'Biology',
      difficulty: 2,
      concepts: ['ecosystem', 'food chain', 'population', 'community'],
      keywords: ['ecology', 'ecosystem', 'population', 'community'],
      createdAt: DateTime.now(),
    ),
  ],
  problems: [
    PracticeProblem(
      id: 'prob_bio_001',
      topicId: 'topic_bio_001',
      question: 'Which organelle is responsible for energy production in the cell?',
      options: ['Mitochondria', 'Nucleus', 'Ribosome', 'Golgi apparatus'],
      correctAnswerIndex: 0,
      explanation: 'Mitochondria is the powerhouse of the cell, producing ATP through cellular respiration',
      difficulty: 1,
      createdAt: DateTime.now(),
    ),
  ],
  totalTopics: 5,
  totalProblems: 200,
  createdAt: DateTime.now(),
);

/// Get all content packs
List<SubjectPack> getAllContentPacks() {
  return [
    mathemaicsPack,
    physicsPack,
    biologyPack,
  ];
}

/// Get content pack by subject
SubjectPack? getContentPackBySubject(String subject) {
  return getAllContentPacks()
      .where((pack) => pack.subject == subject)
      .firstOrNull;
}
