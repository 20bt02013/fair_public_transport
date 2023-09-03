import 'package:flutter/material.dart';

TextField reuseTextField(
  String text,
  IconData icon,
  bool isPasswordType,
  TextEditingController controller,
  bool obscureText, // Pass the obscureText variable
  Function
      togglePasswordVisibility, // Pass the togglePasswordVisibility callback
) {
  return TextField(
    controller: controller,
    obscureText:
        isPasswordType ? obscureText : false, // Use the 'obscureText' variable
    enableSuggestions: !isPasswordType,
    autocorrect: isPasswordType,
    cursorColor: Colors.black,
    style: TextStyle(
      color: Colors.black.withOpacity(0.9),
    ),
    decoration: InputDecoration(
      prefixIcon: Icon(
        icon,
        color: Colors.black,
      ),
      labelText: text,
      labelStyle: TextStyle(
        color: Colors.black.withOpacity(0.9),
      ),
      filled: false,
      // Add a suffix icon button to toggle password visibility
      suffixIcon: isPasswordType
          ? IconButton(
              icon: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.black,
              ),
              onPressed: () {
                // Call the callback to toggle password visibility
                togglePasswordVisibility();
              },
            )
          : null, // No suffix icon for non-password fields
    ),
    keyboardType: isPasswordType
        ? TextInputType.visiblePassword
        : TextInputType.emailAddress,
  );
}

// TextField reuseTextField(String text, IconData icon, bool isPasswordType,
//     TextEditingController controller) {
//   return TextField(
//     controller: controller,
//     obscureText: isPasswordType,
//     enableSuggestions: !isPasswordType,
//     autocorrect: isPasswordType,
//     cursorColor: Colors.black,
//     style: TextStyle(
//       color: Colors.black.withOpacity(0.9),
//     ),
//     decoration: InputDecoration(
//       prefixIcon: Icon(
//         icon,
//         color: Colors.black,
//       ),
//       labelText: text,
//       labelStyle: TextStyle(
//         color: Colors.black.withOpacity(0.9),
//       ),
//       filled: false,
//     ),
//     keyboardType: isPasswordType
//         ? TextInputType.visiblePassword
//         : TextInputType.emailAddress,
//   );
// }

TextField reuseInfoTextField(String text, IconData icon, bool isPasswordType,
    TextEditingController controller) {
  return TextField(
    controller: controller,
    obscureText: isPasswordType,
    enableSuggestions: !isPasswordType,
    autocorrect: isPasswordType,
    cursorColor: Colors.black,
    style: TextStyle(
      color: Colors.black.withOpacity(0.9),
    ),
    decoration: InputDecoration(
      prefixIcon: Icon(
        icon,
        color: Colors.black,
      ),
      labelText: text,
      labelStyle: TextStyle(
        color: Colors.black.withOpacity(0.9),
      ),
      filled: false,
    ),
    keyboardType: isPasswordType
        ? TextInputType.visiblePassword
        : TextInputType.emailAddress,
  );
}

Center logInSignUpBtn(BuildContext context, bool isLogin, Function onTap) {
  return Center(
    child: Container(
      width: MediaQuery.of(context).size.width * 0.4,
      height: 45,
      margin: const EdgeInsets.fromLTRB(0, 10, 0, 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white70,
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          onTap();
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.pressed)) {
              return Colors.blue.shade200;
            }
            return Colors.blueGrey;
          }),
          shape:
              MaterialStateProperty.all<OutlinedBorder>(const StadiumBorder()),
        ),
        child: Text(
          isLogin ? 'LOG IN' : 'SIGN UP',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    ),
  );
}
