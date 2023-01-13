// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
// !! THIS FILE WAS AUTOGENERATED BY abi-to-sol v0.6.6. SEE SOURCE BELOW. !!
pragma solidity >=0.7.0 <0.9.0;
pragma experimental ABIEncoderV2;

interface IERC721CollectionV2 {
    event AddItem(uint256 indexed _itemId, ERC721BaseCollectionV2.Item _item);
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
    event BaseURI(string _oldBaseURI, string _newBaseURI);
    event Complete();
    event CreatorshipTransferred(
        address indexed _previousCreator,
        address indexed _newCreator
    );
    event Issue(
        address indexed _beneficiary,
        uint256 indexed _tokenId,
        uint256 indexed _itemId,
        uint256 _issuedId,
        address _caller
    );
    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );
    event RescueItem(
        uint256 indexed _itemId,
        string _contentHash,
        string _metadata
    );
    event SetApproved(bool _previousValue, bool _newValue);
    event SetEditable(bool _previousValue, bool _newValue);
    event SetGlobalManager(address indexed _manager, bool _value);
    event SetGlobalMinter(address indexed _minter, bool _value);
    event SetItemManager(
        uint256 indexed _itemId,
        address indexed _manager,
        bool _value
    );
    event SetItemMinter(
        uint256 indexed _itemId,
        address indexed _minter,
        uint256 _value
    );
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );
    event UpdateItemData(
        uint256 indexed _itemId,
        uint256 _price,
        address _beneficiary,
        string _metadata
    );

    function COLLECTION_HASH() external view returns (bytes32);

    function ISSUED_ID_BITS() external view returns (uint8);

    function ITEM_ID_BITS() external view returns (uint8);

    function MAX_ISSUED_ID() external view returns (uint216);

    function MAX_ITEM_ID() external view returns (uint40);

    function addItems(ERC721BaseCollectionV2.ItemParam[] memory _items)
        external;

    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function baseURI() external view returns (string memory);

    function batchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds
    ) external;

    function completeCollection() external;

    function createdAt() external view returns (uint256);

    function creator() external view returns (address);

    function decodeTokenId(uint256 _id)
        external
        pure
        returns (uint256 itemId, uint256 issuedId);

    function domainSeparator() external view returns (bytes32);

    function editItemsData(
        uint256[] memory _itemIds,
        uint256[] memory _prices,
        address[] memory _beneficiaries,
        string[] memory _metadatas
    ) external;

    function encodeTokenId(uint256 _itemId, uint256 _issuedId)
        external
        pure
        returns (uint256 id);

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory);

    function getApproved(uint256 tokenId) external view returns (address);

    function getChainId() external pure returns (uint256);

    function getNonce(address user) external view returns (uint256 nonce);

    function globalManagers(address) external view returns (bool);

    function globalMinters(address) external view returns (bool);

    function initImplementation() external;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseURI,
        address _creator,
        bool _shouldComplete,
        bool _isApproved,
        address _rarities,
        ERC721BaseCollectionV2.ItemParam[] memory _items
    ) external;

    function isApproved() external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function isCompleted() external view returns (bool);

    function isEditable() external view returns (bool);

    function isInitialized() external view returns (bool);

    function isMintingAllowed() external view returns (bool);

    function issueTokens(
        address[] memory _beneficiaries,
        uint256[] memory _itemIds
    ) external;

    function itemManagers(uint256, address) external view returns (bool);

    function itemMinters(uint256, address) external view returns (uint256);

    function items(uint256)
        external
        view
        returns (
            string memory rarity,
            uint256 maxSupply,
            uint256 totalSupply,
            uint256 price,
            address beneficiary,
            string memory metadata,
            string memory contentHash
        );

    function itemsCount() external view returns (uint256);

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function rarities() external view returns (address);

    function renounceOwnership() external;

    function rescueItems(
        uint256[] memory _itemIds,
        string[] memory _contentHashes,
        string[] memory _metadatas
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] memory _tokenIds,
        bytes memory _data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setApproved(bool _value) external;

    function setBaseURI(string memory _baseURI) external;

    function setEditable(bool _value) external;

    function setItemsManagers(
        uint256[] memory _itemIds,
        address[] memory _managers,
        bool[] memory _values
    ) external;

    function setItemsMinters(
        uint256[] memory _itemIds,
        address[] memory _minters,
        uint256[] memory _values
    ) external;

    function setManagers(address[] memory _managers, bool[] memory _values)
        external;

    function setMinters(address[] memory _minters, bool[] memory _values)
        external;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenByIndex(uint256 index) external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256);

    function tokenURI(uint256 _tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256);

    function transferCreatorship(address _newCreator) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferOwnership(address newOwner) external;
}

