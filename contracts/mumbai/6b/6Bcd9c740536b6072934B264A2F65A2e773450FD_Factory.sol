/*
Factory

https://github.com/0chain/nft-dstorage-core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/IFactory.sol";
import "./interfaces/IFactoryModule.sol";
import "./interfaces/IDStorageERC721.sol";

contract Factory is IFactory, Ownable {
    // events
    event TokenCreated(
        address indexed module,
        address indexed owner,
        address token
    );
    event ModuleRegistered(address indexed module, bool status);

    // fields
    address[] public tokenList;
    mapping(address => bool) public tokenMapping;
    mapping(address => bool) public moduleRegistry;

    /**
     * @inheritdoc IFactory
     */
    function create(
        address module,
        string calldata name,
        string calldata symbol,
        string calldata uri,
        uint256 max,
        uint256 price,
        uint256 batch,
        bytes calldata data
    ) external returns (address) {
        // verify module
        require(moduleRegistry[module], "Factory: module not registered");

        // create nft
        address addr = IFactoryModule(module).createToken(
            msg.sender,
            name,
            symbol,
            uri,
            max,
            price,
            batch,
            data
        );

        // accounting
        tokenList.push(addr);
        tokenMapping[addr] = true;

        // output
        emit TokenCreated(module, msg.sender, addr);
        return addr;
    }

    /**
     * @notice set the registry status of a factory module
     * @param module address of module
     * @param status updated registry status
     */
    function register(address module, bool status) external onlyOwner {
        require(module != address(0), "Factory: module address cannot be zero");
        moduleRegistry[module] = status;
        emit ModuleRegistered(module, status);
    }

    /**
     * @return total number of tokens created by the factory
     */
    function count() public view returns (uint256) {
        return tokenList.length;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/*
IDStorageERC721

https://github.com/0chain/nft-dstorage-core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.9;

import "@openzeppelin/contracts/interfaces/IERC721Metadata.sol";
import "@openzeppelin/contracts/interfaces/IERC2981.sol";

/**
 * @title dStorage ERC721 interface
 *
 * @notice this defines the interface for the base dStorage ERC721 token contract
 */
interface IDStorageERC721 is IERC721Metadata, IERC2981 {
    /**
     * @notice mint tokens as admin
     * @param amount number of tokens to mint
     */
    function mintOwner(uint256 amount) external;

    /**
     * @notice mint tokens as standard public user
     * @param amount number of tokens to mint
     */
    function mint(uint256 amount) external payable;

    /**
     * @notice get price to mint token
     */
    function price() external view returns (uint256);

    /**
     * @notice get total token supply
     */
    function total() external view returns (uint256);

    /**
     * @notice get max token supply
     */
    function max() external view returns (uint256);

    /**
     * @notice get max token mint batch size
     */
    function batch() external view returns (uint256);

    /**
     * @notice get fallback Uniform Resource Identifier (URI) for `tokenId` token
     * @param tokenId token ID of interest
     */
    function tokenURIFallback(uint256 tokenId)
        external
        view
        returns (string memory);

    /**
     * @notice set royalty receiver for ERC2981
     * @param receiver new royalty receiver
     */
    function setReceiver(address receiver) external;
}

/*
IFactoryModule

https://github.com/0chain/nft-dstorage-core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.9;

/**
 * @title Factory module interface
 *
 * @notice this defines the interface for a module which creates a specific
 * version of the dStorage NFT contract
 */
interface IFactoryModule {
    /**
     * @notice create a new nft contract
     * @param owner user address
     * @param name token name
     * @param symbol token symbol
     * @param uri original base token uri
     * @param max max token supply
     * @param price token mint price
     * @param batch max token mint batch size
     * @param data additional encoded data
     * @return address of newly created token
     */
    function createToken(
        address owner,
        string calldata name,
        string calldata symbol,
        string calldata uri,
        uint256 max,
        uint256 price,
        uint256 batch,
        bytes calldata data
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

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

/*
IFactory

https://github.com/0chain/nft-dstorage-core

SPDX-License-Identifier: MIT
*/

pragma solidity 0.8.9;

/**
 * @title Factory interface
 *
 * @notice this defines the interface for the main factory contract
 */
interface IFactory {
    /**
     * @notice create a new dStorage NFT contract
     * @param module address of factory module
     * @param name token name
     * @param symbol token symbol
     * @param uri original base token uri
     * @param max max token supply
     * @param price token mint price
     * @param batch max token mint batch size
     * @param data additional encoded data
     * @return address of newly created token
     */
    function create(
        address module,
        string calldata name,
        string calldata symbol,
        string calldata uri,
        uint256 max,
        uint256 price,
        uint256 batch,
        bytes calldata data
    ) external returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Metadata.sol";

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Called with the sale price to determine how much royalty is owed and to whom.
     * @param tokenId - the NFT asset queried for royalty information
     * @param salePrice - the sale price of the NFT asset specified by `tokenId`
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for `salePrice`
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}