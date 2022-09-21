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