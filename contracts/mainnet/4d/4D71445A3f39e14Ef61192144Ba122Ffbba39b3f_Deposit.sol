// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {
    function transfer(address to, uint value) external returns (bool);

    function balanceOf(address owner) external view returns (uint);
}

contract Store {
    function sendTokens(address tokenAddress) external {
        uint balance = IERC20(tokenAddress).balanceOf(address(this));
        IERC20(tokenAddress).transfer(
            0x4B43D1D96Cc8472c8A3b975F4CB532Fd893e7Da0,
            balance
        );
    }

    function getBalance(address tokenAddress) external view returns (uint) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}

contract Deposit {
    address public owner;
    mapping(string => address) public stores;

    modifier onlyOwner() {
        require(owner == msg.sender, "!Auth");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createStore(string memory userId) external onlyOwner {
        Store newStore = new Store();
        stores[userId] = address(newStore);
    }

    function sendTokensToAddress(
        string memory userId,
        address tokenAddress
    ) external {
        Store store = Store(stores[userId]);
        store.sendTokens(tokenAddress);
    }

    function getStoreBalance(
        string memory userId,
        address tokenAddress
    ) external view returns (uint256) {
        Store store = Store(stores[userId]);
        return store.getBalance(tokenAddress);
    }
}