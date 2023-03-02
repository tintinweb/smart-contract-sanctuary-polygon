/**
 *Submitted for verification at polygonscan.com on 2023-03-02
*/

// SPDX-License-Identifier: MIT 

pragma solidity ^0.8.17;

contract LensStorage {

    string[] public urls;

    mapping(string => string[]) public publications;

    function addUrl(string memory url) internal {
        urls.push(url);
    }

    function addPublication(string memory _url, string memory _publicationID) public {

        if (publications[_url].length == 0) {
            addUrl(_url);
            
        }
        publications[_url].push(_publicationID);
    } 
}