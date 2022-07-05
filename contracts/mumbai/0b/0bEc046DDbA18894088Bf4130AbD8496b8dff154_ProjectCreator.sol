// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.6;

import {ClonesUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/ClonesUpgradeable.sol";
import {CountersUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import {Versions} from "./Versions.sol";

interface IProject {
    function initialize(
        address _owner,
        string memory _name,
        string memory _symbol,
        string memory _description,
        Versions.Version memory _version,
        uint256 _editionSize,
        uint256 _royaltyBPS
    ) external;
}

contract ProjectCreator {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    /// Important: None of these fields can be changed after calling
    /// urls can be updated and upgraded via the versions interface
    struct ProjectData {
        string name; // Name of the edition contract
        string symbol; // Symbol of the edition contract
        string description; /// Metadata: Description of the edition entry
        Versions.Version version; /// Version media with animation url, animation sha256hash, image url, image sha256hash
        uint256 editionSize; /// Total size of the edition (number of possible editions)
        uint256 royaltyBPS; /// BPS amount of royalty
    }

    struct creatorApproval {
        address id;
        bool approval;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _;
    }

    modifier onlyCreator {
        require(creatorApprovals[address(0)] || creatorApprovals[msg.sender], "Only approved creators can call this function.");
        _;
    }

    address public owner;

    mapping(address => bool) private creatorApprovals;

    /// Counter for current contract id upgraded
    mapping(uint8 => CountersUpgradeable.Counter) private atContracts;

    /// Address for implementation of SingleEditionMintable to clone
    address[] public implementations;

    /// Initializes factory with address of implementations logic
    /// @param _implementations Array of addresse for implementations of SingleEditionMintable like contracts to clone
    constructor(address[] memory _implementations) {
        owner = address(msg.sender);
        for (uint8 i = 0; i < _implementations.length; i++) {
            implementations.push(_implementations[i]);
            atContracts[i] = CountersUpgradeable.Counter(0);
        }

        // set creator approval for owner
        creatorApprovals[address(msg.sender)] = true;
    }

    /// Creates a new edition contract as a factory with a deterministic address
    /// @param projectData the data of the of the project being created
    /// @param implementation Implementation of the project contract
    function createProject(
        ProjectData memory projectData,
        uint8 implementation
    )
        external
        onlyCreator
        returns (uint256)
    {
        require(implementations.length > implementation, "implementation does not exist");

        uint256 newId = atContracts[implementation].current();
        address newContract = ClonesUpgradeable.cloneDeterministic(
            implementations[implementation],
            bytes32(abi.encodePacked(newId))
        );

        IProject(newContract).initialize(
            msg.sender,
            projectData.name,
            projectData.symbol,
            projectData.description,
            projectData.version,
            projectData.editionSize,
            projectData.royaltyBPS
        );

        emit CreatedProject(
            newId,
            msg.sender,
            projectData.editionSize,
            newContract,
            implementation
        );

        // increment for the next contract creation call
        atContracts[implementation].increment();

        return newId;
    }

    /// Get project given the created ID
    /// @param projectId id of the project to get
    /// @return project the contract of the project
    function getProjectAtId(uint256 projectId, uint8 implementation)
        external
        view
        returns (address)
    {
        return
            ClonesUpgradeable.predictDeterministicAddress(
                implementations[implementation],
                bytes32(abi.encodePacked(projectId)),
                address(this)
            );
    }

    function addImplementation(address implementation)
        external
        onlyOwner
        returns (uint256)
    {
        // initilize counter for implementation
        atContracts[uint8(implementations.length)] = CountersUpgradeable.Counter(0);
        // add implementation to clonable implementations
        implementations.push(implementation);

        emit ImplemnetationAdded(
            implementation,
            uint8(implementations.length - 1)
        );

        return implementations.length;
    }

    function setCreatorApprovals(creatorApproval[] memory creators)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < creators.length; i++) {
            creatorApprovals[creators[i].id] = creators[i].approval;
        }

        emit CreatorApprovalsUpdated(creators);
    }

    event CreatorApprovalsUpdated (
        creatorApproval[] creators
    );

    event ImplemnetationAdded(
        address indexed implementationContractAddress,
        uint8 implementation
    );

    /// Emitted when a project is created reserving the corresponding token IDs.
    /// @param projectId ID of newly created edition
    event CreatedProject(
        uint256 indexed projectId,
        address indexed creator,
        uint256 editionSize,
        address project,
        uint8 implementation
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library ClonesUpgradeable {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create(0, ptr, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, implementation))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf3ff00000000000000000000000000000000)
            mstore(add(ptr, 0x38), shl(0x60, deployer))
            mstore(add(ptr, 0x4c), salt)
            mstore(add(ptr, 0x6c), keccak256(ptr, 0x37))
            predicted := keccak256(add(ptr, 0x37), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.6;

import {StringsUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
/*
    please note this is work in progress and not ready for production just yet
*/

/**
 @title A libary for versioning of NFT content and metadata
 @dev Provides versioning for nft content and follows the semantic labeling convention.
 Each version contains an array of content and content hash pairs as well as a version label.
 Versions can be added and urls can be updated along with getters to retrieve specific versions and history.

 Include with `using Versions for Versions.set;`
 @author george baldwin
 */
library Versions {

    struct UrlHashPair {
        string url;
        bytes32 sha256hash;
    }

    struct Version {
        UrlHashPair[] urls;
        uint8[3] label;
    }

    struct Set {
        string[] labels;
        mapping(string => Version) versions;
    }

    /**
     @dev creates a new version from array of url hashe pairs and a semantic label
     @param urls An array of urls with sha-256 hash of the content on that url
     @param label a version label in a semantic style
     */
    function createVersion(
        UrlHashPair[] memory urls,
        uint8[3] memory label
    )
        internal
        pure
        returns (Version memory)
    {
        Version memory version = Version(urls, label);
        return version;
    }

    /**
     @dev adds a version to a given set by pushing the version label to an array
        and mapping the version to a string of that label. Will revert if the label already exists.
     @param set the set to add the version to
     @param version the version that will be stored
     */
    function addVersion(
        Set storage set,
        Version memory version
    ) internal {

        string memory labelKey = uintArray3ToString(version.label);

        require(
            set.versions[labelKey].urls.length == 0,
            "#Versions: A version with that label already exists"
        );

        // add to labels array
        set.labels.push(labelKey);

        // store urls and hashes in mapping
        for (uint256 i = 0; i < version.urls.length; i++){
            set.versions[labelKey].urls.push(version.urls[i]);
        }

        // store label
        set.versions[labelKey].label = version.label;
    }

    /**
     @dev gets a version from a given set. Will revert if the version doesn't exist.
     @param set The set to get the version from
     @param label The label of the requested version
     @return version The version corrosponeding to the label
     */
    function getVersion(
        Set storage set,
        uint8[3] memory label
    )
        internal
        view
        returns (Version memory)
    {
        Version memory version = set.versions[uintArray3ToString(label)];
        require(
            version.urls.length != 0,
            "#Versions: The version does not exist"
        );
        return version;
    }

    /**
     @dev updates a url of a given version in a given set
     @param set The set containing the version of which the url will be updated
     @param label The label of the requested version
     @param index The index of the url
     @param newUrl The new url to be updated to
     */
    function updateVersionURL(
        Set storage set,
        uint8[3] memory label,
        uint256 index,
        string memory newUrl
    ) internal {
        string memory labelKey = uintArray3ToString(label);
        require(
            set.versions[labelKey].urls.length != 0,
            "#Versions: The version does not exist"
        );
        require(
            set.versions[labelKey].urls.length > index,
            "#Versions: The url does not exist on that version"
        );
        set.versions[labelKey].urls[index].url = newUrl;
    }

    /**
     @dev gets all the version labels of a given set
     @param set The set containing the versions
     @return labels an array of labels as strings
    */
    function getAllLabels(
        Set storage set
    )
        internal
        view
        returns (string[] memory)
    {
        return set.labels;
    }

    /**
     @dev gets all the versions of a given set
     @param set The set containing the versions
     @return versions an array of versions
    */
    function getAllVersions(
        Set storage set
    )
        internal
        view
        returns (Version[] memory)
    {
        return getVersionsFromLabels(set, set.labels);
    }

    /**
     @dev gets the versions of a given array of labels as strings, reverts if no labels are given
     @param set The set containing the versions
     @return versions an array of versions
    */
    function getVersionsFromLabels(
        Set storage set,
        string[] memory _labels
    )
        internal
        view
        returns (Version[] memory)
    {
        require(_labels.length != 0, "#Versions: No labels provided");
        Version[] memory versionArray = new Version[](_labels.length);

        for (uint256 i = 0; i < _labels.length; i++) {
                versionArray[i] = set.versions[_labels[i]];
        }

        return versionArray;
    }

    /**
     @dev gets the last added version of a given set, reverts if no versions are in the set
     @param set The set containing the versions
     @return version the last added version
    */
    function getLatestVersion(
        Set storage set
    )
        internal
        view
        returns (Version memory)
    {
        require(
            set.labels.length != 0,
            "#Versions: No versions exist"
        );
        return set.versions[
            set.labels[set.labels.length - 1]
        ];
    }

    /**
     @dev A helper function to convert a three length array of numbers into a semantic style verison label
     @param label the label as a uint8[3] array
     @return label the label as a string
    */
    function uintArray3ToString (uint8[3] memory label)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(
            StringsUpgradeable.toString(label[0]),
            ".",
            StringsUpgradeable.toString(label[1]),
            ".",
            StringsUpgradeable.toString(label[2])
        ));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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