import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Handle more options
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Center(
              child: Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: const BoxDecoration(
                      color: Colors.white, // Background color of the circle
                      shape: BoxShape.circle, // Makes the container circular
                    ),
                    child: Center(
                      child: Image.asset(
                        "assets/images/logopng.png",
                        width: 220,
                        height: 220,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // main_view(context),
        ],
      ),
    );
  }

  Container main_view(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xFF0E5F23),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
                width: 200,
                height: 200,
                child: Image.asset(
                  "assets/images/logopng.png",
                  fit: BoxFit.cover,
                )),

            const SizedBox(height: 10),
            // Title
            const Text(
              'DYNAMO CHESS',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            // Subtitle
            const Text(
              'Develop a Dynamic Mind!',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),

            // Buttons
            _buildButton(context, 'Play online', Icons.public),
            const SizedBox(height: 20),
            _buildButton(context, 'Play offline', Icons.wifi_off),
            const SizedBox(height: 20),
            _buildButton(context, 'Puzzles', Icons.extension),
            const SizedBox(height: 20),
            _buildButton(context, 'With Friends', Icons.people),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(BuildContext context, String text, IconData icon) {
    return ElevatedButton.icon(
      onPressed: () {
        // Handle button press
      },
      icon: Icon(icon, color: Colors.white),
      label: Text(text, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green, // Button color
        minimumSize: const Size(200, 50), // Adjust size
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Rounded corners
        ),
      ),
    );
  }
}
