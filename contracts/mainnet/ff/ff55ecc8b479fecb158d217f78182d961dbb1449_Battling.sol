// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Ownable.sol";
import "./VRFConsumerBase.sol";
import "./Set.sol";
import "./SignerVerifiable.sol";

contract Battling is Ownable, VRFConsumerBase, Set, SignerVerifiable {

    struct Battle {
        address player_one;
        address player_two;
    }

    uint256 public team_balance = 0;
    uint256 public community_balance = 0;
    mapping(address => uint256) public balances;
    mapping(uint256 => bool) public winner_paid;
    mapping(uint256 => mapping(address => bool)) public draw_paid_out;
    mapping(string => Battle) public battle_contestants;

    bool public contract_frozen = false;
    address public SIGNER = 0x499f6d0c92b17f922ed8A0846cEC3A4AFe458c86;
    
    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;

    modifier frozen {
        require(!contract_frozen, "Contract is currently paused");
        _;
    }

    modifier callerVerified(uint256 _amount, string memory _message, uint256 _battle_id, uint256 _deadline, bytes memory _signature) {
        require(decodeSignature(msg.sender, _amount, _message, _battle_id, _deadline, _signature) == SIGNER, "Call is not authorized");
        _;
    }

    function depositIntoCommunityChest() external payable {
        community_balance += msg.value;
    }

    // CHAINLINK FUNCTIONS 
    
    constructor () VRFConsumerBase(
            0x3d2341ADb2D31f1c5530cDC622016af293177AE0, // VRF Coordinator 0x3d2341ADb2D31f1c5530cDC622016af293177AE0
            0xb0897686c545045aFc77CF20eC7A532E3120E0F1  // LINK Token 0xb0897686c545045aFc77CF20eC7A532E3120E0F1
        ) {
            keyHash = 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da; // 0xf86195cf7690c55907b2b611ebb7343a6f649bff128701cc542f0569e2c549da
            fee = 0.0001 * 10 ** 18;
    }
    
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        return requestRandomness(keyHash, fee);
    }
    
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }
    
    function payoutCommunityChest(uint _num_winners) external onlyOwner {
        for (uint256 i = 0; i < _num_winners; ++i) {
            uint256 rand_num = uint256(keccak256(abi.encode(randomResult, i))) % Set.items_length;
            address selected_winner = Set.items[rand_num];
            balances[selected_winner] += community_balance / _num_winners;
        }   

        community_balance = 0;
    }

    
    // END CHAINLINK FUNCTIONS

    // USER FUNCTIONS
    
    function userDepositIntoContract() external payable frozen {
        balances[msg.sender] += msg.value;
    }
    
    function userWithdrawFromContract(uint256 _amount) external payable frozen {
        require(_amount <= balances[msg.sender], "Not enough balance to withdraw");
        balances[msg.sender] -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    // END USER FUNCTIONS

    // AUTHORIZED FUNCTIONS

    function initiateBattle(uint256 _amount, string memory _message, uint256 _battle_id, uint256 _deadline, bytes memory _signature, string memory _battle_seed) external frozen callerVerified(_amount, _message, _battle_id, _deadline, _signature) {
        require(_amount <= balances[msg.sender], "Player does not have enough balance");

        require(battle_contestants[_battle_seed].player_one == address(0x0) || battle_contestants[_battle_seed].player_two == address(0x0), "Battle is full");

        if (battle_contestants[_battle_seed].player_one == address(0x0)) {
            battle_contestants[_battle_seed].player_one = msg.sender;
        } else {
            battle_contestants[_battle_seed].player_two = msg.sender;
        }

        Set.add(msg.sender);
        balances[msg.sender] -= _amount;
    }
    
    function claimWinnings(uint256 _amount, string memory _message, uint256 _battle_id, uint256 _deadline, bytes memory _signature, string memory _battle_seed) external frozen callerVerified(_amount, _message, _battle_id, _deadline, _signature) {
        require(!winner_paid[_battle_id], "Rewards already claimed for battle");
        require(battle_contestants[_battle_seed].player_one == msg.sender || battle_contestants[_battle_seed].player_two == msg.sender, "User is not in this battle");
        
        winner_paid[_battle_id] = true;
        balances[msg.sender] += 95 * _amount / 100;
        team_balance += 4 * _amount / 100;
        community_balance += _amount / 100;
    }

    function returnWager(uint256 _amount, string memory _message, uint256 _battle_id, uint256 _deadline, bytes memory _signature, string memory _battle_seed) external frozen callerVerified(_amount, _message, _battle_id, _deadline, _signature) {
        require(!draw_paid_out[_battle_id][msg.sender], "Rewards already claimed for battle");
        require(battle_contestants[_battle_seed].player_one == msg.sender || battle_contestants[_battle_seed].player_two == msg.sender, "User is not in this battle");

        draw_paid_out[_battle_id][msg.sender] = true;
        balances[msg.sender] += _amount;
    }

    // END AUTHORIZED FUNCTIONS

    // OWNER FUNCTIONS

    function clearPlayers() external onlyOwner {
        Set.destroy();
    }
    
    function withdrawTeamBalance() external onlyOwner {
        payable(msg.sender).transfer(team_balance);
        team_balance = 0;
    }

    function toggleContractFreeze() external onlyOwner {
        contract_frozen = !contract_frozen;
    }
    
    function setSignerAddress(address _new_signer) external onlyOwner {
        SIGNER = _new_signer;
    }

    // END OWNER FUNCTIONS

    // HELPER FUNCTIONS

    function drawPaidOut(uint256 _battle_id, address _player) external view returns(bool) {
        return draw_paid_out[_battle_id][_player];
    }

    // END HELPER FUNCTIONS
    
}