# @version ^0.3.3
"""
@title weDAO Reward Pool
@license GNU AGPLv3
@author msugarm
@notice
    Contract where users can stake staked_token to get reward in reward_token
@dev DAO Version: 3.0
"""

activation: public(uint256) # unixtimestamp in seconds
governance: public(address)
proposed_governance: public(address)
incomes_bucket: public(address)

reward_token: public(address)
staked_token: public(address)
total_supply: public(uint256)
balance_of: public(HashMap[address, uint256])

duration: public(uint256) # seconds
period_finish: public(uint256) # timestamp in seconds

reward_rate: public(uint256)
last_update_time: public(uint256)
reward_per_token_stored: public(uint256)

user_reward_per_token_paid: public(HashMap[address, uint256])
rewards: public(HashMap[address, uint256])

# events

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

# @notice Emitted when a Sweep is executed
# @param token Address of token that has been sweep, if is ZERO_ADDRESS means Native coin
# @param amount The quantity of token/native that has been transfer
event Sweep:
    token: indexed(address) 
    amount: uint256

# interfaces

from vyper.interfaces import ERC20

# internals

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

@view
@internal
def _get_last_time_reward_applicable() -> uint256:
    return min(block.timestamp, self.period_finish)

@view
@internal
def _get_reward_per_token() -> uint256:
    if self.total_supply == 0:
        return self.reward_per_token_stored
    else:
        return self.reward_per_token_stored + ((( self._get_last_time_reward_applicable() - self.last_update_time) * self.reward_rate * as_wei_value(1, "ether") ) / self.total_supply)

@view
@internal
def _get_earned(account: address) -> uint256:
    return (self.balance_of[account] * (self._get_reward_per_token() - self.user_reward_per_token_paid[account]) / as_wei_value(1, "ether")) + self.rewards[account]

@internal
def _update_reward(account: address):
    self.reward_per_token_stored = self._get_reward_per_token()
    self.last_update_time = self._get_last_time_reward_applicable()
    if account != ZERO_ADDRESS:
        self.rewards[account] = self._get_earned(account)
        self.user_reward_per_token_paid[account] = self.reward_per_token_stored

@internal
def _get_reward(account: address):
    self._update_reward(account)
    reward: uint256 = self._get_earned(account)
    if reward > 0:
        self.rewards[account] = 0
        self._erc20_safe_transfer(self.reward_token, account, reward)
        log RewardPaid(account, reward)

@internal
def _set_stake(account: address, amount: uint256):
    self._update_reward(account)
    assert amount > 0 , "Cannot stake 0"
    self.total_supply = self.total_supply + amount
    self.balance_of[account] = self.balance_of[account] + amount
    self._erc20_safe_transfer_from(self.staked_token, account, self, amount)
    log Staked(account, amount)

@internal
def _set_withdraw(account: address, amount: uint256):
    self._update_reward(account)
    assert amount > 0 , "Cannot withdraw 0"
    self.total_supply = self.total_supply - amount
    self.balance_of[account] = self.balance_of[account] - amount
    self._erc20_safe_transfer(self.staked_token, account, amount)
    log Withdrawn(account, amount)

# externals

@view
@external
def get_reward_per_token() -> uint256:
    return self._get_reward_per_token()

@view
@external
def get_last_time_reward_applicable() -> uint256:
    return self._get_last_time_reward_applicable()

@view
@external
def get_earned(account: address) -> uint256:
    return self._get_earned(account)

@external
def set_stake(amount: uint256):
    self._set_stake(msg.sender, amount)

@external
def set_withdraw(amount: uint256):
    self._set_withdraw(msg.sender, amount)

@external
@nonreentrant("lock")
def get_teward():
    self._get_reward(msg.sender)

@external
@nonreentrant("lock")
def exit():
    self._set_withdraw(msg.sender, self.balance_of[msg.sender])
    self._get_reward(msg.sender)

@external
@nonreentrant("lock")
def update_reward_rate():
    assert msg.sender == self.governance or msg.sender == self.incomes_bucket , "!governance"
    self._update_reward(ZERO_ADDRESS)
    reward: uint256 = ERC20(self.reward_token).balanceOf(self)
    self.reward_rate = reward / self.duration
    self.last_update_time = block.timestamp
    self.period_finish = block.timestamp + self.duration
    log RewardAdded(reward)

## sweep 
@external
def sweep(token: address, to: address, amount: uint256):
    """
    @notice
        Sweep tokens and coins out
        This may be used in case of accidentally someone transfer wrong kind of token to this contract.
        Token can not be `reward_token` or `staked_token`.
        This may only be called by governance.
    @param token The token to transfer, if value is ZERO_ADDRESS, function will transfer native coin.
    @param to Address that will receive transfer.
    @param amount The quantity of token to transfer, if value is 0 function will transfer all.
    """
    assert msg.sender == self.governance , "!governance"
    assert self.reward_token != token , "can not be reward_token"
    assert self.staked_token != token , "can not be staked_token"
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
def initialize(governance: address, staked_token: address, reward_token: address, duration: uint256, incomes_bucket: address):
    assert self.activation == 0 , "initialized"
    self.governance = governance
    self.staked_token = staked_token
    self.reward_token = reward_token
    self.duration = duration
    self.incomes_bucket = incomes_bucket
    self.activation = block.timestamp