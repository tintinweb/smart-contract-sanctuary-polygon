/**
 *Submitted for verification at polygonscan.com on 2022-07-26
*/

// File: contracts/erc20.sol

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.6.7;

interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Crypton is ERC20 {
    string public constant symbol = "CRTN";
    string public constant name = "Crypton";
    uint8 public constant decimals = 18;
    uint private constant __totalSupply = 1000000000 * (10 ** 18);
    address public owner;
 
    uint public amountAllowed = 10 * (10 ** 18);
    uint public amountMaticAllowed = 1 * (10 ** 17);
    uint public claimedAtFaucet = 0;
    uint public faucetLimit = 10000000 * (10 ** 18);
    
    mapping(address => uint) public lockTime;
    mapping (address => uint) private __balanceOf;
    mapping (address => mapping (address => uint)) private __allowances;

    constructor() public {
        __balanceOf[msg.sender] = __totalSupply;
        owner = msg.sender;
    }

    function totalSupply() public view override returns (uint _totalSupply) {
        _totalSupply = __totalSupply;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
        _; 
    }

    function balanceOf(address _addr) public view override returns (uint balance) {
        return __balanceOf[_addr];
    }

    function transfer(address _to, uint _value) public override returns (bool success) {
        if (_value > 0 && _value <= balanceOf(msg.sender)) {
            __balanceOf[msg.sender] -= _value;
            __balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint _value) public override returns (bool success) {
        if (__allowances[_from][msg.sender] > 0 &&
            _value >0 &&
            __allowances[_from][msg.sender] >= _value) {
            __balanceOf[_from] -= _value;
            __balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }

    function isContract(address _addr) public view returns (bool) {
        uint codeSize;
        assembly {
            codeSize := extcodesize(_addr)
        }
        return codeSize > 0;    
    }
 
    function approve(address _spender, uint _value) external override returns (bool success) {
        __allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external override view returns (uint remaining) {
        return __allowances[_owner][_spender];
    }

    //CRTN FAUCET
    function requestTokens(address _spender) public payable {
        require(block.timestamp > lockTime[msg.sender], "Lock time has not expired. Please try again later");
        require(__balanceOf[owner] > amountAllowed, "Not enough funds in the faucet.");
        require((claimedAtFaucet + amountAllowed) < faucetLimit, "Faucet Limit reached.");
            __balanceOf[owner] -= amountAllowed;
            __balanceOf[_spender] += amountAllowed;
            claimedAtFaucet += amountAllowed;
            Transfer(owner, _spender, amountAllowed);
            lockTime[msg.sender] = block.timestamp + 1 hours;
    }

    function setOwner(address newOwner) public onlyOwner {
        owner = newOwner;
    }

    function setAmountallowed(uint newAmountAllowed) public onlyOwner {
        amountAllowed = newAmountAllowed;
    }

    function setFaucetLimit(uint newFaucetLimit) public onlyOwner {
        faucetLimit = newFaucetLimit;
    }

    //MATIC FAUCET
    function donateTofaucet() public payable {
	}

    function setMaticAmountallowed(uint newMaticAmountAllowed) public onlyOwner {
        amountMaticAllowed = newMaticAmountAllowed;
    }

    function setFaucet() public onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Failed");
    }

    function requestMaticTokens(address payable _requestor) public payable {
        require(block.timestamp > lockTime[msg.sender], "Lock time has not expired. Please try again later");
        require(address(this).balance > amountAllowed, "Not enough matic funds in the faucet. Please donate.");
        _requestor.transfer(amountAllowed);
        lockTime[msg.sender] = block.timestamp + 1 days;
    }

    //raldblox:pzoo

}