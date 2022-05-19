# @version ^0.3.3
"""
@title weDAO Governance
@license GNU AGPLv3
@author msugarm
@notice
    This contract is the only one that has control over the other part of DAO
    architecture contracts and Owner of governance is the major authority of the DAO.
    
    This contract should be seen has the main API where users can execture actions.

    Governance Owner can add roles and limits to address to exection minor actions
    like treasurers or minters.
@dev DAO Version: 3.0
"""
ROLES_LIST_SIZE: constant(uint256) = 10

activation: public(uint256)
owner: public(address)
proposed_owner: public(address)

treasurers: public(address[ROLES_LIST_SIZE])

struct Treasurer_limit:
    period: uint256
    amount: uint256
    remainder: uint256
    last_time: uint256
# @dev 
#   treasurer - token - Treasurer_limit
#   use ZERO_ADDRESS in token as reference for Native
treasurer_limits: public(HashMap[address, HashMap[address, Treasurer_limit]])
treasurer_free_pass: public(HashMap[address, bool])

minters: public(address[ROLES_LIST_SIZE]) 
struct Minter_limit:
    period: uint256
    amount: uint256
    remainder: uint256
    last_time: uint256
minter_limits: public(HashMap[address, Minter_limit])

treasury: public(address)
incomes_bucket: public(address)
reward_pool: public(address)
token: public(address)

# events

# @notice Emitted when a new Ownership is proposed
# @param governance Address of governance
event OwnerProposed:
    governance: indexed(address)
# @notice Emitted when a new Ownership is accepted
# @param governance Address of governance
event OwnershipAccepted:
    governance: indexed(address)
# @notice Emitted when a new Treasurer is set
# @param index Array Index
# @param treasurer Address of treasurer
event TreasurerSet:
    index: uint256
    treasurer: indexed(address)
# @notice Emitted when a new Treasurer free pass is set
# @param treasurer Address of treasurer
# @param active Bool 
event TreasurerFreePassSet:
    treasurer: indexed(address)
    active: bool
# @notice Emitted when a Treasurer Limit is set
# @param treasurer Address of treasurer
# @param token Address of token ERC20
# @param period Time frequency available to transfer
# @param amount The quantity of token available to transfer between period
event TreasurerLimitSet:
    treasurer: indexed(address)
    token: address
    period: uint256
    amount: uint256
# @notice Emitted when a new Minter is set
# @param index Array Index
# @param minter Address of minter
event MinterSet:
    index: uint256
    minter: indexed(address)
# @notice Emitted when a new Minter is set
# @param minter Address of minter
# @param period Time frequency available to mint
# @param amount The quantity of token available to mint between period
event MinterLimitSet:
    minter: indexed(address)
    period: uint256
    amount: uint256
# @notice Emitted when a Sweep is executed
# @param token Address of token that has been sweep, if is ZERO_ADDRESS means Native coin
# @param amount The quantity of token/native that has been transfer
# @param to Address that received tokens
event Sweep:
    token: indexed(address) 
    amount: uint256
    to: indexed(address)

# interfaces

from vyper.interfaces import ERC20

interface IncomesBucketAPI:
    def add_beneficiary(target: address, token: address, bps: uint256): nonpayable
    def set_beneficiary(beneficiary_index: uint256, target: address, token: address, bps: uint256):nonpayable
    def set_unirouter(new_unirouter: address): nonpayable
    def sweep(token: address, to: address, amount: uint256): nonpayable

interface RewardPoolAPI:
    def update_reward_rate(): nonpayable
    def sweep(token: address, to: address, amount: uint256): nonpayable

interface TokenAPI:
    def mint(to: address, amount: uint256): nonpayable
    def disableMint(): nonpayable
    def sweep(token: address, to: address, amount: uint256): nonpayable

interface TreasuryAPI:
    def transfer(token: address, to: address, amount: uint256): nonpayable
    

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

# externals
## incomes bucket
@external
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
    assert msg.sender == self.owner, "!owner"
    IncomesBucketAPI(self.incomes_bucket).add_beneficiary(target, token, bps)

@external
def set_beneficiary(beneficiary_index: uint256, target: address, token: address, bps: uint256):
    """
    @notice
        Edit a Beneficiary from beneficiaries list

        Only can modify token or bps.
        Target beneficiary is for control and avoid misseditions
        Bps cannot be greater than MAX_BPS or the sum of all beneficiaries bps

        This may only be called by the current governance owner address
    @param beneficiary_index index of beneficiary array
    @param target Address of beneficiary
    @param token Address of ERC20 token that beneficiary going to receive
    @param bps percentage in basis point that beneficiary receive from this fee split
    """
    assert msg.sender == self.owner, "!owner"
    IncomesBucketAPI(self.incomes_bucket).set_beneficiary(beneficiary_index,target, token, bps)

