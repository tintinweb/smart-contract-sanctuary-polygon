// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {LibCommon} from "../../shared/libraries/LibCommon.sol";
import {LibNFT} from "../libraries/LibNFT.sol"; 
import {LibFixedPrice} from "../libraries/LibFixedPrice.sol";
import {
    AppStorage,
    Modifiers,
    AssetStandard,
    AssetVersion
} from "../libraries/LibAppStorage.sol";
import {
    LibOrders,
    MintERC721Order,
    AuctionResolveOrder,
    MintERC721BatchOrder,
    RedeemERC721Order,
    RedeemERC721BundleOrder
} from "../../shared/libraries/LibOrders.sol"; 

/// @title ERC721 minting-related functions.
/// @author Nypox
contract ERC721MintFacet is Modifiers {
    AppStorage internal s;

    event RoyaltyPayed(
        address indexed token,
        address paymentToken,
        address buyer,
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 value
    );

    event ComissionPayed(
        address paymentToken,
        address indexed buyer,
        address indexed receiver,
        uint256 value
    ); 
    
/// @dev Mints a token `order.id` to address `order.to`.
    function ERC721Mint(
        MintERC721Order calldata order,
        bytes calldata marketSignature
    ) external {

        require(
            order.to == LibCommon.msgSender(),
            "ERC721Mint: NOT_ALLOWED"
        );

        require(
            s.marketConfig.signers[ECDSA.recover(LibOrders.hashMintOrderId(order.token, order.id), marketSignature)],
            "auctionResolve: INVALID_MARKET_SIGNATURE"
        );

        AssetVersion version = LibNFT.getAssetVersion(order.token);

        LibNFT.checkAssetVersionIsDefault(AssetStandard.ERC721, version);

        LibNFT.mintERC721(order, version, false); 
    }

/// @dev Batched version of {ERC721Mint}.
    function ERC721MintBatch(
        MintERC721BatchOrder calldata order,
        bytes calldata marketSignature
    ) external {

        require(
            order.to == LibCommon.msgSender(),
            "ERC721F: NOT_ALLOWED"
        );

        require(
            s.marketConfig.signers[ECDSA.recover(LibOrders.hashMintOrderIds(order.token, order.ids), marketSignature)],
            "auctionResolve: INVALID_MARKET_SIGNATURE"
        );

        AssetVersion version = LibNFT.getAssetVersion(order.token);

        LibNFT.checkAssetVersionIsDefault(AssetStandard.ERC721, version);

        LibNFT.mintERC721Batch(order, version, false); 
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

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
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
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
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

library LibCommon {

    function msgSender() internal view returns (address sender) {
        return msg.sender;
    }

    function msgData() internal pure returns (bytes calldata) {
        return msg.data;
    }

    function verifyLeaf(bytes32 _leaf, bytes32[] memory _proof, bytes32 _root)
    internal pure returns (bool)
    {
        return MerkleProof.verify(_proof, _root, _leaf);
    }

    function verify(
        bytes32 digest,
        address signer,
        bytes memory signature
    ) internal pure returns (bool) {

        return signer == ECDSA.recover(digest, signature);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {IFERC721V1} from "../../tokens/IFERC721V1.sol"; 
import {IFERC1155V1} from "../../tokens/IFERC1155V1.sol";
import {LibTransfer} from "./LibTransfer.sol"; 
import {ERC2981Base} from "../../tokens/ERC2981Base.sol";
import {
    LibAppStorage,
    AppStorage,
    AssetStandard,
    AssetVersion,
    Asset,
    Bundle
} from "../libraries/LibAppStorage.sol";
import {
    MintERC721Order,
    MintERC721BatchOrder,
    MintERC1155Order,
    MintERC1155BatchOrder,
    RedeemERC721Order,
    RedeemERC721BundleOrder,
    RedeemERC1155Order,
    RedeemERC1155BundleOrder
} from "../../shared/libraries/LibOrders.sol"; 

library LibNFT {

    using SafeERC20 for IERC20;

    function getAssetVersion( 
        address token
    ) internal view returns (AssetVersion) {

        AppStorage storage s = LibAppStorage.diamondStorage();

        AssetVersion version = s.marketConfig.assetTokenVersions[token];

        return version;
    }

    function checkAssetVersionIsDefault( 
        AssetStandard standard,
        AssetVersion version
    ) internal view {

        AppStorage storage s = LibAppStorage.diamondStorage();

        require(
            version == s.marketConfig.defaultTokenVersions[standard],
            "checkAssetVersionIsDefault: INVALID_TOKEN_VERSION"
        );
    }

    function mintERC721(
        MintERC721Order memory order,
        AssetVersion assetVersion,
        bool approve
    ) internal {

        if (assetVersion == AssetVersion.V1) {
            IFERC721V1(order.token).mint(order, approve, false, "");
        }
    }

    function mintERC1155(
        MintERC1155Order memory order,
        AssetVersion assetVersion,
        bool approve
    ) internal {

        if (assetVersion == AssetVersion.V1) {
            IFERC1155V1(order.token).mint(order, approve, false, "");
        }
    }

    function mintERC721Batch(
        MintERC721BatchOrder calldata order,
        AssetVersion assetVersion,
        bool approve
    ) internal {

        if (assetVersion == AssetVersion.V1) {
            IFERC721V1(order.token).mintBatch(order, approve, false, "");
        }
    }

    function mintERC1155Batch(
        MintERC1155BatchOrder calldata order,
        AssetVersion assetVersion,
        bool approve
    ) internal {

        if (assetVersion == AssetVersion.V1) {
            IFERC1155V1(order.token).mintBatch(order, approve, false, "");
        }
    }

    function redeemERC721(
        RedeemERC721Order memory order
    ) internal {

        if (order.price > 0) {

          uint256 royaltyPayed = LibTransfer.payRoyalty(
              order.token,
              order.paymentToken,
              order.to,
              order.to,
              order.id,
              order.price
          );

          uint256 comissionPayed = LibTransfer.payComission(
              order.paymentToken,
              order.to,
              order.to,
              order.price
          );

          LibTransfer.executePayment(
              order.paymentToken,
              order.targetToken,
              order.to,
              order.from,
              order.price - royaltyPayed - comissionPayed
          );
        }

        IERC721(order.token).safeTransferFrom(
            order.from,
            order.to,
            order.id,
            ""
        );
    }

    function redeemERC721Bundle(
        RedeemERC721BundleOrder calldata order
    ) internal {

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 value;
        uint256 royaltyTotal;

        uint256 minPrice = s.marketConfig.minPrices[order.paymentToken];

        for (uint256 i = 0; i < order.ids.length; i++) {

            if (order.prices[i] > 0) {

              require(
                  order.prices[i] > minPrice,
                  "redeemERC721Bundle: INVALID_PRICE"
              );

              uint256 royaltyPayed = LibTransfer.payRoyalty(
                  order.tokens[i],
                  order.paymentToken,
                  order.to,
                  order.to,
                  order.ids[i], 
                  order.prices[i]
              );

              royaltyTotal += royaltyPayed;
              value += order.prices[i];
            }
        }

        if (value > 0) {

          uint256 comissionPayed = LibTransfer.payComission(
              order.paymentToken,
              order.to,
              order.to,
              value
          );

          LibTransfer.executePayment(
              order.paymentToken,
              order.targetToken,
              order.to,
              order.from,
              value - royaltyTotal - comissionPayed
          );
        }

        for (uint256 i = 0; i < order.ids.length; i++) {

            IERC721(order.tokens[i]).safeTransferFrom(
                order.from,
                order.to,
                order.ids[i],
                ""
            );
        }
    }

    function redeemERC1155(
        RedeemERC1155Order memory order
    ) internal {

        if (order.price > 0) {

          uint256 value = order.price * order.amount;

          if (value == 0) {
              revert("redeemERC1155: ZERO_AMOUNT");
          }

          uint256 royaltyPayed = LibTransfer.payRoyalty(
              order.token,
              order.paymentToken,
              order.to,
              order.to,
              order.id,
              value
          );

          uint256 comissionPayed = LibTransfer.payComission(
              order.paymentToken,
              order.to,
              order.to,
              value
          );

          LibTransfer.executePayment(
              order.paymentToken,
              order.targetToken,
              order.to,
              order.from,
              value - royaltyPayed - comissionPayed
          );
        }

        IERC1155(order.token).safeTransferFrom(
            order.from,
            order.to,
            order.id,
            order.amount,
            ""
        );
    }

    function redeemERC1155Bundle(
        RedeemERC1155BundleOrder calldata order
    ) internal {

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 value;
        uint256 royaltyTotal;

        uint256 minPrice = s.marketConfig.minPrices[order.paymentToken];

        for (uint256 i = 0; i < order.ids.length; i++) {

            if (order.prices[i] > 0) {

              require(
                  order.prices[i] > minPrice,
                  "redeemERC1155Bundle: INVALID_PRICE"
              );

              uint256 ivalue = order.prices[i] * order.amounts[i];

              uint256 royaltyPayed = LibTransfer.payRoyalty(
                  order.tokens[i],
                  order.paymentToken,
                  order.to,
                  order.to,
                  order.ids[i],
                  ivalue
              );

              value += ivalue;
              royaltyTotal += royaltyPayed;
            }
        }

        if (value > 0) {

          uint256 comissionPayed = LibTransfer.payComission(
              order.paymentToken,
              order.to,
              order.to,
              value
          );

          LibTransfer.executePayment(
              order.paymentToken,
              order.targetToken,
              order.to,
              order.from,
              value - royaltyTotal - comissionPayed
          );
        }

        for (uint256 i = 0; i < order.ids.length; i++) {

            IERC1155(order.tokens[i]).safeTransferFrom(
                order.from,
                order.to,
                order.ids[i],
                order.amounts[i],
                ""
            );
        }
    }

    function mintBundle(
        Bundle storage bundle
    ) internal {

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 bundleSize = bundle.ids.length;

        for (uint256 i = 0; i < bundleSize; i++) {

            Asset storage asset = s.market.assets[bundle.owner][bundle.tokens[i]][bundle.ids[i]];

            if (asset.standard == AssetStandard.ERC721) {

                MintERC721Order memory mintOrder;
                mintOrder.token = bundle.tokens[i];
                mintOrder.to = bundle.owner;
                mintOrder.id = bundle.ids[i];
                mintOrder.uri = asset.uri;
                mintOrder.royalty = asset.royalty;

                AssetVersion version = getAssetVersion(mintOrder.token);

                mintERC721(mintOrder, version, true);

                RedeemERC721Order memory redeemOrder;
                redeemOrder.token = bundle.tokens[i];
                redeemOrder.from = bundle.owner;
                redeemOrder.to = address(this);
                redeemOrder.id = bundle.ids[i];
                redeemOrder.paymentToken = bundle.paymentToken;
                redeemOrder.targetToken = bundle.targetToken;
                redeemOrder.price = asset.price;

                redeemERC721(redeemOrder);  
            }

            if (asset.standard == AssetStandard.ERC1155) {

                MintERC1155Order memory mintOrder;
                mintOrder.token = bundle.tokens[i];
                mintOrder.to = bundle.owner;
                mintOrder.id = bundle.ids[i];
                mintOrder.amount = asset.amount;
                mintOrder.uri = asset.uri;
                mintOrder.royalty = asset.royalty;

                AssetVersion version = getAssetVersion(mintOrder.token);

                mintERC1155(mintOrder, version, true);

                RedeemERC1155Order memory redeemOrder;
                redeemOrder.token = bundle.tokens[i];
                redeemOrder.from = bundle.owner;
                redeemOrder.to = address(this);
                redeemOrder.id = bundle.ids[i];
                redeemOrder.paymentToken = bundle.paymentToken;
                redeemOrder.targetToken = bundle.targetToken;
                redeemOrder.amount = asset.amount;
                redeemOrder.price = asset.price;

                redeemERC1155(redeemOrder);
            }
        }
    }

    function validateRoyalty(
        ERC2981Base.RoyaltyInfo memory royalty
    ) internal view {

        AppStorage storage s = LibAppStorage.diamondStorage();

        if (royalty.amount > 0) {
            require(
                royalty.amount < s.marketConfig.maxRoyalty && royalty.recipient != address(0),
                "validateRoyalty: INVALID_ROYALTY"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

import {LibMarketplace} from "../libraries/LibMarketplace.sol";
import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {LibCommon} from "../../shared/libraries/LibCommon.sol";
import {LibNFT} from "../libraries/LibNFT.sol"; 
import {LibTransfer} from "./LibTransfer.sol"; 
import {
    LibAppStorage,
    AppStorage,
    Asset,
    Bundle,
    Bid,
    ListingType,
    BundleState,
    AssetStandard,
    AssetVersion
} from "../libraries/LibAppStorage.sol";
import {
    FixedPriceListOrder,
    FixedPriceUnlistOrder,
    FixedPriceRedeemOrder
} from "../../shared/libraries/LibOrders.sol";

library LibFixedPrice {

    using SafeERC20 for IERC20;

    event FixedPriceBundleListed(
        uint256 indexed bundleId,
        address indexed owner,
        address paymentToken,
        address[] tokens,
        uint256[] ids,
        uint256[] amounts,
        uint256[] prices,
        uint8[] standards,
        uint64 listingTime,
        uint8 state
    );

    event FixedPriceBundleUnlisted(
        uint256 indexed bundleId
    );

    event FixedPriceBundleRedeemed(
        uint256 indexed bundleId,
        address indexed buyer
    );

    function checkFixedPriceListOrder(
        FixedPriceListOrder calldata order
    ) internal view {

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 bundleSize = order.tokens.length;
        require(
          bundleSize <= s.marketConfig.maxBundleSize,
          "checkFixedPriceListOrder: INVALID_BUNDLE_SIZE"
        );

        require(
            order.ids.length == bundleSize &&
            order.amounts.length == bundleSize &&
            order.prices.length == bundleSize,
            "checkFixedPriceListOrder: SIZE_MISMATCH"
        );

        LibMarketplace.checkPaymentSupport(order.paymentToken);
        LibMarketplace.checkTargetSupport(order.targetToken);

        for (uint256 i = 0; i < bundleSize; i++) {

            address token = order.tokens[i];

            Asset storage asset = s.market.assets[order.owner][token][order.ids[i]];

            LibMarketplace.checkAssetIsIdle(asset);

            require(
                order.amounts[i] > 0, 
                "checkFixedPriceListOrder: ZERO_AMOUNT"
            );
            require(
                order.prices[i] >= s.marketConfig.minPrices[order.paymentToken], 
                "checkFixedPriceListOrder: INVALID_PRICE"
            );
            require(
                order.standards[i] == AssetStandard.ERC721 ||
                order.standards[i] == AssetStandard.ERC1155, 
                "checkFixedPriceListOrder: INVALID_STANDARD"
            );

            if (!order.minted) {
                if (bytes(order.uris[i]).length == 0) {
                    revert("checkFixedPriceListOrder: MISSING_TOKEN_URI");
                }
                AssetVersion version = s.marketConfig.assetTokenVersions[token];
                LibNFT.checkAssetVersionIsDefault(order.standards[i], version);
            }
        }
    }

    function fixedPriceList(
        FixedPriceListOrder calldata order
    ) internal {

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 bundleSize = order.tokens.length;

        Bundle storage bundle = s.market.bundles[order.bundleId];
        if (bundle.listingType != ListingType.Offchain) {
          revert("fixedPriceList: BUNDLE_EXISTS");
        }

        bundle.owner = order.owner;
        bundle.paymentToken = order.paymentToken;
        bundle.targetToken = order.targetToken;
        bundle.listingTime = uint64(block.timestamp);
        bundle.state = order.minted ? BundleState.OnSale : BundleState.Pending;
        bundle.listingType = ListingType.FixedPrice;

        uint8[] memory standards = new uint8[](bundleSize);

        for (uint256 i = 0; i < bundleSize; i++) {

            Asset storage asset = s.market.assets[bundle.owner][order.tokens[i]][order.ids[i]];
            asset.bundleId = order.bundleId;
            asset.price = order.prices[i];
            if (!order.minted) {
                asset.uri = order.uris[i];
            }
            asset.standard = order.standards[i];
            asset.version = s.marketConfig.defaultTokenVersions[asset.standard];

            if (asset.standard == AssetStandard.ERC721) {

                if (order.minted) {

                    IERC721(order.tokens[i]).safeTransferFrom(
                        order.owner,
                        address(this),
                        order.ids[i],
                        ""
                    );
                }
                
                asset.amount = 1;
            }

            if (asset.standard == AssetStandard.ERC1155) {

                if (order.minted) {

                    IERC1155(order.tokens[i]).safeTransferFrom(
                        order.owner,
                        address(this),
                        order.ids[i],
                        order.amounts[i],
                        ""
                    );
                }

                asset.amount = order.amounts[i];
            }

            if (!order.minted && order.royalties.length > 0) {
                asset.royalty = order.royalties[i]; 
                LibNFT.validateRoyalty(asset.royalty); 
            }

            bundle.tokens.push(order.tokens[i]); 
            bundle.ids.push(order.ids[i]);

            standards[i] = uint8(asset.standard);
        }

        emit FixedPriceBundleListed(
            order.bundleId,
            bundle.owner,
            order.paymentToken,
            order.tokens,
            order.ids,
            order.amounts,
            order.prices,
            standards,
            bundle.listingTime,
            uint8(bundle.state)
        );
    }

    function checkFixedPriceUnlistOrder(
        FixedPriceUnlistOrder calldata order
    ) internal view {

        AppStorage storage s = LibAppStorage.diamondStorage();

        Bundle storage bundle = s.market.bundles[order.bundleId];

        LibMarketplace.checkBundleListingType(bundle, ListingType.FixedPrice);

        require(
            order.owner == bundle.owner, 
            "checkFixedPriceUnlistOrder: NOT_ALLOWED"
        );

        require(
            bundle.state == BundleState.OnSale || bundle.state == BundleState.Pending,
            "checkFixedPriceUnlistOrder: WRONG_BUNDLE_STATE"
        );
    }

    function fixedPriceUnlist(
        FixedPriceUnlistOrder calldata order
    ) internal {

        AppStorage storage s = LibAppStorage.diamondStorage();

        Bundle storage bundle = s.market.bundles[order.bundleId];

        uint256 bundleSize = bundle.ids.length;

        for (uint256 i = 0; i < bundleSize; i++) {

            Asset storage asset = s.market.assets[bundle.owner][bundle.tokens[i]][bundle.ids[i]];

            if (bundle.state == BundleState.OnSale) {

                if (asset.standard == AssetStandard.ERC721) {

                    IERC721(bundle.tokens[i]).safeTransferFrom(
                        address(this),
                        bundle.owner,
                        bundle.ids[i],
                        ""
                    );
                }

                if (asset.standard == AssetStandard.ERC1155) {

                    IERC1155(bundle.tokens[i]).safeTransferFrom(
                        address(this),
                        bundle.owner,
                        bundle.ids[i],
                        asset.amount,
                        ""
                    );
                }
            }

            asset.bundleId = 0;
        }

        bundle.state = BundleState.Idle;

        emit FixedPriceBundleUnlisted(
            order.bundleId
        );
    }

    function checkFixedPriceRedeemOrder(
        FixedPriceRedeemOrder calldata order
    ) internal view {

        AppStorage storage s = LibAppStorage.diamondStorage();

        Bundle storage bundle = s.market.bundles[order.bundleId];

        LibMarketplace.checkNonZero(order.buyer);
        LibMarketplace.checkBundleListingType(bundle, ListingType.FixedPrice);

        require(
            bundle.state == BundleState.OnSale || bundle.state == BundleState.Pending,
            "checkFixedPriceUnlistOrder: WRONG_BUNDLE_STATE"
        );
        require(
            bundle.owner != order.buyer,
            "checkFixedPriceUnlistOrder: OWNER_IS_BUYER"
        );
    }

    function fixedPriceRedeem(
        FixedPriceRedeemOrder calldata order
    ) internal {

        AppStorage storage s = LibAppStorage.diamondStorage();

        Bundle storage bundle = s.market.bundles[order.bundleId];

        if (bundle.state == BundleState.Pending) {
            LibNFT.mintBundle(bundle);
            bundle.state = BundleState.OnSale;
        }

        uint256 bundleSize = bundle.ids.length;

        uint256 value;
        uint256 royaltyTotal;

        bool bundleIsEmpty = true;

        for (uint256 i = 0; i < bundleSize; i++) {

            Asset storage asset = s.market.assets[bundle.owner][bundle.tokens[i]][bundle.ids[i]];

            require(
                order.amounts[i] <= asset.amount,
                "fixedPriceRedeem: AMOUNT_EXCEEDS_LISTED_AMOUNT"
            );

            if (order.amounts[i] == 0) {
                continue;
            }

            uint256 cost = asset.price * order.amounts[i];

            uint256 royaltyPayed = LibTransfer.payRoyalty(
                bundle.tokens[i],
                bundle.paymentToken,
                order.buyer,
                order.buyer,
                bundle.ids[i], 
                cost
            );

            if (asset.standard == AssetStandard.ERC721) {

                IERC721(bundle.tokens[i]).safeTransferFrom(
                    address(this),
                    order.buyer,
                    bundle.ids[i],
                    ""
                );
            }

            if (asset.standard == AssetStandard.ERC1155) {

                IERC1155(bundle.tokens[i]).safeTransferFrom(
                    address(this),
                    order.buyer,
                    bundle.ids[i],
                    order.amounts[i],
                    ""
                );
            }

            value += cost;
            royaltyTotal += royaltyPayed;
            asset.amount = asset.amount - order.amounts[i];

            if (asset.amount > 0) {
                bundleIsEmpty = false;
            } else {
                asset.bundleId = 0;
            }
        }

        if (value == 0) {
            revert("redeemERC1155Bundle: ZERO_VALUE");
        }

        uint256 comissionPayed = LibTransfer.payComission(
            bundle.paymentToken,
            order.buyer,
            order.buyer,
            value
        );

        LibTransfer.executePayment(
            bundle.paymentToken,
            bundle.targetToken,
            order.buyer,
            bundle.owner,
            value - royaltyTotal - comissionPayed
        );

        if (bundleIsEmpty) {
            bundle.state = BundleState.Idle;
        }
 
        emit FixedPriceBundleRedeemed(
            order.bundleId,
            order.buyer
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../../shared/libraries/LibDiamond.sol";
import {LibCommon} from "../../shared/libraries/LibCommon.sol";
import {ERC2981Base} from "../../tokens/ERC2981Base.sol";

enum AssetStandard {
    ERC721,
    ERC1155
}

enum AssetVersion {
    None,                                // standard-compliant external contract
    V1                                   // Funrise mintable contract V1
}

enum BundleState {
    Idle,                                // not on sale, default
    OnSale,                              // on sale, minted
    Pending                              // on sale, not minted
}

enum ListingType {
    Offchain,                            // not listed / listed off-chain
    FixedPrice,                          // fixed price listing
    Auction,                             // auction listing
    VirtualAuction                       // virtual auction listing
}

// Represents ERC721 / ERC1155 token
struct Asset {
    uint256 bundleId;                    // current bundle
    uint256 amount;                      // amount of token
    uint256 price;                       // fixed price / starting price
    string uri;                          // token URI
    AssetStandard standard;    
    AssetVersion version;    
    ERC2981Base.RoyaltyInfo royalty;
}

// Represents a bid on a {Bundle}
struct Bid {
    address bidder;                 // payer and bundle recipient
    uint256 value;                  // bid value
    // uint64 timestamp;               // block time
    bool active;                    // bid is active: payment token is locked
}

// Represents a set of {Asset}s
struct Bundle {
    address owner;                       // owner of assets, seller
    address paymentToken;                // this token is transferred from a buyer
    address targetToken;                 // this token is transferred to a seller
    address[] tokens;                    // asset tokens
    uint256[] ids;                       // asset token IDs
    uint256 reservePrice;                // do not accept the highest bid if its value is below this price
    uint64 listingTime;                  // listing block time
    uint64 duration;                     // auction duration
    Bid bid;                             // current bid
    BundleState state;
    ListingType listingType;
}

struct Market {
    // owner -> token -> token id -> asset id
    mapping(address => mapping(address => mapping(uint256 => Asset))) assets;

    // bundle id -> bundle
    mapping(uint256 => Bundle) bundles;
}

struct MarketConfig {
    mapping(address => bool) signers;                                           // newly minted tokens must have IDs signed by a signer
    mapping(address => bool) resolvers;                                         // resolves listings

    mapping(AssetStandard => mapping(AssetVersion => address)) assetTokens;     // native mitable asset tokens
    mapping(AssetStandard => AssetVersion) defaultTokenVersions;                // default asset token versions
    mapping(address => AssetStandard) assetTokenStandards;                      // asset token standards
    mapping(address => AssetVersion) assetTokenVersions;                        // asset token versions

    mapping(address => uint256[]) comissionSteps;                               // payment token => comission steps
    mapping(address => uint24[]) comissionPercentages;                          // payment token => comission step values
    mapping(address => uint256) minPrices;                                      // minimum asset prices (payment token => minimum price)
    mapping(address => bool) targetTokens;                                      // seller receives these ERC20 tokens (whitelist)
    address comissionReceiver;                                                  // comissions are transfered to this address
    address platformToken;                                                      // FNR ERC20 token

    uint24 maxRoyalty;                                                          // maximum royalty value
    uint256 maxBundleSize;                                                      // maximum number of assets in a bundle

    mapping(address => uint256) auctionSteps;                                   // payment token => minimal value difference required for overbid
    mapping(address => uint256) minReservePriceTotal;                           // payment token -> value
    uint256 minAuctionDuration;                                                 // in seconds
    uint256 maxAuctionDuration;                                                 // in seconds
    uint64 auctionProlongation;                                                 // duration is increased by this value after each successful bid
    uint64 auctionRelaxationTime;                                               // resolver can resolve an auction after {auction duration + relaxation time}

    bool skipPlatformToken;                                                     // skip platform token for the path {payment token => platform token => target token}
}

struct ExchangeConfig {
    address router;                                                             // swap router
    uint256 maxSwapDelay;                                                       // deadline = block.timestamp + maxDelay
}

struct Accounts {
    mapping(bytes32 => bool) roots;                                             // Merkle roots
    mapping(address => bool) refillBlacklist;                                   // do not refill these accounts
    uint256 refillValue;                                                        // registered accounts are refilled with this amount
}

struct AppStorage {
    Accounts accounts;
    Market market;
    MarketConfig marketConfig;
    ExchangeConfig exchangeConfig;
}

library LibAppStorage {

    function diamondStorage() internal pure returns (AppStorage storage ds) {
        assembly {
            ds.slot := 0
        }
    }
}

contract Modifiers {

    modifier onlyDiamondOwner() {
        LibDiamond.enforceIsContractOwner();
        _;
    }

    modifier isSender(address _address) {
        require(
            _address == LibCommon.msgSender(),
            "NOT_SENDER"
        );
        _;
    }

    modifier notEqual(address _address1, address _address2) {
        require(
            _address1 != _address2,
            "WRONG_ADDRESS"
        );
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

import {ERC2981Base} from "../../tokens/ERC2981Base.sol";
import {
    LibAppStorage,
    AppStorage,
    AssetStandard,
    AssetVersion
} from "../../marketplace/libraries/LibAppStorage.sol";

// Mint / Off-chain fixed price listing

struct MintERC721Order {
    address token;
    address to;
    uint256 id;
    string uri;
    ERC2981Base.RoyaltyInfo royalty;
}

struct MintERC721BatchOrder {
    address token;
    address to;
    uint256[] ids;
    string[] uris;
    ERC2981Base.RoyaltyInfo royalty;
}

struct MintERC1155Order {
    address token;
    address to;
    uint256 id;
    uint256 amount;
    string uri;
    ERC2981Base.RoyaltyInfo royalty;
}

struct MintERC1155BatchOrder {
    address token;
    address to;
    uint256[] ids;
    uint256[] amounts;
    string[] uris;
    ERC2981Base.RoyaltyInfo royalty;
}

struct RedeemERC721Order {
    address token;
    address paymentToken;
    address targetToken;
    address from;
    address to;
    uint256 id;
    uint256 price;
}

struct RedeemERC721BundleOrder {
    address[] tokens;
    address paymentToken;
    address targetToken;
    address from;
    address to;
    uint256[] ids;
    uint256[] prices;
}

struct RedeemERC1155Order {
    address token;
    address paymentToken;
    address targetToken;
    address from;
    address to;
    uint256 id;
    uint256 amount;
    uint256 price;
}

struct RedeemERC1155BundleOrder {
    address[] tokens;
    address paymentToken;
    address targetToken;
    address from;
    address to;
    uint256[] ids;
    uint256[] amounts;
    uint256[] prices;
}

// FixedPrice

struct FixedPriceListOrder {
    address owner;                          // owner of assets, seller
    address paymentToken;                   // this token is transferred from a buyer
    address targetToken;                    // this token is transferred to a seller
    uint256 bundleId;                       // target bundle (edit bundle if exists)
    address[] tokens;                       // asset tokens
    uint256[] ids;                          // asset token IDs
    uint256[] amounts;                      // asset token amounts
    uint256[] prices;                       // asset prices
    string[] uris;                          // asset token URIs (lazy mint only)
    AssetStandard[] standards;              // asset type
    ERC2981Base.RoyaltyInfo[] royalties;    // ERC2981 royalties (lazy mint only)
    bool minted;                            // assets existence (lazy mint if false)
}

struct FixedPriceUnlistOrder {
    address owner;
    uint256 bundleId;          
}

struct FixedPriceRedeemOrder {
    address buyer;                          // payer and buyer
    uint256 bundleId;                       // target bundle
    uint256[] amounts;                      // asset token amounts
}

// Auction

struct AuctionListOrder {
    address owner;                          // bundle owner
    address paymentToken;                   // this token is transferred from a bidder
    address targetToken;                    // this token is transferred to the seller
    uint256 bundleId;                       // target bundle (edit bundle if exists)
    address[] tokens;                       // NFT contract addresses
    uint256[] ids;                          // token IDs
    uint256[] amounts;                      // token amounts
    uint256[] startingPrices;               // bids below cumulative starting price are rejectd
    uint256 reservePrice;                   // do not auto sell if final highest bid is below this value
    uint64 duration;                        // auction dutation in seconds
    string[] uris;                          // asset token URIs (lazy mint / virtual only)
    AssetStandard[] standards;              // asset type
    ERC2981Base.RoyaltyInfo[] royalties;    // ERC2981 royalties (lazy mint / virtual only)
    bool minted;                            // assets existence (lazy mint if false)
    bool deferred;                          // virtual if true (lazy mint if true)
}

struct AuctionBidOrder {
    address bidder;                         // bid maker
    uint256 bundleId;                       // target bundle
    uint256 value;                          // total bid value
}

struct AuctionSetOwnerOrder {
    address owner;                          // bundle owner
    address targetToken;                    // this token is transferred to the seller
    uint256 bundleId;                       // target bundle
    string[] uris;                          // asset token URIs
    ERC2981Base.RoyaltyInfo royalty;        // ERC2981 royalty
}

struct AuctionResolveOrder {
    uint256 bundleId;                       // target bundle
    bool accept;                            // accept the highest bid or close the auction and return assets
}

/// @title Order structures.
/// @author Nypox
library LibOrders {

    function hashMintOrderId(
        address token,
        uint256 id
    ) internal view returns (bytes32) {
        
        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    token,
                    id,
                    block.chainid
                )
            )
        );
    }

    function hashMintOrderIds(
        address token,
        uint256[] memory ids
    ) internal view returns (bytes32) {
        
        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    token,
                    ids,
                    block.chainid
                )
            )
        );
    }

    function hashMintERC721Order(
        MintERC721Order calldata order
    ) internal view returns (bytes32) {
        
        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.token,
                    order.to,
                    order.id,
                    order.uri,
                    order.royalty.recipient,
                    order.royalty.amount,
                    block.chainid
                )
            )
        );
    }

    function hashMintERC721BatchOrder(
        MintERC721BatchOrder calldata order
    ) internal view returns (bytes32) {

        bytes memory uris;
        for (uint i = 0; i < order.uris.length; i++) {
            uris = abi.encodePacked(uris, order.uris[i]);
        }
        
        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.token,
                    order.to,
                    order.ids,
                    uris,
                    order.royalty.recipient,
                    order.royalty.amount,
                    block.chainid
                )
            )
        );
    }

    function hashMintERC1155Order(
        MintERC1155Order calldata order
    ) internal view returns (bytes32) {
        
        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.token,
                    order.to,
                    order.id,
                    order.amount,
                    order.uri,
                    order.royalty.recipient,
                    order.royalty.amount,
                    block.chainid
                )
            )
        );
    }

    function hashMintERC1155BatchOrder(
        MintERC1155BatchOrder calldata order
    ) internal view returns (bytes32) {
        
        bytes memory uris;
        for (uint i = 0; i < order.uris.length; i++) {
            uris = abi.encodePacked(uris, order.uris[i]);
        }

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.token,
                    order.to,
                    order.ids,
                    order.amounts,
                    uris,
                    order.royalty.recipient,
                    order.royalty.amount,
                    block.chainid
                )
            )
        );
    }

    function hashRedeemERC721Order(
        RedeemERC721Order calldata order
    ) internal view returns (bytes32) {

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.token,
                    order.from,
                    order.id,
                    order.paymentToken,
                    order.targetToken,
                    order.price,
                    block.chainid
                )
            )
        );
    }

    function hashRedeemERC721BundleOrder(
        RedeemERC721BundleOrder calldata order
    ) internal view returns (bytes32) {

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.tokens,
                    order.from,
                    order.ids,
                    order.paymentToken,
                    order.targetToken,
                    order.prices,
                    block.chainid
                )
            )
        );
    }

    function hashRedeemERC1155Order(
        RedeemERC1155Order calldata order
    ) internal view returns (bytes32) {

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.token,
                    order.from,
                    order.id,
                    order.paymentToken,
                    order.targetToken,
                    order.amount,
                    order.price,
                    block.chainid
                )
            )
        );
    }

    function hashRedeemERC1155BundleOrder(
        RedeemERC1155BundleOrder memory order
    ) internal view returns (bytes32) {

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.tokens,
                    order.from,
                    order.ids,
                    order.paymentToken,
                    order.targetToken,
                    order.amounts,
                    order.prices,
                    block.chainid
                )
            )
        );
    }

    function hashAuctionSetOwnerOrder(
        AuctionSetOwnerOrder memory order
    ) internal view returns (bytes32) {

        bytes memory uris;
        for (uint i = 0; i < order.uris.length; i++) {
            uris = abi.encodePacked(uris, order.uris[i]);
        }

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.owner,
                    order.targetToken,
                    order.bundleId,
                    uris,
                    order.royalty.recipient,
                    order.royalty.amount,
                    block.chainid
                )
            )
        );
    }

    function hashAuctionResolveOrder(
        AuctionResolveOrder memory order
    ) internal view returns (bytes32) {

        return ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    order.bundleId,
                    block.chainid
                )
            )
        );
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {MintERC721Order, MintERC721BatchOrder} from "../shared/libraries/LibOrders.sol";  

