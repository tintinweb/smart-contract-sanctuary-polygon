// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "../node_modules/@openzeppelin/contracts/utils/Counters.sol";
import "./ISMRCertificate.sol";

contract SMRService {
    address private _owner;

    struct CertificateContract {
        address ref;
        string category;
        uint256 registrationDate;
        bool active;
    
    }

    event ContractRegistration(address indexed ref, string category);
    event ContractActivation(address indexed ref, bool active);

   // mapping for all certificates collections
    mapping (address => CertificateContract) certificates;
    mapping (bytes32 => bool) categories;
    address[] addresses;



    // key - address, value - true/false. Admin can update the data. It is used for authorized list
    mapping(address => bool) private authorizedList;    


    modifier onlyOwner() {
       require(owner() == msg.sender, "caller is not the owner");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedList[msg.sender], "you are not authorized");
        _;
    }

    constructor(){
        _owner = msg.sender;
    }

    function addCertificateContract(address contractAddress, bool activate) external onlyOwner {

        require(contractAddress != address(0), "contract address is zero address");
        ISMRCertificate cert = ISMRCertificate(contractAddress);

        string memory _category = cert.category();
        bytes32 _hashCategory = keccak256(abi.encodePacked(_category));
        require(!categories[_hashCategory], "contract refers to category that is already registered");

        require(certificates[contractAddress].ref == address(0), "contract is already registered");
        CertificateContract memory certContract = CertificateContract({
            ref : contractAddress,
            category : _category,
            registrationDate : block.timestamp,
            active : activate
        }); 

        categories[_hashCategory] = true;
        certificates[contractAddress] = certContract;
        addresses.push(contractAddress);

        emit ContractRegistration(contractAddress, _category);
        emit ContractActivation(contractAddress, activate);
    }


    function activateCertificateContract(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "contract address is zero address");
        require(certificates[contractAddress].ref != address(0), "contract is not registered");
        require(!certificates[contractAddress].active, "contract is already active");
        // activate
        certificates[contractAddress].active = true; 
        // emit event
        emit ContractActivation(contractAddress, true);
    }

    function deActivateCertificateContract(address contractAddress) external onlyOwner {
        require(contractAddress != address(0), "contract address is zero address");
        require(certificates[contractAddress].ref != address(0), "contract is not registered");
        require(certificates[contractAddress].active, "contract is already deactivated");
        // deactivate
        certificates[contractAddress].active = false; 
        // emit event
        emit ContractActivation(contractAddress, false);
    }

    function issueCertificate(address contractAddress, address to, string calldata uri, string calldata imprint, string calldata signature) external onlyAuthorized  {
        require(contractAddress != address(0), "contract address is zero address");
        require(certificates[contractAddress].ref != address(0), "contract is not registered");
        require(certificates[contractAddress].active, "contract is not active");
        ISMRCertificate cert = ISMRCertificate(contractAddress);
        cert.issue(to, uri, imprint, bytes(signature));
    }

    function attestCertificate(address contractAddress, address to, string calldata uri, string calldata imprint, string calldata signature) external onlyAuthorized {
        require(contractAddress != address(0), "contract address is zero address");
        require(certificates[contractAddress].ref != address(0), "contract is not registered");
        require(certificates[contractAddress].active, "contract is not active");
        ISMRCertificate cert = ISMRCertificate(contractAddress);
        cert.attest(to, uri, imprint, bytes(signature));
    }    


    function totalSupply() external view returns (uint256) {
        return addresses.length;
    }

    function addToAuthorizedList(address _address) external onlyOwner {
        authorizedList[_address] = true;
    }

    function removeFromAuthorizedList(address _address) external onlyOwner {
        delete authorizedList[_address];
    }

    function checkAddressInAuthorizedList(address _address) public view returns (bool)  {
        return authorizedList[_address];
    }	          

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function setOwner(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _owner = newOwner;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface ISMRCertificate {

    struct Cert {
        uint256 id;
        // who issued
        address issuer;
        // recipient
        address user;
        string uri;
        uint256 issuingDate;
        uint256 acceptanceDate;        
        // data imprint
        string imprint;
        // signature
        bytes signature;
    }

    // certificate is issued
    event Issue(address indexed from, address indexed to, uint256 indexed tokenId);
    // certificate is accepted , nft is minted
    event Attest(address indexed to, uint256 indexed tokenId);
    // certificate is revoked by the issuer. nft has not been minted yet
    event Revoke(address indexed from, uint256 indexed tokenId);
    // certificate is remove, nft removed as well
    event Burn(address indexed from, uint256 indexed tokenId);


    function revoke(uint256 tokenId) external;

    function issue(address to, string calldata uri, string calldata imprint, bytes calldata signature) external returns (uint256);

    function attest(address to, string calldata uri, string calldata imprint, bytes calldata signature) external returns (uint256);

    function take(uint256 tokenId) external;

    function burn(uint256 tokenId) external;

    function totalReserve() external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function status(uint256 tokenId) external view returns (string memory);    

    // global certification , namespace like Training Platform, Education , Courses, Personal identification, 
    function category() external view returns (string memory);
    
    // version of the certificate platform : v0.0.1, v0.1, v1, etc
    function version() external pure returns (string memory);    
}