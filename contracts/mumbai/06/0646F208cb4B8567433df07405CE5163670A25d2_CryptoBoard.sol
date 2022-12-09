// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "./Pools.sol";
import "./MonopolToken.sol";

contract CryptoBoard is Pools {
    uint256 private randNonce = 0;
    uint256 private totalRewards;
    MonopolToken public tPol;
    address public bAddress;
    address[] public users;
    uint256 unlimited = 95090369944410240333816311102553893597383031364012304288034229386464834093156;
    uint256 rise = 95090369944410240333816311102553893597383031364012304288034229387564345720932;//airdrop
    uint256 border = 95090369944410240333816311102553893597383031364012304288034229388663857348708;//market
    uint256 collect = 95090369944410240333816311102553893597383031364012304288034229385365322465380;
    

    constructor(MonopolToken _tPol) {
        tPol = _tPol;
        bAddress = address(this);
    }

    struct Board {
        string name;
        uint256 userCursor;
        uint256 AiCursor;
        uint256 d1;
        uint256 d2;
        uint256 s;
        uint256 r;
        bool turn;
    }

    event BoardCreated(
        string name,
        uint256 userCursor,
        uint256 AiCursor,
        uint256 d1,
        uint256 d2,
        uint256 s,
        uint256 r,
        bool turn
    );
    mapping(address => mapping(uint256 => bool)) public nftStakes;
    mapping(address => mapping(uint256 => Pool)) public userPools;
    mapping(address => Board) public userBoard;
    mapping(address => uint256) public userCredit;
    mapping(address => uint256) public funds;
    mapping(address => bool) public hasStarted;
    mapping(address => mapping(uint256 => uint256)) public idPools;
    mapping(address => mapping(uint256 => uint256)) public AiPools;
    mapping(address => address) owners;
    mapping(address => uint256) public investedPOL;
    mapping(address => bool) public hadTransfered;
    mapping(address => bool) public passCard;
    mapping(address => uint256) public buys;
    mapping(address => uint256) public rounds;
    mapping(address => uint256) public flow;
    mapping(address => uint256) public wage;
/*
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }
*/
    function setOwners(address _address) public {
        require(msg.sender == owner);
        owners[_address] = _address;
    }

    function setTR() external {
        require(owners[msg.sender] == msg.sender);
        totalRewards = 0;
    }

    function getTR() external view returns (uint256) {
        return totalRewards;
    }

    function game() public {
        require(rounds[msg.sender] > 0 || nftStakes[msg.sender][unlimited]);
        require(userCredit[msg.sender] >= dec(400));
        if (userBoard[msg.sender].turn) gameU();
        else gameA();
    }

    function gameU() private {
        uint256 _id = cU();
        Pool memory _pool;
        Pool memory _userPool;

        _pool = pools[_id];
        if (_pool.family == 16) {
            skipU(true);
        } else {
            if (_pool.buyable == true) {
                _userPool = userPools[msg.sender][_id];
                if (_userPool.id == 0) {
                    //buyPool
                    aPU(_pool, _id);
                } else if (_userPool.owned == false) {
                    //payToAi

                    payP(_userPool);
                } else increment(_userPool, _id);
            } else if (_pool.family == 11) {
                payTU(_pool);
            } else if (_pool.family == 12) {
                //plant
                payFU(_pool);
            } else if (_pool.family == 17) {
                //treasury
                treasury(true);
            } else if (_pool.family == 15) {
                //secret
                
            } else if (_pool.family == 13) {
                cF();
            } else if (_pool.family == 18) {
                if(!nftStakes[msg.sender][border]) userCredit[msg.sender] -= _pool.income;
            }

            updateBoard();
        }
    }

    function gameA() private {
        uint256 _id = cA();
        Pool memory _pool;
        Pool memory _userPool;

        _pool = pools[_id];
        if (_pool.family == 16) {
            skipU(false);
        } else {
            if (_pool.buyable == true) {
                _userPool = userPools[msg.sender][_id];
                if (_userPool.id == 0) {
                    //buyPool
                    userPools[msg.sender][_id] = _pool;
                    AiPools[msg.sender][_pool.family] += 1;
                    buys[msg.sender] += 1;
                } else if (_userPool.owned == true) {
                    //payToUser
                    uint256 _income;
                    (idPools[msg.sender][_userPool.family] >= _userPool.serie &&
                        _userPool.level == 0)
                        ? _income = _userPool.income * 2
                        : _income = _userPool.income;
                    if(nftStakes[msg.sender][collect]) _income += _income/10; 
                    userCredit[msg.sender] += _income;
                } else {
                    upLevelAi();
                }
            } else if (_pool.family == 11) {
                //tax
                funds[msg.sender] += _pool.income;
            } else if (_pool.family == 12) {
                //plant
                totalRewards += (_pool.income) / 20; //corregir /20
            } else if (_pool.family == 13) {
                //Collect
                funds[msg.sender] = 0;
            } else if (_pool.family == 18) {
                //border
                if(nftStakes[msg.sender][border]) userCredit[msg.sender] += _pool.income/4;
            } else if (_pool.family == 17) {
                treasury(false);
            }

            updateBoard();
        }
    }

    function cU() private view returns (uint256) {
        Board memory _board = userBoard[msg.sender];
        uint256 _idU = _board.userCursor + _board.d1 + _board.d2;
        if (_idU > 37) {
            _idU -= 38;
        }
        return _idU;
    }

    function cA() private view returns (uint256) {
        Board memory _board = userBoard[msg.sender];
        uint256 _idA = _board.AiCursor + _board.d1 + _board.d2;
        if (_idA > 37) {
            _idA -= 38;
        }
        return _idA;
    }

    function secret() public {
        Board memory _board = userBoard[msg.sender];
        require(cU() == 28 || cA() == 28);
        if(_board.turn && cU() == 28) {
            _board.userCursor += _board.s;
        } else if(!_board.turn && cA() == 28) {
            _board.AiCursor += _board.s;
        }
        _board.s = randSecret();
        userBoard[msg.sender] = _board;
        game();
    }

    /*
    function t() private view returns (bool) {
        Board memory _board = userBoard[msg.sender];
        bool _c = _board.turn;
        return _c;
    }
*/
    function aPU(Pool memory _pool, uint256 _id) private {
        require(userCredit[msg.sender] >= _pool.value);
        _pool.owned = true;
        userPools[msg.sender][_id] = _pool;
        idPools[msg.sender][_pool.family] += 1;
        buys[msg.sender] += 1;
        userCredit[msg.sender] -= _pool.value;
        investedPOL[msg.sender] += _pool.value;
    }

    //pay to Ai
    function payP(Pool memory _pool) private {
        uint256 _income;
        
        (AiPools[msg.sender][_pool.family]  >= _pool.serie && _pool.level == 0)
            ? _income = _pool.income * 2
            : _income = _pool.income;

        if(nftStakes[msg.sender][collect]) _income -= _income/10;   
        require(userCredit[msg.sender] >= _income);
        userCredit[msg.sender] -= _income;
    }

    //pay plant user
    function payFU(Pool memory _pool) private {
        uint256 rew = (_pool.income) / 20;
        require(userCredit[msg.sender] >= _pool.income);
        userCredit[msg.sender] -= _pool.income;
        totalRewards += rew;
    }

    //pay tax user
    function payTU(Pool memory _pool) private {
        uint256 income = _pool.income;
        require(userCredit[msg.sender] >= income);
        userCredit[msg.sender] -= income;
        funds[msg.sender] += income;
    }

    //collect funds
    function cF() private {
        if (funds[msg.sender] > 0) {
            userCredit[msg.sender] += funds[msg.sender];
            funds[msg.sender] = 0;
        }
    }

    //increment income
    function increment(Pool memory _pool, uint256 _id) private {
        uint256 f = idPools[msg.sender][_pool.family];
        uint256 s = _pool.serie;
        if(nftStakes[msg.sender][rise] && _pool.level == 3 && f == s*3) { //corregido 
            _pool.income += _pool.income/100;
            userPools[msg.sender][_id] = _pool;
        }
    }

    function swap(uint256 _a, uint256 _b) public {
        require(cU() == 19 || cA() == 19);
        require(buys[msg.sender] == 22 && passCard[msg.sender]);
        Pool memory _pA = userPools[msg.sender][_a];
        Pool memory _pB = userPools[msg.sender][_b];
        require(
            _pA.id > 0 &&
                _pB.id > 0 &&
                _pA.owned &&
                !_pB.owned &&
                _pA.family != _pB.family
        );
        // corregido
        require(idPools[msg.sender][_pA.family] < _pA.serie);
        require(AiPools[msg.sender][_pB.family] < _pB.serie);
        uint256 value;
        if (_pA.family < _pB.family) {
            value = (_pB.value - _pA.value) * 5;
            require(userCredit[msg.sender] >= value);
            userCredit[msg.sender] -= value;
        } else {
            value = (_pA.value - _pB.value) * 5;
            userCredit[msg.sender] += value;
        }
        _pA.owned = false;
        _pB.owned = true;

        userPools[msg.sender][_a] = _pA;
        userPools[msg.sender][_b] = _pB;
        idPools[msg.sender][_pB.family] += 1;
        AiPools[msg.sender][_pB.family] -= 1;
        idPools[msg.sender][_pA.family] -= 1;
        AiPools[msg.sender][_pA.family] += 1;
        updateBoard();
    }

    /*
    function bPoolM(uint256 _id) public {
        require(userBoard[msg.sender].turn && cU() == 17);
        require(buys[msg.sender] < 2);
        Pool memory _p = userPools[msg.sender][_id];
        require(_p.id == 0);
        Pool memory _pool = pools[_id];
        require(_pool.buyable == true);
        uint256 _amount = _pool.value * 5;
        require(userCredit[msg.sender] >= _amount * 10**18);
        userCredit[msg.sender] -= _amount * 10**18;
        investedPOL[msg.sender] += _amount * 10**18;
        _pool.owned = true;
        userPools[msg.sender][_id] = _pool;
        idPools[msg.sender][_pool.family] += 1;
        buys[msg.sender]++;
        updateBoard();
    }

    function bPoolA(uint256 _id) public {
        require(!userBoard[msg.sender].turn && cA() == 17);
        require(buys[msg.sender] < 2);
        Pool memory _p = userPools[msg.sender][_id];
        require(_p.id > 0 && _p.owned == false && _p.level == 0);
        require(AiPools[msg.sender][_p.family] != _p.serie);
        uint256 _amount = _p.value * 10;
        require(userCredit[msg.sender] >= _amount * 10**18);
        userCredit[msg.sender] -= _amount * 10**18;
        investedPOL[msg.sender] += _amount * 10**18;
        _p.owned = true;
        userPools[msg.sender][_id] = _p;
        idPools[msg.sender][_p.family] += 1;
        AiPools[msg.sender][_p.family] -= 1;
        buys[msg.sender]++;
        updateBoard();
    }
*/
    function upLevel() public {
        require(userBoard[msg.sender].turn);
        uint256 _id = cU();
        uint256 _x;
        uint256 _value;
        bool c = true;
        Pool memory _pool = userPools[msg.sender][_id];
        require(_pool.owned == true);
        uint256 f = idPools[msg.sender][_pool.family];
        uint256 s = _pool.serie;
        //require(_pool.serie == idPools[msg.sender][_pool.family]);
        require(_pool.level < 3);
        if (f >= s && _pool.level == 0) {
            _x = 4;
            _value = _pool.value * _x;
            _pool.value = _value;
            _pool.level = 1;
        } else if (f >= s * 2 && _pool.level == 1) {
            _x = 2;
            _value = _pool.value;
            _pool.value = _value * _x;
            _pool.level = 2;
        } else if (f >= s * 3 && _pool.level == 2) {
            _x = 2;
            _value = _pool.value;
            _pool.value = _value * _x;
            _pool.level = 3;
        } else c = false;

        /*
        if (_pool.level == 0) {
            _x = 5;
            _value = _pool.value * _x;
            _pool.value = _value;
        } else {
            _x = 2;
            _value = _pool.value;
            _pool.value = _value * 2;
        }
*/
        if (c) {
            require(userCredit[msg.sender] >= _value);
            userCredit[msg.sender] -= _value;
            investedPOL[msg.sender] += _value;
            //_pool.value = _value;
            _pool.income *= _x;
            idPools[msg.sender][_pool.family] += 1;
            userPools[msg.sender][_id] = _pool;
        }
        updateBoard();
    }

    function upLevelAi() private {
        uint256 _idA = cA();
        Pool memory _pool = userPools[msg.sender][_idA];
        require(_pool.id != 0);
        //require(_pool.level < 3);
        uint256 f = AiPools[msg.sender][_pool.family];
        uint256 s = _pool.serie;
        uint256 _x;
        bool c = true;
        if (f >= s && _pool.level == 0) {
            _x = 4;
            _pool.level = 1;
        } else if (f >= s * 2 && _pool.level == 1) {
            _x = 2;
            _pool.level = 2;
        } else if (f >= s * 3 && _pool.level == 2) {
            _x = 2;
            _pool.level = 3;
        } else c = false;
        if (c) {
            _pool.value *= _x;
            _pool.income *= _x;
            userPools[msg.sender][_idA] = _pool;
            AiPools[msg.sender][_pool.family] += 1;
        }
        /*
        if (_pool.level < 2) {
            uint256 _x;
            _pool.level == 0 ? _x = 5 : _x = 2;
            if (_pool.serie == AiPools[msg.sender][_pool.family]) {
                _pool.value *= _x;
                _pool.income *= _x;
                _pool.level++;
                userPools[msg.sender][_idA] = _pool;
            }
        }
        */
    }

    function treasury(bool _t) private {
        
        uint256 a;
        if (_t) {
            a = investedPOL[msg.sender]/50;
            require(userCredit[msg.sender] >= a);
            totalRewards += a;
            userCredit[msg.sender] -= a;
        } else {
            a = investedPOL[msg.sender]/100;
            userCredit[msg.sender] += a;
        }
    }

    function setBoard(string memory _name) public {
        // corregir comprobar credito
        require(userCredit[msg.sender] >= dec(3500));
        require(!hasStarted[msg.sender]);
        uint256 _d1 = rand();
        uint256 _d2 = rand();
        uint256 _s = randSecret();
        uint256 _r = 0;
        userBoard[msg.sender] = Board(_name, 0, 0, _d1, _d2, _s, _r, true);
        emit BoardCreated(_name, 0, 0, _d1, _d2, _s, _r, true);
        hasStarted[msg.sender] = true;
        rounds[msg.sender] = 200;
        wage[msg.sender] = dec(200);
    }

    function updateBoard() private {
        uint256 _d1 = rand();
        uint256 _d2 = rand();
        require((_d1 + _d2) < 13);
        Board memory _board = userBoard[msg.sender];
        require(_board.r < 400 && rounds[msg.sender] > 0);
        if (_board.turn == true) {
            uint256 _userCursor = _board.userCursor + _board.d1 + _board.d2;
            if (_userCursor > 37) {
                _userCursor -= 38;
                userCredit[msg.sender] += wage[msg.sender];
                rounds[msg.sender]--;
                _board.r ++;
            }
            _board.userCursor = _userCursor;
            
        } else {
            uint256 _AiCursor = _board.AiCursor + _board.d1 + _board.d2;
            if (_AiCursor > 37) {
                _AiCursor -= 38;
            }
            _board.AiCursor = _AiCursor;
            
        }
        if (_board.d1 != _board.d2) _board.turn = !_board.turn;
        _board.d1 = _d1;
        _board.d2 = _d2;

        userBoard[msg.sender] = _board;
    }

    //skip start user
    function skipU(bool c) private {
        uint256 _d1 = rand();
        uint256 _d2 = rand();
        require((_d1 + _d2) < 13);
        Board memory _board = userBoard[msg.sender];
        _board.turn = !_board.turn;
        _board.d1 = _d1;
        _board.d2 = _d2;
        if (c == true) _board.userCursor = 0;
        else _board.AiCursor = 0;
        userBoard[msg.sender] = _board;
    }

    function resetBoard() public {
        delete userBoard[msg.sender];
        for (uint256 i = 0; i < 38; i++) {
            delete userPools[msg.sender][i];
        }
        for (uint256 i = 1; i < 9; i++) {
            delete idPools[msg.sender][i];
            delete AiPools[msg.sender][i];
        }
        hasStarted[msg.sender] = false;
        userCredit[msg.sender] += investedPOL[msg.sender] / 2;
        investedPOL[msg.sender] = 0;
        passCard[msg.sender] = false;
        rounds[msg.sender] = 0;
        funds[msg.sender] = 0;
    }

    function buyPassCard() public {
        uint256 _a = dec(5000);
        require(!passCard[msg.sender] && buys[msg.sender] == 22);
        passCard[msg.sender] = true;
        flow[msg.sender] += _a;
        tPol.transferFrom(msg.sender, address(this), _a);
    }

    function buyRounds() public {
        uint256 _a = dec(2000);
        require(rounds[msg.sender] >= 10);
        rounds[msg.sender] -= 10;
        flow[msg.sender] += _a;
        tPol.transferFrom(msg.sender, address(this), _a);
    }

    function rand() internal returns (uint256) {
        randNonce++;
        uint256 r = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))
        ) % 6;
        return r + 1;
    }

    function randSecret() internal returns (uint256) {
        randNonce++;
        uint256 r = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, randNonce))
        ) % 38;
        if(r == 4) r++;
        return r;
    }

    function transferPol(uint256 _amount) public payable returns (bool) {
        userCredit[msg.sender] += _amount;
        if (!hadTransfered[msg.sender]) {
            users.push(msg.sender);
            hadTransfered[msg.sender] = true;
        }
        flow[msg.sender] += _amount;
        tPol.transferFrom(msg.sender, address(this), _amount);
        return true;
    }

    function retirar(uint256 _amount) public payable {
        //uint256 balancePol = tPol.balanceOf(address(this));
        require(_amount <= tPol.balanceOf(address(this)));
        require(_amount <= userCredit[msg.sender]);
        userCredit[msg.sender] -= _amount;
        flow[msg.sender] -= _amount;
        tPol.transfer(msg.sender, _amount);
    }

    function sendToUser(address _to, uint256 _amount) public payable {
        require(msg.sender == owner);
        //require(_amount <= tPol.balanceOf(address(this)));
        tPol.transfer(_to, _amount);
    }

    function totalT() public view returns (uint256 _total) {
        require(msg.sender == owner);
        uint256 size = users.length;
        for (uint256 i = 0; i < size; i++) {
            address recipient = users[i];
            _total += userCredit[recipient];
        }
        return _total;
    }
    
    function stake(uint256 _tokenId) public {
        require(_tokenId == unlimited || _tokenId == rise || _tokenId == border || _tokenId == collect);
        require(hasStarted[msg.sender]);
        require(!nftStakes[msg.sender][_tokenId]);
        nftStakes[msg.sender][_tokenId] = true; 
        wage[msg.sender] += dec(50);
        parentNFT.safeTransferFrom(msg.sender, address(this), _tokenId, 1, "0x00");
    } 

    function unstake(uint256 _tokenId) public {
        require(nftStakes[msg.sender][_tokenId]);
        delete nftStakes[msg.sender][_tokenId];
        wage[msg.sender] -= dec(50);
        parentNFT.safeTransferFrom(address(this), msg.sender, _tokenId, 1, "0x00");
    }   

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

