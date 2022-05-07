//SPDX-License-Identifier: Cool kids only

import "../survivors/IDoomsday.sol";

pragma solidity ^0.8.4;

contract DoomsdayImpacts{

    int64 constant MAP_WIDTH         = 4320000;   //map units
    int64 constant MAP_HEIGHT        = 2588795;   //map units
    int64 constant BASE_BLAST_RADIUS = 80000;   //map units

    uint constant IMPACT_BLOCK_INTERVAL = 255;

    address doomsday;
    constructor(){
        doomsday = msg.sender;
    }

    function currentImpact() public view returns (int64[2] memory _coordinates, int64 _radius, bytes32 impactId){
        uint eliminationBlock = block.number - (block.number % IMPACT_BLOCK_INTERVAL) + 1;
        int hash = int(uint(blockhash(eliminationBlock))%uint(type(int).max) );

        uint _totalSupply = IDoomsday(doomsday).totalSupply();

        //Min radius is half map height divided by num
        int o = MAP_HEIGHT/2/int(_totalSupply+1);

        //Limited in smallness to about 3% of map height
        if(o < BASE_BLAST_RADIUS){
            o = BASE_BLAST_RADIUS;
        }
        //Max radius is twice this
        _coordinates[0] = int64(hash%MAP_WIDTH - MAP_WIDTH/2);
        _coordinates[1] = int64((hash/MAP_WIDTH)%MAP_HEIGHT - MAP_HEIGHT/2);
        _radius = int64((hash/MAP_WIDTH/MAP_HEIGHT)%o + o);

        return(_coordinates,_radius, blockhash(eliminationBlock));
    }

    function setDoomsday(address _doomsday) public{
        require(msg.sender == doomsday,"sender");
        doomsday = _doomsday;
    }
}

// SPDX-License-Identifier: Fear

pragma solidity ^0.8.4;

interface IDoomsday {
    enum Stage {Initial,PreApocalypse,Apocalypse,PostApocalypse}
    function stage() external view returns(Stage);
    function totalSupply() external view returns (uint256);
    function isVulnerable(uint _tokenId) external view returns(bool);

    function ownerOf(uint256 _tokenId) external view returns(address);

    function confirmHit(uint _tokenId) external;
}