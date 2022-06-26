// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;
import "./Owners.sol";

contract OwnersImpl is Owners {
    address private _proxy;

    address[] private _owners;
    mapping(address => uint256) private _ownersMapping;

    uint256 ownersBalance;

    constructor() {}

    modifier onlyProxy() {
        require(msg.sender == _proxy, "Not called from proxy");
        _;
    }

    function setProxy(address proxy) external {
        require(_proxy == address(0), "Proxy already set");
        _proxy = proxy;
    }

    function getOwners() external view onlyProxy returns (address[] memory) {
        return _owners;
    }

    function addOwner(address owner) external onlyProxy {
        require(_owners.length == 0 || _owners[_ownersMapping[owner]] != owner, "Already added as an owner");
        _ownersMapping[owner] = _owners.length;
        _owners.push(owner);
    }

    function isOwner(address sender) external view onlyProxy returns (bool) {
        return _owners[_ownersMapping[sender]] == sender;
    }

    function removeOwner(address sender, address owner) external onlyProxy {
        require(sender != owner, "The owner is the same as the sender");
        address last = _owners[_owners.length - 1];
        uint256 index = _ownersMapping[owner];
        _owners[index] = _owners[_owners.length - 1];
        _ownersMapping[last] = index;
        _owners.pop();
        _ownersMapping[owner] = 0;
    }

    function getOwnersBalance() external view onlyProxy returns (uint256) {
        return ownersBalance;
    }

    function withdrawProfit(address sender, uint256 amount) external onlyProxy {
        require(amount > 0, "The specified amount should be greater than zero");
        ownersBalance -= amount;
        (bool success, ) = sender.call{value: amount}("");
        require(success, "Transfer failed.");
    }

    function addToBalalnce() external payable onlyProxy {
        ownersBalance += msg.value;
    }

    function kill() external onlyProxy {
        selfdestruct(payable(msg.sender));
    }
}