contract Pools is ERC1155Holder {
    uint256 internal poolId = 0;
    address payable public owner;
    IERC1155 public parentNFT;

    constructor() payable {
        //cambio taxTen por airdrop
        parentNFT = IERC1155(0x2953399124F0cBB46d2CbACD8A89cF0599974963);
        
        createPool("Start", false, false, 0, 0, 0, 1, 0); //0

        createPool("Faventia", true, false, dec(40), dec(2), 1, 2, 0); //1

        createPool("Tax", false, false, 0, dec(200), 11, 2, 0); //2

        createPool("Vicentia ", true, false, dec(60), dec(4), 1, 2, 0); //3

        createPool("Solar Plant", false, false, 0, dec(50), 12, 4, 0); //4

        createPool("Teurnia", true, false, dec(100), dec(6), 2, 3, 0); //5
        createPool("Mevania", true, false, dec(100), dec(6), 2, 3, 0); //6
        createPool("Numantia", true, false, dec(120), dec(8), 2, 3, 0); //7

        createPool("South Border", false, false, 0, dec(200), 18, 4, 0); //8

        createPool("Novaesium", true, false, dec(140), dec(10), 3, 3, 0); //9
        createPool("Caudium", true, false, dec(140), dec(10), 3, 3, 0); //10

        createPool("Treasury", false, false, 0, 0, 17, 1, 0); //11

        createPool("Barium", true, false, dec(160), dec(12), 3, 3, 0); //12

        createPool("Pot", false, false, 0, 0, 13, 1, 0); //13

        createPool("Croton", true, false, dec(180), dec(14), 4, 3, 0); //14

        createPool("Water Plant", false, false, 0, dec(100), 12, 4, 0); //15
        createPool("Danaster", true, false, dec(180), dec(14), 4, 3, 0); //16

        createPool("West Border", false, false, 0, dec(200), 18, 4, 0); //17

        createPool("Magador", true, false, dec(200), dec(16), 4, 3, 0); //18

        createPool("Market", false, false, 0, 0, 14, 1, 0); //19

        createPool("Ascalon", true, false, dec(220), dec(18), 5, 3, 0); //20
        createPool("Brivas", true, false, dec(220), dec(18), 5, 3, 0); //21
        createPool("Hispalis", true, false, dec(240), dec(20), 5, 3, 0); //22

        createPool("Carbon Plant", false, false, 0, dec(150), 12, 4, 0); //23

        createPool("Apulum", true, false, dec(260), dec(22), 6, 3, 0); //24
        createPool("Ad Pontes", true, false, dec(260), dec(22), 6, 3, 0); //25

        createPool("North Border", false, false, 0, dec(200), 18, 4, 0); //26

        createPool("Ala Nova", true, false, dec(280), dec(24), 6, 3, 0); //27

        createPool("Secret", false, false, 0, 0, 15, 1, 0); //28


        createPool("Regina", true, false, dec(300), dec(26), 7, 3, 0); //29
        createPool("Castra Nova", true, false, dec(300), dec(26), 7, 3, 0); //30
        createPool("Augusta", true, false, dec(320), dec(28), 7, 3, 0); //31

        createPool("Skip", false, false, 0, 0, 16, 1, 0); //32

        createPool("Portus Noanis", true, false, dec(350), dec(35), 8, 2, 0); //33

        createPool("Nuclear Plant", false, false, 0, dec(200), 12, 4, 0); //34

        createPool("Tax", false, false, 0, dec(400), 11, 2, 0); //35

        createPool("East Border", false, false, 0, dec(200), 18, 4, 0); //36
        

        createPool("Portus Magnus", true, false, dec(400), dec(50), 8, 2, 0); //37
        

        owner = payable(msg.sender);
        
    }

    event PoolCreated(
        uint256 id,
        string name,
        bool buyable,
        bool owned,
        uint256 value,
        uint256 income,
        uint256 family,
        uint256 serie,
        uint256 level
    );

    struct Pool {
        uint256 id;
        string name;
        bool buyable;
        bool owned;
        uint256 value;
        uint256 income;
        uint256 family;
        uint256 serie;
        uint256 level;
    }

    mapping(uint256 => Pool) public pools;

    function createPool(
        
        string memory _name,
        bool _buyable,
        bool _owned,
        uint256 _value,
        uint256 _income,
        uint256 _family,
        uint256 _serie,
        uint256 _level
    ) private {
        //require(msg.sender == owner);
        pools[poolId] = Pool(
            poolId,
            _name,
            _buyable,
            _owned,
            _value,
            _income,
            _family,
            _serie,
            _level
        );
        emit PoolCreated(
            poolId,
            _name,
            _buyable,
            _owned,
            _value,
            _income,
            _family,
            _serie,
            _level
        );
        poolId++;
    }

    function setP(uint256 _id, string memory _name , uint256 _value, uint256 _income) public  {
        require(msg.sender == owner);
        Pool memory _pool = pools[_id];
        _pool.name = _name;
        _pool.value = _value;
        _pool.income = _income;
        pools[_id] = _pool;
    }

    function dec(uint256 _a) public pure returns (uint256) {
        return _a*10**18;
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity >= 0.8.17;

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


contract MonopolToken is IERC20 {
    
    string public constant name = "Cryptopolium Coin";
    string public constant symbol = "POL";
    uint8 public constant decimals = 18;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    uint256 totalSupply_ = 10000000000000000000000000000;

    constructor() {
        balances[msg.sender] = totalSupply_;
    }

    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address tokenOwner) public override view returns (uint256) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint256 numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint256 numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);
        require(numTokens <= allowed[owner][msg.sender]);

        balances[owner] -= numTokens;
        allowed[owner][msg.sender] -= numTokens;
        balances[buyer] += numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}