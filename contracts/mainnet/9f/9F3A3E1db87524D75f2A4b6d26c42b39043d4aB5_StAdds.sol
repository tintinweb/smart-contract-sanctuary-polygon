// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "./lib/EllipticCurve.sol";
import "./lib/Errors.sol";
import "./lib/Events.sol"; 

/**@title StAdds
 * A contract that creats a Stealth Address and keeps track of shared secrets
 */ 
contract StAdds is Events {
  // users can add a Shared Secret every 10 minutes
  uint256 public constant timeLock = 10 minutes;
  address public owner;
  address public pendingOwner;
  EC public ec;

  // Elliptic Curve point
  struct Point {
    bytes32 x;
    bytes32 y;
  }
  struct SharedSecret {
    bytes32 x;
    bytes32 y;
    address creator;
  }

  mapping (address => Point) publicKeys;
  mapping (address => SharedSecret[]) sharedSecrets;
  // cheaper than iterating over big arrays
  mapping (bytes => bool) isSharedSecretProvided;
  mapping (address => uint256) timeStamps;

  constructor() payable {
    owner = msg.sender;
    ec = new EC();
  }

  /**
   * @dev Only sender can provide their public key
   * @param publicKeyX - x coordinate of the public key
   * @param publicKeyY - y coordinate of the public key
   */
  function addPublicKey(bytes32 publicKeyX, bytes32 publicKeyY) external {
    if (isPublicKeyProvided(msg.sender)) revert Errors.PublicKeyProvided();
    bytes memory publicKey = abi.encodePacked(publicKeyX, publicKeyY);
    // 0x00FF... is a mask to get the address from the hashed public key
    bool isSender = (uint256(keccak256(publicKey)) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF) == uint256(uint160(msg.sender));
    if (!isSender) revert Errors.NotSender();
    publicKeys[msg.sender] = Point(publicKeyX, publicKeyY);
    emit NewPublicKey(msg.sender, publicKeyX, publicKeyY);
  }

  /**
   * @notice Remove sender's public key
   */
  function removePublicKey() external {
    if (!isPublicKeyProvided(msg.sender)) revert Errors.PublicKeyNotProvided();
    delete publicKeys[msg.sender];
    emit PublicKeyRemoved(msg.sender);
  }

  /**
   * @notice Add a Shared Secret
   * this creates a link between the sender and the receiver
   * @param receiver - address of the receiver
   * @param sharedSecretX - x coordinate of the Shared Secret
   * @param sharedSecretY - y coordinate of the Shared Secret
   */
  function addSharedSecret(
    address receiver,
    bytes32 sharedSecretX, 
    bytes32 sharedSecretY
  ) external {
    if (doesSharedSecretExist(
      sharedSecretX, 
      sharedSecretY
    )) revert Errors.SharedSecretExists();
    uint256 allowedTime = timeStamps[msg.sender];
    if (allowedTime != 0 && allowedTime > block.timestamp) revert Errors.SharedSecretCooldown();
    sharedSecrets[receiver].push(SharedSecret(
      sharedSecretX, 
      sharedSecretY,
      msg.sender
    ));
    timeStamps[msg.sender] = block.timestamp + timeLock;
    emit NewSharedSecret(
      msg.sender, 
      receiver, 
      sharedSecretX, 
      sharedSecretY
    ); 
  }

  /**
   * @notice Remove a shared secret
   * @param index - index of the shared secret
   * in the sharedSecret mapping
   */
  function removeSharedSecret(uint256 index) external {
    SharedSecret[] storage ShS = sharedSecrets[msg.sender];
    uint256 len = ShS.length;
    if (len == 0 || index >= len) revert Errors.WrongIndex();
    bytes32 ShSX = ShS[index].x;
    bytes32 ShSY = ShS[index].y;
    if (ShSX == 0 && ShSY == 0) revert Errors.WrongIndex();
    delete ShS[index];
    bytes memory ShSLong = abi.encodePacked(ShSX, ShSY);
    delete isSharedSecretProvided[ShSLong];
    emit SharedSecretRemoved(msg.sender, index);
  }

  /**
   * @notice Get stealth address from a public key
   * stored in the contract
   * @param secret - salt to generate a stealth address
   */
  function getStealthAddressFromAddress(
    address recipientAddress, 
    string calldata secret
  ) external view returns (
    address stealthAddress, 
    bytes32 sharedSecretX,
    bytes32 sharedSecretY
  ) {
    Point storage publicKey = publicKeys[recipientAddress];
    bytes32 publicKeyX = publicKey.x;
    bytes32 publicKeyY = publicKey.y;
    if (
      publicKeyX == 0x0 && 
      publicKeyY == 0x0
    ) revert Errors.PublicKeyNotProvided();

    bytes32 secretToNumber = keccak256(bytes(secret));

    Point memory sharedSecretPoint;
    (sharedSecretPoint.x, sharedSecretPoint.y) = ec.mul(
      secretToNumber, 
      publicKeyX, 
      publicKeyY
    );
    bytes32 sharedSecretPointToNumber = keccak256(abi.encodePacked(
      sharedSecretPoint.x, 
      sharedSecretPoint.y
    ));
    Point memory sharedSecretGPoint;
    (sharedSecretGPoint.x, sharedSecretGPoint.y) = ec.mulG(sharedSecretPointToNumber);

    Point memory stealthPublicKey;
    (stealthPublicKey.x, stealthPublicKey.y) = ec.add(
      publicKeyX, 
      publicKeyY, 
      sharedSecretGPoint.x, 
      sharedSecretGPoint.y
    );
    uint256 stealthPublicKeyToNumber = uint256(keccak256(abi.encodePacked(
      stealthPublicKey.x, 
      stealthPublicKey.y
    )));

    stealthAddress = address(uint160(stealthPublicKeyToNumber) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

    (sharedSecretX, sharedSecretY) = ec.mulG(secretToNumber);
  }

  /**
   * @notice Get stealth address from a public key
   * @param secret - salt to generate a stealth address
   */
  function getStealthAddressFromPublicKey(
    bytes32 publicKeyX,
    bytes32 publicKeyY, 
    string calldata secret
  ) external view returns (
    address stealthAddress, 
    bytes32 sharedSecretX,
    bytes32 sharedSecretY
  ) {
    if (
      publicKeyX == 0x0 && 
      publicKeyY == 0x0
    ) revert Errors.PublicKeyNotProvided();

    bytes32 secretToNumber = keccak256(bytes(secret));

    Point memory sharedSecretPoint;
    (sharedSecretPoint.x, sharedSecretPoint.y) = ec.mul(
      secretToNumber, 
      publicKeyX, 
      publicKeyY
    );
    bytes32 sharedSecretPointToNumber = keccak256(abi.encodePacked(
      sharedSecretPoint.x, 
      sharedSecretPoint.y
    ));
    Point memory sharedSecretGPoint;
    (sharedSecretGPoint.x, sharedSecretGPoint.y) = ec.mulG(sharedSecretPointToNumber);

    Point memory stealthPublicKey;
    (stealthPublicKey.x, stealthPublicKey.y) = ec.add(
      publicKeyX, 
      publicKeyY, 
      sharedSecretGPoint.x, 
      sharedSecretGPoint.y
    );
    uint256 stealthPublicKeyToNumber = uint256(keccak256(abi.encodePacked(
      stealthPublicKey.x, 
      stealthPublicKey.y
    )));

    stealthAddress = address(uint160(stealthPublicKeyToNumber) & 0x00FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

    (sharedSecretX, sharedSecretY) = ec.mulG(secretToNumber);
  }

  /**
   * @notice Get stealth address
   */  
  function getStealthPrivateKey(
    bytes32 privateKey,
    bytes32 sharedSecretX,
    bytes32 sharedSecretY
  ) external view returns (bytes32 stealthPrivateKey) {
    // Biggest number allowed
    // https://ethereum.stackexchange.com/questions/10055/is-each-ethereum-address-shared-by-theoretically-2-96-private-keys
    uint256 modulo = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141;

    Point memory sharedSecretPoint;
    (sharedSecretPoint.x, sharedSecretPoint.y) = ec.mul(
      privateKey, 
      sharedSecretX, 
      sharedSecretY
    ); 
    uint256 sharedSecretPointToNumber = uint256(keccak256(abi.encodePacked(
      sharedSecretPoint.x, 
      sharedSecretPoint.y
    )));

    unchecked {
      stealthPrivateKey = bytes32(addmod(
        uint256(privateKey), 
        sharedSecretPointToNumber,
        modulo
      ));
    }
  }

  function withdraw() external payable OnlyOwner {
    uint256 funds = address(this).balance;
    if (funds == 0) revert Errors.NotEnoughMATIC();
    (bool s,) = msg.sender.call{value: funds}("");
    if (!s) revert();
    emit FundsWithdrawn(msg.sender, funds);
  }

  function proposeOwner(address _addr) external payable OnlyOwner {
    pendingOwner = _addr;
    emit NewOwnerProposed(msg.sender, _addr);
  }

  function acceptOwnership() external payable {
    if (pendingOwner != msg.sender) revert Errors.NotOwner();
    owner = msg.sender;
    delete pendingOwner;
    emit OwnershipAccepted(msg.sender);
  }

  /**
   * @notice returns the public key of _addr
   */
  function getPublicKey(address _addr) external view returns (Point memory) {
    return publicKeys[_addr];
  }

  /**
   * @notice returns all shared secrets of _addr
   */
  function getSharedSecrets(address _addr) external view returns (SharedSecret[] memory) {
    return sharedSecrets[_addr];
  }

  /**
   * @notice returns the timestamp of _addr
   */
  function getTimestamp(address _addr) external view returns (uint256) {
    return timeStamps[_addr];
  }

  function isPublicKeyProvided(address _addr) internal view returns (bool) {
    Point storage PBK = publicKeys[_addr];
    return (PBK.x != 0 && PBK.y != 0);
  }

  function doesSharedSecretExist( 
    bytes32 sharedSecretX,
    bytes32 sharedSecretY
  ) internal view returns (bool) {
    bytes memory sharedSecretLong = abi.encodePacked(
      sharedSecretX, 
      sharedSecretY
    );
    return isSharedSecretProvided[sharedSecretLong];
  } 

  modifier OnlyOwner {
    if (msg.sender != owner) revert Errors.NotOwner();
    _;
  }

  receive() external payable {}
}

contract EC {
  uint256 public constant GX = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798;
  uint256 public constant GY = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8;
  uint256 public constant AA = 0;
  uint256 public constant BB = 7;
  uint256 public constant PP = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F;

  /**
   * @dev Multiplies scalar _k and an ec point
   */
  function mul(
    bytes32 _k, 
    bytes32 _x, 
    bytes32 _y
  ) external pure returns (
    bytes32 qx, 
    bytes32 qy
  ) {
    (uint256 x, uint256 y) = EllipticCurve.ecMul(
      uint256(_k),
      uint256(_x),
      uint256(_y),
      AA,
      PP
    );

    qx = bytes32(x);
    qy = bytes32(y);
  }

  /**
   * @dev Multiplies scalar _k and a generator point G
   */
  function mulG(bytes32 _k) external pure returns (
    bytes32 qx, 
    bytes32 qy
  ) {
    (uint256 x, uint256 y) = EllipticCurve.ecMul(
      uint256(_k),
      GX,
      GY,
      AA,
      PP
    );

    qx = bytes32(x);
    qy = bytes32(y);
  }

  function add(
    bytes32 _x1, 
    bytes32 _y1, 
    bytes32 _x2, 
    bytes32 _y2
  ) external pure returns (
    bytes32 qx, 
    bytes32 qy
  ) {
    (uint256 x, uint256 y) = EllipticCurve.ecAdd(
      uint256(_x1),
      uint256(_y1),
      uint256(_x2),
      uint256(_y2),
      AA,
      PP
    );

    qx = bytes32(x);
    qy = bytes32(y);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

/**
 * @title Elliptic Curve Library
 * @dev Library providing arithmetic operations over elliptic curves.
 * This library does not check whether the inserted points belong to the curve
 * `isOnCurve` function should be used by the library user to check the aforementioned statement.
 * @author Witnet Foundation
 */
library EllipticCurve {
  
  // Pre-computed constant for 2 ** 255
  uint256 constant private U255_MAX_PLUS_1 = 57896044618658097711785492504343953926634992332820282019728792003956564819968;

  /// @dev Modular euclidean inverse of a number (mod p).
  /// @param _x The number
  /// @param _pp The modulus
  /// @return q such that x*q = 1 (mod _pp)
  function invMod(uint256 _x, uint256 _pp) internal pure returns (uint256) {
    require(_x != 0 && _x != _pp && _pp != 0, "Invalid number");
    uint256 q = 0;
    uint256 newT = 1;
    uint256 r = _pp;
    uint256 t;
    while (_x != 0) {
      t = r / _x;
      (q, newT) = (newT, addmod(q, (_pp - mulmod(t, newT, _pp)), _pp));
      (r, _x) = (_x, r - t * _x);
    }

    return q;
  }

  /// @dev Modular exponentiation, b^e % _pp.
  /// Source: https://github.com/androlo/standard-contracts/blob/master/contracts/src/crypto/ECCMath.sol
  /// @param _base base
  /// @param _exp exponent
  /// @param _pp modulus
  /// @return r such that r = b**e (mod _pp)
  function expMod(uint256 _base, uint256 _exp, uint256 _pp) internal pure returns (uint256) {
    require(_pp!=0, "Modulus is zero");

    if (_base == 0)
      return 0;
    if (_exp == 0)
      return 1;

    uint256 r = 1;
    uint256 bit = U255_MAX_PLUS_1;
    assembly {
      for { } gt(bit, 0) { }{
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, bit)))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 2))))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 4))))), _pp)
        r := mulmod(mulmod(r, r, _pp), exp(_base, iszero(iszero(and(_exp, div(bit, 8))))), _pp)
        bit := div(bit, 16)
      }
    }

    return r;
  }

  /// @dev Converts a point (x, y, z) expressed in Jacobian coordinates to affine coordinates (x', y', 1).
  /// @param _x coordinate x
  /// @param _y coordinate y
  /// @param _z coordinate z
  /// @param _pp the modulus
  /// @return (x', y') affine coordinates
  function toAffine(
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _pp)
  internal pure returns (uint256, uint256)
  {
    uint256 zInv = invMod(_z, _pp);
    uint256 zInv2 = mulmod(zInv, zInv, _pp);
    uint256 x2 = mulmod(_x, zInv2, _pp);
    uint256 y2 = mulmod(_y, mulmod(zInv, zInv2, _pp), _pp);

    return (x2, y2);
  }

  /// @dev Derives the y coordinate from a compressed-format point x [[SEC-1]](https://www.secg.org/SEC1-Ver-1.0.pdf).
  /// @param _prefix parity byte (0x02 even, 0x03 odd)
  /// @param _x coordinate x
  /// @param _aa constant of curve
  /// @param _bb constant of curve
  /// @param _pp the modulus
  /// @return y coordinate y
  function deriveY(
    uint8 _prefix,
    uint256 _x,
    uint256 _aa,
    uint256 _bb,
    uint256 _pp)
  internal pure returns (uint256)
  {
    require(_prefix == 0x02 || _prefix == 0x03, "Invalid compressed EC point prefix");

    // x^3 + ax + b
    uint256 y2 = addmod(mulmod(_x, mulmod(_x, _x, _pp), _pp), addmod(mulmod(_x, _aa, _pp), _bb, _pp), _pp);
    y2 = expMod(y2, (_pp + 1) / 4, _pp);
    // uint256 cmp = yBit ^ y_ & 1;
    uint256 y = (y2 + _prefix) % 2 == 0 ? y2 : _pp - y2;

    return y;
  }

  /// @dev Check whether point (x,y) is on curve defined by a, b, and _pp.
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _aa constant of curve
  /// @param _bb constant of curve
  /// @param _pp the modulus
  /// @return true if x,y in the curve, false else
  function isOnCurve(
    uint _x,
    uint _y,
    uint _aa,
    uint _bb,
    uint _pp)
  internal pure returns (bool)
  {
    if (0 == _x || _x >= _pp || 0 == _y || _y >= _pp) {
      return false;
    }
    // y^2
    uint lhs = mulmod(_y, _y, _pp);
    // x^3
    uint rhs = mulmod(mulmod(_x, _x, _pp), _x, _pp);
    if (_aa != 0) {
      // x^3 + a*x
      rhs = addmod(rhs, mulmod(_x, _aa, _pp), _pp);
    }
    if (_bb != 0) {
      // x^3 + a*x + b
      rhs = addmod(rhs, _bb, _pp);
    }

    return lhs == rhs;
  }

  /// @dev Calculate inverse (x, -y) of point (x, y).
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _pp the modulus
  /// @return (x, -y)
  function ecInv(
    uint256 _x,
    uint256 _y,
    uint256 _pp)
  internal pure returns (uint256, uint256)
  {
    return (_x, (_pp - _y) % _pp);
  }

  /// @dev Add two points (x1, y1) and (x2, y2) in affine coordinates.
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _x2 coordinate x of P2
  /// @param _y2 coordinate y of P2
  /// @param _aa constant of the curve
  /// @param _pp the modulus
  /// @return (qx, qy) = P1+P2 in affine coordinates
  function ecAdd(
    uint256 _x1,
    uint256 _y1,
    uint256 _x2,
    uint256 _y2,
    uint256 _aa,
    uint256 _pp)
    internal pure returns(uint256, uint256)
  {
    uint x = 0;
    uint y = 0;
    uint z = 0;

    // Double if x1==x2 else add
    if (_x1==_x2) {
      // y1 = -y2 mod p
      if (addmod(_y1, _y2, _pp) == 0) {
        return(0, 0);
      } else {
        // P1 = P2
        (x, y, z) = jacDouble(
          _x1,
          _y1,
          1,
          _aa,
          _pp);
      }
    } else {
      (x, y, z) = jacAdd(
        _x1,
        _y1,
        1,
        _x2,
        _y2,
        1,
        _pp);
    }
    // Get back to affine
    return toAffine(
      x,
      y,
      z,
      _pp);
  }

  /// @dev Substract two points (x1, y1) and (x2, y2) in affine coordinates.
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _x2 coordinate x of P2
  /// @param _y2 coordinate y of P2
  /// @param _aa constant of the curve
  /// @param _pp the modulus
  /// @return (qx, qy) = P1-P2 in affine coordinates
  function ecSub(
    uint256 _x1,
    uint256 _y1,
    uint256 _x2,
    uint256 _y2,
    uint256 _aa,
    uint256 _pp)
  internal pure returns(uint256, uint256)
  {
    // invert square
    (uint256 x, uint256 y) = ecInv(_x2, _y2, _pp);
    // P1-square
    return ecAdd(
      _x1,
      _y1,
      x,
      y,
      _aa,
      _pp);
  }

  /// @dev Multiply point (x1, y1, z1) times d in affine coordinates.
  /// @param _k scalar to multiply
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _aa constant of the curve
  /// @param _pp the modulus
  /// @return (qx, qy) = d*P in affine coordinates
  function ecMul(
    uint256 _k,
    uint256 _x,
    uint256 _y,
    uint256 _aa,
    uint256 _pp)
  internal pure returns(uint256, uint256)
  {
    // Jacobian multiplication
    (uint256 x1, uint256 y1, uint256 z1) = jacMul(
      _k,
      _x,
      _y,
      1,
      _aa,
      _pp);
    // Get back to affine
    return toAffine(
      x1,
      y1,
      z1,
      _pp);
  }

  /// @dev Adds two points (x1, y1, z1) and (x2 y2, z2).
  /// @param _x1 coordinate x of P1
  /// @param _y1 coordinate y of P1
  /// @param _z1 coordinate z of P1
  /// @param _x2 coordinate x of square
  /// @param _y2 coordinate y of square
  /// @param _z2 coordinate z of square
  /// @param _pp the modulus
  /// @return (qx, qy, qz) P1+square in Jacobian
  function jacAdd(
    uint256 _x1,
    uint256 _y1,
    uint256 _z1,
    uint256 _x2,
    uint256 _y2,
    uint256 _z2,
    uint256 _pp)
  internal pure returns (uint256, uint256, uint256)
  {
    if (_x1==0 && _y1==0)
      return (_x2, _y2, _z2);
    if (_x2==0 && _y2==0)
      return (_x1, _y1, _z1);

    // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
    uint[4] memory zs; // z1^2, z1^3, z2^2, z2^3
    zs[0] = mulmod(_z1, _z1, _pp);
    zs[1] = mulmod(_z1, zs[0], _pp);
    zs[2] = mulmod(_z2, _z2, _pp);
    zs[3] = mulmod(_z2, zs[2], _pp);

    // u1, s1, u2, s2
    zs = [
      mulmod(_x1, zs[2], _pp),
      mulmod(_y1, zs[3], _pp),
      mulmod(_x2, zs[0], _pp),
      mulmod(_y2, zs[1], _pp)
    ];

    // In case of zs[0] == zs[2] && zs[1] == zs[3], double function should be used
    require(zs[0] != zs[2] || zs[1] != zs[3], "Use jacDouble function instead");

    uint[4] memory hr;
    //h
    hr[0] = addmod(zs[2], _pp - zs[0], _pp);
    //r
    hr[1] = addmod(zs[3], _pp - zs[1], _pp);
    //h^2
    hr[2] = mulmod(hr[0], hr[0], _pp);
    // h^3
    hr[3] = mulmod(hr[2], hr[0], _pp);
    // qx = -h^3  -2u1h^2+r^2
    uint256 qx = addmod(mulmod(hr[1], hr[1], _pp), _pp - hr[3], _pp);
    qx = addmod(qx, _pp - mulmod(2, mulmod(zs[0], hr[2], _pp), _pp), _pp);
    // qy = -s1*z1*h^3+r(u1*h^2 -x^3)
    uint256 qy = mulmod(hr[1], addmod(mulmod(zs[0], hr[2], _pp), _pp - qx, _pp), _pp);
    qy = addmod(qy, _pp - mulmod(zs[1], hr[3], _pp), _pp);
    // qz = h*z1*z2
    uint256 qz = mulmod(hr[0], mulmod(_z1, _z2, _pp), _pp);
    return(qx, qy, qz);
  }

  /// @dev Doubles a points (x, y, z).
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _z coordinate z of P1
  /// @param _aa the a scalar in the curve equation
  /// @param _pp the modulus
  /// @return (qx, qy, qz) 2P in Jacobian
  function jacDouble(
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _aa,
    uint256 _pp)
  internal pure returns (uint256, uint256, uint256)
  {
    if (_z == 0)
      return (_x, _y, _z);

    // We follow the equations described in https://pdfs.semanticscholar.org/5c64/29952e08025a9649c2b0ba32518e9a7fb5c2.pdf Section 5
    // Note: there is a bug in the paper regarding the m parameter, M=3*(x1^2)+a*(z1^4)
    // x, y, z at this point represent the squares of _x, _y, _z
    uint256 x = mulmod(_x, _x, _pp); //x1^2
    uint256 y = mulmod(_y, _y, _pp); //y1^2
    uint256 z = mulmod(_z, _z, _pp); //z1^2

    // s
    uint s = mulmod(4, mulmod(_x, y, _pp), _pp);
    // m
    uint m = addmod(mulmod(3, x, _pp), mulmod(_aa, mulmod(z, z, _pp), _pp), _pp);

    // x, y, z at this point will be reassigned and rather represent qx, qy, qz from the paper
    // This allows to reduce the gas cost and stack footprint of the algorithm
    // qx
    x = addmod(mulmod(m, m, _pp), _pp - addmod(s, s, _pp), _pp);
    // qy = -8*y1^4 + M(S-T)
    y = addmod(mulmod(m, addmod(s, _pp - x, _pp), _pp), _pp - mulmod(8, mulmod(y, y, _pp), _pp), _pp);
    // qz = 2*y1*z1
    z = mulmod(2, mulmod(_y, _z, _pp), _pp);

    return (x, y, z);
  }

  /// @dev Multiply point (x, y, z) times d.
  /// @param _d scalar to multiply
  /// @param _x coordinate x of P1
  /// @param _y coordinate y of P1
  /// @param _z coordinate z of P1
  /// @param _aa constant of curve
  /// @param _pp the modulus
  /// @return (qx, qy, qz) d*P1 in Jacobian
  function jacMul(
    uint256 _d,
    uint256 _x,
    uint256 _y,
    uint256 _z,
    uint256 _aa,
    uint256 _pp)
  internal pure returns (uint256, uint256, uint256)
  {
    // Early return in case that `_d == 0`
    if (_d == 0) {
      return (_x, _y, _z);
    }

    uint256 remaining = _d;
    uint256 qx = 0;
    uint256 qy = 0;
    uint256 qz = 1;

    // Double and add algorithm
    while (remaining != 0) {
      if ((remaining & 1) != 0) {
        (qx, qy, qz) = jacAdd(
          qx,
          qy,
          qz,
          _x,
          _y,
          _z,
          _pp);
      }
      remaining = remaining / 2;
      (_x, _y, _z) = jacDouble(
        _x,
        _y,
        _z,
        _aa,
        _pp);
    }
    return (qx, qy, qz);
  }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

library Errors {
  error NotOwner();
  error NotSender();
  error PublicKeyProvided();
  error PublicKeyNotProvided();
  error NotEnoughMATIC();
  error WrongIndex();
  error SharedSecretExists();
  error SharedSecretCooldown();
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

contract Events {
  event NewPublicKey(address indexed sender, bytes32 PBx, bytes32 PBy);
  event PublicKeyRemoved(address indexed sender);
  event NewSharedSecret(
    address indexed sender, 
    address indexed receiver,
    bytes32 sharedSecretX, 
    bytes32 sharedSecretY
  );
  event SharedSecretRemoved(
    address indexed sender,
    uint256 indexed index
  );
  event FundsWithdrawn(address indexed sender, uint256 amount);
  event NewOwnerProposed(address indexed owner, address indexed newOwner);
  event OwnershipAccepted(address indexed owner);
}