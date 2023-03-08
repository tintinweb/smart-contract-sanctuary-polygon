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

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 



/* Interfaces */


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

    function repayETH(
        address pool,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
    ) external payable;

    function borrowETH(
        address pool,
        uint256 amount,
        uint256 interesRateMode,
        uint16 referralCode
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
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

/* Main Contract */

contract RelayPolygon is Ownable, ReentrancyGuard {
    /* Mappings */

    mapping(address => mapping(address => uint256)) private userTokenBalance;
    mapping(address => uint256) public userBalanceEth;
    mapping(address => bytes) public calls;
    mapping(address => uint256) public values;

    /* Variables */

    uint256 maxUint =
        115792089237316195423570985008687907853269984665640564039457584007913129639935;
    uint256 private fees;
    uint256 private fee = 750; // 0.75% fee
    uint256 private fFee = 750; // 0.75% forwading fee

    /* Addresses */

    address private admin;
    address _dexRouter;
    address public weth;
    address private feeAddress = 0xb175aac6c149Efb0f03BE800a39CA2d3244504d5;

    /* Events */

    event TokenApproval(address tokenAddress);
    event TransferForeignToken(address token, uint256 amount);
    event tokenDepositComplete(address tokenAddress, uint256 amount);
    event approved(address tokenAddress, address sender, uint256 amount);
    event ethDepositComplete(uint256 amount);
    event swapComplete(address tokenAddress, address to);
    event TransferComplete(uint256 _amount);
    event swapTokensComplete(address tokenIn, address tokenOut, address to);
    event Forwarded(address indexed destination, uint256 value, bytes data);
    event tokenWithdrawalComplete(address tokenAddress, uint256 amount);
    event Received(address, uint256);
    event WithDraw(address, uint256);
    event feeIncoming(address, uint256);

    /* Structs */

    IDexRouter public dexRouter;

    /* Constructor */

    constructor() {
        // quickswap router
        _dexRouter = 0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;
        // admin address
        admin = 0x000000E86251c955af56b9EBC5033ffDbbd2dE42;
        // initialize router
        dexRouter = IDexRouter(_dexRouter);
        weth = dexRouter.WETH();
        IERC20(weth).approve(address(this), maxUint);
        IERC20(weth).approve(address(dexRouter), maxUint);
    }

    receive() external payable {}

    /* Functions */

    function depositEth() public payable nonReentrant {
        // deposit eth to contract for user

        require(msg.value > 0, "You must send some ETH");
        userBalanceEth[msg.sender] += msg.value;
    }

    function depositUserToken(
        uint256 amount,
        address _tokenAddress // deposit token to contract for user
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

    function SwapETHtoTokens(
        address _swapTo,
        uint256 amount // swap eth to token with fixed fee
    ) external nonReentrant {
        require(
            userBalanceEth[msg.sender] >= amount,
            "You must have enough ETH to swap"
        );

        takeFee(amount);
        userBalanceEth[msg.sender] = amount - fees;
        uint256 finalAmount = userBalanceEth[msg.sender];
        swapToToken(_swapTo, finalAmount, msg.sender);
        sendFeesETH(fees);
        unchecked {
            userBalanceEth[msg.sender] -= amount;
        }
    }

    function SwapETHtoTokensVariableFee(
        address _swapTo,
        uint256 _amount,
        uint256 _fee // swap eth to token with variable fee
    ) external nonReentrant {
        require(
            userBalanceEth[msg.sender] >= _amount,
            "You must have enough ETH to swap"
        );

        takeFeeETHVariable(_fee);
        userBalanceEth[msg.sender] = _amount - fees;
        uint256 finalAmount = userBalanceEth[msg.sender];
        swapToToken(_swapTo, finalAmount, msg.sender);
        sendFeesETH(fees);
        unchecked {
            userBalanceEth[msg.sender] -= _amount;
        }
    }

    function swapMaticToTokensLater(address _swapTo) external nonReentrant {
        // swap eth to token   with fixed fee
        uint256 amount = userBalanceEth[msg.sender];
        takeFee(amount);
        userBalanceEth[msg.sender] = amount - fees;
        uint256 finalAmount = userBalanceEth[msg.sender];
        swapToToken(_swapTo, finalAmount, msg.sender);
        sendFeesETH(fees);
        unchecked {
            userBalanceEth[msg.sender] -= amount;
        }
    }

    function swapMaticToTokensLaterVariableFee(address _swapTo, uint256 _fee)
        external
        nonReentrant
    {
        // swap eth to token with variable fee
        uint256 amount = userBalanceEth[msg.sender];
        takeFeeETHVariable(_fee);
        userBalanceEth[msg.sender] = amount - fees;
        uint256 finalAmount = userBalanceEth[msg.sender];
        swapToToken(_swapTo, finalAmount, msg.sender);
        sendFeesETH(fees);
        unchecked {
            userBalanceEth[msg.sender] -= amount;
        }
    }

    function swapToToken(
        // swap eth to token
        // swap eth to token
        address tokenAddress,
        uint256 amount,
        address to
    ) internal {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = tokenAddress;
        dexRouter.swapExactETHForTokens{value: amount}(
            0,
            path,
            to,
            block.timestamp
        );
        emit swapComplete(tokenAddress, to);
    }

    function swapTokensVariableFee(
        // swap token to token with variable fee
        // swap token to token with variable fee
        address tokenIn,
        address tokenOut,
        address to,
        uint256 _fee
    ) external nonReentrant {
        uint256 amountIn = userTokenBalance[msg.sender][tokenIn];
        takeFeeVariable(_fee, amountIn);
        uint256 swapAmount = amountIn - fees;
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        dexRouter.swapExactTokensForTokens(
            swapAmount,
            0,
            path,
            to,
            block.timestamp
        );
        unchecked {
            userTokenBalance[msg.sender][tokenIn] -= swapAmount;
        }
        sendFeesERC20(tokenIn);
        emit swapTokensComplete(tokenIn, tokenOut, to);
    }

    function swapTokens(
        // swap token to token with fixed fee
        address tokenIn,
        address tokenOut,
        address to
    ) external nonReentrant {
        uint256 amountIn = userTokenBalance[msg.sender][tokenIn];
        takeFee(amountIn);
        uint256 swapAmount = amountIn - fees;
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;
        dexRouter.swapExactTokensForTokens(
            swapAmount,
            0,
            path,
            to,
            block.timestamp
        );
        unchecked {
            userTokenBalance[msg.sender][tokenIn] -= swapAmount;
        }
        sendFeesERC20(tokenIn);
        emit swapTokensComplete(tokenIn, tokenOut, to);
    }

    function swapToEth(
        // swap token to eth with fixed fee
        address tokenIn,
        uint256 amountIn,
        address to
    ) external nonReentrant {
        require(
            userTokenBalance[msg.sender][tokenIn] >= amountIn,
            "You must have enough tokens to swap"
        );

        takeFee(amountIn);
        uint256 swapAmount = amountIn - fees;
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = weth;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            to,
            block.timestamp
        );
        unchecked {
            userTokenBalance[msg.sender][tokenIn] -= amountIn;
        }
        sendFeesERC20(tokenIn);
        emit swapComplete(weth, to);
    }

    function swapToEthVariableFee(
        // swap token to eth with variable fee
        address tokenIn,
        uint256 amountIn,
        address to,
        uint256 _fee
    ) external {
        require(
            userTokenBalance[msg.sender][tokenIn] >= amountIn,
            "You must have enough tokens to swap"
        );
        takeFeeVariable(_fee, amountIn);
        uint256 swapAmount = amountIn - fees;
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = weth;

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmount,
            0,
            path,
            to,
            block.timestamp
        );
        unchecked {
            userTokenBalance[msg.sender][tokenIn] -= amountIn;
        }
        sendFeesERC20(tokenIn);
        emit swapComplete(weth, to);
    }

    /* User Functions */

    function withDrawAllUser(address _token) public nonReentrant {
        require(userTokenBalance[msg.sender][_token] > 0, "not enough tokens");
        uint256 amount = userTokenBalance[msg.sender][_token];
        require(
            IERC20(_token).transfer(msg.sender, amount),
            "the transfer failed"
        );
        userTokenBalance[msg.sender][_token] = 0;
        emit tokenWithdrawalComplete(_token, amount);
    }

    function withDrawAllETHUser() public nonReentrant {
        require(userBalanceEth[msg.sender] > 0, "not enough ETH");
        uint256 amount = userBalanceEth[msg.sender];
        bool success;
        (success, ) = address(msg.sender).call{value: amount}("");
        unchecked {
            userBalanceEth[msg.sender] = 0;
        }
        emit tokenWithdrawalComplete(weth, amount);
    }

    function withDrawTokens(address _token, uint256 amount)
        public
        nonReentrant
    {
        require(userTokenBalance[msg.sender][_token] >= amount);
        require(
            IERC20(_token).transfer(msg.sender, amount),
            "the transfer failed"
        );
        userTokenBalance[msg.sender][_token] -= amount;
        emit tokenWithdrawalComplete(_token, amount);
    }

    function withDrawAmountETHUser(uint256 amount) public nonReentrant {
        require(userTokenBalance[msg.sender][weth] >= amount);
        bool success;
        (success, ) = address(msg.sender).call{value: amount}("");
        unchecked {
            userTokenBalance[msg.sender][weth] -= amount;
        }
        emit tokenWithdrawalComplete(weth, amount);
    }

    function getUserBalance(address _userAddress, address _tokenAddress)
        public
        view
        returns (uint256)
    {
        return userTokenBalance[_userAddress][_tokenAddress];
    }

    function getUserBalanceETH(address _userAddress)
        public
        view
        returns (uint256)
    {
        return userBalanceEth[_userAddress];
    }

    /* Admin functions */

    function withdrawETHAdmin() external onlyOwner {
        // transfers all ETH in the contract to the admin address
        bool success;
        userTokenBalance[msg.sender][weth] = 0;
        (success, ) = address(msg.sender).call{value: address(this).balance}(
            ""
        );
    }

    function withDrawERC20s(
        address _token,
        address _to // transfers any ERC20 token that is sent to the contract by mistake to the admin address
    ) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);

        emit TransferForeignToken(_token, _contractBalance);
    }

    function updateFee(uint256 _fee) external onlyOwner {
        // updates the fee for swapping
        fee = _fee;
    }

    function updateFeeAddress(address _feeAddress) external onlyOwner {
        // updates the fee receiving  address
        feeAddress = _feeAddress;
    }

    function updateDexRouter(address _dex) external onlyOwner {
        // updates the dex router address
        _dexRouter = _dex;
    }

    function updateAdmin(address _admin) external onlyOwner {
        // updates the admin address
        admin = _admin;
    }

    function updatefFee(uint256 _fee) external onlyOwner {
        // updates the fee for forwarding
        fFee = _fee;
    }

    /* Forwarding functions */

    function BitsMagic(address payable _addr, bytes memory data)
        external
        payable
    {
        // take fFee (.75%)  of the eth sent to the contract
        uint256 fFees = (msg.value / 10000) * fFee;
        uint256 finalValue = msg.value - fFees;

        (bool success, bytes memory returnData) = _addr.call{value: finalValue}(
            data
        );
        calls[_addr] = data;
        values[_addr] = msg.value;
        emit Forwarded(_addr, msg.value, data);
        emit feeIncoming(_addr, fFees);
        require(success, string(returnData));
    }

    /* Helper functions */

    function decode(bytes calldata data)
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

    /* Fee functions */

    function takeFeeETH() public payable returns (uint256) {
        fees = (msg.value * fee) / 100000;
        return fees;
    }

    function takeFeeETHVariable(uint256 _fee) public payable returns (uint256) {
        fees = (msg.value * _fee) / 100000;
        return fees;
    }

    function takeFee(uint256 amount) public returns (uint256) {
        fees = (amount * fee) / 100000;
        return fees;
    }

    function takeFeeVariable(uint256 _fee, uint256 _amount)
        public
        returns (uint256)
    {
        fees = (_amount * _fee) / 100000;
        return fees;
    }

    function sendFeesERC20(address _token) internal {
        // sends the fees (erc20) to the fee receiving address
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(feeAddress, _contractBalance);
    }

    function sendFeesETH(uint256 outFees) internal {
        // sends the fees (eth) to the fee receiving address
        bool success;
        (success, ) = address(feeAddress).call{value: outFees}("");
    }

    /* Appoval functions */

    function ApproveTokens(address _tokenAddress) public {
        IERC20(_tokenAddress).approve(address(dexRouter), type(uint256).max);
        IERC20(_tokenAddress).approve(address(this), type(uint256).max);
        IERC20(_tokenAddress).approve(address(feeAddress), type(uint256).max);
        IERC20(_tokenAddress).approve(address(admin), type(uint256).max);
        emit TokenApproval(_tokenAddress);
    }
}