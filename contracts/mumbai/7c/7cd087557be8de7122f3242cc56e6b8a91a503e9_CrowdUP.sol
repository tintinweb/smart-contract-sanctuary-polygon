/**
 *Submitted for verification at polygonscan.com on 2022-04-02
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

//import "hardhat/console.sol";

contract CrowdUP {

    address public owner;
    uint[]  public closed;

    uint public count;
    uint bannerCount;
  
    constructor(){
        owner = msg.sender;
        add(owner);
    }

    struct Goal{
        uint id;
        address creator;
        uint goal;
        address imageAddr;
        string imageUrl;
        uint imageId;
        string[] platform;
        uint users;
        uint value;
        address[] addrList;
        bytes[] buySellTx;
        bool open;
    }

    struct User{
       uint amount;
       address user_addr;
       string[] buyTx;
       string[] profitTx;
    }

    mapping(uint => Goal) public crowdfundings;
    mapping(uint => mapping(address => User)) public transactions;
    mapping(address => bool) whitelist;

  
    event Lanch(uint id, address indexed creator, address paint, string url, string[] _platform, uint imageId, uint goal, uint quantity, bool open);
    event Log(uint receipt, string text);
    event ConfirmTransaction(uint indexed id, address indexed caller, string txId , uint amount);
    event CloseFunding(uint id);
  
    event Ads( uint id, string url, address indexed user, string txId); 
    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);

    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender), "You're not a helper");
        _;
    }

    /*
    function getOwner() public view onlyOwner returns( address ow ) {
         ow = owner;
    }
    */
    /***************************************************************************
    ******************************* Whitelisting *****************************
    ****************************************************************************/


    function add(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function remove(address _address) public onlyOwner {
        require( _address != owner, "Owner cant be removed");
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view onlyOwner  returns(bool) {
        return whitelist[_address];
    }

    /***************************************************************************
    ******************************* CrowdFunding *****************************
    ****************************************************************************/

    function start( address _creator, uint _goal, uint _value, string[] memory _platform , address _imageAddr, string memory _imageUrl, uint _imageId) external onlyWhitelisted {

        require(_imageAddr == address(_imageAddr),"Invalid address");   
        address[] memory addrs = new address[](_goal);
        bytes[] memory txhash = new bytes[](2);
        count += 1;
        
        crowdfundings[count] = Goal({
            id: count,
            creator : _creator,
            users : 0,
            goal: _goal,
            imageId: _imageId,
            imageAddr: _imageAddr,
            imageUrl: _imageUrl,
            value: _value,
            platform:_platform,
            addrList: addrs,
            buySellTx: txhash,
            open: true
        });

        emit Lanch(count, _creator, _imageAddr, _imageUrl, _platform, _imageId, _goal, _value, true);
    }

    function updateImage(uint _id, string memory _imageUrl) public  onlyOwner {
        Goal storage crowd = crowdfundings[_id];
        require(crowd.open, "Crowdfunding is finish, the image can't be changed any more");
        crowd.imageUrl = _imageUrl;
    }

    function updateTx(uint _id, bytes memory _tx) public  onlyOwner {
        Goal storage crowd = crowdfundings[_id];
        require(!crowd.open, "Crowdfunding is still open");
        
        if(crowd.buySellTx[0].length < 3){
            crowd.buySellTx[0] = _tx;
        }else{
            require(crowd.buySellTx[1].length < 3, "Can't store more Tx");
            crowd.buySellTx[1] = _tx;
        }    
    }

    function userActivity(uint _id) public onlyOwner view returns(string[] memory buyTx, string[] memory profitTx){
        User storage transaction = transactions[_id][msg.sender];
        buyTx = transaction.buyTx;
        profitTx = transaction.profitTx;
    }

    function updateActivity(uint _id, string memory _txId) public onlyOwner {
        Goal storage crowd = crowdfundings[_id];
        require(!crowd.open, "Crowdfunding is still open");
        require(crowd.buySellTx[0].length > 3 && crowd.buySellTx[1].length > 3, "hasn't been sold");
        
        User storage transaction = transactions[_id][msg.sender];
        require(transaction.profitTx.length < crowd.goal , "all user has been already payed");
        transaction.profitTx.push(_txId);
    }

    function fetchData(uint _id) public view onlyOwner returns(
        address  creator,
        uint goal,
        address  image_addr,
        string memory image_url,
        uint image_id,
        string[] memory platform,
        uint users,
        uint value,
        address[] memory addr_list,
        bytes[] memory buy_sell_tx,
        bool open
    ){
        Goal storage crowd = crowdfundings[_id];
        creator = crowd.creator;
        users = crowd.users;
        goal = crowd.goal;
        image_addr = crowd.imageAddr;
        image_url = crowd.imageUrl; 
        image_id = crowd.imageId;
        value= crowd.value;
        platform = crowd.platform;
        addr_list = crowd.addrList;
        buy_sell_tx = crowd.buySellTx;    
        open = crowd.open;
    }
  
    function fund(uint _id, address _userAddr,string memory _txId, uint _amount ) external onlyWhitelisted {
        Goal storage crowd = crowdfundings[_id];
        //require(crowd.users < crowd.goal, "Crowdfunding has been closed");
        require(crowd.open, "Crouwdunding has been closed");
        crowd.users += 1;
        crowd.addrList.push(_userAddr);
        
        User storage transaction = transactions[_id][msg.sender];
        transaction.amount += _amount;
        transaction.buyTx.push(_txId);

        if(crowd.users == crowd.goal){
            closeFunding(_id);
        }

        emit ConfirmTransaction(_id, msg.sender, _txId, _amount); 
    }

    function closeFunding(uint _id)public onlyOwner{
        Goal storage crowd = crowdfundings[_id]; 
        require(crowd.open, "Crouwdunding has been already closed");
        require(crowd.users == crowd.goal, "some users are missing");
        crowd.open = false;
        emit CloseFunding(_id);
    }


}