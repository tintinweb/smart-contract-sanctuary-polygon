// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "IKlimaRetirementAggregator.sol";
import "IERC20.sol";

import "Ownable.sol";
import "Offsetter.sol";

contract LiveOffset is Ownable, Offsetter {

    uint private _offsetPerLetter; /* 1000000000000000000 is 1 tonne */
    string private _eventName;
    string private _eventMessage;
    address private _eventBeneficiaryAddress;
    address private _carbonToken;
    bool private _retireSpecific;
    address private _specificAddress;

    address public immutable KlimaRetirementAggregator;

    /** === Event Setup === */
    event LiveOffsetEventUpdate(
        uint _offsetPerLetter,
        string _eventName,
        string _eventMessage,
        address _eventBeneficiaryAddress,
        address _carbonToken,
        bool _retireSpecific,
        address _specificAddress
    );

    constructor() {

        KlimaRetirementAggregator = 0xEde3bd57a04960E6469B70B4863cE1c9d9363Cb8;
        
    }

    function withdrawBalanceOwner() onlyOwner public {

        /* withdraw unused event offsets */
        
        uint balance = IERC20(_carbonToken).balanceOf(address(this));
        IERC20(_carbonToken).transfer(msg.sender, balance);

    }

    function singleOffset() onlyOffsetter public {

        /* simgle offset on behalf of the event */
        _executeOffset(_offsetPerLetter);

    }

    function offsetBalanceOwner() onlyOwner public {

        /* offset balance on behalf of the event */
        
        uint balance = IERC20(_carbonToken).balanceOf(address(this));
        uint offsetMax = balance * 99 / 100;
        _executeOffset(offsetMax); /*account for aggregator fee */

    }

    function _executeOffset(uint amount) private {

        uint balance = IERC20(_carbonToken).balanceOf(address(this));

        if (amount == 0) {
            amount = _offsetPerLetter;
        }

        require(balance >= amount, "All offsets allocated for the event have been used!");

        /* Retire through aggregator */
            
        /*
        if retireSpecific is true {
            IKlimaRetirementAggregator(KlimaRetirementAggregator).retireCarbonSpecific(
                _carbonToken, _carbonToken, amount, false, _eventBeneficiaryAddress, _eventName, _eventMessage, [_specificAddress]);
        } else {
            IKlimaRetirementAggregator(KlimaRetirementAggregator).retireCarbon(
                _carbonToken, _carbonToken, amount, false, _eventBeneficiaryAddress, _eventName, _eventMessage);
        }*/

    }

    /* Change params */
    function changeEventParams(address CarbonToken, address eventBeneficiaryAddress, 
        string memory eventName, string memory eventMessage, uint OffsetPerLetter, bool retireSpecific, address specificAddress) onlyOwner public {

        _offsetPerLetter = OffsetPerLetter;
        _eventName = eventName;
        _eventMessage = eventMessage;
        _eventBeneficiaryAddress = eventBeneficiaryAddress;
        _carbonToken = CarbonToken;
        _retireSpecific = retireSpecific;
        _specificAddress = specificAddress;

        /*IERC20(_carbonToken).approve(KlimaRetirementAggregator, type(uint).max);*/

        emit LiveOffsetEventUpdate(
            _offsetPerLetter,
            _eventName,
            _eventMessage,
            _eventBeneficiaryAddress,
            _carbonToken,
            _retireSpecific,
            _specificAddress
        );

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

// SPDX-License-Identifier: MIT
// Based on OpenZepplin's Ownable

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
abstract contract Offsetter is Context {
    address private _offsetter;

    event OffsetterTransferred(address indexed previousOffsetter, address indexed newOffsetter);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOffsetter(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOffsetter() {
        _checkOffsetter();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function offsetter() public view virtual returns (address) {
        return _offsetter;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOffsetter() internal view virtual {
        require(offsetter() == _msgSender(), "caller is not the offsetter");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOffsetter() public virtual onlyOffsetter {
        _transferOffsetter(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOffsetter(address newOffsetter) public virtual onlyOffsetter {
        require(newOffsetter != address(0), "new offsetter is the zero address");
        _transferOffsetter(newOffsetter);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOffsetter(address newOffsetter) internal virtual {
        address oldOffsetter = _offsetter;
        _offsetter = newOffsetter;
        emit OffsetterTransferred(oldOffsetter, newOffsetter);
    }
}