/// @dev Required interface of Funrise ERC721-compliant contract.
/// @dev Based on code by OpenZeppelin.
/// @author Nypox
interface IFERC721V1 is IERC165 {

/// @dev Emitted when `id` token is transferred from `from` to `to`.
    event Transfer(address indexed from, address indexed to, uint256 indexed id);

/// @dev Emitted when `owner` enables `approved` to manage the `id` token.
    event Approval(address indexed owner, address indexed approved, uint256 indexed id);

/// @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

/// @dev Emitted when the URI for token type `id` changes to `value`
    event URI(string value, uint256 indexed id);

/// @dev Returns the number of tokens in `owner`'s account.
    function balanceOf(address owner) external view returns (uint256);

/// @dev Returns the owner of the `id` token.
/// @dev `id` must exist.
    function ownerOf(uint256 id) external view returns (address);

/// @dev Returns the creator of `id` token.
    function creatorOf(uint256 id) external view returns (address);

/// @dev Transfers `id` token from `from` to `to`.
/// @dev `from` cannot be the zero address.
/// @dev `to` cannot be the zero address.
/// @dev `id` token must be owned by `from`.
/// @dev If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
    function transferFrom(
        address from,
        address to,
        uint256 id
    ) external;

/// @dev Safely transfers `id` token from `from` to `to`, checking first that contract recipients are aware of the ERC721 protocol to prevent tokens from being forever locked.
/// @dev `from` cannot be the zero address.
/// @dev `to` cannot be the zero address.
/// @dev `id` token must exist and be owned by `from`.
/// @dev If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
/// @dev If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
/// @dev Emits a {Transfer} event.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        bytes calldata data
    ) external;

