/**
 *
 * ░▀▀█░█▀█░█▀█░█▀▀░▀█▀░█▀▀░▀█▀░█░█
 * ░▄▀░░█░█░█░█░█░░░░█░░█▀▀░░█░░░█░
 * ░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░▀▀▀░░▀░░░▀░
 *
 * ZOOCIETY QUANTIZED LIBRARY
 * https://zoociety.xyz
 *
 */

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

/**
 * @author https://github.com/raldblox
 */
library QuantizedLibrary {
    function graviton() external pure returns (string memory) {
        return "data:text/html";
    }

    function gluino(string memory gravitino, string memory higgsino)
        external
        pure
        returns (string memory)
    {
        string memory a = '<img class="image" src="';
        string memory b = '" alt="';
        string memory c = '"/>';

        return string(abi.encodePacked(a, gravitino, b, higgsino, c));
    }

    function neutralino(
        string memory photino,
        string memory sleptons,
        string memory sneutrino
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '"',
                    photino,
                    '": "',
                    sleptons,
                    '", "value": "',
                    sneutrino,
                    '"'
                )
            );
    }

    function hadron(
        string memory _squarks,
        string memory _axion,
        string memory _axino
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    '<!DOCTYPE html><html lang="en">',
                    _squarks,
                    _axion,
                    _axino,
                    "</html>"
                )
            );
    }

    function squarks(
        string memory branon,
        string memory digamma,
        string memory dilaton
    ) external pure returns (string memory) {
        return
            string(
                abi.encodePacked("<head>", branon, digamma, dilaton, "</head>")
            );
    }

    function axion(string memory _axion) external pure returns (string memory) {
        return string(abi.encodePacked("<body>", _axion, "</body>"));
    }

    function axino(string memory _axino) external pure returns (string memory) {
        return string(abi.encodePacked("<script>", _axino, "</script>"));
    }

    function quarks(string memory _quarks)
        external
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("<style>", _quarks, "</style>"));
    }

    function leptons(string memory _leptons)
        external
        pure
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    ".card {background-image: url(",
                    _leptons,
                    ");}"
                )
            );
    }
}