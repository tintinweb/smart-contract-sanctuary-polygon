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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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

/*
 ▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀█░▌▀▀▀▀█░█▀▀▀▀  ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌       ▐░▌    ▐░▌          ▐░▌     ▐░▌          
▐░█▄▄▄▄▄▄▄█░▌    ▐░▌          ▐░▌     ▐░█▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░▌     ▐░▌          ▐░▌     ▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀█░▌    ▐░▌          ▐░▌      ▀▀▀▀▀▀▀▀▀█░▌
▐░▌       ▐░▌    ▐░▌          ▐░▌               ▐░▌
▐░█▄▄▄▄▄▄▄█░▌▄▄▄▄█░█▄▄▄▄      ▐░▌      ▄▄▄▄▄▄▄▄▄█░▌
▐░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌
 ▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀       ▀▀▀▀▀▀▀▀▀▀▀ 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDexRouter {
    function factory() external pure returns (address); // returns the factory address

    function WETH() external pure returns (address); // returns the weth address

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        // swaps tokens for eth
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETH(
        // swaps tokens for eth
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        // swaps tokens for tokens
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        // swaps eth for tokens
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function getAmountsOut(
        // returns the amount of tokens out
        uint256 amountIn,
        address[] calldata path
    ) external view returns (uint256[] memory amounts);
}

interface IWETHGateway {
    function depositETH(
        address pool,
        address onBehalfOf,
        uint16 referralCode
    ) external payable;

    function withdrawETH(
        address pool,
        uint256 amount,
        address onBehalfOf
    ) external;

    function withdrawETHWithPermit(
        address pool,
        uint256 amount,
        address to,
        uint256 deadline,
        uint8 permitV,
        bytes32 permitR,
        bytes32 permitS
    ) external;

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256);
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface MeshGateway {
    function depositETH() external payable;

    function depositToken(uint256 amount) external;

    function withdrawToken(uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function withdrawETH(uint256 withdrawAmount) external;

    function withdrawETHByAmount(uint256 withdrawAmount) external;

    function withdrawTokenByAmount(uint256 withdrawTokens) external;
}

interface MeshRouter {
    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

/*
 ▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄  ▄▄▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀█░▌▀▀▀▀█░█▀▀▀▀  ▀▀▀▀█░█▀▀▀▀ ▐░█▀▀▀▀▀▀▀▀▀ 
▐░▌       ▐░▌    ▐░▌          ▐░▌     ▐░▌          
▐░█▄▄▄▄▄▄▄█░▌    ▐░▌          ▐░▌     ▐░█▄▄▄▄▄▄▄▄▄ 
▐░░░░░░░░░░▌     ▐░▌          ▐░▌     ▐░░░░░░░░░░░▌
▐░█▀▀▀▀▀▀▀█░▌    ▐░▌          ▐░▌      ▀▀▀▀▀▀▀▀▀█░▌
▐░▌       ▐░▌    ▐░▌          ▐░▌               ▐░▌
▐░█▄▄▄▄▄▄▄█░▌▄▄▄▄█░█▄▄▄▄      ▐░▌      ▄▄▄▄▄▄▄▄▄█░▌
▐░░░░░░░░░░▌▐░░░░░░░░░░░▌     ▐░▌     ▐░░░░░░░░░░░▌
 ▀▀▀▀▀▀▀▀▀▀  ▀▀▀▀▀▀▀▀▀▀▀       ▀       ▀▀▀▀▀▀▀▀▀▀▀ 
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

//allows the contract to use the ERC20 token interface
// which is a standard interface for fungible tokens
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// allows for ownership control and access control based on ownership.
// It includes functions for setting and transferring ownership of the contract.
import "@openzeppelin/contracts/access/Ownable.sol";

// prevents reentrancy attacks by making sure that the
// contract is not in the middle of a call when a function is called.
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./IDexRouter.sol";
 

/* Main Contract */

