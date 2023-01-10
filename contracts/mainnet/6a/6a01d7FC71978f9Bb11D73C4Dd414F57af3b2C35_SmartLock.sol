/**
 *Submitted for verification at polygonscan.com on 2023-01-10
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract SmartLock {
	
	struct GuestPermissionDetails {
	    uint256 unixStartDate;
	    uint256 unixExpiryDate;
	    uint indexAtAllGuestsList;
	}
	
	struct ManagerDetails {
	    bool isRegistered;
	    uint indexAtAllManagersList;
	}

	struct ExclusiveFeatureDetails {
	    uint256 unixExpiryDate;
	    address holder;
	}

	address internal _host;
	mapping(address => ManagerDetails) internal _managers;
	address[] internal _allManagers;

	mapping(address => GuestPermissionDetails) internal _guests;
	address[] internal _allGuests;

	ExclusiveFeatureDetails internal _exclusivePermission;
	
	event GuestChange();
	event ManagerChange();
	event ExclusiveFeatureChange();

	constructor(){
	    _host = msg.sender;
	    _exclusivePermission.unixExpiryDate = 0;
	    _exclusivePermission.holder = 
	    	0x0000000000000000000000000000000000000000;
	}
	
	function registerGuest(
		address guest, 
		uint256 unixStartDate, 
		uint256 unixExpiryDate
	) 
		public 
		eitherOwnerOrManager 
	{
	    if (!guestIsRegistered(guest)) {
	        _allGuests.push(guest);
	        _guests[guest].indexAtAllGuestsList = _allGuests.length - 1;
	    }
	    
	    _guests[guest].unixStartDate = unixStartDate;
	    _guests[guest].unixExpiryDate = unixExpiryDate;
	    emit GuestChange();
	}
	
	function removeGuest(address guest) 
	    public 
	    eitherOwnerOrManager 
	    notExclusivePermissionHolder(guest)
	{
	    require(guestIsRegistered(guest), "The Guest is not registered");
	    
	    if (_allGuests.length > 1) {
    	    swapGuestWithLastAtAllGuests(guest);
    	    _allGuests.pop();
	    } else {
	        delete _allGuests;
	    }
	    
	    delete _guests[guest];
	    emit GuestChange();
	}
	
	function registerManager(address manager) public onlyOwner {
	    require(
	        !isManager(manager), 
	        "Manager already registered"
	    );
	    
	    _allManagers.push(manager);
	    _managers[manager].isRegistered = true;
	    _managers[manager].indexAtAllManagersList = _allManagers.length - 1;
	    emit ManagerChange();
	}
	
	function removeManager(address manager) 
	    public 
	    onlyOwner 
	    notExclusivePermissionHolder(manager)
	{
	    require(
	        isManager(manager), 
	        "Manager is not registered"
	    );
	    
	    if (_allManagers.length > 1) {
	        swapManagerWithLastAtAllManagers(manager);
	        _allManagers.pop();
	    } else {
			delete _allManagers;	    
	    }
        
	    delete _managers[manager];
	    emit ManagerChange();
	}

	function turnExclusiveFeatureOn(
		address holder, 
		uint256 unixExpiryDate
	) 
		public 
		eitherOwnerOrManager 
	{
	    require(exclusiveFeatureIsOff(), "Feature is already On");
	    require(
	    	unlock(holder), 
	    	"The permission holder must have active unlock permission"
	    );
	    if(isManager(msg.sender)) {
	    	require(
	    		!isManager(holder) && holder != _host,
	    		"Manager can only turn this feature on to Guests"
	    	);
	    }
	    
	    _exclusivePermission.unixExpiryDate = unixExpiryDate;
	    _exclusivePermission.holder = holder;
	    emit ExclusiveFeatureChange();
	}
	
	function turnExclusiveFeatureOff() public {
	    require(!exclusiveFeatureIsOff(), "Feature is already Off");
	    require(
	    	msg.sender == _exclusivePermission.holder, 
	    	"Only exclusive holder can turn off"
	    );
	    
	    _exclusivePermission.unixExpiryDate = 0;
	    _exclusivePermission.holder = 
	    	0x0000000000000000000000000000000000000000;
	    emit ExclusiveFeatureChange();
	}

	function unlock(address whoKnocks) 
		public 
		view 
		returns(bool canUnlock) 
	{
	    if (!exclusiveFeatureIsOff()) {
	        return whoKnocks == _exclusivePermission.holder;
	    }
	    
	    if (whoKnocks == _host) return true;
	    if (isManager(whoKnocks)) return true;
	    
	    if (
	    	(_guests[whoKnocks].unixStartDate <= block.timestamp) && 
	        (_guests[whoKnocks].unixExpiryDate >= block.timestamp)
	    ) 
	        return true;
	    
	    return false;
	}
	
	function guestPermissionDetails(address guest) 
		public 
		view 
		eitherOwnerOrManager 
		returns (uint256 unixStartDate, uint256 unixExpiryDate)
	{
	    return (
	    	_guests[guest].unixStartDate, 
	    	_guests[guest].unixExpiryDate
	    );
	}
	
	function guestSelfPermissionDetails() 
		public 
		view 
		returns (
			uint256 unixStartDate, 
			uint256 unixExpiryDate,
			bool canUnlockNow,
			bool holdsExclusivePermission, 
			uint256 exclusivePermissionUnixExpiryDate
		) 
	{
	    if (holdsActiveExclusivePermission(msg.sender)) {

	        return (
	        	_guests[msg.sender].unixStartDate, 
	        	_guests[msg.sender].unixExpiryDate, 
	        	unlock(msg.sender),
	        	true, 
	        	_exclusivePermission.unixExpiryDate
	        );
	    } else {

	    	return (
		    	_guests[msg.sender].unixStartDate, 
		    	_guests[msg.sender].unixExpiryDate, 
		    	unlock(msg.sender),
		    	false, 
		    	0
		    );
		}
	}
	
	function retrieveGuests() 
		public 
		view 
		eitherOwnerOrManager 
		returns (address[] memory allGuests) 
	{
	    return _allGuests;
	}

	function getExclusiveFeatureDetails() 
		public 
		view 
		eitherOwnerOrManager 
		returns (
			address permissionHolder, 
			uint256 permissionUnixExpiryDate
		) 
	{
	    return (
	    	_exclusivePermission.holder, 
	    	_exclusivePermission.unixExpiryDate
	    );
	}
	
	function guestIsRegistered(address guest) 
		internal 
		view 
		returns (bool isRegistered) 
	{
	    return _guests[guest].unixStartDate != 0;
	}
	
	function swapGuestWithLastAtAllGuests(address guest) internal {
	    _allGuests[_guests[guest].indexAtAllGuestsList] = 
	    	_allGuests[_allGuests.length - 1];
	    _guests[_allGuests[_allGuests.length - 1]].indexAtAllGuestsList =
	    	_guests[guest].indexAtAllGuestsList;
	}
	
	function retrieveManagers() 
		public 
		view 
		onlyOwner 
		returns (address[] memory allManagers) 
	{
	    return _allManagers;
	}
	
	function isManager(address who) 
		internal 
		view 
		returns (bool isRegistered) 
	{
	    return _managers[who].isRegistered;
	}
	
	function swapManagerWithLastAtAllManagers(address manager) internal {
	    _allManagers[_managers[manager].indexAtAllManagersList] =
            _allManagers[_allManagers.length - 1];
        _managers[_allManagers[_allManagers.length - 1]].indexAtAllManagersList = 
            _managers[manager].indexAtAllManagersList;
	}

	function holdsActiveExclusivePermission(address who) 
		internal 
		view 
		returns (bool itHolds) 
	{
	    return (
	    	who == _exclusivePermission.holder && 
	    	!exclusiveFeatureIsOff()
	    );
	}
	
	function exclusiveFeatureIsOff() internal view returns(bool isOff) {
	    return block.timestamp >= _exclusivePermission.unixExpiryDate;
	}
	
	modifier onlyOwner() {
	    require(msg.sender == _host, "Only Host can do this");
	    _;
	}

	modifier eitherOwnerOrManager() {
	    require(
	    	msg.sender == _host || isManager(msg.sender), 
	    	"Only Host and Managers can do this"
	    );
	    _;
	}
	
	modifier notExclusivePermissionHolder(address who) {
	    require(
	    	exclusiveFeatureIsOff() || who != _exclusivePermission.holder,
	    	"The person holds an active exclusive permission"
	    );
	    _;
	}
	
}