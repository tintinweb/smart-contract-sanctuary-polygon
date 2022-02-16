// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./raffle.sol";


/**
 * @title Raffles
 * @dev Raffle factory contract
 */
contract Raffles is Ownable {
    LinkTokenInterface internal LINK = LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);

    address internal VRF = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;
    bytes32 internal KEY = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
    uint256 internal FEE = 0.0001 * 10 ** 18;

    Raffle[] private _raffles;

    /**
     * @dev Create a raffle and return its address
     * @return value of 'address'
     */
    function create() public onlyOwner returns (address) {
        require(LINK.balanceOf(address(this)) >= FEE, "Not enough LINK");

        Raffle _raffle = new Raffle(VRF, address(LINK), KEY, FEE);

        LINK.approve(address(this), FEE);
        LINK.transferFrom(address(this), address(_raffle), FEE);

        _raffles.push(_raffle);
        return  address(_raffle);
    }

    /**
     * @dev List of raffles
     * @return value of 'Raffle[]'
     */
    function list() public view returns (Raffle[] memory) {
        return _raffles;
    }

    /**
     * @dev List of raffle entries
     * @param index raffle's index 
     * @return value of 'address[]'
     */
    function entries(uint256 index) public view returns (address[] memory) {
        return Raffle(address(_raffles[index])).entries();
    }

    /**
     * @dev List of raffle winners
     * @param index raffle's index 
     * @return value of 'address[]'
     */
    function winners(uint256 index) public view returns (address[] memory) {
        return Raffle(address(_raffles[index])).winners();
    }

    /**
     * @dev Set the raffle entries
     * @param index raffle's index 
     * @param addresses entries to store
     */
    function setEntries(uint256 index, address[] memory addresses) public onlyOwner {
        return Raffle(address(_raffles[index])).setEntries(addresses);
    }

    /**
     * @dev Make a raffle
     * @param index raffle's index 
     * @param number number of winners to raffle
     */
    function selectWinners(uint256 index, uint256 number) public onlyOwner {
        return Raffle(address(_raffles[index])).selectWinners(number);
    }

}