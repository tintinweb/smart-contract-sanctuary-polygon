// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


import "./interfaces/Roles.sol";
import "./interfaces/ISMRCertificate.sol";
import "./interfaces/ISMRService.sol";

contract SMRService is ISMRService {
  using Roles for Roles.Role;
  address private _owner;

  struct CertificateContract {
    address ref;
    string category;
    uint256 registrationDate;
    bool active;
  }

  event ContractRegistration(address indexed ref, string category);
  event ContractRemoving(address indexed ref);    
  event ContractActivation(address indexed ref, bool active);

  // roles  
  Roles.Role private _primaryAgencies;
  Roles.Role private _agencies;

  // mapping for all certificates collections
  mapping (address => CertificateContract) certificates;
  mapping (bytes32 => bool) categories;
  address[] addresses;


  modifier onlyOwner() {
    require(owner() == msg.sender, "caller is not the owner");
    _;
  }

  modifier isOwnerOrPrimaryAgency() {
    require(owner() == msg.sender || _primaryAgencies.has(msg.sender), "you are not authorized");
    _;
  }  

  modifier isPrimaryAgency() {
    require(_primaryAgencies.has(msg.sender), "you are not authorized");
    _;
  }  

  modifier isPrimaryOrJustAgency() {
    require(_primaryAgencies.has(msg.sender) || _agencies.has(msg.sender), "you are not authorized");
    _;
  }

  constructor() {
    _owner = msg.sender;
  }

  /**
   * @notice Registration a new contract that represents some certificate type. Second parameter indicates if contract is ready for usage or not
   */
  function addCertificateContract(address contractAddress, bool activate) external onlyOwner {
    require(contractAddress != address(0), "contract address is zero address");
    require(certificates[contractAddress].ref == address(0), "contract is already registered");

    ISMRCertificate cert = ISMRCertificate(contractAddress);
    string memory _category = cert.category();
    bytes32 _hashCategory = keccak256(abi.encodePacked(_category));
    require(!categories[_hashCategory], "contract refers to category that is already registered");

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

  /**
   * @notice Removing a contract that represents some certificate type.
   */
  function removeCertificateContract(address contractAddress) external onlyOwner {
    require(contractAddress != address(0), "contract address is zero address");
    require(certificates[contractAddress].ref != address(0), "contract is not  registered");
    bytes32 _hashCategory = keccak256(abi.encodePacked(certificates[contractAddress].category));

    uint index = addresses.length-1;
    // if found, then index >0 else 1st element is a target
    for (uint i=0; i<addresses.length-1; i++){
        if (addresses[i] == contractAddress) {
            index = i;
            break;
        }
    }

    for (uint i=index; i<addresses.length-1; i++){
        addresses[i] = addresses[i+1];
    }
    addresses.pop();

    delete categories[_hashCategory];
    delete certificates[contractAddress];

    emit ContractRemoving(contractAddress);
  }    

  /**
   * @notice Activation of already registered contract that represents some certificate type.
   */
  function activateCertificateContract(address contractAddress) external onlyOwner {
    require(contractAddress != address(0), "contract address is zero address");
    require(certificates[contractAddress].ref != address(0), "contract is not registered");
    require(!certificates[contractAddress].active, "contract is already active");
        // activate
    certificates[contractAddress].active = true; 
        // emit event
    emit ContractActivation(contractAddress, true);
  }
  /**
   * @notice Deactivation of already registered contract that represents some certificate type.
   */
  function deactivateCertificateContract(address contractAddress) external onlyOwner {
    require(contractAddress != address(0), "contract address is zero address");
    require(certificates[contractAddress].ref != address(0), "contract is not registered");
    require(certificates[contractAddress].active, "contract is already deactivated");
    // deactivate
    certificates[contractAddress].active = false; 
    // emit event
    emit ContractActivation(contractAddress, false);
  }
  /**
   * @notice Registration and assignment of a new certificate of the specified contract. Certificate becomes "accepted" by the receiver
   * @param contractAddress contract address  that represents some certificate type.
   * @param to - address of the receiver.
   * @param uri - certificate metadata url
   * @param signature - signature generated by the issuer
   * @param imprint - imprint of the metadata referenced by uri            
   */
  function assignCertificate(address contractAddress, address to, string calldata uri, bytes calldata signature, bytes32 imprint) override external isPrimaryAgency {
    require(contractAddress != address(0), "contract address is zero address");
    require(certificates[contractAddress].ref != address(0), "contract is not registered");
    require(certificates[contractAddress].active, "contract is not active");
    ISMRCertificate cert = ISMRCertificate(contractAddress);
    cert.assign(to, uri, signature, imprint);
  }
  /**
   * @notice Registration of a new certificate of the specified contract. Certificate becomes "ready" for the acceptance by the receiver
   * @param contractAddress contract address  that represents some certificate type.
   * @param to - address of the receiver.
   * @param uri - certificate metadata url
   * @param signature - signature generated by the issuer
   * @param imprint - imprint of the metadata referenced by uri         
   */
  function issueCertificate(address contractAddress, address to, string calldata uri, bytes calldata signature, bytes32 imprint) override external isPrimaryOrJustAgency  {
    require(contractAddress != address(0), "contract address is zero address");
    require(certificates[contractAddress].ref != address(0), "contract is not registered");
    require(certificates[contractAddress].active, "contract is not active");
    ISMRCertificate cert = ISMRCertificate(contractAddress);
    cert.give(to, uri, signature, imprint);
  }
  /**
   * @notice Revoke of the certificate of the specified contract. Applicable only if certificate hasn't been accepted yet.
   * It is extra method, because issuer can "revoke" the previously issued certificate from the direct contract as well. 
   * @param contractAddress contract address  that represents some certificate type.
   * @param tokenId - certificate id
   */
  function revokeCertificate(address contractAddress, uint256 tokenId) override external isPrimaryOrJustAgency {
    require(contractAddress != address(0), "contract address is zero address");
    require(certificates[contractAddress].ref != address(0), "contract is not registered");
    require(certificates[contractAddress].active, "contract is not active");
    ISMRCertificate cert = ISMRCertificate(contractAddress);
    cert.revoke(tokenId);
  }    
  /**
   * @notice Return contract details like address, category, version, registration date in the system.
   */
  function contractDetails(address contractAddress) view  external returns (CertificateContract memory) {
    require(certificates[contractAddress].ref!=address(0), "no contract found");
    return certificates[contractAddress];
  }
  /**
   * @notice Array of contract addresses irrespective of their statuses
   */
  function getContractAddresses() external view returns (address[] memory) {
    return addresses;
  }
  /**
   * @notice Return totoal number of registered contracts irrespective of their active statuses
   */
  function totalSupply() external view returns (uint256) {
    return addresses.length;
  }
  /**
   * @notice Add primary agency address. Primary agency is able to assign and issue certificates. Also, primary agency is able to register common agencies
   */
  function addPrimaryAgency(address _address) external onlyOwner {
    _primaryAgencies.safetyAdd(_address);
  }
  /**
   * @notice Remove primary agency address. Primary agency is able to assign and issue certificates. Also, primary agency is able to register common agencies
   */
  function removePrimaryAgency(address _address) external onlyOwner {
    _primaryAgencies.safetyRemove(_address);
  }
  /**
   * @notice Check if address belongs to "primary agency" group. Primary agency is able to assign and issue certificates. Also, primary agency is able to register common agencies
   */
  function checkPrimaryAgency(address _address) public view returns (bool)  {
    return _primaryAgencies.has(_address);
  }
  /**
   * @notice Add agency address. Agency is able to issue certificates.
   */
  function addAgency(address _address) external isOwnerOrPrimaryAgency {
    _agencies.safetyAdd(_address);
  }
  /**
   * @notice Remove agency address. Agency is able to issue certificates.
   */
  function removeAgency(address _address) external isOwnerOrPrimaryAgency {
    _agencies.safetyRemove(_address);
  }
  /**
   * @notice Check if address belongs to "agency" group. Agency is able to issue certificates.
   */
  function checkAgency(address _address) public view returns (bool)  {
    return _agencies.has(_address);
  }	  	         

  function owner() public view returns (address) {
        return _owner;
  }
  /**
   * @notice Assign a new owner
   */
  function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0), "new owner is the zero address");
        _owner = newOwner;
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


