/**
 *Submitted for verification at polygonscan.com on 2022-04-01
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol



pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/Painter.sol



pragma solidity >=0.7.0 <0.9;


abstract contract Painter is Ownable{
  event Received(address indexed _from, uint256 _amount);
  uint256 public updateCost = 0;

  function paint(uint256 _number) external view virtual returns(string memory);
  
  function setUpdateCost(uint256 _cost) external onlyOwner{
    updateCost = _cost;
  }

  function getUpdateCost() external view returns(uint256){
    return updateCost;
  }

  receive() external payable virtual {
      emit Received(msg.sender, msg.value);
  }

  function withdraw() external virtual onlyOwner {

  // Do not remove this otherwise you will not be able to withdraw the funds.
  // =============================================================================
  (bool os, ) = payable(owner()).call{value: address(this).balance}("");
  require(os);
  // =============================================================================
  }

}
// File: @openzeppelin/contracts/utils/Strings.sol



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

// File: contracts/SwordPainter.sol



pragma solidity >=0.7.0 <0.9.0;




contract SwordPainter is Ownable, Painter {
  using Strings for uint256;
  

constructor() 
  
 {
    
  }

  function blade(uint256 number) internal pure virtual returns (string memory){
    string[2] memory shapes =[
    '"M 250 10 L 225 110 C 235 110, 235 370, 225 370 H 275 C 265 370, 265 110, 275 110 Z V 350 L 225 370 H 275 L 250 350"',
    '"M 250 10 L 225 110 v 260 H 275 V 110 Z V 350 L 225 370 H 275 L 250 350"'
    ];
    uint8 shape = uint8(number&1);
    uint256 colorB = (number>>8)&0xFF;
    uint256 colorG = (number>>(8*2))&0xFF;
    uint256 colorR = (number>>(8*3))&0xFF;
     return string(abi.encodePacked(
     '<path stroke="black" d=',
     shapes[shape],
     ' fill="RGB(',
     colorR.toString(),',',
     colorG.toString(),',',
     colorB.toString(),')"/>'
     ));
  }

function crossguard(uint256 number) internal pure virtual returns (string memory){
     uint8 shape = uint8(number&0xFF);
    uint256 colorB = (number>>8)&0xFF;
    uint256 colorG = (number>>(8*2))&0xFF;
    uint256 colorR = (number>>(8*3))&0xFF;
     return string(abi.encodePacked(
     '<path stroke="black" d="M 215 370 C 215 400, 285 400, 285 370 Z" fill="RGB(',
     colorR.toString(),',',
     colorG.toString(),',',
     colorB.toString(),')"/>'
     ));
  }

  function grip(uint256 number) internal pure virtual returns (string memory){
    string[3] memory shapes;
    uint8 shape = uint8(number&0xFF);
    uint256 colorB = (number>>8)&0xFF;
    uint256 colorG = (number>>(8*2))&0xFF;
    uint256 colorR = (number>>(8*3))&0xFF;
    string memory gripColor = string(abi.encodePacked(
      'stroke="black" fill="RGB(',
     colorR.toString(),',',
     colorG.toString(),',',
     colorB.toString(),')"/>'
     ));
    shapes[0]=string(abi.encodePacked(
      '<path d="M 238 392 C 238 393, 262 393, 262 392 V 456 C 262 454, 238 454, 238 456 V 392 " ',
      gripColor
      ));
    shapes[1]=string(abi.encodePacked(
      shapes[0],
      '<ellipse cx="250" cy="400" rx="15" ry="5" ',gripColor,
      '<ellipse cx="250" cy="420" rx="15" ry="5" ',gripColor,
      '<ellipse cx="250" cy="440" rx="15" ry="5" ',gripColor
      ));
    shapes[2] = string(abi.encodePacked(
      '<path d="M 238 392 C 238 393, 262 393, 262 392 Q 256 399, 262 406 v 3 Q 256 416, 262 423 v 3 Q 256 433, 262 440 v 3 Q 256 450, 262 456 C 262 454, 238 454, 238 456 Q 244 450, 238 443 v -3 Q 244 433, 238 426 v -3 Q 244 416, 238 409 v -3 Q 244 399, 238 392 M 238 406 h 24 M 238 409 h 24 M 238 423 h 24 M 238 426 h 24 M 238 440 h 24 M 238 443 h 24" ',
      gripColor
    ));

     return shapes[shape%3];
  }

  
  function pommel(uint256 number) internal pure virtual returns (string memory){
    string[6] memory shapes;
    uint8 shape = uint8(number&0xFF);
    uint256 color1B = (number>>8)&0xFF;
    uint256 color1G = (number>>(8*2))&0xFF;
    uint256 color1R = (number>>(8*3))&0xFF;
    uint256 color2B = (number>>(8*4))&0xFF;
    uint256 color2G = (number>>(8*5))&0xFF;
    uint256 color2R = (number>>(8*6))&0xFF;
    string memory gemColor = string(abi.encodePacked(
      'stroke="black" fill="RGB(',
     color2R.toString(),',',
     color2G.toString(),',',
     color2B.toString(),')"/>'
      
     ));
     shapes[0] = string(abi.encodePacked(
       '<circle cx="250" cy="475" r="12" ',
        gemColor
       ));
     shapes[1] = string(abi.encodePacked(
        '<polygon points="250,463 262,475 250,487 238,475" ',
        gemColor
        ));
     shapes[2] =  string(abi.encodePacked(
        '<polygon points="250,463 239.61,469 239.61,481 250,487 260.39,481 260.39,469" ',
        gemColor
        ));
      shapes[3] = string(abi.encodePacked(
        shapes[0],
        shapes[1]
      ));

      shapes[4] = string(abi.encodePacked(
        shapes[0],
        shapes[2]
      ));
      shapes[5] = string(abi.encodePacked(
        shapes[4],
        shapes[1]
      ));
     return string(abi.encodePacked(
      '<ellipse stroke="black" cx="250" cy="475" rx="30" ry="20" fill="RGB(',
     color1R.toString(),',',
     color1G.toString(),',',
     color1B.toString(),')"/>',
     shapes[shape%6]
      
     ));
  }

  function sword(uint256 number) internal pure virtual returns (string memory){
      uint256 crossguardNumber = (number>>56)&0xFFFFFFFFFFFFFF;
      uint256 gripNumber = (number>>(56*2))&0xFFFFFFFFFFFFFF;
      uint256 pommelNumber = (number>>(56*3))&0xFFFFFFFFFFFFFF;
     return string(abi.encodePacked(
      blade(number),
      crossguard(crossguardNumber),
      grip(gripNumber),
      pommel(pommelNumber)
     ));
  }

    function paint(uint256 number)external pure override returns(string memory){
      
      // uint256 number = getPetNumber(_tokenId);
      uint256 bg1 = (number&65535)%361;
      uint256 bg2 = ((number>>16)&65535)%361;
      number = number>>32;
      
      return string(abi.encodePacked(
        '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500" >',
         '<defs><linearGradient id="nG" gradientTransform="rotate(45)"><stop offset="5%" stop-color="hsl(',bg1.toString(),',50%, 25%)"/>',
         '<stop offset="95%" stop-color="hsl(',bg2.toString(),',50%, 25%)"/></linearGradient></defs>',
        
        '<rect width="500" height="500" fill="url(\'#nG\')"/>',
       sword(number),
        '</svg>'
          ));
  }

      
}