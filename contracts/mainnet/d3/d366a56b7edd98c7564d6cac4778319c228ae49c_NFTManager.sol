/**
 *Submitted for verification at polygonscan.com on 2022-10-13
*/

// File: contracts/EIP712Base.sol



pragma solidity ^0.8.10;


contract EIP712Base {
    
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,uint256 salt)"
        )
    );
    bytes32 public domainSeparator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name,
        string memory version
    )
        internal
    {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                getChainId()
            )
        );

    }

    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, messageHash)
            );
    }
}
// File: contracts/NativeMetaTransaction.sol



pragma solidity ^0.8.10;


contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature,string functionInfo)"
        )
    );
    
    bytes32 public messagehash;

    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
        string functionInfo;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        string memory functionInfo,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature,
            functionInfo: functionInfo
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "NMT#executeMetaTransaction: SIGNER_AND_SIGNATURE_DO_NOT_MATCH"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress] + 1;

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "NMT#executeMetaTransaction: CALL_FAILED");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature),
                    keccak256(bytes(metaTx.functionInfo))
                )
            );
    }

    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal returns (bool) {
        require(signer != address(0), "NMT#verify: INVALID_SIGNER");
        messagehash = toTypedMessageHash(hashMetaTransaction(metaTx));
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}
// File: contracts/ContextMixin.sol



pragma solidity ^0.8.10;


contract ContextMixin {
    function _msgSender()
        internal
        view
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}
// File: contracts/Ownable.sol



