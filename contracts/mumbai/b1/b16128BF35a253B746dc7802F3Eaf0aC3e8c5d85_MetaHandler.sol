// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../common/Upgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract MetaHandler is Upgradeable {
    address immutable proxy;
    /**
     * This are save as immutable for cheap access
     * The chainId is also saved to be able to recompute domainSeparator in the case of fork
     */
    bytes32 private immutable _domainSeparator;
    uint256 private immutable _domainChainId;

    string public constant BUY_FROM_PRIMARY_SALE = "Buy from primary sale";
    string public constant BUY_FROM_SECONDARY_SALE = "Buy from secondary sale";
    string public constant CANCEL_SALE_ORDER = "Cancel sale order";
    string public constant CANCEL_OFFER = "Cancel offer";
    string public constant TRANSFER_NFT = "Transfer NFT";
    string public constant OPEN_BOX = "Open mystery box";

    // * REQUEST
    bytes32 public constant PRIMARY_SALE_REQUEST =
        keccak256(bytes("PRIMARY_SALE_REQUEST"));
    bytes32 public constant SECONDARY_SALE_REQUEST =
        keccak256(bytes("SECONDARY_SALE_REQUEST"));
    bytes32 public constant CANCEL_SALE_ORDER_REQUEST =
        keccak256(bytes("CANCEL_SALE_ORDER_REQUEST"));
    bytes32 public constant CANCEL_OFFER_REQUEST =
        keccak256(bytes("CANCEL_OFFER_REQUEST"));
    bytes32 public constant TRANSFER_NFT_REQUEST =
        keccak256(bytes("TRANSFER_NFT_REQUEST"));
    bytes32 public constant BOX_OPEN_REQUEST =
        keccak256(bytes("BOX_OPEN_REQUEST"));

    string public constant name = "NFTify";
    string public constant version = "1";

    constructor(address proxy_) {
        proxy = proxy_;

        uint256 chainId;

        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        _domainChainId = chainId;
        _domainSeparator = _calculateDomainSeparator(chainId, proxy_);
    }

    /**
     * @notice Builds the DOMAIN_SEPARATOR (eip712) at time of use
     * @dev This is not set as a constant, to ensure that the chainId will change in the event of a chain fork
     * @return the DOMAIN_SEPARATOR of eip712
     */
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        uint256 chainId;

        //solhint-disable-next-line no-inline-assembly
        assembly {
            chainId := chainid()
        }

        return
            (chainId == _domainChainId)
                ? _domainSeparator
                : _calculateDomainSeparator(chainId, proxy);
    }

    function _calculateDomainSeparator(
        uint256 chainId,
        address verifyingContract
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes("NFTify")),
                    keccak256(bytes("1")),
                    chainId,
                    address(verifyingContract)
                )
            );
    }

    /**
     * @dev Execute meta transaction

     * ? -- BOX_OPEN_REQUEST --
     * -- data [0] tokenType, [1] tokenID, [2] quantity
     * -- addrs [0] from, [1] targetContract, [2] collection

     * ? -- OTHERS --
     * -- data [0] tokenType, [1] tokenID, [2] quantity, [3] price
     * -- addrs [0] from, [1] targetContract, [2] collection, [3] seller, [4] paymentToken
     */

    function executeMetaTransaction(
        uint256[] memory data,
        address[] memory addrs,
        bytes[] memory signatures,
        bytes32 requestType,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[addrs[0]],
            from: addrs[0],
            targetContract: proxy,
            request: ""
        });

        Item memory item = Item({
            tokenID: data[1],
            tokenType: data[0],
            collection: addrs[2]
        });

        bytes32 typedDataHash;

        if (
            requestType == PRIMARY_SALE_REQUEST ||
            requestType == SECONDARY_SALE_REQUEST
        ) {
            metaTx.request = requestType == PRIMARY_SALE_REQUEST
                ? BUY_FROM_PRIMARY_SALE
                : BUY_FROM_SECONDARY_SALE;

            BuyRequest memory buyRequest = BuyRequest({
                metaTx: metaTx,
                item: item,
                quantity: data[2],
                price: data[3],
                seller: addrs[3],
                paymentToken: addrs[4]
            });

            // * Get the hash
            typedDataHash = hash(buyRequest);
        } else if (requestType == CANCEL_SALE_ORDER_REQUEST) {
            metaTx.request = CANCEL_SALE_ORDER;

            CancelSaleOrderRequest
                memory cancelRequest = CancelSaleOrderRequest({
                    metaTx: metaTx,
                    item: item,
                    quantity: data[2],
                    price: data[3]
                });

            // * Get the hash
            typedDataHash = hash(cancelRequest);
        } else if (requestType == CANCEL_OFFER_REQUEST) {
            metaTx.request = CANCEL_OFFER;

            CancelOfferRequest memory cancelRequest = CancelOfferRequest({
                metaTx: metaTx,
                item: item,
                quantity: data[2],
                yourOffer: data[3]
            });

            // * Get the hash
            typedDataHash = hash(cancelRequest);
        } else if (requestType == TRANSFER_NFT_REQUEST) {
            metaTx.request = TRANSFER_NFT;

            TransferNFTRequest memory request = TransferNFTRequest({
                metaTx: metaTx,
                item: item,
                quantity: data[2],
                from: addrs[3],
                to: addrs[4]
            });

            typedDataHash = hash(request);
        } else if (requestType == BOX_OPEN_REQUEST) {
            metaTx.request = OPEN_BOX;

            BoxOpenRequest memory request = BoxOpenRequest({
                metaTx: metaTx,
                boxId: data[1],
                boxAddress: addrs[2],
                quantity: data[2]
            });

            typedDataHash = hash(request);
        }

        bytes32 digest = ECDSA.toTypedDataHash(
            DOMAIN_SEPARATOR(),
            typedDataHash
        );

        (address recoveredAddress, ) = ECDSA.tryRecover(digest, v, r, s);

        require(
            recoveredAddress == metaTx.from,
            "MetaTransaction: invalid signature"
        );

        nonces[metaTx.from]++;

        // Currently, the contract is locked by calling `executeMetaTransaction`.
        // So, to call another function, we have to unlock it.
        // That's why have change the state of `reentrancyLock` here.
        reentrancyLock = false;
        (bool success, ) = metaTx.targetContract.call(
            abi.encodePacked(signatures[0], metaTx.from)
        );

        require(success, "NFTifyMetaTx: function call not success");
    }

    function hash(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        bytes(
                            "MetaTransaction(uint256 nonce,address from,address targetContract,string request)"
                        )
                    ),
                    metaTx.nonce,
                    metaTx.from,
                    metaTx.targetContract,
                    keccak256(bytes(metaTx.request))
                )
            );
    }

    function hash(Item memory item) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        bytes(
                            "Item(uint256 tokenID,uint256 tokenType,address collection)"
                        )
                    ),
                    item.tokenID,
                    item.tokenType,
                    item.collection
                )
            );
    }

    function hash(BuyRequest memory buyRequest)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        bytes(
                            "BuyRequest(MetaTransaction metaTx,Item item,uint256 quantity,uint256 price,address seller,address paymentToken)Item(uint256 tokenID,uint256 tokenType,address collection)MetaTransaction(uint256 nonce,address from,address targetContract,string request)"
                        )
                    ),
                    hash(buyRequest.metaTx),
                    hash(buyRequest.item),
                    buyRequest.quantity,
                    buyRequest.price,
                    buyRequest.seller,
                    buyRequest.paymentToken
                )
            );
    }

    function hash(CancelSaleOrderRequest memory cancelRequest)
        internal
        pure
        returns (bytes32)
    {
        return (
            keccak256(
                abi.encode(
                    keccak256(
                        bytes(
                            "CancelSaleOrderRequest(MetaTransaction metaTx,Item item,uint256 quantity,uint256 price)Item(uint256 tokenID,uint256 tokenType,address collection)MetaTransaction(uint256 nonce,address from,address targetContract,string request)"
                        )
                    ),
                    hash(cancelRequest.metaTx),
                    hash(cancelRequest.item),
                    cancelRequest.quantity,
                    cancelRequest.price
                )
            )
        );
    }

    function hash(CancelOfferRequest memory cancelRequest)
        internal
        pure
        returns (bytes32)
    {
        return (
            keccak256(
                abi.encode(
                    keccak256(
                        bytes(
                            "CancelOfferRequest(MetaTransaction metaTx,Item item,uint256 quantity,uint256 yourOffer)Item(uint256 tokenID,uint256 tokenType,address collection)MetaTransaction(uint256 nonce,address from,address targetContract,string request)"
                        )
                    ),
                    hash(cancelRequest.metaTx),
                    hash(cancelRequest.item),
                    cancelRequest.quantity,
                    cancelRequest.yourOffer
                )
            )
        );
    }

    function hash(TransferNFTRequest memory transferRequest)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        bytes(
                            "TransferNFTRequest(MetaTransaction metaTx,Item item,uint256 quantity,address from,address to)Item(uint256 tokenID,uint256 tokenType,address collection)MetaTransaction(uint256 nonce,address from,address targetContract,string request)"
                        )
                    ),
                    hash(transferRequest.metaTx),
                    hash(transferRequest.item),
                    transferRequest.quantity,
                    transferRequest.from,
                    transferRequest.to
                )
            );
    }

    function hash(BoxOpenRequest memory boxOpenRequest)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    keccak256(
                        bytes(
                            "BoxOpenRequest(MetaTransaction metaTx,uint256 boxId,address boxAddress,uint256 quantity)MetaTransaction(uint256 nonce,address from,address targetContract,string request)"
                        )
                    ),
                    hash(boxOpenRequest.metaTx),
                    boxOpenRequest.boxId,
                    boxOpenRequest.boxAddress,
                    boxOpenRequest.quantity
                )
            );
    }
}

