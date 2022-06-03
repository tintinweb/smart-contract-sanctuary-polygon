# @version ^0.3.3
"""
@title weRegistry
@license Copyright (c) weDAO, 2022 - all rights reserved
@author weDAO
@notice
    Registry contract with DAOs created by weDAO.
    Only Factories availables or registry owner can
    modify this dao registry
@dev version: 4
"""
MAX_LEN: constant(uint256) = 1_000_000

name: public(String[64])
version: public(String[32])
activation: public(uint256)
creator: public(address)
governance: public(address)
proposed_governance: public(address)

factories: public(HashMap[address,bool])

# governance id -> address
governances: public(DynArray[address,MAX_LEN])
# @dev old governance -> new governance
governances_migration: public(HashMap[address,address])

# contract id -> address
contracts: public(DynArray[address,MAX_LEN])

# events

# @notice Emitted when a new governance is set
# @param governance Address of new governance
event GovernanceSet:
    governance: indexed(address)
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
    def activation() -> uint256: view

# internals
## ERC20 Safe Transfer
@internal
def _erc20_safe_transfer(token: address, receiver: address, amount: uint256):
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

# externals

@view
@external
def governances_length() -> uint256:
    return len(self.governances)

@view
@external
def contracts_length() -> uint256:
    return len(self.contracts)

@external
def set_governances(governances: DynArray[address, 10]) -> DynArray[uint256,10]:
    """
    @notice
        Set a DAO Governance address into governances address.

        This may only be called by the current registry owner or any factory enable.
    @param governances Addresses of governances to set
    @return array with governances id
    """
    assert msg.sender == self.governance or self.factories[msg.sender] , "!owner or !factory"
    added: DynArray[uint256, 10] =[]
    for governance in governances:
        self.governances.append(governance)
        added.append(len(self.governances))
    return added

@external
def set_contracts(contracts: DynArray[address, 10]) -> DynArray[uint256,10]:
    """
    @notice
        Set a DAO Governance address into governances address.

        This may only be called by the current registry owner or any factory enable.
    @param contracts Addresses of contracts to set
    @return array with contracts id
    """
    assert msg.sender == self.governance or self.factories[msg.sender] , "!owner or !factory"
    added: DynArray[uint256, 10] =[]
    for contract in contracts:
        self.contracts.append(contract)
        added.append(len(self.contracts))
    return added

@external
def set_migrate_governance(id: uint256, governance: address):
    """
    @notice
        Migrate a governance address to another governance address

        This may only be called by the current registry owner or DAO governance owner.
    @param id of DAO in dao list
    @param governance Address this change only will works when is called from governance contract.
    """
    assert msg.sender == self.governances[id] , "!sender"
    self.governances[id] = governance
    self.governances_migration[msg.sender] = governance


## factories
@external
def set_factory(factory: address, active: bool):
    """
    @notice
        Enable or disable a Factory on factories list

        Factories enables (with value True), can registry new Daos
        on this registry.

        By default all factories are disable to registry daos.

        This may only be called by the current owner address.
    """
    assert msg.sender == self.governance , "!owner"
    self.factories[factory] = active

## governance
@external
def set_proposed_governance(governance: address):
    """
    @notice propose an Address to be the new governance
    @param governance Address of porposed governance
    """
    assert msg.sender == self.governance , "!governance"
    self.proposed_governance = governance

@external
def set_governance():
    """
    @notice governance migration to another governance contract

    This may only be called by the proposed governance address.
    """
    assert msg.sender == self.proposed_governance , "!proposed_governance"
    self.proposed_governance = ZERO_ADDRESS
    self.governance = msg.sender
    log GovernanceSet(msg.sender)

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
    assert msg.sender == self.governance , "!owner"
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
def initialize(name: String[64], governance: address, creator: address):
    """
    @notice
        Initializes the weRegistry

        This may only be called once.
    @param name String of name reference for this contract
    @param governance address authorized for governance interactions
    @param creator Address of contract creator
    """
    assert self.activation == 0 , "initialized"  
    self.name = name
    self.governance = governance
    self.creator = creator
    self.version = "registry v4"
    self.activation = block.timestamp