//SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IVenari.sol";

contract VenariMarketplace is 
    ReentrancyGuard,
    Ownable
{
    using ECDSA for bytes32;

    event CancelListing(uint256 _tokenId);
    event MatchListing(uint256 _tokenId, address _buyer, address _seller);

    // mapping from an owner to a mapping of venari token ids to nonces
    mapping (address => mapping (uint256 => uint256)) private _sellerNonces;

    // track nonces of server side approvals
    mapping (address => mapping (uint256 => uint256)) private _serverNonces;

    uint256 private baseFeeNumerator = 50;
    uint256 private shardFeeNumerator = 300;
    uint256 private feeDenominator = 1000;

    bytes32 public immutable domainSeparator;

    IVenari private venariInterface;
    IERC20 private shardInterface;

    address private signVerifier;

    // keccak256("AddListing(address seller,uint256 tokenId,uint256 listingExpiryTimestamp,uint256 price)")
    bytes32 public constant ADD_LISTING_TYPEHASH = 0x415e30265e5490c67fce306eae57098102f9fada7c950adf662380fe2f8f4a35;
    // keccak256("AddListingBaseToken(address seller,uint256 tokenId,uint256 listingExpiryTimestamp,address baseTokenAddress,uint256 price)")
    bytes32 public constant ADD_LISTING_BASETOKEN_TYPEHASH = 0xe03a3d655fda03b186b889ec549966697994237d3b02c1ec0635fd5b65591948;

    mapping (address => bool) private allowedBaseTokens;
    bool private enableShardBurn;

    constructor () {
        uint256 chainID;

        assembly {
            chainID := chainid()
        }

        domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("Venari Marketplace")),
                keccak256(bytes("1")),
                chainID,
                address(this)
            )
        );
    }

    // @dev Sets the address of the venari contract
    function setVenariInterface(address venariInterfaceAddress) external onlyOwner {
        venariInterface = IVenari(venariInterfaceAddress);
    }

    // @dev Sets the address of the shard (ERC20) contract
    function setShardInterface(address shardInterfaceAddress) external onlyOwner {
        shardInterface = IERC20(shardInterfaceAddress);
    }

    // @dev Sets a new signature verifier
    function setSignVerifier(address verifier) public onlyOwner {
        signVerifier = verifier;
    }

    // @dev Sets the value for the enable flag for burning shard fees
    function setShardInterface(bool _enableShardBurn) external onlyOwner {
        enableShardBurn = _enableShardBurn;
    }

    function getSellerNonce(address owner, uint256 tokenId) public view returns (uint256) {
        return _sellerNonces[owner][tokenId];
    }

    function cancelListing(uint256 tokenId) external {
        require(venariInterface.ownerOf(tokenId) == msg.sender);
        _sellerNonces[msg.sender][tokenId]++;
        emit CancelListing(tokenId);
    }

    /**
     * @dev Execute match between a buyer and seller
     */
    function matchListing(
        uint256 tokenId,
        address seller,
        uint256 listingExpiry,
        uint256 price,
        bytes calldata ownerSig,
        uint256 txnExpiry,
        bytes calldata serverSig
    ) external payable nonReentrant {
        require(seller != address(0), "Seller must not be the zero address");
        require(venariInterface.ownerOf(tokenId) == seller, "Seller must own the venari");
        require(block.timestamp <= listingExpiry, "Listing expired");
        require(msg.value == price, "ETH sent mismatch");
        require(block.timestamp <= txnExpiry, "Transaction expired");

        // Verifies signatures of seller and server
        {   // Scoping for stack too deep error
            bytes32 message = _generateAddListingHash(seller, tokenId, listingExpiry, price).toEthSignedMessageHash();
            require(ECDSA.recover(message, ownerSig) == seller, "Recovered address does not match seller");

            message = generateServerAuthHash(msg.sender, tokenId, 0, txnExpiry).toEthSignedMessageHash();
            require(ECDSA.recover(message, serverSig) == signVerifier, "Recovered address does not match server");
        }

        // Update nonce
        _sellerNonces[seller][tokenId]++;
        _serverNonces[msg.sender][tokenId]++;

        // Redistribute ETH
        address passOwner;
        uint256 split;

        // Verify split
        (passOwner, split) = venariInterface.getVenariSplit(tokenId);
        require(split <= feeDenominator, "Split out of range");

        // Remove split
        venariInterface.removeSplit(tokenId);

        // Transfer Venari
        venariInterface.transferFrom(seller, msg.sender, tokenId);

        // Calculate Remaining Balance after Fee
        uint256 remainingBalance = price - (price * baseFeeNumerator / feeDenominator);
        require(remainingBalance <= msg.value);

        // If there is a split, distribute ETH amongst the owner of the venari and the associated passOwner
        if (passOwner != address(0)) {
            uint256 passOwnerEarnings = remainingBalance * split / feeDenominator;
            require(passOwnerEarnings <= remainingBalance);
            require(remainingBalance - passOwnerEarnings <= remainingBalance);
            payable(passOwner).transfer(passOwnerEarnings);
            payable(seller).transfer(remainingBalance - passOwnerEarnings);
        } else {
            payable(seller).transfer(remainingBalance);
        }

        emit MatchListing(tokenId, msg.sender, seller);
    }

