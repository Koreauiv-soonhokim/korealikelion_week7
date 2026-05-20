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
  // Flutter 엔진과 위젯 트리가 바인딩되기 전에 비동기 작업을 하기 위해 필수!
  WidgetsFlutterBinding.ensureInitialized();
  
  // SharedPreferences 인스턴스를 비동기로 먼저 가져옴
  final prefs = await SharedPreferences.getInstance();

  runApp(
    // ✅ 과제 조건: ProviderScope로 앱 감싸기
    ProviderScope(
      overrides: [
        // 위에서 가져온 prefs를 전역 프로바이더에 주입 (이후로는 await 없이 동기적으로 사용 가능)
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

// ✅ 과제 조건: ConsumerWidget 사용
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ 과제 조건: ref.watch()로 상태를 구독해서 UI(테마)에 표시
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
    // ✅ 과제 조건: ref.watch()로 닉네임과 다크모드 상태 구독
    final settings = ref.watch(settingsProvider);
    
    // TextField의 초기값을 현재 닉네임으로 세팅
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
                // ✅ 과제 조건: ref.read(provider.notifier)로 버튼 이벤트에서 상태 변경
                ref.read(settingsProvider.notifier).updateNickname(textController.text);
                
                // 키보드 내리기
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
                    // ✅ 과제 조건: ref.read(provider.notifier)로 스위치 이벤트에서 상태 변경
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