contract PolygonRelay is
    Ownable,
    ReentrancyGuard // inherits from the Ownable and ReentrancyGuard contracts
{
    /* Mappings */

    mapping(address => mapping(address => uint256)) private userTokenBalance; // mapping of user address to token address to balance
    mapping(address => uint256) public userBalanceEth; // mapping of user address to eth balance
    mapping(address => bytes) public calls; // mapping of user address to bytes
    mapping(address => uint256) public values; // mapping of user address to value

    /* Variables */

    uint256 maxUint =
        115792089237316195423570985008687907853269984665640564039457584007913129639935; // max uint256
    uint256 private fees; // fees
    uint256 private fee = 750; // 0.75% fee
    uint256 private fFee = 750; // 0.75% forwading fee

    /* Addresses */

    address private admin; // admin address
    address _dexRouter; // dex router address
    address public weth; // weth address
    address private feeAddress = 0xb175aac6c149Efb0f03BE800a39CA2d3244504d5; // fee address

    /* Events */

    event TokenApproval(address tokenAddress); // event for token approval
    event TransferForeignToken(address token, uint256 amount); // event for transfering foreign token
    event tokenDepositComplete(address tokenAddress, uint256 amount); // event for token deposit
    event approved(address tokenAddress, address sender, uint256 amount); // event for approval
    event ethDepositComplete(uint256 amount); // event for eth deposit
    event swapComplete(address tokenAddress, address to); // event for swap
    event TransferComplete(uint256 _amount); // event for transfer
    event swapTokensComplete(address tokenIn, address tokenOut, address to); // event for swap tokens
    event Forwarded(address indexed destination, uint256 value, bytes data); // event for forwarding
    event tokenWithdrawalComplete(address tokenAddress, uint256 amount); // event for token withdrawal
    event Received(address, uint256); // event for receiving
    event WithDraw(address, uint256); // event for withdrawal
    event feeIncoming(address, uint256); // event for fee incoming

    /* Structs */

    IDexRouter public dexRouter; // dex router

    /* Constructor */

    constructor() {
        // quickswap router
        _dexRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff; // quickswap router

        admin = msg.sender; // admin address
        // initialize router
        dexRouter = IDexRouter(_dexRouter); // initialize router
        weth = dexRouter.WETH();
        IERC20(weth).approve(address(this), maxUint); // approve weth
        IERC20(weth).approve(address(dexRouter), maxUint); // approve weth
    }

    receive() external payable {} // receive function

    /**
     * Deposits ETH to the contract for the user.
     * @dev  function is payable and the sender must send some ETH.
     */

    function depositEth() public payable nonReentrant {
        // deposit eth to contract for user

        require(msg.value > 0, "You must send some ETH");
        userBalanceEth[msg.sender] += msg.value;
    }

    /**
     * @dev Deposits a specified amount of tokens to the contract for the user.
     * @param amount The amount of tokens to deposit.
     * @param _tokenAddress The address of the token to deposit - deposit token to contract for user
     * @notice The user must have a balance of at least `amount` of `_tokenAddress` tokens.
     */
    function depositUserToken(
        uint256 amount,
        address _tokenAddress
    ) public nonReentrant {
        require(
            IERC20(_tokenAddress).balanceOf(msg.sender) >= amount,
            "Your token amount must be greater then you are trying to deposit"
        );
        require(IERC20(_tokenAddress).approve(address(this), amount));
        require(
            IERC20(_tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            )
        );

        userTokenBalance[msg.sender][_tokenAddress] += amount;
        ApproveTokens(_tokenAddress);
        emit tokenDepositComplete(_tokenAddress, amount);
    }

    /**
     * @dev Deposits ETH to the contract, swaps it to a specified token, and sends the resulting tokens to the user.
     * @param tokenAddress The address of the ERC20 token to swap to.
     * @notice User must send some ETH.
     */

    function depositEthAndSwap(
        // deposit eth and swap to token with fixed fee
        address tokenAddress //
    ) external payable nonReentrant {
        require(msg.value > 0, "You must send some ETH");

        userBalanceEth[msg.sender] += msg.value;
        takeFee(msg.value);
        uint256 swapAmount = msg.value - fees;

        swapToToken(tokenAddress, swapAmount, msg.sender);
        sendFeesETH(fees);
        unchecked {
            userBalanceEth[msg.sender] = 0;
        }
    }

    /**
     * @dev Deposits ETH to the contract, swaps it to a specified token, and sends the resulting tokens to the user.
     * @param tokenAddress The address of the ERC20 token to swap to.
     * @param _fee The variable fee to take from the deposited ETH.
     * @notice User must send some ETH.
     */
    function depositEthAndSwapVariableFee(
        address tokenAddress,
        uint256 _fee // deposit eth and swap to token with variable fee
    ) external payable nonReentrant {
        require(msg.value > 0, "You must send some ETH");

        userBalanceEth[msg.sender] += msg.value;
        takeFeeETHVariable(_fee);
        uint256 swapAmount = msg.value - fees;

        swapToToken(tokenAddress, swapAmount, msg.sender);
        sendFeesETH(fees);
        unchecked {
            userBalanceEth[msg.sender] = 0;
        }
    }

    /**
     * Swaps a fixed amount of ETH to tokens with a fixed fee.
     * @param _swapTo The address of the token to swap to.
     * @param amount The amount of ETH to swap.
     */
    function SwapETHtoTokens(
        address _swapTo,
        uint256 amount
    ) external nonReentrant {
        // Ensures the user has enough ETH to swap
        require(
            userBalanceEth[msg.sender] >= amount,
            "You must have enough ETH to swap"
        );

        // Takes the fixed fee from the amount
        takeFee(amount);
        // Updates the user's ETH balance after fees are taken
        userBalanceEth[msg.sender] = amount - fees;
        // Calculates the final amount of ETH after fees are taken
        uint256 finalAmount = userBalanceEth[msg.sender];
        // Swaps the final amount of ETH to the specified token
        swapToToken(_swapTo, finalAmount, msg.sender);
        // Sends the collected fees to the contract owner
        sendFeesETH(fees);
        // Updates the user's ETH balance after swapping
        unchecked {
            userBalanceEth[msg.sender] -= amount;
        }
    }

    /**
     * Swap ETH to tokens with a variable fee.
     * @param _swapTo The address of the token to swap to.
     * @param _amount The amount of ETH to swap.
     * @param _fee The fee to be taken for the swap.
     */
    function SwapETHtoTokensVariableFee(
        address _swapTo,
        uint256 _amount,
        uint256 _fee
    ) external nonReentrant {
        // Ensures the user has enough ETH to swap
        require(
            userBalanceEth[msg.sender] >= _amount,
            "You must have enough ETH to swap"
        );

        // Takes the variable fee from the amount
        takeFeeETHVariable(_fee);
        // Updates the user's ETH balance after fees are taken
        userBalanceEth[msg.sender] = _amount - fees;
        // Calculates the final amount of ETH after fees are taken
        uint256 finalAmount = userBalanceEth[msg.sender];
        // Swaps the final amount of ETH to the specified token
        swapToToken(_swapTo, finalAmount, msg.sender);
        // Sends the collected fees to the contract owner
        sendFeesETH(fees);
        // Updates the user's ETH balance after swapping
        unchecked {
            userBalanceEth[msg.sender] -= _amount;
        }
    }

    /**
     * @dev Swap ETH to token with a fixed fee.
     * @param _swapTo The address of the token to swap to.
     */
    function swapMaticToTokensLater(address _swapTo) external nonReentrant {
        // Get the amount of ETH to be swapped
        uint256 amount = userBalanceEth[msg.sender];
        // Take the fixed fee from the ETH amount
        takeFee(amount);
        // Subtract the fees from the user's ETH balance
        userBalanceEth[msg.sender] = amount - fees;
        // Calculate the final amount of ETH after deducting fees
        uint256 finalAmount = userBalanceEth[msg.sender];
        // Swap the final amount of ETH to the specified token
        swapToToken(_swapTo, finalAmount, msg.sender);
        // Send the collected fees to the owner
        sendFeesETH(fees);
        // Subtract the original amount of ETH from the user's balance
        unchecked {
            userBalanceEth[msg.sender] -= amount;
        }
    }

    /**
    @dev Allows a user to swap a specified amount of MATIC for a specified token, with a variable fee applied.
    @param _swapTo The address of the token being swapped.
    @param _fee The fee percentage to be applied to the swap.
    Emits a {TokenWithdrawalComplete} event indicating that the withdrawal is complete.
    */
    function swapMaticToTokensLaterVariableFee(
        address _swapTo,
        uint256 _fee
    ) external nonReentrant {
        // Get the amount of ETH to be swapped
        uint256 amount = userBalanceEth[msg.sender];
        // Take the variable fee from the ETH amount
        takeFeeETHVariable(_fee);
        // Subtract the fees from the user's ETH balance
        userBalanceEth[msg.sender] = amount - fees;
        // Calculate the final amount of ETH after deducting fees
        uint256 finalAmount = userBalanceEth[msg.sender];
        // Swap the final amount of ETH to the specified token
        swapToToken(_swapTo, finalAmount, msg.sender);
        // Send the collected fees to the owner
        sendFeesETH(fees);
        // Subtract the original amount of ETH from the user's balance
        unchecked {
            userBalanceEth[msg.sender] -= amount;
        }
    }

    /**
     * Swaps ETH to tokens using the DEX router.
     * @param tokenAddress The address of the token to swap to.
     * @param amount The amount of ETH to swap.
     * @param to The address to send the swapped tokens to.
     */
    function swapToToken(
        address tokenAddress,
        uint256 amount,
        address to
    ) internal {
        // Define the token swap path
        address[] memory path = new address[](2);
        path[0] = weth; // The token to swap from
        path[1] = tokenAddress; // The token to swap to

        // Swap ETH for tokens using the Uniswap router
        dexRouter.swapExactETHForTokens{value: amount}(
            0, // The minimum amount of tokens that must be received in the swap
            path, // The path to swap along
            to, // The address to send the swapped tokens to
            block.timestamp // The deadline for the swap
        );

        // Emit an event indicating that the swap was completed
        emit swapComplete(tokenAddress, to);
    }

    /**
     * @dev Swaps tokens with a variable fee.
     * @param tokenIn The address of the token to swap from.
     * @param tokenOut The address of the token to swap to.
     * @param to The address to send the swapped tokens to.
     * @param _fee The variable fee to deduct from the swap.
     */
    function swapTokensVariableFee(
        address tokenIn,
        address tokenOut,
        address to,
        uint256 _fee
    ) external nonReentrant {
        // Get the amount of the input token held by the user
        uint256 amountIn = userTokenBalance[msg.sender][tokenIn];
        // Deduct the variable fee from the input token amount
        takeFeeVariable(_fee, amountIn);
        // Calculate the amount of input tokens to swap after deducting fees
        uint256 swapAmount = amountIn - fees;
        // Set up the token swap path
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        // Swap the input tokens for the output tokens using the DEX router
        dexRouter.swapExactTokensForTokens(
            swapAmount,
            0,
            path,
            to,
            block.timestamp
        );
        // Subtract the swapped input token amount from the user's balance
        unchecked {
            userTokenBalance[msg.sender][tokenIn] -= swapAmount;
        }
        // Send the collected fees in the input token to the owner
        sendFeesERC20(tokenIn);
        // Emit an event to signify that the token swap has been completed
        emit swapTokensComplete(tokenIn, tokenOut, to);
    }

    /**
     * @dev Swaps one ERC20 token for another using a generic DEX router.
     * @param _dex The address of the DEX router.
     * @param _from The address of the token to swap from.
     * @param _to The address of the token to swap to.
     * @param _amount The amount of the token to swap.
     */
    function swapERC20Generic(
        address _dex,
        address _from,
        address _to,
        uint256 _amount
    ) public onlyOwner {
        dexRouter = IDexRouter(_dex); // initialize router
        approveERC20(_from, address(_dex));
        approveERC20(_to, address(_dex));

        // swap tokens
        uint256 amountOutMin = 0;
        address[] memory path = new address[](2);
        path[0] = _from;
        path[1] = _to;
        dexRouter.swapExactTokensForTokens(
            _amount,
            amountOutMin,
            path,
            address(msg.sender),
            block.timestamp + 1000
        );
    }

    /**
     * @dev Swap tokens with a fixed fee
     * @param tokenIn The address of the input token
     * @param tokenOut The address of the output token
     * @param to The address to receive the output tokens
     */

    function swapTokens(
        address tokenIn,
        address tokenOut,
        address to
    ) external nonReentrant {
        // Get the amount of tokens the user has
        uint256 amountIn = userTokenBalance[msg.sender][tokenIn];

        // Calculate the fee to be taken
        takeFee(amountIn);

        // Calculate the amount of tokens that will be swapped (minus the fee)
        uint256 swapAmount = amountIn - fees;

        // Define the token swap path
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // Swap tokens using the Uniswap router
        dexRouter.swapExactTokensForTokens(
            swapAmount,
            0,
            path,
            to,
            block.timestamp
        );

        // Update the user's token balance
        unchecked {
            userTokenBalance[msg.sender][tokenIn] -= swapAmount;
        }

        // Send the collected fees to the fee receiver
        sendFeesERC20(tokenIn);

        // Emit an event indicating that the swap was completed
        emit swapTokensComplete(tokenIn, tokenOut, to);
    }

    /**
     * Swap tokens to ETH with a fixed fee.
     * @param tokenIn The address of the token being swapped.
     * @param amountIn The amount of tokens to be swapped.
     * @param to The address to receive the ETH after the swap.
     */
    function swapToEth(
        // swap token to eth with fixed fee
        address tokenIn,
        uint256 amountIn,
        address to
    ) external nonReentrant {
        // Verify that the user has enough tokens to swap
        require(
            userTokenBalance[msg.sender][tokenIn] >= amountIn,
            "You must have enough tokens to swap"
        );

        // Calculate the fee to be taken
        takeFee(amountIn);

        // Calculate the amount of tokens that will be swapped (minus the fee)
        uint256 swapAmount = amountIn - fees;

        // Define the token swap path
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = weth;

        // Swap tokens for ETH using the Uniswap router
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            to,
            block.timestamp
        );

        // Update the user's token balance
        unchecked {
            userTokenBalance[msg.sender][tokenIn] -= amountIn;
        }

        // Send the collected fees to the fee receiver
        sendFeesERC20(tokenIn);

        // Emit an event indicating that the swap was completed
        emit swapComplete(weth, to);
    }

    /**
     * @dev This function allows a user to swap a specified amount of tokens for ETH, with a variable fee applied.
     * @param tokenIn The address of the token being swapped.
     * @param amountIn The amount of `tokenIn` being swapped.
     * @param to The address that will receive the ETH.
     *  fee The fee percentage to be applied to the swap.
     */

    function swapToEthVariableFee(
        // swap token to eth with variable fee
        address tokenIn,
        uint256 amountIn,
        address to,
        uint256 _fee
    ) external {
        // Check that the user has enough tokens to perform the swap.
        require(
            userTokenBalance[msg.sender][tokenIn] >= amountIn,
            "You must have enough tokens to swap"
        );

        /**
         * @notice This function allows a user to swap a specified amount of tokens for ETH, with a variable fee applied.
         * @param tokenIn The address of the token being swapped.
         * @param amountIn The amount of `tokenIn` being swapped.
         * @param to The address that will receive the ETH.
         * @_fee The fee percentage to be applied to the swap.
         */
        takeFeeVariable(_fee, amountIn);

        // Set the path for the swap to go from `tokenIn` to WETH.
        uint256 swapAmount = amountIn - fees;
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = weth;

        // Use the DEX router to perform the swap.
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            to,
            block.timestamp
        );

        // Deduct the `amountIn` (including the fees) from the user's balance.
        unchecked {
            userTokenBalance[msg.sender][tokenIn] -= amountIn;
        }

        // Send any collected fees to the fee address.
        sendFeesERC20(tokenIn);

        // Emit an event to indicate that the swap is complete.
        emit swapComplete(weth, to);
    }

    /* User Functions */
    /**
     * @dev This function allows a user to withdraw all of a specific token from their balance.
     * @param _token The address of the token being withdrawn.
     */

    function withDrawAllUser(address _token) public nonReentrant {
        // Check that the user has a non-zero balance of the specified token.

        require(userTokenBalance[msg.sender][_token] > 0, "not enough tokens");
        uint256 amount = userTokenBalance[msg.sender][_token];
        // Transfer the entire balance of the token to the user's address.

        require(
            IERC20(_token).transfer(msg.sender, amount),
            "the transfer failed"
        );
        // Set the user's balance of the token to zero.

        userTokenBalance[msg.sender][_token] = 0;
        // Emit an event to indicate that the withdrawal is complete.

        emit tokenWithdrawalComplete(_token, amount);
    }

    /**
     * @dev This function allows a user to withdraw all of their ETH balance.
     */
    function withDrawAllETHUser() public nonReentrant {
        // Check that the user has a non-zero ETH balance.
        require(userBalanceEth[msg.sender] > 0, "not enough ETH");
        uint256 amount = userBalanceEth[msg.sender];
        // Transfer the entire ETH balance to the user's address.

        bool success;
        (success, ) = address(msg.sender).call{value: amount}("");
        unchecked {
            userBalanceEth[msg.sender] = 0;
        }

        // Emit an event to indicate that the withdrawal is complete.

        emit tokenWithdrawalComplete(weth, amount);
    }

    /**
     * Withdraws a specified amount of tokens from the caller's balance and transfers them to the caller's address.
     *
     * @param _token The address of the token to be withdrawn.
     * @param amount The amount of tokens to be withdrawn.
     */
    function withDrawTokens(
        address _token,
        uint256 amount
    ) public nonReentrant {
        // Check if the user has enough tokens to cover the requested withdrawal amount
        require(
            userTokenBalance[msg.sender][_token] >= amount,
            "Insufficient token balance"
        );

        // Transfer the requested amount of tokens to the caller's address
        require(
            IERC20(_token).transfer(msg.sender, amount),
            "Token transfer failed"
        );

        // Update the user's token balance by subtracting the withdrawn amount
        userTokenBalance[msg.sender][_token] -= amount;

        // Emit an event to notify any interested parties that the withdrawal has been completed successfully
        emit tokenWithdrawalComplete(_token, amount);
    }

    /**
     * @dev Allows a user to withdraw a certain amount of Ether (ETH) from their balance of Wrapped Ether (WETH) tokens.
     * @param amount The amount of ETH to withdraw.
     */
    function withDrawAmountETHUser(uint256 amount) public nonReentrant {
        // Check if the user has enough WETH tokens to cover the requested withdrawal amount
        require(
            userTokenBalance[msg.sender][weth] >= amount,
            "Insufficient WETH balance"
        );

        // Use a low-level call to transfer the requested amount of ETH to the caller's address
        bool success;
        (success, ) = address(msg.sender).call{value: amount}("");

        // Update the user's WETH balance by subtracting the withdrawn amount
        unchecked {
            userTokenBalance[msg.sender][weth] -= amount;
        }

        // Emit an event to notify any interested parties that the withdrawal has been completed successfully
        emit tokenWithdrawalComplete(weth, amount);
    }

    /**
     * @dev Returns the token balance of a user
     * @param _userAddress The address of the user
     * @param _tokenAddress The address of the token
     * @return The token balance of the user
     */
    function getUserBalance(
        address _userAddress,
        address _tokenAddress
    ) public view returns (uint256) {
        return userTokenBalance[_userAddress][_tokenAddress];
    }

    /**
     * @dev Returns the ETH balance of a user
     * @param _userAddress The address of the user
     * @return The ETH balance of the user
     */
    function getUserBalanceETH(
        address _userAddress
    ) public view returns (uint256) {
        return userBalanceEth[_userAddress];
    }

    /**
     * @dev Allows the admin to withdraw ETH from the contract
     */
    function withdrawETHAdmin() external onlyOwner {
        bool success;
        // set the WETH balance of the owner to 0
        userTokenBalance[msg.sender][weth] = 0;
        // transfer the balance of the contract to the owner
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    /**
     * @dev Withdraws ERC20 tokens from the contract and sends them to the specified address.
     * @param _token The address of the ERC20 token to withdraw.
     * @param _to The address to send the withdrawn tokens to.
     * @return _sent Returns true if the tokens were successfully transferred, false otherwise.
     */
    function withDrawERC20s(
        address _token,
        address _to
    ) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);

        emit TransferForeignToken(_token, _contractBalance);
    }

    /**
     * @dev Updates the transaction fee percentage.
     * @param _fee The new fee percentage to be set.
     */
    function updateFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    /**
     * @dev Updates the address of the account that receives the transaction fees.
     * @param _feeAddress The address of the new fee receiving account.
     */
    function updateFeeAddress(address _feeAddress) external onlyOwner {
        feeAddress = _feeAddress;
    }

    /**
     * @dev Update the DEX router contract address.
     * @param _dex The address of the new DEX router contract.
     * Requirements:
     * - Caller must be the owner of the contract.
     */
    function updateDexRouter(address _dex) external onlyOwner {
        _dexRouter = _dex;
    }

    /**
     * @dev Update the admin address.
     * @param _admin The address of the new admin.
     * Requirements:
     * - Caller must be the owner of the contract.
     */
    function updateAdmin(address _admin) external onlyOwner {
        admin = _admin;
    }

    /**
     * @dev Update the fee percentage.
     * @param _fee The new fee percentage.
     * Requirements:
     * - Caller must be the owner of the contract.
     */
    function updatefFee(uint256 _fee) external onlyOwner {
        fFee = _fee;
    }

    /**
     * @dev Call another contract and forward some ETH, while taking a fee.
     * @param _addr The address of the contract to call.
     * @param data The data to send with the call.
     * Requirements:
     * - The function must be called with some ETH.
     */
    function BitsMagic(
        address payable _addr,
        bytes memory data
    ) external payable {
        uint256 fFees = (msg.value / 10000) * fFee;
        uint256 finalValue = msg.value - fFees;

        // Call the contract and forward the ETH.
        (bool success, bytes memory returnData) = _addr.call{value: finalValue}(
            data
        );

        // Keep track of the call and the amount of ETH sent.
        calls[_addr] = data;
        values[_addr] = msg.value;

        // Emit events.
        emit Forwarded(_addr, msg.value, data);
        emit feeIncoming(_addr, fFees);

        // Revert if the call was not successful.
        require(success, string(returnData));
    }

    /**
     * @dev Call another contract and forward some ERC20 ,  while taking a fee.
     * @param _addr The address of the contract to call.
     * @param data The data to send with the call.
     */
    function BitsMagicERC20(address _addr, bytes memory data) external {
        // decode the data and get the amountin and the path
        (
            uint256 amountIn,
            uint256 amountOutMin,
            address[] memory path,
            address to,
            uint256 deadline
        ) = abi.decode(data, (uint256, uint256, address[], address, uint256));

        // calculate the fee and the final value

        uint256 fFees = (amountIn / 10000) * fFee;
        uint256 finalValue = amountIn - fFees;
        // re encode the data with the new amount

        data = abi.encodeWithSelector(
            IDexRouter.swapExactTokensForTokens.selector,
            finalValue,
            amountOutMin,
            path,
            to,
            deadline
        );

        // Call the contract and forward the transaction.

        (bool success, bytes memory returnData) = _addr.call(data);

        // Keep track of the call and the amount of ETH sent.

        calls[_addr] = data;
        values[_addr] = amountIn;

        // Emit events.
        emit Forwarded(_addr, amountIn, data);
        emit feeIncoming(_addr, fFees);

        require(success, string(returnData));
    }

    /**
     * @dev Decode function arguments from bytes.
     * @param data The data to decode.
     * @return amountIn The amount of input token to send.
     * @return amountOutMin The minimum amount of output token to receive.
     * @return path The path of tokens to use for the swap.
     * @return to The address to send the output token to.
     * @return deadline The deadline for the transaction.
     */
    function decode(
        bytes calldata data
    )
        external
        pure
        returns (
            uint256 amountIn,
            uint256 amountOutMin,
            address[] memory path,
            address to,
            uint256 deadline
        )
    {
        return
            abi.decode(data, (uint256, uint256, address[], address, uint256));
    }

    /**
     * @dev Calculate the fee for an ETH transaction.
     * @return The fee amount.
     */

    /**
     * @dev Calculates the fee in ETH for a given fee percentage and amount of ETH sent.
     * @param _fee The fee percentage to calculate.
     * @return The calculated fee in ETH.
     */
    function takeFeeETHVariable(uint256 _fee) public payable returns (uint256) {
        fees = (msg.value * _fee) / 100000;
        return fees;
    }

    /**
     * @dev Calculates the fee in a specified token for a given fee percentage and amount of tokens.
     * @param amount The amount of tokens to calculate the fee on.
     * @return The calculated fee in the token.
     */
    function takeFee(uint256 amount) public returns (uint256) {
        fees = (amount * fee) / 100000;
        return fees;
    }

    /**
     * @dev Calculates the fee in a specified token for a given fee percentage and amount of tokens.
     * @param _fee The fee percentage to calculate.
     * @param _amount The amount of tokens to calculate the fee on.
     * @return The calculated fee in the token.
     */
    function takeFeeVariable(
        uint256 _fee,
        uint256 _amount
    ) public returns (uint256) {
        fees = (_amount * _fee) / 100000;
        return fees;
    }

    /**
     * @dev Sends the fees (in ERC20 tokens) to the designated fee receiving address.
     * @param _token The address of the ERC20 token to send as fees.
     */
    function sendFeesERC20(address _token) internal {
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(feeAddress, _contractBalance);
    }

    /**
     * @dev Sends the fees (in ETH) to the designated fee receiving address.
     * @param outFees The amount of fees to send in ETH.
     */
    function sendFeesETH(uint256 outFees) internal {
        bool success;
        (success, ) = address(feeAddress).call{value: outFees}("");
    }

    /**
     * @dev Approve the contract to spend an unlimited amount of an ERC20 token on behalf of the user.
     * @param _token The address of the ERC20 token to approve.
     * @param _spender The address of the spender contract to approve.
     */
    function approveERC20(address _token, address _spender) public {
        IERC20(_token).approve(_spender, maxUint);
    }

    /**
     * @dev Approves the contract to spend an unlimited amount of a specified token on the user's behalf.
     * @param _tokenAddress The address of the ERC20 token to approve.
     */
    function ApproveTokens(address _tokenAddress) public {
        IERC20(_tokenAddress).approve(address(dexRouter), type(uint256).max);
        IERC20(_tokenAddress).approve(address(this), type(uint256).max);
        IERC20(_tokenAddress).approve(address(feeAddress), type(uint256).max);
        IERC20(_tokenAddress).approve(address(admin), type(uint256).max);
        emit TokenApproval(_tokenAddress);
    }

    // Set the 1inch contract address
    address private ONEINCH_CONTRACT =
        0x1111111254EEB25477B68fb85Ed929f73A960582;
    uint256 MAX_UINT256 = 2 ** 256 - 1;
 
    function approveToken(address tokenAddress) external {
        // Approve the 1inch contract to spend the specified amount of tokens
        IERC20(tokenAddress).approve(ONEINCH_CONTRACT, MAX_UINT256);
        IERC20(tokenAddress).approve(address(this), MAX_UINT256);
    }

    function forwardSwap(bytes calldata data) external payable {
        // Forward the call to the 1inch contract with the specified data
        (bool success, ) = ONEINCH_CONTRACT.call{value: msg.value}(data);
        require(success, "Forwarder: Swap failed");
    }

    function depositERC20(address tokenAddress, uint256 amount) external {
        // Transfer the specified amount of tokens from the sender to the contract
        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                address(this),
                amount
            ),
            "Deposit failed"
        );
    }

    function withdrawERC20(
        address tokenAddress,
        uint256 amount
    ) external onlyOwner {
        // Transfer the specified amount of tokens from the contract to the owner
        require(
            IERC20(tokenAddress).transfer(msg.sender, amount),
            "Withdraw failed"
        );
    }

    function balanceOf(address tokenAddress) external view returns (uint256) {
        // Return the token balance of the contract
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function withDrawMatic() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }
 
}


// © 2023 Bits. All rights reserved.