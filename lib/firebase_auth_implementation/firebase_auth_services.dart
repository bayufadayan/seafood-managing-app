import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:prak_mobpro/component/toast.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Future<User?> signUpWithEmailAndPassword(String email, password) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (credential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.email)
            .set({
          'email': email,
          'fullname': email.split('@')[0].toUpperCase(),
          'address': "Empty Field",
          'image': "No Image",
        });
      }
      return credential.user;

    } catch (e) {
      String errorMessage = 'An error occurred, please try again';
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'invalid-email':
            errorMessage = "Invalid email format";
            break;
          case 'weak-password':
            errorMessage = "Password is too weak";
            break;
          case 'email-already-in-use':
            errorMessage = "Email is already in use";
            break;
          default:
            errorMessage = e.message ?? 'An error occurred, please try again';
        }
      }
      showToast(errorMessage);
      return null;
    }
  }

  Future<User?> signInWithEmailAndPassword(String email, password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return credential.user;
    } catch (e) {
      if (e is FirebaseAuthException) {
        showToast(e.code);
      }
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
