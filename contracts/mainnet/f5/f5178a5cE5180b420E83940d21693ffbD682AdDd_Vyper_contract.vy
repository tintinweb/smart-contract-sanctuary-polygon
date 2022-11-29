# @version 0.3.3


interface ERC20:
    def transferFrom(_from : address, _to : address, _value : uint256) -> bool: nonpayable
    def transfer(_to : address, _value : uint256) -> bool: nonpayable

interface ERC721:
    def transferFrom(_from: address, _to: address, token_id: uint256): nonpayable
    def ownerOf(_id: uint256) -> address: view
    def isMinter(_minter: address) -> bool: view

event Deposit721:
    depositor: indexed(address)
    nft_contract: indexed(address)
    token_id: indexed(uint256)

event Withdraw721:
    withdrawal_id: indexed(bytes32)
    withdrawer: indexed(address)
    nft_contract: indexed(address)
    token_id: uint256

event IncrementNonce:
    withdrawer: indexed(address)
    nonce: uint256

event Deposit20:
    depositor: indexed(address)
    token_contract: indexed(address)
    amount: uint256

event Withdraw20:
    withdrawal_id: indexed(bytes32)
    withdrawer: indexed(address)
    token_contract: indexed(address)
    amount: uint256


struct Item:
    nft_contract: address
    token_id: uint256


contractOperator: public(address) 
null_slots: address # int128[1]   # place holder for 'address public currentDefaultVersion' in proxy.sol.


## New data slots for our contract.

# keep track of users inventory
#                NFT_address -> NFT_id -> User_wallet
holdings: HashMap[address, HashMap[uint256, address]]
#holdings: HashMap[address, HashMap[address, HashMap[uint256, bool]]]


# bridgeEOA:  "0xbridgeEOA"
bridgeEOA: public(address)




user_nonces: public(HashMap[address, uint256])

user_items: public(HashMap[address, Item])


# EIP-712
DOMAIN_TYPE_HASH: constant(bytes32) = keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')
DOMAIN_SEPARATOR: public(bytes32)



WITHDRAW_INFO_TYPE_HASH: constant(bytes32) = keccak256("WITHDRAW(address sender,address nft_contract,uint256 token_id,uint256 expirytimestamp,uint256 nonce)")
WITHDRAW20_INFO_TYPE_HASH: constant(bytes32) = keccak256("WITHDRAW(address sender,address token_contract,uint256 amount,uint256 expirytimestamp,uint256 nonce)")


@view
@external
def token_owner( nft_contract: address, nft_id: uint256 ) -> address:
    return self.holdings[nft_contract][nft_id]


@internal
def _validate_sig(_signature: Bytes[65], type_hash: bytes32) -> address:
    digest: bytes32 = keccak256(
        concat(
            b'\x19\x01',
            self.DOMAIN_SEPARATOR,
            type_hash
        )
    )

    r: uint256 = convert(slice(_signature, 0, 32), uint256)
    s: uint256 = convert(slice(_signature, 32, 32), uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)
    return ecrecover(digest, v, r, s)

@pure
@internal
def _withdrawal721_type_hash(sender: address, nft_contract: address, token_id: uint256, expirytimestamp: uint256, nonce: uint256) -> bytes32:
    return keccak256(
        concat(
            WITHDRAW_INFO_TYPE_HASH,
            convert(sender, bytes32),
            convert(nft_contract, bytes32),
            convert(token_id, bytes32),
            convert(expirytimestamp, bytes32),
            convert(nonce, bytes32),
        ),
    )

@pure
@internal
def _withdrawal20_type_hash(sender: address, token_contract: address, amount: uint256, expirytimestamp: uint256, nonce: uint256) -> bytes32:
    return keccak256(
        concat(
            WITHDRAW20_INFO_TYPE_HASH,
            convert(sender, bytes32),
            convert(token_contract, bytes32),
            convert(amount, bytes32),
            convert(expirytimestamp, bytes32),
            convert(nonce, bytes32),
        ),
    )
    

@external 
def custodialInit(_bridgeEOA: address):
    assert self.contractOperator ==  msg.sender, "Only the owner of this contract can use this function"
    self.bridgeEOA = _bridgeEOA
    
    # EIP-712
    self.DOMAIN_SEPARATOR = keccak256(
        concat(
            DOMAIN_TYPE_HASH,
            keccak256(convert("CryptoKnights Bridge Contract", Bytes[29])),
            keccak256(convert("0.0.1", Bytes[5])),
            convert(chain.id, bytes32),
            convert(self, bytes32)
        )
    )



