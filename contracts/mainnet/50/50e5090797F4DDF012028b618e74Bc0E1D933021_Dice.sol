/**
 *Submitted for verification at polygonscan.com on 2022-07-13
*/

// Sources flattened with hardhat v2.9.5 https://hardhat.org

// File contracts/lib/reentrancyguard.sol

// SPDX-License-Identifier: MIT
// An example of a consumer contract that relies on a subscription for funding.
pragma solidity 0.8.9;

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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    mapping(address => bool) public games;

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

    function gameRole(address _sender) public view returns (bool) {
        return games[_sender];
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyGame() {
        require(gameRole(_msgSender()), "GameRole: caller is not the game");
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

    function addGameRole(address _game) public virtual onlyOwner {
        require(_game != address(0), "GameRole: gameRole is the zero address");
        games[_game] =  true;
    }

    function removeGameRole(address _game) public virtual onlyOwner {
        games[_game] = false;
    }
}


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


abstract contract VRFConsumerBase is VRFRequestIDBase {
  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBase expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomness the VRF output
   */
  function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;

  /**
   * @dev In order to keep backwards compatibility we have kept the user
   * seed field around. We remove the use of it because given that the blockhash
   * enters later, it overrides whatever randomness the used seed provides.
   * Given that it adds no security, and can easily lead to misunderstandings,
   * we have removed it from usage and can now provide a simpler API.
   */
  uint256 private constant USER_SEED_PLACEHOLDER = 0;

  /**
   * @notice requestRandomness initiates a request for VRF output given _seed
   *
   * @dev The fulfillRandomness method receives the output, once it's provided
   * @dev by the Oracle, and verified by the vrfCoordinator.
   *
   * @dev The _keyHash must already be registered with the VRFCoordinator, and
   * @dev the _fee must exceed the fee specified during registration of the
   * @dev _keyHash.
   *
   * @dev The _seed parameter is vestigial, and is kept only for API
   * @dev compatibility with older versions. It can't *hurt* to mix in some of
   * @dev your own randomness, here, but it's not necessary because the VRF
   * @dev oracle will mix the hash of the block containing your request into the
   * @dev VRF seed it ultimately uses.
   *
   * @param _keyHash ID of public key against which randomness is generated
   * @param _fee The amount of LINK to send with the request
   *
   * @return requestId unique ID for this request
   *
   * @dev The returned requestId can be used to distinguish responses to
   * @dev concurrent requests. It is passed as the first argument to
   * @dev fulfillRandomness.
   */
  function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
    LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
    // This is the seed passed to VRFCoordinator. The oracle will mix this with
    // the hash of the block containing this request to obtain the seed/input
    // which is finally passed to the VRF cryptographic machinery.
    uint256 vRFSeed = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
    // nonces[_keyHash] must stay in sync with
    // VRFCoordinator.nonces[_keyHash][this], which was incremented by the above
    // successful LINK.transferAndCall (in VRFCoordinator.randomnessRequest).
    // This provides protection against the user repeating their input seed,
    // which would result in a predictable/duplicate output, if multiple such
    // requests appeared in the same block.
    nonces[_keyHash] = nonces[_keyHash] + 1;
    return makeRequestId(_keyHash, vRFSeed);
  }

  LinkTokenInterface internal immutable LINK;
  address private immutable vrfCoordinator;

  // Nonces for each VRF key from which randomness has been requested.
  //
  // Must stay in sync with VRFCoordinator[_keyHash][this]
  mapping(bytes32 => uint256) /* keyHash */ /* nonce */
    private nonces;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   * @param _link address of LINK token contract
   *
   * @dev https://docs.chain.link/docs/link-token-contracts
   */
  constructor(address _vrfCoordinator, address _link) {
    vrfCoordinator = _vrfCoordinator;
    LINK = LinkTokenInterface(_link);
  }

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
    require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
    fulfillRandomness(requestId, randomness);
  }
}

abstract contract Random is Ownable, VRFConsumerBase {
    address public constant LINK_TOKEN = 0xb0897686c545045aFc77CF20eC7A532E3120E0F1;
    address public constant VRF_COORDINATOR = 0x3d2341ADb2D31f1c5530cDC622016af293177AE0;
    bytes32 public keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da;
    uint public chainlinkFee = 0.0001 ether;

    constructor() VRFConsumerBase(VRF_COORDINATOR, LINK_TOKEN) {}

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    function setChainlinkFee(uint256 _chainlinkFee) external onlyOwner {
        chainlinkFee = _chainlinkFee;
    }

    function linkBalance() public view returns (uint256) {
        return LINK.balanceOf(address(this));
    }

    function isEnoughLinkForBet() public view returns (bool) {
        return linkBalance() >= chainlinkFee;
    }
}

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


