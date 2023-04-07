package com.wanjawischmeier.pizza

import android.content.DialogInterface
import android.content.Intent
import android.os.Bundle
import android.view.MenuItem
import android.view.View
import android.widget.TextView
import androidx.appcompat.app.AlertDialog
import androidx.appcompat.app.AppCompatActivity
import androidx.fragment.app.FragmentContainerView
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout
import com.google.android.gms.tasks.Task
import com.google.android.material.bottomnavigation.BottomNavigationView
import com.google.firebase.auth.FirebaseUser
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase
import com.wanjawischmeier.pizza.Database.VersionHintType


class MainActivity : AppCompatActivity() {
    private lateinit var orderFragment: OrderFragment
    private lateinit var shopFragment: ShopFragment
    private lateinit var transactionFragment: TransactionFragment
    private lateinit var profileFragment: ProfileFragment
    private lateinit var previousFragment: CallableFragment
    private lateinit var currentFragment: CallableFragment
    private lateinit var bottomNavigationView: BottomNavigationView
    private lateinit var navigationHost: FragmentContainerView
    private lateinit var navigationHeader: TextView

    lateinit var shop: Shop
    lateinit var users: Users
    lateinit var swipeRefreshLayout: SwipeRefreshLayout
    lateinit var scrollContainer: View
    lateinit var user: FirebaseUser
    var userId = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        checkUser()

        setContentView(R.layout.activity_main)
        CallableFragment.topBubble = findViewById(R.id.top_bubble_constraint)
        CallableFragment.bottomLayout = findViewById(R.id.bottom_layout)
        swipeRefreshLayout = findViewById(R.id.swipe_refresh_layout)
        swipeRefreshLayout.setOnRefreshListener(this::refreshView)
        swipeRefreshLayout.setOnChildScrollUpCallback { _, _ ->
            scrollContainer.canScrollVertically(-1)
        }

        // Preferences screen bridge
        CallableFragment.topBubble.setOnClickListener {
            val intent = Intent(this, PreferenceQuizAktivity::class.java)
            startActivity(intent)
        }

        navigationHost = findViewById(R.id.nav_host_fragment)
        navigationHeader = findViewById(R.id.header)

