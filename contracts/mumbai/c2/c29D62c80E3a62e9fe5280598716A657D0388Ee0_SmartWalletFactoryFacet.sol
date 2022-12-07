// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "./IdentityVerifier.sol";
import "./ApprovalsStorage.sol";
import "./SetupStorage.sol";
import "./StandardApprovalHooksFacet.sol";
import "./smart-wallet/SmartWallet.sol";

contract SmartWalletFactoryFacet is IdentityVerifier {
    using ApprovalsStorage for ApprovalsStorage.Layout;
    using SetupStorage for SetupStorage.Layout;

    event SmartWalletDeployed(uint256 indexed mnft, address wallet, address implementation);
    event SmartWalletEnabled(uint256 indexed mnft, address wallet);
    event SmartWalletDisabled(uint256 indexed mnft, address wallet);

    event ApprovalSet(uint256 indexed mnft, address target, bytes4 selector); // This is copy from ApprovalManagerFacet

    function deploySmartWalletProxy(uint256 mnft, VerifierCredentials[] calldata credentials) external returns (address) {
        verifyAccess(mnft, IRules.Operation.MANAGE_WALLETS, credentials, msg.sender);
        address impl = SetupStorage.layout().smartWalletInstance;
        address payable swc = payable(Clones.clone(impl));
        SmartWallet(swc).initialize(IApprovalVerifier(address(this)), mnft);
        ApprovalsStorage.layout().enableWallet(mnft, swc);
        emit SmartWalletDeployed(mnft, swc, impl);
        emit SmartWalletEnabled(mnft, swc);

        ApprovalsStorage.layout().setApprovalHook(
            mnft, 
            swc, 
            address(0),         // Wildcard for any address
            bytes4(0),          // Wildcard for any method
            IApprovals.ApprovalHook(
                address(0),  // Reference to the current contract (Diamond)
                StandardApprovalHooksFacet.approvalHookAllowAllForMnftOwner.selector, // Approve transfer
                bytes(""),
                bytes("")
            )
        );
        emit ApprovalSet(mnft, address(0), bytes4(0));

        return swc;
    }

    /**
     * @dev This function can be used to enable externally-deployed wallets
     */
    function enableWallet(
        uint256 mnft,
        VerifierCredentials[] calldata credentials,
        address wallet
    ) external {
        verifyAccess(mnft, IRules.Operation.MANAGE_WALLETS, credentials, msg.sender);
        ApprovalsStorage.layout().enableWallet(mnft, wallet);
        emit SmartWalletEnabled(mnft, wallet);
    }

    function disableWallet(
        uint256 mnft,
        VerifierCredentials[] calldata credentials,
        address wallet
    ) external {
        verifyAccess(mnft, IRules.Operation.MANAGE_WALLETS, credentials, msg.sender);
        ApprovalsStorage.layout().disableWallet(mnft, wallet);
        emit SmartWalletDisabled(mnft, wallet);
    }
}

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

