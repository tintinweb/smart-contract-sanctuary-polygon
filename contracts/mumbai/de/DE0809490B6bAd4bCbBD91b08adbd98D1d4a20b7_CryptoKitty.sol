/**
 *Submitted for verification at polygonscan.com on 2023-05-25
*/

pragma solidity ^0.8.0;

contract CryptoKitty {
    struct Kitty {
        string color;
        uint8 reproductionCount;
    }

    Kitty[] public kitties;

    mapping(string => string) colorMix;

    mapping(uint => address) public kittyOwners;

    constructor() {
        colorMix["yellow&red"] = "pink";
        colorMix["yellow&blue"] = "green";
        colorMix["red&blue"] = "black";
    }

    function createKitty() public {
        require(kitties.length < 3, "Maximum kitties created");
        string memory color = _randomColor();
        kitties.push(Kitty(color, 0));
        uint256 newKittyId = kitties.length - 1;
        kittyOwners[newKittyId] = msg.sender;
    }

    function breedKitty(uint256 _kittyId1, uint256 _kittyId2) public {
        require(kittyOwners[_kittyId1] == msg.sender && kittyOwners[_kittyId2] == msg.sender, "You must own both kitties");
        require(kitties[_kittyId1].reproductionCount < 3 && kitties[_kittyId2].reproductionCount < 3, "Kitties can only reproduce 3 times");

        string memory color1 = kitties[_kittyId1].color;
        string memory color2 = kitties[_kittyId2].color;

        string memory childColor = _mixColors(color1, color2);

        kitties.push(Kitty(childColor, 0));
        uint256 newKittyId = kitties.length - 1;

        kitties[_kittyId1].reproductionCount++;
        kitties[_kittyId2].reproductionCount++;

        kittyOwners[newKittyId] = msg.sender;
    }

    function _randomColor() private view returns (string memory) {
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty))) % 3;
        if (rand == 0) {
            return "yellow";
        } else if (rand == 1) {
            return "red";
        } else {
            return "blue";
        }
    }

    function _mixColors(string memory color1, string memory color2) private view returns (string memory) {
        return colorMix[string(abi.encodePacked(color1, "&", color2))];
    }
}