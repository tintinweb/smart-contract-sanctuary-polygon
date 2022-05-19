# @version ^0.3.3
"""
@title weDAO Incomes Bucket
@license GNU AGPLv3
@author msugarm
@notice
    Where fee funds are pointed to be later distributed among all beneficiaries
    This contract has a Beneficiaries List who receive the distribution.
@dev
    First two beneficiaries usually are Treasury and RewardPool, first two
    beneficiaries get the remainers, half each one

    DAO Version: 3.0
"""
MAX_BENEFICIARIES: constant(uint256) = 10
MAX_BPS: constant(uint256) = 10_000
total_bps: public(uint256)

activation: public(uint256)
governance: public(address)
reward_pool: public(address)
wnative: public(address)
unirouter: public(address)

struct Beneficiary:
    target: address # where to send the funds
    token: address # in which token (ERC20), must have a pair with wnative
    bps: uint256 # basis point

beneficiaries: public(Beneficiary[MAX_BENEFICIARIES])

# events

# @notice Emitted when a new Beneficiary is added
# @param target Address of beneficiary
# @param token Address of ERC20 token that beneficiary going to receive
# @param bps percentage in basis point that beneficiary receive from this fee split
event BeneficiarySet:
    target: indexed(address) 
    token: indexed(address) 
    bps: uint256

# @notice Emitted when a new unirouter is set
# @param unirouter Address of new unirouter
event UnirouterSet:
    unirouter: indexed(address)

# @notice Emitted when a governance sweep stuck tokens
# @param token Address of token stuck
# @param amount Number of token sweeped
event Sweep:
    token: indexed(address)
    amount: uint256

# interfaces

from vyper.interfaces import ERC20

interface UniswapV2Router02:
    def swapExactTokensForTokens(amountIn: uint256, amountOutMin: uint256, path: address[2], to: address, deadline: uint256) -> uint256[3]: nonpayable

interface RewardPoolAPI:
    def update_reward_rate(): nonpayable

# internals

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

@view
@internal
def _get_empty_space() -> uint256:
    for i in range(MAX_BENEFICIARIES):
        if self.beneficiaries[i].target == ZERO_ADDRESS:
            return i
    raise "no more empty spaces"

@view
@internal
def _get_beneficiary(target: address) -> uint256:
    for i in range(MAX_BENEFICIARIES):
        if self.beneficiaries[i].target == target:
            return i
    raise "beneficiary 404 no found"

@internal
def _add_beneficiary(target: address, token: address, bps: uint256):
    """
    @dev See addBeneficiary below
    """
    assert (self.total_bps + bps) < MAX_BPS
    self.total_bps += bps
    empty_space: uint256 = self._get_empty_space()
    self.beneficiaries[empty_space] = Beneficiary({
        target: target,
        token: token,
        bps: bps
    })
    log BeneficiarySet( target, token, bps )

@internal
def _set_unirouter(unirouter: address):
    self.unirouter = unirouter
    ERC20(self.wnative).approve(unirouter, MAX_UINT256)
    log UnirouterSet(unirouter)

# externals

## beneficiary
@external
@nonreentrant("lock")
def add_beneficiary(target: address, token: address, bps: uint256):
    """
    @notice
        Add a new Beneficiary to beneficiaries list

        This only will work if there is space in beneficiaries list
        Bps cannot be greater than MAX_BPS or the sum of all beneficiaries bps

        This may only be called by the current governance owner address
    @param target Address of beneficiary
    @param token Address of ERC20 token that beneficiary going to receive
    @param bps percentage in basis point that beneficiary receive from this fee split
    """
    assert msg.sender == self.governance , "!governance"
    self._add_beneficiary(target, token, bps)

