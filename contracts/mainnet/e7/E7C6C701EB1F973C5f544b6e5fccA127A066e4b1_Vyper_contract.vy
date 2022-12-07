# @version 0.3.6

from vyper.interfaces import ERC165
from vyper.interfaces import ERC721

implements: ERC721
implements: ERC165

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
            _operator: address,
            _from: address,
            _tokenId: uint256,
            _data: Bytes[1024]
        ) -> bytes4: view


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

# @dev Mapping from NFT ID to approved address.
idToApprovals: HashMap[uint256, address]

# @dev Mapping from owner address to count of his tokens.
ownerToNFTokenCount: HashMap[address, uint256]

# @dev Mapping from owner address to mapping of operator addresses.
ownerToOperators: HashMap[address, HashMap[address, bool]]

# @dev Address of main minter, who owns the contract
minter: public(address)

# @dev Address of allowed minters, who can mint a token
allowedMinters: public(address[20])

# @dev The base URL used to generate the token uri for a given token Id. 
baseURI: String[100]

# @dev The contract name (ERC721 Metadata)
name: public(String[64])

# @dev The contract symbol (ERC721 Metadata)
symbol: public(String[32])

# @dev Mapping from NFT ID to the Slot it can be applied on a PX Avatar. 
tokenIdToSlot: public(HashMap[uint256, uint256])

# @dev Total Supply of NFTs used to auto-increment NFT IDs
totalSupply: public(uint256)

# @dev Percentage fee with 2 decimal precision 1% = 100
royaltyFee: public(uint256)

# @dev Static list of supported ERC165 interface ids
SUPPORTED_INTERFACES: constant(bytes4[4]) = [
    0x01ffc9a7,  # ERC165 interface ID of ERC165
    0x80ac58cd,  # ERC165 interface ID of ERC721
    0x5b5e139f,  # ERC165 interface ID of ERC721 Metadata Extension
    0x2a55205a,  # ERC165 interface ID of ERC2981
]

IDENTITY_PRECOMPILE: constant(address) = 0x0000000000000000000000000000000000000004

@external
def __init__():
    """
    @dev Contract constructor.
    """
    self.minter = msg.sender
    self.baseURI = "https://zumbi.herokuapp.com/api/metadata/"
    self.symbol = "PXI"
    self.name = "FURIA PX Items"
    self.royaltyFee = 800

@pure
@external
def supportsInterface(interface_id: bytes4) -> bool:
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
    assert _owner != empty(address)
    return self.ownerToNFTokenCount[_owner]


@view
@external
def ownerOf(_tokenId: uint256) -> address:
    """
    @dev Returns the address of the owner of the NFT.
    @param _tokenId The identifier for an NFT.
    """
    owner: address = self.idToOwner[_tokenId]
    return owner

@view
@external
def owner() -> address:
    """
    @dev Returns the address of the owner of the Contract.
    """
    return self.minter


@view
@external
def getApproved(_tokenId: uint256) -> address:
    """
    @dev Get the approved address for a single NFT.
         Throws if `_tokenId` is not a valid NFT.
    @param _tokenId ID of the NFT to query the approval of.
    """
    # Throws if `_tokenId` is not a valid NFT
    assert self.idToOwner[_tokenId] != empty(address)
    return self.idToApprovals[_tokenId]


@view
@external
def isApprovedForAll(_owner: address, _operator: address) -> bool:
    """
    @dev Checks if `_operator` is an approved operator for `_owner`.
    @param _owner The address that owns the NFTs.
    @param _operator The address that acts on behalf of the owner.
    """
    return (self.ownerToOperators[_owner])[_operator]


### TRANSFER FUNCTION HELPERS ###

