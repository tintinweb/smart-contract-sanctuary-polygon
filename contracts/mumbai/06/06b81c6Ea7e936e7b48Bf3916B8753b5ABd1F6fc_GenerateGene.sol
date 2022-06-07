// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.10;

/// @notice BoxyHeroNFT interface, i just want to get the total supply
interface BoxyHeroNFT {
  function totalSupply() external returns (uint256);
}

/// @title This contract used to generate gene, randomize gene, or something related to gene. not the genie
/// @author Christopher Yu
contract GenerateGene {
  address public boxyHeroAddress;
  uint256[][] partsMatrix;
  uint256 maxProb = 100;
  uint256 maxArmorParts = 4;

  /// @notice creates a pseudo random uint256
  function random(uint256 nonce) internal view returns (uint256) {
    uint256 randomNumber = uint256(
      keccak256(abi.encodePacked(block.difficulty, block.timestamp, nonce))
    );

    return randomNumber;
  }

  function setBoxyHeroAddress(address newBoxyHeroAddress) public {
    boxyHeroAddress = newBoxyHeroAddress;
  }

  function setMaxArmorParts(uint256 newMaxArmorParts) public {
    maxArmorParts = newMaxArmorParts;
  }

  /// @notice setup the probability matrix
  function setPartsMatrix(uint256[][] memory parts) public {
    partsMatrix = parts;
  }

  function getPartsMatrix()
    public
    view
    returns (
      uint256[] memory,
      uint256[] memory,
      uint256[] memory,
      uint256[] memory,
      uint256[] memory,
      uint256[] memory
    )
  {
    return (
      partsMatrix[0],
      partsMatrix[1],
      partsMatrix[2],
      partsMatrix[3],
      partsMatrix[4],
      partsMatrix[5]
    );
  }

  function getTotalSupply() internal returns (uint256) {
    return BoxyHeroNFT(boxyHeroAddress).totalSupply();
  }

  /*  first [] is the part Id, and the second [] is the probability number with index as the Id for the armor
    [[10,30,100],[20,50,100],[30,50,100]]
   */
  function getRandomOriginGene() public returns (uint256) {
    uint256 tempNonce = uint256(
      keccak256(abi.encodePacked(uint256(getTotalSupply())))
    );

    uint256[6][3] memory randomedParts;
    // uint256 randomRandom;

    for (uint8 i = 0; i < 3; i++) {
      for (uint8 j = 0; j < 6; j++) {
        for (uint256 k = 0; k < partsMatrix[j].length; k++) {
          tempNonce++;
          if ((random(tempNonce) % maxProb) < partsMatrix[j][k]) {
            randomedParts[i][j] = k;
            break;
          }
        }
      }
    }

    uint256 randomClass = random(tempNonce) % 6;

    uint256 veryRandomGene = generateGene(
      randomedParts[0],
      randomedParts[1],
      randomedParts[2],
      randomClass
    );

    return veryRandomGene;
  }

  //creates a gene with 6 parts each with 3 genes each given as params
  function generateGene(
    uint256[6] memory DpartName,
    uint256[6] memory R1PartName,
    uint256[6] memory R2PartName,
    uint256 class
  ) public pure returns (uint256) {
    uint256 gene = 0;

    gene = class << 200; // 8 bits also, we can reduce it to 4 bits or something. Just want to make it 8(No reason why)

    for (uint8 i = 0; i < 6; i++) {
      // shift left 24 bits to get last 8 bits from 32 bits
      // shift left 16 bits to get last 16 bits from 32 bits
      // shift left 8 bits to get last 24 bits from 32 bits
      uint256 result = ((DpartName[i] << (32 * i)) << 24) |
        ((R1PartName[i] << (32 * i)) << 16) |
        ((R2PartName[i] << (32 * i)) << 8);
      gene |= result;
    }

    return gene;
  }

  // parses gene to return 3 arrays for every part in gene
  function parseGene(uint256 gene)
    public
    pure
    returns (
      uint256[] memory DPart,
      uint256[] memory R1Part,
      uint256[] memory R2Part,
      uint256 class
    )
  {
    uint256[] memory DpartNamePart = new uint256[](6);
    uint256[] memory R1partNamePart = new uint256[](6);
    uint256[] memory R2partNamePart = new uint256[](6);

    for (uint256 i = 0; i < 6; i++) {
      // shift right 24 to get 8 bits from the last of the first 32 bits,
      // still will get some amount of bits because we have 4 parts
      // & with 0xff to make sure we only take the 8 bits
      // and so on
      uint256 DpartName = (gene >> 24) & 0xff;
      uint256 R1partName = (gene >> 16) & 0xff;
      uint256 R2partName = (gene >> 8) & 0xff;

      // continue to parse the next 32 bits of the gene
      // this will make sure that the gene is 32 bits aligned
      gene = gene >> 32;

      DpartNamePart[i] = DpartName;
      R1partNamePart[i] = R1partName;
      R2partNamePart[i] = R2partName;
    }

    class = gene >> 8;
    DPart = DpartNamePart;
    R1Part = R1partNamePart;
    R2Part = R2partNamePart;
  }

  // function verifyBreeder(uint256 gene, bytes memory signature) internal view {
  //   require(verifySignature.verify(msg.sender, gene, signature) == true);
  // }

  // Still in testing
  function getOriginGene() public returns (uint256) {
    uint256[6][3] memory randomedParts;

    uint256 tempNonce = uint256(
      keccak256(abi.encodePacked(BoxyHeroNFT(boxyHeroAddress).totalSupply()))
    );

    for (uint8 i = 0; i < 3; i++) {
      for (uint8 j = 0; j < 6; j++) {
        uint256 randomRandom = random(tempNonce) % maxArmorParts;
        randomedParts[i][j] = randomRandom;

        tempNonce++;
      }
    }

    uint256 randomClass = random(tempNonce) % 5;

    uint256 veryRandomGene = generateGene(
      randomedParts[0],
      randomedParts[1],
      randomedParts[2],
      randomClass
    );

    return veryRandomGene;
  }

  function getOffspringGene(uint256 momGene, uint256 dadGene)
    public
    returns (uint256)
  {
    uint8[6][3] memory probArr = [
      [9, 13, 15, 24, 28, 30],
      [5, 10, 15, 20, 25, 30],
      [5, 10, 15, 20, 25, 30]
    ];

    (
      uint256[] memory momDPart,
      uint256[] memory momR1Part,
      uint256[] memory momR2Part,
      uint256 momClass
    ) = parseGene(momGene);
    (
      uint256[] memory dadDPart,
      uint256[] memory dadR1Part,
      uint256[] memory dadR2Part,
      uint256 dadClass
    ) = parseGene(dadGene);

    uint256[6][3] memory childParts;

    uint256 tempNonce = uint256(
      keccak256(abi.encodePacked(BoxyHeroNFT(boxyHeroAddress).totalSupply()))
    );

    // 3 loops for 3 genes, dominant, recessive 1, recessive 2
    for (uint8 i = 0; i < 3; i++) {
      // 6 loops for 6 parts(body, boots, heads, weapons, eyes, mouth)
      for (uint8 j = 0; j < 6; j++) {
        uint256 offspringProb = uint256(random(tempNonce)) % 30;
        if (offspringProb < probArr[i][0]) {
          // childDominant gets the momDparts
          childParts[i][j] = momDPart[j];
        } else if (offspringProb < probArr[i][1]) {
          // childDominant gets the momR1Parts
          childParts[i][j] = momR1Part[j];
        } else if (offspringProb < probArr[i][2]) {
          // childDominant gets the momR2Parts
          childParts[i][j] = momR2Part[j];
        } else if (offspringProb < probArr[i][3]) {
          // childDominant gets the dadDparts
          childParts[i][j] = dadDPart[j];
        } else if (offspringProb < probArr[i][4]) {
          // childDominant gets the dadR1parts
          childParts[i][j] = dadR1Part[j];
        } else if (offspringProb < probArr[i][5]) {
          // childDominant gets the dadR2parts
          childParts[i][j] = dadR2Part[j];
        }
        tempNonce++;
      }
    }

    uint256 randomClass;

    if (uint256(random(tempNonce)) % 2 == 1) randomClass = momClass;
    else randomClass = dadClass;

    // generate gene from child dominant, r1, and r2 parts
    uint256 offspringGene = generateGene(
      childParts[0],
      childParts[1],
      childParts[2],
      randomClass
    );

    return offspringGene;
  }
}
// 4 parts

// 2684478324332888378144872617140815104
// 6677374891575958144127869590897296128
// 6651372841847538701596802507471978752
// 2668860868632223081922131248061548032
// 2679265744139931091718083759745139712

// 4, 1, 3 ,2 | 3, 1, 4, 2 | 1, 3, 6, 5
// 3, 6, 4, 5 | 4, 2, 3, 5 | 2, 1, 4, 6
// 3, 3, 1, 3 | 5, 6, 1, 3 | 3, 6, 2, 4

// test with + = 5337762301144313382978054055146881280
// test with | = 5337762301144313382978054055146881280
// same because the bits per part are not in the same part of the 8 bits

// 6 parts
// 98464335112698257766625537368202663711796500919463576320
// 49330193411339848123002935403146890362136623470436811264
// 98658141904672422418661189413512228927486783291448757248