@external
@nonreentrant("lock")
def set_beneficiary(beneficiary_index: uint256, target: address, token: address, bps: uint256):
    """
    @notice
        Edit a Beneficiary from beneficiaries list

        Only can modify token or bps.
        Target beneficiary is for control and avoid misseditions
        Bps can not be higher than MAX_BPS and summarize of all beneficiaries
        bps.

        This may only be called by the current governance owner address.
    @param beneficiary_index index of beneficiary array
    @param target Address of beneficiary
    @param token Address of ERC20 token that beneficiary going to receive
    @param bps percentage in basis point that beneficiary receive from this fee split
    """
    assert msg.sender == self.governance , "!governance"
    assert beneficiary_index != 0 and beneficiary_index != 1 , "!beneficiary_index"
    beneficiary: Beneficiary = self.beneficiaries[beneficiary_index]
    self.total_bps += bps - beneficiary.bps
    assert self.total_bps <= MAX_BPS

    beneficiary = Beneficiary({
        target: target,
        token: token,
        bps: bps
    })

## distribute
@external
@nonreentrant("lock")
def distribute():
    """
    @notice
        Distribute funds from Incomes Bucket to beneficiaries list.
        Treasury receive the remainder in wrapped native token.
        This function only can be called by EOA
    """
    assert msg.sender == tx.origin , "!EOA"

    wnative_balance: uint256 = ERC20(self.wnative).balanceOf(self)

    for i in range(1, MAX_BENEFICIARIES):
        beneficiary: Beneficiary = self.beneficiaries[i]

        if beneficiary.target == ZERO_ADDRESS:
            continue

        half: uint256 = ( wnative_balance * beneficiary.bps ) / MAX_BPS
        if beneficiary.token == self.wnative:
            self._erc20_safe_transfer(self.wnative, beneficiary.target, half)
        else:
            UniswapV2Router02(self.unirouter).swapExactTokensForTokens(half, 0, [self.wnative, beneficiary.token], beneficiary.target, block.timestamp)
    
    # transfer remainder funds to treasury
    remainder: uint256 = ERC20(self.wnative).balanceOf(self)
    self._erc20_safe_transfer(self.wnative, self.beneficiaries[0].target, remainder )
    # update reward rate
    RewardPoolAPI(self.reward_pool).update_reward_rate()

## unirouter
@external
def set_unirouter(new_unirouter: address):
    assert msg.sender == self.governance, "!governance"
    self._set_unirouter(new_unirouter)

## sweep
@external
@nonreentrant("lock")
def sweep(token: address, to: address, amount: uint256):
    """
    @notice
        Sweep tokens and coins out
        This may be used in case of accidentally someone transfer wrong kind of token to this contract.
        Token can not be `wnative`.
        This may only be called by governance.
    @param token The token to transfer, if value is ZERO_ADDRESS, function will transfer native coin.
    @param to Address that will receive transfer.
    @param amount The quantity of token to transfer, if value is 0 function will transfer all.
    """
    assert msg.sender == self.governance , "!governance"
    assert self.wnative != token , "can not be wnative"
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
def initialize(unirouter: address, wnative: address, dao_token: address, governance: address, treasury: address, reward_pool: address, wedao_incomes_bucket: address):
    """
    @notice
        Initializes the Incomes Bucket, this is called only once, when the contract is
        deployed.

        This contract has a Beneficiaries List who receive the distribution.

        First Beneficiary added is governance.

        This may only be called once.
    @param unirouter Address of Uniswapv2 router
    @param wnative Address of ERC20 Wrapped Native token
    @param dao_token Address of ERC20 DAO token
    @param governance The address authorized for governance interactions.
    @param treasury The address of treasury
    @param reward_pool The address of reward_pool
    @param wedao_incomes_bucket The address of wedao_incomes_bucket
    """
    assert self.activation == 0 , "initialized" 
    self.governance = governance
    self.wnative = wnative
    self._set_unirouter(unirouter)
    self.reward_pool = reward_pool
    self._add_beneficiary(treasury, wnative, 0)
    self._add_beneficiary(wedao_incomes_bucket, wnative, 1)
    self._add_beneficiary(reward_pool, wnative, 3500)
    self.activation = block.timestamp