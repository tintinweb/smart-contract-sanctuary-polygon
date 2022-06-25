/**
 *Submitted for verification at polygonscan.com on 2022-06-24
*/

contract Event {
  // is Ownable, AccessControl
  uint256 certCreate;
  struct Certificate {
    string name;
    string organization;
    string url;
    address assignedTo;
    bool approved;
  }
  mapping(address => Certificate[]) public holdersCertificate;
  mapping(address => uint16) public holdersCertificateCount;

  address contractOwnerAddress; //make private later

  function initialize(address _contractOwnerAddress) public {
    require(contractOwnerAddress == address(0), "already initialized");
    contractOwnerAddress = _contractOwnerAddress;
    certCreate = 100;
  }

  function addMoreCertificates(uint256 number) public {
    require(contractOwnerAddress != address(0));
    // require(msg.sender != address(0)); //ask y abhay put this
    require(contractOwnerAddress == msg.sender);
    certCreate = certCreate + number;
  }

  //in future make child contract capable of adding its entry in parent contract
  function assignCertificate(
    string memory name,
    string memory organization,
    string memory url,
    address assignTo
  ) public {
    require(contractOwnerAddress != address(0));
    // require(msg.sender != address(0)); //ask abhay y he put this
    require(contractOwnerAddress == msg.sender);
    require(certCreate > 0); //just in case 2 prevent underflow attacks (not a problem in this vertion of solidity)
    //let us leave the checks off chain🔗
    // require(bytes(_name).length > 0);
    // require(bytes(_url).length > 0);
    //require(checkURL(_url));
    certCreate--;
    holdersCertificateCount[assignTo] = holdersCertificateCount[assignTo] + 1;

    holdersCertificate[assignTo].push(
      Certificate(name, organization, url, assignTo, true)
    );
    // holderCertificateCount[msg.sender] = holderCertificateCount[msg.sender] + 1;
  }

  function approveCertificate(
    uint256 id,
    address owner,
    bool status
  ) public {
    require(contractOwnerAddress != address(0));
    require(contractOwnerAddress == msg.sender);

    holdersCertificate[owner][id].approved = status;
  }
}