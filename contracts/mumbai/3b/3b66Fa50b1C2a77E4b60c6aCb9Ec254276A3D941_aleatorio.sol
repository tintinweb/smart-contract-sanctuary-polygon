/**
 *Submitted for verification at polygonscan.com on 2023-07-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract random {
    function rand() internal view returns(uint256){
        bytes32 _blockhash = blockhash(block.number-1);
        return uint256(keccak256(abi.encode(_blockhash,block.timestamp,block.prevrandao, address(0).balance, address(0x000000000000000000000000000000000000dEaD).balance,address(this).balance)));
    }

    function rand_to(uint256 number) internal view returns(uint256){
        return uint256(keccak256(abi.encode(rand(), number)));
    }
}

contract aleatorio is random {

    receive() external payable {} // added for the contract to directly receive funds

    function un_numero() external view returns(uint256){
        return (rand() % 100)+1;
    }

    function varios_numeros(uint256 cantidad) external view returns(uint256 [] memory){
        uint256 [] memory ganadores = new uint256[](cantidad);
        for(uint256 i = 0; i < cantidad; i++){
            ganadores[i] = rand_to(i*gasleft()) % 100;
            ganadores[i]++;
        }
        return ganadores;
    }

    function destroy() external {
        selfdestruct(payable(msg.sender));
    }

}