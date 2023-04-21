import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp.router(
        title: 'First Flutter App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepOrange,
          ),
        ),
        routerConfig: GoRouter(
          initialLocation: "/generator",
          routes: [
            ShellRoute(
              pageBuilder: (context, state, child) {
                return NoTransitionPage(
                  key: state.pageKey,
                  restorationId: state.pageKey.value,
                  child: AppScaffold(
                    key: state.pageKey,
                    child: child,
                  ),
                );
              },
              routes: [
                GoRoute(
                  path: "/generator",
                  builder: (context, state) => GeneratorPage(),
                ),
                GoRoute(
                  path: "/favorites",
                  builder: (context, state) => FavoritesPage(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var history = <WordPair>[];
  var current = WordPair.random();

  GlobalKey<AnimatedListState>? historyViewKey;

  void getNext() {
    // insert current word into history
    history.insert(0, current);
    historyViewKey?.currentState?.insertItem(0);
    // generate a new word
    current = WordPair.random();
    notifyListeners();
  }

  var favorites = <WordPair>[];

  void toggleFavorite(pair) {
    if (favorites.contains(pair)) {
      favorites.remove(pair);
    } else {
      favorites.add(pair);
    }
    notifyListeners();
  }
}

class AppScaffold extends StatefulWidget {
  const AppScaffold({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  State<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends State<AppScaffold> {
  int _calculateSelectedIndex(BuildContext context) {
    final GoRouter route = GoRouter.of(context);
    final String location = route.location;
    if (location.startsWith('/generator')) {
      return 0;
    }
    if (location.startsWith('/favorites')) {
      return 1;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("First Flutter App"),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: theme.colorScheme.inversePrimary,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "home",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorites",
          ),
        ],
        currentIndex: _calculateSelectedIndex(context),
        onTap: (value) {
          switch (value) {
            case 0:
              context.go("/generator");
              break;
            case 1:
              context.go("/favorites");
              break;
            default:
              context.go("/generator");
          }
        },
      ),
      body: Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: widget.child,
      ),
    );
  }
}

class GeneratorPage extends StatelessWidget {
  const GeneratorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    var pair = appState.current;

    IconData icon;
    if (appState.favorites.contains(pair)) {
      icon = Icons.favorite;
    } else {
      icon = Icons.favorite_border;
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: HistoryView()),
              SizedBox(height: 20),
              BigCard(pair: pair),
              SizedBox(height: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      appState.toggleFavorite(pair);
                    },
                    icon: Icon(icon),
                    label: Text('Like'),
                  ),
                  SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      appState.getNext();
                    },
                    child: Text('Next'),
                  ),
                ],
              ),
              Spacer(flex: 2)
            ],
          ),
        ),
      ),
    );
  }
}

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  /// Used to "fade out" the history items at the top, to suggest continuation.
  static const Gradient _maskingGradient = LinearGradient(
    // This gradient goes from fully transparent to fully opaque black...
    colors: [Colors.transparent, Colors.black],
    // ... from the top (transparent) to half (0.5) of the way to the bottom.
    stops: [0.0, 0.5],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final _historyViewKey = GlobalKey<AnimatedListState>();
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<MyAppState>();
    appState.historyViewKey = _historyViewKey;

    return ShaderMask(
      shaderCallback: (bounds) =>
          HistoryView._maskingGradient.createShader(bounds),
      blendMode: BlendMode.dstIn,
      child: AnimatedList(
        key: _historyViewKey,
        reverse: true,
        initialItemCount: appState.history.length,
        itemBuilder: (context, index, animation) {
          var pair = appState.history[index];
          var isFavorite = appState.favorites.contains(pair);
          return SizeTransition(
            sizeFactor: animation,
            child: ListTile(
              title: Center(
                child: TextButton.icon(
                  onPressed: () {
                    appState.toggleFavorite(pair);
                  },
                  label: Text(
                    pair.asLowerCase,
                    semanticsLabel: pair.asPascalCase,
                  ),
                  icon: isFavorite
                      ? Icon(
                          Icons.favorite,
                          size: 12,
                        )
                      : SizedBox(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: MergeSemantics(
          child: Wrap(
            children: [
              Text(
                pair.first,
                style: style.copyWith(fontWeight: FontWeight.w100),
              ),
              Text(
                pair.second,
                style: style.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    if (appState.favorites.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text("No favorites yet."),
        ),
      );
    }

    return Scaffold(
      body: ListView.builder(
        padding: EdgeInsets.all(8.0),
        itemCount: appState.favorites.length,
        itemBuilder: (BuildContext context, int index) {
          var pair = appState.favorites[index];
          return ListTile(
            leading: Icon(Icons.favorite),
            title: Text(pair.asLowerCase),
          );
        },
      ),
    );
  }
}
