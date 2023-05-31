/**
 *Submitted for verification at polygonscan.com on 2023-05-30
*/

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
        assembly { size := extcodesize(account) }
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

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
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
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

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
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
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
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// File: contracts/EthermonAdventure.sol

/**
 *Submitted for verification at Etherscan.io on 2018-09-04
 */


pragma solidity ^0.6.6;

library AddressUtils {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

contract BasicAccessControl {
    address payable public owner;
    // address[] public moderators;
    uint16 public totalModerators = 0;
    mapping(address => bool) public moderators;
    bool public isMaintaining = false;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyModerators() {
        require(msg.sender == owner || moderators[msg.sender] == true);
        _;
    }

    modifier isActive() {
        require(!isMaintaining);
        _;
    }

    function ChangeOwner(address payable _newOwner) external onlyOwner {
        if (_newOwner != address(0)) {
            owner = _newOwner;
        }
    }

    function Kill() external onlyOwner {
        selfdestruct(owner);
    }

    function AddModerator(address _newModerator) external onlyOwner {
        if (moderators[_newModerator] == false) {
            moderators[_newModerator] = true;
            totalModerators += 1;
        }
    }

    function RemoveModerator(address _oldModerator) external onlyOwner {
        if (moderators[_oldModerator] == true) {
            moderators[_oldModerator] = false;
            totalModerators -= 1;
        }
    }

    function UpdateMaintaining(bool _isMaintaining) external onlyOwner {
        isMaintaining = _isMaintaining;
    }
}

contract EtheremonEnum {
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

    enum PropertyType {
        ANCESTOR,
        XFACTOR
    }
}

interface EtheremonDataBase {
    // read
    function getMonsterClass(
        uint32 _classId
    )
        external
        view
        returns (
            uint32 classId,
            uint256 price,
            uint256 returnPrice,
            uint32 total,
            bool catchable
        );

    function getMonsterObj(
        uint64 _objId
    )
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

    function getElementInArrayType(
        EtheremonEnum.ArrayType _type,
        uint64 _id,
        uint256 _index
    ) external view returns (uint8);

    function addMonsterObj(
        uint32 _classId,
        address _trainer,
        string calldata _name
    ) external returns (uint64);

    function addElementToArrayType(
        EtheremonEnum.ArrayType _type,
        uint64 _id,
        uint8 _value
    ) external returns (uint256);
}

interface ERC721Interface {
    function ownerOf(uint256 _tokenId) external view returns (address owner);
}

interface EtheremonAdventureItem {
    function ownerOf(uint256 _tokenId) external view returns (address);

    function getItemInfo(
        uint256 _tokenId
    ) external view returns (uint256 classId, uint256 value);

    function spawnItem(
        uint256 _classId,
        uint256 _value,
        address _owner
    ) external returns (uint256);
}

interface EtheremonAdventureSetting {
    function getSiteItem(
        uint256 _siteId,
        uint256 _seed
    )
        external
        view
        returns (
            uint256 _monsterClassId,
            uint256 _tokenClassId,
            uint256 _value
        );

    function getSiteId(
        uint64 _monsterId,
        uint256 _seed
    ) external view returns (uint256);
}

interface EtheremonMonsterNFT {
    function mintMonster(
        uint32 _classId,
        address _trainer,
        string calldata _name
    ) external returns (uint256);
}

abstract contract EtheremonAdventureData {
    function addLandRevenue(
        uint256 _siteId,
        uint256 _emonAmount,
        uint256 _etherAmount
    ) external virtual;

    function addTokenClaim(
        uint256 _tokenId,
        uint256 _emonAmount,
        uint256 _etherAmount
    ) external virtual;

    function addExploreData(
        address _sender,
        uint256 _typeId,
        uint256 _monsterId,
        uint256 _siteId,
        uint256 _startAt,
        uint256 _emonAmount,
        uint256 _etherAmount
    ) external virtual returns (uint256);

    function removePendingExplore(
        uint256 _exploreId,
        uint256 _itemSeed
    ) external virtual;

    // public function
    function getLandRevenue(
        uint256 _classId
    ) public view virtual returns (uint256 _emonAmount, uint256 _etherAmount);

    function getTokenClaim(
        uint256 _tokenId
    ) public view virtual returns (uint256 _emonAmount, uint256 _etherAmount);

    function getExploreData(
        uint256 _exploreId
    )
        public
        view
        virtual
        returns (
            address _sender,
            uint256 _typeId,
            uint256 _monsterId,
            uint256 _siteId,
            uint256 _itemSeed,
            uint256 _startAt
        );

    function getPendingExplore(
        address _player
    ) public view virtual returns (uint256);

    function getPendingExploreData(
        address _player
    )
        public
        view
        virtual
        returns (
            uint256 _exploreId,
            uint256 _typeId,
            uint256 _monsterId,
            uint256 _siteId,
            uint256 _itemSeed,
            uint256 _startAt
        );
}

contract EtheremonAdventure is EtheremonEnum, BasicAccessControl {
    using AddressUtils for address;
    using SafeERC20 for IERC20;

    uint8 public constant STAT_COUNT = 6;
    uint8 public constant STAT_MAX = 32;

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

    struct ExploreData {
        address sender;
        uint256 monsterType;
        uint256 monsterId;
        uint256 siteId;
        uint256 itemSeed;
        uint256 startAt; // blocknumber
    }

    struct ExploreReward {
        uint256 monsterClassId;
        uint256 itemClassId;
        uint256 value;
        uint256 temp;
    }

    address public dataContract;
    address public monsterNFT;
    IERC20 public emon;
    address public adventureDataContract;
    address public adventureSettingContract;
    address public adventureItemContract;
    address public adventureRevenue;

    uint256 public exploreEMONFee = 10 ** 18;
    uint256 public minBlockGap = 240;

    uint256 seed = 0;

    event SendExplore(
        address indexed from,
        uint256 monsterType,
        uint256 monsterId,
        uint256 exploreId
    );
    event ClaimExplore(
        address indexed from,
        uint256 exploreId,
        uint256 itemType,
        uint256 itemClass,
        uint256 itemId
    );

    modifier requireDataContract() {
        require(dataContract != address(0));
        _;
    }

    modifier requireAdventureDataContract() {
        require(adventureDataContract != address(0));
        _;
    }

    modifier requireAdventureSettingContract() {
        require(adventureSettingContract != address(0));
        _;
    }

    modifier requireTokenContract() {
        require(address(emon) != address(0));
        _;
    }

    modifier requireAdventureRevenueContract() {
        require(adventureRevenue != address(0));
        _;
    }

    function setContract(
        address _dataContract,
        address _monsterNFT,
        address _adventureDataContract,
        address _adventureSettingContract,
        address _adventureItemContract,
        address _adventureRevenue,
        address _emon
    ) public onlyOwner {
        dataContract = _dataContract;
        monsterNFT = _monsterNFT;
        adventureDataContract = _adventureDataContract;
        adventureSettingContract = _adventureSettingContract;
        adventureItemContract = _adventureItemContract;
        adventureRevenue = _adventureRevenue;
        emon = IERC20(_emon);
    }

    function setConfig(
        uint256 _minBlockGap,
        uint256 _exploreEMONFee
    ) external onlyOwner {
        exploreEMONFee = _exploreEMONFee;
        minBlockGap = _minBlockGap;
    }

    function adventureByToken(
        uint256 _param1,
        uint256 _param2,
        uint64 _param3
    ) external isActive {
        // param1 = 1 -> explore, param1 = 2 -> claim
        address player = msg.sender;
        if (_param1 == 1) {
            _exploreUsingEmon(player, _param2, _param3, exploreEMONFee);
            emon.safeTransferFrom(player, adventureRevenue, exploreEMONFee);
        } else {
            _claimExploreItemUsingEmon(_param2);
            // if (_token >= exploreFastenEMONFee)
            //     emon.safeTransferFrom(
            //         player,
            //         address(this),
            //         exploreFastenEMONFee
            //     );
        }
    }

    function _exploreUsingEmon(
        address _sender,
        uint256 _monsterType,
        uint256 _monsterId,
        uint256 _token
    ) internal {
        seed = getRandom(_sender, block.number - 1, seed, _monsterId);
        uint256 siteId = getTargetSite(_sender, _monsterType, _monsterId, seed);
        require(siteId != 0, "Site ID is 0");

        EtheremonAdventureData adventureData = EtheremonAdventureData(
            adventureDataContract
        );
        uint256 exploreId = adventureData.addExploreData(
            _sender,
            _monsterType,
            _monsterId,
            siteId,
            block.number,
            _token,
            0
        );

        emit SendExplore(_sender, _monsterType, _monsterId, exploreId);
    }

    //TODO: New Fast return which requires backend mod signature and offchain item from db.
    function _claimExploreItemUsingEmon(
        uint256 _exploreId
    )
        internal
        returns (uint256 monsterClassId, uint256 itemClassId, uint256 value)
    {
        EtheremonAdventureData adventureData = EtheremonAdventureData(
            adventureDataContract
        );
        EtheremonAdventureSetting adventureSetting = EtheremonAdventureSetting(
            adventureSettingContract
        );

        ExploreData memory exploreData;
        (
            exploreData.sender,
            exploreData.monsterType,
            exploreData.monsterId,
            exploreData.siteId,
            exploreData.itemSeed,
            exploreData.startAt
        ) = adventureData.getExploreData(_exploreId);

        require(exploreData.itemSeed == 0, "Item already explored");

        // min 2 blocks
        require(
            block.number > exploreData.startAt + 2,
            "Mon is still Exploring..."
        );

        exploreData.itemSeed =
            getRandom(
                exploreData.sender,
                exploreData.startAt + 1,
                exploreData.monsterId,
                _exploreId
            ) %
            100000;

        // // We are giving items on runtime cannot wait for an item for certain blocks as items may change everytime we call claim.
        // if (_token < exploreFastenEMONFee) {
        //     require(
        //         block.number >
        //             (exploreData.startAt +
        //                 minBlockGap +
        //                 (exploreData.startAt % minBlockGap)),
        //         "Increase EMONs to fast explore"
        //     );
        // }
        ExploreReward memory reward;
        (
            reward.monsterClassId,
            reward.itemClassId,
            reward.value
        ) = EtheremonAdventureSetting(adventureSettingContract).getSiteItem(
            exploreData.siteId,
            exploreData.itemSeed
        );

        adventureData.removePendingExplore(_exploreId, exploreData.itemSeed);

        if (reward.monsterClassId > 0) {
            EtheremonMonsterNFT monsterContract = EtheremonMonsterNFT(
                monsterNFT
            );
            reward.temp = monsterContract.mintMonster(
                uint32(reward.monsterClassId),
                exploreData.sender,
                "..name me.."
            );
            emit ClaimExplore(
                exploreData.sender,
                _exploreId,
                0,
                reward.monsterClassId,
                reward.temp
            );
        } else if (reward.itemClassId > 0) {
            // give new adventure item
            EtheremonAdventureItem item = EtheremonAdventureItem(
                adventureItemContract
            );
            reward.temp = item.spawnItem(
                reward.itemClassId,
                reward.value,
                exploreData.sender
            );
            emit ClaimExplore(
                exploreData.sender,
                _exploreId,
                1,
                reward.itemClassId,
                reward.temp
            );
        }

        emit ClaimExplore(
            exploreData.sender,
            _exploreId,
            exploreData.itemSeed,
            reward.itemClassId,
            reward.temp
        );

        return (reward.monsterClassId, reward.itemClassId, reward.value); //revert();
    }

    //TODO: Create a mod function that returns different items at different rate of time
    function returnOffchain(uint256 _blocks) external onlyModerators {}

    // public
    function getRandom(
        address _player,
        uint256 _block,
        uint256 _seed,
        uint256 _count
    ) public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(blockhash(_block), _player, _seed, _count)
                )
            );
    }

    function getTargetSite(
        address _sender,
        uint256 _monsterType,
        uint256 _monsterId,
        uint256 _seed
    ) public view returns (uint256) {
        MonsterObjAcc memory obj;
        (
            obj.monsterId,
            obj.classId,
            obj.trainer,
            obj.exp,
            obj.createIndex,
            obj.lastClaimIndex,
            obj.createTime
        ) = EtheremonDataBase(dataContract).getMonsterObj(uint64(_monsterId));
        require(obj.trainer == _sender, "Invalid mon owner");
        return
            EtheremonAdventureSetting(adventureSettingContract).getSiteId(
                obj.monsterId,
                _seed
            );
    }

    function predictExploreReward(
        uint256 _exploreId
    )
        external
        view
        returns (
            uint256 itemSeed,
            uint256 rewardMonsterClass,
            uint256 rewardItemCLass,
            uint256 rewardValue
        )
    {
        EtheremonAdventureData adventureData = EtheremonAdventureData(
            adventureDataContract
        );
        ExploreData memory exploreData;
        (
            exploreData.sender,
            exploreData.monsterType,
            exploreData.monsterId,
            exploreData.siteId,
            exploreData.itemSeed,
            exploreData.startAt
        ) = adventureData.getExploreData(_exploreId);

        if (exploreData.itemSeed != 0) {
            itemSeed = exploreData.itemSeed;
        } else {
            if (block.number < exploreData.startAt + 2) revert(); //return (0, 0, 0, 0);
            itemSeed =
                getRandom(
                    exploreData.sender,
                    exploreData.startAt + 1,
                    exploreData.monsterId,
                    _exploreId
                ) %
                100000;
        }
        (
            rewardMonsterClass,
            rewardItemCLass,
            rewardValue
        ) = EtheremonAdventureSetting(adventureSettingContract).getSiteItem(
            exploreData.siteId,
            itemSeed
        );
    }

    function getExploreItem(
        uint256 _exploreId
    )
        external
        view
        returns (
            address trainer,
            uint256 monsterType,
            uint256 monsterId,
            uint256 siteId,
            uint256 startBlock,
            uint256 rewardMonsterClass,
            uint256 rewardItemClass,
            uint256 rewardValue
        )
    {
        EtheremonAdventureData adventureData = EtheremonAdventureData(
            adventureDataContract
        );
        (
            trainer,
            monsterType,
            monsterId,
            siteId,
            rewardMonsterClass,
            startBlock
        ) = adventureData.getExploreData(_exploreId);

        if (rewardMonsterClass > 0) {
            (
                rewardMonsterClass,
                rewardItemClass,
                rewardValue
            ) = EtheremonAdventureSetting(adventureSettingContract).getSiteItem(
                siteId,
                rewardMonsterClass
            );
        }
    }

    function getPendingExploreItem(
        address _trainer
    )
        external
        view
        returns (
            uint256 exploreId,
            uint256 monsterType,
            uint256 monsterId,
            uint256 siteId,
            uint256 startBlock,
            uint256 endBlock
        )
    {
        EtheremonAdventureData adventureData = EtheremonAdventureData(
            adventureDataContract
        );
        (
            exploreId,
            monsterType,
            monsterId,
            siteId,
            endBlock,
            startBlock
        ) = adventureData.getPendingExploreData(_trainer);
        if (exploreId > 0) {
            endBlock = startBlock + minBlockGap + (startBlock % minBlockGap);
        }
    }
}