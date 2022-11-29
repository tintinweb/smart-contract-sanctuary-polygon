# @version 0.3.3
# @dev Implementation of ERC-721 non-fungible token standard.    ψ(▼へ▼メ)～→
# @author ApeWorX Team (@ApeWorX), Ryuya Nakamura (@nrryuya), Benjamin Scherry (@scherrey), Vyperlang Contributors
# Modified from: https://github.com/vyperlang/vyper/blob/master/examples/tokens/ERC721.vy
# Forked again from: https://github.com/ApeWorX/simple-nft/blob/main/contracts/ApePiece.vy
# Modded again from: https://github.com/ActorForth/monet-contract/blob/develop/contracts/token/SurpriseBox721.vy

from vyper.interfaces import ERC721

implements: ERC721

SUPPORTED_INTERFACES: constant(bytes4[6]) = [
    # ERC165 interface ID of ERC165
    0x01ffc9a7, 
    # ERC165 interface ID of ERC721
    0x80ac58cd,
    # ERC165 interface ID of ERC721 Metadata extension
    0x5b5e139f, 
    # ERC165 interface ID of ERC2981
    0x2a55205a,
    # ERC165 interface ID of ERC4494
    0x5604e225,
    # ERC165 interface ID of ERC721 Enumerable
    0x780e9d63,
]

# Interface for the contract called by safeTransferFrom()
interface ERC721Receiver:
    def onERC721Received(
            operator: address,
            holder: address,
            tokenId: uint256,
            data: Bytes[1024]
        ) -> bytes32: view

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    tokenId: indexed(uint256)

event Approval:
    holder: indexed(address)
    approved: indexed(address)
    tokenId: indexed(uint256)

event ApprovalForAll:
    holder: indexed(address)
    operator: indexed(address)
    approved: bool

event ArtistUpdated:
    newArtist: indexed(address)

event ContractOperatorUpdated:
    newContractOperator: indexed(address)

event MinterUpdated:
    minter: indexed(address)
    addDel: bool

struct RoyaltyInfo:
    receiver: address
    royaltyAmount: uint256

contractOperator: public(address)
null_slots: int128[1]
# Contract assigned storage slots
totalSupply: public(uint256)
_name: public(String[64])
_symbol: public(String[32])
maxTotalSupply: public(uint256)
maxMintBatchSize: constant(uint256) = 300 # 150
balanceOf: public(HashMap[address, uint256])
ownerOf: public(HashMap[uint256, address])
idToApprovals: HashMap[uint256, address]
#isApprovedForAll[0xHolder][0xOperator] = approved
isApprovedForAll: public(HashMap[address, HashMap[address, bool]])

null_slot_two: address 
artist: public(address)
ROYALTY: constant(uint256) = 0
nonces: public(HashMap[uint256, uint256])
domainSeparator: public(bytes32)
identityPrecompile: constant(address) = 0x0000000000000000000000000000000000000004
URIprefix: public(String[256])
URIsuffix: public(String[256])
#HolderTokenByIndex[0xHolder][Index] = TokenID
HolderTokenByIndex: public(HashMap[address, HashMap[uint256, uint256]])
#HolderIndexForToken[0xHolder][TokenID] = Index
HolderIndexForToken: public(HashMap[address, HashMap[uint256, uint256]])
initialized: bool

minters: public(HashMap[address, bool])

@external
def proxy_init(_name: String[64], _symbol: String[16], _URIprefix: String[256], _URIsuffix: String[256], _artist: address, _max_supply: uint256 ):
    
    assert self.initialized == False, 'Contract has already been initialized!'
    self.initialized = True

    self._name = _name 
    self._symbol = _symbol
    self.URIprefix = _URIprefix
    self.URIsuffix = _URIsuffix
    self.artist = _artist
    self.maxTotalSupply = _max_supply




############ ERC-165 #############