library SetupStorage {
    bytes32 internal constant STORAGE_SLOT = keccak256("allianceblock.MetaNFT.utils.SetupStorage");
    struct Layout {
        address smartWalletInstance;
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

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "./TokenReceiverInterface.sol";
import "./EtherReceiver.sol";
import "../IApprovalVerifier.sol";

contract SmartWallet is Initializable, TokenReceiverInterface, EtherReceiver {
    IApprovalVerifier public verifier;
    uint256 public mNFT;

    modifier onlyVerifiedCall() {
        verifier.verifyApproval(mNFT, msg.sender, address(this), address(this), msg.sig, msg.data);
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(IApprovalVerifier _verifier, uint256 _mNFT) external initializer {
        require(address(_verifier) != address(0), "Bad verifier");
        require(_mNFT != 0, "Bad mNFT"); //maybe check if user is owner?
        verifier = _verifier;
        mNFT = _mNFT;
    }

    function setVerifier(IApprovalVerifier newVerifier) external onlyVerifiedCall {
        require(address(newVerifier) != address(0), "Bad verifier");
        verifier = newVerifier;
    }

    function transferOwnership(uint256 newMnft) external onlyVerifiedCall {
        require(newMnft != 0, "Bad mNFT"); //maybe check if user is owner?
        mNFT = newMnft;
    }

    function transferEther(address payable target, uint256 amount) external onlyVerifiedCall {
        target.transfer(amount);
    }

    function executeAction(address target, bytes calldata payload) external returns (bytes memory) {
        verifyAction(target, payload);
        (bool success, bytes memory returnData) = target.call(payload);
        if (!success)
            assembly {
                revert(add(returnData, 32), returnData) // Reverts with an error message from the returnData
            }
        return returnData;
    }

    function verifyAction(address target, bytes calldata payload) internal {
        bytes4 selector = bytes4(payload[:4]);
        require(verifier.verifyApproval(mNFT, address(this), msg.sender, target, selector, payload), "verifyApproval unexpected error");
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@nexeraprotocol/metanft/contracts/interfaces/IMetaNFT.sol";
import "@nexeraprotocol/metanft/contracts/utils/Bytes32Key.sol";
import "../../generic-diamond/BaseSinglePropertyManagerStorage.sol";
import "./IAuthVerifier.sol";
import "./IRules.sol";
import "./IdentityStorage.sol";

contract IdentityVerifier is IRules {
    using IdentityStorage for IdentityStorage.Layout;
    using BaseSinglePropertyManagerStorage for BaseSinglePropertyManagerStorage.Layout;

    struct VerifierCredentials {
        IAuthVerifier verifier;
        IAuthVerifier.Credentials credentials;
    }

    function verifyAccess(
        uint256 mnft,
        Operation op,
        VerifierCredentials[] memory credentials,
        address sender
    ) internal view {
        IdentityStorage.RuleData storage ud = IdentityStorage.layout().ruleData[mnft];
        uint256 ruleNum = ud.operations[op];
        if (ruleNum == 0) {
            // Rule is not set, just verify mNFT ownership
            require(_mnft().ownerOf(mnft) == sender, "access only allowed to owner");
        } else {
            require(verifyRule(mnft, credentials, ud.rules, ruleNum, sender), "access denied");
        }
    }

    /**
     * @dev Verifies the rule
     * @param credentialsList credetials with proof already verified
     * @param mnft id of MetaNFT we are working with
     * @param rules list of rules of the user
     * @param ruleNum number of the rule to verify in the rules array
     * @param sender address of tx sender (eiher msg.sender or metatransaction signer)
     * @return if rule is passed
     */
    function verifyRule(
        uint256 mnft,
        VerifierCredentials[] memory credentialsList,
        AccessRule[] memory rules,
        uint256 ruleNum,
        address sender
    ) internal view returns (bool) {
        require(ruleNum == 0, "wrong rule num");
        require(ruleNum < rules.length, "rule num is too high");
        AccessRule memory ar = rules[ruleNum];
        require(ar.required > 0, "rule not exists");
        uint256 matchedIdentities;
        for (uint256 i = 0; i < ar.identities.length; i++) {
            AccessIdentity memory ai = ar.identities[i];
            if (
                (ai.verifier == address(0xFFfFfFffFFfffFFfFFfFFFFFffFFFffffFfFFFfF) && verifySenderIsAccessIdentityTarget(mnft, ai, sender)) ||
                (
                    hasIdentity(credentialsList, ai) //TODO optimise identity search if possible
                )
            ) {
                matchedIdentities++;
            }
            if (matchedIdentities == ar.required) return true;
        }
        return false;
    }

    function verifySenderIsAccessIdentityTarget(
        uint256 mnft,
        AccessIdentity memory ai,
        address sender
    ) private view returns (bool) {
        address identityTarget = (ai.id == bytes32(0)) ? _mnft().ownerOf(mnft) : Bytes32Key.bytes322address(ai.id);
        return (identityTarget == sender);
    }

    function verifyCredentials(VerifierCredentials[] memory credentialsList) private returns (bool) {
        for (uint256 i = 0; i < credentialsList.length; i++) {
            VerifierCredentials memory vc = credentialsList[i];
            //bool res = vc.verifier.verify(vc.credentials);
            bool res = vc.verifier.verify(vc.credentials, msg.sender);
            if (!res) return false;
        }
        return true;
    }

    function hasIdentity(VerifierCredentials[] memory credentialsList, AccessIdentity memory ai) private pure returns (bool) {
        for (uint256 i = 0; i < credentialsList.length; i++) {
            VerifierCredentials memory vc = credentialsList[i];
            if (address(vc.verifier) != ai.verifier) continue;
            for (uint256 j = 0; j < vc.credentials.ids.length; j++) {
                if (vc.credentials.ids[j] == ai.id) return true;
            }
        }
        return false;
    }

    function _mnft() private view returns (IMetaNFT) {
        return BaseSinglePropertyManagerStorage.layout().mnft;
    }

    function _prop() private view returns (bytes32) {
        return BaseSinglePropertyManagerStorage.layout().prop;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRules.sol";
import "./IApprovals.sol";
import "@solidstate/contracts/utils/EnumerableSet.sol";

library ApprovalsStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes32 internal constant STORAGE_SLOT = keccak256("allianceblock.MetaNFT-PMs.allianceblock.nexera-identity.ApprovalsStorage");

    struct ApprovalData {
        mapping(address => mapping(bytes4 => IApprovals.ApprovalHook)) approvals;
    }

    struct WalletsData {
        EnumerableSet.AddressSet wallets;
        mapping(address => ApprovalData) approvalData;
    }

    struct Layout {
        mapping(uint256 => WalletsData) walletsData; // Mapping of MNFT to user wallets & approvals data
    }

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function isWalletEnabled(
        Layout storage l,
        uint256 mnft,
        address wallet        
    ) internal view returns(bool) {
        return l.walletsData[mnft].wallets.contains(wallet);
    }

    function enableWallet(
        Layout storage l,
        uint256 mnft,
        address wallet
    ) internal {
        l.walletsData[mnft].wallets.add(wallet);
    }

    function disableWallet(
        Layout storage l,
        uint256 mnft,
        address wallet
    ) internal {
        l.walletsData[mnft].wallets.remove(wallet);
    }

    function getApprovalData(
        Layout storage l,
        uint256 mnft,
        address wallet
    ) internal view returns (ApprovalData storage) {
        require(l.walletsData[mnft].wallets.contains(wallet), "wallet not enabled");
        return l.walletsData[mnft].approvalData[wallet];
    }

    function setApprovalHook(
        Layout storage l,
        uint256 mnft,
        address wallet,
        address target,
        bytes4 selector,
        IApprovals.ApprovalHook memory ah
    ) internal {
        require(l.walletsData[mnft].wallets.contains(wallet), "wallet not enabled");
        ApprovalData storage ad = l.walletsData[mnft].approvalData[wallet];
        ad.approvals[target][selector] = ah;
    }

    function deleteApprovalHook(
        Layout storage l,
        uint256 mnft,
        address wallet,
        address target,
        bytes4 selector
    ) internal {
        require(l.walletsData[mnft].wallets.contains(wallet), "wallet not enabled");
        ApprovalData storage ad = l.walletsData[mnft].approvalData[wallet];
        delete ad.approvals[target][selector];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

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
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
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
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
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
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IMetaToken.sol";
import "./IMetaTokenMetadata.sol";
import "./IMetaProperties.sol";
import "./IMetaRestrictions.sol";
import "./IMetaGlobalData.sol";

interface IMetaNFT is IMetaToken, IMetaTokenMetadata, IMetaProperties, IMetaRestrictions, IMetaGlobalData {}

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

import "@solidstate/contracts/token/ERC721/metadata/IERC721Metadata.sol";

interface IMetaTokenMetadata is IERC721Metadata {

    function contractURI() external view returns (string memory);

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IApprovalVerifier {
    /**
     * @notice Verifies and updates approval
     * @dev will revert if approval check fails
     * @param mnft MetaNFT to check
     * @param sender of the call
     * @param wallet to work with
     * @param target target contract of the call
     * @param message message sent to the target
     * @return shoud always return true or revert
     */
    function verifyApproval(
        uint256 mnft,
        address sender,
        address wallet,
        address target,
        bytes4 selector,
        bytes calldata message
    ) external returns(bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import "@openzeppelin/contracts/interfaces/IERC777Recipient.sol";
import "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";

contract TokenReceiverInterface is IERC165, IERC721Receiver, IERC777Recipient, IERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC1155Receiver.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function tokensReceived(
        address,
        address,
        address,
        uint256,
        bytes calldata,
        bytes calldata
    ) external pure override {
        // required for IERC777Receiver
    }

    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(IERC721Receiver).interfaceId ||
            interfaceId == type(IERC777Recipient).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EtherReceiver {
    event EtherReceived(address indexed sender, uint256 value);

    receive() external payable {
        emit EtherReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC777Recipient.sol)

pragma solidity ^0.8.0;

import "../token/ERC777/IERC777Recipient.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155Receiver.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC777/IERC777Recipient.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC777TokensRecipient standard as defined in the EIP.
 *
 * Accounts can be notified of {IERC777} tokens being sent to them by having a
 * contract implement this interface (contract holders can be their own
 * implementer) and registering it on the
 * https://eips.ethereum.org/EIPS/eip-1820[ERC1820 global registry].
 *
 * See {IERC1820Registry} and {ERC1820Implementer}.
 */
interface IERC777Recipient {
    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IRules {
    struct AccessIdentity {
        address verifier; // Address of verifier. 0x00 means it's not a verifier but a reference
        //   to another AccessRule (id is position of the rule in the rule array, should not be 0).
        //   0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF means id is an address (zero-padded on the right)
        //   and is verified externally (by transaction signature or meta=transaction's TrustedVerifier)
        //   if address in such rule is 0x00 that is the reference to current MetaNFT owner
        bytes32 id; // Id assigned by the verifier (should always be the same for the same user)
    }

    struct AccessRule {
        uint256 required; // Amount of identities required for access
        AccessIdentity[] identities; // List of access identities available in this rule
    }

    enum Operation {
        MANAGE_RULES, // Manage list of authetication rules
        MANAGE_APPROVALS, // Manage approvals,
        MANAGE_WALLETS, // Deploy, disable and enable Smart-Wallets
        MNFT_OWNER_RECOVERY // Transfer MetaNFT to a new owner in case of recovery
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IRules.sol";
import "./IApprovals.sol";
import "@solidstate/contracts/utils/EnumerableSet.sol";

library IdentityStorage {
    using EnumerableSet for EnumerableSet.AddressSet;
    bytes32 internal constant STORAGE_SLOT = keccak256("allianceblock.MetaNFT-PMs.allianceblock.nexera-identity.IdentityStorage");

    struct RuleData {
        IRules.AccessRule[] rules; // Array of Rules. Rule 0 is always empty and should not be used.
        // Rule with both verifier and id == 0 means it was deleted
        mapping(IRules.Operation => uint256) operations;
    }

    struct Layout {
        mapping(uint256 => RuleData) ruleData; // Mapping of mNFT id to user rules data
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

/**
 * @title Interface for Authentication Verifiers
 * @notice This contract is used by Identity PM to verify the authentication proof
 * generated by some off-chain process and provide to the PM by the user
 */
interface IAuthVerifier {
    /**
     * Authentication data to be verified by the AuthVerifier
     * Includes a list of identifiers used to sign-in and a proof
     * that user was actually successfuly signed in
     */
    struct Credentials {
        bytes32[] ids; // List of the identifiers user is claiming to be authentified with
        bytes proof; // Proof which should be verified by the Verifier
    }

    /**
     * @notice Verifies the proof is valid for specified idetifiers
     * @param credentials to verify
     * @param sender sender of transaction (either msg.sender or sender verified by Trusted verifier)
     * @return if the proof is valid for all identifiers provided
     */
    function verify(Credentials memory credentials, address sender) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Bytes32Key {
    bytes32 private constant MAX_BYTES32_ADDRESS = bytes32(uint256(type(uint160).max)); // 0x000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
    bytes32 private constant MAX_BYTES32_UINT248 = bytes32(uint256(type(uint248).max)); // 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

    // ==== Conversions between common key types ====
    function address2bytes32(address a) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(a)));
    }

    function bytes322address(bytes32 b) internal pure returns (address) {
        require(b & MAX_BYTES32_ADDRESS == b, "bytes32 to address conversion fail");
        return address(uint160(uint256(b)));
    }

    function uint2482bytes32(uint248 v) internal pure returns (bytes32) {
        return bytes32(uint256(v));
    }

    function bytes322uint248(bytes32 v) internal pure returns (uint248) {
        require(v & MAX_BYTES32_UINT248 == v, "bytes32 to uint248 conversion fail");
        return uint248(uint256(v));
    }

    function uint2562uint248(uint256 v) internal pure returns (uint248) {
        require(v <= type(uint248).max, "uint248 conversion fail");
        return uint248(v);
    }

    // ==== Partitioning tools ====

    /**
     * @notice Internal convert address to a partitioned key
     * @param partition Partition
     * @param account Address to convert
     * @return byte32 key
     */
    function partitionedKeyForAddress(uint8 partition, address account) internal pure returns (bytes32) {
        bytes32 p = bytes32(bytes1(partition));
        bytes32 v = bytes32(uint256(uint160(account)));
        return p | v;
    }

    /**
     * @notice Internal convert address to a partitioned key
     * @param partition Partition
     * @param value Value to convert
     * @return byte32 key
     */
    function partitionedKeyForUint248(uint8 partition, uint248 value) internal pure returns (bytes32) {
        bytes32 p = bytes32(bytes1(partition));
        bytes32 v = bytes32(uint256(value));
        return p | v;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IApprovals {
    struct ApprovalHook {
        address target; // Address of the contract to call verifier rule. 0x00 means this (Identity PM) facet
        bytes4 selector; // Selector of the hook to call, arguments of the call to this method will be
        //   - uint256 mnft - MetaNFT id to work with
        //   - address sender - sender of the message
        //   - address target - target contract
        //   - bytes message  - original message to the target (starting with selector)
        //   - bytes initialHookData
        //   - bytes actualHookData
        // so the method definition should look like
        // function hookName(bytes calldata callData, bytes calldata initialHookData, bytes actualHookData) external returns(bytes calldata newActualHookData);
        bytes initialData; // Data stored in the Approval, for example approved amount
        bytes actualData; // Data returned by the last hook call, for exammple approved amount already used
    }

    // struct Approval {
    //     address target;         // Traget contract which requires approval to send message to, zero addres is wildcard for all contracts
    //     bytes4 selector;        // Target method selector, 0x00000000 is wildcard selector used if there is no rule for specific selector
    //     ApprovalHook hook;      // Hook data to call on the call to a target
    // }
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