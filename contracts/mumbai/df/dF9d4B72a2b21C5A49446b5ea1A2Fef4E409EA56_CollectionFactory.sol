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
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
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
pragma solidity 0.8.18;

import './interfaces/ICollectionFactory.sol';
import './interfaces/IERC721Mintable.sol';
import './interfaces/IERC1155Mintable.sol';

import '@openzeppelin/contracts/access/Ownable.sol';

import './lib/Errors.sol';
import '@openzeppelin/contracts/proxy/Clones.sol';

/**
 * @title CollectionFactory
 * @author gotbit
 * @dev Contract for creating ERC721/ERC1155 mintable collections using
 * the openzeppelin/Clones library
 */
contract CollectionFactory is ICollectionFactory, Ownable {
    address public immutable erc721MintableImplementation;
    address public immutable erc1155MintableImplementation;

    string public baseURI;

    constructor(
        address erc721,
        address erc1155,
        string memory baseURI_,
        address owner
    ) {
        if (erc721 == address(0) || erc1155 == address(0) || owner == address(0))
            revert ZeroAddress();
        if (bytes(baseURI_).length == 0) revert EmptyBaseURI();

        erc721MintableImplementation = erc721;
        erc1155MintableImplementation = erc1155;
        baseURI = baseURI_;
        transferOwnership(owner);
    }

    /**
     * @dev Creates ERC721 mintable collection using `clone`
     * @param name ERC721 collection name
     * @param symbol ERC721 collection symbol
     * @return collection Address of the created collection
     */
    function createERC721Proxy(string memory name, string memory symbol)
        external
        returns (address collection)
    {
        if (bytes(name).length == 0) revert EmptyName();
        if (bytes(symbol).length == 0) revert EmptySymbol();

        collection = Clones.clone(erc721MintableImplementation);
        IERC721Mintable(collection).initialize(msg.sender, name, symbol);
        emit ERC721Created(msg.sender, collection);
    }

    /**
     * @dev Creates ERC1155 mintable collection using `clone`
     * @return collection Address of the created collection
     */
    function createERC1155Proxy() external returns (address collection) {
        collection = Clones.clone(erc1155MintableImplementation);
        IERC1155Mintable(collection).initialize(msg.sender);
        emit ERC1155Created(msg.sender, collection);
    }

    /**
     * @dev Sets the base URI for all created collections
     * @param baseURI_ Base URI
     */
    function updateBaseURI(string memory baseURI_) external onlyOwner {
        if (bytes(baseURI_).length == 0) revert EmptyBaseURI();
        baseURI = baseURI_;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title ICollectionFactory
 * @author gotbit
 * @dev Required the CollectionFactory contract interface
 */
interface ICollectionFactory {
    /**
     * @dev Emitted when new ERC721 mintable collection is created
     * @param creator ERC721 collection creator
     * @param collection Address of the created collection
     */
    event ERC721Created(address indexed creator, address indexed collection);

    /**
     * @dev Emitted when new ERC1155 mintable collection is created
     * @param creator ERC1155 collection creator
     * @param collection Address of the created collection
     */
    event ERC1155Created(address indexed creator, address indexed collection);

    /**
     * @dev Gets the base URI for all created collections
     * @return Base URI
     */
    function baseURI() external view returns (string memory);

    /**
     * @dev Creates ERC721 mintable collection using `clone`
     * @param name ERC721 collection name
     * @param symbol ERC721 collection symbol
     * @return Address of the created collection
     */
    function createERC721Proxy(string memory name, string memory symbol)
        external
        returns (address);

    /**
     * @dev Creates ERC1155 mintable collection using `clone`
     * @return Address of the created collection
     */
    function createERC1155Proxy() external returns (address);

    /**
     * @dev Sets the base URI for all created collections
     * @param baseURI Base URI
     */
    function updateBaseURI(string memory baseURI) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title IERC1155Mintable
 * @author gotbit
 */
interface IERC1155Mintable {
    /**
     * @dev Gets the address of the collection creator
     * @return Collection creator address
     */
    function creator() external view returns (address);

    /**
     * @dev Initializes the mintable ERC1155 proxy collection.
     * Called once by the CollectionFactory contract after deploying a proxy.
     * @param creator ERC1155 collection creator
     */
    function initialize(address creator) external;

    /**
     * @dev Mints ERC1155 tokens.
     * Called by the ExecutionDelegate contract.
     * @param to Address of the recipient
     * @param tokenId ERC1155 token id
     * @param amount ERC1155 token amount
     */
    function mint(
        address to,
        uint256 tokenId,
        uint256 amount
    ) external;

    /**
     * @dev Gets the URI of a specific token id.
     * The URI is the concatenation of the baseUri specified in the CollectionFactory
     * contract, the address of the collection and the token id.
     * @param tokenId ERC1155 token id
     * @return Token URI
     */
    function uri(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @title IERC721Mintable
 * @author gotbit
 * @dev Required the ERC721Mintable contract interface
 */
interface IERC721Mintable {
    /**
     * @dev Gets the address of the collection creator
     * @return Collection creator address
     */
    function creator() external view returns (address);

    /**
     * @dev Initializes the mintable ERC721 proxy collection.
     * Called once by the CollectionFactory contract after deploying a proxy.
     * @param creator ERC721 collection creator
     * @param name ERC721 collection name
     * @param symbol ERC721 collection symbol
     */
    function initialize(
        address creator,
        string memory name,
        string memory symbol
    ) external;

    /**
     * @dev Mints ERC721 tokens.
     * Called by the ExecutionDelegate contract.
     * @param to Address of the recipient
     * @param tokenId ERC721 token id
     */
    function mint(address to, uint256 tokenId) external;

    /**
     * @dev Gets the URI of a specific token id.
     * The URI is the concatenation of the baseUri specified in the CollectionFactory
     * contract, the address of the collection and the token id.
     * @param tokenId ERC721 token id
     * @return Token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {Direction} from './OrderStructs.sol';

/**
 * @dev Custom errors used in other contracts
 */
error ZeroAddress();
error WrongPaymentAmount();
error ZeroLengthArray();
error DifferentLengthArrays();
error WrongCaller();
error InvalidOrder(Direction direction);
error OrdersCantBeMatched();
error WrongSellOrderCreator();
error WrongSignature(bytes sig);
error OrderAlreadyCancelledOrCompleted();
error InvalidFee();
error FeesExceedPrice();
error InvalidCollection();
error EmptyBaseURI();
error EmptyName();
error EmptySymbol();
error RestrictedToMarket();
error InvalidLotDetails();
error InvalidTime();
error TooSmallBid();
error BidderIsSeller();
error WrongBidPaymentType();
error ClaimedAlready();
error NoBids();

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

/**
 * @dev Buy or sell order
 */
enum Direction {
    Buy,
    Sell
}

/**
 * @dev NFT type
 */
enum AssetType {
    ERC721,
    ERC1155
}

/**
 * @dev Fee paid to collection creator
 */
struct RoyaltyFee {
    uint256 rate;
    address receiver;
}

/**
 * @dev RoyaltyFee struct typehash for EIP712 compatibility
 */
bytes32 constant FEE_TYPEHASH = keccak256('RoyaltyFee(uint256 rate,address receiver)');

/**
 * @dev Order creator data
 */
struct Creator {
    address creator;
    uint256 nonce;
}

/**
 * @dev Creator struct typehash for EIP712 compatibility
 */
bytes32 constant CREATOR_TYPEHASH = keccak256('Creator(address creator,uint256 nonce)');

/**
 * @dev An order consists of thirteen components: the order direction (Buy or Sell),
 * the NFT type (721 or 1155), whether the NFT will be minted or transferred,
 * the creator address with its nonce, the nft collection address,
 * the tokenId to sell, the amount of tokenIds, the payment token address,
 * the price per one item, the order listing time, the order signature expiration
 * time, the information about royalties (royalty fee rate and royalty fee receiver) and
 * the salt from the backend.
 */
struct Order {
    Direction direction;
    AssetType assetType;
    bool mint;
    Creator creator;
    address collection;
    uint256 tokenId;
    uint256 amount;
    address paymentToken;
    uint256 price;
    uint256 listingTime;
    uint256 expirationTime;
    RoyaltyFee royaltyFee;
    uint256 salt;
}

/**
 * @dev Order struct typehash for EIP712 compatibility
 */
bytes32 constant ORDER_TYPEHASH = keccak256(
    abi.encodePacked(
        'Order(',
        'uint8 direction,',
        'uint8 assetType,',
        'bool mint,',
        'Creator creator,',
        'address collection,',
        'uint256 tokenId,',
        'uint256 amount,',
        'address paymentToken,',
        'uint256 price,',
        'uint256 listingTime,',
        'uint256 expirationTime,',
        'RoyaltyFee royaltyFee,',
        'uint256 salt',
        ')',
        'Creator(',
        'address creator,'
        'uint256 nonce',
        ')',
        'RoyaltyFee(',
        'uint256 rate,'
        'address receiver',
        ')'
    )
);

/**
 * @dev An order signed by the relayer
 */
struct Input {
    Order order;
    bytes signature;
}