interface ERC721BaseCollectionV2 {
    struct Item {
        string rarity;
        uint256 maxSupply;
        uint256 totalSupply;
        uint256 price;
        address beneficiary;
        string metadata;
        string contentHash;
    }

    struct ItemParam {
        string rarity;
        uint256 price;
        address beneficiary;
        string metadata;
    }
}

// THIS FILE WAS AUTOGENERATED FROM THE FOLLOWING ABI JSON:
/*
[{"inputs":[],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"_itemId","type":"uint256"},{"components":[{"internalType":"string","name":"rarity","type":"string"},{"internalType":"uint256","name":"maxSupply","type":"uint256"},{"internalType":"uint256","name":"totalSupply","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"},{"internalType":"address","name":"beneficiary","type":"address"},{"internalType":"string","name":"metadata","type":"string"},{"internalType":"string","name":"contentHash","type":"string"}],"indexed":false,"internalType":"struct ERC721BaseCollectionV2.Item","name":"_item","type":"tuple"}],"name":"AddItem","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"approved","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Approval","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"owner","type":"address"},{"indexed":true,"internalType":"address","name":"operator","type":"address"},{"indexed":false,"internalType":"bool","name":"approved","type":"bool"}],"name":"ApprovalForAll","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"string","name":"_oldBaseURI","type":"string"},{"indexed":false,"internalType":"string","name":"_newBaseURI","type":"string"}],"name":"BaseURI","type":"event"},{"anonymous":false,"inputs":[],"name":"Complete","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_previousCreator","type":"address"},{"indexed":true,"internalType":"address","name":"_newCreator","type":"address"}],"name":"CreatorshipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_beneficiary","type":"address"},{"indexed":true,"internalType":"uint256","name":"_tokenId","type":"uint256"},{"indexed":true,"internalType":"uint256","name":"_itemId","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"_issuedId","type":"uint256"},{"indexed":false,"internalType":"address","name":"_caller","type":"address"}],"name":"Issue","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"address","name":"userAddress","type":"address"},{"indexed":false,"internalType":"address","name":"relayerAddress","type":"address"},{"indexed":false,"internalType":"bytes","name":"functionSignature","type":"bytes"}],"name":"MetaTransactionExecuted","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"previousOwner","type":"address"},{"indexed":true,"internalType":"address","name":"newOwner","type":"address"}],"name":"OwnershipTransferred","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"_itemId","type":"uint256"},{"indexed":false,"internalType":"string","name":"_contentHash","type":"string"},{"indexed":false,"internalType":"string","name":"_metadata","type":"string"}],"name":"RescueItem","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"_previousValue","type":"bool"},{"indexed":false,"internalType":"bool","name":"_newValue","type":"bool"}],"name":"SetApproved","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"_previousValue","type":"bool"},{"indexed":false,"internalType":"bool","name":"_newValue","type":"bool"}],"name":"SetEditable","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_manager","type":"address"},{"indexed":false,"internalType":"bool","name":"_value","type":"bool"}],"name":"SetGlobalManager","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"_minter","type":"address"},{"indexed":false,"internalType":"bool","name":"_value","type":"bool"}],"name":"SetGlobalMinter","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"_itemId","type":"uint256"},{"indexed":true,"internalType":"address","name":"_manager","type":"address"},{"indexed":false,"internalType":"bool","name":"_value","type":"bool"}],"name":"SetItemManager","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"_itemId","type":"uint256"},{"indexed":true,"internalType":"address","name":"_minter","type":"address"},{"indexed":false,"internalType":"uint256","name":"_value","type":"uint256"}],"name":"SetItemMinter","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"from","type":"address"},{"indexed":true,"internalType":"address","name":"to","type":"address"},{"indexed":true,"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"Transfer","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"uint256","name":"_itemId","type":"uint256"},{"indexed":false,"internalType":"uint256","name":"_price","type":"uint256"},{"indexed":false,"internalType":"address","name":"_beneficiary","type":"address"},{"indexed":false,"internalType":"string","name":"_metadata","type":"string"}],"name":"UpdateItemData","type":"event"},{"inputs":[],"name":"COLLECTION_HASH","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"ISSUED_ID_BITS","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"ITEM_ID_BITS","outputs":[{"internalType":"uint8","name":"","type":"uint8"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_ISSUED_ID","outputs":[{"internalType":"uint216","name":"","type":"uint216"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"MAX_ITEM_ID","outputs":[{"internalType":"uint40","name":"","type":"uint40"}],"stateMutability":"view","type":"function"},{"inputs":[{"components":[{"internalType":"string","name":"rarity","type":"string"},{"internalType":"uint256","name":"price","type":"uint256"},{"internalType":"address","name":"beneficiary","type":"address"},{"internalType":"string","name":"metadata","type":"string"}],"internalType":"struct ERC721BaseCollectionV2.ItemParam[]","name":"_items","type":"tuple[]"}],"name":"addItems","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"approve","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"}],"name":"balanceOf","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"baseURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_from","type":"address"},{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256[]","name":"_tokenIds","type":"uint256[]"}],"name":"batchTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"completeCollection","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"createdAt","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"creator","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_id","type":"uint256"}],"name":"decodeTokenId","outputs":[{"internalType":"uint256","name":"itemId","type":"uint256"},{"internalType":"uint256","name":"issuedId","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[],"name":"domainSeparator","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"_itemIds","type":"uint256[]"},{"internalType":"uint256[]","name":"_prices","type":"uint256[]"},{"internalType":"address[]","name":"_beneficiaries","type":"address[]"},{"internalType":"string[]","name":"_metadatas","type":"string[]"}],"name":"editItemsData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"_itemId","type":"uint256"},{"internalType":"uint256","name":"_issuedId","type":"uint256"}],"name":"encodeTokenId","outputs":[{"internalType":"uint256","name":"id","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"userAddress","type":"address"},{"internalType":"bytes","name":"functionSignature","type":"bytes"},{"internalType":"bytes32","name":"sigR","type":"bytes32"},{"internalType":"bytes32","name":"sigS","type":"bytes32"},{"internalType":"uint8","name":"sigV","type":"uint8"}],"name":"executeMetaTransaction","outputs":[{"internalType":"bytes","name":"","type":"bytes"}],"stateMutability":"payable","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"getApproved","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getChainId","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"user","type":"address"}],"name":"getNonce","outputs":[{"internalType":"uint256","name":"nonce","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"globalManagers","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"","type":"address"}],"name":"globalMinters","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"initImplementation","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"_name","type":"string"},{"internalType":"string","name":"_symbol","type":"string"},{"internalType":"string","name":"_baseURI","type":"string"},{"internalType":"address","name":"_creator","type":"address"},{"internalType":"bool","name":"_shouldComplete","type":"bool"},{"internalType":"bool","name":"_isApproved","type":"bool"},{"internalType":"contract IRarities","name":"_rarities","type":"address"},{"components":[{"internalType":"string","name":"rarity","type":"string"},{"internalType":"uint256","name":"price","type":"uint256"},{"internalType":"address","name":"beneficiary","type":"address"},{"internalType":"string","name":"metadata","type":"string"}],"internalType":"struct ERC721BaseCollectionV2.ItemParam[]","name":"_items","type":"tuple[]"}],"name":"initialize","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"isApproved","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"address","name":"operator","type":"address"}],"name":"isApprovedForAll","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isCompleted","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isEditable","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isInitialized","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"isMintingAllowed","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address[]","name":"_beneficiaries","type":"address[]"},{"internalType":"uint256[]","name":"_itemIds","type":"uint256[]"}],"name":"issueTokens","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"address","name":"","type":"address"}],"name":"itemManagers","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"},{"internalType":"address","name":"","type":"address"}],"name":"itemMinters","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"","type":"uint256"}],"name":"items","outputs":[{"internalType":"string","name":"rarity","type":"string"},{"internalType":"uint256","name":"maxSupply","type":"uint256"},{"internalType":"uint256","name":"totalSupply","type":"uint256"},{"internalType":"uint256","name":"price","type":"uint256"},{"internalType":"address","name":"beneficiary","type":"address"},{"internalType":"string","name":"metadata","type":"string"},{"internalType":"string","name":"contentHash","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"itemsCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"name","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"owner","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"ownerOf","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"rarities","outputs":[{"internalType":"contract IRarities","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"renounceOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"_itemIds","type":"uint256[]"},{"internalType":"string[]","name":"_contentHashes","type":"string[]"},{"internalType":"string[]","name":"_metadatas","type":"string[]"}],"name":"rescueItems","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"_from","type":"address"},{"internalType":"address","name":"_to","type":"address"},{"internalType":"uint256[]","name":"_tokenIds","type":"uint256[]"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"safeBatchTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"},{"internalType":"bytes","name":"_data","type":"bytes"}],"name":"safeTransferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"operator","type":"address"},{"internalType":"bool","name":"approved","type":"bool"}],"name":"setApprovalForAll","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_value","type":"bool"}],"name":"setApproved","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"string","name":"_baseURI","type":"string"}],"name":"setBaseURI","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"_value","type":"bool"}],"name":"setEditable","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"_itemIds","type":"uint256[]"},{"internalType":"address[]","name":"_managers","type":"address[]"},{"internalType":"bool[]","name":"_values","type":"bool[]"}],"name":"setItemsManagers","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256[]","name":"_itemIds","type":"uint256[]"},{"internalType":"address[]","name":"_minters","type":"address[]"},{"internalType":"uint256[]","name":"_values","type":"uint256[]"}],"name":"setItemsMinters","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_managers","type":"address[]"},{"internalType":"bool[]","name":"_values","type":"bool[]"}],"name":"setManagers","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address[]","name":"_minters","type":"address[]"},{"internalType":"bool[]","name":"_values","type":"bool[]"}],"name":"setMinters","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes4","name":"interfaceId","type":"bytes4"}],"name":"supportsInterface","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"symbol","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"owner","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"tokenOfOwnerByIndex","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"_tokenId","type":"uint256"}],"name":"tokenURI","outputs":[{"internalType":"string","name":"","type":"string"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"totalSupply","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"_newCreator","type":"address"}],"name":"transferCreatorship","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"from","type":"address"},{"internalType":"address","name":"to","type":"address"},{"internalType":"uint256","name":"tokenId","type":"uint256"}],"name":"transferFrom","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"newOwner","type":"address"}],"name":"transferOwnership","outputs":[],"stateMutability":"nonpayable","type":"function"}]
*/