/// @dev Gives permission to `to` to transfer `id` token to another account.
/// @dev The approval is cleared when the token is transferred.
/// @dev Only a single account can be approved at a time, so approving the zero address clears previous approvals.
/// @dev The caller must own the token or be an approved operator.
/// @dev `id` must exist.
/// @dev Emits an {Approval} event.
    function approve(address to, uint256 id) external;

/// @dev Returns the account approved for `id` token.
/// @dev `id` must exist.
    function getApproved(uint256 id) external view returns (address);

/// @dev Approve or remove `operator` as an operator for the caller.
/// @dev Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
/// @dev The `operator` cannot be the caller.
/// @dev Emits an {ApprovalForAll} event.
    function setApprovalForAll(address operator, bool _approved) external;

/// @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
    function isApprovedForAll(address owner, address operator) external view returns (bool);

/// @dev Mints a token `order.id` to address `order.to`.
/// @dev Enables approval for minter to transfer tokens if `approve_` is true.
/// @dev Only minter is allowed to call this function.
/// @dev If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
/// @dev Emits a {Transfer} event.
    function mint(
        MintERC721Order calldata order,
        bool approve_,
        bool freezeTokenURI,
        bytes memory data
    ) external;

/// @dev Batched version of {mint}.
/// @dev Emits a {Transfer} event.
    function mintBatch(
        MintERC721BatchOrder calldata order,
        bool approve_,
        bool freezeTokenURI,
        bytes memory data
    ) external;

