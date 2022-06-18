// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//                                                                                                                              //
//                                                                                                                              //
//                                                                                             ....    .:-===-.                 //
//                                             .:--:.      --==:   .+++++.:***#-       [email protected]@@@@@@@@@@+ -%@@@@@@@@@+               //
//                -*****##*+-    #%@@#   =#@@@@@@@@+   [email protected]@@@:  [email protected]@@@=  [email protected]@@@.       @@@@@@@%%%%%:[email protected]@@@=:-*@@@@-                 //
//                %@@@@@@@@@@@+ [email protected]@@@= [email protected]@@@@#*#@@@@%. *@@@@ [email protected]@@@=    %@@@%       [email protected]@@@-        [email protected]@@@*=-.                      //
//               [email protected]@@@+-:-#@@@@[email protected]@@@[email protected]@@@+    -%###= @@@@@@@@@+     [email protected]@@@+       [email protected]@@@@%@@@@=  .#@@@@@@@@%+.                  //
//               [email protected]@@@    *@@@@.%@@@% @@@@%           :@@@@@@@@@=     [email protected]@@@.       %@@@@######.     -+*%@@@@@@.                 //
//               %@@@@%%%@@@@@[email protected]@@@+ @@@@*         . [email protected]@@@@%@@@@-    #@@@%       [email protected]@@@+        ****+    *@@@@-                 //
//              [email protected]@@@@@@@@@#+. [email protected]@@@: @@@@@     %@@@@ %@@@%  #@@@@-   @@@@%++++**[email protected]@@@%##%%%%% [email protected]@@@@#*%@@@@*                  //
//              [email protected]@@@.         *@@@@  [email protected]@@@@#*#@@@@%[email protected]@@@+   #@@@@- [email protected]@@@@@@@@@@ *@@@@@@@@@@@*  :*%@@@@@@#+.                   //
//              %@@@#          @@@@*   .+%@@@@@@@*-  -%%##.    ****+.-++======--: ::::::......        .....                     //
//              ++++-          -:::.       .::.     .:::.           --===      .+*****##*+-   -%%@@@@@@@@@%                     //
//                 -----=====++:  -*#%%%%#+.     -#@@@@@@@%=       *@@@@@=     [email protected]@@@@@@@@@@@. *@@@@@@@@%%%+                     //
//                [email protected]@@@@@@@@@@@[email protected]@@@@%@@@@@=  :%@@@@%#%@@@@%     [email protected]@@@@@%     *@@@@[email protected]@@@* @@@@#                             //
//                [email protected]@@@+=====-- @@@@#   =+++= [email protected]@@@*    -%%%%-   [email protected]@@#@@@@-    @@@@*   [email protected]@@@*:@@@@@%%%@@%                       //
//                #@@@@-=====   #@@@@@%#*=:   @@@@%             [email protected]@@# %@@@#   :@@@@%%%@@@@@%[email protected]@@@%%####=                       //
//                @@@@@@@@@@%    -#@@@@@@@@%: @@@@*        ..  [email protected]@@#[email protected]@@@.  *@@@@@@%%%#+:  @@@@#                              //
//               [email protected]@@@+---::.       .:=#@@@@% @@@@@     %@@@@ [email protected]@@@@@@@@@@@*  @@@@#         [email protected]@@@@%%%%@@@=                      //
//               *@@@@::[email protected]@@@%-::[email protected]@@@* [email protected]@@@@*+*@@@@@:[email protected]@@@***++%@@@@.:@@@@=         [email protected]@@@@@@@@@@@.                      //
//               @@@@@@@@@@@@+ [email protected]@@@@@@@@@@+   :*@@@@@@@@#= [email protected]%%%.     -#***-:++++.         .--:::::.....                       //
//              :#####******+.   :=+++++=:        .::-:.                                                                        //
//                                                                                                                              //
//                                                                                                          www.miinded.com     //
//                                                                                                                              //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

import "./RunGameManager.sol";