@external
def get_chain_id() -> uint256:
    return chain.id


struct TokenAssignment:
    token_id: uint256
    receiver: address

@external
def pre_assign_token(nft_contract: address, assignments: DynArray[TokenAssignment, 100]):
    assert self.contractOperator == msg.sender, "Only Contract Operator can do this."    

    # Not protecting against NULL assignments cause you may want to do that.
    for token in assignments:
        self.holdings[nft_contract][token.token_id] = token.receiver


@external
def deposit721(nft_contract: address, token_id: uint256):
    assert self.holdings[nft_contract][token_id] == empty(address), "You already deposit this nft"

    ERC721(nft_contract).transferFrom(msg.sender, self, token_id)

    # update holdings map
    self.holdings[nft_contract][token_id] = msg.sender

    # Emit some event
    log Deposit721(msg.sender, nft_contract, token_id)


@external
def withdraw721(_sig: Bytes[65], _nft_contract: address, _token_id: uint256, _expirytimestamp: uint256, _nonce: uint256):
    assert self.holdings[_nft_contract][_token_id] == msg.sender, "No deposit found"
    assert block.timestamp < _expirytimestamp, "Token is expired"
    assert _nonce == self.user_nonces[msg.sender], "Incorrect nonce"
    # Declaring a struct variable
    type_hash: bytes32 = self._withdrawal721_type_hash(msg.sender, _nft_contract, _token_id, _expirytimestamp, _nonce)

    assert self._validate_sig(_sig, type_hash) == self.bridgeEOA, "Signature do not match"

    ERC721(_nft_contract).transferFrom(self, msg.sender, _token_id)
    self.holdings[_nft_contract][_token_id] = empty(address) #or unset

    #Emit some event
    log Withdraw721(type_hash, msg.sender, _nft_contract, _token_id)
    #Increment nonce to prevent reuse
    self.user_nonces[msg.sender] += 1


@external
def claim721For(nft_contract: address, token_id: uint256, receiver: address) -> bool:

    assert receiver != empty(address), "Can't associate with NULL wallet."

    assert ERC721(nft_contract).ownerOf(token_id) == self, "We do not own this token!"

    assert self.holdings[nft_contract][token_id] == empty(address), "Token is already associated with a wallet."

    assert ERC721(nft_contract).isMinter(msg.sender) == True, "Only minters can claim unclaimed tokens."

    self.holdings[nft_contract][token_id]=receiver    

    log Deposit721(receiver, nft_contract, token_id)

    return True


@external
def cancel_all_withdraws():
    self.user_nonces[msg.sender] += 1
    log IncrementNonce(msg.sender, self.user_nonces[msg.sender])


@external
def deposit20(token_contract: address, amount: uint256):
    ERC20(token_contract).transferFrom(msg.sender, self, amount)
    #Emit some event
    log Deposit20(msg.sender, token_contract, amount)


@external
def deposit20for(token_contract: address, amount: uint256, receiver: address):
    ERC20(token_contract).transferFrom(msg.sender, self, amount)
    #Emit some event
    log Deposit20(receiver, token_contract, amount)


@external
def withdraw20(_sig: Bytes[65], _token_contract: address, _amount: uint256, _expirytimestamp: uint256, _nonce: uint256):
    assert block.timestamp < _expirytimestamp, "Token is expired"
    assert _nonce == self.user_nonces[msg.sender], "Incorrect nonce"
    type_hash: bytes32 = self._withdrawal20_type_hash(msg.sender, _token_contract, _amount, _expirytimestamp, _nonce)

    assert self._validate_sig(_sig, type_hash) == self.bridgeEOA, "Signature do not match"
    ERC20(_token_contract).transfer(msg.sender, _amount)

    #Emit event
    log Withdraw20(type_hash, msg.sender, _token_contract, _amount)
    #Increment nonce to prevent reuse
    self.user_nonces[msg.sender] += 1

@pure
@external
def get_user_inventory(player: address):
    #query from holdings and return an array
    #Can only query 721 this way, for ERC20 the backend needs to build an index
    pass


@external
def update_owner(_new_owner: address):
    assert msg.sender == self.contractOperator, "Only owner change update owner"
    self.contractOperator = _new_owner


@external
def update_bridgeEOA(_new_bridgeEOA: address):
    assert msg.sender == self.contractOperator, "Only owner change update bridgeEOA"
    self.bridgeEOA = _new_bridgeEOA