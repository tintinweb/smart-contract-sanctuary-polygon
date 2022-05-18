# @version ^0.3.3
"""
@title weDAO Token
@license GNU AGPLv3
@author msugarm
@notice
    This is an initializable ERC20 contract.
    At the intialize moment can set if token can be mintable.
    If token is enable to be mintable, later mintable function can be disable forever.
@dev DAO Version: 3.0
"""

governance: public(address)
mintable: public(bool)
activation: public(uint256)

name: public(String[64])
symbol: public(String[12])
decimals: public(uint256)

balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)

# events

# @notice Emitted when an Transfer is executed
# @param sender address that sent the tokens
# @param receiver address that received the tokens
# @param amount the quantity of tokens that has been transfered
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256
# @notice Emitted when an Approval is executed
# @param owner address that allowed to spender to spend their tokens
# @param spender address that is allowed to spend tokenbs
# @param value the quantity of token that spender is allowed to spend
event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256
# @notice Emitted when a Sweep is executed
# @param token Address of token that has been sweep, if is ZERO_ADDRESS means Native coin
# @param amount The quantity of token/native that has been transfer
event Sweep:
    token: indexed(address) 
    amount: uint256

# interfaces

from vyper.interfaces import ERC20

# internals

## erc20 safe
@internal
def _erc20_safe_transfer(token: address, receiver: address, amount: uint256):
    # Used only to send tokens that are not the type managed by this Vault.
    # HACK: Used to handle non-compliant tokens like USDT
    response: Bytes[32] = raw_call(
        token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(receiver, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) > 0:
        assert convert(response, bool), "Transfer failed!"

## mint
@internal
def _mint(_to: address, _amount: uint256):
    assert _to != ZERO_ADDRESS , "ERC20: mint to the zero address"
    self.totalSupply += _amount
    self.balanceOf[_to] += _amount
    log Transfer(ZERO_ADDRESS, _to, _amount)

#externals

## erc20
@external
def transfer(_to: address, _value: uint256) -> bool:
    """
    @dev Transfer token for a specified address
    @param _to The address to transfer to.
    @param _value The amount to be transferred.
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True

@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    """
    @dev Transfer tokens from one address to another.
    @param _from address The address which you want to send tokens from
    @param _to address The address which you want to transfer to
    @param _value uint256 the amount of tokens to be transferred
    """
    # NOTE: vyper does not allow underflows
    #       so the following subtraction would revert on insufficient balance
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    # NOTE: vyper does not allow underflows
    #      so the following subtraction would revert on insufficient allowance
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True

@external
def approve(_spender: address, _value: uint256) -> bool:
    """
    @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
         Beware that changing an allowance with this method brings the risk that someone may use both the old
         and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
         race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
         https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param _spender The address which will spend the funds.
    @param _value The amount of tokens to be spent.
    """
    assert _spender != ZERO_ADDRESS , "spender cannot be the zero address"
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

## mint
@external
def mint(_to: address, _amount: uint256):
    """
    @notice
        Mint tokens
        This function will add more token to totalSupply and increase balance of `to`.
        This may only be called if `mintable` variable is `True`.
        This may only be called by the current governance owner address.
    @param _to address The address that will receive new tokens
    @param _amount uint256 The quantity of token to add on supply
    """
    assert self.mintable == True , "!mintable"
    assert msg.sender == self.governance , "!governance"
    self._mint(_to, _amount)

@external
def disableMint():
    """
    @notice
        Disable Mint function.
        One time Mint is disable, never can be enable again.
        This may only be called if `mintable` variable is `True`.
        This may only be called by the current governance owner address.
    """
    assert self.mintable == True , "!mintable"
    assert msg.sender == self.governance , "!governance"
    self.mintable = False

## sweep 
@external
def sweep(token: address, to: address, amount: uint256):
    """
    @notice
        Sweep tokens and coins out
        This may be used in case of accidentally someone transfer wrong kind of token to this contract.
        Token can not be `this token`.
        This may only be called by governance.
    @param token The token to transfer, if value is ZERO_ADDRESS, function will transfer native coin.
    @param to Address that will receive transfer.
    @param amount The quantity of token to transfer, if value is 0 function will transfer all.
    """
    assert msg.sender == self.governance , "!governance"
    assert self != token , "can not be this token"
    if token == ZERO_ADDRESS:
        value: uint256 = amount
        if value == 0:
            value = self.balance
        log Sweep(ZERO_ADDRESS, value)
        send(to, amount)
    else:
        value: uint256 = amount
        if value == 0:
            value = ERC20(token).balanceOf(self)
        log Sweep(token, value)
        self._erc20_safe_transfer(token, to, value)

## init 
@external
def initialize(name: String[64], symbol: String[12], supply: uint256, governance: address, to: address, mintable: bool):
    """
    @notice
        Initialize contract
        This only be called once.
    @param name Token name
    @param symbol Token symbol, max recommented is 12 digits
    @param supply Quantity of token for initial supply
    @param governance Address authorized for governance interactions.
    @param to Address that receive initial supply
    @param mintable Boolean if token can be mintable 
    """
    assert self.activation == 0 , "initialized"
    self.name = name
    self.symbol = symbol
    self.decimals = 18
    self.governance = governance
    self.mintable = mintable
    self._mint(to, supply * 10 ** 18)
    self.activation = block.timestamp