function matchListingBaseToken(
        uint256 tokenId,
        address seller,
        uint256 listingExpiry,
        address baseTokenAddress,
        uint256 basePrice,
        uint256 shardPrice,
        bytes calldata ownerSig,
        uint256 txnExpiry,
        bytes calldata serverSig
    ) external payable nonReentrant {
        require(seller != address(0), "Seller must not be the zero address");
        require(venariInterface.ownerOf(tokenId) == seller, "Seller must own the venari");
        require(block.timestamp <= listingExpiry, "Listing expired");
        require(isAllowedBaseToken(baseTokenAddress), "ERC20 not permitted for marketplace");
        require(msg.value == 0, "msg.value != 0");
        require(block.timestamp <= txnExpiry, "Transaction expired");

        // Transfer funds from buyer to this contract. Will fail if allowances/amounts are not set properly
        IERC20(baseTokenAddress).transferFrom(msg.sender, address(this), basePrice);
        shardInterface.transferFrom(msg.sender, address(this), shardPrice);

        // Verifies signatures of seller and server
        {   // Scoping for stack too deep error
            bytes32 sellerMessage = _generateAddListingHashBaseToken(seller, tokenId, listingExpiry, baseTokenAddress, basePrice).toEthSignedMessageHash();
            require(ECDSA.recover(sellerMessage, ownerSig) == seller, "Recovered address does not match seller");

            bytes32 serverMessage = generateServerAuthHash(msg.sender, tokenId, shardPrice, txnExpiry).toEthSignedMessageHash();
            require(ECDSA.recover(serverMessage, serverSig) == signVerifier, "Recovered address does not match server");
        }

        // Update nonce
        _sellerNonces[seller][tokenId]++;
        _serverNonces[msg.sender][tokenId]++;

        // Handle base token payment
        {
            address passOwner;
            uint256 split;

            // Verify split
            (passOwner, split) = venariInterface.getVenariSplit(tokenId);
            require(split <= feeDenominator, "Split out of range");

            // Calculate Remaining Balance of base token after fee
            uint256 remainingBaseBalance = basePrice - (basePrice * baseFeeNumerator) / feeDenominator;
            require(remainingBaseBalance <= basePrice);

            // If there is a split, distribute ETH amongst the owner of the venari and the associated passOwner
            if (passOwner != address(0)) {
                uint256 passOwnerEarnings = (remainingBaseBalance * split) / feeDenominator;
                require(passOwnerEarnings <= remainingBaseBalance);
                IERC20(baseTokenAddress).transfer(passOwner, passOwnerEarnings);
                IERC20(baseTokenAddress).transfer(seller, remainingBaseBalance - passOwnerEarnings);
            } else {
                IERC20(baseTokenAddress).transfer(seller, remainingBaseBalance);
            }
        }

        // Handle shard payment
        {
            uint256 shardFee = (shardPrice * shardFeeNumerator) / feeDenominator;
            uint256 remainingShardBalance = shardPrice - shardFee;
            require(shardFee <= shardPrice); 
            if (enableShardBurn) {
                // TODO Burn Fee
            }
            shardInterface.transfer(seller, remainingShardBalance);
        }

        // Remove split
        venariInterface.removeSplit(tokenId);

        // Transfer Venari
        venariInterface.transferFrom(seller, msg.sender, tokenId);

        emit MatchListing(tokenId, msg.sender, seller);
    }

    function generateAddListingHash(
        address seller,
        uint256 tokenId,
        uint256 listingExpiry,
        uint256 price
    ) public view returns (bytes32) {
        return _generateAddListingHash(seller, tokenId, listingExpiry, price);
    }

    function generateAddListingHashBaseToken(
        address seller,
        uint256 tokenId,
        uint256 listingExpiry,
        address baseTokenAddress,
        uint256 price
    ) public view returns (bytes32) {
        return _generateAddListingHashBaseToken(seller, tokenId, listingExpiry, baseTokenAddress, price);
    }

    /**
     * @dev Generates the hash to be signed by the server authorizing a buyer to buy a venari
     */ 
    function generateServerAuthHash(
        address buyer,
        uint256 tokenId,
        uint256 shardPrice,
        uint256 txnExpiry
    )
    public pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                buyer,
                tokenId,
                shardPrice,
                txnExpiry
            )
        );
    }

    /**
     * @dev Generates the EIP712 hash that was signed for a seller listing their venari
     */ 
    function _generateAddListingHash(
        address seller,
        uint256 tokenId,
        uint256 listingExpiry,
        uint256 price
    ) private view returns (bytes32) {

        // Recreate signed message 
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        ADD_LISTING_TYPEHASH,
                        seller,
                        tokenId,
                        listingExpiry,
                        price,
                        _sellerNonces[seller][tokenId]
                    )
                )
            )
        );
    }

    /**
     * @dev Generates the EIP712 hash that was signed for a seller listing their venari in exchange for an ERC20
     */ 
    function _generateAddListingHashBaseToken(
        address seller,
        uint256 tokenId,
        uint256 listingExpiry,
        address baseTokenAddress,
        uint256 price
    ) private view returns (bytes32) {

        // Recreate signed message 
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        ADD_LISTING_BASETOKEN_TYPEHASH,
                        seller,
                        tokenId,
                        listingExpiry,
                        baseTokenAddress,
                        price,
                        _sellerNonces[seller][tokenId]
                    )
                )
            )
        );
    }

    function _recoverSigner(bytes32 _hash, bytes memory _sig) private pure returns (address) {
        address signer = ECDSA.recover(_hash, _sig);
        require(signer != address(0));
        return signer;
    }

    function setBaseFeeNumerator(uint256 _baseFeeNumerator) external onlyOwner {
        require(_baseFeeNumerator <= feeDenominator);
        baseFeeNumerator = _baseFeeNumerator;
    }

    function setShardFeeNumerator(uint256 _shardFeeNumerator) external onlyOwner {
        require(_shardFeeNumerator <= feeDenominator);
        shardFeeNumerator = _shardFeeNumerator;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function addAllowedBaseToken(address _baseTokenAddress) external onlyOwner {
        allowedBaseTokens[_baseTokenAddress] = true; 
    }

    function delAllowedBaseToken(address _baseTokenAddress) external onlyOwner {
        allowedBaseTokens[_baseTokenAddress] = false;
    }

    function isAllowedBaseToken(address _baseTokenAddress) public view returns (bool) {
        return allowedBaseTokens[_baseTokenAddress];
    }

    function withdrawToken(address _tokenAddress) external nonReentrant onlyOwner {
        IERC20 token = IERC20(_tokenAddress);
        token.transfer(msg.sender, token.balanceOf(address(this)));
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/**
 * @title Interface for Venari
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IVenari is IERC721Enumerable {

    /**
     * @dev Removes the split on a given Venari, can only be called by the marketplace
     */
    function removeSplit(uint256 tokenId) external;

    /**
     * @dev Checks if a venari has a split
     */
    function hasSplit(uint256 tokenId) external view returns (bool);

    /**
     * @dev Gets the current venari split
     */
    function getVenariSplit(uint256 tokenId) external view returns (address, uint256);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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