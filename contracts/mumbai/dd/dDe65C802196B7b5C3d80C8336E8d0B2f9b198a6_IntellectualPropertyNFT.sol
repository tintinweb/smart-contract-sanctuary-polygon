/**
 *Submitted for verification at polygonscan.com on 2023-03-08
*/

// File: contracts/EIP5345.sol



// EIP-5345: Silent Signing Extension for JSON-RPC

pragma solidity ^0.8.11;

contract SilentSigner {

    struct PendingTransaction {
        address to;
        uint256 value;
        bytes data;
    }

    mapping(address => mapping(uint256 => PendingTransaction)) private _pendingTransactions;
    uint256 private _transactionCount;

    event LogTransactionSubmitted(address indexed user, uint256 indexed transactionId);

    //allows users to submit transactions by calling the submitTransaction function, 
    //which stores the transaction in a struct. The struct is stored in a mapping with the 
    //user's address and a transaction ID as the key
    function submitTransaction(address _to, uint256 _value, bytes memory _data) public {
        _pendingTransactions[msg.sender][_transactionCount] = PendingTransaction(_to, _value, _data);
        emit LogTransactionSubmitted(msg.sender, _transactionCount);
        _transactionCount++;
    }

    //off-chain signing service can then read the pending transaction from the 
    //smart contract using the getPendingTransaction function, sign it, and broadcast it to the blockchain
    function getPendingTransaction(address _user, uint256 _transactionId) public view returns (address to, uint256 value, bytes memory data) {
        PendingTransaction storage pendingTransaction = _pendingTransactions[_user][_transactionId];
        return (pendingTransaction.to, pendingTransaction.value, pendingTransaction.data);
    }
}
// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol


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

// File: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/ERC165.sol


// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;


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

// File: contracts/EIP5289.sol



pragma solidity ^0.8.11;

// import "https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5289.md";


contract ERC5289Library is IERC165 {
    event DocumentSigned(address indexed signer, uint16 indexed documentId);
    
    mapping (address => mapping (uint16 => uint64)) private signedTimestamps;
    mapping (uint16 => string) private documents;


    function legalDocument(uint16 documentId) external view returns (string memory) {
        return documents[documentId];
    }
    
    function documentSigned(address user, uint16 documentId) external view returns (bool signed) {
        return signedTimestamps[user][documentId] != 0;
    }

    function documentSignedAt(address user, uint16 documentId) external view returns (uint64 timestamp) {
        return signedTimestamps[user][documentId];
    }

    function signDocument(address signer, uint16 documentId) external {
        string memory empty = "";
        require(keccak256(bytes(documents[documentId])) != keccak256(bytes(empty)), "Document does not exist");
        require(signedTimestamps[signer][documentId] == 0, "Document already signed");
        signedTimestamps[signer][documentId] = uint64(block.timestamp);
        emit DocumentSigned(signer, documentId);
    }
    
    function addDocument(string memory document, uint16 documentId) external {
        string memory empty = "";
        require(keccak256(bytes(documents[documentId])) == keccak256(bytes(empty)), "Document already exists");
        documents[documentId] = document;
    }
    
    function removeDocument(uint16 documentId) external {
        string memory empty = "";
        require(keccak256(bytes(documents[documentId])) != keccak256(bytes(empty)), "Document does not exist");
        documents[documentId] = "";
    }
    
    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        // return interfaceId == IERC165.interfaceId;
        return interfaceId == type(IERC165).interfaceId;
    }
}



contract DocumentSignerImpl is ERC5289Library {
    mapping (bytes32 => bytes) public documents;
    mapping (address => mapping (bytes32 => bool)) public signatures;
    mapping (address => mapping (bytes32 => uint64)) private signedTimestamps;

    event DocumentSignedHash(address indexed signer, bytes32 indexed hash);


    function offChainSignature(bytes memory _signedData) public {
        bytes32 documentHash = keccak256(abi.encodePacked(_signedData));
        require(!signatures[msg.sender][documentHash]);
        documents[documentHash] = _signedData;
        signatures[msg.sender][documentHash] = true;
        signedTimestamps[msg.sender][documentHash] = uint64(block.timestamp);
        emit DocumentSignedHash(msg.sender, documentHash);
    }

    function legalDocumentOffChain(bytes32 documentHash) external view returns (string memory) {
        return string(documents[documentHash]);
    }

    function documentSignedOffChain(address user, bytes32 documentHash) external view returns (bool signed) {
        return signatures[user][documentHash];
    }

    function documentSignedAtOffChain(address user, bytes32 documentHash) external view returns (uint64 timestamp) {
        return signedTimestamps[user][documentHash];
    }

    
}
// File: contracts/ERC5554.sol



