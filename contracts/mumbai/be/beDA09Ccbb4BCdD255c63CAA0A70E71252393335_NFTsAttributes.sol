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

    return string(abi.encodePacked(
      backgrounds[bg - 1], ", ",
      faces[face - 1], ", ",
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

    return chosenLayers({
      bg: backgrounds[bg - 1],
      face: faces[face - 1], 
      eyes: eyes[eye - 1],
      head: heads[head - 1],
      mouth: mouths[mouth - 1],
      nose: noses[nose - 1]
    });
  }




}