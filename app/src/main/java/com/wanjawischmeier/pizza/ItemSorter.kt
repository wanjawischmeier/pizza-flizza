package com.wanjawischmeier.pizza

import kotlin.math.floor
import kotlin.math.min

class ItemSorter(
    list: Iterable<String>,
    private val limit: Int,
    private val callback: (List<String>, Int) -> Unit
) {
    private var minimum = 0
    private var maximum = 0
    private var pointer = 0
    private var listPointer = 1
    private var comparisons = 0
    private var value = ""
    private var sorted: MutableList<String>
    private var cache = mutableMapOf<Pair<String, String>, Boolean>()
    private var input: List<String> = list.toList()
    private var key: Pair<String, String>

    init {
        sorted = mutableListOf(input[0])
        value = input[listPointer]
        maximum = min(sorted.size, limit)
        pointer = maximum - 1 // floor(maximum / 2f).toInt()
        key = value to sorted[pointer]
    }

    private fun loadNextKey(sortedKey: Int) {
        sorted.add(min(sorted.size, sortedKey), value)

        listPointer++

        if (listPointer >= input.size) {
            pointer = -1
            callback(sorted, comparisons)
            return
        }

        value = input[listPointer]
        minimum = 0
        maximum = min(sorted.size, limit)
        pointer = maximum - 1 // floor(maximum / 2f).toInt()

        key = value to sorted[pointer]
        setComparisonResult(cache[key] ?: return)
    }

    fun getNextComparison(): Pair<String, String> {
        return key
    }

    fun setComparisonResult(result: Boolean) {
        if (pointer == -1) {
            return
        } else {
            comparisons++
        }

        cache[key] = result

        if (result) {
            maximum = pointer
        } else {
            minimum = if (minimum == pointer) {
                maximum
            } else {
                pointer
            }

            if (minimum > limit) {
                loadNextKey(pointer)
                return
            }
        }

        if (minimum == maximum) {
            loadNextKey(minimum)
            return
        }

        pointer = minimum + floor((maximum - minimum) / 2f).toInt()
        key = value to sorted[pointer]
        val cached = cache[key]
        if (cached != null) {
            comparisons--
            setComparisonResult(cached)
        }
    }
}