# pragma ^0.0.33

# Interfaces

interface Fundraiser:
    def initialiseFundraiser(
        _owner: address,
        _depositTokenERC20: address,
        _assetTokenERC1155: address,
        _assetTokenIdERC1155: uint256,
        _fractionPrice: uint256,
        _totalFractions: uint256,
        _completionThreshold: uint256,
        _completionDeadline: uint256,
    ): nonpayable

interface ERC1155AccessControl:
    def grantRole(_role: bytes32, _to: address): nonpayable
    def MINTER_ROLE() -> bytes32: view

# State

ASSET_TOKEN_ERC1155: immutable(address)
TEMPLATE: immutable(address)

owner: public(address)
getFundraiser: public(HashMap[uint256, address])
getFundraiserId: public(HashMap[address, uint256])
fundraiserCount: public(uint256)

# Events

event FundraiserDeployed:
    id: uint256
    contract: address

event OwnershipTransferred:
    oldOwner: address
    newOwner: address

# Constructor

@external
def __init__(
    _assetTokenERC1155: address, # address of the Fraction contract
    _template: address           # address of the Fundraiser template contract
):
    ASSET_TOKEN_ERC1155 = _assetTokenERC1155
    TEMPLATE = _template
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
def createFundraiser(
    depositTokenERC20: address,
    assetTokenIdERC1155: uint256,
    fractionPrice: uint256,
    totalFractions: uint256,
    completionThreshold: uint256,
    completionDeadline: uint256,
) -> address:
    """
    @dev Creates a new fundraiser. Only callable by current owner. Sets owner of Factory as owner of Fundraiser.
    @param depositTokenERC20 Address of ERC20 deposit token, e.g. USDC
    @param assetTokenIdERC1155 Token ID
    @param fractionPrice Price 1 fraction per 1 unit of Deposit Token. Be careful with decimals.
    @param totalFractions Total number of fractions.
    @param completionThreshold 0-`totalFractions` threshold required to be allowed to complete
    @param completionDeadline Block number that sale must be completed by, or funds will be refunded. 0 means no deadline.
    """
    assert msg.sender == self.owner, "Not admin"

    # Because we increment first, there can never be a fundraiser with ID 0.
    # This means that if getFundraiserId(address) returns 0, the fundraiser is invalid
    self.fundraiserCount += 1

    fundraiserId: uint256 = self.fundraiserCount
    salt: bytes32 = convert(fundraiserId, bytes32)

    fundraiserAddress: address = create_forwarder_to(TEMPLATE, salt=salt)

    Fundraiser(fundraiserAddress).initialiseFundraiser(
        self.owner,
        depositTokenERC20,
        ASSET_TOKEN_ERC1155,
        assetTokenIdERC1155,
        fractionPrice,
        totalFractions,
        completionThreshold,
        completionDeadline,
    )

    ERC1155AccessControl(ASSET_TOKEN_ERC1155).grantRole(
        ERC1155AccessControl(ASSET_TOKEN_ERC1155).MINTER_ROLE(),
        fundraiserAddress,
    )

    self.getFundraiser[fundraiserId] = fundraiserAddress
    self.getFundraiserId[fundraiserAddress] = fundraiserId

    log FundraiserDeployed(fundraiserId, fundraiserAddress)

    return fundraiserAddress

@external
@view
def isValid(_address: address) -> bool:
    # See comment in createFundraiser
    if self.getFundraiserId[_address] == 0:
        return False

    return True

@external
@view
def getTemplate() -> address:
    return TEMPLATE

@external
@view
def getAssetToken() -> address:
    return ASSET_TOKEN_ERC1155