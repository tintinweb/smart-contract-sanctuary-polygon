// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./raffle.sol";


/**
 * @title Raffles
 * @dev Raffle factory contract
 */
contract Raffles is Ownable {
    LinkTokenInterface constant private LINK = LinkTokenInterface(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);

    address constant private VRF = 0x8C7382F9D8f56b33781fE506E897a4F1e2d17255;
    bytes32 constant private KEY = 0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4;
    uint256 constant private FEE = 0.0001 * 10 ** 18;

    mapping(uint256 => address) public raffles;
    uint256 rafflesNumber;

    /**
     * @dev Raffle's by index
     * @param index raffle's index 
     * @return value of 'Raffle'
     */
    function i_raffle(uint256 index) private view returns (Raffle) {
        require(rafflesNumber != 0 && index < rafflesNumber, "No such raffle");
        return Raffle(raffles[index]);
    }

    /**
     * @dev Get all values of the mapping
     * @param _length number of elements in the mapping
     * @param _getter the mapping 
     * @return value of 'address[]'
     */
    function mapping_values(uint256 _length, function (uint256) view external returns (address) _getter) private view returns (address[] memory) {
        address[] memory values = new address[](_length);
        
        for (uint256 i = 0; i < _length; i++) {
                values[i] = _getter(i);
            }
        
        return values;
    }

    /**
     * @dev Create a raffle and return its address
     * @return value of 'address'
     */
    function create() public onlyOwner returns (address) {
        require(LINK.balanceOf(address(this)) >= FEE, "Not enough LINK");

        Raffle raffle = new Raffle(VRF, address(LINK), KEY, FEE);

        LINK.approve(address(this), FEE);
        LINK.transferFrom(address(this), address(raffle), FEE);

        raffles[rafflesNumber] = address(raffle);
        rafflesNumber++;

        return address(raffle);
    }

    /**
     * @dev List of raffles
     * @return value of 'Raffle[]'
     */
    function list() public view returns (address[] memory) {
        return mapping_values(rafflesNumber, this.raffles);
    }

    /**
     * @dev Raffel's state
     * @param index raffle's index 
     * @return value of 'Raffle.STATE'
     */
    function state(uint256 index) public view returns (Raffle.STATE) {
        return i_raffle(index).state();
    }

    /**
     * @dev List of raffle entries
     * @param index raffle's index 
     * @return value of 'address[]'
     */
    function entries(uint256 index) public view returns (address[] memory) {
        Raffle raffle = Raffle(i_raffle(index));

        return mapping_values(raffle.entriesNumber(), raffle.entries);
    }

    /**
     * @dev List of raffle winners
     * @param index raffle's index 
     * @return value of 'address[]'
     */
    function winners(uint256 index) public view returns (address[] memory) {
        Raffle raffle = Raffle(i_raffle(index));

        return mapping_values(raffle.winnersNumber(), raffle.winners);
    }

    /**
     * @dev Set the raffle entries
     * @param index raffle's index 
     * @param addresses entries to store
     */
    function addEntries(uint256 index, address[] memory addresses, bool overwrite) public onlyOwner {
        return i_raffle(index).addEntries(addresses, overwrite);
    }

    /**
     * @dev Make a raffle
     * @param index raffle's index 
     * @param number number of winners to raffle
     */
    function selectWinners(uint256 index, uint256 number) public onlyOwner {
        return i_raffle(index).selectWinners(number);
    }

}