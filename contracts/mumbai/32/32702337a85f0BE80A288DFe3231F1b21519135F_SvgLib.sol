// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SvgLib {
    struct Image {
        string[3] backgroundColor;
        string[3] shoesColor;
        string[2] skinColor;
        string[2] skinShadow;
        string[4] hairColor;
        string[7] haircut;
        string[10] beard;
        string[3] rightHand;
        string[2] rightLeg;
        string[10] outfit;
    }

    function generatesSvg(uint8[15] calldata _scores)
        external
        pure
        returns (string memory)
    {
        Image memory image;

        image.backgroundColor = ["#9eb89e", "#ff9200", "#baffc9"];
        image.shoesColor = ["#000000", "#fdfbfb", "#eac117"];
        image.skinColor = ["#f1c27d", "#6f4f1d"];
        image.skinShadow = ["#d9a066", "#4d3714"];
        image.hairColor = ["#75250a", "#fde968", "#905424", "#14100b"];
        image.haircut = [
            '<path class="hair" d="M16 10h1v-4h1v-1h7v1h1v4h1v-6h-1v-1h-1v-1h-7v1h-1v1h-1M18 8h2v1h-2M23 8h2v1h-2" />',
            '<path class="hair" d="M15 11h1v-1h1v-2h1v-2h1v-1h1v1h1v-1h1v1h1v-1h1v1h1v2h1v2h1v1h1v-2h-1v-4h-1v-2h-1v-1h-7v1h-1v2h-1v3h-1M16 12h1v2h1v1h1v1h-1v1h-1v-1h-2v-1h1v-1h-1v-1h1M26 12h1v1h1v1h-1v1h1v1h-2v1h-1v-1h-1v-1h1v-1h1 M18 8h2v1h-2M23 8h2v1h-2" />',
            '<path class="hair" d="M15 10h1v1h1v3h1v6h-1v-1h-1v-4h-1M15 10h2v-1h1v-2h1v-1h1v-1h2v-3h-3v1h-1v1h-1v1h-1v3h-1M22 2h2v1h2v1h1v2h1v8h-1v7h-1v-1h-1v-7h1v-4h-1v-2h-1v-1h-2 M18 9h2v1h-2M23 9h2v1h-2" />',
            '<path class="hair" d="M16 10h1v-3h-1M17 7h1v-2h-1M18 5h2v-1h-2M20 4h3v-1h-3M23 5h2v-1h-2M25 5h1v2h-1M26 7h1v3h-1M18 8h2v1h-2M23 8h2v1h-2" />',
            '<path class="hair" d="M16 10h1v-3h1v-1h1v-1h5v1h1v1h1v3h1v-6h-1v-1h-10 M18 8h2v1h-2M23 8h2v1h-2" />',
            '<path class="hair" d="M16 10h1v-3h1v-1h2v-1h3v-1h1v-1h1v-1h-1v-1h-5v1h-1v1h-1v1h-1M26 10h1v-6h-1v-1h-1v1h-1v2h1v1h1 M18 8h2v1h-2M23 8h2v1h-2"/><path class="skin" d="M24 3h1v1h-1"/>',
            '<path class="hair" d="M16 10h1v-3h1v-2h1v-1h1v1h3v-4h-4v1h-1v1h-1v1h-1 M26 10h1v-6h-1v-1h-1v-1h-1v-1h-1v3h1v1h1v2h1 M18 8h2v1h-2M23 8h2v1h-2"/>'
        ];
        image.beard = [
            "",
            "",
            "",
            "",
            "",
            '<path class="hair" d="M17 12h1v1h1v1h1v-1h3v1h1v-1h1v-1h1v2h-1v2h-1v1h-5v-1h-1v-2h-1" />',
            '<path class="hair" d="M17 12h1v1h1v1h1v-1h3v1h1v-1h1v-1h1v2h-1v2h-1v1h-5v-1h-1v-2h-1" />',
            '<path class="hair" d="M20 13h3v1h-3M19 14h1v2h1v-1h1v1h1v-2h1v3h-1v1h-3v-1h-1" />',
            '<path class="hair" d="M20 13h3v1h-3M19 14h1v2h1v-1h1v1h1v-2h1v3h-1v1h-3v-1h-1" />',
            '<path class="hair" d="M19 15h5v-2h-5" />'
        ];
        image.rightHand = [
            '<path class="skin" d="M12 23h1v1h-1" />',
            '<path class="skin" d="M10 24h1v1h-1" />',
            '<path class="skin" d="M12 23h1v1h-1" /><path class="skin" d="M10 24h1v1h-1" />'
        ];
        image.rightLeg = [
            '<path class="skin" d="M18 32h2v2h-2" /><path class="socks" d="M18 33h2v4h-2" /><path class="socks-side" d="M18 33h2v1h-2" /><path class="shoes" d="M20 37h-3v1h-1v1h4" /><path class="shadow" d="M20 37h2v1h5v1h-3v1h-4" /><path class="black" d="M20 39h-4v1h4" />',
            '<g class="move-right"><path class="skin" d="M16 29h2v1h-2" /><path class="socks" d="M16 30h2v3h-2" /><path class="socks-side" d="M16 30h2v1h-2" /><path class="shoes" d="M15 33h3v2h-4v-1h1" /><path class="ball" d="M14 35h4v4h-4" /><path class="black" d="M14 35h1v1h-1M15 36h1v1h-1M16 37h1v1h-1M17 38h1v1h-1M16 35h2v1h-2M13 36h1v2h-1M18 36h1v2h-1M15 39h2v1h-2M14 38h1v1h-1" /><path class="shadow" d="M17 39h3v1h-3" /></g>'
        ];

        image.outfit = [
            ".socks { fill: #a00000 } .socks-side { fill: #000000 } .shorts { fill: #000000 } .shirt { fill: #a00000 } .shirt-side { fill: #000000 } .stripes { fill: #000000 }",
            ".socks { fill: #011f4b } .socks-side { fill: #000000 } .shorts { fill: #000000 } .shirt { fill: #011f4b } .shirt-side { fill: #000000 } .stripes { fill: #000000 }",
            ".socks { fill: #fdfbfb } .socks-side { fill: #000000 } .shorts { fill: #000000 } .shirt { fill: #000000 } .shirt-side { fill: #000000 } .stripes { fill: #fdfbfb }",
            ".socks { fill: #011f4b } .socks-side { fill: #740001 } .shorts { fill: #740001 } .shirt { fill: #011f4b } .shirt-side { fill: #011f4b } .stripes { fill: #740001 }",
            ".socks { fill: #71c7ec } .socks-side { fill: #fdfbfb } .shorts { fill: #71c7ec } .shirt { fill: #71c7ec } .shirt-side { fill: #fdfbfb } .stripes { fill: #71c7ec }",
            ".socks { fill: #a00000 } .socks-side { fill: #fdfbfb } .shorts { fill: #a00000 } .shirt { fill: #a00000 } .shirt-side { fill: #fdfbfb } .stripes { fill: #a00000 }",
            ".socks { fill: #090088 } .socks-side { fill: #fdfbfb } .shorts { fill: #090088 } .shirt { fill: #090088 } .shirt-side { fill: #fdfbfb } .stripes { fill: #090088 }",
            ".socks { fill: #fdfbfb } .socks-side { fill: #71c7ec } .shorts { fill: #fdfbfb } .shirt { fill: #fdfbfb } .shirt-side { fill: #71c7ec } .stripes { fill: #fdfbfb }",
            ".socks { fill: #fdfbfb } .socks-side { fill: #6abe30 } .shorts { fill: #0000ff } .shirt { fill: #fbf236 } .shirt-side { fill: #6abe30 } .stripes { fill: #fbf236 }",
            ".socks { fill: #cf142b } .socks-side { fill: #000000 } .shorts { fill: #fdfbfb } .shirt { fill: #0300f3 } .shirt-side { fill: #000000 } .stripes { fill: #0300f3 }"
        ];

        return
            string.concat(
                '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 42 42">',
                "<style>",
                ".background { fill: ",
                image.backgroundColor[_scores[6]],
                " }",
                ".shoes { fill: ",
                image.shoesColor[_scores[7]],
                " }",
                ".skin { fill: ",
                image.skinColor[_scores[8]],
                " }",
                ".skin-shadow { fill: ",
                image.skinShadow[_scores[8]],
                " }",
                ".hair { fill: ",
                image.hairColor[_scores[9]],
                " }",
                image.outfit[_scores[12]],
                ".black { fill: #000000 }",
                ".white { fill: #ffffff }",
                ".shadow { fill: #4c5029 }",
                ".ball { fill: #cbdbfc }",
                ".move-right { animation: 1s move-right infinite alternate ease-in-out; }",
                "@keyframes move-right { from { transform: translateY(0px); } to { transform: translateX(1px) ; } }  ",
                "</style>",
                '<rect class="background" width="100%" height="100%" />',
                '<path class="shirt" d="M17 18h9v9h-9" />',
                '<path class="stripes" d="M17 18h1v9h-1M19 18h1v9h-1M21 18h1v9h-1M23 18h1v9h-1M25 18h1v9h-1" />',
                '<path class="shirt-side" d="M18 17h7v1h-7M20 18h3v1h-3M21 19h1v1h-1" />',
                '<path class="shirt" d="M15 19h2v3h-2" />',
                '<path class="shirt-side" d="M15 19h1v1h-1M16 18h2v1h-2" />',
                '<path class="skin" d="M15 22h2v4h-6v-2h4" />',
                image.rightHand[_scores[11]],
                '<path class="shirt" d="M26 19h2v3h-2" />',
                '<path class="shirt-side" d="M25 18h2v1h-2M27 19h1v3h-1" />',
                '<path class="skin" d="M26 22h2v7h-1v1h-1" />',
                '<path class="shorts" d="M17 27h9v5h-4v-2h-1v2h-4" />',
                '<path class="skin" d="M17 5h9v9h-9M18 14h7v2h-7M19 16h5v1h-5M19 5h5v-1h-5" />',
                '<path class="skin-shadow" d="M16 10h1v2h-1M22 9h1v4h-3v-1h2M26 10h1v2h-1v2h-1v-3h1M24 15h1v1h-1M23 16h1v1h-1M20 17h3v1h-3" />',
                image.beard[_scores[14]],
                '<path class="white" d="M18 10h2v1h-2M23 10h2v1h-2M20 14h3v1h-3" />',
                '<path class="black" d="M18 10 h1v1h-1M23 10h1v1h-1" />',
                image.haircut[_scores[13]],
                image.rightLeg[_scores[10]],
                '<path class="skin" d="M23 32h2v2h-2" />',
                '<path class="socks" d="M23 33h2v4h-2" />',
                '<path class="socks-side" d="M23 33h2v1h-2" />',
                '<path class="shoes" d="M23 37h3v1h1v1h-4" />',
                '<path class="shadow" d="M26 37h2v1h5v1h-3v1h-3v-2h-1" />',
                '<path class="black" d="M23 39h4v1h-4" />',
                "</svg>"
            );
    }
}