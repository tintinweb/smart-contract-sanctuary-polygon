/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

// File: contracts/Admin/data/GachaStruct.sol


pragma solidity ^0.8.18;

    enum GachaType {
        None,
        Character,
        FateCore
    }

    struct InputGachaInfo {
        uint256 tokenId;
        string name;
        uint256[] tierRatio;
        uint256[][] gachaGradeRatio;
        uint256[] gachaFateCoreRatio;
        uint256[] gachaFateCoreList;
        GachaType gachaType;
        bool isValid;
    }

    struct GachaInfo {
        uint256 tokenId;
        string name;
        uint256[] tierRatio;
        uint256[][] gachaGradeRatio;
        bool isValid;
    }

    struct FateCoreGachaInfo {
        uint256 tokenId;
        string name;
        uint256[] gachaFateCoreRatio;
        uint256[] gachaFateCoreList;
        bool isValid;
    }
// File: @openzeppelin/contracts/utils/math/SafeMath.sol


// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
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
        return a + b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: contracts/Admin/data/PeriodQuestStructV2.sol


pragma solidity ^0.8.18;

    enum CalculateType {
        NONE,
        SET,
        ADD,
        SUB
    }

    enum ConditionType {
        NONE,
        CHARACTER,
        CHARACTER_TIER,
        PACK,
        CHARACTER_ELEMENT,
        CHARACTER_NATION
    }

    enum QuestCategory {
        NONE,
        MISSION,
        REWARD
    }

    enum MissionType {
        NONE,
        BURN,
        STAKE,
        REGIST
    }

    enum TokenType {
        NONE,
        ERC20,
        ERC721,
        ERC1155
    }

    enum QuestType {
        NONE,
        MAIN,
        HIDDEN,
        DAILY,
        WEEKLY,
        PREMIUM,
        GLOBAL
    }

    enum LimitType {
        NONE,
        LIMIT,
        INFINITE
    }

    struct BurnWaitInfo {
        uint256 tokenId;
        uint256 amount;
        uint256 conditionType;
        uint256 slotNo;
    }

    struct StakeInfo {
        uint256 tokenId;
        uint256 amount;
        uint256 conditionType;
    }

    struct Quest {
        uint256 questNo;
        string name;
        uint256 requireQuest;
        uint256 questCategory;
        uint256 stakingTime;
        Reward[] rewards;
        QuestConditionSlot[] questConditionSlot;
    }

    struct Reward {
        uint256 rewardType;
        uint256 reward;
        uint256 rewardAmount;
    }

    struct QuestConditionSlot {
        uint256 questType;       // 미션 타입
        uint256 conditionType;   // 미션 조건 타입
        uint256 conditionValue;  // 미션 조건 값
        uint256 conditionAmount; // 개수
        uint256 subConditionType;
        uint256 subConditionValue;
    }

    struct PeriodQuestInfo {
        uint256 id;
        uint256 requireId;
        uint256 questType;
        uint256 questId;
        uint256 startAt;
        uint256 endAt;
        LimitType userLimitType;
        uint256 userLimit;
        LimitType limitType;
        uint256 limit;
        uint256 finishId;
        bool isValid;
    }

    struct QuestInfo {
        uint256 questNo;
        uint256 startAt;
        uint256 endAt;
        QuestSlotInfo[] slotData;
    }

    struct QuestSlotInfo {
        uint256 tokenId;
        uint256 amount;
        bool isValid;
    }

    struct Dashboard {
        uint256 id;
        uint256 clearCount;
        uint256 userClearCount;
        QuestInfo userQuestInfo;
        BurnWaitInfo[] burnInfo;
        StakeInfo[] stakeInfo;
    }

    struct RewardInfo {
        uint256 goodsType;
        uint256 tokenType;
        address tokenAddress;
        bool isValid;
    }

    struct GetQuestInfos {
        uint256 userClearCount;
        uint256 totalClearCount;
        QuestInfo userQuestInfo;
        Quest questData;
    }

    struct UserClearCount {
        uint256 id;
        uint256 clearCount;
        bool isOpen;
    }

    struct CharacterOwner {
        uint256 id;
        bool isOwner;
    }
// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
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

// File: @openzeppelin/contracts/utils/Address.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol


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

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: contracts/Admin/data/ActorData.sol


pragma solidity ^0.8.18;


contract DspActorData is Ownable {
    event SetGachaTypeById(uint256 indexed id, uint256 indexed gachaType);
    event SetGachaTypeByName(string indexed name, uint256 indexed gachaType);

    struct InputGachaTypeById {
        uint256 id;
        uint256 gachaType;
    }

    struct InputGachaTypeByName {
        string name;
        uint256 gachaType;
    }

    // id => type
    mapping(uint256 => uint256) private gachaTypeById;
    // fate core id => name
    mapping(string => uint256) private gachaTypeByName;


    function getGachaTypeById(uint256 _id) public view returns(uint256) {
        return gachaTypeById[_id];
    }

    function getGachaTypeByName(string memory _name) public view returns(uint256) {
        return gachaTypeByName[_name];
    }

    function getGachaTypeByIds(uint256[] memory _ids) public view returns(uint256[] memory) {
        uint256[] memory gachaTypes = new uint256[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            gachaTypes[i] = gachaTypeById[_ids[i]];
        }
        return gachaTypes;
    }

    function getGachaTypeByNames(string[] memory _names) public view returns(uint256[] memory) {
        uint256[] memory gachaTypes = new uint256[](_names.length);
        for (uint256 i = 0; i < _names.length; i++) {
            gachaTypes[i] = gachaTypeByName[_names[i]];
        }
        return gachaTypes;
    }

    function setGachaTypeById(InputGachaTypeById memory _inputGachaTypeById) external onlyOwner {
        gachaTypeById[_inputGachaTypeById.id] = _inputGachaTypeById.gachaType;
        emit SetGachaTypeById(_inputGachaTypeById.id, _inputGachaTypeById.gachaType);
    }

    function setGachaTypeByIds(InputGachaTypeById[] memory _inputGachaTypeByIds) external onlyOwner {
        for (uint256 i = 0; i < _inputGachaTypeByIds.length; i++) {
            gachaTypeById[_inputGachaTypeByIds[i].id] = _inputGachaTypeByIds[i].gachaType;
            emit SetGachaTypeById(_inputGachaTypeByIds[i].id, _inputGachaTypeByIds[i].gachaType);
        }
    }

    function setGachaTypeByName(InputGachaTypeByName memory _inputGachaTypeByName) external onlyOwner {
        gachaTypeByName[_inputGachaTypeByName.name] = _inputGachaTypeByName.gachaType;
        emit SetGachaTypeByName(_inputGachaTypeByName.name, _inputGachaTypeByName.gachaType);
    }

    function setGachaTypeByNames(InputGachaTypeByName[] memory _inputGachaTypeByNames) external onlyOwner {
        for (uint256 i = 0; i < _inputGachaTypeByNames.length; i++) {
            gachaTypeByName[_inputGachaTypeByNames[i].name] = _inputGachaTypeByNames[i].gachaType;
            emit SetGachaTypeByName(_inputGachaTypeByNames[i].name, _inputGachaTypeByNames[i].gachaType);
        }
    }
}
// File: contracts/Admin/LuxOnService.sol


pragma solidity ^0.8.15;


contract LuxOnService is Ownable {
    mapping(address => bool) isInspection;

    event Inspection(address contractAddress, uint256 timestamp, bool live);

    function isLive(address contractAddress) public view returns (bool) {
        return !isInspection[contractAddress];
    }

    function setInspection(address[] memory contractAddresses, bool _isInspection) external onlyOwner {
        for (uint256 i = 0; i < contractAddresses.length; i++) {
            isInspection[contractAddresses[i]] = _isInspection;
            emit Inspection(contractAddresses[i], block.timestamp, _isInspection);
        }
    }
}
// File: contracts/LUXON/utils/LuxOnLive.sol


pragma solidity ^0.8.16;



contract LuxOnLive is Ownable {
    address private luxOnService;

    event SetLuxOnService(address indexed luxOnService);

    constructor(
        address _luxOnService
    ) {
        luxOnService = _luxOnService;
    }

    function getLuxOnService() public view returns (address) {
        return luxOnService;
    }

    function setLuxOnService(address _luxOnService) external onlyOwner {
        luxOnService = _luxOnService;
        emit SetLuxOnService(_luxOnService);
    }

    modifier isLive() {
        require(LuxOnService(luxOnService).isLive(address(this)), "LuxOnLive: not live");
        _;
    }
}
// File: contracts/Admin/data/QuestCalendarV2.sol


