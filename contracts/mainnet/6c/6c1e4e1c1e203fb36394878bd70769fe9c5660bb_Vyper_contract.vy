# @version 0.3.2

# Event for logging that funding has been sent
event FundingSent:
    recipient: address
    amount: uint256

event ToppedUp:
    amount: uint256


struct FishfoodFundingStatus:
    authorized: bool
    isAdmin: bool
    timestampOfLastCall: uint256

upperRequestLimit: public(uint256)
lowerRequestLimit: public(uint256)
balanceLimit: public(uint256)
adminCount: public(uint256)
upperGasLimit: public(uint256)

fishFoodFundingStatus: HashMap[address, FishfoodFundingStatus]

@external
def __init__():
    self.upperRequestLimit = 300000000000000000
    self.lowerRequestLimit = 50000000000000000
    self.balanceLimit = 150000000000000000
    self.upperGasLimit = 30000000000
    self.fishFoodFundingStatus[msg.sender].isAdmin = True
    self.adminCount = 1

@external
@view
def getUpperRequestLimit() -> uint256:
    return self.upperRequestLimit

@external
@view
def getLowerRequestLimit() -> uint256:
    return self.lowerRequestLimit

@external
@view
def getBalanceLimit() -> uint256:
    return self.balanceLimit

@external
@view
def getAdminCount() -> uint256:
    return self.adminCount

@external
@view
def getGasLimit() -> uint256:
    return self.upperGasLimit

@external
def getFunding(amountRequested: uint256):
    # Only permit authorized addresses to receive fishfood funding.
    assert self.fishFoodFundingStatus[msg.sender].authorized, "TooBad"
    # Revert with a useful message if the contract is broke.
    assert amountRequested < self.balance, "TooDepleted"
    # Don't be greedy.
    assert amountRequested <= self.upperRequestLimit, "TooMuch"
    # Don't get confused by wei vs ETH.
    assert amountRequested >= self.lowerRequestLimit, "TooLittle"
    # Don't be out here spending 10 bucks to request 11.
    assert tx.gasprice <= self.upperGasLimit, "TooExpensive"
    # Don't ask for money if you already have a lot.
    assert msg.sender.balance <= self.balanceLimit, "TooRich"
    # Only permit one request every week.
    assert self.fishFoodFundingStatus[msg.sender].timestampOfLastCall + 604800 <= block.timestamp, "TooSoon"

    # Update the last request block timestamp.
    self.fishFoodFundingStatus[msg.sender].timestampOfLastCall = block.timestamp

    # Emit an event for more convenient accounting.
    log FundingSent(msg.sender, amountRequested)

    # If all the checks pass, send the funds.
    send(msg.sender, amountRequested)

@external
def setUpperRequestLimit(newLimit: uint256):
    # Only permit authorized addresses to set the upper request limit.
    assert self.fishFoodFundingStatus[msg.sender].isAdmin, "TooBad"

    # Set the upper request limit.
    self.upperRequestLimit = newLimit

@external
def setLowerRequestLimit(newLimit: uint256):
    # Only permit authorized addresses to set the lower request limit.
    assert self.fishFoodFundingStatus[msg.sender].isAdmin, "TooBad"

    # Set the lower request limit.
    self.lowerRequestLimit = newLimit

@external
def setBalanceLimit(newLimit: uint256):
    # Only permit authorized addresses to set the balance limit.
    assert self.fishFoodFundingStatus[msg.sender].isAdmin, "TooBad"

    # Set the balance limit.
    self.balanceLimit = newLimit

@external
def setGasLimit(newLimit: uint256):
    # Only permit authorized addresses to set the gas limit.
    assert self.fishFoodFundingStatus[msg.sender].isAdmin, "TooBad"

    # Set the gas limit.
    self.upperGasLimit = newLimit

@external
def authorizeAddress(addressToAuthorize: address):
    # Only permit authorized addresses to authorize.
    assert self.fishFoodFundingStatus[msg.sender].isAdmin, "TooBad"

    # Only permit authorizing addresses that haven't already been authorized.
    assert not self.fishFoodFundingStatus[addressToAuthorize].authorized, "AlreadyAuthorized"

    # Authorize the address.
    self.fishFoodFundingStatus[addressToAuthorize].authorized = True

@internal
def _authorizeAddress(addressToAuthorize: address):
    # Authorize the address.
    self.fishFoodFundingStatus[addressToAuthorize].authorized = True


@external
def batchAuthorizeAddresses(addressesToAuthorize: address[8]):
    # Only permit authorized addresses to authorize.
    assert self.fishFoodFundingStatus[msg.sender].isAdmin, "TooBad"
    
    for i in range(8):
        self._authorizeAddress(addressesToAuthorize[i])

@external
def deauthorizeAddress(addressToDeauthorize: address):
    # Only permit authorized addresses to deauthorize.
    assert self.fishFoodFundingStatus[msg.sender].isAdmin, "TooBad"

    # Only permit deauthorizing addresses that have already been authorized.
    assert self.fishFoodFundingStatus[addressToDeauthorize].authorized, "AlreadyDeauthorized"

    # Deauthorize the address.
    self.fishFoodFundingStatus[addressToDeauthorize].authorized = False

@internal
def _deauthorizeAddress(addressToDeauthorize: address):
    # Deauthorize the address.
    self.fishFoodFundingStatus[addressToDeauthorize].authorized = False

@external
def batchDeauthorizeAddresses(addressesToDeauthorize: address[8]):
    # Only permit authorized addresses to deauthorize.
    assert self.fishFoodFundingStatus[msg.sender].isAdmin, "TooBad"

    for i in range(8):
        self._deauthorizeAddress(addressesToDeauthorize[i])

@external
def addAdmin(addressToAdd: address):
    # Only permit authorized addresses to add admins.
    assert self.fishFoodFundingStatus[msg.sender].isAdmin, "TooBad"

    # Add the address.
    self.fishFoodFundingStatus[addressToAdd].isAdmin = True

    # Increment the admin count.
    self.adminCount += 1

@external
def removeAdmin(addressToRemove: address):
    # Only permit authorized addresses to remove admins.
    assert self.fishFoodFundingStatus[msg.sender].isAdmin, "TooBad"

    # Remove the address.
    self.fishFoodFundingStatus[addressToRemove].isAdmin = False

    # Decrement the admin count.
    self.adminCount -= 1

# @external
# @view
# def isAdmin(addressToCheck: address) -> bool:
#     return self.fishFoodFundingStatus[addressToCheck].isAdmin

@external
@view
def isAuthorized(addressToCheck: address) -> bool:
    return self.fishFoodFundingStatus[addressToCheck].authorized

@external
@view
def lastRequestTimestamp(addressToCheck: address) -> uint256:
    return self.fishFoodFundingStatus[addressToCheck].timestampOfLastCall

@external
def withdraw():
    # Only permit authorized addresses to withdraw.
    assert self.fishFoodFundingStatus[msg.sender].isAdmin, "TooBad"

    # Withdraw the funds.
    send(msg.sender, self.balance)

@external
@payable
def __default__():
    log ToppedUp(msg.value)