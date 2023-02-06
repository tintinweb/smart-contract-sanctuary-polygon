/**
 *Submitted for verification at polygonscan.com on 2023-02-05
*/

// File: contracts/NiftyLibrary.sol

/**
 *
 * ░▀▀█░█▀█░█▀█░█▀▀░▀█▀░█▀▀░▀█▀░█░█
 * ░▄▀░░█░█░█░█░█░░░░█░░█▀▀░░█░░░█░
 * ░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░░▀░░░▀░
 *
 * ZOOCIETY NIFTY
 * https://zoociety.xyz
 *
 * @author https://github.com/raldblox
 *
 */


pragma solidity ^0.8.10;

library NiftyLibrary {
    function figure(string memory _image, string memory _figcaption)
        external
        pure
        returns (string memory)
    {
        string memory a = '<figure><div class="nifty-bg"></div><img src="';
        string memory b = '" /><figcaption>';
        string memory c = "</figcaption></figure>";

        return string(abi.encodePacked(a, _image, b, _figcaption, c));
    }

    function image(string memory _src, string memory _alt)
        external
        pure
        returns (string memory)
    {
        string memory a = '<img src="';
        string memory b = '" alt="';
        string memory c = '"/>';

        return string(abi.encodePacked(a, _src, b, _alt, c));
    }

    function list(string memory _content)
        external
        pure
        returns (string memory)
    {
        string memory a = "<li>";
        string memory b = "</li>";

        return string(abi.encodePacked(a, _content, b));
    }

    function attribute(
        string memory _type,
        string memory _name,
        string memory _value
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"',
                    _type,
                    '": "',
                    _name,
                    '", "value": "',
                    _value,
                    '"'
                )
            );
    }
}