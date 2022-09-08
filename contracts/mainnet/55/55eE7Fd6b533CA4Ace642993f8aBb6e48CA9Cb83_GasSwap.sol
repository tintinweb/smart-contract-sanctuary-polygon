//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

contract EIP712Base {

    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"));

    bytes32 internal domainSeparator;

    constructor(string memory name, string memory version) {
        domainSeparator = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            address(this),
            bytes32(getChainID())
        ));
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() private view returns(bytes32) {
        return domainSeparator;
    }

    /**
    * Accept message hash and returns hash message in EIP712 compatible form
    * So that it can be used to recover signer from signature signed using EIP712 formatted data
    * https://eips.ethereum.org/EIPS/eip-712
    * "\\x19" makes the encoding deterministic
    * "\\x01" is the version byte to make it compatible to EIP-191
    */
    function toTypedMessageHash(bytes32 messageHash) internal view returns(bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./EIP712Base.sol";

contract EIP712MetaTransaction is EIP712Base {
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(address userAddress, address payable relayerAddress, bytes functionSignature);
    mapping(address => uint256) private nonces;

    /*
     * Meta transaction structure.
     * No point of including value field here as if user is doing value transfer then he has the funds to pay for gas
     * He should call the desired function directly in that case.
     */
    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    constructor(string memory name, string memory version) EIP712Base(name, version) {}

    function convertBytesToBytes4(bytes memory inBytes) internal pure returns (bytes4 outBytes4) {
        if (inBytes.length == 0) {
            return 0x0;
        }

        assembly {
            outBytes4 := mload(add(inBytes, 32))
        }
    }

    function executeMetaTransaction(address userAddress,
        bytes memory functionSignature, bytes32 sigR, bytes32 sigS, uint8 sigV) public payable returns(bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(destinationFunctionSig != msg.sig, "functionSignature can not be of executeMetaTransaction method");
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");
        nonces[userAddress] += 1;
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(abi.encodePacked(functionSignature, userAddress));

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            META_TRANSACTION_TYPEHASH,
            metaTx.nonce,
            metaTx.from,
            keccak256(metaTx.functionSignature)
        ));
    }

    function getNonce(address user) external view returns(uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(address user, MetaTransaction memory metaTx, bytes32 sigR, bytes32 sigS, uint8 sigV) internal view returns (bool) {
        address signer = ecrecover(toTypedMessageHash(hashMetaTransaction(metaTx)), sigV, sigR, sigS);
        require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns(address sender) {
        if(msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "./EIP712MetaTransaction.sol";

struct Transformation {
    uint32 _uint32;
    bytes _bytes;
}

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract GasSwap is EIP712MetaTransaction("GasSwap", "2") {
    address public owner;
    address public authorizedTarget;

    constructor() {
        owner = msg.sender;
        authorizedTarget = 0xDef1C0ded9bec7F1a1670819833240f027b25EfF;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY_OWNER");
        _;
    }

    receive() external payable {
        require(isContract(msgSender()), "REVERT_EOA_DEPOSIT");
    }

    function changeOwner(address newOwner)
        external
        onlyOwner
    {
        owner = newOwner;
    }

    function changeTarget(address newTarget)
        external
        onlyOwner
    {
        require(isContract(newTarget), "NO_CONTRACT_AT_ADDRESS");
        authorizedTarget = newTarget;
    }

    function withdrawToken(IERC20 token, uint256 amount)
        external
        onlyOwner
    {
        require(token.transfer(msg.sender, amount));
    }

    // Transfer ETH held by this contract to the sender/owner.
    function withdrawETH(uint256 amount)
        external
        onlyOwner
    {
        payable(msg.sender).transfer(amount);
    }

    // Swaps ERC20->MATIC tokens held by this contract using a 0x-API quote.
    function fillQuote(address spender, bytes calldata swapCallData) external returns (uint256)
    {
        (address inputToken,address outputToken,uint256 inputAmount,uint256 minOutputAmount,) = abi.decode(swapCallData[4:], (address,address,uint256,uint256,Transformation[]));
        require(outputToken == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, "INVALID_OUTPUT_TOKEN");
        IERC20 sellToken = IERC20(inputToken);
        require(sellToken.transferFrom(msgSender(), address(this), inputAmount), "TRANSFER_FAILED");
        require(sellToken.approve(spender, uint256(0)), "APPROVAL_WIPE_FAILED");
        require(sellToken.approve(spender, inputAmount), "REAPPROVAL_FAILED");
        (bool success, bytes memory res) = authorizedTarget.call(swapCallData);
        require(success, string(concat(bytes("SWAP_FAILED: "),bytes(getRevertMsg(res)))));
        uint256 outputTokenAmount = abi.decode(res, (uint256));
        require(outputTokenAmount >= minOutputAmount, "SWAP_VALUE_MISMATCH");
        payable(msgSender()).transfer(outputTokenAmount);
        return outputTokenAmount;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function concat(bytes memory a, bytes memory b) internal pure returns (bytes memory) {
        return abi.encodePacked(a, b);
    }

    function getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        if (_returnData.length < 68)
            return "Transaction reverted silently";

        assembly {
            _returnData := add(_returnData, 0x04)
        }

        return abi.decode(_returnData, (string));
    }
}