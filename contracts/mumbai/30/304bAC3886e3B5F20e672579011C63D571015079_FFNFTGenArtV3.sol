/**
 *Submitted for verification at polygonscan.com on 2023-02-08
*/

/** 
 *  SourceUnit: c:\Users\PC\Documents\flip-sc\src\sc\contracts\NftCollectionGenArtV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity >=0.8;

interface IOperatorFilterRegistry {
    function isOperatorAllowed(address registrant, address operator) external view returns (bool);
    function register(address registrant) external;
    function registerAndSubscribe(address registrant, address subscription) external;
    function registerAndCopyEntries(address registrant, address registrantToCopy) external;
    function updateOperator(address registrant, address operator, bool filtered) external;
    function updateOperators(address registrant, address[] calldata operators, bool filtered) external;
    function updateCodeHash(address registrant, bytes32 codehash, bool filtered) external;
    function updateCodeHashes(address registrant, bytes32[] calldata codeHashes, bool filtered) external;
    function subscribe(address registrant, address registrantToSubscribe) external;
    function unsubscribe(address registrant, bool copyExistingEntries) external;
    function subscriptionOf(address addr) external returns (address registrant);
    function subscribers(address registrant) external returns (address[] memory);
    function subscriberAt(address registrant, uint256 index) external returns (address);
    function copyEntriesOf(address registrant, address registrantToCopy) external;
    function isOperatorFiltered(address registrant, address operator) external returns (bool);
    function isCodeHashOfFiltered(address registrant, address operatorWithCode) external returns (bool);
    function isCodeHashFiltered(address registrant, bytes32 codeHash) external returns (bool);
    function filteredOperators(address addr) external returns (address[] memory);
    function filteredCodeHashes(address addr) external returns (bytes32[] memory);
    function filteredOperatorAt(address registrant, uint256 index) external returns (address);
    function filteredCodeHashAt(address registrant, uint256 index) external returns (bytes32);
    function isRegistered(address addr) external returns (bool);
    function codeHashOf(address addr) external returns (bytes32);
}



/** 
 *  SourceUnit: c:\Users\PC\Documents\flip-sc\src\sc\contracts\NftCollectionGenArtV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}




/** 
 *  SourceUnit: c:\Users\PC\Documents\flip-sc\src\sc\contracts\NftCollectionGenArtV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (metatx/ERC2771Context.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

/**
 * @dev Context variant with ERC2771 support.
 */
abstract contract ERC2771Context is Context {
    address private _trustedForwarder;

    constructor(address trustedForwarder) {
        _trustedForwarder = trustedForwarder;
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return forwarder == _trustedForwarder;
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return super._msgSender();
        }
    }

    function _msgData() internal view virtual override returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return super._msgData();
        }
    }
}




