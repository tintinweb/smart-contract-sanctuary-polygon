// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../Reserve/Reserve.sol";

contract TokenSale is Ownable {
    uint256 public investorMinCap = 0.02 ether;
    uint256 public investorHardCap = 10 ether;
    uint256 public rate = 10;
    address public feeRecipient;
    uint256 public feeDecimal;
    uint256 public feeRate;

    event FeeRateUpdated(uint256 feeDecimal, uint256 feeRate);

    mapping(address => uint256) public contributions;
    IERC20 public tokenVIE;
    Reserve public immutable reserve;
    address public reserveAddress;

    constructor(
        address _tokenAddress,
        address _reserveAddress,
        uint256 feeDecimal_,
        uint256 feeRate_
    ) {
        tokenVIE = IERC20(_tokenAddress);
        reserve = Reserve(_reserveAddress);
        reserveAddress = _reserveAddress;
        _updateFeeRate(feeDecimal_, feeRate_);
    }

    //update rate

    receive() external payable {}

    function updateRate(uint256 _rate) public onlyOwner {
        rate = _rate;
    }

    function _updateFeeRate(uint256 feeDecimal_, uint256 feeRate_) internal {
        require(feeRate_ < 10**(feeDecimal_ + 2), "TokenSale: bad fee rate");
        feeDecimal = feeDecimal_;
        feeRate = feeRate_;
    }

    function updateFeeRate(uint256 feeDecimal_, uint256 feeRate_)
        external
        onlyOwner
    {
        _updateFeeRate(feeDecimal_, feeRate_);
        emit FeeRateUpdated(feeDecimal_, feeRate_);
    }

    function _calculateFee(uint256 amount_) private view returns (uint256) {
        if (feeRate == 0) {
            return 0;
        }
        return (feeRate * amount_) / 10**(feeDecimal + 2);
    }

    function buy() public payable {
        uint256 amountToken = msg.value * rate;
        require(amountToken > investorMinCap, "TokenSale: Not reach min cap");
        require(
            contributions[msg.sender] + amountToken < investorHardCap,
            "TokenSale: exceed hard cap"
        );
        require(
            tokenVIE.balanceOf(reserveAddress) >= amountToken,
            "TokenSale: exceed token balance"
        );

        reserve.distributeToken(_msgSender(), amountToken);
    }

    function sell(uint256 _amountToken) public payable {
        require(
            contributions[msg.sender] >= _amountToken,
            "TokenSale: Your contribution do not have enough token"
        );
        uint256 fee = _calculateFee(_amountToken);
        uint256 ethAmount = (_amountToken - fee) / rate;

        contributions[msg.sender] -= _amountToken;
        tokenVIE.transferFrom(_msgSender(), reserveAddress, _amountToken);
        payable(msg.sender).transfer(ethAmount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Staking reserve is a contract that holds tokens from staking actions and allows
//  the staking contract to take the amount to interest their profit

contract Reserve is Ownable {
    IERC20 public tokenVIE;
    address public shoesNFTAddress;
    address public tokenSaleAddress;

    constructor(address _tokenVIE) {
        tokenVIE = IERC20(_tokenVIE);
    }

    function setShoesNFTAddress(address _shoesNFTAddress) external onlyOwner {
        shoesNFTAddress = _shoesNFTAddress;
    }

    function setTokenSaleAddress(address _tokenSaleAddress) external onlyOwner {
        tokenSaleAddress = _tokenSaleAddress;
    }

    function distributeToken(address _recipient, uint256 _amount) public {
        require(
            msg.sender == shoesNFTAddress || msg.sender == tokenSaleAddress
        );
        require(
            _amount <= tokenVIE.balanceOf(address(this)),
            "Reserve: Not enough token"
        );
        tokenVIE.transfer(_recipient, _amount);
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