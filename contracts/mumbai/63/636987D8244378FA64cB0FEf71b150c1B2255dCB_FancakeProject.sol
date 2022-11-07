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
pragma solidity ^0.8.0;

// import Ownable
import "@openzeppelin/contracts/access/Ownable.sol";

contract FancakeProject is Ownable {
    // define a struct
    struct Project {
        string title;
        uint256 goal;
        uint256 deadline;
        bool isOngoing;
    }

    struct Contract {
        address governanceToken;
        address vote;
    }

    // mapping
    mapping(uint256 => Project) public projects; // tokenId => Project
    mapping(uint256 => Contract) public contracts; // tokenId => Contracts

    // define a counter
    uint256 public projectCount;
    uint256 public contractCount;

    // define an event
    event ProjectSetted(
        uint256 indexed tokenId,
        string title,
        uint256 goal,
        uint256 deadline,
        bool isOngoing,
        uint256 timestamp
    );

    event ContractSetted(
        uint256 indexed tokenId,
        address governanceToken,
        address vote,
        uint256 timestamp
    );

    // define a function
    /** setProject */
    function setProject(
        uint256 _tokenId,
        string memory _title,
        uint256 _goal,
        uint256 _deadline,
        bool _isOngoing
    ) public onlyGovernance(_tokenId) {
        projects[_tokenId] = Project(_title, _goal, _deadline, _isOngoing);
        projectCount++;
        emit ProjectSetted(_tokenId, _title, _goal, _deadline, _isOngoing, block.timestamp);
    }

    /** setContract */
    function setContract(
        uint256 _tokenId,
        address _governanceToken,
        address _vote
    ) public onlyOwner {
        contracts[_tokenId] = Contract(_governanceToken, _vote);
        contractCount++;
        emit ContractSetted(_tokenId, _governanceToken, _vote, block.timestamp);
    }

    modifier onlyGovernance(uint256 _tokenId) {
        require(msg.sender == contracts[_tokenId].vote, "Only governance contract can call this function.");
        _;
    }
}