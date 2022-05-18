# @version ^0.3.3
"""
@title weHODL
@license GNU AGPLv3
@author msugarm
@notice
    This contract only works with weDAO Dao Factory to mint new weHODL token at the moment that an
    user create a DAO.
    
    This contract is a modification of ERC721.

    At the time that an user want to create a new DAO, user will need at least one $weDAO and allow
    this factory to spend 1 $weDAO from user.

    After the new DAO is created, user $weDAO will be stake in `weHODL` contract and user will 
    receive one $weHODL token. 

    User only can withdraw their $weDAO after 95 days.
    Withdraw $weDAO from weHODL contract has a WITHDRAW_FEE of 5000 BPS and WITHDRAW_FEE is
    gradually reducing 8 BPS everyday. So after 720 days of holding has no withdraw fee.

    $weHODL are Non-Transferible Non-Fungible Tokens.
@dev Factory Version: 2.1
"""
# @dev 360 days in seconds
DAY: constant(uint256) = 86_400
WITHDRAW_START: constant(uint256) = DAY * 95
HODL_AMOUNT: constant(uint256) = 1 * 10 ** 18
WITHDRAW_FEE: constant(uint256) = 5_000 # bps
TOTAL_BPS: constant(uint256) = 10_000 # bps

owner: public(address)
proposed_owner: public(address)
# @dev Contract available to mint new weHODL NT-NFT
minters: public(HashMap[address, bool])
# @dev ERC20 to be hodl here
token: public(address)

struct Hodl:
    owner: address
    start: uint256 # timestamp when hodl start
    active: bool # turn False when hodl withdraw their tokens

hodls: public(HashMap[uint256,Hodl]) # uint256 is for timestamp
hodls_length: public(uint256)
token_enabled_to_withdraw: public(uint256)

# @dev Mapping from NFT ID to the address that owns it.
idToOwner: HashMap[uint256, address]
# @dev Mapping from owner address to count of his tokens.
ownerToHodlCount: HashMap[address, uint256]


# events

# @notice Emitted when a new Ownership is proposed
# @param governance Address of governance
event OwnerProposed:
    governance: indexed(address)
# @notice Emitted when a new Ownership is accepted
# @param governance Address of governance
event OwnershipAccepted:
    governance: indexed(address)
# @notice Emitted when a new Hodler is added
# @param name of governance
# @param id number of governance
event HodlerAdded:
    name: String[64]
    id: uint256
# @notice Emitted when a Sweep is executed
# @param token Address of token that has been sweep, if is ZERO_ADDRESS means Native coin
# @param amount The quantity of token/native that has been transfer
event Sweep:
    token: indexed(address) 
    amount: uint256

# interfaces
from vyper.interfaces import ERC20

interface GovernanceAPI:
    def owner() -> address: view

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
def _mint_hodl(to: address):
    """
    @notice Mint new weHODL token to `to`
    """
    assert to != ZERO_ADDRESS
    self.ownerToHodlCount[to] += 1
    self.hodls[self.hodls_length] = Hodl({
        owner: to,
        start: block.timestamp,
        active: True
    })
    self.hodls_length += 1

# externals

## erc721
@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @dev Returns the number of NFTs owned by `_owner`.
         Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    @param _owner Address for whom to query the balance.
    """
    assert _owner != ZERO_ADDRESS
    return self.ownerToHodlCount[_owner]

@view
@external
def ownerOf(_tokenId: uint256) -> address:
    """
    @dev Returns the address of the owner of the NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId The identifier for an NFT.
    """
    owner: address = self.hodls[_tokenId].owner
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    return owner

# hodl

@external
def mint(hodler: address):
    assert self.minters[msg.sender] , "!minter"
    self._mint_hodl(hodler)

@external
@nonreentrant("lock")
def withdraw(tokenId: uint256):
    """
    @notice
        withdraw weDAO tokens.
        This function may only be call once if hodl is active.
    @param tokenId TokenId to deactivated
    @dev desactive hodl on hodls token list
    """
    hodl: Hodl = self.hodls[tokenId]
    assert msg.sender == hodl.owner
    assert hodl.active , "!active"
    assert (block.timestamp - hodl.start) > WITHDRAW_START , "!WITHDRAW_START"
    days_after_withdraw_fee: uint256 = ( block.timestamp - hodl.start ) / DAY
    fee: uint256 = HODL_AMOUNT * ( WITHDRAW_FEE - ( days_after_withdraw_fee * 8 ) ) / TOTAL_BPS
    hodl.active = False
    self.token_enabled_to_withdraw += fee
    self._erc20_safe_transfer(self.token, msg.sender, (HODL_AMOUNT - fee))


@external
def withdraw_fees(to: address, amount: uint256):
    """
    @notice
        Withdraw fees collected from this contract to `to` address.

        This may only be called by the current owner address.
    @param to The address that will receive tokens
    @param amount The amount of token to transfer
    """
    assert msg.sender == self.owner , "!owner"
    assert amount <= self.token_enabled_to_withdraw, "!amount"
    self.token_enabled_to_withdraw -= amount
    self._erc20_safe_transfer(self.token, to, amount)


## minters
@external
def set_minter(minter: address, active: bool):
    """
    @notice
        Enable or disable a Minter on minters list

        Minters enables (with value True), can registry new Hodler
        on this registry.

        By default all minters are disable to registry holders.

        This may only be called by the current owner address.
    """
    assert msg.sender == self.owner , "!owner"
    self.minters[minter] = active

## ownership
@external
def propose_owner(owner: address):
    """
    @notice
        Nominate a new address to be the new governance owner.

        The change does not go into effect immediately. This function sets a
        pending change, and the governance address is not updated until
        the proposed owner address has accepted the responsibility.

        This may only be called by the current owner address.
    @param owner The address requested to take over governance ownership.
    """
    assert msg.sender == self.owner, "!owner"
    log OwnerProposed(owner)
    self.proposed_owner = owner

@external
def accept_ownership():
    """
    @notice
        Once a new owner address has been proposed using proposeOwner(),
        this function may be called by the proposed address to accept the
        responsibility of taking over owner for this contract.

        This may only be called by the proposed owner address.
    @dev
        proposeOwner() should be called by the existing owner address,
        prior to calling this function.
    """
    assert msg.sender == self.proposed_owner, "!proposedOwner"
    self.owner = msg.sender
    log OwnershipAccepted(msg.sender)

## sweep
@external
def sweep(token: address, to: address, amount: uint256):
    """
    @notice
        Sweep tokens and coins out
        This may be used in case of accidentally someone transfer wrong kind of token to this contract.
        This may only be called by owner.
        Can not sweep the token that this hodl.
    @param token The token to transfer, if value is ZERO_ADDRESS, function will transfer native coin.
    @param to Address that will receive transfer.
    @param amount The quantity of token to transfer, if value is 0 function will transfer all.
    """
    assert msg.sender == self.owner , "!owner"
    assert token != self.token , "!token"
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

# init
@external
def __init__(token: address):
    self.token = token
    self.owner = msg.sender