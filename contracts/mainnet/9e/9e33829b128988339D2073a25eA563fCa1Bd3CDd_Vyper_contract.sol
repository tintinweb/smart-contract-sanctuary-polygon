"""
@title Reward Pool
@license GNU AGPLv3
@author msugarm
@notice
    A token hold contract that will allow a beneficiary to extract the tokens
    after a given release time.
"""

from vyper.interfaces import ERC20

activation: public(uint256) # unixtimestamp in seconds
governance: public(address)
proposedGovernance: public(address)
feeBatch: public(address)

rewardToken: public(address)
stakedToken: public(address)
totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])

duration: public(uint256) # seconds
periodFinish: public(uint256) # timestamp in seconds

rewardRate: public(uint256)
lastUpdateTime: public(uint256)
rewardPerTokenStored: public(uint256)

userRewardPerTokenPaid: public(HashMap[address, uint256])
rewards: public(HashMap[address, uint256])

event RewardAdded:
    reward: uint256

event Staked:
    user: indexed(address) 
    amount: uint256

event Withdrawn:
    user: indexed(address) 
    amount: uint256

event RewardPaid:
    user: indexed(address) 
    amount: uint256

# @notice Emitted when a new Governance is proposed
# @param governance Address of governance
event GovernanceProposed:
    governance: indexed(address)
# @notice Emitted when a new Governance is accepted
# @param governance Address of governance
event GovernanceAccepted:
    governance: indexed(address)

event Sweep:
    token: indexed(address) 
    amount: uint256

# ERC20 Safe Transfer

@internal
def erc20_safe_transfer_from(token: address, sender: address, receiver: address, amount: uint256):
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

# Internals 

@view
@internal
def last_time_reward_applicable() -> uint256:
    return min(block.timestamp, self.periodFinish)

@view
@internal
def reward_per_token() -> uint256:
    if self.totalSupply == 0:
        return self.rewardPerTokenStored
    else:
        return self.rewardPerTokenStored + ((( self.last_time_reward_applicable() - self.lastUpdateTime) * self.rewardRate * as_wei_value(1, "ether") ) / self.totalSupply)

@view
@internal
def _earned(account: address) -> uint256:
    return (self.balanceOf[account] * (self.reward_per_token() - self.userRewardPerTokenPaid[account]) / as_wei_value(1, "ether")) + self.rewards[account]

@internal
def update_reward(account: address):
    self.rewardPerTokenStored = self.reward_per_token()
    self.lastUpdateTime = self.last_time_reward_applicable()
    if account != ZERO_ADDRESS:
        self.rewards[account] = self._earned(account)
        self.userRewardPerTokenPaid[account] = self.rewardPerTokenStored

@internal
def get_reward(account: address):
    self.update_reward(account)
    reward: uint256 = self._earned(account)
    if reward > 0:
        self.rewards[account] = 0
        self.erc20_safe_transfer(self.rewardToken, account, reward)
        log RewardPaid(account, reward)

@internal
def stake_internal(account: address, amount: uint256):
    self.update_reward(account)
    assert amount > 0 , "Cannot stake 0"
    self.totalSupply = self.totalSupply + amount
    self.balanceOf[account] = self.balanceOf[account] + amount
    self.erc20_safe_transfer_from(self.stakedToken, account, self, amount)
    log Staked(account, amount)


@internal
def withdraw_internal(account: address, amount: uint256):
    self.update_reward(account)
    assert amount > 0 , "Cannot withdraw 0"
    self.totalSupply = self.totalSupply - amount
    self.balanceOf[account] = self.balanceOf[account] - amount
    self.erc20_safe_transfer(self.stakedToken, account, amount)
    log Withdrawn(account, amount)

# Externals

@view
@external
def rewardPerToken() -> uint256:
    return self.reward_per_token()

@view
@external
def lastTimeRewardApplicable() -> uint256:
    return self.last_time_reward_applicable()

@view
@external
def earned(account: address) -> uint256:
    return self._earned(account)

@external
def stake(amount: uint256):
    self.stake_internal(msg.sender, amount)

@external
def withdraw(amount: uint256):
    self.withdraw_internal(msg.sender, amount)

@external
def getReward():
    self.get_reward(msg.sender)

@external
def exit():
    self.withdraw_internal(msg.sender, self.balanceOf[msg.sender])
    self.get_reward(msg.sender)

@external
def updateRewardRate():
    assert msg.sender == self.governance or msg.sender == self.feeBatch , "!governance"
    self.update_reward(ZERO_ADDRESS)
    reward: uint256 = ERC20(self.rewardToken).balanceOf(self)
    self.rewardRate = reward / self.duration
    self.lastUpdateTime = block.timestamp
    self.periodFinish = block.timestamp + self.duration
    log RewardAdded(reward)

@external
def initialize (governance: address, staked_token: address, reward_token: address, duration: uint256, fee_batch: address):
    assert self.activation == 0 , "contract initialized"
    self.governance = governance
    self.stakedToken = staked_token
    self.rewardToken = reward_token
    self.duration = duration
    self.feeBatch = fee_batch
    self.activation = block.timestamp

@external
def sweep(token: address):
    """
    @notice
        Removes tokens from this Vault that are not the type of token managed
        by this Vault. This may be used in case of accidentally sending the
        wrong kind of token to this Vault.

        Tokens will be sent to `governance`.

        This will fail if an attempt is made to sweep the tokens that this
        Vault manages.

        This may only be called by governance.
    @param token the address of token to transfer out of this vault.
    """
    assert msg.sender == self.governance, 'only governace'
    assert token != self.stakedToken, 'staked token not allowed'
    assert token != self.rewardToken, 'reward token not allowed'
    # Can't be used to steal what this Vault is protecting
    amount: uint256 = ERC20(token).balanceOf(self)
    self.erc20_safe_transfer(token, self.governance, amount)
    log Sweep(token, amount)

@external
def sweepNative():
    """
    @notice
        Removes tokens from this Vault that are not the type of token managed
        by this Vault. This may be used in case of accidentally sending the
        wrong kind of token to this Vault.

        Tokens will be sent to `governance`.

        This will fail if an attempt is made to sweep the tokens that this
        Vault manages.

        This may only be called by governance.
    """
    assert msg.sender == self.governance
    # Can't be used to steal what this Vault is protecting
    amount: uint256 = self.balance
    send(self.governance, amount)
    log Sweep(ZERO_ADDRESS, amount)