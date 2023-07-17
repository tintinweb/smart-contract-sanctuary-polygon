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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "./Context.sol";

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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;
import "./Ownable.sol";
import "./IERC20.sol";

contract PublicSale is Ownable {
    uint256 public vibPerEther = 20000;
    address public vib;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public softcap = 50 ether;
    uint256 public hardcap = 100 ether;
    uint256 public _duration;
    bool public softcapmet;
    bytes32 public root;

    mapping (address => uint256) public payAmount;
    mapping (address => uint256) private _vibReleased;

    event VibReleased(address user, uint256 amount);
    // TGE: 25%
    // VESTING 25%/month
    constructor(address _vib, uint256 _start, uint256 _end, uint256 durationSeconds) {
        vib = _vib;
        startTime = _start;
        endTime = _end;
        _duration = durationSeconds;
    }


    function setPrice(uint256 _price) external onlyOwner {
        require(block.timestamp < startTime, "IDO has started, the price cannot be changed");
        vibPerEther = _price;
    }

    function setTime(uint256 _start, uint256 _end) external onlyOwner {
        if(startTime > 0) {
            require(block.timestamp < startTime);
        }
        startTime = _start;
        endTime = _end;
    }

    function join() external payable {
        require(block.timestamp >= startTime && block.timestamp < endTime, "The public sale hasn't started yet");
        require(address(this).balance <= hardcap, "IDO quota has been reached");
        payAmount[msg.sender] += msg.value;
        if(address(this).balance >= softcap) {
            softcapmet = true;
        }
    }

    function leave(uint256 amount) external {
        require(!softcapmet, "Refunds are not possible as the soft cap has been exceeded");
        require(payAmount[msg.sender] >= amount, "The exit amount is greater than the invested amount");
        payAmount[msg.sender] -= amount;
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function released(address _user) public view returns(uint256){
        //withdraw
        return _vibReleased[_user];
    }

    function releasable(address _user) public view returns(uint256){
        //available
        return _vestingSchedule( getTotalAllocation(_user) , block.timestamp) - released(_user);
    }

    function release() external {
        require(softcapmet, "VIB cannot be claimed as the soft cap for IDO has not been reached");
        uint256 amount = releasable(msg.sender);
        _vibReleased[msg.sender] += amount;
        emit VibReleased(msg.sender, amount);
        IERC20(vib).transfer(msg.sender, amount * vibPerEther);
    }

    function startVesting() public view returns(uint256){
        return endTime;
    }

    function duration() public view returns(uint256){
        return _duration;
    }

    function getTotalAllocation(address _user) public view returns (uint256){
        return payAmount[_user] * vibPerEther;
    }

    function _vestingSchedule(uint256 totalAllocation, uint256 timestamp) internal view returns (uint256) {
        if (timestamp < startVesting()) {
            return 0;
        } else if (timestamp > startVesting() + duration()) {
            return totalAllocation;
        } else {
            return ( totalAllocation / 4 + 3 * totalAllocation * (timestamp - startVesting())) / (4 * duration());
        }
    }


    function withdrawEther() external onlyOwner {
        require(block.timestamp >= endTime, "The owner can only withdraw ETH after the IDO ends");
        require(softcapmet, "The owner cannot withdraw ETH as the soft cap for IDO has not been reached");
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    // to help users who accidentally send their tokens to this contract
    function sendToken(address token, address to, uint256 amount) external onlyOwner {
        require(block.timestamp >= endTime);
        IERC20(token).transfer(to, amount);
    }
}