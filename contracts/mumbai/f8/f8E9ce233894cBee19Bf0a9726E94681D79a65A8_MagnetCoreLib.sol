// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

library MagnetCoreLib {
    bytes32 internal constant NAMESPACE = keccak256("magnet.lib.core");

    struct ProgramFirstMatrix {
        uint[3] users;
        uint[3] matrixNumber;
    }

    struct ProgramSecond {
        uint id;
        uint currentReferrer;
        uint[] referrals;
        bool closed;
    }

    struct ProgramThird {
        uint row; //Номер ряда в тринаре
        uint8 id; //Номер в ряду (0-2)
    }

    struct ProgramThirdStruct {
        uint[3] users;
        bool closed;
    }

    struct User {
        address mainAddress; // Основной адрес
        address[2] secondAddresses; // Дополнительныe адресa
        uint8[3] levels; // Уровни в 3х программах
        uint mainReferrer; // Изначальный пригласитель
        mapping(uint8 => uint)[3] referrers; // Пригласители по уровням в трех программах
        uint[16][3] referralsCount; // Количество реферралов в трех программах на каждом уровне
        uint[][16][3] referrals; // Реферралы в трех программах на каждом уровне
        uint[16][3] reinvestsCount; // Количество реинвествов в трех программах на каждом уровне
        uint[16][3] programId; // Id в каждой программе и на каждом уровне для структурных партнерок
        mapping(uint8 => mapping(uint => ProgramFirstMatrix)) programFirstUser;
        mapping(uint8 => ProgramSecond) programSecondUser;
        mapping(uint8 => ProgramThird) programThirdUser;
        uint turnover; //Оборот
        uint registryTime;
    }

    struct Storage {
        bool initialized;
        address root; // Команда Magnet
        address owner; // Управляющий смартконтрактом
        uint8 p1TreeDepth; // TODO: default value 2
        uint[][16][3] usersProgramsIds; // TODO: public Массивы с адресами по уровням для программ (чтобы следить за последовательностью входов)
        string[] balanceTypes; // TODO: public Типы балансов для возможности добавить новые
        bool locked; // No reentrance
        bool canOneButtonClaim; // Возможность клеймить по одной кнопке
        uint lastId;
        ProgramThirdStruct[][16] usersProgramThird; // Программа 3
        mapping(address => uint) usersIds; // TODO: public Адрес => ID пользователя
        mapping(uint => mapping(uint => uint)) usersBalances; // TODO: public userId => balanceTypeId => count
        mapping(uint => User) users; // TODO: public ID пользователя => Пользователь
    }

    function getStorage() internal pure returns (Storage storage s) {
        bytes32 position = NAMESPACE;
        assembly {
            s.slot := position
        }
    }

    // only lib

    function getUserById(uint _id) internal view returns (User storage) {
        return getStorage().users[_id];
    }

    // TODO: only programs
    function getUserId(address _addr) public view returns (uint) {
        return getStorage().usersIds[_addr];
    }

    function getUserByAddr(address _addr) internal view returns (User storage) {
        return getStorage().users[getUserId(_addr)];
    }

    function getRegistryTime(address _addr) internal view returns (uint) {
        return getUserByAddr(_addr).registryTime;
    }

    function getOneButtonClaimPossibility() internal view returns (bool) {
        return getStorage().canOneButtonClaim;
    }

    function setUserBalance(
        address _addr,
        uint _balanceType,
        uint _newBalance
    ) internal {
        Storage storage s = getStorage();
        s.usersBalances[getUserId(_addr)][_balanceType] = _newBalance;
    }

    //

    // --- ПРОГРАММЫ (ОБЩИЕ) ---

    // TODO: only programs
    function setProgramLevel(uint8 prgm, uint uid, uint8 _level) public {
        Storage storage s = getStorage();
        s.users[uid].levels[prgm] = _level;
    }

    // TODO: only programs
    function setUserMainReferrer(uint uid, uint rid) public {
        Storage storage s = getStorage();
        s.users[uid].mainReferrer = rid;
    }

    function getUserBalance(
        address addr,
        uint8 prgm
    ) external view returns (uint) {
        Storage storage s = getStorage();
        return s.usersBalances[s.usersIds[addr]][prgm];
    }

    function getUsersCountInProgram(
        uint8 prgm,
        uint8 levelNumber
    ) public view returns (uint) {
        return getStorage().usersProgramsIds[prgm][levelNumber].length;
    }

    function getUserLevel(uint uid, uint8 prgm) external view returns (uint8) {
        return getStorage().users[uid].levels[prgm];
    }

    // TODO: add require to ckeck 0 <= program <= 2
    function getUserLevelByAddress(
        address addr,
        uint8 program
    ) public view returns (uint8) {
        return getStorage().users[getUserId(addr)].levels[program];
    }

    function getUserLevels(address addr) public view returns (uint8[3] memory) {
        return getStorage().users[getUserId(addr)].levels;
    }

    function getUserMainReferrer(uint uid) public view returns (uint) {
        return getStorage().users[uid].mainReferrer;
    }

    function getMainReferrerAddressById(uint id) public view returns (address) {
        return getMainAddress(getStorage().users[id].mainReferrer);
    }

    // TODO: add require to ckeck 0 <= program <= 2
    function getUserProgramReferrer(
        uint uid,
        uint8 program,
        uint8 levelNumber
    ) public view returns (uint) {
        return getStorage().users[uid].referrers[program][levelNumber];
    }

    // TODO: only programs
    function setUserProgramReferrer(
        uint uid,
        uint8 prgm,
        uint8 levelNumber,
        uint rid
    ) public {
        Storage storage s = getStorage();
        s.users[uid].referrers[prgm][levelNumber] = rid;
    }

    // TODO: add require to ckeck 0 <= program <= 2
    function getUserReferralsCount(
        uint uid,
        uint8 prgm
    ) public view returns (uint[16] memory) {
        return getStorage().users[uid].referralsCount[prgm];
    }

    function getReferralByArrayId(
        uint uid,
        uint8 prgm,
        uint8 levelNumber,
        uint id
    ) public view returns (uint) {
        return getStorage().users[uid].referrals[prgm][levelNumber][id];
    }

    function getReinvestsCount(
        uint uid
    ) public view returns (uint[16][3] memory) {
        return getStorage().users[uid].reinvestsCount;
    }

    function getStructureId(
        uint8 prgm,
        uint8 levelNumber,
        uint uid
    ) external view returns (uint) {
        return getStorage().users[uid].programId[prgm][levelNumber];
    }

    // TODO: only programs
    function addUserMainAddress(uint id, address addr) external {
        Storage storage s = getStorage();
        s.users[id].mainAddress = addr;
    }

    // TODO: only programs
    function addUserIds(uint id, address addr) external {
        Storage storage s = getStorage();
        s.usersIds[addr] = id;
    }

    // TODO: only programs
    function incrementId() external {
        Storage storage s = getStorage();
        s.lastId += 1;
    }

    // TODO: only programs
    function getLastId() external view returns (uint) {
        return getStorage().lastId;
    }

    // TODO: only programs
    function setRegistryTime(uint id, uint _time) external {
        Storage storage s = getStorage();
        s.users[id].registryTime = _time;
    }

    // TODO: only programs
    function incReferralsCount(
        uint uid,
        uint8 prgm,
        uint8 levelNumber
    ) external {
        Storage storage s = getStorage();
        s.users[uid].referralsCount[prgm][levelNumber]++;
    }

    // TODO: only programs
    function incUserLevel(uint uid, uint8 prgm) external {
        Storage storage s = getStorage();
        s.users[uid].levels[prgm]++;
    }

    // TODO: only programs
    function setUserLevel(uint uid, uint8 prgm, uint8 levelNumber) external {
        Storage storage s = getStorage();
        s.users[uid].levels[prgm] = levelNumber;
    }

    // TODO: only programs
    function incReinvestsCount(
        uint uid,
        uint8 prgm,
        uint8 levelNumber
    ) external {
        Storage storage s = getStorage();
        s.users[uid].reinvestsCount[prgm][levelNumber]++;
    }

    // TODO: only programs
    function addReferral(
        uint uid,
        uint8 prgm,
        uint8 levelNumber,
        uint rid
    ) public {
        Storage storage s = getStorage();
        s.users[uid].referrals[prgm][levelNumber].push(rid);
    }

    // TODO: only programs
    function getMainAddress(uint id) public view returns (address) {
        return getStorage().users[id].mainAddress;
    }

    // TODO: only programs
    function setMainAddress(uint id, address addr) external {
        Storage storage s = getStorage();
        s.users[id].mainAddress = addr;
    }

    function getUserReferrerInProgram(
        uint8 prgm,
        uint8 levelNumber,
        uint uid
    ) public view returns (uint) {
        return getStorage().users[uid].referrers[prgm][levelNumber];
    }

    // TODO: only programs
    function addUserProgramIds(
        uint8 prgm,
        uint8 levelNumber,
        uint uid
    ) external {
        Storage storage s = getStorage();
        s.usersProgramsIds[prgm][levelNumber].push(uid);
    }

    // TODO: only programs
    function setUserProgramId(
        uint8 prgm,
        uint8 levelNumber,
        uint uid,
        uint id
    ) external {
        Storage storage s = getStorage();
        s.users[uid].programId[prgm][levelNumber] = id;
    }

    function getProgramIdsLength(
        uint8 prgm,
        uint8 levelNumber
    ) external view returns (uint) {
        return getStorage().usersProgramsIds[prgm][levelNumber].length;
    }

    function getProgramIdsUser(
        uint8 prgm,
        uint8 levelNumber,
        uint id
    ) public view returns (uint) {
        return getStorage().usersProgramsIds[prgm][levelNumber][id];
    }

    function getLeaders(
        uint8 prgm,
        uint user,
        uint8 levelNumber,
        uint256 cnt
    ) public view returns (uint[] memory) {
        uint[] memory out;
        out[0] = getUserReferrerInProgram(prgm, levelNumber, user);

        uint a = out[0];

        for (uint8 i = 1; i < (cnt + 1); i++) {
            a = getUserReferrerInProgram(prgm, levelNumber, a);
            if (getMainAddress(a) != address(0)) {
                out[i] = a;
            } else {
                out[i] = 1;
            }
        }

        return out;
    }

    function getOwner() external view returns (address) {
        Storage storage s = getStorage();
        return s.owner;
    }

    function addUserBalance(uint id, uint _balanceType, uint value) external {
        Storage storage s = getStorage();
        s.usersBalances[id][_balanceType] += value;
    }

    // TODO: only programs
    function getTurnover(uint id) external view returns (uint) {
        return getStorage().users[id].turnover;
    }

    // TODO: only programs
    function addTurnover(uint id, uint value) external {
        Storage storage s = getStorage();
        s.users[id].turnover += value;
    }

    // --- ПРОГРАММЫ (ПРОГРАММА 1) ---

    // TODO: only programs
    function setFirstMatrixUser(
        uint uid,
        uint matrixNumber,
        uint8 levelNumber,
        uint8 numberCol,
        uint rid
    ) external {
        Storage storage s = getStorage();
        s.users[uid].programFirstUser[levelNumber][matrixNumber].users[
            numberCol
        ] = rid;
    }

    // TODO: only programs
    function setFirstMatrixLink(
        uint uid,
        uint matrixNumber,
        uint8 levelNumber,
        uint8 numberCol,
        uint refMatrix
    ) external {
        Storage storage s = getStorage();
        s.users[uid].programFirstUser[levelNumber][matrixNumber].matrixNumber[
            numberCol
        ] = refMatrix;
    }

    function _getP1Matrix(
        uint uid,
        uint8 levelNumber,
        uint matrixId
    ) public view returns (ProgramFirstMatrix memory) {
        return getStorage().users[uid].programFirstUser[levelNumber][matrixId];
    }

    function _getP1Structure(
        ProgramFirstMatrix[] memory matrixes,
        uint8 levelNumber,
        uint8 d
    ) private view returns (ProgramFirstMatrix[] memory) {
        uint countOut = 0;
        for (uint i = d; i <= getStorage().p1TreeDepth; i++) {
            countOut += 3 ** i;
        }

        ProgramFirstMatrix[] memory outMatrixes = new ProgramFirstMatrix[](
            countOut
        );

        ProgramFirstMatrix[] memory newMatrixes = new ProgramFirstMatrix[](
            matrixes.length * 3
        );

        // Цикл по всем переданным (адрес и ссылка на матрицу)
        for (uint i = 0; i < matrixes.length; i++) {
            outMatrixes[i] = matrixes[i];
            // Цикл по адресам тринара
            for (uint8 j = 0; j < 3; j++) {
                newMatrixes[i * 3 + j] = _getP1Matrix(
                    matrixes[i].users[j],
                    levelNumber,
                    matrixes[i].matrixNumber[j]
                );
                if (d + 1 >= getStorage().p1TreeDepth) {
                    outMatrixes[matrixes.length + i * 3 + j] = newMatrixes[
                        i * 3 + j
                    ];
                }
            }
        }

        if (d + 1 < getStorage().p1TreeDepth) {
            ProgramFirstMatrix[] memory innerMatrixes = _getP1Structure(
                newMatrixes,
                levelNumber,
                d + 1
            );
            for (uint i = 0; i < innerMatrixes.length; i++) {
                outMatrixes[i + matrixes.length] = innerMatrixes[i];
            }
        }

        return outMatrixes;
    }

    function _getAddressesFromMatrixes(
        ProgramFirstMatrix[] memory matrixes
    ) private pure returns (uint[] memory) {
        uint[] memory out = new uint[](matrixes.length * 3);

        for (uint i = 0; i < matrixes.length; i++) {
            for (uint j = 0; j < 3; j++) {
                out[i * 3 + j] = matrixes[i].users[j];
            }
        }

        return out;
    }

    function _checkAddressInStructure(
        uint uid,
        uint mainAddress,
        uint8 levelNumber
    ) private view returns (bool) {
        if (getUserProgramReferrer(uid, 0, levelNumber) == mainAddress)
            return true;
        if (getUserProgramReferrer(uid, 0, levelNumber) == 0) return false;
        return
            _checkAddressInStructure(
                getUserProgramReferrer(uid, 0, levelNumber),
                mainAddress,
                levelNumber
            );
    }

    function getP1Structure(
        uint uid,
        uint8 levelNumber,
        uint matrix
    ) external view returns (uint[] memory) {
        require(
            getUserId(msg.sender) == uid ||
                msg.sender == getStorage().owner ||
                _checkAddressInStructure(
                    uid,
                    getUserId(msg.sender),
                    levelNumber
                ),
            "Not your structure!"
        );
        ProgramFirstMatrix[] memory tree = new ProgramFirstMatrix[](1);
        tree[0] = _getP1Matrix(uid, levelNumber, matrix);

        ProgramFirstMatrix[] memory outMatrix = _getP1Structure(
            tree,
            levelNumber,
            0
        );
        uint[] memory out = _getAddressesFromMatrixes(outMatrix);

        return out;
    }

    // --- ПРОГРАММЫ (ПРОГРАММА 2) ---
    function getP2ReferralsCount(
        uint uid,
        uint8 levelNumber
    ) external view returns (uint) {
        return
            getStorage()
                .users[uid]
                .programSecondUser[levelNumber]
                .referrals
                .length;
    }

    function getP2Referral(
        uint uid,
        uint8 levelNumber,
        uint id
    ) external view returns (uint) {
        return
            getStorage().users[uid].programSecondUser[levelNumber].referrals[
                id
            ];
    }

    function getUserBinarReferrerP2(
        uint8 levelNumber,
        uint uid
    ) external view returns (uint) {
        return
            getStorage()
                .users[uid]
                .programSecondUser[levelNumber]
                .currentReferrer;
    }

    // TODO: only programs
    function setProgramSecondReferrer(
        uint uid,
        uint8 levelNumber,
        uint rid
    ) external {
        Storage storage s = getStorage();
        s.users[uid].programSecondUser[levelNumber].currentReferrer = rid;
    }

    // TODO: only programs
    function addProgramSecondReferral(
        uint uid,
        uint8 levelNumber,
        uint referral
    ) external {
        Storage storage s = getStorage();
        s.users[uid].programSecondUser[levelNumber].referrals.push(referral);
    }

    function getProgramSecondReferrer(
        uint uid,
        uint8 levelNumber
    ) external view returns (uint) {
        return
            getStorage()
                .users[uid]
                .programSecondUser[levelNumber]
                .currentReferrer;
    }

    function getRefPrgm2(
        uint user,
        uint8 levelNumber,
        uint cnt
    ) public view returns (uint[] memory) {
        uint[] memory out;
        Storage storage s = getStorage();
        for (uint i = 0; i < cnt; i++) {
            s.users[user].programSecondUser[levelNumber].currentReferrer != 0
                ? out[i] = s
                    .users[user]
                    .programSecondUser[levelNumber]
                    .currentReferrer
                : out[i] = 1;
        }

        return out;
    }

    function getUserProgramSecondUser(
        uint addr,
        uint8 levelNumber
    ) public view returns (ProgramSecond memory) {
        return getStorage().users[addr].programSecondUser[levelNumber];
    }

    function getUserProgramSecondId(
        uint addr,
        uint8 levelNumber
    ) public view returns (uint) {
        return getStorage().users[addr].programSecondUser[levelNumber].id;
    }

    function getPSBinarReferrer(
        uint addr,
        uint8 levelNumber
    ) public view returns (uint) {
        return
            getStorage()
                .users[addr]
                .programSecondUser[levelNumber]
                .currentReferrer;
    }

    // --- ПРОГРАММЫ (ПРОГРАММА 3) ---

    function getUserP3Row(
        uint8 levelNumber,
        uint uid
    ) external view returns (uint) {
        return getStorage().users[uid].programThirdUser[levelNumber].row;
    }

    function getRefPrgm3(
        uint user,
        uint8 levelNumber,
        uint cnt
    ) public view returns (uint[3][] memory) {
        Storage storage s = getStorage();
        uint userRow = s.users[user].programThirdUser[levelNumber].row;
        require(userRow > 1, "Invalid Row!");
        uint[3][] memory out;
        for (uint i = 1; i < cnt; i++) {
            uint[3] memory a = s
            .usersProgramThird[levelNumber][userRow - i].users;
            out[i - 1] = a;
        }
        return out;
    }

    function getUsersP3Length(uint8 levelNumber) external view returns (uint) {
        return getStorage().usersProgramThird[levelNumber].length;
    }

    function getUsersP3Id(
        uint uid,
        uint8 levelNumber
    ) external view returns (uint8) {
        return getStorage().users[uid].programThirdUser[levelNumber].id;
    }

    function getUsersP3Row(
        uint uid,
        uint8 levelNumber
    ) external view returns (uint) {
        return getStorage().users[uid].programThirdUser[levelNumber].row;
    }

    function getUserP3(
        uint8 levelNumber,
        uint row,
        uint8 col
    ) external view returns (uint) {
        return getStorage().usersProgramThird[levelNumber][row].users[col];
    }

    // TODO: only programs
    function setUserP3(
        uint8 levelNumber,
        uint row,
        uint8 col,
        uint uid
    ) external {
        Storage storage s = getStorage();
        s.usersProgramThird[levelNumber][row].users[col] = uid;
    }

    // TODO: only programs
    function setP3UserId(uint uid, uint8 levelNumber, uint8 col) external {
        getStorage().users[uid].programThirdUser[levelNumber].id = col;
    }

    // TODO: only programs
    function setP3UserRow(uint uid, uint8 levelNumber, uint row) external {
        Storage storage s = getStorage();
        s.users[uid].programThirdUser[levelNumber].row = row;
    }

    function isP3BlockClosed(
        uint8 levelNumber,
        uint row
    ) external view returns (bool) {
        return getStorage().usersProgramThird[levelNumber][row].closed;
    }

    // TODO: only programs
    function setP3BlockClosed(uint8 levelNumber, uint row) external {
        getStorage().usersProgramThird[levelNumber][row].closed = true;
    }

    // TODO: only programs
    function addP3NewRow(uint8 levelNumber, uint uid) external {
        Storage storage s = getStorage();
        ProgramThirdStruct memory newRow;
        newRow.users[0] = uid;
        s.usersProgramThird[levelNumber].push(newRow);
    }

    // --- ОБЩИЕ ---

    function getBallance() external view returns (uint256) {
        return address(this).balance;
    }

    function addSecondWallet(address addr, uint8 id) external {
        Storage storage s = getStorage();
        require(id >= 0 && id < 2, "Invalid ID!");
        require(
            s.usersIds[msg.sender] != 0 && s.usersIds[addr] == 0,
            "Invalid address!"
        );
        s.users[s.usersIds[msg.sender]].secondAddresses[id] = addr;
    }

    function changeMainWallet(address addr, uint8 id) external {
        Storage storage s = getStorage();
        require(
            s.users[s.usersIds[addr]].secondAddresses[id] != address(0),
            "Invalid address!"
        );
        require(
            s.users[s.usersIds[addr]].secondAddresses[0] == msg.sender ||
                s.users[s.usersIds[addr]].secondAddresses[1] == msg.sender,
            "Invalid address!"
        );
        s.users[s.usersIds[addr]].mainAddress = s
            .users[s.usersIds[addr]]
            .secondAddresses[id];
        s.usersIds[s.users[s.usersIds[addr]].secondAddresses[id]] = s.usersIds[
            addr
        ];
        s.usersIds[addr] = 0;
    }

    //-- БАЛАНС --

    // TODO: only programs
    function addBalanceType(string memory name) external onlyOwnerMain {
        Storage storage s = getStorage();
        s.balanceTypes.push(name);
    }

    function getBanceTypes() external view returns (string[] memory) {
        return getStorage().balanceTypes;
    }

    function getUserBalanceByBalanceId(
        uint uid,
        uint balanceTypeId
    ) public view returns (uint) {
        return getStorage().usersBalances[uid][balanceTypeId];
    }

    function getUserBalanceAll(uint uid) external view returns (uint) {
        uint sum = 0;
        for (uint i = 0; i < getStorage().balanceTypes.length; i++) {
            sum += getUserBalanceByBalanceId(uid, i);
        }
        return sum;
    }

    //-- СЛУЖЕБНЫЕ ФУНКЦИИ И МОДИФИКАТОРЫ --

    function changeTransferClaim() external onlyOwnerMain {
        getStorage().canOneButtonClaim = true;
    }

    modifier onlyOwnerMain() {
        require(msg.sender == getStorage().owner, "Access denied!");
        _;
    }

    // modifier NoReentrancyMain() {
    //     Storage storage s = getStorage();
    //     require(!s.locked, "No re-entrancy");
    //     s.locked = true;
    //     _;
    //     s.locked = false;
    // }

    function initialize(address _root, address _owner) internal {
        Storage storage s = getStorage();
        require(!s.initialized, "already initialized");
        s.root = _root;
        s.owner = _owner;

        s.balanceTypes.push("P1");
        s.balanceTypes.push("P2");
        s.balanceTypes.push("P3");

        for (uint8 i = 1; i < 16; i++) {
            // Программа 1
            s.usersProgramsIds[0][i].push(1);
            // Программа 2
            s.usersProgramsIds[1][i].push(1);
            ProgramSecond memory _programSecond;
            _programSecond.closed = true;
            s.users[1].programSecondUser[i] = _programSecond;
        }

        for (uint8 i = 1; i < 16; i++) {
            // Программа 3
            s.usersProgramsIds[2][i].push(1);
            ProgramThirdStruct memory _programThirdStruct;
            _programThirdStruct.users[0] = 1;
            _programThirdStruct.users[1] = 1;
            _programThirdStruct.users[2] = 1;
            _programThirdStruct.closed = true;
            s.usersProgramThird[i].push(_programThirdStruct);

            ProgramThird memory _programThird;
            _programThird.id = 0;
            _programThird.row = 0;

            s.users[1].programThirdUser[i] = _programThird;
        }
        s.initialized = true;
    }
}