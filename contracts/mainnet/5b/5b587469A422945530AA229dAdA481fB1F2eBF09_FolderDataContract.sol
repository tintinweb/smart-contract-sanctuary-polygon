// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

interface ProjectDataInterface {
    function getProjectExists(uint256 projectId) external view returns (bool);
}

struct FolderData {
    uint folderId;
    bytes32 folderReference;
    string name;
    string description;
    bool hidden;
    bool exists;
}

struct FileData {
    uint fileId;
    bytes32 fileReference;
    string title;
    uint timestamp;
    string fileUrl;
    bool hidden;
    bool exists;
}

contract FolderDataContract is AccessControlEnumerable {
    
    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    bool private _initialised;

    ProjectDataInterface private _projectDataInstance;
    mapping (uint => FolderData[]) _folders;
    mapping (uint => mapping (uint => FileData[])) _files;

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // **************************************************
    // ***************** MODERATOR REGION ***************
    // **************************************************
    /// @notice Add folder to a project
    /// @dev Project id must exist
    /// @param projectId_ Id of the project you want to add folder
    /// @param folderReference_ Reference to the record corresponding to the folder in the off-chain database
    /// @param name_ Name of the folder
    /// @param description_ Description of the folder
    /// @param hidden_ Is folder shown on frontend
    function addFolder(
        uint projectId_, 
        bytes32 folderReference_,
        string memory name_, 
        string memory description_, 
        bool hidden_
    ) public onlyRole(MODERATOR_ROLE) {
        require(_projectDataInstance.getProjectExists(projectId_), "Project does not exist!");
        _folders[projectId_].push(
            FolderData(
                getFolderCount(projectId_), 
                folderReference_,
                name_, 
                description_, 
                hidden_, 
                true
            )
        );

        emit FolderAdded(
            projectId_,
            getFolderCount(projectId_) - 1, 
            folderReference_, 
            name_, 
            description_, 
            hidden_
        );
    }
    /// @notice Edit existing folder in a project
    /// @dev Project id must exist and valueId should be between 0-2
    /// @param projectId_ Id of the project you want to change
    /// @param folderId_ Id of the folder you want to change
    /// @param valueId_ Id of value that you want to change
    /// @param newValue_ New value in bytes
    function editFolder(uint projectId_, uint folderId_, uint valueId_, bytes memory newValue_) public onlyRole(MODERATOR_ROLE) {
        require(_projectDataInstance.getProjectExists(projectId_), "Project does not exist!");
        FolderData storage folder = _folders[projectId_][folderId_];
        require(folder.exists, "Folder does not exist!");

        if(valueId_ == 0) {
            string memory newValue = abi.decode(newValue_, (string));
            require(keccak256(bytes(folder.name)) != keccak256(newValue_), "Value is already set!" );
            emit FolderNameChanged(projectId_, folderId_, folder.name, newValue);
            folder.name = newValue;
        } else if(valueId_ == 1) {
            string memory newValue = abi.decode(newValue_, (string));
            require(keccak256(bytes(folder.description)) != keccak256(newValue_), "Value is already set!" );
            emit FolderDescriptionChanged(projectId_, folderId_, folder.description, newValue);
            folder.description = newValue;
        } else if(valueId_ == 2) {
            bool newValue = abi.decode(newValue_, (bool));
            require(folder.hidden != newValue, "Value is already set!" );
            emit FolderHiddenChanged(projectId_, folderId_, folder.hidden, newValue);
            folder.hidden = newValue;
        } else {
            revert("Value does not exist!");
        }
    }
    /// @notice Swap two folders so order will be different on frontend
    /// @dev Project id must exist and folder ids must be in range
    /// @param projectId_ Id of the project you want to change folders
    /// @param firstFolderId_ Id of the first folder
    /// @param secondFolderId_ Id of the second folder
    function swapFolders(uint projectId_, uint firstFolderId_, uint secondFolderId_) public onlyRole(MODERATOR_ROLE) {
        require(_projectDataInstance.getProjectExists(projectId_), "Project does not exist!");
        FolderData memory firstFolder = getFolder(projectId_, firstFolderId_);
        FolderData memory secondFolder = getFolder(projectId_, secondFolderId_);
        require(firstFolder.exists, "FirstFolder does not exist!");
        require(secondFolder.exists, "SecondFolder does not exist!");

        _folders[projectId_][firstFolderId_] = secondFolder;
        _folders[projectId_][firstFolderId_].folderId = secondFolderId_;
        _folders[projectId_][secondFolderId_] = firstFolder;
        _folders[projectId_][secondFolderId_].folderId = firstFolderId_;

        emit FoldersSwapped(projectId_, firstFolderId_, secondFolderId_);
    }

    /// @notice Add file to a folder
    /// @dev Project id must exist and folder id must be in range
    /// @param fileReference_ Reference to the record corresponding to the file in the off-chain database
    /// @param projectId_ Id of the project you want to add file
    /// @param folderId_ Id of the folder you want to add file
    /// @param title_ Title of the file
    /// @param timestamp_ Timestamp of the file
    /// @param fileUrl_ Url of the file
    /// @param hidden_ Is file shown on frontend
    function addFile(
        bytes32 fileReference_,
        uint projectId_, 
        uint folderId_, 
        string memory title_, 
        uint timestamp_, 
        string memory fileUrl_, 
        bool hidden_
    ) public onlyRole(MODERATOR_ROLE) {
        require(_projectDataInstance.getProjectExists(projectId_), "Project does not exist!");
        require(getFolderExists(projectId_, folderId_), "Folder does not exist!");
        _files[projectId_][folderId_].push(
            FileData(
                getFileCount(projectId_, folderId_),
                fileReference_, 
                title_, 
                timestamp_, 
                fileUrl_, 
                hidden_, 
                true
            )
        );

        emit FileAdded(projectId_, folderId_, getFileCount(projectId_, folderId_) - 1, title_, timestamp_, fileUrl_, hidden_);
    }
    /// @notice Edit file in a folder
    /// @dev Project id must exist and folder id must be in range and valueId should be between 0-4
    /// @param projectId_ Id of the project you want to change
    /// @param folderId_ Id of the folder you want to change
    /// @param fileId_ Id of the file you want to change
    /// @param valueId_ Id of value that you want to change
    function editFile(uint projectId_, uint folderId_, uint fileId_, uint valueId_, bytes memory newValue) public onlyRole(MODERATOR_ROLE){
        require(_projectDataInstance.getProjectExists(projectId_), "Project does not exist!");
        require(getFolderExists(projectId_, folderId_), "Folder does not exist!");
        FileData storage file = _files[projectId_][folderId_][fileId_];
        require(file.exists, "File does not exist!");

        if(valueId_ == 0) {
            string memory newValue_ = abi.decode(newValue, (string));
            require(keccak256(bytes(file.title)) != keccak256(newValue), "Value is already set!" );
            emit FileTitleChanged(projectId_, folderId_, fileId_, file.title, newValue_);
            file.title = newValue_;
        } else if(valueId_ == 1) {
            uint newValue_ = abi.decode(newValue, (uint));
            require(file.timestamp != newValue_, "Value is already set!" );
            emit FileTimestampChanged(projectId_, folderId_, fileId_, file.timestamp, newValue_);
            file.timestamp = newValue_;
        } else if(valueId_ == 2) {
            string memory newValue_ = abi.decode(newValue, (string));
            require(keccak256(bytes(file.fileUrl)) != keccak256(newValue), "Value is already set!" );
            emit FileUrlChanged(projectId_, folderId_, fileId_, file.fileUrl, newValue_);
            file.fileUrl = newValue_;
        } else if(valueId_ == 3) {
            bool newValue_ = abi.decode(newValue, (bool));
            require(file.hidden != newValue_, "Value is already set!" );
            emit FileHiddenChanged(projectId_, folderId_, fileId_, file.hidden, newValue_);
            file.hidden = newValue_;
        } else {
            revert("Value does not exist!");
        }
    }
    /// @notice Swap two files so order will be different on frontend
    /// @dev Project id must exist and folder id must be in range
    /// @param projectId_ Id of the project you want to change
    /// @param folderId_ Id of the folder you want to change
    /// @param firstFileId_ Id of the first file
    /// @param secondFileId_ Id of the second file
    function swapFiles(uint projectId_, uint folderId_, uint firstFileId_, uint secondFileId_) public onlyRole(MODERATOR_ROLE) {
        require(_projectDataInstance.getProjectExists(projectId_), "Project does not exist!");
        require(getFolderExists(projectId_, folderId_), "Folder does not exist!");
        FileData memory firstFile = getFile(projectId_, folderId_, firstFileId_);
        FileData memory secondFile = getFile(projectId_, folderId_, secondFileId_);
        require(firstFile.exists, "FirstFile does not exist!");
        require(secondFile.exists, "SecondFile does not exist!");

        _files[projectId_][folderId_][firstFileId_] = secondFile;
        _files[projectId_][folderId_][firstFileId_].fileId = secondFileId_;
        _files[projectId_][folderId_][secondFileId_] = firstFile;
        _files[projectId_][folderId_][secondFileId_].fileId = firstFileId_;

        emit FilesSwapped(projectId_, folderId_, firstFileId_, secondFileId_);
    }

    // **************************************************
    // *************** DEFAULT_ADMIN REGION *************
    // **************************************************
    /// @notice Initialise the contract after the deployment
    /// @dev This method method is only used in the deployment process
    /// @param defaultAdminAddress_ Address of the default admin
    /// @param moderatorAddress_ Address of the moderator
    function init(address defaultAdminAddress_, address moderatorAddress_, address projectDataAddress_)
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(!_initialised, "Contract is already initialised!");

        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdminAddress_);
        _grantRole(MODERATOR_ROLE, moderatorAddress_);

        _projectDataInstance = ProjectDataInterface(projectDataAddress_);

        _initialised = true;
        _revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    /// @notice Set the address of the project data contract
    /// @dev This method method is only used when migrating onto new contracts
    /// @param projectDataAddress_ Address of the project data contract
    function setProjectDataInstance(address projectDataAddress_) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(address(_projectDataInstance) != projectDataAddress_, "ProjectDataInstance is already set!");
        emit ProjectDataInstanceChanged(address(_projectDataInstance), projectDataAddress_);
        _projectDataInstance = ProjectDataInterface(projectDataAddress_);
    }

    /// @notice Transfer tokens from the contract to desiered address
    /// @dev This method should be used if users accedentaly sends tokens to our contract address
    /// @param tokenAddress_ Token address of the token that we want to salvage
    /// @param to_ Destination where salvaged tokens will be sent
    /// @param amount_ Amount of tokens we want to salvage
    function salvageTokensFromContract(
        address tokenAddress_,
        address to_,
        uint amount_
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        bytes memory callPayload = abi.encodePacked(
            bytes4(keccak256(bytes("transfer(address,uint256)"))),
            abi.encode(to_, amount_)
        );
        (bool success, ) = address(tokenAddress_).call(callPayload);
        require(success, "Call failed!");
        emit TokensSalvaged(tokenAddress_, to_, amount_);
    }

    /// @notice Destroys the contract
    /// @dev This method should NEVER be used if you don't know the implications!!!!!!!!
    function killContract() public onlyRole(DEFAULT_ADMIN_ROLE) {
        emit ContractKilled();
        selfdestruct(payable(msg.sender));
    }

    // **************************************************
    // ************** PUBLIC GETTERS REGION *************
    // **************************************************
    /// @notice Get number of folders in project
    /// @param projectId_ Id of the project
    /// @return Number of folders in project
    function getFolderCount(uint projectId_) public view returns(uint) {
        return _folders[projectId_].length;
    }
    /// @notice Get multiple folder data
    /// @param projectId_ Id of the project
    /// @param startIndex_ Start index of the answer
    /// @param endIndex_ End index of the answer
    /// @return Array of folder data
    function getFolders(uint projectId_, uint startIndex_, uint endIndex_) public view returns (FolderData[] memory) {
        uint endIndex = endIndex_;
        if (getFolderCount(projectId_) < endIndex) {
            endIndex = getFolderCount(projectId_);
        }
        FolderData[] memory folders = new FolderData[](endIndex - startIndex_);
        for (uint i = 0; i < endIndex - startIndex_; i++) {
            folders[i] = getFolder(projectId_, i + startIndex_);
        }
        return folders;
    }
    /// @notice Get single folder data
    /// @param projectId_ Id of the project
    /// @param folderId_ Id of the folder
    /// @return Folder data
    function getFolder(uint projectId_, uint folderId_) public view returns (FolderData memory) {
         return _folders[projectId_][folderId_];
    }
    /// @notice Check if folder actually exits
    /// @param projectId_ Id of the project
    /// @param folderId_ Id of the folder
    /// @return True if folder exists
    function getFolderExists(uint projectId_, uint folderId_) public view returns (bool) {
        return _folders[projectId_][folderId_].exists;
    }

    /// @notice Get number of files in folder
    /// @param projectId_ Id of the project
    /// @param folderId_ Id of the folder
    /// @return Number of files in folder
    function getFileCount(uint projectId_, uint folderId_) public view returns(uint) {
        return _files[projectId_][folderId_].length;
    }
    /// @notice Get multiple file data
    /// @param projectId_ Id of the project
    /// @param folderId_ Id of the folder
    /// @param startIndex_ Start index of the answer
    /// @param endIndex_ End index of the answer
    /// @return Array of file data
    function getFiles(uint projectId_, uint folderId_, uint startIndex_, uint endIndex_) public view returns (FileData[] memory) {
        uint endIndex = endIndex_;
        if (getFileCount(projectId_, folderId_) < endIndex) {
            endIndex = getFileCount(projectId_, folderId_);
        }
        FileData[] memory files = new FileData[](endIndex - startIndex_);
        for (uint i = 0; i < endIndex - startIndex_; i++) {
            files[i] = getFile(projectId_, folderId_, i + startIndex_);
        }
        return files;
    }

    /// @notice Get single file data
    /// @param projectId_ Id of the project
    /// @param folderId_ Id of the folder
    /// @param fileId_ Id of the file
    /// @return File data
    function getFile(uint projectId_, uint folderId_, uint fileId_) public view returns (FileData memory) {
        return _files[projectId_][folderId_][fileId_];
    }

    /// @notice Check if file actually exits
    /// @param projectId_ Id of the project
    /// @param folderId_ Id of the folder
    /// @param fileId_ Id of the file
    /// @return True if file exists
    function getFileExists(uint projectId_, uint folderId_, uint fileId_) public view returns (bool) {
        return _files[projectId_][folderId_][fileId_].exists;
    }

    /// @notice Check if contract is initialized
    /// @dev This is used for deployment and the ability of hardhat-deploy to reuse existing contracts
    function getIsInitialized() public view returns(bool) 
    {
       return _initialised; 
    }

    // **************************************************
    // ****************** EVENTS REGION *****************
    // **************************************************
    event FolderAdded(
        uint indexed projectId,
        uint indexed folderId,
        bytes32 folderReference,
        string name,
        string description,
        bool hidden
    );
    event FolderNameChanged(uint indexed projectId, uint indexed folderId, string oldValue, string newValue);
    event FolderIconChanged(uint indexed projectId, uint indexed folderId, bytes32 oldValue, bytes32 newValue);
    event FolderDescriptionChanged(uint indexed projectId, uint indexed folderId, string oldValue, string newValue);
    event FolderHiddenChanged(uint indexed projectId, uint indexed folderId, bool oldValue, bool newValue);
    event FoldersSwapped(uint indexed projectId, uint indexed firstFolderId, uint indexed secondFolderId);

    event FileAdded(
        uint indexed projectId,
        uint indexed folderId,
        uint indexed fileId,
        string title,
        uint timestamp,
        string fileUrl,
        bool hidden
    );
    event FileTitleChanged(uint indexed projectId, uint indexed folderId, uint indexed fileId, string oldValue, string newValue);
    event FileTimestampChanged(uint indexed projectId, uint indexed folderId, uint indexed fileId, uint oldValue, uint newValue);
    event FileUrlChanged(uint indexed projectId, uint indexed folderId, uint indexed fileId, string oldValue, string newValue);
    event FileHiddenChanged(uint indexed projectId, uint indexed folderId, uint indexed fileId, bool oldValue, bool newValue);
    event FilesSwapped(uint indexed projectId, uint indexed folderId, uint firstFileId, uint secondFileId);

    event ProjectDataInstanceChanged(address oldValue, address newValue);
    event TokensSalvaged(
        address indexed tokenAddress,
        address indexed userAddress,
        uint amount
    );
    event ContractKilled();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

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
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
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

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

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
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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