library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

contract Config {
    struct Token {
        string name;
        bool isLive;
        IERC20 tokenAddress;
    }

    struct TokenLTInfo {
        uint16 amount;
        uint16 unit;
        bool isExists;
    }

    mapping(string => Token) public tokenMap;
    mapping(string => uint128[]) public minBetAmounts;
    mapping(string => uint128[]) public maxBetAmounts;
    mapping(string => TokenLTInfo) public proportionLT;

    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "You are not an owner");
        _;
    }

    // convert
    function convertKey(address _tokenAddress, string memory _game)
        internal
        pure
        returns (string memory)
    {
        string memory tokenString = Strings.toHexString(
            uint256(uint160(_tokenAddress)),
            20
        );
        string memory key = string(abi.encodePacked(tokenString, _game));
        return key;
    }

    function setProportion(
        IERC20 token,
        string memory game,
        uint16 amount,
        uint16 unit
    ) external onlyOwner {
        string memory key = convertKey(address(token), game);
        proportionLT[key] = TokenLTInfo({amount: amount, unit: unit, isExists: true});
    }

    function setDefaultLimit(
        string memory game,
        string memory tokenString,
        IERC20 tokenAddress,
        uint128[] memory min,
        uint128[] memory max,
        uint8 unit
    ) external onlyOwner {
        for (uint8 i = 0; i < min.length; i++) {
            min[i] = uint128(min[i] * 10**unit);
        }
        for (uint8 i = 0; i < max.length; i++) {
            max[i] = uint128(max[i] * 10**unit);
        }
        string memory key = convertKey(address(tokenAddress), game);
        minBetAmounts[key] = min;
        maxBetAmounts[key] = max;
        if (!tokenMap[tokenString].isLive) {
            Token memory token = Token(tokenString, true, tokenAddress);
            tokenMap[tokenString] = token;
        }
    }

    function removeToken(string memory tokenString) external onlyOwner {
        if (tokenMap[tokenString].isLive) {
            tokenMap[tokenString].isLive = false;
        }
    }

    function getDefaultLimits(
        address tokenAddress,
        string memory game,
        uint8 index
    ) external view returns (uint128, uint128) {
        string memory key = convertKey(tokenAddress, game);
        return (minBetAmounts[key][index], maxBetAmounts[key][index]);
    }

    function getTokenAddress(string memory tokenString)
        external
        view
        returns (IERC20)
    {
        return tokenMap[tokenString].tokenAddress;
    }

    function getTokenIsLive(string memory tokenString)
        external
        view
        returns (bool)
    {
        return tokenMap[tokenString].isLive;
    }

    function calcLTCount(
        uint128 amount,
        string memory tokenString,
        string memory game
    ) external view returns (uint128) {
        if (tokenMap[tokenString].isLive) {
            IERC20 token = tokenMap[tokenString].tokenAddress;
            string memory key = convertKey(address(token), game);
            if (proportionLT[key].isExists) {
                return (amount * proportionLT[key].amount / proportionLT[key].unit);
            } else {
                return 0;
            }
        } else {
            return 0;
        }
    }
}