pragma solidity >=0.6.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is ContextMixin {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: contracts/IERC20.sol


pragma solidity ^0.8.17;

interface IERC20 {
  function DEFAULT_ADMIN_ROLE (  ) external view returns ( bytes32 );
  function MINTER_ROLE (  ) external view returns ( bytes32 );
  function PAUSER_ROLE (  ) external view returns ( bytes32 );
  function UPGRADER_ROLE (  ) external view returns ( bytes32 );
  function allowance ( address owner, address spender ) external view returns ( uint256 );
  function approve ( address spender, uint256 amount ) external returns ( bool );
  function balanceOf ( address account ) external view returns ( uint256 );
  function burn ( uint256 amount ) external;
  function burnFrom ( address account, uint256 amount ) external;
  function decimals (  ) external view returns ( uint8 );
  function decreaseAllowance ( address spender, uint256 subtractedValue ) external returns ( bool );
  function getRoleAdmin ( bytes32 role ) external view returns ( bytes32 );
  function grantRole ( bytes32 role, address account ) external;
  function hasRole ( bytes32 role, address account ) external view returns ( bool );
  function increaseAllowance ( address spender, uint256 addedValue ) external returns ( bool );
  function initialize (  ) external;
  function mint ( address to, uint256 amount ) external;
  function name (  ) external view returns ( string memory);
  function pause (  ) external;
  function paused (  ) external view returns ( bool );
  function proxiableUUID (  ) external view returns ( bytes32 );
  function renounceRole ( bytes32 role, address account ) external;
  function revokeRole ( bytes32 role, address account ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory);
  function totalSupply (  ) external view returns ( uint256 );
  function transfer ( address to, uint256 amount ) external returns ( bool );
  function transferFrom ( address from, address to, uint256 amount ) external returns ( bool );
  function unpause (  ) external;
  function upgradeTo ( address newImplementation ) external;
  function upgradeToAndCall ( address newImplementation, bytes memory data ) external;
}
// File: contracts/IDCLNFT.sol


pragma solidity ^0.8.17;

interface IDCLNFT {
    struct ItemParam {
        string rarity;
        uint256 price;
        address beneficiary;
        string metadata;
    }
    function COLLECTION_HASH () external view returns ( bytes32 );
    function ISSUED_ID_BITS () external view returns ( uint8 );
    function ITEM_ID_BITS () external view returns ( uint8 );
    function MAX_ISSUED_ID () external view returns ( uint216 );
    function MAX_ITEM_ID () external view returns ( uint40 );
    function addItems ( ItemParam[] memory _items ) external;
    function approve (address to, uint256 tokenId) external;
    function balanceOf (address owner) external view returns ( uint256 );
    function baseURI () external view returns ( string memory);
    function batchTransferFrom ( address _from, address _to, uint256[] memory _tokenIds ) external;
    function completeCollection () external;
    function createdAt () external view returns ( uint256 );
    function creator () external view returns ( address );
    function decodeTokenId ( uint256 _id ) external pure returns ( uint256 itemId, uint256 issuedId );
    function domainSeparator () external view returns ( bytes32 );
    function editItemsData ( uint256[] memory _itemIds, uint256[] memory _prices, address[] memory _beneficiaries, string[] memory _metadatas ) external;
    function encodeTokenId ( uint256 _itemId, uint256 _issuedId ) external pure returns ( uint256 id );
    function executeMetaTransaction ( address userAddress, bytes memory functionSignature, bytes32 sigR, bytes32 sigS, uint8 sigV ) external returns ( bytes memory);
    function getApproved ( uint256 tokenId ) external view returns ( address );
    function getChainId () external pure returns ( uint256 );
    function getNonce ( address user ) external view returns ( uint256 nonce );
    function globalManagers ( address ) external view returns ( bool );
    function globalMinters ( address ) external view returns ( bool );
    function initImplementation () external;
    function initialize ( string memory _name, string memory _symbol, string memory _baseURI, address _creator, bool _shouldComplete, bool _isApproved, address _rarities, ItemParam[] memory _items ) external;
    function isApproved () external view returns ( bool );
    function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
    function isCompleted () external view returns ( bool );
    function isEditable () external view returns ( bool );
    function isInitialized () external view returns ( bool );
    function isMintingAllowed () external view returns ( bool );
    function issueTokens ( address[] memory _beneficiaries, uint256[] memory _itemIds ) external;
    function itemManagers ( uint256, address ) external view returns ( bool );
    function itemMinters ( uint256, address ) external view returns ( uint256 );
    function items ( uint256 ) external view returns ( string memory rarity, uint256 maxSupply, uint256 totalSupply, uint256 price, address beneficiary, string memory metadata, string memory contentHash );
    function itemsCount (  ) external view returns ( uint256 );
    function name (  ) external view returns ( string memory);
    function owner (  ) external view returns ( address );
    function ownerOf ( uint256 tokenId ) external view returns ( address );
    function rarities (  ) external view returns ( address );
    function renounceOwnership (  ) external;
    function rescueItems ( uint256[] memory _itemIds, string[] memory _contentHashes, string[] memory _metadatas ) external;
    function safeBatchTransferFrom ( address _from, address _to, uint256[] memory _tokenIds, bytes memory _data ) external;
    function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
    function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory _data ) external;
    function setApprovalForAll ( address operator, bool approved ) external;
    function setApproved ( bool _value ) external;
    function setBaseURI ( string memory _baseURI ) external;
    function setEditable ( bool _value ) external;
    function setItemsManagers ( uint256[] memory _itemIds, address[] memory _managers, bool[] memory _values ) external;
    function setItemsMinters ( uint256[] memory _itemIds, address[] memory _minters, uint256[] memory _values ) external;
    function setManagers ( address[] memory _managers, bool[] memory _values ) external;
    function setMinters ( address[] memory _minters, bool[] memory _values ) external;
    function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
    function symbol (  ) external view returns ( string memory );
    function tokenByIndex ( uint256 index ) external view returns ( uint256 );
    function tokenOfOwnerByIndex ( address owner, uint256 index ) external view returns ( uint256 );
    function tokenURI ( uint256 _tokenId ) external view returns ( string memory);
    function totalSupply (  ) external view returns ( uint256 );
    function transferCreatorship ( address _newCreator ) external;
    function transferFrom ( address from, address to, uint256 tokenId ) external;
    function transferOwnership ( address newOwner ) external;

}
// File: contracts/NFTManager.sol


pragma solidity ^0.8.17;





