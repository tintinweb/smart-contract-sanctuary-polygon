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
    
    event ganador(uint256);
    event ganadores(uint256[]);

    function un_numero() external returns(uint256){
        uint256 num = (rand() % 100)+1;
        emit ganador(num);
        return num;
    }

    function varios_numeros(uint256 cantidad) external  returns(uint256 [] memory){
        uint256 [] memory _ganadores = new uint256[](cantidad);
        for(uint256 i = 0; i < cantidad; i++){
            _ganadores[i] = rand_to(i*gasleft()) % 100;
            _ganadores[i]++;
        }

        emit ganadores(_ganadores);
        return _ganadores;
    }

    function destroy() external {
        selfdestruct(payable(msg.sender));
    }

}