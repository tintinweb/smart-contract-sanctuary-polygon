// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

contract Whotie {
    struct Game {
        address player1;
        address player2;
        uint256 stake;
        address winner;
        bool finished;
    }

    mapping(string => Game) public games;

    address public owner;

    bool private locked;

    address public communityWallet;
    address public premiumHoldersContract;
    address public proHoldersContract;
    address public basicHoldersContract;

    uint256 public COMMUNITY_FEE = 4;
    uint256 public PREMIUM_HOLDER_REWARD = 50;
    uint256 public PRO_HOLDER_REWARD = 35;
    uint256 public BASIC_HOLDER_REWARD = 15;

    event GameCreated(
        string indexed gameId,
        address indexed player1,
        uint256 stake
    );

    event GameJoined(string indexed gameId, address indexed player2);

    event GameFinished(
        string indexed gameId,
        address indexed winner,
        uint256 amountWon
    );

    constructor(
        address _communityWallet,
        address _premiumHoldersContract,
        address _proHoldersContract,
        address _basicHoldersContract
    ) {
        owner = msg.sender;
        communityWallet = _communityWallet;
        premiumHoldersContract = _premiumHoldersContract;
        proHoldersContract = _proHoldersContract;
        basicHoldersContract = _basicHoldersContract;
    }

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "Only contract owner can call this function."
        );
        _;
    }

    modifier noReentrant() {
        require(!locked, "Reentrant call.");
        locked = true;
        _;
        locked = false;
    }

    function setCommunityFee(uint256 newFee) external onlyOwner {
        require(newFee <= 20, "Community fee cannot exceed 20%.");
        COMMUNITY_FEE = newFee;
    }

    function setCommunityWallet(address newWallet) external onlyOwner {
        require(
            newWallet != communityWallet,
            "This is the assigned Community Wallet Address"
        );
        communityWallet = newWallet;
    }

    function setPremiumHolders(address newWallet) external onlyOwner {
        require(
            newWallet != premiumHoldersContract,
            "This is the assigned Premium Holder Address"
        );
        premiumHoldersContract = newWallet;
    }

    function setProHolders(address newWallet) external onlyOwner {
        require(
            newWallet != proHoldersContract,
            "This is the assigned Pro Holder Address"
        );
        proHoldersContract = newWallet;
    }

    function setBasicHolders(address newWallet) external onlyOwner {
        require(
            newWallet != basicHoldersContract,
            "This is the assigned Basic Holder Address"
        );
        basicHoldersContract = newWallet;
    }

    function setPremiumHolderReward(uint256 newReward) external onlyOwner {
        PREMIUM_HOLDER_REWARD = newReward;
    }

    function setProHolderReward(uint256 newReward) external onlyOwner {
        PRO_HOLDER_REWARD = newReward;
    }

    function setBasicHolderReward(uint256 newReward) external onlyOwner {
        BASIC_HOLDER_REWARD = newReward;
    }

    function createGame(string memory gameId) external payable {
        require(games[gameId].player1 == address(0), "Game ID already exists");

        games[gameId] = Game(
            payable(msg.sender),
            address(0),
            msg.value,
            address(0),
            false
        );

        emit GameCreated(gameId, msg.sender, msg.value);
    }

    function joinGame(string memory gameId) external payable {
        require(
            games[gameId].player1 != msg.sender,
            "You are the game creator!"
        );
        require(games[gameId].player1 != address(0), "Game does not exist");
        require(games[gameId].player2 == address(0), "Game is already full");
        require(msg.value == games[gameId].stake, "Invalid stake amount");

        games[gameId].player2 = msg.sender;

        emit GameJoined(gameId, msg.sender);
    }

    function collectReward(
        string memory gameId,
        address payable winner
    ) external payable noReentrant {
        require(games[gameId].player1 != address(0), "Game ID does not exist");
        require(games[gameId].finished == false, "Game has already finished");
        require(
            msg.sender == games[gameId].player1 ||
                msg.sender == games[gameId].player2,
            "Only players can finish the game"
        );
        require(msg.sender == winner, "Invalid winner address");

        uint256 totalStake = games[gameId].stake * 2;
        uint256 communityFee = (totalStake * COMMUNITY_FEE) / 100;
        uint256 amountWon = (totalStake * 95) / 100;
        uint256 holderReward = (totalStake * 1) / 100;

        require(
            address(this).balance >= totalStake,
            "Insufficient contract balance"
        );

        payable(communityWallet).transfer(communityFee);
        payable(premiumHoldersContract).transfer(
            (holderReward * PREMIUM_HOLDER_REWARD) / 100
        );
        payable(proHoldersContract).transfer(
            (holderReward * PRO_HOLDER_REWARD) / 100
        );
        payable(basicHoldersContract).transfer(
            (holderReward * BASIC_HOLDER_REWARD) / 100
        );

        winner.transfer(amountWon);

        games[gameId].winner = winner;
        games[gameId].finished = true;

        emit GameFinished(gameId, winner, amountWon);
    }

    function getGameDetails(
        string memory gameId
    )
        external
        view
        returns (
            address player1,
            address player2,
            uint256 stake,
            address winner,
            bool finished
        )
    {
        require(games[gameId].player1 != address(0), "Game ID does not exist");
        return (
            games[gameId].player1,
            games[gameId].player2,
            games[gameId].stake,
            games[gameId].winner,
            games[gameId].finished
        );
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    receive() external payable {}
}