contract Agent is Ownable {
    Config public config;

    struct TokenLTInfo {
        uint16 amount;
        uint16 unit;
        bool isExists;
    }
    struct AgentInfo {
        uint32 agentID;
        address profitAddress;
        uint16 profitRate;
        bool isAlive;
        uint16 chargeRate;
    }

    mapping(string => uint256[]) public minBetAmounts;
    mapping(string => uint256[]) public maxBetAmounts;
    mapping(string => bool) public betLimits;
    mapping(uint32 => AgentInfo) public agents;
    mapping(string => TokenLTInfo) public proportionLT;
    mapping(address => bool) private addressAdmin;

    modifier admin() {
        addressAdmin[msg.sender] = true;
        require(addressAdmin[msg.sender] == true, "You are not an admin");
        _;
    }

    event SetAgentInfoDone(
        uint32 agentID,
        address profitAddress,
        bool isAlive,
        uint16 chargeRate,
        uint16 profitRate
    );
    event SetAgentGameLimitDone(
        uint32 agentID,
        address tokenAddress,
        uint256[] minBetAmount,
        uint256[] maxBetAmount
    );

    function addAdmin(address _admin) public virtual onlyOwner {
        require(_admin != address(0), "Admin: admin is the zero address");
        addressAdmin[_admin] = true;
    }

    function setConfig(address _address) external onlyOwner {
        config = Config(_address);
    }

    // convert
    function convertLimitKey(
        uint256 _agentID,
        address _tokenAddress,
        string memory _game
    ) internal pure returns (string memory) {
        string memory aid = Strings.toString(_agentID);
        string memory tokenString = Strings.toHexString(
            uint256(uint160(_tokenAddress)),
            20
        );
        string memory key = string(abi.encodePacked(tokenString, aid, _game));
        return key;
    }

    function getLimits(
        uint256 agentID,
        address tokenAddress,
        string memory game,
        uint8 index
    ) external view returns (uint256, uint256) {
        uint256 minBetAmount = 0;
        uint256 maxBetAmount = 0;
        string memory key = convertLimitKey(agentID, tokenAddress, game);
        if (betLimits[key]) {
            minBetAmount = minBetAmounts[key][index];
            maxBetAmount = maxBetAmounts[key][index];
        } else {
            (minBetAmount, maxBetAmount) = config.getDefaultLimits(
                tokenAddress,
                game,
                index
            );
        }
        return (minBetAmount, maxBetAmount);
    }

    function setAgentInfo(
        uint32 _agentID,
        address _profitAddress,
        bool _isAlive,
        uint16 _chargeRate,
        uint16 _profitRate
    ) external admin {
        AgentInfo memory agent = AgentInfo({
            agentID: _agentID,
            profitAddress: _profitAddress,
            isAlive: _isAlive,
            chargeRate: _chargeRate,
            profitRate: _profitRate
        });
        agents[_agentID] = agent;
        emit SetAgentInfoDone(
            _agentID,
            _profitAddress,
            _isAlive,
            _chargeRate,
            _profitRate
        );
    }

    function setAgentGameLimit(
        uint32 agentID,
        string memory game,
        address tokenAddress,
        uint256[] memory minBetAmount,
        uint256[] memory maxBetAmount
    ) external admin {
        string memory limitKey = convertLimitKey(agentID, tokenAddress, game);
        betLimits[limitKey] = true;
        minBetAmounts[limitKey] = minBetAmount;
        maxBetAmounts[limitKey] = maxBetAmount;
        emit SetAgentGameLimitDone(
            agentID,
            tokenAddress,
            minBetAmount,
            maxBetAmount
        );
    }

    function chargeRate(uint32 agentID) external view returns (uint16) {
        AgentInfo memory agent = agents[agentID];
        return agent.chargeRate;
    }

    function profitRate(uint32 agentID) external view returns (uint16) {
        AgentInfo memory agent = agents[agentID];
        return agent.profitRate;
    }

    function profitAddress(uint32 agentID) external view returns (address) {
        AgentInfo memory agent = agents[agentID];
        return agent.profitAddress;
    }

    function getTokenAddress(string memory tokenString)
        external
        view
        returns (IERC20)
    {
        return config.getTokenAddress(tokenString);
    }

    function calcLTCount(
        uint32 agentID,
        uint128 amount,
        string memory tokenString,
        string memory game
    ) external view returns (uint128) {
        bool isLive = config.getTokenIsLive(tokenString);
        if (isLive) {
            IERC20 token = config.getTokenAddress(tokenString);
            string memory key = convertLimitKey(agentID, address(token), game);
            if (proportionLT[key].isExists) {
                return proportionLT[key].amount * amount / proportionLT[key].unit;
            } else {
                return config.calcLTCount(amount, tokenString, game);
            }
        } else {
            return 0;
        }
    }

    function setProportion(
        IERC20 token,
        string memory game,
        uint32 agentID,
        uint16 amount,
        uint16 unit
    ) external onlyOwner {
        string memory key = convertLimitKey(agentID, address(token), game);
        proportionLT[key] = TokenLTInfo({amount: amount, unit: unit, isExists: true});
    }
}

interface IHouse {
    function checkValidate(
        uint256 amount,
        IERC20 token
    ) external payable;

    function settleBet(
        address player,
        uint128 amount,
        uint128 charge,
        uint32 agentID,
        uint128 tokenLTReward,
        bool win,
        IERC20 token
    ) external;
}

