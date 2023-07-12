# @version 0.3.7
"""
@title am3crv LP Burner
@notice LP tokens
"""


interface ERC20:
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def balanceOf(_owner: address) -> uint256: view
    def decimals() -> uint256: view

interface StableSwap:
    def remove_liquidity_one_coin(
        _token_amount: uint256,
        i: int128,
        _min_amount: uint256,
        _use_underlying: bool
    ) -> uint256: nonpayable
    def get_virtual_price() -> uint256: view


BPS: constant(uint256) = 10000

SWAP: immutable(StableSwap)
PROXY: constant(address) = 0x774D1Dba98cfBD1F2Bc3A1F59c494125e07C48F9
USDC: immutable(ERC20)
slippage: public(uint256)

owner: public(address)


@external
def __init__():
    """
    @notice Contract constructor
    """
    SWAP = StableSwap(0x445FE580eF8d70FF569aB36e80c647af338db351)
    USDC = ERC20(0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174)
    self.owner = msg.sender

    self.slippage = 50  # .5%, 0.995


@internal
def _burn(_coin: address, _amount: uint256):
    min_amount: uint256 = _amount * SWAP.get_virtual_price() / 10 ** 18
    min_amount /= 10 ** 12  # 18 - 6, usdc decimals

    min_amount -= min_amount * self.slippage / BPS

    SWAP.remove_liquidity_one_coin(_amount, 1, 0, True)
    amount: uint256 = USDC.balanceOf(self)
    USDC.transfer(PROXY, amount)


@external
def burn(_coin: address) -> bool:
    """
    @notice Convert `_coin` by removing liquidity and transfer to another burner
    @param _coin Address of the coin being converted
    @return bool success
    """
    # transfer coins from caller
    amount: uint256 = ERC20(_coin).balanceOf(msg.sender)
    if amount != 0:
        ERC20(_coin).transferFrom(msg.sender, self, amount)

    # get actual balance in case of pre-existing balance
    amount = ERC20(_coin).balanceOf(self)

    if amount != 0:
        self._burn(_coin, amount)

    return True


@external
def burn_amount(_coin: address, _amount_to_burn: uint256):
    """
    @notice Burn a specific quantity of `_coin`
    @dev Useful when the total amount to burn is so large that it fails from slippage
    @param _coin Address of the coin being converted
    @param _amount_to_burn Amount of the coin to burn
    """
    amount: uint256 = ERC20(_coin).balanceOf(PROXY)
    if amount != 0:
        ERC20(_coin).transferFrom(PROXY, self, amount)

    amount = ERC20(_coin).balanceOf(self)
    assert amount >= _amount_to_burn, "Insufficient balance"

    self._burn(_coin, _amount_to_burn)


@external
def recover_balance(_coin: address) -> bool:
    """
    @notice Recover ERC20 tokens from this contract
    @dev Tokens are sent to the recovery address
    @param _coin Token address
    @return bool success
    """
    assert msg.sender == self.owner  # dev: only owner

    amount: uint256 = ERC20(_coin).balanceOf(self)
    response: Bytes[32] = raw_call(
        _coin,
        _abi_encode(PROXY, amount, method_id=method_id("transfer(address,uint256)")),
        max_outsize=32,
    )
    if len(response) != 0:
        assert convert(response, bool)

    return True


@external
def set_slippage(_slippage: uint256):
    """
    @notice Set default slippage parameter
    @param _slippage Slippage value in bps
    """
    assert msg.sender == self.owner  # dev: only owner
    assert _slippage <= BPS  # dev: slippage too high
    self.slippage = _slippage


@external
def set_owner(_owner: address):
    """
    @notice Set owner
    @param _owner New owner address
    """
    assert msg.sender == self.owner  # dev: only owner
    self.owner = _owner