@external
@view
def squareRoot(_value: uint256) -> uint256:
    x: decimal = convert(_value, decimal)
    return convert(sqrt(x), uint256)