contract PickleEscapeGame is RunGameManager {

    constructor(address _gameManager, address _nft) {
        setGameManagerContract(_gameManager);
        setNftContract(_nft);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Tournament.sol";
import "./Final.sol";
import "./Setters.sol";
import "./IGameResponse.sol";

abstract contract RunGameManager is Tournament, Final, Setters, IGameResponse {

    uint16 private offset = 0;
    uint256 private offsetBurnNfts = 0;

    function length(uint16 _offset, uint16 _length, uint16 _total) internal view returns (uint16) {
        return offset + _length > _total ? _total - _offset : _length;
    }

    //////////////////////////////////////////////////
    // Functions Manager
    //////////////////////////////////////////////////
    function _setDayId(uint8 _dayId) public onlyAdmin returns (Response memory){

        offset = 0;

        _seasons[seasonId].day[_seasons[seasonId].dayId].end = uint64(block.timestamp);

        _seasons[seasonId].dayId = _dayId;

        _seasons[seasonId].day[_dayId].start = uint64(block.timestamp);

        setNewHashSD();

        if (_seasons[seasonId].dayId >= pctKillByDay.length) {
            return Response(true, "fOpening", uint16(_seasons[seasonId].dayId - 1), uint16(_seasons[seasonId].dayId), 0);
        }
        return Response(false, "dayDone", uint16(_seasons[seasonId].dayId - 1), uint16(_seasons[seasonId].dayId), 0);
    }

    function _setSeasonId(uint16 _seasonId) public onlyAdmin returns (Response memory){

        offset = 0;

        _seasons[seasonId].seasonDone = true;
        _seasons[seasonId].day[_seasons[seasonId].dayId].end = uint64(block.timestamp);
        _seasons[seasonId].dayId += 1;

        seasonId = _seasonId;

        _seasons[seasonId].dayId = 0;
        _seasons[seasonId].day[0].start = uint64(block.timestamp);
        _seasons[seasonId].day[0].end = uint64(0);
        _seasons[seasonId].seasonId = seasonId;
        _seasons[seasonId].seasonDone = false;

        setNewHashSD();

        return Response(true, "seasonDone", seasonId - 1, seasonId, 0);
    }

    function _addPickleBalanceIn(uint16 _jarId, uint16 _count) public onlyAdmin {

        if (_seasons[seasonId].balance[_jarId] == 0) {
            _seasons[seasonId].jarIdsKey[_jarId] = uint16(_seasons[seasonId].jarIds.length);
            _seasons[seasonId].jarIds.push(_jarId);
            _seasons[seasonId].totalJars += 1;
        }

        _seasons[seasonId].totalPickles += _count;
        _seasons[seasonId].balance[_jarId] += _count;

        emit EventAddPickle(_jarId, _count, seasonId, _seasons[seasonId].dayId);
    }

    function _addPickleBalanceInMany(uint16[] memory _jarIds, uint16[] memory _counts) public onlyAdmin {
        for (uint256 i = 0; i < _jarIds.length; i++) {
            _addPickleBalanceIn(_jarIds[i], _counts[i]);
        }
    }

    function transfer(address, address, uint256 _jarId) external virtual {

        require(gameManager.getCurrentGameState() <= 3, "You can't transfer during processing");

        burnAllFor(uint16(_jarId));
    }

    function _chooseWayMany(uint16[] memory _wayIds, uint16[] memory _jarIds) public onlyAdmin {

        require(_wayIds.length == _jarIds.length, "BL");

        for (uint256 i = 0; i < _jarIds.length; i++) {
            chooseWay(_wayIds[i], _jarIds[i]);
        }
    }

    function _activeBonusFor(uint16 _jarId, uint8 _bonusId) public onlyAdmin {
        _picklesKill[hashSD].bonus[_jarId][_bonusId] = true;
    }
    function _activeBonusForMany(uint16[] memory _jarIds, uint8[] memory _bonusIds) public onlyAdmin {

        require(_jarIds.length == _bonusIds.length, "BL");

        for (uint256 i = 0; i < _jarIds.length; i++) {
            _picklesKill[hashSD].bonus[_jarIds[i]][_bonusIds[i]] = true;
        }
    }

    function _finalChoosePlane(uint16[] memory _planeIds, uint16[] memory _jarIds) public onlyAdmin {
        for(uint256 i = 0; i < _planeIds.length; i++){
            finalChoosePlane(_planeIds[i], _jarIds[i]);
        }
    }

    function _walletsNotChoose(uint16 _length) public onlyAdmin returns (Response memory){

        uint16 total = getCurrentJarsLength();
        _length = length(offset, _length, total);

        for (uint16 i = offset; i < offset + _length; i++) {
            addJarIdNotChosen(_seasons[seasonId].jarIds[i]);
        }

        offset += _length;

        if (offset < total) {
            return Response(false, "wNotChosen", offset, total, 0);
        }

        offset = 0;
        return Response(true, "wNotChosenDone", total, total, 0);
    }

    function _setWinnerWay() public onlyAdmin returns (Response memory) {

        _picklesKill[hashSD].wayIdWinner = winnerWayId(seasonId, _seasons[seasonId].dayId);

        return Response(true, "winDone", _picklesKill[hashSD].wayIdWinner, 0, 0);
    }

    function _loadWaysKill() public onlyAdmin returns (Response memory){

        bytes32 hashSDWinner = getHashSDW(seasonId, _seasons[seasonId].dayId, _picklesKill[hashSD].wayIdWinner);

        uint16 pickleAlive = _seasons[seasonId].totalPickles - _seasons[seasonId].totalPicklesDead;
        uint16 balanceSelected = pickleAlive - _ways[hashSDWinner].balance;

        uint256 killCountPct = ((uint256(pickleAlive) * pctKillByDay[_seasons[seasonId].dayId] / 10000) * 10000) / uint256(balanceSelected);

        for (uint8 wayId = 0; wayId <= maxWays; wayId ++) {

            bytes32 hashSDW = getHashSDW(seasonId, _seasons[seasonId].dayId, wayId);

            if (wayId == _picklesKill[hashSD].wayIdWinner) {
                _ways[hashSDW].kill = 0;
                continue;
            }

            _ways[hashSDW].kill = uint16(uint256(_ways[hashSDW].balance) * killCountPct / 10000);
        }

        return Response(true, "lWKill", 0, 0, 0);
    }

    function _loadRepartition(uint8 _wayId, uint16 _length) public onlyAdmin returns(Response memory) {

        bytes32 hashSDW = getHashSDW(seasonId, _seasons[seasonId].dayId, _wayId);

        uint16 total = uint16(_ways[hashSDW].jarIds.length);
        _length = length(offset, _length, total);

        uint16 key = offset;
        for (uint16 i = offset; i < offset + _length; i++) {

            uint16 jarId = _ways[hashSDW].jarIds[key];

            uint16 offsetWallet = _ways[hashSDW].offsetWayJarIds[jarId];
            uint16 totalWallet = currentPickleIn(jarId);
            uint16 lengthWallet = offsetWallet + uint16(250) > totalWallet ? totalWallet - offsetWallet : uint16(250);

            for (uint16 k = offsetWallet; k < offsetWallet + lengthWallet; k++) {
                _ways[hashSDW].repartition.push(jarId);
            }

            _ways[hashSDW].offsetWayJarIds[jarId] += lengthWallet;

            if (_ways[hashSDW].offsetWayJarIds[jarId] == totalWallet) {
                key++;
            }
        }

        offset = key;

        if (offset < total) {
            return Response(false, "LRep", offset, total, _wayId);
        }

        offset = 0;
        return Response(true, "LRepDone", total, total, _wayId);
    }

    function _killPickle(uint8 _wayId, uint16 _length) public onlyAdmin returns (Response memory){

        bytes32 hashSDW = getHashSDW(seasonId, _seasons[seasonId].dayId, _wayId);

        uint16 total = _ways[hashSDW].kill;
        _length = length(offset, _length, total);

        for (uint16 i = offset; i < offset + _length; i++) {

            uint16 key = getRandomKeyKillPickle(_ways[hashSDW].balance, i);
            uint16 jarId = _ways[hashSDW].repartition[key];

            while(currentPickleIn(jarId) == 0){
                if(key == 0){
                    key = _ways[hashSDW].balance;
                }
                key --;
                jarId = _ways[hashSDW].repartition[key];
            }

            if (_picklesKill[hashSD].bonus[jarId][uint8(1)] == false) {
                burnOneFor(jarId);
            }

            if (currentPickleIn(jarId) == 0) {
                uint16 jarIdKey = _seasons[seasonId].jarIdsKey[jarId];
                uint16 lastJarId = _seasons[seasonId].jarIds[ _seasons[seasonId].jarIds.length - 1];
                _seasons[seasonId].jarIds[jarIdKey] = lastJarId;
                _seasons[seasonId].jarIdsKey[lastJarId] = jarIdKey;
                _seasons[seasonId].jarIds.pop();
            }
        }

        offset += _length;

        if (offset < total) {
            return Response(false, "kPickles", offset, total, _wayId);
        }

        offset = 0;
        return Response(true, "KPicklesDone", total, total, _wayId);
    }

    function _finalLoadWalletNotChosen(uint16 _length) public onlyAdmin returns (Response memory){

        uint16 total = getCurrentJarsLength();
        _length = length(offset, _length, total);

        for (uint16 i = offset; i < offset + _length; i++) {
            finalChoosePlane(getRandomKeyFinalPlane(maxPlanes + 1, i), _seasons[seasonId].jarIds[i]);
        }

        offset += _length;

        if (offset < total) {
            return Response(false, "fLWNotC", offset, total, 0);
        }

        offset = 0;
        return Response(true, "fLWNotCDone", total, total, 0);
    }

    function _finalLoadRepartition(uint16 _length) public onlyAdmin returns (Response memory){

        uint16 total = maxPlanes;
        _length = length(offset, _length, total);

        for (uint16 placeId = offset; placeId <= offset + _length; placeId++) {
            for (uint256 i = 0; i < _seasons[seasonId].theFinal.planeIdJarId[placeId].length; i++) {
                _seasons[seasonId].theFinal.repartition.push(_seasons[seasonId].theFinal.planeIdJarId[placeId][i]);
            }
        }

        offset += _length;

        if (offset < total) {
            return Response(false, "fLRep", offset, total, 0);
        }

        offset = 0;
        return Response(true, "fLRepDone", total, total, 0);
    }

    function _finalKillPickles(uint16 _length) public onlyAdmin returns (Response memory){

        uint16 total = uint16(_seasons[seasonId].theFinal.repartition.length) - 1;
        _length = length(offset, _length, total);

        for (uint256 i = offset; i < offset + _length; i++) {

            uint16 key = getRandomKeyFinalKill(uint256(_seasons[seasonId].theFinal.repartition.length - i), i);

            finalKillPickle(_seasons[seasonId].theFinal.repartition[key]);
        }

        offset += _length;

        if (offset < total) {
            return Response(false, "fKPickles", offset, total, 0);
        }

        offset = 0;
        return Response(true, "fKPicklesDone", total, total, 0);
    }

    function _finalSetWinnerSeason(uint16 _length) public onlyAdmin returns (Response memory) {

        uint16 total = uint16(_seasons[seasonId].theFinal.repartition.length);
        _length = length(offset, _length, total);

        for (uint256 i = offset; i < offset + _length; i++) {

            uint16 jarId = _seasons[seasonId].theFinal.repartition[i];

            if (currentPickleIn(jarId) != 0) {
                finalSetWinner(jarId);
            }
        }

        offset += _length;

        if (offset < total) {
            return Response(false, "fWinner", offset, total, 0);
        }

        offset = 0;
        return Response(true, "fDone", total, total, 0);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Burn.sol";

abstract contract Tournament is Burn {

    function chooseWay(uint16 _wayId, uint16 _jarId) public onlyAdmin {

        if (_picklesKill[hashSD].jarIdWayChosen[_jarId] != 0) {
            return;
        }

        uint16 balance = currentPickleIn(_jarId);

        if (balance == 0) {
            _picklesKill[hashSD].jarIdWayChosen[_jarId] = maxWays;
            return;
        }

        bytes32 hashSDW = getHashSDW(seasonId, _seasons[seasonId].dayId, uint8(_wayId));

        _picklesKill[hashSD].jarIdWayChosen[_jarId] = uint8(_wayId) + 1;
        _ways[hashSDW].jarIds.push(_jarId);
        _ways[hashSDW].balance += balance;
    }

    function winnerWayId(uint16 _seasonId, uint8 _dayId) internal view returns (uint8){
        uint8 winner;
        uint16 balanceWinner = type(uint16).max;
        for (uint8 wayId = 0; wayId < maxWays; wayId ++) {

            bytes32 hashSDW = getHashSDW(_seasonId, _dayId, wayId);

            if (_ways[hashSDW].balance < balanceWinner) {
                winner = wayId;
                balanceWinner = _ways[hashSDW].balance;
            }
        }
        return winner;
    }

    function addJarIdNotChosen(uint16 _jarId) public onlyAdmin {

        if (_picklesKill[hashSD].jarIdWayChosen[_jarId] != 0 || currentPickleIn(_jarId) == 0 || _jarId == 0) {return;}

        chooseWay(maxWays, _jarId);
    }

    function getRandomKeyKillPickle(uint256 _remaining, uint16 _i) internal view returns (uint16) {

        return uint16(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _i))) % _remaining);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Burn.sol";

abstract contract Final is Burn {

    function finalChoosePlane(uint16 _planeId, uint16 _jarId) public onlyAdmin {

        if (_jarId == 0 || _planeId == 0 || _planeId > maxPlanes || _seasons[seasonId].theFinal.jarIdPlaneId[_jarId] != 0 || currentPickleIn(_jarId) == 0) {
            return;
        }

        _seasons[seasonId].theFinal.planeIdJarId[_planeId].push(_jarId);
        _seasons[seasonId].theFinal.jarIdPlaneId[_jarId] = _planeId;

    }

    function finalKillPickle(uint16 _jarId) public onlyAdmin {

        if(_jarId == 0){
            return;
        }

        burnAllFor(_jarId);

        _seasons[seasonId].theFinal.killed.push(_jarId);
    }

    function finalSetWinner(uint16 _jarId) public onlyAdmin {
        _seasons[seasonId].theFinal.winner.jarId = _jarId;
        _seasons[seasonId].theFinal.winner.owner = nft.ownerOf(_jarId);

    }

    function getRandomKeyFinalKill(uint256 _remaining, uint256 _i) internal returns(uint16) {

        uint16 rand = uint16(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _i))) % _remaining);
        uint16 key = rand;

        if (_seasons[seasonId].theFinal.randomKeyUsed[rand] != 0) {
            key = _seasons[seasonId].theFinal.randomKeyUsed[rand];
        }

        if (_seasons[seasonId].theFinal.randomKeyUsed[uint16(_remaining - 1)] == 0) {
            _seasons[seasonId].theFinal.randomKeyUsed[rand] = uint16(_remaining - 1);
        } else {
            _seasons[seasonId].theFinal.randomKeyUsed[rand] = _seasons[seasonId].theFinal.randomKeyUsed[uint16(_remaining - 1)];
        }

        return key;
    }
    function getRandomKeyFinalPlane(uint256 _remaining, uint256 _i) internal view returns(uint16) {
        return uint16(uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, _i))) % _remaining);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Globals.sol";

