// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Ownable.sol";
import "./ECDSA.sol";
import "./IERC20.sol";
import "./IERC1155.sol";
error InvalidSignature();

contract Marketplace is Ownable{
    using ECDSA for bytes32;

    struct Payment{
        bytes4 paymentClass;
        bytes data;
        uint256 amount;
    }

    struct Order{
        address maker;
        // uint256 tokenId;
        uint256 rentalId;
        uint256 numberOfTokens;
        Payment payment;
        uint256 salt;
    }

    uint256 public constant UINT256_MAX = 2**256 - 1;
    bytes4 constant public MATIC_PAYMENT_CLASS = bytes4(keccak256("MATIC"));
    bytes4 constant public ERC20_PAYMENT_CLASS = bytes4(keccak256("ERC20"));
    bytes32 constant PAYMENT_TYPEHASH = keccak256(
        "Payment(bytes4 paymentClass,bytes data,uint256 amount)"
    );
    bytes32 private constant SELL_ORDER_TYPEHASH =
        keccak256("SellOrder(address maker,uint256 rentalId,uint256 numberOfTokens,Payment payment,uint256 salt)Payment(bytes4 paymentClass,bytes data,uint256 amount)");

    uint256 public royaltyFee;
    uint256 public platformFee;
    address public platformFeeReceiver;
    address public royaltiesReceiver;
    address public collectionAddress;

    
    bytes32 private DOMAIN_SEPARATOR;
    
    mapping(bytes32 => uint256) public fills;

    event Cancel(bytes32 hash, address maker, uint256 rentalId, uint256 numberOfTokens ,uint256 salt);

    constructor( 
        uint256 _platformFee,
        uint256 _royaltyFee,
        address _platformFeeReceiver,
        address _royaltiesReceiver,
        address _collectionAddress
    ){
        royaltyFee = _royaltyFee;
        platformFee = _platformFee; // 250 = 2.5%
        platformFeeReceiver = _platformFeeReceiver;
        royaltiesReceiver = _royaltiesReceiver;
        collectionAddress = _collectionAddress;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }

        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256(
                "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256(bytes("SellOrder")),
                keccak256(bytes("1")),
                chainId,
                address(this)
            )
        );
    }

    function orderHash(Order memory order) public pure returns(bytes32){
        return keccak256(abi.encode(
                order.maker,
                order.rentalId,
                order.numberOfTokens,
                order.salt
            ));
    }

    function cancel(Order memory order) external {
        require(msg.sender == order.maker, "not a maker");
        require(order.salt != 0, "0 salt can't be used");
        bytes32 orderKeyHash = orderHash(order);
        fills[orderKeyHash] = UINT256_MAX;
        emit Cancel(orderKeyHash, order.maker, order.rentalId, order.numberOfTokens, order.salt);
    }

    function buyRental(Order memory sellOrder, bytes memory sellSignature, uint256 numberOfRentals) external payable{
        validateSellSignature(sellOrder, sellSignature);
        updateOrderFill(sellOrder, numberOfRentals);
        uint256 totalPayment = calculateTotalPayment(sellOrder.payment);
        doPaymentTransfer(totalPayment, sellOrder.maker, sellOrder.payment);
        doRentalTransfer(sellOrder.maker, sellOrder.rentalId, sellOrder.numberOfTokens);
    }

    function validateSellSignature(Order memory sellOrder, bytes memory sellSignature) internal view{
        if (sellOrder.salt == 0) revert("Invalid salt, should not be 0");

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    SELL_ORDER_TYPEHASH, 
                    sellOrder.maker, 
                    sellOrder.rentalId, 
                    sellOrder.numberOfTokens,
                    paymentHash(sellOrder.payment),
                    sellOrder.salt)
                )
            )
        );

        address signer = digest.recover(sellSignature);
        if(signer == address(0) || signer != sellOrder.maker) revert InvalidSignature();
    }

    function paymentHash(Payment memory payment) internal pure returns(bytes32){
        return keccak256(abi.encode(PAYMENT_TYPEHASH, payment.paymentClass, payment.data, payment.amount));
    }

    function updateOrderFill(Order memory sellOrder, uint256 numberOfRentals) internal {
        uint256 orderFill = fills[orderHash(sellOrder)];
        if( orderFill > sellOrder.numberOfTokens ) revert("Already filled");
        uint256 remainingToFill = sellOrder.numberOfTokens - orderFill;
        if(numberOfRentals > remainingToFill) revert("insufficient fill remaining");
        fills[orderHash(sellOrder)] += numberOfRentals;
    }

    function calculateTotalPayment(Payment memory payment) internal view returns(uint256 totalPayment){
        totalPayment = payment.amount;
        // adding buyer-side platform fee to total payment
        totalPayment += (totalPayment * platformFee) / 20000;
    }

    function doPaymentTransfer(uint256 totalPayment, address seller, Payment memory payment) internal {
        // Transfer platform fees
        uint256 remainingPayment = totalPayment;
        uint256 currentPayment;
        if (payment.paymentClass == MATIC_PAYMENT_CLASS) {
            
            if(msg.value < totalPayment) revert("Insufficient payment");
            
            // Pay platform fee
            currentPayment = (payment.amount * platformFee ) / 10000;
            transferMatic(platformFeeReceiver, currentPayment);
            remainingPayment -= currentPayment;

            // Transfer royalties
            currentPayment = (remainingPayment*royaltyFee) / 10000;
            transferMatic(royaltiesReceiver, currentPayment);
            remainingPayment -= currentPayment;

            // Transfer remaining payment to seller
            transferMatic(seller, remainingPayment);

        }
        
        else if( payment.paymentClass == ERC20_PAYMENT_CLASS){

            (address token) = abi.decode(payment.data, (address));

            // Pay platform fee
            currentPayment = (payment.amount * platformFee ) / 10000;
            IERC20(token).transfer(platformFeeReceiver, currentPayment);
            remainingPayment -= currentPayment;

            // Transfer royalties
            currentPayment = (remainingPayment*royaltyFee) / 10000;
            IERC20(token).transfer(royaltiesReceiver, currentPayment);
            remainingPayment -= currentPayment;

            // Transfer remaining payment to seller
            IERC20(token).transfer(seller, remainingPayment);
        }

        else{
            revert("Invalid payment class");
        }
    }

    function doRentalTransfer(address from, uint256 rentalId, uint256 numberOfTokens) internal {
        IERC1155(collectionAddress).safeTransferFrom(from, msg.sender, rentalId, numberOfTokens, "");
    }

    function transferMatic(address to, uint value) internal {
        (bool success,) = to.call{ value: value }("");
        require(success, "transfer failed");
    }

    uint256[50] private __gap;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "./Strings.sol";

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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

interface IERC1155 {

function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
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