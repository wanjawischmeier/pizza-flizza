// Function to delete account data asynchronously
async function deleteAccountData(user) {
    try {
        // Get the currently signed-in user
        var user = firebase.auth().currentUser;

        // Get a reference to the groups node in Firebase Realtime Database
        var groupsRef = firebase.database().ref('groups');

        // Fetch the snapshot of all groups
        var groupsSnapshot = await groupsRef.once('value');
        var userGroupId = null;

        // Iterate over each group and remove the user's UID from the users field
        groupsSnapshot.forEach(function (groupSnapshot) {
            var groupId = groupSnapshot.key;
            var groupData = groupSnapshot.val();

            // Check if the group has a users field
            if (groupData.users && groupData.users[user.uid]) {
                userGroupId = groupId;

                // Remove the user's UID from the users field
                delete groupData.users[user.uid];

                // Update the group data in Firebase Realtime Database
                groupsRef.child(groupId).update(groupData);
            }
        });

        if (userGroupId) {
            // Get a reference to the user node in Firebase Realtime Database
            var userRef = firebase.database().ref(`users/${userGroupId}/${user.uid}`);

            // Fetch the snapshot of all groups
            var userSnapshot = await groupsRef.once('value');

            if (userSnapshot) {
                await userRef.remove();
            }
        }

        // Delete user account from Firebase Authentication
        await user.delete();

        // Account data deletion successful
        return { success: true, errorMessage: '' };
    } catch (error) {
        console.error('Account data deletion error:', error);

        // Account data deletion failed
        return { success: false, errorMessage: error.message };
    }
}

async function confirmDelete(user) {
    var confirmDelete = confirm('Are you sure you want to delete your account? This action cannot be undone.');

    if (confirmDelete) {
        var deletionResult = await deleteAccountData(user);

        if (deletionResult.success) {
            infoMessageDiv.textContent = 'Account data deletion successful';

            // Reset the form fields
            loginForm.reset();
        } else {
            infoMessageDiv.textContent = deletionResult.errorMessage;
        }
    }
}


// Get a reference to the login form
var loginForm = document.getElementById('login-form');
var infoMessageDiv = document.getElementById('info-message');

// Add a submit event listener to the login form
loginForm.addEventListener('submit', function (event) {
    event.preventDefault(); // Prevent form submission

    // Get user input values
    var email = document.getElementById('email').value;
    var password = document.getElementById('password').value;

    // Sign in the user with email and password
    firebase.auth().signInWithEmailAndPassword(email, password)
        .then(async function (userCredential) {
            // User successfully logged in
            var user = userCredential.user;
            console.log('User logged in:', user.uid);

            confirmDelete(user);
        })
        .catch(function (error) {
            // Handle login error
            var errorCode = error.code;
            var errorMessage = error.message;
            console.error('Login error:', errorCode, errorMessage);

            // Format and display the error message for Firebase errors only
            if (errorCode.startsWith('auth/')) {
                var formattedErrorMessage = errorMessage.startsWith('Firebase: ')
                    ? errorMessage.substr('Firebase: '.length)
                    : errorMessage;

                infoMessageDiv.textContent = formattedErrorMessage;
            } else {
                infoMessageDiv.textContent = 'Unknown Error when signing in user';
            }
        });
});

// Sign in with Google function
function signInWithGoogle() {
    var provider = new firebase.auth.GoogleAuthProvider();
    firebase.auth().signInWithPopup(provider)
      .then(function(userCredential) {
        // Logged in successfully with Google
        var user = userCredential.user;
        console.log('User logged in with Google:', user);
        
        confirmDelete(user);
      })
      .catch(function(error) {
        // Handle login errors
        console.error('Google login error:', error.message);
        infoMessageDiv.textContent = error.message;
      });
  }