pragma solidity ^0.8.18;



contract QuestCalendar is Ownable {
    uint256 public lastId = 0;
    // id => type
    mapping(uint256 => PeriodQuestInfo) public calendars;

    function getLsatId() public view returns (uint256) {
        return lastId;
    }

    function getQuestCalendar(uint256 id) public view returns (PeriodQuestInfo memory) {
        return calendars[id];
    }

    function getQuestCalendars(uint256[] memory ids) public view returns (PeriodQuestInfo[] memory) {
        PeriodQuestInfo[] memory _calendars = new PeriodQuestInfo[](ids.length);
        for (uint256 i = 0; i < ids.length; i++) {
            _calendars[i] = calendars[ids[i]];
        }
        return _calendars;
    }

    function setQuestInfos(PeriodQuestInfo[] memory periodQuestInfos) external onlyOwner {
        for (uint256 i = 0; i < periodQuestInfos.length; i++) {
            calendars[periodQuestInfos[i].id] = periodQuestInfos[i];
            if (lastId < periodQuestInfos[i].id) {
                lastId = periodQuestInfos[i].id;
            }
        }
    }

    function setQuestInfo(PeriodQuestInfo memory periodQuestInfo) external onlyOwner {
        calendars[periodQuestInfo.id] = periodQuestInfo;
        if (lastId < periodQuestInfo.id) {
            lastId = periodQuestInfo.id;
        }
    }
}
// File: contracts/Admin/data/PeriodQuestDataV2.sol


pragma solidity ^0.8.18;



contract PeriodQuestData is Ownable {
    // quest id => quest
    mapping(uint256 => Quest) questConditionMap;

    function getQuest(uint256 questNo) public view returns (Quest memory) {
        return questConditionMap[questNo];
    }

    function getQuests(uint256[] memory questNo) public view returns (Quest[] memory) {
        Quest[] memory quests = new Quest[](questNo.length);
        for (uint256 i = 0; i < questNo.length; i++) {
            quests[i] = questConditionMap[questNo[i]];
        }
        return quests;
    }

    function setQuestDataMany(Quest[] memory _questData) external onlyOwner {
        for (uint i = 0; i < _questData.length; i++) {
            uint questNo = _questData[i].questNo;
            delete questConditionMap[questNo];
            Quest storage quest_ = questConditionMap[questNo];

            quest_.questNo = questNo;
            quest_.name = _questData[i].name;
            quest_.requireQuest = _questData[i].requireQuest;
            quest_.questCategory = _questData[i].questCategory;
            quest_.stakingTime = _questData[i].stakingTime;
            for (uint j = 0; j < _questData[i].rewards.length; j++) {
                quest_.rewards.push(
                    Reward(
                        _questData[i].rewards[j].rewardType,
                        _questData[i].rewards[j].reward,
                        _questData[i].rewards[j].rewardAmount
                    )
                );
            }

            for (uint j = 0; j < _questData[i].questConditionSlot.length; j++) {
                quest_.questConditionSlot.push(QuestConditionSlot(
                        _questData[i].questConditionSlot[j].questType,
                        _questData[i].questConditionSlot[j].conditionType,
                        _questData[i].questConditionSlot[j].conditionValue,
                        _questData[i].questConditionSlot[j].conditionAmount,
                        _questData[i].questConditionSlot[j].subConditionType,
                        _questData[i].questConditionSlot[j].subConditionValue
                    ));
            }
        }
    }

    function setQuestData(Quest memory _questData) external onlyOwner {
        delete questConditionMap[_questData.questNo];
        Quest storage quest_ = questConditionMap[_questData.questNo];

        quest_.questNo = _questData.questNo;
        quest_.name = _questData.name;
        quest_.requireQuest = _questData.requireQuest;
        quest_.questCategory = _questData.questCategory;
        quest_.stakingTime = _questData.stakingTime;

        for (uint j = 0; j < _questData.rewards.length; j++) {
            quest_.rewards.push(
                Reward(
                    _questData.rewards[j].rewardType,
                    _questData.rewards[j].reward,
                    _questData.rewards[j].rewardAmount
                )
            );
        }

        for (uint j = 0; j < _questData.questConditionSlot.length; j++) {
            quest_.questConditionSlot.push(QuestConditionSlot(
                    _questData.questConditionSlot[j].questType,
                    _questData.questConditionSlot[j].conditionType,
                    _questData.questConditionSlot[j].conditionValue,
                    _questData.questConditionSlot[j].conditionAmount,
                    _questData.questConditionSlot[j].subConditionType,
                    _questData.questConditionSlot[j].subConditionValue
                ));
        }
    }
}
// File: contracts/Admin/data/FateCoreData.sol


pragma solidity ^0.8.18;


contract DspFateCoreData is Ownable {
    event SetFateCoreData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);
    event DeleteFateCoreData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);
    event SetFateCoreName(uint256 indexed id, string indexed name);

    struct FateCoreInfo {
        string name;
        uint256 tier;
        uint256 gachaGrade;
        uint256 classType;
        uint256 nation;
        uint256 element;
        uint256 rootId;
        bool isValid;
    }

    struct FateCoreName {
        uint256 id;
        string name;
    }

    // fate core id => name
    mapping(uint256 => string) private fateCoreName;
    // name => fate core info
    mapping(string => FateCoreInfo) private fateCoreData;
    // tier => gacha grade => name[]
    mapping(uint256 => mapping(uint256 => string[])) private fateCoreInfoTable;

    uint256 private fateCoreCount;

    function getFateCoreInfo(string memory name) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (fateCoreData[name].tier, fateCoreData[name].gachaGrade, fateCoreData[name].classType, fateCoreData[name].nation, fateCoreData[name].element, fateCoreData[name].rootId, fateCoreData[name].isValid);
    }

    function getFateCoreInfoIsValid(string memory name) public view returns(bool) {
        return fateCoreData[name].isValid;
    }

    function getFateCoreName(uint256 id) public view returns (string memory) {
        return fateCoreName[id];
    }

    function setFateCoreName(FateCoreName[] memory _fateCoreName) external onlyOwner {
        for (uint256 i = 0; i < _fateCoreName.length; i++) {
            fateCoreName[_fateCoreName[i].id] = _fateCoreName[i].name;
            emit SetFateCoreName(_fateCoreName[i].id, _fateCoreName[i].name);
        }
    }

    function setFateCoreData(FateCoreInfo[] memory _fateCoreData) external onlyOwner {
        for (uint256 i = 0; i < _fateCoreData.length; i++) {
            require(_fateCoreData[i].isValid, "isValid false use delete");
            if (!fateCoreData[_fateCoreData[i].name].isValid) {
                fateCoreCount++;
            } else if (fateCoreData[_fateCoreData[i].name].tier != _fateCoreData[i].tier) {
                uint256 index;
                uint256 _tier = fateCoreData[_fateCoreData[i].name].tier;
                uint256 _gachaGrade = fateCoreData[_fateCoreData[i].name].gachaGrade;
                for (uint256 j = 0; j < fateCoreInfoTable[_tier][_gachaGrade].length; j++) {
                    if (keccak256(abi.encodePacked(fateCoreInfoTable[_tier][_gachaGrade][j])) == keccak256(abi.encodePacked(_fateCoreData[i].name))) {
                        index = j;
                        break;
                    }
                }
                for (uint256 j = index; j < fateCoreInfoTable[_tier][_gachaGrade].length - 1; j++) {
                    fateCoreInfoTable[_tier][_gachaGrade][j] = fateCoreInfoTable[_tier][_gachaGrade][j + 1];
                }
                fateCoreInfoTable[_tier][_gachaGrade].pop();
            }
            fateCoreInfoTable[_fateCoreData[i].tier][_fateCoreData[i].gachaGrade].push(_fateCoreData[i].name);
            fateCoreData[_fateCoreData[i].name] = _fateCoreData[i];

            emit SetFateCoreData(_fateCoreData[i].name, _fateCoreData[i].tier, _fateCoreData[i].gachaGrade, _fateCoreData[i].classType, _fateCoreData[i].nation, _fateCoreData[i].element, _fateCoreData[i].isValid);
        }
    }

    function deleteFateCoreData(string[] memory names) external onlyOwner {
        for (uint256 i = 0; i < names.length; i++) {
            uint256 _tier = fateCoreData[names[i]].tier;
            uint256 _gachaGrade = fateCoreData[names[i]].gachaGrade;

            uint256 index;
            for (uint256 j = 0; j < fateCoreInfoTable[_tier][_gachaGrade].length; j++) {
                if (keccak256(abi.encodePacked(fateCoreInfoTable[_tier][_gachaGrade][j])) == keccak256(abi.encodePacked(fateCoreData[names[i]].name))) {
                    index = j;
                    break;
                }
            }
            for (uint256 j = index; j < fateCoreInfoTable[_tier][_gachaGrade].length - 1; j++) {
                fateCoreInfoTable[_tier][_gachaGrade][j] = fateCoreInfoTable[_tier][_gachaGrade][j + 1];
            }
            fateCoreInfoTable[_tier][_gachaGrade].pop();
            fateCoreCount--;

            emit DeleteFateCoreData(fateCoreData[names[i]].name, fateCoreData[names[i]].tier, fateCoreData[names[i]].gachaGrade, fateCoreData[names[i]].classType, fateCoreData[names[i]].nation, fateCoreData[names[i]].element, fateCoreData[names[i]].isValid);
            delete fateCoreData[names[i]];
        }
    }

    function getFateCoreCount() public view returns (uint256) {
        return fateCoreCount;
    }

    function getFateCoreCountByTireAndGachaGrade(uint256 _tier, uint256 _gachaGrade) public view returns (uint256) {
        return fateCoreInfoTable[_tier][_gachaGrade].length;
    }

    function getFateCoreInfoByTireAndIndex(uint256 _tier, uint256 _gachaGrade, uint index) public view returns (string memory) {
        return fateCoreInfoTable[_tier][_gachaGrade][index];
    }
}
// File: contracts/Admin/data/ValueChipData.sol


