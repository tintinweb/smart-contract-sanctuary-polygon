// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MinterGuruToken is AccessControl, ERC20 {
    /// @dev VestingRecord - struct with vesting
    struct VestingRecord {
        address receiver;                    // receiver of vesting tokens
        uint256 stepValue;                   // value unlocked at every period
        uint256 stepDuration;                // single period duration in seconds
        uint256 steps;                       // count of unlock periods
        uint256 createdAt;                   // started at timestamp
        uint256 withdrawn;                   // already released
    }

    /// @dev CommunityEvent - struct with some gaming activity details
    /// Reward calculates as follows:
    /// expectedSupply = ((now - start) / duration) * value
    /// eventRate = currentSupply / expectedSupply
    /// By thresholds list we are building interval set: let's assume that length of thresholds equals to n.
    /// Then our set will going to be: [0, thresholds[0]], [thresholds[1], thresholds[2]], [thresholds[n-2], thresholds[n-1]]
    /// For each interval we have token value in values list, so length of values must equal to length(thresholds)+1
    ///
    /// There is one exception from above algorythm. If less then 20% of event passed, then reward will equal to reward for interval, which includes 100%
    struct CommunityEvent {
        uint256 id;                             // event id
        uint256 value;                          // total value to distribute
        uint256 start;                          // start of event - unix timestamp in seconds
        uint256 finish;                         // end of event - unix timestamp in seconds
        uint256[] thresholds;                   // right bounds of intervals in percents (100 means 0.01%)
        uint256[] values;                       // values for intervals. length must equal to length(thresholds)+1
        uint256 currentSupply;                  // tokens minted via this event
    }

    /// @dev VestingStarted - event emitted when vesting started for some receiver
    event VestingStarted(address indexed receiver, uint256 stepValue, uint256 stepDuration, uint256 steps);

    /// @dev VestingWithdrawn - event emitted when some amount of vesting tokens
    event VestingWithdrawn(address indexed receiver, uint256 value);

    /// @dev VestingFullWithdrawn - event emitted when receiver withdrew all tokens
    event VestingFullWithdrawn(address indexed receiver, uint256 totalValue);

    /// @dev VestingRevoked - event emitted when vesting of receiver is revoked
    event VestingRevoked(address indexed receiver, uint256 totalValue);

    /// @dev CommunityEventCreated - event emitted when game event is created
    event CommunityEventCreated(uint256 indexed id, uint256 value, uint256 start, uint256 finish,
        uint256[] thresholds, uint256[] values);

    /// @dev CommunityEventFinished - event emitted when all tokens from event will be distributed
    event CommunityEventFinished(uint256 indexed id);

    // constants
    bytes32 public constant LIQUIDITY_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000001;
    bytes32 public constant VESTING_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000002;
    bytes32 public constant COMMUNITY_REWARD_ADMIN_ROLE = 0x0000000000000000000000000000000000000000000000000000000000000003;
    uint256 public constant PERCENT_MULTIPLIER = 10000;  // 100 means 1%. Example: 2/10 - 2*10000/10 = 2000 which is 20%

    uint256 public totalLimit;                         // limit of minting tokens amount
    uint256 public vestingLeftSupply;                  // tokens locked for vesting (minted + locked)
    uint256 public communityRewardLeftSupply;          // tokens minted for rewards in game activities
    uint256 public burned;                             // amount of burned tokens

    uint256 eventsCount = 0;                                          // total count of events
    mapping(uint256 => CommunityEvent) public currentEvents;          // current game event
    mapping(address => VestingRecord) public vestingRecords;          // vestings

    /// @dev constructor
    /// @param _totalLimit - limit of amount of minted tokens
    /// @param _liquidityAmount - amount for liquidity
    /// @param _vestingAmount - amount for vesting program
    /// @param _communityRewardAmount - amount for rewards in community events
    /// @param _liquidityAdmin - account, which will receive liquidity tokens
    /// @param _vestingAdmin - account, which will have permission to create/revoke vesting
    /// @param _gameRewardAdmin - account, which will have permission to create gaming events and mint rewards
    constructor(
        uint256 _totalLimit,
        uint256 _liquidityAmount,
        uint256 _vestingAmount,
        uint256 _communityRewardAmount,
        address _liquidityAdmin,
        address _vestingAdmin,
        address _gameRewardAdmin
    ) ERC20("MinterGuru", "MIGU") {
        require(_totalLimit == _liquidityAmount + _vestingAmount + _communityRewardAmount, "MinterGuruToken: wrong limits");
        totalLimit = _totalLimit;
        vestingLeftSupply = _vestingAmount;
        communityRewardLeftSupply = _communityRewardAmount;
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _grantRole(LIQUIDITY_ADMIN_ROLE, _liquidityAdmin);
        _grantRole(VESTING_ADMIN_ROLE, _vestingAdmin);
        _grantRole(COMMUNITY_REWARD_ADMIN_ROLE, _gameRewardAdmin);
        _mint(_liquidityAdmin, _liquidityAmount);
    }

    /// @dev burn tokens
    /// @param from - spending account
    /// @param value - spending value
    function burnWithOptionalReturn(address from, uint256 value) external {
        uint256 rate = PERCENT_MULTIPLIER * burned / totalLimit;
        uint256 toReturn = (rate * value) / PERCENT_MULTIPLIER;
        if (toReturn > value / 2) {
            toReturn = value / 2;
        }
        if (toReturn > 0) {
            transferFrom(from, address(this), toReturn);
            communityRewardLeftSupply += toReturn;
        }
        burned += value - toReturn;
        _spendAllowance(from, _msgSender(), value - toReturn);
        _burn(from, value - toReturn);
    }

    /// @dev create vesting record
    /// @param receiver - receiver of tokens
    /// @param stepValue - value released in each step
    /// @param stepDuration - duration of step in seconds
    /// @param steps - steps qty
    /// Emits a VestingStarted event
    function createVesting(
        address receiver,
        uint256 stepValue,
        uint256 stepDuration,
        uint256 steps
    ) external onlyRole(VESTING_ADMIN_ROLE) {
        require(stepValue > 0, "MinterGuruToken: step value must be positive");
        require(stepDuration > 0, "MinterGuruToken: step duration must be positive");
        require(steps > 0, "MinterGuruToken: steps quantity must be positive");
        require(vestingRecords[receiver].stepValue == 0, "MinterGuruToken: single receive can't have multiple vesting records");
        require(stepValue * steps <= vestingLeftSupply, "MinterGuruToken: vesting limit reached");
        vestingRecords[receiver] = VestingRecord(receiver, stepValue, stepDuration, steps, block.timestamp, 0);
        vestingLeftSupply -= stepValue * steps;
        emit VestingStarted(receiver, stepValue, stepDuration, steps);
    }

    /// @dev withdraw released vesting
    /// @param value - value to withdraw. Must be less then released and not withdrawn amount of tokens
    /// Emits a VestingWithdrawn event and VestingFullWithdrawn if all tokens were released and withdrawn
    function withdrawVesting(uint256 value) external {
        VestingRecord storage record = vestingRecords[_msgSender()];
        require(record.stepValue > 0, "MinterGuruToken: vesting record doesn't exist");
        require(value <= vestingAvailableToRelease(), "MinterGuruToken: value is greater than available amount of tokens");
        _sendTokens(_msgSender(), value);
        record.withdrawn += value;
        if (record.withdrawn == record.stepValue * record.steps) {
            emit VestingFullWithdrawn(_msgSender(), record.withdrawn);
            delete vestingRecords[_msgSender()];
        }
        emit VestingWithdrawn(_msgSender(), value);
    }

    /// @dev revoke vesting. All released funds remains with receiver, but new will not unlock
    /// @param receiver - account for which vesting must be revoked
    /// Emits a VestingRevoked event and VestingWithdrawn event if there are some released and not withdrawn tokens
    function revokeVesting(address receiver) external onlyRole(VESTING_ADMIN_ROLE) {
        VestingRecord storage record = vestingRecords[receiver];
        require(record.stepValue > 0, "MinterGuruToken: vesting record doesn't exist");
        uint256 availableAfterRevocation = record.stepValue * ((block.timestamp - record.createdAt) / record.stepDuration);
        vestingLeftSupply += (record.stepValue * record.steps - availableAfterRevocation);
        if (availableAfterRevocation > record.withdrawn) {
            _sendTokens(receiver, availableAfterRevocation - record.withdrawn);
            emit VestingWithdrawn(receiver, availableAfterRevocation - record.withdrawn);
        }
        emit VestingRevoked(receiver, record.withdrawn);
        delete vestingRecords[receiver];
    }

    /// @dev get released amount of tokens
    /// @return released amount of tokens ready for withdraw
    function vestingAvailableToRelease() public view returns (uint256) {
        VestingRecord storage record = vestingRecords[_msgSender()];
        require(record.stepValue > 0, "MinterGuruToken: vesting record doesn't exist");
        uint256 rightBound = block.timestamp;
        return record.stepValue * ((rightBound - record.createdAt) / record.stepDuration) - record.withdrawn;
    }

    /// @dev Create community event
    /// @param value - total value for event
    /// @param start - start of the event
    /// @param finish - finish of the event
    /// @param thresholds - thresholds for CommunityEvent. See GameEvent docs
    /// @param values - values for CommunityEvent. See CommunityEvent docs
    /// Emits a CommunityEventCreated event
    function createEvent(
        uint256 value,
        uint256 start,
        uint256 finish,
        uint256[] memory thresholds,
        uint256[] memory values
    ) external onlyRole(COMMUNITY_REWARD_ADMIN_ROLE) {
        require(start >= block.timestamp, "MinterGuruToken: event start must not be in the past");
        require(start < finish, "MinterGuruToken: start must be less than finish");
        require(value <= communityRewardLeftSupply, "MinterGuruToken: limit reached");
        require(thresholds.length + 1 == values.length, "MinterGuruToken: thresholds and values sizes unmatch");
        uint256 id = eventsCount;
        eventsCount++;
        currentEvents[id] = CommunityEvent(id, value, start, finish, thresholds, values, 0);
        communityRewardLeftSupply -= value;
        emit CommunityEventCreated(id, value, start, finish, thresholds, values);
    }

    /// @dev Check if there is enough supply for batch of the receivers
    /// @param id - id of CommunityEvent
    /// @param receiversCount - quantity of the receivers of the tokens
    /// @return allowed number of receivers (less or equal to receiversCount param)
    function canMint(
        uint256 id,
        uint256 receiversCount
    ) external view returns (uint256) {
        CommunityEvent memory ev = currentEvents[id];
        if (ev.value == 0) {
            return 0;
        }
        for (uint256 i = 0; i < receiversCount; i++) {
            uint256 value = _calcGamingReward(ev);
            ev.currentSupply += value;
            if (ev.currentSupply == ev.value) {
                return i + 1;
            }
        }
        return receiversCount;
    }

    /// @dev Mint CommunityEvent reward tokens
    /// @param id - id of CommunityEvent
    /// @param to - receiver of tokens
    /// Emits a CommunityEventFinished event if supply fully minted
    function mintCommunityReward(
        uint256 id,
        address to
    ) external onlyRole(COMMUNITY_REWARD_ADMIN_ROLE) {
        address[] memory receivers = new address[](1);
        receivers[0] = to;
        _mintCommunityReward(id, receivers);
    }

    /// @dev Mint CommunityEvent reward tokens for batch of addresses
    /// @param id - id of CommunityEvent
    /// @param receivers - receivers of tokens
    /// Emits a CommunityEventFinished event if supply fully minted
    function mintCommunityRewardForMultiple(
        uint256 id,
        address[] calldata receivers
    ) external onlyRole(COMMUNITY_REWARD_ADMIN_ROLE) {
        _mintCommunityReward(id, receivers);
    }

    /// @dev Finish event. Only for expired events in which not full supply was distributed
    /// @param id - id of CommunityEvent
    /// Emits a CommunityEventFinished event
    function finishEvent(
        uint256 id
    ) external onlyRole(COMMUNITY_REWARD_ADMIN_ROLE) {
        CommunityEvent storage ev = currentEvents[id];
        require(ev.value > 0, "MinterGuruToken: event doesn't exist");
        _finishEvent(ev);
    }

    /// @dev Top up community reward pool
    /// @param value - value to transfer
    function topUpCommunityRewardPool(uint256 value) external {
        require(balanceOf(_msgSender()) >= value, "MinterGuruToken: insufficient funds");
        transferFrom(_msgSender(), address(this), value);
        communityRewardLeftSupply += value;
    }

    /// @dev Top up vesting pool
    /// @param value - value to transfer
    function topUpVestingPool(uint256 value) external {
        require(balanceOf(_msgSender()) >= value, "MinterGuruToken: insufficient funds");
        transferFrom(_msgSender(), address(this), value);
        vestingLeftSupply += value;
    }

    /// @dev Calculate pending reward for GameEvent
    /// @param id - id of CommunityEvent
    /// @return expected reward
    function calcCommunityReward(uint256 id) public view returns (uint256) {
        CommunityEvent storage ev = currentEvents[id];
        require(ev.value > 0, "MinterGuruToken: event doesn't exist");
        require(ev.start <= block.timestamp && block.timestamp <= ev.finish, "MinterGuruToken: event is not active");
        return _calcGamingReward(ev);
    }

    /// @dev Finish event internal func
    /// @param ev - CommunityEvent to finish
    /// Emits a CommunityEventFinished event
    function _finishEvent(
        CommunityEvent storage ev
    ) internal {
        if (ev.value - ev.currentSupply > 0) {
            communityRewardLeftSupply += (ev.value - ev.currentSupply);
        }
        delete currentEvents[ev.id];
        emit CommunityEventFinished(ev.id);
    }

    /// @dev mint community reward helper function
    /// @param id - id of community event
    /// @param receivers - list of receivers
    function _mintCommunityReward(uint256 id, address[] memory receivers) internal {
        CommunityEvent storage ev = currentEvents[id];
        require(ev.value > 0, "MinterGuruToken: event doesn't exist");
        require(ev.start <= block.timestamp && block.timestamp <= ev.finish, "MinterGuruToken: event is not active");
        for (uint256 i = 0; i < receivers.length; i++) {
            address to = receivers[i];
            uint256 value = _calcGamingReward(ev);
            _sendTokens(to, value);
            ev.currentSupply += value;
            if (ev.currentSupply == ev.value) {
                require(i == receivers.length - 1, "MinterGuruToken: supply finished");
                _finishEvent(ev);
            }
        }
    }

    /// @dev Calculate pending reward for GameEvent helper function
    /// @param ev - GameEvent to check
    /// @return expected reward
    function _calcGamingReward(CommunityEvent memory ev) internal view returns (uint256) {
        if ((10 * (block.timestamp - ev.start)) / (ev.finish - ev.start) < 2) {
            return _findGamingReward(ev, PERCENT_MULTIPLIER);
        }
        uint256 expectedSupply = (ev.value * (block.timestamp - ev.start)) / (ev.finish - ev.start);
        uint256 eventRate = ev.currentSupply * PERCENT_MULTIPLIER / expectedSupply;
        uint256 res = _findGamingReward(ev, eventRate);
        if (ev.value - ev.currentSupply < res) {
            res = ev.value - ev.currentSupply;
        }
        return res;
    }

    /// @dev Helper function. If there are some returned tokens (from burn), then they will be used to send to receiver
    /// @param to - tokens receiver
    /// @param value - value to transfer
    function _sendTokens(address to, uint256 value) internal {
        uint256 returnedTokens = balanceOf(address(this));
        uint256 toTransfer;
        if (returnedTokens >= value) {
            toTransfer = value;
        } else {
            toTransfer = returnedTokens;
        }
        uint256 toMint = value - toTransfer;
        if (toTransfer > 0) {
            _transfer(address(this), to, toTransfer);
        }
        if (toMint > 0) {
            _mint(to, toMint);
        }
    }

    /// @dev Helper function to find gaming reward based on percent of minted supply (100% - expected supply)
    /// @param ev - event to check
    /// @param percent - percent to check
    /// @return expected reward
    function _findGamingReward(
        CommunityEvent memory ev,
        uint256 percent
    ) internal pure returns (uint256) {
        for (uint256 i = 0; i < ev.thresholds.length; i++) {
            if (percent < ev.thresholds[i]) {
                return ev.values[i];
            }
        }
        return ev.values[ev.values.length - 1];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

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
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
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
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
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
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

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
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
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
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

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
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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