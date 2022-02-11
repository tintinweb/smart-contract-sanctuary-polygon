# @version ^0.3.1

names: HashMap[uint256, String[30]]
lenN: uint256
owner: address

@external
def __init__() -> address:
    self.owner = msg.sender
    return self.owner


@payable
@external
def set(namesadd: String[30]):
    assert namesadd != "", "Don't enter a blank string."
    assert len(namesadd) < 30, "String is too long."

    value_sent: uint256 = msg.value
    assert value_sent >= as_wei_value(1, "wei"), "Please pay the required 1 MATIC fee."

    self.names[self.lenN] = namesadd
    self.lenN = self.lenN + 1

@view
@external
def read(num: uint256) -> String[30]:
    name: String[30] = self.names[num]
    return name

@view
@external
def length() -> uint256:
    return self.lenN

@external
def withdraw(amount: uint256):
    assert self.balance > amount, "There is not enough money. The amount is written in wei."
    assert msg.sender == self.owner, "You have to be the creator of the contract to withdraw fees."
    send(self.owner, amount)

@view
@external
def value() -> uint256:
    return self.balance