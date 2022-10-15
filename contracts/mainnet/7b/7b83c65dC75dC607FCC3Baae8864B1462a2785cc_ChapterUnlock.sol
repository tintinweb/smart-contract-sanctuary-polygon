/**
 *Submitted for verification at polygonscan.com on 2022-10-14
*/

/*

       ▄▄▄▄███▄▄▄▄    ▄█  ███▄▄▄▄       ███           ▄██████▄     ▄████████      ████████▄     ▄████████    ▄████████     ███      ▄█  ███▄▄▄▄   ▄██   ▄
     ▄██▀▀▀███▀▀▀██▄ ███  ███▀▀▀██▄ ▀█████████▄      ███    ███   ███    ███      ███   ▀███   ███    ███   ███    ███ ▀█████████▄ ███  ███▀▀▀██▄ ███   ██▄
     ███   ███   ███ ███▌ ███   ███    ▀███▀▀██      ███    ███   ███    █▀       ███    ███   ███    █▀    ███    █▀     ▀███▀▀██ ███▌ ███   ███ ███▄▄▄███
     ███   ███   ███ ███▌ ███   ███     ███   ▀      ███    ███  ▄███▄▄▄          ███    ███  ▄███▄▄▄       ███            ███   ▀ ███▌ ███   ███ ▀▀▀▀▀▀███
     ███   ███   ███ ███▌ ███   ███     ███          ███    ███ ▀▀███▀▀▀          ███    ███ ▀▀███▀▀▀     ▀███████████     ███     ███▌ ███   ███ ▄██   ███
     ███   ███   ███ ███  ███   ███     ███          ███    ███   ███             ███    ███   ███    █▄           ███     ███     ███  ███   ███ ███   ███
     ███   ███   ███ ███  ███   ███     ███          ███    ███   ███             ███   ▄███   ███    ███    ▄█    ███     ███     ███  ███   ███ ███   ███
      ▀█   ███   █▀  █▀    ▀█   █▀     ▄████▀         ▀██████▀    ███             ████████▀    ██████████  ▄████████▀     ▄████▀   █▀    ▀█   █▀   ▀█████▀


    v1
    @author NFTArca.de
    @title Unlock for Chapter 2

*/

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

