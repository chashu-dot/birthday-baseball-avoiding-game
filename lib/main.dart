import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const BirthdayGameApp());
}

// ============================================================
// アプリ本体
// ============================================================

class BirthdayGameApp extends StatelessWidget {
  const BirthdayGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '幻想野球譚',
      theme: ThemeData.dark(),
      home: const TitleScreen(),
    );
  }
}

// ============================================================
// ゲームモード
// ============================================================

enum GameMode { normal, hard, endless }

// ============================================================
// タイトル画面
// ============================================================

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080817),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),

                  // タイトル
                  const Text(
                    '幻想野球譚',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 6,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    '～ Birthday Danmaku ～',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // 誕生日メッセージ
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.amber.withOpacity(0.7)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '⚾ 20歳の誕生日おめでとう！ ⚾',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 19,
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(height: 45),

                  // NORMAL
                  ModeButton(
                    title: 'NORMAL',
                    subtitle: '15秒間逃げ切れ！',
                    color: Colors.blue,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const GameScreen(mode: GameMode.normal),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  // HARD
                  ModeButton(
                    title: 'HARD',
                    subtitle: 'もっとたくさん飛んでくる',
                    color: Colors.red,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GameScreen(mode: GameMode.hard),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 15),

                  // ENDLESS
                  ModeButton(
                    title: 'ENDLESS',
                    subtitle: '限界まで逃げ続けろ！',
                    color: Colors.purple,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const GameScreen(mode: GameMode.endless),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'PC：WASDで移動\nスマホ：画面をドラッグ',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white54,
                      height: 1.6,
                    ),
                  ),

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// モード選択ボタン
// ============================================================

class ModeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onPressed;

  const ModeButton({
    super.key,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      height: 70,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.18),
          foregroundColor: Colors.white,
          side: BorderSide(color: color, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                letterSpacing: 3,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ゲーム画面
// ============================================================

class GameScreen extends StatefulWidget {
  final GameMode mode;

  const GameScreen({super.key, required this.mode});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

// ============================================================
// ゲーム状態
// ============================================================

class _GameScreenState extends State<GameScreen> {
  // ----------------------------------------------------------
  // キーボード
  // ----------------------------------------------------------

  final FocusNode focusNode = FocusNode();

  final Set<LogicalKeyboardKey> pressedKeys = <LogicalKeyboardKey>{};

  // ----------------------------------------------------------
  // ランダム
  // ----------------------------------------------------------

  final Random random = Random();

  // ----------------------------------------------------------
  // ゲームタイマー
  // ----------------------------------------------------------

  Timer? gameTimer;

  DateTime? lastUpdate;
  DateTime? lastSpawn;

  // ----------------------------------------------------------
  // プレイヤー
  // ----------------------------------------------------------

  double playerX = 0.0;
  double playerY = 0.0;

  // ----------------------------------------------------------
  // ゲーム状態
  // ----------------------------------------------------------

  double elapsed = 0.0;

  bool gameRunning = false;
  bool gameOver = false;
  bool cleared = false;

  // ----------------------------------------------------------
  // ボール
  // ----------------------------------------------------------

  final List<GameBall> balls = <GameBall>[];

  // ----------------------------------------------------------
  // 定数
  // ----------------------------------------------------------

  static const double playerRadius = 11.0;

  static const double playerSpeed = 300.0;

  // ==========================================================
  // 初期化
  // ==========================================================

  @override
  void initState() {
    super.initState();

    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      updateGame();
    });
  }

  // ==========================================================
  // 終了処理
  // ==========================================================

  @override
  void dispose() {
    gameTimer?.cancel();
    focusNode.dispose();
    super.dispose();
  }

  // ==========================================================
  // ゲーム開始
  // ==========================================================

  void startGame(Size size) {
    playerX = size.width / 2.0;
    playerY = size.height * 0.75;

    elapsed = 0.0;

    balls.clear();

    gameOver = false;
    cleared = false;
    gameRunning = true;

    lastUpdate = DateTime.now();
    lastSpawn = DateTime.now();

    focusNode.requestFocus();

    setState(() {});
  }

  // ==========================================================
  // ゲーム更新
  // ==========================================================

  void updateGame() {
    if (!mounted) {
      return;
    }

    if (!gameRunning) {
      return;
    }

    final DateTime now = DateTime.now();

    if (lastUpdate == null) {
      lastUpdate = now;
      return;
    }

    final double dt = now.difference(lastUpdate!).inMilliseconds / 1000.0;

    lastUpdate = now;

    // --------------------------------------------------------
    // 時間
    // --------------------------------------------------------

    elapsed += dt;

    // --------------------------------------------------------
    // プレイヤー移動
    // --------------------------------------------------------

    updatePlayer(dt);

    // --------------------------------------------------------
    // ボール生成
    // --------------------------------------------------------

    if (lastSpawn == null) {
      lastSpawn = now;
    }

    final int millisecondsSinceSpawn = now
        .difference(lastSpawn!)
        .inMilliseconds;

    if (millisecondsSinceSpawn >= spawnInterval) {
      spawnBall();
      lastSpawn = now;
    }

    // --------------------------------------------------------
    // ボール移動
    // --------------------------------------------------------

    for (final GameBall ball in balls) {
      ball.x += ball.vx * dt;
      ball.y += ball.vy * dt;
    }

    // --------------------------------------------------------
    // 画面外のボールを削除
    // --------------------------------------------------------

    final Size size = MediaQuery.of(context).size;

    balls.removeWhere((GameBall ball) {
      return ball.x < -100.0 ||
          ball.x > size.width + 100.0 ||
          ball.y < -100.0 ||
          ball.y > size.height + 100.0;
    });

    // --------------------------------------------------------
    // 当たり判定
    // --------------------------------------------------------

    for (final GameBall ball in balls) {
      final double dx = ball.x - playerX;
      final double dy = ball.y - playerY;

      final double distance = sqrt(dx * dx + dy * dy);

      final double hitDistance = ball.radius + playerRadius;

      if (distance < hitDistance) {
        finishGame(false);
        return;
      }
    }

    // --------------------------------------------------------
    // 15秒クリア
    // --------------------------------------------------------

    if (widget.mode != GameMode.endless) {
      if (elapsed >= 15.0) {
        finishGame(true);
        return;
      }
    }

    setState(() {});
  }

  // ==========================================================
  // プレイヤー移動
  // ==========================================================

  void updatePlayer(double dt) {
    double dx = 0.0;
    double dy = 0.0;

    // W
    if (pressedKeys.contains(LogicalKeyboardKey.keyW)) {
      dy -= 1.0;
    }

    // S
    if (pressedKeys.contains(LogicalKeyboardKey.keyS)) {
      dy += 1.0;
    }

    // A
    if (pressedKeys.contains(LogicalKeyboardKey.keyA)) {
      dx -= 1.0;
    }

    // D
    if (pressedKeys.contains(LogicalKeyboardKey.keyD)) {
      dx += 1.0;
    }

    // --------------------------------------------------------
    // 斜め移動の速度を一定にする
    // --------------------------------------------------------

    if (dx != 0.0 || dy != 0.0) {
      final double length = sqrt(dx * dx + dy * dy);

      dx /= length;
      dy /= length;

      playerX += dx * playerSpeed * dt;
      playerY += dy * playerSpeed * dt;
    }

    // --------------------------------------------------------
    // 画面外に出ないようにする
    // --------------------------------------------------------

    final Size size = MediaQuery.of(context).size;

    final double minX = playerRadius;
    final double maxX = size.width - playerRadius;

    final double minY = 55.0;
    final double maxY = size.height - playerRadius;

    if (playerX < minX) {
      playerX = minX;
    }

    if (playerX > maxX) {
      playerX = maxX;
    }

    if (playerY < minY) {
      playerY = minY;
    }

    if (playerY > maxY) {
      playerY = maxY;
    }
  }

  // ==========================================================
  // ボール生成
  // ==========================================================

  void spawnBall() {
    final Size size = MediaQuery.of(context).size;

    final int side = random.nextInt(4);

    double x;
    double y;

    // --------------------------------------------------------
    // ボールの出現位置
    // --------------------------------------------------------

    if (side == 0) {
      // 上

      x = random.nextDouble() * size.width;
      y = -30.0;
    } else if (side == 1) {
      // 右

      x = size.width + 30.0;
      y = random.nextDouble() * size.height;
    } else if (side == 2) {
      // 下

      x = random.nextDouble() * size.width;
      y = size.height + 30.0;
    } else {
      // 左

      x = -30.0;
      y = random.nextDouble() * size.height;
    }

    // --------------------------------------------------------
    // プレイヤー方向へ飛ばす
    // --------------------------------------------------------

    double dx = playerX - x;
    double dy = playerY - y;

    final double distance = sqrt(dx * dx + dy * dy);

    if (distance == 0.0) {
      return;
    }

    dx /= distance;
    dy /= distance;

    // --------------------------------------------------------
    // スピード
    // --------------------------------------------------------

    double speed;

    if (widget.mode == GameMode.hard) {
      speed = 300.0 + random.nextDouble() * 180.0;
    } else if (widget.mode == GameMode.endless) {
      // 10秒ごとに少しずつ速くする
      final double difficultyLevel = (elapsed / 10.0).floorToDouble();

      speed = 190.0 + difficultyLevel * 25.0 + random.nextDouble() * 130.0;
    } else {
      speed = 190.0 + random.nextDouble() * 130.0;
    }

    // --------------------------------------------------------
    // ボール追加
    // --------------------------------------------------------

    balls.add(
      GameBall(x: x, y: y, vx: dx * speed, vy: dy * speed, radius: 12.0),
    );

    // --------------------------------------------------------
    // HARDの場合は追加弾
    // --------------------------------------------------------

    if (widget.mode == GameMode.hard) {
      if (random.nextDouble() < 0.35) {
        spawnExtraBall();
      }
    }
  }

  // ==========================================================
  // HARD追加ボール
  // ==========================================================

  void spawnExtraBall() {
    final Size size = MediaQuery.of(context).size;

    final double x = random.nextDouble() * size.width;

    final double y = -20.0;

    final double angle = pi / 4.0 + random.nextDouble() * pi / 2.0;

    final double speed = 280.0 + random.nextDouble() * 160.0;

    balls.add(
      GameBall(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        radius: 10.0,
      ),
    );
  }

  // ==========================================================
  // スマホ操作
  // ==========================================================

  void movePlayerByTouch(Offset position) {
    if (!gameRunning) {
      return;
    }

    playerX = position.dx;
    playerY = position.dy;

    final Size size = MediaQuery.of(context).size;

    playerX = playerX.clamp(playerRadius, size.width - playerRadius);

    playerY = playerY.clamp(55.0, size.height - playerRadius);

    setState(() {});
  }

  // ==========================================================
  // ゲーム終了
  // ==========================================================

  void finishGame(bool success) {
    gameRunning = false;

    if (success) {
      cleared = true;
      gameOver = false;
    } else {
      cleared = false;
      gameOver = true;
    }

    setState(() {});
  }

  // ==========================================================
  // リスタート
  // ==========================================================

  void restartGame() {
    final Size size = MediaQuery.of(context).size;

    startGame(size);
  }

  // ==========================================================
  // タイトルに戻る
  // ==========================================================

  void backToTitle() {
    Navigator.pop(context);
  }

  // ==========================================================
  // モード名
  // ==========================================================

  String get modeName {
    switch (widget.mode) {
      case GameMode.normal:
        return 'NORMAL';

      case GameMode.hard:
        return 'HARD';

      case GameMode.endless:
        return 'ENDLESS';
    }
  }

  // ==========================================================
  // ボール出現間隔
  // ==========================================================

  int get spawnInterval {
    switch (widget.mode) {
      case GameMode.normal:
        return 500;

      case GameMode.hard:
        return 230;

      case GameMode.endless:
        // 時間が経つほど出現間隔を短くする
        final int difficultyLevel = (elapsed / 10.0).floor();

        final int interval = 420 - difficultyLevel * 35;

        // 最低100msまで
        return max(100, interval);
    }
  }

  // ==========================================================
  // 画面
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    // 初回起動
    if (!gameRunning &&
        !gameOver &&
        !cleared &&
        playerX == 0.0 &&
        playerY == 0.0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          startGame(size);
        }
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF080817),
      body: SafeArea(
        child: KeyboardListener(
          focusNode: focusNode,
          autofocus: true,
          onKeyEvent: (KeyEvent event) {
            // キーを押した
            if (event is KeyDownEvent) {
              pressedKeys.add(event.logicalKey);
            }

            // キーを離した
            if (event is KeyUpEvent) {
              pressedKeys.remove(event.logicalKey);
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,

            // スマホで指を動かした
            onPanStart: (DragStartDetails details) {
              movePlayerByTouch(details.localPosition);
            },

            onPanUpdate: (DragUpdateDetails details) {
              movePlayerByTouch(details.localPosition);
            },

            child: Stack(
              children: [
                // =================================================
                // ゲーム描画
                // =================================================
                Positioned.fill(
                  child: CustomPaint(
                    painter: GamePainter(
                      balls: balls,
                      playerX: playerX,
                      playerY: playerY,
                    ),
                  ),
                ),

                // =================================================
                // 上部UI
                // =================================================
                Positioned(
                  top: 10.0,
                  left: 15.0,
                  right: 15.0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        modeName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white70,
                        ),
                      ),

                      Text(
                        widget.mode == GameMode.endless
                            ? '${elapsed.toStringAsFixed(2)} 秒'
                            : '${min(elapsed, 15.0).toStringAsFixed(2)} / 15.00 秒',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // =================================================
                // 操作説明
                // =================================================
                if (gameRunning)
                  Positioned(
                    bottom: 15.0,
                    left: 0.0,
                    right: 0.0,
                    child: IgnorePointer(
                      child: Center(
                        child: Text(
                          'WASD / ドラッグで移動',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.35),
                          ),
                        ),
                      ),
                    ),
                  ),

                // =================================================
                // ゲームオーバー
                // =================================================
                if (gameOver)
                  ResultOverlay(
                    title: 'GAME OVER',
                    message: '⚾ ボールに当たってしまった！',
                    time: elapsed,
                    success: false,
                    onRestart: restartGame,
                    onTitle: backToTitle,
                  ),

                // =================================================
                // クリア
                // =================================================
                if (cleared)
                  ResultOverlay(
                    title: 'CLEAR!',
                    message: '15秒間、逃げ切った！\n\n🎂 HAPPY BIRTHDAY! 🎂',
                    time: elapsed,
                    success: true,
                    onRestart: restartGame,
                    onTitle: backToTitle,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 野球ボールクラス
// ============================================================

class GameBall {
  double x;
  double y;

  double vx;
  double vy;

  double radius;

  GameBall({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
  });
}

// ============================================================
// ゲーム描画
// ============================================================

class GamePainter extends CustomPainter {
  final List<GameBall> balls;

  final double playerX;
  final double playerY;

  GamePainter({
    required this.balls,
    required this.playerX,
    required this.playerY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // ========================================================
    // 背景
    // ========================================================

    final Paint backgroundPaint = Paint();

    backgroundPaint.shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF11112C), Color(0xFF080817), Color(0xFF170B20)],
    ).createShader(Rect.fromLTWH(0.0, 0.0, size.width, size.height));

    canvas.drawRect(
      Rect.fromLTWH(0.0, 0.0, size.width, size.height),
      backgroundPaint,
    );

    // ========================================================
    // 背景の円
    // ========================================================

    final Paint circlePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withOpacity(0.05);

    final Offset center = Offset(size.width / 2.0, size.height / 2.0);

    for (int i = 1; i <= 7; i++) {
      canvas.drawCircle(center, i * 65.0, circlePaint);
    }

    // ========================================================
    // 背景の星
    // ========================================================

    final Paint starPaint = Paint()..color = Colors.white.withOpacity(0.12);

    final Random starRandom = Random(12345);

    for (int i = 0; i < 45; i++) {
      final double starX = starRandom.nextDouble() * size.width;

      final double starY = starRandom.nextDouble() * size.height;

      canvas.drawCircle(Offset(starX, starY), 1.0, starPaint);
    }

    // ========================================================
    // ボール
    // ========================================================

    for (final GameBall ball in balls) {
      drawBaseball(canvas, Offset(ball.x, ball.y), ball.radius);
    }

    // ========================================================
    // プレイヤー
    // ========================================================

    drawPlayer(canvas, Offset(playerX, playerY));
  }

  // ==========================================================
  // 野球ボール描画
  // ==========================================================

  void drawBaseball(Canvas canvas, Offset position, double radius) {
    // --------------------------------------------------------
    // 影
    // --------------------------------------------------------

    final Paint shadowPaint = Paint()..color = Colors.black.withOpacity(0.45);

    canvas.drawCircle(
      position + const Offset(2.0, 3.0),
      radius + 1.0,
      shadowPaint,
    );

    // --------------------------------------------------------
    // ボール本体
    // --------------------------------------------------------

    final Paint ballPaint = Paint();

    ballPaint.shader = RadialGradient(
      colors: [Colors.white, Colors.grey.shade300],
    ).createShader(Rect.fromCircle(center: position, radius: radius));

    canvas.drawCircle(position, radius, ballPaint);

    // --------------------------------------------------------
    // 縫い目
    // --------------------------------------------------------

    final Paint seamPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final Path seamPath = Path();

    seamPath.moveTo(position.dx - radius * 0.55, position.dy - radius * 0.55);

    seamPath.quadraticBezierTo(
      position.dx,
      position.dy,
      position.dx + radius * 0.55,
      position.dy + radius * 0.55,
    );

    canvas.drawPath(seamPath, seamPaint);
  }

  // ==========================================================
  // プレイヤー描画
  // ==========================================================

  void drawPlayer(Canvas canvas, Offset position) {
    // --------------------------------------------------------
    // 外側の光
    // --------------------------------------------------------

    final Paint glowPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.10);

    canvas.drawCircle(position, 32.0, glowPaint);

    final Paint glowPaint2 = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.15);

    canvas.drawCircle(position, 22.0, glowPaint2);

    // --------------------------------------------------------
    // プレイヤー本体
    // --------------------------------------------------------

    final Paint playerPaint = Paint()..color = Colors.cyanAccent;

    canvas.drawCircle(position, 11.0, playerPaint);

    // --------------------------------------------------------
    // 中心
    // --------------------------------------------------------

    final Paint centerPaint = Paint()..color = Colors.white;

    canvas.drawCircle(position, 3.0, centerPaint);
  }

  @override
  bool shouldRepaint(covariant GamePainter oldDelegate) {
    return true;
  }
}

// ============================================================
// 結果画面
// ============================================================

class ResultOverlay extends StatelessWidget {
  final String title;
  final String message;
  final double time;
  final bool success;

  final VoidCallback onRestart;
  final VoidCallback onTitle;

  const ResultOverlay({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.success,
    required this.onRestart,
    required this.onTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.82),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // ------------------------------------------------
                // タイトル
                // ------------------------------------------------
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    color: success ? Colors.amber : Colors.redAccent,
                  ),
                ),

                const SizedBox(height: 25),

                // ------------------------------------------------
                // メッセージ
                // ------------------------------------------------
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 18, height: 1.6),
                ),

                const SizedBox(height: 25),

                // ------------------------------------------------
                // 記録
                // ------------------------------------------------
                Text(
                  '${time.toStringAsFixed(2)} 秒',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 40),

                // ------------------------------------------------
                // もう一度
                // ------------------------------------------------
                SizedBox(
                  width: 230,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: onRestart,
                    child: const Text('もう一度遊ぶ', style: TextStyle(fontSize: 17)),
                  ),
                ),

                const SizedBox(height: 12),

                // ------------------------------------------------
                // タイトルへ
                // ------------------------------------------------
                TextButton(onPressed: onTitle, child: const Text('タイトルへ戻る')),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
