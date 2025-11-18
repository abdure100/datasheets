import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: '.env');
  print('Password from env: "${dotenv.env['FILEMAKER_PASSWORD']}"');
  print('Password length: ${dotenv.env['FILEMAKER_PASSWORD']?.length}');
}
