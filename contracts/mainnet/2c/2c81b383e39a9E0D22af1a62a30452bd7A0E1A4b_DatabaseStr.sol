/**
 *Submitted for verification at polygonscan.com on 2023-01-26
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DatabaseStr {

    address internal _owner;

    struct ClientDetails {
        //string clientId;
        string buildingName;
        string buildingIdentifier;
        string buildingPhysicalAddress;
        string barrierIdentifier;
        string floorIdentfier;
        string roomNumbersIdentifier;
        string spaceManagerId;  // building 
        string tenantManagerId; // tenant
        
        bool isSpaceManager;
        bool isTenantManager;        
        bool isRegistered;
    }
    
    mapping(string => ClientDetails) clients;

    event ManagerChange();
    event ClientChange();
    
    function getClient(string memory _clientId) 
        public view returns(ClientDetails memory client) 
    {
        return clients[_clientId];
    }

    constructor(){
	    _owner = msg.sender;    
	}

    function registerSpaceManager(string memory _clientId, 
    string memory _buildingName, string memory _buildingIdentifier,
        string memory _buildingPhysicalAddress 
        ) 
    
    external onlyOwner {
        
        // chech manager is already registered
        require(!isSpaceManager(_clientId), "Manager already registered");
        
        clients[_clientId].buildingName = _buildingName;
        clients[_clientId].buildingIdentifier = _buildingIdentifier;
        clients[_clientId].buildingPhysicalAddress = _buildingPhysicalAddress;
        
        //clients[_clientId].barierIdentifier = _barierIdentifier;
        //clients[_clientId].floorIdentfier = _floorIdentfier;
        
        clients[_clientId].isSpaceManager = true;
        emit ManagerChange();

    }

    function removeSpaceManager(string memory clientId) public  onlyOwner
	{
	    require(isSpaceManager(clientId),"Building manager is not registered");
        
	    delete clients[clientId];
	    emit ManagerChange();
	}

    // ****** begin block register and remove tenant manager **** /
    function registerTenantManager(
        string memory _managerId, string memory _clientId, string memory _buildingIdentifier,
        string memory _barrierIdentifier, string memory _floorIdentfier
        ) 

    external eitherOwnerOrManager(_managerId) {

       clients[_clientId].buildingIdentifier = _buildingIdentifier;
       clients[_clientId].barrierIdentifier = _barrierIdentifier;
       clients[_clientId].floorIdentfier = _floorIdentfier; 
       clients[_clientId].spaceManagerId = _managerId;    
       clients[_clientId].isTenantManager = true;
       emit ManagerChange();

    }

    function removeTenantManager(string memory _managerId, string memory _clientId)     
    public  eitherOwnerOrManager(_managerId)
	{
	    require(isTenantManager(_clientId),"Tenant manager is not registered");
        
	    delete clients[_clientId];
	    emit ManagerChange();
	}
    // ****** end block register and remove space manager **** /

    function registerClient(
        string memory _managerId, string memory _clientId, string memory _buildingIdentifier,
        string memory _barrierIdentifier, string memory _floorIdentfier, string memory _roomNumbersIdentifier
        ) 
    external eitherOwnerOrManagerOrTenantManager(_managerId) {
        require(!clientIsRegistered(_clientId), "Client already registered");
        
        clients[_clientId].buildingIdentifier = _buildingIdentifier;
        clients[_clientId].barrierIdentifier = _barrierIdentifier;
        clients[_clientId].floorIdentfier = _floorIdentfier;
        clients[_clientId].roomNumbersIdentifier = _roomNumbersIdentifier;
        clients[_clientId].tenantManagerId = _managerId;
        clients[_clientId].isRegistered = true;
    
        emit ClientChange();
    }

    function changeBarrier(string memory _managerId, string memory _clientId, 
    string memory _barrierIdentifier) external eitherOwnerOrManagerOrTenantManager(_managerId) {
        clients[_clientId].barrierIdentifier = _barrierIdentifier;
    }

     function removeClient(string memory _managerId, string memory clientId) 
     public  eitherOwnerOrManagerOrTenantManager(_managerId)
	{
	    require(clientIsRegistered(clientId),"Client is not registered");
        
	    delete clients[clientId];
	    emit ManagerChange();
	}

    function unlock(string memory _clientId, string memory _buildingIdentifier,
        string memory _barrierIdentifier, string memory _floorIdentfier) 
        external 
		view 
		returns(bool canUnlock) {
            
            if (msg.sender == _owner) return true;
            
            if (isSpaceManager(_clientId)) return true;

           return 
           keccak256(abi.encodePacked(clients[_clientId].buildingIdentifier)) == keccak256(abi.encodePacked(_buildingIdentifier))
           &&
           keccak256(abi.encodePacked(clients[_clientId].barrierIdentifier)) == keccak256(abi.encodePacked(_barrierIdentifier))
           &&
           keccak256(abi.encodePacked(clients[_clientId].floorIdentfier)) == keccak256(abi.encodePacked(_floorIdentfier));
        }


    function clientIsRegistered(string memory _clientId) 
		internal 
		view 
		returns (bool isRegistered) 
	{
	    return clients[_clientId].isRegistered;
	}

    function isSpaceManager(string memory _clientId) internal view returns (bool isSManager) 
	{
	    return clients[_clientId].isSpaceManager;
	}

    function isTenantManager(string memory _clientId) internal view returns (bool isTManager) 
	{
	    return clients[_clientId].isTenantManager;
	}


    modifier onlyOwner() {
	    require(msg.sender == _owner, "Only Owner can do this");
	    _;
	}

    modifier eitherOwnerOrManager(string memory clientId) {
	    require(msg.sender == _owner || isSpaceManager(clientId), 
	    	"Only Owner and Building Managers can do this"
	    );
	    _;
	}

     modifier eitherOwnerOrManagerOrTenantManager(string memory _clientId) {
	    require(msg.sender == _owner || isSpaceManager(_clientId)
        || isTenantManager(_clientId), 
	    	"Only Owner and Building and Space Managers can do this"
	    );
	    _;
	}

}