pragma solidity ^0.8.11;

// import " https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5554.md";
// import "https://github.com/ethereum/EIPs/blob/master/assets/eip-5218/contracts/src/IERC5218.sol";

interface IERC5554  {
    event CommercialExploitation(uint256 _tokenId, uint256 _licenseId, string _externalUri);
    event ReproductionCreated(uint256 _tokenId, uint256 _licenseId, uint256 _reproductionId, address _reproduction, uint256 _reproductionTokenId);
    event DerivativeCreated(uint256 _tokenId, uint256 _licenseId, uint256 _derivativeId, address _derivative, uint256 _derivativeTokenId);
    event LicenseSet(uint indexed _tokenId, uint indexed _licenseId);

    function getCopyrightOwner(uint256 tokenId) external returns (address);
    function logReproduction(uint256 tokenId, address reproduction, uint256 reproductionTokenId) external  returns (uint256);
    function logDerivative(uint256 tokenId, address derivative, uint256 derivativeTokenId) external  returns (uint256);
    function logCommercialExploitation(uint256 tokenId, string calldata uri) external;
    function getReproduction(uint256 _reproductionId) external view returns (uint256, uint256, address);
    function getDerivative(uint256 _derivativeId) external view returns (uint256, uint256, address);
    function getLicense(uint256 _tokenId) external view returns (uint256);
    function setLicense(uint256 _tokenId, uint256 _licenseId) external;

}

contract EIP5554 {
    function isValidAddress(address _address) public pure returns (bool) {
        bytes memory addressBytes = abi.encodePacked(_address);
        // Check if the address is 20 bytes
        require(addressBytes.length == 20);
        // Check the address against the EIP-5554 check sum
        bytes32 checkSum = bytes32(keccak256(abi.encodePacked(addressBytes)));
        for (uint i = 0; i < addressBytes.length; i++) {
            if (i >= 2 && i <= 19) {
                // Check if the 4th byte of the check sum is uppercase
                if (uint8(checkSum[i >> 1]) > 87) {
                    if (uint(uint8(addressBytes[i])) < 97 || uint(uint8(addressBytes[i])) > 122) {
                        return false;
                    }
                } else {
                    if (uint(uint8(addressBytes[i])) < 65 || uint(uint8(addressBytes[i])) > 90) {
                        return false;
                    }
                }
            } else {
                // Check if the first 2 bytes and last byte are lowercase
                if (uint(uint8(addressBytes[i])) < 97 || uint(uint8(addressBytes[i])) > 122) {
                    return false;
                }
            }
        }
        return true;
    }
}

contract ERC5554 is IERC5554 {
    // Mapping of tokenId to copyright owner address
    mapping(uint256 => address) private tokenOwners;
    // Mapping of tokenId to licenseId
    mapping(uint256 => uint256) private tokenLicenses;
    // Mapping of licenseId to the number of reproductions generated
    mapping(uint256 => uint256) private licenseReproductionCount;
    // Mapping of licenseId to the number of derivatives generated
    mapping(uint256 => uint256) private licenseDerivativeCount;
    // Mapping of reproductionId to the tokenId used to generate the reproduction
    mapping(uint256 => uint256) private reproductionTokenIds;
    // Mapping of reproductionId to the licenseId used to generate the reproduction
    mapping(uint256 => uint256) private reproductionLicenseIds;
    // Mapping of reproductionId to the address of the reproduction collection
    mapping(uint256 => address) private reproductionCollections;
    // Mapping of derivativeId to the tokenId used to generate the derivative
    mapping(uint256 => uint256) private derivativeTokenIds;
    // Mapping of derivativeId to the licenseId used to generate the derivative
    mapping(uint256 => uint256) private derivativeLicenseIds;
    mapping (uint256 => address) public derivativeCollections;
    uint256 public nextReproductionId = 0;
    uint256 public nextDerivativeId = 0;


    function getCopyrightOwner(uint256 tokenId) external virtual returns (address) {
        return tokenOwners[tokenId];
    }

    function logReproduction(uint256 tokenId, address reproduction, uint256 reproductionTokenId) external virtual returns (uint256) {
        require(tokenOwners[tokenId] != address(0), "Token does not exist");
        reproductionTokenIds[nextReproductionId] = reproductionTokenId;
        reproductionLicenseIds[nextReproductionId] = tokenId;
        reproductionCollections[nextReproductionId] = reproduction;
        emit ReproductionCreated(tokenId, tokenId, nextReproductionId, reproduction, reproductionTokenId);
        return nextReproductionId++;
    }

    function logDerivative(uint256 _tokenId, address _derivative, uint256 _derivativeTokenId) external returns (uint256) {
        require(tokenOwners[_tokenId] == msg.sender, "Only the owner of the original token can log a derivative");
        uint256 derivativeId = licenseDerivativeCount[tokenLicenses[_tokenId]]++;
        derivativeTokenIds[derivativeId] = _tokenId;
        derivativeLicenseIds[derivativeId] = tokenLicenses[_tokenId];
        derivativeCollections[derivativeId] = _derivative;
        emit DerivativeCreated(_tokenId, tokenLicenses[_tokenId], derivativeId, _derivative, _derivativeTokenId);
        return derivativeId;
    }
    function logCommercialExploitation(uint256 _tokenId, string calldata _uri) external {
        require(tokenOwners[_tokenId] == msg.sender, "Only the owner of the original token can log commercial exploitation");
        emit CommercialExploitation(_tokenId, tokenLicenses[_tokenId], _uri);
    }

    function getReproduction(uint256 _reproductionId) external view returns (uint256, uint256, address) {
        return (reproductionTokenIds[_reproductionId], reproductionLicenseIds[_reproductionId], reproductionCollections[_reproductionId]);
    }

    function getDerivative(uint256 _derivativeId) external view returns (uint256, uint256, address) {
        return (derivativeTokenIds[_derivativeId], derivativeLicenseIds[_derivativeId], derivativeCollections[_derivativeId]);
    }

    function getLicense(uint256 _tokenId) external view returns (uint256) {
        return tokenLicenses[_tokenId];
    }

    function setLicense(uint256 _tokenId, uint256 _licenseId) external {
        require(tokenOwners[_tokenId] == msg.sender, "Only the owner of the original token can set the license");
        tokenLicenses[_tokenId] = _licenseId;
        emit LicenseSet(_tokenId, _licenseId);
    }
}
// File: contracts/EIP5453.sol