## treasury

### treasurer
@view
@internal
def fetch_treasurer_remainer(treasurer: address, token: address) -> uint256:
    limits: Treasurer_limit = self.treasurer_limits[msg.sender][token]
    if limits.last_time > ( block.timestamp - limits.period ):
        return limits.remainder + (limits.amount / limits.period) * (block.timestamp - limits.last_time)
    else:
        return limits.amount

@internal
def _validate_is_treasurer(treasurer: address) -> bool:
    for i in range(ROLES_LIST_SIZE):    
        if self.treasurers[i] == treasurer:
            return True
    return False

@external
def set_treasurer(index: uint256, treasurer: address):
    """
    @notice
        Set or unset Treasurer of treasurers list 

        Treasurer are not allow to execute transfer. 
        To set permissions to treasurer to transfer you have two options:
        1. set limited permission over a token using `set_treasurer_limit` function
        2. set unlimited permissions over all tokens using `set_treasurer_free_pass` function
    """
    assert msg.sender == self.owner , "!owner"
    self.treasurers[index] = treasurer
    log TreasurerSet(index, treasurer)

@external
def set_treasurer_limit(treasurer: address, token: address, period: uint256, amount: uint256):
    assert msg.sender == self.owner , "!owner"
    self.treasurer_limits[treasurer][token] = Treasurer_limit({
        period: period,
        amount: amount,
        remainder: amount,
        last_time: 0
    })
    log TreasurerLimitSet(treasurer, token, period, amount)

@external
def set_treasurer_free_pass(treasurer: address, active: bool):
    """
    @notice
        Enable or Disable Treasurer Free pass transfers 

        treasurers with free pass will have unlimited permissions to transfer over all tokens
    """
    assert msg.sender == self.owner , "!owner"
    self.treasurer_free_pass[treasurer] = active
    log TreasurerFreePassSet(treasurer, active)

### Transfer
@external
@nonreentrant("lock")
def transfer(token: address, to: address, amount: uint256):
    is_treasurer: bool = self._validate_is_treasurer(msg.sender)
    assert msg.sender == self.owner or is_treasurer , "!owner or !treasurer"
    if msg.sender == self.owner or self.treasurer_free_pass[msg.sender]:
        TreasuryAPI(self.treasury).transfer(token, to, amount)
    else:
        limits: Treasurer_limit = self.treasurer_limits[msg.sender][token]
        # @dev tricky: if period is 0, amount act like ERC20 allowance
        if limits.period == 0:
            assert limits.amount >= amount , "!amount"
            limits.amount -= amount
            TreasuryAPI(self.treasury).transfer(token, to, amount)
        elif limits.last_time > ( block.timestamp - limits.period ):
            # @dev refill the remainder if still in a period
            limits.remainder += (limits.amount / limits.period) * (block.timestamp - limits.last_time)
            assert limits.remainder >= amount , "!amount"
            limits.remainder -= amount
            limits.last_time = block.timestamp
            TreasuryAPI(self.treasury).transfer(token, to, amount)
        else:
            # @dev if it out of period, refill remainder up to 'amount'
            assert limits.amount >= amount , "!amount"
            limits.remainder = limits.amount - amount
            limits.last_time = block.timestamp
            TreasuryAPI(self.treasury).transfer(token, to, amount)

## reward pool
@external
def update_reward_rate():
    assert msg.sender == self.owner , "!owner"
    RewardPoolAPI(self.reward_pool).update_reward_rate()

## token

### minters
@view
@internal
def fetch_minter_remainer(minter: address) -> uint256:
    limits: Minter_limit = self.minter_limits[msg.sender]
    if limits.last_time > ( block.timestamp - limits.period ):
        return limits.remainder + (limits.amount / limits.period) * (block.timestamp - limits.last_time)
    else:
        return limits.amount

@internal
def _validate_is_minter(minter: address) -> bool:
    for i in range(ROLES_LIST_SIZE):    
        if self.minters[i] == minter:
            return True
    return False

@external
def set_minter(index: uint256, minter: address):
    """
    @notice
        Enable or Disable Minter Role to `minter` Address 

        Minter per se does not has authority to mint

        set limit with `setMinterLimit` to adjust limit to Minter
    @param index Number in minter array to set up new minter
    @param minter Address of minter
    """
    assert msg.sender == self.owner , "!owner"
    self.minters[index] = minter
    log MinterSet(index, minter)

