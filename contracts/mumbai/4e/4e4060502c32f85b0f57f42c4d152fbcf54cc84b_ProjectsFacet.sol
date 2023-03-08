// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../libraries/LibAppStorage.sol";
import "../libraries/LibERC2771Context.sol";
import "../libraries/LibProjects.sol";
import "../libraries/LibCards.sol";
import "../libraries/LibStrings.sol";

contract ProjectsFacet is Modifiers {
    LibAppStorage s;

    //  ==========  project logic    ==========
    function createProject(
        string calldata _name,
        string calldata _imageUrl,
        string calldata _description
    ) external onlyTrustedForwarder {
        require(getProjectIdByName(_name) == 0, "ProjectsFacet: That name has been taken");

        address operator = LibERC2771Context.msgSender();
        uint256 projectId = LibProjects.currentProjectId();

        ProjectStruct memory project = ProjectStruct({
            id: projectId,
            name: _name,
            imageUrl: _imageUrl,
            description: _description,
            createdBy: operator
        });

        s.projectMapping[_name] = projectId;
        s.projects[projectId] = project;

        s.userProjects[operator].push(projectId);
        s.userProjectExists[operator][projectId] = ExistStruct({isExisted: 1, index: s.userProjects[operator].length});

        s.projectUsers[projectId].push(operator);
        s.projectUserExists[projectId][operator] = ExistStruct({isExisted: 1, index: s.projectUsers[projectId].length});

        s.operatorAdmins[projectId][operator] = 1;

        LibProjects.incrementProjectId();
    }

    function updateProjectById(
        uint256 _projectId,
        string calldata _name,
        string calldata _imageUrl,
        string calldata _description
    ) external onlyTrustedForwarder {
        require(
            LibProjects.getAdminByProjectId(_projectId, LibERC2771Context.msgSender()) == 1,
            "ProjectsFacet: Not authorized"
        );

        ReturnProjectStruct memory currentProject = LibProjects.getProjectById(_projectId);
        string memory currentName = currentProject.name;

        require(
            LibStrings.equalStrings(currentName, _name) || getProjectIdByName(_name) == 0,
            "ProjectsFacet: That name has been taken"
        );

        if (!LibStrings.equalStrings(currentName, _name)) {
            s.projects[_projectId].name = _name;
            s.projectMapping[_name] = _projectId;
            delete s.projectMapping[currentName];
        }

        if (bytes(_imageUrl).length != 0 && !LibStrings.equalStrings(currentProject.imageUrl, _imageUrl)) {
            s.projects[_projectId].imageUrl = _imageUrl;
        }

        if (!LibStrings.equalStrings(currentProject.description, _description)) {
            s.projects[_projectId].description = _description;
        }
    }

    function getProjectById(uint256 _projectId) external view returns (ReturnProjectStruct memory) {
        return LibProjects.getProjectById(_projectId);
    }

    function getProjectIdByName(string calldata _name) public view returns (uint256) {
        return s.projectMapping[_name];
    }

    //  ==========  projectUsers logic    ==========
    function getProjectUsersById(
        uint256 _projectId
    ) external view returns (ReturnProjectStruct memory project, ProjectUserStruct[] memory projectUsers) {
        return (LibProjects.getProjectById(_projectId), getUsersByProjectId(_projectId));
    }

    function getUsersByProjectId(uint256 _projectId) public view returns (ProjectUserStruct[] memory) {
        address[] memory addressList = s.projectUsers[_projectId];
        uint256 count = addressList.length;
        ProjectUserStruct[] memory projectUsers = new ProjectUserStruct[](count);

        for (uint256 i; i < count; ) {
            address walletAddress = addressList[i];
            ProjectUserStruct memory projectUser = ProjectUserStruct({
                walletAddress: walletAddress,
                isAdmin: LibProjects.getAdminByProjectId(_projectId, walletAddress) == 1
            });
            projectUsers[i] = projectUser;
            unchecked {
                ++i;
            }
        }

        return projectUsers;
    }

    //  ==========  userProjects logic    ==========
    function getUserProjects(address _walletAddress) external view returns (ReturnProjectStruct[] memory) {
        uint256[] memory projectIds = s.userProjects[_walletAddress];
        uint256 count = projectIds.length;
        ReturnProjectStruct[] memory userProjects = new ReturnProjectStruct[](count);

        for (uint256 i; i < count; ) {
            uint256 projectId = projectIds[i];
            ProjectStruct memory project = s.projects[projectId];
            ReturnProjectStruct memory userProject = ReturnProjectStruct({
                id: project.id,
                name: project.name,
                imageUrl: project.imageUrl,
                description: project.description,
                createdBy: project.createdBy,
                canCreateCard: s.projectCardIds[projectId].length < LibCards.cardLimit()
            });
            userProjects[i] = userProject;
            unchecked {
                ++i;
            }
        }

        return userProjects;
    }

    struct UsersProjectsRelations {
        ProjectStruct project;
        address[] users;
    }

    function getUsersProjectsRelations(address _walletAddress) external view returns (UsersProjectsRelations[] memory) {
        uint256[] memory projectIds = s.userProjects[_walletAddress];
        uint256 count = projectIds.length;

        UsersProjectsRelations[] memory usersProjectsRelations = new UsersProjectsRelations[](count);

        for (uint256 i; i < count; ) {
            uint256 projectId = projectIds[i];
            UsersProjectsRelations memory usersProjectsRelation = UsersProjectsRelations({
                project: s.projects[projectId],
                users: s.projectUsers[projectId]
            });
            usersProjectsRelations[i] = usersProjectsRelation;
            unchecked {
                ++i;
            }
        }

        return usersProjectsRelations;
    }

    //  ==========  admin logic    ==========
    function getAdminByProjectId(uint256 _projectId, address _walletAddress) external view returns (bool) {
        return LibProjects.getAdminByProjectId(_projectId, _walletAddress) == 1;
    }

    function updateAdminByProjectId(
        uint256 _projectId,
        address _walletAddress,
        bool _isAdmin
    ) external onlyTrustedForwarder {
        address createdBy = s.projects[_projectId].createdBy;
        require(createdBy == LibERC2771Context.msgSender(), "ProjectsFacet: Not authorized");

        require(createdBy != _walletAddress, "ProjectsFacet: Cannot change the permissions of the creator");

        require(
            s.projectUserExists[_projectId][_walletAddress].isExisted == 1,
            "ProjectsFacet: User does not exist in the project"
        );

        uint256 isAdmin = _isAdmin ? 1 : 2;
        if (s.operatorAdmins[_projectId][_walletAddress] != isAdmin) {
            s.operatorAdmins[_projectId][_walletAddress] = isAdmin;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./LibERC2771Context.sol";

struct LibAppStorage {
    string tokenName;
    string tokenSymbol;
    string tokenUri;
    // Mapping from token id to card info
    mapping(uint256 => MetadataStruct) tokenMetadata;
    // Mapping from token id to user address
    mapping(uint256 => address[]) cardUsers;
    // Mapping from project id to token ids
    mapping(uint256 => uint256[]) projectCardIds;
    // Mapping from wallet address to last created token id
    mapping(address => uint256) userLatestTokenId;
    // Mapping from user address to token ids
    mapping(address => uint256[]) userCardsIds;
    mapping(address => mapping(uint256 => MintDetailStruct)) mintDetails;
    // Mapping from project id to project info
    mapping(uint256 => ProjectStruct) projects;
    // Mapping from project name to project id
    mapping(string => uint256) projectMapping;
    // Mapping from user address to project ids
    mapping(address => uint256[]) userProjects;
    mapping(address => mapping(uint256 => ExistStruct)) userProjectExists;
    // Mapping from project id to user address
    mapping(uint256 => address[]) projectUsers;
    mapping(uint256 => mapping(address => ExistStruct)) projectUserExists;
    // Mapping from project id to user admin
    mapping(uint256 => mapping(address => uint256)) operatorAdmins;
}

struct MetadataStruct {
    uint256 tokenId;
    uint256 projectId;
    uint256 createdAt;
    string name;
    string imageCID;
    string description;
    string role;
    string category;
    string twitter;
    string opensea;
    string discord;
    address createdBy;
}

struct ProjectStruct {
    uint256 id;
    string name;
    string imageUrl;
    string description;
    address createdBy;
}

struct ProjectUserStruct {
    address walletAddress;
    bool isAdmin;
}

struct MintDetailStruct {
    uint256 isMinted;
    uint256 index; // NOTE: Start at one.
    uint256 mintedAt;
    address mintedBy;
}

struct ExistStruct {
    uint256 isExisted;
    uint256 index; // NOTE: Start at one.
}

contract Modifiers {
    modifier onlyTrustedForwarder() {
        require(LibERC2771Context.isTrustedForwarder(msg.sender), "ERC2771Context: caller is not a trusted forwarder");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";

library LibCards {
    using Counters for Counters.Counter;

    bytes32 constant CARDS_STORAGE_POSITION = keccak256("diamond.standard.cards.storage");

    struct CardsStorage {
        Counters.Counter tokenIds;
        Counters.Counter mintedCount;
        uint256 cardLimit;
    }

    function cardsStorage() internal pure returns (CardsStorage storage cs) {
        bytes32 position = CARDS_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    function incrementTokenId() internal {
        CardsStorage storage cs = cardsStorage();
        cs.tokenIds.increment();
    }

    function currentTokenId() internal view returns (uint256) {
        return cardsStorage().tokenIds.current();
    }

    function setCardLimit(uint256 _limit) internal {
        CardsStorage storage cs = cardsStorage();
        cs.cardLimit = _limit;
    }

    function cardLimit() internal view returns (uint256) {
        return cardsStorage().cardLimit;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibContext {
    function msgSender() internal view returns (address) {
        return msg.sender;
    }

    function msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LibContext.sol";

library LibERC2771Context {
    bytes32 constant CONTEXT_STORAGE_POSITION = keccak256("diamond.standard.context.storage");

    struct ContextStorage {
        address trustedForwarder;
    }

    function contextStorage() internal pure returns (ContextStorage storage cs) {
        bytes32 position = CONTEXT_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    function setTrustedForwarder(address _trustedForwarder) internal {
        ContextStorage storage cs = contextStorage();
        cs.trustedForwarder = _trustedForwarder;
    }

    function isTrustedForwarder(address _forwarder) internal view returns (bool) {
        return _forwarder == contextStorage().trustedForwarder;
    }

    function msgSender() internal view returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return LibContext.msgSender();
        }
    }

    function msgData() internal view returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return LibContext.msgData();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./LibAppStorage.sol";
import "./LibCards.sol";
import "./LibERC2771Context.sol";

struct ReturnProjectStruct {
    uint256 id;
    string name;
    string imageUrl;
    string description;
    address createdBy;
    bool canCreateCard;
}

library LibProjects {
    using Counters for Counters.Counter;

    bytes32 constant PROJECTS_STORAGE_POSITION = keccak256("diamond.standard.projects.storage");

    struct ProjectsStorage {
        Counters.Counter projectId;
    }

    function projectsStorage() internal pure returns (ProjectsStorage storage ds) {
        bytes32 position = PROJECTS_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function appStorage() internal pure returns (LibAppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }

    function incrementProjectId() internal {
        ProjectsStorage storage ps = projectsStorage();
        ps.projectId.increment();
    }

    function currentProjectId() internal view returns (uint256) {
        return projectsStorage().projectId.current();
    }

    function getProjectById(uint256 _projectId) internal view returns (ReturnProjectStruct memory) {
        ProjectStruct memory project = appStorage().projects[_projectId];
        return
            ReturnProjectStruct({
                id: project.id,
                name: project.name,
                imageUrl: project.imageUrl,
                description: project.description,
                createdBy: project.createdBy,
                canCreateCard: appStorage().projectCardIds[_projectId].length < LibCards.cardLimit()
            });
    }

    function getAdminByProjectId(uint256 _projectId, address _walletAddress) internal view returns (uint256) {
        return appStorage().operatorAdmins[_projectId][_walletAddress];
    }

    function addUsersToProject(uint256 _projectId, address[] calldata _addressList) internal {
        LibAppStorage storage s = appStorage();

        require(s.operatorAdmins[_projectId][LibERC2771Context.msgSender()] == 1, "LibProjects: Not authorized");

        uint256 count = _addressList.length;
        for (uint256 i; i < count; ) {
            address walletAddress = _addressList[i];

            if (s.projectUserExists[_projectId][walletAddress].isExisted != 1) {
                if (s.projectUserExists[_projectId][walletAddress].index == 0) {
                    s.projectUsers[_projectId].push(walletAddress);
                    s.projectUserExists[_projectId][walletAddress] = ExistStruct({
                        isExisted: 1,
                        index: s.projectUsers[_projectId].length
                    });
                } else {
                    s.projectUsers[_projectId][
                        s.projectUserExists[_projectId][walletAddress].index - 1
                    ] = walletAddress;
                    s.projectUserExists[_projectId][walletAddress].isExisted = 1;
                }

                s.operatorAdmins[_projectId][walletAddress] = 2;
            }

            if (s.userProjectExists[walletAddress][_projectId].isExisted != 1) {
                if (s.userProjectExists[walletAddress][_projectId].index == 0) {
                    s.userProjects[walletAddress].push(_projectId);
                    s.userProjectExists[walletAddress][_projectId] = ExistStruct({
                        isExisted: 1,
                        index: s.userProjects[walletAddress].length
                    });
                } else {
                    s.userProjects[walletAddress][
                        s.userProjectExists[walletAddress][_projectId].index - 1
                    ] = _projectId;
                    s.userProjectExists[walletAddress][_projectId].isExisted = 1;
                }
            }
            unchecked {
                ++i;
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library LibStrings {
    function equalStrings(string memory _a, string memory _b) internal pure returns (bool) {
        return keccak256(bytes(_a)) == keccak256(bytes(_b));
    }

    // NOTE: High gas cost
    function compareToIgnoreCase(string memory _a, string memory _b) internal pure returns (bool) {
        bytes memory _aBytes = bytes(_a);
        bytes memory _bBytes = bytes(_b);

        if (_aBytes.length != _bBytes.length) {
            return false;
        }

        uint256 count = _aBytes.length;
        for (uint i; i < count; ) {
            if (_aBytes[i] != _bBytes[i] && _lower(_aBytes[i]) != _lower(_bBytes[i])) {
                return false;
            }
            unchecked {
                ++i;
            }
        }

        return true;
    }

    function lower(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        uint256 count = _baseBytes.length;
        for (uint i; i < count; ) {
            _baseBytes[i] = _lower(_baseBytes[i]);
            unchecked {
                ++i;
            }
        }
        return string(_baseBytes);
    }

    function _lower(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}