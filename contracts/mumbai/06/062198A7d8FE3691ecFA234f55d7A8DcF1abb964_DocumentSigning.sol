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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract DocumentSigning is Ownable {
    uint public price = 1 ether;
    address public fundWallet = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    struct Document {
        bytes32 hash; // Hash of the PDF
        address[] parties;
        mapping(address => bool) signedBy; // Mapping to keep track of which parties have signed
    }

    mapping(bytes32 => Document) public documents; // Mapping to store documents by their hash
    // address[] public parties;

    // Event to notify parties when a document has been fully signed
    event DocumentFullySigned(bytes32 documentHash);

    //Function to get the hash of the document's byte32 data
    function hashPDF(bytes memory pdfData) public pure returns (bytes32) {
        // Compute the SHA-256 hash of the PDF data
        bytes32 hash = sha256(pdfData);
        return hash;
    }

    // Function to upload a password-protected PDF to the system
    function uploadDocument(
        bytes32 documentHash,
        address[] memory _parties
    ) external payable {
        require(msg.value >= 1 ether, "Insufficient ethers provided");
        payable(fundWallet).transfer(msg.value);
        Document storage document = documents[documentHash];
        require(document.hash == bytes32(0), "Document already exists");

        // Store the hash of the PDF
        document.hash = documentHash;
        document.parties = _parties;
    }

    // Function for parties to sign the document
    function signDocument(bytes32 documentHash) external payable {
        require(msg.value >= 1 ether, "Insufficient ethers provided");
        payable(fundWallet).transfer(msg.value);
        Document storage document = documents[documentHash];
        require(
            checkIfPartyMemberValid(msg.sender, document),
            "Invalid Member"
        );
        require(document.hash != bytes32(0), "Document does not exist");
        require(!document.signedBy[msg.sender], "Already signed by this party");

        // Mark the document as signed by the sender
        document.signedBy[msg.sender] = true;

        // Emit an event if all parties have signed
        if (isDocumentFullySigned(document)) {
            emit DocumentFullySigned(documentHash);
        }
    }

    // Function to check if all parties have signed the document
    function isDocumentFullySigned(
        Document storage document
    ) internal view returns (bool) {
        for (uint256 i = 0; i < document.parties.length; i++) {
            if (!document.signedBy[document.parties[i]]) {
                return false;
            }
        }
        return true;
    }

// Function to check if party wanting to sign a document is eligible
    function checkIfPartyMemberValid(
        address _member,
        Document storage document
    ) internal view returns (bool) {
        for (uint i = 0; i < document.parties.length; i++) {
            if (document.parties[i] == _member) {
                return true;
            }
        }
        return false;
    }
// Function to check if all addresss that have to sign a document
    function viewPartyMembersForDocument(
        bytes32 documentHash
    ) public view returns (address[] memory) {
        Document storage document = documents[documentHash];
        return document.parties;
    }

// Function to change price
    function setNewPrice(uint _newPrice) external onlyOwner {
        price = _newPrice;
    }

// Function to change fund wallet
    function setNewWallet(address _newWallet) external onlyOwner {
        fundWallet = _newWallet;
    }

// Function to check the signer status of which parties have signed and which have not
    function viewSignerStatus(
        bytes32 documentHash
    ) external view returns (address[] memory, bool[] memory) {
        Document storage document = documents[documentHash];
        uint256 numParties = document.parties.length;
        address[] memory parties = new address[](numParties);
        bool[] memory signedStatus = new bool[](numParties);

        for (uint256 i = 0; i < numParties; i++) {
            parties[i] = document.parties[i];
            signedStatus[i] = document.signedBy[document.parties[i]];
        }
        return (parties, signedStatus);
    }
}