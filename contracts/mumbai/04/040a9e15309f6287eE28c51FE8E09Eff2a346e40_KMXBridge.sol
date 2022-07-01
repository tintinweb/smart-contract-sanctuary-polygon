//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract KMXBridge is Ownable {

    address public ERC20_ADDRESS;

    struct Bundle { 
      uint256 bundleId;
      uint256 bundleCost;
      uint256 bundleReward;
      bool bundleEnabled;
    }

    Bundle[] public bundles;


    event Deposit(address depositor, uint256 amount);
    event Withdraw(address destinationAddress, uint256 amount);
    event BundleBought(address buyer, uint256 bundleId, uint256 bundleCost, uint256 bundleReward);

    constructor(address _ERC20_ADDRESS) {
        ERC20_ADDRESS = _ERC20_ADDRESS;
        bundles.push(
          Bundle(
            bundles.length,
            10000000000000000000,
            15,
            true
          )
        );
        bundles.push(
          Bundle(
            bundles.length,
            50000000000000000000,
            80,
            true
          )
        );
        bundles.push(
          Bundle(
            bundles.length,
            150000000000000000000,
            300,
            true
          )
        );
        bundles.push(
          Bundle(
            bundles.length,
            600000000000000000000,
            1300,
            true
          )
        );
    }


    /**
     * @dev Buys a particular bundleId
     */

    function buyCoinBundle(uint256[] calldata bundleIds, uint256[] calldata bundleQtys)
        external
        payable
        returns (bool)
    {

      require(bundleIds.length == bundleQtys.length);

      uint256 bufferCost = 0;
      uint256 bufferReward = 0;

      for(uint i = 0; i < bundleIds.length; i++) {
        bufferCost += bundleQtys[i] * bundles[i].bundleCost;
        bufferReward += bundleQtys[i] * bundles[i].bundleReward;
      }

        if (IERC20(ERC20_ADDRESS).balanceOf(msg.sender) < bufferCost)
            revert("You don't have enough tokens");

        bool sent = IERC20(ERC20_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            bufferCost
        );

        if (!sent) {
            revert("Transfer failed");
        }

        emit BundleBought(msg.sender, 0, bufferCost, bufferReward);

        return true;
    }

    function withdrawTokens(
        address payable _destinationAddress,
        uint256 _amountInWei
    ) external returns (bool) {
        require(
            _destinationAddress != address(0),
            "Destination cannot be the zero-address"
        );

        require(_amountInWei > 0, "Amount must be > 0 wei");

        bool sent = IERC20(ERC20_ADDRESS).transferFrom(
            address(this),
            _destinationAddress,
            _amountInWei
        );

        if (!sent) {
            revert("Transfer failed");
        }

        emit Withdraw(_destinationAddress, _amountInWei);

        return true;
    }

    function ownerWithdrawTokens(
        address destinationAddress,
        uint256 amountInWei
    ) external onlyOwner returns (bool) {
        bool sent = IERC20(ERC20_ADDRESS).transferFrom(
            address(this),
            destinationAddress,
            amountInWei
        );

        if (!sent) {
            revert("Transfer failed");
        }

        return true;
    }

    /**
     * @dev Deposits a UIM token `amountInWei` from the msg.sender to the contract
     */

    function depositUimToken(uint256 amountInWei)
        external
        payable
        returns (bool)
    {
        if (amountInWei < 0) revert("Negative amount");

        if (IERC20(ERC20_ADDRESS).balanceOf(msg.sender) < amountInWei)
            revert("You don't have enough tokens");

        bool sent = IERC20(ERC20_ADDRESS).transferFrom(
            msg.sender,
            address(this),
            amountInWei
        );

        if (!sent) {
            revert("Transfer failed");
        }

        emit Deposit(msg.sender, amountInWei);

        return true;
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