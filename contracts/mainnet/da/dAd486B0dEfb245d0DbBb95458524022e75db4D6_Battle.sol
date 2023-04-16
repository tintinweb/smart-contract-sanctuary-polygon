/**
 *Submitted for verification at polygonscan.com on 2023-04-16
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
/*\
Created by SolidityX for Decision Game
Telegram: @solidityX
\*/


library SafeMath {

    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {

            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface automation {
    function addFunds(uint256 id, uint96 amount) external;
}

interface IUniswapV2Router {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IERC20 {
 
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC1155 {
    function balanceOf(address account, uint id) external returns(uint);   
}

interface IERC721 {
    function balanceOf(address account) external view returns (uint256);
}

interface IVault {
    function deposit(address _token, uint _amount) external returns(bool);
}

interface ILinkSwap {
function swap(uint256 amount, address source, address target) external;
}


library EnumerableSet {

    struct Set {
        bytes32[] _values;
        mapping(bytes32 => uint256) _indexes;
    }

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    struct Bytes32Set {
        Set _inner;
    }

    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }


    struct AddressSet {
        Set _inner;
    }

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;
        assembly {
            result := store
        }

        return result;
    }
}

contract Battle {

    using SafeMath for uint;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*\
    saves all values of each gamme
    \*/
    struct game {
        address operator;
        address player1;
        address player2;
        uint256 stakes;
        address winner;
        uint startedAt;
    }

    /*\
    saves stats of each wallet
    \*/
    struct player {
        uint[] gamesPlayed;
        uint[] gamesWon;
        uint[] gamesLost;
    }


    address private owner; // owner of contract
    address private dev; // address of dev 
    address private team; // address of team
    address private LPstaking; // address of LP staking contract
    address private weth; // weth address
    address constant private dead = 0x000000000000000000000000000000000000dEaD; // dead address

    EnumerableSet.AddressSet private operators; // list of all operators
    IERC20 private mainToken; // main tkens address
    IERC721 private erc721; // nft tokens contract
    IERC1155 private erc1155; // address of erc155 tken
    IUniswapV2Router private router; // router address of dex
    automation private registry; // registry of chainlink automation
    ILinkSwap constant private linkSwap = ILinkSwap(0xAA1DC356dc4B18f30C347798FD5379F3D77ABC5b); // to conver link1 to link2
    IERC20 constant private link = IERC20(0x53E0bca35eC356BD5ddDFebbD1Fc0fD03FaBad39); // chainlink's link token
    IERC20 constant private link2 = IERC20(0xb0897686c545045aFc77CF20eC7A532E3120E0F1); //chainlink's link token for automation deposit
    
    mapping(address => uint) inGame; // mapping to check which gamme the player is currently on
    mapping(uint => game) public Gamelist; // mapping form gammeId to gamme
    mapping(address => player) stats; // mapping  from player to playerStats
    
    uint private id; // id of chainlink automation
    uint private currentGame = 1; // current  game  id
    uint private feePP = 1e16; // matic fee per player
    uint private fee; // current fee
    uint private mFee; // current matic fee
    uint private minFeeForExecution = 100e18; // minimum fee to execute proccessing
    uint constant public burnFee = 6; // token burn fee given in percent
    uint constant public teamFee = 1; // treasury fee given in percent
    uint constant public LPStakingFee = 3; // lp staking reward fee given in percent
    uint constant public tFee = 10; // total fee given in percent

    constructor(address _token, address _operator, address _staking, address _team, address _erc1155, address _erc721, address _router, address _registry, address _weth, uint _id){
        owner = msg.sender;
        dev = msg.sender;
        operators.add(_operator);
        LPstaking = _staking;
        team = _team;
        weth = _weth;
        router = IUniswapV2Router(_router);
        registry = automation(_registry);
        erc1155 = IERC1155(_erc1155);
        erc721 = IERC721(_erc721);
        mainToken = IERC20(_token);
        id = _id;
        mainToken.approve(team, 2**256 - 1);
        link2.approve(address(registry), 2**256-1); 
        link.approve(address(linkSwap), 2**256-1);
    }

    /*\
    functions with this modifier can only be called by the owner or dev
    \*/
    modifier onlyOwner() {
        require(owner == msg.sender, "!owner");
        _;
    }

    /*\
    functions with this modifier can only be called by the dev or owner
    \*/
    modifier onlyDev() {
        require(msg.sender == dev || msg.sender == owner, "!dev");
        _;
    }

    /*\
    functions with this modifier can only be called by the operators
    \*/
    modifier onlyOperator() {
        require(operators.contains(msg.sender), "!operator");
        _;
    }

    event newGame(uint indexed id, address indexed creator, uint indexed bet); // event for newGame
    event joinedGame(uint indexed id, address indexed player, uint indexed bet); // event for joining game
    event endedGame(uint indexed id, address indexed winner, uint indexed bet); // event for ending games
    event gameCanceled(uint indexed id, address indexed creator); // event for canceled games


/*//////////////////////////////////////////////‾‾‾‾‾‾‾‾‾‾\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*\
///////////////////////////////////////////////executeables\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\*\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\____________/////////////////////////////////////////////*/


    /*\
    create a new game
    \*/
    function createGame(uint256 _bet) public payable returns(uint256 _id, uint256 bet, bool started) {
        require(inGame[msg.sender] == 0, "already joineed a game atm!");
        require(msg.value >= feePP, "please provide the required fee!"); 
        require(_bet >= 10e18, "Bet must be higher than 10!");
        require(_bet <= 10000e18, "bet too big!");
        require(mainToken.transferFrom(msg.sender, address(this), _bet), "bet transfer  failed!");
        
        if(_bet >= 100e18 && _bet < 1000e18) {
            require(erc1155.balanceOf(msg.sender, 1) > 0 ||
                    erc1155.balanceOf(msg.sender, 2) > 0 ||
                    erc1155.balanceOf(msg.sender, 3) > 0 ||
                    erc1155.balanceOf(msg.sender, 4) > 0 ||
                    erc1155.balanceOf(msg.sender, 5) > 0, "Please purchse coin! (erc1155)");
        }
        if(_bet >= 1000e18)
            require(erc721.balanceOf(msg.sender) > 0, "please purchase a nft. (erc721)");
        
        inGame[msg.sender] = currentGame;
        game memory Game = game(address(0x0), msg.sender, address(0x0), _bet, address(0x0), block.timestamp);
        stats[msg.sender].gamesPlayed.push(currentGame);
        Gamelist[currentGame] = Game;
        currentGame++;
        
        emit newGame(currentGame-1, msg.sender, _bet);
        
        return (currentGame, _bet, false);
    }


    /*\
    join a game
    \*/
    function joinGame(uint _id) public payable returns(bool){
        require(msg.value >= feePP, "please provide a fee of at least 0.01 MATIC!"); 
        require(inGame[msg.sender] == 0, "already joineed a game atm!");
        require(mainToken.transferFrom(msg.sender, address(this), Gamelist[_id].stakes), "payment failed!");
        require(Gamelist[_id].winner == address(0x0), "game was shut down!");
        require(Gamelist[_id].player1 != address(0x0), "invalid id!");
        require(Gamelist[_id].player2 == address(0x0), "game full!");
        
        inGame[msg.sender] = _id;
        Gamelist[_id].player2 = msg.sender;
        stats[msg.sender].gamesPlayed.push(_id);
        
        emit joinedGame(_id, msg.sender, Gamelist[_id].stakes);
        
        return true;
    }

    /*\
    cancels game if no other player joins
    \*/
    function cancel(uint _id) public returns(bool){
        require(Gamelist[_id].player2 == address(0x0), "opponent already joined!");
        require(Gamelist[_id].player1 == msg.sender || operators.contains(msg.sender), "not game creator or operator!");
        require(mainToken.transfer(Gamelist[_id].player1, Gamelist[_id].stakes), "refund transfer failed!");
        
        inGame[Gamelist[_id].player1] = 0;
        Gamelist[_id].player2 = Gamelist[_id].player1;
        Gamelist[_id].winner = Gamelist[_id].player1;
        
        payable(Gamelist[_id].player1).transfer(feePP);
        
        emit gameCanceled(_id, Gamelist[_id].player1);
        
        return true;
    }

    /*\
    operator ends game and sets winner
    \*/
    function endGame(uint256 _id, address winner) public onlyOperator returns(bool){
        require(Gamelist[_id].winner == address(0x0), "winner already set!");
        require(Gamelist[_id].player2 != address(0x0),  "game not full!");
        require(winner == address(0x0) || winner == Gamelist[_id].player1 || winner == Gamelist[_id].player2, "winner not player or draw");
        
        inGame[Gamelist[_id].player1] = 0;
        inGame[Gamelist[_id].player2] = 0;
        
        Gamelist[_id].winner = winner;
        Gamelist[_id].operator = msg.sender;
        
        payable(Gamelist[_id].operator).transfer(feePP);
        
        _distributeFee();

        emit endedGame(_id, winner, Gamelist[_id].stakes);

        if(winner == address(0x0)) {
            Gamelist[_id].winner = Gamelist[_id].operator;
            require(mainToken.transfer(Gamelist[_id].player1, Gamelist[_id].stakes), "transfer failed, 1!");
            require(mainToken.transfer(Gamelist[_id].player2, Gamelist[_id].stakes), "transfer failed, 2!");
            return true;
        }
        
        mFee = mFee.add(feePP);
        uint _fee = (Gamelist[_id].stakes.mul(2)).mul(tFee).div(100);
        fee = fee.add(_fee);
        uint win = (Gamelist[_id].stakes.mul(2)).sub(_fee);
        require(mainToken.transfer(winner, win), "transfer failed, winner!");

        address loser = winner == Gamelist[_id].player1 ? Gamelist[_id].player2 : Gamelist[_id].player1;
        stats[winner].gamesWon.push(_id);
        stats[loser].gamesLost.push(_id);

        return true;
    }

    /*\
    distributes the fee in it exceeds the minFeeForExecution
    \*/
    function _distributeFee() private {
        if(fee >= minFeeForExecution) {
            uint _burnFee = fee.mul(burnFee).div(tFee);
            uint _teamFee = fee.mul(teamFee).div(tFee);
            uint _LPStakingFee = fee.mul(LPStakingFee).div(tFee);
            mainToken.transfer(dead, _burnFee);
            require(IVault(team).deposit(address(mainToken), _teamFee), "transfer failed, team vault!");
            require(mainToken.transfer(LPstaking, _LPStakingFee));
            require(_fundAutoamtion(), "automation funding failed!");
            fee = 0;
            mFee = 0;
        }
    }


    /*\
    funds chainlink automation with link
    \*/
    function _fundAutoamtion() private returns(bool) {
        address[] memory path = new address[](2);
        path[0] = weth;
        path[1] = address(link);
        
        router.swapExactETHForTokens {value: mFee}(
            0,
            path,
            address(this),
            block.timestamp
        );
        
        linkSwap.swap(link.balanceOf(address(this)), address(link), address(link2));
        registry.addFunds(id, uint96(link2.balanceOf(address(this))));
        
        return true;
    }

    /*\
    allows contract to receive ETH
    \*/
    receive() external payable {}


    /*\
    sets id of chainlink automation
    \*/
    function setId(uint _id) public onlyDev {
        id = _id;
    }

    /*\
    set matic fee per player
    \*/
    function setFeePP(uint _fee) public onlyOwner {
        feePP = _fee;
    }

    /*\
    sets registry of chainlink automation
    \*/
    function setRegistry(address _registry) public onlyDev {
        registry = automation(_registry);
    }

    /*\
    sets router address
    \*/
    function setRouter(address _router) public onlyOwner {
        router = IUniswapV2Router(_router);
    }

    /*\
    set weth token
    \*/
    function setWeth(address _weth) public onlyOwner {
        weth = _weth;
    }

    /*\
    transfers owner
    \*/
    function setOwner(address _add) public onlyOwner{
        owner = _add;
    }

    /*\
    transfers dev
    \*/
    function transferDev(address _add) public onlyDev {
        dev = _add;
    }

    /*\
    sets main token
    \*/
    function setToken(address _add) public onlyOwner{
        mainToken = IERC20(_add);
    }

    /*\
    renounce owner
    \*/
    function renouceOwner() public onlyOwner{
        owner = address(0x0);
    }

    /*\
    set team address
    \*/
    function setTeam(address _add) public onlyOwner {
        team = _add;
    }

    /*\
    set staking contract
    \*/
    function setStaking(address _add) public onlyOwner {
        LPstaking = _add;
    }

    /*\
    sets the minimum amount of tokens where the fee distribution is triggered
    \*/
    function setMinFeeForExecution(uint _min) public onlyDev {
        minFeeForExecution = _min; 
    }


    /*\
    toggles operator
    \*/
    function setOperator(address _add) public onlyOwner{
        if (operators.contains(_add))
            operators.remove(_add);
        else
            operators.add(_add);
    }


/*//////////////////////////////////////////////‾‾‾‾‾‾‾‾‾‾‾\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\*\
///////////////////////////////////////////////viewable/misc\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
\*\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\_____________/////////////////////////////////////////////*/


    /*\
    returns total games won of address
    \*/
    function getTotalWonOf(address _add) public view returns(uint) {
        return stats[_add].gamesWon.length;
    }

    /*\
    returns total lost games of address
    \*/
    function getTotalLostOf(address _add) public view returns(uint) {
        return stats[_add].gamesLost.length;
    }

    /*\
    returns total played games of address
    \*/
    function getTotalPlayedOf(address _add) public view returns(uint) {
        return stats[_add].gamesPlayed.length;
    }

    /*\
    returns total games drawn of address
    \*/
    function getTotalGamesDrawnOf(address _add) public view returns(uint) {
        return getTotalPlayedOf(_add) - (getTotalWonOf(_add) + getTotalLostOf(_add));
    }

    /*\
    returns latest game id
    \*/
    function latestGame() external view returns(uint) {
        return currentGame;
    }

    /*\
    return what address is currently playing on
    \*/
    function playingOn(address _add) external view returns(uint) {
        return inGame[_add];
    }

    /*\
    returns all ids of won games of address
    \*/
    function getAllWonOf(address _add) external view returns(uint[] memory) {
        return stats[_add].gamesWon;
    }

    /*\
    returns all ids of games played of address
    \*/
    function getAllPlayedOf(address _add) external view returns(uint[] memory) {
        return stats[_add].gamesPlayed;
    }

    /*\
    returns all ids of lost games of address
    \*/
    function getAllLostOf(address _add) external view returns(uint[] memory) {
        return stats[_add].gamesLost;
    }

    /*\
    returns W/L rate of player
    \*/
    function getWLOf(address _add) external view returns(uint)  {
        return getTotalWonOf(_add) * 1e18 / getTotalLostOf(_add);
    }  

    /*\
    returns win percentage of player
    \*/
    function getWinPercentageOf(address _add) external view returns(uint) {
        return 100e18 / getTotalPlayedOf(_add) * getTotalWonOf(_add);
    }

    /*\
    returns loose percentage of player
    \*/
    function getLoosePercentageOf(address _add) external view returns(uint) {
        return 100e18 / getTotalPlayedOf(_add) * getTotalLostOf(_add);
    }

    /*\
    returns draw percentage of player
    \*/
    function getDrawPercentageOf(address _add) external view returns(uint) {
        return 100e18 / getTotalPlayedOf(_add) * getTotalGamesDrawnOf(_add);
    }
    
    /*\
    returns information of game id
    \*/
    function getGame(uint _id) external view returns(uint, uint, address, address, address) {
        return (getState(_id), Gamelist[_id].stakes, Gamelist[_id].player1, Gamelist[_id].player2, Gamelist[_id].winner);
    }

    /*\
    returns the owner's address
    \*/
    function getOwner() external view returns(address) {
        return owner;
    }

    /*\
    returns the dev's address
    \*/
    function getDev() external view returns(address) {
        return dev;
    }

    /*\
    returns current state of game id
    \*/
    function getState(uint _id) public view returns(uint) {
        uint state = 0;
        if(Gamelist[_id].winner != address(0x0))
            state = 3;
        else if(Gamelist[_id].player1 != address(0x0) && Gamelist[_id].player2 == address(0x0))
            state = 1;
        else if(Gamelist[_id].player1 != address(0x0) && Gamelist[_id].player2 != address(0x0))
            state = 2;
        return state;
    }

    /*\
    get a list of all operators
    \*/
    function getOperators() external view returns(address[] memory) {
        address[] memory ops = new address[](operators.length());
        for(uint i; i < ops.length; i++) {
            ops[i] = operators.at(i);
        }
        return ops;
    } 

    /*\
    returns all ids of draw games of address 
    \*/
    function getAllDrawnOf(address _add) external view returns(uint[] memory) {
        uint[] memory ids = new uint[](getTotalGamesDrawnOf(_add));
        uint count = 0;
        for(uint i; i < getTotalPlayedOf(_add); i++) {
            if(stats[_add].gamesPlayed[i] != stats[_add].gamesWon[i] && stats[_add].gamesPlayed[i] != stats[_add].gamesLost[i]) {
                ids[count] = i;
                count++;
            }
        }
        return ids;
    }

    /*\
    returns all current active games
    \*/
    function getAllActive(uint _start) external view returns(uint[] memory, uint[] memory, uint[] memory, uint) {
        uint count = 0;
        for(uint i = _start; i < currentGame; i++) {
            if(Gamelist[i].winner == address(0x0))
                count++;
        }
        uint[] memory _id = new uint[](count);
        uint[] memory _times = new uint[](count);
        uint[] memory _state = new uint[](count);
        count = 0;
        for(uint i = _start; i < currentGame; i++) {
            if(Gamelist[i].winner == address(0x0)) {
                _id[count] = i;
                _times[count] = Gamelist[i].startedAt;
                _state[count] = getState(i);
                count++;
            }
        }
        return (_id, _times, _state, block.timestamp);
    }
}