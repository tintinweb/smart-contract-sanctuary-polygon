/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

// File: contracts/EthermonEnum.sol

pragma solidity 0.6.6;

contract EthermonEnum {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_TRAINER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum ArrayType {
        CLASS_TYPE,
        STAT_STEP,
        STAT_START,
        STAT_BASE,
        OBJ_SKILL
    }

    enum BattleResult {
        CASTLE_WIN,
        CASTLE_LOSE,
        CASTLE_DESTROYED
    }

    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

// File: contracts/EthermonDataBase.sol

pragma solidity 0.6.6;

interface EtheremonDataBase {
    // write
    function withdrawEther(address _sendTo, uint256 _amount)
        external
        returns (EthermonEnum.ResultCode);

    function addElementToArrayType(
        EthermonEnum.ArrayType _type,
        uint64 _id,
        uint8 _value
    ) external returns (uint256);

    function updateIndexOfArrayType(
        EthermonEnum.ArrayType _type,
        uint64 _id,
        uint256 _index,
        uint8 _value
    ) external returns (uint256);

    function setMonsterClass(
        uint32 _classId,
        uint256 _price,
        uint256 _returnPrice,
        bool _catchable
    ) external returns (uint32);

    function addMonsterObj(
        uint32 _classId,
        address _trainer,
        string calldata _name
    ) external returns (uint64);

    function setMonsterObj(
        uint64 _objId,
        string calldata _name,
        uint32 _exp,
        uint32 _createIndex,
        uint32 _lastClaimIndex
    ) external;

    function increaseMonsterExp(uint64 _objId, uint32 amount) external;

    function decreaseMonsterExp(uint64 _objId, uint32 amount) external;

    function removeMonsterIdMapping(address _trainer, uint64 _monsterId)
        external;

    function addMonsterIdMapping(address _trainer, uint64 _monsterId) external;

    function clearMonsterReturnBalance(uint64 _monsterId)
        external
        returns (uint256 amount);

    function collectAllReturnBalance(address _trainer)
        external
        returns (uint256 amount);

    function transferMonster(
        address _from,
        address _to,
        uint64 _monsterId
    ) external returns (EthermonEnum.ResultCode);

    function addExtraBalance(address _trainer, uint256 _amount)
        external
        returns (uint256);

    function deductExtraBalance(address _trainer, uint256 _amount)
        external
        returns (uint256);

    function setExtraBalance(address _trainer, uint256 _amount) external;

    // read
    function totalMonster() external view returns (uint256);

    function totalClass() external view returns (uint32);

    function getSizeArrayType(EthermonEnum.ArrayType _type, uint64 _id)
        external
        view
        returns (uint256);

    function getElementInArrayType(
        EthermonEnum.ArrayType _type,
        uint64 _id,
        uint256 _index
    ) external view returns (uint8);

    function getMonsterClass(uint32 _classId)
        external
        view
        returns (
            uint32 classId,
            uint256 price,
            uint256 returnPrice,
            uint32 total,
            bool catchable
        );

    function getMonsterObj(uint64 _objId)
        external
        view
        returns (
            uint64 objId,
            uint32 classId,
            address trainer,
            uint32 exp,
            uint32 createIndex,
            uint32 lastClaimIndex,
            uint256 createTime
        );

    function getMonsterName(uint64 _objId)
        external
        view
        returns (string memory name);

    function getExtraBalance(address _trainer) external view returns (uint256);

    function getMonsterDexSize(address _trainer)
        external
        view
        returns (uint256);

    function getMonsterObjId(address _trainer, uint256 index)
        external
        view
        returns (uint64);

    function getExpectedBalance(address _trainer)
        external
        view
        returns (uint256);

    function getMonsterReturn(uint64 _objId)
        external
        view
        returns (uint256 current, uint256 total);
}

// File: openzeppelin-solidity/contracts/token/ERC20/IERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
        require(c >= a, "SafeMath: addition overflow");

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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
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
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// File: openzeppelin-solidity/contracts/utils/Address.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
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
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
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
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
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

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/Context.sol

pragma solidity 0.6.6;

contract Context {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// File: contracts/BasicAccessControl.sol

pragma solidity 0.6.6;

contract BasicAccessControl is Context {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = true;

    constructor() public {
        owner = msgSender();
    }

    modifier onlyOwner() {
        require(msgSender() == owner);
        _;
    }

    modifier onlyModerators() {
        require(msgSender() == owner || moderators[msgSender()] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) public onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function AddModerator(address _newModerator) public onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        } else {
            delete moderators[_newModerator];
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) public onlyOwner {
        isMaintaining = _isMaintaining;
    }

    function Kill() public onlyOwner {
        selfdestruct(owner);
    }
}

// File: contracts/EthermonTransformSetting.sol

/**
 *Submitted for verification at Etherscan.io on 2018-08-28
 */

pragma solidity 0.6.6;

// copyright [email protected]

contract EthermonTransformSetting is BasicAccessControl {
    mapping(uint32 => uint8) public transformLevels;
    mapping(uint32 => uint32) public transformClasses;

    function setConfigClass(
        uint32 _classId,
        uint8 _transformLevel,
        uint32 _tranformClass
    ) public onlyModerators {
        transformLevels[_classId] = _transformLevel;
        transformClasses[_classId] = _tranformClass;
    }

    function getTransformInfo(uint32 _classId)
        external
        view
        returns (uint32 transformClassId, uint8 level)
    {
        transformClassId = transformClasses[_classId];
        level = transformLevels[_classId];
    }

    function getClassTransformInfo(uint32 _classId)
        external
        view
        returns (uint8 transformLevel, uint32 transformCLassId)
    {
        transformLevel = transformLevels[_classId];
        transformCLassId = transformClasses[_classId];
    }
}

// File: contracts/EthermonAdventureHandler.sol

/**
 *Submitted for verification at Etherscan.io on 2019-01-21
 */
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.6;

interface EthermonSeasonDataInterface {
    function getCurrentSeasonExp(uint64 _objId) external view returns (uint256);

    function getCurrentSeason(uint64 _objId) external view returns (uint32);

    function getExp(uint64 _objId, uint32 _season)
        external
        view
        returns (uint256);

    function increaseMonsterExp(uint64 _objId, uint256 amount) external;
}

interface EtheremonMonsterNFTInterface {
    function triggerTransferEvent(
        address _from,
        address _to,
        uint256 _tokenId
    ) external;

    function getMonsterCurrentStats(uint64 _monsterId)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        );

    function getMonsterBaseStats(uint64 _monsterId)
        external
        view
        returns (
            uint256 hp,
            uint256 pa,
            uint256 pd,
            uint256 sa,
            uint256 sd,
            uint256 speed
        );

    function mintMonster(
        uint32 _classId,
        address _trainer,
        string calldata _name
    ) external returns (uint256);

    function burnMonster(uint64 _tokenId) external;
}

interface EthermonAdventureTransformInterface {
    function transform(
        uint64 _monsterId,
        uint32 _classId,
        address _owner
    ) external;
}

interface EtheremonWorldNFT {
    function STAT_MAX_CLASS(uint32 _classId)
        external
        returns (uint256 _statMax);
}

contract EthermonAdventureHandler is BasicAccessControl, EthermonEnum {
    uint8 public constant STAT_MAX_VALUE = 31;
    uint8 public constant LEVEL_MAX_VALUE = 100;

    struct MonsterObjAcc {
        uint64 monsterId;
        uint32 classId;
        address trainer;
        string name;
        uint32 exp;
        uint32 createIndex;
        uint32 lastClaimIndex;
        uint256 createTime;
    }

    struct MonsterObjWithStats {
        // MonsterObjAcc obj;
        //    uint64 objId,
        //     uint32 classId,
        //     address trainer,
        //     uint32 exp,
        //     uint32 createIndex,
        //     uint32 lastClaimIndex,
        //     uint256 createTime
        uint64 monsterId;
        uint32 classId;
        address trainer;
        uint256 exp;
        uint32 createIndex;
        string name;
        uint256 level;
        uint256[6] currentStats;
        uint256[6] baseStats;
    }

    // address
    address public transformSettingContract;
    address public dataContract;
    address public monsterNFT;
    address public worldNFTContract;
    address public seasonDataContract;
    address public transformAdventure;

    mapping(uint8 => uint32) public levelExps;
    uint256 public levelItemClass = 200;
    uint256 public expItemClass = 201;
    uint256 public transformItemClass = 202;

    function setContract(
        address _dataContract,
        address _monsterNFT,
        address _transformSettingContract,
        address _seasonDataContract,
        address _worldNFTContract,
        address _transformAdventure
    ) public onlyModerators {
        dataContract = _dataContract;
        monsterNFT = _monsterNFT;
        worldNFTContract = _worldNFTContract;
        seasonDataContract = _seasonDataContract;
        transformSettingContract = _transformSettingContract;
        transformAdventure = _transformAdventure;
    }

    function setConfig(uint256 _levelItemClass, uint256 _expItemClass)
        public
        onlyModerators
    {
        levelItemClass = _levelItemClass;
        expItemClass = _expItemClass;
    }

    function handleSingleItem(
        address _sender,
        uint256 _classId,
        uint256 _value,
        uint256 _target
    ) public onlyModerators {
        // check ownership of _target
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        EthermonSeasonDataInterface seasonData = EthermonSeasonDataInterface(
            seasonDataContract
        );
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(uint64(_target));
        if (obj.monsterId != _target || obj.trainer != _sender) revert();
        uint256 currentSeasonExp = seasonData.getCurrentSeasonExp(
            obj.monsterId
        );
        currentSeasonExp = currentSeasonExp < 1 ? 1 : currentSeasonExp;
        if (_classId == expItemClass) {
            uint8 currentLevel = getLevel(uint32(currentSeasonExp)) - 1;
            uint8 nextLevel = currentLevel + 1;
            uint256 levelExp = levelExps[nextLevel];
            uint256 lvl = levelExps[currentLevel];
            // currentLevelExp = 100
            // nextLevelExp = 215
            // next - curr = 115
            uint256 exp = levelExp - lvl; // Remaining exp to next level.
            uint256 expValue = (exp * _value) / 100;
            seasonData.increaseMonsterExp(obj.monsterId, expValue);
        } else if (_classId == levelItemClass) {
            uint8 currentLevel = getLevel(uint32(currentSeasonExp));
            require(currentLevel < LEVEL_MAX_VALUE, "Level reached max cap");
            currentLevel += uint8(_value);

            require(
                levelExps[currentLevel - 1] > currentSeasonExp,
                "Invalid level exp"
            );

            //getting remaining exp to next leve and adding to current exp.
            seasonData.increaseMonsterExp(
                obj.monsterId,
                levelExps[currentLevel - 1] - currentSeasonExp //Capping it to max exp 20004745
            );
        } else if (_classId == transformItemClass) {
            EthermonTransformSetting transformSetting = EthermonTransformSetting(
                    transformSettingContract
                );
            uint32 transformClass = 0;
            uint8 transformLevel = 0;
            (transformClass, transformLevel) = transformSetting
                .getTransformInfo(obj.classId);

            require(
                obj.classId != transformItemClass &&
                    transformItemClass > 0 &&
                    transformLevel > 0,
                "Transform cannot be processed"
            );
            EthermonAdventureTransformInterface adventureTransform = EthermonAdventureTransformInterface(
                    transformAdventure
                );
            adventureTransform.transform(obj.monsterId, obj.classId, _sender);
        } else {
            revert();
        }
    }

    function handleMultipleItems(
        address _sender,
        uint256 _classId1,
        uint256 _classId2,
        uint256 _classId3,
        uint256 _target
    ) public onlyModerators {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(uint64(_target));
        require(
            obj.monsterId == uint64(_target) && obj.trainer == _sender,
            "Mon or owner is not correct"
        );

        uint256 index = 0;
        if (_classId1 == 300 && _classId2 == 301 && _classId3 == 302) {
            //health shards
            index = 0;
        } else if (_classId1 == 310 && _classId2 == 311 && _classId3 == 312) {
            // primary attack shards
            index = 1;
        } else if (_classId1 == 320 && _classId2 == 321 && _classId3 == 322) {
            // primary defense shards
            index = 2;
        } else if (_classId1 == 330 && _classId2 == 331 && _classId3 == 332) {
            // secondary attack shards
            index = 3;
        } else if (_classId1 == 340 && _classId2 == 341 && _classId3 == 342) {
            // secondary defense shards
            index = 4;
        } else if (_classId1 == 350 && _classId2 == 351 && _classId3 == 352) {
            // speed shards
            index = 5;
        }

        uint8 currentValue = data.getElementInArrayType(
            ArrayType.STAT_BASE,
            obj.monsterId,
            index
        );

        uint8 maxValue = data.getElementInArrayType(
            ArrayType.STAT_START,
            uint64(obj.classId),
            index
        );
        uint8 updatedValue = currentValue + 2;

        // EtheremonWorldNFT worldNFT = EtheremonWorldNFT(worldNFTContract);

        // uint256 _statMaxClass = worldNFT.STAT_MAX_CLASS(obj.classId);

        // uint256 statMax = uint8((_statMaxClass > 0)
        //     ? (_statMaxClass - 1)
        //     : STAT_MAX_VALUE);
        // // Make it to +3
        // // DONE: make it max value instead of +3 pass max if > max.
        // // (88 - 32) = 56 < 56
        // // DONE: Will get STAT_MAX_VALUE from WorldNFT contract.
        // uint8 diff = currentValue - statMax;
        // require(diff < maxValue, "Already reached max stat");
        // if (updatedValue > (maxValue + statMax))
        //     updatedValue = maxValue + statMax;

        // Make it to +3
        // TODO: make it max value instead of +3 pass max if > max.
        // (88 - 32) = 56 < 56
        uint8 diff = currentValue - STAT_MAX_VALUE;
        require(diff < maxValue, "Already reached max stat");
        if (updatedValue > (maxValue + STAT_MAX_VALUE))
            updatedValue = maxValue + STAT_MAX_VALUE;

        data.updateIndexOfArrayType(
            ArrayType.STAT_BASE,
            obj.monsterId,
            index,
            updatedValue
        );
    }

    function getMonSeasonExp(uint64 _monId) public view returns (uint256) {
        EthermonSeasonDataInterface seasonData = EthermonSeasonDataInterface(
            seasonDataContract
        );
        return seasonData.getCurrentSeasonExp(_monId);
    }

    // function getMonsterDataInfoByIndex(
    //     address _trainer,
    //     uint256 _index
    // ) public view returns (MonsterObjWithStats memory) {
    //     EtheremonDataBase data = EtheremonDataBase(dataContract);
    //     EtheremonMonsterNFTInterface monsterTokenContract = EtheremonMonsterNFTInterface(
    //             monsterNFT
    //         );

    //     uint64 monsterId = data.getMonsterObjId(_trainer, _index);
    //     MonsterObjWithStats memory objWithStats;

    //     //    uint64 objId,
    //     //     uint32 classId,
    //     //     address trainer,
    //     //     uint32 exp,
    //     //     uint32 createIndex,
    //     //     uint32 lastClaimIndex,
    //     //     uint256 createTime

    //     (
    //         objWithStats.monsterId,
    //         objWithStats.classId,
    //         objWithStats.trainer,
    //         objWithStats.name,
    //         ,
    //         objWithStats.createIndex,
    //         ,
    //         ,

    //     ) = data.getMonsterObj(monsterId);

    //     (
    //         ,
    //         ,
    //         objWithStats.currentStats[0],
    //         objWithStats.currentStats[1],
    //         objWithStats.currentStats[2],
    //         objWithStats.currentStats[3],
    //         objWithStats.currentStats[4],
    //         objWithStats.currentStats[5]
    //     ) = monsterTokenContract.getMonsterCurrentStats(monsterId);

    //     (
    //         objWithStats.baseStats[0],
    //         objWithStats.baseStats[1],
    //         objWithStats.baseStats[2],
    //         objWithStats.baseStats[3],
    //         objWithStats.baseStats[4],
    //         objWithStats.baseStats[5]
    //     ) = monsterTokenContract.getMonsterBaseStats(monsterId);

    //     objWithStats.exp = getMonSeasonExp(objWithStats.monsterId);
    //     return objWithStats;
    // }

    function getMonCurrentSeasonExp(uint64 _monId, uint32 _season)
        external
        returns (uint256)
    {
        EthermonSeasonDataInterface seasonData = EthermonSeasonDataInterface(
            seasonDataContract
        );
        return seasonData.getExp(_monId, _season);
    }

    function monsterWorldTokenOfOwnerByIndex(address _trainer, uint256 _index)
        public
        view
        returns (
            uint64 _monsterId,
            uint32 _classId,
            address _trainerAddress,
            string memory _name,
            uint32 _exp
        )
    {
        EtheremonDataBase data = EtheremonDataBase(dataContract);
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = data.getMonsterObj(_monsterId);

        EthermonSeasonDataInterface seasonData = EthermonSeasonDataInterface(
            seasonDataContract
        );
        uint256 currentSeasonExp = seasonData.getCurrentSeasonExp(
            obj.monsterId
        );

        _monsterId = obj.monsterId;
        _classId = obj.classId;
        _trainerAddress = obj.trainer;
        _name = obj.name;
        _exp = uint32(currentSeasonExp);
    }

    // public method
    function getRandom(address _player, uint256 _block)
        public
        view
        returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(blockhash(_block), _player)));
    }

    function genLevelExp() external onlyModerators {
        uint8 level = 1;
        uint32 requirement = 100;
        uint32 sum = requirement;
        while (level <= 100) {
            levelExps[level] = sum;
            level += 1;
            requirement = (requirement * 11) / 10 + 5;
            sum += requirement;
        }
    }

    function getLevel(uint32 exp) public view returns (uint8) {
        uint8 minIndex = 1;
        uint8 maxIndex = 100;
        uint8 currentIndex;

        while (minIndex < maxIndex) {
            currentIndex = (minIndex + maxIndex) / 2;
            if (exp < levelExps[currentIndex]) maxIndex = currentIndex;
            else minIndex = currentIndex + 1;
        }

        return minIndex;
    }
}