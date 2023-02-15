/**
 *Submitted for verification at polygonscan.com on 2023-02-15
*/

pragma solidity ^0.5.9;

// Adding only the ERC-20 function we need
interface DaiToken {
    function transfer(address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract owned {
    DaiToken daitoken;
    address owner;

    constructor() public{
        owner = msg.sender;
        daitoken = DaiToken(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    }

    modifier onlyOwner {
        require(msg.sender == owner,
        "Only the contract owner can call this function");
        _;
    }
}

contract SplitDai is owned {
    
    event SplitDaiMultisend(uint256 value , address indexed sender);
    event SplitDaiAirdrop(address indexed _userAddress, uint256 _amount);
    using SafeMath for uint256;
    
    
    function FlizzDropDai(address payable[]  memory  _userAddresses, uint256 _amount) public payable {
        require(msg.value == _userAddresses.length.mul((_amount)));
        
        for (uint i = 0; i < _userAddresses.length; i++) {
            daitoken.transfer(_userAddresses[i], _amount);
            emit SplitDaiAirdrop(_userAddresses[i], _amount);
        }
    }
    
    function FlizzMultiDai(address payable[]  memory  _contributors, uint256[] memory _balances) public payable {
        uint256 total = msg.value;
        uint256 i = 0;
        for (i; i < _contributors.length; i++) {
            require(total >= _balances[i] );
            total = total.sub(_balances[i]);
            daitoken.transfer(_contributors[i], _balances[i]);
        }
        emit SplitDaiMultisend(msg.value, msg.sender);
    }
}


library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }


  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }


  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a); 
    return c;
  }
}