/// @dev Burns token `id`.
/// @dev Emits a {Transfer} event.
    function burn(
        uint256 id
    ) external;

/// @dev Returns whether token URI of token `id` is frozen.
    function isPermanentURI(
        uint256 id
    ) external returns (bool);

/// @dev Sets token URI for token `id`.
/// @dev Token owner must be the creator.
    function setTokenURI(
        uint256 id,
        string calldata newUri,
        bool freeze
    ) external;

/// @notice Called when token is deposited on root chain.
/// @param user user address for whom deposit is being done.
/// @param depositData abi encoded ids.
    function deposit(address user, bytes calldata depositData) external;

/// @notice Called when user wants to withdraw token to root chain.
    function withdraw(uint256 id) external;

/// @notice Called when user wants to withdraw multiple tokens to root chain.
    function withdrawBatch(uint256[] calldata ids) external;

/// @notice Called when user wants to withdraw token to root chain with token URI.
    function withdrawWithMetadata(uint256 id) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import {MintERC1155Order, MintERC1155BatchOrder} from "../shared/libraries/LibOrders.sol"; 

/// @dev Required interface of Funrise ERC1155-compliant contract.
/// @dev Based on code by OpenZeppelin.
/// @author Nypox
interface IFERC1155V1 is IERC165 {

/// @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

/// @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all transfers.
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

/// @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to `approved`.
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

/// @dev Emitted when the URI for token type `id` changes to `value`
    event URI(string value, uint256 indexed id);

/// @dev Returns the amount of tokens of token type `id` owned by `account`.
/// @dev `account` cannot be the zero address.
    function balanceOf(address account, uint256 id) external view returns (uint256);

/// @dev Batched version of {balanceOf}.
/// @dev `accounts` and `ids` must have the same length.
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

/// @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`.
/// @dev `operator` cannot be the caller.
    function setApprovalForAll(address operator, bool approved) external;

/// @dev Returns true if `operator` is approved to transfer `account`'s tokens.
    function isApprovedForAll(address account, address operator) external view returns (bool);

/// @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
/// @dev `to` cannot be the zero address.
/// @dev If the caller is not `from`, it must be have been approved to spend `from`'s tokens via {setApprovalForAll}.
/// @dev `from` must have a balance of tokens of type `id` of at least `amount`.
/// @dev If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received}.
/// @dev Emits a {TransferSingle} event.
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

/// @dev Batched version of {safeTransferFrom}.
/// @dev Emits a {TransferBatch} event.
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;

/// @dev Returns the creator of `id` token.
    function creatorOf(uint256 id) external view returns (address);

/// @dev Mints `order.amount` tokens of token type `order.id` to `order.to`.
/// @dev Enables approval for minter to transfer tokens if `approve` is true.
/// @dev Only minter is allowed to call this function.
/// @dev Emits a {TransferSingle} event.
/// @dev Emits a {URI} event.
    function mint(
        MintERC1155Order calldata order,
        bool approve,
        bool freezeTokenURI,
        bytes memory data
    ) external;

/// @dev Batched version of {mint}.
/// @dev Emits a {TransferBatch} event.
/// @dev Emits {URI} events.
    function mintBatch(
        MintERC1155BatchOrder calldata order,
        bool approve,
        bool freezeTokenURI,
        bytes memory data
    ) external;

/// @dev Burns `value` tokens of token `id` from `account`.
/// @dev Burned token cannot be re-minted
/// @dev Emits a {TransferSingle} event.
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

/// @dev Batched version of {burn}.
/// @dev Emits a {TransferBatch} event.
    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) external;

