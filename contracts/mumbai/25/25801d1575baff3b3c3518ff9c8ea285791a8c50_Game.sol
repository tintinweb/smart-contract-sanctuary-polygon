/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

contract Game {
    struct Planet {
        address owner;
        uint256 stakeAmount;
        bool isValid;
    }
    
    address public immutable owner;

    mapping(uint => Planet) public planets;

    constructor(uint[] memory planetIds) {
        owner = msg.sender;
        for(uint i; i < planetIds.length; i++) {            
            planets[planetIds[i]] = Planet({
                owner: address(0),
                stakeAmount: 0,
                isValid: true
            });
        }
    }

    event planetClaimed(Planet planet, uint planetId);

    function _onlyValidPlanet(uint planetId) internal view virtual {
        require(
        planets[planetId].isValid,
        "planet does not exist"
        );
    }

    function getOwner(uint planetId) public view returns (address){
        _onlyValidPlanet(planetId);
        return planets[planetId].owner;
    }

    function initialClaim(uint planetId, address player) public {
        _onlyValidPlanet(planetId);
        require(msg.sender == owner, "only owner can make an initial claim");

        planets[planetId].owner = player;
    }

    function claimPlanet(uint planetId) public {
        _onlyValidPlanet(planetId);

        Planet storage planet = planets[planetId];
        require(msg.sender != planet.owner, "cant claim your own planet");

        planet.owner = msg.sender;
        emit planetClaimed(planet, planetId);

    }

    function stake(uint planetId) public payable {
        _onlyValidPlanet(planetId);

        Planet storage planet = planets[planetId];
        require(msg.sender == planet.owner, "cant stake on opponenets planet");
        
        planet.stakeAmount = msg.value;
    }

    function unstake(uint planetId, uint amount) public {
        _onlyValidPlanet(planetId);

        Planet storage planet = planets[planetId];
        require(msg.sender == planet.owner, "cant unstake on opponenets planet");
        require(planet.stakeAmount >= amount, "cant unstake more than is currently staked");
        require(address(this).balance >= amount, "oops this contract doesnt have the funds to give you that amount");
        
        planet.stakeAmount -= amount;

        address payable _player = payable(msg.sender);
        _player.transfer(amount);
    }
}