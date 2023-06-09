//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../../interfaces/INFTMultiPrivilege.sol";
import "../../Eip712/Eip712CheckerInternal.sol";
import "../../libraries/NodesStorage.sol";
import "../../libraries/nodes/ManufacturerStorage.sol";
import "../../libraries/nodes/VehicleStorage.sol";
import "../../libraries/nodes/AftermarketDeviceStorage.sol";
import "../../libraries/MapperStorage.sol";
import "../AdLicenseValidator/AdLicenseValidatorInternal.sol";

import "../../shared/Roles.sol" as Roles;
import "../../shared/Types.sol" as Types;
import "../../shared/Errors.sol" as Errors;

import "@solidstate/contracts/access/access_control/AccessControlInternal.sol";

error RegistryNotApproved();
error DeviceAlreadyRegistered(address addr);
error DeviceAlreadyClaimed(uint256 id);
error InvalidAdSignature();
error AdNotClaimed(uint256 id);
error AdPaired(uint256 id);
error VehicleNotPaired(uint256 id);
error AdNotPaired(uint256 id);
error OwnersDoesNotMatch();

/**
 * @title AftermarketDevice
 * @notice Contract that represents the Aftermarket Device node
 * @dev It uses the Mapper contract to link Aftermarket Devices to Vehicles
 */
