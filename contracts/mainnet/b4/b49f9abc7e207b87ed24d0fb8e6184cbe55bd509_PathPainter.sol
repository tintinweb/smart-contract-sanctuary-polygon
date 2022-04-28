/**
 *Submitted for verification at polygonscan.com on 2022-04-28
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

// File: contracts/PathPainter.sol



pragma solidity >=0.7.0 <0.9.0;




contract PathPainter is Ownable, Painter {
  using Strings for uint256;


 constructor(){
       
    }

  function M(uint256 _n)internal pure virtual returns(string memory, uint256){
    uint256 x = _n&0xFF;
    _n >>=8;
    uint256 y = _n&0xFF;
    _n >>=8;
    return (string(abi.encodePacked(
      'M',
      x.toString(),
      ',',
      y.toString()
      )),
      _n);
  }
  function start(uint256 _n) internal pure virtual returns(string memory, uint256){
    uint256 colorB = _n&0xFF;
    _n >>=8;
    uint256 colorG = _n&0xFF;
    _n >>=8;
    uint256 colorR = _n&0xFF;
    _n >>=8;
    string memory m;
    (m,_n) = M(_n);  
    

    return (string(abi.encodePacked(
      '<path fill="RGB(', 
      colorR.toString(),',',
      colorG.toString(),',',
      colorB.toString(),')" ',
      'd="',m
    )), _n);
  }
  function end() internal pure virtual returns(string memory){
    return ('"/>');
  }

  function L(uint256 _n)internal pure virtual returns(string memory, uint256){
    uint256 x = _n&0xFF;
    _n >>=8;
    uint256 y = _n&0xFF;
    _n >>=8;
    return (string(abi.encodePacked(
      'L',
      x.toString(),
      ',',
      y.toString()
      )),
      _n);
  }

  function C(uint256 _n)internal pure virtual returns(string memory, uint256){
    uint256 x1 = _n&0xFF;
    _n >>=8;
    uint256 y1 = _n&0xFF;
    _n >>=8;
    uint256 x2 = _n&0xFF;
    _n >>=8;
    uint256 y2 = _n&0xFF;
    _n >>=8;
    uint256 x = _n&0xFF;
    _n >>=8;
    uint256 y = _n&0xFF;
    _n >>=8;
    return (string(abi.encodePacked(
      'C',
      x1.toString(),
      ',',
      y1.toString(),
      ',',
      x2.toString(),
      ',',
      y2.toString(),
      ',',
      x.toString(),
      ',',
      y.toString()
      )),
      _n);
  }

  function chooseBody(uint256 _n)internal pure virtual returns(string memory, uint256){
    uint256 selector = _n&3;
    _n>>=2;
    if (selector == 0){
      string memory p;
      (p, _n )= start(_n);
      return (string(abi.encodePacked(
        end(),
        p
        )),
        _n);
    }else if(selector == 1){
      return M(_n);
    }else if (selector == 2){
      return L(_n);
    }else{
      return C(_n);
    }
  }



  function group(uint256 _n) internal pure virtual returns(string memory){
    string memory p;
    uint256 n;
    (p,n)=start(_n);
    while (n>0){
      string memory b;
      (b,n)=chooseBody(n);
      p = string(abi.encodePacked(
        p,
        b
      ));
    }
    return string(abi.encodePacked(
      '<g transform="scale(2.0)">',
      p,
      end(),
      '</g>'
    ));
  }
  

  function paint(uint256 number)external pure override returns(string memory){
    uint256 bg1 = (number&65535)%361;
    uint256 bg2 = ((number>>16)&65535)%361;
    uint256 angle = ((number>>32)&65535)%361;
    uint256 fg = ((number>>48)&65535)%361;
    string memory fgStr = fg.toString();
    string memory textSvg = string(abi.encodePacked(
        group(number),
      '<text y="125" fill="hsl(',fgStr,',100%, 80%)"><tspan font-family = "monospace" x="4.34% 8.68% 13.02% 17.36% 21.7% 26.04% 30.38% 34.72% 39.06% 43.4% 47.74% 52.08% 56.42% 60.76% 65.1% 69.44% 73.78% 78.12% 82.46% 86.8% 91.14% 95.48% 4.34% 8.68% 13.02% 17.36% 21.7% 26.04% 30.38% 34.72% 39.06% 43.4% 47.74% 52.08% 56.42% 60.76% 65.1% 69.44% 73.78% 78.12% 82.46% 86.8% 91.14% 95.48% 4.34% 8.68% 13.02% 17.36% 21.7% 26.04% 30.38% 34.72% 39.06% 43.4% 47.74% 52.08% 56.42% 60.76% 65.1% 69.44% 73.78% 78.12% 82.46% 86.8% 91.14% 95.48%" dy="0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 125 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 125 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0">',
      number.toHexString(32),
      '</tspan></text>'
    ));
    return string(abi.encodePacked(
      '<svg xmlns="http://www.w3.org/2000/svg" width="500" height="500" font-size="32" text-anchor="middle">',
      '<defs><linearGradient id="nG" gradientTransform="rotate(',angle.toString(),')"><stop offset="5%" stop-color="hsl(',bg1.toString(),',50%, 25%)"/>',
        '<stop offset="95%" stop-color="hsl(',bg2.toString(),',50%, 25%)"/></linearGradient></defs>',
      
      '<rect width="500" height="500" fill="url(\'#nG\')"/>',
        
        textSvg,
      '</svg>'
        ));
  }

      
}