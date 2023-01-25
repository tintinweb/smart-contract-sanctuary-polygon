// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IZodiacArbitrator {
    function getDisputeFee(bytes32 question_id) external view returns (uint256);
    function requestArbitration(bytes32 question_id, uint256 max_previous) external payable;

    function realitio() external view returns (address);
    function metadata() external view returns (string memory);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";

interface IZodiacReality {
    /// TODO
    function getTransactionHash(address to, uint256 value, bytes memory data, Enum.Operation operation, uint256 nonce) external view returns (bytes32);
    /// @notice Notify the contract that the arbitrator has been paid for a question, freezing it pending their decision.
    /// @dev The arbitrator contract is trusted to only call this if they've been paid, and tell us who paid them.
    /// @param question_id The ID of the question
    /// @param requester The account that requested arbitration
    /// @param max_previous If specified, reverts if a bond higher than this was submitted after you sent your transaction.
    function notifyOfArbitrationRequest(bytes32 question_id, address requester, uint256 max_previous) external;

    /// @notice Submit the answer for a question, for use by the arbitrator.
    /// @dev Doesn't require (or allow) a bond.
    /// If the current final answer is correct, the account should be whoever submitted it.
    /// If the current final answer is wrong, the account should be whoever paid for arbitration.
    /// However, the answerer stipulations are not enforced by the contract.
    /// @param question_id The ID of the question
    /// @param answer The answer, encoded into bytes32
    /// @param answerer The account credited with this answer for the purpose of bond claims
    function submitAnswerByArbitrator(bytes32 question_id, bytes32 answer, address answerer) external;

    function getBestAnswer(bytes32 question_id) external view returns (bytes32);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/IZodiacArbitrator.sol";
import "../interfaces/IZodiacReality.sol";

// Owner is the arbitrating body (eg Some Council Gnosis Safe)

contract Arbitrator is IZodiacArbitrator, Ownable {
    uint256 public disputeFee;
    address public immutable realitio;
    string public metadata;

    mapping(bytes32 => address) arbitrationRequester;

    event ArbitrationRequested(bytes32 indexed questionId, address indexed requester);
    event BestAnswerConfirmed(bytes32 indexed questionId, address indexed winner);
    event BestAnswerOverturned(bytes32 indexed questionId, address indexed winner);

    constructor(uint256 _disputeFee, address _zodiacReality, string memory _metadata) {
        require(_disputeFee > 0, "Dispute fee cannot be 0");
        disputeFee = _disputeFee;
        realitio = _zodiacReality;
        metadata = _metadata;
    }

    function setDisputeFee(uint256 _disputeFee) external onlyOwner {
        require(_disputeFee > 0, "Dispute fee cannot be 0");
        disputeFee = _disputeFee;
    }

    function getDisputeFee(bytes32) external view returns (uint256) {
        return disputeFee;
    }

    // anyone calls to request arbitration of question.
    // make sure to pass the current bond as max_previous in case someone posts a bond for the correct answer (in the opinion of the requester) before this tx is mined
    function requestArbitration(bytes32 question_id, uint256 max_previous) external payable override {
        require(msg.value == disputeFee, "Incorrect fee");

        arbitrationRequester[question_id] = msg.sender;

        IZodiacReality(realitio).notifyOfArbitrationRequest(question_id, msg.sender, max_previous);
        
        payable(owner()).transfer(msg.value);

        emit ArbitrationRequested(question_id, msg.sender);
    }

    function confirmBestAnswer(bytes32 questionId, address answerer) external onlyOwner {
        IZodiacReality(realitio).submitAnswerByArbitrator(questionId, IZodiacReality(realitio).getBestAnswer(questionId), answerer);

        emit BestAnswerConfirmed(questionId, answerer);
    }

    function overturnBestAnswer(bytes32 questionId) external onlyOwner {
        bytes32 bestAnswer = IZodiacReality(realitio).getBestAnswer(questionId);
        bytes32 newAnswer = bestAnswer == bytes32(0) ? bytes32(uint256(1)) : bytes32(0);
        address requester = arbitrationRequester[questionId];
        IZodiacReality(realitio).submitAnswerByArbitrator(questionId, newAnswer, requester);

        emit BestAnswerOverturned(questionId, requester);
    }
}