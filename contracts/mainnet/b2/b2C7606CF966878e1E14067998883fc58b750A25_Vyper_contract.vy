"""
@title Fee Batch
@license GNU AGPLv3
@author msugarm
@notice
    Where fee funds are pointed to be later distributed among all beneficiaries
    This contract has a Beneficiaries List who receive the distribution.

@dev
    First two beneficiaries usually are Treasury and RewardPool, first two
    beneficiaries get the remainers, half each one

"""

from vyper.interfaces import ERC20 as IERC20

interface UniswapV2Router02:
    def swapExactTokensForTokens(amountIn: uint256, amountOutMin: uint256, path: address[2], to: address, deadline: uint256) -> uint256[3]: nonpayable

interface RewardPoolAPI:
    def updateRewardRate(): nonpayable

activation: public(uint256)
proposedGovernance: public(address)
governance: public(address)
rewardPool: public(address)
# Tokens used
wnative: public(address)
unirouter: public(address)

struct Beneficiary:
    target: address # where to send the funds
    token: address # in which token (ERC20), must have a pair with wnative
    bps: uint256 # basis point

beneficiaries: Beneficiary[MAX_BENEFICIARIES]

# @notice Emitted when a new Beneficiary is added
# @param target Address of beneficiary
# @param token Address of ERC20 token that beneficiary going to receive
# @param bps percentage in basis point that beneficiary receive from this fee split
event BeneficiaryAdded:
    target: indexed(address) 
    token: indexed(address) 
    bps: uint256

# @notice Emitted when a Beneficiary is removed
# @param target Address of beneficiary
event BeneficiaryRemoved:
    target: indexed(address)

# @notice Emitted when a new Governance is accepted
# @param governance Address of governance
event GovernanceAccepted:
    governance: indexed(address)
# @notice Emitted when a new Governance is proposed
# @param governance Address of governance
event GovernanceProposed:
    governance: indexed(address)

# @notice Emitted when a governance sweep stuck tokens
# @param token Address of token stuck
# @param amount Number of token sweeped
event Sweep:
    token: indexed(address)
    amount: uint256

DOMAIN_SEPARATOR: public(bytes32)
MAX_BENEFICIARIES: constant(uint256) = 10
MAX_BPS: constant(uint256) = 10_000

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


@view
@internal
def find_empty_space_in_beneficiaries() -> uint256:
    for i in range(MAX_BENEFICIARIES):
        if self.beneficiaries[i].target == ZERO_ADDRESS:
            return i
    raise "no more empty spaces"

@view
@internal
def find_beneficiary(target: address) -> uint256:
    for i in range(MAX_BENEFICIARIES):
        if self.beneficiaries[i].target == target:
            return i
    raise "no more empty spaces"

@view
@internal
def sum_of_all_bps() -> uint256:
    result: uint256 = 0
    for i in range(MAX_BENEFICIARIES):
        result += self.beneficiaries[i].bps
    return result

@internal
def add_beneficiary(target: address, token: address, bps: uint256):
    """
    @dev See addBeneficiary below
    """

    # TODO add check for ERC20

    sum_of_bps: uint256 = self.sum_of_all_bps()

    assert MAX_BPS >= (sum_of_bps + bps)

    empty_space: uint256 = self.find_empty_space_in_beneficiaries()
    self.beneficiaries[empty_space] = Beneficiary({
        target: target,
        token: token,
        bps: bps
    })
    log BeneficiaryAdded( target, token, bps )

@external
def addBeneficiary(target: address, token: address, bps: uint256):
    """
    @notice
        Add a new Beneficiary to beneficiaries list

        This only will work if there is space in beneficiaries list

        Token have to be a ERC20
        
        Bps can not be higher than MAX_BPS and summarize of all beneficiaries
        bps

        This may only be called by the current governance address.
    @param target Address of beneficiary
    @param token Address of ERC20 token that beneficiary going to receive
    @param bps percentage in basis point that beneficiary receive from this fee split
    """
    assert msg.sender == self.governance
    self.add_beneficiary(target, token, bps)

@external
def removeBeneficiary(target: address):
    """
    @notice
        Remove a Beneficiary from beneficiaries list

        This may only be called by the current governance address.
    @param target Address of beneficiary
    """
    assert msg.sender == self.governance
    beneficiary_index: uint256 = self.find_beneficiary(target)
    self.beneficiaries[beneficiary_index] = Beneficiary({
        target: ZERO_ADDRESS,
        bps: 0,
        token: ZERO_ADDRESS
    })

