// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract NFTsAttributes {

  // all attributes
  string[7] backgrounds = ["purple", "red", "blue", "orange" , "gray", "dark", "aqua"]; // 7
  string[10] faces = ["zombie", "face1", "face2", "face3", "face4", "face5", "alien", "gold", "silver", "ice"]; // 10
  string[16] eyes = ["sunglasses", "angry", "silly", "helpless", "dead", "empty", "pirate", "shocked", "lady", "cyclop", "eyeballs", "love", "hypno", "focus", "ke", "look up"]; // 16
  string[15] heads = ["bald", "king", "semibald", "hairy", "punk", "unicorn", "curly", "blond", "grass", "double tails", "horns", "rufous", "angel", "brain", "knife"]; // 15
  string[14] mouths = ["tongue", "nope", "surprised", "goofy", "scream", "golden tooth", "squeezy", "rotten", "pacman", "sewn up", "mouth ball", "kiss", "vampire", "joint"]; // 12
  string[10] noses = ["snot", "pointy", "piggy", "lack", "greek", "worm", "ring", "clown", "stick", "ice cream"]; // 10
  

  struct chosenLayers {
    string bg;
    string face;
    string eyes;
    string head;
    string mouth;
    string nose;
  }


  function layersToString(
    uint256 bg,
    uint256 face,
    uint256 eye,
    uint256 head,
    uint256 mouth,
    uint256 nose
  ) external view returns(string memory) {

    uint256 faceIndex = getFaceIndex(face);

    return string(abi.encodePacked(
      backgrounds[bg - 1], ", ",
      faces[faceIndex], ", ",
      eyes[eye - 1], ", ",
      heads[head - 1], ", ",
      mouths[mouth - 1], ", ",
      noses[nose - 1]
    ));
  }



  function getChosenLayers(
    uint256 bg,
    uint256 face,
    uint256 eye,
    uint256 head,
    uint256 mouth,
    uint256 nose
  ) external view returns(chosenLayers memory) {

    uint256 faceIndex = getFaceIndex(face);

    return chosenLayers({
      bg: backgrounds[bg - 1],
      face: faces[faceIndex], 
      eyes: eyes[eye - 1],
      head: heads[head - 1],
      mouth: mouths[mouth - 1],
      nose: noses[nose - 1]
    });
  }


  function getFaceIndex(uint256 chosenNumber) internal pure returns(uint256) {

    if(chosenNumber >= 1 && chosenNumber <= 13) {
      return 0;
    }

    if(chosenNumber >= 14 && chosenNumber <= 26) {
      return 1;
    }

    if(chosenNumber >= 27 && chosenNumber <= 39) {
      return 2;
    }

    if(chosenNumber >= 40 && chosenNumber <= 52) {
      return 3;
    }

    if(chosenNumber >= 53 && chosenNumber <= 65) {
      return 4;
    }

    if(chosenNumber >= 66 && chosenNumber <= 78) {
      return 5;
    }

    if(chosenNumber >= 79 && chosenNumber <= 91) {
      return 6;
    }

    if(chosenNumber == 92) {
      return 7;
    }

    if(chosenNumber == 93 || chosenNumber == 94) {
      return 8;
    }

    if(chosenNumber >= 95 && chosenNumber <= 100) {
      return 9;
    }


    revert("Wrong number");
  }


}