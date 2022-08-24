/**
 *Submitted for verification at polygonscan.com on 2022-08-24
*/

// SPDX-License-Identifier: Apache-2.0
// Authors: six and Silur
pragma solidity ^0.8.16;

contract CCTF9 {
  address public admin;
  uint256 public volStart;
  uint256 public volMaxPoints;
  uint256 public powDiff;
  bool public started;

  enum PlayerStatus {
    Unverified,
    Verified,
    Banned
  }

  struct Player {
    PlayerStatus status;
    uint256 points;
  }

  modifier onlyAdmin {
    require(msg.sender == admin, "Not admin");
    _;
  }

  modifier onlyActive {
    require(started == true, "CCTF not started.");
    _;
  }

  struct Flag {
    address signer;
    bool onlyFirstSolver;
    uint256 points;
    string skill_name;
  }

  mapping (address => Player) public players;
  mapping (uint256 => Flag) public flags;

  event CCTFStarted(uint256 timestamp);
  event FlagAdded(uint256 indexed flagId, address flagSigner);
  event FlagRemoved(uint256 indexed flagId);
  event FlagSolved(uint256 indexed flagId, address indexed solver);

  constructor(uint256 _volMaxPoints, uint256 _powDiff) {
    admin = msg.sender;
    volMaxPoints = _volMaxPoints;
    powDiff = _powDiff;
    started = false;
  }
  
  function setAdmin(address _admin) external onlyAdmin {
    require(_admin != address(0));
    admin = _admin;
  }

  function setCCTFStatus(bool _started) external onlyAdmin {
    started = _started;
  }

  function setFlag(uint256 _flagId, address _flagSigner, bool _onlyFirstSolver, uint256 _points, string memory _skill) external onlyAdmin{
    flags[_flagId] = Flag(_flagSigner, _onlyFirstSolver, _points, _skill);
    emit FlagAdded(_flagId, _flagSigner);
  }

  function setPowDiff(uint256 _powDiff) external onlyAdmin {
    powDiff = _powDiff;
  }


  function register(string memory _RTFM) external {
    require(players[msg.sender].status == PlayerStatus.Unverified, 'Already registered or banned');
    //uint256 pow = uint256(keccak256(abi.encodePacked("CCTF", msg.sender,"registration", nonce)));
    //require(pow < powDiff, "invalid pow");
    require(keccak256(abi.encodePacked('I_read_it')) == keccak256(abi.encodePacked(_RTFM)));  // PoW can be used for harder challenges, this is Entry!
    players[msg.sender].status = PlayerStatus.Verified;
  }

  function setPlayerStatus(address player, PlayerStatus status) external onlyAdmin {
    players[player].status = status;
  }
  
  
////////// Submit flags
    mapping(bytes32 => bool) usedNs;                       // Against replay attack (we only check message signer)
    mapping (address => mapping (uint256 => bool)) Solves;     // address -> challenge ID -> solved/not
    uint256 public submission_success_count = 0;               // For statistics

    function SubmitFlag(bytes32 _message, bytes memory signature, uint256 _submitFor) external onlyActive {
        require(players[msg.sender].status == PlayerStatus.Verified, "You are not even playing");
        require(bytes32(_message).length <= 256, "Too long message.");
        require(!usedNs[_message]);
        usedNs[_message] = true;
        require(recoverSigner(_message, signature) == flags[_submitFor].signer, "Not signed with the correct key.");
        require(Solves[msg.sender][_submitFor] == false);
        
        Solves[msg.sender][_submitFor] = true;
        players[msg.sender].points += flags[_submitFor].points;
        players[msg.sender].points = players[msg.sender].points < volMaxPoints ? players[msg.sender].points : volMaxPoints;
        
        if (flags[_submitFor].onlyFirstSolver) {
            flags[_submitFor].points = 0;
        }
        
        submission_success_count = submission_success_count + 1;
        emit FlagSolved(_submitFor, msg.sender);
    }

    function recoverSigner(bytes32 _ethSignedMessageHash, bytes memory _signature) public pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig) public pure returns (bytes32 r, bytes32 s, uint8 v){
        require(sig.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

////////// Check status, scores, etc
  function getPlayerStatus(address _player) external view returns (PlayerStatus) {
    return players[_player].status;
  }

  function getPlayerPoints(address _player) external view returns (uint256) {
    return players[_player].points < volMaxPoints ? players[_player].points : volMaxPoints;
  } 

  function getSuccessfulSubmissionCount() external view returns (uint256){
      return submission_success_count;
  }
}