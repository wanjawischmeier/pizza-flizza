from functools import cmp_to_key
from heapq import nsmallest

def compare(a: int, b: int) -> bool:
    global comparisons
    comparisons += 1
    if a < b:
        return 1
    else:
        return -1

numbers = [8, 10, 12, 0, 2, 9, 11, 4, 5, 7, 3, 6, 13, 1]
cmp_key = cmp_to_key(compare)

comparisons = 0
result0 = sorted(numbers, key=cmp_key)
print(result0, comparisons)

comparisons = 0
result1 = nsmallest(5, numbers, cmp_key)
print(result1, comparisons)