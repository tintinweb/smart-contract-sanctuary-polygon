//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ItemHeaderLib } from "./ItemHeaderLib.sol";
import { RgLib } from "./RgLib.sol";
import { RgLibView } from "./RgLibView.sol";

contract Registry is Initializable, OwnableUpgradeable, EIP712Upgradeable {
    using ECDSAUpgradeable for bytes32;

    event LocalDeviceDrafted(address indexed account, bytes32 indexed accountSigningPublicKey, bytes32 indexed deviceSigningPublicKey);
    event LocalDeviceDisapproved(address indexed account, bytes32 indexed accountSigningPublicKey, bytes32 indexed deviceSigningPublicKey, bytes32 approvingDeviceSigningPublicKey);

    event AccountRegistered(address indexed account, bytes32 indexed accountSigningPublicKey, bytes32 indexed deviceSigningPublicKey);
    event AccountKeyUpdated(address indexed account, bytes32 indexed accountSigningPublicKey, bytes32 indexed revokedAccountSigningPublicKey);
    event DeviceRegistered(address indexed account, bytes32 indexed accountSigningPublicKey, bytes32 indexed deviceSigningPublicKey);
    event DeviceRevoked(address indexed account, bytes32 indexed accountSigningPublicKey, bytes32 indexed revokedDeviceSigningPublicKey);

    // States

    /* solhint-disable var-name-mixedcase */
    bytes32 constant private _REGISTER_ACCOUNT_TYPE_HASH = keccak256(
        "RegisterAccount(address to,bytes signature,bytes32 accountSigningPublicKey,bytes32 accountEncryptionPublicKey,bytes32 deviceSigningPublicKey,bytes32 deviceEncryptionPublicKey,bytes seeds)"
    );
    bytes32 constant private _REGISTER_DEVICE_TYPE_HASH = keccak256(
        "RegisterDevice(address to,uint index,bytes32 signerDevicePublicKey,bytes signature,bytes32 accountSigningPublicKey,bytes32 accountEncryptionPublicKey,bytes32 deviceSigningPublicKey,bytes32 deviceEncryptionPublicKey,bytes seeds)"
    );

    // Mappers
    mapping(address => RgLib.Account) private accountRecords;
    mapping(bytes32 => address) private publicKeyRecords;

    // Initialize
    function initialize() public initializer {
        // Initializes the contract setting the deployer as the initial owner.
        __Ownable_init();

        // Initializes the domain separator and parameter caches
        __EIP712_init("Registry", "1");
    }

    // Register Account
    // signature = sign-by-device ==> ['registry', address, 0, 100, accountSigningPublicKey, accountEncryptionPublicKey, deviceSigningPublicKey, deviceEncryptionPublicKey]
    function registerAccount(
        bytes memory signature,
        RgLib.PubKeyBundle memory accountPubKey,
        RgLib.PubKeyBundle memory devicePubKey,
        RgLib.DeviceNameAndHash memory deviceNameAndHash,
        bytes memory boxedSeed
    ) public {
        RgLib.LocalCommonVars memory vars = RgLib.LocalCommonVars(
            0,
            devicePubKey.signingPublicKey, signature,
            accountPubKey.signingPublicKey, accountPubKey.encryptionPublicKey,
            devicePubKey.signingPublicKey, devicePubKey.encryptionPublicKey,
            deviceNameAndHash.deviceName, deviceNameAndHash.deviceNameHash
        );

        _registerAccount(msg.sender, vars, boxedSeed);
    }

    // Register Account by Admin
    // signature = sign-by-device ==> ['registry', address, 0, 100, accountSigningPublicKey, accountEncryptionPublicKey, deviceSigningPublicKey, deviceEncryptionPublicKey]
    function registerAccountByAdmin(
        address account, bytes memory txSignature,
        bytes memory signature,
        RgLib.PubKeyBundle memory accountPubKey,
        RgLib.PubKeyBundle memory devicePubKey,
        RgLib.DeviceNameAndHash memory deviceNameAndHash,
        bytes memory boxedSeed
    ) public onlyOwner {
        RgLib.LocalCommonVars memory vars = RgLib.LocalCommonVars(
            0,
            devicePubKey.signingPublicKey, signature,
            accountPubKey.signingPublicKey, accountPubKey.encryptionPublicKey,
            devicePubKey.signingPublicKey, devicePubKey.encryptionPublicKey,
            deviceNameAndHash.deviceName, deviceNameAndHash.deviceNameHash
        );
        require(
            _verifyRegisterAccount(account, txSignature, vars, boxedSeed),
            "Invalid signature"
        );
        _registerAccount(account, vars, boxedSeed);
    }

    // Register Device
    // signature => approver-device ==> ['registry', address, <newindex>, 101, accountSigningPublicKey, accountEncryptionPublicKey, deviceSigningPublicKey, deviceEncryptionPublicKey]
    function registerDevice(
        uint index,
        bytes32 signerDevicePublicKey, bytes memory signature,
        RgLib.PubKeyBundle memory accountPubKey,
        RgLib.PubKeyBundle memory devicePubKey,
        RgLib.DeviceNameAndHash memory deviceNameAndHash,
        bytes memory boxedSeed
    ) public {
        RgLib.LocalCommonVars memory vars = RgLib.LocalCommonVars(
            index,
            signerDevicePublicKey, signature,
            accountPubKey.signingPublicKey, accountPubKey.encryptionPublicKey,
            devicePubKey.signingPublicKey, devicePubKey.encryptionPublicKey,
            deviceNameAndHash.deviceName, deviceNameAndHash.deviceNameHash
        );

        _registerDevice(msg.sender, index,
            vars,
            boxedSeed);
    }

    // Register Device By Admin
    // signature => approver-device ==> ['registry', address, <newindex>, 101, accountSigningPublicKey, accountEncryptionPublicKey, deviceSigningPublicKey, deviceEncryptionPublicKey]
    function registerDeviceByAdmin(
        address account, bytes memory txSignature,
        uint index,
        bytes32 signerDevicePublicKey, bytes memory signature,
        RgLib.PubKeyBundle memory accountPubKey,
        RgLib.PubKeyBundle memory devicePubKey,
        RgLib.DeviceNameAndHash memory deviceNameAndHash,
        bytes memory boxedSeed
    ) public onlyOwner {
        RgLib.LocalCommonVars memory vars = RgLib.LocalCommonVars(
            index,
            signerDevicePublicKey, signature,
            accountPubKey.signingPublicKey, accountPubKey.encryptionPublicKey,
            devicePubKey.signingPublicKey, devicePubKey.encryptionPublicKey,
            deviceNameAndHash.deviceName, deviceNameAndHash.deviceNameHash
        );

        require(
            _verifyRegisterDevice(
                account, txSignature,
                index,
                signerDevicePublicKey, signature,
                accountPubKey.signingPublicKey, accountPubKey.encryptionPublicKey,
                devicePubKey.signingPublicKey, devicePubKey.encryptionPublicKey,
                boxedSeed
            ),
            "Invalid signature"
        );
        _registerDevice(account, index, vars, boxedSeed);
    }

    // signature => new-device ==> ['registry', address, <newindex>, 1, accountSigningPublicKey, accountEncryptionPublicKey, deviceSigningPublicKey, deviceEncryptionPublicKey]
    function addDraftDevice(
        uint index,
        bytes32 signerDevicePublicKey, bytes memory signature,
        RgLib.PubKeyBundle memory accountPubKey,
        RgLib.PubKeyBundle memory devicePubKey,
        RgLib.DeviceNameAndHash memory deviceNameAndHash
    ) public {
        RgLib.LocalCommonVars memory vars = RgLib.LocalCommonVars(
            index,
            signerDevicePublicKey, signature,
            accountPubKey.signingPublicKey, accountPubKey.encryptionPublicKey,
            devicePubKey.signingPublicKey, devicePubKey.encryptionPublicKey,
            deviceNameAndHash.deviceName, deviceNameAndHash.deviceNameHash
        );

        _addDraftDevice(msg.sender, index, vars);
    }

    function getRawSignatureChains(address account, uint offset, uint size) public view returns (RgLib.SigChainItem[] memory) {
        RgLib.SigChainItem[] storage accItems = accountRecords[account].items;
        return RgLibView.getRawSignatureChains(accItems, offset, size);
    }

    function getSignatureChainsLength(address account) public view returns (uint) {
        return accountRecords[account].items.length;
    }

    function getAccountAddress(bytes32 publicKey) public view returns (address) {
        return publicKeyRecords[publicKey];
    }

    // return latest active account public keys
    function getAccountPublicKeys(address account) public view returns (RgLib.PublicKeyBundle memory bundle) {
        RgLib.SigChainItem[] storage accItems = accountRecords[account].items;
        return RgLibView.getAccountPublicKeys(accItems);
    }

    function getDevices(address account, bool populateDeviceNames, bool populateSigners) public view returns (RgLib.DeviceInfo[] memory devices) {
        RgLib.SigChainItem[] storage accItems = accountRecords[account].items;
        return RgLibView.getDevices(accItems, populateDeviceNames, populateSigners);
    }

    function getDraftDevices() public view returns (RgLib.DeviceInfo[] memory devices) {
        address account = msg.sender;
        RgLib.SigChainItem[] storage accItems = accountRecords[account].items;
        return RgLibView.getDraftDevices(accItems);
    }

    function getVaultSeeds() public view returns(RgLib.SeedItem[] memory) {
        return accountRecords[msg.sender].seedItems;
    }

    // Private Functions

    function _registerAccount(
        address account,
        RgLib.LocalCommonVars memory vars,
        bytes memory boxedSeed
    ) private {
        require(accountRecords[account].items.length == 0, "Account Address already registered");
        require(publicKeyRecords[vars.signingPublicKey] == address(0), "Account PublicKey already registered");
        require(publicKeyRecords[vars.encryptionPublicKey] == address(0), "Account PublicKey already registered");
        require(publicKeyRecords[vars.deviceSigningPublicKey] == address(0), "Device PublicKey already registered");
        require(publicKeyRecords[vars.deviceEncryptionPublicKey] == address(0), "Device PublicKey already registered");

        RgLib.Account storage acct = accountRecords[account];
        acct.items.push();
        RgLib.SigChainItem storage item = acct.items[0];

        item.itemHeader = ItemHeaderLib.packHeader(uint8(1), uint64(block.timestamp), uint16(RgLib.SIG_ACTION_NEW_ACCOUNT));

        item.signerDevicePublicKey = vars.deviceSigningPublicKey; // registration is self-signed
        item.signedAction = vars.signedAction;

        item.signingPublicKey = vars.signingPublicKey;
        item.encryptionPublicKey = vars.encryptionPublicKey;
        item.deviceSigningPublicKey = vars.deviceSigningPublicKey;
        item.deviceEncryptionPublicKey = vars.deviceEncryptionPublicKey;
        item.deviceName = vars.deviceName;
        item.deviceNameHash = vars.deviceNameHash;
        if (keccak256(boxedSeed) != keccak256("")) {
            acct.seedItems.push();
            RgLib.SeedItem storage sItem = acct.seedItems[acct.seedItems.length-1];
            sItem.signingPublicKey = vars.signingPublicKey;
            sItem.encryptionPublicKey = vars.encryptionPublicKey;
            sItem.signerDevicePublicKey = vars.signerDevicePublicKey;
            sItem.seeds.push(boxedSeed);
        }

        publicKeyRecords[vars.signingPublicKey] = account;
        publicKeyRecords[vars.encryptionPublicKey] = account;
        publicKeyRecords[vars.deviceSigningPublicKey] = account;
        publicKeyRecords[vars.deviceEncryptionPublicKey] = account;

        emit AccountRegistered(account, vars.signingPublicKey, vars.deviceSigningPublicKey);
        emit DeviceRegistered(account, vars.signingPublicKey, vars.deviceSigningPublicKey);
    }

    function _verifyRegisterAccount(
        address account, bytes memory txSignature,
        RgLib.LocalCommonVars memory vars,
        bytes memory boxedSeed
    ) private view returns (bool isValid) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(_REGISTER_ACCOUNT_TYPE_HASH,
            account, keccak256(vars.signedAction),
            vars.signingPublicKey, vars.encryptionPublicKey,
            vars.deviceSigningPublicKey, vars.deviceEncryptionPublicKey,
            keccak256(boxedSeed)
            ))
        );
        return ECDSAUpgradeable.recover(digest, txSignature) == account;
    }

    function _registerDevice(
        address account, uint index,
        RgLib.LocalCommonVars memory vars,
        bytes memory boxedSeed
    ) private {
        RgLib.SigChainItem[] storage acctItems = accountRecords[account].items;
        require(acctItems.length > 0, "Account does not exist");
        require(acctItems.length == index-1, "Mismatched SigChain length");
        require(publicKeyRecords[vars.deviceSigningPublicKey] == address(0), "Device PublicKey already registered");
        require(publicKeyRecords[vars.deviceEncryptionPublicKey] == address(0), "Device PublicKey already registered");
        _registerDeviceCheck(account, vars);

        acctItems.push();

        RgLib.SigChainItem storage item = acctItems[acctItems.length - 1];

        item.itemHeader = ItemHeaderLib.packHeader(uint8(1), uint64(block.timestamp), RgLib.SIG_ACTION_REGISTER_DEVICE);

        item.signerDevicePublicKey = vars.signerDevicePublicKey;
        item.signedAction = vars.signedAction;
        item.signingPublicKey = vars.signingPublicKey;
        item.encryptionPublicKey = vars.encryptionPublicKey;
        item.deviceSigningPublicKey = vars.deviceSigningPublicKey;
        item.deviceEncryptionPublicKey = vars.deviceEncryptionPublicKey;
        item.deviceName = vars.deviceName;
        item.deviceNameHash = vars.deviceNameHash;

        if (keccak256(boxedSeed) != keccak256("")) {
            RgLib.SeedItem[] storage seedItems = accountRecords[account].seedItems;
            seedItems.push();
            RgLib.SeedItem storage seedItem = seedItems[seedItems.length - 1];
            seedItem.signingPublicKey = vars.signingPublicKey;
            seedItem.encryptionPublicKey = vars.encryptionPublicKey;
            seedItem.signerDevicePublicKey = vars.signerDevicePublicKey;
            seedItem.seeds.push(boxedSeed);
        }

        publicKeyRecords[vars.deviceSigningPublicKey] = account;
        publicKeyRecords[vars.deviceEncryptionPublicKey] = account;

        emit DeviceRegistered(account, vars.signingPublicKey, vars.deviceSigningPublicKey);
    }

    function _registerDeviceCheck(address account, RgLib.LocalCommonVars memory vars) private view returns (bool) {
        RgLib.SigChainItem[] storage acctItems = accountRecords[account].items;

        uint itemLength = acctItems.length;
        bool deviceKeyFound = false;
        bool deviceNameFound = false;
        for(uint i = 0; i < itemLength; i++) {
            RgLib.SigChainItem storage dvItem = acctItems[i];
            if (ItemHeaderLib.unpackAction(dvItem.itemHeader) == RgLib.SIG_ACTION_LOCAL_DISAPPROVE_DEVICE
            || ItemHeaderLib.unpackAction(dvItem.itemHeader) == RgLib.SIG_ACTION_REGISTER_DEVICE
            || ItemHeaderLib.unpackAction(dvItem.itemHeader) == RgLib.SIG_ACTION_NEW_ACCOUNT
            ) {
                if (vars.deviceSigningPublicKey == dvItem.deviceSigningPublicKey
                || vars.deviceSigningPublicKey == dvItem.deviceEncryptionPublicKey
                || vars.deviceSigningPublicKey == dvItem.signingPublicKey
                || vars.deviceSigningPublicKey == dvItem.encryptionPublicKey
                || vars.deviceEncryptionPublicKey == dvItem.deviceSigningPublicKey
                || vars.deviceEncryptionPublicKey == dvItem.deviceEncryptionPublicKey
                || vars.deviceEncryptionPublicKey == dvItem.signingPublicKey
                || vars.deviceEncryptionPublicKey == dvItem.encryptionPublicKey
                ) {
                    deviceKeyFound = true;
                    break;
                }
                if (vars.deviceNameHash == dvItem.deviceNameHash) {
                    deviceNameFound = true;
                    break;
                }
            }
        }
        require(!deviceKeyFound, "Duplicated Device PublicKey");
        require(!deviceNameFound, "Duplicated Device Name");
        return true;
    }

    function _verifyRegisterDevice(
        address account, bytes memory txSignature,
        uint index,
        bytes32 signerDevicePublicKey, bytes memory signature,
        bytes32 accountSigningPublicKey, bytes32 accountEncryptionPublicKey,
        bytes32 deviceSigningPublicKey, bytes32 deviceEncryptionPublicKey,
        bytes memory boxedSeed
    ) private view returns (bool isValid) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(_REGISTER_DEVICE_TYPE_HASH,
            account, index, signerDevicePublicKey, keccak256(signature),
            accountSigningPublicKey, accountEncryptionPublicKey,
            deviceSigningPublicKey, deviceEncryptionPublicKey,
            keccak256(boxedSeed)
            ))
        );
        return ECDSAUpgradeable.recover(digest, txSignature) == account;
    }

    function _addDraftDevice(
        address account, uint index,
        RgLib.LocalCommonVars memory vars
    ) private {
        RgLib.SigChainItem[] storage acctItems = accountRecords[account].items;
        require(acctItems.length > 0, "Account does not exist");
        require(acctItems.length == index-1, "Mismatched SigChain length");
        require(publicKeyRecords[vars.deviceSigningPublicKey] == address(0), "Device PublicKey already registered");
        require(publicKeyRecords[vars.deviceEncryptionPublicKey] == address(0), "Device PublicKey already registered");

        acctItems.push();
        RgLib.SigChainItem storage item = acctItems[acctItems.length - 1];

        item.itemHeader = ItemHeaderLib.packHeader(1, uint64(block.timestamp), RgLib.SIG_ACTION_LOCAL_ADD_DEVICE);

        item.signerDevicePublicKey = vars.signerDevicePublicKey;
        item.signedAction = vars.signedAction;
        item.signingPublicKey = vars.signingPublicKey;
        item.encryptionPublicKey = vars.encryptionPublicKey;
        item.deviceSigningPublicKey = vars.deviceSigningPublicKey;
        item.deviceEncryptionPublicKey = vars.deviceEncryptionPublicKey;
        item.deviceName = vars.deviceName;
        item.deviceNameHash = vars.deviceNameHash;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library ItemHeaderLib {
    function unpackHeader(uint256 itemHeader) public pure returns (uint8, uint64, uint16) {
        return (
            uint8((itemHeader >> (8 * 31)) & 0xff),
            uint64((itemHeader >> (8 * 23)) & 0xffffffffffffffff),
            uint16((itemHeader >> (8 * 21)) & 0xffff)
        );
    }

    function unpackVersion(uint256 itemHeader) public pure returns (uint8) {
        return uint8((itemHeader >> (8 * 31)) & 0xff);
    }

    function unpackTimestamp(uint256 itemHeader) public pure returns (uint64) {
        return uint64((itemHeader >> (8 * 23)) & 0xffffffffffffffff);
    }


    function unpackAction(uint256 itemHeader) public pure returns (uint16) {
        return uint16((itemHeader >> (8 * 21)) & 0xffff);
    }

    function packHeader(uint8 version, uint64 timestamp, uint16 action) public pure returns (uint256) {
        return (uint256(version) << (8 * 31)) + (uint256(timestamp) << (8 * 23)) + (uint256(action) << (8 * 21));
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ItemHeaderLib } from "./ItemHeaderLib.sol";
import { RgLib } from "./RgLib.sol";

library RgLibView {

    function getRawSignatureChains(RgLib.SigChainItem[] storage accItems, uint offset, uint size) public view returns (RgLib.SigChainItem[] memory) {
        require(offset >= 0, "offset must be non-negative");
        if (size <= 0) {
            size = accItems.length;
        }
        if (offset + size > accItems.length) {
            size = accItems.length - offset;
        }
        RgLib.SigChainItem[] memory items = new RgLib.SigChainItem[](size);
        uint itemLength = accItems.length;
        for(uint i = 0; (i+offset) < itemLength && i < size; i++) {
            items[i] = accItems[i+offset];
        }
        return items;
    }

    // return latest active account public keys
    function getAccountPublicKeys(RgLib.SigChainItem[] storage accItems) public view returns (RgLib.PublicKeyBundle memory bundle) {
        if (accItems.length == 0) { return bundle; }

        uint itemLength = accItems.length;
        for(uint i = itemLength-1; i >= 0; i--) {
            RgLib.SigChainItem storage item = accItems[i];
            if (ItemHeaderLib.unpackAction(item.itemHeader) == RgLib.SIG_ACTION_NEW_ACCOUNT
            || ItemHeaderLib.unpackAction(item.itemHeader) == RgLib.SIG_ACTION_UPDATE_ACCOUNT_KEYS
            ) {
                bundle.timestamp = ItemHeaderLib.unpackTimestamp(item.itemHeader);
                bundle.version = ItemHeaderLib.unpackVersion(item.itemHeader);
                bundle.signingPublicKey = item.signingPublicKey;
                bundle.encryptionPublicKey = item.encryptionPublicKey;
                return bundle;
            }
        }
    }

    function getDevices(RgLib.SigChainItem[] storage accItems, bool populateDeviceNames, bool populateSigners) public view returns (RgLib.DeviceInfo[] memory devices) {
        if (accItems.length == 0) { return devices; }

        uint itemLength = accItems.length;
        uint deviceCount = 0;
        for(uint i = 0; i < itemLength; i++) {
            RgLib.SigChainItem storage item = accItems[i];
            if (ItemHeaderLib.unpackAction(item.itemHeader) == RgLib.SIG_ACTION_NEW_ACCOUNT
            || ItemHeaderLib.unpackAction(item.itemHeader) == RgLib.SIG_ACTION_REGISTER_DEVICE
            ) {
                deviceCount++;
            }
        }

        devices = new RgLib.DeviceInfo[](deviceCount);
        uint di = 0;
        for(uint i = 0; i < itemLength; i++) {
            RgLib.SigChainItem storage item = accItems[i];
            if (ItemHeaderLib.unpackAction(item.itemHeader) != RgLib.SIG_ACTION_NEW_ACCOUNT
            && ItemHeaderLib.unpackAction(item.itemHeader) != RgLib.SIG_ACTION_REGISTER_DEVICE
            ) {
                continue;
            }
            RgLib.DeviceInfo memory dev = devices[di];
            di++;
            dev.timestamp = ItemHeaderLib.unpackTimestamp(item.itemHeader);
            dev.version = ItemHeaderLib.unpackVersion(item.itemHeader);
            dev.signingPublicKey = item.signingPublicKey;
            dev.encryptionPublicKey = item.encryptionPublicKey;
            dev.deviceSigningPublicKey = item.deviceSigningPublicKey;
            dev.deviceEncryptionPublicKey = item.deviceEncryptionPublicKey;
            if (populateDeviceNames) {
                dev.deviceName = item.deviceName;
                dev.deviceNameHash = item.deviceNameHash;
            }
            if (populateSigners) {
                dev.signerDevicePublicKey = item.signerDevicePublicKey;
                dev.signedAction = item.signedAction;
            }

            for(uint j = i+1; j < itemLength; j++) {
                RgLib.SigChainItem storage rvItem = accItems[j];
                if (ItemHeaderLib.unpackAction(rvItem.itemHeader) == RgLib.SIG_ACTION_UPDATE_ACCOUNT_KEYS) {
                    for(uint k = 0; i < rvItem.revokedKeys.length; k++) {
                        if (rvItem.revokedKeys[k] == dev.deviceSigningPublicKey || rvItem.revokedKeys[k] == dev.deviceEncryptionPublicKey) {
                            dev.isRevoked = true;
                            dev.revokedTimestamp = ItemHeaderLib.unpackTimestamp(rvItem.itemHeader);
                            break;
                        }
                    }
                }
            }
        }
    }

    function getDraftDevices(RgLib.SigChainItem[] storage accItems) public view returns (RgLib.DeviceInfo[] memory devices) {
        if (accItems.length == 0) { return devices; }

        uint itemLength = accItems.length;
        uint deviceCount = 0;
        for(uint i = 0; i < itemLength; i++) {
            RgLib.SigChainItem storage item = accItems[i];
            if (ItemHeaderLib.unpackAction(item.itemHeader) == RgLib.SIG_ACTION_NEW_ACCOUNT
            || ItemHeaderLib.unpackAction(item.itemHeader) == RgLib.SIG_ACTION_REGISTER_DEVICE
            ) {
                deviceCount++;
            }
        }
        uint[] memory draftIxs = new uint[](deviceCount);
        bytes32[] memory draftPks = new bytes32[](deviceCount);
        uint drafti = 0;
        for(uint i = 0; i < itemLength; i++) {
            RgLib.SigChainItem storage item = accItems[i];
            if (ItemHeaderLib.unpackAction(item.itemHeader) == RgLib.SIG_ACTION_LOCAL_ADD_DEVICE) {
                draftPks[drafti] = item.deviceSigningPublicKey;
                draftIxs[drafti] = drafti;
                drafti++;
            }
            else if (ItemHeaderLib.unpackAction(item.itemHeader) == RgLib.SIG_ACTION_NEW_ACCOUNT
            || ItemHeaderLib.unpackAction(item.itemHeader) == RgLib.SIG_ACTION_REGISTER_DEVICE
            ) {
                for(uint chki = 0; chki < drafti; chki++) {
                    if (item.deviceSigningPublicKey == draftPks[chki]) {
                        draftPks[chki] = draftPks[drafti-1];
                        draftPks[drafti-1] = 0;
                        draftIxs[chki] = draftIxs[drafti-1];
                        draftIxs[drafti-1] = 0;
                        drafti--;
                        break;
                    }
                }
            }
        }

        devices = new RgLib.DeviceInfo[](drafti);
        for(uint i = 0; i < drafti; i++) {
            RgLib.SigChainItem storage item = accItems[draftIxs[i]];
            devices[i].timestamp = ItemHeaderLib.unpackTimestamp(item.itemHeader);
            devices[i].version = ItemHeaderLib.unpackVersion(item.itemHeader);
            devices[i].signingPublicKey = item.signingPublicKey;
            devices[i].encryptionPublicKey = item.encryptionPublicKey;
            devices[i].deviceSigningPublicKey = item.deviceSigningPublicKey;
            devices[i].deviceEncryptionPublicKey = item.deviceEncryptionPublicKey;
            devices[i].deviceName = item.deviceName;
            devices[i].deviceNameHash = item.deviceNameHash;
            devices[i].signerDevicePublicKey = item.signerDevicePublicKey;
            devices[i].signedAction = item.signedAction;
        }
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library RgLib {

    struct Account {
        SigChainItem[] items;
        SeedItem[] seedItems;
        uint256[6] _reserved;
    }

    struct SeedItem {
        bytes32 signerDevicePublicKey;

        bytes32 signingPublicKey; // if action==11|12|100|111 new ed25519 signing key of account
        bytes32 encryptionPublicKey; // if action==11|12|100|111, new x25519 encryption key

        bytes previousSeed;
        // if action=111, nonce|nacl.secretBox(previousSi, newSeed)

        bytes[] seeds;
        // if action==111, array of deviceSigningPublicKey|nonce|nacl.box(account-seed, deviceEncryptionPublicKey, newEncryptionPrivateKey).
        // if action==100|101, the array will only contain the one for new device
    }

    struct SigChainItem {
        uint itemHeader;
        // 1 = add draft device (to be approve)
        // 2 = disapprove draft device
        // 11 = add vault account key for devices
        // 12 = manual seeds saving
        // 100 = create new account address
        // 101 = publish device key
        // 111 = publish new account key and (optionally) revoke a device

        bytes32 signerDevicePublicKey; // signing public key of device that perform this action.
        bytes signedAction; // signature of the action contained using nacl.sign.detached.
        // add first device = self-sign ==> ['registry', address, 0, 100, accountSigningPublicKey, accountEncryptionPublicKey, deviceSigningPublicKey, deviceEncryptionPublicKey]
        // add draft device => newDevice-signed ==> ['registry', address, <newindex>, 1, accountSigningPublicKey, accountEncryptionPublicKey, deviceSigningPublicKey, deviceEncryptionPublicKey]
            // disapprove draft device => approver-device ==> ['registry', address, <newindex>, 2, accountSigningPublicKey, accountEncryptionPublicKey, deviceSigningPublicKey, deviceEncryptionPublicKey]
        // add account key to device => approver-device ==> ['registry', address, <newindex>, 11, accountSigningPublicKey, accountEncryptionPublicKey, deviceSigningPublicKey, deviceEncryptionPublicKey]
        // manual seeds saving => approver-device ==> ['registry', address, <newindex>, 12, accountSigningPublicKey, accountEncryptionPublicKey, deviceSigningPublicKey, deviceEncryptionPublicKey, ...]
        // publish device key/approve device => approver-device ==> ['registry', address, <newindex>, 101, accountSigningPublicKey, accountEncryptionPublicKey, deviceSigningPublicKey, deviceEncryptionPublicKey]
        // publish account key => approver-device ==> ['registry', address, <newindex>, 111, accountSigningPublicKey, accountEncryptionPublicKey, rvkDeviceSigningPublicKey, rvkDeviceEncryptionPublicKey]

        bytes32 signingPublicKey; // if action==11|12|100|111 new ed25519 signing key of account
        bytes32 encryptionPublicKey; // if action==11|12|100|111, new x25519 encryption key

        bytes32 deviceSigningPublicKey; // if action==1|100|101, new device public ed25519 key
        bytes32 deviceEncryptionPublicKey; // if action==1|100|101, new device public x25519 key

        bytes deviceName; // if action==1|100|101, nonce|nacl.box(device_name, DvEck, AcEcK)
        bytes32 deviceNameHash; // if action==1|100|101, keccak256(address, device_name), supposed to be unique for each account

        bytes32[] revokedKeys; // array of public keys to revoke

        // if action=2, public keys to disapproved devices
        // if action=111, contains both public keys of account to revoke and devices; accountSigningPublicKey, accountEncryptionPublicKey, deviceSigningPublicKey, deviceEncryptionPublicKey

        // reserved space for future fields
        uint256[4] _reserved;

        // Deriving KeyPairs and Secret from Seed.
        // new account seed is generated with
        // 1. random bytes32 ==> seedi (si)
        // 2. signingKey = nacl.sign.keyPair.fromSeed( scrypt(si, "EDH-Derived-NaCl-Ed25519", 32) )
        // 3. encryptionKey = nacl.box.keyPair.fromSecretKey( scrypt(si, "EDH-Derived-NaCl-X25519", 32) )
        // 4. secretKey = scrypt(si, "EDH-Derived-NaCl-Secret", 32)

        // STEP on First Device
        // 1. [client] device generator Wallet
        // 1. [client] gen device DvKP, store device KP on device only
        // 2. [client] gen seedi, derive AcKP.
        // 4. call Contract.registerAccount(AcKPs, DvKPs, boxedSeedi)
        //   4.1. [contract] add SigItem(100) (AcKPs)
        //   4.2. [event] AccountRegistered
        //   4.3. [event] DeviceRegistered
        // -- ALT -- saving boxedSeed is optional (Registry can be used for dPKI only and client will find a way to share secret keys themselves)
        // 4. [ALT] call Contract.registerAccount(AcKPs, DvKPs, [])
        //   4.1. [contract] add SigItem(100) (AcKPs)
        //   4.2. [event] AccountRegistered
        //   4.3. [event] DeviceRegistered
        // STEP [ALT]. save seed to block chain.
        // [OPTIONS]. call Contract.addVaultSeeds(AcKps, DvKPs[], boxedSeedi[], boxedPrvSeed || bytes[0], rvkDvKps[])
        //   OPT.1 [event] VaultItemSaved(address, AcKps, DvKPs)
        //   OPT.2 [event] DeviceRevoked(address, AcKps, DvKPs)

        // STEP on Next Device(s)
        // 1. [client-new-device] Find a way to import wallet to new Device
        // 2. [client-new-device] gen device DvKP, store device KP on device only
        // 3. call Contract.getDevices()
        //   3.1 check that name does not conflicts
        // 4. call Contract.getAccountPublicKeys()
        //   4.1. Use this to create box(deviceName, AcEKp, DvEKp)
        // 5. call Contract.addDraftDevice(DvKPs)
        //   5.1. [contract] add SigItem(1) (device is not yet approved)
        // 6. [client-old-device] Approve New Device
        //   6.1 call Contract.getVaultSeeds() and parse the vault seed can be cached in secure storage.
        //   6.2 call Contract.getDraftDevices()
        //   6.3-A if not approve, call Contract.disapproveDraftDevice(DvKp) and done
        //   6.3-B if user Approve, generate boxSeed for new Device with box(seed, AcEcK, DvEcKp)
        //   6.4 call Contract.registerDevice(DvKps, boxedSeedi)
        //   6.5 [contract] add SigItem(101) (DvKPs)

        // STEP on Revoke Device
        // 1. [revoking-device] call Contract.getDevices()
        //   1.1 to get device info to revoke.
        // 2. call Contract.getVaultSeeds()
        // 3. call Contract.getAccountPublicKeys()
        //   3.1 Make sure our own device has not been revoked.
        // 4. Decrypt latest seed.
        // 5. Generate new seed and derive new AcKPs, secretKey.
        // 6. box old seed ==> box(oldSeed, newSecretKey)
        // 7. box new seed for each non-revoked devices ==> box(newSeed, newAcEcKp, DvEcKp)
        // 8. call Contract.revokeDevice(newAcKP, DvKps[], boxedSeedi[], prevSeedi, revokedDvKps[], revokedAcKPs[])
        //   8.1. [contract] add SigItem(111) (AcKPs), add set vault seed and revoked keys
    }

    struct PubKeyBundle {
        bytes32 signingPublicKey;
        bytes32 encryptionPublicKey;
    }
    struct DeviceNameAndHash {
        bytes deviceName;
        bytes32 deviceNameHash;
    }

    // -- end state models

    // -- read models

    struct DeviceInfo {
        uint64 timestamp;
        uint16 version; // fixed to 1
        bool isRevoked;
        uint64 revokedTimestamp;

        bytes32 signerDevicePublicKey; // signing public key of device that perform this action.
        bytes signedAction; // signature of the action contained using nacl.sign.detached.

        bytes32 signingPublicKey;
        bytes32 encryptionPublicKey;

        bytes32 deviceSigningPublicKey;
        bytes32 deviceEncryptionPublicKey;
        bytes deviceName; // encrypted device name (only for account owner)
        bytes32 deviceNameHash; // encrypted device name (only for account owner)
    }

    struct PublicKeyBundle {
        uint64 timestamp;
        uint16 version; // fixed to 1
        bool isRevoked;
        uint64 revokedTimestamp;

        bytes32 signingPublicKey;
        bytes32 encryptionPublicKey;
    }

    // use this to pass around common variables -- pubkeys and sign
    // this reduce number of local variables.
    struct LocalCommonVars {
        uint index;
        bytes32 signerDevicePublicKey;
        bytes signedAction;

        bytes32 signingPublicKey;
        bytes32 encryptionPublicKey;

        bytes32 deviceSigningPublicKey;
        bytes32 deviceEncryptionPublicKey;

        bytes deviceName;
        bytes32 deviceNameHash;
    }

    // Constants
    uint16 constant SIG_ACTION_LOCAL_ADD_DEVICE = 1;
    uint16 constant SIG_ACTION_LOCAL_DISAPPROVE_DEVICE = 2;
    uint16 constant SIG_ACTION_LOCAL_ADD_DEVICE_SEEDS = 11;
    uint16 constant SIG_ACTION_LOCAL_SAVE_SEEDS = 12;
    uint16 constant SIG_ACTION_NEW_ACCOUNT = 100;
    uint16 constant SIG_ACTION_REGISTER_DEVICE = 101;
    uint16 constant SIG_ACTION_UPDATE_ACCOUNT_KEYS = 111;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
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
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
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
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 *
 * @custom:storage-size 52
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
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
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
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
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        return functionCall(target, data, "Address: low-level call failed");
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
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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