# @version 0.3.1

from vyper.interfaces import ERC20

implements: ERC20

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

owner: public(address)
allowance: public(HashMap[address, HashMap[address, uint256]])
balanceOf: public(HashMap[address, uint256])
totalSupply: public(uint256)
activation: uint8
name: public(String[50])
symbol: public(String[5])

DECIMALS: constant(uint8) = 18


VERSION: constant(String[28]) = "1.0.0"

# `nonces` track `permit` approvals with signature.
nonces: public(HashMap[address, uint256])
DOMAIN_SEPARATOR: public(bytes32)
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
PERMIT_TYPE_HASH: constant(bytes32) = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")

@external
def __init__(name: String[50], symbol: String[5]):
    assert self.activation < 1 # dev: no devops199 here
    self.owner = msg.sender
    self.name = name 
    self.symbol = symbol 
    self.activation = 1
    # EIP-712
    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(convert("PX Token", Bytes[11])),
            keccak256(convert(VERSION, Bytes[28])),
            convert(chain.id, bytes32),
            convert(self, bytes32)
        )
    )


@view
@external
def decimals() -> uint8:
    return DECIMALS

@external
def mint(receiver: address, amount: uint256) -> bool:
    assert msg.sender == self.owner
    assert receiver != ZERO_ADDRESS

    self.totalSupply += amount
    self.balanceOf[receiver] += amount

    log Transfer(ZERO_ADDRESS, receiver, amount)
    return True

@external
def approve(spender : address, amount : uint256) -> bool:
    self.allowance[msg.sender][spender] = amount

    log Approval(msg.sender, spender, amount)
    return True

@external
def increaseAllowance(spender: address, added: uint256) -> bool:
    allowance: uint256 = self.allowance[msg.sender][spender] + added
    self.allowance[msg.sender][spender] = allowance

    log Approval(msg.sender, spender, allowance)
    return True

@external
def decreaseAllowance(spender: address, subtracted: uint256) -> bool:
    allowance: uint256 = self.allowance[msg.sender][spender] - subtracted
    self.allowance[msg.sender][spender] = allowance

    log Approval(msg.sender, spender, allowance)
    return True

@external
def burnFrom(owner: address, amount: uint256) -> bool:
    assert msg.sender == self.owner
    assert owner != ZERO_ADDRESS

    self.totalSupply -= amount
    self.balanceOf[owner] -= amount

    log Transfer(owner, ZERO_ADDRESS, amount)
    return True

@external
def transfer(receiver: address, amount: uint256) -> bool:
    assert amount > 0
    assert self.balanceOf[msg.sender] >= amount, "Insufficient funds"
    assert msg.sender != receiver
    assert receiver != ZERO_ADDRESS
    self.balanceOf[msg.sender] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(msg.sender, receiver, amount)
    return True

@external
def transferFrom(sender: address, receiver: address, amount: uint256) -> bool:
    assert amount > 0
    assert self.balanceOf[sender] >= amount, "Insufficient funds"
    assert sender != receiver
    assert receiver != ZERO_ADDRESS
    allowance: uint256 = self.allowance[sender][msg.sender]
    assert allowance >= amount
    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount
    if allowance != MAX_UINT256:
        self.allowance[sender][msg.sender] = allowance - amount

    log Transfer(sender, receiver, amount)
    return True

@external
def set_owner(owner: address):
    assert msg.sender == self.owner
    assert owner != ZERO_ADDRESS # dev: invalid owner
    self.owner = owner


@external
def permit(owner: address, spender: address, amount: uint256, expiry: uint256, signature: Bytes[65]) -> bool:
    """
    @notice
        Approves spender by owner's signature to expend owner's tokens.
        See https://eips.ethereum.org/EIPS/eip-2612.
    @param owner The address which is a source of funds and has signed the Permit.
    @param spender The address which is allowed to spend the funds.
    @param amount The amount of tokens to be spent.
    @param expiry The timestamp after which the Permit is no longer valid.
    @param signature A valid secp256k1 signature of Permit by owner encoded as r, s, v.
    @return True, if transaction completes successfully
    """
    assert owner != ZERO_ADDRESS  # dev: invalid owner
    assert expiry == 0 or expiry >= block.timestamp  # dev: permit expired
    nonce: uint256 = self.nonces[owner]
    digest: bytes32 = keccak256(
        concat(
            b'\x19\x01',
            self.DOMAIN_SEPARATOR,
            keccak256(
                concat(
                    PERMIT_TYPE_HASH,
                    convert(owner, bytes32),
                    convert(spender, bytes32),
                    convert(amount, bytes32),
                    convert(nonce, bytes32),
                    convert(expiry, bytes32),
                )
            )
        )
    )
    # NOTE: signature is packed as r, s, v
    r: uint256 = convert(slice(signature, 0, 32), uint256)
    s: uint256 = convert(slice(signature, 32, 32), uint256)
    v: uint256 = convert(slice(signature, 64, 1), uint256)
    assert ecrecover(digest, v, r, s) == owner  # dev: invalid signature
    self.allowance[owner][spender] = amount
    self.nonces[owner] = nonce + 1
    log Approval(owner, spender, amount)
    return True