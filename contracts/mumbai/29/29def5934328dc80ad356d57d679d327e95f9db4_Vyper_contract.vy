# @version 0.3.7

from vyper.interfaces import ERC165
from vyper.interfaces import ERC721

implements: ERC165
implements: ERC721

############ ERC-165 #############
# @dev Static list of supported ERC165 interface ids
SUPPORTED_INTERFACES: constant(bytes4[5]) = [
    0x01ffc9a7,  # ERC165 interface ID of ERC165
    0x80ac58cd,  # ERC165 interface ID of ERC721
    0x5b5e139f,  # ERC165 interface ID of ERC721 Metadata Extension
    0x5604e225,  # ERC165 interface ID of ERC4494
    0x2a55205a,  # ERC165 interface ID of ERC2981
]

############ ERC-721 #############

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
            operator: address,
            owner: address,
            tokenId: uint256,
            data: Bytes[1024]
        ) -> bytes4: nonpayable

# Interface for ERC721Metadata

interface ERC721Metadata:
	def name() -> String[64]: view

	def symbol() -> String[32]: view

	def tokenURI(
		_tokenId: uint256
	) -> String[128]: view

interface ERC721Enumerable:

	def totalSupply() -> uint256: view

	def tokenByIndex(
		_index: uint256
	) -> uint256: view

	def tokenOfOwnerByIndex(
		_address: address,
		_index: uint256
	) -> uint256: view


# @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
#      created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
#      number of NFTs may be created and assigned without emitting Transfer. At the time of any
#      transfer, the approved address for that NFT (if any) is reset to none.
# @param owner Sender of NFT (if address is zero address it indicates token creation).
# @param receiver Receiver of NFT (if address is zero address it indicates token destruction).
# @param tokenId The NFT that got transfered.
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    tokenId: indexed(uint256)

# @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
#      address indicates there is no approved address. When a Transfer event emits, this also
#      indicates that the approved address for that NFT (if any) is reset to none.
# @param owner Owner of NFT.
# @param approved Address that we are approving.
# @param tokenId NFT which we are approving.
event Approval:
    owner: indexed(address)
    approved: indexed(address)
    tokenId: indexed(uint256)

# @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
#      all NFTs of the owner.
# @param owner Owner of NFT.
# @param operator Address to which we are setting operator rights.
# @param approved Status of operator rights(true if operator rights are given and false if
# revoked).
event ApprovalForAll:
    owner: indexed(address)
    operator: indexed(address)
    approved: bool

owner: public(address)
isMinter: public(HashMap[address, bool])

totalSupply: public(uint256)

# @dev TokenID => owner
idToOwner: public(HashMap[uint256, address])

# @dev Mapping from owner address to count of their tokens.
balanceOf: public(HashMap[address, uint256])

# @dev Mapping from owner address to mapping of operator addresses.
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])

# @dev Mapping from NFT ID to approved address.
idToApprovals: public(HashMap[uint256, address])
# @dev we check this value to make sure royalties have been paid
# this can also be used to explore a based floor price oracle for a minimum royalty payment to the creator
# current implementation sends to the smart contract the apply % in royalties to the creator

minRoyaltyAmount: public(uint256)
############ ERC-4494 ############

# @dev Mapping of TokenID to nonce values used for ERC4494 signature verification
nonces: public(HashMap[uint256, uint256])

DOMAIN_SEPARATOR: public(bytes32)

EIP712_DOMAIN_TYPEHASH: constant(bytes32) = keccak256(
    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
)
EIP712_DOMAIN_NAMEHASH: constant(bytes32) = keccak256("Owner NFT")
EIP712_DOMAIN_VERSIONHASH: constant(bytes32) = keccak256("1")


# ERC20 Token Metadata
NAME: constant(String[20]) = "YES"
SYMBOL: constant(String[5]) = "YES"
baseURI: public(String[100])
# @dev Maximum supply of token
MAX_SUPPLY: constant(uint256) = 100
# @dev Percentage of royalties for lifetime for the creator
ROYALTY_TO_APPLY_TO_PRICE: constant(decimal) = 10.0 / 100.0