@external
def set_minter_limit(minter: address, period: uint256, amount: uint256):
    """
    @notice
        Set limits to minter
    @param minter Address of minter
    @param period Time frequency available to mint
    @param amount The quantity of token available to mint between period
    """
    assert msg.sender == self.owner , "!owner"
    self.minter_limits[minter] = Minter_limit({
        period: period,
        amount: amount,
        remainder: amount,
        last_time: 0
    })
    log MinterLimitSet(minter, period, amount)

### mint
@external
def mint(to: address, amount: uint256):
    """
    @notice
        Mint tokens of token variable
        This may only called by owner or any minter available
    @param to Address that receive new tokens
    @param amount Quantity of new tokens
    """
    is_minter: bool = self._validate_is_minter(msg.sender)
    assert msg.sender == self.owner or is_minter , "!owner or !minter"
    if is_minter:
        limits: Minter_limit = self.minter_limits[msg.sender]
        # @dev tricky: if period is 0, amount act like ERC20 allowance
        if limits.period == 0:
            assert limits.amount >= amount , "!amount"
            limits.amount -= amount
            TokenAPI(self.token).mint(to, amount)
        elif limits.last_time > ( block.timestamp - limits.period ):
            # @dev refill the remainder if still in a period
            limits.remainder += (limits.amount / limits.period) * (block.timestamp - limits.last_time)
            assert limits.remainder >= amount , "!amount"
            limits.remainder -= amount
            limits.last_time = block.timestamp
            TokenAPI(self.token).mint(to, amount)
        else:
            # @dev if it out of period, refill remainder up to 'amount'
            assert limits.amount >= amount , "!amount"
            limits.remainder = limits.amount - amount
            limits.last_time = block.timestamp
            TokenAPI(self.token).mint(to, amount)
    else:
        TokenAPI(self.token).mint(to, amount)


@external
def set_disable_mint():
    """
    @notice
        Disable Mint from token for ever
        This only be called once.
        This may only be called by owner.
    """
    assert msg.sender == self.owner , "!owner"
    TokenAPI(self.token).disableMint()

## sweep
@external
def sweep(token: address, to: address, amount: uint256, contract: String[32]):
    """
    @notice
        sweep tokens and coins out
        This may only be called by owner.
    @param token The token to transfer, if value is ZERO_ADDRESS, function will transfer native coin.
    @param to Address that will receive transfer.
    @param amount The quantity of token to transfer, if value is 0 function will transfer all. 
    @param contract The contract where want to sweep, if value is blank function will sweep from this contract
    """
    assert msg.sender == self.owner , "!owner"
    if contract == "token":
        IncomesBucketAPI(self.token).sweep(token, to, amount)
    if contract == "incomes_bucket":
        IncomesBucketAPI(self.incomes_bucket).sweep(token, to, amount)
    if contract == "reward_pool":
        RewardPoolAPI(self.reward_pool).sweep(token, to, amount)
    if contract == "":
        if token == ZERO_ADDRESS:
            log Sweep(ZERO_ADDRESS, amount, to)
            send(to, amount)
        else:
            log Sweep(token, amount, to)
            self._erc20_safe_transfer(token, to, amount)

## ownership
@external
def set_proposed_owner(new_owner: address):
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
    self.proposed_owner = new_owner

@external
def accept_ownership():
    """
    @notice
        Once a new owner address has been proposed using set_propose_owner(),
        this function may be called by the proposed address to accept the
        responsibility of taking over owner for this contract.

        This may only be called by the proposed owner address.
    @dev
        set_propose_owner() should be called by the existing owner address,
        prior to calling this function.
    """
    assert msg.sender == self.proposed_owner, "!proposed_owner"
    self.proposed_owner = ZERO_ADDRESS
    self.owner = msg.sender
    log OwnershipAccepted(msg.sender)

## init
@external
def initialize(owner: address, treasury: address, incomes_bucket: address, reward_pool: address, token: address):
    """
    @notice
        Initialize governance address
        
        Set initial values for essencial variables.

        This may only be called once.
    @param owner The address authorized for owner interactions
    @param treasury The address for treasury variable
    @param incomes_bucket The address for incomes_bucket variable
    @param reward_pool The address for reward_pool variable
    @param token The address for token variable
    """
    assert self.activation == 0 , "initialized"
    self.owner = owner
    self.treasury = treasury
    self.incomes_bucket = incomes_bucket
    self.reward_pool = reward_pool
    self.token = token
    self.activation = block.timestamp