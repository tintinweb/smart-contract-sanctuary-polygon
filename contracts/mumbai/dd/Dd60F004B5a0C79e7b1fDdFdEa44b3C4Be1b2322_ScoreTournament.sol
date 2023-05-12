// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "./Miracle-Tournament-Score-G1.sol";

//    _______ _______ ___ ___ _______ ______  ___     ___ ______  _______     ___     _______ _______  _______ 
//   |   _   |   _   |   Y   |   _   |   _  \|   |   |   |   _  \|   _   |   |   |   |   _   |   _   \|   _   |
//   |   1___|.  1___|.  |   |.  1___|.  |   |.  |   |.  |.  |   |.  1___|   |.  |   |.  1   |.  1   /|   1___|
//   |____   |.  __)_|.  |   |.  __)_|.  |   |.  |___|.  |.  |   |.  __)_    |.  |___|.  _   |.  _   \|____   |
//   |:  1   |:  1   |:  1   |:  1   |:  |   |:  1   |:  |:  |   |:  1   |   |:  1   |:  |   |:  1    |:  1   |
//   |::.. . |::.. . |\:.. ./|::.. . |::.|   |::.. . |::.|::.|   |::.. . |   |::.. . |::.|:. |::.. .  |::.. . |
//   `-------`-------' `---' `-------`--- ---`-------`---`--- ---`-------'   `-------`--- ---`-------'`-------'
//       

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract TournamentEscrow {
    address public admin;
    address public tournamentAddr;
    ScoreTournament internal scoretournament;

    struct Tournament {
        address organizer;
        IERC20 prizeToken;
        IERC20 feeToken;
        uint prizeAmount;
        uint registrationFee;
        uint feeBalance;
        uint256[] withdrawAmount;
        mapping (address => uint256) AddrwithdrawAmount;
    }
    mapping(uint => Tournament) public tournamentMapping;

    event UnlockFee(uint tournamentId, uint feeBalance);
    event PrizePaid(uint tournamentId, address account, uint PrizeAmount);

    constructor(address adminAddr) {
        admin = adminAddr;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyTournament(){
        require(msg.sender == tournamentAddr, "Only tournament contract can call this function");
        _;
    }

    function connectTournament(address _scoretournament) public onlyAdmin{
        tournamentAddr = _scoretournament;
        scoretournament = ScoreTournament(_scoretournament);
    }

    function createTournamentEscrow(uint _tournamentId, address _prizeToken, address _feeToken, uint _prizeAmount, uint _registrationFee, uint _registerStartTime, uint _registerEndTime, uint _tournamentStartTime, uint _tournamentEndTime, uint256[] memory _withdrawAmount, string memory _tournamentURI) public {
        require(IERC20(_prizeToken).allowance(msg.sender, address(this)) >= _prizeAmount, "Allowance is not sufficient.");
        require(_prizeAmount <= IERC20(_prizeToken).balanceOf(msg.sender), "Insufficient balance.");
        require(IERC20(_prizeToken).transferFrom(msg.sender, address(this), _prizeAmount), "Transfer failed.");
        uint256 totalWithdrawAmount;
        for (uint256 i = 0; i < _withdrawAmount.length; i++) {
            totalWithdrawAmount += _withdrawAmount[i];
        }
        require(totalWithdrawAmount == _prizeAmount, "Total withdraw amount must equal prize amount.");

        Tournament storage newTournament = tournamentMapping[_tournamentId];
        newTournament.organizer = msg.sender;
        newTournament.prizeToken = IERC20(_prizeToken);
        newTournament.feeToken = IERC20(_feeToken);
        newTournament.prizeAmount = _prizeAmount;
        newTournament.registrationFee = _registrationFee;
        newTournament.withdrawAmount = _withdrawAmount;
        scoretournament.createTournament(_tournamentId, _registerStartTime, _registerEndTime, _tournamentStartTime, _tournamentEndTime, _withdrawAmount.length, _tournamentURI);
    }

    function register(uint _tournamentId) public {
        Tournament storage _tournament = tournamentMapping[_tournamentId];
        require(_tournament.feeToken.allowance(msg.sender, address(this)) >= _tournament.registrationFee, "Allowance is not sufficient.");
        require(_tournament.registrationFee <= _tournament.feeToken.balanceOf(msg.sender), "Insufficient balance.");
        require(_tournament.feeToken.transferFrom(msg.sender, address(this), _tournament.registrationFee), "Transfer failed.");
        _tournament.feeBalance = _tournament.feeBalance + _tournament.registrationFee;
        scoretournament.register(_tournamentId, msg.sender);
    }

    function updateWithdrawals(uint _tournamentId, address[] memory _withdrawAddresses) public onlyTournament {
        Tournament storage _tournament = tournamentMapping[_tournamentId];
        uint256[] memory _withdrawAmount = _tournament.withdrawAmount;
        require(_withdrawAddresses.length == _withdrawAmount.length, "Arrays must be the same length.");

        for (uint256 i = 0; i < _withdrawAddresses.length; i++) {
            _tournament.AddrwithdrawAmount[_withdrawAddresses[i]] = _withdrawAmount[i];
        }
    }

    function feeWithdraw(uint _tournamentId) public onlyTournament{
        Tournament storage _tournament = tournamentMapping[_tournamentId];

        IERC20 token = _tournament.feeToken;
        uint256 withdrawAmount = _tournament.feeBalance;
        require(token.transfer(_tournament.organizer, withdrawAmount), "Transfer failed.");
        emit UnlockFee(_tournamentId, withdrawAmount);
    }

    function prizeWithdraw(uint _tournamentId) public {
        Tournament storage _tournament = tournamentMapping[_tournamentId];
        require(_tournament.AddrwithdrawAmount[msg.sender] > 0, "There is no prize token to be paid to you.");

        IERC20 token = _tournament.prizeToken;
        uint256 withdrawAmount = _tournament.AddrwithdrawAmount[msg.sender];
        require(token.transfer(msg.sender, withdrawAmount), "Transfer failed.");
        emit PrizePaid(_tournamentId, msg.sender, withdrawAmount);
    }

    function emergencyWithdraw(uint _tournamentId) public onlyAdmin{
        Tournament storage _tournament = tournamentMapping[_tournamentId];

        IERC20 feeToken = _tournament.feeToken;
        uint256 withdrawAmountFee = _tournament.feeBalance;
        require(feeToken.transfer(admin, withdrawAmountFee), "Transfer failed.");
        _tournament.feeBalance = 0;

        IERC20 prizeToken = _tournament.prizeToken;
        uint256 withdrawAmountPrize = _tournament.prizeAmount;
        require(prizeToken.transfer(admin, withdrawAmountPrize), "Transfer failed.");
        _tournament.prizeAmount = 0;
    }

    function prizeAvailable(uint _tournamentId, address player) external view returns(uint _amount) {
        Tournament storage _tournament = tournamentMapping[_tournamentId];
        return _tournament.AddrwithdrawAmount[player];
    }

}

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;    

import "./Miracle-Escrow-G1.sol";

//    _______ _______ ___ ___ _______ ______  ___     ___ ______  _______     ___     _______ _______  _______ 
//   |   _   |   _   |   Y   |   _   |   _  \|   |   |   |   _  \|   _   |   |   |   |   _   |   _   \|   _   |
//   |   1___|.  1___|.  |   |.  1___|.  |   |.  |   |.  |.  |   |.  1___|   |.  |   |.  1   |.  1   /|   1___|
//   |____   |.  __)_|.  |   |.  __)_|.  |   |.  |___|.  |.  |   |.  __)_    |.  |___|.  _   |.  _   \|____   |
//   |:  1   |:  1   |:  1   |:  1   |:  |   |:  1   |:  |:  |   |:  1   |   |:  1   |:  |   |:  1    |:  1   |
//   |::.. . |::.. . |\:.. ./|::.. . |::.|   |::.. . |::.|::.|   |::.. . |   |::.. . |::.|:. |::.. .  |::.. . |
//   `-------`-------' `---' `-------`--- ---`-------`---`--- ---`-------'   `-------`--- ---`-------'`-------'
//   

contract ScoreTournament {

    address public EscrowAddr;

    struct Player {
        uint id;
        address account;
        uint score;
        bool isRegistered;
        uint rank;
    }

    struct Tournament {
        Player[] players;
        mapping(address => uint) playerIdByAccount;
        mapping(uint => address) rankToAccount;
        mapping(address => uint) accountToRank;
        address organizer;
        uint registerStartTime;
        uint registerEndTime;
        uint tournamentStartTime;
        uint tournamentEndTime;
        uint prizeCount;
        bool tournamentEnded;
        string tournamentURI;
    }

    address admin;
    mapping(uint => Tournament) public tournamentMapping;

    event CreateTournament(uint tournamentId);
    event Registered(uint tournamentId, address account);
    event ScoreUpdated(uint tournamentId, address account, uint score);
    event TournamentEnded(uint tournamentId);

    constructor(address adminAddress) {
        admin = adminAddress;
    }

    modifier onlyAdmin(){
        require(msg.sender == admin, "Only admin can call this function");
        _;
    }

    modifier onlyEscrow(){
        require(msg.sender == EscrowAddr,  "Only escorw contract can call this function");
        _;
    }

    modifier registrationOpen(uint tournamentId) {
        Tournament storage tournament = tournamentMapping[tournamentId];
        require(block.timestamp >= tournament.registerStartTime, "Registration has not started yet");
        require(block.timestamp <= tournament.registerEndTime, "Registration deadline passed");
        _;
    }

    modifier onlyOrganizer(uint tournamentId) {
        Tournament storage tournament = tournamentMapping[tournamentId];
        require(msg.sender == tournament.organizer, "Only organizer can call this function");
        _;
    }

    modifier tournamentNotStarted(uint tournamentId) {
        Tournament storage tournament = tournamentMapping[tournamentId];
        require(block.timestamp < tournament.tournamentEndTime, "This is not the time to proceed with the tournement.");
        require(block.timestamp > tournament.tournamentStartTime, "Tournament is not start");
        _;
    }

    modifier tournamentEndedOrNotStarted(uint tournamentId) {
        Tournament storage tournament = tournamentMapping[tournamentId];
        require(tournament.tournamentEnded || block.timestamp < tournament.tournamentEndTime, "Tournament has ended");
        _;
    }

    function connectEscrow(address _escrowAddr) public onlyAdmin {
        EscrowAddr = _escrowAddr;
    }

    function createTournament(uint _tournamentId, uint _registerStartTime, uint _registerEndTime, uint _tournamentStartTime, uint _tournamentEndTime, uint _prizeCount, string memory _tournamentURI) public onlyEscrow {
        Tournament storage newTournament = tournamentMapping[_tournamentId];
        newTournament.organizer = payable(msg.sender);
        newTournament.registerStartTime = _registerStartTime;
        newTournament.registerEndTime = _registerEndTime;
        newTournament.tournamentStartTime = _tournamentStartTime;
        newTournament.tournamentEndTime = _tournamentEndTime;
        newTournament.tournamentEnded = false;
        newTournament.prizeCount = _prizeCount;
        newTournament.tournamentURI = _tournamentURI;

        emit CreateTournament(_tournamentId);
    }

    function register(uint tournamentId, address _player) public payable registrationOpen(tournamentId) {
        Tournament storage tournament = tournamentMapping[tournamentId];
        require(block.timestamp >= tournament.registerStartTime, "Registration has not started yet");
        require(block.timestamp <= tournament.registerEndTime, "Registration deadline passed");
        uint playerId = tournament.players.length + 1;

        Player memory player = Player({
            id: playerId,
            account: payable(_player),
            score: 0,
            isRegistered: true,
            rank: 0
        });

        tournament.players.push(player);
        tournament.playerIdByAccount[_player] = playerId;

        emit Registered(tournamentId, _player);
    }


    function updateScore(uint tournamentId, address _account, uint _score) public onlyAdmin tournamentNotStarted(tournamentId) tournamentEndedOrNotStarted(tournamentId) {
        Tournament storage tournament = tournamentMapping[tournamentId];
        require(tournament.playerIdByAccount[_account] > 0, "Player not registered");
        Player storage _player = tournament.players[tournament.playerIdByAccount[_account]];

        _player.score += _score;
        emit ScoreUpdated(tournamentId, _account, _player.score);
    }

    function calculateRanking(uint tournamentId) public onlyAdmin {
        Tournament storage tournament = tournamentMapping[tournamentId];
        uint len = tournament.players.length;

        for (uint i = 0; i < len; i++) {
            tournament.rankToAccount[i] = tournament.players[i].account;
        }

        uint[] memory scores = new uint[](len);
        for (uint i = 0; i < len; i++) {
            scores[i] = tournament.players[i].score;
        }

        // sort scores and rearrange the rank mapping
        for (uint i = 0; i < len - 1; i++) {
            for (uint j = i + 1; j < len; j++) {
                if (scores[i] < scores[j]) {
                    uint tempScore = scores[i];
                    scores[i] = scores[j];
                    scores[j] = tempScore;

                    address tempAddr = tournament.rankToAccount[i];
                    tournament.rankToAccount[i] = tournament.rankToAccount[j];
                    tournament.rankToAccount[j] = tempAddr;
                }
            }
        }

        for (uint i = 0; i < len; i++) {
            tournament.accountToRank[tournament.rankToAccount[i]] = i + 1;
        }

        // store the rank and score in the Player struct
        for (uint i = 0; i < len; i++) {
            tournament.players[i].score = scores[i];
            tournament.players[i].isRegistered = false;
            uint rank = tournament.accountToRank[tournament.players[i].account];
            tournament.players[i] = Player(tournament.players[i].id, tournament.players[i].account, tournament.players[i].score, tournament.players[i].isRegistered, rank);
        }
    }

    function endTournament(uint tournamentId) public onlyAdmin {
        calculateRanking(tournamentId);
        Tournament storage tournament = tournamentMapping[tournamentId];
        uint _prizeCount = tournament.prizeCount;
        address[] memory prizeAddr = new address[](_prizeCount);
        for(uint i = 0; i < _prizeCount; i++){
            prizeAddr[i] = tournament.rankToAccount[i];
        }
        TournamentEscrow(EscrowAddr).updateWithdrawals(tournamentId, prizeAddr);
        TournamentEscrow(EscrowAddr).feeWithdraw(tournamentId);
        tournament.tournamentEnded = true;
        emit TournamentEnded(tournamentId);
    }

    function getPlayerCount(uint _tournamentId) external view returns(uint _playerCnt){
        Tournament storage _tournament = tournamentMapping[_tournamentId];
        return _tournament.players.length;
    }

    function getPlayerInfo(uint _tournamentId, uint playerId) external view returns(Player memory _player){
        Tournament storage _tournament = tournamentMapping[_tournamentId];
        return _tournament.players[playerId];
    }

    function getPlayerRank(uint _tournamentId, address player) external view returns(uint _rank){
        Tournament storage _tournament = tournamentMapping[_tournamentId];
        return _tournament.accountToRank[player];
    }

    function playerIdByAccount(uint _tournamentId, address player) external view returns(uint _id){
        Tournament storage _tournament = tournamentMapping[_tournamentId];
        return _tournament.playerIdByAccount[player];
    }
}