@external
def __init__():
    """
    @dev Contract constructor.
    """
    self.owner = msg.sender
    self.baseURI = "ipfs://QmaZm1rAkt6kHTKTFX8GwEhtPMVMeAGJYMBvoAcJWTddwb"

# @dev the default value for the minRoyaltyAmount is 0.01 ETH = 10**16
    self.minRoyaltyAmount = 100000000000000
    # ERC712 domain separator for ERC4494
    self.DOMAIN_SEPARATOR = keccak256(
        _abi_encode(
            EIP712_DOMAIN_TYPEHASH,
            EIP712_DOMAIN_NAMEHASH,
            EIP712_DOMAIN_VERSIONHASH,
            chain.id,
            self,
        )
    )
# ERC721 Metadata Extension
@pure
@external
def name() -> String[40]:
    return NAME

@pure
@external
def symbol() -> String[5]:
    return SYMBOL


@view
@external
def tokenURI(tokenId: uint256) -> String[179]:
    return concat(self.baseURI, "/" , uint2str(tokenId))

@external
def setBaseURI(_baseURI: String[100]):
    assert msg.sender == self.owner
    self.baseURI = _baseURI

@external
def setDomainSeparator():
    """
    @dev Update the domain separator in case of a hardfork where chain ID changes
    """
    self.DOMAIN_SEPARATOR = keccak256(
        _abi_encode(
            EIP712_DOMAIN_TYPEHASH,
            EIP712_DOMAIN_NAMEHASH,
            EIP712_DOMAIN_VERSIONHASH,
            chain.id,
            self,
        )
    )

############ ERC-165 #############