@view
@internal
def _isApprovedOrOwner(_spender: address, _tokenId: uint256) -> bool:
    """
    @dev Returns whether the given spender can transfer a given token ID
    @param spender address of the spender to query
    @param tokenId uint256 ID of the token to be transferred
    @return bool whether the msg.sender is approved for the given token ID,
        is an operator of the owner, or is the owner of the token
    """
    owner: address = self.idToOwner[_tokenId]
    spenderIsOwner: bool = owner == _spender
    spenderIsApproved: bool = _spender == self.idToApprovals[_tokenId]
    spenderIsApprovedForAll: bool = (self.ownerToOperators[owner])[_spender]
    return (spenderIsOwner or spenderIsApproved) or spenderIsApprovedForAll


@internal
def _addTokenTo(_to: address, _tokenId: uint256):
    """
    @dev Add a NFT to a given address
         Throws if `_tokenId` is owned by someone.
    """
    # Throws if `_tokenId` is owned by someone
    assert self.idToOwner[_tokenId] == empty(address)
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
    self.idToOwner[_tokenId] = empty(address)
    # Change count tracking
    self.ownerToNFTokenCount[_from] -= 1


@internal
def _clearApproval(_owner: address, _tokenId: uint256):
    """
    @dev Clear an approval of a given address
         Throws if `_owner` is not the current owner.
    """
    # Throws if `_owner` is not the current owner
    assert self.idToOwner[_tokenId] == _owner
    if self.idToApprovals[_tokenId] != empty(address):
        # Reset approvals
        self.idToApprovals[_tokenId] = empty(address)


@internal
def _transferFrom(_from: address, _to: address, _tokenId: uint256, _sender: address):
    """
    @dev Exeute transfer of a NFT.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT. (NOTE: `msg.sender` not allowed in private function so pass `_sender`.)
         Throws if `_to` is the zero address.
         Throws if `_from` is not the current owner.
         Throws if `_tokenId` is not a valid NFT.
    """
    # Check requirements
    assert self._isApprovedOrOwner(_sender, _tokenId)
    # Throws if `_to` is the zero address
    assert _to != empty(address)
    # Clear approval. Throws if `_from` is not the current owner
    self._clearApproval(_from, _tokenId)
    # Remove NFT. Throws if `_tokenId` is not a valid NFT
    self._removeTokenFrom(_from, _tokenId)
    # Add NFT
    self._addTokenTo(_to, _tokenId)
    # Log the transfer
    log Transfer(_from, _to, _tokenId)


### TRANSFER FUNCTIONS ###

@external
def transferFrom(_from: address, _to: address, _tokenId: uint256):
    """
    @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `_from` is not the current owner.
         Throws if `_to` is the zero address.
         Throws if `_tokenId` is not a valid NFT.
    @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
            they maybe be permanently lost.
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _tokenId The NFT to transfer.
    """
    self._transferFrom(_from, _to, _tokenId, msg.sender)


@external
def safeTransferFrom(
        _from: address,
        _to: address,
        _tokenId: uint256,
        _data: Bytes[1024]=b""
    ):
    """
    @dev Transfers the ownership of an NFT from one address to another address.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the
         approved address for this NFT.
         Throws if `_from` is not the current owner.
         Throws if `_to` is the zero address.
         Throws if `_tokenId` is not a valid NFT.
         If `_to` is a smart contract, it calls `onERC721Received` on `_to` and throws if
         the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    @param _from The current owner of the NFT.
    @param _to The new owner.
    @param _tokenId The NFT to transfer.
    @param _data Additional data with no specified format, sent in call to `_to`.
    """
    self._transferFrom(_from, _to, _tokenId, msg.sender)
    if _to.is_contract: # check if `_to` is a contract address
        returnValue: bytes4 = ERC721Receiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data)
        mid: Bytes[4] = method_id("onERC721Received(address,address,uint256,bytes)", output_type=Bytes[4])
        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert returnValue == convert(mid, bytes4)


