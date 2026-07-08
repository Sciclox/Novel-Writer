import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import '../database/app_database.dart';

class EditorViewModel extends ChangeNotifier {
  final int capituloId;
  
  Map<String, dynamic>? _capitulo;
  bool _isLoading = true;
  bool _focusMode = false;
  bool _typewriterMode = false;

  // Goals
  int _sessionWordCount = 0;
  int _sessionGoal = 0;
  int _dailyGoal = 0;
  int _initialWordsCount = 0;

  List<Map<String, dynamic>> _versions = [];

  quill.QuillController? quillController;
  Timer? _autosaveTimer;
  DateTime? _lastSaved;

  EditorViewModel(this.capituloId);

  Map<String, dynamic>? get capitulo => _capitulo;
  bool get isLoading => _isLoading;
  bool get focusMode => _focusMode;
  bool get typewriterMode => _typewriterMode;
  int get sessionWordCount => _sessionWordCount;
  int get sessionGoal => _sessionGoal;
  int get dailyGoal => _dailyGoal;
  List<Map<String, dynamic>> get versions => _versions;
  DateTime? get lastSaved => _lastSaved;

  set focusMode(bool val) {
    _focusMode = val;
    notifyListeners();
  }

  set typewriterMode(bool val) {
    _typewriterMode = val;
    notifyListeners();
  }

  set sessionGoal(int val) {
    _sessionGoal = val;
    _saveGoals();
    notifyListeners();
  }

  set dailyGoal(int val) {
    _dailyGoal = val;
    _saveGoals();
    notifyListeners();
  }

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    final db = await AppDatabase.database;
    final List<Map<String, dynamic>> caps = await db.query(
      'capitulos',
      where: 'id = ?',
      whereArgs: [capituloId],
    );
    
    if (caps.isNotEmpty) {
      _capitulo = Map<String, dynamic>.from(caps.first);
      
      // Load versions
      _versions = await AppDatabase.getCapituloVersiones(capituloId);
      
      // Load goals
      _sessionGoal = _capitulo!['meta_sesion'] ?? 0;
      _dailyGoal = _capitulo!['meta_diaria'] ?? 0;

      // Initialize Quill Controller
      final contentStr = _capitulo!['contenido'] ?? '';
      quill.Document doc;
      if (contentStr.trim().startsWith('[') && contentStr.trim().endsWith(']')) {
        try {
          doc = quill.Document.fromJson(jsonDecode(contentStr));
        } catch (_) {
          doc = quill.Document()..insert(0, contentStr);
        }
      } else {
        doc = quill.Document()..insert(0, contentStr);
      }
      
      quillController = quill.QuillController(
        document: doc,
        selection: const TextSelection.collapsed(offset: 0),
      );

      _initialWordsCount = _countWords(quillController!.document.toPlainText());
      _sessionWordCount = 0;

      // Setup Autosave timer
      _autosaveTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
        autosave();
      });
    }

    _isLoading = false;
    notifyListeners();
  }

  int _countWords(String text) {
    if (text.isEmpty) return 0;
    return text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  void updateWordCount() {
    if (quillController == null) return;
    final currentText = quillController!.document.toPlainText();
    final currentWords = _countWords(currentText);
    _sessionWordCount = (currentWords - _initialWordsCount).clamp(0, 999999);
    notifyListeners();
  }

  Future<void> save() async {
    if (quillController == null || _capitulo == null) return;
    
    final contentStr = jsonEncode(quillController!.document.toDelta().toJson());
    final words = _countWords(quillController!.document.toPlainText());

    await AppDatabase.updateCapitulo(capituloId, {
      'contenido': contentStr,
      'palabras': words,
    });
    
    _lastSaved = DateTime.now();
    notifyListeners();
  }

  Future<void> autosave() async {
    await save();
  }

  Future<void> _saveGoals() async {
    await AppDatabase.updateCapitulo(capituloId, {
      'meta_sesion': _sessionGoal,
      'meta_diaria': _dailyGoal,
    });
  }

  Future<void> createSnapshot(String motivo) async {
    if (quillController == null) return;
    final contentStr = jsonEncode(quillController!.document.toDelta().toJson());
    final words = _countWords(quillController!.document.toPlainText());

    await AppDatabase.insertCapituloVersion(capituloId, contentStr, palabras: words, motivo: motivo);
    _versions = await AppDatabase.getCapituloVersiones(capituloId);
    notifyListeners();
  }

  Future<void> restoreVersion(Map<String, dynamic> version) async {
    final contentStr = version['contenido'] ?? '';
    quill.Document doc;
    if (contentStr.trim().startsWith('[') && contentStr.trim().endsWith(']')) {
      try {
        doc = quill.Document.fromJson(jsonDecode(contentStr));
      } catch (_) {
        doc = quill.Document()..insert(0, contentStr);
      }
    } else {
      doc = quill.Document()..insert(0, contentStr);
    }

    if (quillController != null) {
      quillController!.dispose();
    }
    quillController = quill.QuillController(
      document: doc,
      selection: const TextSelection.collapsed(offset: 0),
    );
    
    _initialWordsCount = _countWords(doc.toPlainText());
    _sessionWordCount = 0;
    
    await save();
    notifyListeners();
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    quillController?.dispose();
    super.dispose();
  }
}
