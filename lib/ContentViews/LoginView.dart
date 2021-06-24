import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:form_field_validator/form_field_validator.dart';

class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  _LoginViewState createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _emailFieldController = TextEditingController();
  final _passwordFieldController = TextEditingController();

  ///Used to validate the email address when the user signs up
  bool _autoValidateEmail = false;

  ///Used to validate the password when the user signs up
  bool _autoValidatePassword = false;

  ///Determine whether to show or hide the password text
  bool _passwordHidden = true;

  ///Switch between showing the password text and blocking it out
  void showHidePassword() {
    setState(() {
      _passwordHidden = !_passwordHidden;
    });
  }

  /// Turn on AutoValidate on the email and password fields to show a warning if either is not valid
  void showEmailPasswordAutoValidation() {
    setState(() {
      _autoValidateEmail = !_autoValidateEmail;
      _autoValidatePassword = !_autoValidatePassword;
    });
  }

  ///Make sure the email address is valid and ends in .edu
  final emailValidator = MultiValidator([
    EmailValidator(errorText: "Enter a valid university email address (no spaces)"),
    EndsWithEDUValidator("Enter a valid university email address (no spaces)"),
    RequiredValidator(errorText: "Enter a valid university email address")
  ]);

  ///Make sure that passwords are at least 8 characters long and contain at least 1 number, 1 uppercase letter, and 1
  /// lowercase letter.
  final passwordValidator = MultiValidator([
    PatternValidator(r'(?=.*[A-Z])(?=.*[a-z])(?=.*?[0-9])',
        errorText: "Password must include at least 1 number, 1 "
            "uppercase letter, and 1 lowercase letter"),
    MinLengthValidator(8, errorText: "Password must contain at least 8 characters"),
    RequiredValidator(errorText: "Please enter a password")
  ]);

  /// Handle user sign ups via Firebase Authentication
  void signUp() {}

  @override
  void initState() {
    super.initState();
    _emailFieldController.addListener(() {
      final String emailAddress = _emailFieldController.text.toLowerCase().trim();

      // block execution of the result of the function if the text didn't change. This is extremely important; otherwise
      // the app will get stuck in an infinite loop.
      if (_emailFieldController.value.text.toLowerCase().trim() == emailAddress) return;
      _emailFieldController.value = _emailFieldController.value.copyWith(
        text: emailAddress,
        selection: TextSelection(baseOffset: emailAddress.length, extentOffset: emailAddress.length),
        composing: TextRange.empty,
      );
    });

    _passwordFieldController.addListener(() {
      final String password = _passwordFieldController.text;

      if (_passwordFieldController.value.text.toLowerCase() == password) return;
      _passwordFieldController.value = _passwordFieldController.value.copyWith(
          text: password,
          selection: TextSelection(baseOffset: password.length, extentOffset: password.length),
          composing: TextRange.empty);
    });
  }

  @override
  void dispose() {
    _emailFieldController.dispose();
    _passwordFieldController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
        navigationBar: CupertinoNavigationBar(middle: Text("Welcome to Podsquad")),
        child: SafeArea(
            child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Podsquad logo
                  CupertinoFormSection(
                      children: [CupertinoFormRow(child: image(named: 'podsquad_logo_improved_2.png'))]),

                  // Email and password
                  CupertinoFormSection(
                    header: Text("Credentials"),
                    children: [
                      CupertinoTextFormFieldRow(
                          keyboardType: TextInputType.emailAddress,
                          autovalidateMode: _autoValidateEmail ? AutovalidateMode.always : AutovalidateMode.disabled,
                          prefix: Text("Email", style: TextStyle(color: CupertinoColors.inactiveGray)),
                          controller: _emailFieldController,
                          validator: emailValidator),
                      Row(
                        children: [
                          Flexible(
                            child: CupertinoTextFormFieldRow(
                              keyboardType: TextInputType.visiblePassword,
                              autovalidateMode:
                                  _autoValidatePassword ? AutovalidateMode.always : AutovalidateMode.disabled,
                              prefix: Text(
                                "Password",
                                style: TextStyle(color: CupertinoColors.inactiveGray),
                              ),
                              controller: _passwordFieldController,
                              obscureText: _passwordHidden,
                              validator: passwordValidator,
                            ),
                          ),
                          CupertinoButton(
                              child: _passwordHidden
                                  ? Opacity(
                                      opacity: 0.8,
                                      child: Icon(CupertinoIcons.eye_slash,
                                          size: 15, color: CupertinoColors.darkBackgroundGray))
                                  : Opacity(
                                      opacity: 0.8,
                                      child: Icon(CupertinoIcons.eye,
                                          size: 15, color: CupertinoColors.darkBackgroundGray)),
                              onPressed: showHidePassword)
                        ],
                      ),
                    ],
                  ),

                  // Sign up, sign in, and forgot password buttons
                  CupertinoFormSection(header: Text("Options"), children: [
                    // sign up button
                    CupertinoButton(
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.plus_circle),
                            Padding(
                                padding: EdgeInsets.only(left: 10),
                                child: Text("Sign "
                                    "Up"))
                          ],
                        ),
                        onPressed: () {
                          this.showEmailPasswordAutoValidation();
                          print("sign up pressed");
                        }),

                    // sign in button
                    CupertinoButton(
                        child: Row(children: [
                          Icon(CupertinoIcons.arrow_right_circle),
                          Padding(padding: EdgeInsets.only(left: 10), child: Text("Sign In"))
                        ]),
                        onPressed: () {
                          this.showEmailPasswordAutoValidation();
                          print("sign in pressed");
                        }),

                    // forgot password button
                    CupertinoButton(
                        child: Row(
                          children: [
                            Icon(CupertinoIcons.question_circle),
                            Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: Text("Forgot Password?"),
                            )
                          ],
                        ),
                        onPressed: () {
                          this.showEmailPasswordAutoValidation();
                          print("forgot password pressed");
                        })
                  ])
                ]),
                clipBehavior: Clip.none)));
  }
}

/// Validates that a text field input ends in .edu. Pass this in as the validator on a text field.
class EndsWithEDUValidator extends FieldValidator {
  EndsWithEDUValidator(String errorText) : super(errorText);

  @override
  bool isValid(value) {
    if (value.toString().endsWith(".edu"))
      return true;
    else
      return false;
  }
}
