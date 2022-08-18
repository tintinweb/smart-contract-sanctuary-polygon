/**
 *Submitted for verification at polygonscan.com on 2022-08-17
*/

// File: tests/testVRF.sol


pragma solidity >=0.8.7 < 0.9.0;

interface IVRF{

    function requestRandomWords(uint256 token, address nft, uint256 value)external returns(uint256);
}


contract testVRF {

    Data[] public data;
    uint256 public count;
    uint256 public value =10;

    IVRF public ivrf;

    struct Data{
        uint256 rarity;
        uint256 random;
        uint256 value;
    }

    function setTree(uint256 _tokenId, uint8 _rarity, uint256 _random)external{

        Data storage d = data[_tokenId];
        d.rarity = _rarity;
        d.random = _random%1000;
    }

    function testVRFCall()external{

        ivrf.requestRandomWords(count, address(this),  value);
        Data memory d;
        d.value = value;
        data.push(d);
        count++;
        value = value*2;


    }

    function setVRF(address vrf)external {

        ivrf = IVRF(vrf);


    }

}