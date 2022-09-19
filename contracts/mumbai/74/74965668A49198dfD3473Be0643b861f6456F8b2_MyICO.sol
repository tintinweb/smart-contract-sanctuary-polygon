/**
 *Submitted for verification at polygonscan.com on 2022-09-18
*/

// SPDX-License-Identifier: MIT

/*


███████ ██████   ██████ ██████   ██████      ████████  ██████  ██   ██ ███████ ███    ██ ██ 
██      ██   ██ ██           ██ ██  ████        ██    ██    ██ ██  ██  ██      ████   ██ ██ 
█████   ██████  ██       █████  ██ ██ ██        ██    ██    ██ █████   █████   ██ ██  ██ ██ 
██      ██   ██ ██      ██      ████  ██        ██    ██    ██ ██  ██  ██      ██  ██ ██    
███████ ██   ██  ██████ ███████  ██████         ██     ██████  ██   ██ ███████ ██   ████ ██ 
                                                                                            
                                  contract coded by: Zain Ul Abideen AKA The Dragon Emperor

*/

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MyToken is IERC20 {
    mapping (address => uint) public _balances;
    mapping (address => mapping (address => uint)) private _allowed;
    string public name = "MyTokenTesting";
    string public symbol = "MTKNTST";
    uint public decimals = 6;
    uint private _totalSupply;
    address public _creator;

    // total supply of 1,000,000 with decimal of 6 will be 1.
    // if i want to mint a 1,000,000 tokens with a decimal of 1, i will have to add 10,000,000 in the supply.
    // also, for 6 decimal places, it will show 5 numbers after the decimal point.

    constructor() {
        _creator = msg.sender;
        _totalSupply = 1000000;
        _balances[_creator] = _totalSupply;
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return _balances[_owner];
    }

    // virtual means function can be overridden in the future.
    function transfer(address _to, uint256 _value) public virtual returns (bool success) {
        require(_value > 0 && _balances[msg.sender] >= _value);
        _balances[_to] += _value;
        _balances[msg.sender] -= _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool success) {
        require(_value > 0 && _balances[msg.sender] >= _value);
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // declaring it public so that it can be inherited.
    function transferFrom(address _from, address _to, uint256 _value) public virtual returns (bool success) {
        require(_value > 0 && _balances[_from] >= _value && _allowed[_from][_to] >= _value);
        _balances[_to] += _value;
        _balances[_from] -= _value;
        _allowed[_from][_to] -= _value;
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return _allowed[_owner][_spender];
    }
}

// deploying the ICO will automatically deploy the ERC20 contract.
// untested as of now.
contract MyICO is MyToken {

/*


▄█    ▄   ▄█    ▄▄▄▄▀ ▄█ ██   █         ▄█▄    ████▄ ▄█    ▄       ████▄ ▄████  ▄████  ▄███▄   █▄▄▄▄ ▄█    ▄     ▄▀  
██     █  ██ ▀▀▀ █    ██ █ █  █         █▀ ▀▄  █   █ ██     █      █   █ █▀   ▀ █▀   ▀ █▀   ▀  █  ▄▀ ██     █  ▄▀    
██ ██   █ ██     █    ██ █▄▄█ █         █   ▀  █   █ ██ ██   █     █   █ █▀▀    █▀▀    ██▄▄    █▀▀▌  ██ ██   █ █ ▀▄  
▐█ █ █  █ ▐█    █     ▐█ █  █ ███▄      █▄  ▄▀ ▀████ ▐█ █ █  █     ▀████ █      █      █▄   ▄▀ █  █  ▐█ █ █  █ █   █ 
 ▐ █  █ █  ▐   ▀       ▐    █     ▀     ▀███▀         ▐ █  █ █            █      █     ▀███▀     █    ▐ █  █ █  ███  
   █   ██                  █                            █   ██             ▀      ▀             ▀       █   ██       
                          ▀                                                                                          
                                                          contract coded by: Zain Ul Abideen AKA The Dragon Emperor

*/

    // explicity writing the values here instead of using a constructor because ...
    // ... some wallets use this information to sync and stuff. just looks prettier to wallets.

    address public administrator;
    address payable public recipient;
    uint public tokenPrice = 0.001 ether;
    uint public icoTarget = 5 ether;
    uint public recievedFund;

    // ... per investors.
    uint public maxInvestment = 1 ether;
    uint public minInvestment = 0.001 ether;

    // an enumeration to set the status of ico to certain states.
    enum Status {inactive, active, stopped, completed}
    Status icoStatus = Status.inactive;

    // there are 432000 seconds in 5 days. ICO will run for 5 days.
    // ICO will start in 100 seconds.
    uint public icoStartTime = block.timestamp + 100;
    uint public icoEndTime = block.timestamp + 432000;

    modifier requireRootAccess {
        if (msg.sender == administrator) {
            _;
        }
    }

    constructor(address payable _recipient) {
        recipient = _recipient;
        administrator = msg.sender;
    }

    function getIcoStatus() public returns (Status _returnStatus) {
        if (block.timestamp >= icoStartTime && block.timestamp <= icoEndTime) {
            icoStatus = Status.active;
        }
        else if (icoStatus != Status.inactive && icoStatus != Status.stopped) {
            icoStatus = Status.completed;
        }
        return icoStatus;
    }

    function investNow() payable public returns  (bool) {
        icoStatus = getIcoStatus();
        require(icoStatus == Status.active, "ICO is not active.");
        require(icoTarget >= recievedFund + msg.value, "Hard cap hit! Investment not accepted.");
        require(msg.value >= minInvestment && msg.value <= maxInvestment, "Investment not in allowed range.");
        uint tokens = msg.value / tokenPrice;
        _balances[msg.sender] += tokens;
        _balances[_creator] -= tokens;
        recievedFund += msg.value;
        recipient.transfer(msg.value);
        return true;
    }

    function setStopStatusForOwnerOnly() public requireRootAccess {
        icoStatus = Status.stopped;
    }

    function setStartStatusForOwnerOnly() public requireRootAccess {
        icoStatus = Status.active;
    }

    function burnTokens() public requireRootAccess {
        icoStatus = getIcoStatus();
        require(icoStatus == Status.completed);
        _balances[_creator] = 0;
    }

    // overriding the transfer functions so that it can only start working at the specified time.
    function transfer(address _to, uint256 _value) public override returns (bool success) {
        require(block.timestamp >= icoEndTime + 100, "Trading is not allowed yet.");
        super.transfer(_to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public override returns (bool success) {
        require(block.timestamp >= icoEndTime + 100, "Trading is not allowed yet.");
        super.transferFrom(_from, _to, _value);
        return true;
    }

}