/**
 *Submitted for verification at polygonscan.com on 2022-04-17
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IPonzi {
    function getBalance() external view returns (uint256);

    function seedRewards(address adr) external view returns (uint256);

    function getMyMiners(address adr) external view returns (uint256);

    function getSeedsSincelastPlanted(address adr)
        external
        view
        returns (uint256);

    function plantSeeds(address ref) external payable;

    function harvestSeeds() external;

    function replantSeeds(address ref) external;
}

contract Worker {
    address owner;
    IPonzi ponzi;

    mapping(address => bool) auth;

    receive() payable external{}

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyAuth() {
        require(owner == msg.sender || auth[msg.sender], "Ownable: caller is not the owner");
        _;
    }

    function authorize(address addr, bool status) external onlyOwner {
        auth[addr] = status;
    }

    constructor(address _ponzi) {
        owner = msg.sender;
        ponzi = IPonzi(_ponzi);
    }

    function reinvest() external onlyAuth {
        ponzi.harvestSeeds();
        ponzi.plantSeeds{value: payable(this).balance}(address(0));
        // ponzi.replantSeeds(address(0));
    }

    function exit() external  onlyAuth {
        ponzi.harvestSeeds();
    }

    function invest() external payable onlyAuth {
        if (msg.value > 0) {
            ponzi.plantSeeds{value: msg.value}(address(0));
        }
    }

    function getCurrentBalance() external view returns (uint256) {
        return ponzi.getBalance();
    }

    function getCurrentRewards() external view returns (uint256) {
        return ponzi.seedRewards(address(this));
    }

    function getCurrentWorkers() external view returns (uint256) {
        return ponzi.getMyMiners(address(this));
    }

    function withdraw() external onlyAuth {
        ponzi.harvestSeeds();
        payable(msg.sender).transfer(address(this).balance);
    }
}