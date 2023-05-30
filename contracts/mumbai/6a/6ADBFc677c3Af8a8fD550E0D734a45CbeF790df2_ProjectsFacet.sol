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
pragma solidity ^0.8.19;

import "../libraries/LibAppStorage.sol";
import "../libraries/LibERC2771Context.sol";
import "../libraries/LibProjects.sol";
import "../libraries/LibCards.sol";
import "../libraries/LibStrings.sol";

contract ProjectsFacet is Modifiers {
    AppStorage s;

    struct ProjectUserStruct {
        address walletAddress;
        bool isAdmin;
    }

    struct UsersProjectsRelations {
        ProjectStruct project;
        address[] users;
    }

    //  ==========  project logic    ==========
    function createProject(
        string calldata _name,
        string calldata _imageCID,
        string calldata _description
    ) external onlyTrustedForwarder {
        require(getProjectIdByName(_name) == 0, "ProjectsFacet: That name has been taken");

        address msgSender = LibERC2771Context.msgSender();
        ++s.userExecutionCount[msgSender]["createProject"];

        uint256 projectId = LibProjects.currentProjectId();
        LibProjects.incrementProjectId();

        ProjectStruct memory project = ProjectStruct({
            id: projectId,
            name: _name,
            imageCID: _imageCID,
            description: _description,
            createdBy: msgSender
        });

        s.projectMapping[_name] = projectId;
        s.projects[projectId] = project;

        s.userProjects[msgSender].push(projectId);
        s.userProjectExists[msgSender][projectId] = ExistStruct({
            isExisted: 1,
            index: s.userProjects[msgSender].length
        });

        s.projectUsers[projectId].push(msgSender);
        s.projectUserExists[projectId][msgSender] = ExistStruct({
            isExisted: 1,
            index: s.projectUsers[projectId].length
        });

        s.operatorAdmins[projectId][msgSender] = 1;
    }

    function updateProjectById(
        uint256 _projectId,
        string calldata _name,
        string calldata _imageCID,
        string calldata _description
    ) external onlyTrustedForwarder {
        address msgSender = LibERC2771Context.msgSender();
        require(LibProjects.getAdminByProjectId(_projectId, msgSender) == 1, "ProjectsFacet: Not authorized");

        ReturnProjectStruct memory currentProject = LibProjects.getProjectById(_projectId);
        string memory currentName = currentProject.name;

        require(
            LibStrings.equalStrings(currentName, _name) || getProjectIdByName(_name) == 0,
            "ProjectsFacet: That name has been taken"
        );

        ++s.userExecutionCount[msgSender]["updateProject"];

        if (!LibStrings.equalStrings(currentName, _name)) {
            s.projects[_projectId].name = _name;
            s.projectMapping[_name] = _projectId;
            delete s.projectMapping[currentName];
        }

        if (bytes(_imageCID).length != 0 && !LibStrings.equalStrings(currentProject.imageCID, _imageCID)) {
            s.projects[_projectId].imageCID = _imageCID;
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

    function getProjectsCount() external view returns (uint256) {
        return LibProjects.currentProjectId() - 1;
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
                imageCID: project.imageCID,
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
        address msgSender = LibERC2771Context.msgSender();
        require(createdBy == msgSender, "ProjectsFacet: Not authorized");

        require(createdBy != _walletAddress, "ProjectsFacet: Cannot change the permissions of the creator");

        require(
            s.projectUserExists[_projectId][_walletAddress].isExisted == 1,
            "ProjectsFacet: User does not exist in the project"
        );

        uint256 isAdmin = _isAdmin ? 1 : 2;
        require(s.operatorAdmins[_projectId][_walletAddress] != isAdmin, "ProjectsFacet: Already set");

        ++s.userExecutionCount[msgSender]["updateAdmin"];
        s.operatorAdmins[_projectId][_walletAddress] = isAdmin;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./LibERC2771Context.sol";

struct AppStorage {
    string cardName;
    string cardSymbol;
    string cardImageCID;
    string cardAnimationCID;
    // Mapping from card id to card info
    mapping(uint256 => MetadataStruct) cardMetadata;
    // Mapping from card id to user address
    mapping(uint256 => address[]) cardUsers;
    // Mapping from project id to card ids
    mapping(uint256 => uint256[]) projectCardIds;
    // Mapping from wallet address to last created card id
    mapping(address => uint256) userLatestCardId;
    // Mapping from user address to card ids
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
    // Mapping from user address to method execution count
    mapping(address => mapping(string => uint256)) userExecutionCount;
}

struct MetadataStruct {
    uint256 cardId;
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
    string imageCID;
    string description;
    address createdBy;
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

library LibAppStorage {
    function appStorage() internal pure returns (AppStorage storage s) {
        assembly {
            s.slot := 0
        }
    }

    function getUserExecutionCount(address _user, string calldata _functionName) internal view returns (uint256) {
        return appStorage().userExecutionCount[_user][_functionName];
    }
}

contract Modifiers {
    modifier onlyTrustedForwarder() {
        require(LibERC2771Context.isTrustedForwarder(msg.sender), "ERC2771Context: caller is not a trusted forwarder");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Counters.sol";

library LibCards {
    using Counters for Counters.Counter;

    bytes32 constant CARDS_STORAGE_POSITION = keccak256("diamond.standard.cards.storage");

    struct CardsStorage {
        Counters.Counter cardIds;
        Counters.Counter mintedCount;
        uint256 cardLimit;
    }

    function cardsStorage() internal pure returns (CardsStorage storage cs) {
        bytes32 position = CARDS_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    function incrementCardId() internal {
        CardsStorage storage cs = cardsStorage();
        cs.cardIds.increment();
    }

    function currentCardId() internal view returns (uint256) {
        return cardsStorage().cardIds.current();
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
pragma solidity ^0.8.19;

library LibContext {
    function msgSender() internal view returns (address) {
        return msg.sender;
    }

    function msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./LibContext.sol";

library LibERC2771Context {
    bytes32 constant CONTEXT_STORAGE_POSITION = keccak256("diamond.standard.context.storage");

    struct ContextStorage {
        mapping(address => uint256) trustedForwarders;
    }

    function contextStorage() internal pure returns (ContextStorage storage cs) {
        bytes32 position = CONTEXT_STORAGE_POSITION;
        assembly {
            cs.slot := position
        }
    }

    function updateTrustedForwarder(address _trustedForwarder, bool _isTrusted) internal {
        ContextStorage storage cs = contextStorage();
        cs.trustedForwarders[_trustedForwarder] = _isTrusted ? 1 : 2;
    }

    function isTrustedForwarder(address _forwarder) internal view returns (bool) {
        return contextStorage().trustedForwarders[_forwarder] == 1;
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
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/Counters.sol";
import "./LibAppStorage.sol";
import "./LibCards.sol";
import "./LibERC2771Context.sol";

struct ReturnProjectStruct {
    uint256 id;
    string name;
    string imageCID;
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

    function projectsStorage() internal pure returns (ProjectsStorage storage ps) {
        bytes32 position = PROJECTS_STORAGE_POSITION;
        assembly {
            ps.slot := position
        }
    }

    function appStorage() internal pure returns (AppStorage storage s) {
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
                imageCID: project.imageCID,
                description: project.description,
                createdBy: project.createdBy,
                canCreateCard: appStorage().projectCardIds[_projectId].length < LibCards.cardLimit()
            });
    }

    function getAdminByProjectId(uint256 _projectId, address _walletAddress) internal view returns (uint256) {
        return appStorage().operatorAdmins[_projectId][_walletAddress];
    }

    function addUsersToProject(uint256 _projectId, address[] calldata _addressList) internal {
        AppStorage storage s = appStorage();

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
pragma solidity ^0.8.19;

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