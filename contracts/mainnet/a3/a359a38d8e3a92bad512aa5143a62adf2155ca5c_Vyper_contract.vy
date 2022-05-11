# @version ^0.3.1
"""
@title Umbrella DAO Registry
@license GNU AGPLv3
@author msugarm
@notice
    Registry contract with DAOs created by Umbrella.
    Only Factories availables or registry owner can
    modify this dao registry
@dev Factory Version: 2.1
"""

DAOS_MAX_SIZE: constant(uint256) = 1_000_000

owner: public(address)
proposedOwner: public(address)
factories: public(HashMap[address,bool])

meta: public(String[128])

struct Dao:
    name: String[64]
    meta: String[128]
    governance: address
    token: address
    treasury: address
    reward_pool: address
    fee_batch: address

daos: public(HashMap[uint256,Dao])
daos_length: public(uint256)

# events

# @notice Emitted when a new Ownership is proposed
# @param governance Address of governance
event OwnerProposed:
    governance: indexed(address)
# @notice Emitted when a new Ownership is accepted
# @param governance Address of governance
event OwnershipAccepted:
    governance: indexed(address)
# @notice Emitted when a new Dao is added
# @param name of governance
# @param id number of governance
event DaoAdded:
    name: String[64]
    id: uint256
# @notice Emitted when a Dao is removed
# @param name of governance
# @param id number of governance
event DaoRemoved:
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
## ERC20 Safe Transfer
@internal
def erc20_safe_transfer(token: address, receiver: address, amount: uint256):
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

@internal
def set_dao(id: uint256, governance: address, name: String[64], meta: String[128], token: address, treasury: address, reward_pool: address, fee_batch: address):
    self.daos[self.daos_length] = Dao({
        governance: governance,
        meta: meta,
        name: name,
        token: token,
        treasury: treasury,
        reward_pool: reward_pool,
        fee_batch: fee_batch,
    })

@internal
def add_dao(governance: address, name: String[64], token: address, treasury: address, reward_pool: address, fee_batch: address):
    self.daos[self.daos_length] = Dao({
        governance: governance,
        meta: self.meta,
        name: name,
        token: token,
        treasury: treasury,
        reward_pool: reward_pool,
        fee_batch: fee_batch,
    })
    self.daos_length += 1

@internal
def pop_dao():
    assert self.daos_length > 0
    self.daos_length -= 1

@internal
def remove_dao(id: uint256):
    assert self.daos_length > 0
    assert self.daos_length > id
    i: uint256 = 0
    for not_i in range(DAOS_MAX_SIZE):
        i = not_i
        if i == self.daos_length - 1:
            self.daos_length -= 1
            return
        elif i >= id and i < self.daos_length - 1:
            self.set_dao(i, self.daos[i + 1].governance,  self.daos[i + 1].name, self.daos[i + 1].meta, self.daos[i + 1].token,  self.daos[i + 1].treasury,  self.daos[i + 1].reward_pool,  self.daos[i + 1].fee_batch)

# externals

## dao
@external
def addDao(governance: address, name: String[64], token: address, treasury: address, reward_pool: address, fee_batch: address):
    assert msg.sender == self.owner or self.factories[msg.sender] , "!owner or !factory"
    self.add_dao(governance, name, token, treasury, reward_pool, fee_batch)

@external
def removeDao(id: uint256, name: String[64]):
    """
    @notice
        Remove an existing DAO in this registry DAO list.

        This may only be called by the current owner address.
    @param id of DAO in dao list
    @param name to set on dao name
    """
    assert msg.sender == self.owner or self.factories[msg.sender] , "!owner or !factory"
    assert self.daos[id].name == name , "wrong dao name" 
    self.remove_dao(id)

@external
def editDAO(id: uint256, name: String[64], meta: String[128]):
    """
    @notice
        Edit and existing DAO in this registry DAO list.

        This may only be called by the current owner address, factory enabled or DAO governance owner.
    @param id of DAO in dao list
    @param name to set on dao name, if empty there will no change on name
    @param meta to set on dao meta, if empty there will no change on meta
    """
    assert msg.sender == self.owner or self.factories[msg.sender] or msg.sender == GovernanceAPI(self.daos[id].governance).owner() , "!owner or !factory or !dao governance owner"
    if len(name) != 0:
        self.daos[id].name = name
    if len(meta) != 0:
        self.daos[id].meta = meta

## meta
@external
def setMeta(meta: String[128]):
    """
    @notice
        Set the default Meta value for every new DAO

        Meta is String for a CID (Content Identifier).
        If want to read more about CID: 
        https://docs.ipfs.io/concepts/content-addressing

        Content always must to follow a JSON format.

        DAO governance can change their Meta using `editDAO()`.

        This may only be called by the current owner address.
    """
    assert msg.sender == self.owner , "!owner"
    self.meta = meta

## factories
@external
def setFactory(factory: address, active: bool):
    """
    @notice
        Enable or disable a Factory on factories list

        Factories enables (with value True), can registry new Daos
        on this registry.

        By default all factories are disable to registry daos.

        This may only be called by the current owner address.
    """
    assert msg.sender == self.owner , "!owner"
    self.factories[factory] = active

## ownership
@external
def proposeOwner(new_owner: address):
    """
    @notice
        Nominate a new address to be the new governance owner.

        The change does not go into effect immediately. This function sets a
        pending change, and the governance address is not updated until
        the proposed owner address has accepted the responsibility.

        This may only be called by the current owner address.
    @param new_owner The address requested to take over governance ownership.
    """
    assert msg.sender == self.owner, "!owner"
    log OwnerProposed(msg.sender)
    self.proposedOwner = new_owner

@external
def acceptOwnership():
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
    assert msg.sender == self.proposedOwner, "!proposedOwner"
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
    @param token The token to transfer, if value is ZERO_ADDRESS, function will transfer native coin.
    @param to Address that will receive transfer.
    @param amount The quantity of token to transfer, if value is 0 function will transfer all.
    """
    assert msg.sender == self.owner , "!owner"
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
        self.erc20_safe_transfer(token, to, value)

# init
@external
def __init__():
    self.owner = msg.sender