/**
 *Submitted for verification at polygonscan.com on 2022-06-11
*/

pragma solidity ^0.8.10;

contract TenbyTen {
    address public creator;
    uint[10][10] public colorArray;
    mapping(uint256 => address) owners; 
    uint globalPlaceX;
    uint globalPlaceY;

    constructor(uint _globalPlaceX, uint _globalPlaceY) public{
        globalPlaceX = _globalPlaceX;
        globalPlaceY = _globalPlaceY;
        creator = msg.sender;
        
    }

    function init() public
    {
        require(msg.sender == creator);
        for (uint i; i < 10; i++) {
            colorArray[i] = [0,0,0,0,0,0,0,0,0,0];
        }
    }

    function placeColor(uint posx, uint posy, uint color) public {
        require(msg.sender == creator);
        colorArray[posx][posy] = color;
    }

    function getColors(uint x, uint y) public view returns(uint color)
    {
        color = colorArray[x][y];
    }

    

}

contract Canvas {
    TenbyTen[10][10] public canvasPieces;
    uint8 public lastIter = 0;
    function deployPieces() public {
        
        require(lastIter<10);
        for(uint j; j<10;j++)
        {
            canvasPieces[lastIter][j] = new TenbyTen(lastIter,j);
            canvasPieces[lastIter][j].init();
        }
        lastIter++;
        
    }

    function placeColorInterface(uint posx, uint posy, uint color) public {
        uint arrPosX = posx / uint(10);
        uint arrPosY = posy / uint(10);
        uint tenbytenPosX = posx % 10;
        uint tenbytenPosY = posy % 10;
        canvasPieces[arrPosX][arrPosY].placeColor(tenbytenPosX, tenbytenPosY, color);
    }

    function getColors(uint posx , uint posy) public view returns(uint color)
    {
        uint arrPosX = posx / uint(10);
        uint arrPosY = posy / uint(10);
        uint tenbytenPosX = posx % 10;
        uint tenbytenPosY = posy % 10;
        color = canvasPieces[arrPosX][arrPosY].getColors(tenbytenPosX,tenbytenPosY);
    }

}