        // check for relevant version hints
        Database.getVersionHint(BuildConfig.VERSION_CODE) { hint ->
            if (hint == null) return@getVersionHint startActivity()
            var type = VersionHintType.values()[hint.type]
            val dialog = AlertDialog.Builder(this, R.style.AlertStyle).create()

            val message = when (type) {
                VersionHintType.DEPRICATED -> {
                    type = VersionHintType.WARNING
                    getString(R.string.hint_obsolete)
                }
                VersionHintType.DISABLED -> {
                    type = VersionHintType.ERROR
                    getString(R.string.hint_disabled)
                }
                else -> {
                    hint.message
                }
            }

            dialog.setMessage(message)

            val title = when (type) {
                VersionHintType.INFO -> {
                    dialog.setButton(AlertDialog.BUTTON_POSITIVE, "Continue") { _: DialogInterface, _: Int -> startActivity() }
                    dialog.setOnDismissListener { startActivity() }
                    R.string.hint_title_info
                }
                VersionHintType.WARNING -> {
                    dialog.setButton(AlertDialog.BUTTON_POSITIVE, "Continue") { _: DialogInterface, _: Int -> startActivity() }
                    dialog.setButton(AlertDialog.BUTTON_NEGATIVE, "Exit") { _: DialogInterface, _: Int -> finishAffinity() }
                    dialog.setOnDismissListener { startActivity() }
                    R.string.hint_title_warning
                }
                // error
                else -> {
                    dialog.setButton(AlertDialog.BUTTON_NEGATIVE, "Exit") { _: DialogInterface, _: Int -> finishAffinity() }
                    dialog.setOnDismissListener { finishAffinity() }
                    R.string.hint_title_error
                }
            }

            dialog.setTitle(title)
            dialog.show()

            val white = getColor(R.color.white)
            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setTextColor(white)
            dialog.getButton(AlertDialog.BUTTON_NEGATIVE).setTextColor(white)
        }
    }

    private fun startActivity() {
        swipeRefreshLayout.isRefreshing = true

        Shop.getShop(SHOP_ID).continueWith getShop@ { shopTask ->
            shop = shopTask.result ?: return@getShop

            User.getUsers(GROUP_ID).continueWith getUsers@ { usersTask ->
                users = usersTask.result ?: return@getUsers
                swipeRefreshLayout.isRefreshing = false

                runOnUiThread(this::initializeFragments)
            }
        }
    }

    private fun initializeFragments() {
        swipeRefreshLayout.isRefreshing = true

        orderFragment = OrderFragment()
        shopFragment = ShopFragment()
        transactionFragment = TransactionFragment()
        // profileFragment = ProfileFragment()

        currentFragment = orderFragment
        previousFragment = currentFragment

        supportFragmentManager.beginTransaction().apply {
            remove(supportFragmentManager.fragments[0])
            add(R.id.nav_host_fragment, orderFragment)
            add(R.id.nav_host_fragment, shopFragment)
            add(R.id.nav_host_fragment, transactionFragment)
            // add(R.id.nav_host_fragment, profileFragment)
            hide(shopFragment)
            hide(transactionFragment)
            // hide(orderFragment)

            runOnCommit {
                val after = { swipeRefreshLayout.isRefreshing = false }
                currentFragment.onShow()?.continueWith { after.invoke() } ?: after.invoke()
            }
        }.commit()

        bottomNavigationView = findViewById(R.id.bottomNavigationView)
        bottomNavigationView.setOnItemSelectedListener(this::onMenuItemSelected)
    }

    private fun checkUser() {
        val currentUser = Firebase.auth.currentUser
        if (currentUser == null) {
            val intent = Intent(this, LoginActivity::class.java)
            startActivity(intent)
            finish()
        } else {
            user = currentUser
            userId = user.uid
        }
    }

    private fun onMenuItemSelected(menuItem: MenuItem): Boolean {
        val menuItemId = menuItem.itemId
        if (menuItemId == bottomNavigationView.selectedItemId) {
            return false
        }

        swipeRefreshLayout.isRefreshing = true
        previousFragment = currentFragment

        when (menuItemId) {
            R.id.navigation_order -> currentFragment = orderFragment
            R.id.navigation_shop -> currentFragment = shopFragment
            R.id.navigation_transaction -> currentFragment = transactionFragment
        }

        /*
        // Login screen bridge
        if (currentFragment == transactionFragment) {
            val intent = Intent(this, LoginActivity::class.java)
            finish()
            startActivity(intent)
        }
         */

        navigationHeader.text = menuItem.title
        navigationHost.animate()
            .alpha(0f)
            .withEndAction {
                supportFragmentManager.beginTransaction().apply {
                    hide(previousFragment)
                    show(currentFragment)

                    runOnCommit {
                        User.getUsers(GROUP_ID).continueWith continueUsers@ { usersTask ->
                            users = usersTask.result ?: return@continueUsers

                            val after = {
                                swipeRefreshLayout.isRefreshing = false

                                navigationHost.animate()
                                    .alpha(1f)
                                    .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()
                            }

                            swipeRefreshLayout.isEnabled = true
                            currentFragment.onShow()?.continueWith { after.invoke() } ?: after.invoke()
                        }
                    }.commit()
                }
            }
            .duration = resources.getInteger(R.integer.animation_duration_fragment).toLong()

        return true
    }

    private fun refreshView(): Task<Unit> {
        checkUser()

        return User.getUsers(GROUP_ID).continueWith continueUsers@ { usersTask ->
            users = usersTask.result ?: return@continueUsers

            val after = { swipeRefreshLayout.isRefreshing = false }
            currentFragment.onShow(true)?.continueWith { after.invoke() } ?: after.invoke()
        }
    }

    fun onOrderSub(view: View) {
        orderFragment.modifyCount(view, -1)
    }

    fun onOrderAdd(view: View) {
        orderFragment.modifyCount(view, 1)
    }

    fun onTransactionAccept(view: View) {
        transactionFragment.accept(view)
    }

    fun onOrder(@Suppress("UNUSED_PARAMETER") view: View) {
        orderFragment.placeOrder()
    }

    fun onResetEmail(view: View) {
        profileFragment.resetEmail(view)
    }

    fun onResetPassword(view: View) {
        profileFragment.resetPassword(view)
    }
}