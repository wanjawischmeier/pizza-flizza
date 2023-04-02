package com.wanjawischmeier.pizza

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.google.android.gms.tasks.Task
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase
import uk.co.deanwild.materialshowcaseview.MaterialShowcaseView

class ProfileFragment : CallableFragment() {
    private lateinit var main: MainActivity

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View? {
        main = activity as MainActivity
        return inflater.inflate(R.layout.fragment_profile, container, false)
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {

    }

    override fun onShow(refresh: Boolean): Task<Unit>? {
        TODO("Not yet implemented")
    }

    fun resetEmail(view: View) {
        main.user.verifyBeforeUpdateEmail("szb02810@zslsz.com")
    }

    fun resetPassword(view: View) {
        Firebase.auth.sendPasswordResetEmail(main.user.email ?: return)
    }
}