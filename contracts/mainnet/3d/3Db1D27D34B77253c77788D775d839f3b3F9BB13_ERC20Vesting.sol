// SPDX-License-Identifier: MIT
/**
    * File Token Vesting.
    */

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IERC20Vesting.sol";

/**
* @dev This contract is part of DeNetFileToken Contract. Issued every year from 1 
*/
contract ERC20Vesting  is IERC20Vesting, Ownable {

    address  private immutable _vestingToken;

    constructor (address _token) {
        _vestingToken = _token;
    }
    
    struct VestingProfile {
        uint64 timeStart;
        uint64 timeEnd;
        uint256 amount;
        uint256 payed;
    }
    

    mapping (address => VestingProfile) public vestingStatus;
    mapping (address => mapping(address => bool)) public allowanceVesting;
    
    // Just getter for origin token address
    function vestingToken() public view override returns(address){
        return _vestingToken;
    }
    /**
        * @notice Creating vesting for _user
        * @param _user address of reciever
        * @param timeStart timestamp of start vesting date
        * @param amount total amount of token for vesting 
        */
    function createVesting(address _user,  uint64 timeStart, uint64 timeEnd, uint256 amount) public onlyOwner {
        require(_user != address(0), "Address = 0");
        require(vestingStatus[_user].timeStart == 0, "User already have vesting");
        require(amount != 0, "Amount = 0");
        require(timeStart < timeEnd, "TimeStart > TimeEnd");
        require(timeEnd > block.timestamp, "Time end < block.timestamp");

        vestingStatus[_user] = VestingProfile(timeStart, timeEnd, amount, 0);
    }

    /**
        * @dev  Return available balance to withdraw
        * @param _user reciever address
        * @return uint256 amount of tokens available to withdraw for this moment
        */
    function getAmountToWithdraw(address _user) public view override returns(uint256) {
        VestingProfile memory _tmpProfile = vestingStatus[_user];
        
        // return 0, if user not exist. (because not possible to create zeor amount in vesting)
        if (_tmpProfile.amount == 0) {
            return 0;
        }

        if (_tmpProfile.timeStart > block.timestamp) {
            return 0;
        }
        uint _vestingPeriod = _tmpProfile.timeEnd - (_tmpProfile.timeStart);
        uint _amount = _tmpProfile.amount / (_vestingPeriod);
        if (_tmpProfile.timeEnd > block.timestamp) {
            _amount = _amount * (block.timestamp - (_tmpProfile.timeStart));
        } else {
            _amount = _tmpProfile.amount;
        }
        return _amount - (_tmpProfile.payed);
    }

    /**
        * @dev Withdraw tokens function
        */
    function _withdraw(address _user) internal {
        uint _amount = getAmountToWithdraw(_user);
        vestingStatus[_user].payed = vestingStatus[_user].payed + (_amount);

        IERC20 tok = IERC20(_vestingToken);
        require (tok.transfer(_user, _amount) == true, "ERC20Vesting._withdraw:Error with _withdraw.transfer");
        
        emit Vested(_user, _amount);
    }

    /**
        * @dev Withdraw for msg.sender
        */
    function withdraw() external override {
        _withdraw(msg.sender);
    }

    /**
        * @dev Withdraw for Approved Address
        */
    function withdrawFor(address _for) external override {
        require(allowanceVesting[_for][msg.sender], "ERC20Vesting.withdrawFor: Not Approved");
        _withdraw(_for);
    }

    /**
        * @dev Approve for withdraw for another address
        */
    function approveVesting(address _to) external override {
        allowanceVesting[msg.sender][_to] = true;
    }

    /**
        * @dev Stop approval for withdraw for another address
        */
    function stopApproveVesting(address _to) external override {
        allowanceVesting[msg.sender][_to] = false;
    }
}

// SPDX-License-Identifier: MIT
/*
    Created by DeNet
    
    Interface for ERC20Vesting 
*/

pragma solidity ^0.8.0;

interface IERC20Vesting {

    event Vested(address indexed to, uint256 value);

    function vestingToken() external view returns(address);

    function getAmountToWithdraw(address _user) external view returns(uint256);

    function withdraw() external;

    function withdrawFor(address _for) external;

    function approveVesting(address _to) external;

    function stopApproveVesting(address _to) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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