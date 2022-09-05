//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "./Base64.sol";
import "./interfaces/IDhedgeStakingV2Storage.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// This is a standalone contract responsible for generating the token metadata and image encoded as base64 json
// It is a seperate contract because of the contract size restriction of 24kb
contract DhedgeStakingV2NFTJson {
  using SafeMath for uint256;

  /// @notice Generates the tokenUri base64 including the svg
  /// @param tokenId the erc721 tokenId
  /// @param stake the stake struct
  /// @param vDHT the amount of accrued vdht for the stake
  /// @param rewards the amount of rewards accrued for the stake
  /// @param poolSymbol the symbol of the staked pool tokens
  /// @param currentTokenPrice the price of the pool tokens staked
  /// @param dhtAddress the address of dht
  /// @param owner the owner of the stake
  /// @return tokenJson base64 encoded json payload
  function tokenJson(
    uint256 tokenId,
    IDhedgeStakingV2Storage.Stake memory stake,
    uint256 vDHT,
    uint256 rewards,
    string memory poolSymbol,
    uint256 currentTokenPrice,
    address dhtAddress,
    address owner
  ) public view returns (string memory) {
    string memory svgData = getSvg(stake, vDHT, poolSymbol, currentTokenPrice, rewards, dhtAddress, owner);
    currentTokenPrice;
    // Need to add pool token information here
    string memory json = Base64.encode(
      // solhint-disable quotes
      bytes(
        string(
          abi.encodePacked(
            "{",
            '"name": "DHT Stake: ',
            Strings.toString(tokenId),
            '",',
            '"description": "vDHT Accruing DHT stake",',
            '"image_data": "',
            bytes(svgData),
            '",',
            '"attributes": ',
            "[",
            '{"trait_type": "Staked DHT", "value":',
            Strings.toString(stake.dhtAmount),
            " },",
            '{"trait_type": "vDHT", "value":',
            Strings.toString(vDHT),
            "}",
            "]",
            "}"
          )
        )
      )
      // solhint-enable quotes
    );
    return string(abi.encodePacked("data:application/json;base64,", json));
  }

  /// @notice Generates svg string (not encoded)
  /// @param stake the stake struct
  /// @param vDHT the amount of accrued vdht for the stake
  /// @param rewards the amount of rewards accrued for the stake
  /// @param poolSymbol the symbol of the staked pool tokens
  /// @param currentTokenPrice the price of the pool tokens staked
  /// @param dhtAddress the address of dht
  /// @param owner the owner of the stake
  /// @return svg unencoded svg
  function getSvg(
    IDhedgeStakingV2Storage.Stake memory stake,
    uint256 vDHT,
    string memory poolSymbol,
    uint256 currentTokenPrice,
    uint256 rewards,
    address dhtAddress,
    address owner
  ) internal view returns (string memory) {
    string[3] memory mainParts;
    //<stop offset='1e-05' stop-color='#ff918f' stop-opacity='1'/><stop offset='1' stop-color='#ff0066' stop-opacity='1'/>
    mainParts[
      0
    ] = "<?xml version='1.0' encoding='UTF-8'?> <svg width='599' height='844' font-family='Arial' viewBox='0 0 599 844' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>";
    string memory guts;

    // We split these up because of stack to deep
    {
      string memory ownerStr = addressToString(owner);
      uint256 ownerLength = bytes(ownerStr).length;
      string memory poolStr = addressToString(stake.dhedgePoolAddress);
      uint256 poolLength = bytes(poolStr).length;
      string memory color1 = string(abi.encodePacked("#", substring(ownerStr, ownerLength.sub(6), ownerLength)));
      string memory color2 = string(abi.encodePacked("#", substring(poolStr, poolLength.sub(6), poolLength)));
      guts = string(
        abi.encodePacked(
          "<g id='Group'>"
          "<linearGradient id='linearGradient1' x1='14.8' y1='14.5' x2='584.4' y2='14.5' gradientUnits='userSpaceOnUse'>"
          "<stop offset='1e-05' stop-color='",
          color1,
          "' stop-opacity='1'/>"
          "<stop offset='1' stop-color='",
          color2,
          "' stop-opacity='1'/>"
          "</linearGradient>"
          "<path id='Path' fill='url(#linearGradient1)' stroke='none' d='M 40.100006 828.700012 C 26.199997 828.700012 14.800003 817.400024 14.800003 803.400024 L 14.800003 39.799988 C 14.800003 25.900024 26.100006 14.5 40.100006 14.5 L 559.099976 14.5 C 573 14.5 584.400024 25.799988 584.400024 39.799988 L 584.400024 803.5 C 584.400024 817.400024 573.099976 828.799988 559.099976 828.799988 L 40.100006 828.799988 Z'/>"
          "<path id='path1' fill='url(#linearGradient1)' stroke='none' d='M 559.099976 29 C 565 29 569.900024 33.799988 569.900024 39.799988 L 569.900024 803.5 C 569.900024 809.400024 565.099976 814.299988 559.099976 814.299988 L 40.100006 814.299988 C 34.199997 814.299988 29.300003 809.5 29.300003 803.5 L 29.300003 39.799988 C 29.300003 33.900024 34.100006 29 40.100006 29 L 559.099976 29 M 559.099976 0 L 40.100006 0 C 18.100006 0 0.300003 17.799988 0.300003 39.799988 L 0.300003 803.5 C 0.300003 825.5 18.100006 843.299988 40.100006 843.299988 L 559.099976 843.299988 C 581.099976 843.299988 598.900024 825.5 598.900024 803.5 L 598.900024 39.799988 C 598.900024 17.799988 581.099976 0 559.099976 0 L 559.099976 0 Z'/> </g> <path id='path2' fill='none' stroke='#000000' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' d='M 235 227.799988 C 235 275.848755 196.048767 314.799988 148 314.799988 C 99.951233 314.799988 61 275.848755 61 227.799988 C 61 179.751221 99.951233 140.799988 148 140.799988 C 196.048767 140.799988 235 179.751221 235 227.799988 Z'/> <g id='g1'> <path id='path3' fill='none' stroke='#000000' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' d='M 235 227.799988 C 235 275.848755 196.048767 314.799988 148 314.799988 C 99.951233 314.799988 61 275.848755 61 227.799988 C 61 179.751221 99.951233 140.799988 148 140.799988 C 196.048767 140.799988 235 179.751221 235 227.799988 Z'/> <path id='path4' fill='none' stroke='#000000' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' d='M 118.100006 146 C 118.100006 146 64.100006 212.099976 109.700012 305.700012'/> <path id='path5' fill='none' stroke='#000000' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' d='M 149 140.799988 L 146.299988 314.799988'/> <path id='path6' fill='none' stroke='#000000' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' d='M 177.200012 309.299988 C 177.200012 309.299988 231.200012 243.200012 185.600006 149.599976'/> <path id='path7' fill='none' stroke='#000000' stroke-width='2' stroke-linecap='round' stroke-linejoin='round' d='M 227.899994 191.799988 C 227.899994 191.799988 158.899994 141.5 67.899994 192.299988'/> <path id='path8' fill='none' stroke='#000000' stroke-width='2.0158' stroke-linecap='round' stroke-linejoin='round' d='M 67.299988 260 C 67.299988 260 137.399994 310.200012 229.799988 259.299988'/> <path id='path9' fill='none' stroke='#000000' stroke-width='1.4931' stroke-linecap='round' stroke-linejoin='round' d='M 232.399994 212 C 232.399994 212 159.299988 185.599976 62.899994 212.299988'/> <path id='path10' fill='none' stroke='#000000' stroke-width='1.4931' stroke-linecap='round' stroke-linejoin='round' d='M 63.100006 247.799988 C 63.100006 247.799988 136.200012 274.200012 232.600006 247.5'/> <path id='path11' fill='none' stroke='#000000' stroke-width='2.9743' stroke-linecap='round' stroke-linejoin='round' d='M 568.400024 717.900024 L 204.5 296.099976'/> </g> <g id='g2'> <path id='path12' fill='#000000' stroke='none' d='M 88.899994 779.099976 C 88.899994 778.599976 88.899994 778.200012 88.899994 777.799988 C 88.899994 760.900024 88.899994 744 88.899994 727.099976 C 88.899994 726.099976 89.200012 725.700012 90.100006 725.299988 C 93.399994 724 96.600006 722.599976 99.899994 721.200012 C 100.200012 721.099976 100.5 721 101 720.799988 C 101 721.200012 101 721.599976 101 721.900024 C 101 739 101 756.200012 101 773.299988 C 101 774.099976 100.799988 774.5 100 774.799988 C 96.700012 776 93.399994 777.299988 90.100006 778.599976 C 89.700012 778.799988 89.399994 779 88.899994 779.099976 Z'/> <path id='path13' fill='#000000' stroke='none' d='M 122.399994 783.5 C 119.399994 782 116.5 780.5 113.600006 779.099976 C 113.600006 779.099976 113.5 779.099976 113.5 779.099976 C 110.799988 777.5 110.600006 776.799988 110.600006 774.400024 C 110.700012 764.700012 110.700012 755 110.700012 745.299988 C 110.700012 744.900024 110.700012 744.5 110.700012 743.900024 C 111.799988 744.400024 112.899994 744.799988 113.899994 745.299988 C 116.399994 746.400024 119 747.599976 121.5 748.700012 C 122 748.900024 122.5 749.200012 122.399994 749.900024 C 122.399994 760.799988 122.399994 771.700012 122.399994 782.700012 C 122.399994 782.900024 122.399994 783.099976 122.399994 783.5 Z'/> <path id='path14' fill='#000000' stroke='none' d='M 67.200012 787.900024 C 67.200012 787.400024 67.200012 787 67.200012 786.700012 C 67.200012 778 67.200012 769.200012 67.200012 760.5 C 67.200012 759.700012 67.399994 759.299988 68.200012 759 C 71.600006 757.5 75 755.900024 78.399994 754.400024 C 78.5 754.299988 78.700012 754.299988 79 754.200012 C 79 754.599976 79 754.900024 79 755.299988 C 79 764.200012 79 773.200012 79 782.099976 C 79 782.900024 78.799988 783.200012 78.100006 783.5 C 74.700012 785 71.299988 786.400024 67.899994 787.900024 C 67.799988 787.900024 67.600006 787.900024 67.200012 787.900024 Z'/> </g> <path id='path15' fill='none' stroke='#000000' stroke-width='0.9801' stroke-linecap='round' stroke-linejoin='round' d='M 296.899994 140.799988 C 296.899994 164.382568 277.782562 183.5 254.200012 183.5 C 230.617432 183.5 211.5 164.382568 211.5 140.799988 C 211.5 117.217407 230.617432 98.099976 254.200012 98.099976 C 277.782562 98.099976 296.899994 117.217407 296.899994 140.799988 Z'/> <g id='g3'> <path id='path16' fill='none' stroke='#000000' stroke-width='0.9801' stroke-linecap='round' stroke-linejoin='round' d='M 296.899994 140.799988 C 296.899994 164.382568 277.782562 183.5 254.200012 183.5 C 230.617432 183.5 211.5 164.382568 211.5 140.799988 C 211.5 117.217407 230.617432 98.099976 254.200012 98.099976 C 277.782562 98.099976 296.899994 117.217407 296.899994 140.799988 Z'/> <path id='path17' fill='none' stroke='#000000' stroke-width='0.9991' stroke-linecap='round' stroke-linejoin='round' d='M 238.5 99.900024 C 238.5 99.900024 211.5 132.900024 234.299988 179.700012'/> <path id='path18' fill='none' stroke='#000000' stroke-width='0.9801' stroke-linecap='round' stroke-linejoin='round' d='M 254.700012 98.099976 L 253.399994 183.400024'/> <path id='path19' fill='none' stroke='#000000' stroke-width='0.9991' stroke-linecap='round' stroke-linejoin='round' d='M 268 181.5 C 268 181.5 295 148.5 272.200012 101.700012'/> <path id='path20' fill='none' stroke='#000000' stroke-width='0.9801' stroke-linecap='round' stroke-linejoin='round' d='M 293.399994 123.099976 C 293.399994 123.099976 259.600006 98.5 215 123.400024'/> <path id='path21' fill='none' stroke='#000000' stroke-width='0.9879' stroke-linecap='round' stroke-linejoin='round' d='M 214.700012 156.599976 C 214.700012 156.599976 249 181.200012 294.299988 156.299988'/> <path id='path22' fill='none' stroke='#000000' stroke-width='0.7344' stroke-linecap='round' stroke-linejoin='round' d='M 295 132.799988 C 295 132.799988 259 119.799988 211.600006 132.900024'/> <path id='path23' fill='none' stroke='#000000' stroke-width='0.7317' stroke-linecap='round' stroke-linejoin='round' d='M 212.600006 150.599976 C 212.600006 150.599976 248.399994 163.599976 295.700012 150.5'/>"
          "</g>"
        )
      );
    }

    {
      if (stake.dhedgePoolAddress != address(0)) {
        uint256 poolAmount = stake.dhedgePoolAmount;
        // div(10**36) would give us flat dollars, so we div(10**34) and then take the last two digits as decimals
        uint256 amount = poolAmount.mul(currentTokenPrice).div(10**34);
        string memory amountStr = Strings.toString(amount);
        uint256 length = bytes(amountStr).length;
        string memory dollars = length > 2 ? substring(amountStr, 0, length.sub(2)) : "0";
        string memory cents = length < 2
          ? string(abi.encodePacked("0", amountStr))
          : substring(amountStr, length.sub(2), length);

        guts = string(
          abi.encodePacked(
            guts,
            "<text id='ETHBull3x---' xml:space='preserve'><tspan x='64' y='457' font-size='28' fill='#000000' xml:space='preserve'>",
            poolSymbol,
            "</tspan><tspan font-size='12' fill='#000000' xml:space='preserve'></tspan></text>",
            "<text id='TVL' xml:space='preserve'><tspan x='64' y='495' font-size='32' font-weight='700' fill='#000000' xml:space='preserve'>$",
            dollars,
            ".",
            cents,
            "</tspan><tspan font-size='12' fill='#000000' xml:space='preserve'></tspan></text>"
          )
        );
      }
    }

    // We split these up because of stack to deep
    guts = string(
      abi.encodePacked(
        guts,
        "<text id='DHT-TIME-STAKED-' xml:space='preserve'><tspan x='265' y='229' font-size='24' fill='#000000' xml:space='preserve'>DHT TIME STAKED:</tspan><tspan font-size='12' fill='#000000' xml:space='preserve'></tspan></text>",
        "<text id='4-Days--' xml:space='preserve'><tspan x='265' y='272' font-size='32' font-weight='700' fill='#000000' xml:space='preserve'>",
        Strings.toString(block.timestamp.sub(stake.dhtStakeStartTime).div(1 days)),
        " Days</tspan><tspan font-size='12' fill='#000000' xml:space='preserve'></tspan></text>"
      )
    );

    guts = string(
      abi.encodePacked(
        guts,
        "<text id='DHTVDHT---' xml:space='preserve'><tspan x='64' y='547' font-size='28' fill='#000000' xml:space='preserve'>DHT:VDHT</tspan><tspan font-size='12' fill='#000000' xml:space='preserve'></tspan></text>"
        "<text id='dht:vdht' xml:space='preserve'><tspan x='64' y='585' font-size='32' font-weight='700' fill='#000000' xml:space='preserve'>",
        Strings.toString(stake.dhtAmount.div(10**18)),
        ":",
        Strings.toString(vDHT.div(10**18)),
        "</tspan><tspan font-size='12' fill='#000000' xml:space='preserve'></tspan></text>",
        "<text id='Rewards---' xml:space='preserve'><tspan x='64' y='636' font-size='28' fill='#000000' xml:space='preserve'>Rewards:</tspan><tspan font-size='12' fill='#000000' xml:space='preserve'></tspan></text>",
        "<text id='10-DHT--' xml:space='preserve'><tspan x='64' y='674' font-size='32' font-weight='700' fill='#000000' xml:space='preserve'>",
        Strings.toString(rewards.div(10**18)),
        "DHT</tspan><tspan font-size='12' fill='#000000' xml:space='preserve'></tspan></text>"
      )
    );

    // Outside addresses
    guts = string(
      abi.encodePacked(
        guts,
        "<defs><path id='path24' d='M 109.299988 814.5 L 38 814.400024 C 38 814.400024 29.5 811.900024 29.300003 804 C 29.100006 794.799988 29.300003 443.5 29.300003 443.5'/></defs>"
        "<defs><path id='path25' d='M 494 29.299988 L 558 29.099976 C 558 29.099976 570 27.200012 570 43.5 C 570 61.700012 569.700012 406.299988 569.700012 406.299988'/></defs>",
        "<text id='---' xml:space='preserve'><textPath xlink:href='#path24' startOffset='1'><tspan font-size='12' fill='#000000' baseline-shift='2' xml:space='preserve'></tspan><tspan font-size='18' fill='#000000' baseline-shift='2' xml:space='preserve'>",
        addressToString(owner),
        "</tspan><tspan font-size='12' fill='#000000' baseline-shift='2' xml:space='preserve'></tspan></textPath></text>",
        "<text id='text2' xml:space='preserve'><textPath xlink:href='#path25' startOffset='1'><tspan font-size='12' fill='#000000' baseline-shift='2' xml:space='preserve'></tspan><tspan font-size='18.4567' fill='#000000' baseline-shift='2' xml:space='preserve'>",
        addressToString(dhtAddress),
        "</tspan><tspan font-size='12' fill='#000000' baseline-shift='2' xml:space='preserve'></tspan></textPath></text>"
      )
    );

    mainParts[1] = guts;
    mainParts[2] = "</svg>";

    return string(abi.encodePacked(mainParts[0], mainParts[1], mainParts[2]));
  }

  function addressToString(address _addr) public pure returns (string memory) {
    return toHexString(uint256(uint160(_addr)), 20);
  }

  function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
    bytes16 hexSymbols = "0123456789abcdef";
    bytes memory buffer = new bytes(2 * length + 2);
    buffer[0] = "0";
    buffer[1] = "x";
    for (uint256 i = 2 * length + 1; i > 1; --i) {
      buffer[i] = hexSymbols[value & 0xf];
      value >>= 4;
    }
    require(value == 0, "Strings: hex length insufficient");
    return string(buffer);
  }

  function substring(
    string memory str,
    uint256 startIndex,
    uint256 endIndex
  ) public pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex - startIndex);
    for (uint256 i = startIndex; i < endIndex; i++) {
      result[i - startIndex] = strBytes[i];
    }
    return string(result);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Base64.sol)