// * EIP712Domain
struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
}

// * Item
struct Item {
    uint256 tokenID;
    uint256 tokenType;
    address collection;
}

// * MetaTransaction
struct MetaTransaction {
    uint256 nonce;
    address from;
    address targetContract;
    string request;
}

// * BuyRequest
struct BuyRequest {
    MetaTransaction metaTx;
    Item item;
    uint256 quantity;
    uint256 price;
    address seller;
    address paymentToken;
}

// * CancelSaleOrderRequest
struct CancelSaleOrderRequest {
    MetaTransaction metaTx;
    Item item;
    uint256 quantity;
    uint256 price;
}

// * CancelOfferRequest
struct CancelOfferRequest {
    MetaTransaction metaTx;
    Item item;
    uint256 quantity;
    uint256 yourOffer;
}

// * TransferNFTRequest
struct TransferNFTRequest {
    MetaTransaction metaTx;
    Item item;
    uint256 quantity;
    address from;
    address to;
}

// * BoxOpenRequest
struct BoxOpenRequest {
    MetaTransaction metaTx;
    uint256 boxId;
    address boxAddress;
    uint256 quantity;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ReentrancyGuarded.sol";

abstract contract Upgradeable is ReentrancyGuarded {
    address public trustedForwarder;
    address public recipient;
    address public signatureUtils;

    address public feeUtils;
    address public offerHandler;
    address public boxUtils;
    mapping(bytes => bool) public openedBoxSignatures;

    mapping(address => bool) adminList;
    mapping(address => bool) public acceptedTokens;
    mapping(uint256 => uint256) public soldQuantity;
    mapping(bytes => bool) invalidSaleOrder;
    mapping(bytes => bool) invalidOffers;
    mapping(bytes => bool) acceptedOffers;
    mapping(bytes => uint256) public soldQuantityBySaleOrder;
    /**
     * Change from `currentSaleOrderByTokenID` to `_nonces`
     */
    mapping(address => uint256) public nonces;
    mapping(address => uint256) public tokensFee;
    address public metaHandler;

    address erc721NftAddress;
    address erc721OfferHandlerAddress;
    address erc721BuyHandlerAddress;
    address erc721OfferHandlerNativeAddress;
    address erc721BuyHandlerNativeAddress;
    address offerHandlerNativeAddress;
    address public buyHandler;
    address sellHandlerAddress;
    address erc721SellHandlerAddress;
    address public featureHandler;
    address public sellHandler;
    address erc721SellHandlerNativeAddress;

    mapping(string => mapping(string => bool)) storeFeatures;
    mapping(string => mapping(address => uint256)) royaltyFeeAmount;
    address public cancelHandler;
    mapping(string => mapping(address => uint256)) featurePrice; // featureId => tokenAddress => price
    mapping(string => mapping(string => mapping(address => uint256))) featureStakedAmount; // storeID => featureID => address => amount
    mapping(address => bool) signers;

    mapping(address => mapping(uint8 => bool)) subAdminList;

    function _delegatecall(address _impl) internal {
        require(_impl != address(0), "Impl address is 0");

        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(
                sub(gas(), 10000),
                _impl,
                ptr,
                calldatasize(),
                0,
                0
            )
            let size := returndatasize()
            returndatacopy(ptr, 0, size)
            switch result
            case 0 {
                revert(ptr, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper: Provide a single mechanism to verify both private-key (EOA) ECDSA signature and
 * ERC1271 contract signatures. Using this instead of ECDSA.recover in your contract will make them compatible with
 * smart contract wallets such as Argent and Gnosis.
 *
 * Note: unlike ECDSA signatures, contract signature's are revocable, and the outcome of this function can thus change
 * through time. It could return true at block N and false at block N+1 (or the opposite).
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
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

contract ReentrancyGuarded {
    bool reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard() {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
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
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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