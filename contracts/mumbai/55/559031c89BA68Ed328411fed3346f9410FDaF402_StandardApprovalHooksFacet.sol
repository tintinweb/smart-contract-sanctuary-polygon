// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@nexeraprotocol/metanft/contracts/interfaces/IMetaNFT.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../../generic-diamond/BaseSinglePropertyManagerStorage.sol";

contract StandardApprovalHooksFacet {
    using BaseSinglePropertyManagerStorage for BaseSinglePropertyManagerStorage.Layout;

    /**
     * This hook can be used as default hook for wildcard target and/or selector
     */
    function approvalHookDenyAll(
        uint256, /*mnft*/
        address, /*sender*/
        address, /*target*/
        bytes calldata, /*message*/
        bytes calldata, /*initialHookData*/
        bytes calldata /*actualHookData*/
    ) external pure returns (bytes memory res) {
        revert("Denied");
    }


    function approvalHookAllowAllForMnftOwner(
        uint256 mnft,
        address sender,
        address, /*target*/
        bytes calldata, /*message*/
        bytes calldata, /*initialHookData*/
        bytes calldata /*actualHookData*/
    ) external view returns (bytes memory res) {
        // Verify ownership
        requireSenderIsMnftOwner(mnft, sender);
        return bytes("");        
    }
    /**
     * @notice Approval hook to approve ERC20 transfers for only MetaNFT owner
     * with a limit of ERC20 amount allowed
     * @param mnft MetaNFT id to work with
     * @param sender Sender of the message to a SmartWallet
     * @param target Target of the action (ERC20 token to transfer)
     * @param message Payload of the action (call to the transfer function)
     * @param initialHookData Initial limit of amount to transfer
     * @param actualHookData Amount already used
     */
    function approvalHookERC20TransferForMNFTOwnerWithLimit(
        uint256 mnft,
        address sender,
        address target,
        bytes calldata message,
        bytes calldata initialHookData,
        bytes calldata actualHookData
    ) external view returns (bytes memory res) {
        // Verify ownership
        requireSenderIsMnftOwner(mnft, sender);
        // Decode message
        requireHookForCorrectMethod(message, IERC20.transfer.selector);
        (, uint256 amount) = abi.decode(message[4:], (address, uint256));

        // Verify amount
        uint256 initialApproval = abi.decode(initialHookData, (uint256));
        uint256 usedApproval = (actualHookData.length == 0) ? 0 : abi.decode(actualHookData, (uint256));
        require(amount <= initialApproval - usedApproval, "not enough approval");

        // Calculate new hookData
        if (initialApproval == type(uint256).max) {
            // Unlimited approval
            return new bytes(0);
        } else {
            return abi.encode(initialApproval - usedApproval - amount);
        }
    }

    /**
     * @notice Approval hook to approve ERC20 transfersFrom approval for only MetaNFT owner
     * with a limit of ERC20 amount allowed
     * @param mnft MetaNFT id to work with
     * @param sender Sender of the message to a SmartWallet
     * @param target Target of the action (ERC20 token to transfer)
     * @param message Payload of the action  (call to the approve function)
     * @param initialHookData Initial limit of amount to transfer and allowed spender address (or wildcard if 0x00)
     * @param actualHookData Amount already used
     */
    function approvalHookERC20ApproveForMNFTOwnerWithLimit(
        uint256 mnft,
        address sender,
        address target,
        bytes calldata message,
        bytes calldata initialHookData,
        bytes calldata actualHookData
    ) external view returns (bytes memory res) {
        // Verify ownership
        requireSenderIsMnftOwner(mnft, sender);
        // Decode message
        requireHookForCorrectMethod(message, IERC20.approve.selector);
        (address spender, uint256 amount) = abi.decode(message[4:], (address, uint256));

        // Decode initial data
        (address approvedSpender, uint256 initialApproval) = abi.decode(initialHookData, (address, uint256));

        //Verify spender
        if (approvedSpender != address(0)) {
            require(spender == approvedSpender, "Spender not approved");
        }

        // Verify amount
        uint256 usedApproval = (actualHookData.length == 0) ? 0 : abi.decode(actualHookData, (uint256));
        require(amount <= initialApproval - usedApproval, "not enough approval");

        // Calculate new hookData
        if (initialApproval == type(uint256).max) {
            // Unlimited approval
            return new bytes(0);
        } else {
            return abi.encode(initialApproval - usedApproval - amount);
        }
    }


    function requireSenderIsMnftOwner(uint256 mnft, address sender) internal view {
        require(sender == BaseSinglePropertyManagerStorage.layout().mnft.ownerOf(mnft), "Only mNFT owner is approved");
    }

    function requireHookForCorrectMethod(bytes calldata message, bytes4 selector) internal pure {
        require(bytes4(message[:4]) == selector, "hook for wrong method");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@nexeraprotocol/metanft/contracts/interfaces/IMetaNFT.sol";
import "@nexeraprotocol/metanft/contracts/interfaces/IMetaRestrictions.sol";
import "@nexeraprotocol/metanft/contracts/interfaces/IMetadataGenerator.sol";
import "@nexeraprotocol/metanft/contracts/utils/Metadata.sol";

library BaseSinglePropertyManagerStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("allianceblock.MetaNFT.managers.generic-diamond.BaseSinglePropertyManagerStorage");

    struct Layout {
        IMetaNFT mnft;
        bytes32 prop;
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMetaToken.sol";
import "./IMetaTokenMetadata.sol";
import "./IMetaProperties.sol";
import "./IMetaRestrictions.sol";
import "./IMetaGlobalData.sol";

interface IMetaNFT is IMetaToken, IMetaTokenMetadata, IMetaProperties, IMetaRestrictions, IMetaGlobalData {}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaRestrictions {
    struct Restriction {
        bytes32 rtype;
        bytes data;
    }

    struct RestrictionByIndex {
        Restriction restriction; 
        uint256 index;
    }

    function addRestriction(
        uint256 pid,
        bytes32 prop,
        Restriction calldata restr
    ) external returns (uint256 idx);

    function removeRestriction(
        uint256 pid,
        bytes32 prop,
        uint256 ridx
    ) external;

    function removeRestrictions(
        uint256 pid,
        bytes32 prop,
        uint256[] calldata ridxs
    ) external;

    function getRestrictions(uint256 pid, bytes32 prop) external view returns (Restriction[] memory);

    function getRestrictionsWithIndexes(uint256 pid, bytes32 prop) external view returns (RestrictionByIndex[] memory);

    function moveRestrictions(
        uint256 fromPid,
        uint256 toPid,
        bytes32 prop
    ) external returns (uint256[] memory newIdxs);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../utils/Metadata.sol";

interface IMetadataGenerator {
    function generateMetadata(bytes32 prop, uint256 pid) external view returns (Metadata.ExtraProperties memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./StringNumberUtils.sol";

/**
 * @dev Provides functions to generate NFT Metadata
 */
library Metadata {
    //bytes32 internal constant TEMP_STORAGE_SLOT = keccak256("allianceblock.metadata.temporary_extra_properties");

    string private constant URI_PREFIX = "data:application/json;base64,";

    struct BaseERC721Properties {
        string name;
        string description;
        string image;
    }

    struct BaseERC1155Properties {
        string name;
        string description;
        uint8 decimals;
        string image;
    }

    struct StringProperty {
        string name;
        string value;
    }

    struct DateProperty {
        string name;
        int64 value;
    }

    struct IntegerProperty {
        string name;
        int64 value;
    }

    struct DecimalProperty {
        string name;
        int256 value;
        uint8 decimals;
        uint8 precision;
        bool truncate;
    }

    struct ExtraProperties {
        StringProperty[] stringProperties;
        DateProperty[] dateProperties;
        IntegerProperty[] integerProperties;
        DecimalProperty[] decimalProperties;
    }

    function generateERC721Metadata(BaseERC721Properties memory bp, StringProperty[] memory sps) public pure returns (string memory) {
        ExtraProperties memory ep;
        ep.stringProperties = sps;
        ep.dateProperties = new DateProperty[](0);
        ep.integerProperties = new IntegerProperty[](0);
        ep.decimalProperties = new DecimalProperty[](0);
        return uriEncode(encodeERC721Metadata(bp, ep));
    }

    function generateERC721Metadata(BaseERC721Properties memory bp, ExtraProperties memory ep) public pure returns (string memory) {
        return uriEncode(encodeERC721Metadata(bp, ep));
    }

    function emptyExtraProperties() internal pure returns (ExtraProperties memory) {
        ExtraProperties memory ep;
        ep.stringProperties = new StringProperty[](0);
        ep.dateProperties = new DateProperty[](0);
        ep.integerProperties = new IntegerProperty[](0);
        ep.decimalProperties = new DecimalProperty[](0);
        return ep;
    }

    function add(ExtraProperties memory ep, StringProperty memory p) internal pure returns (ExtraProperties memory) {
        StringProperty[] memory npa = new StringProperty[](ep.stringProperties.length + 1);
        for (uint256 i = 0; i < ep.stringProperties.length; i++) {
            npa[i] = ep.stringProperties[i];
        }
        npa[ep.stringProperties.length] = p;
        ep.stringProperties = npa;
        return ep;
    }

    function add(ExtraProperties memory ep, DateProperty memory p) internal pure returns (ExtraProperties memory) {
        DateProperty[] memory npa = new DateProperty[](ep.stringProperties.length + 1);
        for (uint256 i = 0; i < ep.dateProperties.length; i++) {
            npa[i] = ep.dateProperties[i];
        }
        npa[ep.dateProperties.length] = p;
        ep.dateProperties = npa;
        return ep;
    }

    function add(ExtraProperties memory ep, IntegerProperty memory p) internal pure returns (ExtraProperties memory) {
        IntegerProperty[] memory npa = new IntegerProperty[](ep.stringProperties.length + 1);
        for (uint256 i = 0; i < ep.integerProperties.length; i++) {
            npa[i] = ep.integerProperties[i];
        }
        npa[ep.integerProperties.length] = p;
        ep.integerProperties = npa;
        return ep;
    }

    function add(ExtraProperties memory ep, DecimalProperty memory p) internal pure returns (ExtraProperties memory) {
        DecimalProperty[] memory npa = new DecimalProperty[](ep.stringProperties.length + 1);
        for (uint256 i = 0; i < ep.decimalProperties.length; i++) {
            npa[i] = ep.decimalProperties[i];
        }
        npa[ep.decimalProperties.length] = p;
        ep.decimalProperties = npa;
        return ep;
    }

    function merge(ExtraProperties memory ep1, ExtraProperties memory ep2) internal pure returns (ExtraProperties memory rep) {
        uint256 offset;
        rep.stringProperties = new StringProperty[](ep1.stringProperties.length + ep2.stringProperties.length);
        for (uint256 i = 0; i < ep1.stringProperties.length; i++) {
            rep.stringProperties[i] = ep1.stringProperties[i];
        }
        offset = ep1.stringProperties.length;
        for (uint256 i = 0; i < ep2.stringProperties.length; i++) {
            rep.stringProperties[offset + i] = ep2.stringProperties[i];
        }

        rep.dateProperties = new DateProperty[](ep1.dateProperties.length + ep2.dateProperties.length);
        for (uint256 i = 0; i < ep1.dateProperties.length; i++) {
            rep.dateProperties[i] = ep1.dateProperties[i];
        }
        offset = ep1.dateProperties.length;
        for (uint256 i = 0; i < ep2.dateProperties.length; i++) {
            rep.dateProperties[offset + i] = ep2.dateProperties[i];
        }

        rep.integerProperties = new IntegerProperty[](ep1.integerProperties.length + ep2.integerProperties.length);
        for (uint256 i = 0; i < ep1.integerProperties.length; i++) {
            rep.integerProperties[i] = ep1.integerProperties[i];
        }
        offset = ep1.integerProperties.length;
        for (uint256 i = 0; i < ep2.integerProperties.length; i++) {
            rep.integerProperties[offset + i] = ep2.integerProperties[i];
        }

        rep.decimalProperties = new DecimalProperty[](ep1.decimalProperties.length + ep2.decimalProperties.length);
        for (uint256 i = 0; i < ep1.decimalProperties.length; i++) {
            rep.decimalProperties[i] = ep1.decimalProperties[i];
        }
        offset = ep1.decimalProperties.length;
        for (uint256 i = 0; i < ep2.decimalProperties.length; i++) {
            rep.decimalProperties[offset + i] = ep2.decimalProperties[i];
        }
    }

    function uriEncode(string memory metadata) private pure returns (string memory) {
        return string.concat(URI_PREFIX, Base64.encode(bytes(metadata)));
    }

    function encodeERC721Metadata(BaseERC721Properties memory bp, ExtraProperties memory ep) private pure returns (string memory) {
        string memory ap = encodeOpenSeaAttributes(ep);
        return string.concat("{", encodeBaseProperties(bp), ",", '"attributes":[', ap, "]}");
    }

    function encodeBaseProperties(BaseERC721Properties memory bp) private pure returns (string memory) {
        return string.concat('"name":"', bp.name, '",', '"description":"', bp.description, '",', '"image":"', bp.image, '"');
    }

    function encodeOpenSeaAttributes(ExtraProperties memory ep) private pure returns (string memory) {
        uint256 i;
        uint256 p = 1;
        string memory tmp = "";

        for (i = 0; i < ep.stringProperties.length; i++) {
            tmp = string.concat(tmp, toOpenSeaAttribute(ep.stringProperties[i], Strings.toString(p++)));
        }

        if (ep.dateProperties.length > 0 && bytes(tmp).length > 0) tmp = string(abi.encodePacked(tmp, ","));
        for (i = 0; i < ep.dateProperties.length; i++) {
            tmp = string.concat(tmp, toOpenSeaAttribute(ep.dateProperties[i], Strings.toString(p++)));
        }

        if (ep.integerProperties.length > 0 && bytes(tmp).length > 0) tmp = string(abi.encodePacked(tmp, ","));
        for (i = 0; i < ep.integerProperties.length; i++) {
            tmp = string.concat(tmp, toOpenSeaAttribute(ep.integerProperties[i], Strings.toString(p++)));
        }

        if (ep.decimalProperties.length > 0 && bytes(tmp).length > 0) tmp = string(abi.encodePacked(tmp, ","));
        for (i = 0; i < ep.decimalProperties.length; i++) {
            tmp = string.concat(tmp, toOpenSeaAttribute(ep.decimalProperties[i], Strings.toString(p++)));
        }

        return tmp;
    }

    function toOpenSeaAttribute(StringProperty memory v, string memory prefix) private pure returns (string memory) {
        return string.concat('{"trait_type":"', prefix, ": ", v.name, '","value":"', v.value, '"}');
    }

    function toOpenSeaAttribute(IntegerProperty memory v, string memory prefix) private pure returns (string memory) {
        return string.concat('{"trait_type":"', prefix, ": ", v.name, '","value":', StringNumberUtils.fromInt64(v.value), "}");
    }

    function toOpenSeaAttribute(DateProperty memory v, string memory prefix) private pure returns (string memory) {
        return string.concat('{"trait_type":"', prefix, ": ", v.name, '","value":', StringNumberUtils.fromInt64(v.value), ',"display_type":"date"}');
    }

    function toOpenSeaAttribute(DecimalProperty memory v, string memory prefix) private pure returns (string memory) {
        return
            string.concat(
                '{"trait_type":"',
                prefix,
                ": ",
                v.name,
                '","value":',
                StringNumberUtils.fromInt256(v.value, v.decimals, v.precision, v.truncate),
                "}"
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/token/ERC721/base/IERC721Base.sol";
import "@solidstate/contracts/token/ERC721/enumerable/IERC721Enumerable.sol";

interface IMetaToken is IERC721Base, IERC721Enumerable {
    function mint(address beneficiary) external returns (uint256);

    function claim(uint256 pid) external; //Tokens transfeered to a user are unavialible for getToken/getorMint/getAllTokensWithProperty untill claimed

    function getToken(address beneficiary, bytes32 property) external view returns (uint256);

    function getOrMintToken(address beneficiary, bytes32 property) external returns (uint256);

    function getAllTokensWithProperty(address beneficiary, bytes32 property) external view returns (uint256[] memory);

    /**
     * @notice Joins two NFTs of the same owner
     * @param fromPid Second NFT (properties will be removed from this one)
     * @param toPid Main NFT (properties will be added to this one)
     * @param category Category of the NFT to merge
     */
    function merge(
        uint256 fromPid,
        uint256 toPid,
        bytes32 category
    ) external;

    function merge(
        uint256 fromPid,
        uint256 toPid,
        bytes32[] calldata categories
    ) external;

    /**
     * @notice Splits a MetaNFTs into two
     * @param pid Id of the NFT to split
     * @param category Category of the NFT to split
     * @return newPid Id of the new NFT holding the detached Category
     */
    function split(uint256 pid, bytes32 category) external returns (uint256 newPid);

    function split(uint256 pid, bytes32[] calldata categories) external returns (uint256 newPid);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMetaRestrictions.sol";

interface IMetaProperties {
    function addProperty(
        uint256 pid,
        bytes32 prop,
        IMetaRestrictions.Restriction[] calldata restrictions
    ) external;

    function removeProperty(uint256 pid, bytes32 prop) external;

    function hasProperty(uint256 pid, bytes32 prop) external view returns (bool);

    function hasProperty(address beneficiary, bytes32 prop) external view returns (bool);

    function setBeforePropertyTransferHook(
        bytes32 prop,
        address target,
        bytes4 selector
    ) external;

    function setOnTransferConflictHook(
        bytes32 prop,
        address target,
        bytes4 selector
    ) external;

    function getAllProperties(uint256 pid) external view returns (bytes32[] memory);

    function getAllKeys(uint256 pid, bytes32 prop)
        external
        view
        returns (
            bytes32[] memory vkeys,
            bytes32[] memory bkeys,
            bytes32[] memory skeys,
            bytes32[] memory mkeys
        );

    function setDataBytes32(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external;

    function getDataBytes32(
        uint256 pid,
        bytes32 prop,
        bytes32 key
    ) external view returns (bytes32);

    function setDataBytes(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes calldata value
    ) external;

    function getDataBytes(
        uint256 pid,
        bytes32 prop,
        bytes32 key
    ) external view returns (bytes memory);

    function getDataSetContainsValue(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external view returns (bool);

    function getDataSetLength(
        uint256 pid,
        bytes32 prop,
        bytes32 key
    ) external view returns (uint256);

    function getDataSetAllValues(
        uint256 pid,
        bytes32 prop,
        bytes32 key
    ) external view returns (bytes32[] memory);

    function setDataSetAddValue(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external;

    function setDataSetRemoveValue(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external;

    function getDataMapValue(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes32 vKey
    ) external view returns (bytes32);

    function getDataMapLength(
        uint256 pid,
        bytes32 prop,
        bytes32 key
    ) external view returns (uint256);

    function getDataMapAllEntries(
        uint256 pid,
        bytes32 prop,
        bytes32 key
    ) external view returns (bytes32[] memory, bytes32[] memory);

    function setDataMapSetValue(
        uint256 pid,
        bytes32 prop,
        bytes32 key,
        bytes32 vKey,
        bytes32 vValue
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";

interface IMetaTokenMetadata is IERC721Metadata {

    function contractURI() external view returns (string memory);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMetaGlobalData {
    function getAllGlobalKeys(bytes32 prop)
        external
        view
        returns (
            bytes32[] memory vkeys,
            bytes32[] memory bkeys,
            bytes32[] memory skeys,
            bytes32[] memory mkeys
        );

    function setGlobalDataBytes32(
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external;

    function getGlobalDataBytes32(bytes32 prop, bytes32 key) external view returns (bytes32);

    function setGlobalDataBytes(
        bytes32 prop,
        bytes32 key,
        bytes calldata value
    ) external;

    function getGlobalDataBytes(bytes32 prop, bytes32 key) external view returns (bytes memory);

    function getGlobalDataSetContainsValue(
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external view returns (bool);

    function getGlobalDataSetLength(bytes32 prop, bytes32 key) external view returns (uint256);

    function getGlobalDataSetAllValues(bytes32 prop, bytes32 key) external view returns (bytes32[] memory);

    function setGlobalDataSetAddValue(
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external;

    function setGlobalDataSetRemoveValue(
        bytes32 prop,
        bytes32 key,
        bytes32 value
    ) external;

    function getGlobalDataMapValue(
        bytes32 prop,
        bytes32 key,
        bytes32 vKey
    ) external view returns (bytes32);

    function getGlobalDataMapLength(bytes32 prop, bytes32 key) external view returns (uint256);

    function getGlobalDataMapAllEntries(bytes32 prop, bytes32 key) external view returns (bytes32[] memory, bytes32[] memory);

    function setGlobalDataMapSetValue(
        bytes32 prop,
        bytes32 key,
        bytes32 vKey,
        bytes32 vValue
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

interface IERC721Enumerable {
    /**
     * @notice get total token supply
     * @return total supply
     */
    function totalSupply() external view returns (uint256);

    /**
     * @notice get token of given owner at given internal storage index
     * @param owner token holder to query
     * @param index position in owner's token list to query
     * @return tokenId id of retrieved token
     */
    function tokenOfOwnerByIndex(address owner, uint256 index)
        external
        view
        returns (uint256 tokenId);

    /**
     * @notice get token at given internal storage index
     * @param index position in global token list to query
     * @return tokenId id of retrieved token
     */
    function tokenByIndex(uint256 index)
        external
        view
        returns (uint256 tokenId);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721 } from '../../../interfaces/IERC721.sol';
import { IERC721BaseInternal } from './IERC721BaseInternal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721Base is IERC721BaseInternal, IERC721 {

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC165 } from './IERC165.sol';
import { IERC721Internal } from './IERC721Internal.sol';

/**
 * @title ERC721 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721 is IERC721Internal, IERC165 {
    /**
     * @notice query the balance of given address
     * @return balance quantity of tokens held
     */
    function balanceOf(address account) external view returns (uint256 balance);

    /**
     * @notice query the owner of given token
     * @param tokenId token to query
     * @return owner token owner
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice transfer token between given addresses, checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     * @param data data payload
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external payable;

    /**
     * @notice transfer token between given addresses, without checking for ERC721Receiver implementation if applicable
     * @param from sender of token
     * @param to receiver of token
     * @param tokenId token id
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external payable;

    /**
     * @notice grant approval to given account to spend token
     * @param operator address to be approved
     * @param tokenId token to approve
     */
    function approve(address operator, uint256 tokenId) external payable;

    /**
     * @notice get approval status for given token
     * @param tokenId token to query
     * @return operator address approved to spend token
     */
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    /**
     * @notice grant approval to or revoke approval from given account to spend all tokens held by sender
     * @param operator address to be approved
     * @param status approval status
     */
    function setApprovalForAll(address operator, bool status) external;

    /**
     * @notice query approval status of given operator with respect to given address
     * @param account address to query for approval granted
     * @param operator address to query for approval received
     * @return status whether operator is approved to spend tokens held by account
     */
    function isApprovedForAll(address account, address operator)
        external
        view
        returns (bool status);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721Internal } from '../../../interfaces/IERC721Internal.sol';

/**
 * @title ERC721 base interface
 */
interface IERC721BaseInternal is IERC721Internal {
    error ERC721Base__NotOwnerOrApproved();
    error ERC721Base__SelfApproval();
    error ERC721Base__BalanceQueryZeroAddress();
    error ERC721Base__ERC721ReceiverNotImplemented();
    error ERC721Base__InvalidOwner();
    error ERC721Base__MintToZeroAddress();
    error ERC721Base__NonExistentToken();
    error ERC721Base__NotTokenOwner();
    error ERC721Base__TokenAlreadyMinted();
    error ERC721Base__TransferToZeroAddress();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title ERC165 interface registration interface
 * @dev see https://eips.ethereum.org/EIPS/eip-165
 */
interface IERC165 {
    /**
     * @notice query whether contract has registered support for given interface
     * @param interfaceId interface id
     * @return bool whether interface is supported
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

/**
 * @title Partial ERC721 interface needed by internal functions
 */
interface IERC721Internal {
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    event Approval(
        address indexed owner,
        address indexed operator,
        uint256 indexed tokenId
    );

    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721MetadataInternal } from './IERC721MetadataInternal.sol';

/**
 * @title ERC721Metadata interface
 */
interface IERC721Metadata is IERC721MetadataInternal {
    /**
     * @notice get token name
     * @return token name
     */
    function name() external view returns (string memory);

    /**
     * @notice get token symbol
     * @return token symbol
     */
    function symbol() external view returns (string memory);

    /**
     * @notice get generated URI for given token
     * @return token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.8;

import { IERC721BaseInternal } from '../base/IERC721BaseInternal.sol';

/**
 * @title ERC721Metadata internal interface
 */
interface IERC721MetadataInternal is IERC721BaseInternal {
    error ERC721Metadata__NonExistentToken();
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev Provides functions to generate convert numbers to string
 */
library StringNumberUtils {
    function fromInt64(int64 value) internal pure returns (string memory) {
        if (value < 0) {
            uint256 positiveValue = (value == type(int64).min)
                ? uint256(uint64(type(int64).max) + 1) //special case for type(int64).min which can not be converted to uint64 via muliplication to -1
                : uint256(uint64(-1 * value));
            return string(abi.encodePacked("-", Strings.toString(positiveValue)));
        } else {
            return Strings.toString(uint256(uint64(value)));
        }
    }

    function fromInt256(
        int256 value,
        uint8 decimals,
        uint8 precision,
        bool truncate
    ) internal pure returns (string memory) {
        if (value < 0) {
            uint256 positiveValue = (value == type(int256).min)
                ? uint256(type(int256).max + 1) //special case for type(int64).min which can not be converted to uint64 via muliplication to -1
                : uint256(-1 * value);
            return string(abi.encodePacked("-", fromUint256(positiveValue, decimals, precision, truncate)));
        } else {
            return fromUint256(uint256(value), decimals, precision, truncate);
        }
    }

    /**
     * @param value value to convert
     * @param decimals how many decimals the number has
     * @param precision how many decimals we should show (see also truncate)
     * @param truncate if we need to remove zeroes after the last significant digit
     */
    function fromUint256(
        uint256 value,
        uint8 decimals,
        uint8 precision,
        bool truncate
    ) internal pure returns (string memory) {
        require(precision <= decimals, "StringNumberUtils: incorrect precision");
        if (value == 0) return "0";

        if (truncate) {
            uint8 counter;
            uint256 countDigits = value;

            while (countDigits != 0) {
                countDigits /= 10;
                counter++;
            }
            value = value / 10**(counter - precision);
        }

        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        if (digits <= decimals) {
            digits = decimals + 2; //add "0."
        } else {
            digits = digits + 1; //add "."
        }
        uint256 truncateDecimals = decimals - precision;
        uint256 bufferLen = digits - truncateDecimals;
        uint256 dotIndex = bufferLen - precision - 1;
        bytes memory buffer = new bytes(bufferLen);
        uint256 index = bufferLen;
        temp = value / 10**truncateDecimals;
        while (temp != 0) {
            index--;
            if (index == dotIndex) {
                buffer[index] = ".";
                index--;
            }
            buffer[index] = bytes1(uint8(48 + (temp % 10)));
            temp /= 10;
        }
        while (index > 0) {
            index--;
            if (index == dotIndex) {
                buffer[index] = ".";
            } else {
                buffer[index] = "0";
            }
        }
        return string(buffer);
    }
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