pragma solidity 0.7.6;
pragma abicoder v2;

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
        // solhint-disable-next-line no-empty-blocks
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

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma experimental ABIEncoderV2;

import "./IDhedgeStakingV2NFTJson.sol";

interface IDhedgeStakingV2Storage {
  struct Stake {
    uint256 dhtAmount;
    uint256 dhtStakeStartTime;
    address dhedgePoolAddress;
    uint256 dhedgePoolAmount;
    uint256 dhedgePoolStakeStartTime;
    uint256 stakeStartTokenPrice;
    bool unstaked;
    uint256 unstakeTime;
    uint256 reward;
    uint256 claimedReward;
    uint256 rewardParamsEmissionsRate;
  }

  struct PoolConfiguration {
    bool configured;
    uint256 stakeCap;
    uint256 stakedSoFar;
  }

  struct RewardParams {
    uint256 stakeDurationDelaySeconds;
    uint256 maxDurationBoostSeconds;
    uint256 maxPerformanceBoostNumerator;
    uint256 maxPerformanceBoostDenominator;
    uint256 stakingRatio;
    uint256 emissionsRate;
    uint256 emissionsRateDenominator;
  }

  /// Only Owner

  /// @notice Allows the owner to allow staking of a pool by setting a cap > 0
  /// @dev can also be used to restrict staking of a pool by setting cap back to 0
  function configurePool(address pool, uint256 cap) external;