/// @dev Sets token URI for token `id`.
/// @dev The creator must own the full supply of the token.
    function setTokenURI(
        uint256 id,
        string calldata newUri,
        bool freeze
    ) external;

/// @notice Called when tokens are deposited on root chain.
/// @param user user address for whom deposit is being done.
/// @param depositData abi encoded ids array and amounts array.
    function deposit(
        address user,
        bytes calldata depositData
    ) external;

// /// @notice Called when user wants to withdraw single token to root chain.
//     function withdrawSingle(
//         uint256 id,
//         uint256 amount
//     ) external;

/// @notice Called when user wants to batch withdraw tokens to root chain.
    function withdrawBatch(
        uint256[] calldata ids,
        uint256[] calldata amounts
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IUniswapV2Router02} from "@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";

import {IERC2981Royalties} from "../../tokens/IERC2981Royalties.sol";
import {LibAppStorage, AppStorage} from "../libraries/LibAppStorage.sol";

library LibTransfer {

    using SafeERC20 for IERC20;

    event RoyaltyPayed(
        address indexed token,
        address paymentToken,
        address buyer,
        address indexed receiver,
        uint256 indexed tokenId,
        uint256 value
    );

    event ComissionPayed(
        address paymentToken,
        address indexed buyer,
        address indexed receiver,
        uint256 value
    );

/// @dev Pay for an asset.
/// @dev This function doesn't perform asset transfer.
/// @dev `paymentToken` <-> `platformToken` and `targetToken` <-> `platformToken` pairs must exist.
/// @param paymentToken - this token is transferred from `payer`.
/// @param targetToken -  this token is transferred to `receiver`.
/// @param payer - `paymentToken` is transferred from this address.
/// @param receiver - `targetToken` is transferred to this address.
/// @param value - this value is transferred from `payer`.
    function executePayment(
        address paymentToken,
        address targetToken,
        address payer,
        address receiver,
        uint256 value
    ) internal {

        AppStorage storage s = LibAppStorage.diamondStorage();

        if (payer != address(this)) {
            require(
                IERC20(paymentToken).allowance(payer, address(this)) >= value,
                "executePayment: INSUFFICIENT_ALLOWANCE"
            );
        }

        uint256 amountPayment = value;
        uint256 amountPlatform; // amount of platformToken

        bool paymentIsPlatform = paymentToken == s.marketConfig.platformToken;
        bool targetIsPlatform = targetToken == s.marketConfig.platformToken;

        if (paymentIsPlatform && targetIsPlatform || s.marketConfig.skipPlatformToken) {
            if (payer != address(this)) {
                IERC20(paymentToken).safeTransferFrom(payer, receiver, amountPayment);
            } else {
                IERC20(paymentToken).safeTransfer(receiver, amountPayment);
            }
            // targetToken has been directly transferred to `receiver`
            return;
        }

        if (payer != address(this)) {

            IERC20(paymentToken).safeTransferFrom(payer, address(this), amountPayment);
        }

        // at this point the contract holds `amountPayment` of paymentToken

        if (!paymentIsPlatform) {
            // paymentToken -> platformToken swap
            address[] memory path = new address[](2);
            path[0] = paymentToken;
            path[1] = s.marketConfig.platformToken;

            IERC20(paymentToken).safeIncreaseAllowance(s.exchangeConfig.router, amountPayment);

            address platformTokenReceiver;
            if (targetIsPlatform) {
                platformTokenReceiver = receiver;
            } else {
                platformTokenReceiver = address(this);
            }
 
            uint256[] memory amounts = IUniswapV2Router02(s.exchangeConfig.router).swapExactTokensForTokens(
                amountPayment,
                0,
                path,
                platformTokenReceiver,
                block.timestamp + s.exchangeConfig.maxSwapDelay
            );

            if (targetIsPlatform) {
                // targetToken has been transferred to `receiver`
                return;
            }

            amountPlatform = amounts[amounts.length - 1];
        } else {
            amountPlatform = amountPayment;
        }

        // at this point the contract holds `amountPlatform` of platformToken

        if (!targetIsPlatform) {
            // platformToken -> targetToken swap
            address[] memory path = new address[](2);
            path[0] = s.marketConfig.platformToken;
            path[1] = targetToken;

            IERC20(s.marketConfig.platformToken).safeIncreaseAllowance(s.exchangeConfig.router, amountPlatform);
 
            IUniswapV2Router02(s.exchangeConfig.router).swapExactTokensForTokens(
                amountPlatform,
                0,
                path,
                receiver,
                block.timestamp + s.exchangeConfig.maxSwapDelay
            );
        }
    }
    
/// @dev Transfers royalty from `payer` to royalty receiver if EIP-2981 is supported by `token`.
    function payRoyalty(
        address token,
        address paymentToken,
        address payer,
        address buyer,
        uint256 id,
        uint256 value
    ) internal returns (uint256) {

        if (value == 0) {
            return 0;
        }

        uint256 royaltyValue = 0;

        if (ERC165Checker.supportsInterface(token, 0x2a55205a)) { // bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
            address royaltyReceiver;
            (royaltyReceiver, royaltyValue) = IERC2981Royalties(token).royaltyInfo(id, value);

            if (royaltyValue > 0 && royaltyValue < value) {

                if (payer == address(this)) {
                    IERC20(paymentToken).safeTransfer(royaltyReceiver, royaltyValue);
                } else {
                    IERC20(paymentToken).safeTransferFrom(payer, royaltyReceiver, royaltyValue);
                }

                emit RoyaltyPayed(
                    token,
                    paymentToken,
                    buyer,
                    royaltyReceiver,
                    id,
                    royaltyValue
                );
            } else {
                royaltyValue = 0;
            }
        }

        return royaltyValue;
    }

/// @dev Transfers comission to {MarketConfig-comissionReceiver}.
    function payComission(
        address paymentToken,
        address payer,
        address buyer,
        uint256 value
    ) internal returns (uint256) {

        if (value == 0) {
            return 0;
        }

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 numSteps = s.marketConfig.comissionSteps[paymentToken].length;
        uint256 percentage = 0;

        for (uint256 i = 0; i < numSteps; i++) {
            if (s.marketConfig.comissionSteps[paymentToken][i] < value) {
                percentage = s.marketConfig.comissionPercentages[paymentToken][i];
            } else {
                break;
            }
        }

        uint256 comissionValue = value * percentage / 10000;
        if (comissionValue > 0) {
            if (payer != address(this)) {
                IERC20(paymentToken).transferFrom(payer, address(this), comissionValue);
            }
            emit ComissionPayed(
                paymentToken,
                buyer,
                address(this),
                comissionValue
            );
        }

        return comissionValue;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/ERC165.sol';

import {IERC2981Royalties} from './IERC2981Royalties.sol';

/// @dev Adds ERC2981 support to ERC721 and ERC1155
abstract contract ERC2981Base is ERC165, IERC2981Royalties {
    
    struct RoyaltyInfo {
        address recipient;
        uint24 amount;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC2981Royalties).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
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
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
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
pragma solidity ^0.8.0;

/// @title IERC2981Royalties
/// @dev Interface for the ERC2981 - Token Royalty standard
interface IERC2981Royalties {

/// @notice Called with the sale price to determine how much royalty is owed and to whom.
/// @param tokenId - the NFT asset queried for royalty information
/// @param value - the sale price of the NFT asset specified by tokenId
/// @return receiver - address of who should be sent the royalty payment
/// @return royaltyAmount - the royalty payment amount for value sale price
    function royaltyInfo(uint256 tokenId, uint256 value)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
    }
}

pragma solidity >=0.6.2;

import './IUniswapV2Router01.sol';

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);
    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);

    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {
    LibAppStorage,
    AppStorage,
    Asset,
    Bundle,
    Bid,
    ListingType,
    BundleState
} from "../libraries/LibAppStorage.sol";

