class Palavras {
  String id;
  String palavra;

  Palavras({required this.id, required this.palavra});

  Palavras.fromMap(Map<String, dynamic> map)
    : id = map["id"],
      palavra = map["palavra"];
  Map<String, dynamic> toMap() {
    return {"id": id, "palavra": palavra};
  }
}