  /// @notice Allows the owner to modify the dhtCap which controls the max staking value
  /// @dev can also be used to restrict staking cap back to 0 or rewardedDHT
  function setDHTCap(uint256 newDHTCap) external;

  /// @notice Allows the owner to adjust the maxVDurationTimeSeconds
  /// @param newMaxVDurationTimeSeconds time to reach max VHDT for a staker
  function setMaxVDurationTimeSeconds(uint256 newMaxVDurationTimeSeconds) external;

  /// @notice Allows the owner to adjust the setStakeDurationDelaySeconds
  /// @param newStakeDurationDelaySeconds delay before a staker starts to receive rewards
  function setStakeDurationDelaySeconds(uint256 newStakeDurationDelaySeconds) external;

  /// @notice Allows the owner to adjust the maxDurationBoostSeconds
  /// @param newMaxDurationBoostSeconds time to reach maximum stake duration boost
  function setMaxDurationBoostSeconds(uint256 newMaxDurationBoostSeconds) external;

  /// @notice Allows the owner to adjust the maxPerformanceBoostNumerator
  /// @param newMaxPerformanceBoostNumerator the performance increase to reach max boost
  function setMaxPerformanceBoostNumerator(uint256 newMaxPerformanceBoostNumerator) external;

  /// @notice Allows the owner to adjust the stakingRatio
  /// @param newStakingRatio the amount of dht that can be staked per dollar of DHPT
  function setStakingRatio(uint256 newStakingRatio) external;

