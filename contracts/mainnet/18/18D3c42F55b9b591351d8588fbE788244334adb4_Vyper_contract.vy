# @version 0.3.6

event Mint:
	owner: indexed(address)
	tokenId: uint256
	name: String[64]


event Invalidate:
	owner: indexed(address)
	tokenId: uint256

baseTokenURI: String[64]

name: public(String[64])

owner: address

symbol: public(String[32])

totalSupply: uint256

tokenIdToValidity: HashMap[uint256, bool]

tokenIdToIssuer: HashMap[uint256, address]

ownerToIndexToId: HashMap[address, HashMap[uint256, uint256]]

tokenIdToOwner: HashMap[uint256, address]

ownerToBalance: HashMap[address, uint256]

tokenIdToURI: HashMap[uint256, String[64]]

ERC165_INTERFACE_ID: constant(Bytes[32]) = b"\x01\xff\xc9\xa7"

EIP_4671_INTERFACE_ID: constant(Bytes[32]) = b"\xa5\x11S="

EIP_4671_METADATA_INTERFACE_ID: constant(Bytes[32]) = b"[^\x13\x9f"

EIP_4671_ENUMERABLE_INTERFACE_ID: constant(Bytes[32]) = b"\x02\xaf\x8dc"

MAX_BALANCE: constant(uint256) = 1

@external
def __init__(
	name: String[64],
	symbol: String[32],
    _owner: address,
):
	self.name = name
	self.symbol = symbol

	self.owner = _owner
	self.totalSupply = 0


@internal
def _mint(_to: address, name: String[64]):
	_current_token_id: uint256 = self.totalSupply + 1
	self.totalSupply = _current_token_id
	self.tokenIdToValidity[_current_token_id] = True
	self.tokenIdToIssuer[_current_token_id] = self.owner
	self.tokenIdToOwner[_current_token_id] = _to

	_current_owner_index: uint256 = self.ownerToBalance[_to]
	self.ownerToBalance[_to] = _current_owner_index
	self.ownerToIndexToId[_to][_current_owner_index] = _current_token_id
	self.ownerToBalance[_to] = _current_owner_index + 1

	log Mint(_to, _current_token_id, name)


@internal
def _invalidate(_tokenId: uint256):
	self.tokenIdToValidity[_tokenId] = False
	_owner: address = self.tokenIdToOwner[_tokenId]

	log Invalidate(_owner, _tokenId)


@view
@internal
def _supportsInterface(_interfaceID: Bytes[4]) -> bool:
	return _interfaceID == ERC165_INTERFACE_ID or \
	 	_interfaceID == EIP_4671_INTERFACE_ID or \
		_interfaceID == EIP_4671_METADATA_INTERFACE_ID or \
		_interfaceID == EIP_4671_ENUMERABLE_INTERFACE_ID


@external
def invalidate(tokenId: uint256) -> bool:
	assert msg.sender == self.owner, "Only owner is authorised to invalidate"
	assert tokenId <= self.totalSupply, "Token ID does not exist"

	self._invalidate(tokenId)
	return True

@external
def setBaseTokenURI(_baseTokenURI: String[64]):
    assert msg.sender == self.owner, "Only owner is set BaseTokenURI"

    self.baseTokenURI = _baseTokenURI


@external
def mint(recipient: address, name: String[64]) -> bool:
    assert msg.sender == self.owner, "Only owner is authorised to mint"
    assert recipient != empty(address), "Invalid address"

    self._mint(recipient, name)
    return True


@view
@external
def supportsInterface(_interfaceID: bytes32) -> bool:
    return self._supportsInterface(slice(_interfaceID, 28, 4))


@external
@view
def ownerOf(tokenId: uint256) -> address:
	assert tokenId <= self.totalSupply, "Token ID does not exist"
	return self.tokenIdToOwner[tokenId]


@external
@view
def balanceOf(owner: address) -> uint256:
	return self.ownerToBalance[owner]


@external
@view
def hasValidToken(owner: address) -> bool:
    _owner_balance: uint256 = self.ownerToBalance[owner]

    for i in range(MAX_BALANCE):
        _tokenId: uint256 = self.ownerToIndexToId[owner][i]
        if self.tokenIdToValidity[_tokenId] == True:
            return True

    return False


@external
@view
def issuerOf(tokenId: uint256) -> address:
    assert tokenId <= self.totalSupply, "Token ID does not exist"

    return self.tokenIdToIssuer[tokenId]


@external
@view
def isValid(tokenId: uint256) -> bool:
    assert tokenId <= self.totalSupply, "Token ID does not exist"

    return self.tokenIdToValidity[tokenId]


@external
@view
def tokenURI(tokenId: uint256) -> String[142]:
    assert tokenId <= self.totalSupply, "Token ID does not exist"

    return concat(
		self.baseTokenURI,
		uint2str(tokenId)
	)

@external
@view
def tokenOfOwnerByIndex(owner: address, index: uint256) -> uint256:
    assert index < self.ownerToBalance[owner], "Index does not exist for address"

    _tokenId: uint256 = self.ownerToIndexToId[owner][index]

    assert _tokenId != 0, "Address does not have any tokens"

    return _tokenId


@external
@view
def total() -> uint256:
    return self.totalSupply