contract ChapterUnlock {

    uint256[] private cypher;

    constructor() {
        cypher.push(44888760);
        cypher.push(482792940);
        cypher.push(155200500);
        cypher.push(457483320);
        cypher.push(145172160);
        cypher.push(70198380);
        cypher.push(79271640);
        cypher.push(77839020);
        cypher.push(81181800);
        cypher.push(87867360);
        cypher.push(85957200);
        cypher.push(104103720);
        cypher.push(80704260);
        cypher.push(118907460);
        cypher.push(82614420);
        cypher.push(158065740);
        cypher.push(97418160);
        cypher.push(174779640);
        cypher.push(80704260);
        cypher.push(14326200);
        cypher.push(15758820);
        cypher.push(5730480);
        cypher.push(8118180);
        cypher.push(3820320);
        cypher.push(7163100);
        cypher.push(5730480);
        cypher.push(4775400);
        cypher.push(7640640);
        cypher.push(17191440);
        cypher.push(189105840);
        cypher.push(82136880);
        cypher.push(203909580);
        cypher.push(79749180);
        cypher.push(9550800);
        cypher.push(214415460);
        cypher.push(12893580);
        cypher.push(13371120);
        cypher.push(221578560);
        cypher.push(11460960);
        cypher.push(235904760);
    }

    function magicNumber(uint256 key) public view returns (string memory) {

        // Make sure the message message length is within limits
        require(key > 0, "You must provide a magic number.");

        string memory fp =
        string(abi.encodePacked(
                '<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"',
                ' viewBox="0 0 640 420" style="enable-background:new 0 0 640 420;" xml:space="preserve">',
                '<style type="text/css">.st0{fill:#290264;}.st1{fill:#FFFFFF;}.st2{font-family:"Montserrat-Regular";}.st3{font-size:12px;}.st4{stroke:#000000;stroke-width:4;stroke-linecap:round;stroke-linejoin:round;}.st5{fill:none;}</style>',
                '<rect class="st0" width="640" height="420"/>',
                '<rect x="6.9" y="6.9" class="st1" width="625" height="406"/>',
                '<g id="layer1" transform="translate(0 -652.36)">',
                ' <path id="path3877" class="st4" d="M', toString(cypher[0] / key), ',', toString(cypher[1] / key), '.9c150.8-13.9,302.4-14.4,455,0c-3.4-95.6-10.3-189.3-7.8-288.4',
                ' c-93.8,3.3-147.2-75.8-227.6-13.1c-90.9-64.7-90.9,18.6-222.6,18.4C97.3,824.5,94.9,918,94,1011.9L94,1011.9z"/>',
                '<path id="path3879" class="st1" d="M', toString(cypher[2] / key), '.5,', toString(cypher[3] / key), '.2c57-41.1,133.5,25.1,199.4,28.6L524.6,739c-104.3-6.8-141.2-84.3-200.8-14.5',
                ' L325.5,958.2z"/>',
                '<path id="path3881" class="st1" d="M', toString(cypher[4] / key), '.3,961c-57-41.1-133.5,25.1-199.4,28.6l0.3-247.8c104.3-6.8,141.2-84.3,200.8-14.5',
                ' L304.3,961z"/></g>',
                '<rect x="126" y="100" class="st5" width="155" height="180"/><g>',
                '<path d="M', toString(cypher[5] / key), '.1,', toString(cypher[6] / key), '.2l7.5,1l2.4,3.7l2.7,28.5l0.3,', toString(cypher[23] / key), '.4l-1.5,2.2l-5.4,0.9l-19.6-1l-1.5-1.1l2.8-29.2l3.4-10.4L147.1,166.2z',
                ' M145,185.1l-3.9-2.8l-6.3,11.5L147,205l3.4-4.7l-9.2-7.8l3.7-7.4H145z M145.3,172.3l-2.7,4.2l', toString(cypher[23] / key), '.9,6.3l-6.1,8.3l4.5,3.4l7.2-12.1 l-11.8-10.3V172.3z"/>'
            ));

        string memory sp =
        string(abi.encodePacked(
                '<path d="M', toString(cypher[7] / key), '.2,', toString(cypher[8] / key), '.5v-1.3h2.8l13.8,', toString(cypher[24] / key), '.3l-3.1,3.1l-10.5-12.7v5l10.6,12.9l-3.1,3.1l-7.2-9.4l0.8,20.9l-5.2,0.2l1.1-37.4V170.5z"/>',
                '<path d="M', toString(cypher[9] / key), '.5,', toString(cypher[10] / key), '.4l3.5-5.3l11.2,11.2L213,172l4.1,4.4l-13.8,', toString(cypher[25] / key), '.9l13,11.8l-3.8,3.8l-12.5-12.2l-13.2,14l-3.5-4l13.2-13.3 l-12-9.2V180.4z"/>',
                '<path d="M', toString(cypher[11] / key), '.3,', toString(cypher[12] / key), '.8l10.1,14.9l12.9-15.3l0.9,36l-5.7-0.2l0.8-24.6l-9,', toString(cypher[26] / key), '.7l-6.4-8.3l0.9,22l-5.1,0.6L218.3,169.8z"/>',
                '<path d="M', toString(cypher[13] / key), '.3,', toString(cypher[14] / key), '.3l-0.2-4.1l24.5,7.4l-18.5,8.5l18.3,17.4l-5,4.4l-13.2-', toString(cypher[27] / key), '.8l1.3,17.6l-5.8-0.1l-1.3-35.5V173.3z M254.2,173.1 l0.3,7.9l11.8-4.2L254.2,173.1z"/>',
                '</g>',
                '<g>'
            ));

        string memory tp =
        string(abi.encodePacked(
                '<path d="M', toString(cypher[15] / key), '.7,', toString(cypher[16] / key), '.9l-0.8-37l14.6,8.6l15.6-8.8l0.8,', toString(cypher[28] / key), '.9h-6.1l-1.1-19.9l-9.2-5.1l-9.4,4.5l1.3,20.7l-5.9,0.1H331.7z M335,173.9',
                ' l0.5,6.3l6.5-2.5l-7-4V173.9z M348.7,177.9l6.3,2.7l0.8-7.2l-7,4.3V177.9z"/>',
                '<path d="M', toString(cypher[17] / key), ',', toString(cypher[18] / key), '.8l9.9,14.6l12.6-15l0.9,35.3l-5.6-0.2l0.8-24l-8.8,', toString(cypher[26] / key), '.5l-6.3-8.1l0.9,21.6l-5,0.5L366,169.8z"/>'
            '<path d="M', toString(cypher[29] / key), '.3,', toString(cypher[30] / key), '.3l6.3,1.6l-1.1,', toString(cypher[19] / key), '.7l-3.8,0.5l-1.6-', toString(cypher[20] / key), '.1L396.3,172.3z"/>'
            ));

        string memory ffp =
        string(abi.encodePacked(
                '<path d="M', toString(cypher[31] / key), ',', toString(cypher[32] / key), '.7l3.8,4l-13.3,12.4l16.2,0.9l-18.5,', toString(cypher[33] / key), '.2l-4.3-4.3l13.5-12.7h-', toString(cypher[24] / key), '.6L427,167.7z"/>',
                '<path d="M', toString(cypher[34] / key), ',', toString(cypher[32] / key), 'l11.1,12.6l-3.8,3.8l-5.6-6.3l1.1,', toString(cypher[35] / key), '.5l-7,0.5l1.6-', toString(cypher[36] / key), '.2l-5.9,6.7l-3-2.9L449,167z"/>'
            ));

        string memory ssp =
        string(abi.encodePacked(
                '<path d="M', toString(cypher[37] / key), '.1,', toString(cypher[18] / key), '.8l9.9,14.6l12.6-15l0.9,35.3l-5.6-0.2l0.8-', toString(cypher[38] / key), 'l-8.8,', toString(cypher[26] / key), '.5l-6.3-8.1l0.9,21.6l-5,0.5L464.1,169.8z"/>',
                '<path d="M', toString(cypher[39] / key), '.5,', toString(cypher[14] / key), '.2l-0.2-4l23.9,7.2l-18.1,8.3l17.9,17l-4.9,4.3l-', toString(cypher[21] / key), '.9-16.4l1.3,', toString(cypher[22] / key), '.3l-5.7-0.1l-1.3-34.7V173.2z M499.3,173 l0.3,7.8l11.5-4.1L499.3,173z"/>',
                '</g>',
                '<text transform="matrix(1 0 0 1 36.68 390.15)" class="st0 st2 st3">Only those skilled in ancient numerology of multiple dimensions will the image reveal itself to.</text>',
                '</svg>'
            ));

        return string(abi.encodePacked(fp,sp,tp,ffp,ssp));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    // Da Runes will provide the key
}