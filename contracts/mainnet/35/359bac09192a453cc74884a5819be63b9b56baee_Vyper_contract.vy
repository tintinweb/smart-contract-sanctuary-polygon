# @version ^0.3.1
"""
@title Umbrella Master Factory
@license GNU AGPLv3
@author msugarm
@notice
    Main factory that create/clone all the DAO architecture
    This Contract is a Factory that clone and create new contracts
"""

struct Dao:
    governance: address
    name: String[64]
    token: address
    treasury: address
    reward_pool: address
    fee_batch: address

daos: public(Dao[256])
owner: public(address)
unirouter: public(address)
wnative: public(address)
targets: public(HashMap[String[12],address])

# events

event DaoAdded:
    name: String[64]
    id: uint256

event NewTarget:
    name: String[12]
    target: address

# interfaces

interface FeeBatchAPI:
    def initialize(unirouter: address, wnative: address, dao_token: address, governance: address, treasury: address, reward_pool: address): nonpayable

interface TreasuryAPI:
    def initialize (governance: address): nonpayable

interface TokenAPI:
    def initialize(name: String[64], symbol: String[12], supply: uint256): nonpayable

interface RewardPoolAPI:
    def initialize (governance: address, staked_token: address, reward_token: address, duration: uint256, fee_batch: address): nonpayable
    def updateRewardRate (): nonpayable

# internal functions

@internal
def deploy_token(name: String[64], symbol: String[12], supply: uint256) -> address:
    clone: address = create_forwarder_to(self.targets["token"])
    TokenAPI(clone).initialize(name, symbol, supply)
    return clone

@internal
def deploy_treasury(governance: address) -> address:
    clone: address = create_forwarder_to(self.targets["treasury"])
    TreasuryAPI(clone).initialize(governance)
    return clone

@internal
def deploy_fee_batch(governance: address, dao_token: address, treasury: address, reward_pool: address) -> address:
    clone: address = create_forwarder_to(self.targets["fee_batch"])
    FeeBatchAPI(clone).initialize(self.unirouter, self.wnative, dao_token, governance, treasury, reward_pool)
    return clone

@view
@internal
def find_free_space() -> uint256:
    for i in range(256):
        if self.daos[i].governance == ZERO_ADDRESS:
            return i
    raise "No more space here"

# Externals

@view
@external
def findFreeSpace() -> uint256:
    return self.find_free_space()

@external
def __init__():
    self.owner = msg.sender

@external
def setUnirouter(new_unirouter: address):
    assert msg.sender == self.owner , '!owner'
    self.unirouter = new_unirouter

@external
def setWnative(new_wnative: address):
    assert msg.sender == self.owner , '!owner'
    self.wnative = new_wnative

@external
def setTarget(name: String[12], new_target: address):
    assert msg.sender == self.owner , "!owner"
    self.targets[name] = new_target
    log NewTarget(name, new_target)

@external
def createDao(governance: address, name: String[64], token_symbol: String[12], token_supply: uint256):

    free_space: uint256 = self.find_free_space()
    token: address = self.deploy_token(name, token_symbol, token_supply)
    treasury: address = self.deploy_treasury(governance)
    reward_pool: address = create_forwarder_to(self.targets["reward_pool"])
    # - fee batch
    fee_batch: address = self.deploy_fee_batch(governance, token, treasury, reward_pool)
    # reward_pool period is 1 day in seconds = 86400
    # users want to stake the DAO token, and get reward in, probably wnative
    RewardPoolAPI(reward_pool).initialize(governance, token, self.wnative, 86400, fee_batch)

    self.daos[free_space] = Dao({
        governance: governance,
        name: name,
        token: token,
        treasury: treasury,
        reward_pool: reward_pool,
        fee_batch: fee_batch,
    })
    log DaoAdded(name, free_space)