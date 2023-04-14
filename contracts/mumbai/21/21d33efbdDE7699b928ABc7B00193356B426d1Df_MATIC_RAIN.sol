/**
 *Submitted for verification at polygonscan.com on 2023-04-14
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-24
*/

/**
 *Submitted for verification at BscScan.com on 2022-05-20
*/

pragma solidity ^0.5.4;
    
    
    contract MATIC_RAIN {

        uint256 public latestReferrerCode;
        address payable private adminAccount_;
        mapping(uint256=>address) public idToAddress;
        mapping(address=>uint256) public addresstoUid;
        event Registration(string waddress,address investor,uint256 investorId,address referrer,uint256 referrerId,uint256 amount,uint256 amt_usd);
        event Reinvest(address investor,uint256 amount,uint256 amt_usd);
        
      
        constructor(address payable _admin) public {
            adminAccount_=_admin;
            latestReferrerCode++;
            idToAddress[latestReferrerCode]=msg.sender;
            addresstoUid[msg.sender]=latestReferrerCode;
        }
        
        function setAdminAccount(address payable _newAccount) public  {
            require(_newAccount != address(0) && msg.sender==adminAccount_);
            adminAccount_ = _newAccount;
        }
        
        function withdrawLostFromBalance(address payable _sender,uint256 _amt) public {
            require(msg.sender == adminAccount_, "onlyOwner");
            _sender.transfer(_amt*1e18);
        }
    
        function getBalance() public view returns (uint256) 
        {
            return address(this).balance;
        }
    
    
        function multisend(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
            require(msg.sender==adminAccount_,"Only Owner");
            uint256 i = 0;
            for (i; i < _contributors.length; i++) {
                _contributors[i].transfer(_balances[i]);
                
            }
        }
    
        
    
        function Register(string memory _user,uint256 _referrerCode, uint256 _amt) public payable
        {
            require(msg.value>0 ,"Invalid Amt");
            require(!isUserExists(msg.sender), "Already Exist.");
            require(addresstoUid[msg.sender]==0,"Invalid Amount");
            require(idToAddress[_referrerCode]!=address(0),"Invalid Referrer ID");
           
                latestReferrerCode++;
                idToAddress[latestReferrerCode]=msg.sender;
                addresstoUid[msg.sender]=latestReferrerCode;
                adminAccount_.transfer(address(this).balance);
                emit Registration(_user,msg.sender,latestReferrerCode,idToAddress[_referrerCode],_referrerCode,msg.value,0);
        }
        
        
        function reinvest(uint256 _amt) public payable
        {

            require(isUserExists(msg.sender), "User Not Exist.");
            require(msg.value>0, "Invalid Amt");

                idToAddress[latestReferrerCode]=msg.sender;
                addresstoUid[msg.sender]=latestReferrerCode;
               
                adminAccount_.transfer(address(this).balance);
                emit Reinvest(msg.sender,msg.value,0);
                
               
        }
        
        
         function isUserExists(address user) public view returns (bool) {
            return (addresstoUid[user] != 0);
        }
    
    }