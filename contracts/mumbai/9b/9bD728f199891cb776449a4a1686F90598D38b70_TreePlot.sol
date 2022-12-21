// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

/**
* @title TreePlot: managing an homogenues plot of monitored trees (single stratum)
* @author Luca Buonocore
* @dev Smart contract which allows:
    1) The Forest Manager (FORESTMANAGER_ROLE) to register/remove trees monitored via IoT devices into the blockchain network
    These trees are part of permanent plots of a stand with uniform characteristics
    2) The service managing the IoT devices (TREE_NETWORK_ROLE) to:
        - record the net change of the carbon content per single trees
        - report an early-warning proposing a buffer of carbon content per tree to allocate as contingency
    3) An inspector (INSPECTOR_ROLE) to confirm the carbon content per single tree
    4) A Risk Manager (RISKMANGER_ROLE) to confirm the buffer of carbon content per tree
    
    Both Inspector and Risk Manager can be physical persons or virtual entities that perform automated controls     

The contract Admin (DEFAULT_ADMIN_ROLE) is the creator of the contract

This contract is part of two contracts (Stand.sol and CarbonProject.sol) and inherits 
set of controls from them:
    1) xxx
    2 xxxxxxxx
    xxxxxxxxxxx

*/

/** TO DOs
    - Update tree metadata (emit event)
    - controlli sul plot ---> Mettere la funzione che registra i plot e fa in controlli quando registri l'albero 
    (plot ID e numero di alberi) e non ti fa registrare piu plot di quanti indicati nel contratto tree stand
    - Una funzione che fa la somma dei valori degli alberi per plot
 */

// Import AccessControl from the OpenZeppelin Contracts library
import "AccessControl.sol";



