/**
 *Submitted for verification at polygonscan.com on 2023-06-08
*/

// File: libraries/VerifierInputFormat.sol


pragma solidity ^0.8.17;

library VerifierInputFormat {
    function changeBytes32ToVerifierInputFormat(
        bytes32 self
    ) internal pure returns (uint256 firstHalf, uint256 secondHalf) {
        bytes32 pubKeyLeFormat = convertToLittleEndian(self);
        (
            bytes16 firstHalfLeFormat,
            bytes16 secondHalfLeFormat
        ) = splitBytes32AndSwap(pubKeyLeFormat);

        firstHalf = uint256(bytes32(firstHalfLeFormat) >> (16 * 8));
        secondHalf = uint256(bytes32(secondHalfLeFormat) >> (16 * 8));
    }

    function splitBytes32AndSwap(
        bytes32 input
    ) internal pure returns (bytes16, bytes16) {
        bytes16 firstHalf = bytes16(input);
        bytes16 secondHalf = bytes16(input << 128);
        return (secondHalf, firstHalf);
    }

    function convertToLittleEndian(
        bytes32 input
    ) internal pure returns (bytes32) {
        bytes32 output;
        for (uint256 i = 0; i < 32; i++) {
            bytes32 nextByte;
            nextByte = input[i];
            output |= nextByte >> ((31 - i) * 8);
        }

        return output;
    }
}

// File: interfaces/IVerifier.sol


pragma solidity ^0.8.17;

interface IVerifier {
    function verifyProof(
        uint256[2] memory a,
        uint256[2][2] memory b,
        uint256[2] memory c,
        uint256[3] memory input
    ) external view returns (bool r);
}

// File: interfaces/IDIDRegistry.sol


pragma solidity ^0.8.7;

interface IDIDRegistry {
    struct IdentifierInfo {
        bool isRegistered;
        bytes pubKey;
        string signatureSchema;
        string name;
        string symbol;
    }

    event AcceptedIdentifier(string indexed did);
    event DeclinedIdentifier(string indexed did);
    event RemovedIdentifier(string indexed did, string reason);

    function registerDID(
        string calldata did,
        string calldata name,
        string calldata symbol,
        string calldata signatureAlgorithm,
        bytes calldata pubKey
    ) external;

    function acceptDID(string calldata did) external;

    function declineDID(string calldata did) external;

    function removeDID(string calldata did, string calldata reason) external;

    function getDID(
        string calldata did
    ) external view returns (IdentifierInfo memory);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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

// File: VerificationCenter.sol


pragma solidity ^0.8.17;





contract VerificationCenter is Ownable {
    using VerifierInputFormat for bytes32;

    IDIDRegistry public immutable DIDregistry;
    mapping(string => IVerifier) public verifiers;

    constructor(address _DIDregistry) {
        DIDregistry = IDIDRegistry(_DIDregistry);
    }

    function verifyClaim(
        string calldata issuerDID,
        bytes calldata proofs,
        bytes32 major
    ) public view returns (IDIDRegistry.IdentifierInfo memory) {
        IDIDRegistry.IdentifierInfo memory issuer = DIDregistry.getDID(
            issuerDID
        );
        bytes32 issuerPubKey = bytes32(issuer.pubKey);
        require(
            bytes32(issuerPubKey) != bytes32(0x0),
            "Can not find issuer DID"
        );

        string memory signatureSchema = issuer.signatureSchema;
        IVerifier verifier = verifiers[signatureSchema];
        require(address(verifier) != address(0x0), "The schema does not support.");

        (uint256[2] memory a, uint256[2][2] memory b, uint256[2] memory c) = abi
            .decode(proofs, (uint256[2], uint256[2][2], uint256[2]));

        (uint256 firstHalfPubKey, uint256 secondHalfPubKey) = issuerPubKey
            .changeBytes32ToVerifierInputFormat();

        uint256[3] memory input = [
            (firstHalfPubKey),
            (secondHalfPubKey),
            uint256(major)
        ];

        bool result = verifier.verifyProof(a, b, c, input);
        require(result, "Verification fails");

        return issuer;
    }

    function addVerifier(string calldata schema, address verifierAddress) public onlyOwner {
        verifiers[schema] = IVerifier(verifierAddress);
    }
}