@external
def distribute():
    """
    @notice
        Distribute funds from Fee batch to beneficiaries

        Distribution is made based in beneficiaries list, this can be done
        through wrapped native or in ERC20 token setted

        First Beneficiary (beneficiaries[0]) is the one that receive the
        remainder of distribution in wrapped native token

        This function only can be called by EOA
    """
    assert msg.sender == tx.origin

    wnative_balance: uint256 = IERC20(self.wnative).balanceOf(self)

    for i in range(2, MAX_BENEFICIARIES):

        if self.beneficiaries[i].target == ZERO_ADDRESS:
            continue

        half: uint256 = ( wnative_balance * self.beneficiaries[i].bps ) / MAX_BPS
        if self.beneficiaries[i].token == self.wnative:
            self.erc20_safe_transfer(self.wnative,self.beneficiaries[i].target, half)
        else:
            UniswapV2Router02(self.unirouter).swapExactTokensForTokens(half, 0, [self.wnative, self.beneficiaries[i].token], self.beneficiaries[i].target, block.timestamp)
    
    remainder: uint256 = wnative_balance * ( MAX_BPS - self.sum_of_all_bps() ) / MAX_BPS

    # send half of remainder funds to reward_pool (beneficiaries[1])
    self.erc20_safe_transfer(self.wnative,self.beneficiaries[1].target, ( remainder / 2 ) )
    # after send wnative to reward, update the reward rate
    RewardPoolAPI(self.rewardPool).updateRewardRate()
    # send the half remainder funds to treasury (beneficiaries[0]), splitting
    # it half in wnative and other half in DAO token
    self.erc20_safe_transfer(self.wnative, self.beneficiaries[0].target, ( remainder / 4 ) )
    UniswapV2Router02(self.unirouter).swapExactTokensForTokens(( remainder / 4 ), 0, [self.wnative, self.beneficiaries[0].token], self.beneficiaries[0].target, block.timestamp)


# Governance
@external
def proposeGovernance(governance: address):
    """
    @notice
        Nominate a new address to use as governance.

        The change does not go into effect immediately. This function sets a
        pending change, and the governance address is not updated until
        the proposed governance address has accepted the responsibility.

        This may only be called by the current governance address.
    @param governance The address requested to take over Vault governance.
    """
    assert msg.sender == self.governance
    log GovernanceProposed(msg.sender)
    self.proposedGovernance = governance

@external
def acceptGovernance():
    """
    @notice
        Once a new governance address has been proposed using proposeGovernance(),
        this function may be called by the proposed address to accept the
        responsibility of taking over governance for this contract.

        This may only be called by the proposed governance address.
    @dev
        proposeGovernance() should be called by the existing governance address,
        prior to calling this function.
    """
    assert msg.sender == self.proposedGovernance
    self.governance = msg.sender
    log GovernanceAccepted(msg.sender)


@external
def sweep(token: address, amount: uint256 = MAX_UINT256):
    """
    @notice
        Removes tokens from this Vault that are not the type of token managed
        by this Vault. This may be used in case of accidentally sending the
        wrong kind of token to this Vault.

        Tokens will be sent to `governance`.

        This will fail if an attempt is made to sweep the tokens that this
        Vault manages.

        This may only be called by governance.
    @param token The token to transfer out of this vault.
    @param amount The quantity or tokenId to transfer out.
    """
    assert msg.sender == self.governance
    # Can't be used to steal what this Vault is protecting
    value: uint256 = amount
    if value == MAX_UINT256:
        value = IERC20(token).balanceOf(self)
    log Sweep(token, value)
    self.erc20_safe_transfer(token, self.governance, value)


# Initializer
@external
def initialize(unirouter: address, wnative: address, dao_token: address, governance: address, treasury: address, reward_pool: address):
    """
    @notice
        Initializes the Fee Batch, this is called only once, when the contract is
        deployed.

        This contract has a Beneficiaries List who receive the distribution.

        First Beneficiary added is governance
    @param unirouter Address of Uniswapv2 router
    @param wnative Address of ERC20 Wrapped Native token
    @param dao_token Address of ERC20 DAO token
    @param governance The address authorized for governance interactions.
    @param treasury The address of treasury
    @param reward_pool The address of reward_pool
    """
    assert self.activation == 0  # dev: no devops199    
    self.governance = governance
    log GovernanceAccepted(governance)

    self.unirouter = unirouter
    IERC20(wnative).approve(unirouter, MAX_UINT256)
    self.wnative = wnative
    self.rewardPool = reward_pool
    self.add_beneficiary(treasury, wnative, 0)
    self.add_beneficiary(reward_pool, dao_token, 0)
    self.activation = block.timestamp