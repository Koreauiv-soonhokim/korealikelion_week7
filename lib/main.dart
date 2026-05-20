import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';


final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError();
});

class SettingsState {
  final bool isDarkMode;
  final String nickname;

  SettingsState({required this.isDarkMode, required this.nickname});

  SettingsState copyWith({bool? isDarkMode, String? nickname}) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      nickname: nickname ?? this.nickname,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final SharedPreferences prefs;

  SettingsNotifier(this.prefs)
      : super(SettingsState(
          isDarkMode: prefs.getBool('isDarkMode') ?? false,
          nickname: prefs.getString('nickname') ?? '게스트',
        ));

  void toggleDarkMode() {
    final newValue = !state.isDarkMode;
    prefs.setBool('isDarkMode', newValue);
    state = state.copyWith(isDarkMode: newValue);
  }

  void updateNickname(String newNickname) {
    prefs.setString('nickname', newNickname);
    state = state.copyWith(nickname: newNickname);
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SettingsNotifier(prefs);
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'Riverpod & SharedPreferences',
      theme: settings.isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    
    final textController = TextEditingController(text: settings.nickname);

    return Scaffold(
      appBar: AppBar(
        title: const Text('내 설정 화면'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '현재 닉네임: ${settings.nickname}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: '새 닉네임 입력',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
              
                ref.read(settingsProvider.notifier).updateNickname(textController.text);
                
                
                FocusScope.of(context).unfocus();
              },
              child: const Text('닉네임 저장'),
            ),
            const Divider(height: 60),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('다크 모드', style: TextStyle(fontSize: 18)),
                Switch(
                  value: settings.isDarkMode,
                  onChanged: (value) {
                   
                    ref.read(settingsProvider.notifier).toggleDarkMode();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
