// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable is IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

import "../Company/facets/CompanyInfoFacet/interfaces/ISeekrCompanyInfoFacet.sol";
import "../Company/facets/ProjectFactoryFacet/interfaces/ISeekrProjectFactoryFacet.sol";
import "../SeekrHub/facets/CompanyFactoryFacet/interfaces/ISeekrCompanyFactoryFacet.sol";
import "../Project/facets/ProjectInfoFacet/interfaces/ISeekrProjectInfoFacet.sol";
import "../Project/facets/JobSoulboundTokenFacet/interfaces/ISeekrJobSoulboundTokenFacet.sol";
import "../Globals/interfaces/ISeekrGlobals.sol";
import "../Authorizer/interfaces/ISeekrAuthorizer.sol";
import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";
import {NotPermittedError} from "../Libraries/SeekrErrors.sol";

/// @title SeekrAdminPortalV1
/// @author Cory Cherven (@Animalmix55)
/// @notice This "portal" is designed to allow for admins to easily interact with Seekr's
///         system of Diamonds with ease through blockchain explorers. The portal must be
///         set as a super admin in the Seekr authorizer. It only allows super admins to interact
///         with it.
contract SeekrAdminPortalV1 {
    ISeekrGlobals private _globals;

    constructor(address globals) {
        _globals = ISeekrGlobals(globals);
    }

    // --------------------------- Company Helpers --------------------------------

    /// Predicts the company address using the provided salt
    /// @param salt the salt used to generate the company contract
    function getCompanyAddress(
        string calldata salt
    ) public view returns (address) {
        return
            ISeekrCompanyFactoryFacet(_globals.getSeekrHub())
                .predictCompanyAddress(keccak256(abi.encodePacked(salt)));
    }

    /// Creates a company using the provided information
    /// @param info [name, description, logoUrl] of the company
    /// @param salt a random string which helps the blockchain deterministically generate a contract
    function createCompany(
        string[] calldata info,
        string calldata salt
    ) public superAdminOnly(msg.sender) {
        ISeekrCompanyFactoryFacet(_globals.getSeekrHub()).createCompanyAdmin(
            info,
            keccak256(abi.encodePacked(salt))
        );
    }

    /// Updates the information stored for a company
    /// @param companyAddress the company address
    /// @param info [name, description, logoUrl] of the company
    function updateCompany(
        address companyAddress,
        string[] calldata info
    ) public superAdminOnly(msg.sender) {
        ISeekrCompanyInfoFacet(companyAddress).setCompanyDataAdmin(info);
    }

    // --------------------------- Project Helpers --------------------------------

    /// Predicts the project address using the provided salt
    /// @param companyAddress the address of the company to which the project will belong
    /// @param salt the salt used to generate the project contract
    function getProjectAddress(
        address companyAddress,
        string calldata salt
    ) public view returns (address) {
        return
            ISeekrProjectFactoryFacet(companyAddress).predictProjectAddress(
                keccak256(abi.encodePacked(salt))
            );
    }

    /// Creates a project under a given company with the given description
    /// @param companyAddress the address of the company to which the project will belong
    /// @param info [name, description, logoUrl] of the project
    /// @param salt the salt used to generate the project contract
    function createProject(
        address companyAddress,
        string[] calldata info,
        string calldata salt
    ) public superAdminOnly(msg.sender) {
        ISeekrProjectFactoryFacet(companyAddress).createProjectAdmin(
            info,
            keccak256(abi.encodePacked(salt))
        );
    }

    /// Updates the given project's information
    /// @param projectAddress the project address to update
    /// @param info [name, description, logoUrl] of the project
    function updateProject(
        address projectAddress,
        string[] calldata info
    ) public superAdminOnly(msg.sender) {
        ISeekrProjectInfoFacet(projectAddress).setProjectDataAdmin(info);
    }

    // --------------------------- Job Helpers ------------------------------------

    /// Issues a job SBT for a given role
    /// @param projectAddress the project under which to issue the SBT
    /// @param to the user to issue the SBT to
    /// @param info [name, description] of the job
    /// @param attributes JSON-formatted ERC721Metadata attributes for a token presented as a string array
    /// @param skills an array of the textual skills associated with the job
    function issueJobToken(
        address projectAddress,
        address to,
        string[] calldata info,
        string[] calldata attributes,
        string[] calldata skills
    ) public superAdminOnly(msg.sender) {
        ISeekrJobSoulboundTokenFacet(projectAddress).issueJobTokenAdmin(
            to,
            info,
            attributes,
            skills
        );
    }

    /// Finalizes the information associated with a job SBT
    /// @param projectAddress the project under which the token lives
    /// @param tokenId the token id
    /// @param additionalSkills any additional skills to append to the token before it becomes immutable
    function finalizeJobToken(
        address projectAddress,
        uint256 tokenId,
        string[] calldata additionalSkills
    ) public superAdminOnly(msg.sender) {
        ISeekrJobSoulboundTokenFacet(projectAddress).finalizeJobTokenAdmin(
            tokenId,
            additionalSkills
        );
    }

    // --------------------------- Disposal ---------------------------------------

    /// Renounces the role and kills the contract.
    function selfDestruct() public superAdminOnly(msg.sender) {
        IAccessControlUpgradeable(_globals.getAuthorizer()).renounceRole(
            _globals.getAuthorizer().SUPER_ADMIN_ROLE(),
            address(this)
        );

        selfdestruct(payable(msg.sender));
    }

    // --------------------------- Modifiers --------------------------------------

    /// Asserts that the provided user is super admin
    modifier superAdminOnly(address user) {
        ISeekrAuthorizer authorizer = _globals.getAuthorizer();

        if (!authorizer.hasRole(authorizer.SUPER_ADMIN_ROLE(), user))
            revert NotPermittedError();

        _;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/IAccessControlEnumerableUpgradeable.sol";

/// @title ISeekrAuthorizer
/// @author Cory Cherven (@Animalmix55)
/// @notice This is the interface representing the centralized authorization contract for all things Seekr.
interface ISeekrAuthorizer is IAccessControlEnumerableUpgradeable {
    /// The role granted to a super admin who is expected to have the highest permissions across the system.
    /// This should be furnished to a multisig wallet.
    function SUPER_ADMIN_ROLE() external returns (bytes32);
    /// The role assigned to top-level support providers, second to super admin.
    function SUPPORT_LEVEL_1_ROLE() external returns (bytes32);
    /// The role assigned to second-level support providers, beneath level 1.
    function SUPPORT_LEVEL_2_ROLE() external returns (bytes32);
    /// The role assigned to third-level support providers, beneath level 2.
    function SUPPORT_LEVEL_3_ROLE() external returns (bytes32);
    /// Indicates if a given address is a valid signer for the Seekr backend
    function isValidSigner(address signer) external returns (bool);
    /// Sets a signer as valid, provided the sender has a right to.
    function setValidSigner(address signer, bool isValid) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

/// @title ISeekrCompanyInfoFacet
/// @author Cory Cherven (@Animalmix55)
/// @notice The interface representing company information
interface ISeekrCompanyInfoFacet {
    /// Updates the information stored for a company using a signature generated by Seekr
    /// @param info [companyName string, companyDescription string, logoUrl string]
    /// @param deadline the deadline after which the signature expires
    /// @param v the v component of the signature
    /// @param r the r component of the signature
    /// @param s the s component of the signature
    function setCompanyData(string[] calldata info, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    /// Updates the information stored for a company using an authorized account
    /// @param info [companyName string, companyDescription string, logoUrl string]
    function setCompanyDataAdmin(string[] calldata info) external;

    /// Initializes company data, can only run once, should be called when the company diamond is created
    /// @param info [companyName string, companyDescription string, logoUrl string]
    function initializeCompanyData(string[] calldata info) external;

    function getCompanyUpdateNonce() external view returns (uint256);
    function getCompanyName() external view returns (string memory);
    function getCompanyDescription() external view returns (string memory);
    function getCompanyLogo() external view returns (string memory);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

/// @title ISeekrProjectFactoryFacet
/// @author Cory Cherven (@Animalmix55)
/// @notice The interface representing the Seekr project factory for a given company
interface ISeekrProjectFactoryFacet {
    /// Create a project under a company using a signature generated by Seekr
    /// @param info [projectName string, projectDescription string, projectLogoUrl string]
    /// @param deadline the deadline after which the signature expires
    /// @param v the v component of the signature
    /// @param r the r component of the signature
    /// @param s the s component of the signature
    function createProject(
        string[] calldata info,
        bytes32 salt,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (address);

    /// Create a project under a company as an admin
    /// @param info [projectName string, projectDescription string, projectLogoUrl string]
    function createProjectAdmin(string[] calldata info, bytes32 salt) external;

    /// Checks to see if this company created the given project
    /// @param projectAddress the address of the created project
    function isProjectCreator(
        address projectAddress
    ) external view returns (bool);

    /// Enumerates the project addresses created by the company
    function getProjects() external view returns (address[] memory);

    /// Predicts the project address that will be generated by createProject
    /// @param salt the salt to use to generate the address
    function predictProjectAddress(
        bytes32 salt
    ) external view returns (address);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

import "diamond-2-hardhat/contracts/interfaces/IDiamondCut.sol";
import "diamond-2-hardhat/contracts/interfaces/IDiamondLoupe.sol";

interface ISeekrProxyDiamondConfiguration is IDiamondCut, IDiamondLoupe {
    /// Allows consumers to implement ERC-165
    /// @param interfaceId the interface to check
    function consumerSupportsInterface(
        bytes4 interfaceId
    ) external view returns (bool);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

import "../../Authorizer/interfaces/ISeekrAuthorizer.sol";
import "../../Diamond/interfaces/ISeekrProxyDiamondConfiguration.sol";

interface ISeekrGlobals {
    function getTokenSymbol() external view returns (string memory);
    function setTokenSymbol(string calldata symbol) external;

    function getAuthorizer() external view returns (ISeekrAuthorizer);
    function setAuthorizer(address authorizerAddress) external;

    function getCompanyDiamondConfiguration() external view returns (ISeekrProxyDiamondConfiguration);
    function setCompanyDiamondConfiguration(address config) external;

    function getCompanyImplementation() external view returns (address);
    function setCompanyImplementation(address projectImplementationAddress) external;

    function getProjectDiamondConfiguration() external view returns (ISeekrProxyDiamondConfiguration);
    function setProjectDiamondConfiguration(address config) external;

    function getProjectImplementation() external view returns (address);
    function setProjectImplementation(address projectImplementationAddress) external;

    function getSeekrHub() external view returns (address);
    function setSeekrHub(address seekrHubAddress) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

// An error used to indicate that a method is not implemented in the Seekr system.
error NotImplementedError();

error NotPermittedError();

error BadRequestError();

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

interface ISeekrJobSoulboundTokenFacet is IERC721MetadataUpgradeable {
    /// Issues an SBT for a job accepted
    /// @param to the recipient of the token
    /// @param info the data associated with the token: [title, description]
    /// @param attributes JSON objects representing standard ERC721 attributes
    /// @param skills brief textual descriptions of skills
    /// @param deadline the time at which the signature from Seekr expires
    /// @param v the v component of the signature
    /// @param r the r component of the signature
    /// @param s the s component of the signature
    function issueJobToken(
        address to,
        string[] calldata info,
        string[] calldata attributes,
        string[] calldata skills,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// Issues an SBT for a job accepted
    /// @param to the recipient of the token
    /// @param info the data associated with the token: [title, description]
    /// @param attributes JSON objects representing standard ERC721 attributes
    /// @param skills brief textual descriptions of skills
    /// @dev super admin only
    function issueJobTokenAdmin(
        address to,
        string[] calldata info,
        string[] calldata attributes,
        string[] calldata skills
    ) external;

    /// Finalizes a job token, rendering it immutable
    /// @param tokenId the token id
    /// @param additionalSkills additional skills to append to the original description for finalization
    /// @param deadline the time at which the signature from Seekr expires
    /// @param v the v component of the signature
    /// @param r the r component of the signature
    /// @param s the s component of the signature
    function finalizeJobToken(
        uint256 tokenId,
        string[] calldata additionalSkills,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// Finalizes a job token, rendering it immutable
    /// @param tokenId the token id
    /// @param additionalSkills additional skills to append to the original description for finalization
    /// @dev admin/csr only
    function finalizeJobTokenAdmin(
        uint256 tokenId,
        string[] calldata additionalSkills
    ) external;

    function totalSupply() external view returns (uint256);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

/// @title ISeekrProjectInfoFacet
/// @author Cory Cherven (@Animalmix55)
/// @notice The interface representing project information
interface ISeekrProjectInfoFacet {
    /// Updates the information stored for a project using a signature generated by Seekr
    /// @param info [projectName string, projectDescription string, logoUrl string]
    /// @param deadline the deadline after which the signature expires
    /// @param v the v component of the signature
    /// @param r the r component of the signature
    /// @param s the s component of the signature
    function setProjectData(
        string[] calldata info,
        uint deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /// Updates the information stored for a project using an authorized account
    /// @param info [projectName string, projectDescription string, logoUrl string]
    function setProjectDataAdmin(string[] calldata info) external;

    /// Initializes project data, can only run once, should be called when the project diamond is created
    /// @param info [projectName string, projectDescription string, logoUrl string]
    /// @param parentCompany the company address that created the project
    function initializeProjectData(
        address parentCompany,
        string[] calldata info
    ) external;

    function getParentCompany() external view returns (address);

    function getProjectName() external view returns (string memory);

    function getProjectDescription() external view returns (string memory);

    function getProjectLogo() external view returns (string memory);

    function getProjectUpdateNonce() external view returns (uint256);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.18;

/// @title ISeekrCompanyFactoryFacet
/// @author Cory Cherven (@Animalmix55)
/// @notice The interface representing the Seekr company factory for a given company
interface ISeekrCompanyFactoryFacet {
    /// Create a company using a signature generated by Seekr
    /// @param info [companyName string, companyDescription string, companyLogoUrl string]
    /// @param deadline the deadline after which the signature expires
    /// @param v the v component of the signature
    /// @param r the r component of the signature
    /// @param s the s component of the signature
    function createCompany(string[] calldata info, bytes32 salt, uint deadline, uint8 v, bytes32 r, bytes32 s) external returns (address);

    /// Create a company as an admin
    /// @param info [companyName string, companyDescription string, companyLogoUrl string]
    function createCompanyAdmin(string[] calldata info, bytes32 salt) external returns (address);

    /// Checks to see if the factory created the given company
    /// @param companyAddress the address of the created company
    function isCompanyCreator(address companyAddress) external view returns (bool);

    /// Enumerates the company addresses created by the company
    function getCompanies() external view returns (address[] memory);

    /// Predicts the deterministic address of the company made with the provided salt
    /// @param salt the salt used to generate the company
    function predictCompanyAddress(bytes32 salt) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

// A loupe is a small magnifying glass used to look at diamonds.
// These functions look at diamonds
interface IDiamondLoupe {
    /// These functions are expected to be called frequently
    /// by tools.

    struct Facet {
        address facetAddress;
        bytes4[] functionSelectors;
    }

    /// @notice Gets all facet addresses and their four byte function selectors.
    /// @return facets_ Facet
    function facets() external view returns (Facet[] memory facets_);

    /// @notice Gets all the function selectors supported by a specific facet.
    /// @param _facet The facet address.
    /// @return facetFunctionSelectors_
    function facetFunctionSelectors(address _facet) external view returns (bytes4[] memory facetFunctionSelectors_);

    /// @notice Get all the facet addresses used by a diamond.
    /// @return facetAddresses_
    function facetAddresses() external view returns (address[] memory facetAddresses_);

    /// @notice Gets the facet that supports the given selector.
    /// @dev If facet is not found return address(0).
    /// @param _functionSelector The function selector.
    /// @return facetAddress_ The facet address.
    function facetAddress(bytes4 _functionSelector) external view returns (address facetAddress_);
}