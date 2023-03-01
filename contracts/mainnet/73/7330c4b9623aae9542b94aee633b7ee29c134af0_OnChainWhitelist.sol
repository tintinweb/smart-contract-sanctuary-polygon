/**
 *Submitted for verification at polygonscan.com on 2023-02-27
*/

// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.7;

interface iINKz {
    function balanceOf(address address_) external view returns (uint); 
    function transferFrom(address from_, address to_, uint amount) external returns (bool);
    function burn(address from_, uint amount) external;
}

interface IERC20 {
    function transfer(address _to, uint256 _amount) external returns (bool);
}

contract OnChainWhitelist {

    struct WhitelistDetails {
        address[] allPurchases; // all purchases per whitelist
        //mapping(address => uint256) addressPurchases; // count of purchases per address per whitelist
        string name; //name of listing
        string image; //image url
        uint32 slots; //available purchases
        uint32 startTime; //unixtimestamp of start time/date
        uint32 endTime; //unixtimestamp of end time/date
        uint256 price; //price for a single purchase
        bool isBurn; //defines if tokens are burned or not
    }

    mapping(uint256 => WhitelistDetails) whitelists; //mapping between whitelist id and its details
    address public owner; //owner of the contract
    uint256 public whitelistCounter; //counter for whitelists created
    bool internal locked; //for no re-entrancy
    mapping(address => bool) public authorized;

    constructor(){
        owner = msg.sender;
    }

    /*
        Checks if the executor is the owner of the contract.
    */
    modifier onlyOwner(){
        require(msg.sender == owner, "Function could be executed only by the owner of the contract.");
        _;
    }

    

    modifier noReentrant() {
        require(!locked, "No re-entrancy");
        locked = true;
        _;
        locked = false;
    }

    event whitelistCreated(uint _whitelistId, uint _slots, uint _price);
    event whitelistPurchased(address _purchaser, uint _whitelistId, uint _price);

    address public INKzAddress;
    iINKz public INKz;

    function setINKz(address address_) external onlyOwner { 
        INKzAddress = address_;
        INKz = iINKz(address_);
    }

    /*
        Sets the price of each whitelist entry.
            @price -> price of whitelist in ETH.
    */
    function setPriceOfTicket(uint _whitelistId, uint256 _price) external onlyOwner {
        whitelists[_whitelistId].price = _price;
    }

    function setAuthorized(address _address, bool _authorized) public onlyOwner {
        authorized[_address] = _authorized;
    }



    /*
        Starts the whitelist with given information.
    */
    function startWhitelist(string memory _name, string memory _image, uint32 _startTime, uint32 _endTime, uint32 _slots, uint256 _price, bool _isBurn) external {
        uint256 setWhitelist = whitelistCounter + 1;
        require(whitelists[setWhitelist].startTime == 0, "There is an active whitelist at the moment.");
        require(authorized[msg.sender], "You do not have permission");
        whitelists[setWhitelist].name = _name;
        whitelists[setWhitelist].image = _image;
        whitelists[setWhitelist].slots = _slots;
        whitelists[setWhitelist].startTime = _startTime;
        whitelists[setWhitelist].endTime = _endTime;
        whitelists[setWhitelist].price = _price;
        whitelists[setWhitelist].isBurn = _isBurn;
        whitelistCounter++;
        emit whitelistCreated(setWhitelist, _slots, _price);
    }

    function editWhitelist(uint256 setWhitelist, string memory _name, string memory _image, uint32 _startTime, uint32 _endTime, uint32 _slots, uint256 _price, bool _isBurn) external {
        require(authorized[msg.sender], "You do not have permission");

        whitelists[setWhitelist].name = _name;
        whitelists[setWhitelist].image = _image;
        whitelists[setWhitelist].slots = _slots;
        whitelists[setWhitelist].startTime = _startTime;
        whitelists[setWhitelist].endTime = _endTime;
        whitelists[setWhitelist].price = _price;
        whitelists[setWhitelist].isBurn = _isBurn;
    }

    /*
        Manually stops whitelist.
    */
    function stopWhitelist(uint _whitelistId) external onlyOwner {
        require(whitelists[_whitelistId].startTime > 0, "There isn't an active whitelist at the moment.");
        whitelists[_whitelistId].startTime = 0;
        whitelists[_whitelistId].endTime = 0;
    }
    
    /*
        External method used to buy a whitelist.
    */
    function buyWhitelist(uint _whitelistId) external payable noReentrant {
        require(whitelists[_whitelistId].startTime < block.timestamp && whitelists[_whitelistId].endTime > block.timestamp, "Sale not ready or ended");
        require(whitelists[_whitelistId].allPurchases.length < whitelists[_whitelistId].slots, "Sold Out!");
        require(getWalletPurchases(_whitelistId, msg.sender) == false, "Already Whitelisted");
        require(INKz.balanceOf(msg.sender) >= whitelists[_whitelistId].price, "You do not have enough INKz!");

        if(whitelists[_whitelistId].isBurn) {
            INKz.burn(msg.sender, whitelists[_whitelistId].price);
        } else {
            INKz.transferFrom(msg.sender, address(this), whitelists[_whitelistId].price);
        }
        //whitelists[_whitelistId].addressPurchases[msg.sender]++;
        whitelists[_whitelistId].allPurchases.push(msg.sender);
        emit whitelistPurchased(msg.sender, _whitelistId, whitelists[_whitelistId].price);
    }

    /*
        Transfers the ownership to another owner.
    */
    function transferOwnership(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    //GETTERS

    /*
        Returns all the whitelisted addresses for the given id.
    */
    function getWhitelistedAddresses(uint256 _whitelistId) external view returns(address[] memory){
        return whitelists[_whitelistId].allPurchases;
    }

    function getAllWhitelists() public view returns(WhitelistDetails[] memory){
        WhitelistDetails[] memory lWhitelists = new WhitelistDetails[](whitelistCounter);
        for (uint i = 0; i < whitelistCounter; i++){
            WhitelistDetails storage lWhitelist = whitelists[i + 1];
            lWhitelists[i] = lWhitelist;
        }
        return lWhitelists;
    }

    function getWhitelistInfo(uint256 _whitelistId) external view returns(string memory, string memory, uint32, uint32, uint32, uint256, uint256, bool){
        WhitelistDetails storage w = whitelists[_whitelistId];
        uint256 remaining = whitelists[_whitelistId].slots - whitelists[_whitelistId].allPurchases.length;
        return (
            w.name,
            w.image,
            w.startTime,
            w.endTime,
            w.slots,
            w.price,
            remaining,
            w.isBurn
        );
    }

    /*
        Returns whitelisted count per wallet for the given whitelist.
    */
    function getWalletPurchases(uint256 _whitelistId, address _wallet) public view returns(bool){
        uint entries = whitelists[_whitelistId].allPurchases.length;
        for(uint i = 0; i < entries; i++){
            if (whitelists[_whitelistId].allPurchases[i] == _wallet){
                return true;
            }
        } return false;

    }

    //withdraw erc20 tokens from contract
    function withdrawToken(address _tokenContract, uint256 _amount) external onlyOwner {
       IERC20 tokenContract = IERC20(_tokenContract);
        tokenContract.transfer(msg.sender, _amount);
    }
}