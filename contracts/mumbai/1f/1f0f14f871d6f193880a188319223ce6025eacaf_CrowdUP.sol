/**
 *Submitted for verification at polygonscan.com on 2022-03-04
*/

// SPDX-License-Identifier: MIt
pragma solidity ^0.8.7;

contract CrowdUP {

    address public safeAddr;
    address owner; 
  
    constructor(address _multiAddr){
        safeAddr = _multiAddr;
        owner = msg.sender;
        add(owner);
    }

    /***************************************************************************
    ******************************* Whitelisting *****************************
    ****************************************************************************/

    mapping(address => bool) whitelist;

    event AddedToWhitelist(address indexed account);
    event RemovedFromWhitelist(address indexed account);


    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyWhitelisted() {
        require(isWhitelisted(msg.sender));
        _;
    }

    function add(address _address) public onlyOwner {
        whitelist[_address] = true;
        emit AddedToWhitelist(_address);
    }

    function remove(address _address) public onlyOwner {
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function isWhitelisted(address _address) public view onlyOwner  returns(bool) {
        return whitelist[_address];
    }

    /***************************************************************************
    ******************************* CrowdFunding *****************************
    ****************************************************************************/
    uint count;

     struct Goal{
        address creator;
        uint goal;
        address multiAdrr;
        address paint;
        uint users;
        uint quantity;
        bool open;
    }

    struct User{
       uint amount;
       string[] txId;
    }

    mapping(uint => Goal) public crowdfundings;
    mapping(uint => mapping(address => User)) public transactions;
  
    event Launch(uint id, address indexed creator, address indexed safeAddr,address paint, uint gol, uint quantity, bool open);
    event Log(uint receipt, string text);
    event ConfirmTransaction(uint indexed id, address indexed caller, string txId , uint amount);
    event CloseFunding(uint id);

    function lanch( uint _goal, uint _quantity,address _paint) external onlyWhitelisted {

        require(_paint == address(_paint),"Invalid address");  

        count += 1;
        crowdfundings[count] = Goal({
            creator : msg.sender,
            multiAdrr:  safeAddr,
            paint: _paint,
            users : 0,
            goal: _goal,
            quantity: _quantity,
            open: true
        });

        emit Launch(count, msg.sender, safeAddr, _paint, _goal, _quantity, true);
    }

    function userTransaction(uint _id) public view onlyOwner returns(string[] memory) {
        User storage transaction = transactions[_id][msg.sender];
        return transaction.txId;
    }

    function fund(uint _id, string memory _txId, uint _amount ) external onlyOwner {
        Goal storage crowd = crowdfundings[_id];
        require(crowd.users < crowd.goal, "This Checkin has been closed");
        crowd.users += 1;
        
        User storage transaction = transactions[_id][msg.sender];
        transaction.amount += _amount;
        transaction.txId.push(_txId);

        if(crowd.users == crowd.goal){
            closeFunding(_id);
        }

        emit ConfirmTransaction(_id, msg.sender, _txId, _amount); 
    }

    function closeFunding(uint _id)public onlyOwner{
        Goal storage crowd = crowdfundings[_id];
        require(crowd.users == crowd.goal, "some ants are missing");
        crowd.open = false;
        emit CloseFunding(_id);
    }

    /***************************************************************************
    ******************************* Advertisment *****************************
    ****************************************************************************/

    uint bannerCount;
    
    struct Banner{
       string url;
       address user;
       string txId;
    }

    mapping(uint => Banner) public advertisement;
    event Ads( uint id, string url, address indexed user, string txId); 

    function addBanner(string memory _url, address _user, string memory _txId ) external onlyOwner {

        bannerCount += 1;
        advertisement[bannerCount] = Banner({ url: _url, user: _user, txId: _txId  });
        
        emit Ads(bannerCount, _url, _user, _txId); 
    }

}