// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EWLargeWarehouse {
    address public manifacturer;
    address public owner;
    //uint256 public nextId;

        constructor(address _manifacturer) {
        owner = msg.sender;
        manifacturer = _manifacturer;
        numRetailers = 0;
        //nextId = 1;
    }

        modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You are not the owner of this smart contract"
        );
        _;
    }

        modifier onlyManifacturer() {
        require(
            msg.sender == manifacturer,
            "You are not registered manifacturer of this smart contract"
        );
        _;
    }

    struct sneaker {
        uint256 id;
        address sneakerRegisteredBy;
        string modelno;
        string color;
        string size;
        string distributerName;
        string retailerName;
        bool isApproved;
        bool isDelivered;

    }
    mapping(uint256 => sneaker) public Sneakers;
    uint256 public totalSneakers;

    event sneakerFiled(
        uint256 id,
        address sneakerRegisteredBy,
        string modelno,
        string color,
        string size
        
    );

        function setManifactureAddress(address _manifacturer) public onlyOwner {
        manifacturer = _manifacturer;
    }

        function fileSneaker(uint256 _id, string memory _color, string memory _size ) public
    {
        require(Sneakers[_id].id == 0, "Id is already used");
        string memory randomModelNo = getRandomString();
        sneaker storage newSneaker = Sneakers[_id];
        newSneaker.id = _id;
        newSneaker.sneakerRegisteredBy = msg.sender;
        newSneaker.modelno = randomModelNo;
        newSneaker.color = _color;
        newSneaker.size = _size;
        newSneaker.retailerName = "Pending Approval";
        newSneaker.distributerName = "Pending Approval";
        newSneaker.isApproved = false;
        newSneaker.isDelivered = false;

        totalSneakers++;
        emit sneakerFiled(_id, msg.sender, randomModelNo, _color, _size);
        
    }

function getRandomString() internal view returns (string memory) {
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender))) % 100000;
        string memory randomString = uint2str(randomNumber);
        return randomString;
    }

    function uint2str(uint256 _i) internal pure returns (string memory str) {
        if (_i == 0) {
            return "00000";
        }
        uint256 j = _i;
        uint256 length;
        while (j != 0) {
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = uint8(48 + _i % 10);
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
    
    function approveDelivery(uint256 _id, string memory _retailerName)
        public
        onlyManifacturer
    {
        require(
            Sneakers[_id].isApproved == false,
            "Sneaker is already approved"
        );
        Sneakers[_id].isApproved = true;
        Sneakers[_id].retailerName = _retailerName;
    }
    bool private hasShown = false;

    function show() public {
    require(!hasShown, "Already shown");
    require(msg.sender == manifacturer, "Only admin can call this function.");
    hasShown = true;
}
    function viewAllSneakers() public view returns (sneaker[] memory) {
        sneaker[] memory allSneakers = new sneaker[](totalSneakers);
        uint256 counter = 0;
        for (uint256 i = 1; i <= totalSneakers; i++) {
            if (Sneakers[i].id != 0) {
                allSneakers[counter] = Sneakers[i];
                counter++;
            }
        }
        return allSneakers;
    }

        function approveDistribute(uint256 _id, string memory _distributerName)
        public{
            
        Retailer memory retailer = retailers[msg.sender];
        require(Sneakers[_id].isDelivered == false,"Sneaker is already distributed");
        require(retailer.addr == msg.sender, "Only retailers can perform this action");

        Sneakers[_id].isDelivered = true;
        Sneakers[_id].distributerName = _distributerName;
    }
    

    //Retailer
    
      struct Retailer {
        uint256 id;
        string name;
        address addr;
    }

    mapping (address => Retailer) public retailers;
    mapping (uint256 => address) public retailerAddresses;
    uint256 public numRetailers;
    

    function addRetailer(uint256 _id, string memory _name, address _addr) public onlyManifacturer {
        require(_id != 0, "Retailer ID cannot be zero");
        require(_addr != address(0), "Retailer address cannot be zero");
        require(retailerAddresses[_id] == address(0), "Retailer ID already exists");

        Retailer memory newRetailer = Retailer(_id, _name, _addr);
        retailers[_addr] = newRetailer;
        retailerAddresses[_id] = _addr;
        numRetailers++;
    }

    
    function getRetailerById(uint256 _id) public view returns (Retailer memory) {
        require(_id != 0, "Retailer ID cannot be zero");
        require(retailerAddresses[_id] != address(0), "Retailer ID does not exist");

        Retailer memory retailer = retailers[retailerAddresses[_id]];
        return retailer;
    }

    function getRetailers() public view returns (Retailer[] memory) {
        require(hasShown, "Show not called yet");
        Retailer[] memory allRetailers = new Retailer[](numRetailers);
        uint256 currentIndex = 0;
        for (uint256 i = 1; i <= numRetailers; i++) { // iterate over the retailers mapping correctly
            Retailer memory retailer = retailers[retailerAddresses[i]]; // get retailer by ID
            if (retailer.addr != address(0)) {
                allRetailers[currentIndex] = retailer;
                currentIndex++;
            }
        }
        return allRetailers;
    }

    function viewRetailerSneakers() public view returns (sneaker[] memory) {

        //Retailer memory retailer = retailers[msg.sender];
        //require(retailer.addr == msg.sender, "Only retailers can perform this action");
        sneaker[] memory allSneakers = new sneaker[](totalSneakers);
        uint256 counter = 0;
        for (uint256 i = 1; i <= totalSneakers; i++) {
            if (Sneakers[i].id != 0) {
                allSneakers[counter] = Sneakers[i];
                counter++;
            }
        }
        return allSneakers;
    }


}