// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import '@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol';

import './components/AbstractBase.sol';
import './interfaces/IDIDRegistry.sol';
import './interfaces/IVerifier.sol';

/**
 * @title A smart contract for verifying W3C Verifiable Credentials
 * @dev This contract requires a deployed DID registry contract to function correctly.
 * @custom:experimental This is an experimental contract.
 */
contract Verifier is AbstractBase, IVerifier {
  using ECDSAUpgradeable for bytes32;

  IDIDRegistry public registry;
  bytes32 private rootIssuer;
  mapping(bytes32 => bool) private knownIssuers;
  mapping(bytes32 => uint256) private didNonce;

  /// @notice Contract initialzier
  /// @param _owner The owner of this contract
  /// @param _rootIssuer The Keccack256 hashed form of the DID
  function initialize(
    address _owner,
    bytes32 _rootIssuer,
    address _trustedForwarder
  ) public initializer {
    _transferOwnership(_owner);
    rootIssuer = _rootIssuer;
    trustedForwarder = _trustedForwarder;
  }

  /// @notice Sets the root issuer for the chain of trust
  /// @dev This is an optional setting. However, if set allows the root issuer to be
  /// @dev used as a trust anchor for a given chain of trust
  /// @dev At this time, setting this value cannot be undone. Whether it should be undoable is a TBD
  /// @param _rootIssuer The Keccack256 hashed form of the DID
  function setRootIssuer(bytes32 _rootIssuer) external onlyOwner confirmForwarder {
    rootIssuer = _rootIssuer;
  }

  /// @notice Adds an issuer from the known issuer list
  /// @dev The primary VC issuer's DID must be in this list for verification to pass.
  /// @param _issuer The Keccack256 hashed form of the DID
  function addKnownIssuer(bytes32 _issuer) external onlyOwner confirmForwarder {
    knownIssuers[_issuer] = true;
  }

  /// @notice Removes an issuer from the known issuer list
  /// @param _issuer The Keccack256 hashed form of the DID
  function removeKnownIssuer(bytes32 _issuer) external onlyOwner confirmForwarder {
    delete knownIssuers[_issuer];
  }

  /// @notice Sets the DID registry
  /// @dev This registry is what is used during verification to look up the status
  /// @dev of the DIDs.
  /// @param _registry  The registry address
  function setRegistryAddress(IDIDRegistry _registry) external onlyOwner confirmForwarder {
    registry = _registry;
  }

  /// @notice Returns the nonce for a given DID
  /// @param _did The Keccack256 hashed form of the DID
  /// @return The nonce value
  function getNonce(bytes32 _did) external view returns (uint256) {
    return didNonce[_did];
  }

  /// @notice Converts an address to a DID then generates the Keccack256 hash of it
  /// @param _a An address
  /// @return The Keccack256 hash
  function toHashedDid(address _a) private pure returns (bytes32) {
    bytes memory prefix = 'did:onyxidentity:'; /// NOTE: TBD, how to set this? Constant, Argument or Initialized?
    return keccak256(abi.encodePacked(prefix, _a));
  }

  /// @notice Verifies a single credential
  /// @dev Performs basic checks such DID validity, expiry and signature validation.
  /// @dev VerificationResult events are emitted to explain why a verification may have failed.
  /// @param _credential An object representing a verifiable credential
  /// @param _issuerVcProofValue The proof value from a credential held by the issuer of this credential
  /// @param _presentationId The id of the presentation for which this check is being performed. This is purely for reporting.
  /// @return True if the credential passed all checks, False if any failed.
  function verifyCredential(
    OnChainVerifiableCredential memory _credential,
    bytes memory _issuerVcProofValue,
    bytes32 _presentationId
  ) private returns (bool) {
    if (!registry.isActive(_credential.id)) {
      emit VerificationResult(_presentationId, false, 'REVOKED');
      return false;
    }

    if (!registry.isActive(_credential.credentialSubject.id)) {
      emit VerificationResult(_presentationId, false, 'SUBJECT_DID_DEACTIVATED');
      return false;
    }

    if (!registry.isActive(_credential.issuer)) {
      emit VerificationResult(_presentationId, false, 'ISSUER_DID_DEACTIVATED');
      return false;
    }

    bytes32 vcHash = keccak256(
      abi.encode(
        _credential.id,
        _credential.credentialSubject.id,
        _credential.issuer,
        _credential.expirationDate,
        _credential.issuanceDate,
        _credential.types,
        _credential.credentialSubject.data,
        _issuerVcProofValue
      )
    );

    address signer = vcHash.toEthSignedMessageHash().recover(_credential.proof.proofValue);
    bytes32 hashedSigner = toHashedDid(signer);

    if (_credential.issuer != hashedSigner) {
      emit VerificationResult(_presentationId, false, 'INVALID_PROOF');
      return false;
    }

    // NOTE: TBD, Accuracy of block.timestamp permits a small window for an expired credential
    // to pass this check
    if (_credential.expirationDate < block.timestamp) {
      emit VerificationResult(_presentationId, false, 'EXPIRED');
      return false;
    }

    // Note: TBD, will return during round 2 pass
    // if (_credential.issuanceDate >= block.timestamp) {
    //   // TODO: `>` or `>=` ?
    //   emit VerificationResult(_presentationId, false, 'NOT_VALID_YET');
    //   return false;
    // }

    return true;
  }

  /// @notice Verifies a Presentation and the Credentials inside it
  /// @dev All the embedded credentials and the presentation itself must be valid for verification to succeed
  /// @dev VerificationResult events are emitted to explain why a verification may have failed.
  /// @dev An external DID registry is required for verification
  /// @param _presentation An object representing a verifiable presentation
  /// @param _presentationSender the address of the presenation sender as reported to the caller of this function
  /// @return True if the  passed all checks, False if any failed.
  function verifyChain(OnChainVerifiablePresentation memory _presentation, address _presentationSender) public override returns (bool) {
    if (registry == IDIDRegistry(address(0))) {
      emit VerificationResult(_presentation.id, false, 'REGISTRY_NOT_INITIALIZED');
      return false;
    }

    uint256 length = _presentation.verifiableCredential.length;

    if (!(length > 0)) {
      emit VerificationResult(_presentation.id, false, 'CREDENTIALS_MISSING');
      return false;
    }

    if (_presentation.verifiableCredential[0].credentialSubject.id != toHashedDid(_presentationSender)) {
      emit VerificationResult(_presentation.id, false, 'PRESENTATION_INVALID_CALLER');
      return false;
    }

    if (rootIssuer != 0 && _presentation.verifiableCredential[length - 1].issuer != rootIssuer) {
      emit VerificationResult(_presentation.id, false, 'ROOT_ISSUER_UNRECOGNIZED');
      return false;
    }

    if (!knownIssuers[_presentation.verifiableCredential[0].issuer]) {
      emit VerificationResult(_presentation.id, false, 'ISSUER_UNRECOGNIZED');
      return false;
    }

    if (_presentation.proof.nonce != didNonce[_presentation.verifiableCredential[0].credentialSubject.id]) {
      emit VerificationResult(_presentation.id, false, 'INVALID_NONCE');
      return false;
    }

    bytes32 runningHash = keccak256(abi.encode(_presentation.proof.nonce));

    // Verify each VC is valid
    for (uint256 i = 0; i != length; i++) {
      bytes memory issuerVcProof = '0xDECAFBAD'; // TODO: This really necessary?
      if (i + 1 < length) {
        issuerVcProof = _presentation.verifiableCredential[i + 1].proof.proofValue;
      }

      bool result = verifyCredential(_presentation.verifiableCredential[i], issuerVcProof, _presentation.id);
      if (!result) {
        return false;
      }

      runningHash = keccak256(
        abi.encode(
          runningHash,
          _presentation.verifiableCredential[i].id,
          _presentation.verifiableCredential[i].credentialSubject.id,
          _presentation.verifiableCredential[i].issuer,
          _presentation.verifiableCredential[i].expirationDate,
          _presentation.verifiableCredential[i].issuanceDate,
          _presentation.verifiableCredential[i].types,
          _presentation.verifiableCredential[i].credentialSubject.data,
          _presentation.verifiableCredential[i].proof.proofValue
        )
      );
    }

    address signer = runningHash.toEthSignedMessageHash().recover(_presentation.proof.proofValue);
    bytes32 signerHashed = toHashedDid(signer);

    if (signerHashed != _presentation.verifiableCredential[0].credentialSubject.id) {
      emit VerificationResult(_presentation.id, false, 'PRESENTATION_INVALID_PROOF');
      return false;
    }

    ++didNonce[_presentation.verifiableCredential[0].credentialSubject.id];

    emit VerificationResult(_presentation.id, true, '');
    return true;
  }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IDIDRegistry {
  event DIDAttributeChanged(address indexed identity, bytes32 name, bytes value, uint256 validTo, uint256 previousChange);

  function register(string calldata _domain, address _subject) external;

  function deactivate(string calldata _domain, address _subject) external;

  function isActive(string calldata _domain, address _subject) external view returns (bool status);

  function isActive(bytes32 credential) external view returns (bool status);

  function setAttribute(
    address identity,
    bytes32 name,
    bytes calldata value,
    uint256 validity
  ) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

/// Various structs for representing a W3C credential as close to spec as possible given contraints
struct OnChainCredentialSubject {
  bytes32 id;
  bytes data;
}

struct OnChainProof {
  bytes types;
  bytes verificationMethod;
  bytes proofValue;
}

struct OnChainPresentationProof {
  bytes types;
  bytes verificationMethod;
  bytes proofValue;
  uint256 nonce;
}

struct OnChainVerifiableCredential {
  bytes32 id;
  OnChainCredentialSubject credentialSubject;
  bytes32 issuer;
  uint256 expirationDate;
  uint256 issuanceDate;
  bytes types;
  OnChainProof proof;
}

struct OnChainVerifiablePresentation {
  bytes32 id;
  OnChainVerifiableCredential[] verifiableCredential;
  OnChainPresentationProof proof;
}

/// @notice Interface for Verifier smart contract
interface IVerifier {
  event VerificationResult(bytes32 indexed id, bool result, string reason);

  function getNonce(bytes32 _did) external view returns (uint256);

  function verifyChain(OnChainVerifiablePresentation memory presentation, address _presentationSender) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

abstract contract AbstractBase is Initializable, OwnableUpgradeable {
  error CONTRACT_SUSPENDED();
  error TRANSFER_FAILED();
  error INVALID_FORWARDER();

  bool public isPaused;
  address public trustedForwarder;

  /**
   * @notice Allows updating the trusted forwarder to another for this contract
   */
  function setTrustedForwarder(address _trustedForwarder) external virtual onlyOwner confirmForwarder {
    trustedForwarder = _trustedForwarder;
  }

  /**
   * @notice Allows pausing of the operation of this contract.
   */
  function setPause(bool _pause) external virtual onlyOwner confirmForwarder {
    isPaused = _pause;
  }

  /**
   * @notice Transfers contract Ether balance to a given address.
   */
  function recoverBalance(address payable _destination) external virtual onlyOwner confirmForwarder {
    (bool success, ) = _destination.call{value: address(this).balance}('');

    if (!success) {
      revert TRANSFER_FAILED();
    }
  }

  /**
   * @notice Transfers ERC20 balance owned by the contract to a given address.
   */
  function recoverTokenBalance(
    IERC20 _token,
    uint256 _amount,
    address _destination
  ) external virtual onlyOwner confirmForwarder {
    bool success = _token.transfer(_destination, _amount);

    if (!success) {
      revert TRANSFER_FAILED();
    }
  }

  /**
   * @notice ERC2771 support. Taken from openzeppelin/ERC2771Context 4.7.3.
   */
  function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
    return forwarder == trustedForwarder;
  }

  /**
   * @notice ERC2771 support. Taken from openzeppelin/ERC2771Context 4.7.3.
   */
  function _msgSender() internal view virtual override returns (address sender) {
    if (isTrustedForwarder(msg.sender)) {
      // The assembly code is more direct than the Solidity version using `abi.decode`.
      /// @solidity memory-safe-assembly
      assembly {
        sender := shr(96, calldataload(sub(calldatasize(), 20)))
      }
    } else {
      return super._msgSender();
    }
  }

  /**
   * @notice ERC2771 support. Taken from openzeppelin/ERC2771Context 4.7.3.
   */
  function _msgData() internal view virtual override returns (bytes calldata) {
    if (isTrustedForwarder(msg.sender)) {
      return msg.data[:msg.data.length - 20];
    } else {
      return super._msgData();
    }
  }

  /**
   * @notice Check that contract is not paused.
   */
  modifier whileActive() virtual {
    if (isPaused) {
      revert CONTRACT_SUSPENDED();
    }

    _;
  }

  /**
   * @notice Support for ERC2771. This method only does rudimentary address checking against a known-good sender address that is expected to be set in a constructor or initializer of the implementing contract.
   */
  modifier confirmForwarder() virtual {
    if (trustedForwarder != address(0) && msg.sender != trustedForwarder) {
      revert INVALID_FORWARDER();
    }

    _;
  }
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