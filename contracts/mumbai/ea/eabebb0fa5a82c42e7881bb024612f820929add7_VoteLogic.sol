// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/access/Ownable.sol";
import "../../interfaces/IXToken.sol";

// | |/ /_ _| \ | |__  /  / \   
// | ' / | ||  \| | / /  / _ \  
// | . \ | || |\  |/ /_ / ___ \ 
// |_|\_\___|_| \_/____/_/   \_\


/// @notice XKZA - Kinza protocol VoteLogic
/// @title VoteLogic
/// @notice VoteLogic is a contract that calculates the voting power of a user
///         based on the xKZA balance
///         and the redeeming position (with some discount)
contract VoteLogic is Ownable {

    /*//////////////////////////////////////////////////////////////
                        CONSTANTS & IMMUTABLES
    //////////////////////////////////////////////////////////////*/
    uint256 private constant PRECISION = 10000;
    IXToken public immutable XToken;

    /*//////////////////////////////////////////////////////////////
                        STORAGE VAARIABLE
    //////////////////////////////////////////////////////////////*/

    // XToken in the process of redeem is counted only as 50%.
    uint256 public countAs = 5000;

    /*//////////////////////////////////////////////////////////////
                              EVENTS
    //////////////////////////////////////////////////////////////*/
    event NewDiscountAs(uint256 newCountAs);

    constructor(
        address _xKZA,
        address _governance
    ) {
        XToken = IXToken(_xKZA);
        transferOwnership(_governance);

    }

    /*//////////////////////////////////////////////////////////////
                         OWNABLE FUNCTION
    //////////////////////////////////////////////////////////////*/
    /// @param _newCountAs new ratio for the xToken on voting
    function updateCountAs(uint256 _newCountAs) external onlyOwner {
        require(_newCountAs <= PRECISION, "discount out of bound");
        countAs = _newCountAs;
        emit NewDiscountAs(_newCountAs);
    }

    /// @notice return a balance accounting xToken balance and 
    ///         redeeming position with discount
    /// @return total balance 
    function balanceOf(address _xTokenHolder) public view returns(uint256) {
        uint256 currentBalance = XToken.balanceOf(_xTokenHolder);

        uint256 length = XToken.getUserRedeemsLength(_xTokenHolder);
        // no redeeming position
        if (length == 0) {
          return currentBalance;  
        // have redeem position
        } else {
            uint256 xTokenInRedeem;
            for (uint256 i; i < length ; ++i) {
                (,uint256 xAmount,) = XToken.getUserRedeem(_xTokenHolder, i);
                xTokenInRedeem += xAmount;
            }
            return currentBalance + xTokenInRedeem * countAs / PRECISION;
        }
        
    }
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

interface IXToken {
    function balanceOf(address _user) view external returns(uint256);
    function getUserRedeemsLength(address _user) view external returns(uint256);
    function getUserRedeem(address _user, uint256 _index) view external returns (uint256 amount, uint256 xAmount, uint256 endTime);

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