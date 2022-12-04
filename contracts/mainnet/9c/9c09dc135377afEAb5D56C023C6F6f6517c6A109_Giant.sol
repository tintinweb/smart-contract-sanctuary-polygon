//Giant

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Ownable {
    address private _owner;

    event OwnershipRenounced(address indexed previousOwner);

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(_owner);
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_
    ) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

contract Giant is ERC20Detailed, Ownable {

    using SafeMath for uint256;

    event LogRebase(uint256 indexed _epoch_, uint256 _totalSupply_);

    uint256 private constant INITIAL_TOKEN_SUPPLY = 21 * 10**12 * 10**9; // 21 trillion x decimals 10**9
    uint256 private constant MAX_SUPPLY = 21 * 10**18 * 10**9; // 21 quintillion = 1_000_000x
    uint256 private constant TOTAL_REFLATIONS = type(uint256).max - (type(uint256).max % INITIAL_TOKEN_SUPPLY); //make highest round number for exact division.
    uint256 private _rebaseRate = 262887; //10x annual at quarter hourly
    uint8 private constant REBASE_DENOMINATOR = 9; //262_887 / 1_000_000_000
    uint256 private constant REBASE_PERIOD = 900; //in seconds. 900 15 minutes, 3600 1 hour
 
    modifier validRecipient(address _to_) {
        require(_to_ != address(0x0));
        _;
    }

    uint256 private _totalSupply; //has an override.
    uint256 private _baseReflator;
    bool private _autoRebase;

    uint256 public initRebaseTime;
    uint256 public lastRebaseTime;
    uint256 public lastAddLiquidityTime;

    mapping(address => uint256) private _baseBalances;
    mapping(address => mapping(address => uint256)) private _baseAllowances;
    mapping(address => bool) private _isRebaseExempt; 
    mapping(address => bool) private _isBlockListed;

    constructor(
        address _ops_,
        address _treasury_
        )
        ERC20Detailed("Galactic Inter Alliance Network Token", "GIANT", uint8(9))
        Ownable()
    {
        _totalSupply = INITIAL_TOKEN_SUPPLY;
        _baseBalances[_treasury_] = TOTAL_REFLATIONS; //send all tokens to treasury for distribution
        _baseReflator = TOTAL_REFLATIONS.div(_totalSupply); //set initial reflator
        initRebaseTime = block.timestamp;
        lastRebaseTime = block.timestamp;
        _autoRebase = true;

        emit Transfer(address(0x0), _treasury_, _totalSupply);
        _transferOwnership(_ops_);
    }

    //from sender account
    function transfer(address _recipient_, uint256 _value_)
        external
        override
        validRecipient(_recipient_)
        returns (bool)
    {
        _transferFrom(msg.sender, _recipient_, _value_);
        return true;
    }

    function transferFrom(
        address _sender_,
        address _recipient_,
        uint256 _amount_
    ) external override validRecipient(_recipient_) returns (bool) {
        
        //SafeMath has revert in .sub if not sufficient.          
        _baseAllowances[_sender_][msg.sender] = _baseAllowances[_sender_][msg.sender].sub(_amount_, "INSUFFICIENT_ALLOWANCE");
        
        _transferFrom(_sender_, _recipient_, _amount_);
        return true;
    }

    function _basicTransfer(
        address _sender_,
        address _recipient_,
        uint256 _amount_
    ) internal returns (bool) {        
        //if _sender_ or receiver is exempt (eg selling to or from swap LP), should omit multiplication/div
        uint256 baseAmount = _amount_.mul(_baseReflator);
        
        if(_isRebaseExempt[_sender_]){
            _baseBalances[_sender_] = _baseBalances[_sender_].sub(_amount_);
        } else {
            _baseBalances[_sender_] = _baseBalances[_sender_].sub(baseAmount);
        }
          
        if(_isRebaseExempt[_recipient_]){
            _baseBalances[_recipient_] = _baseBalances[_recipient_].add(_amount_);
        } else {
            _baseBalances[_recipient_] = _baseBalances[_recipient_].add(baseAmount);
        }

        emit Transfer(
            _sender_,
            _recipient_,
            _amount_
        );
        return true;
    }

    function _transferFrom(
        address _sender_,
        address _recipient_,
        uint256 _amount_
    ) internal returns (bool) {

        require(!_isBlockListed[_sender_] && !_isBlockListed[_recipient_], "BLOCKLISTED");

        //will leave rebase dust in transferring account if sending entire balance
        //during a transaction which triggers a rebase.
        //consider it a reward for gas used by sender to process rebase.
        if (_shouldRebase()) { 
           _rebase();
        }

        //continue for transfers between exempt (LPs) and non exempt addresses     
        return _basicTransfer(_sender_, _recipient_, _amount_);
    }

    function allowance(address _owner_, address _spender_)
        external
        view
        override
        returns (uint256)
    {
        return _baseAllowances[_owner_][_spender_];
    }

    function decreaseAllowance(address _spender_, uint256 _subtractedValue_)
        external
        returns (bool)
    {
        uint256 oldAllowance_ = _baseAllowances[msg.sender][_spender_];
        if (_subtractedValue_ >= oldAllowance_) {
            _baseAllowances[msg.sender][_spender_] = 0;
        } else {
            _baseAllowances[msg.sender][_spender_] = oldAllowance_.sub(
                _subtractedValue_
            );
        }
        emit Approval(
            msg.sender,
            _spender_,
            _baseAllowances[msg.sender][_spender_]
        );
        return true;
    }

    function increaseAllowance(address _spender_, uint256 _addedValue_)
        external
        returns (bool)
    {
        _baseAllowances[msg.sender][_spender_] = _baseAllowances[msg.sender][
            _spender_
        ].add(_addedValue_);
        emit Approval(
            msg.sender,
            _spender_,
            _baseAllowances[msg.sender][_spender_]
        );
        return true;
    }

    function approve(address _spender_, uint256 _value_)
        external
        override
        returns (bool)
    {
        _baseAllowances[msg.sender][_spender_] = _value_;
        emit Approval(msg.sender, _spender_, _value_);
        return true;
    }
    
    function getCirculatingSupply() public view returns (uint256) {
        return
            (TOTAL_REFLATIONS.sub(_baseBalances[address(0)])).div(_baseReflator);
    }
    
    function totalSupply() external view override returns (uint256) {
        return _totalSupply;
    }
   
    function balanceOf(address _addr_) public view override returns (uint256) {
        if(_isRebaseExempt[_addr_]){
            return _baseBalances[_addr_];
        }else{
            return _baseBalances[_addr_].div(_baseReflator);
        }
    }

    function _rebase() internal {

        uint256 deltaTime_ = block.timestamp - lastRebaseTime;
        uint256 times_ = deltaTime_.div(REBASE_PERIOD); //15 minutes.
        uint256 epoch_ = times_.mul(REBASE_PERIOD.div(60)); //only since last rebase??

        for (uint256 i = 0; i < times_; i++) {
            //tS = tS * (1 + rate)
            _totalSupply = _totalSupply.mul((10**REBASE_DENOMINATOR).add(_rebaseRate)).div(10**REBASE_DENOMINATOR); //263_000/1_000_000_000
        }

        _baseReflator = TOTAL_REFLATIONS.div(_totalSupply);
        lastRebaseTime = lastRebaseTime.add(times_.mul(REBASE_PERIOD));//15 minutes. back calc last time.

        emit LogRebase(epoch_, _totalSupply);
    }

    function _shouldRebase() internal view returns (bool) {
        return (
            _autoRebase &&
            (_totalSupply < MAX_SUPPLY) &&
            block.timestamp >= (lastRebaseTime + REBASE_PERIOD)
        );
    }

    function isRebaseExempt(address _addr_) external view returns (bool) {
        return _isRebaseExempt[_addr_];
    }

    function setRebaseExempt(address _addr_, bool _flag_) external onlyOwner {
        //LPs etc. no personal addresses, when adding to list
        //convert curent balances before changing.
        uint256 bal_ = balanceOf(_addr_);
        if(_flag_){
            require(isContract(_addr_), "CONTRACT_ADDRESSES_ONLY");
            _baseBalances[_addr_] = bal_;
        } else {
            _baseBalances[_addr_] = bal_.mul(_baseReflator);
        }
        _isRebaseExempt[_addr_] = _flag_;
    }

    function getBaseBalance(address _addr_) public view returns (uint256) {
        return _baseBalances[_addr_];
    }
    
    function getBaseReflator() public view returns (uint256) {
        return _baseReflator;
    }
    
    function getRebaseRate() public view returns (uint256) {
        return _rebaseRate;
    }

    function setRebaseRate(uint256 _rate_) external onlyOwner {
        require(_rate_ <= 333333, "DONT_BE_RIDICULOUS"); //18X
        _rebaseRate = _rate_;
    }

    function getAutoRebase() external view returns (bool) {
        return _autoRebase;
    }

    function setAutoRebase(bool _flag_) external onlyOwner {
        //if true, reset rebase time to block immediate rebase
        if (_flag_) {
            _autoRebase = _flag_;
            lastRebaseTime = block.timestamp;
        } else {
            _autoRebase = _flag_;
        }
    }

    function manualRebase() external returns(bool) {
        require(block.timestamp > lastRebaseTime + REBASE_PERIOD, "UNLAPSED_TIMEOUT");
        _rebase();
        return true;
    }

    function isBlockListed(address _addr_) external view returns (bool) {
        return _isBlockListed[_addr_];
    }

    function setOnBlocklist(address _addr_, bool _flag_) external onlyOwner {
        //bots etc. no personal addresses
        if(_flag_){
            require(isContract(_addr_), "CONTRACT_ADDRESSES_ONLY");
        }
        _isBlockListed[_addr_] = _flag_;    
    }
    
    function isContract(address _addr_) internal view returns (bool) {
        uint size_;
        assembly { size_ := extcodesize(_addr_) }
        return size_ > 0;
    }

    function clearDustBalance() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    //transfer out to treasury random airdrop etc tokens if required.
    function rescueTokens(address _tokenAddress_)
        external
        onlyOwner
        returns (bool success)
    {
        return ERC20Detailed(_tokenAddress_).transfer(owner(), balanceOf(address(this)));
    }
    
    receive() external payable {}
}