contract NFTManager is Ownable, NativeMetaTransaction{
    event Incriment(address sender);

    constructor() {
        issueDetails.reciver_add.push(_msgSender());
        issueDetails.reciver_item.push(0);
        _initializeEIP712("NFTManager", "1");
    }
    struct TokenContract{
        address token_address;
        IERC20 token_contract;
    }

    struct IssueDetails{
        address[]  reciver_add;
        uint256[]  reciver_item;
    }

    TokenContract token;
    IssueDetails issueDetails;

    struct NFTContract {
        address nft_address;
        string name;
        uint256[] items;
        mapping(uint256 => uint) item_indexMap;
        mapping(uint256 => uint) price;
        IDCLNFT nft_contract;
        bool isInitilized;
    }

    mapping(address => NFTContract) public contracts;

    function setTokenContract(address _address) external onlyOwner{
        token.token_contract = IERC20(_address);
        token.token_address = _address;
    }

    function addContract(address _address, string memory _name) external onlyOwner returns(string memory){
        require(!contracts[_address].isInitilized, "contract already exists");
        IDCLNFT nft_contract = IDCLNFT(_address);
        contracts[_address].nft_address = _address;
        contracts[_address].name = _name;
        contracts[_address].nft_contract = nft_contract;
        contracts[_address].isInitilized = true;
        return "contract has been added";
    }

    function removeContract(address _address) external onlyOwner returns(string memory){
        require(contracts[_address].isInitilized, "contract dose not exits");
        //delete all the item price map
        uint256[] memory items = contracts[_address].items;
        for(uint i=0; i<items.length; i++){
            delete contracts[_address].price[items[i]];
            delete contracts[_address].item_indexMap[items[i]];
        }
        delete contracts[_address];
        return "contract removed";
    }

    function addItem(address _address, uint256 _item, uint _price) external onlyOwner returns(string memory){
        require(contracts[_address].isInitilized, "contract dose not exits");
        require(contracts[_address].price[_item] == 0, "item already added");
        contracts[_address].item_indexMap[_item] = contracts[_address].items.length;
        contracts[_address].items.push(_item);
        contracts[_address].price[_item] = _price;
        return "item added";
    }

    function removeItem(address _address, uint256 _item) external onlyOwner returns(string memory){
        require(contracts[_address].isInitilized, "contract dose not exits");
        require(contracts[_address].price[_item] != 0, "item dose not exist");
        contracts[_address].items[contracts[_address].item_indexMap[_item]] = contracts[_address].items[contracts[_address].items.length -1];
        contracts[_address].items.pop();
        contracts[_address].item_indexMap[contracts[_address].items[contracts[_address].item_indexMap[_item]]] = contracts[_address].item_indexMap[_item];
        delete contracts[_address].item_indexMap[_item];
        delete contracts[_address].price[_item];
       return "item removed";
    }

    function setItemPrice(address _address, uint256 _item, uint _price) external onlyOwner returns(string memory){
        require(contracts[_address].isInitilized, "contract dose not exits");
        require(contracts[_address].price[_item] != 0, "item dose not exist");
        contracts[_address].price[_item] = _price;
        return "item price set";
    }

    function buyItem(address _address, uint256 _item) external returns(string memory){
        require(contracts[_address].isInitilized, "This NFT collection dose not exist");
        require(contracts[_address].price[_item] != 0, "This item dose not exist");
        require(token.token_contract.allowance(_msgSender(), address(this)) >= contracts[_address].price[_item], "failed to get sufficent token for this transaction");
        token.token_contract.burnFrom(_msgSender(), contracts[_address].price[_item]);
        issueDetails.reciver_add[0] = _msgSender();
        issueDetails.reciver_item[0] = _item;
        contracts[_address].nft_contract.issueTokens( issueDetails.reciver_add, issueDetails.reciver_item);
        return "Transaction successfull";
    }

    function getIteamList(address _address) external view returns(uint256[] memory){
        return contracts[_address].items;
    }
    function getIteamPrize(address _address, uint256 _item) view external returns(uint){
        return contracts[_address].price[_item];
    }
    function getIteamIndexMap(address _address, uint256 _item) view external returns(uint){
        return contracts[_address].item_indexMap[_item];
    }
    function getContractAddress() external view returns(address){
        return address(this);
    }
}