abstract contract Setters is Globals {

    function setGameManagerContract(address _gameManager) public onlyAdmin {
        setAdminAddress(address(gameManager), false);
        gameManager = IGameManager(_gameManager);
        setAdminAddress(_gameManager, true);
    }
    function setNftContract(address _nft) public onlyAdmin {
        nft = IPickleJar(_nft);
    }

    function setNewHashSD() public onlyAdmin {
        hashSD = keccak256(abi.encodePacked(seasonId, _seasons[seasonId].dayId));
    }

    function setPctKillByDay(uint256[] memory _pctKillByDay) public onlyAdmin {
        for(uint256 i = 0; i < 5; i++){
            pctKillByDay[i] = _pctKillByDay[i];
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameResponse {

    struct Response{
        bool done;
        string method;
        uint16 offset;
        uint16 total;
        uint16 data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Getters.sol";

abstract contract Burn is Getters{

    function burnOneFor(uint16 _jarId) public onlyAdmin{

        emit EventKillPickle(_jarId, 1, seasonId, _seasons[seasonId].dayId);

        _seasons[seasonId].totalPicklesDead += 1;
        _seasons[seasonId].balance[_jarId] -= 1;
    }

    function burnAllFor(uint16 _jarId) internal {

        emit EventKillPickle(_jarId, _seasons[seasonId].balance[_jarId], seasonId, _seasons[seasonId].dayId);

        _seasons[seasonId].totalPicklesDead += _seasons[seasonId].balance[_jarId];
        _seasons[seasonId].balance[_jarId] = 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Globals.sol";

abstract contract Getters is Globals{

    struct SeasonData {
        uint16 seasonId;
        uint8 dayId;
        uint256 jarIdsLength;
        uint16 totalJars;
        uint16 totalPickles;
        uint16 totalPicklesDead;
        bool seasonDone;
        Day[7] day;
    }
    struct WaySelectionData {
        uint256 jarIdsLength;
        uint16 balanceWays;
        uint16 kill;
    }
    struct PicklesKilledData {
        uint8 wayIdWinner;
        uint256 jarIdsNotChooseListLength;
    }
    struct FinalData {
        uint256 finalRepartitionLength;
        uint256 finalKilledLength;
        uint16[] repartition;
    }

    //////////////////////////////////////////////////
    // Current Season
    //////////////////////////////////////////////////
    function currentPickleIn(uint16 _jarId) public view returns (uint16){
        return _seasons[seasonId].balance[_jarId];
    }
    function getTotalJars() public view returns (uint16){
        return _seasons[seasonId].totalJars;
    }
    function getCurrentJarsLength() public view returns (uint16){
        return uint16(_seasons[seasonId].jarIds.length);
    }
    function getCurrentJarsIds() public view returns (uint16[] memory){
        return _seasons[seasonId].jarIds;
    }
    function getFinalJarIdPlaceId(uint16 _jarId) public view returns (uint16){
        return _seasons[seasonId].theFinal.jarIdPlaneId[_jarId];
    }
    function getBonusActive(uint16 _jarId) public view returns(bool[] memory){
        bool[] memory bonus = new bool[](6);
        for(uint8 i = 1; i <= 5; i++){
            bonus[i] = _picklesKill[hashSD].bonus[_jarId][i];
        }
        return bonus;
    }

    //////////////////////////////////////////////////
    // By Season
    //////////////////////////////////////////////////
    function totalSupplySeason(uint16 _seasonId) public view returns (uint16){
        return _seasons[_seasonId].totalPickles - _seasons[_seasonId].totalPicklesDead;
    }
    function balancePicklesIn(uint16 _seasonId, uint16 _jarId) public view returns (uint256){
        return _seasons[_seasonId].balance[_jarId];
    }
    function balancePicklesInMany(uint16 _seasonId, uint16[] memory _jarIds) public view returns (uint16[] memory){
        uint16[] memory balance = new uint16[](_jarIds.length);

        for(uint256 i = 0; i < _jarIds.length; i++){
            balance[i] = _seasons[_seasonId].balance[_jarIds[i]];
        }

        return balance;
    }
    function jarIdNotEmpty(uint16 _seasonId, uint16 _jarId) public view returns (bool){
        return _seasons[_seasonId].balance[_jarId] > 0;
    }
    function jarIdsNotEmpty(uint16 _seasonId, uint16[] memory _jarIds) public view returns (bool[] memory){

        bool[] memory notEmpty = new bool[](_jarIds.length);

        for(uint256 i = 0; i < _jarIds.length; i++){
            notEmpty[i] = _seasons[_seasonId].balance[_jarIds[i]] > 0;
        }

        return notEmpty;
    }
    function getWinnerWay(uint16 _seasonId, uint8 _dayId) public view returns (uint16){
        bytes32 _hashSD = getHashSD(_seasonId, _dayId);
        return _picklesKill[_hashSD].wayIdWinner;
    }
    function getFinalKill(uint16 _seasonId) public view returns (uint16[] memory){
        return _seasons[_seasonId].theFinal.killed;
    }
    function getWayIdFor(uint16 _seasonId, uint8 _dayId, uint16 _jarId) public view returns(uint16){
        if(_dayId >= 5){
            return _seasons[_seasonId].theFinal.jarIdPlaneId[_jarId];
        }
        bytes32 _hashSD = getHashSD(_seasonId, _dayId);
        return uint16(_picklesKill[_hashSD].jarIdWayChosen[_jarId]);
    }
    function getWayIdForMany(uint16 _seasonId, uint8 _dayId, uint16[] memory _jarIds) public view returns(uint16[] memory){
        bytes32 _hashSD = getHashSD(_seasonId, _dayId);
        uint16[] memory wayIds = new uint16[](_jarIds.length);
        for(uint256 i = 0; i < _jarIds.length; i++){
            if(_dayId >= 5){
                wayIds[i] = _seasons[_seasonId].theFinal.jarIdPlaneId[_jarIds[i]];
            }else{
                wayIds[i] = uint16(_picklesKill[_hashSD].jarIdWayChosen[_jarIds[i]]);
            }
        }
        return wayIds;
    }
    function getWaySelectionJarIds(uint16 _seasonId, uint8 _dayId, uint8 _wayId, uint256 _offset, uint256 _limit) public view returns(uint16[] memory){
        bytes32 hashSDW = getHashSDW(_seasonId, _dayId, _wayId);
        uint16[] memory jarIds = new uint16[](_limit);
        for(uint256 i = _offset; i < _offset + _limit; i++){
            jarIds[i] = _ways[hashSDW].jarIds[i];
        }
        return jarIds;
    }
    function getSeasonData(uint16 _seasonId) public view returns (SeasonData memory){
        return SeasonData(
            _seasons[_seasonId].seasonId,
            _seasons[_seasonId].dayId,
            _seasons[_seasonId].jarIds.length,
            _seasons[_seasonId].totalJars,
            _seasons[_seasonId].totalPickles,
            _seasons[_seasonId].totalPicklesDead,
            _seasons[_seasonId].seasonDone,
            _seasons[_seasonId].day
        );
    }
    function getWaySelectionData(uint16 _seasonId, uint8 _dayId, uint8 _wayId) public view returns (WaySelectionData memory){
        bytes32 hashSDW = getHashSDW(_seasonId, _dayId, _wayId);
        return WaySelectionData(
            _ways[hashSDW].jarIds.length,
            _ways[hashSDW].balance,
            _ways[hashSDW].kill
        );
    }
    function getPicklesKilledData(uint16 _seasonId, uint8 _dayId) public view returns (PicklesKilledData memory){
        bytes32 hashSD = getHashSD(_seasonId, _dayId);
        return PicklesKilledData(
            _picklesKill[hashSD].wayIdWinner,
            _picklesKill[hashSD].jarIdsNotChosen.length
        );
    }
    function getFinalData(uint16 _seasonId) public view returns (FinalData memory){
        return FinalData(
            _seasons[_seasonId].theFinal.repartition.length,
            _seasons[_seasonId].theFinal.killed.length,
            _seasons[_seasonId].theFinal.repartition
        );
    }
    function getWinnerData(uint16 _seasonId) public view returns (Winner memory){
        return _seasons[_seasonId].theFinal.winner;
    }

    //////////////////////////////////////////////////
    // Global
    //////////////////////////////////////////////////
    function totalPickle() public view returns (uint256){
        uint256 total = 0;
        for (uint16 i = 0; i <= seasonId; i++) {
            total += totalSupplySeason(i);
        }
        return total;
    }
    function getHashSD(uint16 _seasonId, uint8 _dayId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_seasonId, _dayId));
    }
    function getHashSDW(uint16 _seasonId, uint8 _dayId, uint8 _wayId) public pure returns(bytes32){
        return keccak256(abi.encodePacked(_seasonId, _dayId, _wayId));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPickleJar.sol";
import "./IGameManager.sol";
import "./AdminGame.sol";

abstract contract Globals is AdminGame {

    //////////////////////////////////////////////////
    // Structs
    //////////////////////////////////////////////////
    struct Season {
        uint16 seasonId;
        uint16 totalPickles;
        uint16 totalPicklesDead;
        uint16 totalJars;
        uint8 dayId;
        bool seasonDone;
        Final theFinal;
        Day[7] day;
        uint16[] jarIds;
        mapping(uint16 => uint16) jarIdsKey;
        mapping(uint16 => uint16) balance;
    }

    struct Day {
        uint64 start;
        uint64 end;
    }

    struct Final {
        uint16 planesLength;
        uint16[] repartition;
        uint16[] killed;
        mapping(uint16 => uint16) randomKeyUsed;
        mapping(uint16 => uint16) jarIdPlaneId;
        mapping(uint16 => uint16[]) planeIdJarId;
        Winner winner;
    }

    struct Winner {
        address owner;
        uint16 jarId;
        uint256 tokenId;
    }

    struct Way {
        uint16 balance;
        uint16 kill;
        uint16[] jarIds;
        uint16[] repartition;
        mapping(uint16 => uint16) offsetWayJarIds;
    }

    struct PicklesKill {
        uint8 wayIdWinner;
        uint16[] jarIdsNotChosen;
        mapping(uint16 => uint8) jarIdWayChosen;
        mapping(uint16 => mapping(uint8 => bool)) bonus;
    }

    //////////////////////////////////////////////////
    // Mapping
    //////////////////////////////////////////////////
    // seasonId => Season
    mapping(uint16 => Season) internal _seasons;

    // hash(seasonId => dayId => wayId) => Way
    mapping(bytes32 => Way) internal _ways;

    // hash(seasonId => dayId) => pickleKilled
    mapping(bytes32 => PicklesKill) internal _picklesKill;

    //////////////////////////////////////////////////
    // Variables
    //////////////////////////////////////////////////
    uint8 public maxWays = 6;
    uint8 public maxPlanes = 24;
    uint256[5] internal pctKillByDay = [3668, 5263, 7553, 7729, 8000];

    ///////////////////////////////////////////////
    // Cache
    ///////////////////////////////////////////////
    uint16 public seasonId;
    bytes32 internal hashSD;

    ///////////////////////////////////////////////
    // Contracts
    ///////////////////////////////////////////////
    IPickleJar public nft;
    IGameManager public gameManager;


    ///////////////////////////////////////////////
    // Event
    ///////////////////////////////////////////////
    event EventAddPickle(uint16 jarId, uint16 count, uint16 seasonId, uint8 dayId);
    event EventKillPickle(uint16 jarId, uint16 count, uint16 seasonId, uint8 dayId);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IPickleJar is IERC721 {
    function mint(address _to, uint256 _startAt, uint256 _count) external;
    function burn(uint256 _tokenId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGameManager {
    function getCurrentGameState() external returns(uint8);
    function setGameState(uint8 _state) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AdminGame is Ownable{

    mapping(address => bool) admins;

    modifier onlyAdmin(){
        require(admins[_msgSender()] || owner() == _msgSender(), "BAW");
        _;
    }

    function setAdminAddress(address _admin, bool _toggle) public onlyOwner {
        admins[_admin] = _toggle;
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}