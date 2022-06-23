/**
 *Submitted for verification at polygonscan.com on 2022-06-23
*/

// File: contracts/ethermontrade.sol



pragma solidity 0.6.6;




contract EtheremonTrade  {

      
    // public api
    function getRandom(address _player, uint _block, uint _seed, uint _count) view public returns(uint) {
        return uint(keccak256(abi.encodePacked(blockhash(_block), _player, _seed, _count)));
    }


function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
    bytes memory tmp = bytes(_a);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    for (uint i = 2; i < 2 + 2 * 20; i += 2) {
        iaddr *= 256;
        b1 = uint160(uint8(tmp[i]));
        b2 = uint160(uint8(tmp[i + 1]));
        if ((b1 >= 97) && (b1 <= 102)) {
            b1 -= 87;
        } else if ((b1 >= 65) && (b1 <= 70)) {
            b1 -= 55;
        } else if ((b1 >= 48) && (b1 <= 57)) {
            b1 -= 48;
        }
        if ((b2 >= 97) && (b2 <= 102)) {
            b2 -= 87;
        } else if ((b2 >= 65) && (b2 <= 70)) {
            b2 -= 55;
        } else if ((b2 >= 48) && (b2 <= 57)) {
            b2 -= 48;
        }
        iaddr += (b1 * 16 + b2);
    }
    return address(iaddr);
}

    // public api 
    function getRandom2(
        address _player,
        uint _block,
        uint _count
    )
        public
        view
        returns(uint)
    {
        return uint(keccak256(abi.encodePacked(blockhash(_block), _player, _count)));
    }

    function isOnTrading(uint64 _objId)  public pure returns (bool) {
        if(_objId > 0)
            return false;
    }
    
    function misc() public view returns (bytes32) {
        return blockhash(block.number-1);
    }
    function rand() public view returns (uint256,  uint8, uint8,uint8,uint8,uint8,uint8  ){
        

        address addr = parseAddr("0xf7e158bd2b6e79ef2f2ab72ac6cb2fea239c2a9b") ;   
        uint256 seed = getRandom(addr, block.number-1 , 0, 229570);
        uint8[6] memory value;
        uint8[6] memory stats =  [68, 25, 39, 90, 68, 92];
        for (uint i=0; i < 6; i+= 1) {
      //  seed /= 100;
        value[i] = uint8(seed % 32) + stats[i];
        }
         
                
        return (seed, value[0], value[1], value[2], value[3], value[4], value[5]);
    }



   function rand2() public view returns (uint256,  uint8, uint8,uint8,uint8,uint8,uint8  ){
        

        address addr = parseAddr("0xf7e158bd2b6e79ef2f2ab72ac6cb2fea239c2a9b") ;   
        uint256 seed = getRandom2(addr, block.number-1 , 229570);
        uint256 seed_orig = seed;
        uint8[6] memory value;
        uint8[6] memory stats =  [68, 25, 39, 90, 68, 92];
        for (uint i=0; i < 6; i+= 1) {
        seed /= 100;
        value[i] = uint8(seed % 32) + stats[i];
        }
         
                
        return (seed_orig%32, value[0], value[1], value[2], value[3], value[4], value[5]);
    }

}