@pure
@external
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Interface identification is specified in ERC-165.
    @param interface_id Id of the interface support required
    @return bool This contract does support the given interface
    """
    # NOTE: Not technically compliant
    return interface_id in SUPPORTED_INTERFACES

############ Role Changes #############

@external
def setArtist(_artist: address):
    assert self.initialized == True, 'Contract has not been initialized!'
    assert msg.sender == self.contractOperator or msg.sender == self.artist, "Error-Only contractOperator or artist may call setArtist!"
    self.artist = _artist
    log ArtistUpdated(_artist)

@external
def setContractOperator(_contractOperator: address):
    assert self.initialized == True, 'Contract has not been initialized!'
    assert msg.sender == self.contractOperator, "Error-Only contractOperator may call setContractOperator!"
    self.contractOperator = _contractOperator
    log ContractOperatorUpdated(_contractOperator)

@external
def setMinter(_minter: address, addIfTrue: bool = True):
    assert self.initialized == True, 'Contract has not been initialized!'
    assert msg.sender == self.contractOperator or self.minters[msg.sender] == True, "Error-Only contract operator or minter may call setMinter!"
    if addIfTrue:    
        assert self.minters[_minter]==False, "Already a minter."
        self.minters[_minter] = True
    else:
        assert self.minters[_minter]==True, "No such minter."
        self.minters[_minter] = False
    log MinterUpdated(_minter, addIfTrue)

@view
@external
def royaltyInfo(tokenId: address, salePrice: uint256) -> RoyaltyInfo:
    assert self.initialized == True, 'Contract has not been initialized!'
    # NOTE: ABI-encoding returns structs as tuples
    return RoyaltyInfo({receiver: self.artist, royaltyAmount: salePrice * ROYALTY / 10_000})


@internal
def addToOwnerIndex(holder: address, tokenId: uint256):
    next_pos: uint256 = self.balanceOf[holder]
    self.HolderTokenByIndex[holder][next_pos] = tokenId
    self.HolderIndexForToken[holder][tokenId] = next_pos


@internal
def removeFromOwnerIndex(holder: address, tokenId: uint256):
    assert self.ownerOf[tokenId] == holder, 'TokenId not found by wallet'
    holder_balance: uint256 = self.balanceOf[holder]
    assert holder_balance > 0, 'Address holds no tokens'
    last_index: uint256 = holder_balance - 1
    current_index: uint256 = self.HolderIndexForToken[holder][tokenId]
    last_tokenId: uint256 = self.HolderTokenByIndex[holder][last_index]
    self.HolderTokenByIndex[holder][current_index] = last_tokenId
    self.HolderTokenByIndex[holder][last_index] = 0
    self.HolderIndexForToken[holder][last_tokenId] = current_index
    self.HolderIndexForToken[holder][tokenId] = 0


##### ERC-721 VIEW FUNCTIONS #####

@view
@external
def name() -> String[64]:
    assert self.initialized == True, 'Contract has not been initialized!'
    return self._name

@view
@external
def symbol() -> String[32]:
    assert self.initialized == True, 'Contract has not been initialized!'
    return self._symbol

@view
@external
def isMinter(_addr: address ) -> bool:
    return self.minters[_addr]


@pure
@internal
def _uint_to_string(_value: uint256) -> String[78]:
    # NOTE: Odd that this works with a raw_call inside, despite being marked
    # a pure function
    # It's 78 because log10(pow(2, 256)) is 77.x so you need 78 decimal characters for a 256 bit number
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
            # https://ethereum.stackexchange.com/a/653/91266
            identityPrecompile, # returns the input for efficient data copying
            concat(buffer, char),
            max_outsize=78,
            is_static_call=True
        )

    return convert(slice(buffer, 78 - digits, digits), String[78])


@view
@external
def getApproved(tokenId: uint256) -> address:
    assert self.initialized == True, 'Contract has not been initialized!'
    # Throws if `tokenId` is not a valid NFT
    assert self.ownerOf[tokenId] != ZERO_ADDRESS, "Error-Holder of tokenId is ZERO_ADDRESS!"
    return self.idToApprovals[tokenId]


### TRANSFER FUNCTION HELPERS ###

@view
@internal
def _isApprovedOrHolder(spender: address, tokenId: uint256) -> bool:
    """
    Returns whether the msg.sender is approved for the given token ID,
        is an operator of the holder, or is the holder of the token
    """
    holder: address = self.ownerOf[tokenId]

    if holder == spender:
        return True

    if spender == self.idToApprovals[tokenId]:
        return True

    if (self.isApprovedForAll[holder])[spender]:
        return True

    return False

@internal
def _transferFrom(holder: address, receiver: address, tokenId: uint256, sender: address, burn: bool):
    """
    Exeute transfer of a NFT.
      Throws unless `msg.sender` is the current holder, an authorized operator, or the approved
      address for this NFT. (NOTE: `msg.sender` not allowed in private function so pass `sender`.)
      Throws if `receiver` is the zero address unless burn == True.
      Throws if `holder` is not the current holder.
      Throws if `tokenId` is not a valid NFT.
    """
    # Check requirements
    # Tokens can be burned even if transfers are blocked.
    # assert burn or self.CLEAR_TO_SEND == True, "Error-Contract operator has not enabled transfers."
    assert self._isApprovedOrHolder(sender, tokenId), "Error-Not approved or holder!"
    assert burn or receiver != ZERO_ADDRESS, "Error-Send to zero address but not a burn!"
    assert holder != ZERO_ADDRESS, "Error-Send from zero address but not a mint!"
    assert self.ownerOf[tokenId] == holder, "Error-From address is not current holder!"

    self.removeFromOwnerIndex(holder, tokenId)
    self.addToOwnerIndex(receiver, tokenId)

    # Reset approvals, if any
    if self.idToApprovals[tokenId] != ZERO_ADDRESS:
        self.idToApprovals[tokenId] = ZERO_ADDRESS

    # EIP-4494: increment nonce on transfer for safety
    self.nonces[tokenId] += 1

    # Change the holder
    self.ownerOf[tokenId] = receiver

    # Change count tracking
    self.balanceOf[holder] -= 1
    self.balanceOf[receiver] += 1

    # Log the transfer
    log Transfer(holder, receiver, tokenId)


### TRANSFER FUNCTIONS ###

@external
def transferFrom(holder: address, receiver: address, tokenId: uint256):
    assert self.initialized == True, 'Contract has not been initialized!'
    self._transferFrom(holder, receiver, tokenId, msg.sender, False)


@external
def safeTransferFrom(
        holder: address,
        receiver: address,
        tokenId: uint256,
        data: Bytes[1024]=b""
    ):
    assert self.initialized == True, 'Contract has not been initialized!'
    self._transferFrom(holder, receiver, tokenId, msg.sender, False)
    if receiver.is_contract: # check if `receiver` is a contract address capable of processing a callback
        returnValue: bytes32 = ERC721Receiver(receiver).onERC721Received(msg.sender, holder, tokenId, data)
        # Throws if transfer destination is a contract which does not implement 'onERC721Received'
        assert returnValue == method_id("onERC721Received(address,address,uint256,bytes)", output_type=bytes32), "ERROR - Bad return on safeTransferFrom!"


##### APPROVAL FUNCTIONS #####

@external
def approve(approved: address, tokenId: uint256):
    assert self.initialized == True, 'Contract has not been initialized!'
    # Throws if `_tokenId` is not a valid NFT
    holder: address = self.ownerOf[tokenId]
    assert holder != ZERO_ADDRESS, "Error-Holder of tokenId is ZERO_ADDRESS!"

    # Throws if `approved` is the current holder
    assert approved != holder, "Error-Approved address is holder!"

    # Throws if `msg.sender` is not the current holder, or is approved for all actions
    if not (
        holder == msg.sender
        or (self.isApprovedForAll[holder])[msg.sender]
    ):
       raise

    # Set the approval
    self.idToApprovals[tokenId] = approved
    log Approval(holder, approved, tokenId)

@external
def setApprovalForAll(operator: address, approved: bool):
    assert self.initialized == True, 'Contract has not been initialized!'
    self.isApprovedForAll[msg.sender][operator] = approved
    log ApprovalForAll(msg.sender, operator, approved)

### MINT FUNCTIONS ###

@internal
def _createTokenId(receiver: address, block_hash: bytes32) -> uint256:
    return convert(keccak256(_abi_encode(receiver, block_hash)), uint256) % self.maxTotalSupply

@internal
def _batchMintTo(receiver: address, quantity: uint256, sender: address) -> (uint256, uint256):
    # Throws if `sender` is not the minter
    assert self.minters[sender] == True, "Error-must be minter to mint!"
    # Throws if `receiver` is zero address
    assert receiver != ZERO_ADDRESS, "Error-can't mint to ZERO_ADDRESS!"
    # Throws if we've minted more than the whole supply
    assert self.totalSupply + quantity <= self.maxTotalSupply, "Error-minting exhausts max token supply!"

    # Throws if larger than the maximum allowed batch size.
    assert quantity <= maxMintBatchSize, "Error-minting more than allowed tokens in single batch."


    baseTokenId: uint256 = self.totalSupply + 1
    for i in range(maxMintBatchSize):
        if i == quantity:
            break

        # Give the `receiver` their token
        self.ownerOf[baseTokenId + i] = receiver
        self.addToOwnerIndex(receiver, baseTokenId + i)
        self.balanceOf[receiver] += 1
        log Transfer(ZERO_ADDRESS, receiver, baseTokenId + i)

    self.totalSupply += quantity

    return (baseTokenId, quantity)

@external
def batchMintTo(receiver: address, quantity: uint256) -> (uint256, uint256):
    assert self.initialized == True, 'Contract has not been initialized!'
    return self._batchMintTo(receiver, quantity, msg.sender)

@external
def mint(receiver: address) -> uint256:
    assert self.initialized == True, 'Contract has not been initialized!'
    id: uint256 = 0
    qty: uint256 = 0
    id, qty = self._batchMintTo(receiver, 1, msg.sender)    
    return id

# @external
# def burn(tokenId : uint256):
#     assert self.initialized == True, 'Contract has not been initialized!'
#     self._transferFrom(msg.sender, ZERO_ADDRESS, tokenId, msg.sender, True)

# @external
# def burn_for(holder : address, tokenId : uint256):
#     assert self.initialized == True, 'Contract has not been initialized!'
#     self._transferFrom(holder, ZERO_ADDRESS, tokenId, msg.sender, True)

# @external
# def self_destruct():
#     assert msg.sender == self.contractOperator, "Error-Only contract operator may call self_destruct!"
#     selfdestruct(self.contractOperator)

    #////////////////////////////////////////////////////////////////////////////////////////
    # ERC721 Metadata extension 
    #////////////////////////////////////////////////////////////////////////////////////////

@view
@external
def tokenURI(_tokenId: uint256) -> String[590]:
    # Check if tokenId is valid
    assert self.initialized == True, 'Contract has not been initialized!'
    assert _tokenId <= self.totalSupply
    _uri: String[590] = concat(self.URIprefix, self._uint_to_string(_tokenId), self.URIsuffix)
    return _uri 

@external
def setURIprefix(_uri: String[256]):
    assert self.initialized == True, 'Contract has not been initialized!'
    # Throws if `msg.sender` is not the minter
    assert self.minters[msg.sender] == True, "Error-Only minter may call setURIprefix!"
    # Check if tokenId is valid
    self.URIprefix = _uri

@external
def setURIsuffix(_uri: String[256]):
    assert self.initialized == True, 'Contract has not been initialized!'
    # Throws if `msg.sender` is not the minter
    assert self.minters[msg.sender] == True, "Error-Only minter may call setURIsuffix!"
    # Check if tokenId is valid
    self.URIsuffix = _uri


@view
@external
def tokenByIndex(index: uint256) -> uint256:
    assert self.initialized == True, 'Contract has not been initialized!'
    assert self.totalSupply > index, 'index cannot be greater than or equal to totalSupply'
    return index + 1


@view
@external
def tokenOfOwnerByIndex(holder: address, index: uint256) -> uint256:
    assert self.initialized == True, 'Contract has not been initialized!'
    assert self.balanceOf[holder] > index, 'index cannot be greater than or equal to balanceOf'
    assert holder != ZERO_ADDRESS, 'holder cannot be ZERO_ADDRESS'

    return self.HolderTokenByIndex[holder][index]