abstract contract Manager is Ownable {
    using SafeERC20 for IERC20;
    IHouse house;
    Agent agent;

    // Variables
    bool public gameIsLive = true;
    address public houseAddress;

    mapping(bytes32 => uint256) public betMap;
    mapping(address => bool) public addressAdmin;


    constructor() {
        addressAdmin[owner()] = true;
    }

    modifier admin() {
        require(addressAdmin[msg.sender] == true, "You are not an admin");
        _;
    }

    function toggleGameIsLive() external admin {
        gameIsLive = !gameIsLive;
    }

    // Methods
    function initializeHouse(address _address) external onlyOwner {
        houseAddress = _address;
        house = IHouse(_address);
    }

    function addAdmin(address _address) external onlyOwner {
        addressAdmin[_address] = true;
    }

    function removeAdmin(address _address) external onlyOwner {
        addressAdmin[_address] = false;
    }

    function withdrawCustomTokenFunds(
        address beneficiary,
        uint256 withdrawAmount,
        address token
    ) external onlyOwner {
        require(
            withdrawAmount <= IERC20(token).balanceOf(address(this)),
            "Withdrawal exceeds limit"
        );
        IERC20(token).safeTransfer(beneficiary, withdrawAmount);
    }

    function setAgent(address _address) external onlyOwner {
       agent = Agent(_address); 
    }
}

