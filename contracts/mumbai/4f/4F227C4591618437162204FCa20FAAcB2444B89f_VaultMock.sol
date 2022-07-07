// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../integrations/stargate/ISgBridge.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultMock is Ownable {

    address public nativeRouter;

    uint256 public borrowBalance;

    uint256 public openPosit;

    address public lastBaseAsset;

    event Bridged(uint256 amount, address token1, address token2, address sender);

    modifier onlyDeCommasRouter(){
        require(_msgSender() == address(nativeRouter),
            "PVLT: Caller isn't deCommas strategy");
        _;
    }

    constructor() {
    }

    function setRouter(address _new) public {
        nativeRouter = _new;
    }


    function borrow(bytes memory _data) external {
        (address p0, uint256 p1) = abi.decode(_data, (address,uint256));
        lastBaseAsset = p0;
        borrowBalance += p1;
    }

    function repay(bytes memory _data) external {
        (address p0, uint256 p1) = abi.decode(_data, (address,uint256));
        lastBaseAsset = p0;
        borrowBalance -= p1;
    }


    function openPosition(bytes memory _data) external {
        (address p0, uint256 p1) = abi.decode(_data, (address,uint256));
        lastBaseAsset = p0;
        openPosit += p1;
     }


    function approve(address baseAsset, address sender, uint256 amount) external {}


    function balanceOf(address _token) external view returns(uint256) {
        return IERC20(_token).balanceOf(address(this));
    }


    function getData(uint16 vaultLZId,
                    address nativeStableToken,
                    address destinationStableToken,
                    address sgBridge,
                    address targetRouter,
                    uint256 stableAmount) external view returns(bytes memory data) {
        data = abi.encode(vaultLZId,nativeStableToken, destinationStableToken, sgBridge, targetRouter, stableAmount);
    }

    function getData(address p0, uint256 p1) external view returns(bytes memory data) {
        data = abi.encode(p0,p1);
    }


    function bridgeToRouterBack(bytes memory _data) external {
        (uint16 vaultLZId,
        address nativeStableToken,
        address destinationStableToken,
        address sgBridge,
        address targetRouter,
        uint256 stableAmount) = abi.decode(_data, (uint16, address, address, address, address, uint256));
        IERC20(nativeStableToken).approve(sgBridge, stableAmount);
        ISgBridge(sgBridge).bridge(nativeStableToken,
                                    stableAmount,
                                    vaultLZId,
                                    targetRouter,
                                    destinationStableToken
        );
        emit Bridged(stableAmount,nativeStableToken,destinationStableToken,targetRouter);
    }


        function backTokensToNative(address _token, uint256 amount) public {
            IERC20(_token).transfer(nativeRouter, amount);
        }
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
pragma solidity ^0.8.0;

interface ISgBridge  {

    function bridge(address token,
        uint256 amount,
        uint16 destChainId,
        address destinationAddress,
        address destinationToken) external;


    function swap(
        address tokenA,
        address tokenB,
        uint256 amountA,
        address recipient
    ) external returns (bool, uint256);
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