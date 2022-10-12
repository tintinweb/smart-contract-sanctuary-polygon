// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./planets/contracts/utils/MultiWhitelist.sol";
import "./planets/contracts/utils/Random.sol";
import "./ApeironStar.sol";
import "./interfaces/IApeironGodiverseCollection.sol";

contract StellaTabullasPresaleFactory is
    IERC1155Receiver,
    MultiWhitelist,
    Random
{
    enum STType {
        Regular,
        Celestial,
        Empyrean,
        Omega
    }

    using Address for address;
    using SafeERC20 for IERC20;

    event Reserved(uint256 indexed tokenId, address indexed reserver);
    event SoldChest(
        uint256 indexed tokenId,
        address indexed buyer,
        uint256 price
    );
    event PresaleEnable(bool isEnabled);
    event TypeCounterUpdated(STType indexed stType, uint256 counter);
    event TypeMaxUpdated(uint256[] typeCounter);
    event STGenMappingUpdated(uint256 indexed tokenId, uint256 genId);
    event STTokenIdNGenIdArrayUpdated(
        STType indexed stType,
        uint256[] tokenIdArray,
        uint256[] genIdArray,
        uint256[] godiverseArray
    );

    modifier onlyDuringSale() {
        require(isEnabled, "Sale is not enabled");
        _;
    }

    IERC20 public immutable token;
    ApeironStar public immutable starContract;
    IApeironGodiverseCollection public immutable godiverseContract;
    bool public isEnabled;

    mapping(STType => uint256) public prices;
    mapping(STType => uint256) public typeCounter;
    mapping(STType => uint256) public typeMax;

    mapping(STType => uint256[]) internal _stTokenIdArrayMap;
    mapping(uint256 => uint256) internal _stIdStarGenMap;
    mapping(uint256 => uint256) internal _stIdGodiverseMap;

    constructor(
        address _starAddress,
        address _godiverseAddress,
        address _tokenAddress,
        uint256[] memory _prices,
        uint256[] memory _mintCountPerType
    ) {
        require(_starAddress.isContract(), "_starAddress must be a contract");
        require(
            _godiverseAddress.isContract(),
            "_godiverseAddress must be a contract"
        );
        require(_tokenAddress.isContract(), "_tokenAddress must be a contract");
        require(_prices.length == 4, "Invalid prices count");
        require(_mintCountPerType.length == 4, "Invalid mint count");

        // NFT + FT Address
        starContract = ApeironStar(_starAddress);
        godiverseContract = IApeironGodiverseCollection(_godiverseAddress);
        token = IERC20(_tokenAddress);

        // PRICES
        prices[STType.Regular] = _prices[0];
        prices[STType.Celestial] = _prices[1];
        prices[STType.Empyrean] = _prices[2];
        prices[STType.Omega] = _prices[3];

        // TYPE COUNTER + MAX
        typeCounter[STType.Regular] = 0;
        typeMax[STType.Regular] = _mintCountPerType[0];

        typeCounter[STType.Celestial] = 0;
        typeMax[STType.Celestial] = _mintCountPerType[1];

        typeCounter[STType.Empyrean] = 0;
        typeMax[STType.Empyrean] = _mintCountPerType[2];

        typeCounter[STType.Omega] = 0;
        typeMax[STType.Omega] = _mintCountPerType[3];
    }

    /// @dev Required by IERC1155Receiver
    function supportsInterface(bytes4 interfaceId)
        external
        view
        override
        returns (bool)
    {}

    /// @dev Required by IERC1155Receiver
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /// @dev Required by IERC1155Receiver
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    /**
     * @notice - Purchase NFT
     *
     * @param _stType - Type of NFT
     */
    function purchase(STType _stType)
        external
        onlyLimited
        onlyDuringSale
        onlyWhitelisted
    {
        require(
            _stTokenIdArrayMap[_stType].length == typeMax[_stType],
            "stTokenIdArrayMap is not correctly mapped"
        );
        uint256 price = prices[_stType];
        require(getAvailableCount(_stType) > 0, "stType sold out");
        (uint256 nftIndex, uint256 nftId) = _getTargetStarIndexNId(_stType);
        // during presale, 0 = there are no star left
        require(
            nftId != 0 && _getStarGenIdByStId(nftId) != 0,
            "stType sold out"
        );

        // transfer token to contract, this will also check the token balance
        token.safeTransferFrom(msg.sender, address(this), price);

        // star mint to buyer
        starContract.safeMint(_getStarGenIdByStId(nftId), msg.sender, nftId);

        // godiverse mint
        uint256[] memory godiverseArray = _convertToGodiverseArray(nftId);
        for (uint256 i = 0; i < godiverseArray.length; i++) {
            if (godiverseArray[i] != 0) {
                godiverseContract.mint(godiverseArray[i], 1, "");
                godiverseContract.safeTransferFrom(
                    address(this),
                    msg.sender,
                    godiverseArray[i],
                    1,
                    ""
                );
            } else {
                continue;
            }
        }

        // update data
        typeCounter[_stType] += 1;
        userPurchaseCounter[msg.sender] += 1;
        delete (_stTokenIdArrayMap[_stType][nftIndex]);

        emit SoldChest(nftId, msg.sender, price);
    }

    /**
     * @notice - Get target star id & index by stType, called when purchase/reserve ST
     * return id 0 mean there are no star left
     *
     * @param _stType - Type of Stella Tabula
     */
    function _getTargetStarIndexNId(STType _stType)
        internal
        returns (uint256 index, uint256 id)
    {
        uint256 randomIndex = _randomRange(0, typeMax[_stType] - 1);
        return _randomPickFromPool(randomIndex, _stTokenIdArrayMap[_stType]);
    }

    /**
     * @notice - Get target star id & index by stType, called by _getTargetStarIndexNId
     * return id 0 mean there are no star left
     *
     * @param _randomIndex - randomIndex
     * @param _poolValues - the pool
     */
    function _randomPickFromPool(
        uint256 _randomIndex,
        uint256[] memory _poolValues
    ) internal pure returns (uint256 index, uint256 poolValue) {
        uint256 count = 0;
        if (_poolValues.length == 0) {
            return (_randomIndex, 0);
        }

        while (_poolValues[_randomIndex] == 0 && count < _poolValues.length) {
            count++;
            _randomIndex++;
            if (_randomIndex >= _poolValues.length) {
                _randomIndex = 0;
            }
        }
        // if return 0, there are no star left
        return (_randomIndex, _poolValues[_randomIndex]);
    }

    /**
     * @notice - Set tokenIdArray by STType
     *
     * @param _stType - ST Type
     * @param _tokenIdArray - TokenId Array
     * @param _starGenArray - Star Gen Array
     * @param _godiverseGenArray - Godiverse Gen Array
     */
    function setStTokenIdNGenIdArray(
        STType _stType,
        uint256[] memory _tokenIdArray,
        uint256[] memory _starGenArray,
        uint256[] memory _godiverseGenArray,
        bool _isReset
    ) external onlyOwner {
        require(
            _tokenIdArray.length == _starGenArray.length &&
                _tokenIdArray.length == _godiverseGenArray.length,
            "array is not in correct length"
        );

        // reset the array
        if (_isReset) {
            _stTokenIdArrayMap[_stType] = new uint256[](0);
        }

        for (uint256 i = 0; i < _tokenIdArray.length; i++) {
            // update _stTokenIdArrayMap
            _stTokenIdArrayMap[_stType].push(_tokenIdArray[i]);

            // update _stIdStarGenMap
            require(_starGenArray[i] != 0, "star gen should not be zero");
            _stIdStarGenMap[_tokenIdArray[i]] = _starGenArray[i];

            // update _stIdGodiverseMap
            _stIdGodiverseMap[_tokenIdArray[i]] = _godiverseGenArray[i];
        }

        emit STTokenIdNGenIdArrayUpdated(
            _stType,
            _tokenIdArray,
            _starGenArray,
            _godiverseGenArray
        );
    }

    /**
     * @notice - Get stTokenIdArray by STType
     *
     * @param _stType - ST Type
     */
    function getStTokenIdArray(STType _stType)
        external
        view
        returns (uint256[] memory tokenIdArray)
    {
        return _stTokenIdArrayMap[_stType];
    }

    /**
     * @notice - get available count for ST
     *
     * @param _stType - Type of stella tabullas
     */
    function getAvailableCount(STType _stType) public view returns (uint256) {
        return typeMax[_stType] - typeCounter[_stType];
    }

    /**
     * @notice - Enable/Disable Sales
     * @dev - callable only by owner
     *
     * @param _isEnabled - enable? sales
     */
    function setEnabled(bool _isEnabled) external onlyOwner {
        isEnabled = _isEnabled;
        emit PresaleEnable(_isEnabled);
    }

    /**
     * @notice - set TypeCounter
     * @dev - callable only by owner
     *
     * @param _stType - Type of stella tabullas
     * @param _newCount - new counter
     */
    function setTypeCounter(STType _stType, uint256 _newCount)
        external
        onlyOwner
    {
        typeCounter[_stType] = _newCount;
        emit TypeCounterUpdated(_stType, _newCount);
    }

    /**
     * @notice - set TypeMax
     * @dev - callable only by owner
     *
     * @param _typeMax - [ Regular's counter, Celestial's counter, Empyrean's counter, Omega's counter ]
     */
    function setTypeMax(uint256[] memory _typeMax) external onlyOwner {
        require(_typeMax.length == 4, "Invalid Type Max");
        typeMax[STType.Regular] = _typeMax[0];
        typeMax[STType.Celestial] = _typeMax[1];
        typeMax[STType.Empyrean] = _typeMax[2];
        typeMax[STType.Omega] = _typeMax[3];
        emit TypeMaxUpdated(_typeMax);
    }

    /**
     * @notice convert STId To godiverse Attributes array
     *
     * @param _stId - ST id
     */
    function _convertToGodiverseArray(uint256 _stId)
        internal
        view
        returns (uint256[] memory)
    {
        // there are max 10 items
        uint256[] memory attributes = new uint256[](10);

        uint256 geneId = _stIdGodiverseMap[_stId];
        for (uint256 i = 0; i < attributes.length; i++) {
            attributes[i] = geneId % (16**3);
            geneId /= (16**3);
        }

        return attributes;
    }

    /**
     * @notice - get star gen id by stella tabullas id
     *
     * @param _stId - stella tabullas id

     */
    function _getStarGenIdByStId(uint256 _stId)
        internal
        view
        returns (uint256)
    {
        return _stIdStarGenMap[_stId];
    }

    /**
     * @notice - Withdraw any ERC20
     *
     * @param _tokenAddress - ERC20 token address
     * @param _amount - amount to withdraw
     * @param _wallet - address to withdraw to
     */
    function withdrawFunds(
        address _tokenAddress,
        uint256 _amount,
        address _wallet
    ) external onlyOwner {
        IERC20(_tokenAddress).transfer(_wallet, _amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity 0.8.12;
pragma abicoder v2;

import "./AccessProtected.sol";

abstract contract MultiWhitelist is AccessProtected {
    mapping(address => Whitelist) private _whitelisted;
    mapping(address => uint256) public userPurchaseCounter;
    mapping(WhitelistType => uint256) public purchaseLimits;

    enum WhitelistType {
        NON,
        WHITELIST,
        VIP_WHITELIST
    }
    struct Whitelist {
        bool isWhitelisted;
        WhitelistType whitelistType;
    }
    enum ForSaleType {
        NotForSale,
        ForVipOnly,
        ForWhitelist,
        PublicSale
    }
    mapping(ForSaleType => uint256) forSaleSchedule;

    event Whitelisted(address _user, WhitelistType whitelistType);
    event Blacklisted(address _user);
    event SaleScheduleUpdated(uint256[] _saleSchedule);

    /**
     * @notice Set the NFT purchase limits
     *
     * @param _purchaseLimits - NFT purchase limits
     */
    function setPurchaseLimits(uint256[] memory _purchaseLimits) external onlyAdmin {
        require(_purchaseLimits.length == 3, "Invalid purchase limits");
        purchaseLimits[WhitelistType.NON] = _purchaseLimits[0];
        purchaseLimits[WhitelistType.WHITELIST] = _purchaseLimits[1];
        purchaseLimits[WhitelistType.VIP_WHITELIST] = _purchaseLimits[2];
    }

    /**
     * @notice Whitelist User
     *
     * @param user - Address of User
     * @param whitelistType - Type of Whitelisting
     */
    function whitelist(address user, WhitelistType whitelistType)
        public
        onlyAdmin
    {
        _whitelisted[user].isWhitelisted = true;
        _whitelisted[user].whitelistType = whitelistType;
        emit Whitelisted(user, whitelistType);
    }

    /**
     * @notice Whitelist Users
     *
     * @param users - Addresses of Users
     */
    function whitelistBatch(
        address[] memory users,
        WhitelistType[] memory whitelistTypes
    ) external onlyAdmin {
        for (uint256 i = 0; i < users.length; i++) {
            whitelist(users[i], whitelistTypes[i]);
        }
    }

    /**
     * @notice Blacklist User
     *
     * @param user - Address of User
     */
    function blacklist(address user) public onlyAdmin {
        _whitelisted[user].isWhitelisted = false;
        _whitelisted[user].whitelistType = WhitelistType.NON;
        emit Blacklisted(user);
    }

    /**
     * @notice Blacklist Users
     *
     * @param users - Addresses of Users
     */
    function blacklistBatch(address[] memory users) external onlyAdmin {
        for (uint256 i = 0; i < users.length; i++) {
            blacklist(users[i]);
        }
    }

    /**
     * @notice Check if Whitelisted
     *
     * @param user - Address of User
     * @return whether user is whitelisted
     */
    function isWhitelisted(address user)
        public
        view
        returns (Whitelist memory)
    {
        return _whitelisted[user];
    }

    /**
     * @notice Check if reached purchase limit
     *
     * @param user - Address of User
     * @return whether user is reached the purchase limit
     */
    function isReachedPurchaseLimit(address user)
        public
        view
        returns (bool)
    {
        return userPurchaseCounter[user] >= purchaseLimits[_whitelisted[user].whitelistType];
    }

    /**
     * @notice set for sale schedule
     *
     * @param _forSaleSchedule - for sale schedules [ ForVipOnly, ForWhitelist, PublicSale ]
     */
    function setForSaleSchedule(uint256[] memory _forSaleSchedule) external onlyAdmin {
        require(
            _forSaleSchedule.length == 3 &&
                _forSaleSchedule[2] >= _forSaleSchedule[1] &&
                _forSaleSchedule[1] >= _forSaleSchedule[0],
            'Invalid for sale schedule'
        );
        forSaleSchedule[ForSaleType.ForVipOnly] = _forSaleSchedule[0];
        forSaleSchedule[ForSaleType.ForWhitelist] = _forSaleSchedule[1];
        forSaleSchedule[ForSaleType.PublicSale] = _forSaleSchedule[2];

        emit SaleScheduleUpdated(_forSaleSchedule);
    }

    /**
     * @notice get current for sale type
     *
     * @return whether current for sale type
     */
    function getCurrentForSaleType()
        public
        view
        returns (ForSaleType)
    {
        if (forSaleSchedule[ForSaleType.PublicSale] > 0
            && forSaleSchedule[ForSaleType.PublicSale] <= block.timestamp) {
            return ForSaleType.PublicSale;
        }
        else if (forSaleSchedule[ForSaleType.ForWhitelist] > 0
                && forSaleSchedule[ForSaleType.ForWhitelist] <= block.timestamp) {
            return ForSaleType.ForWhitelist;
        }
        else if (forSaleSchedule[ForSaleType.ForVipOnly] > 0
                && forSaleSchedule[ForSaleType.ForVipOnly] <= block.timestamp) {
            return ForSaleType.ForVipOnly;
        }

        return ForSaleType.NotForSale;
    }

    /**
     * Throws if NFT purchase limit has exceeded.
     */
    modifier onlyLimited() {
        require(
            !isReachedPurchaseLimit(_msgSender()),
            "Purchase limit reached"
        );
        _;
    }

    /**
     * Throws if called by any account other than Whitelisted.
     */
    modifier onlyWhitelisted() {
        require(
            getCurrentForSaleType() == ForSaleType.PublicSale ||
            (
                getCurrentForSaleType() == ForSaleType.ForWhitelist &&
                _whitelisted[_msgSender()].whitelistType >= WhitelistType.WHITELIST &&
                _whitelisted[_msgSender()].isWhitelisted
            ) ||
            (
                getCurrentForSaleType() == ForSaleType.ForVipOnly &&
                _whitelisted[_msgSender()].whitelistType == WhitelistType.VIP_WHITELIST &&
                _whitelisted[_msgSender()].isWhitelisted
            ) ||
            _admins[_msgSender()] ||
            _msgSender() == owner(),
            "Caller is not Whitelisted"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract Random {
    uint256 randomNonce;

    function _updateRandomNonce(uint256 _num) internal {
        randomNonce = _num;
    }
    
    function _getRandomNonce() internal view returns (uint256) {
        return randomNonce;
    }

    function __getRandomBaseValue(uint256 _nonce) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            msg.sender,
            _nonce
        )));
    }

    function _getRandomBaseValue() internal returns (uint256) {
        randomNonce++;
        return __getRandomBaseValue(randomNonce);
    }

    function __random(uint256 _nonce, uint256 _modulus) internal view returns (uint256) {
        require(_modulus >= 1, 'invalid values for random');

        return __getRandomBaseValue(_nonce) % _modulus;
    }

    function _random(uint256 _modulus) internal returns (uint256) {
        randomNonce++;
        return __random(randomNonce, _modulus);
    }

    function _randomByBaseValue(uint256 _baseValue, uint256 _modulus) internal pure returns (uint256) {
        require(_modulus >= 1, 'invalid values for random');

        return _baseValue % _modulus;
    }

    function __randomRange(uint256 _nonce, uint256 _start, uint256 _end) internal view returns (uint256) {
        if (_end > _start) {
            return _start + __random(_nonce, _end + 1 - _start);
        }
        else {
            return _end + __random(_nonce, _start + 1 - _end);
        }
    }

    function _randomRange(uint256 _start, uint256 _end) internal returns (uint256) {
        randomNonce++;
        return __randomRange(randomNonce, _start, _end);
    }

    function _randomRangeByBaseValue(uint256 _baseValue, uint256 _start, uint256 _end) internal pure returns (uint256) {
        if (_end > _start) {
            return _start + _randomByBaseValue(_baseValue, _end + 1 - _start);
        }
        else {
            return _end + _randomByBaseValue(_baseValue, _start + 1 - _end);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./planets/contracts/utils/AccessProtectedUpgradable.sol";
import "./ApeironStarData.sol";
import "./StarMeta.sol";

contract ApeironStar is
    StarMeta,
    Initializable,
    ERC721Upgradeable,
    PausableUpgradeable,
    AccessProtectedUpgradable,
    UUPSUpgradeable
{
    using AddressUpgradeable for address;

    // Base URI
    string private baseURI;

    ApeironStarData public apeironStarDataContract;

    // event
    event UpdateStarDataContract(address _starDataAddress);
    event UpdateURI(string _baseURI);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    modifier hasTokenId(uint256 _tokenId) {
        require(_exists(_tokenId), "tokenId is non existent");
        _;
    }

    function initialize() public initializer {
        __ERC721_init("ApeironStar", "APES");
        __Pausable_init();
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address _from,
        address _to,
        uint256 _tokenId
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(_from, _to, _tokenId);
    }

    function _authorizeUpgrade(address _newImplementation)
        internal
        override
        onlyOwner
    {}

    function updateStarDataContract(address _starDataAddress)
        external
        onlyOwner
    {
        require(
            _starDataAddress.isContract(),
            "_starDataAddress must be a contract"
        );

        apeironStarDataContract = ApeironStarData(_starDataAddress);

        emit UpdateStarDataContract(_starDataAddress);
    }

    /**
     * @notice - safeMint NFT
     *
     * @param _gene - star gene
     * @param _to - owner address
     * @param _tokenId - star tokenId
     */
    function safeMint(
        uint256 _gene,
        address _to,
        uint256 _tokenId
    ) external onlyAdmin {
        _safeMint(_to, _tokenId);

        apeironStarDataContract.updateStarGenMap(_tokenId, _gene);
    }

    /**
     * @notice - update Star GenId
     *
     * @param _tokenId - star tokenId
     * @param _genId - star genId
     */
    function updateStarGen(uint256 _tokenId, uint256 _genId)
        external
        hasTokenId(_tokenId)
        whenNotPaused
        onlyAdmin
    {
        apeironStarDataContract.updateStarGenMap(_tokenId, _genId);
    }

    /**
     * @notice - get Star GenId
     *
     * @param _tokenId - star tokenId
     */
    function getStarGenByStarId(uint256 _tokenId)
        external
        view
        returns (
            uint256, //starGen
            bool //isAlive
        )
    {
        return (
            apeironStarDataContract.getStarGenByStarId(_tokenId),
            _exists(_tokenId)
        );
    }

    /**
     * @notice - get Star Godiverse struct by star tokenId
     *
     * @param _tokenId - star tokenId
     */
    function getStarGodiverseMapList(uint256 _tokenId, GodiverseSlot _slot)
        external
        view
        hasTokenId(_tokenId)
        returns (uint256[] memory)
    {
        // return starGodiverseMap[_tokenId];
        return apeironStarDataContract.getStarGodiverseMapList(_tokenId, _slot);
    }

    /**
        0: Supernova slots
        1: Comet slots
        2: Kuiper Belt slots
        3: Asteroid Belt slots
        4: Sun slots
        5: Alliance Expansion
        6: Ultranova
        7:  Celestial Object
        8:  Core Effect
        9:  Core Color
        10:  Track Count
        11:  Age Buff
        12:  Constellation Digit
        13:  Constellation
        14:  major/minor
        15:  Galaxy
        16:  Tier
     */
    /**
     * @notice convert geneId ToAttributes array
     * @param _geneId geneId
     * @param _numOfAttributes Number Of Attributes, star should be 17
     */
    function convertToAttributes(uint256 _geneId, uint256 _numOfAttributes)
        public
        pure
        returns (uint256[] memory)
    {
        uint256[] memory attributes = new uint256[](_numOfAttributes);

        uint256 geneId = _geneId;
        for (uint256 i = 0; i < attributes.length; i++) {
            attributes[i] = geneId % 256;
            geneId /= 256;
        }

        return attributes;
    }

    // set baseURI
    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit UpdateURI(baseURI);
    }

    // override functions for ERC721Upgradeable
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IApeironGodiverseCollection {
    function mint(
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
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
pragma solidity 0.8.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessProtected is Context, Ownable {
    mapping(address => bool) internal _admins; // user address => admin? mapping

    event AdminAccessSet(address _admin, bool _enabled);

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Admin
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether user has admin access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[_msgSender()] || _msgSender() == owner(),
            "Caller does not have Admin Access"
        );
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

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
    function __ERC721_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return
            interfaceId == type(IERC721Upgradeable).interfaceId ||
            interfaceId == type(IERC721MetadataUpgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        safeTransferFrom(from, to, tokenId, "");
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
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
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
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
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

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

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
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

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
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
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
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
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
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
        __UUPSUpgradeable_init_unchained();
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallSecure(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/utils/Context.sol";

abstract contract AccessProtectedUpgradable is OwnableUpgradeable {
    mapping(address => bool) internal _admins; // user address => admin? mapping

    event AdminAccessSet(address _admin, bool _enabled);

    /**
     * @notice Set Admin Access
     *
     * @param admin - Address of Admin
     * @param enabled - Enable/Disable Admin Access
     */
    function setAdmin(address admin, bool enabled) external onlyOwner {
        _admins[admin] = enabled;
        emit AdminAccessSet(admin, enabled);
    }

    /**
     * @notice Check Admin Access
     *
     * @param admin - Address of Admin
     * @return whether user has admin access
     */
    function isAdmin(address admin) public view returns (bool) {
        return _admins[admin];
    }

    /**
     * Throws if called by any account other than the Admin.
     */
    modifier onlyAdmin() {
        require(
            _admins[_msgSender()] || _msgSender() == owner(),
            "Caller does not have Admin Access"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
// pragma abicoder v2;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./planets/contracts/utils/AccessProtectedUpgradable.sol";

import "./StarMeta.sol";

contract ApeironStarData is
    StarMeta,
    Initializable,
    AccessProtectedUpgradable,
    UUPSUpgradeable
{
    // Mapping from token ID to Star attributes
    // starId => genId
    mapping(uint256 => uint256) private starGenMap;
    // starId => attached godiverse
    mapping(uint256 => mapping(GodiverseSlot => uint256[]))
        private starGodiverseMap;

    // attact/detach addition data
    // available attach godiverse id for each slot type
    mapping(GodiverseSlot => uint256[]) private godiverseIdsPerSlot;

    // godiverseId => GodiverseInfo; if tierRequire is 0, = no requirement
    mapping(uint256 => GodiverseInfo) public godiverse_info_map;

    // event
    event UpdateStarGen(uint256 indexed _starId, uint256 indexed _genId);
    event SetAvailableGodiverseIdMap(
        GodiverseSlot indexed _slot,
        uint256[] _godiverseIdArray
    );
    event SetGodiverseInfoMap(
        uint256[] _godiverseIdArray,
        GodiverseInfo[] _sunInfoArray
    );
    event SetStarGodiverseMap(
        uint256 indexed _starId,
        GodiverseSlot indexed _slot,
        uint256 indexed _slotIndex,
        uint256 _godiverseId
    );
    event RemoveStarGodiverseMap(
        uint256 indexed _starId,
        GodiverseSlot indexed _slot,
        uint256 indexed _slotIndex
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function initialize() public initializer {
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        override
        onlyOwner
    {}

    /**
     * @notice Update StarGenMap
     *
     * @param _starId star ID
     * @param _starGen star GenID
     */
    function updateStarGenMap(uint256 _starId, uint256 _starGen)
        external
        onlyAdmin
    {
        starGenMap[_starId] = _starGen;
        emit UpdateStarGen(_starId, _starGen);
    }

    /**
     * @notice Get StarGenID
     *
     * @param _starId star ID
     */
    function getStarGenByStarId(uint256 _starId)
        external
        view
        returns (uint256)
    {
        return starGenMap[_starId];
    }

    // Godiverse function
    /**
     * @notice init available godiverse ID for slot
     *
     * @param _slot GodiverseSlot enum
     * @param _slotArray GodiverseSlot count
     */
    function initAvailableGodiverseIdMap(
        GodiverseSlot _slot,
        uint256[] memory _slotArray
    ) external onlyAdmin {
        godiverseIdsPerSlot[_slot] = _slotArray;

        emit SetAvailableGodiverseIdMap(_slot, _slotArray);
    }

    /**
     * @notice init godiverse info map
     *
     * @param _godiverseIdArray godiverse ID array
     * @param _infoArray info array
     */
    function initGodiverseInfoMap(
        uint256[] memory _godiverseIdArray,
        GodiverseInfo[] memory _infoArray
    ) external onlyAdmin {
        require(_godiverseIdArray.length == _infoArray.length, "error length");

        for (uint256 i = 0; i < _godiverseIdArray.length; i++) {
            godiverse_info_map[_godiverseIdArray[i]] = _infoArray[i];
        }

        emit SetGodiverseInfoMap(_godiverseIdArray, _infoArray);
    }

    /**
     * @notice init available godiverse ID for slot
     *
     * @param _slot GodiverseSlot enum
     */
    function getAvailableGodiverseIdMap(GodiverseSlot _slot)
        external
        view
        returns (uint256[] memory)
    {
        return godiverseIdsPerSlot[_slot];
    }

    /**
     * @notice get godiverse require tier by ID
     *
     * @param _godiverseId godiverse ID
     */
    function getGodiverseInfo(uint256 _godiverseId)
        external
        view
        returns (GodiverseInfo memory)
    {
        return godiverse_info_map[_godiverseId];
    }

    /**
     * @notice init available godiverse ID for slot
     *
     * @param _slot GodiverseSlot enum
     * @param _slotCount GodiverseSlot count
     */
    function initStarGodiverseMap(
        uint256 _starId,
        GodiverseSlot _slot,
        uint256 _slotCount
    ) external onlyAdmin {
        starGodiverseMap[_starId][_slot] = new uint256[](_slotCount);
    }

    /**
     * @notice set StarGodiverseMap
     *
     * @param _starId star ID
     * @param _slot GodiverseSlot enum
     * @param _slotIndex GodiverseSlot index
     * @param _godiverseId Godiverse ID
     */
    function setStarGodiverseMap(
        uint256 _starId,
        GodiverseSlot _slot,
        uint256 _slotIndex,
        uint256 _godiverseId
    ) external onlyAdmin {
        starGodiverseMap[_starId][_slot][_slotIndex] = _godiverseId;
        emit SetStarGodiverseMap(_starId, _slot, _slotIndex, _godiverseId);
    }

    /**
     * @notice remove Godiverse from StarGodiverseMap by slot index
     *
     * @param _starId star ID
     * @param _slot GodiverseSlot enum
     * @param _slotIndex GodiverseSlot index
     */
    function removeStarGodiverseMap(
        uint256 _starId,
        GodiverseSlot _slot,
        uint256 _slotIndex
    ) external onlyAdmin {
        delete starGodiverseMap[_starId][_slot][_slotIndex];
        emit RemoveStarGodiverseMap(_starId, _slot, _slotIndex);
    }

    /**
     * @notice get GodiverseMap by star ID and godiverse slot
     *
     * @param _starId star ID
     * @param _slot GodiverseSlot enum
     */
    function getStarGodiverseMapList(uint256 _starId, GodiverseSlot _slot)
        external
        view
        returns (uint256[] memory)
    {
        return starGodiverseMap[_starId][_slot];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

contract StarMeta {
    enum GodiverseSlot {
        Sun,
        AsteroidBelt,
        KuiperBelt,
        Comet,
        Supernova
    }

    enum OrbitalTrackState {
        Empty,
        Listing,
        Renting
    }

    // enum OrbitalTrackSettingType {
    //     Open,
    //     Invite
    // }

    struct GodiverseInfo {
        uint256 tierRequire;
        uint256 agingBuff; // 1.5 buff will set to 150 (just * 100 to the origin value)
        uint256 additionalOribitalTrack;
    }

    // struct StarOrbitalTrackSetting {
    //     OrbitalTrackSettingType settingType;
    //     uint256 numberofTracks;
    //     uint256 rentalFee;
    //     uint256 rentalDuration; // days
    //     address inviteAddress; // star owner invite other to stake
    //     bool canBeRenew;
    // }

    struct StarOrbitalTrackData {
        OrbitalTrackState rentingState;
        // status = Listing
        uint256 availableTrackTime;
        address inviteAddress; // star owner invite other to stake
        uint256 rentalFee;
        uint256 rentalDuration; // days
        bool canBeRenew;
        // status = Renting
        address planetOwnerAddress;
        uint256 rentalStartTime;
        uint256 attachedPlanetId;
        uint256 rentalEndTime; // if 0 and renting, = Orbiting own planet
        uint256 rentalFeeAfterPlatform;
    }

    // this data is saved when
    // the old rental data when renew rental ||
    // the StarOrbitalTrackData updated
    struct StarOrbitalTrackRentedData {
        uint256 slotIndex;
        uint256 planetId;
        uint256 rentalFeeAfterPlatform;
        uint256 oldRentalEndTime; // the old rental end time
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
    function getApproved(uint256 tokenId) external view returns (address operator);

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
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
        __ERC1967Upgrade_init_unchained();
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallSecure(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        address oldImplementation = _getImplementation();

        // Initial upgrade and setup call
        _setImplementation(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }

        // Perform rollback test if not already in progress
        StorageSlotUpgradeable.BooleanSlot storage rollbackTesting = StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT);
        if (!rollbackTesting.value) {
            // Trigger rollback using upgradeTo from the new implementation
            rollbackTesting.value = true;
            _functionDelegateCall(
                newImplementation,
                abi.encodeWithSignature("upgradeTo(address)", oldImplementation)
            );
            rollbackTesting.value = false;
            // Check rollback was effective
            require(oldImplementation == _getImplementation(), "ERC1967Upgrade: upgrade breaks further upgrades");
            // Finally reset to the new implementation and log the upgrade
            _upgradeTo(newImplementation);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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
    uint256[49] private __gap;
}