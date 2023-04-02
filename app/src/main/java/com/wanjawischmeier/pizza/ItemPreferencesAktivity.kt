package com.wanjawischmeier.pizza

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.ImageView
import android.widget.ProgressBar
import android.widget.TextView
import android.widget.Toast
import androidx.appcompat.app.AppCompatActivity
import androidx.constraintlayout.widget.ConstraintLayout
import androidx.core.view.isVisible
import com.google.android.gms.tasks.Task
import com.google.firebase.auth.ktx.auth
import com.google.firebase.ktx.Firebase

class ItemPreferencesAktivity : AppCompatActivity() {
    private lateinit var progressBar: ProgressBar
    private lateinit var quizConstraint: ConstraintLayout
    private lateinit var layoutLeft: ConstraintLayout
    private lateinit var layoutRight: ConstraintLayout
    private lateinit var tourText: TextView
    private lateinit var itemNameLeft: TextView
    private lateinit var itemNameRight: TextView
    private lateinit var itemImageLeft: ImageView
    private lateinit var itemImageRight: ImageView
    private lateinit var itemSorter: ItemSorter<String>
    private lateinit var shop: Shop
    private var currentLeftId = ""
    private var currentRightId = ""
    private var sorted = mutableListOf<List<String>>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_item_preferences)
    }

    override fun onStart() {
        super.onStart()

        progressBar = findViewById(R.id.sorting_bar)
        progressBar.progress = 0

        tourText = findViewById(R.id.quiz_tour_text)

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

        val shopTask = Shop.getShop(SHOP_ID)
        quizConstraint = findViewById(R.id.quiz_constraint)

        tourText.text = getString(R.string.quiz_prompt_hearty)
        quizConstraint.setOnClickListener { startHeartyQuiz(shopTask) }
    }

    private fun startHeartyQuiz(shopTask: Task<Shop?>) {
        // clear onClick listener
        quizConstraint.setOnClickListener {  }

        tourText.animate()
            .alpha(0f)
            .duration = resources.getInteger(R.integer.animation_duration_card_out).toLong()

        layoutLeft.translationX = -layoutLeft.width.toFloat() * 2
        layoutRight.translationX = layoutRight.width.toFloat() * 2
        layoutLeft.isVisible = true
        layoutRight.isVisible = true

        shopTask.continueWith {
            shop = it.result ?: return@continueWith
            val heartyItems = Shop.getItemType(shop, Shop.Item.Type.HEARTY)

            itemSorter = ItemSorter(heartyItems.keys, 5, this::updateProgress) { sortedHearty, comparisonsHearty ->
                sorted.add(sortedHearty)

                var pckd = "Hearty selection:\n"

                for ((i, itemId) in sortedHearty.withIndex()) {
                    pckd += "${i + 1}. ${heartyItems[itemId]?.name}\n"
                }

                pckd += "$comparisonsHearty comparisons"
                Log.d("COMPARISONS", pckd)

                layoutLeft.clearAnimation()
                layoutLeft.animate()
                    .translationX(-layoutLeft.width.toFloat() * 2)
                    .duration = resources.getInteger(R.integer.animation_duration_card_out).toLong()
                layoutRight.clearAnimation()
                layoutRight.animate()
                    .translationX(layoutRight.width.toFloat() * 2)
                    .duration = resources.getInteger(R.integer.animation_duration_card_out).toLong()

                progressBar.setProgress(0, true)

                tourText.text = getString(R.string.quiz_prompt_sweet)
                tourText.animate()
                    .alpha(1f)
                    .duration = resources.getInteger(R.integer.animation_duration_card_out).toLong()

                quizConstraint.setOnClickListener(this::startSweetsQuiz)
            }

            showNextComparison()
        }
    }

    private fun startSweetsQuiz(view: View) {
        quizConstraint.setOnClickListener {  }

        tourText.animate()
            .alpha(0f)
            .duration = resources.getInteger(R.integer.animation_duration_card_out).toLong()

        val sweetItems = Shop.getItemType(shop, Shop.Item.Type.SWEET)
        itemSorter = ItemSorter(sweetItems.keys, 5, this::updateProgress) { sortedSweet, comparisonsSweet ->
            sorted.add(sortedSweet)

            var pckd = "Sweets selection:\n"

            for ((i, itemId) in sortedSweet.withIndex()) {
                pckd += "${i + 1}. ${sweetItems[itemId]?.name}\n"
            }

            pckd += "$comparisonsSweet comparisons"
            Log.d("COMPARISONS", pckd)

            User.setPriorities(GROUP_ID, Firebase.auth.currentUser?.uid ?: return@ItemSorter, sorted).continueWith {
                val intent = Intent(this, MainActivity::class.java)
                finish()
                startActivity(intent)
            }
        }

        showNextComparison()
    }

    private fun updateProgress(progress: Int) {
        progressBar.setProgress(progress, true)
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
        val translation = layout.width * selected.toFloat() * 2
        val duration = resources.getInteger(R.integer.animation_duration_card_out).toLong()

        layout.setOnClickListener {  }
        layout.clearAnimation()
        layout.animate()
            .translationX(translation)
            .setDuration(duration)
            .withEndAction {
                nameView.text = name
                imageView.setImageResource(
                    if (resourceId == 0) {
                        R.drawable.baeckerkroenung
                    } else {
                        resourceId
                    }
                )

                layout.animate().translationX(0f)
                    .withEndAction {
                        layout.setOnClickListener {
                            itemSorter.setComparisonResult(selected == -1)
                            showNextComparison()
                        }
                    }
            }
    }
}