/** 
 *  SourceUnit: c:\Users\PC\Documents\flip-sc\src\sc\contracts\NftCollectionGenArtV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity >=0.8;


////import './IOperatorFilterRegistry.sol';

abstract contract OperatorFilter {
    error OperatorNotAllowed(address operator);

    IOperatorFilterRegistry constant operatorFilterRegistry =
        IOperatorFilterRegistry(0x000000000000AAeB6D7670E522A718067333cd4E);

    constructor(address subscriptionOrRegistrantToCopy, bool subscribe) {
        // If an inheriting token contract is deployed to a network without the registry deployed, the modifier
        // will not revert, but the contract will need to be registered with the registry once it is deployed in
        // order for the modifier to filter addresses.
        if (address(operatorFilterRegistry).code.length > 0) {
            if (subscribe) {
                operatorFilterRegistry.registerAndSubscribe(address(this), subscriptionOrRegistrantToCopy);
            } else {
                if (subscriptionOrRegistrantToCopy != address(0)) {
                    operatorFilterRegistry.registerAndCopyEntries(address(this), subscriptionOrRegistrantToCopy);
                } else {
                    operatorFilterRegistry.register(address(this));
                }
            }
        }
    }

    modifier onlyAllowedOperator(address from) virtual {
        // Check registry code length to facilitate testing in environments without a deployed registry.
        if (address(operatorFilterRegistry).code.length > 0) {
            // Allow spending tokens from addresses with balance
            // Note that this still allows listings and marketplaces with escrow to transfer tokens if transferred
            // from an EOA.
            if (from == msg.sender) {
                _;
                return;
            }
            if (
                !(
                    operatorFilterRegistry.isOperatorAllowed(address(this), msg.sender)
                        && operatorFilterRegistry.isOperatorAllowed(address(this), from)
                )
            ) {
                revert OperatorNotAllowed(msg.sender);
            }
        }
        _;
    }
}



/** 
 *  SourceUnit: c:\Users\PC\Documents\flip-sc\src\sc\contracts\NftCollectionGenArtV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity ^0.8;

interface Structs {
    struct Rarities {
         bytes32 rarity;
         uint256 amounts;
    }

    struct Mint {
         address to;
         bytes32 rarity;
    }

    struct URI {
         string _contractUri;
         string _tokenUri;
    }

    struct Royalty {
        uint256 _royaltyBps;
        address _spliter;
    }
}

interface StructsGenArt {
    struct Rarities {
         bytes32 rarity;
         uint256 amounts;
    }

    struct Mint {
         address to;
         uint96 id;
         bytes32 rarity;
    }

    struct URI {
         string _contractUri;
         string _tokenUri;
    }

    struct Royalty {
        uint256 _royaltyBps;
        address _spliter;
    }
}




/** 
 *  SourceUnit: c:\Users\PC\Documents\flip-sc\src\sc\contracts\NftCollectionGenArtV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}




/** 
 *  SourceUnit: c:\Users\PC\Documents\flip-sc\src\sc\contracts\NftCollectionGenArtV3.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0-only
pragma solidity >=0.8.0;

////import "@openzeppelin/contracts/metatx/ERC2771Context.sol";

/// @notice Modern, minimalist, and gas efficient ERC-721 implementation.
/// @dev Handles Meta transactions
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721 is ERC2771Context {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event Transfer(address indexed from, address indexed to, uint256 indexed id);

    event Approval(address indexed owner, address indexed spender, uint256 indexed id);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /*//////////////////////////////////////////////////////////////
                         METADATA STORAGE/LOGIC
    //////////////////////////////////////////////////////////////*/

    string public name;

    string public symbol;

    function tokenURI(uint256 id) public view virtual returns (string memory);

    /*//////////////////////////////////////////////////////////////
                      ERC721 BALANCE/OWNER STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) internal _ownerOf;

    mapping(address => uint256) internal _balanceOf;

    function ownerOf(uint256 id) public view virtual returns (address owner) {
        require((owner = _ownerOf[id]) != address(0), "NOT_MINTED");
    }

    function balanceOf(address owner) public view virtual returns (uint256) {
        require(owner != address(0), "ZERO_ADDRESS");

        return _balanceOf[owner];
    }

    /*//////////////////////////////////////////////////////////////
                         ERC721 APPROVAL STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(uint256 => address) public getApproved;

    mapping(address => mapping(address => bool)) public _isApprovedForAll;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    /*//////////////////////////////////////////////////////////////
                              ERC721 LOGIC
    //////////////////////////////////////////////////////////////*/

    function approve(address spender, uint256 id) public virtual {
        address owner = _ownerOf[id];
        address sender = _msgSender();

        require(sender == owner || _isApprovedForAll[owner][sender], "NOT_AUTHORIZED");

        getApproved[id] = spender;

        emit Approval(owner, spender, id);
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        address sender = _msgSender();
        _isApprovedForAll[sender][operator] = approved;

        emit ApprovalForAll(sender, operator, approved);
    }

    function transferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        require(from == _ownerOf[id], "WRONG_FROM");

        require(to != address(0), "INVALID_RECIPIENT");
        address sender = _msgSender();

        require(
            sender == from || _isApprovedForAll[from][sender] || sender == getApproved[id],
            "NOT_AUTHORIZED"
        );

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        unchecked {
            _balanceOf[from]--;

            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        delete getApproved[id];

        emit Transfer(from, to, id);
    }

    function burn(
        uint256 id
    ) public virtual {
        require(msg.sender == _ownerOf[id], "Only owner can burn");
        _burn(id);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(_msgSender(), from, id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) public virtual {
        transferFrom(from, to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(_msgSender(), from, id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids
    ) public virtual {
        
        for(uint256 i = 0; i < ids.length; i++) {
            transferFrom(from, to, ids[i]);

            require(
                to.code.length == 0 ||
                    ERC721TokenReceiver(to).onERC721Received(_msgSender(), from, ids[i], "") ==
                    ERC721TokenReceiver.onERC721Received.selector,
                "UNSAFE_RECIPIENT"
            );
        }
        
    }

    /*//////////////////////////////////////////////////////////////
                              ERC165 LOGIC
    //////////////////////////////////////////////////////////////*/

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 || // ERC165 Interface ID for ERC165
            interfaceId == 0x80ac58cd || // ERC165 Interface ID for ERC721
            interfaceId == 0x5b5e139f;
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL MINT/BURN LOGIC
    //////////////////////////////////////////////////////////////*/

    function _mint(address to, uint256 id) internal virtual {
        require(to != address(0), "INVALID_RECIPIENT");

        require(_ownerOf[id] == address(0), "ALREADY_MINTED");

        // Counter overflow is incredibly unrealistic.
        unchecked {
            _balanceOf[to]++;
        }

        _ownerOf[id] = to;

        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal virtual {
        address owner = _ownerOf[id];

        require(owner != address(0), "NOT_MINTED");

        // Ownership check above ensures no underflow.
        unchecked {
            _balanceOf[owner]--;
        }

        delete _ownerOf[id];

        delete getApproved[id];

        emit Transfer(owner, address(0), id);
    }

    /*//////////////////////////////////////////////////////////////
                        INTERNAL SAFE MINT LOGIC
    //////////////////////////////////////////////////////////////*/

    function _safeMint(address to, uint256 id) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(_msgSender(), address(0), id, "") ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }

    function _safeMint(
        address to,
        uint256 id,
        bytes memory data
    ) internal virtual {
        _mint(to, id);

        require(
            to.code.length == 0 ||
                ERC721TokenReceiver(to).onERC721Received(_msgSender(), address(0), id, data) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "UNSAFE_RECIPIENT"
        );
    }
}

/// @notice A generic interface for a contract which properly accepts ERC721 tokens.
/// @author Solmate (https://github.com/Rari-Capital/solmate/blob/main/src/tokens/ERC721.sol)
abstract contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}

/** 
 *  SourceUnit: c:\Users\PC\Documents\flip-sc\src\sc\contracts\NftCollectionGenArtV3.sol
*/

// contracts/GameItems.sol
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
pragma solidity >=0.8.4;

////import "./ERC721/SERC721Meta.sol";
////import '@openzeppelin/contracts/utils/Strings.sol';
////import "./Structs.sol";
////import './OS-on-chain-royalties/OperatorFilter.sol';
contract FFNFTGenArtV3 is ERC721, Structs, OperatorFilter {
    using Strings for uint256;

    uint256 public immutable MAX_AMOUNT_TOTAL;

    string private _contractURI;
    string private _tokenURI;
    address public owner;
    address public spliter;
    address public metaApprovedOperator;

    address constant DEFAULT_SUBSCRIPTION = address(0x3cc6CddA760b79bAfa08dF41ECFA224f810dCeB6);
    
    uint256 public royaltyBps;

    mapping(bytes32 => uint256) public rarityByCount;
    mapping(bytes32 => uint256) public rarityByMax;
    mapping(bytes32 => uint256) public rarityByIndex;

    event RoyaltyUpdated(uint256 royalty);

    modifier onlyOwner {
        require(_msgSender() == owner, "NOT THE OWNER");
      _;
    }
    
    constructor(
        string memory name, 
        string memory symbol,
        URI memory uri,
        Royalty memory _royalty,
        Rarities[] memory rarities
        ) ERC2771Context(0xDA0bab807633f07f013f94DD0E6A4F96F8742B53) ERC721(name, symbol) OperatorFilter(DEFAULT_SUBSCRIPTION, true) {
        owner = _msgSender();
        uint256 _maxAmount;
        _tokenURI = uri._tokenUri;
        _contractURI = uri._contractUri;
        uint256 index;
        require(type(uint8).max > rarities.length, "PREVENT OVERFLOW");
        for(uint8 i = 0; i < rarities.length;) {
            uint256 amount = rarities[i].amounts;
            rarityByMax[rarities[i].rarity] = amount; 
            _maxAmount = _maxAmount + amount;
            
            unchecked {  
                rarityByIndex[rarities[i].rarity] = index;
                index = index + amount;
                i++;
            }
        }
        metaApprovedOperator = 0x58807baD0B376efc12F5AD86aAc70E78ed67deaE;
        royaltyBps = _royalty._royaltyBps;
        spliter = _royalty._spliter;
        MAX_AMOUNT_TOTAL = _maxAmount;
    }

    function mintToken(address[] calldata _destinataries, uint256[] calldata _ids, bytes32[] calldata _rarities) external onlyOwner {
        for(uint256 i=0; i<_destinataries.length;) {
            bytes32 _rarity = _rarities[i];
            uint256 _innerTokenId = _ids[i];
            uint256 _countId = rarityByCount[_rarity];
            
            //REPLACE FOR CUSTOM ERROR TO MARK WHEN IT FAILED AND REQUEUE FROM THAT INDEX
            require(_countId <= rarityByMax[_rarity], "REACHED FULL MAX IN A RARITY");

            _safeMint(_destinataries[i], _innerTokenId);

            unchecked {
                i++;
                _countId++;
            }

            rarityByCount[_rarity] = _countId;
        }     
    }

    function setOwner(address newOwner) external onlyOwner {
        owner = newOwner;
    }

    function setMetaApprovedOperator(address newMetaApprovedOperator) external onlyOwner {
        metaApprovedOperator = newMetaApprovedOperator;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return string(abi.encodePacked(_tokenURI, "/", id.toString(), ".json"));
    }

    function contractURI() public view returns (string memory) {
        return _contractURI;
    }

    function setTokenURI(string calldata uri) external onlyOwner {
        _tokenURI = uri;
    }

    function setContractURI(string calldata uri) external onlyOwner {
        _contractURI = uri;
    }

    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount)
    {
        return (spliter, (_salePrice * royaltyBps)/10000);
    }

    function setRoyaltyBps(uint256 _royaltyBps) public onlyOwner {

        require(_royaltyBps < 10000, "EXCEDS 10000 BPS");

        royaltyBps = _royaltyBps;

        emit RoyaltyUpdated(_royaltyBps);
    }

    function supportsInterface(bytes4 interfaceId) public view override returns (bool) {
        return
            interfaceId == 0x2a55205a || 
            super.supportsInterface(interfaceId); 
    }

    function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
        if (_operator == address(metaApprovedOperator)) {
            return true;
        }
        
        return  _isApprovedForAll[_owner][_operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data)
        public
        override
        onlyAllowedOperator(from)
    {
        super.safeTransferFrom(from, to, tokenId, data);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public override onlyAllowedOperator(from) {
        super.safeTransferFrom(from, to, tokenId);
    }

    
}

//[
//["0x4c494d4954454400000000000000000000000000000000000000000000000000", "1000"], 
//["0x5241524500000000000000000000000000000000000000000000000000000000", "100"], 
//["0x4558545241205241524500000000000000000000000000000000000000000000", "10"], 
//["0x4c4547454e444152590000000000000000000000000000000000000000000000", "1"]]
//["ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq", "hello"] 


//[["0x4c494d4954454400000000000000000000000000000000000000000000000000","1000"],["0x5241524500000000000000000000000000000000000000000000000000000000","100"],["0x4558545241205241524500000000000000000000000000000000000000000000","10"],["0x4c4547454e444152590000000000000000000000000000000000000000000000","1"]]
//[["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0x5241524500000000000000000000000000000000000000000000000000000000"], ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4","0x4c494d4954454400000000000000000000000000000000000000000000000000"], ["0x5B38Da6a701c568545dCfcB03FcB875f56beddC4", "0x5241524500000000000000000000000000000000000000000000000000000000"]]