//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Params } from "./Params.sol";
import { NFTSVG } from "./NFTSVG.sol";
import { Base64 } from "@openzeppelin/contracts/utils/Base64.sol";

contract SVGProvider {
  Params.Character[] public CHARACTERS_T;

  Params.Character[] public CHARACTERS_R;

  Params.Character[] public CHARACTERS_U;

  Params.Character[] public CHARACTERS_H;

  Params.Character[] public CHARACTERS_DOT;

  Params.Character[] public CHARACTERS_A;

  Params.Character[] public CHARACTERS_F;

  constructor() {
    CHARACTERS_T.push(Params.Character({ path: "M0,48H48V64H32v96H16V64H0Z", width: 48 }));
    CHARACTERS_T.push(Params.Character({ path: "M56,128v16H48v16H24V144H16V96H0V80H16V48H32V80H48V96H32v48h8V128Z", width: 56 }));
    CHARACTERS_T.push(Params.Character({ path: "M64,80v32H40v48H24V112H0V80H24V32H40V80Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M40,80v32H16v48H0V32H16V80Z", width: 40 }));
    CHARACTERS_T.push(Params.Character({ path: "M0,48H8V32H40V48h8V64H32V48H16V64H0Zm32,96H16V64H32Z", width: 48 }));
    CHARACTERS_T.push(Params.Character({ path: "M8,48H24V80h8V96H24v48H56v16H8V112H0V96H8Z", width: 56 }));
    CHARACTERS_T.push(Params.Character({ path: "M0,96V80H16V48H32V80H48V96H32v32H16V96Z", width: 48 }));
    CHARACTERS_T.push(Params.Character({ path: "M64,80H0V64H64ZM24,160H16V128H0V112H24Zm40-32H48v32H40V112H64Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M16,64V32h8V80H0V64Zm8,96H16V128H0V112H24ZM64,80H40V32h8V64H64Zm0,48H48v32H40V112H64Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M64,80v32H40v48H24V112H0V80Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M64,80v32H40v48H24V112H0V80H24V32H40V80Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M64,80V96H40v16H64v16H40v32H24V128H0V112H24V96H0V80H24V32H40V80Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M0,96V80H64V96Zm0,32V112H64v16H40v32H24V128Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M0,160V32H32V64H64V96H32v32H64v32Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M0,32H64V160H0ZM56,96V80H40V48H24V80H8V96H24v32H40V96Z", width: 64 }));
    CHARACTERS_T.push(Params.Character({ path: "M0,32H64V160H0Zm56,96H40V80H56V64H40V48H24V64H8V80H24v48h8v16H56Z", width: 64 }));

    CHARACTERS_R.push(Params.Character({ path: "M0,48H40V64h8V96H40v16H32v16h8v16h8v16H32V144H24V128H16v32H0ZM32,64H16V96H32Z", width: 48 }));
    CHARACTERS_R.push(Params.Character({ path: "M0,160V80H40V96h8v16H32V96H16v64Z", width: 48 }));
    CHARACTERS_R.push(Params.Character({ path: "M0,32H64V96H32V64H0Zm0,96V96H32v32Zm64,32H32V128H64Z", width: 64 }));
    CHARACTERS_R.push(Params.Character({ path: "M48,64V80H8v80H0V64Zm0,64H32v32H24V112H48Z", width: 48 }));
    CHARACTERS_R.push(Params.Character({ path: "M0,160V96H64v32H32v32Z", width: 64 }));
    CHARACTERS_R.push(Params.Character({ path: "M40,80H16v32H8v16H32v16h8v16H16V144H8v16H0V64H8V48h8V32H40Z", width: 40 }));
    CHARACTERS_R.push(Params.Character({ path: "M8,64v48H0V64Zm8-16V64H8V48ZM8,128V112h8v16ZM40,32V48H16V32ZM32,96H24v16H16V64H40V80H32Zm8,32v16H16V128Zm0-32v16H32V96Zm8-32H40V48h8Zm0,48v16H40V112Zm8,0H48V64h8Z", width: 56 }));
    CHARACTERS_R.push(Params.Character({ path: "M40,80v32H16v48H0V80Z", width: 40 }));

    CHARACTERS_U.push(Params.Character({ path: "M0,48H16v80H32V48H48v80H40v16H32v16H16V144H8V128H0Z", width: 48 }));
    CHARACTERS_U.push(Params.Character({ path: "M48,144H40v16H8V144H0V80H16v64H32V80H48Z", width: 48 }));
    CHARACTERS_U.push(Params.Character({ path: "M0,32H64V160H0ZM8,48V80h8v32h8v32H40V112h8V80h8V48Z", width: 64 }));
    CHARACTERS_U.push(Params.Character({ path: "M40,80H32V64H8V80H0V48H40ZM8,80h8v32H8Zm16,64H16V112h8Zm8-32H24V80h8Z", width: 40 }));
    CHARACTERS_U.push(Params.Character({ path: "M56,112v16H48v16H40v16H24V144H16V128H8V112H0V80H8V64h8V48h8V32H40V64H32V80H24v32H40V96h8V80H64v32Z", width: 64 }));
    CHARACTERS_U.push(Params.Character({ path: "M56,112v16H48v16H40v16H24V144H16V128H8V112H0V80H16V96h8v16H40V80H32V64H24V32H40V48h8V64h8V80h8v32Z", width: 64 }));
    CHARACTERS_U.push(Params.Character({ path: "M56,112v16H48v16H40v16H24V144H16V128H8V112H0V80H16V96h8v16H40V96h8V80H64v32Z", width: 64 }));
    CHARACTERS_U.push(Params.Character({ path: "M48,128H40v16H32v16H16V144H8V128H0V80H16v48H32V80H48Z", width: 48 }));
    CHARACTERS_U.push(Params.Character({ path: "M0,48H16v80H32V48H48v80H40v16H32v16H16V144H8V128H0Z", width: 48 }));
    CHARACTERS_U.push(Params.Character({ path: "M48,160H8V144H0V80H16v64H32V80H48Z", width: 48 }));

    CHARACTERS_H.push(Params.Character({ path: "M48,48V160H32V112H16v48H0V48H16V96H32V48Z", width: 48 }));
    CHARACTERS_H.push(Params.Character({ path: "M0,48H16V80H40V96h8v64H32V96H16v64H0Z", width: 48 }));
    CHARACTERS_H.push(Params.Character({ path: "M0,48H16V64H32V48H48V160H32V144H16v16H0ZM16,96H32V80H16Zm0,16v16H32V112Z", width: 48 }));
    CHARACTERS_H.push(Params.Character({ path: "M8,48H24V80H40V48H56V80h8V96H56v16h8v16H56v32H40V128H24v32H8V128H0V112H8V96H0V80H8Zm16,64H40V96H24Z", width: 64 }));
    CHARACTERS_H.push(Params.Character({ path: "M8,32V48h8V64h8V80H40V64h8V48h8V32h8V160H56V144H48V128H40V112H24v16H16v16H8v16H0V32Z", width: 64 }));
    CHARACTERS_H.push(Params.Character({ path: "M0,32H8V160H0ZM23.88,80V32h-8V160h8V112H37.25v16H61.12v32h8V112H39.79V96H69.08V32h-8V80M77,32V160h8V32Z", width: 85 }));
    CHARACTERS_H.push(Params.Character({ path: "M23.94,128v32H16V112H59v48h-8V128M0,160H8V32H0ZM59,96V32h-8V80H23.94V32H16V96M67,32V160h8V32Z", width: 75 }));
    CHARACTERS_H.push(Params.Character({ path: "M0,32H15.93V160H0Zm56.07,0V80H32.18v32H56.07v48H72V32Z", width: 72 }));

    CHARACTERS_DOT.push(Params.Character({ path: "M16,160H0V128H16Z", width: 16 }));
    CHARACTERS_DOT.push(Params.Character({ path: "M16,144H0V112H16Z", width: 16 }));
    CHARACTERS_DOT.push(Params.Character({ path: "M48,110H0V94H48Z", width: 48 }));
    CHARACTERS_DOT.push(Params.Character({ path: "M0,64H16V80H0Zm16,66H0V114H16Z", width: 16 }));
    CHARACTERS_DOT.push(Params.Character({ path: "M8,48H24V64H40V48H56V64H48V80H64V96H48v16h8v16H40V112H24v16H8V112h8V96H0V80H16V64H8Z", width: 64 }));

    CHARACTERS_A.push(Params.Character({ path: "M0,160V80H8V64h8V48H32V64h8V80h8v80H32V112H16v48ZM16,96H32V80H16Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M8,80H40V96h8v64H8V144H0V128H8V112H32V96H8Zm8,64H32V128H16Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M8,144H24V96H40v48H56V64H48V48H40V32H64V160H0V32H24V48H16V64H8ZM24,80V64H40V80Z", width: 64 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,160H32V144H16v16H0V64H8V48h8V32H32V48h8V64h8ZM16,80v32H32V80Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,144V128H8V112h8V80H8V64h8V48h8V32H40V48h8V64h8V80H48v32h8v16h8v16H48V128H40V112H24v16H16v16ZM24,80H40V64H24Z", width: 64 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,48H8V32H40V48h8V96H24V64h8V48H16v80H40v16H8V128H0Zm48,64v16H40V112Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,32H64V160H0ZM16,64V80H40V96H16v16H8v16h8v16H56V80H48V64Zm8,64V112H40v16Z", width: 64 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,32H8V48H0ZM8,64h8V48H32V64h8V80h8v64H32V112H16v32H0V80H8Zm8,32H32V80H16ZM40,32h8V48H40Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,112H8V96H0V80H8V64H32V48H8V32H40V48h8ZM16,80V96H32V80Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,144V80H8V48h8V64H32V48h8V80h8v64H32V112H16v32ZM32,48H16V32H32ZM16,80V96H32V80Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,80v64H8V128H0V112H8V96H32V80H8V48h8V32H40V48h8V64H40V80ZM16,128H32V112H16ZM32,48H24V64h8Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M64,80v32H40v16H64v16H8V128H0V112H8V96H24V80H8V64H56V80ZM16,128h8V112H16ZM48,96V80H40V96Z", width: 64 }));
    CHARACTERS_A.push(Params.Character({ path: "M8,64h8V48H8V32H24V48h8V64h8V80h8v64H8V128H0V112H8V96H32V80H8Zm8,64H32V112H16Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,48H8V32H40V48h8V64H40V80h8v64H32V112H16v32H0V80H8V64H0Zm32,0H16V64H32ZM16,96H32V80H16Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,96H32V80H16V96H0V80H8V64h8V48H32V64h8V80h8Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,128h8v32H0V128H8V96h8V64h8V32h8V64h8V96h8Z", width: 56 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,112H32v16h8v16h8v16H32V144H16v16H0V144H8V128h8V112H0V96H8V80h8V64H32V80h8V96h8ZM8,64V48h8V64ZM32,32V48H16V32Zm0,16h8V64H32Z", width: 48 }));
    CHARACTERS_A.push(Params.Character({ path: "M48,128h8v32H0V128H8v16H48Zm-32,0H8V96h8Zm8-64V96H16V64Zm0-32h8V64H24ZM40,96H32V64h8Zm8,0v32H40V96Z", width: 56 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,144V128H8V112h8v16h8v16Zm56-16h8v16H32V128h8V112H16V96h8V80h8V96h8V80H32V64h8V48h8V32h8Z", width: 64 }));
    CHARACTERS_A.push(Params.Character({ path: "M0,144V64H8V48h8V32H48V48H40V80h8V96H40v32h8v16H24V96H16v48ZM16,80h8V64H16Z", width: 48 }));

    CHARACTERS_F.push(Params.Character({ path: "M0,48H48V64H16V96H32v16H16v48H0Z", width: 48 }));
    CHARACTERS_F.push(Params.Character({ path: "M8,160V112H0V96H8V64h8V48H40V64h8V80H32V64H24V96h8v16H24v48Z", width: 48 }));
    CHARACTERS_F.push(Params.Character({ path: "M40,80V96H8v64H0V80Zm0,48H24v32H16V112H40Z", width: 40 }));
    CHARACTERS_F.push(Params.Character({ path: "M40,80V96H16v16H40v16H16v32H0V80Z", width: 40 }));
    CHARACTERS_F.push(Params.Character({ path: "M0,160V64H32V96H64v32H32v32ZM64,64H32V32H64Z", width: 64 }));
    CHARACTERS_F.push(Params.Character({ path: "M0,32H64V160H0ZM56,96V80H40V64H56V48H32V64H24V80H16V96h8v48H40V96Z", width: 64 }));
    CHARACTERS_F.push(Params.Character({ path: "M0,48H8V32H40V48h8V64H32V48H16V80h8V96h8v16H16V96H8V80H0Zm32,96H16V128H32Z", width: 48 }));
    CHARACTERS_F.push(Params.Character({ path: "M0,144V128H8V112h8V96H8V80h8V64h8V48h8V80H48V96H32v16H24v16H48v16ZM48,48H32V32H48Zm8,16H48V48h8Zm0,48v16H48V112Z", width: 56 }));
  }

  function generateSVG(Params.SVGParams memory _params, bool _isFull) public view returns (string memory) {
    Params.Character[][8] memory characters;
    characters[0] = CHARACTERS_T;
    characters[1] = CHARACTERS_R;
    characters[2] = CHARACTERS_U;
    characters[3] = CHARACTERS_T;
    characters[4] = CHARACTERS_H;
    characters[5] = CHARACTERS_DOT;
    characters[6] = CHARACTERS_A;
    characters[7] = CHARACTERS_F;

    if (_isFull) {
      return
      string(
        abi.encodePacked(
          "data:image/svg+xml;base64,",
          Base64.encode(
            NFTSVG.generateFullSVG(
              //
              characters,
              _params
            )
          )
        )
      );
    }

    return
      string(
        abi.encodePacked(
          "data:image/svg+xml;base64,",
          Base64.encode(
            NFTSVG.generateCoreSVG(
              //
              characters,
              _params
            )
          )
        )
      );
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

library Params {
  struct Character {
    bytes path;
    uint8 width;
  }

  struct FilterNoiseParams {
    bytes frequency;
    uint16 seed;
    uint8 numOctaves;
    uint8 duration;
  }

  struct SVGParams {
    uint8 pattern_id;
    uint8 pixelate_id;
    FilterNoiseParams[3] filterNoise;
    bytes background_color;
    bytes folder_color;
    bytes screen_color;
    bytes content_color;
    bytes truth_color;
    bytes pattern_color;
    uint8[8] character_ids;
  }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Params } from "./Params.sol";

library NFTSVG {
  bytes constant patternId = "pattern";

  bytes constant filterNoiseRedId = "filter_noise_r";
  bytes constant filterNoiseGreenId = "filter_noise_g";
  bytes constant filterNoiseBlueId = "filter_noise_b";

  bytes constant filterPixelate16Id = "filter_pixel_16";
  bytes constant filterPixelate32Id = "filter_pixel_32";

  bytes constant filterDropshadowBGId = "filter_ds_background";

  bytes constant filterGreyBGId = "filter_grey_background";

  bytes constant filterOverlayBGId = "filter_overlay_background";

  bytes constant filterDropshadowFDId = "filter_ds_folder";
  bytes constant filterDropshadowScreenId = "filter_ds_screen";
  bytes constant filterDropshadowTitleId = "filter_ds_title";

  function generateFullSVG(Params.Character[][8] memory _characters, Params.SVGParams memory _params) internal pure returns (bytes memory) {
    return
      bytes.concat(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">',
        generateStyles(_params),
        bytes.concat(
          "<defs>", //
          generateBackgroundDefs(_params),
          generateKernelDefs(_params),
          "</defs>"
        ),
        bytes.concat(
          generateBackground(),
          generateFolder(_characters, _params.character_ids), //
          generateScreen(),
          generateTitle(_characters, _params.character_ids)
        ),
        "</svg>"
      );
  }

  function generateCoreSVG(Params.Character[][8] memory _characters, Params.SVGParams memory _params) internal pure returns (bytes memory) {
    return
      bytes.concat(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1024 1024">',
        generateStyles(_params),
        bytes.concat(
          "<defs>", //
          generateKernelDefs(_params),
          "</defs>"
        ),
        bytes.concat(
          generateFolder(_characters, _params.character_ids), //
          generateScreen(),
          generateTitle(_characters, _params.character_ids)
        ),
        "</svg>"
      );
  }

  function generateBackgroundDefs(Params.SVGParams memory _params) internal pure returns (bytes memory) {
    return
      bytes.concat(
        generatePattern(_params), // done
        generateFilterNoise(_params.filterNoise[0], filterNoiseRedId, "1 0 0"), // red // done
        generateFilterNoise(_params.filterNoise[1], filterNoiseGreenId, "0 1 0"), // green // done
        generateFilterNoise(_params.filterNoise[2], filterNoiseBlueId, "0 0 1"), // blue // done
        generateFilterPixelate(0), // 16 pixel // done
        generateFilterPixelate(1), // 32 pixel // done
        generateFilterDropshadow(filterDropshadowBGId), //
        generateFilterGrey(filterGreyBGId),
        generateFilterOverlay(filterOverlayBGId)
      );
  }

  function generateKernelDefs(Params.SVGParams memory _params) internal pure returns (bytes memory) {
    return
      bytes.concat(
        generateFilterDropshadow(filterDropshadowFDId), //
        generateFilterDropshadow(filterDropshadowScreenId),
        generateFilterDropshadow(filterDropshadowTitleId)
      );
  }

  function generateStyles(Params.SVGParams memory _params) internal pure returns (bytes memory) {
    return
      bytes.concat(
        '<style type="text/css">',
        bytes.concat(".b{fill:#", _params.background_color, ";}"), // background
        bytes.concat(".colB{fill:#", "0000FF", ";}"), // background
        bytes.concat(".f{fill:#", _params.folder_color, ";}"), // folder
        bytes.concat(".s{fill:#", _params.screen_color, ";}"), // screen
        bytes.concat(".c{fill:#", _params.content_color, ";}"), // content
        bytes.concat(".t{fill:#", _params.truth_color, ";}"), // truth
        bytes.concat(".p{fill:#", _params.pattern_color, ";}"), // pattern
        "</style>"
      );
  }

  // done
  function generatePattern(Params.SVGParams memory _params) internal pure returns (bytes memory) {
    uint8 _id = _params.pattern_id % 10;
    string[10] memory width = ["32", "32", "32", "48", "64", "96", "48", "96", "128", "128"];
    string[10] memory height = ["32", "32", "32", "48", "32", "48", "96", "64", "64", "112"];
    string[10] memory path = [
      "M0 0h16v16H0zM16 16h16v16H16z", //
      "M0 16h32v16H0z",
      "M0 0h16v32H0z",
      "M0 0h16v16H0zM16 16h16v16H16zM32 0h16v16H32zM0 32h16v16H0zM32 32h16v16H32z",
      "M0 0h32v16H0zM16 16h32v16H16z",
      "M0 0h32v16H0zM32 16h32v16H32zM64 32h32v16H64z",
      "M0 64h16v32H0zM16 32h16v32H16zM32 0h16v32H32z",
      "M0 0h32v32H0zM32 16h32v32H32zM64 32h32v32H64z",
      "M0 0h32v32H0zM32 16h32v32H32zM64 32h32v32H64zM96 48h32v16H96zM96 0h32v16H96z",
      "M0 0h32v56H0zM32 28h32v56H32zM64 56h32v56H64zM96 84h32v28H96zM96 0h32v28H96z"
    ];

    return
      bytes.concat(
        bytes.concat('<pattern id="', patternId, '" patternUnits="userSpaceOnUse" width="', bytes(width[_id]), '" height="', bytes(height[_id]), '">'), //
        '<g class="p">',
        bytes.concat('<path d="', bytes(path[_id]), '"/>'),
        "</g>",
        "</pattern>"
      );
  }

  // done
  function generateFilterNoise(
    Params.FilterNoiseParams memory _params,
    bytes memory _id,
    bytes memory _noiseColor
  ) internal pure returns (bytes memory) {
    return
      bytes.concat(
        bytes.concat('<filter id="', _id, '" x="0" y="0" width="100%" height="100%">'),
        bytes.concat('<feTurbulence type="fractalNoise" baseFrequency="', _params.frequency, '" seed="', bytes(Strings.toString(_params.seed)), '" numOctaves="', bytes(Strings.toString(_params.numOctaves)), '"/>'), // dynamic
        '<feColorMatrix type="hueRotate" values="0">',
        bytes.concat('<animate attributeName="values" from="0" to="360" dur="', bytes(Strings.toString(_params.duration)), '" repeatCount="indefinite"/>'), // dynamic
        "</feColorMatrix>",
        '<feComponentTransfer><feFuncR type="discrete" tableValues="0 0 1"/><feFuncG type="discrete" tableValues="0 0 1"/><feFuncB type="discrete" tableValues="0 1"/></feComponentTransfer>',
        bytes.concat('<feColorMatrix values="1 0 0 0 0 -1 1 0 0 0 -1 -1 1 0 0 ', _noiseColor, ' 0 0"/>'), // dynamic
        "</filter>"
      );
  }

  // done
  function generateFilterPixelate(uint8 _id) internal pure returns (bytes memory) {
    _id = _id % 2;
    bytes[2] memory id = [filterPixelate16Id, filterPixelate32Id];
    string[5][2] memory options = [
      ["7.5", "7.5", "15", "15", "7.5"], //
      ["15.5", "15.5", "31", "31", "15.5"]
    ];
    return
      bytes.concat(
        bytes.concat('<filter id="', id[_id], '" x="0" y="0">'),
        bytes.concat('<feFlood x="', bytes(options[_id][0]), '" y="', bytes(options[_id][1]), '" height="1" width="1"/>'), // dynamic
        bytes.concat('<feComposite height="', bytes(options[_id][2]), '" width="', bytes(options[_id][3]), '"/>'), // dynamic
        '<feTile result="a"/><feComposite in="SourceGraphic" in2="a" operator="in"/>',
        bytes.concat('<feMorphology operator="dilate" radius="', bytes(options[_id][4]), '"/>'), // dynamic
        "</filter>"
      );
  }

  // cessing
  // note: color group should be change
  function generateFilterDropshadow(bytes memory _id) internal pure returns (bytes memory) {
    bytes memory feDropShadows;
    {
      bytes[8] memory delta = [bytes("2"), "2", "2", "2", "4", "4", "-2", "-2"];
      bytes[8] memory colors = [bytes("#999"), "#999", "#666", "#666", "#1A1A1A", "#1A1A1A", "#1A1A1A", "#1A1A1A"];

      bytes memory d;
      for (uint8 i = 0; i < 8; i++) {
        if (i % 2 == 0) {
          d = bytes.concat('dx="', delta[i], '" dy="0"');
        } else {
          d = bytes.concat('dx="0" dy="', delta[i], '"');
        }

        if (i == delta.length - 1) {
          d = bytes.concat(d, ' result="dsOUT"');
        }
        feDropShadows = bytes.concat(feDropShadows, bytes.concat('<feDropShadow stdDeviation="0" ', d, ' flood-color="', colors[i], '"/>'));
      }
    }
    return
      bytes.concat(
        bytes.concat('<filter id="', _id, '" x="0" y="0" width="100%" height="100%">'),
        feDropShadows,
        '<feOffset dx="2" dy="2" height="100%" in="SourceGraphic" result="offset1"/>',
        '<feComposite in="SourceGraphic" in2="offset1" operator="out" width="100%" height="100%" result="composite1"/>',
        bytes.concat('<feColorMatrix type="matrix" values="1 0 0 0 0.', "9", " 0 1 0 0 0.", "9", " 0 0 1 0 0.", "9", ' 0 0 0 1 0" in="composite1" result="colormatrix1"/>'),
        '<feMerge result="merge1"><feMergeNode in="dsOUT"/><feMergeNode in="colormatrix1"/></feMerge>',
        "</filter>"
      );
  }

  // cessing
  function generateFilterGrey(bytes memory _id) internal pure returns (bytes memory) {
    bytes memory values = ".132 .318 .603";
    return
      bytes.concat(
        bytes.concat('<filter id="', _id, '">'), //
        bytes.concat('<feColorMatrix values="', values, " 0 0 ", values, " 0 0 ", values, ' 0 0 0 0 0 1 0"/>'),
        "</filter>"
      );
  }

  // cessing
  function generateFilterOverlay(bytes memory _id) internal pure returns (bytes memory) {
    return
      bytes.concat(
        bytes.concat('<filter id="', _id, '" x="-20%" y="-20%" width="140%" height="140%" filterUnits="objectBoundingBox" primitiveUnits="userSpaceOnUse" color-interpolation-filters="linearRGB">'), //
        bytes.concat('<feFlood flood-color="', "#28c3e2", '" flood-opacity="1" x="0%" y="0%" width="100%" height="100%" result="flood"/>'),
        '<feBlend mode="color" x="0%" y="0%" width="100%" height="100%" in="flood" in2="SourceGraphic" result="blend"/>',
        "</filter>"
      );
  }

  // cessing
  // note: each filter noise color will have a filter pixelate id
  function generateBackground() internal pure returns (bytes memory) {
    bytes memory tmp;
    {
      bytes[3] memory pixelates = [filterPixelate32Id, filterPixelate16Id, filterPixelate16Id];
      bytes[3] memory noises = [filterNoiseRedId, filterNoiseBlueId, filterNoiseGreenId];
      for (uint8 i = 0; i < 3; i++) {
        tmp = bytes.concat(
          tmp, //
          bytes.concat('<g filter="url(#', filterGreyBGId, ')">'),
          bytes.concat('<g filter="url(#', filterDropshadowBGId, ')">'),
          bytes.concat('<g filter="url(#', pixelates[i], ')">'),
          bytes.concat('<rect x="0" y="0" width="100%" height="100%" filter="url(#', noises[i], ')"/>'),
          "</g>",
          "</g>",
          "</g>"
        );
      }
    }

    return
      bytes.concat(
        bytes.concat('<g filter="url(#', filterOverlayBGId, ')">'), //
        bytes.concat('<g filter="url(#', filterGreyBGId, ')">'),
        bytes.concat('<rect width="100%" height="100%" class="colB"/>'),
        bytes.concat('<g filter="url(#', filterDropshadowBGId, ')">'),
        bytes.concat('<rect width="100%" height="100%" fill="url(#', patternId, ')" />'),
        "</g>",
        "</g>",
        tmp,
        "</g>"
      );
  }

  function generateFilterDropshadowScreen() internal pure returns (bytes memory) {
    return
      bytes.concat(
        '<filter id="FT_ds_s">',
        bytes.concat('<feDropShadow stdDeviation="0" dx="2" dy="0" flood-color="', "#F5D4E5", '"/>'), // dynamic
        bytes.concat('<feDropShadow stdDeviation="0" dx="0" dy="2" flood-color="', "#F5D4E5", '"/>'),
        bytes.concat('<feDropShadow stdDeviation="0" dx="-2" dy="0" flood-color="', "#BD83B9", '"/>'),
        bytes.concat('<feDropShadow stdDeviation="0" dx="0" dy="-2" flood-color="', "#BD83B9", '"/>'),
        bytes.concat('<feDropShadow stdDeviation="0" dx="4" dy="0" flood-color="', "#FFFFFF", '"/>'),
        bytes.concat('<feDropShadow stdDeviation="0" dx="0" dy="4" flood-color="', "#FFFFFF", '"/>'),
        bytes.concat('<feDropShadow stdDeviation="0" dx="-2" dy="0" flood-color="', "#884095", '"/>'),
        bytes.concat('<feDropShadow stdDeviation="0" dx="0" dy="-2" flood-color="', "#884095", '"/>'),
        "</filter>"
      );
  }

  // done
  function generateFolder(Params.Character[][8] memory _characters, uint8[8] memory _charactersIds) internal pure returns (bytes memory) {
    uint8 pad = 47;
    uint8 gap = 12;
    uint16 translateX = 208;
    for (uint8 i = 0; i < 8; i++) {
      translateX += _characters[i][_charactersIds[i]].width + gap;
    }
    uint16 x3 = translateX + pad - gap;
    uint16 x2 = x3 - 16;
    uint16 x1 = x2 - 16;
    bytes memory corner = bytes.concat(
      //
      bytes(Strings.toString(x3)),
      " 320 ",
      bytes(Strings.toString(x3)),
      " 192 ",
      bytes(Strings.toString(x2)),
      " 192 ",
      bytes(Strings.toString(x2)),
      " 176 ",
      bytes(Strings.toString(x1)),
      " 176 ",
      bytes(Strings.toString(x1))
    );
    return
      bytes.concat(
        bytes.concat('<g class="f" filter="url(#', filterDropshadowFDId, ')">'), //
        bytes.concat(
          '<polygon points="192 160 192 176 176 176 176 192 160 192 160 832 176 832 176 848 192 848 192 864 832 864 832 848 848 848 848 832 864 832 864 336 848 336 848 320 ', //
          corner,
          ' 160 192 160"/>'
        ),
        "</g>"
      );
  }

  function generateScreen() internal pure returns (bytes memory) {
    return
      bytes.concat(
        bytes.concat('<g class="s" filter="url(#', filterDropshadowScreenId, ')">'), //
        '<rect x="208" y="368" width="608" height="448"/>',
        "</g>"
      );
  }

  // done
  function generateTitle(Params.Character[][8] memory _characters, uint8[8] memory _charactersIds) internal pure returns (bytes memory) {
    uint8 gap = 12;
    uint16 translateX = 208;
    bytes memory truth;
    for (uint8 i = 0; i < 8; i++) {
      if (i > 0) {
        translateX += _characters[i - 1][_charactersIds[i - 1]].width + gap;
      }
      if (i == 7) {
        translateX -= gap;
      }
      truth = bytes.concat(truth, bytes.concat("<path", ' transform="translate(', bytes(Strings.toString(translateX)), ',183)" d="', _characters[i][_charactersIds[i]].path, '"/>'));
    }
    return bytes.concat(bytes.concat('<g class="t" filter="url(#', filterDropshadowTitleId, ')">'), truth, "</g>");
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}