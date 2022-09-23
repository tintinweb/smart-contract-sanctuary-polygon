/**
 *Submitted for verification at polygonscan.com on 2022-09-23
*/

//SPDX-License-Identifier:MIT

pragma solidity ^0.8.13;

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// LIBRARIES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// SAFEMATH its a Openzeppelin Lib. Check out for more info @ https://docs.openzeppelin.com/contracts/2.x/api/math
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INTERFACES
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IAFTCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IAFTController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);
    function _getNFM() external pure returns (address);
    function _getDaoYield() external pure returns (address);
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// INFMCONTROLLER
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface INfmController {
    function _checkWLSC(address Controller, address Client)
        external
        pure
        returns (bool);
}
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
// IDAOYIELD
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
interface IDaoYield {
    function _trackingBlocker()
        external
        pure
        returns (uint256);
}


//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
/// @title AFT.sol
/// @author Fernando Viktor Seidl E-mail: [email protected]
/// @notice ERC20 Token Standard Contract with special extensions in the "_transfer" functionality for the Governance *** AFT ERC20 TOKEN ***
/// @dev This ERC20 contract includes all functionalities of an ERC20 standard. The only difference to the standard are the built-in
///            extensions in the _transfer function.
///            TOKEN DETAILS:
///            -    Inicial total supply 0 AFT
///            -    Final total supply 1,000,000 AFT
///            -    Token Decimals 0
///            -    Token uniqueness _NumOnToken
///            -    Token Name: Arthena
///            -    Token Symbol: AFT
///
///            TOKEN USE CASE:
///            -    The principal application of the AFT token is the creation of value and Governance. 
///            -    The token can be viewed as an auto-generating yield token with a Governance voting implementation, the AFT receives a share
///                 of the overall projects income and has a 60% voting power on Governance.
//------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
contract AFT {
    //include SafeMath
    using SafeMath for uint256;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    STANDARD ERC20 MAPPINGS:
    _balances(owner address, aft amount) ONLY 1 AFT ALLOWED ON ADDRESS
    _allowances(owner address, spender address, AFT amount)
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    mapping(address => uint256) public _balances;
    mapping(address => mapping(address => uint256)) public _allowances;
    mapping(address => uint256) private _BonusTracker;
    mapping(address => uint256) public _CoinIndex;
    mapping(uint256 => uint256) public _OTMap;
    mapping(address => mapping(uint256 => uint256)) public _NumOnToken;
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    CONTRACT EVENTS
    STANDARD ERC20 EVENTS:
    Transfer(sender, receiver, amount);
    Approval(owner, spender, amount);
    SPECIAL EVENT:
    Mint(sender, receiver, BurningFee, Timestamp
    );
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Mint(
        address indexed minter,
        uint256 IndexRef
    );

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    ERC20 STANDARD ATTRIBUTES
    _TokenName           => Name of the Token (Nftismus)
    _TokenSymbol         => Symbol of the Token (NFM)
    _TokenDecimals      =>  Precision of the Token (18 Decimals)
    _TotalSupply            =>  Total Amount of Tokens (Inicial 400 Million NFM)
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    string private _TokenName;
    string private _TokenSymbol;
    uint256 private _TokenDecimals;
    uint256 private _TotalSupply;
    uint256 private _TIndexer;
    uint256 public _OTRefCounter;
    /*
    CONTROLLER
    OWNER = MSG.SENDER ownership will be handed over to dao
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    address private _Owner;
    IAFTController public _Controller;
    address private _SController;

    constructor(
        string memory TokenName,
        string memory TokenSymbol,
        address Controller
    ) {
        _TokenName = TokenName;
        _TokenSymbol = TokenSymbol;
        _TokenDecimals = 0;
        _TotalSupply = 0;
        _TIndexer = 0;
        _Owner = msg.sender;
        _SController = Controller;
        IAFTController Cont = IAFTController(Controller);
        _Controller = Cont;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @name() returns (string);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function name() public view returns (string memory) {
        return _TokenName;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @symbol() returns (string);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function symbol() public view returns (string memory) {
        return _TokenSymbol;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @decimals() returns (uint256);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function decimals() public view returns (uint256) {
        return _TokenDecimals;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @totalSupply() returns (uint256);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function totalSupply() public view returns (uint256) {
        return _TotalSupply;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @balanceOf(address account) returns (uint256);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @bonusCheck(address account) returns (uint256);
    Special Function for Bonus Extension
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function bonusCheck(address account) public view returns (uint256) {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                msg.sender == _Owner,
            "oO"
        );
        return _BonusTracker[account];
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_returnTokenReference(address account) returns (uint256, uint256);
    Special Function for Bonus Extension
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _returnTokenReference(address account) public view returns (uint256,uint256) {
        require(
            _Controller._checkWLSC(_SController, msg.sender) == true ||
                msg.sender == _Owner,
            "oO"
        );
        return (_CoinIndex[account], _NumOnToken[account][_CoinIndex[account]]);
    }
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @allowance(address owner, address spender) returns (uint256);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @transfer(address to, uint256 amount)  returns (bool);
    Strandard ERC20 Function 
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function transfer(address to, uint256 amount) public returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @transferFrom(address from, address to, uint256 amount)   returns (bool);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_transfer(address from, address to, uint256 amount)  returns (bool);
    Strandard ERC20 Function with implemented Extensions and ReentrancyGuard as safety mechanism
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "0A");
        require(to != address(0), "0A");
        uint256 fromBalance = _balances[from];
        uint256 toBalance = _balances[to];
        require(fromBalance > 0, "<B");
        //Check if Receiver is Contract
        if(_Controller._checkWLSC(_SController, to)==true){
            uint256 CInd=_CoinIndex[from];
            uint256 RNum=_NumOnToken[from][CInd];
            unchecked {
                _balances[from] = SafeMath.sub(fromBalance, amount);
                _NumOnToken[from][CInd] = 0;
                _CoinIndex[from] = 0;
            }
            if (
                block.timestamp <
                IDaoYield(address(_Controller._getDaoYield()))._trackingBlocker()                
            ) {
                _BonusTracker[to] = _balances[to] + amount;
                _BonusTracker[from] = _balances[from];
            }
            _balances[to] += amount;
            _OTRefCounter++;
            _OTMap[_OTRefCounter]=RNum;
            emit Transfer(from, to, amount);
        //Check if Sender is Contract
        }else if(_Controller._checkWLSC(_SController, from)==true){
            _TIndexer++;
            uint256 CInd=_TIndexer;
            uint256 RNum=_OTMap[_OTRefCounter];
            unchecked {
                _balances[from] = SafeMath.sub(fromBalance, amount);
            }
            if (
                block.timestamp <
                IDaoYield(address(_Controller._getDaoYield()))._trackingBlocker()                
            ) {
                _BonusTracker[to] = _balances[to] + amount;
                _BonusTracker[from] = _balances[from];
            }
            _balances[to] += amount;
            _CoinIndex[to] = CInd;
            _NumOnToken[to][CInd]=RNum;
            _OTRefCounter--;
            emit Transfer(from, to, amount);
        //If NO Contract in Addresses, then handle as Transfer between Wallets
        }else{
            uint256 CInd=_CoinIndex[from];
            uint256 RNum=_NumOnToken[from][CInd];
            require(toBalance == 0, "EE");
            unchecked {
                _balances[from] = SafeMath.sub(fromBalance, amount);
                _NumOnToken[from][CInd]=0;
                _CoinIndex[from] = 0;

            }
            if (
                block.timestamp <
                IDaoYield(address(_Controller._getDaoYield()))._trackingBlocker()                
            ) {
                _BonusTracker[to] = _balances[to] + amount;
                _BonusTracker[from] = _balances[from];
            }

            _balances[to] += amount;
            _CoinIndex[to] = CInd;
            _NumOnToken[to][CInd]=RNum;

            emit Transfer(from, to, amount);
        }                    
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_spendAllowance(address owner, address spender, uint256 amount);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "<A");
            unchecked {
                _approve(
                    owner,
                    spender,
                    SafeMath.sub(currentAllowance, amount)
                );
            }
        }
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_approve(address owner, address spender, uint256 amount);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "0A");
        require(spender != address(0), "0A");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @approve(address spender, uint256 amount) return (bool);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @increaseAllowance(address spender, uint256 amount) return (bool);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        _approve(
            owner,
            spender,
            SafeMath.add(allowance(owner, spender), addedValue)
        );
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @decreaseAllowance(address spender, uint256 amount) return (bool);
    Strandard ERC20 Function
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "_D");
        unchecked {
            _approve(
                owner,
                spender,
                SafeMath.sub(currentAllowance, subtractedValue)
            );
        }
        return true;
    }

    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /*
    @_mint(address to, uint256 amount);
    Strandard ERC20 Function has been modified for the protocol
     */
    //------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _mint(address to) public returns (bool) {
        require(msg.sender != address(0), "0A");
        require(to != address(0), "0A");
        require(_Controller._checkWLSC(_SController, msg.sender) == true, "oO");
        require(_TotalSupply + 1 <= 1000000,'TSL');
        _TotalSupply += 1;
        _balances[to] += 1;
        _TIndexer++;
        _CoinIndex[to] = _TIndexer;
        _NumOnToken[to][_TIndexer] = block.timestamp+_TotalSupply;
        _BonusTracker[to] = _balances[to];
        emit Transfer(address(0), to, 1);
        emit Mint(to, _NumOnToken[to][_TIndexer]);
        return true;
    }
}