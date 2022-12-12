/**
 *Submitted for verification at polygonscan.com on 2022-12-12
*/

pragma solidity ^0.5.4;
    
    interface TRC20 {
      function totalSupply() external view returns (uint256);
      function balanceOf(address who) external view returns (uint256);
      function allowance(address owner, address spender) external view returns (uint256);
      function transfer(address to, uint256 value) external returns (bool);
      function approve(address spender, uint256 value) external returns (bool);
      
      function transferFrom(address from, address to, uint256 value) external returns (bool);
      function burn(uint256 value) external returns (bool);
      function burnFrom(address _from, uint256 _value) external returns (bool success);
      event Transfer(address indexed from,address indexed to,uint256 value);
      event Approval(address indexed owner,address indexed spender,uint256 value);
      event Burn(address indexed from, uint256 value);
                
    }
    
    contract TMT {
        uint256 public latestReferrerCode;
        uint256 public usd_token_price;
        uint256 public trx_token_price;
        address payable private adminAccount_;
     

        mapping(address => mapping(uint8 => bool)) public activeLevel;
        event Registration(string waddress,address investor,uint256 investorId,address referrer,uint256 referrerId,uint256 amount,uint256 amt_tkn,uint256 amt_usd);
        event Reinvest(address investor,uint256 amount,uint256 amt_tkn,uint256 amt_usd);
        event TokenDistribution(address indexed sender, address indexed receiver, uint total_token, uint _amount);
        
        TRC20 private _token; 
        uint public  total_token_buy = 0;
        constructor(address payable _admin , TRC20 _usdtToken) public {
            _token = _usdtToken;
            adminAccount_=_admin;
            latestReferrerCode++;
        }
        
    function buyToken(uint256 tokenQty) public payable
	{
	    tokenQty=tokenQty/1e8;
        uint256 buy_amt = tokenQty*trx_token_price;
	    require(!isContract(msg.sender),"Can not be contract");
	    require(msg.value>=buy_amt, " Invalid amount");
	    _token.transfer(msg.sender,tokenQty);
	     
         total_token_buy=total_token_buy+tokenQty;
		 emit TokenDistribution( address(this), msg.sender, tokenQty,msg.value);					
	 }
	 
	 function sellToken(uint256 tokenQty) public payable
	{
	     require(!isContract(msg.sender),"Can not be contract");
	     _token.transferFrom(msg.sender ,address(this), (tokenQty));
	     tokenQty=tokenQty/1e8;
	     uint256 trx_amt=tokenQty*trx_token_price;
	     msg.sender.transfer(trx_amt);
		 emit TokenDistribution(address(this), msg.sender, tokenQty, trx_amt);					
	 }

    function setTokenPrice(uint256 trx_price, uint256 usd_price) public payable
    {
           require(msg.sender==adminAccount_,"Only Owner");
              trx_token_price = trx_price;
              usd_token_price = usd_price;
    }
        function setAdminAccount(address payable _newAccount) public  {
            require(_newAccount != address(0) && msg.sender==adminAccount_);
            adminAccount_ = _newAccount;
        }
        
        function withdrawLostFromBalance(address payable _sender,uint256 _amt) public {
            require(msg.sender == adminAccount_, "onlyOwner");
            _sender.transfer(_amt*1e8);
        }
    
        function multisend(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
            require(msg.sender==adminAccount_,"Only Owner");
            uint256 i = 0;
            for (i; i < _contributors.length; i++) {
                _contributors[i].transfer(_balances[i]);
                
            }
        }
    
        function multisendtoken(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
            require(msg.sender==adminAccount_,"Only Owner");
            uint256 i = 0;
            for (i; i < _contributors.length; i++) {
                _token.transfer(msg.sender,_balances[i]);
            }
        }
    
        function Register(string memory _user,uint256 _referrerCode,address refferAddress, uint256 _amt) public payable
        {
            require(_amt<1, "Invalid Amount.");
            latestReferrerCode++;
            _amt=_amt/1e8;
            uint256 usdAmt=(_amt*usd_token_price);
            require(usdAmt>=25e8,"Less Amount");
            _token.transferFrom(msg.sender,adminAccount_, _amt*1e8);
            emit Registration(_user,msg.sender,latestReferrerCode,refferAddress,_referrerCode,0,_amt,usdAmt);
        }
        
        function reinvest(uint256 _amt) public payable
        {
                require(_amt<1, "Invalid Amount.");
                _amt=_amt/1e8;
                uint256 usdAmt=(_amt*usd_token_price);
                require(usdAmt>=25e8,"Less Amount");
                _token.transferFrom(msg.sender,adminAccount_, _amt*1e8);
                emit Reinvest(msg.sender,0,_amt,usdAmt);
        }
        
        

        function isContract(address _address) public view returns (bool _isContract)
        {
            uint32 size;
            assembly {
               size := extcodesize(_address)
            }
              return (size > 0);
        } 
    }