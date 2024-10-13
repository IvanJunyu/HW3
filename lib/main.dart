import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Matching Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameProvider(vsync: this),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Card Matching Game'),
        ),
        body: Center(
          child: Consumer<GameProvider>(
            builder: (context, gameProvider, child) {
              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, 
                  childAspectRatio: 1,
                ),
                itemCount: gameProvider.cards.length,
                itemBuilder: (context, index) {
                  return CardWidget(index: index);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class CardWidget extends StatefulWidget {
  final int index;

  const CardWidget({super.key, required this.index});

  @override
  _CardWidgetState createState() => _CardWidgetState();
}

class _CardWidgetState extends State<CardWidget> {
  @override
  Widget build(BuildContext context) {
    final gameProvider = Provider.of<GameProvider>(context);
    final card = gameProvider.cards[widget.index];

    return GestureDetector(
      onTap: () {
        if (!gameProvider.isAnimating) {
          gameProvider.flipCard(widget.index);
        }
      },
      child: AnimatedBuilder(
        animation: card.controller,
        builder: (context, child) {
          final isFlipped = card.controller.value >= 0.5;

          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(card.controller.value * 3.5) 
              ..scale(1 + (0.1 * card.controller.value)), 
            child: isFlipped ? _buildFrontCard(card.frontImage) : _buildBackCard(),
          );
        },
      ),
    );
  }

  Widget _buildFrontCard(String imagePath) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildBackCard() {
    return Container(
      margin: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        image: const DecorationImage(
          image: AssetImage('assets/bg.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class CardModel {
  final String frontImage;
  bool isFaceUp;
  late AnimationController controller; 

  CardModel({required this.frontImage, this.isFaceUp = false, required TickerProvider vsync}) {
    controller = AnimationController(
      duration: const Duration(milliseconds: 800), 
      vsync: vsync,
    );
  }
}

class GameProvider with ChangeNotifier {
  List<CardModel> cards = [];
  bool isAnimating = false;
  List<int> flippedCards = [];
  final TickerProvider vsync;

  GameProvider({required this.vsync}) {
    _initializeCards();
  }

  void _initializeCards() {
    List<String> images = [
      'assets/1.png',
      'assets/2.png',
      'assets/3.png',
      'assets/4.png',
      'assets/5.png',
      'assets/6.png',
      'assets/7.png',
      'assets/8.png',
      'assets/9.png',
      'assets/10.png',
      'assets/11.png',
      'assets/12.png',
    ];

    cards = images
        .expand((image) => [
              CardModel(frontImage: image, vsync: vsync),
              CardModel(frontImage: image, vsync: vsync)
            ])
        .toList();

    cards.shuffle();
    notifyListeners();
  }

  void flipCard(int index) {
    if (flippedCards.length < 2 && !cards[index].isFaceUp && !isAnimating) {
      cards[index].isFaceUp = true;
      cards[index].controller.forward();
      flippedCards.add(index);

      if (flippedCards.length == 2) {
        isAnimating = true;
        _checkMatch();
      }
      notifyListeners();
    }
  }

  void _checkMatch() {
    Future.delayed(const Duration(seconds: 1), () {
      if (cards[flippedCards[0]].frontImage == cards[flippedCards[1]].frontImage) {
        flippedCards.clear();
      } else {
        cards[flippedCards[0]].isFaceUp = false;
        cards[flippedCards[1]].isFaceUp = false;
        cards[flippedCards[0]].controller.reverse();
        cards[flippedCards[1]].controller.reverse();
        flippedCards.clear();
        notifyListeners();
      }
      isAnimating = false;
    });
  }
}
