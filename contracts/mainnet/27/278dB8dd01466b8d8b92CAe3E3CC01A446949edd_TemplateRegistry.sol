// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../termsable/TermsableNoToken.sol";

contract TemplateRegistry is Ownable, TermsableNoToken {
    /// @notice Struct to store Template related data
    struct Template {
        /// @notice Template name
        string name;
        /// @notice Template cid on IPFS
        string cid;
        /// @notice Template reputation score
        int score;
        /// @notice Template metadata
        string MetadataURI;
        /// @notice Template owner(uploader)
        address owner;
    }
    /// @notice Array that stores all the templates
    Template[] private templates;
    /// @notice Mapping that stores the mapping of template cid to template index
    mapping(string => uint256) private indexes;
    /// @notice Minimum fee to score a template
    uint minfee = 0.5 ether;

    /// @notice This event is emitted when a template is added to the registry
    /// @dev This event is emitted when a template is added to the registry
    /// @param owner The owner of the template
    /// @param index The index of the template in the registry
    event TemplateAdded(address owner, uint256 indexed index);

    /// @notice This function let's a user add a template to the registry
    /// @dev This function let's a user add a template of type Template structure to the registry and emits the TemplateAdded event.
    /// @param _template The template of type struct Template to add to the registry
    function add(Template memory _template) public {
        require(_acceptedTerms(msg.sender));
        uint256 index = templates.length;
        templates.push(_template);
        indexes[_template.cid] = index;
        emit TemplateAdded(_template.owner, index);
    }

    /// @notice This function returns the template at a certain index
    /// @dev This function returns the template at a certain index
    /// @param _index The index of the template to return
    /// @return The template of type Template at the given index
    function template(uint256 _index) public view returns (Template memory) {
        return templates[_index];
    }

    /// @notice This function returns the template given a cid
    /// @dev This function returns the template given a cid
    /// @param _cid The cid of the template to return
    /// @return The template of type Template at the given cid
    function templatebyCID(string memory _cid)
        public
        view
        returns (Template memory)
    {
        return templates[indexes[_cid]];
    }

    /// @notice This function returns the number of templates in the registry
    function count() public view returns (uint256) {
        return templates.length;
    }

    /// @notice This function returns the index of a template given a cid
    /// @dev This function returns the index of a template given a cid
    /// @param _cid The cid of the template to return the index of
    /// @return The index of the template in the registry
    function indexOf(string memory _cid) public view returns (uint256) {
        return indexes[_cid];
    }

    /// @notice This function let's a user upvote a template to increase its reputation score
    /// @dev This is a payable function let's a user upvote a template given it's cid to increase its reputation score
    /// @dev This function also checks if the user has paid atleast the minimum fee to score a template
    /// @param _cid The cid of the template to upvote
    function upvote(string memory _cid) public payable {
        require(
            msg.value >= minfee,
            "You must pay at least the minimum fee to upvote"
        );
        for (uint256 i = 0; i < templates.length; i++) {
            if (keccak256(bytes(templates[i].cid)) == keccak256(bytes(_cid))) {
                templates[i].score += int(msg.value);
            }
        }
    }

    /// @notice This function let's a user downvote a template to increase its reputation score
    /// @dev This is a payable function let's a user downvote a template given it's cid to decrease its reputation score
    /// @dev This function also checks if the user has paid atleast the minimum fee to score a template
    /// @param _cid The cid of the template to downvote
    function downvote(string memory _cid) public payable {
        require(
            msg.value >= minfee,
            "You must pay at least the minimum fee to downvote"
        );
        for (uint256 i = 0; i < templates.length; i++) {
            if (keccak256(bytes(templates[i].cid)) == keccak256(bytes(_cid))) {
                templates[i].score -= int(msg.value);
            }
        }
    }

    /// @notice This function returns the reputation score of a template given a cid
    /// @dev This function returns the reputation score of a template given a cid
    /// @param _cid The cid of the template to return the reputation score of
    /// @return The reputation score of the template
    function score(string memory _cid) public view returns (int) {
        for (uint256 i = 0; i < templates.length; i++) {
            if (keccak256(bytes(templates[i].cid)) == keccak256(bytes(_cid))) {
                return templates[i].score;
            }
        }
        return 0;
    }
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./TermsableBase.sol";
import "../interfaces/Signable.sol";

abstract contract TermsableNoToken is TermsableBase, Signable {
    /// @notice Mapping that stores whether the address has accepted terms.
    /// @dev This mapping returns a boolean value indicating whether the address has accepted terms.
    mapping(address => bool) _hasAcceptedTerms;

    /// @notice This is an internal function that returns whether the address has accepted terms.
    /// @dev This function returns a boolean value indicating whether the address has accepted terms.
    /// @param _to The address to check.
    /// @return True if the address has accepted terms, false otherwise.
    function _acceptedTerms(address _to) internal view returns (bool) {
        return _hasAcceptedTerms[_to];
    }

    /// @notice This is an external function that returns whether the address has accepted terms.
    /// @dev This function returns a boolean value indicating whether the address has accepted terms.
    /// @param _address The address to check.
    /// @return True if the address has accepted terms, false otherwise.
    function acceptedTerms(address _address) external view returns (bool) {
        return _acceptedTerms(_address);
    }

    /// @notice This is an external function called by a user that wants to accepts the agreement at certain url
    /// @dev This function is called by a user that wants to accepts terms. It checks if the terms url for the agreement is the latest one.
    /// @dev It then updates the mapping _hasAcceptedTerms and emits the AcceptedTerms event.
    /// @param _newtermsUrl The url of the terms.
    function acceptTerms(string memory _newtermsUrl) external {
        require(
            keccak256(bytes(_newtermsUrl)) == keccak256(bytes(_termsUrl())),
            "Terms Url does not match"
        );
        _acceptTerms(msg.sender, _newtermsUrl);
    }

    /// @notice This function is used to accept the terms at certain url on behalf of the user (metasigner)
    /// @dev This function is called by a metasigner to accept terms on behalf of the signer that wants to accepts terms.
    /// @dev It uses ECDSA to recover the signer from the signature and the hash of the termsurl and checks if they match.
    /// @param _signer The address of the signer that wants to accept terms.
    /// @param _newtermsUrl The url of the terms.
    /// @param _signature The signature of the signer that wants to accept terms.
    function acceptTermsFor(
        address _signer,
        string memory _newtermsUrl,
        bytes memory _signature
    ) external onlyMetaSigner {
        bytes32 hash = ECDSA.toEthSignedMessageHash(bytes(_newtermsUrl));
        address _checkedSigner = ECDSA.recover(hash, _signature);
        require(_checkedSigner == _signer);
        _acceptTerms(_signer, _newtermsUrl);
    }

    /// @notice This is an internal function called by a user that wants to accepts the agreement at certain url
    /// @dev This function is called by a the external function which is called by a user that wants to accepts terms.
    /// @dev It updates the mapping _hasAcceptedTerms and emits the AcceptedTerms event.
    /// @param _newtermsUrl The url of the terms.
    /// @param _signer The address of the signer that wants to accept terms.
    function _acceptTerms(address _signer, string memory _newtermsUrl)
        internal
    {
        _hasAcceptedTerms[_signer] = true;
        emit AcceptedTerms(_signer, _newtermsUrl);
    }

    /// @notice This function returns the url of the terms.
    /// @dev This function returns the url of the terms with the prefix "ipfs://".
    function termsUrl() external view returns (string memory) {
        return _termsUrlWithPrefix("ipfs://");
    }

    /// @notice This internal function returns the url of the terms.
    /// @dev This internal function returns the url of the terms with the prefix "ipfs://".
    function _termsUrl() internal view returns (string memory) {
        return _termsUrlWithPrefix("ipfs://");
    }

    /// @notice This function returns the url of the terms with a given prefix
    /// @dev This function returns the url of the terms with the prefix
    /// @param prefix The prefix of the url.
    /// return _termsUrlWithPrefix(prefix) The url of the terms with the prefix.
    function termsUrlWithPrefix(string memory prefix)
        external
        view
        returns (string memory)
    {
        return _termsUrlWithPrefix(prefix);
    }

    /// @notice This is an internal function that returns the url of the agreement with a given prefix.
    /// @dev This function returns the url of the agreement with the prefix.
    /// @dev It uses the global renderer, template, chain id, contract address of the deployed contract and the latest block height to concatenate the url.
    /// @param prefix The prefix of the url.
    /// @return _termsURL The url of the agreement with the prefix.
    function _termsUrlWithPrefix(string memory prefix)
        internal
        view
        returns (string memory _termsURL)
    {
        _termsURL = string(
            abi.encodePacked(
                prefix,
                _globalRenderer,
                "/#/",
                _globalDocTemplate,
                "::",
                // Strings.toString(block.number),
                // "::",
                Strings.toString(block.chainid),
                "::",
                Strings.toHexString(uint160(address(this)), 20),
                "::",
                Strings.toString(_lastTermChange)
            )
        );
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/cryptography/ECDSA.sol)

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
            /// @solidity memory-safe-assembly
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
            /// @solidity memory-safe-assembly
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../interfaces/TermReader.sol";
import "@openzeppelin/contracts/token/common/ERC2981.sol";
import "../interfaces/MetadataURI.sol";

abstract contract TermsableBase is Ownable, TermReader, MetadataURI {
    /// @notice The default value of the global renderer.
    /// @dev The default value of the global renderer.
    string _globalRenderer = "";

    /// @notice The default value of the global template.
    /// @dev The default value of the global template.
    string _globalDocTemplate = "";

    string private _uri;

    /// @notice Mapping that store the global terms.
    /// @dev This mapping stores the global terms.
    mapping(string => string) _globalTerms;

    /// @notice This is the latest block height at which the terms were updated.
    /// @dev This is the latest block height at which the terms were updated. 0 by default.
    uint256 _lastTermChange = 0;

    /// @notice Returns whether the address is allowed to accept terms on behalf of the signer.
    /// @dev This function returns whether the address is allowed to accept terms on behalf of the signer.
    mapping(address => bool) private _metaSigners;

    modifier onlyMetaSigner() {
        require(
            _metaSigners[_msgSender()] || owner() == _msgSender(),
            "Not a metasigner or Owner"
        );
        _;
    }

    /// @notice Adds a meta signer to the list of signers that can accept terms on behalf of the signer.
    /// @dev This function adds a meta signer to the list of signers that can accept terms on behalf of the signer.
    /// @dev This function is only available to the owner of the contract.
    /// @param _signer The address of the signer that can accept terms on behalf of the signer.
    function addMetaSigner(address _signer) external onlyOwner {
        _addMetaSigner(_signer);
    }

    function _addMetaSigner(address _signer) internal {
        _metaSigners[_signer] = true;
    }

    /// @notice Removes a meta signer from the list of signers that can accept terms on behalf of the signer.
    /// @dev This function removes a meta signer from the list of signers that can accept terms on behalf of the signer.
    /// @dev This function is only available to the owner of the contract.
    /// @param _signer The address of the signer that can no longer accept terms on behalf of the signer.
    function removeMetaSigner(address _signer) external onlyOwner {
        _removeMetaSigner(_signer);
    }

    function _removeMetaSigner(address _signer) internal {
        _metaSigners[_signer] = false;
    }

    function isMetaSigner(address _signer) public view returns (bool) {
        return _metaSigners[_signer];
    }

    /// @notice Function to set the Global Renderer.
    /// @dev This function lets the owner of the contract set the global renderer of the terms.
    /// @param _newRenderer The new renderer to use for the terms.
    function setGlobalRenderer(string memory _newRenderer) external onlyOwner {
        _setGlobalRenderer(_newRenderer);
    }

    function _setGlobalRenderer(string memory _newRenderer) internal {
        _globalRenderer = _newRenderer;
        emit GlobalRendererChanged(_newRenderer);
        _lastTermChange = block.number;
    }

    /// @notice Function that returns the global renderer.
    /// @dev This function returns the global renderer of the terms.
    /// @return _globalRenderer The global renderer of the terms.
    function renderer() public view returns (string memory) {
        return _globalRenderer;
    }

    /// @notice Function to set the Global Document Template.
    /// @dev This function lets the owner of the contract set the global document template of the terms.
    /// @param _newDocTemplate The new document template to use for the terms.
    function setGlobalTemplate(string memory _newDocTemplate)
        external
        onlyOwner
    {
        _setGlobalTemplate(_newDocTemplate);
    }

    function _setGlobalTemplate(string memory _newDocTemplate) internal {
        _globalDocTemplate = _newDocTemplate;
        emit GlobalTemplateChanged(_newDocTemplate);
        _lastTermChange = block.number;
    }

    /// @notice Function that returns the global document template.
    /// @dev This function returns the global document template of the terms.
    /// @return _globalDocTemplate The global document template of the terms.
    function docTemplate() external view returns (string memory) {
        return _globalDocTemplate;
    }

    /// @notice Function to set the Global Term/// @notice Explain to an end user what this does
    /// @dev This function lets the owner of the contract set the global terms
    /// @param _term The term to set.
    /// @param _value The value of the term to set.
    function setGlobalTerm(string memory _term, string memory _value)
        external
        onlyOwner
    {
        _setGlobalTerm(_term, _value);
    }

    function _setGlobalTerm(string memory _term, string memory _value)
        internal
    {
        _globalTerms[_term] = _value;
        emit GlobalTermChanged(
            keccak256(bytes(_term)),
            keccak256(bytes(_value))
        );
        _lastTermChange = block.number;
    }

    /// @notice This function returns the global value of the term
    /// @dev This function returns the global value of the term
    /// @param _term The term to get.
    /// @return _globalTerms[_term] The global value of the term
    function globalTerm(string memory _term)
        public
        view
        returns (string memory)
    {
        return _globalTerms[_term];
    }

    /// @notice Function to get block of the latest term change.
    /// @dev This function returns the block number of the last term change.
    /// @return _lastTermChange The block number of the last term change.
    function currentTermsBlock() public view returns (uint256) {
        return _lastTermChange;
    }

    function setURI(string memory _newURI) external onlyMetaSigner {
        _uri = _newURI;
        _lastTermChange = block.number;
        emit UpdatedURI(_uri);
    }

    function URI() public view returns (string memory) {
        return _uri;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface Signable {
    /// @notice Event that is emitted when a terms are accepted.
    /// @dev This event is emitted when a terms are accepted.
    /// @param sender The address that accepted the terms.
    /// @param terms The terms that were accepted.
    event AcceptedTerms(address sender, string terms);

    /// @notice This function returns the terms url with a given prefix.
    /// @dev This function returns the terms url with a given prefix.
    /// @param prefix The prefix to add to the terms url.
    /// @return The terms url with the prefix.
    function termsUrlWithPrefix(string memory prefix)
        external
        view
        returns (string memory);

    /// @notice This function returns the terms url.
    /// @dev This function returns the terms url.
    /// @return The terms url.
    function termsUrl() external view returns (string memory);

    /// @notice This function is used to accept the terms at certain url
    /// @dev This function is called by a user that wants to accepts terms.
    /// @param _newtermsUrl The url of the terms.
    function acceptTerms(string memory _newtermsUrl) external;

    /// @notice This function is used to accept the terms at certain url on behalf of the user (metasigner)
    /// @dev This function is called by a metasigner to accept terms on behalf of the signer that wants to accepts terms.
    /// @param _signer The address of the signer that wants to accept terms.
    /// @param _newtermsUrl The url of the terms.
    /// @param _signature The signature of the signer that wants to accept terms.
    function acceptTermsFor(
        address _signer,
        string memory _newtermsUrl,
        bytes memory _signature
    ) external;

    /// @notice This function returns whether or not a user has accepted the terms.
    /// @dev This function returns whether or not a user has accepted the terms.
    /// @param _address The address of the user.
    /// @return True if the user has accepted the terms, false otherwise.
    function acceptedTerms(address _address) external view returns (bool);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface TermReader {
    /// @notice This event is fired when a token term is added.
    /// @dev Event when a new Global term is added to the contract
    /// @param _term The term being added to the contract
    /// @param _value value of the term added to the contract
    event GlobalTermChanged(bytes32 indexed _term, bytes32 _value);

    /// @notice This event is emitted when the global renderer is updated.
    /// @dev This event is emitted when the global renderer is updated.
    /// @param _renderer The new renderer.
    event GlobalRendererChanged(string indexed _renderer);

    /// @notice This event is emitted when the global template is updated.
    /// @dev This event is emitted when the global template is updated.
    /// @param _template The new template.
    event GlobalTemplateChanged(string indexed _template);

    /// @notice This function is used to return the value of the term
    /// @dev Function to return the value of the term
    /// @param _term  The term to get
    /// @return _value The value of the term
    function globalTerm(string memory _term)
        external
        view
        returns (string memory _value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/common/ERC2981.sol)

pragma solidity ^0.8.0;

import "../../interfaces/IERC2981.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of the NFT Royalty Standard, a standardized way to retrieve royalty payment information.
 *
 * Royalty information can be specified globally for all token ids via {_setDefaultRoyalty}, and/or individually for
 * specific token ids via {_setTokenRoyalty}. The latter takes precedence over the first.
 *
 * Royalty is specified as a fraction of sale price. {_feeDenominator} is overridable but defaults to 10000, meaning the
 * fee is specified in basis points by default.
 *
 * IMPORTANT: ERC-2981 only specifies a way to signal royalty information and does not enforce its payment. See
 * https://eips.ethereum.org/EIPS/eip-2981#optional-royalty-payments[Rationale] in the EIP. Marketplaces are expected to
 * voluntarily pay royalties together with sales, but note that this standard is not yet widely supported.
 *
 * _Available since v4.5._
 */
abstract contract ERC2981 is IERC2981, ERC165 {
    struct RoyaltyInfo {
        address receiver;
        uint96 royaltyFraction;
    }

    RoyaltyInfo private _defaultRoyaltyInfo;
    mapping(uint256 => RoyaltyInfo) private _tokenRoyaltyInfo;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        return interfaceId == type(IERC2981).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @inheritdoc IERC2981
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice) public view virtual override returns (address, uint256) {
        RoyaltyInfo memory royalty = _tokenRoyaltyInfo[_tokenId];

        if (royalty.receiver == address(0)) {
            royalty = _defaultRoyaltyInfo;
        }

        uint256 royaltyAmount = (_salePrice * royalty.royaltyFraction) / _feeDenominator();

        return (royalty.receiver, royaltyAmount);
    }

    /**
     * @dev The denominator with which to interpret the fee set in {_setTokenRoyalty} and {_setDefaultRoyalty} as a
     * fraction of the sale price. Defaults to 10000 so fees are expressed in basis points, but may be customized by an
     * override.
     */
    function _feeDenominator() internal pure virtual returns (uint96) {
        return 10000;
    }

    /**
     * @dev Sets the royalty information that all ids in this contract will default to.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setDefaultRoyalty(address receiver, uint96 feeNumerator) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: invalid receiver");

        _defaultRoyaltyInfo = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Removes default royalty information.
     */
    function _deleteDefaultRoyalty() internal virtual {
        delete _defaultRoyaltyInfo;
    }

    /**
     * @dev Sets the royalty information for a specific token id, overriding the global default.
     *
     * Requirements:
     *
     * - `receiver` cannot be the zero address.
     * - `feeNumerator` cannot be greater than the fee denominator.
     */
    function _setTokenRoyalty(
        uint256 tokenId,
        address receiver,
        uint96 feeNumerator
    ) internal virtual {
        require(feeNumerator <= _feeDenominator(), "ERC2981: royalty fee will exceed salePrice");
        require(receiver != address(0), "ERC2981: Invalid parameters");

        _tokenRoyaltyInfo[tokenId] = RoyaltyInfo(receiver, feeNumerator);
    }

    /**
     * @dev Resets royalty information for the token id back to the global default.
     */
    function _resetTokenRoyalty(uint256 tokenId) internal virtual {
        delete _tokenRoyaltyInfo[tokenId];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface MetadataURI {
    /// @notice Event that is emitted when contract URI is updated.
    /// @dev This event is emitted when contract URI is updated.
    /// @param uri The new contract URI.
    event UpdatedURI(string uri);

    /// @notice This function is used to return the contract URI
    /// @dev Function to return the contract URI
    /// @return _uri The contract URI
    function URI() external view returns (string memory _uri);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

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