contract Dice is ReentrancyGuard, Random, Manager {
    uint256 public constant MOD = 6;

    uint40[] public odds = [6, 6, 6, 6, 6, 6, 2, 2, 2, 2];

    struct Bet {
        uint40 choice;
        uint256[] betAmount;
        uint40 outcome;
        uint168 placeBlockNumber;
        uint128 amount;
        uint128 winAmount;
        address player;
        bool isSettled;
        string tokenString;
        uint32 agentID;
        uint256 randomNumber;
        uint128 tokenLTReward;
    }

    Bet[] public bets;

    function betsLength() external view returns (uint256) {
        return bets.length;
    }

    // Events
    event BetPlaced(
        uint256 indexed betId,
        address indexed player,
        uint256 amount,
        uint256 choice,
        string tokenString,
        uint32 agentID
    );
    event BetSettled(
        uint256 indexed betId,
        address indexed player,
        uint256 amount,
        uint256 choice,
        uint256 outcome,
        uint256 winAmount,
        string tokenString,
        uint32 agentID,
        uint256 randomNumber,
        address houseAddress,
        uint128 tokenLTReward,
        uint256[] betAmount
    );

    function checkBetAmount(uint256[] memory betAmount, uint32 agentID, IERC20 token) internal view returns(uint256, uint256) {
        uint256 totalBetAmount = 0;
        uint256 totalWinnableAmount = 0;
        for (uint8 i = 0; i < betAmount.length; i++) {
            if (betAmount[i] > 0) {
                uint256 minBetAmount = 0;
                uint256 maxBetAmount = 0;
                (minBetAmount, maxBetAmount) = agent.getLimits(
                    agentID,
                    address(token),
                    "dice",
                    i
                );
                require(
                    betAmount[i] >= minBetAmount &&
                        betAmount[i] <= maxBetAmount,
                    "Bet amount not in range"
                );
                totalBetAmount += betAmount[i];
                totalWinnableAmount += betAmount[i] * odds[i];
            }
        }
        return (totalBetAmount, totalWinnableAmount);
    }

    /** @param numChoice dice number bet choice, eg: "0101011001" means player choose bet 1/4/5 odd small, numChoice will be 25;
     * @param betAmount uint array, every dice number's bet amount and odd/even small/big bet amount, eg: [0,40000000000000000,0,50000000000000000,0,10000000000000000,20000000000000000,0,0,30000000000000000];
     * @param agentID which agent player belongs;
     * @param tokenString bet token, eg: "MATIC" or "USDT";
     */
    function placeBet(
        uint256 numChoice,
        uint256[] memory betAmount,
        uint32 agentID,
        string memory tokenString
    ) external payable nonReentrant {
        require(gameIsLive, "Game is not live");
        require(isEnoughLinkForBet(), "Insufficient LINK token");
        require(numChoice > 0, "Must bet one place");
        require(!Address.isContract(msg.sender), "Contract not allowed");
        require(msg.sender == tx.origin, "Contract not allowed");

        uint256 totalBetAmount = 0;
        uint256 totalWinnableAmount = 0;

        IERC20 token = agent.getTokenAddress(tokenString);
        
        (totalBetAmount, totalWinnableAmount) = checkBetAmount(betAmount, agentID, token);

        uint256 betId = bets.length;

        if (address(token) == address(0)) {
            require(msg.value >= totalBetAmount, "bet amount not enough");
            house.checkValidate{value: msg.value}(totalWinnableAmount, token);
        } else {
            require(
                token.balanceOf(msg.sender) >= totalBetAmount,
                "Your token balance not enough"
            );
            SafeERC20.safeTransferFrom(token, msg.sender, houseAddress, totalBetAmount);
            house.checkValidate(totalWinnableAmount, token);
        }

        bytes32 requestId = requestRandomness(keyHash, chainlinkFee);
        betMap[requestId] = betId;

        emit BetPlaced(betId, msg.sender, totalBetAmount, numChoice, tokenString, agentID);
        bets.push(
            Bet({
                choice: uint40(numChoice),
                betAmount: betAmount,
                outcome: 0,
                placeBlockNumber: uint168(block.number),
                amount: uint128(totalBetAmount),
                winAmount: 0,
                player: msg.sender,
                isSettled: false,
                tokenString: tokenString,
                agentID: agentID,
                randomNumber: 0,
                tokenLTReward: 0
            })
        );
    }

    // Callback function called by Chainlink VRF coordinator.
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        settleBet(requestId, randomness);
    }

    // Function can only be called by fulfillRandomness function, which in turn can only be called by Chainlink VRF.
    function settleBet(bytes32 requestId, uint256 randomNumber)
        private
        nonReentrant
    {
        Bet storage bet = bets[betMap[requestId]];

        if (bet.amount == 0 || bet.isSettled == true) {
            return;
        }

        bet.outcome = uint40(randomNumber % MOD);
        bet.isSettled = true;
        bet.randomNumber = randomNumber;
        uint128 charge = 0;
        (bet.winAmount, charge) = calc(
            bet.agentID,
            bet.betAmount,
            bet.choice,
            bet.outcome
        );

        bet.tokenLTReward = agent.calcLTCount(bet.agentID, bet.amount, bet.tokenString, "dice");

        house.settleBet(
            bet.player,
            bet.winAmount,
            charge,
            bet.agentID,
            bet.tokenLTReward,
            bet.winAmount > 0,
            agent.getTokenAddress(bet.tokenString)
        );

        emit BetSettled(
            betMap[requestId],
            bet.player,
            bet.amount,
            bet.choice,
            bet.outcome,
            bet.winAmount,
            bet.tokenString,
            bet.agentID,
            bet.randomNumber,
            houseAddress,
            bet.tokenLTReward,
            bet.betAmount
        );
    }

    function calc(
        uint32 agentID,
        uint256[] memory betAmount,
        uint256 choice,
        uint256 outcome
    ) private view returns (uint128, uint128) {
        uint256 winAmount = 0;
        uint256 charge = 0;
        uint256 chargeRate = agent.chargeRate(agentID);
        if ((choice & (1 << outcome)) > 0) {
            winAmount =
                (betAmount[outcome] * (odds[outcome] - 1) * (10000 - chargeRate)) /
                10000 + betAmount[outcome];
            charge += (betAmount[outcome] * (odds[outcome] - 1) * chargeRate) / 10000;
        }

        uint256 oddEvenOutcome;
        if ((outcome + 1) % 2 == 0) {
            oddEvenOutcome = 7;
        } else {
            oddEvenOutcome = 6;
        }

        if ((choice & (1 << oddEvenOutcome)) > 0) {
            winAmount +=
                (betAmount[oddEvenOutcome] *
                    (odds[oddEvenOutcome] - 1)*
                    (10000 - chargeRate)) /
                10000 + betAmount[oddEvenOutcome];
            charge +=
                (betAmount[oddEvenOutcome] *
                    (odds[oddEvenOutcome] - 1)*
                    chargeRate) /
                10000;
        }

        uint256 smallBigOutcome;
        if (outcome >= 0 && outcome <= 2) {
            smallBigOutcome = 8;
        } else {
            smallBigOutcome = 9;
        }
        if ((choice & (1 << smallBigOutcome)) > 0) {
            winAmount +=
                (betAmount[smallBigOutcome] *
                    (odds[smallBigOutcome] - 1)*
                    (10000 - chargeRate)) /
                10000 + betAmount[smallBigOutcome];
            charge +=
                (betAmount[smallBigOutcome] *
                    (odds[smallBigOutcome] - 1)*
                    chargeRate) /
                10000;
        }

        return (uint128(winAmount), uint128(charge));
    }
}