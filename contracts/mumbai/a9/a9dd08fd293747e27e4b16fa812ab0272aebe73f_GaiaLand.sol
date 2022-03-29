/**
 *Submitted for verification at polygonscan.com on 2022-03-28
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol

pragma solidity >=0.7.0 <0.9.0;

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

  function decimals() external view returns (uint8);

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
  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

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

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
  function _msgSender() internal view virtual returns (address payable) {
    return payable(msg.sender);
  }

  function _msgData() internal view virtual returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    return msg.data;
  }
}

// File: @openzeppelin/contracts/introspection/IERC165.sol

pragma solidity >=0.7.0 <0.9.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
  /**
   * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
   */
  event Transfer(
    address indexed from,
    address indexed to,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
   */
  event Approval(
    address indexed owner,
    address indexed approved,
    uint256 indexed tokenId
  );

  /**
   * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
   */
  event ApprovalForAll(
    address indexed owner,
    address indexed operator,
    bool approved
  );

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
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * Requirements:
   *
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   * - `tokenId` token must exist and be owned by `from`.
   * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
   * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
   *
   * Emits a {Transfer} event.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  /**
   * @dev Transfers `tokenId` token from `from` to `to`.
   *
   * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

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
   * @dev Returns the account approved for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getApproved(uint256 tokenId)
    external
    view
    returns (address operator);

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
  function setApprovalForAll(address operator, bool _approved) external;

  /**
   * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
   *
   * See {setApprovalForAll}
   */
  function isApprovedForAll(address owner, address operator)
    external
    view
    returns (bool);

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
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Metadata.sol

pragma solidity >=0.7.0 <0.9.0;

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

// File: @openzeppelin/contracts/token/ERC721/IERC721Enumerable.sol

//////////////////////////

interface IUniswapV2Pair {
    function decimals() external pure returns (uint8);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

    function initialize(address, address) external;
}

////////////////////////////

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
  /**
   * @dev Returns the total amount of tokens stored by the contract.
   */
  function totalSupply() external view returns (uint256);

  /**
   * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
   * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    external
    view
    returns (uint256 tokenId);

  /**
   * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
   * Use along with {totalSupply} to enumerate all tokens.
   */
  function tokenByIndex(uint256 index) external view returns (uint256);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

pragma solidity >=0.7.0 <0.9.0;

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
   * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
   */
  function onERC721Received(
    address operator,
    address from,
    uint256 tokenId,
    bytes calldata data
  ) external returns (bytes4);
}

// File: @openzeppelin/contracts/introspection/ERC165.sol

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
  /*
   * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
   */
  bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

  /**
   * @dev Mapping of interface ids to whether or not it's supported.
   */
  mapping(bytes4 => bool) private _supportedInterfaces;

  constructor() {
    // Derived contracts need only register support for their own interfaces,
    // we register support for ERC165 itself here
    _registerInterface(_INTERFACE_ID_ERC165);
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   *
   * Time complexity O(1), guaranteed to always use less than 30 000 gas.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _supportedInterfaces[interfaceId];
  }

  /**
   * @dev Registers the contract as an implementer of the interface defined by
   * `interfaceId`. Support of the actual ERC165 interface is automatic and
   * registering its interface id is not required.
   *
   * See {IERC165-supportsInterface}.
   *
   * Requirements:
   *
   * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
   */
  function _registerInterface(bytes4 interfaceId) internal virtual {
    require(interfaceId != 0xffffffff, 'ERC165: invalid interface id');
    _supportedInterfaces[interfaceId] = true;
  }
}

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
  /**
   * @dev Returns the addition of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    uint256 c = a + b;
    if (c < a) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the substraction of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b > a) return (false, 0);
    return (true, a - b);
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
   *
   * _Available since v3.4._
   */
  function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
    if (a == 0) return (true, 0);
    uint256 c = a * b;
    if (c / a != b) return (false, 0);
    return (true, c);
  }

  /**
   * @dev Returns the division of two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a / b);
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
   *
   * _Available since v3.4._
   */
  function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    if (b == 0) return (false, 0);
    return (true, a % b);
  }

  /**
   * @dev Returns the addition of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `+` operator.
   *
   * Requirements:
   *
   * - Addition cannot overflow.
   */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, 'SafeMath: addition overflow');
    return c;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting on
   * overflow (when the result is negative).
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, 'SafeMath: subtraction overflow');
    return a - b;
  }

  /**
   * @dev Returns the multiplication of two unsigned integers, reverting on
   * overflow.
   *
   * Counterpart to Solidity's `*` operator.
   *
   * Requirements:
   *
   * - Multiplication cannot overflow.
   */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) return 0;
    uint256 c = a * b;
    require(c / a == b, 'SafeMath: multiplication overflow');
    return c;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting on
   * division by zero. The result is rounded towards zero.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, 'SafeMath: division by zero');
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting when dividing by zero.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0, 'SafeMath: modulo by zero');
    return a % b;
  }

  /**
   * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
   * overflow (when the result is negative).
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {trySub}.
   *
   * Counterpart to Solidity's `-` operator.
   *
   * Requirements:
   *
   * - Subtraction cannot overflow.
   */
  function sub(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b <= a, errorMessage);
    return a - b;
  }

  /**
   * @dev Returns the integer division of two unsigned integers, reverting with custom message on
   * division by zero. The result is rounded towards zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryDiv}.
   *
   * Counterpart to Solidity's `/` operator. Note: this function uses a
   * `revert` opcode (which leaves remaining gas untouched) while Solidity
   * uses an invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function div(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a / b;
  }

  /**
   * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
   * reverting with custom message when dividing by zero.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryMod}.
   *
   * Counterpart to Solidity's `%` operator. This function uses a `revert`
   * opcode (which leaves remaining gas untouched) while Solidity uses an
   * invalid opcode to revert (consuming all remaining gas).
   *
   * Requirements:
   *
   * - The divisor cannot be zero.
   */
  function mod(
    uint256 a,
    uint256 b,
    string memory errorMessage
  ) internal pure returns (uint256) {
    require(b > 0, errorMessage);
    return a % b;
  }
}

// File: @openzeppelin/contracts/utils/Address.sol

