# @version 0.3.1

from vyper.interfaces import ERC721
from vyper.interfaces import ERC20

event BuyNFT:
    operator: indexed(address)
    buyer: indexed(address)
    price: uint256
    tokenId: uint256

owner: public(address)
pxItems: public(address)
asset: public(address)
price: public(uint256)
activation: uint8

startTokenId: public(uint256)
endTokenId: public(uint256) 
isSelling: public(bool)

@external
def __init__(pxItems: address, asset: address, price: uint256):
    assert self.activation == 0
    self.owner = msg.sender
    self.pxItems = pxItems
    self.asset = asset
    self.price = price
    self.activation = 1 

@external 
def start(_startTokenId: uint256, _endTokenId: uint256):
    assert self.owner == msg.sender
    assert not self.isSelling
    assert _startTokenId <= _endTokenId
    self.startTokenId = _startTokenId
    self.endTokenId = _endTokenId
    self.isSelling = True

@view
@external
def available() -> uint256:
    return self.endTokenId - self.startTokenId + 1 

@external
@nonreentrant("lock")
def buyNFT(_to: address) -> bool: 
    assert self.isSelling
    assert _to != ZERO_ADDRESS
    sender: address = msg.sender
    assert ERC20(self.asset).balanceOf(sender) >= self.price
    
    available: uint256 = ERC721(self.pxItems).balanceOf(self)
    assert available > 0, "sales ended"
    # Transfer the tokens from the asset contract to the seller
    assert ERC20(self.asset).transferFrom(sender, self, self.price)
    # Transfer the NFT from the seller to the buyer
    ERC721(self.pxItems).transferFrom(self, _to, self.endTokenId)
    self.endTokenId -= 1 
    if self.endTokenId < self.startTokenId:
        self.isSelling = False 
        self.startTokenId = 0
        self.endTokenId = 0
    return True


@external 
@nonreentrant("lock")
def setPrice(_price: uint256) -> bool:
    assert msg.sender == self.owner
    self.price = _price
    return True

@external 
@nonreentrant("lock")
def setAsset(_asset: address) -> bool:
    assert msg.sender == self.owner
    self.asset = _asset
    return True

@external 
@nonreentrant("lock")
def withdraw() -> bool:
    assert msg.sender == self.owner
    amount: uint256 = ERC20(self.asset).balanceOf(self)
    assert amount > 0
    assert ERC20(self.asset).transfer(self.owner, amount)
    return True