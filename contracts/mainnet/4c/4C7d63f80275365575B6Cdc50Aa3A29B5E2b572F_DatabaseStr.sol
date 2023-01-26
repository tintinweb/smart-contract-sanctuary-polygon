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
        string buildingIdentifierAddress;
        string barierIdentifier;
        string floorIdentfier;
        bool isBuildingManager;
        bool isTenantManager;
        bool isSpaceManager;
        bool isRegistered;
    }
    
    mapping(string => ClientDetails) clients;

    event ManagerChange();
    event ClientChange();
    

    constructor(){
	    _owner = msg.sender;    
	}

    function registerBuildingManager(string memory _clientId, string memory _buildingName, string memory _buildingIdentifier,
        string memory _buildingIdentifierAddress, string memory _barierIdentifier, string memory _floorIdentfier) 
    
    external onlyOwner {
        
        // chech manager is already registered
        require(!isBuildingManager(_clientId), "Manager already registered");
        
        clients[_clientId].buildingName = _buildingName;
        clients[_clientId].buildingIdentifier = _buildingIdentifier;
        clients[_clientId].buildingIdentifierAddress = _buildingIdentifierAddress;
        clients[_clientId].barierIdentifier = _barierIdentifier;
        clients[_clientId].floorIdentfier = _floorIdentfier;
        clients[_clientId].isBuildingManager = true;
        emit ManagerChange();

    }

    function removeBuildingManager(string memory clientId) public  onlyOwner
	{
	    require(isBuildingManager(clientId),"Building manager is not registered");
        
	    delete clients[clientId];
	    emit ManagerChange();
	}

    // ****** begin block register and remove space manager **** /
    function registerSpaceManager(
        string memory _managerId, string memory _clientId, string memory _buildingIdentifier,
        string memory _barierIdentifier, string memory _floorIdentfier
        ) 

    external eitherOwnerOrManager(_managerId) {

       clients[_clientId].buildingIdentifier = _buildingIdentifier;
       clients[_clientId].barierIdentifier = _barierIdentifier;
       clients[_clientId].floorIdentfier = _floorIdentfier;     
       clients[_clientId].isSpaceManager = true;
       emit ManagerChange();

    }

    function removeSpaceManager(string memory _managerId, string memory _clientId)     
    public  eitherOwnerOrManager(_managerId)
	{
	    require(isSpaceManager(_clientId),"Space manager is not registered");
        
	    delete clients[_clientId];
	    emit ManagerChange();
	}
    // ****** end block register and remove space manager **** /

    function registerClient(
        string memory _managerId, string memory _clientId, string memory _buildingIdentifier,
        string memory _barierIdentifier, string memory _floorIdentfier
        ) 
    external eitherOwnerOrManagerOrSpaceManager(_managerId) {
        require(!clientIsRegistered(_clientId), "Client already registered");
        
        clients[_clientId].buildingIdentifier = _buildingIdentifier;
        clients[_clientId].barierIdentifier = _barierIdentifier;
        clients[_clientId].floorIdentfier = _floorIdentfier;
        clients[_clientId].isRegistered = true;
        emit ClientChange();
    }

     function removeClient(string memory _managerId, string memory clientId) public  eitherOwnerOrManagerOrSpaceManager(_managerId)
	{
	    require(clientIsRegistered(clientId),"Client is not registered");
        
	    delete clients[clientId];
	    emit ManagerChange();
	}

    function unlock(string memory _clientId, string memory _buildingIdentifier,
        string memory _barierIdentifier, string memory _floorIdentfier) 
        external 
		view 
		returns(bool canUnlock) {
            if (msg.sender == _owner) return true;
            if (isBuildingManager(_clientId)) return true;

           return 
           keccak256(abi.encodePacked(clients[_clientId].buildingIdentifier)) == keccak256(abi.encodePacked(_buildingIdentifier))
           &&
           keccak256(abi.encodePacked(clients[_clientId].barierIdentifier)) == keccak256(abi.encodePacked(_barierIdentifier))
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

    function isBuildingManager(string memory _clientId) internal view returns (bool isBManager) 
	{
	    return clients[_clientId].isBuildingManager;
	}

    function isSpaceManager(string memory _clientId) internal view returns (bool isSManager) 
	{
	    return clients[_clientId].isSpaceManager;
	}

    modifier onlyOwner() {
	    require(msg.sender == _owner, "Only Owner can do this");
	    _;
	}

    modifier eitherOwnerOrManager(string memory clientId) {
	    require(msg.sender == _owner || isBuildingManager(clientId), 
	    	"Only Owner and Building Managers can do this"
	    );
	    _;
	}

     modifier eitherOwnerOrManagerOrSpaceManager(string memory clientId) {
	    require(msg.sender == _owner || isBuildingManager(clientId)
        || isSpaceManager(clientId), 
	    	"Only Owner and Building and Space Managers can do this"
	    );
	    _;
	}

}