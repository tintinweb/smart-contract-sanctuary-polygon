/**
 *Submitted for verification at polygonscan.com on 2023-03-10
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

////////////////////////////////////////////////////////////////////////////////
contract    Token
{
    //----- VARIABLES

    address private             owner;          // Owner of this contract
    address public              admin;          // The one who is allowed to do changes

    mapping(address => uint256)                         balances;       // Maintain balance in a mapping
    mapping(address => mapping (address => uint256))    allowances;     // Allowances index-1 = Owner account   index-2 = spender account

    //------ TOKEN SPECIFICATION

    string  private  constant    _name     = "SDC Token";   
    string  private  constant    _symbol   = "SDC";
    uint256 private  constant    _decimals = 6;

    uint256 private              _totalSupply = 100000000000 * 10**_decimals;        // 100 Billions token with 18 decimals precision

    //---------------------------------------------------- smartcontract control

    uint256 public              icoDeadLine = 0;     // 2000-01-01 00:00 (GMT+0)

    //--------------------------------------------------------------------------

    modifier duringIcoOnlyTheOwner()  // if not during the ico : everyone is allowed at anytime
    {
        require( block.timestamp > icoDeadLine || msg.sender==owner );
        _;
    }

    modifier onlyOwner()            { require(msg.sender==owner);           _; }
    modifier onlyAdmin()            { require(msg.sender==admin);           _; }

    //----- EVENTS

    event Transfer(address indexed fromAddr, address indexed toAddr,   uint256 amount);
    event Approval(address indexed _owner,   address indexed _spender, uint256 amount);

            //---- extra EVENTS

    event onAdminUserChanged(   address oldAdmin,  address newAdmin);
    event onOwnershipTransfered(address oldOwner,  address newOwner);
    event onAdminUserChange(    address oldAdmin,  address newAdmin);

    event onIcoDeadlineChanged( uint256 previousDeadline,  uint256 newDeadline);

    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    constructor() 
    {
        owner = msg.sender;
        admin = owner;

        balances[owner] = _totalSupply;
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //----- IBEP20 FUNCTIONS
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function    totalSupply()   external view returns (uint256)         { return _totalSupply;      }
    //--------------------------------------------------------------------------
    function    decimals()      external pure returns (uint8)           { return uint8(_decimals);  }
    //--------------------------------------------------------------------------
    function    symbol()        external pure returns (string memory)   { return _symbol;           }
    //--------------------------------------------------------------------------
    function    name()          external pure returns (string memory)   { return _name;             }
    //--------------------------------------------------------------------------
    function    getOwner()      external view returns (address)         { return owner;             }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //----- ERC20 FUNCTIONS
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function balanceOf(address walletAddress) public view returns (uint256 balance)
    {
        return balances[walletAddress];
    }
    //--------------------------------------------------------------------------
    function transfer(address toAddr, uint256 amountInWei)  public   duringIcoOnlyTheOwner   returns (bool)     // don't icoNotPaused here. It's a logic issue.
    {
        require(toAddr!=address(0x0), 'Transfer cannot be done to Address ZERO');
        require(toAddr!=msg.sender,   "Can't transfer to yourself");
        require(amountInWei>0,        "Amount must be above ZERO");     // Prevent transfer to 0x0 address and to self, amount must be >0

        uint256 balanceFrom = balances[msg.sender] - amountInWei;
        uint256 balanceTo   = balances[toAddr]     + amountInWei;
       
        assert(balanceFrom <= balances[msg.sender]);
        assert(balanceTo   >= balances[toAddr]);
       
        balances[msg.sender] = balanceFrom;
        balances[toAddr]     = balanceTo;

        emit Transfer(msg.sender, toAddr, amountInWei);

        return true;
    }
    //--------------------------------------------------------------------------
    function    allowance(address walletAddress, address spender) public view returns (uint remaining)
    {
        return allowances[walletAddress][spender];
    }
    //--------------------------------------------------------------------------
    function    transferFrom(address fromAddr, address toAddr, uint256 amountInWei)  public  returns (bool)
    {
        require(amountInWei!=0,                                  'Amount must be non-Zero');
        require(balances[fromAddr]               >= amountInWei, 'Amount is greater than available Balance');
        require(allowances[fromAddr][msg.sender] >= amountInWei, 'Amount is greater than allowed amount');

        uint256 balanceFrom  = balances[fromAddr]               - amountInWei;
        uint256 balanceTo    = balances[toAddr]                 + amountInWei;
        uint256 newAllowance = allowances[fromAddr][msg.sender] - amountInWei;

        assert(balanceFrom  <= balances[fromAddr]);
        assert(balanceTo    >= balances[toAddr]);
        assert(newAllowance <= allowances[fromAddr][msg.sender]);

        balances[fromAddr]               = balanceFrom;
        balances[toAddr]                 = balanceTo;
        allowances[fromAddr][msg.sender] = newAllowance;

        emit Transfer(fromAddr, toAddr, amountInWei);
        return true;
    }
    //--------------------------------------------------------------------------
    function    approve(address spender, uint256 amountInWei) public returns (bool)
    {
        require((amountInWei == 0) || (allowances[msg.sender][spender] == 0), "Cannot approved zero amount or zero allowance detected");
       
        allowances[msg.sender][spender] = amountInWei;
        emit Approval(msg.sender, spender, amountInWei);

        return true;
    }
    //--------------------------------------------------------------------------
    fallback() external payable
    {
        assert(true == false);      // If Ether is sent to this address, don't handle it -> send it back.
    }
    receive() external payable 
    {
        assert(true == false);      // If Ether is sent to this address, don't handle it -> send it back.
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    function mint(uint256 amountToMintInWei) public onlyAdmin  returns(uint)
    {
        require(msg.sender==owner, "Only owner can add tokens");

        uint256     newOwnerBalance = balances[owner] + amountToMintInWei;
        uint256     newTotalSupply  = _totalSupply    + amountToMintInWei;

        assert(newOwnerBalance >= _totalSupply);
        assert(newTotalSupply  >= _totalSupply);

        balances[owner] = balances[owner] + amountToMintInWei;

        emit Transfer(msg.sender, owner, amountToMintInWei);

        _totalSupply = _totalSupply + amountToMintInWei;

        return 1;
    }
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
    //--------------------------------------------------------------------------
}