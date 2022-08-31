# @version 0.3.3

from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed

implements: ERC20
implements: ERC20Detailed

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

event MinterUpdated:
    newMinter: indexed(address)

contract_operator: public(address)
null_slots: int128[1]
# Contract assigned storage slots
name: public(String[64])
symbol: public(String[32])
decimals: public(uint8)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])
totalSupply: public(uint256)
tokenURI: public(String[96])
minter: public(address)
initialized: bool


@external
def proxy_init(_name: String[64], _symbol: String[32], _decimals: uint8, _supply: uint256, _tokenURI: String[96]):
    assert self.initialized == False, 'Contract has already been initialized!'
    self.initialized = True
    self.name = _name
    self.symbol = _symbol
    self.decimals = _decimals
    self.balanceOf[msg.sender] = _supply
    self.totalSupply = _supply
    self.minter = msg.sender
    self.tokenURI = _tokenURI
    log Transfer(ZERO_ADDRESS, msg.sender, _supply)


@internal
def _transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    assert self.balanceOf[_from] >= _value, "Error balance is too low!"
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    log Transfer(_from, _to, _value)
    return True


@external
def transfer(_to : address, _value : uint256) -> bool:
    assert self.initialized == True, 'Contract has not been initialized!'
    return self._transferFrom(msg.sender, _to, _value)


@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    assert self.initialized == True, 'Contract has not been initialized!'
    assert self.allowance[_from][msg.sender] >= _value, "Error allowance is too low!"
    self.allowance[_from][msg.sender] -= _value
    return self._transferFrom(_from, _to, _value)


@external
def approve(_spender : address, _value : uint256) -> bool:
    assert self.initialized == True, 'Contract has not been initialized!'
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True


@external
def mint(_to: address, _value: uint256):
    assert self.initialized == True, 'Contract has not been initialized!'
    assert msg.sender == self.minter, "Error-Only minter may call mint!"
    assert _to != ZERO_ADDRESS
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)


@external
def updateTokenURI(_tokenURI: String[96]):
    assert self.initialized == True, 'Contract has not been initialized!'
    assert msg.sender == self.contract_operator, "Error-Only contract_operator may call updateTokenURI!"
    self.tokenURI = _tokenURI


@external
def setMinter(_minter: address):
    assert self.initialized == True, 'Contract has not been initialized!'
    assert msg.sender == self.minter or msg.sender == self.contract_operator, "Error-Only minter or contract_operator may call setMinter!"
    self.minter = _minter
    log MinterUpdated(_minter)