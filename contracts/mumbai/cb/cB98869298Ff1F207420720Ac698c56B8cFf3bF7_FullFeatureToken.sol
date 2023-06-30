// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Helpers } from "./lib/Helpers.sol";

interface NFTCollectible {
  function mint(address receiver) external payable;
}

interface IUniswapV2Router {
  // solhint-disable-next-line func-name-mixedcase
  function WETH() external pure returns (address);

  function addLiquidityETH(
    address token,
    uint256 amountTokenDesired,
    uint256 amountTokenMin,
    uint256 amountETHMin,
    address to,
    uint256 deadline
  )
    external
    payable
    returns (
      uint256 amountToken,
      uint256 amountETH,
      uint256 liquidity
    );
}

interface IUniswapV2Factory {
  function getPair(address tokenA, address tokenB)
    external
    view
    returns (address pair);
}

interface IERC1155 {
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) external;
}

interface IERC721 {
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

contract CoinService {
  using SafeERC20 for IERC20;
  /// @notice records tokenIds and associated amounts
  struct BatchTransfer {
    uint256[] tokenIds;
    uint256[] amounts;
  }

  /// @notice address of the Uniswap Factory address
  address private immutable _addressFactory;
  /// @notice address of the Uniswap Router address
  address private immutable _addressRouter;
  /// @notice address of the fee receiver (Bitbond wallet)
  address private constant FEE_RECEIVER =
    0x9254C0fcB2FaA4550B9ba582558cE1D03Ba3d05d;

  /// @notice emitted when a new contract is created
  event CreatedContract(
    address indexed tokenAddress,
    address indexed tokenOwner
  );
  /// @notice emitted when a liquidity is added to a Uniswap pair
  event LiquidityAdded(
    address indexed liquidityOwner,
    address indexed pairAddress,
    uint256 amountLiquidityTokens
  );
  /// @notice emitted after a multi token transfer
  event MultiTransfer(address indexed from, address indexed to, uint256 amount);
  /// @notice emitted after a ERC20 multi token transfer
  event MultiERC20Transfer(
    address indexed from,
    address indexed to,
    uint256 amount,
    IERC20 token
  );
  /// @notice emitted after a ERC721 multi token transfer
  event MultiERC721Transfer(
    address indexed from,
    address indexed to,
    uint256 tokenId,
    IERC721 token
  );
  /// @notice emitted after a ERC1155 multi token transfer
  event MultiERC1155Transfer(
    address indexed from,
    address indexed to,
    uint256[] tokenIds,
    uint256[] amounts,
    IERC1155 token
  );

  /// @notice raised when the token amount is zero
  error InvalidTokenAmount(uint256 amount);
  /// @notice raised when array length is zero
  error InvalidArrayLength(uint256 length);
  /// @notice raised when 2 arrays have different length
  error ArrayMismatch(uint256 length1, uint256 length2);

  constructor(address payable router, address payable factory) {
    Helpers.validateAddress(router);
    Helpers.validateAddress(factory);
    _addressRouter = router;
    _addressFactory = factory;
  }

  /**
   * @notice Method for deploying a new contract using bytecode
   * @param bytecode - bytecode of the contract to deploy
   * @return address - of the newly deployed contract
   */
  function deployContract(bytes memory bytecode)
    external
    payable
    returns (address)
  {
    Helpers.safeTransferETH(FEE_RECEIVER, msg.value);
    // attempt to get a random salt
    uint256 salt = uint256(
      keccak256(abi.encodePacked(msg.sender, block.difficulty, block.timestamp))
    );
    address contractAddress;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      contractAddress := create2(0, add(bytecode, 0x20), mload(bytecode), salt)
      if iszero(extcodesize(contractAddress)) {
        revert(0, 0)
      }
    }
    emit CreatedContract(contractAddress, msg.sender);
    return contractAddress;
  }

  /**
   * @notice Add liquidity to a Uniswap pair
   * @param feeAmount - the amount of fee to pay
   * @param addressToken - the address of the token to add liquidity for
   * @param amountToken - the amount of liquidity to add
   */
  function addLiquidity(
    uint256 feeAmount,
    address addressToken,
    uint256 amountToken
  ) external payable {
    Helpers.safeTransferETH(FEE_RECEIVER, feeAmount);
    if (amountToken == 0) {
      revert InvalidTokenAmount(amountToken);
    }
    uint256 amountWETH = msg.value - feeAmount;
    IERC20(addressToken).safeTransferFrom(
      msg.sender,
      address(this),
      amountToken
    );
    IERC20(addressToken).safeIncreaseAllowance(_addressRouter, amountToken);
    (, , uint256 liquidity) = IUniswapV2Router(_addressRouter).addLiquidityETH{
      value: amountWETH
    }(
      addressToken,
      amountToken,
      amountToken,
      amountWETH,
      address(msg.sender),
      block.timestamp
    );
    address addressWETH = IUniswapV2Router(_addressRouter).WETH();
    address addressLiquidity = IUniswapV2Factory(_addressFactory).getPair(
      addressWETH,
      addressToken
    );
    emit LiquidityAdded(msg.sender, addressLiquidity, liquidity);
  }

  /**
   * @notice get the address of the Uniswap pair for a token
   * @param addressToken - the address of the token to get the pair for
   * @return address - for the pair
   */
  function getLiquidityPairAddress(address addressToken)
    external
    view
    returns (address)
  {
    Helpers.validateAddress(addressToken);
    address addressWETH = IUniswapV2Router(_addressRouter).WETH();
    address addressLiquidity = IUniswapV2Factory(_addressFactory).getPair(
      addressWETH,
      addressToken
    );

    return addressLiquidity;
  }

  /**
   * @notice Send to multiple addresses using two arrays which
   * includes the addresses and associated amounts.
   * @param feeAmount - the amount of fee to pay
   * @param addresses - array of addresses to send to
   * @param amounts - array of associated amounts to send for each address
   * @return bool - true if successful
   */
  function multiTransfer(
    uint256 feeAmount,
    address[] calldata addresses,
    uint256[] calldata amounts
  ) external payable returns (bool) {
    Helpers.safeTransferETH(FEE_RECEIVER, feeAmount);
    if (addresses.length == 0) {
      revert InvalidArrayLength(addresses.length);
    }
    if (addresses.length != amounts.length) {
      revert ArrayMismatch(addresses.length, amounts.length);
    }

    uint256 toReturn = msg.value - feeAmount;

    for (uint256 i; i < addresses.length; ) {
      Helpers.safeTransferETH(addresses[i], amounts[i]);
      toReturn -= amounts[i];
      emit MultiTransfer(msg.sender, addresses[i], amounts[i]);
      unchecked {
        ++i;
      }
    }
    Helpers.safeTransferETH(msg.sender, toReturn);
    return true;
  }

