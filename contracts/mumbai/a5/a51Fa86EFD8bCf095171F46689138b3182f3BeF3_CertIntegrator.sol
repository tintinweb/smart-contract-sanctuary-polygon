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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ICertIntegrator.sol";

/**
 *  @notice The Cert integrator contract
 *
 *  While the FeedbackRegistry contracts will be deployed on multiple chains, another contracts
 *  will only be present on its main chain. This contract is a Solidity contract that solves
 *  the previous problem. This contract will be deployed on the supported chains, and its purpose
 *  is to store and provide the ability to update data about courses and their participants from
 *  the chains. This data is the root of the Sparse Merkle tree that contains course participants.
 *  Whenever a certificate is issued or a new course is created, the CertIntegration service will
 *  update the data. This way, every instance of FeedbackRegistry on different chains will have
 *  the latest and most up-to-date data available.
 *
 *  Requirements:
 *
 *  - The ability to update the state for a specific course. It is only for a contract owner.
 *
 *  - The contract must store all roots, to avoid collision when the user generates a ZKP for
 *    a specific merkle root, but after several seconds this root is replaced by the CertIntegrator
 *    service. Also, the contract should bind up every state to the block number. It will provide
 *    an ability for external services to set some interval of blocks in which they will consider
 *    this state valid.
 */
contract CertIntegrator is Ownable, ICertIntegrator {
    // course name => data (root+block)
    mapping(bytes => Data[]) public contractData;

    /**
     * @inheritdoc ICertIntegrator
     */
    function updateCourseState(
        bytes[] memory courses_,
        bytes32[] memory states_
    ) external onlyOwner {
        uint256 coursesLength_ = courses_.length;

        require(
            coursesLength_ == states_.length,
            "CertIntegrator: courses and states arrays must be the same size"
        );

        for (uint256 i = 0; i < coursesLength_; i++) {
            Data memory newData_ = Data(block.number, states_[i]);
            contractData[courses_[i]].push(newData_);
        }
    }

    /**
     * @inheritdoc ICertIntegrator
     */
    function getData(bytes memory course_) external view returns (Data[] memory) {
        return contractData[course_];
    }

    /**
     * @inheritdoc ICertIntegrator
     */
    function getLastData(bytes memory course_) external view returns (Data memory) {
        uint256 length_ = contractData[course_].length;

        require(length_ > 0, "CertIntegrator: course info is empty");

        return contractData[course_][length_ - 1];
    }

    /**
     * @inheritdoc ICertIntegrator
     */
    function getDataLength(bytes memory course_) external view returns (uint256) {
        return contractData[course_].length;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.16;

interface ICertIntegrator {
    /**
     * Structure to store contract data:
     * merkle tree root and corresponding block number
     */
    struct Data {
        uint256 blockNumber;
        bytes32 root;
    }

    /**
     * @dev Updates the contract information abouts course states.
     *
     * This function takes two equal size arrays that contains courses
     * names and merkle tree roots (to identify whether the user in course).
     * Each root in the list corresponds to the course with such name.
     *
     * @param courses_ array with course names
     * @param states_ array with course states
     *
     * Requirements:
     *
     * - the `courses_` and `states_` arrays length must be equal.
     */
    function updateCourseState(bytes[] memory courses_, bytes32[] memory states_) external;

    /**
     * @dev Retrieves info by course name.
     *
     * @param course_ course name to retrieve info
     * @return Data[] with all states for course
     */
    function getData(bytes memory course_) external view returns (Data[] memory);

    /**
     * @dev Retrieves last info by course name.
     *
     * @param course_ course name to retrieve info
     * @return Data with last state for course
     */
    function getLastData(bytes memory course_) external view returns (Data memory);

    /**
     * @dev Retrieves info length by course name.
     *
     * @param course_ course name to retrieve info length
     * @return uint256 amount of Data[] elements
     */
    function getDataLength(bytes memory course_) external view returns (uint256);
}