library Roles {
  struct Role {
    mapping (address => bool) members;
  }

  function safetyAdd(Role storage role, address entity) internal {
    require(entity != address(0), "invalid address");
    require(!role.members[entity], "role already given");

    role.members[entity] = true;
  }

  function add(Role storage role, address entity) internal {
    require(entity != address(0), "invalid address");
    role.members[entity] = true;
  }  

  function safetyRemove(Role storage role, address entity) internal {
    require(entity != address(0), "invalid address");
    require(role.members[entity], "role is not given");
    role.members[entity] = false;
  }

  function remove(Role storage role, address entity) internal {
    require(entity != address(0), "invalid address");
    role.members[entity] = false;
  }


  function has(Role storage role, address entity) internal view returns (bool) {
    require(entity != address(0), "invalid address");
    return role.members[entity];
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;


interface ISMRService {

    function issueCertificate(address contractAddress, address to, string calldata uri, bytes calldata signature, bytes32 imprint) external;

    function assignCertificate(address contractAddress, address to, string calldata uri, bytes calldata signature, bytes32 imprint) external;

    function revokeCertificate(address contractAddress, uint256 tokenId) external;

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
        // signature
        bytes signature;
        // imprint of the data referenced by uri
        bytes32 imprint;
    }

    // certificate is issued
    event Issue(address indexed from, address indexed to, uint256 indexed tokenId);
    // certificate is accepted , nft is minted
    event Attest(address indexed to, uint256 indexed tokenId);
    // certificate is revoked by the issuer. nft has not been minted yet
    event Revoke(address indexed from, uint256 indexed tokenId);
    // certificate is remove, nft removed as well
    event Remove(address indexed from, uint256 indexed tokenId);

    function revoke(uint256 tokenId) external;

    function give(address to, string calldata uri, bytes calldata signature, bytes32 imprint) external returns (uint256);

    function assign(address to, string calldata uri, bytes calldata signature, bytes32 imprint) external returns (uint256);

    function take(uint256 tokenId) external;

    function unequip(uint256 tokenId) external;

    function totalSupply() external view returns (uint256); 

    function totalPending() external view returns (uint256);    

    // submitted certficate details    
    function details(uint256 tokenId) external view returns (Cert memory); 

    // global certification , namespace like Training Platform, Education , Courses, Personal identification, 
    function category() external view returns (string memory);
    
}