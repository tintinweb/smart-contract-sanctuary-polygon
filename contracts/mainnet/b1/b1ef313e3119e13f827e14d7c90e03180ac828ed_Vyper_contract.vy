# @version 0.3.7

"""
@title Bare-bones Token implementation
@notice
    Based on the ERC-20 token standard as defined at
    https://github.com/ethereum/EIPs/issues/20
"""

from vyper.interfaces import ERC20

implements: ERC20

# ERC20 Token Metadata
NAME: constant(String[20]) = "Cloud AUD"
SYMBOL: constant(String[5]) = "CAUD"
DECIMALS: constant(uint8) = 8


# batchTransfer defaults for gas accounting.

# Use to reserve remaining gas in case calling from contract that needs to do more
# things. 30,000 gas is roughly one function call.
MIN_GAS_REMAINING: constant(uint256) = 30000

# Max size of batchTransfer payment batches.
MAX_PAYMENTS: constant(uint256) = 200

# Initial estimate of the cost for a single payment transfer.
EST_GAS_PER_TRANSFER: constant(uint256) = 35600


# ERC20 State Variables
totalSupply: public(uint256)
balanceOf: public(HashMap[address, uint256])
allowance: public(HashMap[address, HashMap[address, uint256]])


# Events
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    amount: uint256

event OwnershipTransfer:
    previousOwner: indexed(address)
    newOwner: indexed(address)

event BatchTransfer:
    sender: indexed(address)
    sender_balance: uint256
    tx_count: uint256
    tx_value: uint256
    gas_per_tx: uint256
    gas_exhausted: bool

event MinterTransfer:
    previousMinter: indexed(address)
    newMinter: indexed(address)


owner: public(address)
minter: public(address)


@external
def __init__():
    self.owner = msg.sender
    self.minter = msg.sender
    self.totalSupply = 0


@pure
@external
def name() -> String[20]:
    return NAME


@pure
@external
def symbol() -> String[5]:
    return SYMBOL


@pure
@external
def decimals() -> uint8:
    return DECIMALS


@external
def transfer(receiver: address, amount: uint256) -> bool:
    """
    @notice Transfers an amount of tokens from the caller to the receiver, if caller's
        token balance allows.
    @param receiver The address for the tokens to be sent to.
    @param amount The amount of tokens to be transferred, in raw integer format.
    """
    assert receiver != empty(address), "Cannot transfer to null address."
    self.balanceOf[msg.sender] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(msg.sender, receiver, amount)
    return True


# Payment structure - compose an array of no more than MAX_PAYMENTS of these.
# Do not allow any receiver addresses to be 0 address as burns are not allowed.
struct Payment:
    receiver: address
    amount: uint256