@external
def approve(_approved: address, _tokenId: uint256):
    """
    @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
         Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
         Throws if `_tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
         Throws if `_approved` is the current owner. (NOTE: This is not written the EIP)
    @param _approved Address to be approved for the given NFT ID.
    @param _tokenId ID of the token to be approved.
    """
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != empty(address)
    # Throws if `_approved` is the current owner
    assert _approved != owner
    # Check requirements
    senderIsOwner: bool = self.idToOwner[_tokenId] == msg.sender
    senderIsApprovedForAll: bool = (self.ownerToOperators[owner])[msg.sender]
    assert (senderIsOwner or senderIsApprovedForAll)
    # Set the approval
    self.idToApprovals[_tokenId] = _approved
    log Approval(owner, _approved, _tokenId)


@external
def setApprovalForAll(_operator: address, _approved: bool):
    """
    @dev Enables or disables approval for a third party ("operator") to manage all of
         `msg.sender`'s assets. It also emits the ApprovalForAll event.
         Throws if `_operator` is the `msg.sender`. (NOTE: This is not written the EIP)
    @notice This works even if sender doesn't own any tokens at the time.
    @param _operator Address to add to the set of authorized operators.
    @param _approved True if the operators is approved, false to revoke approval.
    """
    # Throws if `_operator` is the `msg.sender`
    assert _operator != msg.sender
    self.ownerToOperators[msg.sender][_operator] = _approved
    log ApprovalForAll(msg.sender, _operator, _approved)


### MINT & BURN FUNCTIONS ###

@internal
def _mint_one(_to: address, _slot: uint256) -> bool:
    _tokenId: uint256 = self.totalSupply + 1 
    self._addTokenTo(_to, _tokenId)
    # Store the slot for that `_tokenId` 
    self.tokenIdToSlot[_tokenId] = _slot
    self.totalSupply += 1 
    log Transfer(empty(address), _to, _tokenId)
    return True


@external
def mint(_to: address, _slot: uint256) -> bool:
    """
    @dev Function to mint tokens
         Throws if `msg.sender` is not the minter.
         Throws if `_to` is zero address.
         Throws if `_slot` is not between 1 and 10 
    @param _to The address that will receive the minted tokens.
    @param _slot The Slot this item occupies when applied to a PX Avatar (between 1 and 10).
    @return A boolean that indicates if the operation was successful.
    """
    # Throws if `msg.sender` is not the minter
    assert msg.sender == self.minter
    # Throws if `_to` is zero address
    assert _to != empty(address)
    # Throws if `_slot` is not between 1 and 10 
    assert _slot > 0 and _slot <= 10, "Slot must be between 1 and 10"
    # Mint NFT
    return self._mint_one(_to, _slot)


@external 
def mintDrop(_to: address, _slot: uint256) -> bool:
    """
    @dev Function to batch mint 100 tokens
         Throws if `msg.sender` is not the minter
         Throws if `_to` is zero address.
         Throws if `_slot` is not between 1 and 10 
    @param _to The address that will receive the minted tokens.
    @param _slot The slot (1 to 10) this item can equip.
    @return A boolean that indicates if the operation was successful.
    """
    # Throws if `msg.sender` is not the minter
    assert msg.sender == self.minter or msg.sender in self.allowedMinters
    # Throws if `_to` is zero address
    assert _to != empty(address)
    assert _slot > 0 and _slot < 11, "Invalid slot number"
    for i in range(100):
        self._mint_one(_to, _slot)
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
    assert self._isApprovedOrOwner(msg.sender, _tokenId)
    owner: address = self.idToOwner[_tokenId]
    # Throws if `_tokenId` is not a valid NFT
    assert owner != empty(address)
    self._clearApproval(owner, _tokenId)
    self._removeTokenFrom(owner, _tokenId)
    log Transfer(owner, empty(address), _tokenId)


@external
def transferOwnership(_owner: address) -> bool:
    """
    @dev Function to transfer the contract ownership to a new address
    @param _owner The new contract owner
    @return A boolean that indicates if the operation was successful.
    """
    assert self.minter == msg.sender, "The sender must be the minter"
    self.minter = _owner
    return True


