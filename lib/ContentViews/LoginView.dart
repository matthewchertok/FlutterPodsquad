import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:podsquad/BackendDataHolders/UserAuth.dart';
import 'package:podsquad/CommonlyUsedClasses/UsefulValues.dart';
import 'package:form_field_validator/form_field_validator.dart';
import 'package:podsquad/OtherSpecialViews/TutorialSheets.dart';

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

  ///Determine whether to disable the sign up button. Button should be disable while waiting for network response to
  ///prevent multiple requests from being made.
  bool _signUpButtonDisabled = false;

  ///Determine whether to disable the sign in button. Button should be disabled while waiting for network response in
  /// order to prevent multiple requests from being made
  bool _signInButtonDisabled = false;

  ///Determine whether to disable the forgot password button. Button should be disable while waiting for network response to
  /// prevent multiple requests from being made.
  bool _forgotPasswordButtonDisabled = false;

  /// Whitelisted email addresses for testing
  List<String> _whitelistedEmailAddresses = ['1@2.com', '1@4.com', 'testaccount@podsquad.com', 'matthewchertok@gmail'
      '.com'];

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
  void _signUp({required String email, required String password}) {
    final isValidEmail = emailValidator.isValid(email) || _whitelistedEmailAddresses.contains(email);
    final isValidPassword = passwordValidator.isValid(password);
    if (isValidEmail && isValidPassword) {
      _signUpButtonDisabled = true; // disable the button while a network request is in progress
      firebaseAuth.createUserWithEmailAndPassword(email: email, password: password).then((authResult) {
        // if there is no error, send the verification link to the email address and re-enable the sign up button.
        _sendEmailVerificationLink(email: email, password: password);
      }).catchError((error) {
        final alert = CupertinoAlertDialog(
            title: Text("Error Creating Account"),
            content: Text("If you previously "
                "signed up with this email address, tap Resend for a new verification link."),
            actions: [
              CupertinoButton(
                  child: Text("Cancel"),
                  onPressed: () {
                    _signUpButtonDisabled = false; // re-enable the sign up button
                    Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert
                  }),
              CupertinoButton(
                  child: Text("Resend"),
                  onPressed: () {
                    // send an email verification link
                    _sendEmailVerificationLink(email: email, password: password);
                    Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert
                  }),
            ]);
        showCupertinoDialog(
            context: context,
            builder: (context) {
              return alert;
            });
      });
    } else {
      final alert = CupertinoAlertDialog(
          title: Text("Sign Up Failed"),
          content: Text("The email and password "
              "combination is not valid."),
          actions: [
            CupertinoButton(
                child: Text("OK"),
                onPressed: () {
                  _signUpButtonDisabled = false;
                  Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert
                })
          ]);
      showCupertinoDialog(context: context, builder: (context) => alert);
    }
  }

  ///Send an email verification link to verify a user and re-enables the sign up button once the sign up process is
  ///complete
  void _sendEmailVerificationLink({required String email, required String password}) {
    final actionCodeSettings = ActionCodeSettings(
        url: 'https://podsquad.page.link/Zi7X', handleCodeInApp: false, iOSBundleId: 'com.coldex.podsquad');

    // sign the user in with Firebase (but don't update the UI) so that we can send an email verification link
    firebaseAuth.signInWithEmailAndPassword(email: email, password: password).then((authResult) {
      // Now send the email verification link
      firebaseAuth.currentUser?.sendEmailVerification(actionCodeSettings).then((value) {
        // we must sign out after sending the email verification link to force the user to actually verify their email
        UserAuth.shared.logOut();
        final alert = CupertinoAlertDialog(
            title: Text("Check Your Email"),
            content: Text("Click the link that was "
                "sent to your email address to confirm your account!"),
            actions: [
              CupertinoButton(
                  child: Text("OK"),
                  onPressed: () {
                    _signUpButtonDisabled = false;
                    Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert
                  })
            ]);
        showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return alert;
            });
      }).catchError((error) {
        final alert = CupertinoAlertDialog(
            title: Text("An Error Occurred"),
            content: Text("Unable to send a "
                "verification link to $email"),
            actions: [
              CupertinoButton(
                  child: Text("OK"),
                  onPressed: () {
                    _signUpButtonDisabled = false;
                    Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert
                  })
            ]);
        showCupertinoDialog(
            context: context,
            builder: (BuildContext context) {
              return alert;
            });
      });
    }).catchError((error) {
      final alert = CupertinoAlertDialog(
          title: Text("Sign Up Failed"),
          content: Text("This email address is already "
              "taken."),
          actions: [
            CupertinoButton(
                child: Text("OK"),
                onPressed: () {
                  _signUpButtonDisabled = false;
                  Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert
                })
          ]);
      showCupertinoDialog(
          context: context,
          builder: (BuildContext context) {
            return alert;
          });
    });
  }

  /// Handles the sign in process
  void _signIn({required String email, required String password}) {
    _signInButtonDisabled = true;

    firebaseAuth.signInWithEmailAndPassword(email: email, password: password).then((authResult) {
      final isEmailVerified = authResult.user?.emailVerified ?? false;

      // if the email is verified, update the UI since sign in was successful.
      if (isEmailVerified) {
        _signInButtonDisabled = false;
        UserAuth.shared.updateUIToLoggedInView();
      } else {
        UserAuth.shared.logOut();
        final alert = CupertinoAlertDialog(
            title: Text("Email Address Not Verified"),
            content: Text("Please click "
                "the link that was sent to your email address to verify your account. If you lost that email, please "
                "sign up again."),
            actions: [
              CupertinoButton(
                  child: Text("OK"),
                  onPressed: () {
                    _signInButtonDisabled = false;
                    Navigator.of(context, rootNavigator: true).pop();
                  })
            ]);
        showCupertinoDialog(
            context: context,
            builder: (context) {
              return alert;
            });
      }
    }).catchError((error) {
      UserAuth.shared.logOut();
      final alert = CupertinoAlertDialog(
          title: Text("Login Failed"),
          content: Text("The email and password combination is incorrect."),
          actions: [
            CupertinoButton(
                child: Text("OK"),
                onPressed: () {
                  _signInButtonDisabled = false;
                  Navigator.of(context, rootNavigator: true).pop();
                })
          ]);
      showCupertinoDialog(
          context: context,
          builder: (context) {
            return alert;
          });
    });
  }

  /// Send a link to the user's email address so they can reset their password
  void sendPasswordResetEmail({required String emailAddress}) {
    _forgotPasswordButtonDisabled = true; // stop the user from repeatedly tapping this and sending themselves
    // multiple emails

    // make sure the email address is valid
    if (emailValidator.isValid(emailAddress)) {
      firebaseAuth.sendPasswordResetEmail(email: emailAddress).then((value) {
        final alert = CupertinoAlertDialog(
            title: Text("Password Reset Sent"),
            content: Text("Check your email for a "
                "link to reset your password!"),
            actions: [
              CupertinoButton(
                  child: Text("OK"),
                  onPressed: () {
                    _forgotPasswordButtonDisabled = false; // allow the user to tap the Forgot Password button again
                    Navigator.of(context, rootNavigator: true).pop();
                  })
            ]);
        showCupertinoDialog(context: context, builder: (context) => alert);
      }).catchError((error) {
        final alert = CupertinoAlertDialog(
            title: Text("Password Reset Error"),
            content: Text("Password reset email "
                "failed to send. Make sure this email address is associated with a valid Podsquad account."),
            actions: [
              CupertinoButton(
                  child: Text("OK"),
                  onPressed: () {
                    _forgotPasswordButtonDisabled = false;
                    Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert
                  })
            ]);
        showCupertinoDialog(context: context, builder: (context) => alert);
      });
    } else {
      final alert = CupertinoAlertDialog(
          title: Text("Invalid Email"),
          content: Text("You must be a current or "
              "recent university student to use Podsquad. Please enter a valid .edu email address."),
          actions: [
            CupertinoButton(
                child: Text("OK"),
                onPressed: () {
                  _forgotPasswordButtonDisabled = false;
                  Navigator.of(context, rootNavigator: true).pop(); // dismiss the alert
                })
          ]);
      showCupertinoDialog(context: context, builder: (context) => alert);
    }
  }

  @override
  void initState() {
    super.initState();
    showLoginTutorialIfNecessary(context: context).then((_) {
      showEULAIfNecessary(context: context);
    });

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

      if (_passwordFieldController.value.text == password) return;
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
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            largeTitle: Text("Podsquad"),
          ),
          SliverList(
              delegate: SliverChildListDelegate([
            SafeArea(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Podsquad logo

                CupertinoFormRow(child: image(named: 'podsquad_logo_improved_2.png')),

                // Email and password
                CupertinoFormSection(
                  header: Text("Credentials"),
                  children: [
                    CupertinoTextFormFieldRow(
                        keyboardType: TextInputType.emailAddress,
                        autovalidateMode: _autoValidateEmail ? AutovalidateMode.always : AutovalidateMode.disabled,
                        placeholder: "Email",
                        controller: _emailFieldController,
                        validator: emailValidator),
                    Row(
                      children: [
                        Flexible(
                          child: CupertinoTextFormFieldRow(
                            keyboardType: TextInputType.visiblePassword,
                            autovalidateMode:
                                _autoValidatePassword ? AutovalidateMode.always : AutovalidateMode.disabled,
                            placeholder: "Password",
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
                                    child:
                                        Icon(CupertinoIcons.eye, size: 15, color: CupertinoColors.darkBackgroundGray)),
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
                        if (!_signUpButtonDisabled)
                          _signUp(email: _emailFieldController.text.trim(), password: _passwordFieldController.text);
                      }),

                  // sign in button
                  CupertinoButton(
                      child: Row(children: [
                        Icon(CupertinoIcons.arrow_right_circle),
                        Padding(padding: EdgeInsets.only(left: 10), child: Text("Sign In"))
                      ]),
                      onPressed: () {
                        this.showEmailPasswordAutoValidation();
                        if (!_signInButtonDisabled)
                          _signIn(email: _emailFieldController.text.trim(), password: _passwordFieldController.text);
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
                        if (!_forgotPasswordButtonDisabled)
                          sendPasswordResetEmail(emailAddress: _emailFieldController.text.trim());
                      })
                ])
              ]),
            )
          ]))
        ],
      ),
    );
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
