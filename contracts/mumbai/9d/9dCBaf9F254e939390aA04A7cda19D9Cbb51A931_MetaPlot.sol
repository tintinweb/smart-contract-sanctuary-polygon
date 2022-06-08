//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/Helpers.sol";

contract MetaPlot is Ownable, Helpers {
    string public constant _PLOT_IDENTIFIER = "METAPLOT";
    string public constant _PLOT_RELEASE_IDENTIFIER = "METAPLOTRELEASE";
    string public constant _PLOT_CONTRACT_VERSION = "1";

    // Enum representing the different plot sources
    enum PlotSource {
        Legal,
        Investor,
        Business
    }

    /**
     * @notice Plot structs.
     *  plotID - Unique ID of the plot. ie. It is an integer value. ex: 1,2,3 etc.
     *  canonicalIdentifier - String (Postal Address, Place Name). It is a string.
     *  name - Friendly name of the plot. Ex: "Plot-abc"
     *  boundaries - Polygon (Lat, Long). It is a serialized json. 
        Ex: "{{"lat":123658963,"long":256936995},{"lat":123658963,"long":256936995},{"lat":123658963,"long":256936995},{"lat":123658963,"long":256936995}}"
     *  elevationProfile - Array of Raster Tiles
     *  centroidId - Point (Lat, Long) of the plot. It is a serialized json. Ex: "{"lat":123658963,"long":256936995}"
     *  source - Enum (Legal, Investor, Business)
     *  plotOwner - Crypto Wallet Address of a GIS Source
     *  sourceName - Friendly name of the GIS Source
      * maxEditions - Maximum number of editions allowed for this plot.
     *  createdAt - DateTime of the plot creation
     */
    struct Plot {
        string plotID;
        address plotOwner;
        string propertyClass;
        string name;
        PlotSource source;
        string sourceName;
        uint256 maxEditions;
        string propertyArweaveHash;
        uint256 version;
        uint256 createdAt;
    }
    // Plots are always mapped with their plotID and version.
    mapping(string => mapping(uint256 => Plot)) public plots;
    mapping(string => uint256) public plotLastestVersion;
    // Every plot has got unique index which is used to generated plotID. _lastPlotIndex records the last index used.
    uint256 private _lastPlotIndex;
    uint256[] private _plotIndices;

    // Event definations for MetaPlot
    event PlotCreate(string plotName, string plotID);

    enum ReleaseType {
        None,
        Manual,
        Automatic_Price_Threshold,
        Automatic_Time_Interval
    }
    /**
     * @notice Released plot information
     *  releaseID - Unique ID of the relesed information of a plot.
     *  plotID - ID of a plot that is released.
     *  editionsReleased - Total number of editions released at this particular release. It should always be <= MaxEditions.
     *  totalReleased - Total number of all editions released so far in multiple releases which should always be <= MaxEditions.
     *  releaseType - Enum (None, Manual, Automatic_Price_Threshold, Automatic_Time_Interval)
     *  releaseScalar - For Automatic transaction this is the fraction that is released per threshold/interval
     *  releasedDate - DateTime of the plot edition released.
     */
    struct PlotRelease {
        string releaseID;
        string plotID;
        address releasedBy;
        uint256 editionsReleased;
        uint256 totalReleased;
        ReleaseType releaseType;
        uint256 releaseScalar;
        uint256 version;
        uint256 releasedDate;
    }
    /*
     * Every plot will have multiple releases. So its mapped like: [plotID][version]=PlotRelease.
     */
    mapping(string => mapping(uint256 => PlotRelease)) public plotReleases;
    mapping(string => uint256) public releasedPlotLatestVersion;
    // Event definations for MetaPlot
    event PlotReleased(string plotID, string releaseID);

    bytes32 constant PLOT_TYPEHASH =
        keccak256(
            "Plot(string propertyClass,string name,uint256 source,string sourceName,uint256 maxEditions,string propertyArweaveHash)"
        );

    struct PlotAuction {
        string plotID;
        uint256 auctionStartDate;
        uint256 auctionClosedDate;
    }

    function createPlot(
        string memory propertyClass,
        string memory name,
        PlotSource source,
        string memory sourceName,
        uint256 maxEditions,
        string memory propertyArweaveHash,
        bytes memory signature
    ) public onlyOwner {
        require(
            checkSignature(
                keccak256(
                    abi.encode(
                        PLOT_TYPEHASH,
                        keccak256(bytes(propertyClass)),
                        keccak256(bytes(name)),
                        source,
                        keccak256(bytes(sourceName)),
                        maxEditions,
                        keccak256(bytes(propertyArweaveHash))
                    )
                ),
                signature
            ) == owner(),
            "Voucher invalid"
        );
        require(maxEditions > 0, "Max editions should be greater than 0");
        string memory id = concatValues(
            _PLOT_IDENTIFIER,
            _PLOT_CONTRACT_VERSION,
            ++_lastPlotIndex
        );
        Plot storage plot = plots[id][++plotLastestVersion[id]];

        plot.plotID = id;
        plot.plotOwner = msg.sender;
        plot.propertyClass = propertyClass;
        plot.name = name;
        plot.source = source;
        plot.sourceName = sourceName;
        plot.maxEditions = maxEditions;
        plot.propertyArweaveHash = propertyArweaveHash;
        plot.version = plotLastestVersion[id];
        plot.createdAt = block.timestamp;

        emit PlotCreate(name, id);
    }

    function createPlotRelease(
        string memory plotID,
        uint256 editionToRelease,
        ReleaseType releaseType,
        uint256 releaseScalar
    ) public plotExists(plotID) onlyOwner {
        require(
            editionToRelease > 0,
            "Number of editions to release should be greater than 0"
        );
        string memory releaseID = concatValues(
            _PLOT_RELEASE_IDENTIFIER,
            _PLOT_CONTRACT_VERSION,
            ++releasedPlotLatestVersion[plotID]
        );
        uint256 totalReleased = getTotalPlotReleased(plotID, editionToRelease);

        PlotRelease storage plotRelease = plotReleases[releaseID][
            releasedPlotLatestVersion[plotID]
        ];

        plotRelease.releaseID = releaseID;
        plotRelease.plotID = plotID;
        plotRelease.releasedBy = msg.sender;
        plotRelease.editionsReleased = editionToRelease;
        plotRelease.totalReleased = totalReleased + editionToRelease;
        plotRelease.releaseType = releaseType;
        plotRelease.releaseScalar = releaseScalar;
        plotRelease.version = releasedPlotLatestVersion[plotID];
        plotRelease.releasedDate = block.timestamp;

        emit PlotReleased(plotID, releaseID);
    }

    modifier plotExists(string memory plotID) {
        require(plotLastestVersion[plotID] != 0, "Plot doesnot exist.");

        _;
    }

    /**
     * @dev Get the latest released plot information.
     * @param plotID - ID of the plot
     * */
    function getPlot(string memory plotID)
        public
        view
        returns (Plot memory plot)
    {
        return plots[plotID][plotLastestVersion[plotID]];
    }

    /**
     * @dev Get the latest released plot information.
     * @param plotID - ID of the plot
     * */
    function getLatestPlotRelease(string memory plotID)
        public
        view
        returns (PlotRelease memory plotRelease)
    {
        return plotReleases[plotID][releasedPlotLatestVersion[plotID]];
    }

    /**
     * @dev Get the total number of editions released for a plot.
     * @notice This function is used to get the total number of editions released for a plot. It also checks if max editions is reached.
     * @param plotID - ID of the plot
     * @param editionsToRelease - Number of editions to release
     * */
    function getTotalPlotReleased(
        string memory plotID,
        uint256 editionsToRelease
    ) public view returns (uint256) {
        uint256 lastVersion = releasedPlotLatestVersion[plotID];
        // If plotID has prior releases then check if the total number of releases is less than the maxEditions.
        uint256 totalReleased = plotReleases[plotID][lastVersion].totalReleased;
        require(
            (plots[plotID][plotLastestVersion[plotID]].maxEditions -
                totalReleased) >= editionsToRelease,
            "Limit reached. Cannot release more than max editions."
        );

        return (totalReleased);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

//SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title Helpers Contract
 * @dev Contains commain helper methods for other contracts
 */
contract Helpers is EIP712 {
    string private constant SIGNING_DOMAIN_NAME = "META";
    string private constant SIGNING_DOMAIN_VERSION = "1";

    constructor() EIP712(SIGNING_DOMAIN_NAME, SIGNING_DOMAIN_VERSION) {}

    /**
     * @dev converts uint256 to string
     * @param v integer value
     */
    function uint2str(uint256 v)
        internal
        pure
        returns (string memory uintAsString)
    {
        uint256 maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint256 i = 0;
        while (v != 0) {
            uint256 remainder = v % 10;
            v = v / 10;
            reversed[i++] = bytes1(uint8(48 + remainder));
        }
        bytes memory s = new bytes(i); // i + 1 is inefficient
        for (uint256 j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
        }
        string memory str = string(s); // memory isn't implicitly convertible to storage
        return str;
    }

    /**
     * @dev Concats two values. i.e one string and another integer
     * @param identifier Identifier as a first value to concat
     * @param index second value to concat
     */
    function concatValues(
        string memory identifier,
        string memory version,
        uint256 index
    ) internal pure returns (string memory value) {
        return
            string(
                abi.encodePacked(
                    identifier,
                    ":v",
                    version,
                    ":",
                    uint2str(index)
                )
            );
    }

    /**
     * toEthSignedMessageHash
     * @dev prefix a bytes32 value with "\x19Ethereum Signed Message:"
     * and hash the result
     */
    function checkSignature(bytes32 messageHash, bytes memory signature)
        internal
        view
        returns (address)
    {
        bytes32 digest = _hashTypedDataV4(messageHash);
        return ECDSA.recover(digest, signature);
    }

    /**
     * @dev Compare two string variables
     * @param firstValue First string variable
     * @param secondValue Second string variable
     * @return true if matches else false
     */
    function matchStrings(string memory firstValue, string memory secondValue)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((firstValue))) ==
            keccak256(abi.encodePacked((secondValue))));
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

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
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

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
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
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
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
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