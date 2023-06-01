// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

/*
 * https://github.com/ProjectOpenSea/meta-transactions/blob/main/contracts/ERC721MetaTransactionMaticSample.sol
 */

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/ContextMixin.sol
 */
abstract contract ContextMixin {
    function msgSender() internal view returns (address payable sender) {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = payable(msg.sender);
        }
        return sender;
    }
}

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/Initializable.sol
 */
contract Initializable {
    bool initiated = false;
    modifier initializer() {
        require(!initiated);
        _;
        initiated = true;
    }
}

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/EIP712Base.sol
 */
contract EIP712Base is Initializable {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }
    string public constant ERC712_VERSION = "1";
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes(
                "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
            )
        );
    bytes32 internal domainSeperator;
    function _initializeEIP712(string memory name) internal initializer {
        _setDomainSeperator(name);
    }
    function _setDomainSeperator(string memory name) internal {
        domainSeperator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(ERC712_VERSION)),
                address(this),
                bytes32(getChainId())
            )
        );
    }
    function getDomainSeperator() public view returns (bytes32) {
        return domainSeperator;
    }
    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }
    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(
        bytes32 messageHash
    ) internal view returns (bytes32) {
        return
            keccak256(
                abi.encodePacked("\x19\x01", getDomainSeperator(), messageHash)
            );
    }
}

/**
 * https://github.com/maticnetwork/pos-portal/blob/master/contracts/common/NativeMetaTransaction.sol
 */
contract NativeMetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(
            bytes(
                "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
            )
        );
    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }
    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "NativeMetaTransaction: SIGNATURE_MISMATCH"
        );
        nonces[userAddress] = nonces[userAddress] + 1;
        emit MetaTransactionExecuted(
            userAddress,
            payable(msg.sender),
            functionSignature
        );
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "NativeMetaTransaction: FUNCTION_CALL_ERROR");
        return returnData;
    }
    function hashMetaTransaction(
        MetaTransaction memory metaTx
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }
    function getNonce(address user) public view returns (uint256 nonce) {
        nonce = nonces[user];
    }
    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NativeMetaTransaction: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

contract BloodTransferBasic is ContextMixin, NativeMetaTransaction {
    address public bloodTokenAddress;
    string public name;
    constructor(string memory name_, address bloodTokenAddress_) {
        name = name_;
        bloodTokenAddress = bloodTokenAddress_;
        _initializeEIP712(name_);
    }
    function _msgSender() internal view returns (address sender) {
        return ContextMixin.msgSender();
    }
    function transfer(address receiver, uint256 amount) public {
        address sender = _msgSender();
        require(sender != tx.origin, "BloodTransferBasic: EOA_PROHIBITED");
        (bool success, ) = address(bloodTokenAddress).call(
            abi.encodeWithSignature(
                "transferFrom(address,address,uint256)",
                sender,
                receiver,
                amount
            )
        );
        require(success, "BloodTransferBasic: BLOOD_TRANSFER_ERROR");
    }
}