pragma solidity ^0.8.16;


contract DspValueChipData is Ownable {
    event SetValueChipInfo(uint256 indexed tokenId, string indexed name, uint256 indexed valueChipsType, string characterName, uint256 gameEnumByValueChipsType);
    event RemoveValueChipInfo(uint256 indexed tokenId);

    enum ValueChipsType { None, Hero, Class, Nation, Element }
    uint256 private valueChipCount;

    struct InputValueChipInfo {
        uint256 tokenId;
        string name;
        ValueChipsType valueChipsType;
        string characterName;
        uint256 gameEnumByValueChipsType;
        bool isValid;
    }

    struct ValueChipInfo {
        string name;
        ValueChipsType valueChipsType;
        string characterName;
        uint256 gameEnumByValueChipsType;
        bool isValid;
    }

    // tokenId => ValueChipInfo
    mapping(uint256 => ValueChipInfo) private valueChipInfo;
    uint256[] private valueChipTokenIdList;

    function getValueChipCount() public view returns (uint256) {
        return valueChipCount;
    }

    function getValueChipInfo(uint256 _tokenId) public view returns (string memory, uint32, string memory, uint256, bool) {
        return (
        valueChipInfo[_tokenId].name,
        uint32(valueChipInfo[_tokenId].valueChipsType),
        valueChipInfo[_tokenId].characterName,
        valueChipInfo[_tokenId].gameEnumByValueChipsType,
        valueChipInfo[_tokenId].isValid
        );
    }

    function getValueChipsIsValid(uint256 _tokenId) public view returns (bool) {
        return valueChipInfo[_tokenId].isValid;
    }

    function getValueChipValueChipsType(uint256 _tokenId) public view returns (uint32) {
        return uint32(valueChipInfo[_tokenId].valueChipsType);
    }

    function getValueChipTokenIdList() public view returns (uint256[] memory) {
        return valueChipTokenIdList;
    }

    function setValueChipInfo(InputValueChipInfo memory _valueChipInfo) external onlyOwner {
        require(_valueChipInfo.tokenId != 0, "value chip id not valid");
        require(_valueChipInfo.isValid, "value chip not valid");
        if (!valueChipInfo[_valueChipInfo.tokenId].isValid) {
            valueChipCount++;
        }
        valueChipInfo[_valueChipInfo.tokenId] =
        ValueChipInfo(
            _valueChipInfo.name,
            _valueChipInfo.valueChipsType,
            _valueChipInfo.characterName,
            _valueChipInfo.gameEnumByValueChipsType,
            _valueChipInfo.isValid
        );
        emit SetValueChipInfo(_valueChipInfo.tokenId, _valueChipInfo.name, uint256(_valueChipInfo.valueChipsType), _valueChipInfo.characterName, _valueChipInfo.gameEnumByValueChipsType);
    }

    function setValueChipInfos(InputValueChipInfo[] memory _valueChipInfos) external onlyOwner {
        for (uint256 i = 0; i < _valueChipInfos.length; i++) {
            require(_valueChipInfos[i].tokenId != 0, "value chip id not valid");
            require(_valueChipInfos[i].isValid, "value chip not valid");
            if (!valueChipInfo[_valueChipInfos[i].tokenId].isValid) {
                valueChipCount++;
                valueChipTokenIdList.push(_valueChipInfos[i].tokenId);
            }
            valueChipInfo[_valueChipInfos[i].tokenId] =
            ValueChipInfo(
                _valueChipInfos[i].name,
                _valueChipInfos[i].valueChipsType,
                _valueChipInfos[i].characterName,
                _valueChipInfos[i].gameEnumByValueChipsType,
                _valueChipInfos[i].isValid
            );
            emit SetValueChipInfo(_valueChipInfos[i].tokenId, _valueChipInfos[i].name, uint256(_valueChipInfos[i].valueChipsType), _valueChipInfos[i].characterName, _valueChipInfos[i].gameEnumByValueChipsType);
        }
    }

    function removeValueChipInfo(uint256 _tokenId) external onlyOwner {
        require(_tokenId != 0, "gacha ticket id not valid");
        if (valueChipInfo[_tokenId].isValid) {
            valueChipCount--;
            uint256 index;
            for (uint256 i = 0; i < valueChipTokenIdList.length; i++) {
                if (valueChipTokenIdList[i] == _tokenId) {
                    index = i;
                }
            }
            for (uint256 i = index; i < valueChipTokenIdList.length - 1; i++) {
                valueChipTokenIdList[i] = valueChipTokenIdList[i + 1];
            }
            valueChipTokenIdList.pop();
        }
        emit RemoveValueChipInfo(_tokenId);
        delete valueChipInfo[_tokenId];
    }
}
// File: contracts/Admin/LuxOnAdmin.sol


pragma solidity ^0.8.16;


contract LuxOnAdmin is Ownable {

    mapping(string => mapping(address => bool)) private _superOperators;

    event SuperOperator(string operator, address superOperator, bool enabled);

    function setSuperOperator(string memory operator, address[] memory _operatorAddress, bool enabled) external onlyOwner {
        for (uint256 i = 0; i < _operatorAddress.length; i++) {
            _superOperators[operator][_operatorAddress[i]] = enabled;
            emit SuperOperator(operator, _operatorAddress[i], enabled);
        }
    }

    function isSuperOperator(string memory operator, address who) public view returns (bool) {
        return _superOperators[operator][who];
    }
}
// File: contracts/LUXON/utils/LuxOnSuperOperators.sol


pragma solidity ^0.8.16;



contract LuxOnSuperOperators is Ownable {

    event SetLuxOnAdmin(address indexed luxOnAdminAddress);
    event SetOperator(string indexed operator);

    address private luxOnAdminAddress;
    string private operator;

    constructor(
        string memory _operator,
        address _luxOnAdminAddress
    ) {
        operator = _operator;
        luxOnAdminAddress = _luxOnAdminAddress;
    }

    modifier onlySuperOperator() {
        require(LuxOnAdmin(luxOnAdminAddress).isSuperOperator(operator, msg.sender), "LuxOnSuperOperators: not super operator");
        _;
    }

    function getLuxOnAdmin() public view returns (address) {
        return luxOnAdminAddress;
    }

    function getOperator() public view returns (string memory) {
        return operator;
    }

    function setLuxOnAdmin(address _luxOnAdminAddress) external onlyOwner {
        luxOnAdminAddress = _luxOnAdminAddress;
        emit SetLuxOnAdmin(_luxOnAdminAddress);
    }

    function setOperator(string memory _operator) external onlyOwner {
        operator = _operator;
        emit SetOperator(_operator);
    }

    function isSuperOperator(address spender) public view returns (bool) {
        return LuxOnAdmin(luxOnAdminAddress).isSuperOperator(operator, spender);
    }
}
// File: contracts/Admin/data/DataAddress.sol


pragma solidity ^0.8.16;


