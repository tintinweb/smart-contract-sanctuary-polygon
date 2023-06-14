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

// SPDX-License-Identifier: MIT
/**
 * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
 * © Copyright Utrecht University (Department of Information and Computing Sciences)
 */

pragma solidity ^0.8.0;

import {GenericSignatureHelper} from "../../utils/GenericSignatureHelper.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title SignVerification
 * @author Utrecht University
 * @notice This contracat requires a signer to provide proof of verification with a certain offchain service (example: GitHub) and assigns the respecitve stamp to the address.
 */
contract SignVerification is GenericSignatureHelper, Ownable {
    // Map from user to their stamps
    mapping(address => Stamp[]) internal stamps;
    // Map from userhash to address to make sure the userhash isn't already used by another address
    mapping(string => address) internal stampHashMap;
    // Map to show if an address has ever been verified
    mapping(address => bool) internal isMember;
    address[] allMembers;

    /// @notice The thresholdHistory array stores the history of the verifyDayThreshold variable. This is needed because we might want to check if some stamps were valid in the past.
    Threshold[] thresholdHistory;

    /// @notice The reverifyThreshold determines how long a user has to wait before they can re-verify their address, in days
    uint64 public reverifyThreshold;

    /// @notice A stamp defines proof of verification for a user on a specific platform at a specific date
    struct Stamp {
        string providerId; // Unique id for the provider (github, proofofhumanity, etc.)
        string userHash; // Hash of some unique user data of the provider (username, email, etc.)
        uint64[] verifiedAt; // Timestamps at which the user has verified
    }

    /// @notice A threshold defines the number of days for which a stamp is valid
    struct Threshold {
        uint64 timestamp; // Timestamp at which the threshold was set
        uint64 threshold; // Number of days for which a stamp is valid
    }

    /// @notice Initializes the owner of the contract
    constructor(uint64 _threshold, uint64 _reverifyThreshold) {
        thresholdHistory.push(Threshold(uint64(block.timestamp), _threshold));
        reverifyThreshold = _reverifyThreshold;
    }

    /// @notice This function can only be called by the owner, and it verifies an address. It's not possible to re-verify an address before half the verifyDayThreshold has passed.
    /// @dev Verifies an address
    /// @param _toVerify The address to verify
    /// @param _timestamp in seconds
    function verifyAddress(
        address _toVerify,
        string calldata _userHash,
        uint64 _timestamp,
        string calldata _providerId,
        bytes calldata _proofSignature
    ) external {
        require(
            stampHashMap[_userHash] == address(0) ||
                stampHashMap[_userHash] == _toVerify,
            "ID already affiliated with another address"
        );

        require(_toVerify != address(0), "Address cannot be 0x0");
        require(
            block.timestamp < _timestamp + 1 hours,
            "Proof expired, try verifying again"
        );

        require(
            verify(owner(), keccak256(abi.encodePacked(_toVerify, _userHash, uint(_timestamp))), _proofSignature),
            "Proof is not valid"
        );

        // Check if there is existing stamp with providerId
        bool found; // = false;
        uint foundIndex; // = 0;

        for (uint i; i < stamps[_toVerify].length; ) {
            if (
                keccak256(abi.encodePacked(stamps[_toVerify][i].providerId)) ==
                keccak256(abi.encodePacked(_providerId))
            ) {
                found = true;
                foundIndex = i;
                break;
            }

            unchecked {
                i++;
            }
        }

        if (!found) {
            // Check if this is the first time this user has verified so we can add them to the allMembers list
            if (!isMember[_toVerify]) {
                isMember[_toVerify] = true;
                allMembers.push(_toVerify);
            }

            // Create new stamp if user does not already have a stamp for this providerId
            stamps[_toVerify].push(
                createStamp(_providerId, _userHash, _timestamp)
            );

            // This only needs to happens once (namely the first time an account verifies)
            stampHashMap[_userHash] = _toVerify;
        } else {
            // If user already has a stamp for this providerId
            // Check how long it has been since the last verification
            uint64[] storage verifiedAt = stamps[_toVerify][foundIndex]
                .verifiedAt;
            uint64 timeSinceLastVerification = uint64(block.timestamp) -
                verifiedAt[verifiedAt.length - 1];

            // If it has been more than reverifyThreshold days, update the stamp
            if (timeSinceLastVerification > reverifyThreshold) {
                // Overwrite the userHash (in case the user changed their username or used another account to reverify)
                stamps[_toVerify][foundIndex].userHash = _userHash;
                verifiedAt.push(_timestamp);
            } else {
                revert(
                    "Address already verified; cannot re-verify yet, wait at least half the verifyDayThreshold"
                );
            }
        }
    }

    /// @notice Unverifies a provider from the sender
    /// @param _providerId Unique id for the provider (github, proofofhumanity, etc.) to be removed
    function unverify(string calldata _providerId) external {
        // Assume all is good in the world
        Stamp[] storage stampsAt = stamps[msg.sender];

        // Look up the corresponding stamp for the provider
        for (uint i; i < stampsAt.length; ) {
            if (stringsAreEqual(stampsAt[i].providerId, _providerId)) {
                // Remove the mapping from userhash to address
                stampHashMap[stampsAt[i].userHash] = address(0);

                // Remove stamp from stamps array (we don't care about order so we can just swap and pop)
                stampsAt[i] = stampsAt[stampsAt.length - 1];
                stampsAt.pop();
                return;
            }

            unchecked {
                i++;
            }
        }

        revert(
            "Could not find this provider among your stamps; are you sure you're verified with this provider?"
        );
    }

    /// @dev Solidity doesn't support string comparison, so we use keccak256 to compare strings
    function stringsAreEqual(
        string memory str1,
        string memory str2
    ) internal pure returns (bool) {
        return
            keccak256(abi.encodePacked(str1)) ==
            keccak256(abi.encodePacked(str2));
    }

    /// @notice Creates a stamp for a user
    /// @param _providerId Unique id for the provider (github, proofofhumanity, etc.)
    /// @param _userHash Unique user hash on the platform of the stamp (GH, PoH, etc.)
    /// @param _timestamp Timestamp at which the proof was generated
    /// @return Stamp Returns the created stamp
    function createStamp(
        string memory _providerId,
        string memory _userHash,
        uint64 _timestamp
    ) internal returns (Stamp memory) {
        uint64[] memory verifiedAt = new uint64[](1);
        verifiedAt[0] = _timestamp;
        Stamp memory stamp = Stamp(_providerId, _userHash, verifiedAt);
        stampHashMap[_userHash] = msg.sender;
        return stamp;
    }

    /// @notice This function returns the stamps of an address
    /// @param _toCheck The address to check
    /// @return An array of stamps
    function getStamps(
        address _toCheck
    ) external view returns (Stamp[] memory) {
        return stamps[_toCheck];
    }

    /// @notice Returns the *valid* stamps of an address at a specific timestamp
    /// @param _toCheck The address to check
    /// @param _timestamp The timestamp to check (seconds)
    function getStampsAt(
        address _toCheck,
        uint _timestamp
    ) external view returns (Stamp[] memory) {
        Stamp[] memory stampsAt = new Stamp[](stamps[_toCheck].length);
        uint count; // = 0;

        // Loop through all the user's stamps
        for (uint i; i < stamps[_toCheck].length; ) {
            // Get the list of all verification timestamps
            uint64[] storage verifiedAt = stamps[_toCheck][i].verifiedAt;

            // Get the threshold at _timestamp
            uint currentTimestampIndex = thresholdHistory.length - 1;
            while (
                currentTimestampIndex > 0 &&
                thresholdHistory[currentTimestampIndex].timestamp > _timestamp
            ) {
                currentTimestampIndex--;
            }

            uint64 verifyDayThreshold = thresholdHistory[currentTimestampIndex]
                .threshold;

            // Reverse for loop, because more recent dates are at the end of the array
            for (uint j = verifiedAt.length; j > 0; j--) {
                // If the stamp is valid at _timestamp, add it to the stampsAt array
                if (
                    verifiedAt[j - 1] + (verifyDayThreshold * 1 days) >
                    _timestamp &&
                    verifiedAt[j - 1] < _timestamp
                ) {
                    stampsAt[count] = stamps[_toCheck][i];
                    count++;
                    break;
                } else if (
                    verifiedAt[j - 1] + (verifyDayThreshold * 1 days) <
                    _timestamp
                ) {
                    break;
                }
            }

            unchecked {
                i++;
            }
        }

        Stamp[] memory stampsAtTrimmed = new Stamp[](count);

        for (uint i = 0; i < count; i++) {
            stampsAtTrimmed[i] = stampsAt[i];
        }

        return stampsAtTrimmed;
    }

    /// @notice This function can only be called by the owner to set the verifyDayThreshold
    /// @dev Sets the verifyDayThreshold
    /// @param _days The number of days to set the verifyDayThreshold to
    function setVerifyDayThreshold(uint64 _days) external onlyOwner {
        Threshold memory lastThreshold = thresholdHistory[
            thresholdHistory.length - 1
        ];
        require(
            lastThreshold.threshold != _days,
            "Threshold already set to this value"
        );

        thresholdHistory.push(Threshold(uint64(block.timestamp), _days));
    }

    /// @notice Returns the full threshold history
    /// @return An array of Threshold structs
    function getThresholdHistory() external view returns (Threshold[] memory) {
        return thresholdHistory;
    }

    function getAllMembers() external view returns (address[] memory) {
        return allMembers;
    }

    /// @notice Returns whether or not the caller is or was a member at any time
    /// @dev Loop through the array of all members and return true if the caller is found
    /// @return bool Whether or not the caller is or was a member at any time
    function isOrWasMember(address _toCheck) external view returns (bool) {
        return isMember[_toCheck];
    }

    /// @notice This function can only be called by the owner to set the reverifyThreshold
    /// @dev Sets the reverifyThreshold
    /// @param _days The number of days to set the reverifyThreshold to
    function setReverifyThreshold(uint64 _days) external onlyOwner {
        reverifyThreshold = _days;
    }
}

