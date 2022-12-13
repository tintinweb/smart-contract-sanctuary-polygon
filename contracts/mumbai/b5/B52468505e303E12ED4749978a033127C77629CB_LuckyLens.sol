// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

contract LuckyLens {



struct Raffle {
address owner;
uint profileId;
uint pubId;
uint time;
uint randomNum;
}


address immutable LensHubProxy;
// mapping(bytes32 => uint) encodedRaffleToRandomNumber;
mapping(bytes32 => Raffle) public encodedRaffleToRaffle;

constructor(address _lensHubProxy) {
    LensHubProxy = _lensHubProxy;
}


function encodeRaffle(uint profileId, uint pubId, uint time) public pure returns(bytes32) {
    return(keccak256(abi.encode(profileId, pubId, time)));
}

function postRaffle(uint profileId, uint pubId, uint time) public {

bytes32 encodedRaffle = encodeRaffle(profileId, pubId, time);

require(encodedRaffleToRaffle[encodedRaffle].owner == address(0), "Raffle already exists at that profile, post, and time");

encodedRaffleToRaffle[encodedRaffle] = Raffle(
    msg.sender, 
    profileId,
    pubId,
    time,
    0
);

}




}