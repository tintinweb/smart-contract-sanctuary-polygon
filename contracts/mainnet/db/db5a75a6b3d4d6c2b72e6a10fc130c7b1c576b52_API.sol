// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable2Step.sol";

import "./lib/TokenStructs.sol";

contract API is Ownable2Step {
    address public protocol;

    error NotProtocolOrOwner(address account);

    mapping(address => string) public staticData;
    mapping(address => uint256) public tokenAssetId;
    Token[] public assets;
    mapping(uint256 => Token) public assetById;

    event NewListing(address indexed token, string ipfsHash);

    event NewAssetListing(Token token);

    modifier onlyProtocolAndOwner() {
        if (protocol != msg.sender && owner() != msg.sender) {
            revert NotProtocolOrOwner(msg.sender);
        }
        _;
    }

    constructor(address _protocol, address _owner) {
        protocol = _protocol;
        _transferOwnership(_owner);
    }

    function getAllAssets() external view returns (Token[] memory) {
        return assets;
    }

    function addStaticData(
        address token,
        string memory ipfsHash,
        uint256 assetId
    ) external onlyProtocolAndOwner {
        staticData[token] = ipfsHash;
        tokenAssetId[token] = assetId;
        emit NewListing(token, ipfsHash);
    }

    function addAssetData(Token memory token) external onlyProtocolAndOwner {
        assets.push(token);
        assetById[token.id] = token;

        emit NewAssetListing(token);
    }

    function removeStaticData(address token) external onlyOwner {
        delete staticData[token];
    }

    function setProtocolAddress(address _protocol) external onlyOwner {
        protocol = _protocol;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable2Step.sol)

pragma solidity ^0.8.0;

import "./Ownable.sol";

/**
 * @dev Contract module which provides access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership} and {acceptOwnership}.
 *
 * This module is used through inheritance. It will make available all functions
 * from parent (Ownable).
 */
abstract contract Ownable2Step is Ownable {
    address private _pendingOwner;

    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Returns the address of the pending owner.
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }

    /**
     * @dev Starts the ownership transfer of the contract to a new account. Replaces the pending transfer if there is one.
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual override onlyOwner {
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`) and deletes any pending owner.
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual override {
        delete _pendingOwner;
        super._transferOwnership(newOwner);
    }

    /**
     * @dev The new owner accepts the ownership transfer.
     */
    function acceptOwnership() public virtual {
        address sender = _msgSender();
        require(pendingOwner() == sender, "Ownable2Step: caller is not the new owner");
        _transferOwnership(sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
* @dev Enum to define a listing vote
* @custom:Accept Accept the Token
* @custom:Reject Reject the Token
* @custom:ModificationsNeeded Token needs modifications
*/
enum ListingVote {
    Accept,
    Reject,
    ModificationsNeeded
}

/**
* @dev Enum to define Listing status
* @custom:Init Initial Listing status
* @custom:Pool Token has been submitted
* @custom:Updating Submitter needs to update Token details
* @custom:Sorting RankI users can vote to sort this Token
* @custom:Validation RankII users can vote to validate this Token
* @custom:Validated Token has been validated and listed
* @custom:Rejected Token has been rejected
* @custom:Killed Token has been killed by owner
*/
enum ListingStatus {
    Init,
    Pool,
    Updating,
    Sorting,
    Validation,
    Validated,
    Rejected,
    Killed
}

/**
 * @custom:ipfsHash IPFS Hash of metadatas
 * @custom:id Attributed ID for the Token
 * @custom:lastUpdate Timestamp of Token's last update
 * @custom:utilityScore Token's utility score
 * @custom:socialScore Token's social score
 * @custom:trustScore Token's trust score
 */
// TODO : Use uint8 score type ?
struct Token {
    string ipfsHash;
    uint256 id;
    uint256 lastUpdate;
    uint256 utilityScore;
    uint256 socialScore;
    uint256 trustScore;
}

/**
 * @custom:token Token
 * @custom:coeff Listing coeff
 * @custom:status Listing status
 * @custom:submitter User who submitted the Token for listing
 * @custom:statusIndex Index of listing in corresponding statusArray
 * @custom:accruedUtilityScore Sum of voters utility score
 * @custom:accruedSocialScore Sum of voters social score
 * @custom:accruedTrustScore Sum of voters trust score
 * @custom:phase Phase count
 */
// TODO : Reorg for gas effiency 
struct TokenListing {
    Token token;
    uint256 coeff;
    ListingStatus status;
    address submitter;
    uint256 statusIndex;

    uint256 accruedUtilityScore;
    uint256 accruedSocialScore;
    uint256 accruedTrustScore;

    uint256 phase;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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