@pure
@internal
def _uint_to_string(_value: uint256) -> String[78]:
    """
    @dev skelletOr
    reference: https://github.com/curvefi/curve-veBoost/blob/0e51be10638df2479d9e341c07fafa940ef58596/contracts/VotingEscrowDelegation.vy#L423
    """
    # NOTE: Odd that this works with a raw_call inside, despite being marked
    # a pure function
    if _value == 0:
        return "0"

    buffer: Bytes[78] = b""
    digits: uint256 = 78

    for i in range(78):
        # go forward to find the # of digits, and set it
        # only if we have found the last index
        if digits == 78 and _value / 10 ** i == 0:
            digits = i

        value: uint256 = ((_value / 10 ** (77 - i)) % 10) + 48
        char: Bytes[1] = slice(convert(value, bytes32), 31, 1)
        buffer = raw_call(
            IDENTITY_PRECOMPILE,
            concat(buffer, char),
            max_outsize=78,
            is_static_call=True
        )

    return convert(slice(buffer, 78 - digits, digits), String[78])

@view
@external
def tokenURI(tokenId: uint256) -> String[179]:
    return concat(self.baseURI, self._uint_to_string(tokenId))


@external
def changeBaseURI(_baseURI: String[100]) -> bool:
    """
    @dev Function to change the base URI to a new string
    @param _baseURI The new contract uri
    @return A boolean that indicates if the operation was successful.
    """
    assert self.minter == msg.sender, "The sender must be the minter"
    self.baseURI = _baseURI
    return True

@external
def allowMinter(_minter: address) -> bool:
    """
    @dev Function to allow a new minter 
         Throws if `msg.sender` is not the main minter.
         Throws if `_minter` is zero address.
         Throws if `_minter` is already allowed 
    @param _minter The address that will be allowed to mint tokens.
    @return A boolean that indicates if the operation was successful.
    """
    # Throws if `msg.sender` is not the minter
    assert msg.sender == self.minter
    # Throws if `_to` is zero address
    assert _minter != empty(address)
    # Throws if `_minter` is already allowed 
    assert not (_minter in self.allowedMinters)

    for i in range(20):
        if self.allowedMinters[i] == empty(address):
            self.allowedMinters[i] = _minter
            return True

    return False
    
@external
def disallowMinter(_minter: address) -> bool:
    """
    @dev Function to allow a new minter 
         Throws if `msg.sender` is not the main minter.
         Throws if `_minter` is zero address.
         Throws if `_minter` is not already allowed 
    @param _minter The address that will be allowed to mint tokens.
    @return A boolean that indicates if the operation was successful.
    """
    # Throws if `msg.sender` is not the minter
    assert msg.sender == self.minter
    # Throws if `_to` is zero address
    assert _minter != empty(address)
    # Throws if `_minter` is not already allowed 
    assert _minter in self.allowedMinters
    
    current: uint256 = 0
    last: uint256 = 19

    for i in range(20):
        if self.allowedMinters[i] == _minter:
            self.allowedMinters[i] = empty(address)
            current = i 
        elif self.allowedMinters[i] == empty(address):
            last = i - 1 

    self.allowedMinters[current] = self.allowedMinters[last]
    return False


### ROYALTIES ###

@view
@external
def royaltyInfo(_tokenId: uint256, _salePrice: uint256) -> (address, uint256):
    """
    @dev Called with the sale price to determine how much royalty is owed and to whom.
    @param _tokenId The NFT asset queried for royalty information
    @param _salePrice The sale price of the NFT asset specified by _tokenId
    @return receiver Address of who should be sent the royalty payment
    @return royaltyAmount The royalty payment amount for _salePrice
    """
    amount: uint256 = _salePrice * self.royaltyFee / 10000
    return (self.minter, amount)