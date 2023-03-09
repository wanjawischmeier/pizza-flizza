package com.wanjawischmeier.pizza

import android.content.Intent
import android.os.Bundle
import android.util.Patterns
import android.view.View
import android.view.inputmethod.EditorInfo
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.TextView.OnEditorActionListener
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.core.view.isInvisible
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
    private lateinit var infoField: TextView
    private lateinit var loginButton: Button


    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_login)

        // Initialize Firebase Auth
        try {
            Firebase.database.setPersistenceEnabled(true)
        }
        catch (_: Exception) { }

        auth = Firebase.auth

        emailField = findViewById(R.id.email_field)
        passwordField = findViewById(R.id.password_field)
        infoField = findViewById(R.id.info_text_login)
        loginButton = findViewById(R.id.button_login)

        infoField.isInvisible = true
        emailField.requestFocus()

        val checkEmailFromListener: (text: CharSequence?, Int, Int, Int) -> Unit =
            { _: CharSequence?, _: Int, _: Int, _: Int ->
                checkEmail()
            }

        emailField.addTextChangedListener(onTextChanged = checkEmailFromListener)
        passwordField.addTextChangedListener(onTextChanged = checkEmailFromListener)

        passwordField.setOnEditorActionListener(OnEditorActionListener { view, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                onSignIn(view)
                return@OnEditorActionListener true
            }

            return@OnEditorActionListener false
        })
    }

    override fun onResume() {
        super.onResume()
        checkEmail()
    }

    private fun checkEmail() {
        infoField.isInvisible = true
        val email = emailField.text.toString()
        val password = passwordField.text.toString()

        if (email != "" && password != "" && Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            loginButton.isEnabled = true

            auth.fetchSignInMethodsForEmail(email)
                .addOnCompleteListener { task ->
                    val methods = task.result.signInMethods

                    if (methods == null || methods.size == 0) {
                        // no account found
                        loginButton.text = getString(R.string.create_account)
                    } else {
                        // account exists
                        loginButton.text = getString(R.string.login_button)
                    }
                }
        } else {
            loginButton.text = getString(R.string.login_button)
            loginButton.isEnabled = false
        }
    }

    fun onSignIn(@Suppress("UNUSED_PARAMETER") view: View) {
        val email = findViewById<EditText>(R.id.email_field).text.toString()
        val password = findViewById<EditText>(R.id.password_field).text.toString()
        val loginButton = findViewById<Button>(R.id.button_login)

        if (email == "" || password == "") return
        if (password.length < 6) {
            infoField.text = getString(R.string.info_invalid_password)
            infoField.isInvisible = false
            return
        }

        if (loginButton.text == getString(R.string.login_button)) {
            signIn(email, password)
        } else {
            createAccount(email, password)
        }
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
        userStruct.name = "FalkonxX"

        database.getReference("users/$GROUP_ID/${user.uid}").setValue(userStruct).addOnCompleteListener { task ->
            if (task.isSuccessful) {
                onSignedIn()
            } else {
                Toast.makeText(applicationContext, "Failed to create user entry", Toast.LENGTH_LONG).show()
            }
        }
    }

    private fun signIn(email: String, password: String) {
        auth.signInWithEmailAndPassword(email, password)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    user = auth.currentUser!!
                    if (user.isEmailVerified) {
                        checkUser()
                    } else {
                        infoField.text = getString(R.string.info_verify_email)
                        infoField.isInvisible = false
                        user.sendEmailVerification()
                        Firebase.auth.signOut()
                    }
                } else {
                    infoField.text = getString(R.string.info_wrong_password)
                    infoField.isInvisible = false
                }
            }
    }

    private fun createAccount(email: String, password: String) {
        auth.createUserWithEmailAndPassword(email, password)
            .addOnCompleteListener(this) { task ->
                if (task.isSuccessful) {
                    signIn(email, password)
                } else {
                    Toast.makeText(applicationContext, "Creation Failed", Toast.LENGTH_SHORT).show()
                }
            }
    }

    private fun checkUser() {
        database = FirebaseDatabase.getInstance()
        database.getReference("users/$GROUP_ID/${user.uid}").get().addOnCompleteListener { task ->
            if (task.result.value == null) {
                setContentView(R.layout.create_disclaimer)
            } else {
                onSignedIn()
            }
        }
    }

    private fun onSignedIn() {
        val intent = Intent(this, MainActivity::class.java)
        finish()
        startActivity(intent)
    }
}