  /// @notice Allows the owner to adjust the emissionsRate
  /// @param newEmissionsRate currently 1 not used
  function setEmissionsRate(uint256 newEmissionsRate) external;

  /// @notice Allows the owner to adjust the rewardStreamingTime
  /// @param newRewardStreamingTime max amount of aggregate value of pool tokens that can be staked
  function setRewardStreamingTime(uint256 newRewardStreamingTime) external;

  /// VIEW

  /// @notice The contract address for DHT
  function dhtAddress() external view returns (address);

  /// @notice The total number of pools configured for staking
  /// @dev can be used with poolConfiguredByIndex and poolConfiguration to look up all existing pool configs
  function numberOfPoolsConfigured() external returns (uint256 numberOfPools);

  /// @notice Returns the poolAddress stored at the index
  /// @dev can be used with numberOfPoolsConfigured and poolConfiguration to get all information about configured pools
  /// @param index the index to look up
  /// @return poolAddress the address at the index
  function poolConfiguredByIndex(uint256 index) external returns (address poolAddress);

  /// @notice Allows the owner to set the tokenUriGenerator contract
  /// @param newTokenUriGenerator the address of the deployed tokenUriGenerator
  function setTokenUriGenerator(IDhedgeStakingV2NFTJson newTokenUriGenerator) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

//
//        __  __    __  ________  _______    ______   ________
//       /  |/  |  /  |/        |/       \  /      \ /        |
//   ____$$ |$$ |  $$ |$$$$$$$$/ $$$$$$$  |/$$$$$$  |$$$$$$$$/
//  /    $$ |$$ |__$$ |$$ |__    $$ |  $$ |$$ | _$$/ $$ |__
// /$$$$$$$ |$$    $$ |$$    |   $$ |  $$ |$$ |/    |$$    |
// $$ |  $$ |$$$$$$$$ |$$$$$/    $$ |  $$ |$$ |$$$$ |$$$$$/
// $$ \__$$ |$$ |  $$ |$$ |_____ $$ |__$$ |$$ \__$$ |$$ |_____
// $$    $$ |$$ |  $$ |$$       |$$    $$/ $$    $$/ $$       |
//  $$$$$$$/ $$/   $$/ $$$$$$$$/ $$$$$$$/   $$$$$$/  $$$$$$$$/
//
// dHEDGE DAO - https://dhedge.org
//
// Copyright (c) 2021 dHEDGE DAO
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//
// SPDX-License-Identifier: MIT

pragma solidity 0.7.6;
pragma abicoder v2;

import "../Base64.sol";
import "./IDhedgeStakingV2Storage.sol";

interface IDhedgeStakingV2NFTJson {
  function tokenJson(
    uint256 tokenId,
    IDhedgeStakingV2Storage.Stake memory stake,
    uint256 vDHT,
    uint256 rewards,
    string memory poolSymbol,
    uint256 currentTokenPrice,
    address dhtAddress,
    address owner
  ) external view returns (string memory);
}