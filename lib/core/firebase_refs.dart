import 'package:cloud_firestore/cloud_firestore.dart';
import 'constants.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

CollectionReference<Map<String, dynamic>> usersRef =
db.collection(Collections.users);

CollectionReference<Map<String, dynamic>> logsRef =
db.collection(Collections.logs);

CollectionReference<Map<String, dynamic>> templatesRef =
db.collection(Collections.formTemplates);

CollectionReference<Map<String, dynamic>> rolesRef =
db.collection(Collections.roles);

CollectionReference<Map<String, dynamic>> districtsRef =
db.collection(Collections.districts);
