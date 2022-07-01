# pragma ^0.0.33

# Interfaces

from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed

interface ERC1155:
    def mint(_account: address, _id: uint256, _amount: uint256, _data: Bytes[1024]): nonpayable

# Constants

MAX_BATCH_SIZE: constant(uint256) = 32

# State

DEPOSIT_TOKEN_ERC20: immutable(address)
ASSET_TOKEN_ERC1155: immutable(address)
ASSET_TOKEN_ID_ERC1155: immutable(uint256)
FRACTION_PRICE: immutable(uint256)
TOTAL_FRACTIONS: immutable(uint256)
COMPLETION_THRESHOLD: immutable(uint256)
COMPLETION_DEADLINE: immutable(uint256)

owner: public(address)
committedPurchaseCount: public(HashMap[address, uint256])
totalCommittedPurchaseCount: public(uint256)
isCompleted: public(bool)
isCancelled: public(bool)

# Events

event PurchaseCommitted:
    purchaser: indexed(address)
    commitmentCount: uint256

event PurchaseCompleted:
    purchaser: indexed(address)
    purchaseCount: uint256

event FundraiserCompleted: pass

event FundraiserCancelled: pass

event RefundClaimed:
    purchaser: indexed(address)
    refundCount: uint256

event OwnershipTransferred:
    oldOwner: address
    newOwner: address

event FundsWithdrawn:
    fundsReceiver: address

# Constructor

@external
def __init__(
    depositTokenERC20: address,   # e.g. USDC
    assetTokenERC1155: address,   # our custom Token deployed contract.
    assetTokenIdERC1155: uint256, # token ID for custom deployed contract.
    fractionPrice: uint256,       # Price 1 fraction per 1 unit of Deposit Token. Be careful with decimals.
    totalFractions: uint256,      # Total number of fractions.
    completionThreshold: uint256, # 0-`totalFractions` threshold required to be allowed to complete
    completionDeadline: uint256,  # Block number that sale must be completed by, or funds will be refunded. 0 means no deadline.
):
    DEPOSIT_TOKEN_ERC20 = depositTokenERC20
    ASSET_TOKEN_ERC1155 = assetTokenERC1155
    ASSET_TOKEN_ID_ERC1155 = assetTokenIdERC1155
    FRACTION_PRICE = fractionPrice
    TOTAL_FRACTIONS = totalFractions
    COMPLETION_THRESHOLD = completionThreshold
    COMPLETION_DEADLINE = completionDeadline
    self.owner = msg.sender

# Functions

@external
def transferOwnership(_to: address):
    """
    @dev Transfers ownership from current owner to `to`. Only callable by current owner.
    @param _to The address to transfer ownership to.
    """
    assert msg.sender == self.owner, "Not admin"
    assert _to != ZERO_ADDRESS, "Cant destroy responsibility"

    oldOwner: address = self.owner
    self.owner = _to
    
    log OwnershipTransferred(oldOwner, _to)

@external
def completeFundraiser():
    """
    @dev Marks fundraiser as completed, allows withdrawal of funds and minting of tokens. Only callable by owner.
    """
    assert msg.sender == self.owner, "Not admin"
    assert not self.isCompleted, "Cannot complete twice"
    assert not self.isCancelled, "Cannot complete cancelled fundraiser"
    assert (COMPLETION_DEADLINE == 0) or (block.number <= COMPLETION_DEADLINE), "Deadline passed already"
    assert self.totalCommittedPurchaseCount >= COMPLETION_THRESHOLD, "Threshold not met"

    self.isCompleted = True
    
    log FundraiserCompleted()

@external
def cancelFundraiser():
    """
    @dev Marks fundraiser as cancelled, allows refunding of user funds. Only callable by owner.
    """
    assert msg.sender == self.owner, "Not admin"
    assert not self.isCompleted, "Cannot cancel completed fundraiser"
    assert not self.isCancelled, "Cannot cancel twice"

    self.isCancelled = True

    log FundraiserCancelled()

