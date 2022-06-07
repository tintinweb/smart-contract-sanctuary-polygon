// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ownable.sol";

contract DNS is Ownable{

    //
    // State variables
    //

    mapping (address => uint) ownerNameCount;   //number of names in existance
    mapping (uint => string) numberToName;   //(used to sort through all names)
    mapping (string => DomainName) domainNames; //gets name items from name
    mapping (string => bool) private claimed;   //stors wether a name has been claimed yet
    mapping (string => bool) private sale_list;

    enum OfferState {NotOffering, PrivateOffering, PublicOffering}

    struct DomainName {
        address payable owner;
        string name;
        string IPAddress;
        OfferState offerState;
        uint offerPrice;
        address offerAddress;
    }

    uint numberOfClaimedNames;
    bool circuitBroken;
    bool initialized;

    //
    // Events - publicize actions to external listeners
    //

    event NewNameClaimed(address accountAddress, string acquiredString);
    event NamesIPAddressChanged(string name, string IPAddress);
    event OwnershipTransfered(string name, address newOwner);

    // 
    // Modifiers
    // 

    modifier circuitNotBroken()
    {
        require(circuitBroken == false, "This contract's state has been frozen by the contract owner");
        _;
    }

    modifier ownsName(string memory _name){
        require(domainNames[_name].owner == msg.sender, "You are not this name's owner");
        _;
    }
    modifier notClaimed(string memory _name){
        require(claimed[_name] != true, "Domain name has already been claimed");
        _;
    }
    modifier is_sale_list(string memory _name){
        require(sale_list[_name] == true, "Domain are not currently for sale");
        _;
    }
    modifier isClaimed(string memory _name){
        require(claimed[_name] == true, "Domain name not yet been claimed");
        _;
    }
    modifier idExists(uint _id){
        require(_id < numberOfClaimedNames, "Requested ID is higher than current number of claimed names, or less than 0");
        _;
    }

    modifier paidEnough(uint _price) {require(msg.value >= _price,"Amount paid, not enough."); _;}

    modifier checkValue(string memory _name) {
        //refund them after pay for item (why it is before, _ checks for logic before func)
        _;
        uint _price = domainNames[_name].offerPrice;
        uint amountToRefund = msg.value - _price;
        payable(msg.sender).transfer(amountToRefund);
    }

    modifier validReceiverOf(string memory _name)
    {
        require(domainNames[_name].offerAddress == msg.sender, "msg.sender is not the authorized receiver of this private offer.");
        _;
    }

    modifier offerStateOfNameIs(string memory _name, OfferState _state)
    {
        require(domainNames[_name].offerState == _state, "offerState of name is not the state needed to preform this function");
        _;
    }

    //
    // Constructor
    //
    function initialize() public onlyOwner(){
        require(!initialized, "already initialized");
        initialized = true;
        numberOfClaimedNames = 0;
        circuitBroken = false;
    }
    //
    // Adminastrative Functions
    //

    /** @notice activates contract Circuit Breaker which stops most contract functions in case of emergency */
    function breakCircuit()
        external
        onlyOwner()
    {
        circuitBroken = true;
    }

    function unbreakCircuit() 
        external 
        onlyOwner()
    {
        circuitBroken = false;
    }
    //
    // General Functions
    //
    function AddtosaleList(string[] memory _names)
        external
        onlyOwner()
    {
        uint arrayLength = _names.length;
        for (uint i=0; i<arrayLength; i++) {
            sale_list[_names[i]] = true;
        }
    }
    /** @notice Gives msg.sender ownership of Domain Name if it's unclaimed
        @param _name name of the domain which is attempting to be claimed
     */
    function claimNewName(string memory _name)
        public
        circuitNotBroken()
        notClaimed(_name)
        is_sale_list(_name)
    {
        claimed[_name] = true;
        numberToName[numberOfClaimedNames] = _name;     //order is important
        numberOfClaimedNames++;                         //order is important
        domainNames[_name].owner = payable(msg.sender);
        domainNames[_name].name = _name;
        domainNames[_name].offerState = OfferState.NotOffering;
        ownerNameCount[msg.sender]++;   
        emit NewNameClaimed(msg.sender, _name);
    }

    /** @notice Sets name's corresponding IP address.
        @param _name Name which is having it's corresponding IP address set.
        @param _address IP Address which will be stored under specified name.
     */
    function setNamesIPAddress(string memory _name, string memory _address)
        public
        circuitNotBroken()
        isClaimed(_name)
        ownsName(_name)
    {
        domainNames[_name].IPAddress = _address;
        emit NamesIPAddressChanged(_name, _address);
    }

    //
    // View Functions
    //

    /** @notice Returns IP address of _name
        @param  _name Name who's corresponding IP address is being returned
        @return string The IP address of the given name
    */
    function viewNamesIPAddress(string memory _name)
        public
        view
        isClaimed(_name)
        returns(string memory)
    {
        return domainNames[_name].IPAddress;
    }

    /** @notice Returns list of uints, corresponding to all of msg.sender's owned Names 
        @return uint[] An array of IDs who's corresponding names are owned by msg.sender
    */
    function listNamesOwnedBy()
        external
        view
        returns(uint[] memory)
    {
        uint[] memory owned = new uint[](ownerNameCount[msg.sender]);
        uint count = 0;
        for(uint i = 0; i < numberOfClaimedNames; i++){
            if(domainNames[numberToName[i]].owner == msg.sender){
                owned[count] = i;
                count++;
            }
        }
        require(count == ownerNameCount[msg.sender], "Internal Error: Number of names retrieved != known owned names");
        return owned;
    }

    /** @notice returns the name of a corresponding ID
        @param _id uint ID which corresponds to a name
        @return string The name corresponding to the given ID
    */
    function getNameByID(uint _id)
        external
        view
        idExists(_id)
        returns(string memory)
    {
        return numberToName[_id];
    }

    //
    // Transfer related Functions
    //

    /** @notice lets msg.sender transfer ownership of one of their names to another address
        @param _name name of the address you are transfering ownership of
        @param _receiver address you are transfering ownership of name to
    */
    function transferOwnershipForFree(string memory _name, address payable _receiver)
        public
        circuitNotBroken()
        ownsName(_name)
    {
        domainNames[_name].owner = _receiver;
        ownerNameCount[msg.sender]--;
        ownerNameCount[_receiver]++;
        emit OwnershipTransfered(_name, _receiver);
    }

    /** @notice Sets name to NotOffered for sale
        @param _name Name who's offerStatus is being changed
    */
    function makeNameNotOffered(string memory _name)
        public
        circuitNotBroken()
        isClaimed(_name)
        ownsName(_name)
    {
        domainNames[_name].offerState = OfferState.NotOffering;  
    }

    /** @notice offers ownership of a name to specific address in exchange for specified amount of funds.
        @param _name The Name who's ownership is being offered
        @param _address The address who the name is being offered to
        @param _wei The amount of Wei required for transfer of ownership
    */
    function makeNamePrivatlyOffered(string memory _name, address _address, uint _wei)
        public
        circuitNotBroken()
        isClaimed(_name)
        ownsName(_name)
    {
        domainNames[_name].offerState = OfferState.NotOffering;     //assure no one can buy while contract changes price
        domainNames[_name].offerPrice = _wei;
        domainNames[_name].offerAddress = _address;
        domainNames[_name].offerState = OfferState.PrivateOffering;
    }

    /** @notice Receives required amount for offered name and transfer's ownership of name
        @param _name Name who's ownership is being transfered
    */
    function acceptPrivateOffer(string memory _name)
        public
        payable
        circuitNotBroken()
        offerStateOfNameIs(_name, OfferState.PrivateOffering)   //make sure OfferState of name is PriavateOffering
        validReceiverOf(_name)
        paidEnough(domainNames[_name].offerPrice)
        checkValue(_name)       //returns any extra funds
    {
        domainNames[_name].offerState = OfferState.NotOffering;
        ownerNameCount[domainNames[_name].owner]--;
        ownerNameCount[msg.sender]++;
        domainNames[_name].owner.transfer(domainNames[_name].offerPrice);   //pays previous owner requested amount
        domainNames[_name].owner = payable(msg.sender);
    }

    /** @notice Offers name to the public for specified amount of ether
        @param _name The Name who's ownership is being offered
        @param _wei The amount of Wei required for transfer of ownership
    */
    function makeNamePubliclyOffered(string memory _name, uint _wei)
        public
        circuitNotBroken()
        isClaimed(_name)
        ownsName(_name)
    {
        domainNames[_name].offerState = OfferState.NotOffering;     //assure no one can buy while contract changes price
        domainNames[_name].offerPrice = _wei;
        domainNames[_name].offerState = OfferState.PublicOffering;
    }

    /** @notice receives requested funds for offered name and transferes ownership of name to msg.sender
        @param _name Name who's ownership is being transfered
    */
    function acceptPublicOffer(string memory _name)
        public
        payable
        circuitNotBroken()
        offerStateOfNameIs(_name, OfferState.PublicOffering)   //make sure OfferState of name is PublicOffering
        paidEnough(domainNames[_name].offerPrice)
        checkValue(_name)       //returns any extra funds
    {
        domainNames[_name].offerState = OfferState.NotOffering;
        ownerNameCount[domainNames[_name].owner]--;
        ownerNameCount[msg.sender]++;
        domainNames[_name].owner.transfer(domainNames[_name].offerPrice);   //pays previous owner requested amount
        domainNames[_name].owner = payable(msg.sender);
    }
}