  /**
   * @notice Send ERC20 tokens to multiple addresses
   * using two arrays addresses and associated amounts.
   * @param token - the token to send
   * @param addresses - array of addresses to send to
   * @param amounts - array of associated token amounts for each address
   */
  function multiERC20Transfer(
    IERC20 token,
    address[] calldata addresses,
    uint256[] calldata amounts
  ) external payable {
    Helpers.safeTransferETH(FEE_RECEIVER, msg.value);
    if (addresses.length == 0) {
      revert InvalidArrayLength(addresses.length);
    }
    if (addresses.length != amounts.length) {
      revert ArrayMismatch(addresses.length, amounts.length);
    }

    for (uint256 i; i < addresses.length; ) {
      IERC20(token).safeTransferFrom(msg.sender, addresses[i], amounts[i]);
      emit MultiERC20Transfer(msg.sender, addresses[i], amounts[i], token);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Send ERC721 tokens to multiple addresses
   * using two arrays addresses and associated tokenIds.
   * @param token - the token to send
   * @param addresses - array of addresses to send to
   * @param tokenIds - array of associated tokenIds for each address
   */
  function multiERC721Transfer(
    IERC721 token,
    address[] calldata addresses,
    uint256[] calldata tokenIds
  ) external payable {
    Helpers.safeTransferETH(FEE_RECEIVER, msg.value);
    if (addresses.length == 0) {
      revert InvalidArrayLength(addresses.length);
    }
    if (addresses.length != tokenIds.length) {
      revert ArrayMismatch(addresses.length, tokenIds.length);
    }

    for (uint256 i; i < addresses.length; ) {
      IERC721(token).safeTransferFrom(msg.sender, addresses[i], tokenIds[i]);
      emit MultiERC721Transfer(msg.sender, addresses[i], tokenIds[i], token);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Send ERC1155 tokens to multiple addresses
   * using two arrays addresses and associated transfers
   * of type BatchTransfer containing tokenIds and amounts.
   * @param token - the token to send
   * @param addresses - array of addresses to send to
   * @param transfers - array of associated transfers for each address
   */
  function multiERC1155Transfer(
    IERC1155 token,
    address[] calldata addresses,
    BatchTransfer[] calldata transfers
  ) external payable {
    Helpers.safeTransferETH(FEE_RECEIVER, msg.value);
    if (addresses.length == 0) {
      revert InvalidArrayLength(addresses.length);
    }
    if (addresses.length != transfers.length) {
      revert ArrayMismatch(addresses.length, transfers.length);
    }

    for (uint256 i; i < addresses.length; ) {
      IERC1155(token).safeBatchTransferFrom(
        msg.sender,
        addresses[i],
        transfers[i].tokenIds,
        transfers[i].amounts,
        ""
      );

      emit MultiERC1155Transfer(
        msg.sender,
        addresses[i],
        transfers[i].tokenIds,
        transfers[i].amounts,
        token
      );
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice Method to mint nft
   * Message sender is required to pay fee and nft price.
   * Under the hood method is invoking mint on ERC721 contract
   * @param tokenAddress - address of NFT contract to mint tokens
   * @param feeAmount - the amount of fee to pay
   */
  function mintNFT(address tokenAddress, uint256 feeAmount) external payable {
    Helpers.safeTransferETH(FEE_RECEIVER, feeAmount);
    NFTCollectible(tokenAddress).mint{ value: msg.value - feeAmount }(
      msg.sender
    );
  }

  /**
   * @notice Method to batch mint NFTs
   * msg.sender is required to pay fee and nft price.
   * Under the hood method is invoking mint on CollectibleBatchToken contract
   * @param tokenAddress - address of NFT contract to mint tokens
   * @param mintAmount - amount of tokens to mint
   * @param feeAmount - the amount of fee to pay
   */
  function batchMintNFT(
    address tokenAddress,
    uint256 mintAmount,
    uint256 feeAmount
  ) external payable {
    Helpers.safeTransferETH(FEE_RECEIVER, feeAmount);
    if (mintAmount == 0) {
      revert InvalidTokenAmount(mintAmount);
    }

    uint256 amountToPayForOneMint = (msg.value - feeAmount) / mintAmount;

    for (uint256 i = 1; i <= mintAmount; ) {
      NFTCollectible(tokenAddress).mint{ value: amountToPayForOneMint }(
        msg.sender
      );
      unchecked {
        ++i;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

library Helpers {
  /// @notice raised when an address is zero
  error NonZeroAddress(address addr);
  /// @notice raised when payment fails
  error PaymentFailed(address to, uint256 amount);

  /**
   * @notice Helper function to check if an address is a zero address
   * @param addr - address to check
   */
  function validateAddress(address addr) internal pure {
    if (addr == address(0x0)) {
      revert NonZeroAddress(addr);
    }
  }

  /**
   * @notice method to pay a specific address with a specific amount
   * @dev inspired from https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol
   * @param to - the address to pay
   * @param amount - the amount to pay
   */
  function safeTransferETH(address to, uint256 amount) internal {
    bool success;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Transfer the ETH and store if it succeeded or not.
      success := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!success) {
      revert PaymentFailed(to, amount);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
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

    /**
     * @dev Transfer `value` amount of `token` from the calling contract to `to`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    /**
     * @dev Transfer `value` amount of `token` from `from` to `to`, spending the approval given by `from` to the
     * calling contract. If `token` returns no value, non-reverting calls are assumed to be successful.
     */
    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    /**
     * @dev Increase the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 oldAllowance = token.allowance(address(this), spender);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance + value));
    }

    /**
     * @dev Decrease the calling contract's allowance toward `spender` by `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful.
     */
    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, oldAllowance - value));
        }
    }

    /**
     * @dev Set the calling contract's allowance toward `spender` to `value`. If `token` returns no value,
     * non-reverting calls are assumed to be successful. Compatible with tokens that require the approval to be set to
     * 0 before setting it to a non-zero value.
     */
    function forceApprove(IERC20 token, address spender, uint256 value) internal {
        bytes memory approvalCall = abi.encodeWithSelector(token.approve.selector, spender, value);

        if (!_callOptionalReturnBool(token, approvalCall)) {
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, 0));
            _callOptionalReturn(token, approvalCall);
        }
    }

    /**
     * @dev Use a ERC-2612 signature to set the `owner` approval toward `spender` on `token`.
     * Revert on invalid signature.
     */
    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        require(returndata.length == 0 || abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     *
     * This is a variant of {_callOptionalReturn} that silents catches all reverts and returns a bool instead.
     */
    function _callOptionalReturnBool(IERC20 token, bytes memory data) private returns (bool) {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We cannot use {Address-functionCall} here since this should return false
        // and not revert is the subcall reverts.

        (bool success, bytes memory returndata) = address(token).call(data);
        return
            success && (returndata.length == 0 || abi.decode(returndata, (bool))) && Address.isContract(address(token));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Address.sol)

pragma solidity ^0.8.1;

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
     *
     * Furthermore, `isContract` will also return true if the target contract within
     * the same transaction is already scheduled for destruction by `SELFDESTRUCT`,
     * which only has an effect at the end of a transaction.
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.8.0/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _ownerOf(tokenId);
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner or approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner or approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns the owner of the `tokenId`. Does NOT revert if token doesn't exist
     */
    function _ownerOf(uint256 tokenId) internal view virtual returns (address) {
        return _owners[tokenId];
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory data) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId, 1);

        // Check that tokenId was not minted by `_beforeTokenTransfer` hook
        require(!_exists(tokenId), "ERC721: token already minted");

        unchecked {
            // Will not overflow unless all 2**256 token ids are minted to the same owner.
            // Given that tokens are minted one by one, it is impossible in practice that
            // this ever happens. Might change if we allow batch minting.
            // The ERC fails to describe this case.
            _balances[to] += 1;
        }

        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     * This is an internal function that does not check if the sender is authorized to operate on the token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId, 1);

        // Update ownership in case tokenId was transferred by `_beforeTokenTransfer` hook
        owner = ERC721.ownerOf(tokenId);

        // Clear approvals
        delete _tokenApprovals[tokenId];

        unchecked {
            // Cannot overflow, as that would require more tokens to be burned/transferred
            // out than the owner initially received through minting and transferring in.
            _balances[owner] -= 1;
        }
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId, 1);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId, 1);

        // Check that tokenId was not transferred by `_beforeTokenTransfer` hook
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");

        // Clear approvals from the previous owner
        delete _tokenApprovals[tokenId];

        unchecked {
            // `_balances[from]` cannot overflow for the same reason as described in `_burn`:
            // `from`'s balance is the number of token held, which is at least one before the current
            // transfer.
            // `_balances[to]` could overflow in the conditions described in `_mint`. That would require
            // all 2**256 token ids to be minted, which in practice is impossible.
            _balances[from] -= 1;
            _balances[to] += 1;
        }
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId, 1);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens will be transferred to `to`.
     * - When `from` is zero, the tokens will be minted for `to`.
     * - When `to` is zero, ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s tokens were transferred to `to`.
     * - When `from` is zero, the tokens were minted for `to`.
     * - When `to` is zero, ``from``'s tokens were burned.
     * - `from` and `to` are never both zero.
     * - `batchSize` is non-zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) internal virtual {}

