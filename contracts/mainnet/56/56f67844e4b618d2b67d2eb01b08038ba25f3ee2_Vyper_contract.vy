# @version ^0.3.3
"""
@title weFactory
@license Copyright (c) weDAO, 2022 - all rights reserved
@author weDAO
@notice 
    Main factory that create new DAOs.

    Any user can create DAO using this contract with 
    just running `create_dao()` function and `weDAO DAO Factory`
    will create a set of mininmal proxies for all necessary dao contracts
    and setup each one to be already to use.

    At the time that an user want to create a new DAO, user will need at least
    one weDAO token ( $utoken ) and allow to this factory to spend 1 $utoken from user.

    After the new DAO is created, user $utoken will be stake for 90 days in `weDAO HODL` contract
    and user will receive one $uBOND token. 

    User can withdraw their $utoken at anytime with a fee discount of 15%.
    Withdraw $utoken from weDAO HODL contract before completion time has a fee of 50%.
    Withdraw $utoken from weDAO HODL contract after completion time has a fee of 50%.
    In the case user want to withdraw it before 1080 days

    Every new Dao create will be registry on `weDAO Dao Registry` contract
@dev Factory Version: 3.1
"""
DAY: constant(uint256) = 86400

name: public(String[64])
version: public(String[32])
activation: public(uint256)
creator: public(address)
governance: public(address)
proposed_governance: public(address)

targets: public(HashMap[String[32],address])

# events

# @notice Emitted when a new governance is set
# @param governance Address of new governance
event GovernanceSet:
    governance: indexed(address)
# @notice Emitted when a new Dao created
# @param name of Dao created
# @param id Number Id of Dao created
event DaoCreated:
    name: String[64]
    governance: indexed(address)
# @notice Emitted when a new Target is set
# @param name String name of target
# @param target Address of target
event TargetSet:
    name: String[32]
    target: address

# interfaces

interface WeRegistryAPI:
    def set_governances(governance: DynArray[address,10]) -> DynArray[uint256,10]: nonpayable
    def set_contracts(contracts: DynArray[address,10]) -> DynArray[uint256,10]: nonpayable

interface HodlAPI:
    def mint(hodler: address): nonpayable

interface IncomesBucketAPI:
    def initialize(name: String[32], governance: address, creator: address, unirouter: address, wnative: address, treasury: address, reward_pool: address, we_incomes_bucket: address, we_fee_discounter: address): nonpayable

interface TreasuryAPI:
    def initialize(name: String[32], governance: address, creator: address): nonpayable

interface TokenAPI:
    def initialize(name: String[32], governance: address, creator: address, symbol: String[12], supply: uint256, to: address, mintable: bool): nonpayable

interface RewardPoolAPI:
    def initialize(name: String[32], governance: address, creator: address, staked_token: address, reward_token: address, duration: uint256, incomes_bucket: address): nonpayable

interface GovernanceAPI:
    def initialize(name: String[32], creator: address, owner: address, registry: address, registry_id: uint256): nonpayable

# Internals

## ERC20 Safe Transfer
@internal
def _erc20_safe_transfer_from(token: address, sender: address, receiver: address, amount: uint256):
    # Used only to send tokens that are not the type managed by this Vault.
    # HACK: Used to handle non-compliant tokens like USDT
    response: Bytes[32] = raw_call(
        token,
        concat(
            method_id("transferFrom(address,address,uint256)"),
            convert(sender, bytes32),
            convert(receiver, bytes32),
            convert(amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) > 0:
        assert convert(response, bool), "Transfer failed!"

@internal
def _mint_hodl(sender: address):
    self._erc20_safe_transfer_from(self.targets["token"], sender, self.targets["hodl"], 1 * 10 ** 18)
    HodlAPI(self.targets["hodl"]).mint(sender)

# Externals

## set variables
@external
def set_target(name: String[32], target: address):
    assert msg.sender == self.governance , "!owner"
    self.targets[name] = target
    log TargetSet(name, target)

## daos 

@external
@nonreentrant("lock")
def create_dao(owner: address, name: String[32], token_symbol: String[12], token_supply: uint256, token_mintable: bool, reward_pool_duration: uint256 = 28):
    """
    @notice
        Craete minimal proxies for every contract of the DAO architecture
        then registry new dao into DAO Registry

    @dev Sender has to allow weFactory as spender of their weDAO
    @param owner The owner for the new DAO
    @param name The name for the new DAO and DAO token
    @param token_symbol The token symbol for the new DAO token
    @param token_supply The token supply for the new DAO token, inital supply is transfer to DAO owner
    @param token_mintable Set if DAO token going to be mintable
    @param reward_pool_duration Duration for reward distribution in time, default is 28 days (4)
    """
    # self._mint_hodl(msg.sender)
    governance: address = create_forwarder_to(self.targets["governance"])
    token: address = create_forwarder_to(self.targets["token"])
    treasury: address = create_forwarder_to(self.targets["treasury"])
    reward_pool: address = create_forwarder_to(self.targets["reward_pool"])
    incomes_bucket: address = create_forwarder_to(self.targets["incomes_bucket"])
    TokenAPI(token).initialize(name, governance, msg.sender, token_symbol, token_supply, owner, token_mintable)
    TreasuryAPI(treasury).initialize(name, governance, msg.sender)
    IncomesBucketAPI(incomes_bucket).initialize(name, governance, msg.sender, self.targets["unirouter"], self.targets["wnative"], treasury, reward_pool, self.targets["incomes_bucket"], self.targets["we_fee_discounter"])
    RewardPoolAPI(reward_pool).initialize(name, governance, msg.sender, token, self.targets["wnative"], reward_pool_duration * DAY, incomes_bucket)
    we_registry_id: DynArray[uint256,10] = WeRegistryAPI(self.targets["we_registry"]).set_governances([governance])
    GovernanceAPI(governance).initialize(name, msg.sender, owner, self.targets["we_registry"], we_registry_id[0])
    WeRegistryAPI(self.targets["we_registry"]).set_contracts([token, treasury, reward_pool, incomes_bucket])
    log DaoCreated(name, governance)


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

## init
@external
def initialize(name: String[64], governance: address, creator: address, wnative: address, unirouter: address):
    """
    @notice
        Initializes the weFactory

        This may only be called once.
    @param name String of name reference for this contract
    @param governance address authorized for governance interactions
    @param creator Address of contract creator
    @param wnative Address of contract wnative
    @param unirouter Address of contract unirouter
    """
    assert self.activation == 0 , "initialized"
    self.name = name
    self.governance = governance
    self.creator = creator
    self.version = "factory v4"
    self.targets["wnative"] = wnative
    self.targets["unirouter"] = unirouter
    self.activation = block.timestamp