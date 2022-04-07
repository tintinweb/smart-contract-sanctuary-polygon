/**
 *Submitted for verification at polygonscan.com on 2022-04-06
*/

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

// File: contracts/ConwayPainter.sol



pragma solidity >=0.8.0 <0.9.0;




contract ConwayPainter is Ownable, Painter {
  using Strings for uint256;
  

constructor() 
  
 {
    
  }

  

    function paint(uint256 number)external pure override returns(string memory){
      string memory hex_num = number.toHexString(32);
      // uint256 number = getPetNumber(_tokenId);
      uint256 fg = (number&65535)%361;
      uint256 bg = ((number>>16)&65535)%361;
      number = number>>32;
      string memory svg_top = "    <svg version='1.1' xmlns='http://www.w3.org/2000/svg' width='400' height='400' >"
"    <script type='text/javascript'><![CDATA["
""
"      class Cell"
"      {"
"          static width = 25;"
"          static height = 25;"
""
"          constructor (svg, gridX, gridY, bit)"
"          {"
"              this.svg = svg;"
""

"              this.gridX = gridX;"
"              this.gridY = gridY;"
""

"              this.alive = bit==1;"
"          }"
""
"          draw() {"

"              const color = this.alive?'";
// #00ff80':'#303030';"
string memory svg_middle = "            var element = document.createElementNS('http://www.w3.org/2000/svg', 'rect');"
"            element.setAttributeNS(null, 'x', this.gridX * Cell.width);"
"            element.setAttributeNS(null, 'y', this.gridY * Cell.height);"
"            element.setAttributeNS(null, 'width', Cell.width);"
"            element.setAttributeNS(null, 'height', Cell.height);"
"            element.setAttributeNS(null, 'fill', color);"
"            this.svg.appendChild(element);"
"            "
""
"          }"
"      }"
""
"      class GameWorld {"
""
"          static numColumns = 16;"
"          static numRows = 16;"
"          static look ={'0': '0000', "
"            '1': '0001',"
"            '2': '0010',"
"            '3': '0011',"
"            '4': '0100',"
"            '5': '0101',"
"            '6': '0110',"
"            '7': '0111',"
"            '8': '1000',"
"            '9': '1001',"
"            'a': '1010',"
"            'b': '1011',"
"            'c': '1100',"
"            'd': '1101',"
"            'e': '1110',"
"            'f': '1111'"
"            };"
"          constructor(hex_number) {"
"              const bin_number = this.hex2bin(hex_number);"
"              console.log(bin_number);"
"              this.svg = document.getElementsByTagName('svg')[0];"
"              this.gameObjects = [];"
""
"              this.createGrid(bin_number);"
""


"              window.requestAnimationFrame(() => this.gameLoop());"
"          }"
""
"          hex2bin(hex){"
"            "
"            hex = hex.replace('0x', '').toLowerCase();"
"            console.log(hex);"
"            var out = '';"
"            for(let c of hex) {"
"                out+=GameWorld.look[c];"
"            }"
"            return out;"
"          }"
"          createGrid(bin)"
"          {"
"              for (let y = 0; y < GameWorld.numRows; y++) {"
"                  for (let x = 0; x < GameWorld.numColumns; x++) {"
"                      this.gameObjects.push(new Cell(this.svg, x, y, bin[x+y*GameWorld.numColumns]));"
"                  }"
"              }"
"          }"
""
"          isAlive(x, y)"
"          {"
"              x = (x+GameWorld.numColumns) % GameWorld.numColumns;"
"              y = (y+GameWorld.numRows) % GameWorld.numRows;"
"              if (x < 0 || x >= GameWorld.numColumns || y < 0 || y >= GameWorld.numRows){"
"                  return false;"
"              }"
""
"              return this.gameObjects[this.gridToIndex(x, y)].alive?1:0;"
"          }"
""
"          gridToIndex(x, y){"
"              return x + (y * GameWorld.numColumns);"
"          }"
""
"          checkSurrounding ()"
"          {"

"              for (let x = 0; x < GameWorld.numColumns; x++) {"
"                  for (let y = 0; y < GameWorld.numRows; y++) {"
""

"                      let numAlive = this.isAlive(x - 1, y - 1) + this.isAlive(x, y - 1) + this.isAlive(x + 1, y - 1) + this.isAlive(x - 1, y) + this.isAlive(x + 1, y) + this.isAlive(x - 1, y + 1) + this.isAlive(x, y + 1) + this.isAlive(x + 1, y + 1);"
"                      let centerIndex = this.gridToIndex(x, y);"
""
"                      if (numAlive == 2){"

"                          this.gameObjects[centerIndex].nextAlive = this.gameObjects[centerIndex].alive;"
"                      }else if (numAlive == 3){"

"                          this.gameObjects[centerIndex].nextAlive = true;"
"                      }else{"

"                          this.gameObjects[centerIndex].nextAlive = false;"
"                      }"
"                  }"
"              }"
""

"              for (let i = 0; i < this.gameObjects.length; i++) {"
"                  this.gameObjects[i].alive = this.gameObjects[i].nextAlive;"
"              }"
"          }"
""
"          gameLoop() {"

"              this.checkSurrounding();"
""
""

"              for (let i = 0; i < this.gameObjects.length; i++) {"
"                  this.gameObjects[i].draw();"
"              }"
""

"              setTimeout( () => {"
"                  window.requestAnimationFrame(() => this.gameLoop());"
"              }, 500)"
"          }"
"      }"
""
"      window.onload = () => {"

"        let gameWorld = new GameWorld('";

string memory svg_bottom = "');"
"      }"
""
"      ]]></script>"
"    </svg>"
""
"";
      return string(abi.encodePacked(
        svg_top,
        "hsl(",
        fg.toString(),
        ",100%, 80%)':'hsl(",
        bg.toString(),
        ",50%, 25%)';",
        svg_middle,
        hex_num,
        svg_bottom
          ));
  }

      
}