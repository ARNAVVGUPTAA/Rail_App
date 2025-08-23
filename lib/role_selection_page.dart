import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for SystemNavigator.pop
import 'actions_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  void _navigateToActionsPage(BuildContext context, String role) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => ActionsPage(selectedRole: role)),
    );
  }

  // This function shows the confirmation dialog for exiting the app
  void _showExitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App?'),
        content: const Text('Are you sure you want to close the app?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(false), // Dismisses the dialog
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirms exit
            child: const Text('Yes'),
          ),
        ],
      ),
    ).then((exit) {
      if (exit == true) {
        // This will close the application
        SystemNavigator.pop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // PopScope handles the back button press
    return PopScope(
      canPop: false, // Prevents default back navigation
      onPopInvoked: (bool didPop) {
        if (!didPop) {
          // Shows the custom exit dialog instead
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        // The app bar is styled to match the image
        appBar: AppBar(
          title: const Text(
            'Select Role',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF2C3E50), // Dark blue-gray color
          centerTitle: true,
          automaticallyImplyLeading: false, // Removes the default back button
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Themed button for "Field Staff"
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // White background
                    foregroundColor: const Color(0xFF34495E), // Dark text color
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners
                      side: BorderSide(
                        color: Colors.grey.shade400, // Light grey border
                        width: 1.5,
                      ),
                    ),
                    elevation: 2, // Subtle shadow
                  ),
                  onPressed: () =>
                      _navigateToActionsPage(context, 'Field Staff'),
                  child: const Text('Field Staff'),
                ),
                const SizedBox(height: 24),
                // Themed button for "Supervisor"
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // White background
                    foregroundColor: const Color(0xFF34495E), // Dark text color
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        12,
                      ), // Rounded corners
                      side: BorderSide(
                        color: Colors.grey.shade400, // Light grey border
                        width: 1.5,
                      ),
                    ),
                    elevation: 2, // Subtle shadow
                  ),
                  onPressed: () =>
                      _navigateToActionsPage(context, 'Supervisor'),
                  child: const Text('Supervisor'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
