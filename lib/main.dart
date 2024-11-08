import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:tokhub/app_actions.dart';
import 'package:tokhub/app_middleware.dart';
import 'package:tokhub/app_reducer.dart';
import 'package:tokhub/app_state.dart';
import 'package:tokhub/pages/home_page.dart';
import 'package:tokhub/storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = createStore(await loadState());
  if (store.state.token != null) {
    // Login and initial load.
    store.dispatch(SetTokenAction(store.state.token!));
  }
  runApp(MyApp(store: store));
}

Store<AppState> createStore(AppState initialState) {
  return Store<AppState>(
    appReducer,
    initialState: initialState,
    middleware: [
      AppMiddleware().call,
    ],
  );
}

class MyApp extends StatelessWidget {
  final Store<AppState> store;

  const MyApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return StoreProvider(
      store: store,
      child: MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        home: const HomePage(),
      ),
    );
  }
}
