/**
 *Submitted for verification at polygonscan.com on 2023-06-20
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: chain.sol


pragma solidity ^0.8.0;


interface IBEP20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}
contract CHAINMLM{
    address public owner;
    uint public apy;
    uint public level1;
    uint public level2to6;
    uint public level7;
    IBEP20 contractToken;
    IBEP20 NativeContractToken;
    uint NativeTokenPrice;
    uint fundraised;
    using Counters for Counters.Counter;
    Counters.Counter private  PackageId;
    Counters.Counter private  StackingId;

    struct User{
       string  email;
       address sponsor_address;
       address second_level;
       address third_level;
       address fourth_level;
       address fifth_level;
       address six_level;
       address seventh_level;
       //uint time;
       address myAddress;
       uint amountofPurchase;
       uint downline;
       uint myearning;
       //uint numberofPackagePurchased;
    }
     struct Package{
        string name;
        uint id;
        uint price;
        uint NumberofAddress;
    }
    struct Staking {
        uint id;
        uint amount;
        uint start_time;
        uint end_time;
        uint APY;
        uint Price;
        bool complete;
        uint withdraw_time;
        uint month;
        uint earningwithdraw;
        address useraddress;
        uint PackageId;
    }

    mapping(address => User) public UserMaping;
    mapping(string => bool) public userNameExist;
    mapping(address => address[]) public  userDownline;
    //mapping(address => address[]) public  userDownline2;
    //mapping(address => address[]) public userDownline3;
   // mapping(address => address[]) public userDownline4;
   // mapping(address => address[]) public userDownline5;
    //mapping(address => address[]) public userDownline6;
   // mapping(address => address[]) public userDownline7;
    mapping (string => address) public useremail;
    mapping (address => bool) public superStockiestUser;
    mapping (address => bool) public StockiestUser;
    mapping (address => mapping(address =>uint)) public earningFromDowlineUser;
    mapping (address => uint[]) public listofpackage;
    mapping (uint => Package) public PackageMapping;
   // mapping(uint =>Staking) public StackingMapping;
    mapping (address => uint[]) public userstackinglist;
    mapping (address => mapping(uint => Staking))  StackingMapping;
    mapping (address => uint) public TimeOfregistration;


    constructor(address _contractToken,address _NativeContractToken,uint _NativeTokenPrice,string memory _email){
        owner =msg.sender;
        contractToken= IBEP20(_contractToken);
        NativeContractToken = IBEP20(_NativeContractToken);
        NativeTokenPrice = _NativeTokenPrice;
         UserMaping[msg.sender] = User ({
         email: _email,
         sponsor_address: msg.sender,
         second_level: msg.sender,
         third_level: msg.sender,
         fourth_level : msg.sender,
         fifth_level: msg.sender,
         six_level : msg.sender,
         seventh_level: msg.sender,
         myAddress: msg.sender,
         amountofPurchase:0,
         downline:0,
         myearning:0
         });
         level1 = 5;
         level2to6 = 4;
         level7 = 4;
          userNameExist[_email] = true;
         useremail[_email] = msg.sender;
         apy = 3;
         TimeOfregistration[msg.sender]=block.timestamp;

    }

    function setLevel1(uint _level1) public {
        require(msg.sender == owner,"Not an Owner");
        level1 = _level1;
    }
    function setLevel2to6(uint _level2) public {
        require(msg.sender == owner,"Not an Owner");
        level2to6 = _level2;
    }
    function setLevel7(uint _level3) public {
        require(msg.sender == owner,"Not an Owner");
        level7 = _level3;
    }
    function setNativeTokenPrice(uint _NativeTokenPrice) public {
        require(msg.sender == owner,"Not an Owner");
        NativeTokenPrice= _NativeTokenPrice;
    }
     function setOwner(address _owner) public {
     require (msg.sender == owner,"Not an Owner");
     owner = _owner;
     string memory OWNER;
     UserMaping[_owner] = User ({
         email: OWNER,
         sponsor_address: _owner,
         second_level: _owner,
         third_level: _owner,
         fourth_level : msg.sender,
         fifth_level: msg.sender,
         six_level : msg.sender,
         seventh_level: msg.sender,
         myAddress: msg.sender,
         amountofPurchase:0,
         downline:0,
         myearning:0
     });
     TimeOfregistration[msg.sender]=block.timestamp;
     useremail[OWNER] = msg.sender;
     }
     function doesUserExist (address username) public view returns(bool) {
        return UserMaping[username].myAddress != address(0);
    }
    function getdownline(address user) public view returns (User [] memory){
       uint length1 = userDownline[user].length;
       User[] memory users = new User[](length1);
       for (uint i=0; i<length1; i++){
           //string memory userEmail = useremail[userDownline[user][i]];
           users[i] = UserMaping[userDownline[user][i]];
       }
       return (users);
   }
    function withdraw(uint amount) public{
       require(msg.sender == owner,"Not an Owner");
       NativeContractToken.transfer(owner, amount);
    }
     function createPackage(string memory _name,uint _price, uint _numberofaddress) public{
        require (msg.sender == owner,"Not an Owner");
        PackageId.increment();
         uint newPackageId = PackageId.current();
        Package memory packages = Package({
           name: _name,
           id : newPackageId,
           price: _price,
           NumberofAddress: _numberofaddress
        });
        PackageMapping[newPackageId] = packages;
    }
    function registration (string memory _username, string memory sponsor_EMAIL) public{
     require(userNameExist[_username] == false, "Sorry, The email is already a user");
     address sponsor_address = useremail[sponsor_EMAIL];
     require(doesUserExist(sponsor_address) == true, "Sponsor is not a Registered User" );
     require(doesUserExist(msg.sender) == false, "User is a Registered User" );
     address second_line = UserMaping[sponsor_address].sponsor_address;
     address thirl_line = UserMaping[second_line].sponsor_address;
     address fourth_line = UserMaping[thirl_line].sponsor_address;
     address fiveth_line = UserMaping[fourth_line].sponsor_address;
     address sixth_line = UserMaping[fiveth_line].sponsor_address;
     address seventh_line = UserMaping[sixth_line].sponsor_address;
     UserMaping[msg.sender] = User({
         email: _username,
         sponsor_address: sponsor_address,
         second_level: second_line,
         third_level: thirl_line,
         fourth_level : fourth_line,
         fifth_level: fiveth_line,
         six_level : sixth_line,
         seventh_level: seventh_line,
         myAddress: msg.sender,
         amountofPurchase:0,
         downline:0,
         myearning:0
           });
      userNameExist[_username] = true;
      userDownline[sponsor_address].push(msg.sender);
      //userDownline2[second_line].push(msg.sender);
      //userDownline3[thirl_line].push(msg.sender);
      useremail[_username] = msg.sender;
      UserMaping[sponsor_address].downline +=1;
      TimeOfregistration[msg.sender]=block.timestamp;
 }
 function paysponsorlevel(address user,uint id) private {
     uint _amount = PackageMapping[id].price;
        uint Tamount = NativeTokenPrice*_amount;
        uint sponrAmt = (level1*Tamount)/100;
        address sponsor= UserMaping[user].sponsor_address;
         NativeContractToken.transfer(sponsor, sponrAmt);
          UserMaping[sponsor].myearning+=sponrAmt;
          earningFromDowlineUser[user][sponsor]+=sponrAmt;

 }
 function pay2level(address user,uint id) private {
     uint _amount = PackageMapping[id].price;
        uint Tamount = NativeTokenPrice*_amount;
        uint sponrAmt = (level1*Tamount)/100;
        address sponsor= UserMaping[user].second_level;
         uint length = userDownline[sponsor].length;
         
          if(length>1){
          NativeContractToken.transfer(sponsor, sponrAmt);
          UserMaping[sponsor].myearning+=sponrAmt;
          earningFromDowlineUser[user][sponsor]+=sponrAmt;}

 }
 function pay3level(address user,uint id) private {
     uint _amount = PackageMapping[id].price;
        uint Tamount = NativeTokenPrice*_amount;
        uint sponrAmt = (level2to6*Tamount)/100;
        address sponsor= UserMaping[user].third_level;
        uint length = userDownline[sponsor].length;
        if(length>2){ NativeContractToken.transfer(sponsor, sponrAmt);
        UserMaping[sponsor].myearning+=sponrAmt;
        earningFromDowlineUser[user][sponsor]+=sponrAmt;}
 }
 function pay4level(address user,uint id) private {
     uint _amount = PackageMapping[id].price;
        uint Tamount = NativeTokenPrice*_amount;
        uint sponrAmt = (level2to6*Tamount)/100;
        address sponsor= UserMaping[user].fourth_level;
        uint length = userDownline[sponsor].length;
        if(length>3){ NativeContractToken.transfer(sponsor, sponrAmt);
         UserMaping[sponsor].myearning+=sponrAmt;
         earningFromDowlineUser[user][sponsor]+=sponrAmt;}
 }
 function pay5level(address user,uint id) private {
     uint _amount = PackageMapping[id].price;
        uint Tamount = NativeTokenPrice*_amount;
        uint sponrAmt = (level2to6*Tamount)/100;
        address sponsor= UserMaping[user].fifth_level;
        uint length = userDownline[sponsor].length;
        if(length>4){ NativeContractToken.transfer(sponsor, sponrAmt);
         UserMaping[sponsor].myearning+=sponrAmt;
         earningFromDowlineUser[user][sponsor]+=sponrAmt;}
 }
 function pay6level(address user,uint id) private {
     uint _amount = PackageMapping[id].price;
        uint Tamount = NativeTokenPrice*_amount;
        uint sponrAmt = (level2to6*Tamount)/100;
        address sponsor= UserMaping[user].six_level;
        uint length = userDownline[sponsor].length;
        if(length>5){ NativeContractToken.transfer(sponsor, sponrAmt);
         UserMaping[sponsor].myearning+=sponrAmt;
         earningFromDowlineUser[user][sponsor]+=sponrAmt;}
 }
 function pay7level(address user,uint id) private {
     uint _amount = PackageMapping[id].price;
        uint Tamount = NativeTokenPrice*_amount;
        uint sponrAmt = (level7*Tamount)/100;
        address sponsor= UserMaping[user].seventh_level;
        uint length = userDownline[sponsor].length;
        if(length>6){ NativeContractToken.transfer(sponsor, sponrAmt);
         UserMaping[sponsor].myearning+=sponrAmt;
         earningFromDowlineUser[user][sponsor]+=sponrAmt;}
 }
 

 function purchasestaking(uint id) public {
         require(doesUserExist(msg.sender) == true, "User is not a Registered User" );
        uint _amount = PackageMapping[id].price;
        uint Tamount = NativeTokenPrice*_amount;
        contractToken.transferFrom(msg.sender, owner, _amount);
        pay7level(msg.sender, id);
        pay6level(msg.sender,id);
        pay5level(msg.sender,id);
        pay4level(msg.sender,id);
        pay3level(msg.sender,id);
        pay2level(msg.sender,id);
        paysponsorlevel(msg.sender,id);
        fundraised+=_amount;
        listofpackage[msg.sender].push(id);
        uint _endtime = (2629746 * 24)+ block.timestamp;
        StackingId.increment();
        uint newStackingId = StackingId.current();
        Staking memory staking = Staking({
        id: newStackingId,
        amount: Tamount,
        start_time : block.timestamp,
        end_time : _endtime,
        APY: apy,
        Price: NativeTokenPrice,
        complete : false,
        withdraw_time: 0,
        month: 24,
        earningwithdraw:0,
        useraddress: msg.sender,
        PackageId: id
    });
    StackingMapping[msg.sender][newStackingId] = staking;
    userstackinglist[msg.sender].push(newStackingId);
    }
function getearning(uint id, address user) public view returns (uint ){
        uint Now = block.timestamp;
        uint end = StackingMapping[user][id].end_time;
        uint start = StackingMapping[user][id].start_time;
        uint with1 = StackingMapping[user][id].withdraw_time;
        uint _amountinUsd = StackingMapping[user][id].amount/NativeTokenPrice;
        uint _apy = StackingMapping[user][id].APY;
        uint withdra = StackingMapping[user][id].earningwithdraw;
        if (StackingMapping[user][id].complete== false){
        if (Now < end ){
         uint earning = (_amountinUsd*(Now - start)*_apy)/315360000000;
         uint amt= earning - withdra;
         return amt;
        }else {
             uint earning = (_amountinUsd*(end - start)*_apy)/315360000000;
              uint amt= earning - withdra;
             return amt;
         }}else{
             uint earning = (_amountinUsd*(with1 - start)*_apy)/315360000000;
              uint amt= earning - withdra;
             return amt;
         }


    }
    function listMystackingID() public view returns (Staking [] memory){
        uint LockcountItem = StackingId.current();
        uint activeTradeCount =0;
        uint current =0;
        for (uint i=0; i< LockcountItem; i++){
            if(StackingMapping[msg.sender][i+1].useraddress == msg.sender){
                activeTradeCount +=1;
        }
    }
     Staking[] memory items1 = new Staking[](activeTradeCount);
      for (uint i=0; i< LockcountItem; i++){
             if(StackingMapping[msg.sender][i+1].useraddress == msg.sender){
                uint currentId = StackingMapping[msg.sender][i+1].id;
                Staking storage currentItem = StackingMapping[msg.sender][currentId];
                items1[current] = currentItem;
                current +=1;
             }
        }
        return items1;
    }
        function WithdrawLock(uint id) public{
        require(StackingMapping[msg.sender][id].complete == false,"already complete");
       // uint Now = block.timestamp;
        uint end = StackingMapping[msg.sender][id].end_time;
        uint _amount = StackingMapping[msg.sender][id].amount;
        require (block.timestamp > end,"The stacking time yet get over" );
        NativeContractToken.transfer(msg.sender, _amount);
        StackingMapping[msg.sender][id].complete = true;
        StackingMapping[msg.sender][id].withdraw_time = block.timestamp;

    }
    function earningwithdraw(uint id , address user) public{
       uint Amount = getearning(id,user);
        NativeContractToken.transfer(msg.sender, Amount);    
        }

}