library LibMarketplace {

    function checkBundleListingType(
        Bundle storage bundle,
        ListingType listingType
    ) internal view {

        require(
            bundle.listingType == listingType,
            "Marketplace: WRONG_LISTRING_TYPE"
        );
    }

    function checkAssetIsIdle(
        Asset storage asset
    ) internal view {

        require(
            asset.bundleId == 0,
            "Marketplace: BUNDLE_EXISTS"
        );
    }

    function checkBundleState(
        Bundle storage bundle,
        BundleState state
    ) internal view {

        require(
            bundle.state == state,
            "Marketplace: WRONG_ASSET_STATE"
        );
    }

    function checkBundleExchangeMatch(
        Bundle storage bundle,
        address token
    ) internal view {

        require(
            bundle.paymentToken == token, 
            "Marketplace: WRONG_EXCHANGE_TOKEN"
        );
    }

    function checkBundleListingTimeMatch(
        Bundle storage bundle,
        uint64 listingTime
    ) internal view {

        require(
            bundle.listingTime == listingTime, 
            "Marketplace: liSTING_TIME_MISMATCH"
        );
    }

    function checkPaymentSupport(
        address token
    ) internal view {

        require(
           LibAppStorage.diamondStorage().marketConfig.minPrices[token] > 0, 
            "Marketplace: PAYMENT_NOT_SUPPORED"
        );
    }

    function checkTargetSupport(
        address token
    ) internal view {

        require(
           LibAppStorage.diamondStorage().marketConfig.targetTokens[token], 
            "Marketplace: TARGET_NOT_SUPPORED"
        );
    }

    function checkNonZero(
        address address_
    ) internal pure {

        require(
            address_ != address(0), 
            "Marketplace: ZERO_ADDRESS"
        );
    }

    function getBundlePriceTotal(Bundle storage bundle) internal view returns (uint256) {

        AppStorage storage s = LibAppStorage.diamondStorage();

        uint256 bundleSize = bundle.tokens.length;
        uint256 value;

        for (uint256 i = 0; i < bundleSize; i++) {
            Asset storage asset = s.market.assets[bundle.owner][bundle.tokens[i]][bundle.ids[i]];
            value += asset.price * asset.amount;
        }

        return value;
    }
}