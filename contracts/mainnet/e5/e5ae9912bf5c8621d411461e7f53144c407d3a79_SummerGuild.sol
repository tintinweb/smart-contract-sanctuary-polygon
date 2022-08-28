// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./ISnowV1Program.sol";
import "./ISnowV1.sol";

contract SummerGuild is ISnowV1Program {
    mapping(address => uint256) public _guildMembers; //maps guild member address to their access key
    uint256  public _guildSize;
    ISnowV1 _snowContract;
    ISnowV1Program public _guildProgram;

   constructor(address snowContractAddress, uint256 guildDeployerAccessKey) public {
      _snowContract = ISnowV1(snowContractAddress);  
      _guildMembers[msg.sender] = guildDeployerAccessKey;
      _guildSize++;
   }

    function name() external pure returns (string memory) {
        return "SummerGuild";
    }

    function run(uint256[64] calldata canvas, uint8 lastUpdatedIndex)
        external
        returns (uint8 index, uint256 value)
    {
        if (address(_guildProgram) != address(0)) {
            return _guildProgram.run(canvas, lastUpdatedIndex);
        }
        else{
            uint256 sprite = 0xffffffff8a83baab8aabeabb88bbffff8223aaebaa63bae7ba2bffffffffffff;

            for (uint8 i = 0; i < 64 && i < _guildSize; i++) {
                    return(i, sprite);
            }
        }
    }

    //join the guild 
    function joinGuild(uint256 accessKey) external {
        require(msg.sender == _snowContract.ownerOf(accessKey), "This is not your key");
        require(ISnowV1Program(address(this)) == _snowContract.programs(accessKey), "You havent delegated your program to the guild.");
        //can't set the users program on their behalf so have to resort to checking if they've done it themselves
        //_snowContract.storeProgram(accessKey, ISnowV1Program(address(this)));
        _guildSize++;
        _guildMembers[msg.sender] = accessKey;
    }

    function setGuildProgram(uint256 accessKey, ISnowV1Program newProgram) external{
        require(msg.sender == _snowContract.ownerOf(accessKey), "You are not an operator");
        require(_guildMembers[msg.sender] > 0, "You are not in the guild");

        uint256[64] memory buffer;
        (uint8 index, uint256 value) = newProgram.run{gas: _snowContract.gasPerRun()}(buffer, 0);
        require(index < 64, "Should return index");
        require(buffer[index] != value, "Should update value");
        _guildProgram = newProgram;    
        (uint8 index2, uint256 value2) = _guildProgram.run{gas: _snowContract.gasPerRun()}(buffer, 0);
    }
}