contract DspDataAddress is Ownable {

    event SetDataAddress(string indexed name, address indexed dataAddress, bool indexed isValid);

    struct DataAddressInfo {
        string name;
        address dataAddress;
        bool isValid;
    }

    mapping(string => DataAddressInfo) private dataAddresses;

    function getDataAddress(string memory _name) public view returns (address) {
        require(dataAddresses[_name].isValid, "this data address is not valid");
        return dataAddresses[_name].dataAddress;
    }

    function setDataAddress(DataAddressInfo memory _dataAddressInfo) external onlyOwner {
        dataAddresses[_dataAddressInfo.name] = _dataAddressInfo;
        emit SetDataAddress(_dataAddressInfo.name, _dataAddressInfo.dataAddress, _dataAddressInfo.isValid);
    }

    function setDataAddresses(DataAddressInfo[] memory _dataAddressInfos) external onlyOwner {
        for (uint256 i = 0; i < _dataAddressInfos.length; i++) {
            dataAddresses[_dataAddressInfos[i].name] = _dataAddressInfos[i];
            emit SetDataAddress(_dataAddressInfos[i].name, _dataAddressInfos[i].dataAddress, _dataAddressInfos[i].isValid);
        }
    }
}
// File: contracts/LUXON/utils/LuxOnData.sol


pragma solidity ^0.8.16;



contract LuxOnData is Ownable {
    address private luxonData;
    event SetLuxonData(address indexed luxonData);

    constructor(
        address _luxonData
    ) {
        luxonData = _luxonData;
    }

    function getLuxOnData() public view returns (address) {
        return luxonData;
    }

    function setLuxOnData(address _luxonData) external onlyOwner {
        luxonData = _luxonData;
        emit SetLuxonData(_luxonData);
    }

    function getDataAddress(string memory _name) public view returns (address) {
        return DspDataAddress(luxonData).getDataAddress(_name);
    }
}
// File: contracts/LUXON/quest/PeriodQuestStorageV2.sol


pragma solidity ^0.8.18;







contract PeriodQuestStorage is LuxOnSuperOperators, LuxOnData {
    event SetStakeInfo(address indexed userAddress, uint256 indexed id, uint256 indexed tokenId, uint256 amt, uint256 conditionType);
    event SetBurnWaitList(address indexed userAddress, uint256 indexed id, uint256 indexed tokenId, uint256 amt, uint256 questType, uint256 idx);
    event SetSlotData(address indexed userAddress, uint256 indexed id, uint256 indexed tokenId, uint256 amt, uint256 idx);
    event SetClear(address indexed userAddress, uint256 indexed id);
    event CancelQuest(address indexed userAddress, uint256 indexed id);
    event SoldOut(uint256 indexed questType, uint256 indexed id, uint256 indexed remainCount);

    using SafeMath for uint256;

    // address => quest id
    mapping(address => uint256[]) public userQuestClearInfo;
    mapping(address => mapping(uint256 => bool)) public userQuestClearState;
    // address => id => count
    mapping(address => mapping(uint256 => uint256)) public userClearCount;
    // address => type => clear
    mapping(address => mapping(uint256 => uint256[])) public userPeriodClearInfo;
    mapping(address => mapping(uint256 => uint256)) public userPeriodClearTime;

    // id => count
    mapping(uint256 => uint256) public questClearCount;
    // address => id => quest info
    mapping(address => mapping(uint256 => QuestInfo)) public userQuestInfo;
    mapping(address => mapping(uint256 => StakeInfo[])) public userStakeInfo;
    mapping(address => mapping(uint256 => BurnWaitInfo[])) public userBurnWaitList;
    uint256 constant HOUR = 3600;

    uint256 public soldOutCount = 3;

    constructor(
        address dataAddress,
        string memory operator,
        address luxOnAdmin
    ) LuxOnData(dataAddress) LuxOnSuperOperators(operator, luxOnAdmin) {}

    function getQuestCount(uint256 id) public view returns (uint256) {
        //PeriodQuestInfo memory periodQuestInfo = QuestCalendar(getDataAddress("QuestCalendar")).getQuestCalendar(id);
        return questClearCount[id];
    }

    function getQuestCounts(uint256[] memory ids) public view returns (uint256[] memory) {
        uint256[] memory counts = new uint256[](ids.length);
        //PeriodQuestInfo[] memory periodQuestInfos = QuestCalendar(getDataAddress("QuestCalendar")).getQuestCalendars(ids);
        for (uint256 i = 0; i < ids.length; i++) {
            counts[i] = questClearCount[ids[i]];
        }
        return counts;
    }

    function getClearState(address _address, uint256 id) public view returns (bool) {
        return userQuestClearState[_address][id];
    }

    function getClearCount(address _address, uint256 id) public view returns (uint256) {
        return userClearCount[_address][id];
    }

    function getQuestStorage(address _address, uint256 id) public view returns (QuestInfo memory) {
        return userQuestInfo[_address][id];
    }

    function getBurnInfo(address _address, uint256 id) public view returns(BurnWaitInfo[] memory) {
        return userBurnWaitList[_address][id];
    }

    function getStakingInfo(address _address, uint256 id) public view returns (StakeInfo[] memory) {
        return userStakeInfo[_address][id];
    }

    function getClearQuestList(address _address) public view returns (uint256[] memory) {
        return userQuestClearInfo[_address];
    }

    function getUserPeriodClearInfo(address _address, uint256 questType) public view returns (uint256[] memory) {
        return userPeriodClearInfo[_address][questType];
    }

    function getUserPeriodClearTime(address _address, uint256 questType) public view returns (uint256) {
        return userPeriodClearTime[_address][questType];
    }

    function getClearCondition(address user, uint256 currentId, uint256 requireId, uint256 finishId) public view returns (uint256, uint256, uint256, uint256) {
        return (
        getQuestCount(finishId),
        getClearCount(user, currentId),
        getClearCount(user, requireId),
        getClearCount(user, finishId)
        );
    }

    function resetUserPeriodClearInfo(address _address, uint256 questType) external onlySuperOperator {
        if (0 != userPeriodClearInfo[_address][questType].length) {
            delete userPeriodClearInfo[_address][questType];
        }
    }

    function setSoldOutCount(uint256 _soldOutCount) external onlySuperOperator {
        soldOutCount = _soldOutCount;
    }

    function setClearQuestList(address _address, uint256[] memory ids, uint256 questType, bool isClear) external onlySuperOperator {
        // PeriodQuestInfo[] memory calendars = QuestCalendar(getDataAddress("QuestCalendar")).getQuestCalendars(ids);
        for (uint256 i = 0; i < ids.length; i++) {
            if (isClear) {
                if (!userQuestClearState[_address][ids[i]]) {
                    userQuestClearInfo[_address].push(ids[i]);
                    userPeriodClearInfo[_address][questType].push(ids[i]);
                    userQuestClearState[_address][ids[i]] = true;
                }
                userPeriodClearTime[_address][questType] = block.timestamp;
                userClearCount[_address][ids[i]]++;
                questClearCount[ids[i]]++;
            } else if (!isClear && 0 != userClearCount[_address][ids[i]]) {
                for (uint256 j = 0; j < userQuestClearInfo[_address].length; j++) {
                    if (userQuestClearInfo[_address][j] == ids[i]) {
                        userQuestClearInfo[_address][j] = userQuestClearInfo[_address][userQuestClearInfo[_address].length - 1];
                        userQuestClearInfo[_address].pop();
                        break;
                    }
                }
                for (uint256 j = 0; j < userPeriodClearInfo[_address][questType].length; j++) {
                    if (userPeriodClearInfo[_address][questType][j] == ids[i]) {
                        userPeriodClearInfo[_address][questType][j] = userPeriodClearInfo[_address][questType][userPeriodClearInfo[_address][questType].length - 1];
                        userPeriodClearInfo[_address][questType].pop();
                        break;
                    }
                }
                userPeriodClearTime[_address][questType] = block.timestamp;
                userClearCount[_address][ids[i]]--;
                if (0 == userClearCount[_address][ids[i]]) {
                    userQuestClearState[_address][ids[i]] = false;
                }
                questClearCount[ids[i]]--;
            }
        }
    }

    function setClearCount(CalculateType setType, uint256 id, uint256 count) external onlySuperOperator {
        if (CalculateType.SET == setType) {
            questClearCount[id] = count;
        } else if (CalculateType.ADD == setType) {
            questClearCount[id] += count;
        } else if (CalculateType.SUB == setType) {
            questClearCount[id] -= count;
        }
    }

    function setStakeInfo(address _address, uint256 id, uint256 _tokenId, uint256 _amt, uint256 _conditionType) external onlySuperOperator {
        userStakeInfo[_address][id].push(StakeInfo(_tokenId, _amt, _conditionType));
        emit SetStakeInfo(_address, id, _tokenId, _amt, _conditionType);
    }

    function setBurnWaitList(address _address, uint256 id, uint256 _tokenId, uint256 _amt, uint256 _questType, uint256 _idx) external onlySuperOperator {
        userBurnWaitList[_address][id].push(BurnWaitInfo(_tokenId, _amt, _questType, _idx));
        emit SetBurnWaitList(_address, id, _tokenId, _amt, _questType, _idx);
    }

    function setSlotData(address _address, uint256 id, uint256 _tokenId, uint256 _amt, uint256 _idx) external onlySuperOperator {
        userQuestInfo[_address][id].slotData.push(QuestSlotInfo(_tokenId, _amt, true));
        emit SetSlotData(_address, id, _tokenId, _amt, _idx);
    }

    function setClear(address _address, uint256 id, uint256 finishId, uint256 questType) external onlySuperOperator {
        if (!userQuestClearState[_address][id]) {
            userQuestClearInfo[_address].push(id);
            userPeriodClearInfo[_address][questType].push(id);
            userQuestClearState[_address][id] = true;
        }
        userClearCount[_address][id]++;
        questClearCount[id]++;
        if (finishId == id) {
            PeriodQuestInfo memory calendar = QuestCalendar(getDataAddress("QuestCalendar")).getQuestCalendar(id);
            if (LimitType.LIMIT == calendar.limitType && calendar.limit - soldOutCount < questClearCount[id]) {
                emit SoldOut(questType, id, calendar.limit - questClearCount[id]);
            }
        }
        userPeriodClearTime[_address][questType] = block.timestamp;
        deleteQuest(_address, id);
        emit SetClear(_address, id);
    }

    function cancelQuest(address _address, uint256 id) external onlySuperOperator {
        require(id == userQuestInfo[_address][id].questNo, "INVALID questNo");
        deleteQuest(_address, id);
        emit CancelQuest(_address, id);
    }

    function deleteQuest(address _address, uint256 id) private {
        delete userQuestInfo[_address][id];
        delete userBurnWaitList[_address][id];
        delete userStakeInfo[_address][id];
    }

    function startQuest(address _address, uint256 id, uint256 stakingTime) external onlySuperOperator {
        userQuestInfo[_address][id].questNo = id;
        userQuestInfo[_address][id].startAt = block.timestamp;
        userQuestInfo[_address][id].endAt = block.timestamp.add(HOUR.mul(stakingTime));
    }
}