// SPDX-License-Identifier: UNLICENSED
/**
 * https://reward.tools Decentraland Wearable Airdrop Gas Balance contract
 */
pragma solidity ^0.8.9;
import "./IERC721CollectionV2.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RTGasStation is Ownable {

    struct SpendableGasBalance {
        uint256 balance;
        address owner;
        address[] approvedCollections;
    }

    using SafeMath for uint256;

    // Hot wallet must be approved as minter on WearableContract
    address public REWARD_TOOLS_HOT_WALLET =
        0xa1a548d34140B252C0F15Bd3C105d81F4a3dC678;

    // Beneficiary for fees deducted
    address public REWARD_TOOLS_BENEFICIARY =
        0x6A67773D8f80151673424e8FefbDf0C9D26Acb75;

    // Set the initial service fee bps to 5%
    uint256 public serviceFeeBps = 500;

    // Track approved collections
    address[] public approvedCollections;

    // Track approved owners
    address[] public approvedOwners;

    // Mapping to store the balance of each user
    mapping(address => SpendableGasBalance) public balances;

    modifier onlyDCLCollectionsThatApprovedRT(address collectionAddress) {
        IERC721CollectionV2 WearableContract = IERC721CollectionV2(
            collectionAddress
        );
        require(
            WearableContract.globalMinters(REWARD_TOOLS_HOT_WALLET) == true,
            "Reward.tools Hot Wallet must be set as Minter"
        );
        _;
    }

    modifier onlyCreatorOrManager(address collectionAddress) {
        IERC721CollectionV2 WearableContract = IERC721CollectionV2(
            collectionAddress
        );
        require(
            WearableContract.creator() == msg.sender ||
                WearableContract.globalManagers(msg.sender) == true,
            "This method is only available to creator or managers"
        );
        _;
    }

    constructor() {}

    // Function to deposit MATIC to the contract and approve a collection
    function depositGasAndApproveCollection(address collectionAddress)
        public
        payable
        onlyDCLCollectionsThatApprovedRT(collectionAddress)
        onlyCreatorOrManager(collectionAddress)
    {
        //Minimum deposit of 1 MATIC
        require(
            msg.value >= uint256(1 ether),
            "Must deposit 1 or more MATIC"
        );

        //Create placeholders if this is the first deposit
        if(balances[msg.sender].owner == address(0)){
            address[] memory approvedDrops = new address[](0);
            SpendableGasBalance memory newBalance = SpendableGasBalance(0, msg.sender, approvedDrops);
            balances[msg.sender] = newBalance;
        }

        //Add the owner to approved if they aren't already
        if(hasOwnerMadeInitialDeposit(msg.sender) == false){
            approvedOwners.push(msg.sender);
        }

        //Add the collection to approved if it isnt already
        if(isCollectionApprovedForGasDeductions(collectionAddress) == false){
            balances[msg.sender].approvedCollections.push(collectionAddress);
            approvedCollections.push(collectionAddress);
        }

        // Update the balance of the sender
        balances[msg.sender].balance += msg.value;
    }

    // Function to for owner to deduct Gas fees + service fee from a users balance
    function deductFee(address _user, uint256 gasTotal)
        external
        payable
        onlyOwner
    {
        // Calculate the service fee amount
        uint256 serviceFee = calculateServiceFee(gasTotal);
        uint256 totalCost = gasTotal.add(serviceFee);

        require(balances[_user].owner != address(0), "Target user is not registered");
        require(
            balances[_user].balance - totalCost >= uint256(0),
            "Insufficient user balance to deduct"
        );

        // Transfer the fees to the respective wallets
        (bool sentToHotWallet,) = REWARD_TOOLS_HOT_WALLET.call{value: totalCost.sub(serviceFee)}("");
        require(sentToHotWallet, "Failed to send MATIC to Hot Wallet");
        (bool sentToBeneficiary,) = REWARD_TOOLS_BENEFICIARY.call{value: serviceFee}("");
        require(sentToBeneficiary, "Failed to send MATIC to Beneficiary");

        // Deduct the total fees from the user's balance
        balances[_user].balance -= totalCost;
    }

    // Function for contract owner refund a user's balance less a service fee
    function refund(address payable _user) external payable onlyOwner {
        require(balances[_user].owner != address(0), "Target user is not registered");
        require(
            balances[_user].balance > uint256(0),
            "User has no balance to refund"
        );
        // The users total current balance
        uint256 bal = balances[_user].balance;

        // Calculate the service fee amount
        uint256 serviceFee = calculateServiceFee(bal);

        // Transfer the user's balance
        (bool sentToUser,) = _user.call{value: bal.sub(serviceFee)}("");
        require(sentToUser, "Failed to refund MATIC to User");
        (bool sentToBeneficiary,) = REWARD_TOOLS_BENEFICIARY.call{value: serviceFee}("");
        require(sentToBeneficiary, "Failed to send MATIC to Beneficiary");

        // Clear the user's balance
        balances[_user].balance = 0;
    }

    //Function to fetch an approved drop
    function isCollectionApprovedForGasDeductions(address collectionAddress)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < approvedCollections.length; ++i) {
            if(approvedCollections[i] == collectionAddress){
                return true;
            }
        }
        return false;
    }

    //Function to check if an owner has registered
    function hasOwnerMadeInitialDeposit(address _user)
        public
        view
        returns (bool)
    {
        for (uint256 i = 0; i < approvedOwners.length; ++i) {
            if(approvedOwners[i] == _user){
                return true;
            }
        }
        return false;
    }

    // Function to get the balance of a user
    function getGasBalance(address _user) public view returns (uint256) {
        // Return the user's balance
        return balances[_user].balance;
    }

    // Function to get the balance for a collection
    function getCollectionGasBalance(address _collectionAddress) public view returns (uint256) {
        // Find and return the collections balance
        for (uint256 i = 0; i < approvedOwners.length; ++i) {
            SpendableGasBalance memory balance = balances[approvedOwners[i]];
            for(uint256 o = 0; o < balance.approvedCollections.length; ++o){
                if(balance.approvedCollections[o] == _collectionAddress){
                    return balance.balance;
                }
            }
        }
        return uint256(0);
    }

    // Function to calculate transaction service fee - to cover gas for deductions 
    function calculateServiceFee(uint256 total) public view returns (uint256) {
        return total.mul(serviceFeeBps).div(10000);
    }

    // Function to set the service fee percentage (only available to the contract owner)
    function setServiceFeePercentage(uint256 _percentage) public onlyOwner {
        // Set the service fee percentage
        serviceFeeBps = _percentage;
    }

    // Function to allow owner to change hot wallet minter
    function setHotWalletMinter(address minter) public onlyOwner {
        REWARD_TOOLS_HOT_WALLET = minter;
    }

    // Function to allow owner to change beneficiary of fees
    function setFeeBeneficiary(address beneficiary) public onlyOwner {
        REWARD_TOOLS_BENEFICIARY = beneficiary;
    }
}