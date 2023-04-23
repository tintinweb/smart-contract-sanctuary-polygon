// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
// import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";


contract Vault 
//is OwnableUpgradeable 
{
    uint256 public amount;
    address public keeper;

    constructor(address _keeper) {
        keeper = _keeper;
    }

    // function initialize(address _keeper) public initializer {
    //     __Ownable_init();

    //     keeper = _keeper;
    // }


    function deposit() payable public {
        amount += msg.value;
    }

    function withdraw() public {
        require(msg.sender == keeper, "only keeper can withdraw");
        payable(msg.sender).transfer(amount);
        amount = 0;

    }

    function getVersion() public pure returns (uint256) {
        return 1;
    }
}