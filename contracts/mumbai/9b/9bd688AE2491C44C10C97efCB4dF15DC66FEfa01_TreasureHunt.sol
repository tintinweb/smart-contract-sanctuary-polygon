// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ICharityID} from "./interfaces/ICharityID.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TreasureHunt Contract
 * @author SolarHunt Team @ ETHCC23 Prague Hackathon
 */
contract TreasureHunt is AccessControl, ReentrancyGuard {
    // =========================== Enum ==============================

    /// @notice Enum Treasure Hunt
    enum Status {
        Opened,
        Closed
    }

    // =========================== Struct ==============================

    /// @notice TreasureHunt information struct
    /// @param id The unique ID for a TreasureHunt
    /// @param charityId The unique ID associated with the charity for this TreasureHunt
    /// @param depositAmount the amout a user must deposit to participate to the TreasureHunt
    /// @param cid Content Identifier on IPFS for this TreasureHunt
    /// @param totalDeposit The total amount of deposit made for this TreasureHunt
    /// @param secretCode The secret code hash for this TreasureHunt (keccak256(secretCode)
    struct TreasureHunt {
        Status status;
        uint256 id;
        uint256 charityId;
        uint256 depositAmount;
        string cid;
        uint256 totalTreasureHuntDeposit;
        bytes32 secretCodeHash;
        uint256 numParticipants;
    }

    /// @notice incremental service Id
    uint256 public nextTreasureHuntId = 1;

    /// Charity  ID contarct instance
    ICharityID public charityIdContrat;

    /// @notice Treasure Hunt mappings index by ID
    mapping(uint256 => TreasureHunt) public treasureHunts;

    // Treasure hunt -> Player -> Deposit
    mapping(uint256 => mapping(address => uint256)) public treasureHuntPlayerDeposit;

    /**
     * @param _charityContractAddress TalentLayerId address
     */
    constructor(address _charityContractAddress) {
        charityIdContrat = ICharityID(_charityContractAddress);
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // =========================== View functions ==============================

    /**
     * @notice Return the whole service data information
     * @param _treasureHuntId Treasure Hunt identifier
     * @return TreasureHunt returns the TreasureHunt struct
     */
    function getTreasureHunt(uint256 _treasureHuntId) external view returns (TreasureHunt memory) {
        require(_treasureHuntId < nextTreasureHuntId, "This treasure Hunt doesn't exist");
        return treasureHunts[_treasureHuntId];
    }

    // =========================== User functions ==============================

    /**
     * @notice Update handle address mapping and emit event after mint.
     * @param _charityId the charityId of the charity
     * @param _depositAmount the bounty amount for the Treasure Hunt
     * @param _treasureHuntCid Content Identifier on IPFS for this TreasureHunt
     * @param _secretCodeHash Hashed version of the secret code for this TreasureHunt
     * @return uint256 returns the id of the newly created Treasure Hunt
     */
    function createTreasureHunt(
        uint256 _charityId,
        string calldata _treasureHuntCid,
        uint256 _depositAmount,
        bytes32 _secretCodeHash
    ) public onlyCharityOwner(_charityId) returns (uint256) {
        charityIdContrat.isValid(_charityId);

        return _createTreasureHunt(Status.Opened, _charityId, _depositAmount, _treasureHuntCid, _secretCodeHash);
    }

    // update createTreasureHuntFromCharity to allow the charity to update the bounty amount
    function updateTreasureHunt(
        uint256 _charityId,
        uint256 _treasureHuntId,
        string calldata _newTreasureHuntCid
    ) public onlyCharityOwner(_charityId) returns (uint256) {
        require(_treasureHuntId < nextTreasureHuntId, "This Treasure hunt doesn't exist");
        require(treasureHunts[_treasureHuntId].status == Status.Opened, "This Treasure hunt is not opened");
        require(bytes(_newTreasureHuntCid).length == 46, "Invalid cid");

        require(
            treasureHunts[_treasureHuntId].charityId == charityIdContrat.ids(msg.sender),
            "You're not the owner of this TreasureHunt"
        );

        treasureHunts[_treasureHuntId].cid = _newTreasureHuntCid;

        emit TreasureHuntDetailedUpdated(_treasureHuntId, _newTreasureHuntCid);
    }

    function closeTreasureHunt(uint256 _charityId, uint256 _treasureHuntId) public onlyCharityOwner(_charityId) {
        require(_treasureHuntId < nextTreasureHuntId, "This Treasure hunt doesn't exist");
        require(treasureHunts[_treasureHuntId].status == Status.Opened, "This Treasure hunt is not opened");

        require(
            treasureHunts[_treasureHuntId].charityId == charityIdContrat.ids(msg.sender),
            "You're not the owner of this TreasureHunt"
        );

        treasureHunts[_treasureHuntId].status = Status.Closed;

        emit TreasureHuntClosed(_treasureHuntId);
    }

    /**
     * @notice Update handle address mapping and emit event after mint.
     * @param _treasureHuntId the id of the TreasureHunt
     * @param _secretCodeHash the secret code for the TreasureHunt
     * @return uint256 returns the id of the newly created Treasure Hunt
     */

    function claimTreasureHunt(uint256 _treasureHuntId, bytes32 _secretCodeHash) public nonReentrant returns (uint256) {
        require(_treasureHuntId < nextTreasureHuntId, "This Treasure hunt doesn't exist");
        require(treasureHunts[_treasureHuntId].status == Status.Opened, "This Treasure hunt is not opened");

        // require(_secretCodeHash == treasureHunts[_treasureHuntId].secretCodeHash, "The secret code is not correct");

        require(
            keccak256(abi.encodePacked(_secretCodeHash)) ==
                keccak256(abi.encodePacked(treasureHunts[_treasureHuntId].secretCodeHash)),
            "The secret code is not correct"
        );

        // calculate and transfer the bounty to the charity and the player and the contract
        uint256 totalBounty = treasureHunts[_treasureHuntId].totalTreasureHuntDeposit;

        // Calculate the contract's gain (1% of the total bounty)
        uint256 contractAmount = totalBounty / 100;
        totalBounty -= contractAmount; // subtract contract's share from total bounty

        uint256 charityGain = charityIdContrat.charities(treasureHunts[_treasureHuntId].charityId).charityGain;
        uint256 charityAmount = (totalBounty * charityGain) / 100;
        uint256 playerAmount = totalBounty - charityAmount;

        (bool charitySent, ) = payable(charityIdContrat.ownerOf(treasureHunts[_treasureHuntId].charityId)).call{
            value: charityAmount
        }("");
        require(charitySent, "Failed to send bounty to charity");

        (bool playerSent, ) = payable(msg.sender).call{value: playerAmount}("");
        require(playerSent, "Failed to send bounty to player");

        // Reset the totalTreasureHuntDeposit to 0 as the funds have been distributed
        treasureHunts[_treasureHuntId].totalTreasureHuntDeposit = 0;

        treasureHunts[_treasureHuntId].status = Status.Closed;

        emit TreasureHuntClaimed(_treasureHuntId, msg.sender);
    }

    // =========================== Private functions ==============================

    /**
     * @notice Creates a new TreasureHunt and emits the TreasureHuntCreated event.
     * @param _status The status of the TreasureHunt
     * @param _charityId The id of the associated charity
     * @param _depositAmount The amount of the deposit for the TreasureHunt
     * @param _treasureHuntCid The IPFS content identifier for the TreasureHunt
     * @param secretCodeHash The hashed version of the secret code for the TreasureHunt
     * @return uint256 The id of the newly created TreasureHunt
     */

    function _createTreasureHunt(
        Status _status,
        uint256 _charityId,
        uint256 _depositAmount,
        string calldata _treasureHuntCid,
        bytes32 secretCodeHash
    ) private returns (uint256) {
        require(bytes(_treasureHuntCid).length == 46, "Invalid cid");

        uint256 id = nextTreasureHuntId;
        nextTreasureHuntId++;

        TreasureHunt storage treasureHunt = treasureHunts[id];
        treasureHunt.status = Status.Opened;
        treasureHunt.charityId = _charityId;
        treasureHunt.depositAmount = _depositAmount;
        treasureHunt.cid = _treasureHuntCid;
        treasureHunt.secretCodeHash = secretCodeHash;

        emit treasureHuntCreated(Status.Opened, id, _charityId, _depositAmount, _treasureHuntCid, secretCodeHash);

        return id;
    }

    // =========================== Player function ==============================

    /**
     * @notice Allows a player to deposit a specified amount of Ether to participate in a Treasure Hunt.
     * The deposited amount is added to the total bounty of the Treasure Hunt and recorded as the player's contribution.
     * @dev This function is payable, allowing it to receive Ether along with the transaction.
     * The value sent is in Wei, and it gets added to the total bounty of the Treasure Hunt and to the player's contribution for this Treasure Hunt.
     * @param _treasureHuntId The unique ID of the Treasure Hunt that the player wishes to participate in.
     */
    function depositAmountToParticipate(uint256 _treasureHuntId) public payable {
        require(_treasureHuntId < nextTreasureHuntId, "This Treasure hunt doesn't exist");
        require(treasureHunts[_treasureHuntId].status == Status.Opened, "This Treasure hunt is not opened");
        require(msg.value > 0, "You must deposit more than 0");

        // require(msg.value == treasureHunts[_treasureHuntId].depositAmount, "Incorrect deposit amount"); DEPRECATED
        // we don't want limited the amount of the donation

        // Add the deposit to the total bounty amount
        treasureHunts[_treasureHuntId].totalTreasureHuntDeposit += msg.value;

        // Keep track of the player's deposit for this treasure hunt
        treasureHuntPlayerDeposit[_treasureHuntId][msg.sender] += msg.value;

        treasureHunts[_treasureHuntId].numParticipants++;

        emit DepositToParticipateDone(msg.sender, msg.value, _treasureHuntId);
    }

    // Fallback function to prevent from sending ether to the contract
    receive() external payable {
        revert("Please use the depositBountyAmount function to deposit ethers");
    }

    /**
     * Withdraws the contract balance to the admin.
     */
    function withdraw(address _solarFundAddress) public onlyRole(DEFAULT_ADMIN_ROLE) {
        (bool sent, ) = payable(_solarFundAddress).call{value: address(this).balance}("");
        require(sent, "Failed to withdraw");

        emit WithdrawDone(_solarFundAddress, address(this).balance);
    }

    // =========================== Modifiers ==============================

    /**
     * @notice Check if msg sender is the owner of a platform
     * @param _charityId The ID of the Charity
     */
    modifier onlyCharityOwner(uint256 _charityId) {
        require(charityIdContrat.ownerOf(_charityId) == msg.sender, "Not the owner");
        _;
    }

    // =========================== Events ==============================

    /// @notice Emitted after a new TreasureHunt is created
    /// @param id The TreasureHunt ID (incremental)
    /// @param status The current status of the TreasureHunt
    /// @param charityId The unique ID associated with the charity for this TreasureHunt
    /// @param bountyAmount The amount of bounty for the TreasureHunt
    /// @param treasureHuntCid Content Identifier on IPFS for this TreasureHunt
    /// @param secretCodeHash Hashed version of the secret code for this TreasureHunt
    event treasureHuntCreated(
        Status status,
        uint256 id,
        uint256 charityId,
        uint256 bountyAmount,
        string treasureHuntCid,
        bytes32 secretCodeHash
    );

    /// @notice Emitted when a player makes a deposit to participate in a treasure hunt
    /// @param playerAddress The address of the player
    /// @param amountDeposit The amount deposited by the player
    /// @param treasureHuntId The ID of the treasure hunt
    event DepositToParticipateDone(address indexed playerAddress, uint256 amountDeposit, uint256 treasureHuntId);

    /// @notice Emitted when the details of a treasure hunt are updated
    /// @param treasureHuntId The ID of the treasure hunt
    /// @param newTreasureHuntCid The new content identifier (CID) of the treasure hunt
    event TreasureHuntDetailedUpdated(uint256 indexed treasureHuntId, string newTreasureHuntCid);

    /// @notice Emitted when a treasure hunt is claimed by a player
    /// @param treasureHuntId The ID of the treasure hunt
    /// @param player The address of the player who claimed the treasure hunt
    event TreasureHuntClaimed(uint256 indexed treasureHuntId, address indexed player);

    /// @notice Emitted when a treasure hunt is closed
    /// @param treasureHuntId The ID of the treasure hunt
    event TreasureHuntClosed(uint256 indexed treasureHuntId);

    /// @notice Emitted when an amount is withdrawn from the solar fund
    /// @param solarFundAddress The address of the solar fund
    /// @param amountWithdrawn The amount withdrawn from the solar fund
    event WithdrawDone(address indexed solarFundAddress, uint256 amountWithdrawn);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICharityID {
    struct Charity {
        uint256 id;
        string name;
        string cid;
        uint256 charityGain;
    }

    function takenCharityNames(string calldata) external view returns (bool);

    function charities(uint256) external view returns (Charity memory);

    function ids(address) external view returns (uint256);

    function getCharity(uint256 _charityId) external view returns (Charity memory);

    function totalSupply() external view returns (uint256);

    function updateProfileData(uint256 _charityId, string memory _newCid) external;

    function updatecharityGain(uint256 _charityId, uint256 _charityGain) external;

    function mintForAddress(string calldata _charityName, address _charityAddress) external payable returns (uint256);

    function isValid(uint256 _charityId) external view;

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    event CidUpdated(uint256 indexed _tokenId, string _newCid);
    event CharityGainUpdated(uint256 _charityId, uint256 _charityGain);
    event Mint(address indexed _charityAddress, uint256 charityId, string _charityName);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

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
                        Strings.toHexString(account),
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
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
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

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
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
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
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
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
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
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
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
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