// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

library Gen3ImageLib1 {
    function generateCharacter(string memory _color1, string memory _color3, string memory _color4, string memory _color5 ) external pure returns(string memory){
        // stack too deep so we need to split this bitch up
        string memory result = "";
        {
            result = string(abi.encodePacked(
                '<svg width="128" height="128" xmlns="http://www.w3.org/2000/svg" xmlns:bx="https://boxy-svg.com" shape-rendering="crispEdges">',
                '<rect x="8" y="0" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="16" y="0" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="32" y="0" width="64" height="8" fill="',_color1,'"/>',
                '<rect x="96" y="0" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="112" y="0" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="0" y="8" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="8" y="8" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="16" y="8" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="24" y="8" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="32" y="8" width="16" height="8" fill="',_color4,'"/>'
                
            ));
        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="48" y="8" width="32" height="8" fill="',_color3,'"/>',
                '<rect x="80" y="8" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="96" y="8" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="104" y="8" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="112" y="8" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="120" y="8" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="0" y="16" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="8" y="16" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="16" y="16" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="24" y="16" width="24" height="8" fill="',_color4,'"/>'
            ));
        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="48" y="16" width="32" height="8" fill="',_color3,'"/>',
                '<rect x="80" y="16" width="24" height="8" fill="',_color4,'"/>',
                '<rect x="104" y="16" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="112" y="16" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="120" y="16" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="0" y="24" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="8" y="24" width="24" height="8" fill="',_color4,'"/>',
                '<rect x="32" y="24" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="40" y="24" width="16" height="8" fill="',_color4,'"/>'
            ));
        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="56" y="24" width="16" height="8" fill="',_color3,'"/>',
                '<rect x="72" y="24" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="88" y="24" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="96" y="24" width="24" height="8" fill="',_color4,'"/>',
                '<rect x="120" y="24" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="0" y="32" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="8" y="32" width="32" height="8" fill="',_color4,'"/>',
                '<rect x="40" y="32" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="48" y="32" width="8" height="8" fill="',_color4,'"/>'
                
            ));

        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="56" y="32" width="16" height="8" fill="',_color3,'"/>',
                '<rect x="72" y="32" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="80" y="32" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="88" y="32" width="32" height="8" fill="',_color4,'"/>',
                '<rect x="120" y="32" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="0" y="40" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="8" y="40" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="24" y="40" width="32" height="8" fill="',_color5,'"/>',
                '<rect x="56" y="40" width="16" height="8" fill="',_color3,'"/>',
                '<rect x="72" y="40" width="32" height="8" fill="',_color5,'"/>'
                
            ));        
        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="104" y="40" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="120" y="40" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="0" y="48" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="16" y="48" width="8" height="8" fill="',_color5,'"/>'
                '<rect x="24" y="48" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="32" y="48" width="16" height="8" fill="',_color1,'"/>',
                '<rect x="48" y="48" width="32" height="8" fill="',_color3,'"/>'
                
                
            ));
        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="80" y="48" width="16" height="8" fill="',_color1,'"/>',
                '<rect x="96" y="48" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="104" y="48" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="112" y="48" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="0" y="56" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="8" y="56" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="16" y="56" width="8" height="8" fill="',_color3,'"/>'
            ));
        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="24" y="56" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="32" y="56" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="40" y="56" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="48" y="56" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="56" y="56" width="16" height="8" fill="',_color3,'"/>',
                '<rect x="72" y="56" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="80" y="56" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="88" y="56" width="8" height="8" fill="',_color5,'"/>'
                
            ));
        }
        {
            result = string(abi.encodePacked(
                result,
                '<rect x="96" y="56" width="8" height="8" fill="',_color1,'"/>',
                '<rect x="104" y="56" width="8" height="8" fill="',_color3,'"/>',
                '<rect x="112" y="56" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="120" y="56" width="8" height="8" fill="',_color4,'"/>',
                '<rect x="0" y="48" width="16" height="8" fill="',_color4,'"/>',
                '<rect x="16" y="48" width="8" height="8" fill="',_color5,'"/>',
                '<rect x="24" y="48" width="8" height="8" fill="',_color3,'"/>'
                
            ));

        }     
        return result;
    }
}