// File: contracts/Admin/data/CharacterData.sol


pragma solidity ^0.8.16;




contract DspCharacterData is Ownable, LuxOnData {
    event SetCharacterData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);
    event DeleteCharacterData(string indexed name, uint256 indexed tier, uint256 indexed gachaGrade, uint256 classType, uint256 nation, uint256 element, bool isValid);
    event SetCharacterName(uint256 indexed id, string indexed name);

    struct CharacterInfo {
        string name;
        uint256 tier;
        uint256 gachaGrade;
        uint256 classType;
        uint256 nation;
        uint256 element;
        uint256 rootId;
        bool isValid;
    }

    struct CharacterName {
        uint256 id;
        string name;
    }

    struct MatchValueChip {
        string name;
        uint256 valueChipId;
    }

    constructor(address dataAddress) LuxOnData(dataAddress) {}

    string public valueChipData = "DspValueChipData";

    // character id => name
    mapping(uint256 => string) private characterName;
    // name => character info
    mapping(string => CharacterInfo) private characterData;
    // tier => gacha grade => name[]
    mapping(uint256 => mapping(uint256 => string[])) private characterInfoTable;
    // name => value chip
    mapping(string => uint256) private matchValueChip;

    uint256 private characterCount;

    function getCharacterInfo(string memory name) public view returns(uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        return (characterData[name].tier, characterData[name].gachaGrade, characterData[name].classType, characterData[name].nation, characterData[name].element, characterData[name].rootId, characterData[name].isValid);
    }

    function getCharacterInfoIsValid(string memory name) public view returns(bool) {
        return characterData[name].isValid;
    }

    function getCharacterName(uint256 id) public view returns (string memory) {
        return characterName[id];
    }

    function setMatchValueChip(MatchValueChip[] memory _matchValueChips) external onlyOwner {
        address valueChipAddress = getDataAddress(valueChipData);
        for (uint256 i = 0; i < _matchValueChips.length; i++) {
            ( , uint32 _valueChipsType, string memory _characterName, , bool _isValid) = DspValueChipData(valueChipAddress).getValueChipInfo(_matchValueChips[i].valueChipId);
            if (
                _isValid &&
                _valueChipsType == uint32(DspValueChipData.ValueChipsType.Hero) &&
                uint(keccak256(abi.encodePacked(_characterName))) == uint(keccak256(abi.encodePacked(_matchValueChips[i].name)))
            ) {
                matchValueChip[_matchValueChips[i].name] = _matchValueChips[i].valueChipId;
            }
        }
    }

    function setCharacterName(CharacterName[] memory _characterName) external onlyOwner {
        for (uint256 i = 0; i < _characterName.length; i++) {
            characterName[_characterName[i].id] = _characterName[i].name;
            emit SetCharacterName(_characterName[i].id, _characterName[i].name);
        }
    }

    function setCharacterData(CharacterInfo[] memory _characterData) external onlyOwner {
        for (uint256 i = 0; i < _characterData.length; i++) {
            require(_characterData[i].isValid, "isValid false use delete");
            if (!characterData[_characterData[i].name].isValid) {
                characterCount++;
            } else if (characterData[_characterData[i].name].tier != _characterData[i].tier) {
                uint256 index;
                uint256 _tier = characterData[_characterData[i].name].tier;
                uint256 _gachaGrade = characterData[_characterData[i].name].gachaGrade;
                for (uint256 j = 0; j < characterInfoTable[_tier][_gachaGrade].length; j++) {
                    if (keccak256(abi.encodePacked(characterInfoTable[_tier][_gachaGrade][j])) == keccak256(abi.encodePacked(_characterData[i].name))) {
                        index = j;
                        break;
                    }
                }
                for (uint256 j = index; j < characterInfoTable[_tier][_gachaGrade].length - 1; j++) {
                    characterInfoTable[_tier][_gachaGrade][j] = characterInfoTable[_tier][_gachaGrade][j + 1];
                }
                characterInfoTable[_tier][_gachaGrade].pop();
            }
            characterInfoTable[_characterData[i].tier][_characterData[i].gachaGrade].push(_characterData[i].name);
            characterData[_characterData[i].name] = _characterData[i];

            emit SetCharacterData(_characterData[i].name, _characterData[i].tier, _characterData[i].gachaGrade, _characterData[i].classType, _characterData[i].nation, _characterData[i].element, _characterData[i].isValid);
        }
    }

    function deleteCharacterData(string[] memory names) external onlyOwner {
        for (uint256 i = 0; i < names.length; i++) {
            uint256 _tier = characterData[names[i]].tier;
            uint256 _gachaGrade = characterData[names[i]].gachaGrade;

            uint256 index;
            for (uint256 j = 0; j < characterInfoTable[_tier][_gachaGrade].length; j++) {
                if (keccak256(abi.encodePacked(characterInfoTable[_tier][_gachaGrade][j])) == keccak256(abi.encodePacked(characterData[names[i]].name))) {
                    index = j;
                    break;
                }
            }
            for (uint256 j = index; j < characterInfoTable[_tier][_gachaGrade].length - 1; j++) {
                characterInfoTable[_tier][_gachaGrade][j] = characterInfoTable[_tier][_gachaGrade][j + 1];
            }
            characterInfoTable[_tier][_gachaGrade].pop();
            characterCount--;

            emit DeleteCharacterData(characterData[names[i]].name, characterData[names[i]].tier, characterData[names[i]].gachaGrade, characterData[names[i]].classType, characterData[names[i]].nation, characterData[names[i]].element, characterData[names[i]].isValid);
            delete characterData[names[i]];
        }
    }

    function getMatchValueChip(string memory _name) public view returns (uint256) {
        return matchValueChip[_name];
    }

    function getCharacterCount() public view returns (uint256) {
        return characterCount;
    }

    function getCharacterCountByTireAndGachaGrade(uint256 _tier, uint256 _gachaGrade) public view returns (uint256) {
        return characterInfoTable[_tier][_gachaGrade].length;
    }

    function getCharacterInfoByTireAndIndex(uint256 _tier, uint256 _gachaGrade, uint index) public view returns (string memory) {
        return characterInfoTable[_tier][_gachaGrade][index];
    }
}
// File: contracts/LUXON/utils/IERC20LUXON.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.16;