@pure
@external
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param interface_id Id of the interface
    """
    return interface_id in SUPPORTED_INTERFACES


##### ERC-721 VIEW FUNCTIONS #####

@view
@external
def ownerOf(tokenId: uint256) -> address:
    """
    @dev Returns the address of the owner of the NFT.
         Throws if `tokenId` is not a valid NFT.
    @param tokenId The identifier for an NFT.
    """
    owner: address = self.idToOwner[tokenId]
    # Throws if `tokenId` is not a valid NFT
    assert owner != empty(address)
    return owner


@view
@external
def getApproved(tokenId: uint256) -> address:
    """
    @dev Get the approved address for a single NFT.
         Throws if `tokenId` is not a valid NFT.
    @param tokenId ID of the NFT to query the approval of.
    """
    # Throws if `tokenId` is not a valid NFT
    assert self.idToOwner[tokenId] != empty(address)
    return self.idToApprovals[tokenId]


### TRANSFER FUNCTION HELPERS ###
### Royalty integration under the ERC-2981: NFT Royalty Standard
@view
@external
def royaltyInfo(_tokenId: uint256, _salePrice: uint256) -> (address, uint256):
    """
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom. Important; Not all marketplaces respect this, e.g. OpenSea
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return minRoyaltyAmount - the minimum royalty payment amount for _salePrice
    """

    royalty: uint256 = convert(convert(_salePrice, decimal) * ROYALTY_TO_APPLY_TO_PRICE, uint256) # Percentage that accepts decimals
    return self.owner, royalty
# Helper functions in case market place does not support royalties to execute by this contract with _enforceRoyalties()
@internal
@view
def _royaltyInfo(_tokenId: uint256, _salePrice: uint256) -> (address, uint256):
    """
    /// @notice Called with the sale price to determine how much royalty
    //          is owed and to whom. Important; Not all marketplaces respect this, e.g. OpenSea
    /// @param _tokenId - the NFT asset queried for royalty information
    /// @param _salePrice - the sale price of the NFT asset specified by _tokenId
    /// @return receiver - address of who should be sent the royalty payment
    /// @return owner address and minRoyaltyAmount - the minimum royalty payment amount for _salePrice
    """

    royalty: uint256 = convert(convert(_salePrice, decimal) * ROYALTY_TO_APPLY_TO_PRICE, uint256) # Percentage that accepts decimals
    # NOTE: We are returning `self` as the receiver of the royalty to enforce payment to `self.owner` later
    return self, max(self.minRoyaltyAmount, royalty)


@internal
@payable
def _enforceRoyalties(tokenId: uint256):
     # check if royalties hace been paid
     assert self.minRoyaltyAmount >= self.minRoyaltyAmount
     # Send all balance to the owner (clears `self.balance`)
     send(self.owner, self.balance)

@view
@internal
def _isApprovedOrOwner(spender: address, tokenId: uint256) -> bool:
    """
    @dev Returns whether the given spender can transfer a given token ID
    @param spender address of the spender to query
    @param tokenId uint256 ID of the token to be transferred
    @return bool whether the msg.sender is approved for the given token ID,
        is an operator of the owner, or is the owner of the token
    """
    owner: address = self.idToOwner[tokenId]

    if owner == spender:
        return True

    if spender == self.idToApprovals[tokenId]:
        return True

    if (self.isApprovedForAll[owner])[spender]:
        return True

    return False


@internal
def _transferFrom(owner: address, receiver: address, tokenId: uint256, sender: address):
    """
    @dev Execute transfer of a NFT.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT. (NOTE: `msg.sender` not allowed in private function so pass `_sender`.)
         address for thisassert self.idToOwner[tokenId] == owner NFT. (NOTE: `msg.sender` not allowed in private function so pass `_sender`.)
         Throws if `receiver` is the zero address.
         Throws if `owner` is not the current owner.
         Throws if `tokenId` is not a valid NFT.
         
    """
    # Check requirements
    assert self._isApprovedOrOwner(sender, tokenId)
    assert receiver != empty(address)
    assert owner != empty(address)
    assert self.idToOwner[tokenId] == owner

    # Reset approvals, if any
    if self.idToApprovals[tokenId] != empty(address):
        self.idToApprovals[tokenId] = empty(address)
    # EIP-4494: increment nonce on transfer for safety
    self.nonces[tokenId] += 1

    # Change the owner
    self.idToOwner[tokenId] = receiver

    # Change count tracking
    self.balanceOf[owner] -= 1
    # Add count of token to address
    self.balanceOf[receiver] += 1

    # Log the transfer
    log Transfer(owner, receiver, tokenId)


@external
@payable
def transferFrom(owner: address, receiver: address, tokenId: uint256):
    """
    @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
         address for this NFT.
         Throws if `owner` is not the current owner.
         Throws if `receiver` is the zero address.
         Throws if `tokenId` is not a valid NFT.
    @notice The caller is responsible to confirm that `receiver` is capable of receiving NFTs or else
            they maybe be permanently lost.
    @param owner The current owner of the NFT.
    @param receiver The new owner.
    @param tokenId The NFT to transfer.
    """
    # check if royalties have been paid
    self._enforceRoyalties(tokenId)
    self._transferFrom(owner, receiver, tokenId, msg.sender)


@external
@payable
def safeTransferFrom(
        owner: address,
        receiver: address,
        tokenId: uint256,
        data: Bytes[1024]=b""
    ):
    """
    @dev Transfers the ownership of an NFT from one address to another address.
         Throws unless `msg.sender` is the current owner, an authorized operator, or the
         approved address for this NFT.
         Throws if `owner` is not the current owner.
         Throws if `receiver` is the zero address.
         Throws if `tokenId` is not a valid NFT.
         If `receiver` is a smart contract, it calls `onERC721Received` on `receiver` and throws if
         the return value is not `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
         NOTE: bytes4 is represented by bytes32 with padding
    @param owner The current owner of the NFT.
    @param receiver The new owner.
    @param tokenId The NFT to transfer.
    @param data Additional data with no specified format, sent in call to `receiver`.
    """
    # check if royalties have been paid
    self._enforceRoyalties(tokenId)
    self._transferFrom(owner, receiver, tokenId, msg.sender)
    if receiver.is_contract: # check if `receiver` is a contract address
        returnValue: bytes4 = ERC721Receiver(receiver).onERC721Received(msg.sender, owner, tokenId, data)
        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes4)


@external
def approve(operator: address, tokenId: uint256):
    """
    @dev Set or reaffirm the approved address for an NFT. The zero address indicates there is no approved address.
         Throws unless `msg.sender` is the current NFT owner, or an authorized operator of the current owner.
         Throws if `tokenId` is not a valid NFT. (NOTE: This is not written the EIP)
         Throws if `operator` is the current owner. (NOTE: This is not written the EIP)
    @param operator Address to be approved for the given NFT ID.
    @param tokenId ID of the token to be approved.
    """
    # Throws if `tokenId` is not a valid NFT
    owner: address = self.idToOwner[tokenId]
    assert owner != empty(address)

    # Throws if `operator` is the current owner
    assert operator != owner

    # Throws if `msg.sender` is not the current owner, or is approved for all actions
    assert owner == msg.sender or (self.isApprovedForAll[owner])[msg.sender]

    self.idToApprovals[tokenId] = operator
    log Approval(owner, operator, tokenId)


@external
def permit(spender: address, tokenId: uint256, deadline: uint256, sig: Bytes[65]) -> bool:
    """
    @dev Allow a 3rd party to approve a transfer via EIP-721 message
        Raises if permit has expired
        Raises if `tokenId` is unowned
        Raises if permit is not signed by token owner
        Raises if `nonce` is not the current expected value
        Raises if `sig` is not a supported signature type
    @param spender The approved spender of `tokenId` for the permit
    @param tokenId The token that is being approved
        NOTE: signer is checked against this token's owner
    @param deadline The time limit for which the message is valid for
    @param sig The signature for the message, either in vrs or EIP-2098 form
    @return bool If the operation is successful
    """
    # Permit is still valid
    assert block.timestamp <= deadline

    # Ensure the token is owned by someone
    owner: address = self.idToOwner[tokenId]
    assert owner != empty(address)

    # Nonce for given token (signer must ensure they use latest)
    nonce: uint256 = self.nonces[tokenId]

    # Compose EIP-712 message
    message: bytes32 = keccak256(
        _abi_encode(
            0x1901,
            self.DOMAIN_SEPARATOR,
            keccak256(
                _abi_encode(
                    keccak256(
                        "Permit(address spender,uint256 tokenId,uint256 nonce,uint256 deadline)"
                    ),
                    spender,
                    tokenId,
                    nonce,
                    deadline,
                )
            )
        )
    )

    # Validate signature
    v: uint256 = 0
    r: uint256 = 0
    s: uint256 = 0

    if len(sig) == 65:
        # Normal encoded VRS signatures
        v = convert(slice(sig, 0, 1), uint256)
        r = convert(slice(sig, 1, 32), uint256)
        s = convert(slice(sig, 33, 32), uint256)

    elif len(sig) == 64:
        # EIP-2098 compact signatures
        r = convert(slice(sig, 0, 32), uint256)
        v = convert(slice(sig, 33, 1), uint256)
        s = convert(slice(sig, 34, 31), uint256)

    else:
        raise  # Other schemes not supported

    # Ensure owner signed permit
    assert ecrecover(message, v, r, s) == owner

    self.nonces[tokenId] = nonce + 1
    self.idToApprovals[tokenId] = spender

    return True

@external
def setApprovalForAll(operator: address, approved: bool):
    """
    @dev Enables or disables approval for a third party ("operator") to manage all of
         `msg.sender`'s assets. It also emits the ApprovalForAll event.
    @notice This works even if sender doesn't own any tokens at the time.
    @param operator Address to add to the set of authorized operators.
    @param approved True if the operators is approved, false to revoke approval.
    """
    self.isApprovedForAll[msg.sender][operator] = approved
    log ApprovalForAll(msg.sender, operator, approved)


@external
def addMinter(minter: address):
    assert msg.sender == self.owner
    self.isMinter[minter] = True

@external
def mint(receiver: address) -> bool:
    """
    @dev Create a new Owner NFT
    @return bool confirming that the minting occurred 
    """
    assert MAX_SUPPLY > self.totalSupply 

    # Throws if `msg.sender` is not the minter
    assert msg.sender == self.owner or self.isMinter[msg.sender], "Access is denied."
    # Throws if `receiver` is zero address
    assert receiver != empty(address)
    # Throws if `totalSupply` count NFTs tracked by this contract is owned by someone
    assert self.idToOwner[self.totalSupply] == empty(address)
    # Create new owner to allocate token
    self.idToOwner[self.totalSupply] = receiver
    # Change count tracking, `totalSupply` represents id for `tokenId`
    self.totalSupply += 1
    # Update balance of minter
    self.balanceOf[receiver] += 1

    log Transfer(empty(address), receiver, self.totalSupply)

    return True