pragma solidity ^0.8.7;

import "../interfaces/IRNG2.sol";
import "../interfaces/IRNG_single_requestor.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract randomV2test is IRNG_single_requestor, Ownable {


    IRNG2     rng;
    uint256  public response;

    event Requested(uint256 reqId);
    event Received(uint256 rand, uint256 requestId);

    constructor(IRNG2 r) {
        rng = r;
    }

    function process(uint256 rand, uint256 requestId) external override {
        require(msg.sender == address(rng),"Invalid source");
        response = rand;
        emit Received(rand,requestId);
    }

    function ask() external onlyOwner {
        uint256 _reqID = rng.requestRandomNumberWithCallback();
        emit Requested(_reqID);
    }

}

pragma solidity ^0.8.7;

interface IRNG2 {
    function requestRandomNumber( ) external returns (uint256);
    function requestRandomNumberWithCallback( ) external returns (uint256);
    function isRequestComplete(uint256 requestId) external view returns (bool isCompleted);
    function randomNumber(uint256 requestId) external view returns (uint256 randomNum);
    function setAuth(address user, bool grant) external;
    function requestRandomWords(uint32 numberOfWords, uint speed) external returns (uint256);
    function requestRandomWordsAdvanced(uint32 numberOfWords, uint speed , uint32 _callbackGasLimit, uint16 _requestConfirmations) external returns (uint256) ;
    function requestRandomWordsWithCallback(uint32 numberOfWords, uint speed) external returns (uint256);
    function requestRandomWordsAdvancedWithCallback(uint32 numberOfWords, uint speed, uint32 _callbackGasLimit, uint16 _requestConfirmations) external returns (uint256) ;

}

pragma solidity ^0.8.7;

interface IRNG_single_requestor {
    function process(uint256 rand, uint256 requestId) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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