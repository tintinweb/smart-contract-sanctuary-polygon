/**
 *Submitted for verification at polygonscan.com on 2022-04-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IERC20 {
  function totalSupply() external view returns (uint);
  function balanceOf(address account) external view returns (uint);
  function transfer(address recipient, uint amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint);
  function approve(address spender, uint amount) external returns (bool);
  function transferFrom(
    address sender,
    address recipient,
    uint amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract Verification {
  address private _owner;
  address private signer;
  IERC20 private feeToken;
  uint private feeAmount;

  struct VerifiedPassport {
    uint expiration;
    bytes32 countryAndDocNumberHash;
  }

  mapping(address => VerifiedPassport) private accounts;
  mapping(bytes32 => address) private idHashToAccount;

  event FeePaid(address indexed account);
  event VerificationUpdated(address indexed account, uint256 expiration);
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event FeeTokenChanged(address indexed previousFeeToken, address indexed newFeeToken);
  event FeeAmountChanged(uint previousFeeAmount, uint newFeeAmount);

  constructor(address _signer, address _feeToken, uint _feeAmount) {
    require(_signer != address(0), "Signer must not be zero address");
    require(_feeToken != address(0), "Fee token must not be zero address");
    _transferOwnership(msg.sender);
    signer = _signer;
    feeToken = IERC20(_feeToken);
    feeAmount = _feeAmount;
  }

  function getFeeToken() external view returns (address) {
    return address(feeToken);
  }

  function getFeeAmount() external view returns (uint) {
    return feeAmount;
  }

  function owner() public view returns (address) {
    return _owner;
  }

  function payFeeFor(address account) public {
    emit FeePaid(account);
    bool received = feeToken.transferFrom(msg.sender, address(this), feeAmount);
    require(received, "Fee transfer failed");
  }

  function payFee() external {
    payFeeFor(msg.sender);
  }

  function publishVerification(
    uint256 expiration,
    bytes32 countryAndDocNumberHash,
    bytes calldata signature
  ) external {
    // Recreate hash as built by the client
    bytes32 hash = keccak256(abi.encode(msg.sender, expiration, countryAndDocNumberHash));
    (bytes32 r, bytes32 s, uint8 v) = splitSignature(signature);
    bytes32 ethSignedHash = keccak256(
      abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));

    address sigAddr = ecrecover(ethSignedHash, v, r, s);
    require(sigAddr == signer, "Invalid Signature");

    // Revoke verification for any other account that uses
    //  the same document number/country
    //  e.g. for case of stolen keys
    if(idHashToAccount[countryAndDocNumberHash] != address(0x0)) {
      revokeVerificationOf(idHashToAccount[countryAndDocNumberHash]);
    }
    // Update account state
    idHashToAccount[countryAndDocNumberHash] = msg.sender;
    accounts[msg.sender] = VerifiedPassport(expiration, countryAndDocNumberHash);
    emit VerificationUpdated(msg.sender, expiration);
  }

  function revokeVerification() external {
    revokeVerificationOf(msg.sender);
  }

  function revokeVerificationOf(address account) public {
    delete accounts[account];
    emit VerificationUpdated(account, 0);
  }

  function addressActive(address toCheck) external view returns (bool) {
    return accounts[toCheck].expiration > block.timestamp;
  }

  function addressExpiration(address toCheck) external view returns (uint) {
    return accounts[toCheck].expiration;
  }

  function setSigner(address newSigner) external onlyOwner {
    require(newSigner != address(0), "Signer cannot be zero address");
    signer = newSigner;
  }

  function setFeeToken(address newFeeToken) external onlyOwner {
    require(newFeeToken != address(0), "Fee Token cannot be zero address");
    address oldFeeToken = address(feeToken);
    feeToken = IERC20(newFeeToken);
    emit FeeTokenChanged(oldFeeToken, newFeeToken);
  }

  function setFeeAmount(uint newFeeAmount) external onlyOwner {
    uint oldFeeAmount = feeAmount;
    feeAmount = newFeeAmount;
    emit FeeAmountChanged(oldFeeAmount, newFeeAmount);
  }

  function _transferOwnership(address newOwner) internal {
    address oldOwner = _owner;
    _owner = newOwner;
    emit OwnershipTransferred(oldOwner, newOwner);
  }

  function transferOwnership(address newOwner) external onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    _transferOwnership(newOwner);
  }

  function transferFeeToken(address recipient, uint amount) external onlyOwner {
    bool sent = feeToken.transfer(recipient, amount);
    require(sent, "Fee transfer failed");
  }

  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  // From https://solidity-by-example.org/signature/
  function splitSignature(bytes memory sig) internal pure
    returns (bytes32 r, bytes32 s, uint8 v)
  {
    require(sig.length == 65, "invalid signature length");
    assembly {
        // first 32 bytes, after the length prefix
        r := mload(add(sig, 32))
        // second 32 bytes
        s := mload(add(sig, 64))
        // final byte (first byte of the next 32 bytes)
        v := byte(0, mload(add(sig, 96)))
    }
  }

}