interface IERC20LUXON {
    function paybackFrom() external view returns (address);

    function addAllowanceIfNeeded(address owner, address spender, uint256 amountNeeded) external returns (bool success);
    function approveFor(address owner, address spender, uint256 amount) external returns (bool success);

    function paybackByMint(address to, uint256 amount) external;
    function paybackByTransfer(address to, uint256 amount) external;
    function burnFor(address owner, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

// File: contracts/LUXON/utils/IERC1155LUXON.sol


pragma solidity ^0.8.16;

interface IERC1155LUXON {
    function safeTransferFrom(address from, address to, uint256 tokenId, uint256 amount, bytes memory data) external;
    function getValueChipType() external view returns(uint32);
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;
}
// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

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

// File: @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: contracts/LUXON/utils/ERC721LUXON.sol


pragma solidity ^0.8.13;









    error ApprovalCallerNotOwnerNorApproved();
    error ApprovalQueryForNonexistentToken();
    error ApproveToCaller();
    error ApprovalToCurrentOwner();
    error BalanceQueryForZeroAddress();
    error MintToZeroAddress();
    error MintZeroQuantity();
    error OwnerQueryForNonexistentToken();
    error TransferCallerNotOwnerNorApproved();
    error TransferFromIncorrectOwner();
    error TransferToNonERC721ReceiverImplementer();
    error TransferToZeroAddress();
    error URIQueryForNonexistentToken();

contract ERC721LUXON is Context, ERC165, IERC721, IERC721Metadata, LuxOnSuperOperators {
    string private baseURI = "";

    constructor(
        string memory name_,
        string memory symbol_,
        string memory operator,
        address luxOnAdmin
    ) LuxOnSuperOperators(operator, luxOnAdmin) {
        _name = name_;
        _symbol = symbol_;
        _currentIndex = _startTokenId();
    }

    using Address for address;
    using Strings for uint256;

    struct TokenOwnership {
        address addr;
        uint64 startTimestamp;
        bool burned;
    }

    struct AddressData {
        uint64 balance;
        uint64 numberMinted;
        uint64 numberBurned;
        uint64 aux;
    }

    uint256 internal _currentIndex;
    uint256 internal _burnCounter;
    string private _name;
    string private _symbol;
    mapping(uint256 => TokenOwnership) internal _ownerships;
    mapping(address => AddressData) private _addressData;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    function _startTokenId() internal pure returns (uint256) {
        return 1;
    }

    function totalSupply() public view returns (uint256) {
    unchecked {
        return _currentIndex - _burnCounter - _startTokenId();
    }
    }

    function _totalMinted() internal view returns (uint256) {
    unchecked {
        return _currentIndex - _startTokenId();
    }
    }

    function nextTokenId() public view returns (uint256) {
        return _currentIndex;
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC165, IERC165) returns (bool) {
        return
        interfaceId == type(IERC721).interfaceId ||
        interfaceId == type(IERC721Metadata).interfaceId ||
        super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(_addressData[owner].balance);
    }

    function _numberMinted(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberMinted);
    }

    function _numberBurned(address owner) internal view returns (uint256) {
        return uint256(_addressData[owner].numberBurned);
    }

    function _getAux(address owner) internal view returns (uint64) {
        return _addressData[owner].aux;
    }

    function _setAux(address owner, uint64 aux) internal {
        _addressData[owner].aux = aux;
    }

    function _ownershipOf(uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;

    unchecked {
        if (_startTokenId() <= curr && curr < _currentIndex) {
            TokenOwnership memory ownership = _ownerships[curr];
            if (!ownership.burned) {
                if (ownership.addr != address(0)) {
                    return ownership;
                }
                while (true) {
                    curr--;
                    ownership = _ownerships[curr];
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                }
            }
        }
    }
        revert OwnerQueryForNonexistentToken();
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _ownershipOf(tokenId).addr;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        if (!_exists(tokenId)) revert URIQueryForNonexistentToken();
        return bytes(baseURI).length != 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : '';
    }

    function approve(address to, uint256 tokenId) public override {
        address owner = ERC721LUXON.ownerOf(tokenId);
        if (to == owner) revert ApprovalToCurrentOwner();

        if (_msgSender() != owner && !isApprovedForAll(owner, _msgSender())) {
            revert ApprovalCallerNotOwnerNorApproved();
        }

        _approve(to, tokenId, owner);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        if (!_exists(tokenId)) revert ApprovalQueryForNonexistentToken();

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        if (operator == _msgSender()) revert ApproveToCaller();

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        safeTransferFrom(from, to, tokenId, '');
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override {
        _transfer(from, to, tokenId);
        if (to.isContract() && !_checkContractOnERC721Received(from, to, tokenId, _data)) {
            revert TransferToNonERC721ReceiverImplementer();
        }
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _startTokenId() <= tokenId && tokenId < _currentIndex && !_ownerships[tokenId].burned;
    }

    function _safeMint(address to, uint256 quantity) internal {
        _safeMint(to, quantity, '');
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
        _mint(to, quantity, _data, true);
    }

    function _mint(
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        uint256 startTokenId = _currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    unchecked {
        _addressData[to].balance += uint64(quantity);
        _addressData[to].numberMinted += uint64(quantity);

        _ownerships[startTokenId].addr = to;
        _ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

        uint256 updatedIndex = startTokenId;
        uint256 end = updatedIndex + quantity;

        if (safe && to.isContract()) {
            do {
                emit Transfer(address(0), to, updatedIndex);
                if (!_checkContractOnERC721Received(address(0), to, updatedIndex++, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
            } while (updatedIndex != end);
            if (_currentIndex != startTokenId) revert();
        } else {
            do {
                emit Transfer(address(0), to, updatedIndex++);
            } while (updatedIndex != end);
        }
        _currentIndex = updatedIndex;
    }
        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();

        bool isApprovedOrOwner = (_msgSender() == from ||
        isApprovedForAll(from, _msgSender()) ||
        getApproved(tokenId) == _msgSender() ||
        isSuperOperator(_msgSender()));

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(from, to, tokenId, 1);

        _approve(address(0), tokenId, from);

    unchecked {
        _addressData[from].balance -= 1;
        _addressData[to].balance += 1;

        TokenOwnership storage currSlot = _ownerships[tokenId];
        currSlot.addr = to;
        currSlot.startTimestamp = uint64(block.timestamp);

        uint256 _nextTokenId = tokenId + 1;
        TokenOwnership storage nextSlot = _ownerships[_nextTokenId];
        if (nextSlot.addr == address(0)) {
            if (_nextTokenId != _currentIndex) {
                nextSlot.addr = from;
                nextSlot.startTimestamp = prevOwnership.startTimestamp;
            }
        }
    }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(from, to, tokenId, 1);
    }

    function _burn(uint256 tokenId) internal {
        _burn(tokenId, false);
    }

    function _burn(uint256 tokenId, bool approvalCheck) internal {
        TokenOwnership memory prevOwnership = _ownershipOf(tokenId);

        address from = prevOwnership.addr;

        if (approvalCheck) {
            bool isApprovedOrOwner = (_msgSender() == from ||
            isApprovedForAll(from, _msgSender()) ||
            getApproved(tokenId) == _msgSender() ||
            isSuperOperator(_msgSender()));

            if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        }

        _beforeTokenTransfers(from, address(0), tokenId, 1);

        _approve(address(0), tokenId, from);

    unchecked {
        AddressData storage addressData = _addressData[from];
        addressData.balance -= 1;
        addressData.numberBurned += 1;

        TokenOwnership storage currSlot = _ownerships[tokenId];
        currSlot.addr = from;
        currSlot.startTimestamp = uint64(block.timestamp);
        currSlot.burned = true;

        uint256 _nextTokenId = tokenId + 1;
        TokenOwnership storage nextSlot = _ownerships[_nextTokenId];
        if (nextSlot.addr == address(0)) {
            if (_nextTokenId != _currentIndex) {
                nextSlot.addr = from;
                nextSlot.startTimestamp = prevOwnership.startTimestamp;
            }
        }
    }

        emit Transfer(from, address(0), tokenId);
        _afterTokenTransfers(from, address(0), tokenId, 1);

    unchecked {
        _burnCounter++;
    }
    }

    function _approve(
        address to,
        uint256 tokenId,
        address owner
    ) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function _checkContractOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
            return retval == IERC721Receiver(to).onERC721Received.selector;
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert TransferToNonERC721ReceiverImplementer();
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }

    function _beforeTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal {}

    function _afterTokenTransfers(
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal {}

    function setBaseURI(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
    }

    function _baseURI() internal view returns (string memory) {
        return baseURI;
    }
}

// File: contracts/LUXON/myPage/character/LCT.sol


pragma solidity ^0.8.13;


contract LCT is ERC721LUXON {

    event MintByCharacterName(address indexed mintUser, uint256 indexed tokenId, string indexed name);
    event BurnCharacter(uint256 indexed tokenId, string indexed name);
    event SetCharacterName(uint256 indexed tokenId, string indexed name);

    struct Character {
        uint256 tokenId;
        string name;
    }

    constructor(
        string memory operator,
        address luxOnAdmin
    ) ERC721LUXON("Lux-On Character NFT", "LCT", operator, luxOnAdmin) {}

    mapping(uint256 => string) characterInfo;

    function mintByCharacterName(address mintUser, uint256 quantity, string[] memory characterName) external onlySuperOperator {
        require(characterName.length == quantity, "quantity != gacha count");
        uint256 tokenId = nextTokenId();
        for (uint8 i = 0; i < quantity; i++) {
            emit MintByCharacterName(mintUser, tokenId, characterName[i]);
            characterInfo[tokenId++] = characterName[i];
        }
        _safeMint(mintUser, quantity);
    }

    function mint(address mintUser, uint256 quantity) external onlySuperOperator {
        _safeMint(mintUser, quantity);
    }

    function getCharacterInfo(uint256 tokenId) public view returns (string memory) {
        return characterInfo[tokenId];
    }

    function getCharacterInfos(uint256[] memory tokenIds) public view returns (string[] memory) {
        string[] memory names = new string[](tokenIds.length);
        for (uint256 i = 0; i < tokenIds.length; i++) {
            names[i] = characterInfo[tokenIds[i]];
        }
        return names;
    }

    function burnCharacter(uint256 tokenId) external onlySuperOperator {
        _burn(tokenId);
        emit BurnCharacter(tokenId, characterInfo[tokenId]);
        delete characterInfo[tokenId];
    }

    function setCharacterName(Character[] memory _character) external onlySuperOperator {
        for (uint256 i = 0; i < _character.length; i++) {
            characterInfo[_character[i].tokenId] = _character[i].name;
            emit SetCharacterName(_character[i].tokenId, _character[i].name);
        }
    }
}
// File: @openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;


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

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Receiver.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;



/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// File: @openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;


/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// File: contracts/LUXON/quest/PeriodQuestV3.sol


pragma solidity ^0.8.18;
















contract PeriodQuest is ReentrancyGuard, LuxOnData, ERC1155Holder, LuxOnLive {
    event EnterQuest(address indexed user, uint256 indexed id);
    event ClearQuest(address indexed user, uint256 indexed id);
    event CancelQuest(address indexed user, uint256 indexed id);

    event SendReward(address indexed user, address indexed to, address indexed tokenAddress, uint256 tokenType, uint256 reward, uint256 rewardAmount);
    event TransferFromByType(address indexed from, address indexed to, address indexed tokenAddress, uint256 tokenId, uint256 amount, uint256 conditionType);

    address constant burnAddress = 0x000000000000000000000000000000000000dEaD;
    uint256 constant errorNo = 9999;

    address public lctAddress;
    address public gachaTicketAddress;
    PeriodQuestStorage public questStorage;

    // goods type => address
    mapping(uint256 => RewardInfo) public rewardAddresses;

    constructor(
        address dataAddress,
        address luxonService,
        address _lctAddress,
        address _gachaTicketAddress,
        address _questStorage
    ) LuxOnData(dataAddress) LuxOnLive(luxonService) {
        lctAddress = _lctAddress;
        gachaTicketAddress = _gachaTicketAddress;
        questStorage = PeriodQuestStorage(_questStorage);
    }

    function setRewardAddress(RewardInfo[] memory rewardInfos) external onlyOwner {
        for (uint256 i = 0; i < rewardInfos.length; i++) {
            rewardAddresses[rewardInfos[i].goodsType] = rewardInfos[i];
        }
    }

    function setQuestStorageAddress(address _questStorage) external onlyOwner {
        questStorage = PeriodQuestStorage(_questStorage);
    }

    function setLctAddress(address _lctAddress) external onlyOwner {
        lctAddress = _lctAddress;
    }
    function setGachaTicketAddress(address _gachaTicketAddress) external onlyOwner {
        gachaTicketAddress = _gachaTicketAddress;
    }

    function withdraw() external onlyOwner nonReentrant {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function enterQuest(uint256 id, uint256[] memory _tokenIds) public nonReentrant isLive {
        PeriodQuestInfo memory pqi = QuestCalendar(getDataAddress("QuestCalendar")).getQuestCalendar(id);
        checkEnterQuestValid(pqi);
        if (questStorage.getUserPeriodClearTime(msg.sender, pqi.questType) < pqi.startAt) {
            questStorage.resetUserPeriodClearInfo(msg.sender, pqi.questType);
        }
        Quest memory qD = PeriodQuestData(getDataAddress("PeriodQuestData")).getQuest(pqi.questId);
        require(qD.questConditionSlot.length == _tokenIds.length, "not valid token count");
        if (uint256(QuestCategory.REWARD) == qD.questCategory) {
            questStorage.setClear(msg.sender, id, pqi.finishId, pqi.questType);
            sendReward(msg.sender, qD.rewards);
        } else {
            address dspActerDataAddress = getDataAddress("DspActorData");
            address dspCharacterDataAddress = getDataAddress("DspCharacterData");
            address dspFateCoreDataAddress = getDataAddress("DspFateCoreData");
            questStorage.startQuest(msg.sender, id, qD.stakingTime);
            QuestInfo memory qI = questStorage.getQuestStorage(msg.sender, id);
            require(0 == qI.slotData.length, "Error : completion condition.");
            for (uint i = 0; i < _tokenIds.length; i++) {
                require(0 != _tokenIds[i], "INVALID tokenId");
                string memory name = LCT(lctAddress).getCharacterInfo(_tokenIds[i]);
                (uint256 _tier, , , uint256 nation, uint256 element, uint256 _rootId, ) = getConditionTokenInfo(dspActerDataAddress, dspCharacterDataAddress, dspFateCoreDataAddress, name);

                if (uint256(ConditionType.CHARACTER_TIER) == qD.questConditionSlot[i].conditionType) {
                    require(uint256(_tier) == uint256(qD.questConditionSlot[i].conditionValue), "Invalid Condition : This character does not match the tier conditions.");
                    if (0 != qD.questConditionSlot[i].subConditionType) {
                        checkSubCondition(qD.questConditionSlot[i].subConditionType, qD.questConditionSlot[i].subConditionValue, nation, element);
                    }
                } else if (uint256(ConditionType.CHARACTER) == qD.questConditionSlot[i].conditionType) {
                    require(uint256(_rootId) == uint256(qD.questConditionSlot[i].conditionValue), "Invalid Condition : This character does not match the condition");
                    if (0 != qD.questConditionSlot[i].subConditionType) {
                        checkSubCondition(qD.questConditionSlot[i].subConditionType, qD.questConditionSlot[i].subConditionValue, nation, element);
                    }
                } else if (uint256(ConditionType.PACK) == qD.questConditionSlot[i].conditionType) {
                    require(uint256(_tokenIds[i]) == uint256(qD.questConditionSlot[i].conditionValue), "Invalid Condition : This character does not match the pack conditions.");
                } else {
                    revert("INVALID condition type");
                }

                checkConditionAndTransfer(id, _tokenIds[i], qD.questConditionSlot[i], i);
            }
        }

        emit EnterQuest(msg.sender, id);
    }

    function checkEnterQuestValid(PeriodQuestInfo memory pqi) private view {
        require(pqi.isValid, "quest not valid");
        require(pqi.startAt <= block.timestamp && block.timestamp < pqi.endAt, "quest not open");
        (uint256 questCount, uint256 currentClearCount, uint256 requiredClearCount, uint256 finishClearCount) = questStorage.getClearCondition(msg.sender, pqi.id, pqi.requireId, pqi.finishId);
        require(currentClearCount == finishClearCount, "already clear this quest");
        if (0 != pqi.requireId) {
            require(currentClearCount < requiredClearCount, "haven't completed the previous quest yet");
        }
        if (LimitType.LIMIT == pqi.userLimitType) {
            require(currentClearCount < pqi.userLimit, "User: Got stuck in the limit of this quest.");
        }
        if (LimitType.LIMIT == pqi.limitType) {
            require(questCount < pqi.limit, "limit quest");
        }
    }

    function getConditionTokenInfo(address dspActerDataAddress, address dspCharacterDataAddress, address dspFateCoreDataAddress, string memory name) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, bool) {
        uint256 gachaType = DspActorData(dspActerDataAddress).getGachaTypeByName(name);
        if (uint256(GachaType.Character) == gachaType) {
            return DspCharacterData(dspCharacterDataAddress).getCharacterInfo(name);
        } else if (uint256(GachaType.FateCore) == gachaType) {
            return DspFateCoreData(dspFateCoreDataAddress).getFateCoreInfo(name);
        }
        revert("INVALID token info type");
    }

    function checkSubCondition(uint256 conditionType, uint256 conditionValue, uint256 nation, uint256 element) private pure {
        if (uint256(ConditionType.CHARACTER_ELEMENT) == conditionType) {
            require(uint256(element) == uint256(conditionValue), "Invalid Condition : This character does not match the element conditions.");
        } else if (uint256(ConditionType.CHARACTER_NATION) == conditionType) {
            require(uint256(nation) == uint256(conditionValue), "Invalid Condition : This character does not match the nation conditions.");
        } else {
            revert("INVALID sub condition type");
        }
    }

    function cancelQuest(uint256 id) public nonReentrant {
        PeriodQuestInfo memory pqi = QuestCalendar(getDataAddress("QuestCalendar")).getQuestCalendar(id);
        checkCancelQuestValid(pqi);
        QuestInfo memory qI = questStorage.getQuestStorage(msg.sender, id);
        require(qI.questNo == id, "not valid clear id");
        StakeInfo[] memory stakeInfos = questStorage.getStakingInfo(msg.sender, id);
        for (uint256 i = 0; i < stakeInfos.length; i++) {
            _transferFromByType(address(questStorage), msg.sender, stakeInfos[i].tokenId, stakeInfos[i].amount, stakeInfos[i].conditionType);
        }

        BurnWaitInfo[] memory burnInfos = questStorage.getBurnInfo(msg.sender, id);
        for (uint i = 0; i < burnInfos.length; i++) {
            _transferFromByType(address(questStorage), msg.sender, burnInfos[i].tokenId, burnInfos[i].amount, burnInfos[i].conditionType);
        }

        questStorage.cancelQuest(msg.sender, id);

        emit CancelQuest(msg.sender, id);
    }

    function checkCancelQuestValid(PeriodQuestInfo memory pqi) private view {
        ( , uint256 currentClearCount, uint256 requiredClearCount, uint256 finishClearCount) = questStorage.getClearCondition(msg.sender, pqi.id, pqi.requireId, pqi.finishId);
        require(currentClearCount == finishClearCount, "already clear this quest");
        if (0 != pqi.requireId) {
            require(currentClearCount < requiredClearCount, "haven't completed the previous quest yet");
        }
    }

    function clearQuest(uint256 id) public nonReentrant isLive {
        PeriodQuestInfo memory pqi = QuestCalendar(getDataAddress("QuestCalendar")).getQuestCalendar(id);
        checkClearQuestValid(pqi);
        Quest memory qD = PeriodQuestData(getDataAddress("PeriodQuestData")).getQuest(pqi.questId);
        QuestInfo memory qI = questStorage.getQuestStorage(msg.sender, id);
        if (uint256(QuestCategory.REWARD) != qD.questCategory) {
            require(qI.questNo == id, "not valid clear id");
            for (uint256 i = 0; i < qI.slotData.length; i++) {
                require(true == qI.slotData[i].isValid, "Error : You are not satisfied with the completion condition.");
            }
            require(block.timestamp > qI.endAt, "Error : You are not satisfied with the staking time.");

            BurnWaitInfo[] memory burnInfos = questStorage.getBurnInfo(msg.sender, id);
            for (uint i = 0; i < burnInfos.length; i++) {
                _transferFromByType(address(questStorage), address(burnAddress), burnInfos[i].tokenId, burnInfos[i].amount, burnInfos[i].conditionType);
            }

            StakeInfo[] memory stakeInfos = questStorage.getStakingInfo(msg.sender, id);
            for (uint256 i = 0; i < stakeInfos.length; i++) {
                _transferFromByType(address(questStorage), msg.sender, stakeInfos[i].tokenId, stakeInfos[i].amount, stakeInfos[i].conditionType);
            }
        }
        questStorage.setClear(msg.sender, id, pqi.finishId, pqi.questType);
        sendReward(msg.sender, qD.rewards);

        emit ClearQuest(msg.sender, id);
    }

    function checkClearQuestValid(PeriodQuestInfo memory pqi) private view {
        require(pqi.isValid, "quest not valid");
        require(pqi.startAt <= block.timestamp && block.timestamp < pqi.endAt, "quest not open");
        (uint256 questCount, uint256 currentClearCount, uint256 requiredClearCount, uint256 finishClearCount) = questStorage.getClearCondition(msg.sender, pqi.id, pqi.requireId, pqi.finishId);
        require(currentClearCount == finishClearCount, "already clear this quest");
        if (0 != pqi.requireId) {
            require(currentClearCount < requiredClearCount, "haven't completed the previous quest yet");
        }
        if (LimitType.LIMIT == pqi.userLimitType) {
            require(currentClearCount < pqi.userLimit, "User: Got stuck in the limit of this quest.");
        }
        if (LimitType.LIMIT == pqi.limitType) {
            require(questCount < pqi.limit, "limit quest");
        }
    }

    ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    function checkConditionAndTransfer(uint256 id, uint256 _tokenId, QuestConditionSlot memory _questConditionSlot, uint256 _index) private {
        uint256 conditionType = _questConditionSlot.conditionType;
        uint256 questType = _questConditionSlot.questType;
        uint256 amount = _questConditionSlot.conditionAmount;
        if (uint256(MissionType.BURN) == questType) {
            questStorage.setBurnWaitList(msg.sender, id, _tokenId, amount, questType, _index);
            _transferFromByType(msg.sender, address(questStorage), _tokenId, amount, conditionType);
        } else if (uint256(MissionType.STAKE) == questType || uint256(MissionType.REGIST) == questType) {
            questStorage.setStakeInfo(msg.sender, id, _tokenId, amount, conditionType);
            _transferFromByType(msg.sender, address(questStorage), _tokenId, amount, conditionType);
        } else {
            revert("INVALID Mission type");
        }
        questStorage.setSlotData(msg.sender, id, _tokenId, amount, _index);
    }

    function sendReward(address _to, Reward[] memory _rewards) private {
        for (uint256 i = 0; i < _rewards.length; i++) {
            RewardInfo memory rewardInfo = rewardAddresses[_rewards[i].rewardType];
            require(rewardInfo.isValid, "reward not valid");
            if (uint256(TokenType.ERC1155) == rewardInfo.tokenType) {
                IERC1155LUXON(rewardInfo.tokenAddress).mint(_to, _rewards[i].reward, _rewards[i].rewardAmount,"");
            } else if (uint256(TokenType.ERC20) == rewardInfo.tokenType) {
                IERC20LUXON(rewardInfo.tokenAddress).transfer(_to, _rewards[i].rewardAmount);
            } else if (uint256(TokenType.ERC721) == rewardInfo.tokenType) {
                IERC721(rewardInfo.tokenAddress).transferFrom(address(this), _to, _rewards[i].reward);
            } else {
                revert("INVALID Reward type");
            }
            emit SendReward(msg.sender, _to, rewardInfo.tokenAddress, uint256(rewardInfo.tokenType), _rewards[i].reward, _rewards[i].rewardAmount);
        }
    }

    function _transferFromByType(address _from, address _to, uint256 _tokenId, uint256 _amount, uint256 _conditionType) private {
        if (uint256(ConditionType.CHARACTER) == _conditionType || uint256(ConditionType.CHARACTER_TIER) == _conditionType) {
            IERC721(lctAddress).transferFrom(_from, _to, _tokenId);
            emit TransferFromByType(_from, _to, lctAddress, _tokenId, _amount, _conditionType);
        } else if (uint256(ConditionType.PACK) == _conditionType) {
            IERC1155LUXON(gachaTicketAddress).safeTransferFrom(_from, _to, _tokenId, _amount, "");
            emit TransferFromByType(_from, _to, gachaTicketAddress, _tokenId, _amount, _conditionType);
        } else {
            revert("INVALID condition type");
        }
    }
}