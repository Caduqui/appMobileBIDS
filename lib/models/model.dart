class Model {
  String id;
  String name;

  Model({required this.id, required this.name});

  Model.fromMap(Map<String, dynamic> map) : id = map["id"], name = map["nome"];

  Map<String, dynamic> toMap() {
    return {"id": id, "name": name};
  }
}
