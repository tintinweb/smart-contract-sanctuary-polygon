// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "../../utils/DataTypes.sol";
import "../../utils/LoanDataTypes.sol";
import "../Interfaces/lib/ISigningUtils.sol";

/// @title NF3 Signing Utils
/// @author NF3 Exchange
/// @dev  Helper contract for Protocol. This contract manages verifying signatures
///       from off-chain Protocol orders.

contract SigningUtil is EIP712, ISigningUtils {
    /// -----------------------------------------------------------------------
    /// Library usage
    /// -----------------------------------------------------------------------
    using ECDSA for bytes32;

    /// -----------------------------------------------------------------------
    /// Storage variables
    /// -----------------------------------------------------------------------

    bytes32 private immutable ASSETS_TYPE_HASH;
    bytes32 private immutable SWAP_ASSETS_TYPE_HASH;
    bytes32 private immutable RESERVE_INFO_TYPE_HASH;
    bytes32 private immutable ROYALTY_TYPE_HASH;
    bytes32 private immutable LISTING_TYPE_HASH;
    bytes32 private immutable SWAP_OFFER_TYPE_HASH;
    bytes32 private immutable RESERVE_OFFER_TYPE_HASH;
    bytes32 private immutable COLLECTION_SWAP_OFFER_TYPE_HASH;
    bytes32 private immutable COLLECTION_RESERVE_OFFER_TYPE_HASH;
    bytes32 private immutable LOAN_OFFER_TYPE_HASH;
    bytes32 private immutable COLLECTION_LOAN_OFFER_TYPE_HASH;
    bytes32 private immutable LOAN_UPDATE_OFFER_TYPE_HASH;

    /* ===== INIT ===== */

    /// @dev Constructor
    /// @param _name Name of the protcol
    /// @param _version Version of the protocol
    /// @dev Calculate and set type hashes for all the structs and nested structs types
    constructor(string memory _name, string memory _version)
        EIP712(_name, _version)
    {
        // build individual type strings
        bytes memory assetsTypeString = abi.encodePacked(
            "Assets(",
            "address[] tokens,",
            "uint256[] tokenIds,",
            "address[] paymentTokens,",
            "uint256[] amounts",
            ")"
        );

        bytes memory swapAssetsTypeString = abi.encodePacked(
            "SwapAssets(",
            "address[] tokens,",
            "bytes32[] roots,",
            "address[] paymentTokens,",
            "uint256[] amounts",
            ")"
        );

        bytes memory reserveInfoTypeString = abi.encodePacked(
            "ReserveInfo(",
            "Assets deposit,",
            "Assets remaining,",
            "uint256 duration",
            ")"
        );

        bytes memory royaltyTypeString = abi.encodePacked(
            "Royalty(",
            "address[] to,",
            "uint256[] percentage",
            ")"
        );

        bytes memory listingTypeString = abi.encodePacked(
            "Listing(",
            "Assets listingAssets,"
            "SwapAssets[] directSwaps,"
            "ReserveInfo[] reserves,"
            "Royalty royalty,"
            "address tradeIntendedFor,"
            "uint256 timePeriod,"
            "address owner,"
            "uint256 nonce"
            ")"
        );

        bytes memory swapOfferTypeString = abi.encodePacked(
            "SwapOffer(",
            "Assets offeringItems,",
            "Royalty royalty,",
            "bytes32 considerationRoot,",
            "uint256 timePeriod,",
            "address owner,",
            "uint256 nonce",
            ")"
        );

        bytes memory reserveOfferTypeString = abi.encodePacked(
            "ReserveOffer(",
            "ReserveInfo reserveDetails,",
            "bytes32 considerationRoot,",
            "Royalty royalty,",
            "uint256 timePeriod,",
            "address owner,",
            "uint256 nonce",
            ")"
        );

        bytes memory collectionSwapOfferTypeString = abi.encodePacked(
            "CollectionSwapOffer(",
            "Assets offeringItems,",
            "SwapAssets considerationItems,",
            "Royalty royalty,",
            "uint256 timePeriod,",
            "address owner,",
            "uint256 nonce",
            ")"
        );

        bytes memory collectionReserveOfferTypeString = abi.encodePacked(
            "CollectionReserveOffer(",
            "ReserveInfo reserveDetails,",
            "SwapAssets considerationItems,",
            "Royalty royalty,",
            "uint256 timePeriod,",
            "address owner,",
            "uint256 nonce",
            ")"
        );

        bytes memory loanOfferTypeString = abi.encodePacked(
            "LoanOffer(",
            "address nftCollateralContract,",
            "uint256 nftCollateralId,",
            "address owner,",
            "uint256 nonce,",
            "address loanPaymentToken,",
            "uint256 loanPrincipalAmount,",
            "uint256 maximumRepaymentAmount,",
            "uint256 loanDuration,",
            "uint256 loanInterestRate,",
            "uint256 adminFees,",
            "bool isLoanProrated,",
            "bool isBorrowerTerms",
            ")"
        );

        bytes memory collectionLoanOfferTypeString = abi.encodePacked(
            "CollectionLoanOffer(",
            "address nftCollateralContract,",
            "bytes32 nftCollateralIdRoot,",
            "address owner,",
            "uint256 nonce,",
            "address loanPaymentToken,",
            "uint256 loanPrincipalAmount,",
            "uint256 maximumRepaymentAmount,",
            "uint256 loanDuration,",
            "uint256 loanInterestRate,",
            "uint256 adminFees,",
            "bool isLoanProrated",
            ")"
        );

        bytes memory loanUpdateOfferTypeString = abi.encodePacked(
            "LoanUpdateOffer(",
            "uint256 loanId,",
            "uint256 maximumRepaymentAmount,",
            "uint256 loanDuration,",
            "uint256 loanInterestRate,",
            "address owner,",
            "uint256 nonce,",
            "bool isLoanProrated,",
            "bool isBorrowerTerms",
            ")"
        );

        // build collective type strings and type hashes
        SWAP_OFFER_TYPE_HASH = keccak256(
            abi.encodePacked(
                swapOfferTypeString,
                assetsTypeString,
                royaltyTypeString
            )
        );
        RESERVE_OFFER_TYPE_HASH = keccak256(
            abi.encodePacked(
                reserveOfferTypeString,
                assetsTypeString,
                reserveInfoTypeString,
                royaltyTypeString
            )
        );
        COLLECTION_SWAP_OFFER_TYPE_HASH = keccak256(
            abi.encodePacked(
                collectionSwapOfferTypeString,
                assetsTypeString,
                royaltyTypeString,
                swapAssetsTypeString
            )
        );
        COLLECTION_RESERVE_OFFER_TYPE_HASH = keccak256(
            abi.encodePacked(
                collectionReserveOfferTypeString,
                assetsTypeString,
                reserveInfoTypeString,
                royaltyTypeString,
                swapAssetsTypeString
            )
        );
        ASSETS_TYPE_HASH = keccak256(assetsTypeString);
        SWAP_ASSETS_TYPE_HASH = keccak256(swapAssetsTypeString);
        RESERVE_INFO_TYPE_HASH = keccak256(
            abi.encodePacked(reserveInfoTypeString, assetsTypeString)
        );
        ROYALTY_TYPE_HASH = keccak256(royaltyTypeString);
        LISTING_TYPE_HASH = keccak256(
            abi.encodePacked(
                listingTypeString,
                assetsTypeString,
                reserveInfoTypeString,
                royaltyTypeString,
                swapAssetsTypeString
            )
        );
        LOAN_OFFER_TYPE_HASH = keccak256(loanOfferTypeString);
        COLLECTION_LOAN_OFFER_TYPE_HASH = keccak256(
            collectionLoanOfferTypeString
        );
        LOAN_UPDATE_OFFER_TYPE_HASH = keccak256(loanUpdateOfferTypeString);
    }

    /// -----------------------------------------------------------------------
    /// Signature Verification Actions
    /// -----------------------------------------------------------------------

    /// @notice Inherit from ISigningUtils
    function verifyListingSignature(
        Listing calldata listing,
        bytes memory signature
    ) external view override {
        uint256 swapCount = listing.directSwaps.length;
        uint256 reserveCount = listing.reserves.length;
        bytes32[] memory directSwapHashes = new bytes32[](swapCount);
        bytes32[] memory reserveHashes = new bytes32[](reserveCount);
        for (uint256 i = 0; i < swapCount; ++i) {
            directSwapHashes[i] = _hashSwapAssets(listing.directSwaps[i]);
        }
        for (uint256 i = 0; i < reserveCount; ++i) {
            reserveHashes[i] = _hashReserve(listing.reserves[i]);
        }

        bytes32 listingHash = keccak256(
            abi.encode(
                LISTING_TYPE_HASH,
                _hashAssets(listing.listingAssets),
                keccak256(abi.encodePacked(directSwapHashes)),
                keccak256(abi.encodePacked(reserveHashes)),
                _hashRoyalty(listing.royalty),
                listing.tradeIntendedFor,
                listing.timePeriod,
                listing.owner,
                listing.nonce
            )
        );

        address signer = _hashTypedDataV4(listingHash).recover(signature);

        if (listing.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_LISTING_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifySwapOfferSignature(
        SwapOffer calldata offer,
        bytes memory signature
    ) external view override {
        bytes32 swapOfferHash = keccak256(
            abi.encode(
                SWAP_OFFER_TYPE_HASH,
                _hashAssets(offer.offeringItems),
                _hashRoyalty(offer.royalty),
                offer.considerationRoot,
                offer.timePeriod,
                offer.owner,
                offer.nonce
            )
        );
        address signer = _hashTypedDataV4(swapOfferHash).recover(signature);
        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_SWAP_OFFER_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifyCollectionSwapOfferSignature(
        CollectionSwapOffer calldata offer,
        bytes memory signature
    ) external view override {
        bytes32 collectionSwapOfferHash = keccak256(
            abi.encode(
                COLLECTION_SWAP_OFFER_TYPE_HASH,
                _hashAssets(offer.offeringItems),
                _hashSwapAssets(offer.considerationItems),
                _hashRoyalty(offer.royalty),
                offer.timePeriod,
                offer.owner,
                offer.nonce
            )
        );
        address signer = _hashTypedDataV4(collectionSwapOfferHash).recover(
            signature
        );
        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_COLLECTION_SWAP_OFFER_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifyReserveOfferSignature(
        ReserveOffer calldata offer,
        bytes memory signature
    ) external view override {
        bytes32 reserveOfferHash = keccak256(
            abi.encode(
                RESERVE_OFFER_TYPE_HASH,
                _hashReserve(offer.reserveDetails),
                offer.considerationRoot,
                _hashRoyalty(offer.royalty),
                offer.timePeriod,
                offer.owner,
                offer.nonce
            )
        );
        address signer = _hashTypedDataV4(reserveOfferHash).recover(signature);
        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_RESERVE_OFFER_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifyCollectionReserveOfferSignature(
        CollectionReserveOffer calldata offer,
        bytes memory signature
    ) external view override {
        bytes32 collectionReserveOffer = keccak256(
            abi.encode(
                COLLECTION_RESERVE_OFFER_TYPE_HASH,
                _hashReserve(offer.reserveDetails),
                _hashSwapAssets(offer.considerationItems),
                _hashRoyalty(offer.royalty),
                offer.timePeriod,
                offer.owner,
                offer.nonce
            )
        );
        address signer = _hashTypedDataV4(collectionReserveOffer).recover(
            signature
        );
        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes
                    .INVALID_COLLECTION_RESERVE_OFFER_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifyLoanOfferSignature(
        LoanOffer calldata offer,
        bytes memory signature
    ) external view override {
        // splitting the acutal string to be hashed in two parts
        // workaround to prevent stack too deep error -_-
        bytes memory secondHalf = abi.encode(
            offer.loanDuration,
            offer.loanInterestRate,
            offer.adminFees,
            offer.isLoanProrated,
            offer.isBorrowerTerms
        );
        bytes memory firstHalf = abi.encode(
            LOAN_OFFER_TYPE_HASH,
            offer.nftCollateralContract,
            offer.nftCollateralId,
            offer.owner,
            offer.nonce,
            offer.loanPaymentToken,
            offer.loanPrincipalAmount,
            offer.maximumRepaymentAmount
        );
        bytes32 loanOffer = keccak256(abi.encodePacked(firstHalf, secondHalf));
        address signer = _hashTypedDataV4(loanOffer).recover(signature);

        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_LOAN_OFFER_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifyCollectionLoanOfferSignature(
        CollectionLoanOffer calldata offer,
        bytes memory signature
    ) external view override {
        bytes32 collectionLoanOffer = keccak256(
            abi.encode(
                COLLECTION_LOAN_OFFER_TYPE_HASH,
                offer.nftCollateralContract,
                offer.nftCollateralIdRoot,
                offer.owner,
                offer.nonce,
                offer.loanPaymentToken,
                offer.loanPrincipalAmount,
                offer.maximumRepaymentAmount,
                offer.loanDuration,
                offer.loanInterestRate,
                offer.adminFees,
                offer.isLoanProrated
            )
        );
        address signer = _hashTypedDataV4(collectionLoanOffer).recover(
            signature
        );
        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_COLLECTION_LOAN_OFFER_SIGNATURE
            );
        }
    }

    /// @notice Inherit from ISigningUtils
    function verifyUpdateLoanSignature(
        LoanUpdateOffer calldata offer,
        bytes memory signature
    ) external view override {
        bytes32 loanUpdateOffer = keccak256(
            abi.encode(
                LOAN_UPDATE_OFFER_TYPE_HASH,
                offer.loanId,
                offer.maximumRepaymentAmount,
                offer.loanDuration,
                offer.loanInterestRate,
                offer.owner,
                offer.nonce,
                offer.isLoanProrated,
                offer.isBorrowerTerms
            )
        );
        address signer = _hashTypedDataV4(loanUpdateOffer).recover(signature);
        if (offer.owner != signer) {
            revert SigningUtilsError(
                SigningUtilsErrorCodes.INVALID_UPDATE_LOAN_OFFER_SIGNATURE
            );
        }
    }

    /// -----------------------------------------------------------------------
    /// Internal functions
    /// -----------------------------------------------------------------------

    /// @dev Get eip 712 compliant hash for Royalty struct type
    /// @param royalty Royalty struct to be hashed
    function _hashRoyalty(Royalty calldata royalty)
        internal
        view
        returns (bytes32)
    {
        bytes32 royaltyHash = keccak256(
            abi.encode(
                ROYALTY_TYPE_HASH,
                keccak256(abi.encodePacked(royalty.to)),
                keccak256(abi.encodePacked(royalty.percentage))
            )
        );
        return royaltyHash;
    }

    /// @dev Get eip 712 compliant hash for ReserveInfo struct type
    /// @param reserve ReserveInfo struct to be hashed
    function _hashReserve(ReserveInfo calldata reserve)
        internal
        view
        returns (bytes32)
    {
        bytes32 reserveHash = keccak256(
            abi.encode(
                RESERVE_INFO_TYPE_HASH,
                _hashAssets(reserve.deposit),
                _hashAssets(reserve.remaining),
                reserve.duration
            )
        );
        return reserveHash;
    }

    /// @dev Get eip 712 compliant hash for SwapAssets struct type
    /// @param directSwap SwapAssets struct to be hashed
    function _hashSwapAssets(SwapAssets calldata directSwap)
        internal
        view
        returns (bytes32)
    {
        bytes32 assetsTypeHash = keccak256(
            abi.encode(
                SWAP_ASSETS_TYPE_HASH,
                keccak256(abi.encodePacked(directSwap.tokens)),
                keccak256(abi.encodePacked(directSwap.roots)),
                keccak256(abi.encodePacked(directSwap.paymentTokens)),
                keccak256(abi.encodePacked(directSwap.amounts))
            )
        );
        return assetsTypeHash;
    }

    /// @dev Get eip 712 compliant hash for Assets struct type
    /// @param _assets Assets struct to be hashed
    function _hashAssets(Assets calldata _assets)
        internal
        view
        returns (bytes32)
    {
        bytes32 assetsTypeHash = keccak256(
            abi.encode(
                ASSETS_TYPE_HASH,
                keccak256(abi.encodePacked(_assets.tokens)),
                keccak256(abi.encodePacked(_assets.tokenIds)),
                keccak256(abi.encodePacked(_assets.paymentTokens)),
                keccak256(abi.encodePacked(_assets.amounts))
            )
        );
        return assetsTypeHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.3) (utils/cryptography/ECDSA.sol)

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

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @dev Royalties for collection creators and platform fee for platform manager.
///      to[0] is platform owner address.
/// @param to Creators and platform manager address array
/// @param percentage Royalty percentage based on the listed FT
struct Royalty {
    address[] to;
    uint256[] percentage;
}

/// @dev Common Assets type, packing bundle of NFTs and FTs.
/// @param tokens NFT asset address
/// @param tokenIds NFT token id
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct Assets {
    address[] tokens;
    uint256[] tokenIds;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common SwapAssets type, packing Bundle of NFTs and FTs. Notice tokenIds are represented by merkle roots
///      Each collection address ie. tokens[i] will have a merkle root corrosponding it's valid tokenIds.
///      This is used to select particular tokenId in corrospoding collection. If roots[i]
///      has the value of bytes32(0), this means the entire collection is considered valid.
/// @param tokens NFT asset address
/// @param roots Merkle roots of the criterias. NOTE: bytes32(0) represents the entire collection
/// @param paymentTokens FT asset address
/// @param amounts FT token amount
struct SwapAssets {
    address[] tokens;
    bytes32[] roots;
    address[] paymentTokens;
    uint256[] amounts;
}

/// @dev Common Reserve type, packing data related to reserve listing and reserve offer.
/// @param deposit Assets considered as initial deposit
/// @param remaining Assets considered as due amount
/// @param duration Duration of reserve now swap later
struct ReserveInfo {
    Assets deposit;
    Assets remaining;
    uint256 duration;
}

/// @dev All the reservation details that are stored in the position token
/// @param reservedAssets Assets that were reserved as a part of the reservation
/// @param reservedAssestsRoyalty Royalty offered by the assets owner
/// @param reserveInfo Deposit, remainig and time duriation details of the reservation
/// @param assetOwner Original owner of the reserved assets
struct Reservation {
    Assets reservedAssets;
    Royalty reservedAssetsRoyalty;
    ReserveInfo reserveInfo;
    address assetOwner;
}

/// @dev Listing type, packing the assets being listed, listing parameters, listing owner
///      and users's nonce.
/// @param listingAssets All the assets listed
/// @param directSwaps List of options for direct swap
/// @param reserves List of options for reserve now swap later
/// @param royalty Listing royalty and platform fee info
/// @param timePeriod Time period of listing
/// @param owner Owner's address
/// @param nonce User's nonce
struct Listing {
    Assets listingAssets;
    SwapAssets[] directSwaps;
    ReserveInfo[] reserves;
    Royalty royalty;
    address tradeIntendedFor;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Listing type of special NF3 banner listing
/// @param token address of collection
/// @param tokenId token id being listed
/// @param editions number of tokenIds being distributed
/// @param gateCollectionsRoot merkle root for eligible collections
/// @param timePeriod timePeriod of listing
/// @param owner owner of listing
struct NF3GatedListing {
    address token;
    uint256 tokenId;
    uint256 editions;
    bytes32 gatedCollectionsRoot;
    uint256 timePeriod;
    address owner;
}

/// @dev Swap Offer type info.
/// @param offeringItems Assets being offered
/// @param royalty Swap offer royalty info
/// @param considerationRoot Assets to which this offer is made
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct SwapOffer {
    Assets offeringItems;
    Royalty royalty;
    bytes32 considerationRoot;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Reserve now swap later type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationRoot Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct ReserveOffer {
    ReserveInfo reserveDetails;
    bytes32 considerationRoot;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection offer type info.
/// @param offeringItems Assets being offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Collection offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionSwapOffer {
    Assets offeringItems;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Collection Reserve type offer info.
/// @param reserveDetails Reservation scheme begin offered
/// @param considerationItems Assets to which this offer is made
/// @param royalty Reserve offer royalty info
/// @param timePeriod Time period of offer
/// @param owner Offer owner
/// @param nonce Offer nonce
struct CollectionReserveOffer {
    ReserveInfo reserveDetails;
    SwapAssets considerationItems;
    Royalty royalty;
    uint256 timePeriod;
    address owner;
    uint256 nonce;
}

/// @dev Swap Params type to be used as one of the input params
/// @param tokens Tokens provided in the parameters
/// @param tokenIds Token Ids provided in the parameters
/// @param proofs Merkle proofs provided in the parameters
struct SwapParams {
    address[] tokens;
    uint256[] tokenIds;
    bytes32[][] proofs;
}

/// @dev Fees struct to be used to signify fees to be paid by a party
/// @param token Address of erc20 tokens to be used for payment
/// @param amount amount of tokens to be paid respectively
/// @param to address to which the fee is paid
struct Fees {
    address token;
    uint256 amount;
    address to;
}

enum Status {
    AVAILABLE,
    EXHAUSTED
}

enum AssetType {
    INVALID,
    ETH,
    ERC_20,
    ERC_721,
    ERC_1155,
    KITTIES,
    PUNK
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

/// @dev Common loan offer struct to be used both the borrower and lender
///      to propose new offers,
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralId NFT collateral token id
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param loanPaymentToken Address of the loan payment token
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param adminFees Admin fees in basis points
/// @param isLoanProrated Flag for interest rate type of loan
/// @param isBorrowerTerms Bool value to represent if borrower's terms were accepted.
///        - if this value is true, this mean msg.sender must be the lender.
///        - if this value is false, this means lender's terms were accepted and msg.sender
///          must be the borrower.
struct LoanOffer {
    address nftCollateralContract;
    uint256 nftCollateralId;
    address owner;
    uint256 nonce;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
    bool isBorrowerTerms;
}

/// @dev Collection loan offer struct to be used to making collection
///      specific offers and trait level offers.
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralIdRoot Merkle root of the tokenIds for collateral
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param loanPaymentToken Address of the loan payment token
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param adminFees Admin fees in basis points
/// @param isLoanProrated Flag for interest rate type of loan
struct CollectionLoanOffer {
    address nftCollateralContract;
    bytes32 nftCollateralIdRoot;
    address owner;
    uint256 nonce;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
}

/// @dev Update loan offer struct to propose new terms for an ongoing loan.
/// @param loanId Id of the loan, same as promissory tokenId
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest rate of the loan
/// @param owner Offer owner address
/// @param nonce Nonce of owner
/// @param isLoanProrated Flag for interest rate type of loan
/// @param isBorrowerTerms Bool value to represent if borrower's terms were accepted.
///        - if this value is true, this mean msg.sender must be the lender.
///        - if this value is false, this means lender's terms were accepted and msg.sender
///          must be the borrower.
struct LoanUpdateOffer {
    uint256 loanId;
    uint256 maximumRepaymentAmount;
    uint256 loanDuration;
    uint256 loanInterestRate;
    address owner;
    uint256 nonce;
    bool isLoanProrated;
    bool isBorrowerTerms;
}

/// @dev Main loan struct that stores the details of an ongoing loan.
///      This struct is used to create hashes and store them in promissory tokens.
/// @param loanId Id of the loan, same as promissory tokenId
/// @param nftCollateralContract Address of the NFT contract
/// @param nftCollateralId TokenId of the NFT collateral
/// @param loanPaymentToken Address of the ERC20 token involved
/// @param loanPrincipalAmount Principal amount of the loan
/// @param maximumRepaymentAmount Maximum amount to be repayed
/// @param loanStartTime Timestamp of when the loan started
/// @param loanDuration Duration of the loan
/// @param loanInterestRate Interest Rate of the loan
/// @param isLoanProrated Flag for interest rate type of loan
struct Loan {
    uint256 loanId;
    address nftCollateralContract;
    uint256 nftCollateralId;
    address loanPaymentToken;
    uint256 loanPrincipalAmount;
    uint256 maximumRepaymentAmount;
    uint256 loanStartTime;
    uint256 loanDuration;
    uint256 loanInterestRate;
    uint256 adminFees;
    bool isLoanProrated;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;

import "../../../utils/DataTypes.sol";
import "../../../utils/LoanDataTypes.sol";

interface ISigningUtils {
    /// -----------------------------------------------------------------------
    /// Errors
    /// -----------------------------------------------------------------------

    enum SigningUtilsErrorCodes {
        INVALID_LISTING_SIGNATURE,
        INVALID_SWAP_OFFER_SIGNATURE,
        INVALID_COLLECTION_SWAP_OFFER_SIGNATURE,
        INVALID_RESERVE_OFFER_SIGNATURE,
        INVALID_COLLECTION_RESERVE_OFFER_SIGNATURE,
        INVALID_LOAN_OFFER_SIGNATURE,
        INVALID_COLLECTION_LOAN_OFFER_SIGNATURE,
        INVALID_UPDATE_LOAN_OFFER_SIGNATURE
    }

    error SigningUtilsError(SigningUtilsErrorCodes code);

    /// -----------------------------------------------------------------------
    /// Signature Verification Actions
    /// -----------------------------------------------------------------------

    /// @dev Check the signature if the listing info is valid or not.
    /// @param _listing Listing info
    /// @param signature Listing signature
    function verifyListingSignature(
        Listing calldata _listing,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the swap offer is valid or not.
    /// @param offer Offer info
    /// @param signature Offer signature
    function verifySwapOfferSignature(
        SwapOffer calldata offer,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the collection offer is valid or not.
    /// @param offer Offer info
    /// @param signature Offer signature
    function verifyCollectionSwapOfferSignature(
        CollectionSwapOffer calldata offer,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the reserve offer is valid or not.
    /// @param offer Reserve offer info
    /// @param signature Reserve offer signature
    function verifyReserveOfferSignature(
        ReserveOffer calldata offer,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the collection reserve offer is valid or not.
    /// @param offer Reserve offer info
    /// @param signature Reserve offer signature
    function verifyCollectionReserveOfferSignature(
        CollectionReserveOffer calldata offer,
        bytes calldata signature
    ) external view;

    /// @dev Check the signature if the loan offer is valid or not.
    /// @param offer Loan offer info
    /// @param signature Loan offer signature
    function verifyLoanOfferSignature(
        LoanOffer calldata offer,
        bytes memory signature
    ) external view;

    /// @dev Check the signature if the collection loan offer is valid or not.
    /// @param offer Collection loan offer info
    /// @param signature Collection loan offer signature
    function verifyCollectionLoanOfferSignature(
        CollectionLoanOffer calldata offer,
        bytes memory signature
    ) external view;

    /// @dev Check the signature if the update loan offer is valid or not.
    /// @param offer Update loan offer info
    /// @param signature Update loan offer signature
    function verifyUpdateLoanSignature(
        LoanUpdateOffer calldata offer,
        bytes memory signature
    ) external view;
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