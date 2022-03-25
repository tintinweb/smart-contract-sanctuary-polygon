/**
 *Submitted for verification at polygonscan.com on 2022-03-24
*/

pragma solidity ^0.8.0;

interface I0bOptions {
    function initCycle() external;
    function NextCurrentGame() external;
    function joinUp() external payable;
    function joinDown() external payable;
    function reward(uint[] memory idGames) external;
    function rewardAdmin(address payable _address) external;
    function isWinner(uint idGame, address _address) external view returns(bool _isWinner);
    function getCurrentPrice() external view returns(int _price);
    function getUserGames(address _user) external view returns(uint[] memory games);
    function getUserAvailableWins(address _user) external view returns(uint[] memory _winGames);
    function getUserWins(address _user) external view returns(uint[] memory _winGames);
    function getUserTotalAmount(address _user) external view returns(uint amountGames);
    function getUserWinAmount(address _user) external view returns(uint _winAmount);
    function setIntervalSeconds(uint _intervalSeconds) external;

    function currentGameId() external view returns (uint);
    function Games(uint) external view returns (uint256, uint256, uint256, uint256, uint256, bool, uint256, int256);
    function users(uint, address) external view returns (uint256, uint8, bool);
    function userGames(address, uint256) external view returns (uint256);
}

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract claim {

    struct Winner{
        uint lastGameLength;
    }

    uint public rewardAmountByGame;
    uint public rewardAmount;
    uint public currentRewardAmount;
    address public admin;

    mapping(uint => int) public nbWinnersByIndex;
    mapping(address => Winner) public winners;
    uint public index;

    I0bOptions public ObContract;
    IERC20 public ObToken;

    event AddReward(address indexed admin, uint amount);
    event GetRewardGames(address indexed from, uint amount);

    constructor(){
        ObContract = I0bOptions(0xCa2d0B66cb00C9FFB7C35602c65EbefD06e291cB);
        ObToken = IERC20(0x77127bEC1015d13B03CB6364E49c050C0FE1f22a);
        rewardAmountByGame = 10 * (10**18);
        admin = msg.sender;
    }

    function addReward() external payable {
        uint amount = ObToken.allowance(msg.sender, address(this));

        require(ObToken.transferFrom(msg.sender, address(this), amount), 'Failed to send.');

        rewardAmount += amount;
        currentRewardAmount += amount;

        emit AddReward(msg.sender, amount);
    }

    function getRewardGames() external {

        Winner storage user = winners[msg.sender];

        (bool win, uint games, uint cpt) = isWinnerGames(msg.sender);
        require(win, "No game available.");

        user.lastGameLength = games;
        
        if(rewardAmount < cpt * rewardAmountByGame){
            require(rewardAmount > 0, "The contract is empty.");

            bool t = ObToken.transfer(msg.sender, rewardAmount);
            require(t, 'Failed to send.');

            currentRewardAmount -= rewardAmount;
        }else{
            require(rewardAmount > 0, "The contract is empty.");

            bool t = ObToken.transfer(msg.sender, cpt * rewardAmountByGame);
            require(t, 'Failed to send.');

            currentRewardAmount -= cpt * rewardAmountByGame;
        }

        emit GetRewardGames(msg.sender, cpt * rewardAmountByGame);
    }

    function isWinnerGames(address _address) public view returns (bool, uint, uint) {

        uint totalGames = ObContract.getUserGames(_address).length;
        Winner storage user = winners[_address];

        uint pendingLength = totalGames - user.lastGameLength;

        uint cpt;
        
        if(pendingLength > 0){
            
            for(uint i=user.lastGameLength; i < totalGames; i++){
                (uint256 amount, , ) = ObContract.users(ObContract.userGames(_address, i), _address);
                if(amount >= 1 ether)   cpt++;
            }

            return (pendingLength > 0 && cpt > 0, totalGames, cpt);
        }

        return (false, totalGames, 0);
    }
    
}