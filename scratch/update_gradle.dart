import 'dart:io';

void main() {
  final file = File('android/app/build.gradle.kts');
  String content = file.readAsStringSync();
  
  content = content.replaceFirst(
    "targetCompatibility = JavaVersion.VERSION_17\n    }",
    "targetCompatibility = JavaVersion.VERSION_17\n        isCoreLibraryDesugaringEnabled = true\n    }"
  );

  final depBlock = """
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}

""";
  content = content + "\\n" + depBlock;

  file.writeAsStringSync(content);
}
