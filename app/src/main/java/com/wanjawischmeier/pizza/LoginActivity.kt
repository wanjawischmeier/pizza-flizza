package com.wanjawischmeier.pizza

import android.content.Intent
import android.os.Bundle
import android.util.Patterns
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.widget.addTextChangedListener
import com.google.firebase.auth.FirebaseAuth
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.ktx.auth
import com.google.firebase.database.FirebaseDatabase
import com.google.firebase.database.ktx.database
import com.google.firebase.ktx.Firebase
import java.text.SimpleDateFormat
import java.util.*

class LoginActivity : AppCompatActivity() {
    private lateinit var auth: FirebaseAuth
    private lateinit var user: FirebaseUser
    private lateinit var database: FirebaseDatabase
    private lateinit var emailField: EditText
    private lateinit var passwordField: EditText


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)

        // Initialize Firebase Auth
        try {
            Firebase.database.setPersistenceEnabled(true)
        }
        catch (_: Exception) { }

        auth = Firebase.auth
        if (auth.currentUser != null) {
            Toast.makeText(applicationContext, "Already signed in", Toast.LENGTH_SHORT).show()
            user = auth.currentUser!!
            checkUser()
        }

        emailField = findViewById(R.id.email_field)
        passwordField = findViewById(R.id.password_field)
        val loginButton = findViewById<Button>(R.id.button_login)
        val createButton = findViewById<Button>(R.id.button_create)

        emailField.addTextChangedListener { text ->
            if (text.toString() != "" && Patterns.EMAIL_ADDRESS.matcher(text.toString()).matches()) {
                auth.fetchSignInMethodsForEmail(text.toString())
                    .addOnCompleteListener { task ->
                        val methods = task.result.signInMethods

                        if (methods == null || methods.size == 0) {
                            // no account found
                            loginButton.isEnabled = false
                            createButton.isEnabled = true
                        } else {
                            // account exists
                            loginButton.isEnabled = true
                            createButton.isEnabled = false
                        }
                    }
            }
        }
    }

    fun onCreateAccount(@Suppress("UNUSED_PARAMETER") view: View) {
        val email = emailField.text.toString()
        val password = passwordField.text.toString()

        if (email == "" || password == "") return

        auth.createUserWithEmailAndPassword(email, password)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    signIn(email, password)
                } else {
                    Toast.makeText(applicationContext, "Creation Failed", Toast.LENGTH_SHORT).show()
                }
            }
    }

    fun onSignIn(@Suppress("UNUSED_PARAMETER") view: View) {
        val email = findViewById<EditText>(R.id.email_field).text.toString()
        val password = findViewById<EditText>(R.id.password_field).text.toString()

        if (email == "" || password == "") return

        signIn(email, password)
    }

    fun onToggleCheck(@Suppress("UNUSED_PARAMETER") view: View) {
        val button = findViewById<Button>(R.id.continue_disclaimer)
        button.isEnabled = !button.isEnabled
    }

    fun onContinueDisclaimer(@Suppress("UNUSED_PARAMETER") view: View) {
        val dateFormat = SimpleDateFormat.getDateTimeInstance()
        val calendar = Calendar.getInstance()
        val date = dateFormat.format(calendar.time)
        val userStruct = User()
        userStruct.creationDate = date

        database.getReference("users/${user.uid}").setValue(userStruct).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                onSignedIn()
            } else {
                Toast.makeText(applicationContext, "Failed to create user entry", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun signIn(email: String, password: String) {
        auth.signInWithEmailAndPassword(email, password)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    user = auth.currentUser!!
                    if (user.isEmailVerified) {
                        Toast.makeText(applicationContext, "Success", Toast.LENGTH_SHORT).show()
                        checkUser()
                    } else {
                        Toast.makeText(applicationContext, "Please verify your email", Toast.LENGTH_SHORT).show()
                        user.sendEmailVerification()
                    }
                } else {
                    Toast.makeText(applicationContext, "Failed", Toast.LENGTH_SHORT).show()
                }
            }
    }

    private fun checkUser() {
        database = FirebaseDatabase.getInstance()
        database.getReference("users/${user.uid}").get().addOnCompleteListener { task ->
            if (task.result.value == null) {
                setContentView(R.layout.create_disclaimer)
            } else {
                Shop.loadAll(database).addOnCompleteListener { task ->
                    task.result["yo"]?.items?.get("lye_rod")?.name
                }
                onSignedIn()
            }
        }
    }

    private fun onSignedIn() {
        val intent = Intent(this, OrderActivity::class.java)
        finish()
        startActivity(intent)
    }
}