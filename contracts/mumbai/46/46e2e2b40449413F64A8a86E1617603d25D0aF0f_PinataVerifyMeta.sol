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
        // _transferOwnership(_msgSender());
        _transferOwnership(0x294bedFf7EddcEf40447837Bc788F2f9Cdde34Cc);


        
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./lib/EIP712Base.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract EIP712MetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH =
        keccak256(bytes("MetaTransaction(uint256 nonce,address from,bytes functionSignature)"));

    event MetaTransactionExecuted(
        address userAddress,
        address payable relayerAddress,
        bytes functionSignature
    );

    event signerEvent(address signer);

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

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) public payable returns (bytes memory) {
        bytes4 destinationFunctionSig = convertBytesToBytes4(functionSignature);
        require(
            destinationFunctionSig != msg.sig,
            "functionSignature can not be of executeMetaTransaction method"
        );
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });
        // require(verify(userAddress, metaTx, sigR, sigS, sigV), "Signer and signature do not match");
        verify(userAddress, metaTx, sigR, sigS, sigV);

        nonces[userAddress] = nonces[userAddress].add(1);
        // Append userAddress at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call(
            abi.encodePacked(functionSignature, userAddress)
        );

        require(success, "Function call not successful");
        emit MetaTransactionExecuted(userAddress, payable(msg.sender), functionSignature);
        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx) internal pure returns (bytes32) {
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

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address user,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal returns (bool) {
        address signer = ecrecover(
            toTypedMessageHash(hashMetaTransaction(metaTx)),
            sigV,
            sigR,
            sigS
        );

        emit signerEvent(signer);
        // require(signer != address(0), "Invalid signature");
        return signer == user;
    }

    function msgSender() internal view returns (address sender) {
        if (msg.sender == address(this)) {
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            bytes("EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)")
        );

    bytes32 internal domainSeparator;

    constructor(string memory name, string memory version) {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainID())
            )
        );
    }

    function getChainID() internal view returns (uint256 id) {
        assembly {
            id := chainid()
        }
    }

    function getDomainSeparator() private view returns (bytes32) {
        return domainSeparator;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", getDomainSeparator(), messageHash));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
import "./HELPER_CONTRACTS/EIP712MetaTransaction.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error PinataVerify__NoApproval(address approvedFrom, address approvedTo);
error PinataVerify__NotVerified(address approvedFrom, address approvedTo);

contract PinataVerifyMeta is EIP712MetaTransaction("PinataVerify", "1"), Ownable {
    enum PermissionLevel {
        None,
        Private,
        Public
    }

    struct DataUpload {
        string ipfsHash;
        string ipfsId;
        bool verified;
    }

    event giveApproval(
        address indexed approvedTo,
        address indexed approvedFrom,
        PermissionLevel permissionLevel,
        bytes approvedFromName
    );

    // event dataUploadSuccess(
    //     address indexed uploadedFrom,
    //     address indexed approvedFrom,
    //     DataUpload dataUpload
    // );

    event dataUploadSuccess(
        address uploadedFrom,
        address approvedFrom,
        string ipfsHash,
        string ipfsId,
        string testName,
        uint256 rating
    );

    event dataUploadVerified(
        address indexed uploadedFrom,
        address indexed approvedFrom,
        DataUpload dataUpload
    );

    mapping(address => mapping(address => PermissionLevel)) private s_approvals;
    mapping(address => mapping(address => DataUpload)) private s_uploads;
    mapping(address => address[]) private s_name_register;

    modifier isApproved(address approvedFrom) {
        PermissionLevel permissionLevel = s_approvals[msgSender()][approvedFrom];

        if (permissionLevel == PermissionLevel.None) {
            revert PinataVerify__NoApproval(msgSender(), approvedFrom);
        }
        _;
    }

    modifier isVerified(address approvedTo) {
        PermissionLevel permissionLevel = s_approvals[approvedTo][msgSender()];
        if (permissionLevel == PermissionLevel.None) {
            revert PinataVerify__NotVerified(approvedTo, msgSender());
        }
        _;
    }

    // CHANGE APPROVEDTO --> APPROVEDROM
    function grantPermission(
        address approvedFrom,
        bytes memory approvedFromName,
        PermissionLevel permissionLevel
    ) public {
        require(
            approvedFrom != msgSender(),
            "Uploader and the address to grant access should be different"
        );
        s_approvals[msgSender()][approvedFrom] = permissionLevel;
        s_name_register[msgSender()].push(approvedFrom);

        emit giveApproval(msgSender(), approvedFrom, permissionLevel, approvedFromName);
    }

    function uploadData(
        address approvedFrom,
        string memory ipfsHash,
        string memory ipfsId,
        string memory testName,
        uint256 rating
    ) external isApproved(approvedFrom) {
        // DataUpload memory dataUpload = DataUpload(ipfsHash, ipfsId, false);
        s_uploads[msgSender()][approvedFrom] = DataUpload(ipfsHash, ipfsId, false);
        // emit dataUploadSuccess(msgSender(), approvedFrom, dataUpload);
        emit dataUploadSuccess(msgSender(), approvedFrom, ipfsHash, ipfsId, testName, rating);
    }

    function verifyDataUpload(
        address approvedTo,
        string memory signedIpfsHash
    ) external isVerified(approvedTo) {
        s_uploads[approvedTo][msgSender()].verified = true;
        s_uploads[approvedTo][msgSender()].ipfsHash = signedIpfsHash;
        DataUpload memory dataUpload = s_uploads[approvedTo][msgSender()];
        emit dataUploadVerified(approvedTo, msgSender(), dataUpload);
    }

    function checkGivenPermission(address approvedTo) public view returns (PermissionLevel) {
        return s_approvals[msgSender()][approvedTo];
    }

    function checkReceivedPermission(address approvedFrom) public view returns (PermissionLevel) {
        return s_approvals[approvedFrom][msgSender()];
    }

    function checkUploads(address approvedFrom) public view returns (DataUpload[2] memory) {
        return [s_uploads[msgSender()][approvedFrom], s_uploads[approvedFrom][msgSender()]];
    }

    // function _setTrustedForwarder(address _forwarder) internal override {
    //     _trustedForwarder(_forwarder);
    // }

    // function msgSender()
    //     internal
    //     view
    //     override(ContextUpgradeable, ERC2771Recipient)
    //     returns (address sender)
    // {
    //     sender = ERC2771Recipient.msgSender();
    // }

    // function _msgData()
    //     internal
    //     view
    //     override(ContextUpgradeable, ERC2771Recipient)
    //     returns (bytes calldata)
    // {
    //     return ERC2771Recipient._msgData();
    // }

    // function versionRecipient() external pure returns (string memory) {
    //     return "1";
    // }

    // function setTrustedForwarder(address _trustedForwarder) public {
    //     // trustedForwarder = _trustedForwarder;
    //     // _setTrustedForwarder(_trustedForwarder)
    // }

    // function _msgSender()
    //     internal
    //     view
    //     override(ContextUpgradeable, ERC2771Recipient)
    //     returns (address sender)
    // {
    //     sender = ERC2771Recipient._msgSender();
    // }

    // function _msgData()
    //     internal
    //     view
    //     override(ContextUpgradeable, ERC2771Recipient)
    //     returns (bytes calldata)
    // {
    //     return ERC2771Recipient._msgData();
    // }

    // function versionRecipient() external pure returns (string memory) {
    //     return "1";
    // }
}

/////////////////////////////////////////////////////////
////////////////////NEEDED FUNCTIONS/////////////////////
/////////////////////////////////////////////////////////
// CHECK ALL ADDRESSES + PERMISSIONLEVEL I GAVE PERMISSION
// CHECK ALL ADDRESSES + PERMISSIONLEVEL I RECEIVED PERMISSION