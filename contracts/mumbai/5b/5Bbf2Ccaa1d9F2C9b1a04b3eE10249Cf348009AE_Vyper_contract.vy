# @version ^0.3.7
# Multiple Signature Contract

event Deposit:
    sender: indexed(address)
    amount: uint256
    bal: uint256
event SubmitTransaction:
    owner: indexed(address)
    txIndex: indexed(uint256)
    to: indexed(address)
    value: uint256
    data: Bytes[256]
event ConfirmTransaction:
    owner: indexed(address)
    txIndex: indexed(uint256)
event RevokeConfirmation:
    owner: indexed(address)
    txIndex: indexed(uint256)
event ExecuteTransaction:
    owner: indexed(address)
    txIndex: indexed(uint256)

owners: DynArray[address, 100]
isOwner: HashMap[address, bool]
numConfirmationsRequired: uint256


struct Transaction: 
    to: address
    val: uint256
    data: Bytes[256]
    executed: bool
    numConfirmations: uint256

# Mapping from txIndex to a mapping of [address, bool], denoting the tx confirmation by a given address
isConfirmed: public(HashMap[uint256, HashMap[address, bool]])

# Dynamic Array with all the submitted transactions
# Shouldn't we be popping the transactions that have been executed from this array after the tx confirmation?
# The way it is now, there is a total of 10k txs that can be submitted using this multisig implementation (or is this not correct?)
transactions: DynArray[Transaction, 10000]


@external
def __init__ (_numConfirmationsRequired: uint256, _owners: DynArray[address,100]):
    assert len(_owners) > 0, "Error: No Owners"
    assert _numConfirmationsRequired > 0 and _numConfirmationsRequired <= len(_owners)
    self.numConfirmationsRequired = _numConfirmationsRequired
    for o in _owners:
        assert o != empty(address)
        assert self.isOwner[o] == False, "Owner Not Unique"
        self.isOwner[o] = True
        self.owners.append(o)

@external
@payable
def __default__():
    log Deposit(msg.sender, msg.value, self.balance)

@external
def submitTransaction( _to: address, _val: uint256, _data: Bytes[256]):
    assert self.isOwner[msg.sender] == True, "Not an Owner"
    txIndex: uint256 = len(self.transactions)
    self.transactions.append(Transaction({to:_to, val:_val, data: _data, executed: False, numConfirmations: 0}))    

@external 
def confirmTransaction(txIndex: uint256):
    assert self.isOwner[msg.sender]==True, "Not an Owner"
    assert txIndex < len(self.transactions), "Does Not Exist"
    assert self.transactions[txIndex].executed == False, "Transaction Already Executed"
    assert self.isConfirmed[txIndex][msg.sender] == False, "Transaction Already Confirmed"
    # increment the number of tx confirmations
    self.transactions[txIndex].numConfirmations += 1
    # take note of the msg sender signing the tx
    self.isConfirmed[txIndex][msg.sender] = True
    log ConfirmTransaction(msg.sender, txIndex)


@payable
@external
def executeTransaction(txIndex: uint256) -> Bytes[256]:
    assert self.isOwner[msg.sender]==True, "Not an Owner"
    assert txIndex < len(self.transactions), "Does Not Exist"
    assert self.transactions[txIndex].executed == False, "Transaction Already Executed"
    assert self.transactions[txIndex].numConfirmations >= self.numConfirmationsRequired, "Insufficent Confirmations"
    assert self.transactions[txIndex].val <= self.balance, "Insufficient multisig balance"
    # shouldn't this happen after the assert success?
    self.transactions[txIndex].executed = True
    success: bool = False
    response: Bytes[256] = b""
    success, response = raw_call(
        self.transactions[txIndex].to, 
        self.transactions[txIndex].data,
        max_outsize=256, # what's that?
        value = self.transactions[txIndex].val,
        revert_on_failure = False # what is this and why we need it to be False?
    )
    assert success
    # shouldn't we pop out the tx from self.transactions if it has been executed correctly?
    return response


@nonpayable
@external
def revokeConfirmation(_txIndex: uint256):
    assert _txIndex < len(self.transactions), "Does Not Exist"
    assert self.transactions[_txIndex].executed == False, "Transaction Already Executed"
    # added to the original: the non-owner can't revoke
    assert self.isOwner[msg.sender]==True, "Not an Owner"
    # decrement the number of tx confirmations
    # only if the msg sender has already signed the tx before
    assert self.isConfirmed[_txIndex][msg.sender] == True, "The owner has to sign first before being able to revoke the signature"
    self.transactions[_txIndex].numConfirmations -= 1
    self.isConfirmed[_txIndex][msg.sender] = False
    log RevokeConfirmation(msg.sender, _txIndex)

@view
@external
def getOwners() -> DynArray[address, 100]:
    return self.owners

@view
@external 
def getTransactionCount() -> uint256:
    return len(self.transactions)

@view
@external 
def getTransaction(_txIndex: uint256) -> (address, uint256, Bytes[256], bool, uint256):
    return(
        self.transactions[_txIndex].to,
        self.transactions[_txIndex].val,
        self.transactions[_txIndex].data,
        self.transactions[_txIndex].executed,
        self.transactions[_txIndex].numConfirmations
    )