contract TreePlot is AccessControl {
    /* Access Controls */

    bytes32 public constant FORESTMANAGER_ROLE =
        keccak256("FORESTMANAGER_ROLE");
    bytes32 public constant TREE_NETWORK_ROLE = keccak256("TREE_NETWORK_ROLE");
    bytes32 public constant INSPECTOR_ROLE = keccak256("INSPECTOR_ROLE");
    bytes32 public constant RISKMANGER_ROLE = keccak256("RISKMANGER_ROLE");

    /* enums */

    // the state of the Tree on the blockhain network
    enum treeState {
        Not_Registered,
        Living,
        Carbon_Accrued,
        Terminated
    }

    enum CarbonPools {
        Above_ground_live_tree,
        Above_ground_dead_tree,
        Below_ground_live_biomass,
        Below_ground_dead_biomass
    }

    /* structs */

    // Carbon accrued and buffer per single tree
    struct TreeCarbonAccount {
        uint256 Carbon_Accrued_Confirmed;
        uint256 Carbon_Accrued_ToBe_Verified;
        uint256 Carbon_Buffer_Confirmed;
        uint256 Carbon_Buffer_ToBe_Verified;
        CarbonPools TreeCarbonPool;
        int256 year;
        int256 doy;
    }

    struct Tree {
        string TreeTalkerID; // TT code mounted on the tree
        string StandID;
        int256 PlotNumber; // mettere la verifica del plot Number//
        string Species; // Tree species
        uint256 Height; // Tree Heigh in meters
        uint256 Diameter; // Tree Diameter in meters
        address Recorder; // Who registers the Tree in the blockchain
        treeState State;
        TreeCarbonAccount CarbonAccount;
        uint256 OperationsFunds; // Deposit for tree management activities in wei
        bool Carbon_Recording_Method; // Cumulative (TRUE) or Delta (FALSE)
    }

    /* Modifiers */

    modifier hasValue() {
        require(msg.value > 0);
        _;
    }

    /**  modifiers implementing conditions based on the tree state in the network  --> mettere nella tesi e togliere da qui
        - If the tree is terminated no other actions are possible  
    */

    modifier treeExist(string memory _TreeTalkerCode) {
        require(Trees[_TreeTalkerCode].State != treeState.Not_Registered);
        _;
    }

    modifier no_early_Warning(string memory _TreeTalkerCode) {
        require(
            Trees[_TreeTalkerCode].CarbonAccount.Carbon_Buffer_ToBe_Verified ==
                0,
            "Verify early Warning first"
        );
        _;
    }

    /** modifiers implementing conditions based on the Stand.sol contract
        - numnber of trees per plot
        - plot id exist
     */

    /* constructor */

    constructor(
        address _forestManager,
        address _tree_network,
        address _inspector,
        address _riskManager
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(FORESTMANAGER_ROLE, _forestManager);
        _setupRole(TREE_NETWORK_ROLE, _tree_network);
        _setupRole(INSPECTOR_ROLE, _inspector);
        _setupRole(RISKMANGER_ROLE, _riskManager);

        emit ContractCreated(applicationName, msg.sender);
    }

    /* storage */

    mapping(string => Tree) public Trees;

    string[] public Plot;

    /* addresses  --> none*/

    /* strings */

    string internal applicationName = "TreePlot";

    /* functions */

    /**
     * @dev record a tree on the network
     */
    function recordTree(
        string memory _TreeTalkerID,
        string memory _StandID,
        int256 _PlotNumb,
        string memory _Species,
        uint256 _Height,
        uint256 _Diameter,
        bool _Carbon_Recording_Method,
        CarbonPools _TreeCarbonPool,
        int256 _year,
        int256 _doy
    ) external payable hasValue onlyRole(FORESTMANAGER_ROLE) {
        require(
            Trees[_TreeTalkerID].State == treeState.Not_Registered,
            "Tree already registered"
        );
        require(
            keccak256(abi.encodePacked(_TreeTalkerID)) !=
                keccak256(abi.encodePacked("")),
            "Enter a tree talker code"
        );

        // aggiungere il require che il plot array sia inferiore alla dimensione

        TreeCarbonAccount memory _TreeCarbonAccount;

        _TreeCarbonAccount.Carbon_Accrued_Confirmed = 0;
        _TreeCarbonAccount.Carbon_Accrued_ToBe_Verified = 0;
        _TreeCarbonAccount.Carbon_Buffer_Confirmed = 0;
        _TreeCarbonAccount.Carbon_Buffer_ToBe_Verified = 0;
        _TreeCarbonAccount.TreeCarbonPool = _TreeCarbonPool;
        _TreeCarbonAccount.year = _year;
        _TreeCarbonAccount.doy = _doy;

        // add the tree to the mapping
        Trees[_TreeTalkerID] = Tree(
            _TreeTalkerID,
            _StandID,
            _PlotNumb,
            _Species,
            _Height,
            _Diameter,
            msg.sender,
            treeState.Living,
            _TreeCarbonAccount,
            msg.value, // funds in wei that the tree manager assigns to the tree
            _Carbon_Recording_Method
        );

        // add the treetalker ID to the plot array
        Plot.push(Trees[_TreeTalkerID].TreeTalkerID);

        emit TreeRecorded(_TreeTalkerID, msg.sender, msg.value);
    }

    /**
    * @dev  change the state of the tree to "Terminated". No new operations to 
    the tree allowed. OperationsFunds returned to the forest manager
    */

    function treeTerminate(string memory _TreeTalkerID)
        public
        payable
        treeExist(_TreeTalkerID)
        hasValue
        onlyRole(FORESTMANAGER_ROLE)
    {
        Trees[_TreeTalkerID].State = treeState.Terminated;
        payable(Trees[_TreeTalkerID].Recorder).transfer(
            Trees[_TreeTalkerID].OperationsFunds
        );
        emit TreeTerminated(
            Trees[_TreeTalkerID].TreeTalkerID,
            msg.sender,
            Trees[_TreeTalkerID].OperationsFunds
        );
    }

    /**
    * @dev  
    TreeNetwork records carbon accrued (just if the tree is in "living")
    */

    function treeAccrueCarbon(
        string memory _TreeTalkerID,
        uint256 _Carbon_Accrued,
        int256 _year,
        int256 _doy
    ) external treeExist(_TreeTalkerID) onlyRole(TREE_NETWORK_ROLE) {
        if (Trees[_TreeTalkerID].State != treeState.Living) {
            revert("Tree must be in state living");
        }

        Trees[_TreeTalkerID].State = treeState.Carbon_Accrued;
        Trees[_TreeTalkerID]
            .CarbonAccount
            .Carbon_Accrued_ToBe_Verified = _Carbon_Accrued;
        Trees[_TreeTalkerID].CarbonAccount.year = _year;
        Trees[_TreeTalkerID].CarbonAccount.doy = _doy;

        emit TreeStateUpdated(_TreeTalkerID, "Carbon_Accrued", msg.sender);
    }

    /**
    * @dev  
    the inspector confirms the carbon accruded per single tree
    */

    function treeConfirmCarbonAccrued(
        string memory _TreeTalkerID,
        uint256 _Carbon_Accrued
    )
        external
        treeExist(_TreeTalkerID)
        no_early_Warning(_TreeTalkerID)
        onlyRole(INSPECTOR_ROLE)
    {
        if (Trees[_TreeTalkerID].State != treeState.Carbon_Accrued) {
            revert("Tree must be in Carbon_Accrued");
        }

        Trees[_TreeTalkerID].State = treeState.Living;
        Trees[_TreeTalkerID]
            .CarbonAccount
            .Carbon_Accrued_Confirmed += _Carbon_Accrued;

        emit TreeStateUpdated(
            _TreeTalkerID,
            "Carbon Accrued Confirmed",
            msg.sender
        );
    }

    function treeEarlyWarning(
        string memory _TreeTalkerID,
        uint256 _Carbon_Buffer
    ) external treeExist(_TreeTalkerID) onlyRole(TREE_NETWORK_ROLE) {
        if (Trees[_TreeTalkerID].State == treeState.Terminated) {
            revert("Tree terminated");
        }

        Trees[_TreeTalkerID]
            .CarbonAccount
            .Carbon_Buffer_ToBe_Verified += _Carbon_Buffer;

        emit TreeStateUpdated(_TreeTalkerID, "EarlyWarning", msg.sender);
    }

    /**
     * @dev  In case of Earlywarning the risk manager has to confirm the carbon buffer
     */

    function treeConfirmCarbonBuffer(
        string memory _TreeTalkerID,
        uint256 _Carbon_Buffer
    ) external treeExist(_TreeTalkerID) onlyRole(RISKMANGER_ROLE) {
        if (Trees[_TreeTalkerID].State == treeState.Terminated) {
            revert("Tree terminated");
        }

        Trees[_TreeTalkerID]
            .CarbonAccount
            .Carbon_Buffer_Confirmed = _Carbon_Buffer;
        Trees[_TreeTalkerID].CarbonAccount.Carbon_Buffer_ToBe_Verified = 0;

        emit TreeStateUpdated(_TreeTalkerID, "EarlyWarning", msg.sender);
    }

    function PlotTreeListReturn() public view returns (string[] memory) {
        return (Plot);
    }

    /* Events */

    event TreeRecorded(
        string _TreeTalkerCode,
        address recorder,
        uint256 deposit
    );

    event TreeTerminated(
        string treeTalkerCode,
        address recorder,
        uint256 deposit
    );

    event ContractCreated(string applicationName, address originatingAddress);

    event TreeStateUpdated(
        string _TreeTalkerCode,
        string TreeState,
        address updatingAddress
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";
import "Strings.sol";
import "ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);

    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    function grantRole(bytes32 role, address account) external;

    function revokeRole(bytes32 role, address account) external;

    function renounceRole(bytes32 role, address account) external;
}

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
     * bearer except when using {_setupRole}.
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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
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
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
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
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
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
     * If the calling account had been granted `role`, emits a {RoleRevoked}
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
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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

pragma solidity ^0.8.0;

import "IERC165.sol";

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