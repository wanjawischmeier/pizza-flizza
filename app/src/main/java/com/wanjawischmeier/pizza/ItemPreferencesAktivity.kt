package com.wanjawischmeier.pizza

import android.annotation.SuppressLint
import android.os.Bundle
import android.util.Log
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase

class ItemPreferencesAktivity : AppCompatActivity() {
    private lateinit var pregressBar: ProgressBar
    private lateinit var layoutLeft: ConstraintLayout
    private lateinit var layoutRight: ConstraintLayout
    private lateinit var itemNameLeft: TextView
    private lateinit var itemNameRight: TextView
    private lateinit var itemImageLeft: ImageView
    private lateinit var itemImageRight: ImageView
    private lateinit var itemSorter: ItemSorter<String>
    private lateinit var shop: Shop
    private var currentLeftId = ""
    private var currentRightId = ""

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_item_preferences)
    }

    override fun onStart() {
        super.onStart()

        pregressBar = findViewById(R.id.sorting_bar)

        layoutLeft = findViewById(R.id.layout_left)
        layoutRight = findViewById(R.id.layout_right)

        itemNameLeft = findViewById(R.id.item_name_left)
        itemNameRight = findViewById(R.id.item_name_right)

        itemImageLeft = findViewById(R.id.item_image_left)
        itemImageRight = findViewById(R.id.item_image_right)

        layoutLeft.setOnClickListener {
            itemSorter.setComparisonResult(true)
            showNextComparison()
        }

        layoutRight.setOnClickListener {
            itemSorter.setComparisonResult(false)
            showNextComparison()
        }

        Shop.getShop(SHOP_ID).continueWith {
            shop = it.result ?: return@continueWith
            val items = Shop.getItemType(shop, Shop.Item.Type.HEARTY)

            itemSorter = ItemSorter(items.keys, 5, this::updateProgress) { sorted, comparisons ->
                Toast.makeText(this, sorted.toString(), Toast.LENGTH_SHORT).show()

                var pckd = "\n"

                for ((i, itemId) in sorted.withIndex()) {
                    pckd += "[$i]: ${items[itemId]?.name}\n"
                }

                pckd += "$comparisons comparisons"
                Log.d("COMPARISONS", pckd)

                User.setPriorities(GROUP_ID, Firebase.auth.currentUser?.uid ?: return@ItemSorter, sorted)
            }

            showNextComparison()
        }
    }

    private fun updateProgress(progress: Int) {
        pregressBar.progress = progress
    }

    @SuppressLint("DiscouragedApi")
    private fun showNextComparison() {
        val (leftId, rightId) = itemSorter.getNextComparison()

        if (leftId != currentLeftId) {
            val imageIdLeft = resources.getIdentifier(leftId, "drawable", packageName)

            animateSlide(
                layoutLeft, -1,
                itemNameLeft, shop.items[leftId]?.name ?: return,
                itemImageLeft, imageIdLeft
            )
            currentLeftId = leftId
        }

        if (rightId != currentRightId) {
            val imageIdRight = resources.getIdentifier(rightId, "drawable", packageName)

            animateSlide(
                layoutRight, 1,
                itemNameRight, shop.items[rightId]?.name ?: return,
                itemImageRight, imageIdRight
            )
            currentRightId = rightId
        }
    }

    private fun animateSlide(layout: ConstraintLayout, selected: Int, nameView: TextView, name: String, imageView: ImageView, resourceId: Int) {
        val translation = layout.width * selected.toFloat()
        val duration = resources.getInteger(R.integer.animation_duration_card_out).toLong()

        layout.animate()
            .translationX(translation)
            .setDuration(duration)
            .withEndAction {
                layout.animate().translationX(0f)

                nameView.text = name
                imageView.setImageResource(
                    if (resourceId == 0) {
                        R.drawable.baeckerkroenung
                    } else {
                        resourceId
                    }
                )
            }
    }
}