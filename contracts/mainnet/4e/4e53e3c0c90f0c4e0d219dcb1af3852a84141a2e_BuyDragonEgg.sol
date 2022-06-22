/**
 *Submitted for verification at polygonscan.com on 2022-06-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;


abstract contract OwnableMulti {
    mapping(address => bool) private _owners;

 
    constructor() {
        _owners[msg.sender] = true;
    }


    function isOwner(address _address) public view virtual returns (bool) {
        return _owners[_address];
    }

  
    modifier onlyOwner() {
        require(_owners[msg.sender], "Ownable: caller is not an owner");
        _;
    }

    function addOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        _owners[_newOwner] = true;
    }
}




interface IERC20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}




contract DragonEgg is OwnableMulti {
    uint256 private _issuedSupply;
    uint256 private _outstandingSupply;
    uint256 private _decimals;
    string private _symbol;

  

    mapping(address => uint256) private _balances;
    event Issued(address account, uint256 amount);
    

    constructor(string memory __symbol, uint256 __decimals) {
        _symbol = __symbol;
        _decimals = __decimals;
        _issuedSupply = 0;
        _outstandingSupply = 0;
    }

   
    function issue(address account, uint256 amount) public onlyOwner {
        require(account != address(0), "zero address");
        _issuedSupply = _issuedSupply + amount;
        _outstandingSupply = _outstandingSupply + amount;
        _balances[account] = _balances[account] + amount;
        emit Issued(account, amount);
    }


    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint256) {
        return _decimals;
    }

    function issuedSupply() public view returns (uint256) {
        return _issuedSupply;
    }

    function outstandingSupply() public view returns (uint256) {
        return _outstandingSupply;
    }
}



contract BuyDragonEgg {

  
    string public Version = "22/06/2022";

    address public investToken;

    address public treasury;

    DragonEgg public egg;
 
    uint256 public totalraised;

    uint256 public totalissued;
 
    uint256 public startTime;
 
    uint256 public duration;

    uint256 public endTime;

    bool public saleEnabled;
	bool public isExtended;

    uint256 public mininvest;
    uint256 public maxinvest;
    uint256 public numWhitelisted = 0;
    uint256 public numInvested = 0;

    event SaleEnabled(bool enabled, uint256 time);

    event DragonEggPruchased(address investor, uint256 amount);

    event Redeem(address investor, uint256 amount);

    struct InvestorInfo {
        uint256 amountInvested; 
        bool claimed; 
    }
    
 
    mapping(address => bool) public whitelisted;

    mapping(address => InvestorInfo) public investorInfoMap;

       modifier onlyTeam() {
        require(isOwner[msg.sender], "Request Not From A Team Member");
        _;
    }

    mapping(address => bool) public isOwner;

    address[] public whitelists;

    constructor(
        address _investToken,
        uint256 _minInvest,
        uint256 _maxinvest,
        address _treasury
    ) {

        investToken = _investToken;
        mininvest = _minInvest;
        maxinvest = _maxinvest;
        treasury = _treasury;
        egg = new DragonEgg("mdw", 18);
        saleEnabled = false;
		isExtended = false;
        isOwner[msg.sender] = true;
  
    }

   function getWhitelists() public view returns (address[] memory) {
        return whitelists;
    }

    function addTeamMember(address _address)  external onlyTeam{
     isOwner[_address] = true;
    }

    function removeTeamMember(address _address)  external onlyTeam{
     isOwner[_address] = false;

    }
   
    function updateStartTime(  
         uint256 _startTime,
         uint256 _duration) external onlyTeam {
         startTime = _startTime;
         duration = _duration;
         require(duration < 8 days, "duration too long");
         endTime = startTime + duration;
    }


    function addWhitelist(address _address) external onlyTeam {
        require(!whitelisted[_address], "already whitelisted");
        if(!whitelisted[_address])
            numWhitelisted = numWhitelisted + 1;
        whitelisted[_address] = true;
    }


    function removeWhitelist(address _address) external onlyTeam {
       InvestorInfo storage investor = investorInfoMap[_address];
       require( investor.amountInvested == 0, "Already Entered Whitelist");
       whitelisted[_address] = false;
    }

  

   function DragonEggPurchase(uint256 investAmount) public {

        require(block.timestamp >= startTime, "Whitelist Event Not Yet Started!");
        require(endTime >= block.timestamp, "Whitelist Event Ended.");
        require(saleEnabled, "Purchase Disabled");
        require(whitelisted[msg.sender] == true, 'sender is not whitelisted');
        require(investAmount >= mininvest && investAmount <= maxinvest , "Not a Valid Amount To Invest");
        InvestorInfo storage investor = investorInfoMap[msg.sender];
        require(investor.amountInvested == 0, "Already Participated In the Whitelist");
        require(
            investAmount == 100000000 
         || investAmount == 200000000
         || investAmount == 300000000 
         || investAmount == 400000000
         || investAmount == 500000000 
         || investAmount == 600000000 
         || investAmount == 700000000 
         || investAmount == 800000000 
         || investAmount == 900000000 
         || investAmount == 1000000000 
         || investAmount == 1100000000 
         || investAmount == 1200000000 
         || investAmount == 1300000000 
           ,"Invalid Amount Range From $100 to $1300" );

        whitelists.push(msg.sender);
        uint256 issueAmount = investAmount * 1000000000000;
        totalraised = totalraised + investAmount;
        totalissued =  totalissued + issueAmount;
        egg.issue(msg.sender, issueAmount);

        if (investor.amountInvested == 0){
            numInvested = numInvested + 1;
        }
        
        investor.amountInvested = investor.amountInvested + investAmount;
        require(
            IERC20(investToken).transferFrom(
                msg.sender, 
                treasury,
                investAmount
            ),
            "Amount Transfer To Treasury Failed!"
        ); 
        emit DragonEggPruchased(msg.sender, investAmount);
    }


 
    function setstartTime(uint256 _startTime) public onlyTeam {
        require(block.timestamp <= startTime, "too late, sale has started");
        require(!saleEnabled, "sale has already started");
        startTime = _startTime;
        endTime = _startTime + duration;
    }



    function toggleSale() public onlyTeam {
        if(block.timestamp > endTime ) {
            saleEnabled = false;
            emit SaleEnabled(false, block.timestamp);
        } else {
            saleEnabled = true;
            emit SaleEnabled(true, block.timestamp);
        }
    }


	function extendSale() public onlyTeam {
		require(!isExtended, 'cannot extend a second time');
		isExtended = true;
		endTime = endTime + 86400;
	}
}