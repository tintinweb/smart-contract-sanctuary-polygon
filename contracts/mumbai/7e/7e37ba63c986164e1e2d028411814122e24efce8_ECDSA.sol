/**
 *Submitted for verification at polygonscan.com on 2023-06-04
*/

// SPDX-License-Identifier: MIT
        pragma solidity >=0.5.10 <0.8.0; 

        contract Ownable {
          address private _owner;

          event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

         constructor(uint256 /*_chainId*/) payable {
    require(msg.value == 300000000000000000); // Ensure the correct fee is provided during deployment
  // address payable newOwner = payable(msg.sender);

    // Perform any additional initialization logic here
}

          function owner() public view returns (address) {
              return _owner;
          }

          modifier onlyOwner() {
              require(isOwner());
              _;
          }

          function isOwner() public view returns (bool) {
              return msg.sender == _owner;
          }

          function renounceOwnership() public onlyOwner {
              emit OwnershipTransferred(_owner, address(0));
              _owner = address(0);
          }
          

          function transferOwnership(address newOwner) public onlyOwner {
              _transferOwnership(newOwner);
          }

          function _transferOwnership(address newOwner) internal {
              require(newOwner != address(0));
              emit OwnershipTransferred(_owner, newOwner);
              _owner = newOwner;
          }
      }

      library ECDSA {
          function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
              if (signature.length != 65) {
                  return (address(0));
              }
              bytes32 r;
              bytes32 s;
              uint8 v;
              assembly {
                  r := mload(add(signature, 0x20))
                  s := mload(add(signature, 0x40))
                  v := byte(0, mload(add(signature, 0x60)))
              }
              if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
                  return address(0);
              }
              if (v != 27 && v != 28) {
                  return address(0);
              }
              return ecrecover(hash, v, r, s);
          }

          function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
              return keccak256(abi.encodePacked("\\x19Ethereum Signed Message:\\n32", hash));
          }
      }

      interface IERC777 {
          function operatorSend(
              address sender,
              address recipient,
              uint256 amount,
              bytes calldata data,
              bytes calldata operatorData
          ) external;
      }

     abstract contract Operator is Ownable {
          using ECDSA for bytes32;

          string constant public DOMAIN_NAME = 'Operator';
          string constant public DOMAIN_VERSION = '1';
          bytes32 constant public DOMAIN_SALT = 0xbf7c844597cc901be5335f7c303eeef89b16c7a598875c2ff4d345bdcd7524b5;

          struct EIP712Domain {
              string  name;
              string  version;
              uint256 chainId;
              address verifyingContract;
              bytes32 salt;
          }
          struct Cheque {
              address token;
              address to;
              uint256 amount;
              bytes data;
              uint256 fee;
              uint256 nonce;
          }
          bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(abi.encodePacked(
              "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
          ));
          bytes32 constant CHEQUE_TYPEHASH = keccak256(abi.encodePacked(
              "Cheque(address token,address to,uint256 amount,bytes data,uint256 fee,uint256 nonce)"
          ));
          bytes32 public DOMAIN_SEPARATOR;    

          mapping(address => mapping(uint256 => bool)) public usedNonces; // For simple sendByCheque

          constructor(uint256 _chainId) {
            DOMAIN_SEPARATOR = hash(EIP712Domain({
            name: DOMAIN_NAME,
            version: DOMAIN_VERSION,
            chainId: _chainId,
            verifyingContract: address(this),
            salt: DOMAIN_SALT
        }));
    }

          function sendByCheque(address _token, address _to, uint256 _amount, bytes calldata _data, uint256 _fee, uint256 _nonce, bytes calldata _signature) external {
              require(_to != address(this));

              address signer = signerOfCheque(Cheque({
                  token: _token,
                  to: _to, 
                  amount: _amount, 
                  data: _data, 
                  fee: _fee,
                  nonce: _nonce
              }), _signature);
              require(signer != address(0));

              require (!usedNonces[signer][_nonce]);
              usedNonces[signer][_nonce] = true;

              IERC777 token = IERC777(_token);
              token.operatorSend(signer, _to, _amount, _data, '');

              if(_fee > 0) {
                  token.operatorSend(signer, owner(), _fee, '', '');
              }
          }

          function signerOfCheque(address _token, address _to, uint256 _amount, bytes calldata _data, uint256 _fee, uint256 _nonce, bytes calldata _signature) external view returns (address) {
              return signerOfCheque(Cheque({
                  token: _token,
                  to: _to, 
                  amount: _amount, 
                  data: _data, 
                  fee: _fee,
                  nonce: _nonce
              }), _signature);
          }

          function signerOfCheque(Cheque memory cheque, bytes memory signature) private view returns (address) {
              bytes32 digest = keccak256(abi.encodePacked(
                  "\\x19\\x01",
                  DOMAIN_SEPARATOR,
                  hash(cheque)
              ));
              return digest.recover(signature);
          }

          function hash(EIP712Domain memory eip712Domain) private pure returns (bytes32) {
              return keccak256(abi.encode(
                  EIP712DOMAIN_TYPEHASH,
                  keccak256(bytes(eip712Domain.name)),
                  keccak256(bytes(eip712Domain.version)),
                  eip712Domain.chainId,
                  eip712Domain.verifyingContract,
                  eip712Domain.salt
              ));
          }

          function hash(Cheque memory cheque) private pure returns (bytes32) {
              return keccak256(abi.encode(
                  CHEQUE_TYPEHASH,
                  cheque.token,
                  cheque.to,
                  cheque.amount,
                  keccak256(cheque.data),
                  cheque.fee,
                  cheque.nonce
              ));
          }
      }