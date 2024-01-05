import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MyInputField extends StatelessWidget {
  // final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final icon;
  final TextEditingController? controller;
  final suffixIcon;
  final bool? enable;
  final bool readOnly;
  final onTap;
  final bool isNumber;

  const MyInputField(
      {super.key,
      required this.hintText,
      required this.obscureText,
      required this.icon,
      required this.controller,
      this.suffixIcon,
      this.enable,
      this.readOnly = false,
      this.onTap,
      this.isNumber = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onTap: onTap,
      readOnly: readOnly,
      enabled: enable,
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              // borderSide: BorderSide(color: Color(044473))),
              borderSide: const BorderSide(color: Colors.deepOrange)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.deepOrange),
            borderRadius: BorderRadius.circular(15),
          ),
          fillColor: Colors.white,
          filled: true,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey.shade600),
          prefixIcon: icon,
          suffixIcon: suffixIcon != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 20,
                      child: VerticalDivider(color: Colors.grey),
                    ),
                    suffixIcon!,
                  ],
                )
              : null,
          suffixIconColor: Colors.grey.shade800,
          contentPadding: EdgeInsets.symmetric(vertical: 15)),
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
    );
  }
}
