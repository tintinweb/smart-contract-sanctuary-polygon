/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.19;

interface IBEP20 {

  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender) external view returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
  constructor () { }

  function _msgSender() internal view returns (address) {
    return msg.sender;
  }

  function _msgData() internal view returns (bytes memory) {
    this; // silence state mutability warning without generating bytecode 
    return msg.data;
  }
}

contract Ownable is Context {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor (){
    address msgSender = _msgSender();
    _owner = msgSender;
    emit OwnershipTransferred(address(0), msgSender);
  }

  function owner() public view returns (address) {
    return _owner;
  }

  modifier onlyOwner() {
    require(_owner == _msgSender(), "Ownable: caller is not the owner");
    _;
  }
  
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

contract WithdrawTokens {
    address public admin;
    address public BUSD;
    address public signer;

    mapping (bytes32 => bool) public hashVerify;

    event Withdraw(address indexed User, uint TokenAmount, uint blockTime);

    constructor(address _admin, address _BUSD, address _signer) {
        admin = _admin;
        BUSD = _BUSD;
        signer = _signer;
    }

    function withdraw(uint _tokenAmount, uint _blockTime, uint8 v, bytes32 r, bytes32 s) external {
        require(_blockTime >= block.timestamp, "Time Expired");
        bytes32 msgHash = toSigEthMsg(msg.sender, _tokenAmount, _blockTime);
        require(!hashVerify[msgHash], "signature already used");
        require(verifySignature(msgHash, v, r, s) == signer, "invalid signature");
        hashVerify[msgHash] = true;

        IBEP20(BUSD).transferFrom(admin, msg.sender, _tokenAmount);

        emit Withdraw(msg.sender, _tokenAmount, block.timestamp);
    }

    function verifySignature(bytes32 msgHash, uint8 v,bytes32 r, bytes32 s) public pure returns(address signerAdd) {
        signerAdd = ecrecover(msgHash, v, r, s);
    }
    
    function toSigEthMsg(address user, uint256 _tokenAmount, uint256 _blockTime) internal view returns(bytes32) {
        bytes32 hash = keccak256(abi.encodePacked(abi.encodePacked(user, _tokenAmount, _blockTime), address(this)));
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function getHash(address user, uint256 _tokenAmount, uint256 _blockTime) public view returns(bytes32) {
        return keccak256(abi.encodePacked(abi.encodePacked(user, _tokenAmount, _blockTime), address(this)));
    }

    function setSigner(address _signer) external {
        require(address(0x0) != _signer, "invalid signer address");
        signer = _signer;
    } 

    function setAdmin(address _admin) external {
        require(address(0x0) != _admin, "invalid admin address");
        admin = _admin;
    }

    function emergency(address _tokenAddress, address _to, uint256 _tokenAmount) external {
        if (_tokenAddress == address(0x0)) {
            require(payable(_to).send(_tokenAmount), "transaction failed");
        } else {
            IBEP20(_tokenAddress).transfer(_to, _tokenAmount);
        }
    }
}