@external
def batchTransfer(
    payments: DynArray[Payment, MAX_PAYMENTS],
    min_gas_remaining: uint256 = MIN_GAS_REMAINING
) -> uint256:
    """
    @notice Saves gas fees by batching multiple transfers from a single
        address into one tx. Performs gas accounting to safely execute
        as many txs in the batch as possible without hitting gas exhaustion
        forcing a tx revert.

        Publishes one Transfer event per payment processed.

        Publishes one BatchTransfer event at the end reporting the sending
        wallet address, its remaining balance, how many payments were transferred,
        the total value, the max per transfer gas, and whether or not the batch had
        left over payments due to gas exhaustion.

    @param payments A DynArray of payments. See struct above.

    @param min_gas_remaining In order to support gas-safe calls from other smart
        contracts, this function takes a min_gas_remaining parameter so batchTransfer's
        gas accounting will ensure at least that qty of gas remains for any follow on
        functions that the calling contract may need to finish its own processing.
        This saves client code from having to do lots of complex and non-deterministic
        gas accounting of its own before sending batches.

    @return a uint of how many transactions were sent. batchTransfer will attempt to
        make as many payments from the batch as possible with the gas budget available.
        It is up to the caller to manage resubmitting any payments that did not get
        processed in the initial batch.
    """
    pay_count: uint256 = 0
    pay_value: uint256 = 0
    per_transfer_cost: uint256 = EST_GAS_PER_TRANSFER
    gas_remaining: uint256 = msg.gas
    gas_exhausted: bool = False

    sender_balance: uint256 = self.balanceOf[msg.sender]

    for payment in payments:
        # Break if we don't have sufficient gas.
        if msg.gas < (min_gas_remaining + per_transfer_cost):
            gas_exhausted = True
            break

        # We're complete if any receiver is a zero address.
        if payment.receiver == empty(address):
            break

        # End if insufficient funds remaining during the batch.
        if sender_balance < payment.amount:
            break

        # If sender & receiver are different addresses then do the math.
        if msg.sender != payment.receiver:
            sender_balance -= payment.amount
            self.balanceOf[payment.receiver] += payment.amount

        # Send one Transfer event per successful payment.
        log Transfer(msg.sender, payment.receiver, payment.amount)

        pay_count += 1
        pay_value += payment.amount

        if per_transfer_cost == EST_GAS_PER_TRANSFER:
            per_transfer_cost = gas_remaining - msg.gas
        if per_transfer_cost < gas_remaining - msg.gas:
            per_transfer_cost = gas_remaining - msg.gas
        gas_remaining = msg.gas

    if pay_value > 0:
        self.balanceOf[msg.sender] = sender_balance

    # Report the final disposition for this Payment batch.
    log BatchTransfer(
        msg.sender,
        self.balanceOf[msg.sender],
        pay_count,
        pay_value,
        per_transfer_cost,
        gas_exhausted
    )

    return pay_count


@external
def transferFrom(sender: address, receiver: address, amount: uint256) -> bool:
    """
    @notice
        Similar to transfer, but used for allowing contracts to send tokens on your
        behalf. For example a decentralized exchange would make use of this method,
        once given authorization via the approve method.
    """
    assert receiver != empty(address), "Cannot transfer to null address."
    self.allowance[sender][msg.sender] -= amount
    self.balanceOf[sender] -= amount
    self.balanceOf[receiver] += amount

    log Transfer(sender, receiver, amount)
    return True


@external
def approve(spender: address, amount: uint256) -> bool:
    """
    @param spender The address that will execute on owner behalf.
    @param amount The amount of token to be transfered.
    """
    self.allowance[msg.sender][spender] = amount

    log Approval(msg.sender, spender, amount)
    return True


@external
def burn(amount: uint256) -> bool:
    """
    @notice Burns the supplied amount of tokens from the sender wallet.
    @param amount The amount of token to be burned.
    @return A boolean that indicates if the operation was successful.
    """
    assert self.balanceOf[msg.sender] >= amount, "Burn amount exceeds balance."

    self.balanceOf[msg.sender] -= amount
    self.totalSupply -= amount

    log Transfer(msg.sender, empty(address), amount)
    return True


@external
def mint(receiver: address, amount: uint256) -> bool:
    """
    @notice Function to mint new tokens.
    @param receiver The address that will receive the minted tokens.
    @param amount The amount of tokens to mint.
    @return A boolean that indicates if the operation was successful.
    """
    assert msg.sender == self.minter, "Access denied."
    assert receiver != empty(address), "Cannot mint to null address."

    self.totalSupply += amount
    self.balanceOf[receiver] += amount

    log Transfer(empty(address), receiver, amount)
    return True


@external
def transferOwnership(target: address) -> bool:
    """
    @notice Function to transfer ownership from one address to another.
    @param target Address of the new owner.
    @return A boolean that indicates if the operation was successful.
    """
    assert msg.sender == self.owner, "Access denied."
    assert target != empty(address), "Cannot add null address as owner."

    self.owner = target

    log OwnershipTransfer(msg.sender, target)
    return True


@external
def transferMinter(target: address) -> bool:
    """
    @notice Function to transfer minter role from one address to another.
    @param target Address of the new minter.
    @return A boolean that indicates if the operation was successful.
    """
    assert msg.sender == self.owner, "Access denied."
    assert target != empty(address), "Cannot add null address as minter."

    previous_minter: address = self.minter
    self.minter = target

    log MinterTransfer(previous_minter, target)
    return True