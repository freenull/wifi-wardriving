import "package:flutter/material.dart";
import "backend.dart";
import "main.dart";

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text("Login"),
            bottom: TabBar(
              tabs: [
                Tab(text: 'Login'),
                Tab(text: 'Register'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              LoginCard(),
              RegisterCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginCard extends StatefulWidget {
    const LoginCard({super.key});

    @override
    State<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends State<LoginCard> {
    final usernameTextField = TextEditingController();
    final passwordTextField = TextEditingController();
    bool passwordFieldVisible = false;
    var rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(child: Card(
        margin: EdgeInsets.all(20.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: const InputDecoration(labelText: 'Username'),
                controller: usernameTextField,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                        icon: Icon(passwordFieldVisible ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).primaryColorDark),
                        onPressed: () => setState(() {
                            passwordFieldVisible = !passwordFieldVisible;
                        })
                    )
                ),
                controller: passwordTextField,
                obscureText: !passwordFieldVisible,
              ),
              const SizedBox(height: 20),
            CheckboxListTile(
                title: const Text("Remember me"),
                value: rememberMe,
                onChanged: (state) => {
                    setState(() { rememberMe = state ?? false; })
                }
            ),
                  ElevatedButton(
                    onPressed: () async {
                        final nav = Navigator.of(context);
                        final result = await Backend().loginAccount(ScaffoldMessenger.of(context), usernameTextField.text, passwordTextField.text, rememberMe);
                        if (result) nav.pop();
                    },
                    child: const Text('Login'),
                  ),
            ],
          ),
        ),
      ),
    ));
  }
}

class RegisterCard extends StatefulWidget {
    const RegisterCard({super.key});

    @override
    State<RegisterCard> createState() => _RegisterCardState();
}

class _RegisterCardState extends State<RegisterCard> {
    final usernameTextField = TextEditingController();
    final passwordTextField = TextEditingController();
    final repeatPasswordTextField = TextEditingController();
    bool passwordFieldVisible = false;
    bool repeatPasswordFieldVisible = false;
    var rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(child: Card(
        margin: EdgeInsets.all(20.0),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                decoration: const InputDecoration(labelText: 'Username'),
                controller: usernameTextField,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                    labelText: 'Password',
                    suffixIcon: IconButton(
                        icon: Icon(passwordFieldVisible ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).primaryColorDark),
                        onPressed: () => setState(() {
                            passwordFieldVisible = !passwordFieldVisible;
                        })
                    )
                ),
                controller: passwordTextField,
                obscureText: !passwordFieldVisible,
              ),
              const SizedBox(height: 10),
              TextField(
                decoration: InputDecoration(
                    labelText: 'Repeat password',
                    suffixIcon: IconButton(
                        icon: Icon(repeatPasswordFieldVisible ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).primaryColorDark),
                        onPressed: () => setState(() {
                            repeatPasswordFieldVisible = !repeatPasswordFieldVisible;
                        })
                    )
                ),
                controller: repeatPasswordTextField,
                obscureText: !repeatPasswordFieldVisible,
              ),
              const SizedBox(height: 20),
            CheckboxListTile(
                title: const Text("Remember me"),
                value: rememberMe,
                onChanged: (state) => {
                    setState(() {
                        rememberMe = state ?? false;
                    })
                }
            ),
                  ElevatedButton(
                    onPressed: () async {
                        if (passwordTextField.text != repeatPasswordTextField.text) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords don't match")));
                            return;
                        }
                        final nav = Navigator.of(context);
                        final result = await Backend().registerAccount(ScaffoldMessenger.of(context), usernameTextField.text, passwordTextField.text, rememberMe);
                        if (result) nav.pop();
                    },
                    child: const Text('Register'),
                  ),
            ],
          ),
        ),
      ),
    ));
  }
}