// EIP 5453 - Endorsment 
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5453.md

pragma solidity ^0.8.11;

// import "https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5453.md";

contract EIP5453 {
    struct ValidityBound {
        bytes32 functionParamStructHash;
        uint256 validSince;
        uint256 validBy;
        uint256 nonce;
    }

    struct SingleEndorsementData {
        address endorserAddress;
        bytes sig;
    }

    struct GeneralExtensionDataStruct {
        bytes32 erc5453MagicWord;
        uint256 erc5453Type;
        uint256 nonce;
        uint256 validSince;
        uint256 validBy;
        bytes endorsementPayload;
    }

    address public owner;

    constructor()  {
        owner = msg.sender;
    }

    function eip5453Nonce(address endorser) public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(endorser, msg.sender)));
    }
    // Validates the Endroser
    function isEligibleEndorser(address endorser) public view returns (bool) {
        return endorser == owner;
    }

    // Validation Information 
    function computeValidityDigest(
        bytes32 _functionParamStructHash,
        uint256 _validSince,
        uint256 _validBy,
        uint256 _nonce
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_functionParamStructHash, _validSince, _validBy, _nonce));
    }

    function computeFunctionParamHash(
        string memory _functionName,
        bytes memory _functionParamPacked
    ) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_functionName, _functionParamPacked));
    }

    function computeExtensionDataTypeA(
        uint256 nonce,
        uint256 validSince,
        uint256 validBy,
        address endorserAddress,
        bytes calldata sig
    ) public pure returns (bytes memory) {
        return abi.encode(
            bytes32(uint256(0x3f3f3f3f)),
            uint256(1),
            nonce,
            validSince,
            validBy,
            abi.encodePacked(endorserAddress, sig)
        );
    }

    function computeExtensionDataTypeB(
        uint256 nonce,
        uint256 validSince,
        uint256 validBy,
        address[] calldata endorserAddress,
        bytes[] calldata sigs
    ) public pure returns (bytes memory) {

        bytes memory encoded;
        uint len = sigs.length;
        for (uint i = 0; i < len; i++) {
            encoded = bytes.concat(
                encoded,
                abi.encodePacked(endorserAddress[i],sigs[i])
            );
        }

        return abi.encode(
            bytes32(uint256(0x3f3f3f3f)),
            uint256(2),
            nonce,
            validSince,
            validBy,
            encoded
        );

           
    }
}
// File: contracts/IPNFT.sol



pragma solidity ^0.8.11;




// import "https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5554.md";
// import "https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5289.md";
// import "https://github.com/ethereum/EIPs/blob/master/EIPS/eip-5453.md";



