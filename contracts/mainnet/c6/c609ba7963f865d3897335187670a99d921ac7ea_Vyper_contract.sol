@external
@view
def squareRoot(_value: uint256) -> uint256:
    x: decimal = convert(_value, decimal)
    return convert(sqrt(x), uint256)

@external
@view
def subNegativeInts(a: int256, b: int256) -> int256:
    return a - b

@external
@view
def subNegativeIntsAndMultiplyBy(a: int256, b: int256, mult: int256) -> int256:
    return mult*(a - b)