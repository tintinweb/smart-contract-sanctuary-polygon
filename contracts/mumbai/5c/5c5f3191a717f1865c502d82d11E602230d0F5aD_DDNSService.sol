/**
 *Submitted for verification at polygonscan.com on 2022-12-06
*/

// File: libs/SafeMath.sol

pragma solidity >=0.4.24 <0.6.0;


library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
        require(b > 0);
        uint256 c = a / b;
        
        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}
// File: common/Ownable.sol

pragma solidity >=0.4.24 <0.6.0;

 //The Ownable contract has an owner address, and provides basic authorization control
 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    //The Ownable constructor sets the original `owner` of the contract to the sender account.

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }


    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

 
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: DDNSService.sol

pragma solidity >=0.4.22 <0.6.0;




contract DDNSService is Ownable {
  //USINGS
  using SafeMath for uint256;

  //STRUCTS
  struct DomainDetails {
    string name;
    string topLevel;
    address owner;
    string ip;
    uint256 expires;
  }

  struct Receipt {
    uint256 amountPaidWei;
    uint256 timestamp;
    uint256 expires;
  }

  //CONSTANTS
  uint256 public constant DOMAIN_NAME_COST = 0.000000000000000001 ether;
  uint256 public constant DOMAIN_NAME_COST_SHORT_ADDITION = 0.00000000000000001 ether;
  uint256 public constant DOMAIN_EXPIRATION_DATE = 365 days;
  uint8 public constant DOMAIN_NAME_MIN_LENGTH = 5;
  uint8 public constant DOMAIN_NAME_EXPENSIVE_LENGTH = 8;
  uint8 public constant TOP_LEVEL_DOMAIN_MIN_LENGTH = 1;
  bytes1 public constant BYTES_DEFAULT_VALUE = bytes1(0x00);

  //STATE VARIABLES
  mapping(bytes32 => DomainDetails) public domainNames;
  mapping(address => bytes32[]) public paymentReceipts;
  mapping(bytes32 => Receipt) public receiptDetails;

  //MODIFIERS
  modifier isAvailable(string memory domain, string topLevel) {
    bytes32 domainHash = getDomainHash(domain, topLevel);
    require(
      domainNames[domainHash].expires < block.timestamp,
      'Domain name is not available.'
    );
    _;
  }

  modifier collectDomainNamePayment(string memory domain) {
    uint256 domainPrice = getPrice(domain);
    require(msg.value >= domainPrice, 'Insufficient amount.');
    _;
  }

  modifier isDomainOwner(string memory domain, string topLevel) {
    bytes32 domainHash = getDomainHash(domain, topLevel);
    require(
      domainNames[domainHash].owner == msg.sender,
      'You are not the owner of this domain.'
    );
    _;
  }

  modifier isDomainNameLengthAllowed(string memory domain) {
    require(
      bytes(domain).length >= DOMAIN_NAME_MIN_LENGTH,
      'Domain name is too short.'
    );
    _;
  }

  modifier isTopLevelLengthAllowed(string topLevel) {
    require(
      bytes(topLevel).length >= TOP_LEVEL_DOMAIN_MIN_LENGTH,
      'The provided TLD is too short.'
    );
    _;
  }

  //EVENTS
  event LogDomainNameRegistered(
    uint256 indexed timestamp,
    string domainName,
    string topLevel
  );

  event LogDomainNameRenewed(
    uint256 indexed timestamp,
    string domainName,
    string topLevel,
    address indexed owner
  );

  event LogDomainNameEdited(
    uint256 indexed timestamp,
    string domainName,
    string topLevel,
    string newIp
  );

  event LogDomainNameTransferred(
    uint256 indexed timestamp,
    string domainName,
    string topLevel,
    address indexed owner,
    address newOwner
  );

  event LogPurchaseChangeReturned(
    uint256 indexed timestamp,
    address indexed _owner,
    uint256 amount
  );

  event LogReceipt(
    uint256 indexed timestamp,
    string domainName,
    uint256 amountInWei,
    uint256 expires
  );

  //Constructor of the contract
  
  constructor() public {}

  //function to register domain name
  function register(
    string memory domain, //domain name to be registered
    string topLevel, //domain top level (TLD)
    string ip //the ip of the host
  )
    public
    payable
    isDomainNameLengthAllowed(domain)
    isTopLevelLengthAllowed(topLevel)
    isAvailable(domain, topLevel)
    collectDomainNamePayment(domain)
  {
    // calculate the domain hash
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // create a new domain entry with the provided fn parameters
    DomainDetails memory newDomain = DomainDetails({
      name: domain,
      topLevel: topLevel,
      owner: msg.sender,
      ip: ip,
      expires: block.timestamp + DOMAIN_EXPIRATION_DATE
    });

    // save the domain to the storage
    domainNames[domainHash] = newDomain;

    // create an receipt entry for this domain purchase
    Receipt memory newReceipt = Receipt({
      amountPaidWei: DOMAIN_NAME_COST,
      timestamp: block.timestamp,
      expires: block.timestamp + DOMAIN_EXPIRATION_DATE
    });

    // calculate the receipt hash/key
    bytes32 receiptKey = getReceiptKey(domain, topLevel);

    // save the receipt key for this `msg.sender` in storage
    paymentReceipts[msg.sender].push(receiptKey);

    // save the receipt entry/details in storage
    receiptDetails[receiptKey] = newReceipt;

    // log receipt 
    emit LogReceipt(
      block.timestamp,
      domain,
      DOMAIN_NAME_COST,
      block.timestamp + DOMAIN_EXPIRATION_DATE
    );

    // log domain name registered
    emit LogDomainNameRegistered(block.timestamp, domain, topLevel);
  }

  //function to extend domain expiration date
  function renewDomainName(string memory domain, string topLevel)
    public
    payable
    isDomainOwner(domain, topLevel)
    collectDomainNamePayment(domain)
  {
    // calculate the domain hash
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // add 365 days (1 year) to the domain expiration date
    domainNames[domainHash].expires += 365 days;

    // create a receipt entity
    Receipt memory newReceipt = Receipt({
      amountPaidWei: DOMAIN_NAME_COST,
      timestamp: block.timestamp,
      expires: block.timestamp + DOMAIN_EXPIRATION_DATE
    });

    // calculate the receipt key for this domain
    bytes32 receiptKey = getReceiptKey(domain, topLevel);

    // save the receipt id for this msg.sender
    paymentReceipts[msg.sender].push(receiptKey);

    // store the receipt details in storage
    receiptDetails[receiptKey] = newReceipt;

    // log domain name Renewed
    emit LogDomainNameRenewed(block.timestamp, domain, topLevel, msg.sender);

    // log receipt
    emit LogReceipt(
      block.timestamp,
      domain,
      DOMAIN_NAME_COST,
      block.timestamp + DOMAIN_EXPIRATION_DATE
    );
  }

  //function to edit domain name
  function edit(
    string memory domain,
    string topLevel,
    string newIp // new ip of the domain
  ) public isDomainOwner(domain, topLevel) {
    // calculate the domain hash - unique id
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // update the new ip
    domainNames[domainHash].ip = newIp;

    // log change
    emit LogDomainNameEdited(block.timestamp, domain, topLevel, newIp);
  }

  //Transfer domain ownership
  function transferDomain(
    string memory domain,
    string topLevel,
    address newOwner //address of the new owner
  ) public isDomainOwner(domain, topLevel) {
    // prevent assigning domain ownership to the 0x0 address
    require(newOwner != address(0));

    // calculate the hash of the current domain
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // assign the new owner of the domain
    domainNames[domainHash].owner = newOwner;

    // log the transfer of ownership
    emit LogDomainNameTransferred(
      block.timestamp,
      domain,
      topLevel,
      msg.sender,
      newOwner
    );
  }

  //Get ip of domain
  function getIP(string memory domain, string topLevel)
    public
    view
    returns (string)
  {
    // calculate the hash of the domain
    bytes32 domainHash = getDomainHash(domain, topLevel);

    // return the ip property of the domain from storage
    return domainNames[domainHash].ip;
  }

  //Get price of domain
  function getPrice(string memory domain) public pure returns (uint256) {
    
    if (bytes(domain).length < DOMAIN_NAME_EXPENSIVE_LENGTH) {
      
      return DOMAIN_NAME_COST + DOMAIN_NAME_COST_SHORT_ADDITION;
    }

    
    return DOMAIN_NAME_COST;
  }

  //Get receipt list for the msg.sender
  function getReceiptList() public view returns (bytes32[] memory) {
    return paymentReceipts[msg.sender];
  }

  //Get single receipt
  function getReceipt(bytes32 receiptKey)
    public
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    return (
      receiptDetails[receiptKey].amountPaidWei,
      receiptDetails[receiptKey].timestamp,
      receiptDetails[receiptKey].expires
    );
  }

  //Get (domain name + top level) hash used for unique identifier
  function getDomainHash(string memory domain, string topLevel)
    public
    pure
    returns (bytes32)
  {
    //tightly pack parameters in struct for keccak256
    return keccak256(abi.encodePacked(domain, topLevel));
  }

  //Get recepit key hash - unique identifier
  function getReceiptKey(string memory domain, string topLevel)
    public
    view
    returns (bytes32)
  {
    //tightly pack parameters in struct for keccak256
    return
      keccak256(
        abi.encodePacked(domain, topLevel, msg.sender, block.timestamp)
      );
  }

  //Withdraw function
  function withdraw() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }
}