interface IERC5289Library is IERC165 {
    event DocumentSigned(address indexed signer, uint16 indexed documentId);
    function legalDocument(uint16 documentId) external view returns (string memory);
    function documentSigned(address user, uint16 documentId) external view returns (bool signed);
    function documentSignedAt(address user, uint16 documentId) external view returns (uint64 timestamp);
    function signDocument(address signer, uint16 documentId) external;
}

interface EndorsedDocs {

    function offChainSignature(bytes memory _signedData) external;
    function transferFrom(address _from, address _to, bytes32 _documentHash) external;
    function approve(address _to, bytes32 _documentHash) external;
    function signDocument(address _to, bytes32 _documentHash) external;
    function mint(address _to, bytes32 _documentHash, string memory _name, string memory _imageLink, string memory _uri, string memory _description) external;
    function addSigner(address _signer) external;
    function removeSigner(address _signer) external;
}

contract IntellectualPropertyNFT is EndorsedDocs, SilentSigner, ERC5554, EIP5453, ERC5289Library {
    mapping(address => mapping(bytes32 => bool)) private _documentSignature;
    mapping (address => mapping (bytes32 => bool)) public signatures;
    mapping(address => mapping(uint => bool)) private _signatureRequirement;
    mapping(address => mapping(bytes32 => bool)) private _balanceOf;
    mapping(bytes32 => address) private _ownerOf;
    mapping (bytes32 => bytes) public documents;
    mapping(address => mapping(address => mapping(bytes32 => bool))) private _approvals;
    address[] private _signers;
    uint public count;

    struct Metadata {
    string name;
    string imageLink;
    string uri;
    string description;
}
    mapping(uint256=>Metadata) public ipMetadata;
    event Transfer(address indexed _to, address indexed _zero, bytes32 indexed _documentHash);
    event Approval(address indexed _sender, address indexed _to, bytes32 indexed _documentHash);

    function signDocument(address _to, bytes32 _documentHash) public {
        require(_signers.length > 0);
        // require(_signers[msg.sender]);
        _documentSignature[_to][_documentHash] = true;
    }

    function mint(address _to, bytes32 _documentHash, string memory _name, string memory _imageLink, string memory _uri, string memory _description) public {
        // require(_documentSignature[_to][_documentHash]);
        _documentSignature[_to][_documentHash] = true;
        _balanceOf[_to][_documentHash] = true;
        _ownerOf[_documentHash] = _to;
        Metadata memory _metadata = Metadata(_name, _imageLink, _uri, _description);
        ipMetadata[count] = _metadata;
        count = count + 1;
        emit Transfer(_to, address(0), _documentHash);
    }

    // Approving ERC-5554 NFTs
    function approve(address _to, bytes32 _documentHash) external {
        require(_balanceOf[msg.sender][_documentHash]);
        _approvals[msg.sender][_to][_documentHash] = true;
        emit Approval(msg.sender, _to, _documentHash);
    }

    // Transferring ERC-5554 NFTs
    function transferFrom(address _from, address _to, bytes32 _documentHash) public {
        require(_balanceOf[_from][_documentHash]);
        require(_approvals[_from][msg.sender][_documentHash]);
        _balanceOf[_from][_documentHash] = false;
        _balanceOf[_to][_documentHash] = true;
        _ownerOf[_documentHash] = _to;
        emit Transfer(_from, _to, _documentHash);
    }

    function tokenURI(uint256 _id) public view returns (string memory) {
        Metadata memory metadata = ipMetadata[_id];
        string memory detail = string(
            abi.encodePacked(
                '{"name":"',
                metadata.name,
                '","imageLink":"',
                metadata.imageLink,
                '","uri":"',
                metadata.uri,
                '","description":"',
                metadata.description,
                '"}'
            )
        );
        return detail;
    }

    // Adding signers for ERC-5554 NFTs
    function addSigner(address _signer) public {
        require(msg.sender == owner);
        _signers.push(_signer);
    }

    // Removing signers for ERC-5554 NFTs
    function removeSigner(address _signer) public {
        require(msg.sender == owner);
        for (uint256 i = 0; i < _signers.length; i++) {
            if (_signers[i] == _signer) {
                delete _signers[i];
                break;
            }
        }
    }


    // Requiring signature for ERC-5554 NFTs
    function requireSignature(address _signer, uint256 _nftId) public {
        require(msg.sender == owner);
        _signatureRequirement[_signer][_nftId] = true;
    }

    function offChainSignature(bytes memory _signedData) public {
        bytes32 documentHash = keccak256(abi.encodePacked(_signedData));
        require(!signatures[msg.sender][documentHash]);
        documents[documentHash] = _signedData;
        signatures[msg.sender][documentHash] = true;
        emit DocumentSigned(msg.sender, uint16(uint(documentHash)));
    }
}