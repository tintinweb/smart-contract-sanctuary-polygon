/**
 *Submitted for verification at polygonscan.com on 2022-06-25
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

//import "hardhat/console.sol";

contract DeCanvas {
    //Struct for storing data about individual pixels
    // struct Pixel {
    //     address painter;
    //     uint8 colour;
    // }

    // struct Canvas {
    //     Pixel[100][100] pixels;
    // }

    //Event for when a pixel is painted
    event Paint(
        address indexed painter,
        uint256 timestamp,
        uint256 colour,
        uint256 pixelID
    );

    //Define the canvas
    //Canvas canvas;

    //Setup owner modifier for function calls
    address owner;
    modifier _ownerOnly() {
        require(msg.sender == owner);
        _;
    }

    //Setup modifier and variable to track when to allow or disallow painting
    bool public allowPaint = true;
    modifier _paintAllowed() {
        require(allowPaint == true);
        _;
    }

    //Runs on initial deploy
    constructor() {
        //Define owner of contract as the address that deployed it
        owner = msg.sender;

        //Initialise each pixel to white, with null address as painter
        // for (uint256 x = 0; x < 100; x++) {
        //     for (uint256 y = 0; y < 100; y++) {
        //         canvas.pixels[x][y].colour = 0;
        //         canvas.pixels[x][y].painter = address(0);
        //         canvas.pixels[x][y].timestamp = block.timestamp;
        //     }
        // }
        
        //console.log("DeCanvas contract deployed");
    }

    //Paint a pixel, only when allowPaint is true
    function paint(
        uint256 pixelID,
        uint256 _colour
    ) public _paintAllowed {
        //Update relevant Pixel struct in canvas
        //canvas.pixels[x][y].colour = _colour;
        //canvas.pixels[x][y].painter = msg.sender;
        //canvas.pixels[x][y].timestamp = block.timestamp;

        //console.log("User %s painted pixel at %s , %s with colour %s",msg.sender,x,y,_colour);
        require(pixelID < 40000);
        emit Paint(msg.sender, block.timestamp, _colour, pixelID);
    }

    //Return the entire canvas
    // function getCanvas() public view returns (Canvas memory) {
    //     return canvas;
    // }

    //Allows the owner of the contract to toggle whether painting is allowed
    function togglePainting() public _ownerOnly {
        allowPaint = !allowPaint;
    }
}