// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "IKlimaRetirementAggregator.sol";
import "IERC20.sol";

import "Ownable.sol";

contract OneUpCuban is Ownable {

    uint public minDeposit;
    uint public targetAmount;
    uint public balance;
    uint public CubanCount;
    
    address public immutable KlimaRetirementAggregator;
    address public immutable BCT;

    mapping(uint => address) public winners;

    constructor() {

        KlimaRetirementAggregator = 0xEde3bd57a04960E6469B70B4863cE1c9d9363Cb8;
        BCT = 0x2F800Db0fdb5223b3C3f354886d907A671414A7F;
        targetAmount =  1000000000000000000 ; 
        minDeposit =    0; 
        
    }


    function deposit(uint amount) public {

        require(amount >= minDeposit, "Cannot deposit less than mindeposit");
        require(IERC20(BCT).allowance(msg.sender, address(this)) >= amount, "Contract must have sufficient spending allowance of BCT amount");

        IERC20(BCT).transferFrom(msg.sender, address(this), amount);
        
        updateBCTBalance();

        if (balance >= targetAmount) {

            _offsetBalance(targetAmount, "#1UpCuban", "Cuban was one-upped!");

            /* set winner */
            winners[CubanCount] = msg.sender;

            /* send remaining change to winner */
            _sendExtra();

            /* Increment Cuban count */
            CubanCount++;

        }

    }

    function updateBCTBalance() public {

        /* Update current contract balance of BCT */
        balance = IERC20(BCT).balanceOf(address(this));

    }

    function getBCTBalance() public view returns (uint bal) {

        /* return BCT balance */
        return balance;

    }

    function offsetBalanceOwner() onlyOwner public {
        
        _offsetBalance(balance, "#1UpCuban", "Cuban was not one-upped, but we made a difference!");

    }

    function changeTargetAmount(uint newTarget) onlyOwner public {

        targetAmount = newTarget;

    }

    function changeMinDeposit(uint newMinDeposit) onlyOwner public {

        minDeposit = newMinDeposit;

    }

    function _sendExtra() private {

        require(msg.sender == winners[CubanCount], "Not winner of current round - can't claim BCT changes");

        IERC20(BCT).transfer(msg.sender, balance);

        updateBCTBalance();
        
    }

    function _offsetBalance(uint offsetAmount, string memory beneficiary, string memory message) private {

        /* Retire the BCT */
        IERC20(BCT).approve(KlimaRetirementAggregator, offsetAmount);
        IKlimaRetirementAggregator(KlimaRetirementAggregator).retireCarbon(BCT, BCT, offsetAmount, false, msg.sender, beneficiary, message);
            
        updateBCTBalance();
        
    }

    

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IKlimaRetirementAggregator {
    function retireCarbon(address _sourceToken,address _poolToken,uint256 _amount,bool _amountInCarbon,address _beneficiaryAddress,string memory _beneficiaryString,string memory _retirementMessage) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "Context.sol";

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