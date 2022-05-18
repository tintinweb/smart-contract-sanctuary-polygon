"""
@title weDAO DAO Factory
@license GNU AGPLv3
@author msugarm
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
@dev Factory Version: 3
"""

owner: public(address)
proposed_owner: public(address)
targets: public(HashMap[String[32],address])

struct Dao:
    name: String[64]
    meta: String[128]
    governance: address
    token: address
    treasury: address
    reward_pool: address
    incomes_bucket: address

# events

# @notice Emitted when a new Ownership is proposed
# @param governance Address of governance
event OwnerProposed:
    governance: indexed(address)
# @notice Emitted when a new Ownership is accepted
# @param governance Address of governance
event OwnershipAccepted:
    governance: indexed(address)
# @notice Emitted when a new Dao created
# @param name of Dao created
# @param id Number Id of Dao created
event DaoCreated:
    name: String[64]
    id: uint256
# @notice Emitted when a new Target is set
# @param name String name of target
# @param target Address of target
event TargetSet:
    name: String[32]
    target: address

# interfaces

interface DaoRegistryAPI:
    def addDao(governance: address, name: String[64], token: address, treasury: address, reward_pool: address, incomes_bucket: address): nonpayable
    def removeDao(id: uint256): nonpayable

interface HodlAPI:
    def mint(hodler: address): nonpayable

interface IncomesBucketAPI:
    def initialize(unirouter: address, wnative: address, dao_token: address, governance: address, treasury: address, reward_pool: address, wedao_incomes_bucket: address): nonpayable

interface TreasuryAPI:
    def initialize(governance: address): nonpayable

interface TokenAPI:
    def initialize(name: String[64], symbol: String[12], supply: uint256, governance: address, to: address, mintable: bool): nonpayable

interface RewardPoolAPI:
    def initialize(governance: address, staked_token: address, reward_token: address, duration: uint256, incomes_bucket: address): nonpayable

interface GovernanceAPI:
    def initialize(owner: address, treasury: address, incomes_bucket: address, reward_pool: address, token: address): nonpayable

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
def _deploy_token(name: String[64], symbol: String[12], supply: uint256, governance: address, to: address, mintable: bool) -> address:
    clone: address = create_forwarder_to(self.targets["token"])
    TokenAPI(clone).initialize(name, symbol, supply, governance, to, mintable)
    return clone

@internal
def _deploy_treasury(governance: address) -> address:
    clone: address = create_forwarder_to(self.targets["treasury"])
    TreasuryAPI(clone).initialize(governance)
    return clone

@internal
def _deploy_incomes_bucket(governance: address, dao_token: address, treasury: address, reward_pool: address) -> address:
    clone: address = create_forwarder_to(self.targets["incomes_bucket"])
    IncomesBucketAPI(clone).initialize(self.targets["unirouter"], self.targets["wnative"], dao_token, governance, treasury, reward_pool, self.targets["wedao_incomes_bucket"])
    return clone

@internal
def _mint_hodl(sender: address):
    self._erc20_safe_transfer_from(self.targets["token"], sender, self.targets["hodl"], 1 * 10 ** 18)
    HodlAPI(self.targets["hodl"]).mint(sender)

# Externals

## set variables

@external
def set_target(name: String[32], target: address):
    assert msg.sender == self.owner , "!owner"
    self.targets[name] = target
    log TargetSet(name, target)

## daos 
@external
def create_dao(owner: address, name: String[64], token_symbol: String[12], token_supply: uint256, token_mintable: bool, reward_pool_duration: uint256 = 28):
    """
    @notice
        Craete minimal proxies for every contract of the DAO architecture
        then registry new dao into DAO Registry

    @dev Sender has to allowed weDAO DAO Factory as spender 
    @param owner The owner for the new DAO
    @param name The name for the new DAO and DAO token
    @param token_symbol The token symbol for the new DAO token
    @param token_supply The token supply for the new DAO token, inital supply is transfer to DAO owner
    @param token_mintable Set if DAO token going to be mintable
    @param reward_pool_duration Duration for reward distribution in time, default is 28 days (4)
    """
    self._mint_hodl(msg.sender)
    governance: address = create_forwarder_to(self.targets["governance"])
    token: address = self._deploy_token(name, token_symbol, token_supply, governance, owner, token_mintable)
    treasury: address = self._deploy_treasury(governance)
    reward_pool: address = create_forwarder_to(self.targets["reward_pool"])
    incomes_bucket: address = self._deploy_incomes_bucket(governance, token, treasury, reward_pool)
    RewardPoolAPI(reward_pool).initialize(governance, token, self.targets["wnative"], reward_pool_duration * 86400, incomes_bucket)
    GovernanceAPI(governance).initialize(owner, treasury, incomes_bucket, reward_pool, token)
    DaoRegistryAPI(self.targets["registry"]).addDao(governance, name, token, treasury, reward_pool, incomes_bucket)

@external
def removeDao(id: uint256, name: String[64]):
    """
    @notice remove a DAO from DAOs list, this will not destroy or modify already deployed DAO minimal proxies
    """
    assert msg.sender == self.owner , "!owner"
    DaoRegistryAPI(self.targets["registry"]).removeDao(id)

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
    self.proposed_owner = owner
    log OwnerProposed(owner)

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
    assert msg.sender == self.proposed_owner, "!proposed_owner"
    self.owner = msg.sender
    log OwnershipAccepted(msg.sender)
    
## init
@external
def __init__(wnative: address, unirouter: address, wedao_incomes_bucket: address):
    self.owner = msg.sender
    self.targets["unirouter"] = unirouter
    self.targets["wedao_incomes_bucket"] = wedao_incomes_bucket
    self.targets["wnative"] = wnative