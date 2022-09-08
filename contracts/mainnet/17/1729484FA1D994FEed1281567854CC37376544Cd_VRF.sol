// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./utils/Swapper.sol";
import "./VRFInternal.sol";
import "../2_words/WordsStorage.sol";

contract VRF is VRFInternal, Swapper {

    function init() external {
        __vrf_init();

        //initial swap
        swap_MATIC_LINK677(vrfFee(), 10 ** 17);
    }

    function linkBalance() public view returns(uint256) {
        return _linkBalance();
    }

    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(
            msg.sender == VRFStorage.layout().vrfCoordinator, 
            "Only VRFCoordinator can fulfill"
        );
        _fulfillRandomness(requestId, randomness);

        WordsStorage.Word storage word = WordsStorage.layout().words[_tokenId(requestId)];
        swap_MATIC_LINK677(word.initialValue / 10);
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.7;
pragma abicoder v2;

import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

interface IwERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function balanceOf(address _owner) external view returns(uint256);
}

interface IpegSwap {
    function swap(uint256 amount, address source, address target) external;
}

// on polygon matic mainnet
contract Swapper {

    ISwapRouter internal constant uniSwap = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    IpegSwap internal constant pegSwap = IpegSwap(0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b);
    address internal constant wMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    address internal constant LINK_ERC20 = 0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39;
    address internal constant LINK_ERC677 = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;

    // For this example, we will set the pool fee to 0.3%.
    uint24 internal constant poolFee = 3000;

    function swap_MATIC_LINK677(uint256 amountIn) internal {

        uint256 amount_LINK20 = swap_MATIC_LINK20(amountIn);

        TransferHelper.safeApprove(LINK_ERC20, address(pegSwap), amount_LINK20);

        swap_LINK20_677(amount_LINK20);
    }

    function swap_MATIC_LINK677(uint256 amountOut, uint256 amountInMaximum) internal {

        swap_MATIC_LINK20(amountOut, amountInMaximum);

        TransferHelper.safeApprove(LINK_ERC20, address(pegSwap), amountOut);

        swap_LINK20_677(amountOut);
    }

    function swap_MATIC_LINK20(uint256 amountIn) internal returns(uint256 amountOut) {
        IwERC20 wm = IwERC20(wMATIC);
        wm.deposit{value: amountIn - wm.balanceOf(address(this))}();

        TransferHelper.safeApprove(wMATIC, address(uniSwap), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: wMATIC,
                tokenOut: LINK_ERC20,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        amountOut = uniSwap.exactInputSingle(params);
    }

    function swap_MATIC_LINK20(uint256 amountOut, uint256 amountInMaximum) internal returns(uint256 amountIn) {
        IwERC20 wm = IwERC20(wMATIC);
        wm.deposit{value: amountInMaximum - wm.balanceOf(address(this))}();

        TransferHelper.safeApprove(wMATIC, address(uniSwap), amountInMaximum);

        ISwapRouter.ExactOutputSingleParams memory params =
            ISwapRouter.ExactOutputSingleParams({
                tokenIn: wMATIC,
                tokenOut: LINK_ERC20,
                fee: poolFee,
                recipient: address(this),
                deadline: block.timestamp,
                amountOut: amountOut,
                amountInMaximum: amountInMaximum,
                sqrtPriceLimitX96: 0
            });

        amountIn = uniSwap.exactOutputSingle(params);
    }

    function swap_LINK20_677(uint256 amount) internal {
        pegSwap.swap(amount, LINK_ERC20, LINK_ERC677);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFRequestIDBase.sol";
import "./VRFStorage.sol";

abstract contract VRFInternal is VRFRequestIDBase {
    using VRFStorage for VRFStorage.Layout;

    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    event NewRandomResult(uint256 tokenId, uint256 randomness);

    function __vrf_init() internal {
        VRFStorage.Layout storage l = VRFStorage.layout();

        l.vrfCoordinator = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0; // on polygon mainnet
        l.LINK = LinkTokenInterface(0xb0897686c545045aFc77CF20eC7A532E3120E0F1); // on polygon mainnet
        l.keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
        l.fee = 0.0001 * 10 ** 18; // 0.0001 LINK (Varies by network)
    }

    function _linkBalance() internal view returns(uint256) {
        return VRFStorage.layout().LINK.balanceOf(address(this));
    }

    function vrfFee() internal view returns(uint256) {
        return VRFStorage.layout().fee;
    }

    function requestRandomness(uint256 tokenId) internal {
        VRFStorage.Layout storage l = VRFStorage.layout();
        l.LINK.transferAndCall(l.vrfCoordinator, l.fee, abi.encode(l.keyHash, USER_SEED_PLACEHOLDER));
        uint256 vRFSeed = makeVRFInputSeed(
            l.keyHash, 
            USER_SEED_PLACEHOLDER, 
            address(this), 
            l.nonces[l.keyHash]++
        );
        bytes32 requestId = makeRequestId(l.keyHash, vRFSeed);
        l.randomRequests[requestId] = tokenId;
    }

    function _tokenId(bytes32 requestId) internal view returns(uint256) {
        return VRFStorage.layout().randomRequests[requestId];
    }

    function _fulfillRandomness(bytes32 requestId, uint256 randomness) internal {
        _newRandomResult(VRFStorage.layout().randomRequests[requestId], randomness);
    }

    function _newRandomResult(uint256 tokenId, uint256 randomness) private {
        VRFStorage.layout().randomResults[tokenId] = randomness;
        emit NewRandomResult(tokenId, randomness);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.13;


library WordsStorage {

    bytes32 constant VALUABLE_WORDS_STORAGE_POSITION = keccak256("VALUABLE_WORDS_STORAGE_POSITION");

    struct Layout {
        mapping(uint256 => Word) words;
        mapping(address => User) users;
        mapping(bytes32 => WordHash) wordHashes;
        mapping(uint256 => string) categories;
        uint256 nextTokenId;
        uint256 minInitialValue;
        uint256 minDomValue;
        uint256 withdrawableValueFraction; //denominator is 10,000
        uint256 votingPowerFraction; //denominator is 10,000
        uint256 timeToFullVotingPower; 
        uint256 totalValue;
        uint256 totalPower;
        uint256 initialBlock;
        string defaultExternalURL;
        string notification1;
        string notification2;
    }

    struct User {
        uint256 power;
        uint256 lastVotingPowerRecorded;
        uint256 lastTransferTimestamp;
    }

    struct WordHash {
        mapping(uint256 => uint256) indexToId;
        mapping(uint256 => uint256) idToIndex;
        uint256 wordHashCounter;
    }

    struct Word {
        mapping(uint256 => Dom) doms;
        string[] word;
        string tags;
        string externalURL;
        address author;
        uint256 domsCount;
        uint256 initialValue;
        uint256 initialPower;
        uint256 value;
        uint256 power;
        uint256 blockNumber;
        uint64 category;
        uint64 template;
    }

    struct Dom{
        address dommer;
        uint256 amount;
        string mention;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = VALUABLE_WORDS_STORAGE_POSITION;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface LinkTokenInterface {
  function allowance(address owner, address spender) external view returns (uint256 remaining);

  function approve(address spender, uint256 value) external returns (bool success);

  function balanceOf(address owner) external view returns (uint256 balance);

  function decimals() external view returns (uint8 decimalPlaces);

  function decreaseApproval(address spender, uint256 addedValue) external returns (bool success);

  function increaseApproval(address spender, uint256 subtractedValue) external;

  function name() external view returns (string memory tokenName);

  function symbol() external view returns (string memory tokenSymbol);

  function totalSupply() external view returns (uint256 totalTokensIssued);

  function transfer(address to, uint256 value) external returns (bool success);

  function transferAndCall(
    address to,
    uint256 value,
    bytes calldata data
  ) external returns (bool success);

  function transferFrom(
    address from,
    address to,
    uint256 value
  ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VRFRequestIDBase {
  /**
   * @notice returns the seed which is actually input to the VRF coordinator
   *
   * @dev To prevent repetition of VRF output due to repetition of the
   * @dev user-supplied seed, that seed is combined in a hash with the
   * @dev user-specific nonce, and the address of the consuming contract. The
   * @dev risk of repetition is mostly mitigated by inclusion of a blockhash in
   * @dev the final seed, but the nonce does protect against repetition in
   * @dev requests which are included in a single block.
   *
   * @param _userSeed VRF seed input provided by user
   * @param _requester Address of the requesting contract
   * @param _nonce User-specific nonce at the time of the request
   */
  function makeVRFInputSeed(
    bytes32 _keyHash,
    uint256 _userSeed,
    address _requester,
    uint256 _nonce
  ) internal pure returns (uint256) {
    return uint256(keccak256(abi.encode(_keyHash, _userSeed, _requester, _nonce)));
  }

  /**
   * @notice Returns the id for this request
   * @param _keyHash The serviceAgreement ID to be used for this request
   * @param _vRFInputSeed The seed to be passed directly to the VRF
   * @return The id for this request
   *
   * @dev Note that _vRFInputSeed is not the seed passed by the consuming
   * @dev contract, but the one generated by makeVRFInputSeed
   */
  function makeRequestId(bytes32 _keyHash, uint256 _vRFInputSeed) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(_keyHash, _vRFInputSeed));
  }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";

library VRFStorage {

    bytes32 constant VRF_STORAGE_POSITION = keccak256("VRF_STORAGE_POSITION");

    struct Layout {
        LinkTokenInterface LINK;
        address vrfCoordinator;
        mapping(bytes32 => uint256) nonces;

        bytes32 keyHash;
        uint256 fee;
        mapping(bytes32 => uint256) randomRequests;
        mapping(uint256 => uint256) randomResults;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = VRF_STORAGE_POSITION;
        assembly {
            l.slot := slot
        }
    }
}