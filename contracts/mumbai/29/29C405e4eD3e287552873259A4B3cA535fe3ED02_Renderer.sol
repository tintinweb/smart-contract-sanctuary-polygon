//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import './SVG.sol';
import './Utils.sol';
import './RealMath.sol';

/// @title GeNFTs Renderer
/// @author espina (modified from w1nt3r.eth's hot-chain-svg)
/// @notice contract to mint Soulbound NFTs with onchain generative SVGs


contract Renderer {

    struct Attract {
        int128 a;
        int128 b;
        int128 c;
        int128 d;
    }

    struct Bee {
        int128 x;
        int128 y;
        int128 vx;
        int128 vy;
    }

    int public constant dims = 2400;


    function _render(uint256 _tokenId, uint size, int swarmSize) public view returns (string memory) {

        Bee[24] memory bees = _swarmInit(_tokenId,swarmSize);
        Attract memory attract = _attractInit(_tokenId);

        return
            string.concat(
                string.concat('<svg xmlns="http://www.w3.org/2000/svg" width="2400" height="2400" style="background:', _bgColor(),'">'),
                _rects(200,200),
                _genSwarm(_tokenId, bees, attract, size),
          
                '</svg>'
            );
    }

    function _swarmInit(uint _tokenId, int swarmSize) public view returns (Bee[24] memory) {
        //int swarmSize = 15;
        Bee[24] memory bees;
        for (uint x = 0; x < uint(swarmSize); x++) {
            bees[x] = Bee(
                RealMath.toReal(int88(uint88((x * uint(dims) / uint(swarmSize))))),
                RealMath.toReal(int88(_random(_tokenId, x ) % dims)),
                0,
                0
            );
        }
        return bees;
    }

    function _attractInit(uint _tokenId) internal view returns (Attract memory) {
        return Attract(
            RealMath.mul(_randomInt(_tokenId, 1) % 1e12, (RealMath.toReal(4))) - RealMath.toReal(2),
            RealMath.mul(_randomInt(_tokenId, 2) % 1e12, (RealMath.toReal(4))) - RealMath.toReal(2),
            RealMath.mul(_randomInt(_tokenId, 3) % 1e12, (RealMath.toReal(4))) - RealMath.toReal(2),
            RealMath.mul(_randomInt(_tokenId, 4) % 1e12, (RealMath.toReal(4))) - RealMath.toReal(2)
        );
    }

    function _genSwarm(uint _tokenId, Bee[24] memory _bees, Attract memory _attracts, uint _times) internal view returns (string memory) {
        string memory SVGString;

        for (uint count = 0; count < _times; count++) {
            for (uint i = 0; i < _bees.length; i++) {   
                Bee memory bee = _bees[i];
                if (bee.x == 0 && bee.y == 0) { continue; }
                int128 val = _attractVal(bee.x, bee.y, _attracts);
                //fix all floatingpoint math

                //DO ALL MATH IN REAL NUMBER FRACT BIT OF REALMATH 


                bee.vx += RealMath.div(RealMath.cos(val), RealMath.toReal(3)); 
                bee.vy += RealMath.div(RealMath.sin(val), RealMath.toReal(3)); 
                bee.x += bee.vx;
                bee.y += bee.vy;

                SVGString = string.concat(SVGString, _rects(uint88(RealMath.fromReal(bee.x)), uint88(RealMath.fromReal(bee.y))));
                
                bee.vx =  RealMath.div(RealMath.mul(bee.vx, RealMath.toReal(99)), RealMath.toReal(100)); //*= 0.99;
                bee.vy =  RealMath.div(RealMath.mul(bee.vy, RealMath.toReal(99)), RealMath.toReal(100));

                if(RealMath.fromReal(bee.x) > dims) bee.x = 0;
                if(RealMath.fromReal(bee.y) > dims) bee.y = 0;
                if(RealMath.fromReal(bee.x) < 0) bee.x = RealMath.toReal(int88(dims));
                if(RealMath.fromReal(bee.y) < 0) bee.y = RealMath.toReal(int88(dims));
            }
        }
        return SVGString;

    }

    function _attractVal(int128 _x, int128 _y, Attract memory _attracts) internal view returns(int128) {
        // clifford attractor
        // http://paulbourke.net/fractals/clifford/
    

        
        // scale down x and y
        int128 scale = RealMath.toReal(200); //divide by 200 instead
        _x = RealMath.div( RealMath.toReal(int88(_x - dims / 2)), scale);
        _y = RealMath.div( RealMath.toReal(int88(_y - dims / 2)), scale);

        // cliiford attactor gives new x, y for old one. 
        int128 x1 = RealMath.sin(RealMath.mul(_attracts.a, _y)) + RealMath.mul(_attracts.c, RealMath.cos(RealMath.mul(_attracts.a, _x)));
        int128 y1 = RealMath.sin(RealMath.mul(_attracts.b, _x)) + RealMath.mul(_attracts.d,RealMath.cos(RealMath.mul(_attracts.b, _y)));

        // find angle from old to new. that's the value.
        return RealMath.atan2(y1 - _y, x1 - _x);

    }



//     // function example() external view returns (string memory) {
//     //     return _render(1);
//     // }

    function example() external view returns (string memory) {
        return _render(1887656786789,1, 1);
    }


    function _random(uint _tokenId, uint _ind) internal pure returns (int128) {
        return int128(int256( (uint256((keccak256(abi.encodePacked(_tokenId, _ind))))) % 1e12));
    }
    
    function _randomInt(uint _tokenId, uint _ind) internal pure returns (int128) {
        int128 random = int128(int256((uint256((keccak256(abi.encodePacked(_tokenId, _ind)))))));
        if (random % 2 > 1) { return -random; }
        else {return random; } 
    }



    function _bgColor() internal view returns (string memory) {
        return 'black';
    }

    function _rects(uint _x, uint _y) internal view returns(string memory) {
        return svg.rect(
            string.concat(
                svg.prop('x', utils.uint2str(_x)),
                svg.prop('y', utils.uint2str(_y)),
                svg.prop('width', '10'),
                svg.prop('height', '10'),
                svg.prop('fill', 'white')
                //svg.prop('stroke', 'white')
                //svg.prop('fill-opacity', utils.uint2str(0)),
                //svg.prop('stroke-width', utils.uint2str(3))
            ),
            utils.NULL
        );
    }

}