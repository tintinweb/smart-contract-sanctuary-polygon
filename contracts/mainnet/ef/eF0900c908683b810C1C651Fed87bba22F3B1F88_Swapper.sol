// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./ISwapPlace.sol";
import "./ISwapper.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "../utils/Initializable.sol";
import { Governable } from "../governance/Governable.sol";

contract Swapper is ISwapper, Initializable, Governable {
    using SafeERC20 for IERC20;
    // token's pair to swap place info list
    mapping(address => mapping(address => SwapPlaceInfo[])) public swapPlaceInfos;

    // swap place type to swap place address
    mapping(string => address) public swapPlaces;

    // pool address to swap place type
    mapping(address => string) public poolSwapPlaceTypes;

    // default split parts for common swap request
    uint256 public defaultSplitPartsAmount;

    function setParams(uint256 _defaultSplitPartsAmount) external {
        defaultSplitPartsAmount = _defaultSplitPartsAmount;
        emit ParamsUpdated(defaultSplitPartsAmount);
    }

    function swapPlaceInfoRegister(
        address token0,
        address token1,
        address pool,
        string calldata swapPlaceType
    ) public onlyGovernor {
        require(token0 != address(0), "Zero address not allowed");
        require(token1 != address(0), "Zero address not allowed");
        require(pool != address(0), "Zero address not allowed");

        SwapPlaceInfo[] storage swapPlaceInfoList = swapPlaceInfos[token0][token1];
        if (swapPlaceInfoList.length > 0) {
            for (uint i; i < swapPlaceInfoList.length; i++) {
                require(swapPlaceInfoList[i].pool != pool, "Already in list");
            }
        }

        poolSwapPlaceTypes[pool] = swapPlaceType;
        swapPlaceInfos[token0][token1].push(SwapPlaceInfo(pool, swapPlaceType));
        swapPlaceInfos[token1][token0].push(SwapPlaceInfo(pool, swapPlaceType));

        emit SwapPlaceInfoRegistered(token0, token1, pool, swapPlaceType);
    }

    function swapPlaceInfoLength(address token0, address token1) external view returns (uint256) {
        return swapPlaceInfos[token0][token1].length;
    }

    function swapPlaceInfoRemove(address token0, address token1, address pool) external onlyGovernor {
        require(token0 != address(0), "Zero address not allowed");
        require(token1 != address(0), "Zero address not allowed");
        require(pool != address(0), "Zero address not allowed");

        SwapPlaceInfo[] storage swapPlaceInfoList = swapPlaceInfos[token0][token1];
        require(swapPlaceInfoList.length > 0, "Cant remove from empty array");

        uint256 index;
        for (uint i; i < swapPlaceInfoList.length; i++) {
            if (swapPlaceInfoList[i].pool == pool) {
                index = i;
                break;
            }
        }

        swapPlaceInfoList[index] = swapPlaceInfoList[swapPlaceInfoList.length - 1];
        swapPlaceInfoList.pop();

        swapPlaceInfoList = swapPlaceInfos[token1][token0];
        swapPlaceInfoList[index] = swapPlaceInfoList[swapPlaceInfoList.length - 1];
        swapPlaceInfoList.pop();

        emit SwapPlaceInfoRemoved(token0, token1, pool);
    }

    function swapPlaceRegister(string calldata swapPlaceType, address swapPlace) external onlyGovernor {
        require(swapPlace != address(0), "Zero address not allowed");
        swapPlaces[swapPlaceType] = swapPlace;
        emit SwapPlaceRegistered(swapPlaceType, swapPlace);
    }

    function swapPlaceRemove(string calldata swapPlaceType) external onlyGovernor {
        delete swapPlaces[swapPlaceType];
        emit SwapPlaceRemoved(swapPlaceType);
    }

    // ---  structures

    struct CalcContext {
        address swapPlace;
        address pool;

        uint256 committedIndex;
        uint256 committedIn;
        uint256 committedOut;

        uint256 lastIn;
        uint256 lastOut;
        uint256 lastOutNormalized;
    }


    // ---  logic

    function swapCommon(address tokenIn, address tokenOut, uint256 amountIn) external override returns (uint256) {
        SwapParams memory params = SwapParams(
            tokenIn,
            tokenOut,
            amountIn,
            0,
            defaultSplitPartsAmount
        );
        return swap(params);
    }


    function swap(SwapParams memory params) public override returns (uint256) {
        SwapRoute[] memory swapRoutes = swapPath(params);
        return swapBySwapRoutes(params, swapRoutes);
    }

    function swapExact(SwapParamsExact memory params) external override returns (uint256) {
        string memory swapPlaceType = poolSwapPlaceTypes[params.pool];
        require(bytes(swapPlaceType).length > 0, "Not found swapPlaceType for pool");

        address swapPlace = swapPlaces[swapPlaceType];
        require(swapPlace != address(0x0), "Not found swapPlaceType for pool");

        SwapRoute[] memory swapRoutes = new SwapRoute[](1);
        swapRoutes[0] = SwapRoute(
            params.tokenIn,
            params.tokenOut,
            params.amountIn,
            0,
            swapPlace,
            params.pool
        );
        return swapBySwapRoutes(
            params.tokenIn, params.amountIn,
            params.tokenOut, params.amountOutMin,
            swapRoutes
        );

    }

    function swapBySwapRoutes(SwapParams memory params, SwapRoute[] memory swapRoutes) public override returns (uint256) {
        return swapBySwapRoutes(
            params.tokenIn, params.amountIn,
            params.tokenOut, params.amountOutMin,
            swapRoutes
        );
    }

    function swapBySwapRoutes(
        address tokenIn, uint256 amountIn,
        address tokenOut, uint256 amountOutMin,
        SwapRoute[] memory swapRoutes
    ) public override returns (uint256) {
        IERC20(tokenIn).safeTransferFrom(msg.sender, address(this), amountIn);

        uint256 amountOut;
        for (uint i; i < swapRoutes.length; i++) {
            amountOut += swapRoutes[i].amountOut;
        }
        require(amountOut >= amountOutMin, "amountOut less than needed");

        for (uint i; i < swapRoutes.length; i++) {
            SwapRoute memory swapRoute = swapRoutes[i];
            IERC20(swapRoute.tokenIn).safeTransfer(swapRoute.swapPlace, swapRoute.amountIn);
            ISwapPlace(swapRoute.swapPlace).swap(swapRoute);
        }

        uint256 balanceOut = IERC20(tokenOut).balanceOf(address(this));
        require(
            balanceOut >= amountOutMin,
            "balanceOut lower than amountOutMin"
        );

        IERC20(tokenOut).safeTransfer(msg.sender, balanceOut);
        return balanceOut;
    }
    
    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) external override view returns (uint256) {
        SwapParams memory params = SwapParams(
            tokenIn,
            tokenOut,
            amountIn,
            0,
            defaultSplitPartsAmount
        );
        return _getAmountOut(params);
    }

    function getAmountOut(SwapParams memory params) external override view returns (uint256) {
        return _getAmountOut(params);
    }

    function _getAmountOut(SwapParams memory params) internal view returns (uint256) {
        SwapRoute[] memory swapRoutes = swapPath(params);
        uint256 amountOut;
        for (uint i; i < swapRoutes.length; i++) {
            amountOut += swapRoutes[i].amountOut;
        }
        return amountOut;
    }

    function swapPath(SwapParams memory params) public override view returns (SwapRoute[] memory) {
        SwapPlaceInfo[] storage swapPlaceInfoList = swapPlaceInfos[params.tokenIn][params.tokenOut];
        require(swapPlaceInfoList.length > 0, "Cant find swapPlace by tokens");

        uint256 iterations;
        if (swapPlaceInfoList.length == 1) {
            iterations = 1;
        } else if (params.partsAmount == 0) {
            iterations = swapPlaceInfoList.length;
        } else {
            iterations = params.partsAmount;
        }
        require(params.amountIn >= iterations, "amountIn must be non less than iterations");
        uint256 iterationAmount = params.amountIn / iterations;


        // 1. setup context
        CalcContext[] memory contexts = prepareContext(
            swapPlaceInfoList,
            params,
            iterationAmount
        );

        // 2. find best swaps
        uint256 lastCommittedIndex = calc(
            params,
            iterations,
            iterationAmount,
            contexts
        );

        // 4. recalc amounts if delta exists
        uint256 lostAmountInDelta = params.amountIn - iterationAmount * iterations;
        if (lostAmountInDelta > 0) {
            recalcLastCommittedWithDelta(
                params,
                iterationAmount,
                contexts,
                lastCommittedIndex,
                lostAmountInDelta
            );
        }

        // 5. make swaps list
        SwapRoute[] memory swapRoutes = makeSwapRoutes(
            params,
            contexts
        );

        return swapRoutes;
    }

    function prepareContext(
        SwapPlaceInfo[] storage swapPlaceInfoList,
        SwapParams memory params,
        uint256 iterationAmount
    ) internal view returns (CalcContext[] memory contexts){
        contexts = new CalcContext[](swapPlaceInfoList.length);
        for (uint i; i < swapPlaceInfoList.length; i++) {
            SwapPlaceInfo memory swapPlaceInfo = swapPlaceInfoList[i];
            address swapPlace = swapPlaces[swapPlaceInfo.swapPlaceType];

            uint256 amountOut = ISwapPlace(swapPlace).getAmountOut(
                params.tokenIn,
                params.tokenOut,
                iterationAmount,
                swapPlaceInfoList[i].pool
            );
            contexts[i] = CalcContext(
                swapPlace,
                swapPlaceInfo.pool,
                0, 0, 0,
                iterationAmount,
                amountOut,
                amountOut
            );
        }
    }

    function calc(
        SwapParams memory params,
        uint256 iterations,
        uint256 iterationAmount,
        CalcContext[] memory contexts
    ) internal view returns (uint256){

        uint256 lastCommittedIndex;
        uint256 iterationsDone;
        while (true) {
            // 2. Find best swap and commit
            uint256 committedIndex = findBestSwapAndCommit(contexts);

            iterationsDone++;
            if (iterationsDone >= iterations) {
                lastCommittedIndex = committedIndex;
                break;
            }

            // 3. Recalc next amount out for committed
            uint256 amountIn;
            uint256 multiplayer = contexts[committedIndex].committedIndex + 1;
            if (multiplayer == iterations) {
                amountIn = params.amountIn;
            } else {
                amountIn = iterationAmount * multiplayer;
            }

            uint256 amountOut = ISwapPlace(contexts[committedIndex].swapPlace).getAmountOut(
                params.tokenIn,
                params.tokenOut,
                amountIn,
                contexts[committedIndex].pool
            );

            contexts[committedIndex].lastIn = amountIn;
            contexts[committedIndex].lastOut = amountOut;
            contexts[committedIndex].lastOutNormalized = amountOut / multiplayer;

        }

        return lastCommittedIndex;
    }

    function findBestSwapAndCommit(CalcContext[] memory contexts) internal pure returns (uint256){
        uint256 maxValue = 0;
        uint256 maxValueIndex = 0;
        for (uint256 i; i < contexts.length; i++) {
            uint256 value = contexts[i].lastOutNormalized;
            if (maxValue < value) {
                maxValue = value;
                maxValueIndex = i;
            }
        }

        contexts[maxValueIndex].committedIn = contexts[maxValueIndex].lastIn;
        contexts[maxValueIndex].committedOut = contexts[maxValueIndex].lastOut;
        contexts[maxValueIndex].committedIndex++;

        return maxValueIndex;
    }

    function recalcLastCommittedWithDelta(
        SwapParams memory params,
        uint256 iterationAmount,
        CalcContext[] memory contexts,
        uint256 committedIndex,
        uint256 lostAmountInDelta
    ) internal view {

        uint256 multiplayer = contexts[committedIndex].committedIndex;
        uint256 amountIn = iterationAmount * multiplayer + lostAmountInDelta;

        uint256 amountOut = ISwapPlace(contexts[committedIndex].swapPlace).getAmountOut(
            params.tokenIn,
            params.tokenOut,
            amountIn,
            contexts[committedIndex].pool
        );

        contexts[committedIndex].committedIn = amountIn;
        contexts[committedIndex].committedOut = amountOut;

    }

    function makeSwapRoutes(
        SwapParams memory params,
        CalcContext[] memory contexts
    ) internal pure returns (SwapRoute[] memory swapRoutes){

        uint256 nonZeroSwaps;
        for (uint i; i < contexts.length; i++) {
            CalcContext memory context = contexts[i];
            if (context.committedIndex != 0) {
                nonZeroSwaps++;
            }
        }


        swapRoutes = new SwapRoute[](nonZeroSwaps);
        uint swapRoutesIndex;
        for (uint i; i < contexts.length; i++) {
            CalcContext memory context = contexts[i];
            if (context.committedIndex == 0) {
                continue;
            }
            swapRoutes[swapRoutesIndex] = SwapRoute(
                params.tokenIn,
                params.tokenOut,
                context.committedIn,
                context.committedOut,
                context.swapPlace,
                context.pool
            );
            swapRoutesIndex++;
        }
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./Structures.sol";


interface ISwapPlace is Structures {

    function swapPlaceType() external view returns (string memory);

    function swap(
        SwapRoute calldata route
    ) external returns (uint256);

    function getAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        address pool
    ) external view returns (uint256);

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Structures.sol";


interface ISwapper is Structures {

    // --- events

    event ParamsUpdated(
        uint256 defaultSplitPartsAmount
    );

    event SwapPlaceInfoRegistered(
        address indexed token0,
        address indexed token1,
        address pool,
        string swapPlaceType
    );

    event SwapPlaceInfoRemoved(
        address indexed token0,
        address indexed token1,
        address pool
    );

    event SwapPlaceRegistered(
        string swapPlaceType,
        address swapPlace
    );

    event SwapPlaceRemoved(
        string swapPlaceType
    );


    // ---  structures

    struct SwapPlaceInfo {
        address pool;
        string swapPlaceType;
    }

    struct SwapParams {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        uint256 partsAmount; // if zero - then would be used pools amount for pair
    }

    struct SwapParamsExact {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOutMin;
        address pool; // pool for 100% swap without comparing available prices
    }


    // ---  logic

    /*
     * Call swap with params with amountOutMin = 0 and partsAmount = default in contract
     */
    function swapCommon(address tokenIn, address tokenOut, uint256 amountIn) external returns (uint256);

    function swap(SwapParams calldata params) external returns (uint256);

    function swapExact(SwapParamsExact calldata params) external returns (uint256);

    function swapBySwapRoutes(SwapParams calldata params, SwapRoute[] memory swapRoutes) external returns (uint256);

    function swapBySwapRoutes(
        address tokenIn, uint256 amountIn,
        address tokenOut, uint256 amountOutMin,
        SwapRoute[] memory swapRoutes
    ) external returns (uint256);

    /*
     * Returned value could be higher than a real swap result because of some protocols
     * algorithms which are different on calculation value for out and values on real swap.
     */
    function getAmountOut(SwapParams calldata params) external view returns (uint256);

    function getAmountOut(address tokenIn, address tokenOut, uint256 amountIn) external view returns (uint256) ;

    function swapPath(SwapParams calldata params) external view returns (SwapRoute[] memory);

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(
            initializing || !initialized,
            "Initializable: contract is already initialized"
        );

        bool isTopLevelCall = !initializing;
        if (isTopLevelCall) {
            initializing = true;
            initialized = true;
        }

        _;

        if (isTopLevelCall) {
            initializing = false;
        }
    }

    uint256[50] private ______gap;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

/**
 * @title CASH Governable Contract
 * @dev Copy of the openzeppelin Ownable.sol contract with nomenclature change
 *      from owner to governor and renounce methods removed. Does not use
 *      Context.sol like Ownable.sol does for simplification.
 * @author XStabl Protocol Inc
 */
contract Governable {
    // Storage position of the owner and pendingOwner of the contract
    // keccak256("CASH.governor");
    bytes32 private constant governorPosition =
        0x83f34c88ec39d54d1e423bd8a181ebc59ede5dcc9996c2df334668b4f89fdd73;

    // keccak256("CASH.pending.governor");
    bytes32 private constant pendingGovernorPosition =
        0x7eaf9a7750884803435dfabc67aa617a7d8fefb23d8d84b3c9722bd69e48c4bc;

    // keccak256("CASH.reentry.status");
    bytes32 private constant reentryStatusPosition =
        0x48a06827bfe8bfc0a59fe65d0fa78f553938265ed1f971326fc09947d19a593c;

    // See OpenZeppelin ReentrancyGuard implementation
    uint256 constant _NOT_ENTERED = 1;
    uint256 constant _ENTERED = 2;

    event PendingGovernorshipTransfer(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    event GovernorshipTransferred(
        address indexed previousGovernor,
        address indexed newGovernor
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial Governor.
     */
    constructor() {
        _setGovernor(msg.sender);
        emit GovernorshipTransferred(address(0), _governor());
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function governor() public view returns (address) {
        return _governor();
    }

    /**
     * @dev Returns the address of the current Governor.
     */
    function _governor() internal view returns (address governorOut) {
        bytes32 position = governorPosition;
        assembly {
            governorOut := sload(position)
        }
    }

    /**
     * @dev Returns the address of the pending Governor.
     */
    function _pendingGovernor()
        internal
        view
        returns (address pendingGovernor)
    {
        bytes32 position = pendingGovernorPosition;
        assembly {
            pendingGovernor := sload(position)
        }
    }

    /**
     * @dev Throws if called by any account other than the Governor.
     */
    modifier onlyGovernor() {
        require(isGovernor(), "Caller is not the Governor");
        _;
    }

    /**
     * @dev Returns true if the caller is the current Governor.
     */
    function isGovernor() public view returns (bool) {
        return msg.sender == _governor();
    }

    function _setGovernor(address newGovernor) internal {
        bytes32 position = governorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        bytes32 position = reentryStatusPosition;
        uint256 _reentry_status;
        assembly {
            _reentry_status := sload(position)
        }

        // On the first call to nonReentrant, _notEntered will be true
        require(_reentry_status != _ENTERED, "Reentrant call");

        // Any calls to nonReentrant after this point will fail
        assembly {
            sstore(position, _ENTERED)
        }

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        assembly {
            sstore(position, _NOT_ENTERED)
        }
    }

    function _setPendingGovernor(address newGovernor) internal {
        bytes32 position = pendingGovernorPosition;
        assembly {
            sstore(position, newGovernor)
        }
    }

    /**
     * @dev Transfers Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the current Governor. Must be claimed for this to complete
     * @param _newGovernor Address of the new Governor
     */
    function transferGovernance(address _newGovernor) external onlyGovernor {
        _setPendingGovernor(_newGovernor);
        emit PendingGovernorshipTransfer(_governor(), _newGovernor);
    }

    /**
     * @dev Claim Governance of the contract to a new account (`newGovernor`).
     * Can only be called by the new Governor.
     */
    function claimGovernance() external {
        require(
            msg.sender == _pendingGovernor(),
            "Only the pending Governor can complete the claim"
        );
        _changeGovernor(msg.sender);
    }

    /**
     * @dev Change Governance of the contract to a new account (`newGovernor`).
     * @param _newGovernor Address of the new Governor
     */
    function _changeGovernor(address _newGovernor) internal {
        require(_newGovernor != address(0), "New Governor is address(0)");
        emit GovernorshipTransferred(_governor(), _newGovernor);
        _setGovernor(_newGovernor);
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;


interface Structures {

    struct SwapRoute {
        address tokenIn;
        address tokenOut;
        uint256 amountIn;
        uint256 amountOut;
        address swapPlace;
        address pool;
        //        string swapPlaceType;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}