pragma solidity >=0.7.0 <0.9.0;

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
    // solhint-disable-next-line no-inline-assembly
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
    require(address(this).balance >= amount, 'Address: insufficient balance');

    // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
    (bool success, ) = recipient.call{value: amount}('');
    require(
      success,
      'Address: unable to send value, recipient may have reverted'
    );
  }

  /**
   * @dev Performs a Solidity function call using a low level `call`. A
   * plain`call` is an unsafe replacement for a function call: use this
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
  function functionCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return functionCall(target, data, 'Address: low-level call failed');
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
    return
      functionCallWithValue(
        target,
        data,
        value,
        'Address: low-level call with value failed'
      );
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
    require(
      address(this).balance >= value,
      'Address: insufficient balance for call'
    );
    require(isContract(target), 'Address: call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.call{value: value}(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a static call.
   *
   * _Available since v3.3._
   */
  function functionStaticCall(address target, bytes memory data)
    internal
    view
    returns (bytes memory)
  {
    return
      functionStaticCall(target, data, 'Address: low-level static call failed');
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
    require(isContract(target), 'Address: static call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.staticcall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  /**
   * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
   * but performing a delegate call.
   *
   * _Available since v3.4._
   */
  function functionDelegateCall(address target, bytes memory data)
    internal
    returns (bytes memory)
  {
    return
      functionDelegateCall(
        target,
        data,
        'Address: low-level delegate call failed'
      );
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
    require(isContract(target), 'Address: delegate call to non-contract');

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, bytes memory returndata) = target.delegatecall(data);
    return _verifyCallResult(success, returndata, errorMessage);
  }

  function _verifyCallResult(
    bool success,
    bytes memory returndata,
    string memory errorMessage
  ) private pure returns (bytes memory) {
    if (success) {
      return returndata;
    } else {
      // Look for revert reason and bubble it up if present
      if (returndata.length > 0) {
        // The easiest way to bubble the revert reason is using memory via assembly

        // solhint-disable-next-line no-inline-assembly
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

// File: @openzeppelin/contracts/utils/EnumerableSet.sol

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
  // To implement this library for multiple types with as little code
  // repetition as possible, we write it in terms of a generic Set type with
  // bytes32 values.
  // The Set implementation uses private functions, and user-facing
  // implementations (such as AddressSet) are just wrappers around the
  // underlying Set.
  // This means that we can only create new EnumerableSets for types that fit
  // in bytes32.

  struct Set {
    // Storage of set values
    bytes32[] _values;
    // Position of the value in the `values` array, plus 1 because index 0
    // means a value is not in the set.
    mapping(bytes32 => uint256) _indexes;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function _add(Set storage set, bytes32 value) private returns (bool) {
    if (!_contains(set, value)) {
      set._values.push(value);
      // The value is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel value
      set._indexes[value] = set._values.length;
      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function _remove(Set storage set, bytes32 value) private returns (bool) {
    // We read and store the value's index to prevent multiple reads from the same storage slot
    uint256 valueIndex = set._indexes[value];

    if (valueIndex != 0) {
      // Equivalent to contains(set, value)
      // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
      // the array, and then remove the last element (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = valueIndex - 1;
      uint256 lastIndex = set._values.length - 1;

      // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      bytes32 lastvalue = set._values[lastIndex];

      // Move the last value to the index where the value to delete is
      set._values[toDeleteIndex] = lastvalue;
      // Update the index for the moved value
      set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

      // Delete the slot where the moved value was stored
      set._values.pop();

      // Delete the index for the deleted slot
      delete set._indexes[value];

      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function _contains(Set storage set, bytes32 value)
    private
    view
    returns (bool)
  {
    return set._indexes[value] != 0;
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function _length(Set storage set) private view returns (uint256) {
    return set._values.length;
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function _at(Set storage set, uint256 index) private view returns (bytes32) {
    require(set._values.length > index, 'EnumerableSet: index out of bounds');
    return set._values[index];
  }

  // Bytes32Set

  struct Bytes32Set {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
    return _add(set._inner, value);
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(Bytes32Set storage set, bytes32 value)
    internal
    returns (bool)
  {
    return _remove(set._inner, value);
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(Bytes32Set storage set, bytes32 value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, value);
  }

  /**
   * @dev Returns the number of values in the set. O(1).
   */
  function length(Bytes32Set storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(Bytes32Set storage set, uint256 index)
    internal
    view
    returns (bytes32)
  {
    return _at(set._inner, index);
  }

  // AddressSet

  struct AddressSet {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(AddressSet storage set, address value) internal returns (bool) {
    return _add(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(AddressSet storage set, address value)
    internal
    returns (bool)
  {
    return _remove(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(AddressSet storage set, address value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Returns the number of values in the set. O(1).
   */
  function length(AddressSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(AddressSet storage set, uint256 index)
    internal
    view
    returns (address)
  {
    return address(uint160(uint256(_at(set._inner, index))));
  }

  // UintSet

  struct UintSet {
    Set _inner;
  }

  /**
   * @dev Add a value to a set. O(1).
   *
   * Returns true if the value was added to the set, that is if it was not
   * already present.
   */
  function add(UintSet storage set, uint256 value) internal returns (bool) {
    return _add(set._inner, bytes32(value));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the value was removed from the set, that is if it was
   * present.
   */
  function remove(UintSet storage set, uint256 value) internal returns (bool) {
    return _remove(set._inner, bytes32(value));
  }

  /**
   * @dev Returns true if the value is in the set. O(1).
   */
  function contains(UintSet storage set, uint256 value)
    internal
    view
    returns (bool)
  {
    return _contains(set._inner, bytes32(value));
  }

  /**
   * @dev Returns the number of values on the set. O(1).
   */
  function length(UintSet storage set) internal view returns (uint256) {
    return _length(set._inner);
  }

  /**
   * @dev Returns the value stored at position `index` in the set. O(1).
   *
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(UintSet storage set, uint256 index)
    internal
    view
    returns (uint256)
  {
    return uint256(_at(set._inner, index));
  }
}

// File: @openzeppelin/contracts/utils/EnumerableMap.sol

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
  // To implement this library for multiple types with as little code
  // repetition as possible, we write it in terms of a generic Map type with
  // bytes32 keys and values.
  // The Map implementation uses private functions, and user-facing
  // implementations (such as Uint256ToAddressMap) are just wrappers around
  // the underlying Map.
  // This means that we can only create new EnumerableMaps for types that fit
  // in bytes32.

  struct MapEntry {
    bytes32 _key;
    bytes32 _value;
  }

  struct Map {
    // Storage of map keys and values
    MapEntry[] _entries;
    // Position of the entry defined by a key in the `entries` array, plus 1
    // because index 0 means a key is not in the map.
    mapping(bytes32 => uint256) _indexes;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
   * key. O(1).
   *
   * Returns true if the key was added to the map, that is if it was not
   * already present.
   */
  function _set(
    Map storage map,
    bytes32 key,
    bytes32 value
  ) private returns (bool) {
    // We read and store the key's index to prevent multiple reads from the same storage slot
    uint256 keyIndex = map._indexes[key];

    if (keyIndex == 0) {
      // Equivalent to !contains(map, key)
      map._entries.push(MapEntry({_key: key, _value: value}));
      // The entry is stored at length-1, but we add 1 to all indexes
      // and use 0 as a sentinel value
      map._indexes[key] = map._entries.length;
      return true;
    } else {
      map._entries[keyIndex - 1]._value = value;
      return false;
    }
  }

  /**
   * @dev Removes a key-value pair from a map. O(1).
   *
   * Returns true if the key was removed from the map, that is if it was present.
   */
  function _remove(Map storage map, bytes32 key) private returns (bool) {
    // We read and store the key's index to prevent multiple reads from the same storage slot
    uint256 keyIndex = map._indexes[key];

    if (keyIndex != 0) {
      // Equivalent to contains(map, key)
      // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
      // in the array, and then remove the last entry (sometimes called as 'swap and pop').
      // This modifies the order of the array, as noted in {at}.

      uint256 toDeleteIndex = keyIndex - 1;
      uint256 lastIndex = map._entries.length - 1;

      // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
      // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

      MapEntry storage lastEntry = map._entries[lastIndex];

      // Move the last entry to the index where the entry to delete is
      map._entries[toDeleteIndex] = lastEntry;
      // Update the index for the moved entry
      map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

      // Delete the slot where the moved entry was stored
      map._entries.pop();

      // Delete the index for the deleted slot
      delete map._indexes[key];

      return true;
    } else {
      return false;
    }
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
   */
  function _contains(Map storage map, bytes32 key) private view returns (bool) {
    return map._indexes[key] != 0;
  }

  /**
   * @dev Returns the number of key-value pairs in the map. O(1).
   */
  function _length(Map storage map) private view returns (uint256) {
    return map._entries.length;
  }

  /**
   * @dev Returns the key-value pair stored at position `index` in the map. O(1).
   *
   * Note that there are no guarantees on the ordering of entries inside the
   * array, and it may change when more entries are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function _at(Map storage map, uint256 index)
    private
    view
    returns (bytes32, bytes32)
  {
    require(map._entries.length > index, 'EnumerableMap: index out of bounds');

    MapEntry storage entry = map._entries[index];
    return (entry._key, entry._value);
  }

  /**
   * @dev Tries to returns the value associated with `key`.  O(1).
   * Does not revert if `key` is not in the map.
   */
  function _tryGet(Map storage map, bytes32 key)
    private
    view
    returns (bool, bytes32)
  {
    uint256 keyIndex = map._indexes[key];
    if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
    return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
  }

  /**
   * @dev Returns the value associated with `key`.  O(1).
   *
   * Requirements:
   *
   * - `key` must be in the map.
   */
  function _get(Map storage map, bytes32 key) private view returns (bytes32) {
    uint256 keyIndex = map._indexes[key];
    require(keyIndex != 0, 'EnumerableMap: nonexistent key'); // Equivalent to contains(map, key)
    return map._entries[keyIndex - 1]._value; // All indexes are 1-based
  }

  /**
   * @dev Same as {_get}, with a custom error message when `key` is not in the map.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {_tryGet}.
   */
  function _get(
    Map storage map,
    bytes32 key,
    string memory errorMessage
  ) private view returns (bytes32) {
    uint256 keyIndex = map._indexes[key];
    require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
    return map._entries[keyIndex - 1]._value; // All indexes are 1-based
  }

  // UintToAddressMap

  struct UintToAddressMap {
    Map _inner;
  }

  /**
   * @dev Adds a key-value pair to a map, or updates the value for an existing
   * key. O(1).
   *
   * Returns true if the key was added to the map, that is if it was not
   * already present.
   */
  function set(
    UintToAddressMap storage map,
    uint256 key,
    address value
  ) internal returns (bool) {
    return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
  }

  /**
   * @dev Removes a value from a set. O(1).
   *
   * Returns true if the key was removed from the map, that is if it was present.
   */
  function remove(UintToAddressMap storage map, uint256 key)
    internal
    returns (bool)
  {
    return _remove(map._inner, bytes32(key));
  }

  /**
   * @dev Returns true if the key is in the map. O(1).
   */
  function contains(UintToAddressMap storage map, uint256 key)
    internal
    view
    returns (bool)
  {
    return _contains(map._inner, bytes32(key));
  }

  /**
   * @dev Returns the number of elements in the map. O(1).
   */
  function length(UintToAddressMap storage map)
    internal
    view
    returns (uint256)
  {
    return _length(map._inner);
  }

  /**
   * @dev Returns the element stored at position `index` in the set. O(1).
   * Note that there are no guarantees on the ordering of values inside the
   * array, and it may change when more values are added or removed.
   *
   * Requirements:
   *
   * - `index` must be strictly less than {length}.
   */
  function at(UintToAddressMap storage map, uint256 index)
    internal
    view
    returns (uint256, address)
  {
    (bytes32 key, bytes32 value) = _at(map._inner, index);
    return (uint256(key), address(uint160(uint256(value))));
  }

  /**
   * @dev Tries to returns the value associated with `key`.  O(1).
   * Does not revert if `key` is not in the map.
   *
   * _Available since v3.4._
   */
  function tryGet(UintToAddressMap storage map, uint256 key)
    internal
    view
    returns (bool, address)
  {
    (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
    return (success, address(uint160(uint256(value))));
  }

  /**
   * @dev Returns the value associated with `key`.  O(1).
   *
   * Requirements:
   *
   * - `key` must be in the map.
   */
  function get(UintToAddressMap storage map, uint256 key)
    internal
    view
    returns (address)
  {
    return address(uint160(uint256(_get(map._inner, bytes32(key)))));
  }

  /**
   * @dev Same as {get}, with a custom error message when `key` is not in the map.
   *
   * CAUTION: This function is deprecated because it requires allocating memory for the error
   * message unnecessarily. For custom revert reasons use {tryGet}.
   */
  function get(
    UintToAddressMap storage map,
    uint256 key,
    string memory errorMessage
  ) internal view returns (address) {
    return
      address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
  }
}

// File: @openzeppelin/contracts/utils/Strings.sol

pragma solidity >=0.7.0 <0.9.0;

/**
 * @dev String operations.
 */
library Strings {
  /**
   * @dev Converts a `uint256` to its ASCII `string` representation.
   */
  function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT licence
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

    if (value == 0) {
      return '0';
    }
    uint256 temp = value;
    uint256 digits;
    while (temp != 0) {
      digits++;
      temp /= 10;
    }
    bytes memory buffer = new bytes(digits);
    uint256 index = digits - 1;
    temp = value;
    while (temp != 0) {
      buffer[index--] = bytes1(uint8(48 + (temp % 10)));
      temp /= 10;
    }
    return string(buffer);
  }
}

// File: @openzeppelin/contracts/token/ERC721/ERC721.sol

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */

contract ERC721 is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable
{
  using SafeMath for uint256;
  using Address for address;
  using EnumerableSet for EnumerableSet.UintSet;
  using EnumerableMap for EnumerableMap.UintToAddressMap;
  using Strings for uint256;

  // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
  // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
  bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

  // Mapping from holder address to their (enumerable) set of owned tokens
  mapping(address => EnumerableSet.UintSet) private _holderTokens;

  // Enumerable mapping from token ids to their owners
  EnumerableMap.UintToAddressMap private _tokenOwners;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Optional mapping for token URIs
  mapping(uint256 => string) private _tokenURIs;

  // Base URI
  string private _baseURI;

  /*
   *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
   *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
   *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
   *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
   *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
   *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
   *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
   *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
   *
   *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
   *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
   */
  bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

  /*
   *     bytes4(keccak256('name()')) == 0x06fdde03
   *     bytes4(keccak256('symbol()')) == 0x95d89b41
   *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
   *
   *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
   */
  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

  /*
   *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
   *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
   *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
   *
   *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
   */
  bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

  /**
   * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
   */
  constructor(string memory name_, string memory symbol_) {
    _name = name_;
    _symbol = symbol_;

    // register the supported interfaces to conform to ERC721 via ERC165
    _registerInterface(_INTERFACE_ID_ERC721);
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
  {
    require(owner != address(0), 'ERC721: balance query for the zero address');
    return _holderTokens[owner].length();
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    return
      _tokenOwners.get(tokenId, 'ERC721: owner query for nonexistent token');
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
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      'ERC721Metadata: URI query for nonexistent token'
    );

    string memory _tokenURI = _tokenURIs[tokenId];
    string memory base = baseURI();

    // If there is no base URI, return the token URI.
    if (bytes(base).length == 0) {
      return _tokenURI;
    }
    // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
    if (bytes(_tokenURI).length > 0) {
      return string(abi.encodePacked(base, _tokenURI));
    }
    // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
    return string(abi.encodePacked(base, tokenId.toString()));
  }

  /**
   * @dev Returns the base URI set via {_setBaseURI}. This will be
   * automatically added as a prefix in {tokenURI} to each token's URI, or
   * to the token ID if no specific URI is set for that token ID.
   */
  function baseURI() public view virtual returns (string memory) {
    return _baseURI;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    return _holderTokens[owner].at(index);
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view virtual override returns (uint256) {
    // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
    return _tokenOwners.length();
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index)
    public
    view
    virtual
    override
    returns (uint256)
  {
    (uint256 tokenId, ) = _tokenOwners.at(index);
    return tokenId;
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public virtual override {
    address owner = ERC721.ownerOf(tokenId);
    require(to != owner, 'ERC721: approval to current owner');

    require(
      _msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
      'ERC721: approve caller is not owner nor approved for all'
    );

    _approve(to, tokenId);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId)
    public
    view
    virtual
    override
    returns (address)
  {
    require(_exists(tokenId), 'ERC721: approved query for nonexistent token');

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved)
    public
    virtual
    override
  {
    require(operator != _msgSender(), 'ERC721: approve to caller');

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    //solhint-disable-next-line max-line-length
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: transfer caller is not owner nor approved'
    );

    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    safeTransferFrom(from, to, tokenId, '');
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public virtual override {
    require(
      _isApprovedOrOwner(_msgSender(), tokenId),
      'ERC721: transfer caller is not owner nor approved'
    );
    _safeTransfer(from, to, tokenId, _data);
  }

  /**
   * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   *
   * `_data` is additional data, it has no specified format and it is sent in call to `to`.
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
  function _safeTransfer(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      'ERC721: transfer to non ERC721Receiver implementer'
    );
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
    return _tokenOwners.contains(tokenId);
  }

  /**
   * @dev Returns whether `spender` is allowed to manage `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    virtual
    returns (bool)
  {
    require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
    address owner = ERC721.ownerOf(tokenId);
    return (spender == owner ||
      getApproved(tokenId) == spender ||
      ERC721.isApprovedForAll(owner, spender));
  }

  /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     d*
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
  function _safeMint(address to, uint256 tokenId) internal virtual {
    _safeMint(to, tokenId, '');
  }

  /**
   * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
   * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to,
    uint256 tokenId,
    bytes memory _data
  ) internal virtual {
    _mint(to, tokenId);
    require(
      _checkOnERC721Received(address(0), to, tokenId, _data),
      'ERC721: transfer to non ERC721Receiver implementer'
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
    require(to != address(0), 'ERC721: mint to the zero address');
    require(!_exists(tokenId), 'ERC721: token already minted');

    _beforeTokenTransfer(address(0), to, tokenId);

    _holderTokens[to].add(tokenId);

    _tokenOwners.set(tokenId, to);

    emit Transfer(address(0), to, tokenId);
  }

  /**
   * @dev Destroys `tokenId`.
   * The approval is cleared when the token is burned.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {Transfer} event.
   */
  function _burn(uint256 tokenId) internal virtual {
    address owner = ERC721.ownerOf(tokenId); // internal owner

    _beforeTokenTransfer(owner, address(0), tokenId);

    // Clear approvals
    _approve(address(0), tokenId);

    // Clear metadata (if any)
    if (bytes(_tokenURIs[tokenId]).length != 0) {
      delete _tokenURIs[tokenId];
    }

    _holderTokens[owner].remove(tokenId);

    _tokenOwners.remove(tokenId);

    emit Transfer(owner, address(0), tokenId);
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
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {
    require(
      ERC721.ownerOf(tokenId) == from,
      'ERC721: transfer of token that is not own'
    ); // internal owner
    require(to != address(0), 'ERC721: transfer to the zero address');

    _beforeTokenTransfer(from, to, tokenId);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId);

    _holderTokens[from].remove(tokenId);
    _holderTokens[to].add(tokenId);

    _tokenOwners.set(tokenId, to);

    emit Transfer(from, to, tokenId);
  }

  /**
   * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function _setTokenURI(uint256 tokenId, string memory _tokenURI)
    internal
    virtual
  {
    require(_exists(tokenId), 'ERC721Metadata: URI set of nonexistent token');
    _tokenURIs[tokenId] = _tokenURI;
  }

  /**
   * @dev Internal function to set the base URI for all token IDs. It is
   * automatically added as a prefix to the value returned in {tokenURI},
   * or to the token ID if {tokenURI} is empty.
   */
  function _setBaseURI(string memory baseURI_) internal virtual {
    _baseURI = baseURI_;
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (!to.isContract()) {
      return true;
    }
    bytes memory returndata = to.functionCall(
      abi.encodeWithSelector(
        IERC721Receiver(to).onERC721Received.selector,
        _msgSender(),
        from,
        tokenId,
        _data
      ),
      'ERC721: transfer to non ERC721Receiver implementer'
    );
    bytes4 retval = abi.decode(returndata, (bytes4));
    return (retval == _ERC721_RECEIVED);
  }

  /**
   * @dev Approve `to` to operate on `tokenId`
   *
   * Emits an {Approval} event.
   */
  function _approve(address to, uint256 tokenId) internal virtual {
    _tokenApprovals[tokenId] = to;
    emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity >=0.7.0 <0.9.0;

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

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev Initializes the contract setting the deployer as the initial owner.
   */
  constructor() {
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
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
    require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newOwner`).
   * Can only be called by the current owner.
   */
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), 'Ownable: new owner is the zero address');
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

pragma solidity 0.8.4;
pragma abicoder v2;

contract GaiaLand is ERC721, Ownable {
  using SafeMath for uint256;

  string public GAIALANDS_PROVENANCE = '';

  string public LICENSE_TEXT = '';

  bool public licenseLocked = false;

  uint256 public gaiaGoodLandPrice = 350;

  uint256 public gaiaRegularLandPrice = 175;

  uint256 public constant MAX_GAIALANDS_PURCHASE = 200;

  uint256 public constant MAX_GAIALANDS = 124884;

  bool public saleIsActive = true;

  uint256 public saleDate = 1648479600;

  uint256 public gaiaLandReserve = 50000;

  uint256 public gaiaUSDC = 79357452196816930849001 * (10**18) / uint256(1868548345305467327315244) * 1588085682360 * (10**12) / uint256(1586020149070416559561266);

  struct Auction {
    uint256 price;
    string unit;
    uint32 duration;
    uint256 startTime;
    uint256 endTime;
    bool status;
    uint32 id;
    uint32 mintId;
    address creator;
    address payable newOwner;
    address payable preOwner;
  }

  struct MapData {
    uint8 size;
    uint32 mintId;
    uint32 x;
    uint32 y;
    address owner;
    bool listing;
    string landType;
    string location;
  }
  
  struct WhiteListData {
    uint16 epic;
    uint16 regular;
  }

  mapping(uint256 => MapData) public ownerMap;
  mapping(uint256 => Auction) public auctions;
  mapping(address => uint16) public whiteLists;
  


  address private immutable PGAIAAddress =
    0xa79E4849cAaAE5dF885e901f1B67725f3807D13F;

  event licenseisLocked(string _licenseText);
  event provenanceHashSet(string provenanceHash);
  event goodPriceSet(uint256 newPrice);
  event regularPriceSet(uint256 newPrice);
  event withdrawRun(uint256 balance);
  address private ownerAddress;

  constructor() ERC721('GAIALAND', 'GAIALAND') {
    ownerAddress = msg.sender;
    whiteLists[0x84F6F9867aC2C4e8d990825D440cd6da1DE3309f] = 10;
    whiteLists[0xdf7640b03e905Ff8d244b73d380F62aeb17077A6] = 5;
    whiteLists[0x8B139211fD5f39C9f4943D0C2039957E8609e960] = 1;
    whiteLists[0x14032910D8EAFb732d67a9Ea5BE3C20eC89F9ED7] = 4;
    whiteLists[0x1dE14ee37F1cf16414c72656607e1A703d7EB46d] = 5;
    whiteLists[0x645855D346F573e12f1D760b6eE1C7A29f6E6BB0] = 1;
    whiteLists[0x7Cc3D75A86a29233Ae14DFeD98f65561EE166Ec7] = 12;
    whiteLists[0xB28B7980B2B3030E0905c603CFFE597b0426fc26] = 2;
    whiteLists[0x436dbF130Df635A43627655Ac6302b36f457f8de] = 1;
    whiteLists[0x4093AB3Ad51c944C2a8aBE095a6A8B26c57b8c11] = 3;
    whiteLists[0x0CE6bA7618A235d64754d11E3673d667FB8c1590] = 2;
    whiteLists[0x2cA9ec1C79ce2fDaEE958996E832eB46c6dC4Ecd] = 5;
    whiteLists[0xAb5b17ca50d534Cf1f8FD03980152003302bEc8c] = 2;
    whiteLists[0x3C12E632fCeB461cDa13588fa7869AEa4c90799a] = 1;
    whiteLists[0x3e21342722fbd583d114E29F6B14D6F777b18cB5] = 18;
    whiteLists[0xf6045C8F74064f6D488E284f8Be018e41cF909D5] = 1;
    whiteLists[0x5973cdCFae5F3C3C7dda3AaDB022eaeA0e84093b] = 5;
    whiteLists[0xB6636526C005a7C493b360bA141694f9e493182E] = 1;
    whiteLists[0xABa47f80Ad6c60dA030B3E6058546e5488c8BBA6] = 25;
    whiteLists[0x217f3268Aa79dd1FeA83c4804D3eC48aA5937e49] = 1;
    whiteLists[0xaeAcf6924040852320235C116bCfEC476A2Aebaa] = 1;
    whiteLists[0x1dDF83c39bB459cDD990b8804D92d933c1f50cBC] = 2;
    whiteLists[0xf47d768a05230FF46Ce37b105bcBAc5466602AB4] = 2;
    whiteLists[0xcCF4a1B1474C7aBb5726D7d57fF92a6Dc86BC866] = 5;
    whiteLists[0x1d4c28D86fF0912CC79F2002c04980C1FB8a031F] = 4;
    whiteLists[0x4F381b68F2d380C47a54aC31750347a4d86DE31B] = 1;
    whiteLists[0x04808250Df92ACeCb57a18002BC50953c300e168] = 1;
    whiteLists[0xEf2ad2E87D581C505cdBF4C6670A349Cd7f8Dd54] = 1;
    whiteLists[0x5B239Dac2396aE1704ae7f90Fc258477Eb39f583] = 10;
    whiteLists[0x187810697F2DD2f5e1D14acacf80e01e16ea9631] = 50;
    whiteLists[0xB0Be6A546eF335C8a8C5fFAdc30B1e71C601525b] = 1;
    whiteLists[0x1bfE8143B7343Bc6F31aE5B53C6a3E0c825fa3DE] = 4;
    whiteLists[0x123b93AEBA977968290FB0de5250A4d441F5a5ab] = 1;
    whiteLists[0xeAa95755bC8162CaA724d9D4bb76eC111c5A41B5] = 4;
    whiteLists[0xB13D98A938f4e684036a476A482Fb5A56f7BA9aC] = 2;
    whiteLists[0x74639aE45F2D3af5720c1ECa3E5D171528746c2D] = 1;
    whiteLists[0x6E4bb750ab33C7DD5Bc0EA274a5055083C38355e] = 1;
    whiteLists[0x71d6c03Cf9A9cbe383DAA9D921C66698D81fc505] = 21;
    whiteLists[0xaF0FfABe45693b24a628723c1D1fe0Bde64318F0] = 12;
    whiteLists[0xA0a30dfb70264362d999BE1CA11Af79B57A893c7] = 3;
    whiteLists[0x6Da5f8234f4E96DBAAb10a99D069FC62F292561E] = 1;
    whiteLists[0xAe2319f4779E6cA885b1C0BfE153c7B534147A6F] = 4;
    whiteLists[0x8Bf58b60592Eda781CDa22C3Aa59EB4FDe6bA01F] = 1;
    whiteLists[0xB77e2AC1F9d6f44Fb8a333842E7278A9aeAD903E] = 1;
    whiteLists[0x2b038d4BC7c1C1C3a9e388bf5e817aCDcCa32D34] = 1;
    whiteLists[0x2fe4f733e897A36120ef5645F184F2217FF32262] = 7;
    whiteLists[0x03Bdfc0F7d88040Cf2A65d79Ba6FC71E0f680252] = 1;
    whiteLists[0xe5A4BB625173B6686f6465d7286d80cA5C81282B] = 1;
    whiteLists[0xacfE9de077f85E0784af4140115cD523D87111aD] = 1;
    whiteLists[0x9953979D083a5A6B2ca4DF7D2f2456BA06cF3181] = 1;
    whiteLists[0x8398cdF4950A59ae56e3cc0003c74a8fa3eB0784] = 2;
    whiteLists[0x05Bf260e17D259bbe2B97fd203cA42250696Ca95] = 50;
    whiteLists[0xFd9C25c3703334233D2B2585615c96682845F981] = 10;
    whiteLists[0x3c25A061850d1EDBfB921DD2db498992cf52283C] = 2;
    whiteLists[0x5cb3131D140bAeDe3AeD0396CFf3379A0909219f] = 1;
    whiteLists[0x7a0eF0380aEA37197912A799CA2eD40B50d3ae75] = 2;
    whiteLists[0xb53740266D724C7dd452140C3ff6864E6efA177D] = 5;
    whiteLists[0x5727F9142864e30a3cC44F0FbAbBd3cEa022C1Ff] = 1;
    whiteLists[0xe407805eB1a415379Ae9d03b957EDdEd19218D75] = 1;
    whiteLists[0x38385E3727C916dC7E9B9c260629890b350Fe95C] = 1;
    whiteLists[0x308E1E12121cF73859D8DC2EA3B5Bb7bCD7192cc] = 1;
    whiteLists[0x790C5654D3dfd26Be69cB6922da9a5C138d82A45] = 1;
    whiteLists[0xDbfbF6F568d4228EABDd80D1624179cc966BC177] = 1;
    whiteLists[0xEaA261C6e166336d0Ce961af6d6b7898182b85d5] = 1;
    whiteLists[0xd1e7e4d146861fb0a07e15Ec61c83b868af80EB4] = 3;
    whiteLists[0x8F21382c618B66E61A499eB57A7aD3B5c3B09E3b] = 1;
    whiteLists[0x6DE789dEF9c2fa1dDCbF4f75Ba1219aA9AB67a87] = 1;
    whiteLists[0xd28eCE094a764Bba63A9AA021B1153627a74Cf8E] = 1;
    whiteLists[0x165564f31299f5760116Ddf29aa94522266CD78b] = 3;
    whiteLists[0x62444a9fBDE3d002816aA91183F954A7B09e7793] = 6;
    whiteLists[0x7e219CE0f63337D9cBB708b1c64AE34eC026b9ae] = 2;
    whiteLists[0x70847C777BDD1B9D3cD0A3640800e5bD9cf6Aff2] = 3;
    whiteLists[0xD36Cd512D34aa2F289CE071d913C06d813797bBd] = 1;
    whiteLists[0x3373bcA6e9F57AC6cddCc362b009750cF49F3d20] = 1;
    whiteLists[0x73bD85d1270a9A5Aeeb2ac5F982F7AA88a6d1E42] = 4;
    whiteLists[0xffCFc37E89f0912bC4663F123C72b056883403AF] = 1;
    whiteLists[0x05d5A4b3797d885E08ED914b5e18B063A7569b0d] = 7;
    whiteLists[0xCb601cb0186f77e4388a7473c908874d5248979D] = 1;
    whiteLists[0x5c6471788Ae8bc553E62Df0fe92bD2404D259cd6] = 1;
    whiteLists[0x5316ba653448D1CaE8646099666b42A28835104b] = 3;
    whiteLists[0x292D17A31317a0781f78f412DE9eA7Ca9bCecD19] = 1;
    whiteLists[0x8Dd2Bb9d6cff327befe7aAf01EBcEB058f085018] = 1;
    whiteLists[0x616c6f0fE3eAA6A2F44c445965265145e6bea236] = 1;
    whiteLists[0x36f9f04762985df3F6c646eE4CAF269d8747eCE8] = 8;
    whiteLists[0x5c256710Da0Be013Cf65E694d4AA7a09f900C156] = 1;
    whiteLists[0x26Ea9aA44620b375747197728ebA985594f8f077] = 1;
    whiteLists[0x15B5Df4eEf4d843A84624ED065bfd552CDff3f4B] = 2;
    whiteLists[0x2C5415FF575afF757d3339f2BDfB1e3489B17ff2] = 1;
    whiteLists[0xf6bFA120B580B219dDc84e1f1f08190Fe9303e0B] = 8;
    whiteLists[0x4E63c2eB7079cBe790dE5bc5A5565e3c86fB057F] = 1;
    whiteLists[0x6Eb186b09447bDB1e2216C15200835fb8656F7f7] = 1;
    whiteLists[0x4661049b4d5318b078F255560b954B87be859f14] = 2;
    whiteLists[0x6EB46F2966d1Cb08aB82a6767C6cD61316162be5] = 1;
    whiteLists[0xe548EaEf543A3F4974b71785A8DcF4F29550f87f] = 3;
    whiteLists[0x9B5F74C8c979F3F34fc1aF43242FDf1683070D0D] = 10;
    whiteLists[0xA9b1a9d31dc2eBd71FdbfbE3ceF8672eA33Bf176] = 1;
    whiteLists[0x6867bA3cD9d6512bC4460b8270250867E93f0caD] = 3;
    whiteLists[0x9DE693aaACe3169e99e118593ED93F1105C5D544] = 1;
    whiteLists[0xf32633f7cdf7B1CdedD9D5204B2e28b07A2C0086] = 2;
    whiteLists[0x9E52c050DB6aBd8a806aE321ede55b8bBE581053] = 1;
    whiteLists[0xc86FCA1ceC172c35135cF61973aEDdEFf59d6220] = 5;
    whiteLists[0x4c5E67Da77660258831A5c5c816C927aCDc912f8] = 1;
    whiteLists[0xd0471C359f65d6aDcbd69694996Ab49E5E6B6A47] = 12;
    whiteLists[0xe0d9A11C43079a6fd38d4F0F9D27282AbB8c71Cd] = 3;
    whiteLists[0xF34A2A5b2B0cad1d8F57C0A2B37D02e02dE0cee7] = 1;
    whiteLists[0xC71EC410bE298b511B88dC85A366aBa1eB35F0B1] = 2;
    whiteLists[0x94de88cb8EF2199eF8419C77745521bDe802c614] = 1;
    whiteLists[0xc366855eC09108491cD7f0C7cc10BC51e6B42747] = 1;
    whiteLists[0x681B083a5408bAbd8d14b803B7DD6D27080042bC] = 1;
    whiteLists[0x8238CC4fAa4bef568340a057603d3d33b529E508] = 1;
    whiteLists[0xAb35AC8661e0011de2b4C20798410c015EAAf598] = 2;
    whiteLists[0xAecDc6B2bAA5D611796C10ce6ec7CE1Bf37f30bD] = 75;
    whiteLists[0xa309966a8Cd6BAA50e0e4733C51F4345410E4CFD] = 1;
    whiteLists[0x2F26892C01e3944e5Fdf5C0D25DFa420B5340d5f] = 50;
    whiteLists[0xD2CAA23271d2c4CE97389D1B747093D2aCa77E04] = 1;
    whiteLists[0x79aBC0FdC1F0FD8D9D6173FC6af576b13AC2dAAD] = 1;
    whiteLists[0xF6Dc722e8883bDb4374585397F75e02A375A5511] = 1;
    whiteLists[0xF08D11Fb9e1244C50704597A8d92016AC18F148f] = 1;
    whiteLists[0x8de310A3b4205fA4E1361839251b577931eD0F88] = 1;
    whiteLists[0xE95369d9A96eEB1D58f6b5a8bca842F093Cd1d0F] = 37;
    whiteLists[0xC301DA51e766a60ce01Af9114563A16E5f599726] = 2;
    whiteLists[0x821768EA768464C3ec34992fb2008D3e93F1Fc50] = 1;
    whiteLists[0x69095788439E36C8773e03f7Ef4B4D276BD54a2E] = 1;
    whiteLists[0xe0194eBc39615c77aBb633dffE328412ceB789a5] = 10;
    whiteLists[0xe667027b2523441F7274796430FC899d8B3fA6aD] = 1;
    whiteLists[0x751b34aFd48036Ca6c150470A9d92857F941f663] = 1;
    whiteLists[0x659aA01481597f861df78e4e044B0603Fe703A1C] = 1;
    whiteLists[0xB7C3421F32d2C70Ef89734f836Bc750E8f32bbb9] = 17;
    whiteLists[0x23810BdD4A99627A338F08A830FbCAb750F3B382] = 5;
    whiteLists[0x2DeA5Fec4d6Dfe10DE1F8EE6D31E7381D62F4182] = 1;
    whiteLists[0x5Bb203E48437Fd4604b291CBC25aB685Cd84C5CB] = 3;
    whiteLists[0x2876936e2796f50b96c42FdEabcf1ac5bcA66aD6] = 1;
    whiteLists[0x08c58e6565f921E4602A5068F2ad88D4DBeDed9B] = 1;
    whiteLists[0xF69A3f7C94201Cd693734F5197Ee029f8b56BDc3] = 6;
    whiteLists[0x8FECF5Aab94a1c7D323a4c9B2Fd6395E1f30d3f9] = 1;
    whiteLists[0x5a617E10F4F97667f5d3b64df80e22d4a3549f83] = 4;
    whiteLists[0x0FB52572d1792A010DF02f4192cc546A5f4CaCf9] = 5;
    whiteLists[0xbabC54d66D1786f6CC544eC578AfCa7E424b136c] = 4;
    whiteLists[0xbb566F649780dA4e8326f0Bc5C581655eFeea04A] = 2;
    whiteLists[0xb00eC779b29C368953781B54cB231D202f388fbB] = 1;
    whiteLists[0x9eDF8CAe8EEDE49775931c894c38cfec24F9666F] = 3;
    whiteLists[0x30c98Ab8FB66212634bF284F3C13b1e1fe61B3CE] = 1;
    whiteLists[0x31A9AcCa15c07D9ED4981fFb3C497678Ff2DcAF9] = 1;
    whiteLists[0xF7Eb242bCC25517f801e76b74B9B3A61098689e0] = 3;
    whiteLists[0xd84B88D0502C06c53816bebCC955e287e2e91C06] = 1;
    whiteLists[0xd0097AEC3a4bfb0D985fC4967A9e88EC039baA85] = 2;
    whiteLists[0x1Fde6561D65284909B79643d3AAe8957461979D7] = 1;
    whiteLists[0x70FE312d15C17B680f2D63157bc301B345f85bD9] = 3;
    whiteLists[0x36d0eb1dfA4DBb1D81465f91999e172a02B1506D] = 1;
    whiteLists[0x707B503A5A3CEb5543e101c3763De267d11C24b5] = 4;
    whiteLists[0x96b20BEB25e848b02414f7dF2e876571377bdB90] = 2;
    whiteLists[0xB0824a286c4eFf207DAc0AD5151CD93739892318] = 15;
    whiteLists[0x715f087b0402b9f538d62403cc86F77219050492] = 1;
    whiteLists[0x2834dbE76C6F713292870c00d7435Caf7f848445] = 1;
    whiteLists[0x0F01a3ED046627bD96D1edEB7675eB6f78Eb32F7] = 3;
    whiteLists[0xF779f836a3d013D8012207dB88Fc16820F4bd7a0] = 3;
    whiteLists[0x0f24684a78cC40C1edAb468F40eE85112307A066] = 2;
    whiteLists[0x71c2cF4877c991f5B7047636C8ebc04408a8312d] = 7;
    whiteLists[0x96117462f846DDc8c7A7203180974701a28151E0] = 50;
    whiteLists[0x78caB77C52Ca6b3D4611A16a55D8C1d2B2A30DB3] = 4;
    whiteLists[0x782fA3d4994971054899618B76E6e6bf4C357Ebd] = 1;
    whiteLists[0x942c82c889B58B0feB97b3B321B2803b12d2Bb0F] = 1;
    whiteLists[0x920afd31A344926737Ce5dBbD8721DB5837C73f2] = 2;
    whiteLists[0x982a3bF476626a0aDA5C8d13746628d0cE89A645] = 2;
    whiteLists[0xCC5A2891A14696EC36083cF75BCEca043784Db0c] = 5;
    whiteLists[0x28F90cBbF68804a90E61eb506a0D693fed6B9219] = 1;
    whiteLists[0x41881dcbE012b56E7cF3b748DE05395DA9E78174] = 1;
    whiteLists[0x65c14514d5E43f66F17Eb4db0FCAE43601FF663D] = 1;
    whiteLists[0x06FB16421aBC23eDd3855ddD2D0d058e390EE470] = 1;
    whiteLists[0x2C168b9d479936F72320FD4C69497Fe747EA5426] = 2;
    whiteLists[0x60df61DbfB677a9A4d0B9452c890B88E94ff708a] = 3;
    whiteLists[0x16Be803bF9bb745A134410760486f9c65B0221Bc] = 1;
    whiteLists[0x7C91A3dA70F1244B91EfD8aa88b9293f92c19bf8] = 6;
    whiteLists[0xE40C191325460c441aC3A3a96b41D3ca7063BD0F] = 10;
    whiteLists[0xDeB326EDb0cEe642800E0Ba30ADAa7FC472A2Bad] = 1;
    whiteLists[0xc251D1Df3b688D40401bDa8FBdf4f1af52Dfc51F] = 1;
    whiteLists[0x8009641888A2A71a3f69b5DacDaE3F0069008c13] = 2;
    whiteLists[0x1B9fd7798637840dd67aBa65d09CcAb861555F31] = 1;
    whiteLists[0x680879ccC472E47016041390091FD00f6277c8c5] = 1;
    whiteLists[0x57e5A8fDEA03A9Ba0C3c3f45f211F179cF23A094] = 2;
    whiteLists[0x04f7A711459C848eF5aE5E1FbF4C5C20A051627d] = 1;
    whiteLists[0x234DC2857f025f12cB2d4ff6c4c0f4Aa561dC2D3] = 10;
    whiteLists[0xa378ecFCaE0C43370737c3e518B8089d1dCbbeEE] = 1;
    whiteLists[0xB104d713e4cd605F0f964d717DD784CD4b8DD43D] = 1;
    whiteLists[0xe83b248f783425A1bc3639FD7cCFFd698d38Cd05] = 7;
    whiteLists[0x526f78b26436A1A627C9e82880eD9b7afb470B5D] = 2;
    whiteLists[0x61168d47ec95BfF7Bd2fF9Efa5Fe5C1e435841A9] = 1;
    whiteLists[0xaCC19E437699F1541eab315caB5F291DCef43e0d] = 1;
    whiteLists[0xd1a2b9a28bDecb92f6981C6Cd7d1d36821168FF6] = 6;
    whiteLists[0xC6988fbB9ae786e6A4C19C7Ffe75A8F6ef28ad27] = 1;
    whiteLists[0x04218d7d31E90AFC4Ef9cd6E895C3c2617ab9C66] = 3;
    whiteLists[0x1C3ef40d9d0527A609eAAb3b508682e930f9BC0b] = 3;
    whiteLists[0xbB7EAd7A81CF27e2B6CD7877AC54C136D5a2DE25] = 1;
    whiteLists[0x651622a981B8a2fA82cec367b9B9858cdE1BAc6d] = 1;
    whiteLists[0x4FE1d80aE770288F13B2bc4f0736145FDe810fbc] = 1;
    whiteLists[0x54555F26EB336596ec7671A168215BdD9900Bb33] = 1;
    whiteLists[0xb72Dc0513E2b22123c601443e9ba1a7a0324862d] = 10;
    whiteLists[0xadE9086630754563619908beAd432de161a1F558] = 2;
    whiteLists[0xeDA5e3d53E61E2C90451efB714a5a3785Fc1fA4C] = 2;
    whiteLists[0x6F74e29f9661142eDc56557E9372517AE70A37b5] = 1;
    whiteLists[0xbAE244a16e4963FC6996A1c804D81a273c4cA529] = 1;
    whiteLists[0xB598B04397e2569c2Cc53E574773FdCd5F1d86Fa] = 1;
    whiteLists[0x83B6B0F85ba9E5aE56b7A5d73C0fDD12F857087a] = 50;
    whiteLists[0xD8430211a7FE6086bC336A3fF9bdBD6Af5D2433F] = 1;
    whiteLists[0x995fc7687C406A2e0cbAeec7cF83806DB96F9397] = 2;
    whiteLists[0x967D60bCae750189Ab97716fE5c7E95bf76186eC] = 3;
    whiteLists[0x031A56Cb6B1B77882dD0A8E96dC8672f5C7851cF] = 2;
    whiteLists[0xf3BB744bD44618A1B8A2F43E4896202916ED07A7] = 1;
    whiteLists[0x170c1375EE673Ba2e605f35f5e7f0B75b00C58ED] = 1;
    whiteLists[0xfEBB0F6ebF085815Fdcb0c762d1109a03C32894C] = 2;
    whiteLists[0x633a40c4ec81a79f7968EF2eF8f7ebBF91Dcef60] = 1;
    whiteLists[0x37C5b68DBEef032409449Ac7C114CeECbCA8e5C2] = 1;
    whiteLists[0xdfc8705D6f55359A42EbcaDE4dF972f91135Add3] = 1;
    whiteLists[0xd6049ED022A2fd0f2c247eE3371DD324559F077B] = 1;
    whiteLists[0xc5C65ADFB86d6f7504C0B0965101c6373eB1cB7D] = 1;
    whiteLists[0xA43941084B90FD9A491efA65211d0A74C0A1BB76] = 1;
    whiteLists[0x83678FBcbCF8AF5a083027097098faE2734edFD4] = 2;
    whiteLists[0x48884A0f1B677Ee111710305Ab97ee91E6aF9001] = 1;
    whiteLists[0xC15CE16Ac073c37a9802185F6FEb7CE51540246f] = 5;
    whiteLists[0x296c8375CCb543F9C491C4C292ABE4dBeA43A456] = 6;
    whiteLists[0xacDd09E166D3E4e72f8153207776e94704219df7] = 1;
    whiteLists[0x7046c1589a86926d96aB1B90449B8f80501935B9] = 2;
    whiteLists[0xfBB30e28e84df73333cD40e0a8158D539FE11Df0] = 2;
    whiteLists[0xc2168cB6bD431ce55c59906180Adee4Db9D26f09] = 1;
    whiteLists[0xFd2082B62212F1Efe81C50Ff159f3828aA5bA406] = 7;
    whiteLists[0x38E6Fa47232E6c388ca6c605B9B46747e7b97f50] = 2;
    whiteLists[0x39b6486D55Fd15d21e5D73920eECd4A204280aCE] = 6;
    whiteLists[0x298ec114E82221a030cBd5D4a9ecCFeD2044605f] = 11;
    whiteLists[0x362449917e0376c91238960E407e614B9A5F5d92] = 1;
    whiteLists[0xfF8Af00483ef6f31e5A04f48E204B1Eb5F3cE45e] = 2;
    whiteLists[0x8315f6441b90684ccEDC705fB34052fC415fb3f4] = 1;
    whiteLists[0x00c875Bd05Df2B650A91337EC293227F12897D68] = 1;
    whiteLists[0x40304EF4f563a176cac9A793B14504B1521eF1D9] = 1;
    whiteLists[0xC614f4d8D6bB2312659444Dcd60Af79180EDcC59] = 1;
    whiteLists[0x0341ab2d783648be716FA78A48eEDF13f151335e] = 1;
    whiteLists[0xab99D731ba503621F59149208E4C75d2B5DcaDF9] = 2;
    whiteLists[0x90f102d39C38cF45a2A5FB5b19Ef243876841d76] = 1;
    whiteLists[0x4b581a2A411FBC5f0c3D53756BC1778FF96B264C] = 7;
    whiteLists[0xDfdCE5289010b4A6F73fcabAdCF6ec946032950D] = 2;
    whiteLists[0xf5eDC7CF22CA03E8dE88f9Ec78cb4f7eaD7D580F] = 2;
    whiteLists[0x121Cd9D84829E584A6AD76AD8477A066e02BF785] = 3;
    whiteLists[0xaf954A28Dc91F6cbeE25276f76Dff4bD8bbB1b89] = 5;
    whiteLists[0xFA1db0AaE7A4F2aa929Bd0A6212b198bBC6ec267] = 1;
    whiteLists[0x94B4CABD89Cd9B3528230a987397b0B274129d84] = 2;
    whiteLists[0xfaD834762Afeb290F980FAD615CE0Ce3a5047165] = 6;
    whiteLists[0xcFeCC60A12326932065114d48378fBC09EAbBD46] = 1;
    whiteLists[0x24E90E58A84395cFc3547baDa6e0Ae4eA256Ef8C] = 5;
    whiteLists[0x94136131C71F2c0467B67923006D4896fAd2B449] = 1;
    whiteLists[0xbfc58B67BEB8c2b87720F3712F87fe23108775cb] = 5;
    whiteLists[0xa236A4b752E139fb38b3a59c41B9d1456E8B0b03] = 1;
    whiteLists[0x5B2cBF9EA2014e10dD7974067DaC9D2DccA7e070] = 5;
    whiteLists[0x2bB0aDe8D542b15AdA3fFcc1DF0FE84e0e19AaCc] = 1;
    whiteLists[0xB7CCF40fC66415798a00E9FCf4E2d5E93C8c3BC1] = 46;
    whiteLists[0x232c98c3bb6b85Ba130Ea503A6cA256c9Cd6139C] = 1;
    whiteLists[0x79080A53Eb2791aAc16b4C72cDCed10F8D61aBe1] = 1;
    whiteLists[0xe56453FB7E93CB113ECA8d12e1747826A956B7cB] = 3;
    whiteLists[0xe5c7A756E2d3fa77DF35F7E134580fB456259220] = 2;
    whiteLists[0x06C29DA156D707240A30e5E264030dc1452bdFd5] = 1;
    whiteLists[0x0f288fA8dBc0283Ee5be62c0Cb2CD97Ae8f1Abb4] = 1;
    whiteLists[0xc55a14f0150B1Ef5abBB049b474D42845c6ade72] = 1;
    whiteLists[0xF44AACFe5680710c4952d448d65A2F03A09B038d] = 3;
    whiteLists[0x70b4cdfbfeC55F947f6f2538d85aBd3E958B3B4e] = 2;
    whiteLists[0x6f0be2694B5A538de636e8DE8EbF0352c6373726] = 1;
    whiteLists[0xe5cE9Da2870A2Ba91AE8e8b82F3092dee0989959] = 1;
    whiteLists[0xA3b9a82257C93408966ACf43C3715f8E72a9D854] = 2;
    whiteLists[0xe8ec9189B9a8E6FfF4081b02798229e9667B0fF4] = 2;
    whiteLists[0x59523f05D4B2237dE3bf811155A80281E33efE6b] = 1;
    whiteLists[0xe42758403B8A6c02Ff81656856278f74985948Cd] = 3;
    whiteLists[0x8a03Ad434fF771bcb8bC6571eD17f5ca3c4FB003] = 2;
    whiteLists[0x12797b71154fCB311D6C92914729E86253dd7D0D] = 1;
    whiteLists[0xf74e644D030D378Ce753FC45A5d4b0aF06E5d0E5] = 1;
    whiteLists[0xEE6b71B0b9E8a2e7A30F3f966A41C8b414d5e2cC] = 5;
    whiteLists[0x9d12dA08E80CbAFcb6AF0883EFEd678723DD3423] = 1;
    whiteLists[0x409419236872Dfea34a23744C91F2F0342Cc10ca] = 2;
    whiteLists[0x8F742636cfB910d81fbD8aCfFff830f56D454d27] = 2;
    whiteLists[0x678b1e349Dcc497401cF693C0Ac242994f6a0456] = 1;
    whiteLists[0x7e2dd9A34B7D041352226d787C3F575Cf018E64c] = 2;
    whiteLists[0xcac8C59d187f0eaBa4bb37ee35D2f101566a77f2] = 5;
    whiteLists[0x547C6f077786A1a80CD2D6ACFDCa617E2Bce4D33] = 1;
    whiteLists[0xCf9CBB28857A9A916fb9dBA7d6f9775a28605803] = 15;
    whiteLists[0x9f5cF7325B3144fD448eF177611F5E39D54374b6] = 1;
    whiteLists[0xB9635fC9f6A94EA729E4481EcD8372355cC0EA99] = 3;
    whiteLists[0x7582E24F46D688b86dFBb9c56A9a59ac4835CB64] = 1;
    whiteLists[0xAE8eea4F06e9a0179af08A1d55b77577369a3656] = 1;
    whiteLists[0x772b0053852963C644E0686A4be5416b27c4f0fc] = 5;
    whiteLists[0xC8D46eb7881975F9aE15216FeEBa2ff58E55803c] = 20;
    whiteLists[0xd9d8847DB8f4d8e8B0A8f4C4e953C33F2Dfee4ed] = 2;
    whiteLists[0xbe06c20FEa69A7B0bD970e32Bc0830Cc8B698e25] = 6;
    whiteLists[0x07C0226b02092aD6551D8F3e34A67Ce649C5FebD] = 2;
    whiteLists[0x6021D1fccf1A0666D8601C03D61Dff155081F508] = 15;
    whiteLists[0x155E45e90841eab750D5deb3B530665E3d22526C] = 1;
    whiteLists[0x40a7B60e7Faf81C0f1fD9C0eAFd2dF7fdDD5AEC4] = 22;
    whiteLists[0x10291ebc89D06f6060A15EF71112B6E572a35686] = 5;
    whiteLists[0x156D592b118046C8B9d09747e900DA94411c185F] = 1;
    whiteLists[0xB3Ed12AB446e33F257728439b875703106416DAC] = 25;
    whiteLists[0x7dcBbA0E5043611bb53A302971d87BBaA391FD29] = 50;
    whiteLists[0x4CbBa6a6d3B584931709240fBc50D4994F7D6931] = 22;
    whiteLists[0xba26B5984fc781364fF3EdA95877423640fC984f] = 1;
    whiteLists[0xA60aB65B7Fc55F5526Af0b8AB038dc621606C8df] = 10;
    whiteLists[0xA3f4933CdA899Ea6b4406dfB627530212C3d0202] = 2;
    whiteLists[0x379F506c1CC374AEa64E20fA08608Cd2ec06c488] = 2;
    whiteLists[0xD4CF0C437Ce9bC6fb237eC5238946fde1A6d79CB] = 3;
    whiteLists[0x4dD1bA1173071585Fc51Cf0bb4735473E33Dc495] = 3;
    whiteLists[0x3e81D20350F59f0a182FCf6831E79251810e42c4] = 1;
    whiteLists[0xee65d2F952943Bac49C2Ff2235f12087092018AE] = 8;
    whiteLists[0xD23513118149888B253657a13Cb7256D226b377A] = 1;
    whiteLists[0x3629D8680fBBA6136a1D8c2c7d7cF7FE97ED3e3f] = 1;
    whiteLists[0xDeFd3e3fE098878Ee9e48A309cD35b0d8A5f363c] = 2;
    whiteLists[0xA2c6499d42de5F4E2D676da0F63bE652A8433B7D] = 50;
    whiteLists[0xa181a573ef5FA1404D852CdFF989034Db0d0FCfa] = 1;
    whiteLists[0xd9381B1D87AD13A3c473CD6de361B161D570535a] = 1;
    whiteLists[0x4CD87C603596c5347e250e8B0A4016e8085d49ca] = 10;
    whiteLists[0x3662E92F8BB9826d597c8068393c93b28887F567] = 5;
    whiteLists[0x92cDfc5a11e7D9338EDDefd082F6c7fdc099a4B6] = 2;
    whiteLists[0x0b55cb441d56aa9aaA384A771f8a2C3d9274e1A9] = 3;
    whiteLists[0x6b5D2fb4a7e970c1bacBe80cEB20f025618125AE] = 5;
    whiteLists[0xf158a6B343fA39bF35E3414202086A16283491cC] = 1;
    whiteLists[0xfe19A78eC261bF9b032d2b6422Cd8FA33f75a988] = 11;
    whiteLists[0x45e3050Aa3A13B95fDdE1b4fd426F3B62A71e908] = 1;
    whiteLists[0x94837950E4E78d1B1510D266dfDC75720d428AA3] = 3;
    whiteLists[0x4aC5A17b758C3A3C93214e770e35C4367ECFF8b6] = 50;
    whiteLists[0x11F6a17DefaF666c730Ac263B770CCAe87969af1] = 1;
    whiteLists[0x69ba1c096A6E0C70592A03F17618d3b1E5B3164c] = 3;
    whiteLists[0xB91Ac8933F8941B35186E2516e9faa95CAf5f325] = 1;
    whiteLists[0x622F9f2a4F4caEb824a799e25Cceeab87FC11Be7] = 14;
    whiteLists[0xB734Ee94e4Ab11Dd94188eD2AE1e7c4E65feB18e] = 1;
    whiteLists[0x048054f6e13BB29c6453a12337999faAf8ebD72F] = 3;
    whiteLists[0x6f2Dc1484C9E49729E3202dd1e1070d5868A4d5F] = 10;
    whiteLists[0x6cbC0ee729408374881f052b69950f2443f4E984] = 1;
    whiteLists[0xf56e809AD3114D3c07a0196EE3e518F67B9c7B32] = 20;
    whiteLists[0x36713Ec3600CBE45c62F6Bcb3BC1a410A2Ae6028] = 9;
    whiteLists[0x9aBA7cE52B550CbB4fF0ae99F64532De8CE6C59F] = 53;
    whiteLists[0xd262f4b46f93326127aebD8173b086E7B975c71c] = 2;
    whiteLists[0xEb5FcaE81f91A01688a3a4b18396E25aB11B20E1] = 2;
    whiteLists[0x8E671014220a13f228849773A64A609Caca52414] = 5;
    whiteLists[0xd38AA8a1d619bAB43E55eD5D0f4a65053e09047A] = 19;
    whiteLists[0x9f9a52C123373a8D383554C0c9Ed0536D97126f5] = 5;
    whiteLists[0x588edA22753F75f0bf0de16b1B1d7c23d197cDcb] = 1;
    whiteLists[0x3F4AcF7c22d15896c9628F635FBcD40ef61512aA] = 2;
    whiteLists[0x4C042Ce1dcAb438d413C5DE69e0944470923BdE8] = 1;
    whiteLists[0xFbF8E63963E371D355C1D25563ad52376E1B70D9] = 1;
    whiteLists[0x08bc5840cddd062C0d9A82A38cF4F85256b67F98] = 1;
    whiteLists[0x7c361828849293684DdF7212Fd1d2Cb5f0aADe70] = 40;
    whiteLists[0xbBa5cd2c00303B8FACEdE230EDC02580FD963Bbc] = 1;
    whiteLists[0x7CF7aEc97D2e2A3534c7086149628BB1424C4fA0] = 1;
    whiteLists[0x6e99223c9b9e3F0d63ACe28c1bF15Bb7013716f0] = 1;
    whiteLists[0x9CE183d3DDe5c487A076fC63b71781908cDeaA2E] = 1;
    whiteLists[0x866a51F32b457333A20AA2783BDC023a7e11A78D] = 1;
    whiteLists[0xe70561a60E00A4D3a1442Aae8E917CE70547d372] = 3;
    whiteLists[0x1dBCF071f0491f67FA13ed972a24c7c0bf3Cad14] = 3;
    whiteLists[0x004C3CC9d21626b6716a7eD361D5082Fe142C04B] = 2;
    whiteLists[0xB5bD344223630b9451772a6e6aa80746DF286291] = 1;
    whiteLists[0x19Aa87c7EBAA7D7e58bbCf395999D9BAfe57804f] = 3;
    whiteLists[0x8A6E76e0B2E1d58b7A9c970202F9B5e28c1170d6] = 1;
    whiteLists[0xdBB16c89B17C7B9F20f74D2D5c4ede533f3721A2] = 3;
    whiteLists[0x19Ca1b8Baba413Af4Ee81163D3996212f28FDEfe] = 16;
    whiteLists[0x8a41713D9584EA1830E395B492198Cce5E4127Ef] = 50;
    whiteLists[0xCD876a3d0bDF0f67778cc8E5999eF9F170ec3A8c] = 30;
    whiteLists[0x95724095503Ac0757b9e5EC23B2F60Bc6B736715] = 5;
    whiteLists[0x387cB8dDb8436a56b889CdccA5410Ef0c9F2a3E8] = 70;
    whiteLists[0x5Df3F99BD0Ca00d49FF45Bd4014A2CA3cC859f6c] = 1;
    whiteLists[0x616B5804aD2b3F89DacE9611bAC56A64a72E5AD0] = 4;
    whiteLists[0x935E8bf9D14e48397DAFcd73A5da8c086C16268E] = 2;
    whiteLists[0xC730a5933e11403aB3661F3883Ae654Ad752eE08] = 1;
    whiteLists[0x3504F0F7515b5DDe2538aB9F0227D2B6Ed118a81] = 1;
    whiteLists[0xEDd30dd9afAb86D55dAB764bA1d34D43426A8e83] = 1;
    whiteLists[0xD33608Ba4f17Ab5DB68Ad29A70E90D0F36572515] = 2;
    whiteLists[0xd76e7Ab7F5A0a57634f78C4D9261DfeF6503eF73] = 46;
    whiteLists[0x46E944FDF72E16245995Fa114E7C84733aBB2c73] = 10;
    whiteLists[0x8a4CcFD0d6b3a0559ba2666d9DD9B0702181Fe62] = 1;
    whiteLists[0x85FF449B5b135a74710ADA66F670Bd143Ce6B657] = 1;
    whiteLists[0x63e0AE9b3d93058eeE80C485E5e9935a8C59e553] = 1;
    whiteLists[0xD676f17324E6a83e5Cfb3DB30e3229600941eeA1] = 38;
    whiteLists[0xFFCFed54f9E4C89189E95d4686DBfA29Bd7D5E4b] = 3;
    whiteLists[0x05cD059556376577e2e237A62d1C789eCA59c84C] = 5;
    whiteLists[0x0347dCA92ca398b8d55476b74F8776615E1F865c] = 5;
    whiteLists[0x55b432d98104b57BD77D5A22912cA16081Cce043] = 3;
    whiteLists[0xaB1D308377Cc2BEE33B7c8150c1FD394Fff2758d] = 1;
    whiteLists[0xF9d7d3ff72516A89945A52DCea78E46282c1bEC9] = 1;
    whiteLists[0x2f9FE181640d065Ddd0C4d040fE3c10c365CE434] = 37;
    whiteLists[0x377a5C8797Ce905f647bC0532d4c6791E9F263C9] = 1;
    whiteLists[0x409f29238cC6f2505cb7c8Cf3F45728f060582D1] = 10;
    whiteLists[0xD8Bd4442eFA0FFeA272dd2C0211959b4e9D0A543] = 1;
    whiteLists[0xbEcbe02a2b90e9c9B50cD972F357170A6185dbC5] = 2;
    whiteLists[0x0B0EddCB270Ae899b7bD5126B2EAB43887BB4603] = 10;
    whiteLists[0x2c89a60122d67DFd7C1Fd5865289dBe59ae963eE] = 4;
    whiteLists[0x6327C4984Ce4343De44A91516570b68863458C65] = 1;
    whiteLists[0xbeC5424b07db33A86bbDFEc8Fd975f3fcC7D0951] = 11;
    whiteLists[0x8F1EbD621358Eb557f9353BbDF3eEB590611b90a] = 1;
    whiteLists[0x86Eb9bE54F116fac3A3A2Dea68CE554d498064dd] = 1;
    whiteLists[0x6Aa58dc635953F62D2454fafbad883C57fE063B9] = 50;
    whiteLists[0x767f09805B0457cdecf115D523313215a7FF6227] = 4;
    whiteLists[0xB87E5E8299aC6f10F0452446D9D4F4D2C99a5dD8] = 2;
    whiteLists[0x37116b36e5434Bff03F4aCE974F1458d1cC2463d] = 10;
    whiteLists[0xaf09f09E72e28ab9dA53f09dd9D3d3f7E0AfEefa] = 1;
    whiteLists[0x7c76C712cB12adc4ab153062124B05B8E597C622] = 4;
    whiteLists[0x87EBdCdB2D63c5E37D2046DD50610F4E530609C9] = 1;
    whiteLists[0xb10BD34199663ebfBF20D740959D773e34030B59] = 50;
    whiteLists[0x25691ddCbF0Be4caE38f720bFA8e0f6de4A03817] = 1;
    whiteLists[0x5535621feEE05C7142a8ea4c1Ce89a78FcE72a60] = 16;
    whiteLists[0x10ae6E1D7E192514a3B8A76F74fA298d378B0f35] = 50;
    whiteLists[0x10d4E76c556DCB9B59450D101bAF9287a42F4483] = 5;
    whiteLists[0x5b7bCEcE3B0c49E1D4aFb70F491044749f1AfBd3] = 5;
    whiteLists[0xD91672A7e9EA8bF163F52a8dE90b2a98aFBee032] = 2;
    whiteLists[0x905b8655516Aabe7AAfD2567A1844CE02d13c3eA] = 1;
    whiteLists[0xbd0b24b8f6F0Cc9Dd137B5D98B4B7C8c3d637730] = 1;
    whiteLists[0xa859Ca66A4FD82FEb8b8513bB590A5FF439f793D] = 1;
    whiteLists[0x2fD9BF884C83DFa03CAE150FC0Bc779C9433697C] = 6;
    whiteLists[0x28BcEE52949e347f7569098F5eDa3068002742a7] = 1;
    whiteLists[0x0712D275DC6020af8D29a1f9247309a652c41095] = 1;
    whiteLists[0x2418Cf3404A91D4C0E24b919BE8b73C5D8D4c1f7] = 4;
    whiteLists[0xc2ec094e12BEEE12544c6307D78a30d1f30fc93B] = 1;
    whiteLists[0x64d5fbC5983BcC3e8651907B1C5cA1A1a06301Dc] = 5;
    whiteLists[0x46f602311267AC6046C091b5E0DA5A40B07DBAd5] = 9;
    whiteLists[0xC7861aFe67DfB005636f41B25B6354a370958E77] = 1;
    whiteLists[0xDE3787CB949F93A58e98e74200DFCEddc2C3A101] = 1;
    whiteLists[0x7E9a7a4511EF76f78daF06F3841eC61DeA7bcfE1] = 1;
    whiteLists[0xDee99166e3aed9300F623A05E086C9673F1c4D41] = 2;
    whiteLists[0xC5Fe6e367742Af4d3A545d073DD310fa4842CD95] = 12;
    whiteLists[0x683D98408cbd81D3C94028Dd34a8De29dB49b9D5] = 2;
    whiteLists[0x8Bb613E36fA47f55aF41Ab662b64E3c27427794D] = 1;
    whiteLists[0x32aFFDEfa28726C81839E75083AfD8b39eF48110] = 2;
    whiteLists[0xbb8dC2B41448EfdAA2982C74e23944C458e458Ad] = 3;
    whiteLists[0xD42e80ec94D74a5FA73A4F16f30f6D311e64F9F6] = 2;
    whiteLists[0x6F32f64aAaB35Fbaf9E53c443e2CBa86386FB611] = 1;
    whiteLists[0xA5a9Dc0B62Ab6763bbaa64697Fc085Ff7F9CaDaf] = 1;
    whiteLists[0x1a68Eca989F04f8CE3C150932154f5A44838f83a] = 4;
    whiteLists[0x305C0AB34C48A482928CA08d4e1C60498D6d9b6d] = 1;
    whiteLists[0x7424631B2430859F74907e0e5814c7e44fb2A0f1] = 1;
    whiteLists[0xB98073Ad3f605051435a6f80EC18E2c80D5cB0de] = 5;
    whiteLists[0x66d44C6a354ebC4c21F5D6AbF48d1F7317D43A1b] = 31;
    whiteLists[0x62Bdf2457dB52AbAD40d530ea4A340eAEEF317b4] = 1;
    whiteLists[0xeba2fc4aC924Ce58630Ac854303c01435E065ED8] = 1;
    whiteLists[0x7daF0f8F8069Aa9f66Ad33a20da7733C8F0a1A65] = 1;
    whiteLists[0x9Cf9abB4765fF1c5AFFb35154C3D68D082EBE3a8] = 1;
    whiteLists[0x0AbA38De15c2e82ba5313188a63d375707Edd758] = 7;
    whiteLists[0x3a9ed3Bcf95371292b47470fB3E0A80D2fe62B83] = 4;
    whiteLists[0x2758cB77247B1267aA219D4de5f6af8B756a233B] = 1;
    whiteLists[0x8A0c098e896fa309828A35Ce714403D23cBBCf3A] = 2;
    whiteLists[0xB7E214d77F9AE82ebc23B59136e21B39c55db4aa] = 1;
    whiteLists[0x732cD428eD0fB67aE575fE50e78eF5a87fb95083] = 10;
    whiteLists[0x82B22CB424F152ACcBEC3810949e40F89d27EDbB] = 1;
    whiteLists[0x31571Fe4368683DDe63bf633CDE1209DA8aA8001] = 1;
    whiteLists[0x6eD3E49b4FCC9A0c5b22ab06B74512d1f2C8d531] = 2;
    whiteLists[0x35fa44C4F6C1b273E3438Ce3Fd360989517c16DA] = 1;
    whiteLists[0xE0D2Feb394CD2c23D4084a578Ae0a2e93f9b0659] = 1;
    whiteLists[0xA982B382c8590b46f3fD28D45CEdBb351bB4ED9f] = 2;
    whiteLists[0xC0fC5A9777d4B4789F5d5ed86201004CE91cb8Fe] = 3;
    whiteLists[0x1d61d6824c90c60Af27A48430Be4aBB8D995E1aD] = 5;
    whiteLists[0x4Df05c0a8354d4b8f442239eC7935e225D0aECab] = 3;
    whiteLists[0x431b5DDB0AcE97eBC3d936403ea25831BaD832B6] = 74;
    whiteLists[0x4147c686BD7d4a78264D57Fd9E5f77aA5eB2723f] = 5;
    whiteLists[0xa6FA4bDD6B96A7b45Bad16c3049a0ADA6c0d0607] = 2;
    whiteLists[0x85531A2fE3C5A654962CB507362C0db38897367D] = 1;
    whiteLists[0x02443b63543E28A0b2f0581Af3BBb3A6F63f7d7B] = 10;
    whiteLists[0x8C69c3e0d6f4A163249D88f299586a43279c599d] = 1;
    whiteLists[0xee48834b904A8C0597B05be3d645d62b157823dC] = 1;
    whiteLists[0x6231656c19eb554e922a0C9Fdf2c1b788691B6F3] = 12;
    whiteLists[0x35652615013f9D6027d2DeAd283Af0dDDf4339b1] = 3;
    whiteLists[0xA734252647965C9368B4A78027c86100bEa4D302] = 1;
    whiteLists[0x39c23b3436E3D9C9DAeBC56bDc526D350E1C5B3b] = 2;
    whiteLists[0x04e9D10BdB8aF4f58a42C709baccECAa9dEce095] = 1;
    whiteLists[0xca1312207b0cAd0fBcf2134D8B8756dCD4C78f78] = 2;
    whiteLists[0x7769dceB749E3d135080dc8348e18a606142D5Eb] = 22;
    whiteLists[0x3B8f4FEc0853F8ba735C727DDD6F097943DD87fE] = 4;
    whiteLists[0xa7E2Ece38adb8Eb8fa6d8f062e4cC037BF561d59] = 3;
    whiteLists[0x1B0D16D92C9029782D83004158F5317258D0d177] = 1;
    whiteLists[0x6A533bAa01B5bfD8867bc0314dd823005DC31d1B] = 10;
    whiteLists[0x6a64A679124103f666D2396D94CC8AC37C05cf0F] = 1;
    whiteLists[0x918b36924095610e859cB1F4A9049dA990f1bcD7] = 3;
    whiteLists[0xA50Ae8fAc80D94e13ED634aF12b7bD59B935FEDD] = 50;
    whiteLists[0x540f3Bf895fF2D10Db9D9Fdf5CD39c8313fD8d6c] = 1;
    whiteLists[0x3b98e55a068E94DadDB89DdaFdb82F24803bEBE7] = 2;
    whiteLists[0x50ae8B6A0d4f0440b49ddBFc1744e8FEd91B9d69] = 150;
    whiteLists[0xAd249CfC3ff356f271C3CB684952c2f9D18bCE76] = 40;
    whiteLists[0xc93E84E7b266619e21a07641c8A6274909Dc4DB8] = 2;
    whiteLists[0x17ED3d0eC1Ee0C7324B4fFf0fa8E3499EE9C02ff] = 1;
    whiteLists[0xcc2470fF37E85C2f3A9bc15D53f35a85D960F19B] = 5;
    whiteLists[0xAbd33421B0F67366a4a6a5489e4Ba84D34511a2A] = 1;
    whiteLists[0xBc90fd53Cab778Bf9B0b718ddeD532DD40AFFAca] = 1;
    whiteLists[0x7681E6d1d58Ada5d68AE6e60D9a0972Ef8e246E6] = 1;
    whiteLists[0xf7E5bdc31a6952B359CA71A6BBD456c16F43Ec0C] = 15;
    whiteLists[0xDc9C5e34959eC3643AF1e1D34A83D6b251AAb1eF] = 1;
    whiteLists[0xBa64442497f31ab5eC8b6540Ac847B0BeaB0d647] = 2;
    whiteLists[0xACbFec68D1266F02baDEB8e791a37c38Fdf66f5a] = 1;
    whiteLists[0xA44D898175033A13aDe93b23aeeC500B39352Fda] = 2;
    whiteLists[0xc391245DA8d78ad7B5E52CE3f39e10Ed30807bb4] = 1;
    whiteLists[0x192fDeb5CfA2dD54A9872806eC43A50ef7FDBf37] = 7;
    whiteLists[0xF4B49aFE47c60Cb25d8c7FeBEE1Bef5E50802a97] = 1;
    whiteLists[0x01cD5cC05969c2C8bfEA0Ff8D01aA21E2F240967] = 6;
    whiteLists[0xAA34856D46076D8F15dd17fdBdA0e70f1FD83556] = 10;
    whiteLists[0x02Ccbc31E948e09870cc6DE237B3fA8597c2Bb02] = 1;
    whiteLists[0x6901A5003E91c0C067F668b518441cD5a8581878] = 19;
    whiteLists[0x9a11f87579b70Aa9e4fC067a54ACdB2BfbC3522d] = 1;
    whiteLists[0xCB98684F451Eac7B710EDE8C850f8dc99F13739e] = 50;
    whiteLists[0x51E914DB8be2818e0D9E682e2b06eEa90A05B494] = 7;
    whiteLists[0xD0D0dabC420aaaA55d40696e77750F65ca12deb5] = 25;
    whiteLists[0x896d3f6afC1140CD06A3811cAb5790e6a4546c9F] = 2;
    whiteLists[0x0A591E6852AAbd254f533Af8eBDADCe411de6bb8] = 1;
    whiteLists[0x57d1F017B3a2f4A699f8446F0Db14999B908acB7] = 1;

    _whiteListSet();
  }

  function _whiteListSet() internal {
    whiteLists[0x4D6f225B205944c5Ad099Bd85e64986F7F8E2B82] = 2;
    whiteLists[0x0b7fa87681047d70647f3A5c8A646b8935E24b82] = 1;
    whiteLists[0x6599f83c1B154E2eC8229Fb12C9057e236705Db2] = 1;
    whiteLists[0x592bad2Be0C7ba15474ADF693267a26Ecf751aec] = 1;
  }

  function withdraw() external onlyOwner {
    uint256 balance = address(this).balance;
    payable(ownerAddress).transfer(balance);
    uint256 gaiaBalance = IERC20(PGAIAAddress).balanceOf(address(this));
    IERC20(PGAIAAddress).transfer(ownerAddress, gaiaBalance);
    emit withdrawRun(balance);
  }

  function reserveGaiaLands(
    address _to,
    uint256 _reserveAmount,
    uint8[] memory _size,
    uint32[] memory _x,
    uint32[] memory _y,
    uint32[] memory _mintId,
    string[] memory _type,
    string[] memory _location,
    uint256 toSupply
  ) external onlyOwner {
    require(_to != address(0), 'Can not send to zero address');
    uint256 supply = totalSupply();
    require(supply == toSupply, 'Sorry, you must mint again later');
    require(
      _reserveAmount > 0 && _reserveAmount <= gaiaLandReserve,
      'Not enough reserve left for team'
    );
    require(
      supply.add(_reserveAmount) <= MAX_GAIALANDS,
      'Reserve would exceed max supply of Lands'
    );
    for (uint256 i = 0; i < _reserveAmount; i++) {
      uint256 mintIndex = totalSupply();
      require(mintIndex == (toSupply + i), 'Sorry, you must mint again later');
      ownerMap[supply + i] = MapData({
        size: _size[i],
        mintId: _mintId[i],
        x: _x[i],
        y: _y[i],
        owner: _to,
        landType: _type[i],
        listing: false,
        location: _location[i]
      });
      _safeMint(_to, supply + i);
    }
    gaiaLandReserve = gaiaLandReserve.sub(_reserveAmount);
  }

  function setProvenanceHash(string memory provenanceHash) public onlyOwner {
    GAIALANDS_PROVENANCE = provenanceHash;
    emit provenanceHashSet(provenanceHash);
  }

  function setBaseURI(string memory baseURI) external onlyOwner {
    _setBaseURI(baseURI);
  }

  function flipSaleState() public onlyOwner {
    saleIsActive = !saleIsActive;
  }

  function setSaleDate(uint256 _date)
    external
    onlyOwner
  {
    saleDate = _date;
  } 

  function tokensOfOwner(address _owner)
    external
    view
    returns (uint256[] memory)
  {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 index;
      for (index = 0; index < tokenCount; index++) {
        result[index] = tokenOfOwnerByIndex(_owner, index);
      }
      return result;
    }
  }

  function getMapData(uint256 _id)
    external
    view
    returns (MapData memory)
  {
    require(
      _id >= 0 && _id < totalSupply(),
      'ID must not exceed than total supply'
    );
    return ownerMap[_id];
  }

  function tokenLicense(uint256 _id) external view returns (string memory) {
    require(_id < totalSupply(), 'CHOOSE A GAIALAND WITHIN RANGE');
    return LICENSE_TEXT;
  }

  function lockLicense() public onlyOwner {
    licenseLocked = true;
    emit licenseisLocked(LICENSE_TEXT);
  }

  function changeLicense(string memory _license) public onlyOwner {
    require(licenseLocked == false, 'License already locked');
    LICENSE_TEXT = _license;
  }

  function mintGaiaLand(
    uint256 numberOfTokens,
    uint256 numberOfGoodLands,
    uint256 numberOfRegularLands,
    uint256 coinRate,
    uint8[] memory _size,
    uint32[] memory _x,
    uint32[] memory _y,
    uint32[] memory _mintId,
    string[] memory _type,
    string[] memory _location,
    uint256 toSupply
  ) external payable {
    require(saleIsActive, 'Sale must be active to mint GaiaLand');
    require(saleDate < block.timestamp, 'You can not mint yet');
    require(totalSupply() == toSupply, 'Sorry, you must mint again later');
    require(
      numberOfTokens > 0 && numberOfTokens <= MAX_GAIALANDS_PURCHASE,
      'Can only mint 200 tokens at a time'
    );
    require(
      totalSupply().add(numberOfTokens) <= MAX_GAIALANDS,
      'Purchase would exceed max supply of Gaias'
    );
    require(
      msg.value.mul(coinRate) >=
        (gaiaGoodLandPrice.mul(numberOfGoodLands) +
          gaiaRegularLandPrice.mul(numberOfRegularLands)).mul(1e24),
      'Ether value sent is not correct'
    );

    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 mintIndex = totalSupply();
      require(mintIndex == (toSupply + i), 'Sorry, you must mint again later');
      if (totalSupply() < MAX_GAIALANDS) {
        ownerMap[mintIndex] = MapData({
          size: _size[i],
          mintId: _mintId[i],
          x: _x[i],
          y: _y[i],
          owner: msg.sender,
          landType: _type[i],
          listing: false,
          location: _location[i]
        });
        _safeMint(msg.sender, mintIndex);
      }
    }
  }

  function mintGaiaLandToken(
    uint256 numberOfTokens,
    uint256 numberOfGoodLands,
    uint256 numberOfRegularLands,
    uint8[] memory _size,
    uint32[] memory _x,
    uint32[] memory _y,
    uint32[] memory _mintId,
    string[] memory _type,
    string[] memory _location,
    uint256 toSupply
  ) external {
    require(saleIsActive, 'Sale must be active to mint GaiaLand');
    require(saleDate < block.timestamp, 'You can not mint yet');
    require(totalSupply() == toSupply, 'Sorry, you must mint again later');
    require(
      numberOfTokens > 0 && numberOfTokens <= MAX_GAIALANDS_PURCHASE,
      'Can only mint 200 tokens at a time'
    );
    require(
      totalSupply().add(numberOfTokens) <= MAX_GAIALANDS,
      'Purchase would exceed max supply of Gaias'
    );
    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 mintIndex = totalSupply();
      require(mintIndex == (toSupply + i), 'Sorry, you must mint again later');
      if (totalSupply() < MAX_GAIALANDS) {
        ownerMap[mintIndex] = MapData({
          size: _size[i],
          mintId: _mintId[i],
          x: _x[i],
          y: _y[i],
          owner: msg.sender,
          landType: _type[i],
          listing: false,
          location: _location[i]
        });
        _safeMint(msg.sender, mintIndex);
      }
    }
    uint256 _price = (gaiaGoodLandPrice * numberOfGoodLands + gaiaRegularLandPrice * numberOfRegularLands) * (10**36) / gaiaUSDC;
    require(
      IERC20(PGAIAAddress).transferFrom(msg.sender, address(this), _price)
    );
  }

  function selectedMintGaiaLandToken(
    uint256 numberOfTokens,
    uint256 numberOfGoodLands,
    uint256 numberOfRegularLands,
    uint8[] memory _size,
    uint32[] memory _x,
    uint32[] memory _y,
    uint32[] memory _mintId,
    string[] memory _type,
    string[] memory _location,
    uint256 toSupply
  ) external {
    require(saleIsActive, 'Sale must be active to mint GaiaLand');
    require(totalSupply() == toSupply, 'Sorry, you must mint again later');
    require(
      numberOfTokens > 0 && numberOfTokens <= MAX_GAIALANDS_PURCHASE,
      'Can only mint 200 tokens at a time'
    );
    require(
      totalSupply().add(numberOfTokens) <= MAX_GAIALANDS,
      'Purchase would exceed max supply of Gaias'
    );
    for (uint256 i = 0; i < numberOfTokens; i++) {
      uint256 mintIndex = totalSupply();
      require(mintIndex == (toSupply + i), 'Sorry, you must mint again later');
      if (totalSupply() < MAX_GAIALANDS) {
        ownerMap[mintIndex] = MapData({
          size: _size[i],
          mintId: _mintId[i],
          x: _x[i],
          y: _y[i],
          owner: msg.sender,
          landType: _type[i],
          listing: false,
          location: _location[i]
        });
        _safeMint(msg.sender, mintIndex);
      }
    }
    uint256 _price = (gaiaGoodLandPrice * numberOfGoodLands + gaiaRegularLandPrice * numberOfRegularLands) * (10**36) / gaiaUSDC;
    require(
      IERC20(PGAIAAddress).transferFrom(msg.sender, address(this), _price)
    );
  }

  function setGoodPrice(uint256 newPrice) external onlyOwner {
    gaiaGoodLandPrice = newPrice;
    emit goodPriceSet(newPrice);
  }

  function setRegularPrice(uint256 newPrice) external onlyOwner {
    gaiaRegularLandPrice = newPrice;
    emit regularPriceSet(newPrice);
  }

  function getTokenPrice() public view returns(uint) {
    address pairAddress1 = address(0x885eb7D605143f454B4345aea37ee8bc457EC730); // QuickSwap GAIA/DAI PairAddress
    IUniswapV2Pair pair1 = IUniswapV2Pair(pairAddress1);
    (uint Res0, uint Res1, ) = pair1.getReserves();
    uint price1 = Res1 * (10**18) / Res0;

    address pairAddress2 = address(0xCD578F016888B57F1b1e3f887f392F0159E26747); // SushiSwap USDC/DAI PairAddress
    IUniswapV2Pair pair2 = IUniswapV2Pair(pairAddress2);
    (uint Re0, uint Re1, ) = pair2.getReserves();
    uint price2 = Re0 * (10**30) / Re1;
    return price1 * price2 / (10**18);
  }

  function openTrade(
    uint32 _id,
    uint256 _price,
    uint32 duration,
    string memory unit,
    uint32 mintId
  ) external {
    require(saleIsActive, 'Sale must be active to mint GaiaLand');
    require(saleDate < block.timestamp, 'You can not trade yet');
    require(ownerMap[_id].owner == msg.sender, 'sender is not owner');
    require(ownerMap[_id].listing == false, 'Already opened');
    ownerMap[_id].listing = true;
    auctions[_id] = Auction({
      duration: duration,
      price: _price,
      unit: unit,
      creator: msg.sender,
      id: _id,
      mintId: mintId,
      newOwner: payable(address(0)),
      preOwner: payable(msg.sender),
      startTime: block.timestamp,
      endTime: block.timestamp + duration,
      status: false
    });
  }

  function closeTrade(uint256 _id) external {
    require(saleIsActive, 'Sale must be active to mint GaiaLand');
    require(saleDate < block.timestamp, 'You can not trade yet');
    require(ownerMap[_id].owner == msg.sender, 'sender is not owner');
    require(ownerMap[_id].listing == true, 'Already closed');
    ownerMap[_id].listing = false;
    delete auctions[_id];
  }

  function buy(uint256 _id) external payable {
    require(saleIsActive, 'Sale must be active to mint GaiaLand');
    require(saleDate < block.timestamp, 'You can not buy yet');
    _validate(_id);
    require(ownerMap[_id].listing == true, 'Already closed');
    require(auctions[_id].price <= msg.value, 'Error, price is not match');
    address _previousOwner = ownerMap[_id].owner;
    address _newOwner = msg.sender;

    uint256 _commissionValue = msg.value.mul(25).div(1000);
    uint256 _sellerValue = msg.value.sub(_commissionValue);
    payable(_previousOwner).transfer(_sellerValue);
    _transfer(_previousOwner, _newOwner, _id);
    ownerMap[_id].owner = msg.sender;
    ownerMap[_id].listing = false;
    delete auctions[_id];
  }

  function buyToken(uint256 _id, uint256 _price) external {
    require(saleIsActive, 'Sale must be active to mint GaiaLand');
    require(saleDate < block.timestamp, 'You can not buy yet');
    _validate(_id);
    require(ownerMap[_id].listing == true, 'Already closed');
    require(auctions[_id].price <= _price, 'Error, price is not match');
    address _previousOwner = ownerMap[_id].owner;
    address _newOwner = msg.sender;

    uint256 _commissionValue = _price.mul(25).div(1000);
    uint256 _sellerValue = _price.sub(_commissionValue);

    require(
      IERC20(PGAIAAddress).transferFrom(
        msg.sender,
        address(this),
        _commissionValue
      )
    );
    require(
      IERC20(PGAIAAddress).transferFrom(
        msg.sender,
        _previousOwner,
        _sellerValue
      )
    );

    _transfer(_previousOwner, _newOwner, _id);
    ownerMap[_id].owner = msg.sender;
    ownerMap[_id].listing = false;
    delete auctions[_id];
  }

  function transferLand(uint256 _id, address _to) external {
    require(saleIsActive, 'Sale must be active to mint GaiaLand');
    require(saleDate < block.timestamp, 'You can not transfer yet');
    require(_to != address(0), 'Can not send to zero address');
    require(ownerMap[_id].owner == msg.sender, 'sender is not owner');
    if (ownerMap[_id].listing == true) {
      ownerMap[_id].listing = false;
      delete auctions[_id];
    }
    transferFrom(msg.sender, _to, _id);
    ownerMap[_id].owner = _to;
  }

  function _validate(uint256 _id) internal view {
    require(ownerMap[_id].listing == true, 'Item not listed currently');
    require(msg.sender != ownerOf(_id), 'Can not buy what you own');
  }
}