# pragma ^0.0.33

# Interfaces

from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed

interface ERC1155:
    def mint(_account: address, _id: uint256, _amount: uint256, _data: Bytes[1024]): nonpayable

# Constants

MAX_BATCH_SIZE: constant(uint256) = 32

# State

owner: public(address)
depositTokenERC20: public(address)
assetTokenERC1155: public(address)
assetTokenIdERC1155: public(uint256)
fractionPrice: public(uint256)
totalFractions: public(uint256)
completionThreshold: public(uint256)
completionDeadline: public(uint256)
committedPurchaseCount: public(HashMap[address, uint256])
totalCommittedPurchaseCount: public(uint256)
isInitialised: public(bool)
isCompleted: public(bool)
isCancelled: public(bool)

# Events

event FundraiserInitialised: pass

event FundraiserCompleted: pass

event FundraiserCancelled: pass

event PurchaseCommitted:
    purchaser: indexed(address)
    commitmentCount: uint256

event PurchaseCompleted:
    purchaser: indexed(address)
    purchaseCount: uint256

event RefundClaimed:
    purchaser: indexed(address)
    refundCount: uint256

event OwnershipTransferred:
    oldOwner: address
    newOwner: address

event FundsWithdrawn:
    fundsReceiver: address

# Constructor and initialise function

@external
def initialiseFundraiser(
    _owner: address,
    _depositTokenERC20: address,
    _assetTokenERC1155: address,
    _assetTokenIdERC1155: uint256,
    _fractionPrice: uint256,
    _totalFractions: uint256,
    _completionThreshold: uint256,
    _completionDeadline: uint256,
):
    """
    @dev Initialised fundraiser.
    @param _owner Address to set as Owner
    @param _depositTokenERC20 Address of ERC20 deposit token, e.g. USDC
    @param _assetTokenERC1155 Address of Fraction contract
    @param _assetTokenIdERC1155 Token ID
    @param _fractionPrice Price 1 fraction per 1 unit of Deposit Token. Be careful with decimals.
    @param _totalFractions Total number of fractions.
    @param _completionThreshold 0-`totalFractions` threshold required to be allowed to complete
    @param _completionDeadline Block number that sale must be completed by, or funds will be refunded. 0 means no deadline.
    """
    self.owner = _owner
    self.depositTokenERC20 = _depositTokenERC20
    self.assetTokenERC1155 = _assetTokenERC1155
    self.assetTokenIdERC1155 = _assetTokenIdERC1155
    self.fractionPrice = _fractionPrice
    self.totalFractions = _totalFractions
    self.completionThreshold = _completionThreshold
    self.completionDeadline = _completionDeadline
    self.isInitialised = True
    log FundraiserInitialised()

# Functions

## ERC20 safe transfer functions
# HACK: Used to handle non-compliant tokens like USDT
@internal
def erc20SafeTransferFrom(_token: address, _sender: address, _receiver: address, _amount: uint256):
    response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transferFrom(address,address,uint256)"),
            convert(_sender, bytes32),
            convert(_receiver, bytes32),
            convert(_amount, bytes32),
        ),
        max_outsize=32,
    )
    if len(response) > 0:
        assert convert(response, bool), "Transfer failed!"

@internal
def erc20SafeTransfer(_token: address, _to: address, _value: uint256) -> bool:
    response: Bytes[32] = raw_call(
        _token,
        concat(
            method_id("transfer(address,uint256)"),
            convert(_to, bytes32),
            convert(_value, bytes32)
        ),
        max_outsize=32
    )
    if len(response) > 0:
        assert convert(response, bool), "Transfer failed!"
    return True

@external
def transferOwnership(_to: address):
    """
    @dev Transfers ownership from current owner to `to`. Only callable by current owner.
    @param _to The address to transfer ownership to.
    """
    assert self.isInitialised, "Not initialised"
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
    assert self.isInitialised, "Not initialised"
    assert msg.sender == self.owner, "Not admin"
    assert not self.isCompleted, "Cannot complete twice"
    assert not self.isCancelled, "Cannot complete cancelled fundraiser"
    assert (self.completionDeadline == 0) or (block.number <= self.completionDeadline), "Deadline passed already"
    assert self.totalCommittedPurchaseCount >= self.completionThreshold, "Threshold not met"

    self.isCompleted = True
    
    log FundraiserCompleted()

@external
def cancelFundraiser():
    """
    @dev Marks fundraiser as cancelled, allows refunding of user funds. Only callable by owner.
    """
    assert self.isInitialised, "Not initialised"
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
    assert self.isInitialised, "Not initialised"
    assert not self.isCancelled, "Cannot deposit in cancelled fundraiser"
    assert not self.isCompleted, "Cannot deposit in completed fundraiser"
    assert self.totalCommittedPurchaseCount + _count <= self.totalFractions, "Cannot purchase more than total fractions"
    assert (self.completionDeadline == 0) or (block.number <= self.completionDeadline), "Deadline passed already"
    
    totalDeposit: uint256 = _count * self.fractionPrice

    selfPreDepositBalance: uint256 = ERC20(self.depositTokenERC20).balanceOf(self)

    self.erc20SafeTransferFrom(self.depositTokenERC20, msg.sender, self, totalDeposit)

    selfPostDepositBalance: uint256 = ERC20(self.depositTokenERC20).balanceOf(self)

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

    ERC1155(self.assetTokenERC1155).mint(_receiver, self.assetTokenIdERC1155, receiverTokenCount, b"0x")

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
    assert self.isInitialised, "Not initialised"
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

    totalRefund: uint256 = receiverTokenCount * self.fractionPrice

    selfPreDepositBalance: uint256 = ERC20(self.depositTokenERC20).balanceOf(self)

    self.erc20SafeTransfer(self.depositTokenERC20, _receiver, totalRefund)

    selfPostDepositBalance: uint256 = ERC20(self.depositTokenERC20).balanceOf(self)

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
    assert self.isInitialised, "Not initialised"
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
    assert self.isInitialised, "Not initialised"
    assert msg.sender == self.owner, "Not admin"
    assert _to != ZERO_ADDRESS, "Don't burn funds"
    assert self.isCompleted, "Cannot withdraw from non-complete fundraiser"
    assert not self.isCancelled, "Cannot withdraw funds from cancelled fundraiser"

    balanceOfDepositToken: uint256 = ERC20(self.depositTokenERC20).balanceOf(self)

    ERC20(self.depositTokenERC20).transfer(_to, balanceOfDepositToken)