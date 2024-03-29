# @version 0.3.1

from vyper.interfaces import ERC721

event BuyNFT:
    operator: indexed(address)
    buyer: indexed(address)
    price: uint256
    tokenId: uint256

owner: public(address)
pxItems: public(address)
price: public(uint256)
activation: uint8

startTokenId: public(uint256)
endTokenId: public(uint256) 
isSelling: public(bool)

@external
def __init__(_pxItems: address, _price: uint256):
    assert self.activation == 0
    self.pxItems = _pxItems
    self.price = _price
    self.owner = msg.sender
    self.activation = 1 

@external 
def start(_startTokenId: uint256, _endTokenId: uint256):
    assert self.owner == msg.sender
    assert not self.isSelling
    assert self.startTokenId <= self.endTokenId
    self.startTokenId = _startTokenId
    self.endTokenId = _endTokenId
    self.isSelling = True

@view
@external
def available() -> uint256:
    return ERC721(self.pxItems).balanceOf(self)

@external
@payable
@nonreentrant("lock")
def buyNFT(_to: address) -> bool: 
    assert msg.value == self.price 
    assert _to != ZERO_ADDRESS

    available: uint256 = ERC721(self.pxItems).balanceOf(self)
    assert available > 0, "sales ended"

    ERC721(self.pxItems).transferFrom(self, _to, self.endTokenId)
    self.endTokenId -= 1 
    if self.endTokenId < self.startTokenId:
        self.isSelling = False 
        self.startTokenId = 0
        self.endTokenId = 0
    return True


@external 
@nonreentrant("lock")
def setPrice(price: uint256) -> bool:
    assert msg.sender == self.owner
    self.price = price
    return True

@external 
@nonreentrant("lock")
def withdraw() -> bool:
    assert msg.sender == self.owner
    send(self.owner, self.balance)
    return True