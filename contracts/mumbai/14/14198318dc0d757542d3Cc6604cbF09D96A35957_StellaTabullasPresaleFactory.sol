// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;
pragma abicoder v2;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";

import "./planets/contracts/utils/MultiWhitelist.sol";
import "./planets/contracts/utils/Random.sol";
import "./interfaces/IApeironStar.sol";
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
    event Sold(uint256 indexed tokenId, address indexed buyer, uint256 price);
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
    IApeironStar public immutable starContract;
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
        starContract = IApeironStar(_starAddress);
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
     * @notice - Reserve NFTs
     *
     * @param _reservedAddress: reserved address
     * @param _reserveCountPerType: array for reserve count per core type
     */
    function reserve(
        address _reservedAddress,
        uint256[] memory _reserveCountPerType
    ) external onlyOwner {
        require(
            _reservedAddress != address(0) && _reserveCountPerType.length == 4,
            "revert arg"
        );

        //reserve some ST
        for (
            uint256 typeIdx = uint256(STType.Regular);
            typeIdx <= uint256(STType.Omega);
            typeIdx++
        ) {
            require(
                getAvailableCount(STType(typeIdx)) >=
                    _reserveCountPerType[typeIdx],
                "stType sold out"
            );

            for (uint256 i = 0; i < _reserveCountPerType[typeIdx]; i++) {
                (uint256 nftIndex, uint256 nftId) = _getTargetStarIndexNId(
                    STType(typeIdx)
                );
                // during presale, 0 = there are no star left
                require(
                    nftId != 0 && _getStarGenIdByStId(nftId) != 0,
                    "stType sold out"
                );

                // star mint to address
                starContract.safeMint(
                    _getStarGenIdByStId(nftId),
                    _reservedAddress,
                    nftId
                );

                // godiverse mint
                uint256[] memory godiverseArray = _convertToGodiverseArray(
                    nftId
                );
                for (uint256 j = 0; j < godiverseArray.length; j++) {
                    if (godiverseArray[j] != 0) {
                        godiverseContract.mint(godiverseArray[j], 1, "");
                        godiverseContract.safeTransferFrom(
                            address(this),
                            _reservedAddress,
                            godiverseArray[j],
                            1,
                            ""
                        );
                    } else {
                        continue;
                    }
                }

                // remove stId from data
                delete (_stTokenIdArrayMap[STType(typeIdx)][nftIndex]);

                // emit event
                emit Reserved(nftId, _reservedAddress);
            }
            // update typeCounter number
            typeCounter[STType(typeIdx)] += _reserveCountPerType[typeIdx];
        }
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

        emit Sold(nftId, msg.sender, price);
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
        uint256[] memory _godiverseGenArray
    ) external onlyOwner {
        require(
            _tokenIdArray.length == typeMax[_stType] &&
                _starGenArray.length == typeMax[_stType] &&
                _godiverseGenArray.length == typeMax[_stType],
            "array is not in correct length"
        );

        // update _stTokenIdArrayMap
        _stTokenIdArrayMap[_stType] = _tokenIdArray;

        // update _stIdStarGenMap
        for (uint256 i = 0; i < _tokenIdArray.length; i++) {
            require(_starGenArray[i] != 0, "star gen should not be zero");
            _stIdStarGenMap[_tokenIdArray[i]] = _starGenArray[i];
        }
        // update _stIdGodiverseMap
        for (uint256 i = 0; i < _tokenIdArray.length; i++) {
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
pragma solidity ^0.8.4;

interface IApeironStar {
    function safeMint(
        uint256 gene,
        address to,
        uint256 tokenId
    ) external;
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