// SPDX-License-Identifier: MIT
/**
  * This program has been developed by students from the bachelor Computer Science at Utrecht University within the Software Project course.
  * © Copyright Utrecht University (Department of Information and Computing Sciences)
  */

pragma solidity ^0.8.0;

// Modified source from: https://solidity-by-example.org/signature/

/* Signature Verification

How to Sign and Verify
# Signing
1. Create message to sign
2. Hash the message
3. Sign the hash (off chain, keep your private key secret)

# Verify
1. Recreate hash from the original message
2. Recover signer from signature and hash
3. Compare recovered signer to claimed signer
*/

/// @title Set of (helper) functions for signature verification
contract GenericSignatureHelper {
    /// @notice Signs the messageHash with a standard prefix
    /// @param _messageHash The hash of the packed message (messageHash) to be signed
    /// @return bytes32 Returns the signed messageHash
    function getEthSignedMessageHash(
        bytes32 _messageHash
    ) internal pure returns (bytes32) {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    /// @notice Verify a signature
    /// @dev Generate the signed messageHash from the parameters to verify the signature against
    /// @param _signer The signer of the signature (the owner of the contract)
    /// @param _messageHash The hash of the packed message (messageHash) to be signed
    /// @param _signature The signature of the proof signed by the signer
    /// @return bool Returns the result of the verification, where true indicates success and false indicates failure
    function verify(
        address _signer,
        bytes32 _messageHash,
        bytes memory _signature
    ) internal pure returns (bool) {
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(_messageHash);

        return recoverSigner(ethSignedMessageHash, _signature) == _signer;
    }

    /// @notice Recover the signer from the signed messageHash and the signature
    /// @dev This uses ecrecover
    /// @param _ethSignedMessageHash The signed messageHash created from the parameters
    /// @param _signature The signature of the proof signed by the signer
    /// @return address Returns the recovered address
    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    /// @notice Splits the signature into r, s, and v
    /// @dev This is necessary for the ecrecover function
    /// @param sig The signature
    /// @return r Returns the first 32 bytes of the signature
    /// @return s Returns the second 32 bytes of the signature
    /// @return v Returns the last byte of the signature
    function splitSignature(
        bytes memory sig
    ) internal pure returns (bytes32 r, bytes32 s, uint8 v) {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }
}