# @version 0.3.1
# from vyper.interfaces import ERC165
from vyper.interfaces import ERC721

implements: ERC721
# implements: ERC165

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
            _operator: address,
            _from: address,
            _tokenId: uint256,
            _data: Bytes[1024]
        ) -> bytes32: view


# @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
#      created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
#      number of NFTs may be created and assigned without emitting Transfer. At the time of any
#      transfer, the approved address for that NFT (if any) is reset to none.
# @param _from Sender of NFT (if address is zero address it indicates token creation).
# @param _to Receiver of NFT (if address is zero address it indicates token destruction).
# @param _tokenId The NFT that got transfered.
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    tokenId: indexed(uint256)

# @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
#      address indicates there is no approved address. When a Transfer event emits, this also
#      indicates that the approved address for that NFT (if any) is reset to none.
# @param _owner Owner of NFT.
# @param _approved Address that we are approving.
# @param _tokenId NFT which we are approving.
event Approval:
    owner: indexed(address)
    approved: indexed(address)
    tokenId: indexed(uint256)

# @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
#      all NFTs of the owner.
# @param _owner Owner of NFT.
# @param _operator Address to which we are setting operator rights.
# @param _approved Status of operator rights(true if operator rights are given and false if
# revoked).
event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool


# @dev Mapping from NFT ID to the address that owns it.
idToOwner: HashMap[uint256, address]

# @dev Mapping from owner address to count of his tokens.
ownerToNFTokenCount: HashMap[address, uint256]

# @dev Address of minter, who can mint a token
minter: address

allowance: public(HashMap[address, HashMap[address, uint256]])

# @dev Static list of supported ERC165 interface ids
SUPPORTED_INTERFACES: constant(bytes32[2]) = [
    # ERC165 interface ID of ERC165
    #0x01ffc9a7,
    0x0000000000000000000000000000000000000000000000000000000001ffc9a7,
    # ERC165 interface ID of ERC721
    #0x80ac58cd,
    0x0000000000000000000000000000000000000000000000000000000080ac58cd
]

@external
def __init__():
    """
    @dev Contract constructor.
    """
    self.minter = msg.sender


@pure
@external
def supportsInterface(interface_id: bytes32) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param interface_id Id of the interface
    """
    return interface_id in SUPPORTED_INTERFACES


### VIEW FUNCTIONS ###

@view
@external
def balanceOf(_owner: address) -> uint256:
    """
    @dev Returns the number of NFTs owned by `_owner`.
         Throws if `_owner` is the zero address. NFTs assigned to the zero address are considered invalid.
    @param _owner Address for whom to query the balance.
    """
    assert _owner != ZERO_ADDRESS
    return self.ownerToNFTokenCount[_owner]


@view
@external
def ownerOf(_tokenId: uint256) -> address:
    """
    @dev Returns the address of the owner of the NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId The identifier for an NFT.
    """
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    return owner


@view
@external
def getApproved(_tokenId: uint256) -> address:
    """
    @dev Get the approved address for a single NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId ID of the NFT to query the approval of.
    """
    # Throws if `_tokenId` is not a valid NFT
    assert self.idToOwner[_tokenId] != ZERO_ADDRESS
    return self.idToOwner[_tokenId]


@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    """
    @dev Checks if `_operator` is an approved operator for `_owner`.
    @param _owner The address that owns the NFTs.
    @param _operator The address that acts on behalf of the owner.
    """
    return False

### TRANSFER FUNCTION HELPERS ###

@internal
def _addTokenTo(_to: address, _tokenId: uint256):
    """
    @dev Add a NFT to a given address
         Throws if `_tokenId` is owned by someone.
    """
    # Throws if `_tokenId` is owned by someone
    assert self.idToOwner[_tokenId] == ZERO_ADDRESS
    # Change the owner
    self.idToOwner[_tokenId] = _to
    # Change count tracking
    self.ownerToNFTokenCount[_to] += 1


@internal
def _removeTokenFrom(_from: address, _tokenId: uint256):
    """
    @dev Remove a NFT from a given address
         Throws if `_from` is not the current owner.
    """
    # Throws if `_from` is not the current owner
    assert self.idToOwner[_tokenId] == _from
    # Change the owner
    self.idToOwner[_tokenId] = ZERO_ADDRESS
    # Change count tracking
    self.ownerToNFTokenCount[_from] -= 1


### TRANSFER FUNCTIONS ###

@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    assert False, "This is a non-transferrable Badge"


@external
def safeTransferFrom(
        _from: address,
        _to: address,
        _tokenId: uint256,
        _data: Bytes[1024]=b""
    ):
    assert False, "This is a non-transferrable Badge"


@external
def approve(_approved: address, _tokenId: uint256):
    assert False, "This is a non-transferrable Badge"


@external
def setApprovalForAll(_operator: address, _approved: bool):
    assert False, "This is a non-transferrable Badge"


### MINT & BURN FUNCTIONS ###

@external
def mint(_to: address, _tokenId: uint256) -> bool:
    """
    @dev Function to mint tokens
         Throws if `msg.sender` is not the minter.
         Throws if `_to` is zero address.
         Throws if `_tokenId` is owned by someone.
    @param _to The address that will receive the minted tokens.
    @param _tokenId The token id to mint.
    @return A boolean that indicates if the operation was successful.
    """
    # Throws if `msg.sender` is not the minter
    assert msg.sender == self.minter
    # Throws if `_to` is zero address
    assert _to != ZERO_ADDRESS
    # Add NFT. Throws if `_tokenId` is owned by someone
    self._addTokenTo(_to, _tokenId)
    log Transfer(ZERO_ADDRESS, _to, _tokenId)
    return True

@external
def mintBatch(_receivers: address[10], _startTokenId: uint256) -> bool:
    # Throws if `msg.sender` is not the minter
    assert msg.sender == self.minter

    for i in range(10):
        _to: address = _receivers[i]
        # Throws if `_to` is zero address
        assert _to != ZERO_ADDRESS
        _tokenId: uint256 = _startTokenId + i
        # Add NFT. Throws if `_tokenId` is owned by someone
        self._addTokenTo(_to, _tokenId)
        log Transfer(ZERO_ADDRESS, _to, _tokenId)

    return True        
    

@external
def burn(_tokenId: uint256):
    """
    @dev Burns a specific ERC721 token.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId uint256 id of the ERC721 token to be burned.
    """
    # Check requirements
    owner: address = self.idToOwner[_tokenId]
    assert owner == msg.sender
    # Throws if `_tokenId` is not a valid NFT
    assert owner != ZERO_ADDRESS
    self._removeTokenFrom(owner, _tokenId)
    log Transfer(owner, ZERO_ADDRESS, _tokenId)