@external
@nonreentrant("commitToPurchase")
def commitToPurchase(_count: uint256):
    """
    @dev Allows a user to commit to purchasing any remaining fractions available.
    @param _count Number of fractions the user wants to buy.
    """
    assert not self.isCancelled, "Cannot deposit in cancelled fundraiser"
    assert not self.isCompleted, "Cannot deposit in completed fundraiser"
    assert self.totalCommittedPurchaseCount + _count <= TOTAL_FRACTIONS, "Cannot purchase more than total fractions"
    assert (COMPLETION_DEADLINE == 0) or (block.number <= COMPLETION_DEADLINE), "Deadline passed already"
    
    totalDeposit: uint256 = _count * FRACTION_PRICE

    selfPreDepositBalance: uint256 = ERC20(DEPOSIT_TOKEN_ERC20).balanceOf(self)

    ERC20(DEPOSIT_TOKEN_ERC20).transferFrom(msg.sender, self, totalDeposit)

    selfPostDepositBalance: uint256 = ERC20(DEPOSIT_TOKEN_ERC20).balanceOf(self)

    assert selfPostDepositBalance - selfPreDepositBalance == totalDeposit, "Error during deposit"

    self.committedPurchaseCount[msg.sender] += _count
    self.totalCommittedPurchaseCount += _count

    log PurchaseCommitted(msg.sender, _count)

@internal
def _completePurchase(_receiver: address):
    """
    @dev Completes a purchase for a receiver.
    @notice Assumes completed/cancelled checks have already been performed.
    @param _receiver Address of committed purchaser.
    """
    receiverTokenCount: uint256 = self.committedPurchaseCount[_receiver]

    assert receiverTokenCount > 0, "Cannot complete purchase if user has no committed purchases left"

    ERC1155(ASSET_TOKEN_ERC1155).mint(_receiver, ASSET_TOKEN_ID_ERC1155, receiverTokenCount, empty(Bytes[100]))

    # erase committed purchases
    self.committedPurchaseCount[_receiver] = 0
    self.totalCommittedPurchaseCount -= receiverTokenCount

    log PurchaseCompleted(_receiver, receiverTokenCount)

@external
@nonreentrant('completePurchase')
def completePurchase(_receivers: DynArray[address, MAX_BATCH_SIZE]):
    """
    @dev Completes a purchase by minting the correct number of tokens and transferring them to the user.
    @param _receivers Array of receivers to complete purchase for, allows for batching.
    """
    assert self.isCompleted, "Cannot complete purchase if fundraiser is not completed"
    assert not self.isCancelled, "Cannot complete purchase if fundraiser is cancelled"

    for receiver in _receivers:
        self._completePurchase(receiver)

@internal
def _claimRefund(_receiver: address):
    """
    @dev Refunds funds for a committed purchase.
    @notice Assumes completed/cancelled checks have already been performed.
    @param _receiver Address of committed purchaser.
    """
    receiverTokenCount: uint256 = self.committedPurchaseCount[_receiver]

    assert receiverTokenCount > 0, "Cannot refund committment if user has no committed purchases left"

    totalRefund: uint256 = receiverTokenCount * FRACTION_PRICE

    selfPreDepositBalance: uint256 = ERC20(DEPOSIT_TOKEN_ERC20).balanceOf(self)

    ERC20(DEPOSIT_TOKEN_ERC20).transfer(_receiver, totalRefund)

    selfPostDepositBalance: uint256 = ERC20(DEPOSIT_TOKEN_ERC20).balanceOf(self)

    assert selfPreDepositBalance - selfPostDepositBalance == totalRefund, "Error during refund transfer"

    # erase committed purchases
    self.committedPurchaseCount[_receiver] = 0
    self.totalCommittedPurchaseCount -= receiverTokenCount

    log RefundClaimed(_receiver, receiverTokenCount)

@external
@nonreentrant('claimRefund')
def claimRefund(_receivers: DynArray[address, MAX_BATCH_SIZE]):
    """
    @dev Refunds a purchase by transferring deposit tokens back to the user.
    @param _receivers Array of receivers to refund purchase for, allows for batching.
    """
    assert not self.isCompleted, "Cannot refund purchase if fundraiser is completed"
    assert self.isCancelled, "Cannot refund purchase if fundraiser is not cancelled"

    for receiver in _receivers:
        self._claimRefund(receiver)

@external
def withdrawFunds(_to: address):
    """
    @dev Withdraws funds to `_to` address. Only callable by owner, and only if fundraiser is complete.
    @param _to Address that will receive all funds
    """
    assert msg.sender == self.owner, "Not admin"
    assert _to != ZERO_ADDRESS, "Don't burn funds"
    assert self.isCompleted, "Cannot withdraw from non-complete fundraiser"
    assert not self.isCancelled, "Cannot withdraw funds from cancelled fundraiser"

    balanceOfDepositToken: uint256 = ERC20(DEPOSIT_TOKEN_ERC20).balanceOf(self)

    ERC20(DEPOSIT_TOKEN_ERC20).transfer(_to, balanceOfDepositToken)