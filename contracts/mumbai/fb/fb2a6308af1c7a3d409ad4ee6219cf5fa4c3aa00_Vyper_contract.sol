# @version ^0.3.1
from vyper.interfaces import ERC20

token: ERC20
owner: address
salt: uint256
rarity_table: uint8[4]
started: public(bool)
finalized: public(bool)
last_draw_amount: public(uint256)

draw_price: constant(uint256) = 10 * 10 ** 18 #10 ether
gacha_base: constant(uint256) = 256
amount_per_draw: constant(uint8) = 10

rarity_ultra_rare: constant(uint8) = 0
rarity_super_super_rare: constant(uint8) = 1
rarity_super_rare: constant(uint8) = 2
rarity_rare: constant(uint8) = 3

ultra_rare_bonus: constant(uint8) = 10
super_super_rare_bonus: constant(uint8) = 5
super_rare_bonus: constant(uint8) = 3
rare_bonus: constant(uint8) = 2

event Draw:
    user: indexed(address)
    rarity: String[16]
    amount: uint8

@external
def __init__():
    self.owner = msg.sender
    self.started = False
    self.finalized = False
    self.salt = bitwise_xor(block.timestamp, block.number)

@external
def config(token: address, rarity_table: uint8[4]):
    self.token = ERC20(token)
    self.rarity_table = rarity_table

@external
def start():
    assert msg.sender == self.owner, "only owner"
    assert not self.finalized, "finalized"

    self.started = True

@external
def finalize():
    assert msg.sender == self.owner, "only owner"
    assert self.started, "not started"

    self.finalized = True
    self.started = False
    
    assert self.token.transfer(ZERO_ADDRESS, self.token.balanceOf(self)), "burn failed"

@external
def withdraw():
    assert msg.sender == self.owner, "only owner"

    send(msg.sender, self.balance)


@internal
def rand() -> uint256:
    seed: Bytes[96] = concat(convert(block.difficulty, bytes32), convert(block.timestamp, bytes32),
    convert(bitwise_xor(self.salt, block.number), bytes32))
    num: uint256 = convert(keccak256(seed), uint256)

    self.salt = num
    return num

@internal
def internal_draw(user: address) -> uint8:
    seed: uint256 = self.rand() / 10 ** 18
    num: uint256 = (seed % gacha_base) + 1

    if num > gacha_base / 2:
        num = gacha_base - num

    rarity: uint8 = convert(num, uint8)
    if rarity <= self.rarity_table[rarity_ultra_rare]:
        amount: uint8 = amount_per_draw * ultra_rare_bonus
        log Draw(user, "Ultra Rare", amount)
        return amount

    if rarity <= self.rarity_table[rarity_super_super_rare]:
        amount: uint8 = amount_per_draw * super_super_rare_bonus
        log Draw(user, "Super Super Rare", amount)
        return amount

    if rarity <= self.rarity_table[rarity_super_rare]:
        amount: uint8 = amount_per_draw * super_rare_bonus
        log Draw(user, "Super Rare", amount)
        return amount

    if rarity <= self.rarity_table[rarity_rare]:
        amount: uint8 = amount_per_draw * rare_bonus
        log Draw(user, "Rare", amount)
        return amount

    log Draw(user, "Commom", amount_per_draw)
    return amount_per_draw

@payable
@external
def draw():
    assert self.started, "not started"
    assert msg.value == draw_price, "pay to draw"
    assert self.token.balanceOf(self) >= amount_per_draw * ultra_rare_bonus, "token balance too low"

    amount: uint256 = convert(self.internal_draw(msg.sender), uint256) * 10 ** 18

    self.last_draw_amount  = amount
    assert self.token.transfer(msg.sender, amount), "transfer failed"


@payable
@external
def special_draw():
    assert self.started, "not started"
    assert msg.value == draw_price * 9, "pay to draw"
    assert self.token.balanceOf(self) >= amount_per_draw * ultra_rare_bonus * 10, "token balance too low"

    amount: uint256 = 0

    for i in range(10):
        amount = amount + convert(self.internal_draw(msg.sender), uint256) * 10 ** 18
    
    self.last_draw_amount = amount
    assert self.token.transfer(msg.sender, amount), "transfer failed"

@payable
@external
def kill():
    assert msg.sender == self.owner, "only owner"
    selfdestruct(self.owner)