contract AftermarketDevice is
    AccessControlInternal,
    AdLicenseValidatorInternal
{
    bytes32 private constant CLAIM_TYPEHASH =
        keccak256(
            "ClaimAftermarketDeviceSign(uint256 aftermarketDeviceNode,address owner)"
        );
    bytes32 private constant PAIR_TYPEHASH =
        keccak256(
            "PairAftermarketDeviceSign(uint256 aftermarketDeviceNode,uint256 vehicleNode)"
        );

    bytes32 private constant UNPAIR_TYPEHASH =
        keccak256(
            "UnPairAftermarketDeviceSign(uint256 aftermarketDeviceNode,uint256 vehicleNode)"
        );
    uint256 private constant MANUFACTURER_MINTER_PRIVILEGE = 1;
    uint256 private constant MANUFACTURER_CLAIMER_PRIVILEGE = 2;

    event AftermarketDeviceIdProxySet(address indexed proxy);
    event AftermarketDeviceAttributeAdded(string attribute);
    event AftermarketDeviceAttributeSet(
        uint256 tokenId,
        string attribute,
        string info
    );
    event AftermarketDeviceNodeMinted(
        uint256 tokenId,
        address indexed aftermarketDeviceAddress,
        address indexed owner
    );
    event AftermarketDeviceClaimed(
        uint256 aftermarketDeviceNode,
        address indexed owner
    );

    event AftermarketDevicePaired(
        uint256 aftermarketDeviceNode,
        uint256 vehicleNode,
        address indexed owner
    );

    event AftermarketDeviceUnpaired(
        uint256 aftermarketDeviceNode,
        uint256 vehicleNode,
        address indexed owner
    );

    // ***** Admin management ***** //

    /**
     * @notice Sets the NFT proxy associated with the Aftermarket Device node
     * @dev Only an admin can set the address
     * @param addr The address of the proxy
     */
    function setAftermarketDeviceIdProxyAddress(address addr)
        external
        onlyRole(Roles.DEFAULT_ADMIN_ROLE)
    {
        if (addr == address(0)) revert Errors.ZeroAddress();
        AftermarketDeviceStorage.getStorage().idProxyAddress = addr;

        emit AftermarketDeviceIdProxySet(addr);
    }

    /**
     * @notice Adds an attribute to the whielist
     * @dev Only an admin can add a new attribute
     * @param attribute The attribute to be added
     */
    function addAftermarketDeviceAttribute(string calldata attribute)
        external
        onlyRole(Roles.DEFAULT_ADMIN_ROLE)
    {
        if (
            !AttributeSet.add(
                AftermarketDeviceStorage.getStorage().whitelistedAttributes,
                attribute
            )
        ) revert Errors.AttributeExists(attribute);

        emit AftermarketDeviceAttributeAdded(attribute);
    }

    // ***** Interaction with nodes *****//

    /**
     * @notice Mints aftermarket devices in batch
     * Caller must be the manufacturer node owner or an authorized address
     * The manufacturer node owner must grant the minter privilege to the authorized address
     * @param manufacturerNode Parent manufacturer node id
     * @param adInfos List of attribute-info pairs and addresses associated with the AD to be added
     *  addr -> AD address
     *  attrInfoPairs[] / attribute
     *                  \ info
     */
    function mintAftermarketDeviceByManufacturerBatch(
        uint256 manufacturerNode,
        Types.AftermarketDeviceInfos[] calldata adInfos
    ) external {
        NodesStorage.Storage storage ns = NodesStorage.getStorage();
        AftermarketDeviceStorage.Storage storage ads = AftermarketDeviceStorage
            .getStorage();
        uint256 devicesAmount = adInfos.length;
        address adIdProxyAddress = ads.idProxyAddress;
        INFTMultiPrivilege manufacturerIdProxy = INFTMultiPrivilege(
            ManufacturerStorage.getStorage().idProxyAddress
        );

        if (!INFT(adIdProxyAddress).isApprovedForAll(msg.sender, address(this)))
            revert RegistryNotApproved();
        if (!manufacturerIdProxy.exists(manufacturerNode))
            revert Errors.InvalidParentNode(manufacturerNode);
        if (
            !manufacturerIdProxy.hasPrivilege(
                manufacturerNode,
                MANUFACTURER_MINTER_PRIVILEGE,
                msg.sender
            )
        ) revert Errors.Unauthorized(msg.sender);

        uint256 newTokenId;
        address deviceAddress;
        address manufacturerNodeOwner = manufacturerIdProxy.ownerOf(
            manufacturerNode
        );

        for (uint256 i = 0; i < devicesAmount; i++) {
            newTokenId = INFT(adIdProxyAddress).safeMint(manufacturerNodeOwner);

            ns
            .nodes[adIdProxyAddress][newTokenId].parentNode = manufacturerNode;

            deviceAddress = adInfos[i].addr;
            if (ads.deviceAddressToNodeId[deviceAddress] != 0)
                revert DeviceAlreadyRegistered(deviceAddress);

            ads.deviceAddressToNodeId[deviceAddress] = newTokenId;
            ads.nodeIdToDeviceAddress[newTokenId] = deviceAddress;

            _setInfos(newTokenId, adInfos[i].attrInfoPairs);

            emit AftermarketDeviceNodeMinted(
                newTokenId,
                deviceAddress,
                manufacturerNodeOwner
            );
        }

        // Validate license and transfer funds to foundation
        _validateMintRequest(manufacturerNodeOwner, msg.sender, devicesAmount);
    }

    /**
     * @notice Claims the ownership of a list of aftermarket devices to a list of owners
     * Caller must have the admin role or the manufacturer node owner must grant the claimer privilege to the caller
     * @dev This contract must be approved to spend the tokens in advance
     * @param adOwnerPair List of pairs AD-owner
     *  aftermarketDeviceNodeId -> Token ID of the AD
     *  owner -> Address to be the new AD owner
     */
    function claimAftermarketDeviceBatch(
        uint256 manufacturerNode,
        Types.AftermarketDeviceOwnerPair[] calldata adOwnerPair
    ) external {
        INFTMultiPrivilege manufacturerIdProxy = INFTMultiPrivilege(
            ManufacturerStorage.getStorage().idProxyAddress
        );

        if (
            !_hasRole(Roles.DEFAULT_ADMIN_ROLE, msg.sender) &&
            !manufacturerIdProxy.hasPrivilege(
                manufacturerNode,
                MANUFACTURER_CLAIMER_PRIVILEGE,
                msg.sender
            )
        ) revert Errors.Unauthorized(msg.sender);

        AftermarketDeviceStorage.Storage storage ads = AftermarketDeviceStorage
            .getStorage();
        INFT adIdProxy = INFT(ads.idProxyAddress);

        uint256 aftermarketDeviceNode;
        address owner;
        for (uint256 i = 0; i < adOwnerPair.length; i++) {
            aftermarketDeviceNode = adOwnerPair[i].aftermarketDeviceNodeId;
            owner = adOwnerPair[i].owner;

            if (ads.deviceClaimed[aftermarketDeviceNode])
                revert DeviceAlreadyClaimed(aftermarketDeviceNode);

            ads.deviceClaimed[aftermarketDeviceNode] = true;
            adIdProxy.safeTransferFrom(
                adIdProxy.ownerOf(aftermarketDeviceNode),
                owner,
                aftermarketDeviceNode
            );

            emit AftermarketDeviceClaimed(aftermarketDeviceNode, owner);
        }
    }

    /**
     * @notice Claims the ownership of an aftermarket device through a metatransaction
     * The aftermarket device owner signs a typed structured (EIP-712) message in advance and submits to be verified
     * @dev Caller must have the admin role
     * @dev This contract must be approved to spend the tokens in advance
     * @param aftermarketDeviceNode Aftermarket device node id
     * @param owner The address of the new owner
     * @param ownerSig User's signature hash
     * @param aftermarketDeviceSig Aftermarket Device's signature hash
     */
    function claimAftermarketDeviceSign(
        uint256 aftermarketDeviceNode,
        address owner,
        bytes calldata ownerSig,
        bytes calldata aftermarketDeviceSig
    ) external onlyRole(Roles.DEFAULT_ADMIN_ROLE) {
        AftermarketDeviceStorage.Storage storage ads = AftermarketDeviceStorage
            .getStorage();
        bytes32 message = keccak256(
            abi.encode(CLAIM_TYPEHASH, aftermarketDeviceNode, owner)
        );
        address aftermarketDeviceAddress = ads.nodeIdToDeviceAddress[
            aftermarketDeviceNode
        ];
        address adIdProxy = ads.idProxyAddress;

        if (!INFT(adIdProxy).exists(aftermarketDeviceNode))
            revert Errors.InvalidNode(adIdProxy, aftermarketDeviceNode);
        if (ads.deviceClaimed[aftermarketDeviceNode])
            revert DeviceAlreadyClaimed(aftermarketDeviceNode);
        if (!Eip712CheckerInternal._verifySignature(owner, message, ownerSig))
            revert Errors.InvalidOwnerSignature();
        if (
            !Eip712CheckerInternal._verifySignature(
                aftermarketDeviceAddress,
                message,
                aftermarketDeviceSig
            )
        ) revert InvalidAdSignature();

        ads.deviceClaimed[aftermarketDeviceNode] = true;
        INFT(adIdProxy).safeTransferFrom(
            INFT(adIdProxy).ownerOf(aftermarketDeviceNode),
            owner,
            aftermarketDeviceNode
        );

        emit AftermarketDeviceClaimed(aftermarketDeviceNode, owner);
    }

    /**
     * @notice Pairs an aftermarket device with a vehicle through a metatransaction.
     * The vehicle owner and AD sign a typed structured (EIP-712) message in advance and submits to be verified
     * @dev Caller must have the admin role
     * @param aftermarketDeviceNode Aftermarket device node id
     * @param vehicleNode Vehicle node id
     * @param aftermarketDeviceSig Aftermarket Device's signature hash
     * @param vehicleOwnerSig Vehicle owner signature hash
     */
    function pairAftermarketDeviceSign(
        uint256 aftermarketDeviceNode,
        uint256 vehicleNode,
        bytes calldata aftermarketDeviceSig,
        bytes calldata vehicleOwnerSig
    ) external onlyRole(Roles.DEFAULT_ADMIN_ROLE) {
        MapperStorage.Storage storage ms = MapperStorage.getStorage();
        bytes32 message = keccak256(
            abi.encode(PAIR_TYPEHASH, aftermarketDeviceNode, vehicleNode)
        );
        address vehicleIdProxyAddress = VehicleStorage
            .getStorage()
            .idProxyAddress;
        address adIdProxyAddress = AftermarketDeviceStorage
            .getStorage()
            .idProxyAddress;

        if (!INFT(vehicleIdProxyAddress).exists(vehicleNode))
            revert Errors.InvalidNode(vehicleIdProxyAddress, vehicleNode);
        if (!INFT(adIdProxyAddress).exists(aftermarketDeviceNode))
            revert Errors.InvalidNode(adIdProxyAddress, aftermarketDeviceNode);
        if (
            !AftermarketDeviceStorage.getStorage().deviceClaimed[
                aftermarketDeviceNode
            ]
        ) revert AdNotClaimed(aftermarketDeviceNode);
        if (ms.links[vehicleIdProxyAddress][vehicleNode] != 0)
            revert Errors.VehiclePaired(vehicleNode);
        if (ms.links[adIdProxyAddress][aftermarketDeviceNode] != 0)
            revert AdPaired(aftermarketDeviceNode);
        if (
            !Eip712CheckerInternal._verifySignature(
                AftermarketDeviceStorage.getStorage().nodeIdToDeviceAddress[
                    aftermarketDeviceNode
                ],
                message,
                aftermarketDeviceSig
            )
        ) revert InvalidAdSignature();

        if (
            !Eip712CheckerInternal._verifySignature(
                INFT(vehicleIdProxyAddress).ownerOf(vehicleNode),
                message,
                vehicleOwnerSig
            )
        ) revert Errors.InvalidOwnerSignature();

        ms.links[vehicleIdProxyAddress][vehicleNode] = aftermarketDeviceNode;
        ms.links[adIdProxyAddress][aftermarketDeviceNode] = vehicleNode;

        emit AftermarketDevicePaired(
            aftermarketDeviceNode,
            vehicleNode,
            INFT(adIdProxyAddress).ownerOf(aftermarketDeviceNode)
        );
    }

    /**
     * @notice Pairs an aftermarket device with a vehicle through a metatransaction
     * The aftermarket device owner signs a typed structured (EIP-712) message in advance and submits to be verified
     * @dev Caller must have the admin role
     * @param aftermarketDeviceNode Aftermarket device node id
     * @param vehicleNode Vehicle node id
     * @param signature User's signature hash
     */
    function pairAftermarketDeviceSign(
        uint256 aftermarketDeviceNode,
        uint256 vehicleNode,
        bytes calldata signature
    ) external onlyRole(Roles.DEFAULT_ADMIN_ROLE) {
        MapperStorage.Storage storage ms = MapperStorage.getStorage();
        bytes32 message = keccak256(
            abi.encode(PAIR_TYPEHASH, aftermarketDeviceNode, vehicleNode)
        );
        address vehicleIdProxyAddress = VehicleStorage
            .getStorage()
            .idProxyAddress;
        address adIdProxyAddress = AftermarketDeviceStorage
            .getStorage()
            .idProxyAddress;

        if (!INFT(vehicleIdProxyAddress).exists(vehicleNode))
            revert Errors.InvalidNode(vehicleIdProxyAddress, vehicleNode);

        address owner = INFT(vehicleIdProxyAddress).ownerOf(vehicleNode);

        if (!INFT(adIdProxyAddress).exists(aftermarketDeviceNode))
            revert Errors.InvalidNode(adIdProxyAddress, aftermarketDeviceNode);
        if (
            !AftermarketDeviceStorage.getStorage().deviceClaimed[
                aftermarketDeviceNode
            ]
        ) revert AdNotClaimed(aftermarketDeviceNode);
        if (owner != INFT(adIdProxyAddress).ownerOf(aftermarketDeviceNode))
            revert OwnersDoesNotMatch();
        if (ms.links[vehicleIdProxyAddress][vehicleNode] != 0)
            revert Errors.VehiclePaired(vehicleNode);
        if (ms.links[adIdProxyAddress][aftermarketDeviceNode] != 0)
            revert AdPaired(aftermarketDeviceNode);
        if (!Eip712CheckerInternal._verifySignature(owner, message, signature))
            revert Errors.InvalidOwnerSignature();

        ms.links[vehicleIdProxyAddress][vehicleNode] = aftermarketDeviceNode;
        ms.links[adIdProxyAddress][aftermarketDeviceNode] = vehicleNode;

        emit AftermarketDevicePaired(aftermarketDeviceNode, vehicleNode, owner);
    }

    /**
     * @dev Unpairs an aftermarket device from a vehicles through a metatransaction
     * Both vehicle and AD owners can unpair.
     * The aftermarket device owner signs a typed structured (EIP-712) message in advance and submits to be verified
     * @dev Caller must have the admin role
     * @param aftermarketDeviceNode Aftermarket device node id
     * @param vehicleNode Vehicle node id
     * @param signature User's signature hash
     */
    function unpairAftermarketDeviceSign(
        uint256 aftermarketDeviceNode,
        uint256 vehicleNode,
        bytes calldata signature
    ) external onlyRole(Roles.DEFAULT_ADMIN_ROLE) {
        bytes32 message = keccak256(
            abi.encode(UNPAIR_TYPEHASH, aftermarketDeviceNode, vehicleNode)
        );
        MapperStorage.Storage storage ms = MapperStorage.getStorage();
        address vehicleIdProxyAddress = VehicleStorage
            .getStorage()
            .idProxyAddress;
        address adIdProxyAddress = AftermarketDeviceStorage
            .getStorage()
            .idProxyAddress;

        if (!INFT(vehicleIdProxyAddress).exists(vehicleNode))
            revert Errors.InvalidNode(vehicleIdProxyAddress, vehicleNode);
        if (!INFT(adIdProxyAddress).exists(aftermarketDeviceNode))
            revert Errors.InvalidNode(adIdProxyAddress, aftermarketDeviceNode);
        if (
            ms.links[vehicleIdProxyAddress][vehicleNode] !=
            aftermarketDeviceNode
        ) revert VehicleNotPaired(vehicleNode);
        if (ms.links[adIdProxyAddress][aftermarketDeviceNode] != vehicleNode)
            revert AdNotPaired(aftermarketDeviceNode);

        address signer = Eip712CheckerInternal._recover(message, signature);
        address adOwner = INFT(adIdProxyAddress).ownerOf(aftermarketDeviceNode);

        if (
            signer != adOwner &&
            signer != INFT(vehicleIdProxyAddress).ownerOf(vehicleNode)
        ) revert Errors.InvalidSigner();

        ms.links[vehicleIdProxyAddress][vehicleNode] = 0;
        ms.links[adIdProxyAddress][aftermarketDeviceNode] = 0;

        emit AftermarketDeviceUnpaired(
            aftermarketDeviceNode,
            vehicleNode,
            adOwner
        );
    }

    /**
     * @notice Add infos to node
     * @dev attributes must be whitelisted
     * @param tokenId Node id where the info will be added
     * @param attrInfo List of attribute-info pairs to be added
     */
    function setAftermarketDeviceInfo(
        uint256 tokenId,
        Types.AttributeInfoPair[] calldata attrInfo
    ) external onlyRole(Roles.DEFAULT_ADMIN_ROLE) {
        address adIdProxy = AftermarketDeviceStorage
            .getStorage()
            .idProxyAddress;
        if (!INFT(adIdProxy).exists(tokenId))
            revert Errors.InvalidNode(adIdProxy, tokenId);
        _setInfos(tokenId, attrInfo);
    }

    /// @notice Gets the AD Id by the device address
    /// @dev If the device is not minted it will return 0
    /// @param addr Address associated with the aftermarket device
    function getAftermarketDeviceIdByAddress(address addr)
        external
        view
        returns (uint256 nodeId)
    {
        nodeId = AftermarketDeviceStorage.getStorage().deviceAddressToNodeId[
            addr
        ];
    }

    // ***** PRIVATE FUNCTIONS ***** //

    /**
     * @dev Internal function to add infos to node
     * @dev attributes must be whitelisted
     * @param tokenId Node where the info will be added
     * @param attrInfo List of attribute-info pairs to be added
     */
    function _setInfos(
        uint256 tokenId,
        Types.AttributeInfoPair[] calldata attrInfo
    ) private {
        NodesStorage.Storage storage ns = NodesStorage.getStorage();
        AftermarketDeviceStorage.Storage storage ads = AftermarketDeviceStorage
            .getStorage();
        address idProxyAddress = ads.idProxyAddress;

        for (uint256 i = 0; i < attrInfo.length; i++) {
            if (
                !AttributeSet.exists(
                    ads.whitelistedAttributes,
                    attrInfo[i].attribute
                )
            ) revert Errors.AttributeNotWhitelisted(attrInfo[i].attribute);

            ns.nodes[idProxyAddress][tokenId].info[
                attrInfo[i].attribute
            ] = attrInfo[i].info;

            emit AftermarketDeviceAttributeSet(
                tokenId,
                attrInfo[i].attribute,
                attrInfo[i].info
            );
        }
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./INFT.sol";

/// @title INFTMultiPrivilege
/// @notice Interface of a MultiPrivilege NFT
interface INFTMultiPrivilege is INFT {
    function hasPrivilege(
        uint256 tokenId,
        uint256 privId,
        address user
    ) external view returns (bool);
}

// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "./Eip712CheckerStorage.sol";

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Eip712CheckerInternal
/// @notice Contract with internal functions to assist in verifying signatures
/// @dev Based on the EIP-712 https://eips.ethereum.org/EIPS/eip-712
library Eip712CheckerInternal {
    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );

    /// @dev Returns the EIP-712 domain separator
    function _eip712Domain() internal view returns (bytes32) {
        Eip712CheckerStorage.Storage storage s = Eip712CheckerStorage
            .getStorage();

        return
            keccak256(
                abi.encode(
                    EIP712_DOMAIN_TYPEHASH,
                    s.name,
                    s.version,
                    block.chainid,
                    address(this)
                )
            );
    }

    /// @dev Recovers message signer
    /// @param message Hashed data payload
    /// @param signature Signed data payload
    function _recover(bytes32 message, bytes calldata signature)
        internal
        view
        returns (address signer)
    {
        bytes32 msgHash = keccak256(
            abi.encodePacked("\x19\x01", _eip712Domain(), message)
        );

        return ECDSA.recover(msgHash, signature);
    }

    /// @dev Recovers message signer and verifies if metches signatory
    /// @param signatory The signer to be verified
    /// @param message Hashed data payload
    /// @param signature Signed data payload
    function _verifySignature(
        address signatory,
        bytes32 message,
        bytes calldata signature
    ) internal view returns (bool success) {
        require(signatory != address(0), "ECDSA: zero signatory address");

        bytes32 msgHash = keccak256(
            abi.encodePacked("\x19\x01", _eip712Domain(), message)
        );

        return signatory == ECDSA.recover(msgHash, signature);
    }

    /// @dev Recovers message signer and verifies if metches signatory
    /// @param signatory The signer to be verified
    /// @param message Hashed data payload
    /// @param v Signature "v" value
    /// @param r Signature "r" value
    /// @param s Signature "s" value
    function _verifySignature(
        address signatory,
        bytes32 message,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal view returns (bool success) {
        require(signatory != address(0), "ECDSA: zero signatory address");

        bytes32 msgHash = keccak256(
            abi.encodePacked("\x19\x01", _eip712Domain(), message)
        );

        return signatory == ECDSA.recover(msgHash, v, r, s);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @title NodesStorage
/// @notice Storage of the Nodes contract
library NodesStorage {
    bytes32 internal constant NODES_STORAGE_SLOT =
        keccak256("DIMORegistry.nodes.storage");

    struct Node {
        uint256 parentNode;
        mapping(string => string) info;
    }

    struct Storage {
        mapping(address => mapping(uint256 => Node)) nodes;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = NODES_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../AttributeSet.sol";

/// @title ManufacturerStorage
/// @notice Storage of the Manufacturer contract
library ManufacturerStorage {
    using AttributeSet for AttributeSet.Set;

    bytes32 private constant MANUFACTURER_STORAGE_SLOT =
        keccak256("DIMORegistry.Manufacturer.storage");

    struct Controller {
        bool isController;
        bool manufacturerMinted;
    }

    struct Storage {
        address idProxyAddress;
        // [Controller address] => is controller, has minted manufacturer
        mapping(address => Controller) controllers;
        // Allowed node attribute
        AttributeSet.Set whitelistedAttributes;
        // Manufacturer name => Manufacturer Id
        mapping(string => uint256) manufacturerNameToNodeId;
        // Manufacturer Id => Manufacturer name
        mapping(uint256 => string) nodeIdToManufacturerName;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = MANUFACTURER_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../AttributeSet.sol";

/// @title VehicleStorage
/// @notice Storage of the Vehicle contract
library VehicleStorage {
    using AttributeSet for AttributeSet.Set;

    bytes32 private constant VEHICLE_STORAGE_SLOT =
        keccak256("DIMORegistry.vehicle.storage");

    struct Storage {
        address idProxyAddress;
        // Allowed node attribute
        AttributeSet.Set whitelistedAttributes;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = VEHICLE_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../AttributeSet.sol";

/// @title AftermarketDeviceStorage
/// @notice Storage of the AftermarketDevice contract
library AftermarketDeviceStorage {
    using AttributeSet for AttributeSet.Set;

    bytes32 private constant AFTERMARKET_DEVICE_STORAGE_SLOT =
        keccak256("DIMORegistry.aftermarketDevice.storage");

    struct Storage {
        address idProxyAddress;
        // Allowed node attribute
        AttributeSet.Set whitelistedAttributes;
        // AD Id => already claimed or not
        mapping(uint256 => bool) deviceClaimed;
        // AD address => AD Id
        mapping(address => uint256) deviceAddressToNodeId;
        // AD Id => AD address
        mapping(uint256 => address) nodeIdToDeviceAddress;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = AFTERMARKET_DEVICE_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @title MapperStorage
/// @notice Storage of the Mapper contract
library MapperStorage {
    bytes32 internal constant MAPPER_STORAGE_SLOT =
        keccak256("DIMORegistry.mapper.storage");

    struct Storage {
        // Links between Vehicles and ADs
        // idProxyAddress -> vehicleId/adId -> adId/vehicleId
        mapping(address => mapping(uint256 => uint256)) links;
        // Stores beneficiary addresses for a given nodeId of an idProxy
        // idProxyAddress -> nodeId -> beneficiary
        mapping(address => mapping(uint256 => address)) beneficiaries;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = MAPPER_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../../libraries/AdLicenseValidatorStorage.sol";

error InvalidLicense();

/// @title AdLicenseValidatorInternal
/// @notice Contract with internal functions to assist in aftermarket device minting
/// @dev Stake contract repository https://github.com/DIMO-Network/dimo-staking-contract-license-nft
contract AdLicenseValidatorInternal {
    /**
     * @notice Validates if the manufacturer has a License
     * Calculates the total cost to mint the desired amount of aftermarket devices
     * The sender transfers the calculated amount to the foundation
     * @dev This contract must be approved to spend the tokens in advance
     * @param manufacturer The address of the manufacturer
     * @param sender The address of the sender
     * @param amount The amount of devices to be minted
     */
    function _validateMintRequest(
        address manufacturer,
        address sender,
        uint256 amount
    ) internal {
        AdLicenseValidatorStorage.Storage storage s = AdLicenseValidatorStorage
            .getStorage();

        if (s.license.balanceOf(manufacturer) == 0) revert InvalidLicense();

        s.dimoToken.transferFrom(sender, s.foundation, s.adMintCost * amount);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

bytes32 constant DEFAULT_ADMIN_ROLE = 0x00;
bytes32 constant MINTER_ROLE = keccak256("Minter");

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @notice File to store shared structs

struct AttributeInfoPair {
    string attribute;
    string info;
}

struct AftermarketDeviceInfos {
    address addr;
    AttributeInfoPair[] attrInfoPairs;
}

struct AftermarketDeviceOwnerPair {
    uint256 aftermarketDeviceNodeId;
    address owner;
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

// Misc
error ZeroAddress();
error Unauthorized(address addr);
error AttributeExists(string attr);
error AttributeNotWhitelisted(string attr);
error AlreadyController(address addr);

// Nodes
error InvalidParentNode(uint256 id);
error InvalidParentNodeOwner(uint256 id, address addr);
error InvalidNode(address proxy, uint256 id);
error VehiclePaired(uint256 id);

// Signature
error InvalidSigner();
error InvalidOwnerSignature();

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';
import { AddressUtils } from '../../utils/AddressUtils.sol';
import { UintUtils } from '../../utils/UintUtils.sol';
import { IAccessControlInternal } from './IAccessControlInternal.sol';
import { AccessControlStorage } from './AccessControlStorage.sol';

/**
 * @title Role-based access control system
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
abstract contract AccessControlInternal is IAccessControlInternal {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;
    using UintUtils for uint256;

    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /*
     * @notice query whether role is assigned to account
     * @param role role to query
     * @param account account to query
     * @return whether role is assigned to account
     */
    function _hasRole(bytes32 role, address account)
        internal
        view
        virtual
        returns (bool)
    {
        return
            AccessControlStorage.layout().roles[role].members.contains(account);
    }

    /**
     * @notice revert if sender does not have given role
     * @param role role to query
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }

    /**
     * @notice revert if given account does not have given role
     * @param role role to query
     * @param account to query
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!_hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        'AccessControl: account ',
                        account.toString(),
                        ' is missing role ',
                        uint256(role).toHexString(32)
                    )
                )
            );
        }
    }

    /*
     * @notice query admin role for given role
     * @param role role to query
     * @return admin role
     */
    function _getRoleAdmin(bytes32 role)
        internal
        view
        virtual
        returns (bytes32)
    {
        return AccessControlStorage.layout().roles[role].adminRole;
    }

    /**
     * @notice set role as admin role
     * @param role role to set
     * @param adminRole admin role to set
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = _getRoleAdmin(role);
        AccessControlStorage.layout().roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /*
     * @notice assign role to given account
     * @param role role to assign
     * @param account recipient of role assignment
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.add(account);
        emit RoleGranted(role, account, msg.sender);
    }

    /*
     * @notice unassign role from given account
     * @param role role to unassign
     * @parm account
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        AccessControlStorage.layout().roles[role].members.remove(account);
        emit RoleRevoked(role, account, msg.sender);
    }

    /**
     * @notice relinquish role
     * @param role role to relinquish
     */
    function _renounceRole(bytes32 role) internal virtual {
        _revokeRole(role, msg.sender);
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @title INFT
/// @notice Interface of a generic NFT
interface INFT {
    function safeMint(address to) external returns (uint256);

    function safeTransferByRegistry(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function setApprovalForAll(address operator, bool _approved) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function exists(uint256 tokenId) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @title Eip712CheckerStorage
/// @notice Storage of the Eip712Checker contract
library Eip712CheckerStorage {
    bytes32 internal constant EIP712_CHECKER_STORAGE_SLOT =
        keccak256("DIMORegistry.eip712Checker.storage");

    struct Storage {
        bytes32 name;
        bytes32 version;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = EIP712_CHECKER_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)

library AttributeSet {
    struct Set {
        string[] _values;
        mapping(string => uint256) _indexes;
    }

    function add(Set storage set, string calldata key) internal returns (bool) {
        if (!exists(set, key)) {
            set._values.push(key);
            set._indexes[key] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function remove(Set storage set, string calldata key)
        internal
        returns (bool)
    {
        uint256 valueIndex = set._indexes[key];

        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                string memory lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    function count(Set storage set) internal view returns (uint256) {
        return (set._values.length);
    }

    function exists(Set storage set, string calldata key)
        internal
        view
        returns (bool)
    {
        return set._indexes[key] != 0;
    }
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

import "../interfaces/IDimo.sol";
import "../interfaces/ILicense.sol";

/// @title AdLicenseValidatorStorage
/// @notice Storage of the AdLicenseValidator contract
library AdLicenseValidatorStorage {
    bytes32 internal constant AD_LICENSE_VALIDATOR_STORAGE_SLOT =
        keccak256("DIMORegistry.adLicenseValidator.storage");

    struct Storage {
        address foundation;
        IDimo dimoToken;
        ILicense license;
        uint256 adMintCost;
    }

    /* solhint-disable no-inline-assembly */
    function getStorage() internal pure returns (Storage storage s) {
        bytes32 slot = AD_LICENSE_VALIDATOR_STORAGE_SLOT;
        assembly {
            s.slot := slot
        }
    }
    /* solhint-enable no-inline-assembly */
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @title IDimo
/// @notice Interface of the DIMO token
/// @dev DIMO token repository https://github.com/DIMO-Network/dimo-token
interface IDimo {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

//SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.13;

/// @title ILicense
/// @notice Interface of the Stake contract that is used to issuing Liceses to manufacturers
/// @dev Stake contract repository https://github.com/DIMO-Network/dimo-staking-contract-license-nft
interface ILicense {
    function balanceOf(address owner) external view returns (uint256);

    function ownerOf(uint256 tokenId) external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Set implementation with enumeration functions
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts (MIT license)
 */
library EnumerableSet {
    error EnumerableSet__IndexOutOfBounds();

    struct Set {
        bytes32[] _values;
        // 1-indexed to allow 0 to signify nonexistence
        mapping(bytes32 => uint256) _indexes;
    }

    struct Bytes32Set {
        Set _inner;
    }

    struct AddressSet {
        Set _inner;
    }

    struct UintSet {
        Set _inner;
    }

    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    function indexOf(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, value);
    }

    function indexOf(AddressSet storage set, address value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(uint256(uint160(value))));
    }

    function indexOf(UintSet storage set, uint256 value)
        internal
        view
        returns (uint256)
    {
        return _indexOf(set._inner, bytes32(value));
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    function toArray(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        uint256 len = _length(set._inner);
        bytes32[] memory arr = new bytes32[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        uint256 len = _length(set._inner);
        address[] memory arr = new address[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function toArray(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        uint256 len = _length(set._inner);
        uint256[] memory arr = new uint256[](len);

        unchecked {
            for (uint256 index; index < len; ++index) {
                arr[index] = at(set, index);
            }
        }

        return arr;
    }

    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        if (index >= set._values.length)
            revert EnumerableSet__IndexOutOfBounds();
        return set._values[index];
    }

    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    function _indexOf(Set storage set, bytes32 value)
        private
        view
        returns (uint256)
    {
        unchecked {
            return set._indexes[value] - 1;
        }
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            unchecked {
                bytes32 last = set._values[set._values.length - 1];

                // move last value to now-vacant index

                set._values[valueIndex - 1] = last;
                set._indexes[last] = valueIndex;
            }
            // clear last index

            set._values.pop();
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { UintUtils } from './UintUtils.sol';

library AddressUtils {
    using UintUtils for uint256;

    error AddressUtils__InsufficientBalance();
    error AddressUtils__NotContract();
    error AddressUtils__SendValueFailed();

    function toString(address account) internal pure returns (string memory) {
        return uint256(uint160(account)).toHexString(20);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable account, uint256 amount) internal {
        (bool success, ) = account.call{ value: amount }('');
        if (!success) revert AddressUtils__SendValueFailed();
    }

    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionCall(target, data, 'AddressUtils: failed low-level call');
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory error
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, error);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                'AddressUtils: failed low-level call with value'
            );
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) internal returns (bytes memory) {
        if (value > address(this).balance)
            revert AddressUtils__InsufficientBalance();
        return _functionCallWithValue(target, data, value, error);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory error
    ) private returns (bytes memory) {
        if (!isContract(target)) revert AddressUtils__NotContract();

        (bool success, bytes memory returnData) = target.call{ value: value }(
            data
        );

        if (success) {
            return returnData;
        } else if (returnData.length > 0) {
            assembly {
                let returnData_size := mload(returnData)
                revert(add(32, returnData), returnData_size)
            }
        } else {
            revert(error);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title utility functions for uint256 operations
 * @dev derived from https://github.com/OpenZeppelin/openzeppelin-contracts/ (MIT license)
 */
library UintUtils {
    error UintUtils__InsufficientHexLength();

    bytes16 private constant HEX_SYMBOLS = '0123456789abcdef';

    function add(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? sub(a, -b) : a + uint256(b);
    }

    function sub(uint256 a, int256 b) internal pure returns (uint256) {
        return b < 0 ? add(a, -b) : a - uint256(b);
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0';
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

    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return '0x00';
        }

        uint256 length = 0;

        for (uint256 temp = value; temp != 0; temp >>= 8) {
            unchecked {
                length++;
            }
        }

        return toHexString(value, length);
    }

    function toHexString(uint256 value, uint256 length)
        internal
        pure
        returns (string memory)
    {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = '0';
        buffer[1] = 'x';

        unchecked {
            for (uint256 i = 2 * length + 1; i > 1; --i) {
                buffer[i] = HEX_SYMBOLS[value & 0xf];
                value >>= 4;
            }
        }

        if (value != 0) revert UintUtils__InsufficientHexLength();

        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Partial AccessControl interface needed by internal functions
 */
interface IAccessControlInternal {
    event RoleAdminChanged(
        bytes32 indexed role,
        bytes32 indexed previousAdminRole,
        bytes32 indexed newAdminRole
    );

    event RoleGranted(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );

    event RoleRevoked(
        bytes32 indexed role,
        address indexed account,
        address indexed sender
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { EnumerableSet } from '../../data/EnumerableSet.sol';

library AccessControlStorage {
    struct RoleData {
        EnumerableSet.AddressSet members;
        bytes32 adminRole;
    }

    struct Layout {
        mapping(bytes32 => RoleData) roles;
    }

    bytes32 internal constant DEFAULT_ADMIN_ROLE = 0x00;

    bytes32 internal constant STORAGE_SLOT =
        keccak256('solidstate.contracts.storage.AccessControl');

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}