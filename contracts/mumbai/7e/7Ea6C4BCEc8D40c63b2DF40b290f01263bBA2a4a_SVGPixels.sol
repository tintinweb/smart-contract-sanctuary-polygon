// SPDX-License-Identifier: MIT
/// @title A library used to construct ERC721 token URIs and SVG pixels rects
/**
>>>   Made with tears and confusion by LFBarreto   <<<
>> https://github.com/LFBarreto/mamie-fait-des-nft  <<
>>>            inspired by nouns.wtf               <<<
*/

pragma solidity 0.8.13;

library SVGPixels {
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    /**
        generates pixels rects
    
        @param x x position of the rect
        @param y y position of the rect
        @param width width of the rect
        @param height height of the rect
        @param fill index of the color to use
        @param class index of the class to use
        @return string memory rect pixel
    */
    function drawRect(
        uint16 x,
        uint16 y,
        uint16 width,
        uint16 height,
        uint16 fill,
        uint16 class
    ) public pure returns (string memory) {
        string[33] memory pixels = [
            "0",
            "10",
            "20",
            "30",
            "40",
            "50",
            "60",
            "70",
            "80",
            "90",
            "100",
            "110",
            "120",
            "130",
            "140",
            "150",
            "160",
            "170",
            "180",
            "190",
            "200",
            "210",
            "220",
            "230",
            "240",
            "250",
            "260",
            "270",
            "280",
            "290",
            "300",
            "310",
            "320"
        ];
        string[33] memory colors = [
            "#6d001a",
            "#be0039",
            "#ff4500",
            "#ffa800",
            "#ffd635",
            "#fff8b8",
            "#00a368",
            "#00cc78",
            "#7eed56",
            "#00756f",
            "#009eaa",
            "#00ccc0",
            "#2450a4",
            "#3690ea",
            "#51e9f4",
            "#493ac1",
            "#6a5cff",
            "#94b3ff",
            "#811e9f",
            "#b44ac0",
            "#e4abff",
            "#de107f",
            "#ff3881",
            "#ff99aa",
            "#6d482f",
            "#9c6926",
            "#ffb470",
            "#000000",
            "#515252",
            "#898d90",
            "#d4d7d9",
            "#ffffff",
            "#d1d0ce"
        ];

        return
            string(
                abi.encodePacked(
                    "<rect x='",
                    pixels[x],
                    "' y='",
                    pixels[y],
                    "' width='",
                    pixels[width],
                    "' height='",
                    pixels[height],
                    "' fill='",
                    colors[fill],
                    "' stroke='",
                    colors[fill],
                    "' class='c-",
                    uint2str(class),
                    "'/>"
                )
            );
    }

    /**
        generate a series of rects
        @param rects array of rects to generate
        @return svg string memory of the rects
     */
    function generate(uint16[6][][6] memory rects)
        public
        pure
        returns (string memory svg)
    {
        svg = "";
        for (uint16 j = 0; j < rects.length; j++) {
            for (uint16 i = 0; i < rects[j].length; i++) {
                svg = string(
                    abi.encodePacked(
                        svg,
                        drawRect(
                            rects[j][i][0],
                            rects[j][i][1],
                            rects[j][i][2],
                            rects[j][i][3],
                            rects[j][i][4],
                            rects[j][i][5]
                        )
                    )
                );
            }
        }

        return svg;
    }
}