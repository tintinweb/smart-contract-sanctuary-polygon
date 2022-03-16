//SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}
contract PolygonPairsUniswapV2 {

    address[] public pairs;
    address public stk;
    constructor () {
        stk = msg.sender;
        pairs.push(0xadbF1854e5883eB8aa7BAf50705338739e558E5b);
        pairs.push(0x6e7a5FAFcec6BB1e78bAE2A1F0B612012BF14827);
        pairs.push(0x604229c960e5CACF2aaEAc8Be68Ac07BA9dF81c3);
        pairs.push(0x9A8b2601760814019B7E6eE0052E25f1C623D1E6);
        pairs.push(0x019ba0325f1988213D448b3472fA1cf8D07618d7);
        pairs.push(0x9b5c71936670e9f1F36e63F03384De7e06E60d2a);
        pairs.push(0xEEf611894CeaE652979C9D0DaE1dEb597790C6eE); 
        pairs.push(0xF6422B997c7F54D1c6a6e103bcb1499EeA0a7046);
        pairs.push(0x4A35582a710E1F4b2030A3F826DA20BfB6703C09);
        pairs.push(0x90bc3E68Ba8393a3Bf2D79309365089975341a43);
        pairs.push(0x1Bd06B96dd42AdA85fDd0795f3B4A79DB914ADD5);
        pairs.push(0xFc2fC983a411C4B1E238f7Eb949308CF0218C750);
        pairs.push(0xdC9232E2Df177d7a12FdFf6EcBAb114E2231198D);
        pairs.push(0xF6a637525402643B0654a54bEAd2Cb9A83C8B498);
        pairs.push(0xaDdc9C73f3CBaD4E647eAFf691715898825Ac20c);
        pairs.push(0x160532D2536175d65C03B97b0630A9802c274daD);
        pairs.push(0x853Ee4b2A13f8a742d64C8F088bE7bA2131f670d);
        pairs.push(0x2cF7252e74036d1Da831d11089D326296e64a728);
        pairs.push(0xf04adBF75cDFc5eD26eeA4bbbb991DB002036Bdd);
        pairs.push(0x096C5CCb33cFc5732Bcd1f3195C13dBeFC4c82f4);
        pairs.push(0xa5cABfC725DFa129f618D527E93702d10412f039);
        pairs.push(0x1F1E4c845183EF6d50E9609F16f6f9cAE43BC9Cb);
        pairs.push(0x74214F5d8AA71b8dc921D8A963a1Ba3605050781);
        pairs.push(0x59153f27eeFE07E5eCE4f9304EBBa1DA6F53CA88);
        pairs.push(0xcCB9d2100037f1253e6C1682AdF7dC9944498AFF);
        pairs.push(0x8B1Fd78ad67c7da09B682c5392b65CA7CaA101B9);
        pairs.push(0xE88e24F49338f974B528AcE10350Ac4576c5c8A1);
        pairs.push(0x4917bC6b8E705Ad462ef525937E7eB7C6c87C356);
        pairs.push(0xe7519Be0E2A4450815858343ca480d1939bE7281);
        pairs.push(0xE89faE1B4AdA2c869f05a0C96C87022DaDC7709a);
    }

    function get_Reserves() public view returns (uint256[] memory) {
        uint256[] memory reserves = new uint256[](pairs.length * 2);

        uint256 counter = 0;
        for (uint256 i = 0; i < pairs.length; i++) {
            (reserves[counter], reserves[counter + 1], ) = IUniswapV2Pair(
                pairs[i]
            ).getReserves();
            counter = counter + 2;
        }
        return reserves;
    }

    function get_BlockTimestampLast(uint256 _i)
        public
        view
        returns (uint256 blockTimestampLast)
    {
        (, , blockTimestampLast) = IUniswapV2Pair(pairs[_i]).getReserves();
    }

    function add_Pair(address _pairAddress) public onlySTK {
        pairs.push(_pairAddress);
    }

    modifier onlySTK {
        require(msg.sender == stk);
        _;
    }
}