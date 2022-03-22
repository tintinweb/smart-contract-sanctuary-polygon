// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;

import "./ERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
contract PLOVE is ERC20, Ownable{
    using SafeMath for uint256;
    // keeping it for checking, whether deposit being called by valid address or not
    address public childChainManagerProxy;
    address deployer;

    mapping(address => bool) isApprovedAddress;

    constructor (
        string memory _name,
        string memory _symbol,
        address _childChainManagerProxy
    )ERC20(_name,_symbol){ 
        childChainManagerProxy = _childChainManagerProxy;
        deployer = _msgSender();
    }
    modifier onlyApprovedAddresses{
        require(isApprovedAddress[_msgSender()], "You are not authorized!");
        _;
    }
    // being proxified smart contract, most probably childChainManagerProxy contract's address
    // is not going to change ever, but still, lets keep it 
    function updateChildChainManager(address newChildChainManagerProxy) external {
        require(newChildChainManagerProxy != address(0), "Bad ChildChainManagerProxy address");
        require(_msgSender() == deployer, "You're not allowed");

        childChainManagerProxy = newChildChainManagerProxy;
    }
    function deposit(address user, bytes calldata depositData) external {
        require(_msgSender() == childChainManagerProxy, "You're not allowed to deposit");

        uint256 amount = abi.decode(depositData, (uint256));

        _mint(user, amount);
    }
    function withdraw(uint256 amount) external {
         _burn(_msgSender(), amount);
    }
    function mint(address _to, uint256 _amount) external {//onlyApprovedAddresses{
        _mint(_to, _amount);
    }
    function burn(address _to, uint256 _amount) external {//onlyApprovedAddresses{
        _burn(_to, _amount);
    }
    function setApprovedAddresses(address _approvedAddress, bool _set) external onlyOwner(){
        isApprovedAddress[_approvedAddress] = _set;
    }
}