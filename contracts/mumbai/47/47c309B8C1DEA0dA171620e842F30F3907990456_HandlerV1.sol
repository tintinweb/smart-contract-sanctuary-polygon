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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal pure virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address owner) {
        _transferOwnership(owner);
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
    function getOwner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(getOwner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IRouter} from "../interfaces/IRouter.sol";
import {IOps} from "../interfaces/IOps.sol";
import {ICore} from "../interfaces/ICore.sol";
import "../interfaces/IHandler.sol";
import "../Core/Ownable.sol";

contract HandlerV1 is IHandler,Ownable {
    address public ROUTER_ADDRESS;
    IOps immutable gelatoOps;
    address immutable WRAPPED_NATIVE;
    address public NATIVE_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    constructor(address _ops, address router_address, address __owner, address _WRAPPED_NATIVE) Ownable(__owner) {
        gelatoOps = IOps(_ops);
        ROUTER_ADDRESS = router_address;
        WRAPPED_NATIVE=_WRAPPED_NATIVE;
    }

    // dont send tokens directly
    receive() external payable {
        require(
            msg.sender != tx.origin,
            "dont send native tokens directly"
        );
    }

    // Need to be invoked in case when Gelato changes their native token address , very unlikely though
    function updateNativeTokenAddress(address newNativeTokenAddress) external onlyOwner {
        NATIVE_TOKEN = newNativeTokenAddress;
    }

    // Transfer native token
    function _transfer(uint256 _fee, address _feeToken, address payable to) internal {
        if (_feeToken == NATIVE_TOKEN) {
            (bool success, ) = to.call{value: _fee}("");
            require(success, "_transfer: NATIVE_TOKEN transfer failed");
        } else {
            IERC20(_feeToken).transfer(address(gelatoOps), _fee);
        }
    }

    // Get transaction fee and feeToken from GelatoOps for the transaction execution
    function _getFeeDetails()
    internal
    view
    returns (uint256 fee, address feeToken)
    {
        (fee, feeToken) = gelatoOps.getFeeDetails();
    }

    // Checker for limit order
    function canExecuteLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        bytes calldata swapData
    ) external view returns (bool) {
        // Decode data
        (
        uint96 deadline,
        uint256 minReturn,
        address[] memory pathNativeSwap,
        address[] memory pathTokenSwap,
        uint32[] memory feeNativeSwap,
        uint32[] memory feeTokenSwap
        ) = abi.decode(
            swapData,
            (uint96, uint256, address[], address[], uint32[], uint32[])
        );

        // Check order validity
        if (block.timestamp > deadline) revert("deadline passed");

        // Check if sufficient tokenB will be returned
        require(
            (
            IRouter(ROUTER_ADDRESS).getAmountsOut(
                amountTokenA,
                pathTokenSwap,
                feeTokenSwap
            )
            )[pathTokenSwap.length - 1] >= minReturn,
            "insufficient token B returned"
        );

        // Check if input FeeToken amount is sufficient to cover fees
        (uint256 FEES, address feeToken) = _getFeeDetails();
        if(feeToken == NATIVE_TOKEN) {
            require(pathNativeSwap[pathNativeSwap.length - 1] == NATIVE_TOKEN, "incorrect fee token provided in swap, provide native");
        } else {
            require(feeToken == pathNativeSwap[pathNativeSwap.length - 1],"incorrect fee token provided in swap");
        }

        require(
            (
            IRouter(ROUTER_ADDRESS).getAmountsOut(
                amountFeeToken,
                pathNativeSwap,
                feeNativeSwap
            )
            )[pathNativeSwap.length - 1] >= FEES,
            "insufficient NATIVE_TOKEN returned"
        );

        return true;
    }

    // Executor for limit order
    function executeLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        address _owner,
        bytes calldata _data
    ) external returns(uint256,uint256) {
        // Decode data
        (
        uint96 deadline,
        uint256 minReturn,
        address[] memory pathNativeSwap, // provide empty array if fee token is native
        address[] memory pathTokenSwap,
        uint32[] memory feeNativeSwap,
        uint32[] memory feeTokenSwap
        ) = abi.decode(
            _data,
            (uint96, uint256, address[], address[], uint32[], uint32[])
        );

        // the approve works for wrapped native tokens also using the IERC20 interface
        // approve tokenA to router
        IERC20(pathTokenSwap[0]).approve(ROUTER_ADDRESS, amountTokenA);

        // calculate feeToken amount from native fee
        uint256[] memory feeTokenAmountFromNativeFee;

        // get tx fee
        (uint256 FEES, address feeToken) = _getFeeDetails();

        //todo discuss
        if (pathNativeSwap.length != 0){
            feeTokenAmountFromNativeFee = IRouter(ROUTER_ADDRESS).getAmountsIn(
                FEES,
                pathNativeSwap,
                feeNativeSwap
            );

            require(
                amountFeeToken >= feeTokenAmountFromNativeFee[0],
                "insufficient feeToken amount"
            );

            require(
                IERC20(pathNativeSwap[0]).balanceOf(address(this)) >=
                amountFeeToken,
                "insufficient balance of feeToken in handler"
            );

            // call swap tokenA to native token
            if (feeToken == NATIVE_TOKEN) {
                require(pathNativeSwap[pathNativeSwap.length-1] == WRAPPED_NATIVE, "Incorrect fee path provided");
                IRouter(ROUTER_ADDRESS).swapTokensForExactNative(
                    FEES,
                    feeTokenAmountFromNativeFee[0],
                    pathNativeSwap,
                    feeNativeSwap,
                    address(this),
                    deadline
                );

                // send gelato fees
                (bool success, ) = gelatoOps.gelato().call{value: FEES}("");
                require(success, "_transfer: NATIVE_TOKEN transfer failed");
            } else {
                require(pathNativeSwap[pathNativeSwap.length-1] == feeToken, "Incorrect erc20 fee token path provided");
                IRouter(ROUTER_ADDRESS).swapTokensForExactTokens(
                    FEES,
                    feeTokenAmountFromNativeFee[0],
                    pathNativeSwap,
                    feeNativeSwap,
                    address(this),
                    deadline
                );

                // send gelato fees
                IERC20(feeToken).transfer(gelatoOps.gelato(), FEES);
            }
        } else {
            // send gelato fees directly
            gelatoOps.gelato().call{value:FEES}("");
        }

        // transfer the remaining welle back to owner
        _transfer(amountFeeToken - feeTokenAmountFromNativeFee[0],pathNativeSwap[0],payable(_owner));

        // call swap tokenA to tokenB
        uint256[] memory amounts =
        IRouter(ROUTER_ADDRESS)
        .swapExactTokensForTokens(
            amountTokenA,
            minReturn,
            pathTokenSwap,
            feeTokenSwap,
            _owner,
            deadline
        );

        uint256 bought = amounts[pathTokenSwap.length-1];

        require(
            bought >= minReturn,
            "Insufficient return tokenB"
        );

        return (bought,feeTokenAmountFromNativeFee[0]);
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface ICore {
    function depositTokens(
        uint256 _amountWelle,
        uint256 _amountTokenA,
        address _module,
        address _tokenA,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external;

    function withdrawTokens(
        address _module,
        address _tokenA,
        address payable _owner,
        address _witness,
        bytes calldata _data
    ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

struct VaultData{
    uint256 tokenBalance;
    uint256 feeTokenBalance;
    bytes32 taskId;
}

interface IHandler {

    /// @notice receive ETH
    receive() external payable;

    /**
     * @notice Executes an order
     * @param _inputAmountFeeToken - uint256 of the input FeeToken amount (order amount)
     * @param _inputAmountTokenA - uint256 of the input token amount (order amount)
     * @param _owner - Address of the order's owner
     * @param _data - Bytes of the order's data
     * @return bought - amount of output token bought
     */
    function executeLimitOrder(
        uint256 _inputAmountFeeToken,
        uint256 _inputAmountTokenA,
        address _owner,
        bytes calldata _data
    ) external returns (uint256,uint256);

    /**
     * @notice Check whether an order can be executed or not
     * @param amountFeeToken - uint256 of the input FeeToken token amount (order amount)
     * @param amountTokenA - uint256 of the input token token amount (order amount)
     * @param swapData - Bytes of the order's data
     * @return bool - whether the order can be executed or not
     */
    function canExecuteLimitOrder(
        uint256 amountFeeToken,
        uint256 amountTokenA,
        bytes calldata swapData
    ) external view returns (bool);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;
    enum Module {
        RESOLVER,
        TIME,
        PROXY,
        SINGLE_EXEC
    }

    struct ModuleData {
        Module[] modules;
        bytes[] args;
    }

interface IOps {
    function createTask(
        address execAddress,
        bytes calldata execDataOrSelector,
        ModuleData calldata moduleData,
        address feeToken
    ) external returns (bytes32 taskId);

    function cancelTask(bytes32 taskId) external;

    function getFeeDetails() external view returns (uint256, address);

    function gelato() external view returns (address payable);

    function taskTreasury() external view returns (ITaskTreasuryUpgradable);
}

interface ITaskTreasuryUpgradable {
    function depositFunds(
        address receiver,
        address token,
        uint256 amount
    ) external payable;

    function withdrawFunds(
        address payable receiver,
        address token,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRouter {
    function factory() external view returns (address);

    function WNative() external view returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
    external
    returns (
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity
    );

    function addLiquidityNative(
        address token,
        uint32 fee,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountNative, uint liquidity);

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint32 fee,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityNative(
        address token,
        uint32 fee,
        uint liquidity,
        uint amountTokenMin,
        uint amountNativeMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountNative);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        uint32[] calldata feePath,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactNativeForTokens(uint amountOutMin, address[] calldata path, uint32[] calldata feePath, address to, uint deadline)
    external
    payable
    returns (uint[] memory amounts);

    function swapTokensForExactNative(uint amountOut, uint amountInMax, address[] calldata path, uint32[] calldata feePath, address to, uint deadline)
    external
    returns (uint[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function quoteByTokens(
        uint256 amountA,
        address tokenA,
        address tokenB,
        uint32 fee
    ) external view returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut,
        uint32 fee
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] memory path, uint32[] calldata feePath)
    external
    view
    returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] memory path, uint32[] calldata feePath)
    external
    view
    returns (uint256[] memory amounts);
}