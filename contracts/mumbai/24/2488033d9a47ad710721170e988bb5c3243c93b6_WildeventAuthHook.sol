// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IWildeventAuthHook} from "../../../interfaces/IWildeventAuthHook.sol";
import {IWildfile} from "../../../interfaces/IWildfile.sol";
import {Wildevents} from "../../Wildevents.sol";

contract WildeventAuthHook is IWildeventAuthHook {
    error NoWildfile();
    error UnauthorizedRegisterWildevent();
    error UnauthorizedSetWildeventAttestor();
    error UnauthorizedPostWildevent();

    IWildfile wildfile;
    Wildevents wildevents;

    constructor(address wildfileAddress, address wildeventsAddress) {
        wildfile = IWildfile(wildfileAddress);
        wildevents = Wildevents(wildeventsAddress);
    }

    function onRegisterWildeventType(
        address msgSender,
        string calldata, // wildeventType not currently used
        string calldata // schema not currently used
    ) public view override {
        // only the Wildevents contract owner is allowed to register new Wildevent types
        if (msgSender != wildevents.owner()) {
            revert UnauthorizedRegisterWildevent();
        }
    }

    function onSetWildeventAttestor(
        address msgSender,
        string calldata, // wildeventType not currently used
        uint32 // wildfileId not currently used
    ) public view override {
        // only the Wildevents contract owner is allowed to set Wildevent attestors
        if (msgSender != wildevents.owner()) {
            revert UnauthorizedSetWildeventAttestor();
        }
    }

    function onPostWildevent(
        address msgSender,
        string calldata wildeventType,
        uint32[] calldata, // wildfile Ids not currently used
        bytes calldata // data not currently used
    ) public view override {
        // make sure the sender has a Wildfile
        uint32 attestorWildfileId = uint32(wildfile.getWildfileId(msgSender));
        if (attestorWildfileId < 1) {
            revert NoWildfile();
        }

        // make sure the sender is allowed to create Wildevents of the given type
        if (!wildevents.isWildeventAttestor(wildeventType, attestorWildfileId)) {
            revert UnauthorizedPostWildevent();
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWildeventAuthHook {
    function onRegisterWildeventType(address msgSender, string calldata wildeventType, string calldata schema)
        external;
    function onSetWildeventAttestor(address msgSender, string calldata wildeventType, uint32 wildfileId) external;
    function onPostWildevent(
        address msgSender,
        string calldata wildeventType,
        uint32[] calldata wildfileIds,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWildfile {
    function getWildfileId(address owner) external view returns (uint256);
    function ownerOf(uint256 wildfileId) external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IWildfile} from "../interfaces/IWildfile.sol";
import {IWildevents} from "../interfaces/IWildevents.sol";
import {IWildeventHook} from "../interfaces/IWildeventHook.sol";
import {IWildeventAuthHook} from "../interfaces/IWildeventAuthHook.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";

contract Wildevents is IWildevents, Ownable {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    uint64 public wildeventIdCounter;
    IWildfile public wildfile;
    IWildeventAuthHook public authHook;
    /// @notice list of registered events in the Wildcard Ecosystem
    string[] public wildeventTypes;
    /// @notice mapping from event type to whether it has been registered
    mapping(string => bool) public wildeventTypeToRegistered;
    /// @notice mapping from event type to the Wildfile Id that registered it
    mapping(string => uint256) public wildeventTypeToRegistrantWildfileId;
    /// @notice mapping from event type to the its schema
    mapping(string => string) public wildeventTypeToSchema;
    /// @notice mapping from event type to list of Wildevents
    mapping(string => Wildevent[]) public wildeventTypeToWildevents;
    /// @notice mapping from event type to hook contract
    mapping(string => IWildeventHook) public wildeventTypeToHook;
    /// @notice mapping from Wildfile Id to event type to boolean saying whether they are allowed to attest to events of that type (i.e. create events)
    mapping(uint32 => mapping(string => bool)) public wildfileIdToEventTypeToCanAttest;

    constructor(address wildfileAddress, address authHookAddress) {
        wildfile = IWildfile(wildfileAddress);
        authHook = IWildeventAuthHook(authHookAddress);
    }

    /*//////////////////////////////////////////////////////////////
                            WILDEVENT ACTIONS
    //////////////////////////////////////////////////////////////*/

    function registerWildeventType(string calldata wildeventType, string calldata schema, IWildeventHook hook) public {
        // make sure the event type has not already been registered
        if (wildeventTypeToRegistered[wildeventType]) {
            revert EventAlreadyRegistered();
        }

        // authenticate registering the Wildevent type
        authHook.onRegisterWildeventType(msg.sender, wildeventType, schema);

        // register the Wildevent type
        wildeventTypes.push(wildeventType);
        wildeventTypeToRegistered[wildeventType] = true;
        wildeventTypeToRegistrantWildfileId[wildeventType] = wildfile.getWildfileId(msg.sender);
        wildeventTypeToSchema[wildeventType] = schema;
        wildeventTypeToHook[wildeventType] = hook;
        emit WildeventTypeRegistered(wildeventType, schema);
    }

    function setWildeventAttestor(string calldata wildeventType, uint32 wildfileId, bool canAttest) public {
        // make sure the event type has been registered
        if (!wildeventTypeToRegistered[wildeventType]) {
            revert UnknownEventType();
        }

        // authenticate setting a Wildevent attestor
        authHook.onSetWildeventAttestor(msg.sender, wildeventType, wildfileId);

        wildfileIdToEventTypeToCanAttest[wildfileId][wildeventType] = canAttest;
        emit WildeventAttestorUpdated(wildeventType, wildfileId, canAttest);
    }

    function postWildevent(string calldata wildeventType, uint32[] calldata wildfileIds, bytes calldata data)
        public
        override
        returns (uint64)
    {
        // make sure the event type has been registered
        if (!wildeventTypeToRegistered[wildeventType]) {
            revert UnknownEventType();
        }

        // authenticate posting a Wildevent
        authHook.onPostWildevent(msg.sender, wildeventType, wildfileIds, data);

        // post the wildevent
        ++wildeventIdCounter;
        uint32 attestorWildfileId = uint32(wildfile.getWildfileId(msg.sender));

        Wildevent memory we = Wildevent(wildeventIdCounter, attestorWildfileId, wildeventType, wildfileIds, data);
        wildeventTypeToWildevents[wildeventType].push(we);

        wildeventTypeToHook[wildeventType].onWildevent(wildfileIds, data);

        emit WildeventPosted(wildeventIdCounter, wildeventType, we);
        return wildeventIdCounter;
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function getWildeventTypes() public view override returns (string[] memory) {
        return wildeventTypes;
    }

    function isWildeventTypeRegistered(string calldata wildeventType) public view override returns (bool) {
        return wildeventTypeToRegistered[wildeventType];
    }

    function getWildeventSchema(string calldata wildeventType) public view override returns (string memory) {
        return wildeventTypeToSchema[wildeventType];
    }

    function getNumWildevents(string calldata wildeventType) public view override returns (uint256) {
        return wildeventTypeToWildevents[wildeventType].length;
    }

    function getWildevents(string calldata wildeventType) public view override returns (Wildevent[] memory) {
        return wildeventTypeToWildevents[wildeventType];
    }

    function getWildeventsBatch(string calldata wildeventType, uint256 startIndex, uint256 endIndex)
        public
        view
        override
        returns (Wildevent[] memory)
    {
        if (startIndex > endIndex) {
            revert InvalidIndex();
        }

        Wildevent[] memory allWildevents = wildeventTypeToWildevents[wildeventType];
        if (endIndex >= allWildevents.length) {
            revert IndexOutOfBounds();
        }

        uint256 length = endIndex - startIndex + 1;
        Wildevent[] memory wildeventsBatch = new Wildevent[](length);
        for (uint256 i = 0; i < length; ++i) {
            wildeventsBatch[i] = allWildevents[i + startIndex];
        }

        return wildeventsBatch;
    }

    /**
     * @return whether the given wildfileId is authorized to attest to (post) Wildevents of the given type
     */
    function isWildeventAttestor(string calldata wildeventType, uint32 wildfileId)
        public
        view
        override
        returns (bool)
    {
        return wildfileIdToEventTypeToCanAttest[wildfileId][wildeventType];
    }

    /*//////////////////////////////////////////////////////////////
                            OWNER FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function setWildfile(address wildfileAddress) public onlyOwner {
        wildfile = IWildfile(wildfileAddress);
    }

    function setWildeventAuthHook(address authHookAddress) public onlyOwner {
        authHook = IWildeventAuthHook(authHookAddress);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {IWildeventHook} from "./IWildeventHook.sol";

interface IWildevents {
    struct Wildevent {
        uint64 wildeventId;
        uint32 attestorWildfileId;
        string wildeventType;
        uint32[] wildfileIds;
        bytes data;
    }

    event WildeventTypeRegistered(string indexed wildeventType, string schema);
    event WildeventPosted(uint64 indexed wildeventId, string indexed wildeventType, Wildevent indexed we);
    event WildeventAttestorUpdated(string indexed wildeventType, uint32 wildfileId, bool canAttest);

    error EventAlreadyRegistered();
    error UnknownEventType();
    error InvalidIndex();
    error IndexOutOfBounds();

    // actions
    function registerWildeventType(string calldata wildeventType, string calldata schema, IWildeventHook hook)
        external;
    function setWildeventAttestor(string calldata wildeventType, uint32 wildfileId, bool canAttest) external;
    function postWildevent(string calldata wildeventType, uint32[] calldata wildfileIds, bytes calldata data)
        external
        returns (uint64);

    // view functions
    function isWildeventAttestor(string calldata wildeventType, uint32 wildfileId) external view returns (bool);
    function getWildeventTypes() external view returns (string[] memory);
    function isWildeventTypeRegistered(string calldata wildeventType) external view returns (bool);
    function getWildeventSchema(string calldata wildeventType) external view returns (string memory);
    function getNumWildevents(string calldata wildeventType) external view returns (uint256);
    function getWildevents(string calldata wildeventType) external view returns (Wildevent[] memory);
    function getWildeventsBatch(string calldata wildeventType, uint256 startIndex, uint256 endIndex)
        external
        view
        returns (Wildevent[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

interface IWildeventHook {
    error OnlyWildeventsContract();

    function onlyWildeventsContract(address msgSender) external view;
    /// @dev each hook should check that the msgSender is the Wildevents contract in onWildevent, and revert with OnlyWildeventsContract if not
    function onWildevent(uint32[] calldata wildfileIds, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
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