    /**
     * @dev Unsafe write access to the balances, used by extensions that "mint" tokens using an {ownerOf} override.
     *
     * WARNING: Anyone calling this MUST ensure that the balances remain consistent with the ownership. The invariant
     * being that for any address `a` the value returned by `balanceOf(a)` must be equal to the number of tokens such
     * that `ownerOf(tokenId)` is `a`.
     */
    // solhint-disable-next-line func-name-mixedcase
    function __unsafe_increaseBalance(address account, uint256 amount) internal {
        _balances[account] += amount;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SignedMath.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `int256` to its ASCII `string` decimal representation.
     */
    function toString(int256 value) internal pure returns (string memory) {
        return string(abi.encodePacked(value < 0 ? "-" : "", toString(SignedMath.abs(value))));
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }

    /**
     * @dev Returns true if the two strings are equal.
     */
    function equal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(bytes(a)) == keccak256(bytes(b));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                // Solidity will revert if denominator == 0, unlike the div opcode on its own.
                // The surrounding unchecked block does not change this fact.
                // See https://docs.soliditylang.org/en/latest/control-structures.html#checked-or-unchecked-arithmetic.
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(uint256 x, uint256 y, uint256 denominator, Rounding rounding) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10 ** 64) {
                value /= 10 ** 64;
                result += 64;
            }
            if (value >= 10 ** 32) {
                value /= 10 ** 32;
                result += 32;
            }
            if (value >= 10 ** 16) {
                value /= 10 ** 16;
                result += 16;
            }
            if (value >= 10 ** 8) {
                value /= 10 ** 8;
                result += 8;
            }
            if (value >= 10 ** 4) {
                value /= 10 ** 4;
                result += 4;
            }
            if (value >= 10 ** 2) {
                value /= 10 ** 2;
                result += 2;
            }
            if (value >= 10 ** 1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10 ** result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 256, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SignedMath.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard signed math utilities missing in the Solidity language.
 */
library SignedMath {
    /**
     * @dev Returns the largest of two signed numbers.
     */
    function max(int256 a, int256 b) internal pure returns (int256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two signed numbers.
     */
    function min(int256 a, int256 b) internal pure returns (int256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two signed numbers without overflow.
     * The result is rounded towards zero.
     */
    function average(int256 a, int256 b) internal pure returns (int256) {
        // Formula from the book "Hacker's Delight"
        int256 x = (a & b) + ((a ^ b) >> 1);
        return x + (int256(uint256(x) >> 255) & (a ^ b));
    }

    /**
     * @dev Returns the absolute unsigned value of a signed value.
     */
    function abs(int256 n) internal pure returns (uint256) {
        unchecked {
            // must be unchecked in order to support `n = type(int256).min`
            return uint256(n >= 0 ? n : -n);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (interfaces/IERC4906.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";
import "./IERC721.sol";

/// @title EIP-721 Metadata Update Extension
interface IERC4906 is IERC165, IERC721 {
    /// @dev This event emits when the metadata of a token is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFT.
    event MetadataUpdate(uint256 _tokenId);

    /// @dev This event emits when the metadata of a range of tokens is changed.
    /// So that the third-party platforms such as NFT market could
    /// timely update the images and related attributes of the NFTs.
    event BatchMetadataUpdate(uint256 _fromTokenId, uint256 _toTokenId);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "../../../interfaces/IERC4906.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is IERC4906, ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165) returns (bool) {
        return interfaceId == bytes4(0x49064906) || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Emits {MetadataUpdate}.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;

        emit MetadataUpdate(tokenId);
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { Helpers } from "./lib/Helpers.sol";

contract CollectibleToken is ERC721URIStorage, Ownable {
  /// @notice total number of tokens minted
  uint256 public totalMinted;
  /// @notice max supply of tokens allowed
  uint256 public immutable maxSupply;
  /// @notice max tokens allowed per wallet
  uint256 public immutable maxPerUser;
  /// @notice price for minting a token
  uint256 public immutable price;
  /// @notice default uri for token
  string public defaultTokenUri;
  /// @notice start block for minting
  uint40 public immutable startMintBlock;
  /// @notice end block for minting
  uint40 public immutable endMintBlock;
  /// @notice boolean to check if anyone can mint a new token
  bool public immutable publicMint;

  /// @notice raised when public minting is not allowed
  error PublicMintNotAllowed();
  /// @notice raised when not enough funds are sent for fee
  error InvalidFeeAmount(uint256 amount);
  /// @notice raised when the max supply has been reached
  error MaxSupplyReached(uint256 maxSupply);
  /// @notice raised when the max per user has been reached
  error MaxPerUserReached(uint256 maxPerUser);
  /// @notice raised when the sale has not started
  error SaleNotStarted();
  /// @notice raised when the sale has already ended
  error SaleAlreadyEnded();
  /// @notice raised when max per user is greater than max supply during initialization
  error MaxPerUserGtMaxSupply(uint256 maxPerUser, uint256 maxSupply);

  /**
   * @notice modifier which checks if public minting is allowed
   */
  modifier publicMintAllowed(address receiver) {
    if (!publicMint && receiver != owner()) {
      revert PublicMintNotAllowed();
    }
    _;
  }

  /**
   * @notice modifier which checks if the correct amount of is sent as fees for mint
   */
  modifier costs() {
    if (price != 0 && msg.value != price) {
      revert InvalidFeeAmount(msg.value);
    }
    _;
  }

  /**
   * @notice modifier which checks if the max supply has been reached
   */
  modifier limitedByMaxSupply() {
    if (maxSupply != 0 && totalMinted >= maxSupply) {
      revert MaxSupplyReached(maxSupply);
    }
    _;
  }

  /**
   * @notice modifier which checks if the max tokens per wallet has been reached
   * @param receiver - address of the user to check if max tokens per wallet has been reached
   */
  modifier limitedPerUser(address receiver) {
    if (maxPerUser != 0 && balanceOf(receiver) >= maxPerUser) {
      revert MaxPerUserReached(maxPerUser);
    }
    _;
  }

  /**
   * @notice modifier which checks if sale has started and not ended
   */
  modifier saleIsOpen() {
    if (block.timestamp < startMintBlock) {
      revert SaleNotStarted();
    }
    if (endMintBlock != 0 && block.timestamp >= endMintBlock) {
      revert SaleAlreadyEnded();
    }
    _;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxSupply_,
    uint256 maxPerUser_,
    uint256 mintPrice_,
    address payable creatorAddress,
    bool publicMint_,
    uint40 startMintBlock_,
    uint40 endMintBlock_,
    string memory tokenURI_
  ) ERC721(name_, symbol_) {
    if (maxPerUser_ > maxSupply_) {
      revert MaxPerUserGtMaxSupply(maxPerUser_, maxSupply_);
    }

    maxSupply = maxSupply_;
    maxPerUser = maxPerUser_;
    price = mintPrice_;
    publicMint = publicMint_;
    startMintBlock = startMintBlock_;
    endMintBlock = endMintBlock_;
    defaultTokenUri = tokenURI_;

    if (creatorAddress != msg.sender) {
      transferOwnership(creatorAddress);
    }
  }

  /**
   * @notice method which is used for minting NFTs
   * @param receiver - address of the receiver of the NFT
   * @return newItemId - id of the newly minted NFT
   */
  function mint(address receiver)
    external
    payable
    publicMintAllowed(receiver)
    saleIsOpen
    costs
    limitedByMaxSupply
    limitedPerUser(receiver)
    returns (uint256)
  {
    uint256 newItemId = totalMinted;
    unchecked {
      ++totalMinted;
    }
    Helpers.safeTransferETH(owner(), msg.value);
    _safeMint(receiver, newItemId);
    _setTokenURI(newItemId, defaultTokenUri);
    return newItemId;
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 *
 * IMPORTANT: This contract does not include public pause and unpause functions. In
 * addition to inheriting this contract, you must define both functions, invoking the
 * {Pausable-_pause} and {Pausable-_unpause} internal functions, with appropriate
 * access control, e.g. using {AccessControl} or {Ownable}. Not doing so will
 * make the contract unpausable.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * The default value of {decimals} is 18. To change this, you should override
 * this function so it returns a different value.
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the default value returned by this function, unless
     * it's overridden.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(address from, address to, uint256 amount) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import { Helpers } from "./lib/Helpers.sol";

contract FullFeatureToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
  uint256 private constant MAX_BPS_AMOUNT = 10_000;
  /// @notice mapping of blacklisted addresses to a boolean
  mapping(address => bool) private _isBlacklisted;
  /// @notice mapping of whitelisted addresses to a boolean
  mapping(address => bool) public whitelist;
  /// @notice array holding all whitelisted addresses
  address[] public whitelistedAddresses;
  /// @notice support for attaching of documentation for security tokens
  string public initialDocumentUri;
  /// @notice the security token documentation
  string public documentUri;
  /// @notice initial number of tokens which will be minted during initialization
  uint256 public immutable initialSupply;
  /// @notice initial max amount of tokens allowed per wallet
  uint256 public immutable initialMaxTokenAmountPerAddress;
  /// @notice max amount of tokens allowed per wallet
  uint256 public maxTokenAmountPerAddress;
  /// @notice set of features supported by the token
  struct ERC20ConfigProps {
    bool _isMintable;
    bool _isBurnable;
    bool _isPausable;
    bool _isBlacklistEnabled;
    bool _isDocumentAllowed;
    bool _isWhitelistEnabled;
    bool _isMaxAmountOfTokensSet;
    bool _isForceTransferAllowed;
    bool _isTaxable;
    bool _isDeflationary;
  }
  /// @notice features of the token
  ERC20ConfigProps private configProps;
  /// @notice owner of the contract
  address public immutable initialTokenOwner;
  /// @notice number of decimals of the token
  uint8 private _decimals;
  address public taxAddress;
  uint256 public taxBPS;
  uint256 public deflationBPS;

  /// @notice emitted when an address is blacklisted
  event UserBlacklisted(address indexed addr);
  /// @notice emitted when an address is unblacklisted
  event UserUnBlacklisted(address indexed addr);
  /// @notice emitted when a new document is set for the security token
  event DocumentUriSet(string newDocUri);
  /// @notice emitted when a new max amount of tokens per wallet is set
  event MaxTokenAmountPerSet(uint256 newMaxTokenAmount);
  /// @notice emitted when a new whitelist is set
  event UsersWhitelisted(address[] updatedAddresses);
  /// @notice emitted when a new tax address or taxBPS is set
  event TaxConfigSet(address indexed _taxAddress, uint256 indexed _taxBPS);
  /// @notice emitted when a new deflationBPS is set
  event DeflationConfigSet(uint256 indexed _deflationBPS);

  /// @notice raised when the amount sent is zero
  error InvalidMaxTokenAmount(uint256 maxTokenAmount);
  /// @notice raised when the decimals are not in the range 0 - 18
  error InvalidDecimals(uint8 decimals);
  /// @notice raised when setting maxTokenAmount less than current
  error MaxTokenAmountPerAddrLtPrevious();
  /// @notice raised when blacklisting is not enabled
  error BlacklistNotEnabled();
  /// @notice raised when the address is already blacklisted
  error AddrAlreadyBlacklisted(address addr);
  /// @notice raised when the address is already unblacklisted
  error AddrAlreadyUnblacklisted(address addr);
  /// @notice raised when attempting to blacklist a whitelisted address
  error CannotBlacklistWhitelistedAddr(address addr);
  /// @notice raised when a recipient address is blacklisted
  error RecipientBlacklisted(address addr);
  /// @notice raised when a sender address is blacklisted
  error SenderBlacklisted(address addr);
  /// @notice raised when a recipient address is not whitelisted
  error RecipientNotWhitelisted(address addr);
  /// @notice raised when a sender address is not whitelisted
  error SenderNotWhitelisted(address addr);
  /// @notice raised when recipient balance exceeds maxTokenAmountPerAddress
  error DestBalanceExceedsMaxAllowed(address addr);
  /// @notice raised minting is not enabled
  error MintingNotEnabled();
  /// @notice raised when burning is not enabled
  error BurningNotEnabled();
  /// @notice raised when pause is not enabled
  error PausingNotEnabled();
  /// @notice raised when whitelist is not enabled
  error WhitelistNotEnabled();
  /// @notice raised when attempting to whitelist a blacklisted address
  error CannotWhitelistBlacklistedAddr(address addr);
  /// @notice raised when trying to set a document URI when not allowed
  error DocumentUriNotAllowed();
  /// @notice raised when trying to set a max amount of tokens when not allowed
  error MaxTokenAmountNotAllowed();
  /// @notice raised when trying to set a tax address or taxBPS when not allowed
  error TokenIsNotTaxable();
  /// @notice raised when trying to set a deflationBPS when not allowed
  error TokenIsNotDeflationary();
  /// @notice raised when trying to set an invalid taxBPS
  error InvalidTaxBPS(uint256 bps);
  /// @notice raised when trying to set and invalid deflationBPS
  error InvalidDeflationBPS(uint256 bps);

  /**
   * @notice modifier for validating if transfer is possible and valid
   * @param sender the sender of the transaction
   * @param recipient the recipient of the transaction
   */
  modifier validateTransfer(address sender, address recipient) {
    if (isWhitelistEnabled()) {
      if (!whitelist[sender]) {
        revert SenderNotWhitelisted(sender);
      }
      if (!whitelist[recipient]) {
        revert RecipientNotWhitelisted(recipient);
      }
      if (
        sender != msg.sender && msg.sender != owner() && !whitelist[msg.sender]
      ) {
        revert SenderNotWhitelisted(msg.sender);
      }
    }
    if (isBlacklistEnabled()) {
      if (_isBlacklisted[sender]) {
        revert SenderBlacklisted(sender);
      }
      if (_isBlacklisted[recipient]) {
        revert RecipientBlacklisted(recipient);
      }
      if (
        sender != msg.sender &&
        msg.sender != owner() &&
        _isBlacklisted[msg.sender]
      ) {
        revert SenderBlacklisted(msg.sender);
      }
    }
    _;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 initialSupplyToSet,
    uint8 decimalsToSet,
    address tokenOwner,
    ERC20ConfigProps memory customConfigProps,
    uint256 maxTokenAmount,
    string memory newDocumentUri,
    address _taxAddress,
    uint256 _taxBPS,
    uint256 _deflationBPS
  ) ERC20(name_, symbol_) {
    if (customConfigProps._isMaxAmountOfTokensSet) {
      if (maxTokenAmount == 0) {
        revert InvalidMaxTokenAmount(maxTokenAmount);
      }
    }
    if (decimalsToSet > 18) {
      revert InvalidDecimals(decimalsToSet);
    }
    if (customConfigProps._isTaxable) {
      if (_taxBPS > MAX_BPS_AMOUNT) {
        revert InvalidTaxBPS(_taxBPS);
      }
      Helpers.validateAddress(_taxAddress);
      taxAddress = _taxAddress;
      taxBPS = _taxBPS;
    }
    if (customConfigProps._isDeflationary) {
      if (_deflationBPS > MAX_BPS_AMOUNT) {
        revert InvalidDeflationBPS(_deflationBPS);
      }
      deflationBPS = _deflationBPS;
    }
    Helpers.validateAddress(tokenOwner);

    initialSupply = initialSupplyToSet;
    initialMaxTokenAmountPerAddress = maxTokenAmount;
    initialDocumentUri = newDocumentUri;
    initialTokenOwner = tokenOwner;
    _decimals = decimalsToSet;
    configProps = customConfigProps;
    documentUri = newDocumentUri;
    maxTokenAmountPerAddress = maxTokenAmount;

    if (initialSupplyToSet != 0) {
      _mint(tokenOwner, initialSupplyToSet * 10**decimalsToSet);
    }

    if (tokenOwner != msg.sender) {
      transferOwnership(tokenOwner);
    }
  }

  /**
   * @notice hook called before any transfer of tokens. This includes minting and burning
   * imposed by the ERC20 standard
   * @param from - address of the sender
   * @param to - address of the recipient
   * @param amount - amount of tokens to transfer
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }

  /// @notice method which checks if the token is pausable
  function isPausable() public view returns (bool) {
    return configProps._isPausable;
  }

  /// @notice method which checks if the token is mintable
  function isMintable() public view returns (bool) {
    return configProps._isMintable;
  }

  /// @notice method which checks if the token is burnable
  function isBurnable() public view returns (bool) {
    return configProps._isBurnable;
  }

  /// @notice method which checks if the token supports blacklisting
  function isBlacklistEnabled() public view returns (bool) {
    return configProps._isBlacklistEnabled;
  }

  /// @notice method which checks if the token supports whitelisting
  function isWhitelistEnabled() public view returns (bool) {
    return configProps._isWhitelistEnabled;
  }

  /// @notice method which checks if the token supports max amount of tokens per wallet
  function isMaxAmountOfTokensSet() public view returns (bool) {
    return configProps._isMaxAmountOfTokensSet;
  }

  /// @notice method which checks if the token supports documentUris
  function isDocumentUriAllowed() public view returns (bool) {
    return configProps._isDocumentAllowed;
  }

  /// @notice method which checks if the token supports force transfers
  function isForceTransferAllowed() public view returns (bool) {
    return configProps._isForceTransferAllowed;
  }

  /// @notice method which returns the number of decimals for the token
  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  /// @notice method which checks if the token is taxable
  function isTaxable() public view returns (bool) {
    return configProps._isTaxable;
  }

  /// @notice method which checks if the token is deflationary
  function isDeflationary() public view returns (bool) {
    return configProps._isDeflationary;
  }

  /**
   * @notice which returns an array of all the whitelisted addresses
   * @return whitelistedAddresses array of all the whitelisted addresses
   */
  function getWhitelistedAddresses() external view returns (address[] memory) {
    return whitelistedAddresses;
  }

  /**
   * @notice method which allows the owner to set a documentUri
   * @param newDocumentUri - the new documentUri
   * @dev only callable by the owner
   */
  function setDocumentUri(string memory newDocumentUri)
    external
    onlyOwner
    whenNotPaused
  {
    if (!isDocumentUriAllowed()) {
      revert DocumentUriNotAllowed();
    }
    documentUri = newDocumentUri;
    emit DocumentUriSet(newDocumentUri);
  }

  /**
   * @notice method which allows the owner to set a max amount of tokens per wallet
   * @param newMaxTokenAmount - the new max amount of tokens per wallet
   * @dev only callable by the owner
   */
  function setMaxTokenAmountPerAddress(uint256 newMaxTokenAmount)
    external
    onlyOwner
    whenNotPaused
  {
    if (!isMaxAmountOfTokensSet()) {
      revert MaxTokenAmountNotAllowed();
    }
    if (newMaxTokenAmount <= maxTokenAmountPerAddress) {
      revert MaxTokenAmountPerAddrLtPrevious();
    }

    maxTokenAmountPerAddress = newMaxTokenAmount;
    emit MaxTokenAmountPerSet(newMaxTokenAmount);
  }

  /**
   * @notice method which allows the owner to blacklist an address
   * @param addr - the address to blacklist
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   * @dev only callable if the token supports blacklisting
   * @dev only callable if the address is not already blacklisted
   * @dev only callable if the address is not whitelisted
   */
  function blackList(address addr) external onlyOwner whenNotPaused {
    Helpers.validateAddress(addr);
    if (!isBlacklistEnabled()) {
      revert BlacklistNotEnabled();
    }
    if (_isBlacklisted[addr]) {
      revert AddrAlreadyBlacklisted(addr);
    }
    if (isWhitelistEnabled() && whitelist[addr]) {
      revert CannotBlacklistWhitelistedAddr(addr);
    }

    _isBlacklisted[addr] = true;
    emit UserBlacklisted(addr);
  }

  /**
   * @notice method which allows the owner to unblacklist an address
   * @param addr - the address to unblacklist
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   * @dev only callable if the token supports blacklisting
   * @dev only callable if the address is blacklisted
   */
  function removeFromBlacklist(address addr) external onlyOwner whenNotPaused {
    Helpers.validateAddress(addr);
    if (!isBlacklistEnabled()) {
      revert BlacklistNotEnabled();
    }
    if (!_isBlacklisted[addr]) {
      revert AddrAlreadyUnblacklisted(addr);
    }
    delete _isBlacklisted[addr];
    emit UserUnBlacklisted(addr);
  }

  /**
   * @notice method which allows the owner to set the tax config
   * @param _taxAddress - the new taxAddress
   * @param _taxBPS - the new taxBPS
   */
  function setTaxConfig(address _taxAddress, uint256 _taxBPS)
    external
    onlyOwner
    whenNotPaused
  {
    if (!isTaxable()) {
      revert TokenIsNotTaxable();
    }
    if (_taxBPS > MAX_BPS_AMOUNT) {
      revert InvalidTaxBPS(_taxBPS);
    }
    Helpers.validateAddress(_taxAddress);
    taxAddress = _taxAddress;
    taxBPS = _taxBPS;
    emit TaxConfigSet(_taxAddress, _taxBPS);
  }

  /**
   * @notice method which allows the owner to set the deflation config
   * @param _deflationBPS - the new deflationBPS
   */
  function setDeflationConfig(uint256 _deflationBPS)
    external
    onlyOwner
    whenNotPaused
  {
    if (!isDeflationary()) {
      revert TokenIsNotDeflationary();
    }
    if (_deflationBPS > MAX_BPS_AMOUNT) {
      revert InvalidDeflationBPS(_deflationBPS);
    }
    deflationBPS = _deflationBPS;
    emit DeflationConfigSet(_deflationBPS);
  }

  /**
   * @notice method which allows to transfer a predefined amount of tokens to a predefined address
   * @param to - the address to transfer the tokens to
   * @param amount - the amount of tokens to transfer
   * @return true if the transfer was successful
   * @dev only callable if the token is not paused
   * @dev only callable if the balance of the receiver is lower than the max amount of tokens per wallet
   * @dev checks if blacklisting is enabled and if the sender and receiver are not blacklisted
   * @dev checks if whitelisting is enabled and if the sender and receiver are whitelisted
   * @dev captures the tax during the transfer if tax is enabvled
   * @dev burns the deflationary amount during the transfer if deflation is enabled
   */
  function transfer(address to, uint256 amount)
    public
    virtual
    override
    whenNotPaused
    validateTransfer(msg.sender, to)
    returns (bool)
  {
    uint256 taxAmount = _taxAmount(msg.sender, amount);
    uint256 deflationAmount = _deflationAmount(amount);
    uint256 amountToTransfer = amount - taxAmount - deflationAmount;

    if (isMaxAmountOfTokensSet()) {
      if (balanceOf(to) + amountToTransfer > maxTokenAmountPerAddress) {
        revert DestBalanceExceedsMaxAllowed(to);
      }
    }

    if (taxAmount != 0) {
      _transfer(msg.sender, taxAddress, taxAmount);
    }
    if (deflationAmount != 0) {
      _burn(msg.sender, deflationAmount);
    }
    return super.transfer(to, amountToTransfer);
  }

  /**
   * @notice method which allows to transfer a predefined amount of tokens from a predefined address to a predefined address
   * @param from - the address to transfer the tokens from
   * @param to - the address to transfer the tokens to
   * @param amount - the amount of tokens to transfer
   * @return true if the transfer was successful
   * @dev only callable if the token is not paused
   * @dev only callable if the balance of the receiver is lower than the max amount of tokens per wallet
   * @dev checks if blacklisting is enabled and if the sender and receiver are not blacklisted
   * @dev checks if whitelisting is enabled and if the sender and receiver are whitelisted
   * @dev captures the tax during the transfer if tax is enabvled
   * @dev burns the deflationary amount during the transfer if deflation is enabled
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  )
    public
    virtual
    override
    whenNotPaused
    validateTransfer(from, to)
    returns (bool)
  {
    uint256 taxAmount = _taxAmount(from, amount);
    uint256 deflationAmount = _deflationAmount(amount);
    uint256 amountToTransfer = amount - taxAmount - deflationAmount;

    if (isMaxAmountOfTokensSet()) {
      if (balanceOf(to) + amountToTransfer > maxTokenAmountPerAddress) {
        revert DestBalanceExceedsMaxAllowed(to);
      }
    }

    if (taxAmount != 0) {
      _transfer(from, taxAddress, taxAmount);
    }
    if (deflationAmount != 0) {
      _burn(from, deflationAmount);
    }

    if (isForceTransferAllowed() && owner() == msg.sender) {
      _transfer(from, to, amountToTransfer);
      return true;
    } else {
      return super.transferFrom(from, to, amountToTransfer);
    }
  }

  /**
   * @notice method which allows to mint a predefined amount of tokens to a predefined address
   * @param to - the address to mint the tokens to
   * @param amount - the amount of tokens to mint
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   * @dev only callable if the token supports additional minting
   * @dev only callable if the balance of the receiver is lower than the max amount of tokens per wallet
   * @dev checks if blacklisting is enabled and if the receiver is not blacklisted
   * @dev checks if whitelisting is enabled and if the receiver is whitelisted
   */
  function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
    if (!isMintable()) {
      revert MintingNotEnabled();
    }
    if (isMaxAmountOfTokensSet()) {
      if (balanceOf(to) + amount > maxTokenAmountPerAddress) {
        revert DestBalanceExceedsMaxAllowed(to);
      }
    }
    if (isBlacklistEnabled()) {
      if (_isBlacklisted[to]) {
        revert RecipientBlacklisted(to);
      }
    }
    if (isWhitelistEnabled()) {
      if (!whitelist[to]) {
        revert RecipientNotWhitelisted(to);
      }
    }

    super._mint(to, amount);
  }

  /**
   * @notice method which allows to burn a predefined amount of tokens
   * @param amount - the amount of tokens to burn
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   * @dev only callable if the token supports burning
   */
  function burn(uint256 amount) public override onlyOwner whenNotPaused {
    if (!isBurnable()) {
      revert BurningNotEnabled();
    }
    super.burn(amount);
  }

  /**
   * @notice method which allows to burn a predefined amount of tokens from a predefined address
   * @param from - the address to burn the tokens from
   * @param amount - the amount of tokens to burn
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   * @dev only callable if the token supports burning
   */
  function burnFrom(address from, uint256 amount)
    public
    override
    onlyOwner
    whenNotPaused
  {
    if (!isBurnable()) {
      revert BurningNotEnabled();
    }
    super.burnFrom(from, amount);
  }

  /**
   * @notice method which allows to pause the token
   * @dev only callable by the owner
   */
  function pause() external onlyOwner {
    if (!isPausable()) {
      revert PausingNotEnabled();
    }
    _pause();
  }

  /**
   * @notice method which allows to unpause the token
   * @dev only callable by the owner
   */
  function unpause() external onlyOwner {
    if (!isPausable()) {
      revert PausingNotEnabled();
    }
    _unpause();
  }

  /**
   * @notice method which allows to removing the owner of the token
   * @dev methods which are only callable by the owner will not be callable anymore
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   */
  function renounceOwnership() public override onlyOwner whenNotPaused {
    super.renounceOwnership();
  }

  /**
   * @notice method which allows to transfer the ownership of the token
   * @param newOwner - the address of the new owner
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   */
  function transferOwnership(address newOwner)
    public
    override
    onlyOwner
    whenNotPaused
  {
    super.transferOwnership(newOwner);
  }

  /**
   * @notice method which allows to update the whitelist of the token
   * @param updatedAddresses - the new set of addresses
   * @dev only callable by the owner
   * @dev only callable if the token supports whitelisting
   */
  function updateWhitelist(address[] calldata updatedAddresses)
    external
    onlyOwner
    whenNotPaused
  {
    if (!isWhitelistEnabled()) {
      revert WhitelistNotEnabled();
    }
    _clearWhitelist();
    _addManyToWhitelist(updatedAddresses);
    whitelistedAddresses = updatedAddresses;
    emit UsersWhitelisted(updatedAddresses);
  }

  /**
   * @notice method which allows for adding a new set of addresses to the whitelist
   * @param addresses - the addresses to add to the whitelist
   * @dev called internally by the contract
   * @dev only callable if any of the addresses are not already whitelisted
   */
  function _addManyToWhitelist(address[] calldata addresses) private {
    for (uint256 i; i < addresses.length; ) {
      Helpers.validateAddress(addresses[i]);
      if (configProps._isBlacklistEnabled && _isBlacklisted[addresses[i]]) {
        revert CannotWhitelistBlacklistedAddr(addresses[i]);
      }
      whitelist[addresses[i]] = true;
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice method which allows for removing a set of addresses from the whitelist
   */
  function _clearWhitelist() private {
    unchecked {
      address[] memory addresses = whitelistedAddresses;
      for (uint256 i; i < addresses.length; i++) {
        delete whitelist[addresses[i]];
      }
    }
  }

  /**
   * @notice method which returns the amount of tokens to be taxed during a transfer
   * @param sender - the address of the originating account
   * @param amount - the total amount of tokens sent in the transfer
   * @dev if the tax address is the same as the originating account performing the transfer, no tax is applied
   */
  function _taxAmount(address sender, uint256 amount)
    internal
    view
    returns (uint256 taxAmount)
  {
    taxAmount = 0;
    if (taxBPS != 0 && sender != taxAddress) {
      taxAmount = (amount * taxBPS) / MAX_BPS_AMOUNT;
    }
  }

  /**
   * @notice method which returns the amount of tokens to be burned during a transfer
   * @param amount - the total amount of tokens sent in the transfer
   */
  function _deflationAmount(uint256 amount)
    internal
    view
    returns (uint256 deflationAmount)
  {
    deflationAmount = 0;
    if (deflationBPS != 0) {
      deflationAmount = (amount * deflationBPS) / MAX_BPS_AMOUNT;
    }
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC20Metadata } from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import { Helpers } from "./lib/Helpers.sol";

contract TokenSaleManager is Ownable {
  using SafeERC20 for IERC20;

  /// @notice mapping of whitelisted addresses to a boolean
  mapping(address => bool) public whitelist;
  /// @notice array holding all whitelisted addresses
  address[] public whitelistedAddresses;
  /// @notice mapping of addresses to their total contributions to the sale
  mapping(address => uint256) public contributions;
  /// @notice mapping of addresses to their amount of tokens to claim
  mapping(address => uint256) public tokensToClaim;
  /// @notice total amount of tokens left for sale
  uint256 public totalTokensLeft;
  /// @notice total amount of contributions
  uint256 public totalContribution;
  /// @notice required config for the sale
  /// @dev add new config variables to the end of the struct
  /// instead of in the middle to avoid breaking the storage layout
  /// for existing contracts
  struct TokenSale {
    address tokenContract; /// token contract address
    address saleCurrency; /// send 0x0 when WETH needs to be used
    uint256 pricePerToken; /// price per 1 token in wei currency
    uint256 totalCap; /// total cap of gathered funds in ETH wei / ERC20 wei
    address owner; /// owner of the sale  address
    uint40 startTime; /// start time of the sale
    uint40 endTime; /// end time of the sale
    uint40 lockTime; /// equals to endTime if no lock is set after sale
    uint256 softCap; /// softcap in ERC20wei / ETHwei
    uint256 minInvestment; /// 0 if no min
    uint256 maxInvestment; /// 0 if no max
    bool whitelistEnabled; /// if true, only whitelisted addresses can participate
  }
  /// @notice set of features supported by the sale
  TokenSale public tokenSale;
  /// @notice address of the fee receiver (Bitbond wallet)
  address private constant FEE_RECEIVER =
    0x9254C0fcB2FaA4550B9ba582558cE1D03Ba3d05d;

  /// @notice event emitted when a new sale is created
  event TokenSaleCreated(
    address indexed tokenContract,
    address indexed ownerAddress,
    uint256 pricePerToken
  );

  /// @notice event emitted when whitelist is updated
  event WhitelistUpdated(address[] indexed updatedAddresses);
  /// @notice event emitted when sale details are updated
  event SaleDetailsUpdated(TokenSale updatedSaleDetails);
  /// @notice event emitted when tokens are deposited
  event TokensDeposited(uint256 amount);
  /// @notice event emitted when tokens are bought
  event TokensBought(uint256 amount);
  /// @notice event emitted when tokens are claimed
  event TokensClaimed(uint256 amount);
  /// @notice event emitted when refund is claimed
  event RefundsClaimed(uint256 amount);
  /// @notice event emitted when funds are withdrawn
  event FundsWithdrawn(uint256 amount);
  /// @notice event emitted whenn tokens are withdrawn
  event TokensWithdrawn(uint256 amount);

  /// @notice raised when some sale details are not valid
  error InvalidTokenSaleDetails(TokenSale saleDetails);
  /// @notice raised when the sale softcap is larger than the total cap
  error SoftcapGtTotalCap();
  /// @notice raised when whitelisting is not enabled
  error WhitelistNotEnabled();
  /// @notice raised when sale already contains the tokens for the sale
  error TokensAlreadyDeposited();
  /// @notice raised when not enough tokens deposited for the sale
  error RequiredTokenAmount(uint256 amount);
  /// @notice raised when not enough tokens left for sale
  error NotEnoughTokensLeft(uint256 amount);
  /// @notice raised when not enough tokens are deposited for the sale to be valid
  error TokensNotDeposited();
  /// @notice raised when sale has not started yet
  error SaleNotStarted();
  /// @notice raised when address is not whitelisted
  error NotWhitelisted(address addr);
  /// @notice raised when contribution exceeds totalCap
  error ContributionExceedsMax(uint256 contribution, uint256 totalCap);
  /// @notice raised when contribution is below minInvestment
  error MinPerUserNotReached(uint256 minPerUser);
  /// @notice raised when contribution is above maxInvestment
  error MaxPerUserReached(address addr, uint256 maxPerUser);
  /// @notice raised when insufficient funds are sent
  error InvalidTransferAmount(uint256 amount);
  /// @notice raised when sale softcap is not reached
  error SoftcapNotReached(uint256 softcap);
  /// @notice raised when trying to withdraw / claim tokens before softcap has been reached
  error SoftcapReached();
  /// @notice raised when trying to claim tokens before sale has ended
  error SaleNotEnded();
  /// @notice raised when trying to claim locked tokens
  error TokensStillLocked();
  /// @notice raised when trying to update a sale that has already started
  error SaleAlreadyStarted();
  /// @notice raised when trying to claim tokens but there are no tokens to claim
  error NoTokensToClaim();
  /// @notice raised when trying trying to claim more tokens than eligible
  error CannotClaimMoreThanEligible(uint256 amount);
  /// @notice raised when there are not refunds to claim
  error NoRefundsToClaim();
  /// @notice raised whn there are no funds to withdraw`
  error NoFundsToWithdraw();

  /**
   * @notice modifier which checks if the sale softcap has been reached
   */
  modifier softcapReached() {
    if (totalContribution < tokenSale.softCap) {
      revert SoftcapNotReached(tokenSale.softCap);
    }
    _;
  }

  /**
   * @notice modifier which checks if the sale softcap has not been reached
   */
  modifier softcapNotReached() {
    if (totalContribution >= tokenSale.softCap) {
      revert SoftcapReached();
    }
    _;
  }

  /**
   * @notice modifier which checks if the sale has finished and lockTime has passed
   */
  modifier lockEnded() {
    if (
      tokenSale.lockTime > tokenSale.endTime &&
      block.timestamp <= tokenSale.lockTime
    ) {
      revert TokensStillLocked();
    }
    _;
  }

  /**
   * @notice modifier which checks if the sale has finished
   */
  modifier saleEnded() {
    if (
      totalContribution < tokenSale.totalCap &&
      block.timestamp <= tokenSale.endTime
    ) {
      revert SaleNotEnded();
    }
    _;
  }

  /**
   * @notice modifier which checks if the sale contains the required number of tokens
   * for the sale to be valid
   */
  modifier tokensExist() {
    if (
      IERC20(tokenSale.tokenContract).balanceOf(address(this)) <
      requiredAmountOfTokensForSale()
    ) {
      revert TokensNotDeposited();
    }
    _;
  }

  /**
   * @notice modifier which checks if the contribution is in the allowed time range
   */
  modifier saleIsOpen() {
    if (
      block.timestamp < tokenSale.startTime ||
      block.timestamp > tokenSale.endTime
    ) {
      revert SaleNotStarted();
    }
    _;
  }

  /**
   * @notice modifier which checks if the sale details can still be changed
   * 10 minutes before the sale starts at the latest
   */
  modifier isSaleUpdatable() {
    uint40 startTime = tokenSale.startTime;
    if (
      startTime <= block.timestamp || startTime - block.timestamp <= 10 minutes
    ) {
      revert SaleAlreadyStarted();
    }
    _;
  }

  constructor(TokenSale memory newTokenSale) payable {
    if (
      newTokenSale.pricePerToken == 0 ||
      newTokenSale.totalCap == 0 ||
      newTokenSale.startTime == 0 ||
      newTokenSale.endTime == 0 ||
      newTokenSale.lockTime == 0 ||
      newTokenSale.owner == address(0x0) ||
      newTokenSale.tokenContract == address(0x0)
    ) {
      revert InvalidTokenSaleDetails(newTokenSale);
    }
    if (newTokenSale.softCap > newTokenSale.totalCap) {
      revert SoftcapGtTotalCap();
    }
    Helpers.validateAddress(newTokenSale.tokenContract);
    Helpers.validateAddress(newTokenSale.owner);

    tokenSale = newTokenSale;

    if (newTokenSale.owner != msg.sender) {
      transferOwnership(newTokenSale.owner);
    }

    emit TokenSaleCreated(
      newTokenSale.tokenContract,
      newTokenSale.owner,
      newTokenSale.pricePerToken
    );
  }

  /**
   * @notice method for updating the whitelist
   * @param updatedAddresses array of addresses to add to the whitelist
   * @dev only callable by owner
   */
  function updateWhitelist(address[] calldata updatedAddresses)
    external
    payable
    onlyOwner
  {
    if (!tokenSale.whitelistEnabled) {
      revert WhitelistNotEnabled();
    }
    Helpers.safeTransferETH(FEE_RECEIVER, msg.value);
    _clearWhitelist();
    _addManyToWhitelist(updatedAddresses);
    whitelistedAddresses = updatedAddresses;
    emit WhitelistUpdated(updatedAddresses);
  }

  /**
   * @notice method for retrieving the whitelisted addresses
   */
  function getWhitelistedAddresses() external view returns (address[] memory) {
    return whitelistedAddresses;
  }

  /**
   * @notice method for updating the token sale details
   * @param updatedTokenSale new token sale details
   * @dev only callable by owner
   * @dev only callable if token sale is still updatable
   */
  function updateSaleDetails(TokenSale calldata updatedTokenSale)
    external
    payable
    onlyOwner
    isSaleUpdatable
  {
    if (totalTokensLeft != 0) {
      revert TokensAlreadyDeposited();
    }
    tokenSale = updatedTokenSale;
    Helpers.safeTransferETH(FEE_RECEIVER, msg.value);
    emit SaleDetailsUpdated(updatedTokenSale);
  }

  /**
   * @notice Method for depositing tokens for sale
   * You need to give allowance to this contract so
   * it may receive your tokens.
   * It is required to deposit tokens for sale and without them
   * token sale won't start.
   * Preferable way of depositing tokens to contract is by this method.
   * @param amountToken Token amount
   */
  function depositTokens(uint256 amountToken) external onlyOwner {
    if (totalTokensLeft != 0) {
      revert TokensAlreadyDeposited();
    }
    if (amountToken != requiredAmountOfTokensForSale()) {
      revert RequiredTokenAmount(requiredAmountOfTokensForSale());
    }
    totalTokensLeft = amountToken;
    IERC20(tokenSale.tokenContract).safeTransferFrom(
      msg.sender,
      address(this),
      amountToken
    );

    emit TokensDeposited(amountToken);
  }

  /**
   * @notice Calculate amount for tokens required for sale
   */
  function requiredAmountOfTokensForSale() public view returns (uint256) {
    return _getTokenAmount(tokenSale.totalCap);
  }

  /**
   * @notice Method for buying tokens from sale
   * Possible to invoke only after sale has started and tokens
   * has been deposited successfuly.
   * @param contribution Amount of tokenContract in WEI
   * @param feeAmount Amount of fee in WEI
   */
  function buy(uint256 contribution, uint256 feeAmount)
    external
    payable
    tokensExist
    saleIsOpen
  {
    Helpers.safeTransferETH(FEE_RECEIVER, feeAmount);
    _validatePurchase(contribution);

    uint256 tokensBeingBought = _getTokenAmount(contribution);
    if (tokensBeingBought > totalTokensLeft) {
      revert NotEnoughTokensLeft(totalTokensLeft);
    }
    contributions[msg.sender] += contribution;
    tokensToClaim[msg.sender] += tokensBeingBought;
    totalContribution += contribution;
    totalTokensLeft -= tokensBeingBought;

    _handleIncomingPayment(contribution, msg.value - feeAmount);

    emit TokensBought(contribution);
  }

  /**
   * @notice Method for claiming tokens from sale
   * Possible to invoke only when softcap has been reached, lock is finished
   * and user has participed in the sale.
   */
  function claim(uint256 amount) external saleEnded lockEnded softcapReached {
    uint256 amountOfTokensToClaim = tokensToClaim[msg.sender];
    if (amountOfTokensToClaim == 0) {
      revert NoTokensToClaim();
    }
    if (amountOfTokensToClaim < amount) {
      revert CannotClaimMoreThanEligible(amountOfTokensToClaim);
    }
    tokensToClaim[msg.sender] -= amount;
    IERC20(tokenSale.tokenContract).safeTransfer(msg.sender, amount);
    emit TokensClaimed(amount);
  }

  /**
   * @notice Investors can claim refunds here if crowdsale is unsuccessful
   * and has finished. Tokens being refund are based on the sale currency.
   */
  function claimRefund() external saleEnded softcapNotReached {
    uint256 contribution = contributions[msg.sender];
    if (contribution == 0) {
      revert NoRefundsToClaim();
    }
    contributions[msg.sender] = 0;
    tokensToClaim[msg.sender] = 0;

    if (tokenSale.saleCurrency == address(0)) {
      Helpers.safeTransferETH(msg.sender, contribution);
    } else {
      IERC20(tokenSale.saleCurrency).safeTransfer(msg.sender, contribution);
    }

    emit RefundsClaimed(contribution);
  }

  /**
   * @notice Method for withdrawing funds from sale by owner if crowdsale is successful
   * and finished.
   * Type of the withdrawn funds are based on the sale currency.
   */
  function withdrawFunds() external saleEnded softcapReached onlyOwner {
    uint256 amount = address(this).balance;
    if (tokenSale.saleCurrency == address(0)) {
      if (amount == 0) {
        revert NoFundsToWithdraw();
      }
      Helpers.safeTransferETH(tokenSale.owner, amount);
    } else {
      IERC20 currency = IERC20(tokenSale.saleCurrency);
      if (currency.balanceOf(address(this)) == 0) {
        revert NoFundsToWithdraw();
      }
      currency.safeTransfer(msg.sender, currency.balanceOf(address(this)));
    }

    emit FundsWithdrawn(amount);
  }

  /**
   * @notice Method for withdrawing tokens from sale by owner if crowdsale is successful
   * and finished.
   * If softcap has been reached, we use "totaltokensLeft" as amount of tokens free to withdraw
   * because rest of the tokens is reserved for investors to claim.
   * If softcap has not been reached, owner is eligible to withdraw all the tokens deposited
   * previously to the contract.
   */
  function withdrawTokens() external saleEnded onlyOwner {
    uint256 tokensLeft = totalTokensLeft;
    totalTokensLeft = 0;

    if (totalContribution >= tokenSale.softCap) {
      IERC20(tokenSale.tokenContract).safeTransfer(msg.sender, tokensLeft);
    } else {
      IERC20(tokenSale.tokenContract).safeTransfer(
        msg.sender,
        requiredAmountOfTokensForSale()
      );
    }

    emit TokensWithdrawn(tokensLeft);
  }

  /**
   * @notice method for retrieving the amount of tokens available to withdraw
   */
  function fundsToWithdraw()
    external
    view
    saleEnded
    softcapReached
    onlyOwner
    returns (uint256)
  {
    if (tokenSale.saleCurrency == address(0)) {
      return address(this).balance;
    }
    return IERC20(tokenSale.saleCurrency).balanceOf(address(this));
  }

  /**
   * @notice method for validating if purchase is possible and valid
   * @param contribution contribution amount
   */
  function _validatePurchase(uint256 contribution) private view {
    if (tokenSale.whitelistEnabled && !whitelist[msg.sender]) {
      revert NotWhitelisted(msg.sender);
    }
    uint256 totalCap = tokenSale.totalCap;
    if (totalContribution + contribution > totalCap) {
      revert ContributionExceedsMax(contribution, totalCap);
    }
    uint256 minInvestment = tokenSale.minInvestment;
    if (minInvestment != 0 && contribution < minInvestment) {
      revert MinPerUserNotReached(minInvestment);
    }
    uint256 maxInvestment = tokenSale.maxInvestment;
    if (
      maxInvestment != 0 &&
      contribution + contributions[msg.sender] > maxInvestment
    ) {
      revert MaxPerUserReached(msg.sender, maxInvestment);
    }
  }

  /**
   * @notice method for getting token amount by multiplying funds in wei by token decimals
   * and dividing result by price per token in wei
   * @param fundsInWei Funds in wei
   */
  function _getTokenAmount(uint256 fundsInWei) private view returns (uint256) {
    return
      (fundsInWei * 10**IERC20Metadata(tokenSale.tokenContract).decimals()) /
      tokenSale.pricePerToken;
  }

  /**
   * @notice method which for given amount and a currency, transfer the amount to this contract.
   * If the currency is (0x0) handle it as ETH
   * @param amount Amount of currency to transfer
   * @param remainingAmount Amount remaining after fees
   */
  function _handleIncomingPayment(uint256 amount, uint256 remainingAmount)
    private
  {
    // If this is an ETH payment, ensure they sent enough
    if (tokenSale.saleCurrency == address(0x0)) {
      if (remainingAmount != amount) {
        revert InvalidTransferAmount(amount);
      }
    } else {
      IERC20 token = IERC20(tokenSale.saleCurrency);

      // We must check the balance that was actually transferred to this contract,
      // as some tokens impose a transfer fee and would not actually transfer the
      // full amount to the market, resulting in potentally locked funds
      uint256 beforeBalance = IERC20(token).balanceOf(address(this));
      IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
      uint256 afterBalance = IERC20(token).balanceOf(address(this));
      if (afterBalance - beforeBalance != amount) {
        revert InvalidTransferAmount(amount);
      }
    }
  }

  /**
   * @notice method for adding addresses to whitelist
   * @param addresses - addresses to be added to the whitelist
   */
  function _addManyToWhitelist(address[] calldata addresses) private {
    for (uint256 i; i < addresses.length; ) {
      Helpers.validateAddress(addresses[i]);
      whitelist[addresses[i]] = true;
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice method for resetting the whitelist
   */
  function _clearWhitelist() private {
    unchecked {
      address[] memory addresses = whitelistedAddresses;
      for (uint256 i; i < addresses.length; i++) {
        whitelist[addresses[i]] = false;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Helpers } from "./lib/Helpers.sol";

contract TokenLocker is Ownable {
  using SafeERC20 for IERC20;
  /// @notice token on which the contract will perform locking
  IERC20 public immutable token;
  /// @notice time after which tokens are locked
  uint40 public lockTime;
  /// @notice time after which tokens are unlocked
  uint40 public unlockTime;
  /// @notice address of the fee receiver (Bitbond wallet)
  address private constant FEE_RECEIVER =
    0x9254C0fcB2FaA4550B9ba582558cE1D03Ba3d05d;

  /// @notice emitted when contract is created
  event TokenLockerCreated(address indexed owner, address indexed token);
  /// @notice emitted when tokens are locked
  event TokensLocked(
    uint256 tokenAmount,
    address indexed token,
    uint40 unlockTimeToSet
  );
  /// @notice emitted when tokens are relocked
  event TokensReLocked(address indexed token, uint40 newUnlockTimeToSet);
  /// @notice emitted when tokens are unlocked
  event TokensWithdrawn(address indexed to);

  /// @notice raised attempting to lock already locked tokens
  error TokensAlreadyLocked();
  /// @notice raised when attempting to set an unlock time in the past
  error UnlockTimeMustBeInFuture(uint40 unlockTime);
  /// @notice raised when no tokens are sent for locking
  error NoTokensToLock(uint256 amount);
  /// @notice raised when attempting to relock tokens when there are no locked tokens
  error NoTokensToRelock(uint256 amount);
  /// @notice raised when attempting to set an unlock time earlier than current
  error UnlockTimeLtPrevious();
  /// @notice raised when attempting to withdraw tokens before unlock time
  error CannotUnlockBeforeUnlockTime();

  constructor(address tokenAddress, address owner_) {
    Helpers.validateAddress(tokenAddress);
    token = IERC20(tokenAddress);
    // owner zero-validation is done inside this method
    transferOwnership(owner_);
    emit TokenLockerCreated(owner_, tokenAddress);
  }

  /**
   * @notice method for retrieving the token address
   * @return address of the token
   */
  function getTokenAddress() external view returns (address) {
    return address(token);
  }

  /**
   * @notice method for locking tokens
   * @param tokenAmount - amount of tokens to lock
   * @param unlockTimeToSet - time after which tokens will be unlocked
   * @dev only callable by owner
   */
  function lock(uint256 tokenAmount, uint40 unlockTimeToSet)
    external
    payable
    onlyOwner
  {
    if (token.balanceOf(address(this)) != 0) {
      revert TokensAlreadyLocked();
    }
    if (unlockTimeToSet <= block.timestamp) {
      revert UnlockTimeMustBeInFuture(unlockTimeToSet);
    }
    if (tokenAmount == 0) {
      revert NoTokensToLock(tokenAmount);
    }
    Helpers.safeTransferETH(FEE_RECEIVER, msg.value);

    lockTime = uint40(block.timestamp);
    unlockTime = unlockTimeToSet;
    token.safeTransferFrom(msg.sender, address(this), tokenAmount);

    emit TokensLocked(tokenAmount, address(token), unlockTimeToSet);
  }

  /**
   * @notice Method allowing to relock currently locked tokens.
   * Possible to relock only when tokens were deposited and new unlock
   * timestamp is after current one.
   * @param newUnlockTime new unlock time to be set
   * @dev only callable by owner
   */
  function relock(uint40 newUnlockTime) external onlyOwner {
    if (token.balanceOf(address(this)) == 0) {
      revert NoTokensToRelock(token.balanceOf(address(this)));
    }
    if (newUnlockTime <= unlockTime) {
      revert UnlockTimeLtPrevious();
    }
    unlockTime = newUnlockTime;
    emit TokensReLocked(address(token), newUnlockTime);
  }

  /**
   * @notice Method allowing to withdraw locked tokens.
   * Possible to unlock only after unlock time.
   * @param to receiver of tokens
   * @param amount amount of tokens
   * @dev only callable by owner
   */
  function withdraw(address to, uint256 amount) external onlyOwner {
    if (block.timestamp < unlockTime) {
      revert CannotUnlockBeforeUnlockTime();
    }
    token.safeTransfer(to, amount);
    emit TokensWithdrawn(to);
  }

  /**
   * @notice Locked tokens amount
   * @return amount of locked tokens
   */
  function getLockedTokensAmount() external view returns (uint256) {
    return token.balanceOf(address(this));
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import { Helpers } from "./lib/Helpers.sol";

contract CollectibleBatchToken is ERC721URIStorage, Ownable {
  /// @notice mapping of whitelisted addresses to a boolean
  mapping(address => bool) public whitelist;
  /// @notice array holding all whitelisted addresses
  address[] public whitelistedAddresses;
  /// @notice array holding tokenUris
  string[] public tokenUris;
  /// @notice total number of tokens minted
  uint256 public totalMinted;
  /// @notice max tokens allowed per wallet
  uint256 public immutable maxPerUser;
  /// @notice price for minting a token
  uint256 public immutable price;
  /// @notice start block for minting
  uint40 public immutable startMintBlock;
  /// @notice end block for minting
  uint40 public immutable endMintBlock;
  /// @notice boolean to check if anyone can mint a new token
  bool public immutable publicMint;
  /// @notice boolean to check if whitelisting is enabled
  bool public immutable isWhitelistEnabled;
  /// @notice used internally
  // solhint-disable-next-line const-name-snakecase
  bool public constant isBatchVersion = true;

  /// @notice raised when public minting is not allowed
  error PublicMintNotAllowed();
  /// @notice raised when the fee amount is invalid
  error InvalidFeeAmount(uint256 amount);
  /// @notice raised when the max supply has been reached
  error MaxSupplyReached(uint256 maxSupply);
  /// @notice raised when the max per user has been reached
  error MaxPerUserReached(uint256 maxPerUser);
  /// @notice raised when the sale has not started
  error SaleNotStarted();
  /// @notice raised when the sale has already ended
  error SaleAlreadyEnded();
  /// @notice raised when whitelisting is not enabled
  error WhitelistNotEnabled();
  /// @notice raised when the address is not whitelisted
  error NotWhitelisted(address addr);

  /**
   * @notice modifier which checks if public minting is allowed
   * or if the minter is the owner of the contract
   * @param receiver - address of the receiver
   */
  modifier publicMintAllowed(address receiver) {
    if (!publicMint && receiver != owner()) {
      revert PublicMintNotAllowed();
    }
    _;
  }

  /**
   * @notice modifier which checks if the correct amount of is sent as fees for mint
   */
  modifier costs() {
    if (price != 0 && msg.value != price) {
      revert InvalidFeeAmount(msg.value);
    }
    _;
  }

  /**
   * @notice modifier which checks if the max supply has been reached
   */
  modifier limitedByMaxSupply() {
    if (tokenUris.length != 0 && totalMinted >= tokenUris.length) {
      revert MaxSupplyReached(tokenUris.length);
    }
    _;
  }

  /**
   * @notice modifier which checks if the max per user has been reached
   * @param receiver - address of the user to check if max per user has been reached
   */
  modifier limitedPerUser(address receiver) {
    if (owner() != receiver) {
      if (maxPerUser != 0 && balanceOf(receiver) >= maxPerUser) {
        revert MaxPerUserReached(maxPerUser);
      }
    }
    _;
  }

  /**
   * @notice modifier which checks if sale has started and not ended
   */
  modifier saleIsOpen() {
    if (block.timestamp < startMintBlock) {
      revert SaleNotStarted();
    }
    if (endMintBlock != 0 && block.timestamp >= endMintBlock) {
      revert SaleAlreadyEnded();
    }
    _;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxPerUser_,
    uint256 mintPrice_,
    address creatorAddress,
    bool publicMint_,
    uint40 startMintBlock_,
    uint40 endMintBlock_,
    bool isWhitelistEnabled_
  ) ERC721(name_, symbol_) {
    maxPerUser = maxPerUser_;
    price = mintPrice_;
    publicMint = publicMint_;
    isWhitelistEnabled = isWhitelistEnabled_;
    startMintBlock = startMintBlock_;
    endMintBlock = endMintBlock_;

    if (creatorAddress != msg.sender) {
      transferOwnership(creatorAddress);
    }
  }

  /**
   * @notice method which is used for minting NFTs
   * @param receiver - address of the receiver of the NFT
   * @return newItemId - id of the newly minted NFT
   */
  function mint(address receiver)
    external
    payable
    publicMintAllowed(receiver)
    saleIsOpen
    costs
    limitedByMaxSupply
    limitedPerUser(receiver)
    returns (uint256)
  {
    if (isWhitelistEnabled && owner() != receiver) {
      if (!whitelist[receiver]) {
        revert NotWhitelisted(receiver);
      }
    }
    uint256 newItemId = totalMinted;
    unchecked {
      ++totalMinted;
    }
    Helpers.safeTransferETH(owner(), msg.value);
    _safeMint(receiver, newItemId);
    _setTokenURI(newItemId, tokenUris[newItemId]);
    return newItemId;
  }

  /**
   * @notice method used to return the maxSupply
   * @return maxSupply - maxSupply of the NFT
   */
  function maxSupply() external view returns (uint256) {
    return tokenUris.length;
  }

  /**
   * @notice method which is used to return the tokenUris array
   * @return tokenUris - array of tokenUris
   */
  function getTokenUris() external view returns (string[] memory) {
    return tokenUris;
  }

  /**
   * @notice method which is used to set the tokenUris
   * @param _tokenUris - array of token uris to be added
   */
  function addTokenUris(string[] calldata _tokenUris) external onlyOwner {
    for (uint256 i; i < _tokenUris.length; ) {
      tokenUris.push(_tokenUris[i]);
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice method for updating the whitelist if whitelist is enabled
   * @param updatedAddresses - whitelisted addresses to be added
   */
  function updateWhitelist(address[] calldata updatedAddresses)
    external
    onlyOwner
  {
    if (!isWhitelistEnabled) {
      revert WhitelistNotEnabled();
    }
    _clearWhitelist();
    _addManyToWhitelist(updatedAddresses);
    whitelistedAddresses = updatedAddresses;
  }

  /**
   * @notice method for returning the whitelisted addresses
   * @return whitelistedAddresses - array of whitelisted addresses
   */
  function getWhitelistedAddresses() external view returns (address[] memory) {
    return whitelistedAddresses;
  }

  /**
   * @notice method for adding addresses to whitelist
   * @param addresses - addresses to be added to the whitelist
   */
  function _addManyToWhitelist(address[] calldata addresses) private {
    for (uint256 i; i < addresses.length; ) {
      Helpers.validateAddress(addresses[i]);
      whitelist[addresses[i]] = true;
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice method for resetting the whitelist
   */
  function _clearWhitelist() private {
    unchecked {
      address[] memory addresses = whitelistedAddresses;
      for (uint256 i; i < addresses.length; i++) {
        whitelist[addresses[i]] = false;
      }
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/ERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC1155.sol";
import "./IERC1155Receiver.sol";
import "./extensions/IERC1155MetadataURI.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155 is Context, ERC165, IERC1155, IERC1155MetadataURI {
    using Address for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    constructor(string memory uri_) {
        _setURI(uri_);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: address zero is not a valid owner");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] memory accounts,
        uint256[] memory ids
    ) public view virtual override returns (uint256[] memory) {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner or approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(address to, uint256 id, uint256 amount, bytes memory data) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_mint}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function _burn(address from, uint256 id, uint256 amount) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray(id);
        uint256[] memory amounts = _asSingletonArray(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {_burn}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     */
    function _burnBatch(address from, uint256[] memory ids, uint256[] memory amounts) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `ids` and `amounts` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    /**
     * @dev Hook that is called after any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non-ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(
        address[] calldata accounts,
        uint256[] calldata ids
    ) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/extensions/IERC1155MetadataURI.sol)

pragma solidity ^0.8.0;

import "../IERC1155.sol";

/**
 * @dev Interface of the optional ERC1155MetadataExtension interface, as defined
 * in the https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155MetadataURI is IERC1155 {
    /**
     * @dev Returns the URI for token type `id`.
     *
     * If the `\{id\}` substring is present in the URI, it must be replaced by
     * clients with the actual token type ID.
     */
    function uri(uint256 id) external view returns (string memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155Token is ERC1155 {
  uint256 private totalMinted;

  // solhint-disable-next-line no-empty-blocks
  constructor(string memory baseURI) ERC1155(baseURI) {}

  /**
   * @dev Creates `amount` tokens of token type current with current id and sends it to msg.sender.
   */
  function mint(uint256 amount) external {
    uint256 tokenId = totalMinted;
    unchecked {
      ++totalMinted;
    }
    _mint(msg.sender, tokenId, amount, "");
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

abstract contract ReentrancyGuard {
  /// @dev inspired from https://github.com/transmissions11/solmate/blob/main/src/utils/ReentrancyGuard.sol
  // Booleans are more expensive than uint256 or any type that takes up a full
  // word because each write operation emits an extra SLOAD to first read the
  // slot's contents, replace the bits taken up by the boolean, and then write
  // back. This is the compiler's defense against contract upgrades and
  // pointer aliasing, and it cannot be disabled.

  // The values being initially non-zero is more gas-efficient than updating a value
  // from a zero to non-zero, but it increases the deployment costs slightly
  uint256 private locked = 1;

  /// @notice raised when reentrancy is detected
  error ReentrantCall();

  modifier nonReentrant() virtual {
    if (locked != 1) {
      revert ReentrantCall();
    }
    locked = 2;
    _;
    locked = 1;
  }
}