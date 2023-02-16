/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

// File: contracts/dashboard.sol


pragma solidity ^0.8.0;

contract test {
    address public owner;
    address[] public traders;
    address[] public recyclers;
    address[] public logisticsPartners;
    address[] public Manufacturers;

    struct WasteMaterial {
        address recycler;
        address logisticsPartner;  
        string typeOfMaterial;
        string category;
        string subCategory;
        string geoAddress;
        uint timestamp;
    }

    struct RecycledMaterial {
        address Manufacturer;
        address logisticsPartner;  
        uint wasteId;
        string typeOfMaterial;
        string category;
        string subCategory;
        string geoAddress;
        uint timestamp;
    }



    mapping(uint => WasteMaterial) public wasteMaterials;
    uint public wasteId;
     mapping(uint => RecycledMaterial) public recycledMaterials;
    uint public RecycledId;

    constructor() public {
        owner = msg.sender;
        
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can perform this action.");
        _;
    }

    modifier onlyTrader() {
    require(isTrader(msg.sender), "Only traders can perform this action.");
    _;
}
    modifier onlyRecycler() {
    require(isRecycler(msg.sender), "Only recycelrs can perform this action.");
    _;
}


    function addTrader(address trader) public onlyOwner {
        traders.push(trader);
    }

    function addRecycler(address recycler) public onlyOwner {
        recyclers.push(recycler);
    }

    function addLogisticsPartner(address logisticsPartner) public onlyOwner {
        logisticsPartners.push(logisticsPartner);
    }

    function addManufacturer(address Manufacturer) public onlyOwner {
        Manufacturers.push(Manufacturer);
    }

    function listTraders() public view returns (address[] memory) {
        return traders;
    }

    function listRecyclers() public view returns (address[] memory) {
        return recyclers;
    }

    function listLogisticsPartners() public view returns (address[] memory) {
        return logisticsPartners;
    }

    function listManufacturer() public view returns (address[] memory) {
        return Manufacturers;
    }

    function addWasteMaterial(string memory typeOfMaterial, string memory category, string memory subCategory, string memory geoAddress) public {
    bool isTrader = false;
    for (uint i = 0; i < traders.length; i++) {
        if (msg.sender == traders[i]) {
            isTrader = true;
            break;
        }
    }
    require(isTrader, "Only traders can perform this action.");
    wasteId++;
    wasteMaterials[wasteId] = WasteMaterial(address(0),address(0), typeOfMaterial, category, subCategory, geoAddress, block.timestamp);

}

function addRecycledMaterial(uint wasteId, string memory typeOfMaterial, string memory category, string memory subCategory, string memory geoAddress) public {
    bool isRecycler = false;
    for (uint i = 0; i < recyclers.length; i++) {
        if (msg.sender == recyclers[i]) {
            isRecycler = true;
            break;
        }
    }
    require(isRecycler, "Only recyclers can perform this action.");
    RecycledId++;
    recycledMaterials[RecycledId] = RecycledMaterial(address(0),address(0),wasteId, typeOfMaterial, category, subCategory, geoAddress, block.timestamp);

}

 function listWasteMaterial(uint wasteId) public view returns (string memory, string memory, string memory, string memory, uint) {
    WasteMaterial storage waste = wasteMaterials[wasteId];
    return (waste.typeOfMaterial, waste.category, waste.subCategory, waste.geoAddress, waste.timestamp);
}

 function listRecycledMaterial(uint RecycledId) public view returns (uint,string memory, string memory, string memory, string memory, uint) {
    RecycledMaterial storage recycled = recycledMaterials[RecycledId];
    return (recycled.wasteId,recycled.typeOfMaterial, recycled.category, recycled.subCategory, recycled.geoAddress, recycled.timestamp);
}

function assignRecycler(uint wasteId, address recycler) public {
    bool isTrader = false;
    for (uint i = 0; i < traders.length; i++) {
        if (msg.sender == traders[i]) {
            isTrader = true;
            break;
        }
    }
    require(isTrader, "Only traders can perform this action.");

    bool isRecycler = false;
    for (uint i = 0; i < recyclers.length; i++) {
        if (recycler == recyclers[i]) {
            isRecycler = true;
            break;
        }
    }
    require(isRecycler, "Invalid recycler address. The address provided is not a registered recycler.");

    wasteMaterials[wasteId].recycler = recycler;
}


function assignManufacturer(uint RecycledId, address Manufacturer) public {
    bool isRecycler = false;
    for (uint i = 0; i < recyclers.length; i++) {
        if (msg.sender == recyclers[i]) {
            isRecycler = true;
            break;
        }
    }
    require(isRecycler, "Only Recyclers can perform this action.");

    bool isManufacturer = false;
    for (uint i = 0; i < Manufacturers.length; i++) {
        if (Manufacturer == Manufacturers[i]) {
            isManufacturer = true;
            break;
        }
    }
    require(isManufacturer, "Invalid manufacturer address. The address provided is not a registered manufacturer.");

    recycledMaterials[RecycledId].Manufacturer = Manufacturer;
}


function assignLogisticsPartner(uint wasteId, address logisticsPartner) public {
    // Check if the msg.sender is a trader
    bool isTrader = false;
    for (uint i = 0; i < traders.length; i++) {
        if (msg.sender == traders[i]) {
            isTrader = true;
            break;
        }
    }
    require(isTrader, "Only traders can perform this action.");

    // Check if the provided logistics partner address is a registered logistics partner
    bool isLogisticsPartner = false;
    for (uint i = 0; i < logisticsPartners.length; i++) {
        if (logisticsPartner == logisticsPartners[i]) {
            isLogisticsPartner = true;
            break;
        }
    }
    require(isLogisticsPartner, "Invalid logistics partner address. The address provided is not a registered logistics partner.");

    // Assign the logistics partner to the waste material
    wasteMaterials[wasteId].logisticsPartner = logisticsPartner;
}

function assignLogisticsPartnerRecyled(uint RecycledId, address logisticsPartner) public {
    // Check if the msg.sender is a trader
    bool isRecycler = false;
    for (uint i = 0; i < recyclers.length; i++) {
        if (msg.sender == recyclers[i]) {
            isRecycler = true;
            break;
        }
    }
    require(isRecycler, "Only recyclers can perform this action.");

    // Check if the provided logistics partner address is a registered logistics partner
    bool isLogisticsPartner = false;
    for (uint i = 0; i < logisticsPartners.length; i++) {
        if (logisticsPartner == logisticsPartners[i]) {
            isLogisticsPartner = true;
            break;
        }
    }
    require(isLogisticsPartner, "Invalid logistics partner address. The address provided is not a registered logistics partner.");

    // Assign the logistics partner to the waste material
    //recycledMaterials[RecycledId].Manufacturer = Manufacturer;
    recycledMaterials[RecycledId].logisticsPartner = logisticsPartner;
}

function createNFCHash(uint wasteId) public view onlyTrader returns (bytes32) {
    require(wasteMaterials[wasteId].recycler != address(0), "Recycler not assigned to waste material");
    require(wasteMaterials[wasteId].logisticsPartner != address(0), "Logistics partner not assigned to waste material");
    return keccak256(abi.encodePacked(wasteId, wasteMaterials[wasteId].typeOfMaterial, wasteMaterials[wasteId].category, wasteMaterials[wasteId].subCategory, wasteMaterials[wasteId].geoAddress, wasteMaterials[wasteId].timestamp));
}

function createNFCHashrecycled(uint RecycledId) public view onlyRecycler returns (bytes32) {
    require(recycledMaterials[RecycledId].Manufacturer != address(0), "Manufacturer not assigned to waste material");
    require(recycledMaterials[RecycledId].logisticsPartner != address(0), "Logistics partner not assigned to waste material");
    return keccak256(abi.encodePacked(RecycledId, recycledMaterials[RecycledId].wasteId,recycledMaterials[RecycledId].typeOfMaterial, recycledMaterials[RecycledId].category, recycledMaterials[RecycledId].subCategory, recycledMaterials[RecycledId].geoAddress, recycledMaterials[RecycledId].timestamp));
}




function isTrader(address _address) private view returns (bool) {
    for (uint i = 0; i < traders.length; i++) {
        if (_address == traders[i]) {
            return true;
        }
    }
    return false;
}

function isRecycler(address _address) private view returns (bool) {
    for (uint i = 0; i < recyclers.length; i++) {
        if (_address == recyclers[i]) {
            return true;
        }
    }
    return false;
}

function ReadNFCHash(bytes32 hash) public view returns (address, string memory, string memory, string memory, string memory, uint) {
    // Iterate through all waste materials
    for (uint i = 1; i <= wasteId; i++) {
        // Check if the hash matches the hash of the current waste material
        if (keccak256(abi.encodePacked(wasteMaterials[i].typeOfMaterial, wasteMaterials[i].category, wasteMaterials[i].subCategory, wasteMaterials[i].geoAddress, wasteMaterials[i].timestamp)) == hash) {
            return (wasteMaterials[i].recycler, wasteMaterials[i].typeOfMaterial, wasteMaterials[i].category, wasteMaterials[i].subCategory, wasteMaterials[i].geoAddress, wasteMaterials[i].timestamp);
        }
    }
    // If no matching hash is found, return an empty address
    return (address(0), "", "", "", "", 0);
}

function ReadNFCHashRecycled(bytes32 hash) public view returns (address,uint, string memory, string memory, string memory, string memory, uint) {
    // Iterate through all waste materials
    for (uint i = 1; i <= RecycledId; i++) {
        // Check if the hash matches the hash of the current waste material
        if (keccak256(abi.encodePacked(recycledMaterials[i].wasteId,recycledMaterials[i].typeOfMaterial, recycledMaterials[i].category, recycledMaterials[i].subCategory, recycledMaterials[i].geoAddress, recycledMaterials[i].timestamp)) == hash) {
            return (recycledMaterials[i].Manufacturer,recycledMaterials[i].wasteId, recycledMaterials[i].typeOfMaterial, recycledMaterials[i].category, recycledMaterials[i].subCategory, recycledMaterials[i].geoAddress, recycledMaterials[i].timestamp);
        }
    }
    // If no matching hash is found, return an empty address
    return (address(0),0, "", "", "", "", 0);
}

function showHash(uint wasteId) public view returns (bytes32) {
    require(wasteId <= wasteId, "Invalid waste ID. The waste ID provided does not exist.");
    WasteMaterial storage waste = wasteMaterials[wasteId];
    return keccak256(abi.encodePacked(waste.typeOfMaterial, waste.category, waste.subCategory, waste.geoAddress, waste.timestamp));
}

function showrecycledHash(uint RecycledId) public view returns (bytes32) {
    require(RecycledId <= RecycledId, "Invalid recycled ID. The recycled ID provided does not exist.");
    //RecycledMaterial storage waste = wasteMaterials[wasteId];
    RecycledMaterial storage recycled = recycledMaterials[RecycledId];
    return keccak256(abi.encodePacked(recycled.wasteId,recycled.typeOfMaterial, recycled.category, recycled.subCategory, recycled.geoAddress, recycled.timestamp));
}


}