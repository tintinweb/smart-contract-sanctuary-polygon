pragma solidity ^0.8.4;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./interface/IWETH.sol";

error YESP_NotOwnerOrAdmin();
error PROC_TransferFailed();

contract YespFeeProcessor is Ownable {

    // Fees are out of 10000, to allow for 0.01 - 9.99% fees.
    uint256 public devFee = 100; //1%
    uint256 public secondaryFee = 100; //1%
    uint256 public tertiaryFee = 100; //1%
    uint256 public totalFee = 300;

    uint256 public accruedAdminFeesEth;
    uint256 public accruedAdminFees;

    IWETH public TOKEN; //WETH
    address public devAddress = 0x24312a0b911fE2199fbea92efab55e2ECCeC637D;
    address public secondaryAddress = 0xB967DaE501F16E229A83f0C4FeA263A4be528dF4;
    address public tertiaryAddress = 0xE9b8258668E17AFA5D09de9F10381dE5565dbDc0;

    bool autoSendFees;

    mapping(address => bool) administrators;

    modifier onlyAdmins() {
        if (!(administrators[_msgSender()] || owner() == _msgSender()))
            revert YESP_NotOwnerOrAdmin();
        _;
    }

    constructor(address _TOKEN) {
        TOKEN = IWETH(_TOKEN);
        administrators[msg.sender] = true;
        // approveSelf();
    }

    function calculateAmounts(
        uint256 amount
    ) private view returns(uint256, uint256, uint256) {
        uint256 totalFee_ = totalFee;
        uint256 devAmount = amount * devFee / totalFee_;
        uint256 secondaryAmount = amount * secondaryFee / totalFee_;
        uint256 tertiaryAmount = amount - devAmount - secondaryAmount;
        return(devAmount, secondaryAmount, tertiaryAmount);
    }

    function processDevFeesEth() external onlyOwner {
        (
            uint256 devAmount,
            uint256 secondaryAmount,
            uint256 tertiaryAmount
        ) = calculateAmounts(address(this).balance);
        _processDevFeesEth(
            devAmount,
            secondaryAmount,
            tertiaryAmount
        );
    }

    function _processDevFeesEth(
        uint256 devAmount,
        uint256 secondaryAmount,
        uint256 tertiaryAmount
    ) private {
        if (devAmount != 0)
            _sendEth(devAddress, devAmount);
        if (secondaryAmount != 0)
            _sendEth(secondaryAddress, secondaryAmount);
        if (tertiaryAmount != 0)
            _sendEth(tertiaryAddress, tertiaryAmount);
    }

    function setAutoSendFees(bool _value) external onlyOwner {
        autoSendFees = _value;
    }

    function setDevAddress(address _address) external onlyOwner {
        devAddress = _address;
    }

    function setSecondaryAddress(address _address) external onlyOwner {
        secondaryAddress = _address;
    }

    function setTertiaryAddress(address _address) external onlyOwner {
        tertiaryAddress = _address;
    }

    function setDevFee(uint256 fee) external onlyOwner {
        require(fee <= 1000, "Max 10% fee");
        devFee = fee;
        totalFee = fee + secondaryFee + tertiaryFee;
    }

    function setSecondaryFee(uint256 fee) external onlyOwner {
        require(fee <= 1000, "Max 10% fee");
        secondaryFee = fee;
        totalFee = devFee + fee + tertiaryFee;
    }

    function setTertiaryFee(uint256 fee) external onlyOwner {
        require(fee <= 1000, "Max 10% fee");
        tertiaryFee = fee;
        totalFee = devFee + secondaryFee + fee;
    }

    function _sendEth(address _address, uint256 _amount) private {
        (bool success, ) = _address.call{value: _amount}("");
        if (!success) revert PROC_TransferFailed();
    }

    function approveSelf() public onlyAdmins() {
        TOKEN.approve(address(this), type(uint256).max);
    }

    receive() external payable {
        if (autoSendFees) {
            (
                uint256 devAmount,
                uint256 secondaryAmount,
                uint256 tertiaryAmount
            ) = calculateAmounts(msg.value);
            _processDevFeesEth(
                devAmount,
                secondaryAmount,
                tertiaryAmount
            );
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

pragma solidity >=0.4.18;

interface IWETH {
    function deposit() external payable;
    function withdraw(uint256) external;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
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