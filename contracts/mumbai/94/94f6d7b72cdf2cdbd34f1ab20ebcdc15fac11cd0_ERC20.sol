/**
 *Submitted for verification at polygonscan.com on 2022-06-16
*/

pragma solidity ^0.8.7;

contract ERC20 {

    mapping(address => uint256) public balanceOf;

    uint256 public totalSupply;
    string public name;
    string public symbol;
    address public owner;
    address public productContract;

    mapping (address => bool) public whitelist;

    event Transfer(address from, address to, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balanceOf[address(this)] = _totalSupply; // give all money to contract at first
        owner = msg.sender;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // only allow product contract - used to applyForPolicy
    function transferFrom(address _from, uint256 _value) public onlyProductContract returns (bool success) {
        require(balanceOf[_from] >= _value);
        require(balanceOf[productContract] + _value > balanceOf[productContract]);
        balanceOf[_from] -= _value;
        balanceOf[productContract] += _value;
        emit Transfer(_from, productContract, _value);
        return true;
    }

    // sends 1000 to caller
    function faucet() public onlyWhitelist {
        require(balanceOf[address(this)] >= 1000);
        balanceOf[address(this)] -= 1000;
        balanceOf[msg.sender] += 1000;
    }

    // receive ether
    receive() external payable {}

    function addWalletToWhitelist(address _wallet) public onlyOwner {
        whitelist[_wallet] = true;
    }

    function removeWalletFromWhitelist(address _wallet) public onlyOwner {
        whitelist[_wallet] = false;
    }

    function setProductContract(address _productContract) public onlyOwner {
        productContract = _productContract;
    }

    modifier onlyProductContract {
        require(msg.sender == productContract);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier onlyWhitelist {
        require(whitelist[msg.sender] == true);
        _;
    }



}